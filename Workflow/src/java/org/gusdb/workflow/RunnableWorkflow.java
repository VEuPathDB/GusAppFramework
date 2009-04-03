package org.gusdb.workflow;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.io.File;

/*
   to do
   - integrate resource pipeline
   - possibly support taking DONE steps offline.  this will require recursion.
   - generate step documentation
   - whole system documentation
   - get manual confirm on -reset

  
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
    final static String nl = System.getProperty("line.separator");

    public RunnableWorkflow(String homeDir) throws FileNotFoundException, IOException {
        super(homeDir);
    }

    // run the controller
    void run(boolean testOnly) throws Exception {
        initHomeDir();             // initialize workflow home directory, if needed

        initDb(true, testOnly);    // write workflow to db, if not already there

        getStepsConfig();          // validate config of all steps.

        getDbSnapshot();           // read state of Workflow and WorkflowSteps

	readOfflineFile();         // read start-up offline requests
	
        readStopAfterFile();       // read start-up offline requests
        
	setRunningState(testOnly); // set db state. fail if already running

        initializeUndo(testOnly);  // unless undoStepName is null

	// start polling
	while (true) {
	    getDbSnapshot();
	    if (handleStepChanges(testOnly)) break;  // return true if all steps done
	    findOndeckSteps();
	    fillOpenSlots(testOnly);
	    Thread.sleep(2000);
	    cleanProcesses();
	}
    }

    private void initializeUndo(boolean testOnly) throws SQLException, IOException, InterruptedException {
        
        if (undo_step_id == null && undoStepName == null) return; 
         
        if (undoStepName == null) error("An undo is in progress.  Cannot run the workflow in regular mode.");

        // if not already running undo
        if (undo_step_id == null) {
            // confirm that no steps are running   
            handleStepChanges(testOnly);
            List<RunnableWorkflowStep> runningSteps = new ArrayList<RunnableWorkflowStep>();
            for (RunnableWorkflowStep step : workflowGraph.getSteps()) {
                if (step.getState() != null && step.getState().equals(RUNNING))
                    runningSteps.add(step);
            }
            if (runningSteps.size() != 0) {
                String errStr = null;
                for (RunnableWorkflowStep step: runningSteps) {
                    errStr += step.getFullName() + nl;
                }
                if (errStr != null)
                    error("The following steps are running.  Can't start an undo while steps are running.  Wait for all steps to complete (or kill them), and try to run undo again" + nl +errStr);
            }
            
            // set undo_step_id in workflow table         
            for (RunnableWorkflowStep step : workflowGraph.getSteps()) {
                if (step.getFullName().equals(undoStepName)) undo_step_id = step.getId();
            }
            if (undo_step_id == null) error("Step name '" + undoStepName + "' is not found");
            
            String sql = "UPDATE apidb.Workflow" + nl
            + "SET undo_step_id = '" + undo_step_id + "'" + nl
            + "WHERE workflow_id = " + workflow_id;
            executeSqlUpdate(sql);
        } 
        
        // if already running undo
        else {
            // confirm that step name does not conflict with current undo step
            for (RunnableWorkflowStep step : workflowGraph.getSteps()) {
                if (undo_step_id == step.getId() && !step.getFullName().equals(undoStepName))
                    error("Step '" + undoStepName + "' does not match '" + step.getFullName()
                            + "' which is currently the step being undone");
            }
        }
            
        // invert and trim graph
        workflowGraph.convertToUndo();
	log("vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv");
	log("Steps in the Undo Graph:");
	log(workflowGraph.getStepsAsString());
	log("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
    }

    // iterate through steps, checking on changes since last snapshot
    // while we're passing through, count how many steps are running
    private boolean handleStepChanges(boolean testOnly) throws SQLException, IOException, InterruptedException {

	runningCount = 0;
	boolean notDone = false;
	for (RunnableWorkflowStep step : workflowGraph.getSteps()) {
	    runningCount += step.handleChangesSinceLastSnapshot(this);
	    notDone |= !step.getOperativeState().equals(DONE);
	}
	if (!notDone) setDoneState(testOnly);
	return !notDone;
    }

    private void findOndeckSteps() throws SQLException, IOException {
	for (RunnableWorkflowStep step : workflowGraph.getSteps()) {
	    step.maybeGoToOnDeck();
	}
    }

    private void fillOpenSlots(boolean testOnly) throws IOException, SQLException {
	for (RunnableWorkflowStep step : workflowGraph.getSortedSteps()) {
	    String[] loadTypes = step.getLoadTypes();
	    boolean okToRun = true;
	    for (String loadType : loadTypes) {
	        if (filledSlots.get(loadType) != null && filledSlots.get(loadType) >= getLoadBalancingConfig(loadType)) {
	            okToRun = false;
	            break;
	        }
	    }
	    if (okToRun) {
	        int slotsUsed = step.runOnDeckStep(this, testOnly);	  
	        for (String loadType : loadTypes) {
	            Integer f = filledSlots.get(loadType);
	            f = f == null? 0 : f;
	            filledSlots.put(loadType, f + slotsUsed);
	        }
	    }
	}
    }

    private void readOfflineFile() throws IOException, java.lang.InterruptedException {
        readStepStateFile("initOfflineSteps", "offline");
    }

    private void readStopAfterFile() throws IOException, java.lang.InterruptedException {
        readStepStateFile("initStopAfterSteps", "stopafter");
    }

    private void readStepStateFile(String file, String state) throws IOException, java.lang.InterruptedException {
        String filename = getHomeDir() + "/config/" + file;
        File f = new File(filename);
        if (!f.exists()) error("Required config file " + filename + " does not exist");
        String[] cmd = {"workflowstep", "-h", getHomeDir(),
                        "-f", filename, state};
        Process process = Runtime.getRuntime().exec(cmd);
        process.waitFor();
	process.destroy();
    }


    private void setRunningState(boolean testOnly) throws SQLException, IOException, java.lang.InterruptedException {

        if (!test_mode && testOnly) error("Cannot run with '-t'.  Already running with '-r'");
        if (test_mode && !testOnly) error("Cannot run with '-r'.  Already running with '-t'");
        
	if (state != null && process_id != null && state.equals(RUNNING)) {
	    String[] cmd = {"ps", "-p", process_id};
	    Process process = Runtime.getRuntime().exec(cmd);
	    process.waitFor();
	    if (process.exitValue() == 0)
	        error("workflow already running (" + process_id + ")");
	    process.destroy();
	}

	String processId = getProcessId(); 

	if (testOnly) log("TESTING workflow....");

	log("Setting workflow state to " + RUNNING
	    + " (process id = " + processId + ")");
	System.err.println("Setting workflow state to " + RUNNING
	    + " (process id = " + processId + ")");

	String sql = "UPDATE apidb.Workflow" + nl
	    + "SET state = '" + RUNNING + "', process_id = " + processId + nl
	    + "WHERE workflow_id = " + workflow_id;
	executeSqlUpdate(sql);
    }

    private void setDoneState(boolean testOnly) throws SQLException, IOException {

        String doneFlag = "state = '" + DONE + "'";
        if (undo_step_id != null) doneFlag = "undo_step_id = NULL";

        String sql = "UPDATE apidb.Workflow "  
            + "SET " + doneFlag + ", process_id = NULL"  
            + " WHERE workflow_id = " + getId();
	executeSqlUpdate(sql);
	
	sql = "UPDATE apidb.WorkflowStep "
	    + "SET undo_state = NULL, undo_state_handled = 1 " 
	    + "WHERE workflow_id = " + workflow_id;
	executeSqlUpdate(sql); 
	
	String what = "Workflow";
	if (undo_step_id != null) what = "Undo of " + undoStepName;
	log(what + " " + (testOnly? "TEST " : "") + DONE);
    }

    /*
     * from http://blog.igorminar.com/2007/03/one-more-way-how-to-get-current-pid-in.html
     */
    private String getProcessId() throws IOException, InterruptedException {
        byte[] bo = new byte[100];
        String[] cmd = {"bash", "-c", "echo $PPID"};
        Process p = Runtime.getRuntime().exec(cmd);
	p.waitFor();
        p.getInputStream().read(bo);	
	p.destroy();
        return new String(bo).trim();
    }

}
