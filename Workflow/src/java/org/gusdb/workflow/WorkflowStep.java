package org.gusdb.workflow;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.security.NoSuchAlgorithmException;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.HashMap;

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
    private String baseName;
    private String path = "";
    protected WorkflowGraph<? extends WorkflowStep> workflowGraph;
    protected String invokerClassName;
    protected List<WorkflowStep> parents = new ArrayList<WorkflowStep>();
    protected List<WorkflowStep> children = new ArrayList<WorkflowStep>();
    protected String subgraphXmlFileName;
    protected boolean isSubgraphCall;
    protected boolean isSubgraphReturn;
    protected boolean isGlobal = false;
    List<? extends WorkflowStep> sharedGlobalSteps;
    String paramsDigest;
    int depthFirstOrder;
    String[] loadTypes = {"total"};
    String includeIf_string;
    String excludeIf_string;
    boolean excludeFromGraph = false;
    
    // state from db
    protected int workflow_step_id;
    protected String state;
    protected boolean state_handled;
    protected String undo_state;
    protected boolean undo_state_handled;
    protected boolean off_line;
    protected boolean stop_after;
    protected String process_id;
    protected Date start_time;
    protected Date end_time;
    
    // other
    private String stepDir;   
    private List<Name> dependsNames = new ArrayList<Name>();
    protected Map<String,String> paramValues = new HashMap<String,String>();
    protected String prevState;
    protected boolean prevOffline;
    protected boolean prevStopAfter;

    // static
    private static final String nl = System.getProperty("line.separator");

    
    public void setName(String name) {
        this.baseName = name;
    }
    
    public void setStepClass(String invokerClassName) {
        this.invokerClassName = invokerClassName;
    }
    
    public void setStepLoadTypes(String loadTypes) {
	String[] tmp = loadTypes.split(",\\s*");
	this.loadTypes = new String[tmp.length+1];
	this.loadTypes[0] = "total";
	for (int i=0; i<tmp.length; i++) this.loadTypes[i+1] = tmp[i];
    }
    
    public String[] getLoadTypes() {
        return loadTypes;
    }
    
    public void setIsGlobal(boolean isGlobal) {
        this.isGlobal  = isGlobal;
    }
    
    protected boolean getIsGlobal() { return isGlobal; }
    
    boolean getIsSubgraphCall() { return isSubgraphCall; }
    
    boolean getIsSubgraphReturn() { return isSubgraphReturn; }
    
    boolean getStopAfter() { return stop_after; }
    
    String getStepClassName() {
	return invokerClassName;
    }
    
    void setSharedGlobalSteps(List<? extends WorkflowStep> sharedGlobalSteps) {
        this.sharedGlobalSteps = sharedGlobalSteps;
    }
    
    public void setWorkflowGraph(WorkflowGraph<? extends WorkflowStep> workflowGraph) {
        this.workflowGraph = workflowGraph;
    }   
    
    void checkLoadTypes() throws FileNotFoundException, IOException {
        for (String loadType : loadTypes) {
            Integer val = workflowGraph.getWorkflow().getLoadBalancingConfig(loadType);
	    if (val == null) Utilities.error("Step " + getFullName() + " has unknown stepLoadType: " + loadType);
        }
    }
    
    public void setIncludeIf(String includeIf_str) {
        includeIf_string = includeIf_str;
    }
    
    public void setExcludeIf(String excludeIf_str) {
        excludeIf_string = excludeIf_str;
    }
    
    boolean getExcludeFromGraph() {
        return excludeFromGraph;
    }

    void addParent(WorkflowStep parent) {
	if (!parents.contains(parent)) parents.add(parent);
    }
    
    void removeParent(WorkflowStep parent) {
        parents.remove(parent);
    }

    protected List<WorkflowStep> getParents() {
	return parents;
    }

    void addChild(WorkflowStep child) {
        if (!children.contains(child)) children.add(child);
    }
    
    void removeChild(WorkflowStep child) {
        children.remove(child);
    }

    protected List<WorkflowStep> getChildren() {
        return children;
    }
    
    Set<WorkflowStep> getAllChildren() {
        Set<WorkflowStep> kids = new HashSet<WorkflowStep>(children);
        for (WorkflowStep kid : children) {
            kids.addAll(kid.getAllChildren());
        }
        return kids;
    }
    
    Map<String,String> getParamValues() {
        return paramValues;
    }
    
    void addToList(List<WorkflowStep> list) {
        if (list.contains(this)) return;
        list.add(this);
        for (WorkflowStep child : getChildren()) {
            child.addToList(list);
        }
    }
        
    // insert a child between this step and its previous children
    protected WorkflowStep insertSubgraphReturnChild() {
        WorkflowStep newStep = newStep();
        newStep.setXmlFile(subgraphXmlFileName); // remember this in case of undo
        newStep.isSubgraphCall = false;
        newStep.isSubgraphReturn = true;
	newStep.setWorkflowGraph(workflowGraph);
        insertSubgraphReturnChild_sub(newStep);
        return newStep;
    }
    
    private void insertSubgraphReturnChild_sub(WorkflowStep returnStep) {
        returnStep.setName(getFullName() + ".return");
        List<WorkflowStep> oldChildren = new ArrayList<WorkflowStep>(children);
        for (WorkflowStep oldChild : oldChildren) {
            oldChild.removeParent(this);
            removeChild(oldChild);
            returnStep.addChild(oldChild);
            oldChild.addParent(returnStep);
        }
        returnStep.addParent(this);
        addChild(returnStep);
    }

    public void addParamValue(NamedValue paramValue) {
	paramValues.put(paramValue.getName(),paramValue.getValue());
    }

    String getBaseName() {
	return baseName;
    }
    
    String getFullName() {
        return getPath() + getBaseName();
    }
    
    void setPath(String path) {
        this.path = path;
    }
    
    String getPath() {
        return path;
    }

    int getId () {
	return workflow_step_id;
    }

    String getState () {
	return state;
    }
    
    String getUndoState () {
        return undo_state;
    }
    
    String getOperativeState() {
        return getUndoing()? undo_state : state;
    }
    
    boolean getOperativeStateHandled() {
        return getUndoing()? undo_state_handled : state_handled;
    }
    
    boolean getUndoing() {
        return workflowGraph.getWorkflow().getUndoStepId() != null;
    }
    List<Name> getDependsNames() {
        return dependsNames;
    }

    public void addDependsName(Name dependsName) {
        dependsNames.add(dependsName);
    }
    
    public void setXmlFile(String subgraphXmlFileName) {
        this.subgraphXmlFileName = subgraphXmlFileName;
        isSubgraphCall = true;
    }
    
    String getSubgraphXmlFileName() {
        return subgraphXmlFileName;
    }
    
    String getParamsDigest() throws NoSuchAlgorithmException, Exception {
        if (paramsDigest == null) 
            paramsDigest = Utilities.encrypt(paramValues.toString());
        return paramsDigest;
    }

    int getDepthFirstOrder() {
	return depthFirstOrder;
    }

    void setDepthFirstOrder(int o) {
	depthFirstOrder = o;
    }
    
    static PreparedStatement getPreparedInsertStmt(Connection dbConnection, int workflowId) throws SQLException {
	String sql = "INSERT INTO apidb.workflowstep (workflow_step_id, workflow_id, name, state, state_handled, undo_state, undo_state_handled, off_line, stop_after, depth_first_order, step_class, params_digest)"
	    + " VALUES (apidb.workflowstep_sq.nextval, " + workflowId
	    + ", ?, ?, 1, null, 1, 0, 0, ?, ?, ?)";
	return dbConnection.prepareStatement(sql);
    }

    static PreparedStatement getPreparedUpdateStmt(Connection dbConnection, int workflowId) throws SQLException {
        String sql = "UPDATE apidb.workflowstep"
            + " SET depth_first_order = ?"
            + " WHERE name = ?"
            + " AND workflow_id = " + workflowId;
        return dbConnection.prepareStatement(sql);
    }

    static PreparedStatement getPreparedUndoUpdateStmt(Connection dbConnection, int workflowId) throws SQLException {
        String sql = "UPDATE apidb.workflowstep"
            + " SET undo_state = '" + Workflow.READY + "'"
            + " WHERE name = ?"
            + " AND undo_state is NULL"
            + " AND workflow_id = " + workflowId;
        return dbConnection.prepareStatement(sql);
    }

    // write this step to the db, if not already there.
    // called during workflow initialization
    void initializeStepTable(Set<String> stepNamesInDb, PreparedStatement insertStmt, PreparedStatement updateStmt) throws SQLException, NoSuchAlgorithmException, Exception {
	if (stepNamesInDb.contains(getFullName())) {
	    updateStmt.setInt(1, getDepthFirstOrder());
	    updateStmt.setString(2, getFullName());
	    updateStmt.execute();
	} else {
	    insertStmt.setString(1, getFullName());
	    insertStmt.setString(2, Workflow.READY);
	    insertStmt.setInt(3, depthFirstOrder);
	    insertStmt.setString(4, invokerClassName);
	    insertStmt.setString(5, getParamsDigest());
	    insertStmt.execute();
	} 
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
	return "SELECT name, workflow_step_id, state, state_handled, undo_state, undo_state_handled, off_line, stop_after, process_id, start_time, end_time, host_machine" 
	    + " FROM apidb.workflowstep"
	    + " WHERE workflow_id = " + workflow_id;
    }

    void setFromDbSnapshot(ResultSet rs) throws SQLException {
	prevState = getOperativeState();
        prevOffline = off_line;
        prevStopAfter = stop_after;

	workflow_step_id = rs.getInt("WORKFLOW_STEP_ID");
	state = rs.getString("STATE");
	state_handled = rs.getBoolean("STATE_HANDLED");
        undo_state = rs.getString("UNDO_STATE");
        undo_state_handled = rs.getBoolean("UNDO_STATE_HANDLED");
        off_line = rs.getBoolean("OFF_LINE");
        stop_after = rs.getBoolean("STOP_AFTER");
	process_id = rs.getString("PROCESS_ID");
	start_time = rs.getDate("START_TIME");
	end_time = rs.getDate("END_TIME");
    }
    
    // interpolate constants into param values
    void substituteValues(Map<String,String>variables, boolean check){
        for (String paramName : paramValues.keySet()) {
            String paramValue = paramValues.get(paramName);
	    String newParamValue = 
		Utilities.substituteVariablesIntoString(paramValue, variables);
	    paramValues.put(paramName, newParamValue); 
	    if (check) {
		if (newParamValue.indexOf("$$") != -1) 
		    Utilities.error("Parameter '" + paramName + "' in step '" 
				    + getFullName() 
				    + "' includes an unresolvable variable reference: '"
				    + newParamValue + "'");
	    }
        }
        if (includeIf_string != null) 
	    includeIf_string = processIfString("includeIf", 
					       includeIf_string,
					       variables,
					       check);
	
        if (excludeIf_string != null) 
	    excludeIf_string = processIfString("excludeIf", 
					       excludeIf_string,
					       variables,
					       check);
	
    }

    private String processIfString(String type, String ifString, Map<String,String>variables, boolean check) {
	String newIf = Utilities.substituteVariablesIntoString(ifString, variables);
	    
	if (check) {
	    if (newIf.indexOf("$$") != -1) 
		Utilities.error(type + " in step '"  + getFullName() 
				+ "' includes an unresolvable variable reference: '"
				+ newIf + "'");
	    if (!newIf.equals("true") && !newIf.equals("false"))
		Utilities.error(type + " in step '"  + getFullName() 
				+ "' is neither 'true' nor 'false': '"
				+ newIf + "'");
	}
	return newIf;
    }

    void setIfs() {
	// the rng schema enforces that we have one or the other, not both
        if (includeIf_string != null) 
	    excludeFromGraph = !Boolean.valueOf(includeIf_string).booleanValue();
        if (excludeIf_string != null) 
	    excludeFromGraph = Boolean.valueOf(excludeIf_string).booleanValue();
    }

    protected String getStepDir() {
	if (stepDir == null) {
	    stepDir = workflowGraph.getWorkflow().getHomeDir() + "/steps/" + getFullName();
            File dir = new File(stepDir);
            if (!dir.exists()) dir.mkdir();
	}
	return stepDir;
    }
    
    void invert() {
        List<WorkflowStep> temp = parents;
        parents = children;
        children = temp;
        boolean temp2 = isSubgraphCall;
        isSubgraphCall = isSubgraphReturn;
        isSubgraphReturn = temp2;
    }

//////////////////////////  utilities /////////////////////////////////////////
    
    WorkflowStep newStep() {
        return new WorkflowStep();
    }

    protected void executeSqlUpdate(String sql) throws SQLException, FileNotFoundException, IOException {
	workflowGraph.getWorkflow().executeSqlUpdate(sql);
    }

    public String toString() {

	String s =  nl 
	    + "name:       " + getFullName() + nl
	    + "id:         " + workflow_step_id + nl
	    + "stepClass:  " + invokerClassName + nl
	    + "subgraphXml " + subgraphXmlFileName + nl
	    + "state:      " + state + nl
            + "undo_state: " + undo_state + nl
            + "off_line:   " + off_line + nl
            + "stop_after: " + stop_after + nl
	    + "handled:    " + state_handled + nl
	    + "process_id: " + process_id + nl
	    + "start_time: " + start_time + nl
	    + "end_time:   " + end_time + nl
	    + "depends on: ";

	String delim = "";
	StringBuffer buf = new StringBuffer(s);
	for (WorkflowStep parent : getParents()) {
	    buf.append(delim + parent.getFullName());
	    delim = ", ";
	}
	buf.append(nl + "params: " + paramValues);
	buf.append(nl + nl);
	return buf.toString();
    }

}
