package GUS::PluginMgr::Args::FloatArg;

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

  return "=f";
}

sub getType {
  my ($self) = @_;

  return "float";
}

sub getPrimativeType {
  my ($self) = @_;

  return "float";
}

sub checkValue {
  my ($self, $value, $plugin) = @_;
  my $problem = undef;
  $problem = "'$value' is not a valid float" 
    if ($value && $value !~ /\d+(\.\d+)?/);
  return $problem;
}

1;
