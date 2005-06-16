package GUS::Supported::GusConfig;

use strict;

use CBIL::Util::PropertySet;

# JC: What is the third field in these arrays used for?  
# I don't see where PropertySet.pm makes use of it.
my @properties = 
(
 ["coreSchemaName",   "",  ""],
 ["userName",   "",  ""],
 ["group",   "",  ""],
 ["project",   "",  ""],
 ["dbiDsn",    "",  ""],
 ["databaseLogin",         "",  ""],
 ["databasePassword",   "",  ""],
 ["readOnlyDatabaseLogin",         "",  ""],
 ["readOnlyDatabasePassword",   "",  ""],
 # JC: this is not optimal, but PropertySet won't accept an empty string here
 # without requiring that the user supply a value for the parameter
 ["oracleDefaultRollbackSegment",   "none", ""],  
);

# param gusConfigFile - an optional file of 'name=value'.
#                       default = $ENV{GUS_CONFIG_FILE}
sub new {
  my ($class, $gusConfigFile) = @_;

  my $self = {};
  bless($self, $class);

  $gusConfigFile = $ENV{GUS_CONFIG_FILE} if (!$gusConfigFile);
  $self->{propertySet} = CBIL::Util::PropertySet->new($gusConfigFile,\@properties);
  return $self;
}


sub getUserName {
  my ($self) = @_;
  return $self->{propertySet}->getProp('userName');
}

sub getGroup {
  my ($self) = @_;
  return $self->{propertySet}->getProp('group');
}

sub getProject {
  my ($self) = @_;
  return $self->{propertySet}->getProp('project');
}

sub getDatabaseLogin {
  my ($self) = @_;
  return $self->{propertySet}->getProp('databaseLogin');
}

sub getDatabasePassword {
  my ($self) = @_;
  return $self->{propertySet}->getProp('databasePassword');
}

sub getCoreSchemaName {
  my ($self) = @_;
  return $self->{propertySet}->getProp('coreSchemaName');
}

sub getDbiDsn {
  my ($self) = @_;
  return $self->{propertySet}->getProp('dbiDsn');
}

sub getReadOnlyDatabaseLogin {
  my ($self) = @_;
  return $self->{propertySet}->getProp('readOnlyDatabaseLogin');
}

sub getReadOnlyDatabasePassword {
  my ($self) = @_;
  return $self->{propertySet}->getProp('readOnlyDatabasePassword');
}

sub getOracleDefaultRollbackSegment {
  my ($self) = @_;
  return $self->{propertySet}->getProp('oracleDefaultRollbackSegment');
}

