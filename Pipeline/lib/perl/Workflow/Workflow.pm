package GUS::Pipeline::Workflow::Workflow;

@ISA = qw(GUS::Pipeline::Workflow::Base);
use strict;
use GUS::Pipeline::Workflow::Base;
use GUS::Pipeline::Workflow::WorkflowStep;
use XML::Simple;
use Data::Dumper;

# to do
# - xml validation
# - include/exclude
# - integrate resource pipeline
# - start/stop steps
# - nested workflows
# - reset option (clears running flag)
# - dynamically change allowed num running steps
# - handle changes to graph after running
# - cascading defaults for config file
# - check for graph cycles

my $RUNNING = 'RUNNING';
my $DONE = 'DONE';
my $START = 'START';
my $END = 'END';

# very light reporting of state of workflow
sub reportState {
    my ($self) = @_;

    $self->getDbState();

    print "
Workflow '$self->{name} $self->{version}'
workflow_id:           $self->{workflow_id}
state:                 $self->{state}
process_id:            $self->{process_id}
start_time:            $self->{start_time}
end_time:              $self->{end_time}
allowed_running_steps: $self->{allowed_running_steps}
\n\n";
}

sub reportSteps {
    my ($self, $desiredStates) = @_;

    my $startStep = $self->getStepGraph();  # parses workflow XML, validates graph

    $self->initDb($startStep);  # write workflow to db, if not already there

    $self->reportState();

    my @sortedStepNames = sort(keys(%{$self->{stepsByName}}));
    foreach my $desiredState (@$desiredStates) {
	print "=============== $desiredState steps ================\n";
	foreach my $stepName (@sortedStepNames) {
	    my $step = $self->{stepsByName}->{$stepName};

	    if ($step->getState() eq $desiredState) {
		$step->toString();
		print "-----------------------------------------\n";
	    }
	}
    }
}

sub run {
    my ($self, $numSteps) = @_;

    my $startStep = $self->getStepGraph(); # parses workflow XML, validates graph

    $self->initDb($startStep);             # write workflow to db, if not already there

    $self->getDbState();                   # read state from db

    $self->validateStepsConfig();          # validate config of all steps.

    $self->initHomeDir();                  # initialize workflow home directory

    $self->setRunningState($numSteps);     # set db state. fail if already running

    # start polling
    while (1) {
	my $runningStepsCount = $startStep->handleChangesSinceLastPoll();
	if ($runningStepsCount == -1) {
	    $self->setDoneState();
	    exit(0);
	}

	if ($runningStepsCount < $self->{allowed_running_steps}) {
	    $startStep->runOnDeckStep();
	}
	sleep(2);
    }
}

# traverse a workflow XML, making Step objects as we go
# also parse the step config file, giving each step its individual config
# NEED TO DEAL WITH START AND END STEPS
sub getStepGraph {
    my ($self) = @_;

    if (!$self->{graph}) {
	my $workflowXmlFile = $self->getMetaConfig('workflowXmlFile');
        $self->log("Parsing and validating $workflowXmlFile");

#	open(FILE, $workflowXmlFile) || $self->error("can't open workflow XML file '$workflowXmlFile'");
#	close(FILE);
	my $simple = XML::Simple->new();

	# use forcearray so elements with one child are still arrays
	my $data = $simple->XMLin($workflowXmlFile, forcearray => 1,
				  KeyAttr => {sqlValue=>'+name'});

	foreach my $stepxml (@{$data->{step}}) {
	    $self->error("non-unique step name: '$stepxml->{name}'")
		if ($self->{stepsByName}->{$stepxml->{name}});
	    require GUS::Pipeline::Workflow::TestStep;
	    GUS::Pipeline::Workflow::TestStep->new();exit;
	    my $s = "{require $stepxml->{class};$stepxml->{class}->new()}";
	    my $step = eval $s;
	    $self->error($@) if $@;
	    $step->setWorkflow($self);
	    $step->setName($stepxml->{name});
	    $self->{stepsByName}->{$stepxml->{name}} = $step;
	    $step->{dependsNames} = $stepxml->{depends};
	}
	foreach my $step (values(%{$self->{stepsByName}})) {
	    foreach my $dependName (@{$step->{dependsNames}}) {
		my $stepName = $step->getName();
		my $parent = $self->{stepsByName}->{$dependName->{name}};
		$self->error("step '$stepName' depends on '$dependName->{name}' which is not found") unless $parent;
		$parent->addChild($step);
	    }
	}
	my $startStep = GUS::Pipeline::Workflow::WorkflowStep->new();
	$startStep->setFakeStepType($START);
	$startStep->setWorkflow($self);
	$startStep->setName($START);
	my $endStep = GUS::Pipeline::Workflow::WorkflowStep->new();
	$endStep->setFakeStepType($END);
	$endStep->setWorkflow($self);
	$endStep->setName($END);
	foreach my $step (values(%{$self->{stepsByName}})) {
	  $startStep->addChild($step) if scalar(@{$step->getParents()}) == 0;
	  $step->addChild($endStep) if scalar(@{$step->getChildren()}) == 0;
	}
	$self->{graph} = $startStep;
    }
    return $self->{graph};
}

# write the workflow and steps to the db
# for now, assume the workflow steps don't change for the life of a workflow
sub initDb {
    my ($self, $startStep) = @_;

    $self->{name} = $self->getMetaConfig('name');
    $self->{version} = $self->getMetaConfig('version');

    my $sql = "
select workflow_id
from apidb.workflow
where name = '$self->{name}'
and version = '$self->{version}'
";
    ($self->{workflow_id}) = $self->runSqlQuery_single_array($sql);
    return if ($self->{workflow_id});

    $self->log("Initializing workflow '$self->{name}$self->{version}' in database");

    # write workflow row
    my $sql = "select apidb.Workflow_sq.nextval from dual";
    $self->{workflow_id} = $self->runSqlQuery_single_array($sql);
    $sql = "
INSERT INTO apidb.workflow (workflow_id, name, version)
VALUES ($self->{workflow_id}, '$self->{name}', '$self->{version}')
";
    $self->runSql($sql);

    # write all steps
    $startStep->initializeStepTable();

    $startStep->initializeDependsTable();
}

sub getDbState {
    my ($self) = @_;
    if (!$self->{workflow_id}) {
	$self->{name} = $self->getMetaConfig('name');
	$self->{version} = $self->getMetaConfig('version');
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

# read all steps config and validate
sub validateStepsConfig {
    my ($self) = @_;

    my $stepsConfigFile = $self->getMetaConfig('stepsConfigFile');

    $self->log("Validating steps config file '$stepsConfigFile'");

    # get hash of all step config declarations
    my $stepsConfigDecl;
    foreach my $step (values(%{$self->{stepsByName}})) {
	$stepsConfigDecl->{$step->getName()} = $step->getConfigDeclaration();
    }

    # this object will do the validation
    CBIL::Util::MultiPropertySet->new($stepsConfigFile, $stepsConfigDecl);
}

sub initHomeDir {
    my ($self) = @_;

    my $homeDir = $self->getMetaConfig('homeDir');

    $self->log("Initializing workflow home directory '$homeDir'")
      unless -e "$homeDir/steps";;
    $self->runCmd("mkdir -p $homeDir/steps") unless -e "$homeDir/steps";
    $self->runCmd("mkdir -p $homeDir/externalFiles") unless -e "$homeDir/externalFiles";
}

sub setRunningState {
    my ($self, $numSteps) = @_;

    $self->error("already running") if ($self->{state} eq $RUNNING);

    $self->log("Setting state to $RUNNING and allowed number of running steps to $numSteps");

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
SET state = $DONE
WHERE workflow_id = $workflow_id
";

    $self->runSql($sql);
}


sub getId {
    my ($self) = @_;
    return $self->{workflow_id};
}

sub log {
    my ($self, $msg) = @_;

    my $homeDir = $self->getMetaConfig('homeDir');

    open(LOG, ">>$homeDir/workflow.log")
      || die "can't open log file '$homeDir/workflow.log'";
    print LOG "$msg\n";
    close (LOG);
}

sub documentStep {
  my ($self, $signal, $documentInfo, $doitProperty) = @_;

  return if (!$self->{justDocumenting}
	     || ($doitProperty
		 && $self->{propertySet}->getProp($doitProperty) eq "no"));

  my $documenter = GUS::Pipeline::StepDocumenter->new($signal, $documentInfo);
  $documenter->printXml();
}

1;
