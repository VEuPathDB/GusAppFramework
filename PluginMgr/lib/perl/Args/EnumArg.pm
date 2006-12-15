package GUS::PluginMgr::Args::EnumArg;

@ISA = qw(GUS::PluginMgr::Args::Arg);

use strict;
use Carp;
use GUS::PluginMgr::Args::Arg;

sub new {
  my ($class, $paramsHashRef) = @_;

  my $self = {};

  bless($self, $class);

  $self->initAttrs($paramsHashRef);

  return $self;
}

sub getType {
  my ($self) = @_;

  return "enum";
}

sub getPrimativeType {
  my ($self) = @_;

  return "string";
}

sub getGetOptionsSuffix {
  my ($self) = @_;

  return "=s";
}

sub checkValue {
  my ($self, $value, $plugin) = @_;

  my $problem = "'$value' is not a valid value for enum argument $self->{name}";
  foreach my $enumEntry (@{$self->{enumArray}}) {
    if ($value eq $enumEntry) {
      $problem = undef;
      last;
    }
  }

  return $problem;
}

sub getAttrs {
  my ($self) = @_;

  my @a = (['enum', \&_checkEnum]);

  return @a;
}

#############################################################################
#          private methods
#############################################################################

sub _checkEnum {
  my ($self) = @_;

  my @enum = split(/,\s*/, $self->{enum});

  if (scalar @enum < 1) {
    return "The plugin author must provide a comma delimited list of choices for this enum argument";
  }
  $self->{enumArray} = \@enum;
  return undef;
}




1;
