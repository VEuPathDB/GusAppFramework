package GUS::Pipeline::Workflow::Base;

use strict;
use DBI;
use CBIL::Util::MultiPropertySet;
use CBIL::Util::PropertySet;

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
	$self->{dbh} = DBI->connect($self->getWorkflowConfig('dbConnectString'),
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

sub getHomeDir {
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
	 ['dbConnectString', "", ""],
	);

    if (!$self->{workflowConfig}) {
      my $workflowConfigFile = "$self->{homeDir}/config/workflow.prop";
      $self->{workflowConfig} =
	CBIL::Util::PropertySet->new($workflowConfigFile, \@properties);
    }
    return $self->{workflowConfig}->getProp($key);
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
