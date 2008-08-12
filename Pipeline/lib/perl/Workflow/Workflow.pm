package GUS::Pipeline::Workflow::Workflow;

@ISA = qw(GUS::Pipeline::Workflow::WorkflowHandle);
use strict;
use GUS::Pipeline::Workflow::WorkflowHandle;
use GUS::Pipeline::Workflow::WorkflowStep;
use XML::Simple;
use Data::Dumper;

# to do
# - xml validation
# - include/exclude
# - integrate resource pipeline
# - nested workflows
# - dynamically change allowed num running steps
# - handle changes to graph after running
# - cascading defaults for config file
# - check for graph cycles
# - compute cluster
# - make running order repeatable (sort by order in xml file)
# - improve log formatting
# - possibly support taking DONE steps offline.  this will require recursion.

my $RUNNING = 'RUNNING';
my $ON_DECK = 'ON_DECK';
my $DONE = 'DONE';
my $READY = 'READY';
my $FAILED = 'FAILED';
my $START = 'START';
my $END = 'END';

##
## Workflow object that runs in two contexts:
##   - step reporter
##   - controller
##


## Controller theoretical issues

## Race conditions
# the controller gets a snapshot of the db each cycle. one class of possible
# race conditions is if there are external changes since the snapshot was
# taken. the controller only updates the state in the database if the state
# in the db is the same as in memory, ie, the same as in the snapshot.  this
# preserves any external change to be seen by the next cycle.
#
# this leaves the problem of (a) more than one external change happening
# within a cycle.  but, there are no transitory states that matter. The only
# consequence is that the intermediate state won't be logged.  the only
# one of these which could realistically happen in the timeframe of a cycle
# is the transition from RUNNING to DONE, if a step executes quickly.  In this
# case, the log will show only DONE, without ever showing RUNNING, which is ok.
#
# and also the problem of (b) that the controller could not write the step's
# state because the state had changed since the snapshot.  the controller
# only writes the ON_DECK and FAILED states.  the next cycle will handle
# these correctly.

$| = 1;

# Step Reporter: called by command line UI to report state of steps. does not
# run the controller
sub reportSteps {
  my ($self, $desiredStates) = @_;
  $self->{noLog} = 1;

  $self->initSteps();

  $self->getDbSnapshot();	     # read state of Workflow and WorkflowSteps

  $self->reportState();

  my @sortedStepNames = sort(keys(%{$self->{stepsByName}}));
  if (scalar(@$desiredStates) == 0) {
    $desiredStates = [$READY, $ON_DECK, $RUNNING, $DONE, $FAILED];
  }
  foreach my $desiredState (@$desiredStates) {
    print "=============== $desiredState steps ================\n";
    foreach my $stepName (@sortedStepNames) {
      my $step = $self->{stepsByName}->{$stepName};
      if ($step->getState() eq $desiredState) {
	print $step->toString();
	print $self->{stepsConfig}->toString($stepName);
	print "-----------------------------------------\n";
      }
    }
  }
}

# run the controller
sub run {
  my ($self, $numSteps) = @_;

  $self->initHomeDir();		     # initialize workflow home directory

  $self->initSteps();                # parse graph xml and config, and init db

  $self->getDbSnapshot();	     # read state of Workflow and WorkflowSteps

  $self->setRunningState($numSteps); # set db state. fail if already running

  # start polling
  while (1) {
    $self->getDbSnapshot();
    last if $self->handleStepChanges();  # return true if all steps done
    $self->findOndeckSteps();
    $self->fillOpenSlots();
    sleep(2);
  }
}

sub initSteps {
  my ($self) = @_;

  $self->getStepGraph();        # parses workflow XML, validates graph

  $self->initDb();              # write workflow to db, if not already there

  $self->getStepsConfig();      # validate config of all steps.
}

# traverse a workflow XML, making Step objects as we go
sub getStepGraph {
  my ($self) = @_;

  if (!$self->{stepsByName}) {
    my $fileName = $self->getWorkflowConfig('workflowFile');
    my $workflowXmlFile = "$ENV{GUS_HOME}/lib/xml/workflow/$fileName";

    $self->log("Parsing and validating $workflowXmlFile");

    # parse the XML.
    # use forcearray so elements with one child are still arrays
    my $simple = XML::Simple->new();
    my $data = $simple->XMLin($workflowXmlFile, forcearray => 1,
			      KeyAttr => {sqlValue=>'+name'});

    # make each step object, remembering dependencies as a string
    foreach my $stepxml (@{$data->{step}}) {
      $self->error("non-unique step name: '$stepxml->{name}'")
	if ($self->{stepsByName}->{$stepxml->{name}});

      my $step = GUS::Pipeline::Workflow::WorkflowStep->
	new($stepxml->{name}, $self, $stepxml->{class});

      $self->{stepsByName}->{$stepxml->{name}} = $step;
      $step->{dependsNames} = $stepxml->{depends};
    }

    # in second pass, make the parent/child links from the remembered
    # dependenceies
    foreach my $step (values(%{$self->{stepsByName}})) {
      foreach my $dependName (@{$step->{dependsNames}}) {
	my $stepName = $step->getName();
	my $parent = $self->{stepsByName}->{$dependName->{name}};
	$self->error("step '$stepName' depends on '$dependName->{name}' which is not found") unless $parent;
	$step->addParent($parent);
      }
    }
  }
}

# write the workflow and steps to the db
# for now, assume the workflow steps don't change over the life of a workflow
sub initDb {
  my ($self) = @_;

  $self->{name} = $self->getWorkflowConfig('name');
  $self->{version} = $self->getWorkflowConfig('version');

  # don't bother if already in db
  my $sql = "
select workflow_id
from apidb.workflow
where name = '$self->{name}'
and version = '$self->{version}'
";
  my ($workflow_id) = $self->runSqlQuery_single_array($sql);
  return if ($workflow_id);

  # otherwise, do it...
  $self->log("Initializing workflow '$self->{name} $self->{version}' in database");

  # write row to Workflow table
  my $sql = "select apidb.Workflow_sq.nextval from dual";
  $self->{workflow_id} = $self->runSqlQuery_single_array($sql);
  $sql = "
INSERT INTO apidb.workflow (workflow_id, name, version)
VALUES ($self->{workflow_id}, '$self->{name}', '$self->{version}')
";
  $self->runSql($sql);

  # write all steps to WorkflowStep table
  my $stmt = 
    GUS::Pipeline::Workflow::WorkflowStep::getPreparedInsertStmt($self->getDbh(), $self->{workflow_id});
  foreach my $step (values %{$self->{stepsByName}}) {
      $step->initializeStepTable($stmt);
  }

  # update steps in memory, to get their new IDs
  $self->getWorkflowStepsDbSnapshot();
}

sub getStep {
  my ($self, $stepName) = @_;

  my $step = $self->{stepsByName}->{$stepName};
  $self->error("Can't find step with name '$stepName'") unless $step;
}

sub getDbSnapshot {
  my ($self) = @_;

  $self->getWorkflowDbSnapshot();
  $self->getWorkflowStepsDbSnapshot();
}

sub getWorkflowDbSnapshot {
  my ($self) = @_;

  if (!$self->{workflow_id}) {
    $self->{name} = $self->getWorkflowConfig('name');
    $self->{version} = $self->getWorkflowConfig('version');
    my $sql = "
select workflow_id, state, process_id, start_time, end_time, allowed_running_steps
from apidb.workflow
where name = '$self->{name}'
and version = '$self->{version}'
";
    ($self->{workflow_id}, $self->{state}, $self->{process_id},
     $self->{start_time}, $self->{end_time}, $self->{allowed_running_steps})
      = $self->runSqlQuery_single_array($sql);

    $self->error("workflow '$self->{name}' version '$self->{version}' not in database")
      unless $self->{workflow_id};
  }
}

# read all WorkflowStep rows into memory (and remember the prev snapshot)
sub getWorkflowStepsDbSnapshot {
    my ($self) = @_;

    $self->{snapshotNum}++;   # identifier of this snapshot
    $self->{prevStepsSnapshot} = $self->{stepsSnapshot};
    $self->{stepsSnapshot} = {};

    my $sql = GUS::Pipeline::Workflow::WorkflowStep::getBulkSnapshotSql($self->{workflow_id});

    # run query to get all rows from WorkflowStep for this workflow
    # stuff each row into the snapshot, keyed on step name
    my $stmt = $self->getDbh()->prepare($sql);
    $stmt->execute();
    while (my $rowHashRef = $stmt->fetchrow_hashref()) {
	$self->{stepsSnapshot}->{$rowHashRef->{NAME}} = $rowHashRef;
    }
}

# iterate through steps, checking on changes since last snapshot
# while we're passing through, count how many steps are running
sub handleStepChanges {
    my ($self) = @_;

    $self->{runningCount} = 0;
    my $notDone = 0;
    foreach my $step (values(%{$self->{stepsByName}})) {
	$self->{runningCount} += $step->handleChangesSinceLastSnapshot();
	$notDone |= ($step->getState() ne $DONE);
    }
    if (!$notDone) { $self->setDoneState(); }
    return !$notDone;
}

sub findOndeckSteps {
    my ($self) = @_;

    foreach my $step (values(%{$self->{stepsByName}})) {
	$step->maybeGoToOnDeck();
    }
}

sub fillOpenSlots {
    my ($self) = @_;

    foreach my $step (values(%{$self->{stepsByName}})) {
	last if $self->{runningCount} >= $self->{allowed_running_steps};
	$self->{runningCount} += $step->runOnDeckStep();
    }
}

# read and validate all steps config
sub getStepsConfig {
  my ($self) = @_;

  if (!$self->{stepsConfig}) {

    my $stepsConfigFile = "$self->{homeDir}/config/steps.prop";

    $self->log("Validating Step classes and step config file '$stepsConfigFile'");

    # for each step in the graph, instantiate its invoker, and get the
    # invoker's config declaration.  compare that against the step config file
    my $stepsConfigDecl;
    my $stepInvokers;
    foreach my $step (values(%{$self->{stepsByName}})) {
      my $invokerClass = $step->getInvokerClass();
      if (!$stepInvokers->{$invokerClass}) {
	$stepInvokers->{$invokerClass}
	  = eval "{require $invokerClass; $invokerClass->new()}";
	$self->error($@) if $@;
      }
      $stepsConfigDecl->{$step->getName()} =
	$stepInvokers->{$invokerClass}->getConfigDeclaration();
    }

    # this object does the validation
    $self->{stepsConfig} =
      CBIL::Util::MultiPropertySet->new($stepsConfigFile, $stepsConfigDecl);
  }
  return $self->{stepsConfig};
}

sub initHomeDir {
  my ($self) = @_;

  my $homeDir = $self->getHomeDir();

  return if -e "$homeDir/steps";
  $self->runCmd("mkdir -p $homeDir/logs") unless -e "$homeDir/logs";
  $self->runCmd("mkdir -p $homeDir/steps") unless -e "$homeDir/steps";
  $self->runCmd("mkdir -p $homeDir/externalFiles") unless -e "$homeDir/externalFiles";
  $self->log("Initializing workflow home directory '$homeDir'");
}

sub setRunningState {
  my ($self, $numSteps) = @_;

  if ($self->{state} eq $RUNNING) {
    system("ps -p $self->{process_id} > /dev/null");
    my $status = $? >> 8;
    if (!$status) {
      $self->error("workflow already running (process $self->{process_id})");
    }
  }
  $self->log("Setting workflow state to $RUNNING and allowed-number-of-running-steps to $numSteps (process id = $$)");

  $self->{allowed_running_steps} = $numSteps;

  my $sql = "
UPDATE apidb.Workflow
SET state = '$RUNNING', process_id = $$, allowed_running_steps = $numSteps
WHERE workflow_id = $self->{workflow_id}
";

  $self->runSql($sql);
}

sub setDoneState {
  my ($self) = @_;

  my $workflow_id = $self->getId();

  my $sql = "
UPDATE apidb.Workflow
SET state = '$DONE', process_id = NULL
WHERE workflow_id = $workflow_id
";

  $self->runSql($sql);
  $self->log("Workflow $DONE");
}


sub getId {
  my ($self) = @_;
  return $self->{workflow_id};
}

sub log {
  my ($self, $msg) = @_;
  return if $self->{noLog};

  my $homeDir = $self->getHomeDir();

  open(LOG, ">>$homeDir/logs/controller.log")
    || die "can't open log file '$homeDir/logs/controller.log'";
  print LOG localtime() . " $msg\n\n";
  close (LOG);
}

# not working yet
sub documentStep {
  my ($self, $signal, $documentInfo, $doitProperty) = @_;

  return if (!$self->{justDocumenting}
	     || ($doitProperty
		 && $self->{propertySet}->getProp($doitProperty) eq "no"));

  my $documenter = GUS::Pipeline::StepDocumenter->new($signal, $documentInfo);
  $documenter->printXml();
}

sub runCmd {
    my ($self, $cmd) = @_;

    my $output = `$cmd`;
    my $status = $? >> 8;
    $self->error("Failed with status $status running: \n$cmd") if ($status);
    return $output;
}

1;
