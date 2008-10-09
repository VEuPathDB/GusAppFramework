package org.gusdb.workflow;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.sql.Connection;
import java.sql.Date;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Arrays;
import java.util.Properties;

public class WorkflowBase {
    public static final String READY = "READY"; // my parents are not done yet  -- default state
    public static final String ON_DECK = "ON_DECK";  //my parents are done, but there is no slot for me
    public static final String FAILED = "FAILED";
    public static final String DONE = "DONE";
    public static final String RUNNING = "RUNNING";
    public static final String WAITING_FOR_PILOT = "WAITING_FOR_PILOT";  // not used yet.
    
    public static final String START = "START";
    public static final String  END = "END";

    final static String nl = System.getProperty("line.separator");

    private Connection dbConnection;
    private String homeDir;
    private Properties workflowProps;
    private WorkflowGraph workflowGraph;
    
    // persistent state
    protected String name;
    protected String version;
    protected Integer workflow_id;
    protected String state;
    protected String process_id;
    protected Integer allowed_running_steps;
    protected Date start_time;
    protected Date end_time;

    // methods shared by the perl controller and perl step wrapper.
    // any other language implementation would presumably need equivalent code
    public WorkflowBase() {
    }

    public void setHomeDir(String homeDir) {
	this.homeDir = homeDir;
    }

    void setWorkflowGraph(WorkflowGraph workflowGraph) {
        this.workflowGraph = workflowGraph;
    }

    /* Step Reporter: called by command line UI to report state of steps.
       does not run the controller
    */
    private void reportSteps(String[] desiredStates) throws Exception {
        noLog = true;

        initSteps();

        getDbSnapshot();      // read state of Workflow and WorkflowSteps

        reportState();

        String sortedStepNames[] = new String[stepsByName.size()];
        stepsByName.keySet().toArray(sortedStepNames); 
        Arrays.sort(sortedStepNames);

        if (desiredStates.length == 0 || desiredStates[0].equals("ALL")) {
            String[] ds = {READY, ON_DECK, RUNNING, DONE, FAILED};
            desiredStates = ds;      
        }
        for (String desiredState : desiredStates) { 
            System.out.println("=============== " 
                               + desiredState + " steps "
                               + "================"); 
            for (String stepName : sortedStepNames) {
                WorkflowStep step = stepsByName.get(stepName);
                if (step.getState().equals(desiredState)) {
                    System.out.println(step.toString());
                    /* FIX
                    System.out.println(stepsConfig.toString(stepName));
                    */
                    System.out.println("-----------------------------------------");
                }
            }    
        }
    }
    private void initSteps() throws Exception {

        initDb();              // write workflow to db, if not already there

        getStepsConfig();      // validate config of all steps.
    }
    
    // write the workflow and steps to the db
    // for now, assume the workflow steps don't change over the life of a workflow
    private void initDb() throws SQLException, IOException {

        name = getWorkflowConfig("name");
        version = getWorkflowConfig("version");

        // don't bother if already in db
        String sql = "select workflow_id"  
            + " from apidb.workflow"  
            + " where name = " + "'" + name + "'"   
            + " and version = '" + version + "'";

        ResultSet rs = getDbConnection().createStatement().executeQuery(sql);

        if (rs.next()) return;

        // otherwise, do it...
        log("Initializing workflow "
            + "'" + name + " " + version + "' in database");

        // write row to Workflow table
        sql = "select apidb.Workflow_sq.nextval from dual";
        workflow_id = runSqlQuerySingleRow(sql).getInt(1);

        sql = "INSERT INTO apidb.workflow (workflow_id, name, version)"  
            + " VALUES (" + workflow_id + ", '" + name + "', '" + version + "')";
        runSql(sql);

        // write all steps to WorkflowStep table
        PreparedStatement stmt = WorkflowStep.getPreparedInsertStmt(getDbConnection(), workflow_id);
        for (WorkflowStep step : steps) {
            step.initializeStepTable(stmt);
        }

        // update steps in memory, to get their new IDs
        getWorkflowStepsDbSnapshot();
    }

    private void getDbSnapshot() throws SQLException, IOException {
        getDbState();
        getWorkflowStepsDbSnapshot();
    }

    // read all WorkflowStep rows into memory (and remember the prev snapshot)
    private void getWorkflowStepsDbSnapshot() throws SQLException, FileNotFoundException, IOException {
        String sql = WorkflowStep.getBulkSnapshotSql(workflow_id);

        // run query to get all rows from WorkflowStep for this workflow
        // stuff each row into the snapshot, keyed on step name
        Statement stmt = getDbConnection().createStatement();
        ResultSet rs = stmt.executeQuery(sql);
        while (rs.next()) {
            String stepName = rs.getString("NAME");
            WorkflowStep step = stepsByName.get(stepName);
            step.setFromDbSnapshot(rs);
        }
    }
    
    private void initHomeDir() throws IOException {
        File stepsDir = new File(getHomeDir() + "/steps");
        if (!stepsDir.exists()) stepsDir.mkdir();
        File logsDir = new File(getHomeDir() + "/logs");
        if (!logsDir.exists()) logsDir.mkdir();
        log("Initializing workflow home directory '" + getHomeDir() + "'");
    }

    
    
    Connection getDbConnection() throws SQLException, FileNotFoundException, IOException {
	if (dbConnection == null) {
	    DriverManager.registerDriver (new oracle.jdbc.driver.OracleDriver());
	    dbConnection = DriverManager.getConnection(getWorkflowConfig("jdbcConnectString"),
	            getWorkflowConfig("dbLogin"),
	            getWorkflowConfig("dbPassword"));
	}
	return dbConnection;
    }

    void runSql(String sql) throws SQLException, FileNotFoundException, IOException {
	Statement stmt = getDbConnection().createStatement();
	stmt.executeUpdate(sql);
    }

    ResultSet runSqlQuerySingleRow(String sql) throws SQLException, FileNotFoundException, IOException {
        Statement stmt = getDbConnection().createStatement();
        ResultSet rs = stmt.executeQuery(sql);
        rs.next();
        return rs;
    }

    String getHomeDir() {
	return homeDir;
    }

    String getWorkflowConfig(String key) throws FileNotFoundException, IOException {
        if (workflowProps == null) {
            workflowProps = new Properties();
            workflowProps.load(new FileInputStream(getHomeDir() + "/config/workflow.prop"));
        }
        return workflowProps.getProperty(key);

        /* FIX
    my @properties = 
	(
	 // [name, default, description]
	 ['name', "", ""],
	 ['version', "", ""],
	 ['dbLogin', "", ""],
	 ['dbPassword', "", ""],
	 ['dbConnectString', "", ""],
	 ['workflowXmlFile', "", ""],
	);
	*/
    }

    void error(String msg) {
        Utilities.error(msg);
    }
    

    // very light reporting of state of workflow
    void reportState() throws SQLException, FileNotFoundException, IOException {
        getDbState();

        System.out.println("Workflow '" + name + " " + version  + "'" + nl
                           + "workflow_id:           " + workflow_id + nl
                           + "state:                 " + state + nl
                           + "process_id:            " + process_id + nl
                           + "allowed_running_steps: " + allowed_running_steps + nl);
    }


    void getDbState() throws SQLException, FileNotFoundException, IOException {

        if (workflow_id == null) {
            name = getWorkflowConfig("name");
            version = getWorkflowConfig("version");
            String sql = "select workflow_id, state, process_id, start_time, end_time, allowed_running_steps"  
                + " from apidb.workflow"  
                + " where name = '" + name + "'"  
                + " and version = '" + version + "'" ;

            ResultSet rs = getDbConnection().createStatement().executeQuery(sql);
            if (!rs.next()) 
                error("workflow '" + name + "' version '" + version + "' not in database");
            
            workflow_id = rs.getInt(1);
            state = rs.getString(2);
            process_id = rs.getString(3);
            start_time = rs.getDate(4);
            end_time = rs.getDate(5);
            allowed_running_steps = rs.getInt(6);
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
            Utilities.deleteDir(dir);
            System.out.println("rm -rf " + dir);
        }

        getDbState();
        String sql = "delete from apidb.workflowstep where workflow_id = " + workflow_id;
        runSql(sql);
        System.out.println(sql);
        sql = "delete from apidb.workflow where workflow_id = " + workflow_id;
        runSql(sql);
        System.out.println(sql);
    }

    void runCmd(String cmd) throws IOException, InterruptedException {
      Process process = Runtime.getRuntime().exec(cmd);
      process.waitFor();
      if (process.exitValue() != 0) 
          error("Failed with status $status running: " + nl + cmd);
    }
    
}
