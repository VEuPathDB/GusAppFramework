package GUS::PluginMgr::Args::FileArg;

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

  return "file";
}

sub getGetOptionsSuffix {
  my ($self) = @_;

  return "=s";
}

sub checkValue {
  my ($self, $value) = @_;

  my $problem = undef;
  if ($self->{mustExist} && ! -e $value) {
    $problem = "file '" . $value . "' does not exist";
  }

  return $problem;
}

sub getAttrs {
  my ($self) = @_;

  my @a = (['format', \&_checkFormat],
	   ['mustExist', \&_checkMustExist]);
  return @a;
}

#############################################################################
#          private methods
#############################################################################

sub _checkFormat {
}

sub _checkMustExist {
}


1;
