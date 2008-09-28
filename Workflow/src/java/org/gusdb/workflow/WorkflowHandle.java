package org.gusdb.workflow;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.sql.Date;
import java.sql.ResultSet;
import java.sql.SQLException;

    /*

  lite workflow object (a handle on workflow row in db) used in three contexts:
    - quick reporting of workflow state
    - reseting the workflow
    - workflowstep UI command changing state of a step

   (it avoids the overhead and stringency of parsing and validating
    all workflow steps)
    */

public class WorkflowHandle extends WorkflowBase {
    
 
    public WorkflowHandle(String homeDir) {
        super(homeDir);
    }

    protected String name;
    protected String version;
    protected Integer workflow_id;
    protected String state;
    protected String process_id;
    protected Integer allowed_running_steps;
    protected Date start_time;
    protected Date end_time;


    // very light reporting of state of workflow
    void reportState() throws SQLException, FileNotFoundException, IOException {
	getDbState();

	System.out.println("Workflow '" + name + " " + version  + "'"
			   + "workflow_id:           " + workflow_id
			   + "state:                 " + state
			   + "process_id:            " + process_id
			   + "allowed_running_steps: " + allowed_running_steps);
    }


    void getDbState() throws SQLException, FileNotFoundException, IOException {

	if (workflow_id == null) {
	    name = getWorkflowConfig("name");
	    version = getWorkflowConfig("version");
	    String sql = "select workflow_id, state, process_id, start_time, end_time, allowed_running_steps" + nl
		+ "from apidb.workflow" + nl
		+ "where name = '" + name + "'" + nl
		+ "and version = '" + version + "'" + nl;

	    ResultSet rs = runSqlQuerySingleRow(sql);
	    
	    workflow_id = rs.getInt(1);
	    state = rs.getString(2);
	    process_id = rs.getString(3);
	    start_time = rs.getDate(4);
	    end_time = rs.getDate(5);
	    allowed_running_steps = rs.getInt(6);

	    if (workflow_id == null) 
	        error("workflow '" + name + "' version '" + version + "' not in database");
	}
    }

    Integer getId() throws SQLException, FileNotFoundException, IOException {
	getDbState();
	return workflow_id;
    }

    // brute force reset of workflow.  for developers only
    void reset() throws SQLException, FileNotFoundException, IOException {
	String[] dirNames = {"logs", "steps", "externalFiles"};
	for (String dirName : dirNames) {
	    File dir = new File(getHomeDir() + "/" + dirName);
	    if (dir.exists()) dir.delete();
	    System.out.println("rm -rf " + getHomeDir() + "/" + dirName);
	}

	getDbState();
	String sql = "delete from apidb.workflowstep where workflow_id = " + workflow_id;
	runSql(sql);
	System.out.println(sql);
	sql = "delete from apidb.workflow where workflow_id = " + workflow_id;
	runSql(sql);
	System.out.println(sql);
    }

    void runCmd(String cmd) throws IOException {
      Process process = Runtime.getRuntime().exec(cmd);
      if (process.exitValue() != 0) 
          error("Failed with status $status running: " + nl + cmd);
    }
}

