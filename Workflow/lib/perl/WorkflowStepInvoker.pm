package GUS::Workflow::WorkflowStepInvoker;

@ISA = qw(GUS::Workflow::Base);
use strict;
use GUS::Workflow::Base;

#
# Super class of workflow steps written in perl, and called by the wrapper
#

sub setParamValues {
  my ($self, $paramValuesArray) = @_;

  $self->{paramValues} = {};
  for (my $i=0; $i<scalar(@$paramValuesArray); $i+=2) {
    my $noHyphen = substr($paramValuesArray->[$i],1);
    $self->{paramValues}->{$noHyphen} = $paramValuesArray->[$i+1];
  }
}

sub getParamValue {
  my ($self, $name) = @_;
  return $self->{paramValues}->{$name};
}

sub runInWrapper {
    my ($self, $workflowId, $stepName) = @_;

    $self->{name} = $stepName;

    my $process_id = $$;

    my $sql = "
UPDATE apidb.WorkflowStep
SET
  state = '$RUNNING',
  state_handled = 0,
  process_id = $process_id,
  start_time = SYSDATE
WHERE name = '$stepName'
AND workflow_id = $workflowId
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
SET
  state = '$state',
  process_id = NULL,
  end_time = SYSDATE,
  state_handled = 0
WHERE name = '$stepName'
AND workflow_id = $workflowId
AND state = '$RUNNING'
";
    $self->runSql($sql);
}


sub getConfig {
  my ($self, $prop) = @_;

  my $homeDir = $self->getHomeDir();
  my $propFile = "$homeDir/config/steps.prop";
  my $className = ref($self);
  $className =~ s/\:\:/\//g;

  if (!$self->{stepConfig}) {
    my $rawDeclaration = $self->getConfigDeclaration();
    my $fullDeclaration = [];
    foreach my $rd (@$rawDeclaration) {
      my $fd = ["$self->{name}.$rd->[0]", $rd->[1], '', "$className.$rd->[0]"];
      push(@$fullDeclaration,$fd);
    }
    $self->{stepConfig} = 
      CBIL::Util::PropertySet->new($propFile, $fullDeclaration, 1);
  }

  # first try explicit step property
  if (defined($self->{stepConfig}->getPropRelaxed("$self->{name}.$prop"))) {
    return $self->{stepConfig}->getPropRelaxed("$self->{name}.$prop");
  } elsif (defined($self->{stepConfig}->getPropRelaxed("$className.$prop"))) {
    return $self->{stepConfig}->getPropRelaxed("$className.$prop");
  } else {
    die "Can't find property '$prop' for step '$self->{name}' or for class '$className' in file $propFile\n";
  }
}

sub getGlobalConfig {
    my ($self, $key) = @_;

    if (!$self->{globalStepsConfig}) {
      my $homeDir = $self->getHomeDir();
      $self->{globalStepsConfig} =
	CBIL::Util::PropertySet->new("$homeDir/config/stepsGlobal.prop",[], 1);
    }
    return $self->{globalStepsConfig}->getProp($key);
}

sub getStepDir {
  my ($self) = @_;

  if (!$self->{stepDir}) {
    my $homeDir = $self->getHomeDir();
    my $stepDir = "$homeDir/steps/$self->{name}";
    my $cmd = "mkdir -p $stepDir";
    `$cmd` unless -e $stepDir;
    my $status = $? >> 8;
    $self->error("Failed with status $status running: \n$cmd") if ($status);
    $self->{stepDir} = $stepDir;
  }
  return $self->{stepDir};
}

sub runPlugin {
    my ($self, $plugin, $args, $msg, $doitProperty) = @_;

    my $comment = $args;
    $comment =~ s/"/\\"/g;

    if ($self->{gusConfigFile}) {
      $args .= " --gusconfigfile $self->{gusConfigFile}";
    }

    my $cmd = "echo ga $plugin $args --comment \"$comment\"";

    $self->runCmd($cmd);
}

sub runCmd {
    my ($self, $cmd) = @_;

    my $stepDir = $self->getStepDir();
    my $err = "$stepDir/step.err";

    my $output = `$cmd 2>> $err`;
    my $status = $? >> 8;
    $self->error("Failed with status $status running: \n$cmd") if ($status);
    return $output;
}

