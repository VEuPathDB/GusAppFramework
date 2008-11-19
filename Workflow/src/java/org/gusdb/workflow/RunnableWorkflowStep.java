package org.gusdb.workflow;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class RunnableWorkflowStep extends WorkflowStep {
    
    int handleChangesSinceLastSnapshot(Workflow<RunnableWorkflowStep> workflow) throws SQLException, IOException, InterruptedException  {
        if (state_handled) {
            if (state.equals(Workflow.RUNNING)) {               
                String cmd = "ps -p " + process_id;
                Process process = Runtime.getRuntime().exec(cmd);
                process.waitFor();
                if (process.exitValue() != 0) handleMissingProcess();
            }
        } else { // this step has been changed by wrapper or pilot UI. log change.
            String stateMsg = "";
            String offlineMsg = "";
            if (!state.equals(prevState)) stateMsg = "  " + state;
            if(off_line != prevOffline) {
                offlineMsg = off_line? "  OFFLINE" : "  ONLINE";
            }

            log("Step '" + getFullName() + "'" + stateMsg + offlineMsg);
            setHandledFlag();
        }
        return state.equals(Workflow.RUNNING)? 1 : 0;
    }

    private void setHandledFlag() throws SQLException, FileNotFoundException, IOException {
        // check that state is still as expected, to avoid theoretical race condition

        int offlineInt = off_line? 1 : 0;
        String sql = "UPDATE apidb.WorkflowStep"  
            + " SET state_handled = 1"
            + " WHERE workflow_step_id = " + workflow_step_id
            + " AND state = '" + state + "'"
            + " AND off_line = " + offlineInt;
        executeSqlUpdate(sql);
        state_handled = true;  // till next snapshot
    }

    private void handleMissingProcess() throws SQLException, IOException {
        String sql = "SELECT state" 
            + " FROM apidb.workflowstep"
            + " WHERE workflow_step_id = " + workflow_step_id;
        
        Statement stmt = null;
        ResultSet rs = null;
        try {
            stmt = workflowGraph.getWorkflow().getDbConnection().createStatement();
            rs = stmt.executeQuery(sql);
            rs.next();
            String stateNow = rs.getString(1);
            if (stateNow.equals(Workflow.RUNNING)) {
                sql = "UPDATE apidb.WorkflowStep"  
                    + " SET"  
                    + " state = '" + Workflow.FAILED + "', state_handled = 1, process_id = null" 
                    + " WHERE workflow_step_id = " + workflow_step_id
                    + " AND state = '" + Workflow.RUNNING + "'";
                executeSqlUpdate(sql);
                log("Step '" + getFullName() + "' FAILED (no wrapper process " + process_id + ")");
            }
        } finally {
            if (rs != null) rs.close();
            if (stmt != null) stmt.close();
        }
    }
        
    // if this step is ready, and all parents are done, transition to ON_DECK
    void maybeGoToOnDeck() throws SQLException, IOException {
 
        if (!state.equals(Workflow.READY) || off_line) return;

        for (WorkflowStep parent : getParents()) {
            if (!parent.getState().equals(Workflow.DONE)) return;
        }

        log("Step '" + getFullName() + "' " + Workflow.ON_DECK);

        String sql = "UPDATE apidb.WorkflowStep"  
            + " SET state = '" + Workflow.ON_DECK + "', state_handled = 1" 
            + " WHERE workflow_step_id = " + workflow_step_id  
            + " AND state = '" + Workflow.READY + "'";
        executeSqlUpdate(sql);
    }

    // if this step doesn't have an invoker (ie, it is a call to or return
    // from a subgraph), just go to done
    void goToDone() throws SQLException, IOException {
 
        String sql = "UPDATE apidb.WorkflowStep"  
            + " SET state = '" + Workflow.DONE + "', state_handled = 1" 
            + " WHERE workflow_step_id = " + workflow_step_id;  
        executeSqlUpdate(sql);
    }

    // try to run a single ON_DECK step
    int runOnDeckStep(Workflow<RunnableWorkflowStep> workflow, boolean testOnly) throws IOException, SQLException {
        if (state.equals(Workflow.ON_DECK) && !off_line) {
	    if (invokerClassName == null) {
		if (subgraphXmlFileName != null)
		    log("Step '" + getFullName() + "' " + Workflow.DONE
			+ " -- called '" + subgraphXmlFileName + "'");
		else log("Step '" + getFullName() + "' " + Workflow.DONE);
		goToDone();		
	    } else {
		String[] cmd = {"workflowstepwrap", workflow.getHomeDir(),
				workflow.getId().toString(),
				getFullName(), invokerClassName,
				getStepDir() + "/step.err",
				testOnly? "test" : "run"}; 

		List<String> cmd2 = new ArrayList<String>();
		Collections.addAll(cmd2, cmd);
		for (String name : paramValues.keySet()) {
		    String valueStr = paramValues.get(name);
		    valueStr = valueStr.replaceAll("\"", "\\\\\""); 
		    cmd2.add("-" + name);
		    cmd2.add(valueStr);
		}
		log("Invoking step '" + getFullName() + "'" );
		Runtime.getRuntime().exec(cmd2.toArray(new String[] {}));
	    }
            return 1;
        } 
        return 0;
    }

    private void log(String msg) throws IOException {
        workflowGraph.getWorkflow().log(msg);
    }

    WorkflowStep newStep() {
        return new RunnableWorkflowStep();
    }


}
