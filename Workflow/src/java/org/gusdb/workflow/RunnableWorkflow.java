package org.gusdb.workflow;

import java.io.IOException;
import java.sql.SQLException;

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

public class RunnableWorkflow extends Workflow<RunnableWorkflowStep>{
    private int runningCount;
    private WorkflowGraph<RunnableWorkflowStep> workflowGraph;
    final static String nl = System.getProperty("line.separator");

    public RunnableWorkflow(String homeDir) {
        super(homeDir);
    }

    void setWorkflowGraph(WorkflowGraph<RunnableWorkflowStep> workflowGraph) {
        this.workflowGraph = workflowGraph;
        setWorkflowGraph(workflowGraph);
    }
    
    // run the controller
    void run(int numSteps, boolean testOnly) throws Exception {
        initHomeDir();         // initialize workflow home directory, if needed

        initDb();              // write workflow to db, if not already there

        getStepsConfig();      // validate config of all steps.

        getDbSnapshot();       // read state of Workflow and WorkflowSteps

	setRunningState(numSteps);      // set db state. fail if already running

	// start polling
	while (true) {
	    getDbSnapshot();
	    if (handleStepChanges()) break;  // return true if all steps done
	    findOndeckSteps();
	    fillOpenSlots(testOnly);
	    Thread.sleep(2000);
	}
    }


    // iterate through steps, checking on changes since last snapshot
    // while we're passing through, count how many steps are running
    private boolean handleStepChanges() throws SQLException, IOException, InterruptedException {

	runningCount = 0;
	boolean notDone = false;
	for (RunnableWorkflowStep step : workflowGraph.getSteps()) {
	    runningCount += step.handleChangesSinceLastSnapshot(this);
	    notDone |= !step.getState().equals(DONE);
	}
	if (!notDone) setDoneState();
	return !notDone;
    }

    private void findOndeckSteps() throws SQLException, IOException {
	for (RunnableWorkflowStep step : workflowGraph.getSteps()) {
	    step.maybeGoToOnDeck();
	}
    }

    private void fillOpenSlots(boolean testOnly) throws IOException, SQLException {
	for (RunnableWorkflowStep step : workflowGraph.getSteps()) {
	    if (runningCount >= allowed_running_steps) break;
	    runningCount += step.runOnDeckStep(this, testOnly);
	}
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
}