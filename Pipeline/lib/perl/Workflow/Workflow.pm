package GUS::Pipeline::Workflow::Workflow;

@ISA = qw(GUS::Pipeline::Workflow::Base);
use strict;
use lib "$ENV{GUS_HOME}/lib/perl";
use XML::Simple;
use Data::Dumper;

# to do
# - xml validation
# - include/exclude
# - integrate resource pipeline
# - start/stop steps
# - nested workflows
# - reset option (clears running flag)
# - always re-read config file
# - dynamically change allowed num running steps
# - handle changes to graph after running
# - cascading defaults for config file

my $RUNNING = 'running';
my $DONE = 'done';

# very light reporting of state of workflow
sub reportState {
    my ($self) = @_;

    $self->getDbState();

    print 
"Workflow '$self->{name}' version '$self->{version}
workflow_id = $self->{id}
state       = $self->{state}
process_id  = $self->{process_id}
start_time  = $self->{start_time}
end_time    = $self->{end_time}
'\n\n";
}

sub reportSteps {
    my ($self, $desiredStates) = @_;

    my $rootStep = $self->getStepGraph();  # parses workflow XML, validates graph

    $self->initDb($rootStep);  # write workflow to db, if not already there
    
    $self->reportState();

    my @sortedStepNames = sort(keys(%{$self->{stepsByName}}));
    foreach my $desiredState (@$desiredStates) {
	print "=============== $desiredState steps ================\n\n";
	foreach my $stepName (@sortedStepNames) {
	    my $step = $self->{stepsByName}->{$stepName};
	    if ($step->getState() eq $desiredState) {
		$step->toString();
		print "\n";
	    }
	}
    }

    $rootStep->toString();
}

sub run {
    my ($self) = @_;

    my $rootStep = $self->getStepGraph();  # parses workflow XML, validates graph

    $self->initDb($rootStep);  # write workflow to db, if not already there

    $self->setRunningState(); # fail if already running

    $self->validateStepsConfig();  # validate the config of all steps.

    while (1) {
	my $runningStepsCount = $rootStep->processChangesSinceLastPoll();
	if ($runningStepsCount == -1) {
	    $self->setDoneState();
	    exit(0);
	}
    
	if ($runningStepsCount < $self->getMetaConfig('numAllowedRunningSteps')) {
	    $rootStep->runAvailableStep();
	}
	sleep(2);
    }
}

sub setRunningState {
    my ($self) = @_;

    my $workflow_id = $self->getId();
    my $sql = "select state from apidb.workflow where workflow_id = $workflow_id";
    my ($state) = runSqlQuery_single_array($sql);
    $self->error("already running") if ($state eq $RUNNING);
    
    $sql = "
UPDATE apidb.Workflow
SET state = $RUNNING, process_id = $$
WHERE workflow_id = $workflow_id
";

    $self->runSql($sql);
}

# traverse a workflow XML, making Step objects as we go
# also parse the step config file, giving each step its individual config
# NEED TO DEAL WITH START AND END STEPS
sub getStepGraph {
    my ($self) = @_;

    if (!$self->{graph}) {

	my $stepsConfig = $self->getStepsConfig();

	my $workflowXmlFile = $self->getMetaConfig('workflowXmlFile');
	open(FILE, $workflowXmlFile) || die "can't open workflow XML file '$workflowXmlFile'\n";
	close(FILE);
	my $simple = XML::Simple->new();

	# use forcearray so elements with one child are still arrays
	my $data = $simple->XMLin($workflowXmlFile, forcearray => 1);

	my $stepsByName;
	foreach my $stepxml (@{$data->{workflow}->{step}}) {
	    die "non-unique step name: '$stepxml->{name}'" 
		if ($stepsByName->{$stepxml->{name}});
	    my $step = eval "{require $stepxml->{class};$stepxml->{class}->new($self, $stepxml->{name})}";
	    $self->error($@) if $@;
	    $stepsByName->{$stepxml->{name}} = $step;  
	    $step->{dependsNames} = $stepxml->{depends};
	    $step->setDbh($self->getDbh());
	}
	foreach my $step (values(%{$stepsByName})) {
	    foreach my $dependName (@{$step->{dependsNames}}) {
		my $stepName = $step->getName();
		my $parent = $stepsByName->{$dependName};
		die "step '$stepName' depends on '$dependName' which is not found" unless $parent;
		$parent->addChild($step);
	    }
	}
    }
    return $self->{graph};
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


# read all steps config and validate
sub validateStepsConfig {
    my ($self) = @_;
    
    # get hash of all step config declarations
    my $stepsConfigDecl;
    foreach my $step (values(%{$self->{stepsByName}})) {
	$stepsConfigDecl->{$step->getName()} = $step->getConfigurationDeclaration();
    }
    
    # this object will do the validation
    CBIL::Util::MultiPropertySet->new($self->getMetaConfig('stepsConfigFile'),
				      $stepsConfigDecl);
}

sub getMetaConfigFileName {
    my ($self) = @_;
    return $self->{metaConfigFileName};
}

# parse meta config file
sub getMetaConfig {
    my ($self, $key) = @_;

    return GUS::Pipeline::Workflow::Shared::getMetaConfig($self,
							 $self->{metaConfigFileName},
							 $key);
}

# write the workflow and steps to the db
# for now, assume the workflow steps don't change for the life of a workflow
sub initDb {
    my ($self, $rootStep) = @_;
    
    return if $self->getId();

    # write workflow row
    my $name = $self->getMetaConfig('name');
    my $version = $self->getMetaConfig('version');
    my $sql = "select apidb.Workflow_sq.nextval from dual";
    $self->{workflow_id} = $self->runSqlQuery_single_array($sql);
    $sql = "
INSERT INTO workflow (workflow_id, name, version)
VALUES ($self->{workflow_id}, '$name', '$version')
";
    $self->runSql($sql);

    # write all steps
    $rootStep->initializeStepTable();

    $rootStep->initializeDependsTable();
}

sub getId {
    my ($self) = @_;
    $self->getDbState();
    return $self->{workflow_id};
}

sub getDbState {
    my ($self) = @_;
    if (!$self->{workflow_id}) {
	my $name = $self->getMetaConfig('name');
	my $version = $self->getMetaConfig('version');
	my $sql = "
select workflow_id, state, process_id, start_time, end_time
from apidb.workflow
where name = '$name'
and version = '$version'
";
	($self->{workflow_id}, $self->{state}, $self->{process_id},
	 $self->{start_time}, $self->{end_time}) 
	    = $self->runSqlQuery_single_array($sql);
	die "workflow '$name' version '$version' not in database" unless $self->{workflow_id};
    }
}

