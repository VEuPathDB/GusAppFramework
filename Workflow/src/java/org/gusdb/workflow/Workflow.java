package org.gusdb.workflow;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.Date;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Set;
import java.util.Properties;
import java.util.Arrays;
import java.text.SimpleDateFormat;
import java.text.FieldPosition;
import java.security.NoSuchAlgorithmException;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.Option;
import org.apache.commons.cli.OptionGroup;
import org.apache.commons.cli.Options;

public class Workflow <T extends WorkflowStep>{
    public static final String READY = "READY"; // my parents are not done yet  -- default state
    public static final String ON_DECK = "ON_DECK";  //my parents are done, but there is no slot for me
    public static final String FAILED = "FAILED";
    public static final String DONE = "DONE";
    public static final String RUNNING = "RUNNING";
    public static final String ALL = "ALL";
    public static final String WAITING_FOR_PILOT = "WAITING_FOR_PILOT";  // not used yet.
    
    public static final String START = "START";
    public static final String  END = "END";

    final static String nl = System.getProperty("line.separator");

    private Connection dbConnection;
    private String homeDir;
    private Properties workflowProps;
    protected WorkflowGraph<T> workflowGraph;
    
    // persistent state
    protected String name;
    protected String version;
    protected Integer workflow_id;
    protected String state;
    protected String process_id;
    protected Integer allowed_running_steps;
    protected Date start_time;
    protected Date end_time;

    String[] homeDirSubDirs = {"logs", "steps", "data"};


    public Workflow(String homeDir) {
	this.homeDir = homeDir + "/";   
    }
    
    /////////////////////////////////////////////////////////////////////////
    //        Properties
    /////////////////////////////////////////////////////////////////////////
    void setWorkflowGraph(WorkflowGraph<T> workflowGraph) {
        this.workflowGraph = workflowGraph;
    }
    
    String getHomeDir() {
        return homeDir;
    }

    
    //////////////////////////////////////////////////////////////////////////
    //      Persistent Initialization
    //////////////////////////////////////////////////////////////////////////
    
    void initHomeDir() throws IOException {
	for (String dirName : homeDirSubDirs) {
	    File dir = new File(getHomeDir() + "/" + dirName);
	    if (!dir.exists()) dir.mkdir();
	}
        log("Initializing workflow home directory '" + getHomeDir() + "'");
    }
    
    // read and validate all steps config
   void getStepsConfig() {
        /*
        if (stepsConfig == null) {

            String stepsConfigFile = homeDir + "/config/steps.prop";

            log("Validating Step classes and step config file '" 
                + stepsConfigFile + "'");

            // for each step in the graph, instantiate its invoker, and get the
            // invoker's config declaration.  compare that against the step config file
            Map<String, ConfigDecl> stepConfigDecl
                = new HashMap<String, ConfigDecl>();
            Map<String, ConfigDecl> invokerClassConfigDecl
                = new HashMap<String, ConfigDecl>();

            for (WorkflowStep step : steps) {
                String invokerClassName = step->getInvokerClass();
                if (!invokerClassConfigDecl.contains(invokerClass)) {
                    /* FIX
                    $stepInvokers->{$invokerClass}
                    = eval "{require $invokerClass; $invokerClass->new()}";
                    $self->error($@) if $@;
                    
                }
                stepConfigDecl.put(step.getName(), 
                                   invokerClassConfigDecl.get(invokerClassName));
            }

            // this object does the validation
            /* FIX
               $self->{stepsConfig} =
               CBIL::Util::MultiPropertySet->new($stepsConfigFile, $stepsConfigDecl);
            
        }
        return stepsConfig;
        */
    }
    
    // write the workflow and steps to the db
    // for now, assume the workflow steps don't change over the life of a workflow
    void initDb() throws SQLException, IOException, Exception, NoSuchAlgorithmException {

	boolean stepTableEmpty = initWorkflowTable();
	initWorkflowStepTable(stepTableEmpty);
    }

    boolean  initWorkflowTable() throws SQLException, IOException, Exception, NoSuchAlgorithmException {

        name = getWorkflowConfig("name");
        version = getWorkflowConfig("version");

        // don't bother if already in db
        String sql = "select workflow_id"  
            + " from apidb.workflow"  
            + " where name = " + "'" + name + "'"   
            + " and version = '" + version + "'";

        Statement stmt = null;
        ResultSet rs = null;
        try {
            stmt = getDbConnection().createStatement();
            rs = stmt.executeQuery(sql);
            if (rs.next()) return false;
        } finally {
            if (rs != null) rs.close();
            if (stmt != null) stmt.close(); 
        }

        // otherwise, do it...
        log("Initializing workflow "
            + "'" + name + " " + version + "' in database");

        // write row to Workflow table
        sql = "select apidb.Workflow_sq.nextval from dual";
        try {
            stmt = getDbConnection().createStatement();
            rs = stmt.executeQuery(sql);
            rs.next();
            workflow_id = rs.getInt(1);
        } finally {
            if (rs != null) rs.close();
            if (stmt != null) stmt.close();
        }

        sql = "INSERT INTO apidb.workflow (workflow_id, name, version)"  
            + " VALUES (" + workflow_id + ", '" + name + "', '" + version + "')";
        executeSqlUpdate(sql);
	return true;
    }

    void  initWorkflowStepTable(boolean stepTableEmpty) throws SQLException, IOException, Exception, NoSuchAlgorithmException {

	if (!stepTableEmpty) {
	    // see if our current graph is already in db (exactly)
	    // if so, return
	    // throw an error if any DONE or FAILED steps are changed
	    if (workflowGraph.inDbExactly()) {
		log("Graph in XML matches graph in database.  No need to update database.");
		return;
	    }

	    log("Workflow graph in XML has changed.  Updating DB with new graph.");

	    // if graph has changed, remove all READY/ON_DECK steps from db
	    workflowGraph.removeReadyStepsFromDb();
	    
	}


	Set<String> stepNamesInDb = workflowGraph.getStepNamesInDb();

        // write all steps to WorkflowStep table
	// for steps that are already there, update the depthFirstOrder
        PreparedStatement insertStepPstmt = WorkflowStep.getPreparedInsertStmt(getDbConnection(), workflow_id);
	PreparedStatement updateStepPstmt = WorkflowStep.getPreparedUpdateStmt(getDbConnection(), workflow_id);
        try {
            for (WorkflowStep step : workflowGraph.getSortedSteps()) {
                log("  " + step.getFullName());
                step.initializeStepTable(stepNamesInDb, insertStepPstmt, updateStepPstmt);
            }
        } finally {
            updateStepPstmt.close();
            insertStepPstmt.close();
        }

        // update steps in memory, to get their new IDs
        getStepsDbState();
    }

    ///////////////////////////////////////////////////////////////////////////
    //    Read from DB
    ///////////////////////////////////////////////////////////////////////////
    
    Integer getId() throws SQLException, FileNotFoundException, IOException {
        getDbState();
        return workflow_id;
    }
    
    void getDbSnapshot() throws SQLException, IOException {
        getDbState();
        getStepsDbState();
    }

    void getDbState() throws SQLException, FileNotFoundException, IOException {
        if (workflow_id == null) {
            name = getWorkflowConfig("name");
            version = getWorkflowConfig("version");
            String sql = "select workflow_id, state, process_id, start_time, end_time, allowed_running_steps"  
                + " from apidb.workflow"  
                + " where name = '" + name + "'"  
                + " and version = '" + version + "'" ;

            Statement stmt = null;
            ResultSet rs = null;
            try {
                stmt = getDbConnection().createStatement();
                rs = stmt.executeQuery(sql);
                if (!rs.next()) 
                    error("workflow '" + name + "' version '" + version + "' not in database");
                workflow_id = rs.getInt(1);
                state = rs.getString(2);
                process_id = rs.getString(3);
                start_time = rs.getDate(4);
                end_time = rs.getDate(5);
                allowed_running_steps = rs.getInt(6);
            } finally {
                if (rs != null) rs.close();
                if (stmt != null) stmt.close(); 
            }
            
        }
    }

    // read all WorkflowStep rows into memory (and remember the prev snapshot)
    void getStepsDbState() throws SQLException, FileNotFoundException, IOException {
        String sql = WorkflowStep.getBulkSnapshotSql(workflow_id);

        // run query to get all rows from WorkflowStep for this workflow
        // stuff each row into the snapshot, keyed on step name
        Statement stmt = null;
        ResultSet rs = null;
        try {
            stmt = getDbConnection().createStatement();
            rs = stmt.executeQuery(sql);
            while (rs.next()) {
                String stepName = rs.getString("NAME");
                WorkflowStep step = workflowGraph.getStepsByName().get(stepName);
		if (step == null) {
		    (new Throwable()).printStackTrace();
		     error("Engine can't find step with name '" 
			   + stepName + "'");
		}
                step.setFromDbSnapshot(rs);
            }
        } finally {
            if (rs != null) rs.close();
            if (stmt != null) stmt.close();             
        }
    }
        
    ////////////////////////////////////////////////////////////////////////
    //             Utilities
    ////////////////////////////////////////////////////////////////////////

    void log(String msg) throws IOException {
        String logFileName = getHomeDir() + "/logs/controller.log";
        PrintWriter writer = new PrintWriter(new FileWriter(logFileName, true));
	SimpleDateFormat sdf = new SimpleDateFormat("EEE, d MMM yyyy HH:mm:ss");
	StringBuffer buf = sdf.format(new java.util.Date(), new StringBuffer(),
				      new FieldPosition(0));

        writer.println(buf + "  " + msg + nl);
        writer.close();
    }
    
    WorkflowStep newStep() {
        return new WorkflowStep();
    }

    void runCmd(String cmd) throws IOException, InterruptedException {
        Utilities.runCmd(cmd);
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

    void executeSqlUpdate(String sql) throws SQLException, FileNotFoundException, IOException {
        Statement stmt = getDbConnection().createStatement();
        try {
            stmt.executeUpdate(sql);
        } finally {
            stmt.close();
        }
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
    
    String getStepsXmlFileName() throws FileNotFoundException, IOException {
        Properties workflowProps = new Properties();        
        workflowProps.load(new FileInputStream(getHomeDir() + "config/workflow.prop"));
        return workflowProps.getProperty("workflowXmlFile");
    }
    
    //////////////////////////////////////////////////////////////////
    //   Actions
    //////////////////////////////////////////////////////////////////
    
    // very light reporting of state of workflow
    void reportState() throws SQLException, FileNotFoundException, IOException {
        getDbState();

        System.out.println("Workflow '" + name + " " + version  + "'" + nl
                           + "workflow_id:           " + workflow_id + nl
                           + "state:                 " + state + nl
                           + "process_id:            " + process_id + nl
                           + "allowed_running_steps: " + allowed_running_steps + nl);
    }

    /* Step Reporter: called by command line UI to report state of steps.
       does not run the controller
    */
    void reportSteps(String[] desiredStates) throws Exception {
        initHomeDir();         // initialize workflow home directory, if needed

        initDb();              // write workflow to db, if not already there

        getStepsConfig();      // validate config of all steps.

        getDbSnapshot();       // read state of Workflow and WorkflowSteps

        reportState();

        if (desiredStates.length == 0 || desiredStates[0].equals("ALL")) {
            String[] ds = {READY, ON_DECK, RUNNING, DONE, FAILED};
            desiredStates = ds;      
        }
        for (String desiredState : desiredStates) { 
            System.out.println("=============== " 
                               + desiredState + " steps "
                               + "================"); 
            for (T step : workflowGraph.getSortedSteps()) {
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
    
    
    // brute force reset of workflow.  for developers only
     void reset() throws SQLException, FileNotFoundException, IOException {
         for (String dirName : homeDirSubDirs) {
             File dir = new File(getHomeDir() + "/" + dirName);
             Utilities.deleteDir(dir);
             System.out.println("rm -rf " + dir);
         }

         getDbState();
         String sql = "delete from apidb.workflowstep where workflow_id = " + workflow_id;
         executeSqlUpdate(sql);
         System.out.println(sql);
         sql = "delete from apidb.workflow where workflow_id = " + workflow_id;
         executeSqlUpdate(sql);
         System.out.println(sql);
     }


     ////////////////////////////////////////////////////////////////////////
     //           Static methods
     ////////////////////////////////////////////////////////////////////////
         
     public static void main(String[] args) throws Exception  {
         String cmdName = System.getProperty("cmdName");

         // parse command line
         Options options = declareOptions();
         String cmdlineSyntax = cmdName + " -h workflow_home_dir <-r num_steps | -t num_steps | -q | -d <states> >";
         String cmdDescrip = "Run or test a workflow, or, print a report about a workflow.";
         CommandLine cmdLine =
             Utilities.parseOptions(cmdlineSyntax, cmdDescrip, getUsageNotes(), options, args);
                 
         String homeDirName = cmdLine.getOptionValue("h");
	 
	 boolean oops = false;
         // branch based on provided options
         if (cmdLine.hasOption("r") || cmdLine.hasOption("t")) {
             RunnableWorkflow runnableWorkflow = new RunnableWorkflow(homeDirName);
             Class<RunnableWorkflowStep> stepClass = RunnableWorkflowStep.class;
             WorkflowGraph<RunnableWorkflowStep> rootGraph = 
                 WorkflowGraph.constructFullGraph(stepClass, runnableWorkflow);
             runnableWorkflow.setWorkflowGraph(rootGraph);
             String numSteps = cmdLine.getOptionValue("r");
             boolean testOnly = cmdLine.hasOption("t");
             if (testOnly) numSteps = cmdLine.getOptionValue("t");
             runnableWorkflow.run(Integer.parseInt(numSteps), testOnly);                
         } 
         
         else if (cmdLine.hasOption("q")) {

         } 
         
         else if (cmdLine.hasOption("d")) {
             Workflow<WorkflowStep> workflow = new Workflow<WorkflowStep>(homeDirName);
             Class<WorkflowStep> stepClass = WorkflowStep.class;
             WorkflowGraph<WorkflowStep> rootGraph = 
                 WorkflowGraph.constructFullGraph(stepClass, workflow);
             workflow.setWorkflowGraph(rootGraph);      
             String desiredStatesStr = cmdLine.getOptionValue("d"); 
             String[] desiredStates = desiredStatesStr.split(",");
	     String[] allowedStates = {READY, ON_DECK, RUNNING, DONE, FAILED, ALL};
	     Arrays.sort(allowedStates);
	     for (String state : desiredStates) {
		 if (Arrays.binarySearch(allowedStates, state) < 0)
		     oops = true;
	     }

             if (!oops) workflow.reportSteps(desiredStates);            
         } 
         
         else if (cmdLine.hasOption("reset")) {
             Workflow<WorkflowStep> workflow = new Workflow<WorkflowStep>(homeDirName);
             workflow.reset();
         } 
         
         else {
	     oops = true;
         }
	 if (oops) {
             Utilities.usage(cmdlineSyntax, cmdDescrip, getUsageNotes(), options);
	     System.exit(1);
	     
	 } else {
	     System.exit(0);
	 }
     }
     
     private static String getUsageNotes() {
         return
  
       "Home dir must contain the following:" + nl
     + "   config/" + nl
     + "     workflow.prop      (meta config)" + nl
     + "     steps.prop         (steps config)" + nl
     + "     stepsGlobal.prop   (global steps config)" + nl
     + "     resources.xml      [future]" + nl
     + nl + nl   
     + "Allowed states:  READY, ON_DECK, RUNNING, DONE, FAILED, ALL"
     + nl + nl                        
     + "Examples:" + nl
     + nl     
     + "  run a workflow:" + nl
     + "    % workflow -h workflow_dir -r 3" + nl
     + nl     
     + "  test a workflow:" + nl
     + "    % workflow -h workflow_dir -t 3" + nl
     + nl     
     + "  quick report of workflow state" + nl
     + "    % workflow -h workflow_dir -q" + nl
     + nl     
     + "  print detailed steps report." + nl
     + "    % workflow -h workflow_dir -d" + nl
     + nl     
     + "  limit steps report to steps in particular states" + nl
     + "    % workflow -h workflow_dir -d FAILED RUNNING" + nl
     + nl     
     + "  print steps report, using the optional offline flag to only include steps" + nl
     + "  that have the flag in the indicated state.  [not implemented yet]" + nl
     + "    % workflow -h workflow_dir -d0 ON_DECK" + nl
     + "    % workflow -h workflow_dir -d1 READY ON_DECK" + nl;
     }

     private static Options declareOptions() {
         Options options = new Options();

         Utilities.addOption(options, "h", "Workflow homedir (see below)");
         
         OptionGroup optionalOptions = new OptionGroup();
         Option run = new Option("r", true,
              "Run a strategy, and specify the number of steps allowed to run simultaneously");
         optionalOptions.addOption(run);
         
         Option test = new Option("t", true,
         "Test a strategy, and specify the number of steps allowed to run simultaneously");
         optionalOptions.addOption(test);
    
         Option detailedRep = new Option("d", true, "Print detailed report");
         optionalOptions.addOption(detailedRep);
         
         Option quickRep = new Option("q", "Print quick report");
         optionalOptions.addOption(quickRep);
         options.addOptionGroup(optionalOptions);

         Option reset = new Option("reset", "Reset workflow. DANGER! Will destroy your workflow.  Use only if you know exactly what you are doing.");
         optionalOptions.addOption(reset);
         options.addOptionGroup(optionalOptions);

         return options;
     }
 }
    

