package GUS::ObjRelP::Generator::WrapperGenerator;

use strict;

sub new {
  my ($class, $generator, $schemaName, $tableName) = @_;

  my $self = {};
  bless $self, $class;

  $self->{generator} = $generator;
  $self->{schemaName} = $schemaName;
  $self->{tableName} = $tableName;
  $self->{fullName} = "${schemaName}::$tableName";

  return $self;
}

1;
