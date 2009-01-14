package GUS::Workflow::WorkflowStepPilot;

use strict;

# allowed states
my $READY = 'READY';      # my parents are not done yet  -- default state
my $ON_DECK = 'ON_DECK';  # my parents are done, but there is no slot for me
my $FAILED = 'FAILED';
my $DONE = 'DONE';
my $RUNNING = 'RUNNING';

my $START = 'START';
my $END = 'END';

sub new {
  my ($class, $stepName, $workflow) = @_;

  my $self = {
	      workflow=> $workflow,
	      name => $stepName,
	     };
  $workflow->checkXmlFileDigest();

  bless($self,$class);
  return $self;
}

# called by pilot UI
sub pilotKill {
    my ($self) = @_;

    my ($state) = $self->getDbState();

    if ($state ne $RUNNING) {
      return "Warning: Can't change $self->{name} from '$state' to '$FAILED'";
    }

    $self->{workflow}->runCmd("kill -9 $self->{process_id}");
    $self->pilotLog("Step '$self->{name}' killed");
    return 0;
}

# called by pilot UI
sub pilotSetReady {
    my ($self) = @_;

    my ($state) = $self->getDbState();

    if ($state ne $FAILED) {
      return "Warning: Can't change $self->{name} from '$state' to '$READY'";
    }

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

    return 0;
}

# called by pilot UI
sub pilotSetOffline {
    my ($self, $offline) = @_;

    $self->{lastSnapshot} = -1;
    my ($state) = $self->getDbState();
    if ($state eq $RUNNING) {
      return "Warning: Can't change $self->{name} to OFFLINE when '$RUNNING'";
    }
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
    return 0;
}

sub getDbState {
    my ($self) = @_;

    if (!$self->{state}) {
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

#########################  utilities ##########################################

sub pilotLog {
  my ($self,$msg) = @_;

  my $homeDir = $self->{workflow}->getWorkflowHomeDir();

  open(LOG, ">>$homeDir/logs/pilot.log")
    || die "can't open log file '$homeDir/logs/pilot.log'";
  print LOG localtime() . " $msg\n";
  close (LOG);
  print STDOUT "$msg\n";
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
