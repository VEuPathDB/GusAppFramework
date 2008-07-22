package GUS::Pipeline::WorkflowStep;

my $READY = 'ready';      # my parents are not done yet  -- default state
my $ON_DECK = 'on_deck';  # my parents are done, but there is no slot for me
my $DO_NOT_RUN = 'do_not_run';  # pilot doesn't want this step to start
my $FAILED = 'failed';
my $DONE = 'done';

# controller
#  READY   --> ON_DECK
#  RUNNING --> FAILED (if wrapper itself dies, ie, controller can't find PID)
#  (state_handled --> true)

# wrapper
#  ON_DECK --> RUNNING
#  RUNNING --> DONE
#  RUNNING --> FAILED
#  (state_handled --> false)

# Pilot UI (GUI or command line)
#  READY      --> DO_NOT_RUN
#  ON_DECK    --> DO_NOT_RUN
#  RUNNING    --> FAILED  (or, just kill the process and let the controller change the state)
#  DO_NOT_RUN --> READY
#  FAILED     --> READY  (ie, the pilot has fixed the problem)
#  (state_handled --> false)
#  [note: going from done to ready is the provence of undo]


sub new {
  my ($class, $workflow, $stepName) = @_;

  my $self = { 
      workflow => $workflow,
      name => $stepName,
      children => []
	  
  };

  bless($self,$class);
  return $self;
}

############## called by controller ###################################

sub addChild {
    my ($self, $childStep) = @_;
    push(@{$self->{children}}, $childStep);
    $childStep->addParent($self);
}

sub addParent {
    my ($self, $parentStep) = @_;
    push(@{$self->{parents}}, $parentStep);
}

sub getChildren {
    my ($self) = @_;
    return $self->{children};
}

# get a single configuration property value
sub getConfig {
    my ($self, $propName) = @_;
    return $self->{workflow}->getStepConfig($self, $propName);
}

sub getName {
    my ($self) = @_;
    return $self->{name};
}

sub getId () {
    my ($self) = @_;

    my $name = $self->getName();
    my $workflow_id = $self->{workflow}->getId();
    my $sql = "
select workflow_step_id from workflowstep 
where name = $name 
and workflow_id = $workflow_id
";
    my ($id) =  runSqlQuery_single_array($sql);
    return $id;
}

# write this step to the db, if not already there.
sub initializeStepTable {
    my ($self, $stmt) = @_;

    return if $self->{inStepTable};
    my $name = $self->getName();
    my $workflow_id = $self->{workflow}->getId();
    $sql = "
INSERT INTO workflowstep (workflow_step_id, workflow_id, name, state, state_handled)
VALUES ((select next from sequence ???), $workflow_id, ?, '$READY', 1)
";
    if (!$stmt) {
	my ($count) = runSqlQuery_single_array("select count * from workflowstep where workflow_id = $workflow_id");
	return if $count; # if any steps are in there, they all are... until dynamic xml is allowed
	$stmt = $self->getDbh()->prepare($sql);
    }
    $stmt->execute($name);
    $self->{inStepTable} = 1;
    foreach my $childStep (@{$self->getChildren()}) {
	$childStep->initializeStepTable($stmt);
    }
}

sub initializeDependsTable {
    my ($self,$stmt) = @_;
    return if $self->{inDependsTable};
    $sql = "
INSERT INTO workflowstepdepends (parent_id, child_id)
VALUES ((select next from sequence ???), ?, ?)
";
    if (!$stmt) {
	$stmt = $self->getDbh()->prepare($sql);
    }
    
    $self->{inDependsTable} = 1;
    foreach my $childStep (@{$self->getChildren()}) {
	$stmt->execute($self->getId(), $childStep->getId());
	$childStep->initializeDependsTable($stmt);
    }
}

# returns number of running steps (-1 if last step is done)
# 
sub handleChangesSinceLastPoll {
    my ($self) = @_;

    # if this step has no kids, then it is the end-step
    # workflow is done!
    if (scalar(@{$self->getChildren()}) == 0) {
	return -1;
    }

    my ($state, $handled, $processId) = $self->getDbState();

    # only the controller can transition into these states, so no need to handle change
    if ($state eq $RUNNING) { 
	system("ps -p $processId");
	my $status = $? >> 8;
	if ($status) {
	    $self->forceFail();
	    return 0;
	}
	return 1; 
    }
    if ($state eq $ON_DECK) { return 0; }

    # the wrapper or GUI can change the state to FAILED, DO_NOT_RUN, READY or DONE.
    # here if we have already seen this state
    if ($handled) {
	if ($state eq $FAILED || $state eq $DO_NOT_RUN) {
	    return 0;
	} 
	# kids can only be active if this step is done
	elsif ($state eq $DONE) { 
	    my $count = 0;
	    foreach my $childStep (@{$self->getChildren()}) {
		$count += $childStep->handleChangesSinceLastPoll();
	    }
	    return $count;
	} elsif ($state eq $READY) {
	    $self->maybeGoToOnDeck();
	}
    }

    else {  # this step has not been handled yet
    if ($state eq $DONE) {
	$self->handleDone();
	return 0;
    } elsif ($state eq $FAILED) {
	$self->handleFailed();
	return 0;
    }
    } elsif ($state eq $DO_NOT_RUN) {
	$self->handleDoNotRun();
	return 0;
    }
    } elsif ($state eq $READY) {
	$self->handleReady();
	return 0;
    }
}

# if this step is ready, and all parents are done, transition to ON_DECK
sub maybeGoToOnDeck {
    my ($self) = @_;

    foreach my $parent (@{$self->getParents()}) {
	my ($state, $handled) = $parent->getDbState();
	return unless $state eq $DONE;
    }
    my $sql = "
UPDATE apidb.WorkflowStep
SET 
  state = '$ON_DECK',
  state_handled = 1
WHERE workflow_step_id = $id
AND state = '$READY'
";
    $self->runSql($sql);   
}

sub handleRunning {
    my ($self) = @_;
    my $sql = "select start_time, process_id from apidb.WorkflowStep where workflow_step_id = $id";
    my ($time, $processId) = runSqlQuery_single_array($sql);
    $self->log("step '$self->{stepName}' started, with process id '$processId'");
    $self->setHandledFlag($RUNNING);
}

sub handleDone {
    my ($self) = @_;
    my $sql = "select end_time from apidb.WorkflowStep where workflow_step_id = $id";
    my ($time) = runSqlQuery_single_array();
    $self->log("step '$self->{stepName}' done");
    $self->setHandledFlag($DONE);
}

sub handleReady {
    my ($self) = @_;
    my $sql = "select end_time from apidb.WorkflowStep where workflow_step_id = $id";
    my ($time) = runSqlQuery_single_array();
    $self->log("step '$self->{stepName}' ready");
    $self->setHandledFlag($READY);
}

sub handleFailed {
    my ($self) = @_;
    my $sql = "select end_time from apidb.WorkflowStep where workflow_step_id = $id";
    my ($time) = runSqlQuery_single_array();
    $self->log("step '$self->{stepName}' failed");
    $self->setHandledFlag($FAILED);
}

sub handleDoNotRun {
    my ($self) = @_;
    my $sql = "select end_time from apidb.WorkflowStep where workflow_step_id = $id";
    my ($time) = runSqlQuery_single_array();
    $self->log("step '$self->{stepName}' do not run");
    $self->setHandledFlag($DO_NOT_RUN);
}

sub setHandledFlag {
    my ($self, $state) = @_;

    # check that state is still as expected, to avoid theoretical race condition
    my $sql = "
UPDATE apidb.WorkflowStep
SET state_handled = 1;
WHERE workflow_step_id = $id
AND state = '$state'
";
    $self->runSql($sql);

}

sub forceFail {
    my ($self, $byPilot) = @_;

    my ($state) = $self->getDbState();
    
    die "Can't change to '$FAILED' from '$state'" 
	if ($byPilot && $state ne $RUNNING);

    my $sql = "
UPDATE apidb.WorkflowStep
SET 
  state = '$FAILED',
  state_handled = 1
WHERE workflow_step_id = $id
AND state = '$RUNNING'
";
    $self->runSql($sql);   
    my $reason = $byPilot? "by pilot" : "(can't find wrapper process)";
    $self->log("step '$self->{stepName}' forced to '$FAILED' from '$state' $reason");
    
}

sub forceReady {
    my ($self) = @_;

    my ($state) = $self->getDbState();
    die "Can't change to '$READY' from '$state'" 
	unless ($state eq $DO_NOT_RUN || $state eq $FAILED);

    my $sql = "
UPDATE apidb.WorkflowStep
SET 
  state = '$READY',
  state_handled = 1
WHERE workflow_step_id = $id
AND (state = '$RUNNING' OR state = '$FAILED')
";
    $self->runSql($sql);   
    $self->log("step '$self->{stepName}' forced to '$READY' from '$state' by pilot");
    
}

sub forceDoNotRun {
    my ($self) = @_;

    my ($state) = $self->getDbState();
    die "Can't change to '$DO_NOT_RUN' from '$state'" 
	unless ($state eq $READY || $state eq $ON_DECK);

    my $sql = "
UPDATE apidb.WorkflowStep
SET 
  state = '$DO_NOT_RUN',
  state_handled = 1
WHERE workflow_step_id = $id
AND (state = '$READY' OR state = '$ON_DECK')
";
    $self->runSql($sql);   
    $self->log("step '$self->{stepName}' forced to '$DO_NOT_RUN' from '$state' by pilot");
    
}

# try to run a single ON_DECK step
sub runAvailableStep {
    my ($self) = @_;

    my ($state, $handled) = $self->getDbState();
    my $foundOne;
    if ($state eq $ON_DECK) {
	$self->forkAndRun();
	$foundOne = 1;
    } 
    elsif ($state eq $DONE) {
	foreach my $childStep (@{$self->getChildren()}) {
	    $foundOne = $childStep->runAvailableStep();
	    last if $foundOne;
	}
    }
    return $foundOne;
}

sub getDbState {
    my ($self) = @_;

    my $sql = "select state, state_handled, process_id from workflowstep where id = $id";
    return runSqlQuery_single_array();
}

sub forkAndRun {
    my ($self) = @_;

    my $metaConfigFile = $self->{$workflow}->getMetaConfigFileName();
    system("workflowstep $self->{stepName} $metaConfigFile RUNSTEP &");
    $self->log("running step '$self->{stepName}'");
}

###################### called when running step in forked wrapper #############

sub runInWrapper {
    my ($self, $pid) = @_;

    my $id = $self->getId();
    
    my $process_id = $$;

    my $sql = "
UPDATE apidb.WorkflowStep
SET 
  state = $RUNNING,
  state_handled = 0,
  process_id = $process_id,
  start_time = $start_time
)
WHERE workflow_step_id = $id
";

    $self->runSql($sql);

    exec {
	$self->validateConfig();
	$self->run();
    }

    my $state = $DONE;
    if ($@) {
	$state = $FAILED;
    }
    $sql = "
UPDATE apidb.WorkflowStep
SET (
  state = $state
  process_id = NULL
  end_time = $end_time
  state_handled = 0
)
WHERE workflow_step_id = $id
";
    $self->runSql($sql);
}


#########################  utilities ##########################################

sub runSql {
    my ($self,$sql) = @_;
    $self->{workflow}->runSql($sql);
}

sub runSqlQuery_single_array {
    my ($self,$sql) = @_;
    return $self->{workflow}->runSqlQuery_single_array($sql);
}
