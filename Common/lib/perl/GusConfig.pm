package GUS::Common::GusConfig;

use strict;

use CBIL::Util::PropertySet;

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
);

# param gusconfigfile - an optional file of 'name=value'.
#                       default = $ENV{GUS_CONFIG_FILE}
sub new {
  my ($class, $gusConfigFile) = @_;

  my $self = {};
  bless($self, $class);

  $gusConfigFile = $ENV{GUS_CONFIG_FILE} if (!$gusConfigFile);
  $self->{propertySet} = CBIL::Util::PropertySet->new($gusConfigFile,\@properties);
  return $self;
}


sub getUser {
  my ($self) = @_;
  return $self->{propertySet}->getProp('user');
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

