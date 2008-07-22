package GUS::Pipeline::Workflow;

use strict;
use lib "$ENV{GUS_HOME}/lib/perl";
use XML::Simple;
use DBI;
use Data::Dumper;
use CBIL::Util::MultiPropertySet;

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

sub new {
  my ($class, $metaConfigFileName, $showParse) = @_;

  my $self = { 
      metaConfigFileName => $metaConfigFileName,
      showParse => $showParse
  };

  bless($self,$class);

  $self->initDb();  # write a row in the db for this workflow (unless already there)

  return $self;
}

sub run {

    $self->setRunningState(); # fail if already running

    $rootStep = $self->getStepGraph();  # parses workflow XML, validates graph

    $self->validateStepsConfig();

    $rootStep->initializeStepTable();

    $rootStep->initializeDependsTable();

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
SET state = $RUNNING
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
	my $simple = XML::Simple->new();

	# use forcearray so elements with one child are still arrays
	my $data = $simple->XMLin($sanityFile, forcearray => 1);

	if ($self->{showParse}) {
	    print Dumper($data);
	    print "\n\n\n";
	}
	my $stepsByName;
	foreach my $stepxml (@{$data->{workflow}->{step}}) {
	    die "non-unique step name: '$stepxml->{name}'" 
		if ($stepsByName->{$stepxml->{name}});
	    my $step = eval "{require $stepxml->{class};$stepxml->{class}->new($this, $stepxml->{name})}";
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
SET state = $RUNNING
WHERE workflow_id = $workflow_id
";

    $self->runSql($sql);
}

# always re-read this file so pilot can change it while workflow is running
sub getStepConfig {
    my ($self, $step, $prop) = @_;
    if (!$self->{stepsConfig}->{$step->getName()}) {
	my $stepsConfigDecl;
	$stepsConfigDecl->{$step->getName()} = $step->getConfigurationDeclaration();
	
	$self->{stepsConfig}->{$step->getName()}= 
	    CBIL::Util::MultiPropertySet->new($self->getMetaConfig('stepsConfigFile'),
					      $stepsConfigDecl, $step->getName());

    }
    return $self->getStepsConfig()->{$step->getName()}->getProp($prop);
}

sub validateStepsConfig {
    my ($self) = @_;
    
    my $stepsConfigDecl;
    foreach my $step (values(%{$self->{stepsByName}})) {
	$stepsConfigDecl->{$step->getName()} = $step->getConfigurationDeclaration();
    }
    
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

    my @properties = 
	(
	 # [name, default, description]
	 ['name', "", ""],
	 ['version', "", ""],
	 ['dbLogin', "", ""],
	 ['dbPassword', "", ""],
	 ['dbConnectString', "", ""],
	 ['numAllowedRunningSteps', "", ""],
	 ['homeDir', "", ""],
	 ['resourcesXmlFile', "", ""],
	 ['stepsConfigFile', "", ""],
	 ['workflowXmlFile', "", ""],
	);

    if (!$self->{metaConfig}) {
	$self->{metaConfig} = CBIL::Util::PropertySet->new($self->{metaConfigFileName},
	    \@properties);
    }
    return $self->{metaConfig}->getProp($key);
}

sub getId {
    my ($self) = @_;

    my $name = $self->getMetaConfig()->{name};
    my $name = $self->getMetaConfig()->{version};
    if (!$self->{workflow_id}) {
	my $sql = "
select workflow_id from apidb.workflow
where name = '$name'
and version = '$version'
";
	my ($workflow_id) = $self->runSqlQuery_single_array($sql);
	if (!$workflow_id) {
	    $sql = "select next from sequence ???";
	    my ($workflow_id) = $self->runSqlQuery_single_array($sql);
	    $sql = "
INSERT INTO workflow (workflow_id, name, version)
VALUES ($workflow_id, '$name', '$version')
";
	    $self->runSql($sql);
	}
    }
    return $self->{workflow_id};
}

sub getDbh {
    my ($self) = @_;
    if (!$self->{dbh}) {
	my $metaConfig = $self->getMetaConfig();
	my $self->{dbh} = DBI->connect($metaConfig->{dbConnectString},
				       $metaConfig->{dbLogin},
				       $metaConfig->{dbPassword}) or die DBI::errstr;
    }
    return $self->{dbh};
}

sub runSql {
    my ($self,$sql) = @_;
    my $dbh = $self->{workflow}->getDbh();
    my $stmt = $dbh->prepare("$sql") or die DBI::errstr;
    $stmt->execute() or die DBI::errstr;
}

sub runSqlQuery_single_array {
    my $stmt = $self->getDbh()->prepare($sql);
    $stmt->execute();
    return $stmt->fetchrow_array();
}
