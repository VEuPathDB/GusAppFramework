package GUS::Pipeline::Workflow::Base;

use strict;
use DBI;
use CBIL::Util::MultiPropertySet;
use CBIL::Util::PropertySet;

# methods shared by the perl controller and perl step wrapper.
# any other language implementation would presumably need equivalent code
sub new {
  my ($class, $metaConfigFileName) = @_;

  my $self = { 
      metaConfigFileName => $metaConfigFileName,
  };

  bless($self,$class);

  return $self;
}

sub getDbh {
    my ($self) = @_;
    if (!$self->{dbh}) {
	$self->{dbh} = DBI->connect($self->getMetaConfig('dbConnectString'),
				    $self->getMetaConfig('dbLogin'),
				    $self->getMetaConfig('dbPassword'))
	  or die DBI::errstr;
    }
    return $self->{dbh};
}

sub runSql {
    my ($self,$sql) = @_;
    my $dbh = $self->getDbh();
    my $stmt = $dbh->prepare("$sql") or die DBI::errstr;
    $stmt->execute() or die DBI::errstr;
}

sub runSqlQuery_single_array {
    my ($self, $sql) = @_;
    my $stmt = $self->getDbh()->prepare($sql);
    $stmt->execute();
    return $stmt->fetchrow_array();
}

# get an individual config property for a step
# if we haven't already read the step's config, do so, validating as well
sub getStepConfig {
    my ($self, $step, $prop) = @_;

    $self->{stepsConfig} = {} unless $self->{stepsConfig};

    # acquire step config if we don't already have it
    if (!$self->{stepsConfig}->{$step->getName()}) {
	my $stepsConfigDecl;
	$stepsConfigDecl->{$step->getName()} = $step->getConfigDeclaration();

	$self->{stepsConfig}->{$step->getName()}= 
	    CBIL::Util::MultiPropertySet->new($self->getMetaConfig('stepsConfigFile'),
					      $stepsConfigDecl, $step->getName());

    }

    return $self->{stepsConfig}->{$step->getName()}->getProp($prop);
}

sub getMetaConfigFileName {
    my ($self) = @_;
    return $self->{metaConfigFileName};
}

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

    die "$msg\n\n";
}

1;
