package GUS::Pipeline::Workflow::WorkflowStep;

use strict;

my $READY = 'READY';      # my parents are not done yet  -- default state
my $ON_DECK = 'ON_DECK';  # my parents are done, but there is no slot for me
my $DO_NOT_RUN = 'DO_NOT_RUN';  # pilot doesn't want this step to start
my $FAILED = 'FAILED';
my $DONE = 'DONE';
my $RUNNING = 'RUNNING';

my $START = 'START';
my $END = 'END';

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
  my ($class, $stepName, $workflow, $invokerClass) = @_;

  my $self = {
	      workflow=> $workflow,
	      name => $stepName,
	      invokerClass => $invokerClass,
	      children => [],
	      parents => []
	     };

  bless($self,$class);
  return $self;
}

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

sub getParents {
    my ($self) = @_;
    return $self->{parents};
}

sub getName {
    my ($self) = @_;
    return $self->{name};
}

sub getInvokerClass {
    my ($self) = @_;
    return $self->{invokerClass};
}

sub getId () {
    my ($self) = @_;

    $self->getDbState() if (!$self->{workflow_step_id});
    return $self->{workflow_step_id};
}

sub getState () {
    my ($self) = @_;

    $self->getDbState() if (!$self->{state});
    return $self->{state};
}

sub setFakeStepType {
  my ($self, $type) = @_;
  $self->{fakeStepType} = $type;
}

# write this step to the db, if not already there.
# called during workflow initialization
sub initializeStepTable {
    my ($self, $stmt) = @_;

    return if $self->{inStepTable};

    my $name = $self->getName();

    # if this is the start step, create a prepared statement for all steps to use
    # also, check if start step is in db.  if so, assume all steps are, and quit.
    my $state = $READY;
    if ($self->{fakeStepType} eq $START) {
      my $workflow_id = $self->{workflow}->getId();
      my ($count) = $self->runSqlQuery_single_array("select count(*) from apidb.workflowstep where workflow_id = $workflow_id");
      return if $count;

      my $sql = "
INSERT INTO apidb.workflowstep (workflow_step_id, workflow_id, name, state, state_handled)
VALUES (apidb.workflowstep_sq.nextval, $workflow_id, ?, ?, 1)
";
      $stmt = $self->{workflow}->getDbh()->prepare($sql);
      $state = $DONE;
    }
    $stmt->execute($name, $state);
    $self->{inStepTable} = 1;
    foreach my $childStep (@{$self->getChildren()}) {
	$childStep->initializeStepTable($stmt);
    }
}

sub initializeDependsTable {
    my ($self,$stmt) = @_;
    return if $self->{inDependsTable};
    my $sql = "
INSERT INTO apidb.workflowstepdependency (workflow_step_dependency_id, parent_id, child_id)
VALUES (apidb.workflowstepdependency_sq.nextval, ?, ?)
";
    if (!$stmt) {
	$stmt = $self->{workflow}->getDbh()->prepare($sql);
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

    $self->getDbState();

    if ($self->{state} eq $RUNNING) { 
	system("ps -p $self->{process_id}");
	my $status = $? >> 8;
	if ($status) {
	    $self->forceFail();
	    return 0;
	}
	return 1;
    }
    if ($self->{state} eq $ON_DECK) { return 0; }

    # the wrapper or pilot UI can change the state to FAILED, DO_NOT_RUN, READY or DONE.
    # here if unchanged since last time
    if ($self->{state_handled}) {
	if ($self->{state} eq $FAILED || $self->{state} eq $DO_NOT_RUN) {
	    return 0;
	}
	# kids can only be active if this step is done
	elsif ($self->{state} eq $DONE) {
	    my $count = 0;
	    foreach my $childStep (@{$self->getChildren()}) {
		$count += $childStep->handleChangesSinceLastPoll();
	    }
	    return $count;
	} elsif ($self->{state} eq $READY) {
	    $self->maybeGoToOnDeck();
	}
    }

    else {  # this step has been changed by wrapper or pilot UI. log change.
	$self->log("step '$self->{name}' $self->{state}");
	$self->setHandledFlag();
	return 0;
    }
}

sub handleRunning {
    my ($self) = @_;
    $self->log("step '$self->{name}' started, with process id '$self->{processId}'");
    $self->setHandledFlag($RUNNING);
}

sub setHandledFlag {
    my ($self) = @_;

    # check that state is still as expected, to avoid theoretical race condition
    my $sql = "
UPDATE apidb.WorkflowStep
SET state_handled = 1
WHERE workflow_step_id = $self->{workflow_step_id}
AND state = '$self->{state}'
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
WHERE workflow_step_id = $self->{workflow_step_id}
AND state = '$RUNNING'
";
    $self->runSql($sql);   
    my $reason = $byPilot? "by pilot" : "(can't find wrapper process)";
    $self->log("step '$self->{name}' forced to '$FAILED' from '$state' $reason");
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
WHERE workflow_step_id = $self->{workflow_step_id}
AND (state = '$RUNNING' OR state = '$FAILED')
";
    $self->runSql($sql);
    $self->log("step '$self->{name}' forced to '$READY' from '$state' by pilot");
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
WHERE workflow_step_id = $self->{workflow_step_id}
AND (state = '$READY' OR state = '$ON_DECK')
";
    $self->runSql($sql);
    $self->log("step '$self->{name}' forced to '$DO_NOT_RUN' from '$state' by pilot");
}

# if this step is ready, and all parents are done, transition to ON_DECK
sub maybeGoToOnDeck {
    my ($self) = @_;

    foreach my $parent (@{$self->getParents()}) {
      print STDERR "parent: $parent->{name}\n";
	return unless $parent->getDbState() eq $DONE;
    }
    $self->log("step '$self->{name}' $ON_DECK");
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

# try to run a single ON_DECK step
sub runOnDeckStep {
    my ($self) = @_;

    my $foundOne;
    if ($self->{state} eq $ON_DECK) {
	$self->forkAndRun();
	$foundOne = 1;
    } 
    elsif ($self->{state} eq $DONE) {
	foreach my $childStep (@{$self->getChildren()}) {
	    $foundOne = $childStep->runOnDeckStep();
	    last if $foundOne;
	}
    }
    return $foundOne;
}

sub getDbState {
    my ($self) = @_;

    my $workflow_id = $self->{workflow}->getId();
    my $sql = "
SELECT workflow_step_id, host_machine, process_id, state,
       state_handled, start_time, end_time
FROM apidb.workflowstep
WHERE name = '$self->{name}'
AND workflow_id = $workflow_id";
    ($self->{workflow_step_id}, $self->{host_machine}, $self->{process_id},
     $self->{state}, $self->{state_handled},
     $self->{start_time}, $self->{end_time})= $self->runSqlQuery_single_array($sql);
    return $self->{state};
}

sub forkAndRun {
    my ($self) = @_;

    my $metaConfigFile = $self->{workflow}->getMetaConfigFileName();
    my $workflowId = $self->{workflow}->getId();
    $self->log("running step '$self->{name}'");
    print STDERR "workflowstepwrap $self->{name} '$self->{invokerClass}' $metaConfigFile $workflowId\n";
    system("workflowstepwrap $self->{name} '$self->{invokerClass}' $metaConfigFile $workflowId &");
}


#########################  utilities ##########################################

sub log {
    my ($self,$msg) = @_;
    $self->{workflow}->log($msg);
}

sub runSql {
    my ($self,$sql) = @_;
    $self->{workflow}->runSql($sql);
}

sub runSqlQuery_single_array {
    my ($self,$sql) = @_;
    return $self->{workflow}->runSqlQuery_single_array($sql);
}

sub toString {
    my ($self) = @_;

    $self->getDbState();

    my @parentsNames;
    foreach my $parent (@{$self->getParents()}) {
	push(@parentsNames, $parent->getName());
    }

    my $depends = join(", ", @parentsNames);
    return "
name:       $self->{name}
id:         $self->{workflow_step_id}
state:      $self->{state}
handled:    $self->{state_handled}
process_id: $self->{process_id}
start_time: $self->{start_time}
end_time:   $self->{end_time}
depends:    $depends
";
}
