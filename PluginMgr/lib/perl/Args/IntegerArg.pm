package GUS::PluginMgr::Args::IntegerArg;

@ISA = qw(GUS::PluginMgr::Args::Arg);

use strict;
use Carp;
use GUS::PluginMgr::Args::Arg;

sub new {
  my ($class, $paramsHashRef) = @_;

  my $self = {};

  bless($self, $class);

  $self->getName();

  $self->initAttrs($paramsHashRef);
  return $self;
}

sub getGetOptionsSuffix {
  my ($self) = @_;

  return "=i";
}

sub getType {
  my ($self) = @_;

  return "integer";
}

sub checkValue {
  my ($self, $value) = @_;
  my $problem;
  return $problem;
}

1;
