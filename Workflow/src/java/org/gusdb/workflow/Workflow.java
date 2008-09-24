package org.gusdb.workflow;

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
   one of these which could realistically happen in the timeframe of a cycle
   is the transition from RUNNING to DONE, if a step executes quickly.  In this
   case, the log will show only DONE, without ever showing RUNNING, which is ok.
  
   and also the problem of (b) that the controller could not write the step's
   state because the state had changed since the snapshot.  the controller
   only writes the ON_DECK and FAILED states.  the next cycle will handle
   these correctly.
*/

public class Workflow extends WorkflowBase {
    private Array<WorkflowStep> steps;
    private Map<String, WorkflowStep> stepsByName;
    private String name;
    private String version;
    private String workflow_id;
    private String homeDir;
    private final static String nl = System.getProperty("line.separator");

    /* Step Reporter: called by command line UI to report state of steps.
       does not run the controller
    */
    public void reportSteps(String[] desiredStates) {
	noLog(true);

	initSteps();

	getDbSnapshot();      // read state of Workflow and WorkflowSteps

	reportState();

	Array<String> sortedStepNames = stepsByNames.getKeys().sort(); 

	if (desiredStates.length == 0) {
	    desiredStates = [READY, ON_DECK, RUNNING, DONE, FAILED];
	}
	for (String desiredState : desiredStates) {
	    System.out.println("=============== " 
			       + desiredState steps
			       + "================");
	    for (String stepName : sortedStepNames) {
		WorkflowStep step = stepsByName.get(stepName};
		if (step.getState().equals(desiredState)) {
		    System.out.println(step.toString());
		    System.out.println(stepsConfig.toString(stepName));
		    System.out.println("-----------------------------------------");
		}
	    }
	}
    }

    // run the controller
    public void run(int numSteps) {

	initHomeDir();		   // initialize workflow home directory

	initSteps();               // parse graph xml and config, and init db

	getDbSnapshot();	   //read state of Workflow and WorkflowSteps

	setRunningState(numSteps); // set db state. fail if already running

	// start polling
	while (true) {
	    getDbSnapshot();
	    if (handleStepChanges()) last;  // return true if all steps done
	    findOndeckSteps();
	    fillOpenSlots();
	    wait(2000);
	}
    }

    private void initSteps() {

	getStepGraph();        // parses workflow XML, validates graph

	initDb();              // write workflow to db, if not already there

	getStepsConfig();      // validate config of all steps.
    }

    // traverse a workflow XML, making Step objects as we go
    private void getStepGraph () {
	if (!stepsByName) {
	    String fileName = getWorkflowConfig('workflowFile');
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
	    // dependenceies
	    for (WorkflowStep step : steps) {
		for (String dependName : step.getDependsNames()) {
		    String stepName = step.getName();
		    WorkflowStep parent = stepsByName.get(dependName};
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
    private void initDb {

	name = getWorkflowConfig("name");
	version = getWorkflowConfig("version");

	// don't bother if already in db
	String sql = "select workflow_id" + nl
	    + "from apidb.workflow" + nl
	    + "where name = " + "'" + name + "'"  + nl
	    + "and version = '" + version + "'";

	String workflow_id_tmp = runSqlQuery_single_array(sql);

	if (workflow_id_tmp != null) return;

	// otherwise, do it...
	log("Initializing workflow "
	    + "'" + name + " " + version + "' in database");

	// write row to Workflow table
	sql = "select apidb.Workflow_sq.nextval from dual";
	workflow_id = runSqlQuery_single_array(sql);

	sql = "INSERT INTO apidb.workflow (workflow_id, name, version)" + nl
	    + "VALUES (" + workflow_id + ", '" + name + "', '" + version + ")";
	runSql(sql);

	// write all steps to WorkflowStep table
	stmt = WorkflowStep.getPreparedInsertStmt(getDbh(), workflow_id);
	for (WorkflowStep step : steps) {
	    step->initializeStepTable(stmt);
	}

	// update steps in memory, to get their new IDs
	getWorkflowStepsDbSnapshot();
    }

    private void getDbSnapshot() {
	getWorkflowDbSnapshot();
	getWorkflowStepsDbSnapshot();
    }

    private void getWorkflowDbSnapshot() {
	if (workflow_id == null) {
	    name = getWorkflowConfig("name");
	    version = getWorkflowConfig("version");
	    String sql = "select workflow_id, state, process_id, start_time, end_time, allowed_running_steps" + nl
		+ "from apidb.workflow" + nl
		+ "where name = '" + name + "'"
		+ "and version = '" + version + "'";

	ResultSet rs = runSqlQuery_single_array(sql);
	workflow_id = rs.getInt(1);
	state = rs.getString(2);
	process_id = rs.getInt(3);
	start_time = rs.getDate(4);
	end_time = rs.getDate(5);
	allowed_running_steps = rs.getInt(6);

	if (workflow_id == null) 
	    error("workflow '" + name + "' version '" + version + "' not in database")
  }
}

    // read all WorkflowStep rows into memory (and remember the prev snapshot)
    private void getWorkflowStepsDbSnapshot() {
	snapshotNum++;   // identifier of this snapshot
	prevStepsSnapshot = stepsSnapshot;
	stepsSnapshot = new HashMap();

	String sql = WorkflowStep.getBulkSnapshotSql(workflow_id);

	// run query to get all rows from WorkflowStep for this workflow
	// stuff each row into the snapshot, keyed on step name
	Statement stmt = getDbh().prepare(sql);
	stmt.execute();
	/*
	  while (my $rowHashRef = $stmt->fetchrow_hashref()) {
	  $self->{stepsSnapshot}->{$rowHashRef->{NAME}} = $rowHashRef;
	  }
	*/
    }

    // iterate through steps, checking on changes since last snapshot
    // while we're passing through, count how many steps are running
    private void handleStepChanges() {

	runningCount = 0;
	boolean notDone = false;
	for (WorkflowStep step : steps) {
	    runningCount += step.handleChangesSinceLastSnapshot();
	    notDone |= !step.getState().equals(DONE);
	}
	if (!notDone) setDoneState();
	return !notDone;
    }

    private void findOndeckSteps {
	for (WorkflowStep step : steps) {
	    step.maybeGoToOnDeck();
	}
    }

    private void fillOpenSlots() {
	for (WorkflowStep step : steps) {
	    if (runningCount >= allowed_running_steps) last;
	    runningCount += step.runOnDeckStep();
	}
    }

    // read and validate all steps config
    private void getStepsConfig {
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

    private void initHomeDir {
	String homeDir = getHomeDir();
	/* FIX
	if () return if -e "$homeDir/steps";
  $self->runCmd("mkdir -p $homeDir/logs") unless -e "$homeDir/logs";
  $self->runCmd("mkdir -p $homeDir/steps") unless -e "$homeDir/steps";
  $self->runCmd("mkdir -p $homeDir/externalFiles") unless -e "$homeDir/externalFiles";
  $self->log("Initializing workflow home directory '$homeDir'");
	*/
    }

    private void setRunningState(int numSteps) {

	if (state.equals(RUNNING)) {
	    system("ps -p $self->{process_id} > /dev/null");
	    my $status = $? >> 8;
	    if (!$status) {
		$self->error("workflow already running (process $self->{process_id})");
	    }
	}
	int processId = 0; // FIX
	log("Setting workflow state to " + RUNNING + "and allowed-number-of-running-steps to " + numSteps + " (process id = " + processId + ")");

	allowed_running_steps = numSteps;

	String sql = "UPDATE apidb.Workflow" + nl
	    + "SET state = '" + RUNNING + "', process_id = " + processId + ", allowed_running_steps = " + numSteps + nl
	    + "WHERE workflow_id = " + workflow_id;
	runSql(sql);
    }

    private void setDoneState {

	String sql = "UPDATE apidb.Workflow" + nl
	    + "SET state = '" + DONE + "', process_id = NULL" + nl
	    + "WHERE workflow_id = " + getId();

	runSql(sql);
	log("Workflow " + DONE);
    }


    private sub getId {
	return workflow_id;
    }

    private void log(String msg) {
	if (noLog) return;

	Strig homeDir = getHomeDir();
	/* FIX
	   open(LOG, ">>$homeDir/logs/controller.log")
	   || die "can't open log file '$homeDir/logs/controller.log'";
	   print LOG localtime() . " $msg\n\n";
	   close (LOG);
	*/
    }

    // not working yet
    private void documentStep {
	/*
	  my ($self, $signal, $documentInfo, $doitProperty) = @_;

	  return if (!$self->{justDocumenting}
	  || ($doitProperty
	  && $self->{propertySet}->getProp($doitProperty) eq "no"));
	  
	  my $documenter = GUS::StepDocumenter->new($signal, $documentInfo);
	  $documenter->printXml();
	*/
    }

    private void runCmd(String cmd) {
	/* FIX
    my $output = `$cmd`;
    my $status = $? >> 8;
    $self->error("Failed with status $status running: \n$cmd") if ($status);
    return $output;
	*/
    }
}