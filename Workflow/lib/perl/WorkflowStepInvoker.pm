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
  $self->log("accessing parameter '$name=$self->{paramValues}->{$name}'");
  return $self->{paramValues}->{$name};
}

sub runInWrapper {
    my ($self, $workflowId, $stepName, $mode) = @_;

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
        my $testOnly = $mode eq 'test';
	$self->log("only testing...") if $testOnly;
	$self->run($testOnly);
	sleep(int(rand(5))+1) if $testOnly;
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

  my $homeDir = $self->getWorkflowHomeDir();
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
  my $value;
  if (defined($self->{stepConfig}->getPropRelaxed("$self->{name}.$prop"))) {
    $value = $self->{stepConfig}->getPropRelaxed("$self->{name}.$prop");
  } elsif (defined($self->{stepConfig}->getPropRelaxed("$className.$prop"))) {
    $value = $self->{stepConfig}->getPropRelaxed("$className.$prop");
  } else {
    die "Can't find property '$prop' for step '$self->{name}' or for class '$className' in file $propFile\n";
  }
  $self->log("accessing step property '$prop=$value'");
}

sub getGlobalConfig {
    my ($self, $key) = @_;

    if (!$self->{globalStepsConfig}) {
      my $homeDir = $self->getWorkflowHomeDir();
      $self->{globalStepsConfig} =
	CBIL::Util::PropertySet->new("$homeDir/config/stepsGlobal.prop",[], 1);
    }
    return $self->{globalStepsConfig}->getProp($key);
}

sub getStepDir {
  my ($self) = @_;

  if (!$self->{stepDir}) {
    my $homeDir = $self->getWorkflowHomeDir();
    my $stepDir = "$homeDir/steps/$self->{name}";
    my $cmd = "mkdir -p $stepDir";
    `$cmd` unless -e $stepDir;
    my $status = $? >> 8;
    $self->error("Failed with status $status running: \n$cmd") if ($status);
    $self->{stepDir} = $stepDir;
  }
  return $self->{stepDir};
}

sub getCluster {
    my ($self) = @_;

    if (!$self->{cluster}) {
	my $clusterServer = $self->getGlobalConfig('clusterServer');
	my $clusterUser = $self->getGlobalConfig('clusterServer');
	if ($clusterServer ne "none") {
	    $self->{cluster} = GUS::Pipeline::SshCluster->new($clusterServer,
							      $clusterUser);
	} else {
	    $self->{cluster} = GUS::Pipeline::NfsCluster->new();
	}
    }
    return $self->{cluster};
}

sub copyToCluster {
    my ($self, $fromDir, $fromFile, $toDir) = @_;
    $self->getCluster()->copyTo($fromDir, $fromFile, $toDir);
}

sub copyFromCluster {
    my ($self, $fromDir, $fromFile, $toDir) = @_;
    $self->getCluster()->copyFrom($fromDir, $fromFile, $toDir);
}

sub runPlugin {
    my ($self, $test, $plugin, $args) = @_;

    my $className = REF($self);

    if ($test != 1 || $test != 0) {
	$self->error("illegal 'test' arg passed to runPlugin() in step class '$className'");
    }

    if ($plugin !~ /\w+\:\:\w+/) {
	$self->error("illegal 'plugin' arg passed to runPlugin() in step class '$className'");
    }

    my $comment = $args;
    $comment =~ s/"/\\"/g;

    if ($self->{gusConfigFile}) {
      $args .= " --gusconfigfile $self->{gusConfigFile}";
    }

    my $cmd = "echo ga $plugin $args --comment \"$comment\"";

    $self->runCmd($test, $cmd);
}

sub runCmd {
    my ($self, $test, $cmd) = @_;

    my $stepDir = $self->getStepDir();
    my $err = "$stepDir/step.err";
    $self->log("running:  $cmd\n\n");

    my $output;

    if ($test) {
      $output = `echo just testing 2>> $err`;
    } else {
      $output = `$cmd 2>> $err`;
      my $status = $? >> 8;
      $self->error("Failed with status $status running: \n$cmd") if ($status);
    }
    return $output;
}

sub log {
  my ($self, $msg) = @_;

    my $stepDir = $self->getStepDir();
  open(F, ">>$stepDir/step.log");
  print F "$msg\n\n";
  close(F);
}
