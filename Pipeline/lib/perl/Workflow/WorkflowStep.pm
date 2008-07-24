package GUS::Pipeline::WorkflowStep;

# these should be imported from someplace, not duplicated here
my $READY = 'READY';      # my parents are not done yet  -- default state
my $ON_DECK = 'ON_DECK';  # my parents are done, but there is no slot for me
my $DO_NOT_RUN = 'DO_NOT_RUN';  # pilot doesn't want this step to start
my $FAILED = 'FAILED';
my $DONE = 'DONE';

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
AND workflow_id = $workflow_id
AND state = '$RUNNING'
";
    $self->runSql($sql);
}


sub _runPlugin {
    my ($self, $signal, $plugin, $args, $msg, $doitProperty) = @_;

    return if $self->startStep($msg, $signal, $doitProperty);
    
    my $err = "$self->{pipelineDir}/logs/$signal.err";
    my $out = "$self->{pipelineDir}/logs/$signal.out";

    my $comment = $args;
    $comment =~ s/"/\\"/g;

    if ($self->{gusConfigFile}) {
      $args .= " --gusconfigfile $self->{gusConfigFile}";
    }

    my $cmd = "ga $plugin $args --comment \"$comment\"  >> $out 2>> $err";

    $self->runCmd("mkdir -p $self->{pipelineDir}/plugins/$signal");
    chdir "$self->{pipelineDir}/plugins/$signal";

    $self->runCmd($cmd);
    if ($self->{testNextPlugin} eq "true"){
	print STDERR "Tested next plugin.  Check $self->{pipelineDir}/logs/$signal" . ".err and $signal" . ".out for results\n\n";
	$self->_cleanup(1);
    }
    else{
	$self->endStep($signal);
    }
}

