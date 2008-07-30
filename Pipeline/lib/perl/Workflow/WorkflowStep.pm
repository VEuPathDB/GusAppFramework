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
#  RUNNING --> DONE | FAILED
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

# static method
sub getBulkSnapshotSql {
    my ($workflow_id) = @_;
      return "
SELECT workflow_step_id, name, host_machine, process_id, state,
       state_handled, off_line, start_time, end_time
FROM apidb.workflowstep
WHERE workflow_id = $workflow_id";
}

# static method
sub getPreparedInsertStmt {
    my ($workflow_id) = @_;

    my $sql = "
INSERT INTO apidb.workflowstep (workflow_step_id, workflow_id, name, state, state_handled, off_line)
VALUES (apidb.workflowstep_sq.nextval, $workflow_id, ?, ?, 1, 0)
";
    return $self->getDbh()->prepare($sql);
}

# write this step to the db, if not already there.
# called during workflow initialization
sub initializeStepTable {
    my ($self, $stmt) = @_;

    return if $self->{inStepTable};

    my $name = $self->getName();
    my $state = $self->{fakeStepType} eq $START? $DONE : $READY;
    $stmt->execute($name, $state);
}

# static method
sub getPreparedDependsStmt {
    my ($workflow_id) = @_;

    my $sql= "
INSERT INTO apidb.workflowstepdependency (workflow_step_dependency_id, parent_id, child_id)
VALUES (apidb.workflowstepdependency_sq.nextval, ?, ?)
";
    return $self->getDbh()->prepare($sql);
}

sub initializeDependsTable {
    my ($self,$stmt) = @_;
    foreach my $parentStep (@{$self->getParents()}) {
	$stmt->execute($parentStep->getId(), $self->getId());
    }
}

sub setFakeStepType {
  my ($self, $type) = @_;
  $self->{fakeStepType} = $type;
}

sub handleChangesSinceLastSnapshot {
    my ($self, $newSnapshot) = @_;

    my $prevState = $self->{state};
    my $prevOffline = $self->{off_line};

    $self->getDbStateFromSnapshot($newSnapshot);

    if ($self->{state_handled}) {

      if ($self->{state} eq $RUNNING) {
	system("ps -p $self->{process_id} > /dev/null");
	my $status = $? >> 8;
	if ($status) {
	  $self->handleMissingProcess();
	}
      }
    } else { # this step has been changed by wrapper or pilot UI. log change.
      my $stateMsg = "";
      my $offlineMsg = "";
      if ($self->{state} ne $prevState) {
	$stateMsg = "  $self->{state}";
      }
      if ($self->{off_line} ne $prevOffline) {
	$offlineMsg = $self->{off_line}? "  OFFLINE" : "  ONLINE";
      }

      $self->log("Step '$self->{name}'$stateMsg$offlineMsg");
      $self->setHandledFlag();
    }
    return $self->{state} eq $RUNNING;
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

    if ($self->{state} eq $ON_DECK && !$self->{off_line}) {
	$self->forkAndRun();
	return 1;
    } 
    return 0;
}

sub getDbStateFromSnapshot {
    my ($self, $snapshot) = @_;

    foreach my $key (%$snapshot) {
	$self->{$key} = $snapshot->{$key};
    }
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

sub runSql {
    my ($self,$sql) = @_;
    $self->{workflow}->runSql($sql);
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
