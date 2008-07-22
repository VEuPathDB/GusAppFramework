package GUS::Pipeline::WorkflowStep;

my $BORED = 'bored';      # my parents are not done yet  -- default state
my $WAITING = 'waiting';  # my parents are done, but there is no slot for me
my $DO_NOT_RUN = 'do_not_run';  # pilot doesn't want this step to start
my $FAILED = 'failed';
my $DONE = 'done';

# controller
#  BORED   --> WAITING
#  RUNNING --> FAILED (if wrapper itself dies, ie, controller can't find PID)
#  (state_handled --> true)

# wrapper
#  WAITING --> RUNNING
#  RUNNING --> DONE
#  RUNNING --> FAILED
#  (state_handled --> false)

# Pilot UI (GUI or command line)
#  BORED      --> DO_NOT_RUN
#  WAITING    --> DO_NOT_RUN
#  RUNNING    --> FAILED  (or, just kill the process and let the controller change the state)
#  DO_NOT_RUN --> BORED
#  FAILED     --> BORED  (ie, the pilot has fixed the problem)
#  (state_handled --> false)
#  [note: going from done to bored is the provence of undo]


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

sub getConfig {
    my ($self) = @_;
    return $workflow->getStepConfig($self->getName());
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
sub initializeDb {
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

    my ($state, $handled) = $self->getDbState();

    # only the controller can transition into these states, so no need to handle change
    if ($state eq $RUNNING) { return 1; }
    if ($state eq $WAITING) { return 0; }

    # the wrapper or GUI can change the state to FAILED, DO_NOT_RUN, BORED or DONE.
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
	} elsif ($state eq $BORED) {
	    $self->maybeGoToWaiting();
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
    } elsif ($state eq $BORED) {
	$self->handleBored();
	return 0;
    }
}

# if this step is bored, and all parents are done, transition to waiting
sub maybeGoToWaiting {
    my ($self) = @_;

    foreach my $parent (@{$self->getParents()}) {
	my ($state, $handled) = $parent->getDbState();
	return unless $state eq $DONE;
    }
    my $sql = "
UPDATE apidb.WorkflowStep
SET (
  state = $WAITING
  state_handled = 1
)
WHERE workflow_step_id = $id
AND state = '$BORED'
";

    $self->runSql($sql);
    
}

sub handleRunning {
    my ($self) = @_;
    my $sql = "select start_time, process_id from apidb.WorkflowStep where workflow_step_id = $id";
    my ($time, $processId) = runSqlQuery_single_array();
    $self->log("step '$self->{stepName}' started at $time, with process id '$processId'");
    $self->setHandledFlag($RUNNING);
}

sub handleDone {
    my ($self) = @_;
    my $sql = "select end_time from apidb.WorkflowStep where workflow_step_id = $id";
    my ($time) = runSqlQuery_single_array();
    $self->log("step '$self->{stepName}' done at $time");
    $self->setHandledFlag($DONE);
}

sub handleBored {
    my ($self) = @_;
    my $sql = "select end_time from apidb.WorkflowStep where workflow_step_id = $id";
    my ($time) = runSqlQuery_single_array();
    $self->log("step '$self->{stepName}' done at $time");
    $self->setHandledFlag($DONE);
}

sub handleFailed {
    my ($self) = @_;
    my $sql = "select end_time from apidb.WorkflowStep where workflow_step_id = $id";
    my ($time) = runSqlQuery_single_array();
    $self->log("step '$self->{stepName}' failed at $time");
    $self->setHandledFlag($FAILED);
}

sub handleDoNotRun {
    my ($self) = @_;
    my $sql = "select end_time from apidb.WorkflowStep where workflow_step_id = $id";
    my ($time) = runSqlQuery_single_array();
    $self->log("step '$self->{stepName}' done at $time");
    $self->setHandledFlag($DO_NOT_RUN);
}

sub setHandledFlag {
    my ($self, $state) = @_;

    # check that state is still as expected, to avoid theoretical race condition
    my $sql = "
UPDATE apidb.WorkflowStep
SET (
  state_handled = 1;
)
WHERE workflow_step_id = $id
AND state = '$state'
";
    $self->runSql($sql);

}

# try to run a single waiting step
sub runAvailableStep {
    my ($self) = @_;

    my ($state, $handled) = $self->getDbState();
    my $foundOne;
    if ($state eq $WAITING) {
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

    my $sql = "select state, state_handled from workflowstep where id = $id";
    return runSqlQuery_single_array();
}

sub forkAndRun {
    my ($self) = @_;

    my $metaConfigFile = $self->{$workflow}->getMetaConfigFileName();
    system("workflowstep $self->{stepName} $metaConfigFile &");
    $self->log("running step '$self->{stepName}'");
}

###################### called when running step in forked wrapper #############

sub runInWrapper {
    my ($self, $pid) = @_;

    my $id = $self->getId();

    my $process_id = ???; # how to do this in perl?

    my $sql = "
UPDATE apidb.WorkflowStep
SET (
  state = $RUNNING
  state_handled = 0
  process_id = $process_id
  start_time = $start_time
)
WHERE workflow_step_id = $id
";

    $self->runSql($sql);

    exec {
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
