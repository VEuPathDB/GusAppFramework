package GUS::PluginMgr::Args::StringArg;

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

sub getGetOptionsSuffix {
  my ($self) = @_;

  return "=s";
}

sub getType {
  my ($self) = @_;

  return "string";
}

sub getPrimativeType {
  my ($self) = @_;

  return "string";
}

sub checkValue {
  my ($self, $value) = @_;
  my $problem;
  return $problem;
}

1;
