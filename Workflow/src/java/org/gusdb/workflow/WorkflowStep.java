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
    protected String name;
    protected WorkflowGraph<? extends WorkflowStep> workflowGraph;
    protected String invokerClassName;
    protected List<WorkflowStep> parents = new ArrayList<WorkflowStep>();
    protected List<WorkflowStep> children = new ArrayList<WorkflowStep>();
    protected String subgraphXmlFileName;
    
    // state from db
    protected int workflow_step_id;
    protected String state;
    protected boolean state_handled;
    protected boolean off_line;
    protected String process_id;
    protected Date start_time;
    protected Date end_time;
    
    // other
    private String stepDir;   
    private List<Name> dependsNames = new ArrayList<Name>();
    protected Map<String,String> paramValues = new HashMap<String,String>();
    protected String prevState;
    protected boolean prevOffline;

    
    // static
    private static final String nl = System.getProperty("line.separator");

    
    public void setName(String name) {
        this.name = name;
    }
    
    public void setStepClass(String invokerClassName) {
        this.invokerClassName = invokerClassName;
    }
    
    public void setWorkflowGraph(WorkflowGraph<? extends WorkflowStep> workflowGraph) {
        this.workflowGraph = workflowGraph;
    }   

    void addParent(WorkflowStep parent) {
	parents.add(parent);
    }
    
    void removeParent(WorkflowStep parent) {
        parents.remove(parent);
    }

    protected List<WorkflowStep> getParents() {
	return parents;
    }

    void addChild(WorkflowStep child) {
        parents.add(child);
    }
    
    void removeChild(WorkflowStep child) {
        children.remove(child);
    }

    protected List<WorkflowStep> getChildren() {
        return children;
    }
    
    // insert a child between this step and its previous children
    protected void insertChild(WorkflowStep child) {
        for (WorkflowStep prevChild : children) {
            prevChild.removeParent(this);
            removeChild(prevChild);
            child.addChild(prevChild);
            prevChild.addParent(child);
        }
        child.addParent(this);
        addChild(child);
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
    
    public void setSubgraphXmlFileName(String subgraphXmlFileName) {
        this.subgraphXmlFileName = subgraphXmlFileName;
    }
    
    String getSubgraphXmlFileName() {
        return subgraphXmlFileName;
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
	stmt.setString(2, Workflow.READY);
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

    protected String getStepDir() {
	if (stepDir == null) {
	    stepDir = workflowGraph.getWorkflow().getHomeDir() + "/steps/" + name;
            File dir = new File(stepDir);
            if (!dir.exists()) dir.mkdir();
	}
	return stepDir;
    }

//////////////////////////  utilities /////////////////////////////////////////

    protected void runSql(String sql) throws SQLException, FileNotFoundException, IOException {
	workflowGraph.getWorkflow().runSql(sql);
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
