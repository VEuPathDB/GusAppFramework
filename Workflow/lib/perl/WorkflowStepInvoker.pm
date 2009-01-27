package GUS::Workflow::WorkflowStepInvoker;

@ISA = qw(GUS::Workflow::Base);
use strict;
use GUS::Workflow::Base;
use GUS::Workflow::SshCluster;
use GUS::Workflow::NfsCluster;

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

sub setRunningState {
    my ($self, $workflowId, $stepName) = @_;

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
}

sub getStepInvoker {
  my ($self, $invokerClass, $homeDir) = @_;
  my $stepInvoker =  eval "{require $invokerClass; $invokerClass->new('$homeDir')}";
  $self->error($@) if $@;
  return $stepInvoker;
}

sub runInWrapper {
    my ($self, $workflowId, $stepName, $mode, $invokerClass) = @_;

    $self->{name} = $stepName;

    chdir $self->getStepDir();

    $self->log("Running Step Class $invokerClass");
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
    my $sql = "
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
    my @rawDeclaration = $self->getConfigDeclaration();
    my $fullDeclaration = [];
    foreach my $rd (@rawDeclaration) {
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
    $self->error("Can't find property '$prop' for step '$self->{name}' or for class '$className' in file $propFile\n");
  }
  $self->log("accessing step property '$prop=$value'");
  return $value;
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

sub getName {
  my ($self) = @_;

  return $self->{name};
}

sub getCluster {
    my ($self) = @_;

    if (!$self->{cluster}) {
	my $clusterServer = $self->getWorkflowConfig('clusterServer');
	my $clusterUser = $ENV{USER};
	if ($clusterServer ne "none") {
	    $self->{cluster} = GUS::Workflow::SshCluster->new($clusterServer,
							      $clusterUser,
							      $self);
	} else {
	    $self->{cluster} = GUS::Workflow::NfsCluster->new($self);
	}
    }
    return $self->{cluster};
}

sub runCmdOnCluster {
  my ($self, $test, $cmd) = @_;

  $self->getCluster()->runCmdOnCluster($test, $cmd);
}

sub copyToCluster {
    my ($self, $fromDir, $fromFile, $toDir) = @_;
    $self->getCluster()->copyTo($fromDir, $fromFile, $toDir);
}

sub copyFromCluster {
    my ($self, $fromDir, $fromFile, $toDir) = @_;
    $self->getCluster()->copyFrom($fromDir, $fromFile, $toDir);
}

sub runAndMonitorClusterTask {
    my ($self, $test, $user, $server, $processIdFile, $logFile, $propFile, $numNodes, $time, $queue, $ppn) = @_;

    # if not already started, start it up (otherwise the local process was restarted)
    if (!$self->clusterTaskRunning($processIdFile, $user, $server)) {
	my $cmd = "workflowclustertask $propFile $processIdFile $logFile $numNodes $time $queue $ppn";
	$self->runCmd($test, "ssh -2 $user\@$server '$cmd' &");
    }

    return 1 if ($test);

    while (1) {
	sleep(5);
	last if !$self->clusterTaskRunning($processIdFile);
    }

    my $done = $self->runCmd($test, "ssh -2 $user\@$server 'if [ -a $logFile ]; then tail -1 $logFile; fi'");
    return $done && $done =~ /Done/;
}

sub clusterTaskRunning {
    my ($self, $processIdFile, $user, $server) = @_;

    my $processId = `ssh -2 $user\@$server 'if [ -a $processIdFile ];then cat $processIdFile; fi'`;
    chomp $processId;

    my $status = 0;
    if ($processId) {
      system("ssh -2 $user\@$server 'ps -p $processId > /dev/null'");
      $status = $? >> 8;
      $status = !$status;
    }
    return $status;
}

sub runPlugin {
    my ($self, $test, $plugin, $args) = @_;

    my $className = ref($self);

    if ($test != 1 && $test != 0) {
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

    my $commit = $args." --commit";

    my $cmd = "ga $plugin $commit --comment \"$comment\"";

    $self->runCmd($test, $cmd);
}

sub runCmd {
    my ($self, $test, $cmd) = @_;

    my $stepDir = $self->getStepDir();
    my $err = "$stepDir/step.err";
    my $testmode = $test? " (in test mode , so only pretending) " : "";
    $self->log("running$testmode:  $cmd\n\n");

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
  print F localtime() . "\t$msg\n\n";
  close(F);
}
