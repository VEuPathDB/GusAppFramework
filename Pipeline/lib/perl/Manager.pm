package GUS::Pipeline::Manager;

use strict;
use File::Basename;
use CBIL::Util::Utils;

#############################################################################
#          Public Methods
#############################################################################

sub new {
    my ($class, $pipelineDir, $propertySet, $propertiesFile, $cluster, $testNextPlugin) = @_;

    my $self = {};
    bless $self, $class;
    $self->{pipelineDir} = $pipelineDir;
    $self->{propertySet} = $propertySet;
    $self->{propertiesFile} = $propertiesFile;
    $self->{program} = basename($0);
    $self->{cluster} = $cluster;
    $cluster->setManager($self);
    $self->{testNextPlugin} = $testNextPlugin;
    $self->_createPipelineDir();

    $self->_dieIfAlreadyRunning();

    open(STDERR, ">$self->{pipelineDir}/logs/pipeline.err")  || die "Can't open $self->{pipelineDir}/logs/pipeline.err";

    $self->_setSignal("running");

    if ($testNextPlugin eq "true"){
	my $msg = "***Running pipeline " . $self->{program} . "; will only run until reaching a step containing a plugin which hasn't been run.\n";
	$msg .= "***That plugin will be tested, the results will not be committed, and the pipeline will exit\n\n";
	print STDOUT $msg;
    }
 
    my $signal = "init";

    return $self if $self->startStep("Initializing", $signal);

    $self->endStep($signal);
    return $self;
}

# param $doitProperty  - the name of a property which will have value 
#                        "no" if this step should be skipped. undef means
#                        don't skip
sub startStep {
    my($self, $msg, $signal, $doitProperty) = @_;

    my $stopBefore = $self->{propertySet}->getProp('stopBefore');

    if ($stopBefore eq $signal) {
	$self->log("Property 'stopBefore' set to $signal.  Stopping.\n\n");
	unlink "$self->{pipelineDir}/signals/running";
	exit(0);
    }

    if ($self->_getSignal('stop')) {
	$self->log("Found 'stop' signal.  Stopping.\n\n");
	unlink "$self->{pipelineDir}/signals/running";
	exit(0);
    }

    if ($doitProperty && $self->{propertySet}->getProp($doitProperty) eq "no") {
	$self->log("$msg\n");
	$self->log("...skipping: property '$doitProperty' set to 'no'\n\n");
	return 1;
    } elsif ($self->_getSignal($signal)) {
	$self->log("$msg\n");
	$self->log("...already done (found signal $signal)\n\n");
	return 1;
    } elsif ($self->_getSkip($signal)) {
	$self->log("$msg\n");
	$self->log("...skipping (found skip/$signal)\n\n");
	return 1;
    } else {
	$self->{stepStartTime} = time;
	my $date = `date`;
	chomp $date;
	$self->log("[$date]  $msg\n");
	return 0;
    }
} 

sub endStep {
    my($self, $signal) = @_;

    my $date = `date`;
    chomp $date;

    my $time = &timeformat(time - $self->{stepStartTime});

    $self->log("[$date]  Done (took $time) ");
    $self->_setSignal($signal);
}

sub log {
    my ($self, $msg) = @_;
    
    open(LOG, ">>$self->{pipelineDir}/logs/pipeline.log");
    print LOG $msg;
    close (LOG);
}

# param $doitProperty  - the name of a property which will have value 
#                        "no" if this step should be skipped. undef means
#                        don't skip
sub runPlugin {
    my ($self, $signal, $plugin, $args, $msg, $doitProperty) = @_;
    my $commit = $args;
    if ($self->{testNextPlugin} ne "true"){
	$commit .= " --commit";
    }

    $self->_runPlugin($signal, $plugin, "$commit", $msg, $doitProperty);
}

# param $doitProperty  - the name of a property which will have value 
#                        "no" if this step should be skipped. undef means
#                        don't skip
sub runPluginNoCommit {
    my ($self, $signal, $plugin, $args, $msg, $doitProperty) = @_;

    $self->_runPlugin($signal, $plugin, $args, $msg, $doitProperty);
}

sub runCmd {
    my ($self, $cmd) = @_;

    my $output = `$cmd`;
    my $status = $? >> 8;
    $self->error("Failed with status $status running: \n$cmd") if ($status);
    return $output;
}

sub runCmdInBackground {
    my ($self, $cmd) = @_;

    system("$cmd &");
    my $status = $? >> 8;
    $self->error("Failed running '$cmd' with stderr:\n $!") if ($status);
}

sub error {
    my ($self, $msg) = @_;

    unlink "$self->{pipelineDir}/signals/running";
    die "$msg\n\n";
}

#output message, write signal
sub exitWithMessage {
    my ($self, $msg, $signal) = @_;

    print STDERR $msg . "\n\n";
    $self->log($msg);
    unlink "$self->{pipelineDir}/signals/running";

    $self->endStep($signal);

    exit(0);
}    


sub runCmdOnLiniac {
    my ($self, $server, $cmd, $user) = @_;

    my $ssh_fro = ($user ? $user . '@' . $server : $server);
    $self->runCmd("ssh -2 $ssh_fro '$cmd'");
}

# Write out a message telling user what to start up on cluster, then exit
sub exitToCluster {
    my ($self, $cmdMsg, $logMsg, $immed) = @_;

    my $when = $immed? "immediately" : "when it completes";
    my $msg =
"EXITING.... PLEASE DO THE FOLLOWING:
 1. on the cluster server:
    - $cmdMsg
    - $logMsg
 2. resume $when by re-runnning '$self->{program} $self->{propertiesFile}'

";
	
    print STDERR $msg;
    $self->log($msg);
    unlink "$self->{pipelineDir}/signals/running";
    exit(0);
}    

# Write out a message telling user what to wait for on cluster, then exit
sub waitForCluster {
    my ($self, $task, $signal) = @_;

    my $s = "Wait for '$task' to complete on Cluster";

    return if $self->startStep($s, $signal);

    my $msg = 
"EXITING.... PLEASE DO THE FOLLOWING:
     - $s
     - Resume when complete by re-runnning '$self->{program} $self->{propertiesFile}'

";
	
    print STDERR $msg;
    $self->log($msg);
    $self->endStep($signal);
    unlink "$self->{pipelineDir}/signals/running";
    exit(0);
}     

sub manualTask {
  my ($self, $task, $signal) = @_;

  my $s = "Complete the following task:'$task'";

  return if $self->startStep($s, $signal);

  my $msg = 
    "EXITING.... PLEASE DO THE FOLLOWING:
     - $s
     - Resume when complete by re-runnning '$self->{program} $self->{propertiesFile}'";
  print STDERR $msg;
  $self->log($msg);
  $self->endStep($signal);
  unlink "$self->{pipelineDir}/signals/running";
  exit(0);
}

# exit pipeline 
sub goodbye {
    my ($self, $msg) = @_;
    $self->log($msg);
    unlink "$self->{pipelineDir}/signals/running";
    exit(0);
}

#############################################################################
#          Private Methods
#############################################################################

# private method to do the actual work of running the plugin
# param $args - must include '--commit' to do so.
#
# param $doitProperty  - the name of a property which will have value 
#                        "no" if this step should be skipped. undef means
#                        don't skip
sub _runPlugin {
    my ($self, $signal, $plugin, $args, $msg, $doitProperty) = @_;

    return if $self->startStep($msg, $signal, $doitProperty);
    
    my $err = "$self->{pipelineDir}/logs/$signal.err";
    my $out = "$self->{pipelineDir}/logs/$signal.out";

    my $comment = $args;
    $comment =~ s/"/\\"/g;

    my $cmd = "ga $plugin $args --comment \"$comment\"  >> $out 2>> $err";

    $self->runCmd("mkdir -p $self->{pipelineDir}/plugins/$signal");
    chdir "$self->{pipelineDir}/plugins/$signal";

    $self->runCmd($cmd);
    if ($self->{testNextPlugin} eq "true"){
	print STDERR "Tested next plugin.  Check $self->{pipelineDir}/logs/$signal" . ".err and $signal" . ".out for results\n\n";
	exit(0);
    }
    else{
	$self->endStep($signal);
    }
}

sub _getSignal {
    my ($self, $signal) = @_;

    return -e "$self->{pipelineDir}/signals/$signal";
}

sub _getSkip {
    my ($self, $signal) = @_;

    return -e "$self->{pipelineDir}/skip/$signal";
}

sub _setSignal {
    my ($self, $signal) = @_;

    $self->log("(writing signal $signal)\n\n");

    $self->runCmd("touch $self->{pipelineDir}/signals/$signal");
}

sub _waitForFiles {
    my ($self, $sleepSecs) = shift @_;
    my @files = @_;

    $self->log("Waiting for \n  " . join ("\n  ", @files) . "\n\n");

    my $c = 0;
    my $waiting;
    do {
	$waiting = 0;
	for (my $i=0; $i<scalar(@files); $i++) {
	    my $file = $files[$i];
	    if ($file) {
		if (-e $file) {
		    $files[$i] = 0;
		    $self->log("\n... found $file\n");
		    $c = 0
		} else {
		    $waiting = 1;
		}
	    }
	} 
	if ($waiting) {
	    sleep($sleepSecs);
	    $self->log($c++);
	    $c = 0 if $c == 10;
	}
    } while($waiting);
}

sub _createPipelineDir {
    my ($self) = @_;

    print "Creating pipeline dir $self->{pipelineDir}\n\n" unless -e $self->{pipelineDir};

    $self->runCmd("mkdir -p $self->{pipelineDir}/logs") unless -e "$self->{pipelineDir}/logs";
    $self->runCmd("mkdir -p $self->{pipelineDir}/signals") unless -e "$self->{pipelineDir}/signals";
    $self->runCmd("mkdir -p $self->{pipelineDir}/skip") unless -e "$self->{pipelineDir}/skip";
    $self->runCmd("mkdir -p $self->{pipelineDir}/plugins") unless -e "$self->{pipelineDir}/plugins";
}

sub _dieIfAlreadyRunning {
    my ($self) = @_;

    if (-e "$self->{pipelineDir}/signals/running") {
	print STDERR 
"
ERROR:  Looks like '$self->{program} $self->{propertiesFile}' is already running (found signal running).
        If it isn't really running, rm $self->{pipelineDir}/signals/running

";
	exit(1);
    }
}

1;
