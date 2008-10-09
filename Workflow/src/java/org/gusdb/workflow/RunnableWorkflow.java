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

public class Workflow extends WorkflowBase {
    private boolean noLog;
    private int runningCount; 

    public Workflow() {}


    // run the controller
    private void run(int numSteps) throws Exception {

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


    ////////////////////////////////////////////////////////////////////////
    //           Static methods
    ////////////////////////////////////////////////////////////////////////
        
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
            WorkflowGraph workflowGraph = parser.parseWorkflow(homeDirName);
            String numSteps = cmdLine.getOptionValue("n"); 
            RunnableWorkflow runnableWorkflow = new RunnableWorkflow(workflowGraph);
            runnableWorkflow.run(Integer.parseInt(numSteps));
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
