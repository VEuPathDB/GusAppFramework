package GUS::Pipeline::Workflow::WorkflowStepPilot;

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

  bless($self,$class);
  return $self;
}

# called by pilot UI
sub pilotKill {
    my ($self) = @_;

    my ($state) = $self->getDbState();

    die "Can't change from '$state' to $FAILED\n"
	if ($state ne $RUNNING);

    $self->{workflow}->runCmd("kill -9 $self->{process_id}");
    $self->pilotLog("Step '$self->{name}' killed");
}

# called by pilot UI
sub pilotSetReady {
    my ($self) = @_;

    my ($state) = $self->getDbState();

    die "Can't change from '$state' to '$READY'\n"
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
    die "Can't change to OFFLINE when '$RUNNING'\n"
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
