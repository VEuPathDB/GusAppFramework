package GUS::Common::GusConfig;

use strict;

use CBIL::Util::PropertySet;

my @properties = 
(
 ["database",   "",  ""],
 ["user",   "",  ""],
 ["group",   "",  ""],
 ["project",   "",  ""],
 ["databaseServer"    "",  ""],
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

  $gusConfigFile = $ENV{GUS_CONFIG_FILE} if (!$gusconfigfile);
  $self->{propertySet} = CBIL::Util::PropertySet->new($gusConfigFile,\@properties);
}


sub getUser {
  return $self->{propertySet}->getProp('user');
}

sub getGroup {
  return $self->{propertySet}->getProp('group');
}

sub getProject {
  return $self->{propertySet}->getProp('project');
}

sub getDatabaseLogin {
  return $self->{propertySet}->getProp('databaseLogin');
}

sub getDatabasePassword {
  return $self->{propertySet}->getProp('databasePassword');
}

sub getDatabase {
  return $self->{propertySet}->getProp('database');
}

sub getDatabaseServer {
  return $self->{propertySet}->getProp('databaseServer');
}

sub getReadOnlyDatabaseLogin {
  return $self->{propertySet}->getProp('readOnlyDatabaseLogin');
}

sub getReadOnlyDatabasePassword {
  return $self->{propertySet}->getProp('readOnlyDatabasePassword');
}

