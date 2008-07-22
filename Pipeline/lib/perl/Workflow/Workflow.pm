package GUS::Pipeline::Workflow;

# to do
# - xml validation
# - include/exclude
# - integrate resource pipeline
# - start/stop steps
# - nested workflows
# - reset option (clears running flag)
# - always re-read config file
# - dynamically change allowed num running steps

my $RUNNING = 'running';
my $DONE = 'done';

sub new {
  my ($class, $metaConfigFileName, $workflowXmlFileName) = @_;

  my $self = { 
      metaConfigFileName => $metaConfigFileName,
      workflowXmlFileName => $workflowXmlFileName,
  };


  bless($self,$class);

  $self->initDb();  # write a row in the db for this workflow (unless already there)

  return $self;
}

sub run {

    $self->setRunningFlag(); # fail if already running

    $rootStep = $self->getStepGraph();  # parses workflow XML, validates graph

    $rootStep->initializeDb(); # make sure graph is in db (in future, check if xml has changed)

    while (1) {
	my $runningStepsCount = $rootStep->processChangesSinceLastPoll();
	if ($runningStepsCount == -1) {
	    $self->setDoneFlag();
	    exit(0);
	}
    
	if ($runningStepsCount < $self->getMetaConfig()->{numAllowedRunningSteps}) {
	    $rootStep->runAvailableStep();
	}
	sleep(2);
    }
}

sub setRunningFlag {
    my ($self) = @_;

    my $workflow_id = $self->getId();
    my $sql = "select state from apidb.workflow where workflow_id = $workflow_id";
    my ($state) = runSqlQuery_single_array($sql);
    $self->error("already running") if ($state eq $RUNNING);
    
    $sql = "
UPDATE apidb.Workflow
SET (
  state = $RUNNING
)
WHERE workflow_id = $workflow_id
";

    $self->runSql($sql);
}

# traverse a workflow XML, making Step objects as we go
# also parse the step config file, giving each step its individual config
sub getStepGraph {
    my ($self) = @_;

    if (!$self->{graph}) {

	my $metaConfig = $self->getMetaConfig();

	# following code is per step 
	my $stepConfig = getStepConfig($stepName);
	require $stepClass;
	exec "${stepClass}->new($self, $stepName)";
    }
    return $self->{graph};
    
}

sub setDoneFlag {
    my ($self) = @_;

    my $workflow_id = $self->getId();
    
    my $sql = "
UPDATE apidb.Workflow
SET (
  state = $RUNNING
)
WHERE workflow_id = $workflow_id
";

    $self->runSql($sql);
}

# parse step config file
sub getStep {
    my ($self, $stepName) = @_;
    my $step = $self->{stepsByName}->{$stepName};
    $step->setDbh($self->getDbh());
}

# always re-read this file so pilot can change it while workflow is running
sub getStepConfig {
    my ($self, $stepName) = @_;

}

sub getMetaConfigFileName {
    my ($self) = @_;
    return $self->{metaConfigFileName};
}

# parse meta config file
sub getMetaConfig {
    my ($self) = @_;
    # properties:
    #  name
    #  version
    #  dbLogin
    #  dbPassword
    #  dbConnectString
    #  numAllowedRunningSteps 
    #  homeDir
    #  resourcesXmlFile
    #  stepsConfigFile
    
    if (!$self->{metaConfig}) {
	# use CBIL PropertySet object for this.
    }
    return $self->{metaConfig};

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

	my $stmt = $self->getDbh()->prepare($sql);
	$stmt->execute();
	my ($workflow_id) = $stmt->fetchrow_array();
	if (!$workflow_id) {
	    $sql = "select next from sequence ???";
	    my $stmt = $self->getDbh()->prepare($sql);
	    $stmt->execute();
	    my ($workflow_id) = $stmt->fetchrow_array();
	    $sql = "
insert into apidb.workflow
???
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
