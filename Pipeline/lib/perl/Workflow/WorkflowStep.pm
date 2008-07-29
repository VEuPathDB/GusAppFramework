package GUS::Pipeline::Workflow::WorkflowStep;

use strict;

# allowed states
my $READY = 'READY';      # my parents are not done yet  -- default state
my $ON_DECK = 'ON_DECK';  # my parents are done, but there is no slot for me
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
#  RUNNING    --> FAILED  (or, just kill the process and let the controller change the state)
#  FAILED     --> READY  (ie, the pilot has fixed the problem)
#  (state_handled --> false)
#  [note: going from done to ready is the provence of undo]

# Pilot UI (GUI or command line)
#  OFFLINE --> 1/0  (change not allowed if step is running)

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
INSERT INTO apidb.workflowstep (workflow_step_id, workflow_id, name, state, state_handled, off_line)
VALUES (apidb.workflowstep_sq.nextval, $workflow_id, ?, ?, 1, 0)
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

    return 0 if $self->{handledSnapshot} == $self->{workflow}->{snapshotNumber};

    $self->{handledSnapshot} = $self->{workflow}->{snapshotNumber};

    # if this step has no kids, then it is the end-step
    # if all parents done, workflow is done!
    if (scalar(@{$self->getChildren()}) == 0 && $self->{state} eq $ON_DECK) {
	return -1;
    }

    $self->getDbState();

    # the wrapper or pilot UI can change the state to
    # RUNNING, FAILED, OFFLINE, READY or DONE.
    # here if unchanged since last time
    if ($self->{state_handled}) {

      return 0 if $self->{off_line};

      if ($self->{state} eq $RUNNING) {
	system("ps -p $self->{process_id} > /dev/null");
	my $status = $? >> 8;
	if ($status) {
	  $self->handleMissingProcess();
	  return 0;
	}
	return 1;
      }

      # kids can only be active if this step is done
      elsif ($self->{state} eq $DONE) {
	my $count = 0;
	foreach my $childStep (@{$self->getChildren()}) {
	  $count += $childStep->handleChangesSinceLastPoll();
	}
	return $count;
      }

      elsif ($self->{state} eq $READY) {
	$self->maybeGoToOnDeck();
      }

      # FAILED, ON_DECK
      else {
	return 0;
      }

    } else { # this step has been changed by wrapper or pilot UI. log change.
      my $stateMsg = "";
      my $offlineMsg = "";
      if ($self->{state} ne $self->{prevState}) {
	$stateMsg = "  $self->{state}";
      }
      if ($self->{off_line} ne $self->{prevOffline}) {
	$offlineMsg = $self->{off_line}? "  OFFLINE" : "  ONLINE";
      }

      $self->log("Step '$self->{name}'$stateMsg$offlineMsg");
      $self->setHandledFlag();
      return 0;
    }
}

sub setHandledFlag {
    my ($self) = @_;

    # check that state is still as expected, to avoid theoretical race condition
    my $sql = "
UPDATE apidb.WorkflowStep
SET state_handled = 1
WHERE workflow_step_id = $self->{workflow_step_id}
AND state = '$self->{state}'
AND off_line = $self->{off_line}
";
    $self->runSql($sql);
    $self->{state_handled} = 1;  # till next snapshot
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

# called by pilot UI
sub pilotKill {
    my ($self) = @_;

     $self->{lastSnapshot} = -1;
   my ($state) = $self->getDbState();

    die "Can't change to '$FAILED' from '$state'\n"
	if ($state ne $RUNNING);

    $self->{workflow}->runCmd("kill -9 $self->{process_id}");
    $self->pilotLog("Step '$self->{name}' killed");
}

# called by pilot UI
sub pilotSetReady {
    my ($self) = @_;

    $self->{lastSnapshot} = -1;
    my ($state) = $self->getDbState();

    die "Can't change to '$READY' from '$state'\n"
	unless ($state eq $FAILED);

    my $sql = "
UPDATE apidb.WorkflowStep
SET 
  state = '$READY',
  state_handled = 0
WHERE workflow_step_id = $self->{workflow_step_id}
AND state = '$FAILED'
";
    $self->runSql($sql);
    $self->pilotLog("Step '$self->{name}' set to $READY");
}

# called by pilot UI
sub pilotSetOffline {
    my ($self, $offline) = @_;

    $self->{lastSnapshot} = -1;
    my ($state) = $self->getDbState();
    die "Can't change OFFLINE when '$RUNNING'\n"
	if ($state eq $RUNNING);
    my $offline_bool = $offline eq 'offline'? 1 : 0;

    my $sql = "
UPDATE apidb.WorkflowStep
SET
  off_line = $offline_bool,
  state_handled = 0
WHERE workflow_step_id = $self->{workflow_step_id}
AND (state != '$RUNNING')
";
    $self->runSql($sql);
    $self->pilotLog("Step '$self->{name}' $offline");
}

# if this step is ready, and all parents are done, transition to ON_DECK
sub maybeGoToOnDeck {
    my ($self) = @_;

    foreach my $parent (@{$self->getParents()}) {
	return unless $parent->getDbState() eq $DONE;
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

# try to run a single ON_DECK step
sub runOnDeckStep {
    my ($self) = @_;

    my $foundOne;
    if ($self->{state} eq $ON_DECK && !$self->{off_line}) {
	$self->forkAndRun();
	$foundOne = 1;
    } 
    elsif ($self->{state} eq $DONE && !$self->{off_line}) {
	foreach my $childStep (@{$self->getChildren()}) {
	    $foundOne = $childStep->runOnDeckStep();
	    last if $foundOne;
	}
    }
    return $foundOne;
}

sub getDbState {
    my ($self) = @_;
    if ($self->{lastSnapshot} != $self->{workflow}->{snapshotNumber}) {
      $self->{lastSnapshot} = $self->{workflow}->{snapshotNumber};

      $self->{prevState} = $self->{state};
      $self->{prevOffline} = $self->{off_line};

      my $workflow_id = $self->{workflow}->getId();
      my $sql = "
SELECT workflow_step_id, host_machine, process_id, state,
       state_handled, off_line, start_time, end_time
FROM apidb.workflowstep
WHERE name = '$self->{name}'
AND workflow_id = $workflow_id";
      ($self->{workflow_step_id}, $self->{host_machine}, $self->{process_id},
       $self->{state}, $self->{state_handled}, $self->{off_line},
       $self->{start_time}, $self->{end_time})= $self->runSqlQuery_single_array($sql);
    }
    return $self->{state};
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


#########################  utilities ##########################################

sub log {
    my ($self,$msg) = @_;
    $self->{workflow}->log($msg);
}

sub pilotLog {
  my ($self,$msg) = @_;

  my $homeDir = $self->{workflow}->getHomeDir();

  open(LOG, ">>$homeDir/logs/pilot.log")
    || die "can't open log file '$homeDir/logs/pilot.log'";
  print LOG localtime() . " $msg\n";
  close (LOG);
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
off_line:   $self->{off_line}
handled:    $self->{state_handled}
process_id: $self->{process_id}
start_time: $self->{start_time}
end_time:   $self->{end_time}
depends:    $depends
";
}
