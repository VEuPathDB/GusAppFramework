package GUS::PluginMgr::Args::BooleanArg;

@ISA = qw(GUS::PluginMgr::Args::Arg);

use strict;
use Carp;
use GUS::PluginMgr::Args::Arg;

sub new {
  my ($class, $paramsHashRef) = @_;

  my $self = {};

  bless($self, $class);

  $self->initAttrs($paramsHashRef, 1);

  return $self;
}

sub getGetOptionsSuffix {
  my ($self) = @_;

  return "!";
}

sub getType {
  my ($self) = @_;

  return "";
}

sub checkValue {
  my ($self, $value) = @_;
  return 0;
}

1;
