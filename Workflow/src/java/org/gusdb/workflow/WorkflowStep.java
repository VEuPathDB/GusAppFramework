package org.gusdb.workflow;

/*

  the following "state diagram" shows allowed state transitions by
  different parts of the system
 
  controller
   READY   --> ON_DECK
   RUNNING --> FAILED (if wrapper itself dies, ie, controller can't find PID)
   (state_handled --> true)

  step invoker
   ON_DECK --> RUNNING
   RUNNING --> DONE | FAILED
   (state_handled --> false)

  Pilot UI (GUI or command line)
   RUNNING    --> FAILED  (or, just kill the process and let the controller change the state)
   FAILED     --> READY  (ie, the pilot has fixed the problem)
   (state_handled --> false)
   [note: going from done to ready is the provence of undo]

  Pilot UI (GUI or command line)
   OFFLINE --> 1/0  (change not allowed if step is running)

*/

public class WorkflowStep {

    String stepName;
    String workflow;
    String invokerClassName;
    List<WorkflowStep> parents = new ArrayList<WorkflowStep>();
    String fakeStepType;

    public WorkflowStep(String stepName, Workflow workflow, String invokerClassName) {
	this.name = stepName;
	this.workflow = workflow;
	this.invokerClassName = invokerClassName;
    }


    void addParent(WorkflowStep parent) {
	parents.add(parentStep);
    }

    List<WorkflowStep> getParents() {
	return parents;
    }

    String getName() {
	return name;
    }

    String getInvokerClassName {
    return invokerClassName;
    }

    int getId () {
	getDbStateFromSnapshot();
	return workflow_step_id;
    }

    String getState () {
	getDbStateFromSnapshot();
	return fakeStepType.equals(START)? DONE : state;
    }

    static PreparedStatement getPreparedInsertStmt(Connection dbConnection, int workflowId) {
	String sql = "INSERT INTO apidb.workflowstep (workflow_step_id, workflow_id, name, state, state_handled, off_line)"
	    + "VALUES (apidb.workflowstep_sq.nextval, " + workflowId + ", ?, ?, 1, 0)";
	return dbConnection.prepareStatement(sql);
    }

    // write this step to the db, if not already there.
    // called during workflow initialization
    void initializeStepTable(PreparedStatement stmt) {
	String state = fakeStepType.equals(START) DONE : READY;
	stmt.executeUpdate(name, state);
    }

    static PreparedStatement getPreparedDependsStmt(Connection dbConnection) {

	String sql= "INSERT INTO apidb.workflowstepdependency (workflow_step_dependency_id, parent_id, child_id)" + nl
	"VALUES (apidb.workflowstepdependency_sq.nextval, ?, ?)";
	return dbConnection.prepareStatement(sql);
    }

    void initializeDependsTable(PreparedStatement stmt) {
	for (WorkflowStep parentStep : getParents()) {
	    stmt.executeUpdate(parentStep.getId(), getId());
	}
    }

    // for fake start and end steps that are forced into the graph
    void setFakeStepType(String type) {
	fakeStepType = type;
	if (type.equals(END)) state = READY; 
    }

    boolean handleChangesSinceLastSnapshot() {
	String prevState = workflow.getPrevStepsSnapshot().get(name).get(STATE);
	String prevOffline = workflow.getPrevStepsSnapshot().get(name).get(OFF_LINE);

	getDbStateFromSnapshot();

	if (state_handled) {
	    if (state eq $RUNNING) {
		/* FIX 
		system("ps -p $self->{process_id} > /dev/null");
		my $status = $? >> 8;
		if ($status) {
		    $self->handleMissingProcess();
		}
		*/
	    }
	} else { // this step has been changed by wrapper or pilot UI. log change.
	    String stateMsg = "";
	    String offlineMsg = "";
	    if (!state.equals(prevState)) stateMsg = "  " + state;
	    if(!off_line.equals(prevOffline)) {
		offlineMsg = off_line? "  OFFLINE" : "  ONLINE";
	    }

	    log("Step '" + name + "'" + stateMsg + offlineMsg);
	    setHandledFlag();
	}
	return state.equals(RUNNING);
    }

    // static method
    static String getBulkSnapshotSql(int workflow_id) {
	return "SELECT workflow_step_id, name, host_machine, process_id, state, state_handled, off_line, start_time, end_time" + nl
	    + "FROM apidb.workflowstep"
	    + "WHERE workflow_id = " + workflow_id;
    }

    void getDbStateFromSnapshot() {

	if (fakeStepType != null) return;
	if (snapshotNum == workflow.getSnapshotNum()) return;

	snapshotNum = workflow.getSnapshotNum();

	Map<String, Object> snapshot = workflow.getStepsSnapshot().get(name);
	for (String key :snapshot.getKeySet()) {
	    /* FIX
	    $self->{lc($key)} = $snapshot->{$key};
	    */
	}
    }

    void setHandledFlag {
	// check that state is still as expected, to avoid theoretical race condition
	String sql = "UPDATE apidb.WorkflowStep" + nl
	    + "SET state_handled = 1"
	    + "WHERE workflow_step_id = " + workflow_step_id
	    + "AND state = '" + state + "'"
	    + "AND off_line = " + off_line;
	runSql(sql);
	state_handled = 1;  // till next snapshot
    }

sub handleMissingProcess {
    my ($self) = @_;

    my $sql = "
UPDATE apidb.WorkflowStep
SET 
  state = '$FAILED',
  state_handled = 1,
  process_id = NULL
WHERE workflow_step_id = $self->{workflow_step_id}
AND state = '$RUNNING'
";
    $self->runSql($sql);
    $self->log("Step '$self->{name}' $FAILED (can't find wrapper process $self->{process_id})");
}

// if this step is ready, and all parents are done, transition to ON_DECK
sub maybeGoToOnDeck {
    my ($self) = @_;

    return unless $self->{state} eq $READY && !$self->{off_line};

    foreach my $parent (@{$self->getParents()}) {
	return unless $parent->getState() eq $DONE;
    }

    $self->log("Step '$self->{name}' $ON_DECK");

    my $sql = "
UPDATE apidb.WorkflowStep
SET 
  state = '$ON_DECK',
  state_handled = 1
WHERE workflow_step_id = $self->{workflow_step_id}
AND state = '$READY'
";
    $self->runSql($sql);
}

// try to run a single ON_DECK step
sub runOnDeckStep {
    my ($self) = @_;

    if ($self->{state} eq $ON_DECK && !$self->{off_line}) {
	$self->forkAndRun();
	return 1;
    } 
    return 0;
}

sub getStepDir {
  my ($self) = @_;

  if (!$self->{stepDir}) {
    my $homeDir = $self->{workflow}->getHomeDir();
    my $stepDir = "$homeDir/steps/$self->{name}";
    $self->{workflow}->runCmd("mkdir -p $stepDir") unless -e $stepDir;
    $self->{stepDir} = $stepDir;
  }
  return $self->{stepDir};
}

sub forkAndRun {
    my ($self) = @_;

    my $homeDir = $self->{workflow}->getHomeDir();
    my $workflowId = $self->{workflow}->getId();
    my $stepDir = $self->getStepDir();
    my $err = "$stepDir/step.err";

    $self->log("Invoking step '$self->{name}'");
    system("workflowstepwrap $homeDir $workflowId $self->{name} '$self->{invokerClass}' 2>> $err &");
}


//////////////////////////////////////////////////  utilities ////////////////////////////////////////////////////////////////////////////////////

sub log {
    my ($self,$msg) = @_;
    $self->{workflow}->log($msg);
}

sub runSql {
    my ($self,$sql) = @_;
    $self->{workflow}->runSql($sql);
}

sub toString {
    my ($self) = @_;

    my @parentsNames;
    foreach my $parent (@{$self->getParents()}) {
	push(@parentsNames, $parent->getName());
    }

    my $depends = join(", ", @parentsNames);
    return "
name:       $self->{name}
id:         $self->{workflow_step_id}
state:      $self->{state}
off_line:   $self->{off_line}
handled:    $self->{state_handled}
process_id: $self->{process_id}
start_time: $self->{start_time}
end_time:   $self->{end_time}
depends:    $depends
";
}

1;
