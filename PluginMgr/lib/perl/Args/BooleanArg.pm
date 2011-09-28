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

sub getPrimativeType {
  my ($self) = @_;

  return "boolean";
}

sub checkValue {
  my ($self, $value, $plugin) = @_;
  return 0;
}

# returns undef if no value (including for list values)
sub getValue {
  my ($self) = @_;

  # compensate for bug someplace that makes absent boolean flags into
  # an undefined value.  we always want either a 1 or 0;
  if (!defined($self->{value})) {
      $self->{value} = 0;
  }
  return $self->{value};
}


1;
