package GUS::Pipeline::Workflow::Base;

use strict;
use lib "$ENV{GUS_HOME}/lib/perl";
use DBI;
use Data::Dumper;
use CBIL::Util::MultiPropertySet;

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
	$stepsConfigDecl->{$step->getName()} = $step->getConfigurationDeclaration();

	$self->{stepsConfig}->{$step->getName()}= 
	    CBIL::Util::MultiPropertySet->new($self->getMetaConfig('stepsConfigFile'),
					      $stepsConfigDecl, $step->getName());

    }

    return $self->{stepsConfig}->{$step->getName()}->getProp($prop);
}
