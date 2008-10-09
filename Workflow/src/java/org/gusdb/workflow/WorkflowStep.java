package org.gusdb.workflow;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.Collections;
import java.util.regex.Matcher;

/*

  the following "state diagram" shows allowed state transitions by
  different parts of the system
 
  controller
   READY   --> ON_DECK
   RUNNING --> FAILED (if wrapper itself dies, ie, controller can't find PID)
   (state_handled --> true)

  step invoker
   ON_DECK --> RUNNING
   RUNNING --> DONE | FAILED
   (state_handled --> false)

  Pilot UI (GUI or command line)
   RUNNING    --> FAILED  (or, just kill the process and let the controller change the state)
   FAILED     --> READY  (ie, the pilot has fixed the problem)
   (state_handled --> false)
   [note: going from done to ready is the province of undo]

  Pilot UI (GUI or command line)
   OFFLINE --> 1/0  (change not allowed if step is running)

*/

public class WorkflowStep  {

    // from construction and configuration
    private String name;
    private Workflow workflow;
    private String invokerClassName;
    private List<WorkflowStep> parents = new ArrayList<WorkflowStep>();
    
    // state from db
    private int workflow_step_id;
    private String state;
    private boolean state_handled;
    private boolean off_line;
    private String process_id;
    private Date start_time;
    private Date end_time;
    
    // other
    private String stepDir;   
    private String prevState;
    private boolean prevOffline;
    private List<Name> dependsNames = new ArrayList<Name>();
    private Map<String,String> paramValues = new HashMap<String,String>();

    
    // static
    private static final String nl = System.getProperty("line.separator");

    
    public void setName(String name) {
        this.name = name;
    }
    
    public void setStepClass(String invokerClassName) {
        this.invokerClassName = invokerClassName;
    }
    
    public void setWorkflow(Workflow w) {
        this.workflow = w;
    }   

    void addParent(WorkflowStep parent) {
	parents.add(parent);
    }

    private List<WorkflowStep> getParents() {
	return parents;
    }

    public void addParamValue(NamedValue paramValue) {
	paramValues.put(paramValue.getName(),paramValue.getValue());
    }

    String getName() {
	return name;
    }

    private int getId () {
	return workflow_step_id;
    }

    String getState () {
	return state;
    }
    
    List<Name> getDependsNames() {
        return dependsNames;
    }

    public void addDependsName(Name dependsName) {
        dependsNames.add(dependsName);
    }
    
    static PreparedStatement getPreparedInsertStmt(Connection dbConnection, int workflowId) throws SQLException {
	String sql = "INSERT INTO apidb.workflowstep (workflow_step_id, workflow_id, name, state, state_handled, off_line)"
	    + " VALUES (apidb.workflowstep_sq.nextval, " + workflowId + ", ?, ?, 1, 0)";
	return dbConnection.prepareStatement(sql);
    }

    // write this step to the db, if not already there.
    // called during workflow initialization
    void initializeStepTable(PreparedStatement stmt) throws SQLException {
	stmt.setString(1, name);
	stmt.setString(2, WorkflowBase.READY);
	stmt.execute();
    }

    static PreparedStatement getPreparedDependsStmt(Connection dbConnection) throws SQLException {
	String sql= "INSERT INTO apidb.workflowstepdependency (workflow_step_dependency_id, parent_id, child_id)"
	+ " VALUES (apidb.workflowstepdependency_sq.nextval, ?, ?)";
	return dbConnection.prepareStatement(sql);
    }

    void initializeDependsTable(PreparedStatement stmt) throws SQLException {
	for (WorkflowStep parentStep : getParents()) {
	    stmt.setInt(1, parentStep.getId());
	    stmt.setInt(2, getId());
	    stmt.execute();
	}
    }

    int handleChangesSinceLastSnapshot() throws SQLException, IOException, InterruptedException  {
	if (state_handled) {
	    if (state.equals(WorkflowBase.RUNNING)) {	        
	        String cmd = "ps -p " + process_id;
	        Process process = Runtime.getRuntime().exec(cmd);
		process.waitFor();
	        if (process.exitValue() != 0) handleMissingProcess();
	    }
	} else { // this step has been changed by wrapper or pilot UI. log change.
	    String stateMsg = "";
	    String offlineMsg = "";
	    if (!state.equals(prevState)) stateMsg = "  " + state;
	    if(off_line != prevOffline) {
		offlineMsg = off_line? "  OFFLINE" : "  ONLINE";
	    }

	    log("Step '" + name + "'" + stateMsg + offlineMsg);
	    setHandledFlag();
	}
	return state.equals(WorkflowBase.RUNNING)? 1 : 0;
    }

    // static method
    static String getBulkSnapshotSql(int workflow_id) {
	return "SELECT name, workflow_step_id, state, state_handled, off_line, process_id, start_time, end_time, host_machine" 
	    + " FROM apidb.workflowstep"
	    + " WHERE workflow_id = " + workflow_id;
    }

    void setFromDbSnapshot(ResultSet rs) throws SQLException {
	prevState = state;
	prevOffline = off_line;

	workflow_step_id = rs.getInt("WORKFLOW_STEP_ID");
	state = rs.getString("STATE");
	state_handled = rs.getBoolean("STATE_HANDLED");
	off_line = rs.getBoolean("OFF_LINE");
	process_id = rs.getString("PROCESS_ID");
	start_time = rs.getDate("START_TIME");
	end_time = rs.getDate("END_TIME");
    }

    private void setHandledFlag() throws SQLException, FileNotFoundException, IOException {
	// check that state is still as expected, to avoid theoretical race condition

	int offlineInt = off_line? 1 : 0;
	String sql = "UPDATE apidb.WorkflowStep"  
	    + " SET state_handled = 1"
	    + " WHERE workflow_step_id = " + workflow_step_id
	    + " AND state = '" + state + "'"
	    + " AND off_line = " + offlineInt;
	runSql(sql);
	state_handled = true;  // till next snapshot
    }

    private void handleMissingProcess() throws SQLException, IOException {
	String sql = "SELECT state" 
	    + " FROM apidb.workflowstep"
	    + " WHERE workflow_step_id = " + workflow_step_id;
	
        ResultSet rs = workflow.getDbConnection().createStatement().executeQuery(sql);

	rs.next();
	String stateNow = rs.getString(1);
	if (stateNow.equals(WorkflowBase.RUNNING)) {

	    sql = "UPDATE apidb.WorkflowStep"  
		+ " SET"  
		+ " state = '" + WorkflowBase.FAILED + "', state_handled = 1, process_id = null" 
		+ " WHERE workflow_step_id = " + workflow_step_id
		+ " AND state = '" + WorkflowBase.RUNNING + "'";
	    runSql(sql);
	    log("Step '" + name + "' FAILED (no wrapper process " + process_id + ")");
	}
    }
	
    // if this step is ready, and all parents are done, transition to ON_DECK
    void maybeGoToOnDeck() throws SQLException, IOException {
 
	if (!state.equals(WorkflowBase.READY) || off_line) return;

	for (WorkflowStep parent : getParents()) {
	    if (!parent.getState().equals(WorkflowBase.DONE)) return;
	}

	log("Step '" + name + "' " + WorkflowBase.ON_DECK);

	String sql = "UPDATE apidb.WorkflowStep"  
	    + " SET state = '" + WorkflowBase.ON_DECK + "', state_handled = 1" 
	    + " WHERE workflow_step_id = " + workflow_step_id  
	    + " AND state = '" + WorkflowBase.READY + "'";
	runSql(sql);
    }

    // try to run a single ON_DECK step
    int runOnDeckStep() throws IOException, SQLException {
	if (state.equals(WorkflowBase.ON_DECK) && !off_line) {
	    String[] cmd = {"workflowstepwrap", workflow.getHomeDir(),
			    workflow.getId().toString(),
			    name, invokerClassName,
			    getStepDir() + "/step.err"}; 

	    List<String> cmd2 = new ArrayList<String>();
	    Collections.addAll(cmd2, cmd);
	    for (String name : paramValues.keySet()) {
		String valueStr = paramValues.get(name);
		valueStr = valueStr.replaceAll("\"", "\\\\\""); 
		cmd2.add("-" + name);
		cmd2.add(valueStr);
	    }
	    log("Invoking step '" + name + "'" );
	    Runtime.getRuntime().exec(cmd2.toArray(new String[] {}));
	    return 1;
	} 
	return 0;
    }
    
    void substituteConstantValues(Map<String,String>constants){
        for (String paramName : paramValues.keySet()) {
            String paramValue = paramValues.get(paramName);
            if (paramValue.indexOf("$$") == -1) continue;
            for (String constantName : constants.keySet()) {
                String constantValue = constants.get(constantName);
                paramValue =
                    paramValue.replaceAll("\\$\\$" + constantName + "\\$\\$",
                            Matcher.quoteReplacement(constantValue));
                paramValues.put(paramName, paramValue);    
            }
        }
    }

    private String getStepDir() {
	if (stepDir == null) {
	    stepDir = workflow.getHomeDir() + "/steps/" + name;
            File dir = new File(stepDir);
            if (!dir.exists()) dir.mkdir();
	}
	return stepDir;
    }

//////////////////////////  utilities /////////////////////////////////////////

    private void log(String msg) throws IOException {
	workflow.log(msg);
    }

    private void runSql(String sql) throws SQLException, FileNotFoundException, IOException {
	workflow.runSql(sql);
    }

    public String toString() {

	String s =  nl 
	    + "name:       " + name + nl
	    + "id:         " + workflow_step_id + nl
	    + "stepClass:  " + invokerClassName + nl
	    + "state:      " + state + nl
	    + "off_line:   " + off_line + nl
	    + "handled:    " + state_handled + nl
	    + "process_id: " + process_id + nl
	    + "start_time: " + start_time + nl
	    + "end_time:   " + end_time + nl
	    + "depends on: ";

	String delim = "";
	StringBuffer buf = new StringBuffer(s);
	for (WorkflowStep parent : getParents()) {
	    buf.append(delim + parent.getName());
	    delim = ", ";
	}
	buf.append(nl + "params: " + paramValues);
	buf.append(nl + nl);
	return buf.toString();
    }

}
