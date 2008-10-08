package org.gusdb.workflow;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.HashMap;
import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.Option;
import org.apache.commons.cli.OptionGroup;
import org.apache.commons.cli.Options;

/*
   to do
   - xml validation
   - include/exclude
   - integrate resource pipeline
   - nested workflows
   - dynamically change allowed num running steps
   - handle changes to graph after running
   - cascading defaults for config file
   - check for graph cycles
   - compute cluster
   - make running order repeatable (sort by order in xml file)
   - improve log formatting
   - possibly support taking DONE steps offline.  this will require recursion.

  
   Workflow object that runs in two contexts:
     - step reporter
     - controller
  
   Controller theoretical issues
  
   Race conditions
   the controller gets a snapshot of the db each cycle. one class of possible
   race conditions is if there are external changes since the snapshot was
   taken. the controller only updates the state in the database if the state
   in the db is the same as in memory, ie, the same as in the snapshot.  this
   preserves any external change to be seen by the next cycle.
  
   this leaves the problem of (a) more than one external change happening
   within a cycle.  but, there are no transitory states that matter. The only
   consequence is that the intermediate state won't be logged.  the only
   one of these which could realistically happen in the time frame of a cycle
   is the transition from RUNNING to DONE, if a step executes quickly.  In this
   case, the log will show only DONE, without ever showing RUNNING, which is ok.
  
   and also the problem of (b) that the controller could not write the step's
   state because the state had changed since the snapshot.  the controller
   only writes the ON_DECK and FAILED states.  the next cycle will handle
   these correctly.
*/

public class Workflow extends WorkflowHandle {
    private List<WorkflowStep> steps = new ArrayList<WorkflowStep>();
    private Map<String, WorkflowStep> stepsByName = new HashMap<String, WorkflowStep>();
    private boolean noLog;
    private int runningCount; 
    private Map<String,String> constants = new HashMap<String,String>();

    public Workflow() {
    }

    public void addConstant(NamedValue constant) {
	constants.put(constant.getName(),constant.getValue());
    }
    
    public void addStep(WorkflowStep step) {
        step.setWorkflow(this);
        String stepName = step.getName();
        if (stepsByName.containsKey(stepName))
            Utilities.error("non-unique step name: '" + stepName + "'");
        stepsByName.put(stepName, step);
        steps.add(step);
        step.substituteConstantValues(constants);
    }

    /* Step Reporter: called by command line UI to report state of steps.
       does not run the controller
    */
    public void reportSteps(String[] desiredStates) throws Exception {
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

    // run the controller
    public void run(int numSteps) throws Exception {

	initHomeDir();		   // initialize workflow home directory

	initSteps();               // parse graph xml and config, and init db

	getDbSnapshot();	   //read state of Workflow and WorkflowSteps

	setRunningState(numSteps); // set db state. fail if already running

	// start polling
	while (true) {
	    getDbSnapshot();
	    if (handleStepChanges()) break;  // return true if all steps done
	    findOndeckSteps();
	    fillOpenSlots();
	    Thread.sleep(2000);
	}
    }

    private void initSteps() throws Exception {

        // make the parent/child links from the remembered dependencies
        for (WorkflowStep step : steps) {
            for (Name dependName : step.getDependsNames()) {
                String stepName = step.getName();
                WorkflowStep parent = stepsByName.get(dependName.getName());
                if (parent == null) 
                    Utilities.error("step '" + stepName + "' depends on '"
                          + dependName + "' which is not found");
                step.addParent(parent);
            }
        }

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

    // iterate through steps, checking on changes since last snapshot
    // while we're passing through, count how many steps are running
    private boolean handleStepChanges() throws SQLException, IOException, InterruptedException {

	runningCount = 0;
	boolean notDone = false;
	for (WorkflowStep step : steps) {
	    runningCount += step.handleChangesSinceLastSnapshot();
	    notDone |= !step.getState().equals(DONE);
	}
	if (!notDone) setDoneState();
	return !notDone;
    }

    private void findOndeckSteps() throws SQLException, IOException {
	for (WorkflowStep step : steps) {
	    step.maybeGoToOnDeck();
	}
    }

    private void fillOpenSlots() throws IOException, SQLException {
	for (WorkflowStep step : steps) {
	    if (runningCount >= allowed_running_steps) break;
	    runningCount += step.runOnDeckStep();
	}
    }

    // read and validate all steps config
    private void getStepsConfig() {
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

    private void initHomeDir() throws IOException {
	File stepsDir = new File(getHomeDir() + "/steps");
	if (!stepsDir.exists()) stepsDir.mkdir();
        File logsDir = new File(getHomeDir() + "/logs");
        if (!logsDir.exists()) logsDir.mkdir();
        log("Initializing workflow home directory '" + getHomeDir() + "'");
    }

    private void setRunningState(int numSteps) throws SQLException, IOException, java.lang.InterruptedException {

	if (state != null && state.equals(RUNNING)) {
	    String cmd = "ps -p " + process_id + "> /dev/null";
	    Process process = Runtime.getRuntime().exec(cmd);
	    process.waitFor();
	    if (process.exitValue() == 0)
		error("workflow already running (" + process_id + ")");
	}

	String processId = getProcessId(); 

	log("Setting workflow state to " + RUNNING
	        + " and allowed-number-of-running-steps to " 
	        + numSteps + " (process id = " + processId + ")");

	allowed_running_steps = numSteps;

	String sql = "UPDATE apidb.Workflow" + nl
	    + "SET state = '" + RUNNING + "', process_id = " + processId + ", allowed_running_steps = " + numSteps + nl
	    + "WHERE workflow_id = " + workflow_id;
	runSql(sql);
    }

    private void setDoneState() throws SQLException, IOException {

	String sql = "UPDATE apidb.Workflow"  
	    + " SET state = '" + DONE + "', process_id = NULL"  
	    + " WHERE workflow_id = " + getId();

	runSql(sql);
	log("Workflow " + DONE);
    }

    void log(String msg) throws IOException {
	if (noLog) return;

	String logFileName = getHomeDir() + "/logs/controller.log";
	PrintWriter writer = new PrintWriter(new FileWriter(logFileName, true));
	writer.println(msg);
	writer.close();
    }
    
    /*
     * from http://blog.igorminar.com/2007/03/one-more-way-how-to-get-current-pid-in.html
     */
    private String getProcessId() throws IOException {
        byte[] bo = new byte[100];
        String[] cmd = {"bash", "-c", "echo $PPID"};
        Process p = Runtime.getRuntime().exec(cmd);
        p.getInputStream().read(bo);
        return new String(bo).trim();
    }

    // not working yet
    /*
    private void documentStep() {

	  my ($self, $signal, $documentInfo, $doitProperty) = @_;

	  return if (!$self->{justDocumenting}
	  || ($doitProperty
	  && $self->{propertySet}->getProp($doitProperty) eq "no"));
	  
	  my $documenter = GUS::StepDocumenter->new($signal, $documentInfo);
	  $documenter->printXml();
    }
    */
    
    public String toString() {
        return "Constants" + nl + constants.toString() + nl + nl
        + "Steps" + nl + steps.toString();
    }
        
    public static void main(String[] args) throws Exception  {
        String cmdName = System.getProperty("cmdName");

        // parse command line
        Options options = declareOptions();
        String cmdlineSyntax = cmdName + " -h workflow_home_dir <-n allowed_running_steps | -q | -d <states> >";
        String cmdDescrip = "Run a workflow, or, print a report about a workflow.";
        CommandLine cmdLine =
            Utilities.parseOptions(cmdlineSyntax, cmdDescrip, getUsageNotes(), options, args);
                
        // get required homedir from cmd line
        String homeDirName = cmdLine.getOptionValue("h");
    
        // branch based on provided options
        if (cmdLine.hasOption("n")) {
            WorkflowXmlParser parser = new WorkflowXmlParser();
            Workflow workflow = parser.parseWorkflow(homeDirName);
            String numSteps = cmdLine.getOptionValue("n"); 
            workflow.run(Integer.parseInt(numSteps));
        } else if (cmdLine.hasOption("q")) {
            
        } else if (cmdLine.hasOption("d")) {
            WorkflowXmlParser parser = new WorkflowXmlParser();
            Workflow workflow = parser.parseWorkflow(homeDirName);
            String desiredStatesStr = cmdLine.getOptionValue("d"); 
            String[] desiredStates = desiredStatesStr.split(",");
            workflow.reportSteps(desiredStates);            
        } else if (cmdLine.hasOption("reset")) {
            Workflow workflow = new Workflow();
            workflow.setHomeDir(homeDirName);
            workflow.reset();
        } else {
            Utilities.usage(cmdlineSyntax, cmdDescrip, getUsageNotes(), options);
        }
        System.exit(0);
    }
    
    private static String getUsageNotes() {
        return
 
      "Home dir must contain the following:" + nl
    + "   config/" + nl
    + "     workflow.prop      (meta config)" + nl
    + "     steps.prop         (steps config)" + nl
    + "     stepsGlobal.prop   (global steps config)" + nl
    + "     resources.xml      [future]" + nl
    + nl                              
    + "Examples:" + nl
    + nl     
    + "  run a workflow:" + nl
    + "    % workflow workflow_dir 3" + nl
    + nl     
    + "  quick report of workflow state" + nl
    + "    % workflow workflow_dir -q" + nl
    + nl     
    + "  print detailed steps report." + nl
    + "    % workflow workflow_dir -d" + nl
    + nl     
    + "  limit steps report to steps in particular states" + nl
    + "    % workflow workflow_dir -d FAILED RUNNING" + nl
    + nl     
    + "  print steps report, using the optional offline flag to only include steps" + nl
    + "  that have the flag in the indicated state.  [not implemented yet]" + nl
    + "    % workflow workflow_dir -d0 ON_DECK" + nl
    + "    % workflow workflow_dir -d1 READY ON_DECK" + nl;
    }

    private static Options declareOptions() {
        Options options = new Options();

        Utilities.addOption(options, "h", "Workflow homedir (see below)");
        
        OptionGroup optionalOptions = new OptionGroup();
        Option numSteps = new Option("n", true,
             "Number of steps allowed to run simultaneously");
        optionalOptions.addOption(numSteps);
        
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
