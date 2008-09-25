package org.gusdb.workflow;

import java.io.PrintWriter;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

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
    private List<WorkflowStep> steps;
    private Map<String, WorkflowStep> stepsByName;
    private boolean noLog;
    private int runningCount;
    private Date start_time;
    private Date end_time;
    private int snapshotNum;
    private List<Map<String,Object>>stepsSnapshot;
    private List<Map<String,Object>>prevStepsSnapshot;   

    /* Step Reporter: called by command line UI to report state of steps.
       does not run the controller
    */
    public void reportSteps(String[] desiredStates) throws SQLException {
	noLog = true;

	initSteps();

	getDbSnapshot();      // read state of Workflow and WorkflowSteps

	reportState();

	String sortedStepNames[] = (String[])stepsByName.keySet().toArray(); 
	Arrays.sort(sortedStepNames);

	if (desiredStates.length == 0) {
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
    public void run(int numSteps) throws InterruptedException, SQLException {

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
	    wait(2000);
	}
    }

    private void initSteps() throws SQLException {

	getStepGraph();        // parses workflow XML, validates graph

	initDb();              // write workflow to db, if not already there

	getStepsConfig();      // validate config of all steps.
    }

    // traverse a workflow XML, making Step objects as we go
    private void getStepGraph () {
	if (stepsByName == null) {
	    String fileName = getWorkflowConfig("workflowFile");
	    String workflowXmlFile = System.getenv("GUS_HOME") 
		+ "/lib/xml/workflow/" + fileName;

	    log("Parsing and validating" + workflowXmlFile);

	    /*
	    // parse the XML.
	    // use forcearray so elements with one child are still arrays
	    my $simple = XML::Simple->new();
	    my $data = $simple->XMLin($workflowXmlFile, forcearray => 1,
				      KeyAttr => {sqlValue=>'+name'});

	   // make each step object, remembering dependencies as a string
	   foreach my $stepxml (@{$data->{step}}) {
	   $self->error("non-unique step name: '$stepxml->{name}'")
	   if ($self->{stepsByName}->{$stepxml->{name}});
	   
	   my $step = GUS::Workflow::WorkflowStep->
	   new($stepxml->{name}, $self, $stepxml->{class});

	   push(@{$self->{steps}}, $step);  // in future, this should be ordered
                                       // by depth-first position
				       $self->{stepsByName}->{$stepxml->{name}} = $step;
				       $step->{dependsNames} = $stepxml->{depends};
				       }
	    */

	    // in second pass, make the parent/child links from the remembered
	    // dependencies
	    for (WorkflowStep step : steps) {
		for (String dependName : step.getDependsNames()) {
		    String stepName = step.getName();
		    WorkflowStep parent = stepsByName.get(dependName);
		    if (parent == null) 
			error("step '" + stepName + "' depends on '"
			      + dependName + "' which is not found");
		    step.addParent(parent);
		}
	    }
	}
    }

    // write the workflow and steps to the db
    // for now, assume the workflow steps don't change over the life of a workflow
    private void initDb() throws SQLException {

	name = getWorkflowConfig("name");
	version = getWorkflowConfig("version");

	// don't bother if already in db
	String sql = "select workflow_id" + nl
	    + "from apidb.workflow" + nl
	    + "where name = " + "'" + name + "'"  + nl
	    + "and version = '" + version + "'";

	Integer workflow_id_tmp = runSqlQuerySingleRow(sql).getInt(1);

	if (workflow_id_tmp != null) return;

	// otherwise, do it...
	log("Initializing workflow "
	    + "'" + name + " " + version + "' in database");

	// write row to Workflow table
        sql = "select apidb.Workflow_sq.nextval from dual";
        Integer workflow_id = runSqlQuerySingleRow(sql).getInt(1);

	sql = "INSERT INTO apidb.workflow (workflow_id, name, version)" + nl
	    + "VALUES (" + workflow_id + ", '" + name + "', '" + version + ")";
	runSql(sql);

	// write all steps to WorkflowStep table
	PreparedStatement stmt = WorkflowStep.getPreparedInsertStmt(dbConnection, workflow_id);
	for (WorkflowStep step : steps) {
	    step.initializeStepTable(stmt);
	}

	// update steps in memory, to get their new IDs
	getWorkflowStepsDbSnapshot();
    }

    private void getDbSnapshot() throws SQLException {
	getWorkflowDbSnapshot();
	getWorkflowStepsDbSnapshot();
    }

    private void getWorkflowDbSnapshot() throws SQLException {
	if (workflow_id == null) {
	    name = getWorkflowConfig("name");
	    version = getWorkflowConfig("version");
	    String sql = "select workflow_id, state, process_id, start_time, end_time, allowed_running_steps" + nl
		+ "from apidb.workflow" + nl
		+ "where name = '" + name + "'"
		+ "and version = '" + version + "'";

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

    // read all WorkflowStep rows into memory (and remember the prev snapshot)
    private void getWorkflowStepsDbSnapshot() throws SQLException {
	String sql = WorkflowStep.getBulkSnapshotSql(workflow_id);

	// run query to get all rows from WorkflowStep for this workflow
	// stuff each row into the snapshot, keyed on step name
	Statement stmt = dbConnection.createStatement();
	ResultSet rs = stmt.executeQuery(sql);
	while (rs.next()) {
	    String stepName = rs.getString("NAME");
	    WorkflowStep step = stepsByName.get(stepName);
	    step.setFromDbSnapshot(rs);
	}
    }

    // iterate through steps, checking on changes since last snapshot
    // while we're passing through, count how many steps are running
    private boolean handleStepChanges() throws SQLException {

	runningCount = 0;
	boolean notDone = false;
	for (WorkflowStep step : steps) {
	    runningCount += step.handleChangesSinceLastSnapshot();
	    notDone |= !step.getState().equals(DONE);
	}
	if (!notDone) setDoneState();
	return !notDone;
    }

    private void findOndeckSteps() throws SQLException {
	for (WorkflowStep step : steps) {
	    step.maybeGoToOnDeck();
	}
    }

    private void fillOpenSlots() {
	for (WorkflowStep step : steps) {
	    if (runningCount >= allowed_running_steps) break;
	    runningCount += step.runOnDeckStep();
	}
    }

    // read and validate all steps config
    private void getStepsConfig() {
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
		    */
		}
		stepConfigDecl.put(step.getName(), 
				   invokerClassConfigDecl.get(invokerClassName));
	    }

	    // this object does the validation
	    /* FIX
	       $self->{stepsConfig} =
	       CBIL::Util::MultiPropertySet->new($stepsConfigFile, $stepsConfigDecl);
	    */
	}
	return stepsConfig;
    }

    private void initHomeDir() {
	String homeDir1 = getHomeDir();
	/* FIX
	if () return if -e "$homeDir/steps";
  $self->runCmd("mkdir -p $homeDir/logs") unless -e "$homeDir/logs";
  $self->runCmd("mkdir -p $homeDir/steps") unless -e "$homeDir/steps";
  $self->runCmd("mkdir -p $homeDir/externalFiles") unless -e "$homeDir/externalFiles";
  $self->log("Initializing workflow home directory '$homeDir'");
	*/
    }

    private void setRunningState(int numSteps) throws SQLException {

	if (state.equals(RUNNING)) {
	    /* FIX
	    system("ps -p $self->{process_id} > /dev/null");
	    my $status = $? >> 8;
	    if (!$status) {
		$self->error("workflow already running (process $self->{process_id})");
	    }
	    */
	}
	int processId = 0; // FIX
	log("Setting workflow state to " + RUNNING + "and allowed-number-of-running-steps to " + numSteps + " (process id = " + processId + ")");

	allowed_running_steps = numSteps;

	String sql = "UPDATE apidb.Workflow" + nl
	    + "SET state = '" + RUNNING + "', process_id = " + processId + ", allowed_running_steps = " + numSteps + nl
	    + "WHERE workflow_id = " + workflow_id;
	runSql(sql);
    }

    private void setDoneState() throws SQLException {

	String sql = "UPDATE apidb.Workflow" + nl
	    + "SET state = '" + DONE + "', process_id = NULL" + nl
	    + "WHERE workflow_id = " + getId();

	runSql(sql);
	log("Workflow " + DONE);
    }

    void log(String msg) {
	if (noLog) return;

	String logFileName = getHomeDir() + "/logs/controller.log";
	PrintWriter writer = new PrintWriter(new FileWriter(logFileName));
	writer.println(msg);
	writer.close();
    }

    // not working yet
    private void documentStep() {
	/*
	  my ($self, $signal, $documentInfo, $doitProperty) = @_;

	  return if (!$self->{justDocumenting}
	  || ($doitProperty
	  && $self->{propertySet}->getProp($doitProperty) eq "no"));
	  
	  my $documenter = GUS::StepDocumenter->new($signal, $documentInfo);
	  $documenter->printXml();
	*/
    }

}