package GUS::PluginMgr::Args::TableNameArg;

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

  return "tablename";
}

sub checkValue {
  my ($self, $value) = @_;
  my $problem;
  $problem = "must be in the form: 'schema::table'" unless $value =~ /\w+::\w+/;

  return $problem;
}

1;
