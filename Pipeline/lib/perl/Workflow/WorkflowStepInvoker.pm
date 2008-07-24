package GUS::Pipeline::WorkflowStep;

# these should be imported from someplace, not duplicated here
my $READY = 'READY';      # my parents are not done yet  -- default state
my $ON_DECK = 'ON_DECK';  # my parents are done, but there is no slot for me
my $DO_NOT_RUN = 'DO_NOT_RUN';  # pilot doesn't want this step to start
my $FAILED = 'FAILED';
my $DONE = 'DONE';
my $RUNNING = 'RUNNING';

@ISA = qw(GUS::Pipeline::Workflow::Base);
use strict;
use lib "$ENV{GUS_HOME}/lib/perl";

#
# Super class of workflow steps written in perl, and called by the wrapper
#

# get a single configuration property value
sub getConfig {
    my ($self, $propName) = @_;
    return $self->getStepConfig($propName);
}

sub runInWrapper {
    my ($self, $workflowId, $stepName) = @_;

    my $process_id = $$;

    my $sql = "
UPDATE apidb.WorkflowStep
SET 
  state = '$RUNNING',
  state_handled = 1,
  process_id = $process_id,
  start_time = SYSDATE
)
WHERE name = $stepName
AND workflow_id = $workflowId
AND state = '$ON_DECK'
";

    $self->runSql($sql);

    chdir $self->getStepDir();

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
  end_time = SYSDATE
  state_handled = 0
)
WHERE name = $self->{name} 
AND workflow_id = $workflowId
AND state = '$RUNNING'
";
    $self->runSql($sql);
}


sub getStepDir {
  my ($self) = @_;

  if (!$self->{stepDir}) {
    my $homeDir = $self->getMetaConfig('homeDir');
    my $stepDir = "$homeDir/steps/$self->{name}";
    $self->runCmd("mkdir -p $stepDir") unless -e $stepDir;
    $self->{stepDir} = $stepDir;
  }
  return $self->{stepDir};
}

sub runPlugin {
    my ($self, $plugin, $args, $msg, $doitProperty) = @_;

    my $stepDir = $self->getStepDir();
    my $err = "$stepDir/step.err";
    my $out = "$stepDir/step.out";

    my $comment = $args;
    $comment =~ s/"/\\"/g;

    if ($self->{gusConfigFile}) {
      $args .= " --gusconfigfile $self->{gusConfigFile}";
    }

    my $cmd = "ga $plugin $args --comment \"$comment\"  >> $out 2>> $err";

    $self->runCmd($cmd);
}

