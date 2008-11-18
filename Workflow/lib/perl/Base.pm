package GUS::Workflow::Base;

use Exporter;
@ISA = qw(Exporter);
our @EXPORT = qw($READY $ON_DECK $FAILED $DONE $RUNNING $START $END);

use strict;
use DBI;
use CBIL::Util::MultiPropertySet;
use CBIL::Util::PropertySet;

BEGIN {
# allowed states
  our $READY = 'READY';      # my parents are not done yet  -- default state
  our $ON_DECK = 'ON_DECK';  # my parents are done, but there is no slot for me
  our $FAILED = 'FAILED';
  our $DONE = 'DONE';
  our $RUNNING = 'RUNNING';
  our $WAITING_FOR_PILOT = 'WAITING_FOR_PILOT';  # not used yet.

  our $START = 'START';
  our $END = 'END';
}

# methods shared by the perl controller and perl step wrapper.
# any other language implementation would presumably need equivalent code
sub new {
  my ($class, $homeDir) = @_;

  my $self = {
      homeDir => $homeDir,
  };

  bless($self,$class);

  return $self;
}

sub getDbh {
    my ($self) = @_;
    if (!$self->{dbh}) {
	$self->{dbh} = DBI->connect($self->getWorkflowConfig('dbiConnectString'),
				    $self->getWorkflowConfig('dbLogin'),
				    $self->getWorkflowConfig('dbPassword'))
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

sub getWorkflowHomeDir {
    my ($self) = @_;
    return $self->{homeDir};
}

sub getWorkflowConfig {
    my ($self, $key) = @_;

    my @properties = 
	(
	 # [name, default, description]
	 ['name', "", ""],
	 ['version', "", ""],
	 ['dbLogin', "", ""],
	 ['dbPassword', "", ""],
	 ['dbiConnectString', "", ""],
	 ['jdbcConnectString', "", ""],
	 ['workflowXmlFile', "", ""],
	);

    if (!$self->{workflowConfig}) {
      my $workflowConfigFile = "$self->{homeDir}/config/workflow.prop";
      $self->{workflowConfig} =
	CBIL::Util::PropertySet->new($workflowConfigFile, \@properties);
    }
    return $self->{workflowConfig}->getProp($key);
}

sub error {
    my ($self, $msg) = @_;

    die "$msg\n\n";
}

1;
