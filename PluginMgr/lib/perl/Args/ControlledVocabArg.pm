package GUS::PluginMgr::Args::ControlledVocabArg;

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

  my $file = $value;

  if ($self->{mustExist} && ! -e $file) {
    return "file '" . $file . "' does not exist";
  }

  # connect to db to read the cv from GUS
  my $sql = 
    "select $self->{primaryKeyColumn}, $self->{termColumn}
     from $self->{table}";

  my $queryHandle = $plugin->getQueryHandle();
  my $sth = $queryHandle->prepareAndExecute($sql);

  my %gusTerm2PrimaryKey;
  while (my ($primaryKey, $term) = $sth->fetchrow_array()) {
    $gusTerm2PrimaryKey{$term} = $primaryKey;
  }

  my %userTerm2PrimaryKey;
  my %userTerm2GusTerm;
  my %userTerm2GusTermAndPrimaryKey;
  my @notReallyGusTerms;

  open(MAPPING_FILE, $file) || return "can't open file '$value'";
  while (<MAPPING_FILE>) {
    if (!/^(\w+)\t(\w+)\s*$/) { die "Controlled vocab mapping file '$file' is not in the correct two column tab-delimited format: '$_'";}
      my $userTerm = $1;
      my $inputGusTerm = $2;
      if (!$gusTerm2PrimaryKey{$inputGusTerm}) {
	push(@notReallyGusTerms, $inputGusTerm);
      } else {
	if ($userTerm2GusTerm{$userTerm}
	    && $userTerm2GusTerm{$userTerm} ne $inputGusTerm) {
	  die "CV mapping file '$file' has inconsistent mappings forinput term  '$userTerm'"
	}
	$userTerm2GusTerm{$userTerm} = $inputGusTerm;
	$userTerm2GusTermAndPrimaryKey{$userTerm} =
	  [$inputGusTerm, $gusTerm2PrimaryKey{$inputGusTerm}];
      }
  }

  my $problem = undef;
  if (scalar @notReallyGusTerms > 0) {
    $problem = "The following terms found in file '$file' are not in GUS table $self->{table}: " . join(" ", @notReallyGusTerms);
  }

  # this is a bit nasty:  changing the value from a file name to a hash.
  $self->{value} = \%userTerm2GusTermAndPrimaryKey;
  return $problem;
}

sub getAttrs {
  my ($self) = @_;

  my @a = (['mustExist', \&_dummy],
	   ['table', \&_dummy],
	   ['primaryKeyColumn', \&_dummy],
	   ['termColumn', \&_dummy]);
  return @a;
}

#############################################################################
#          private methods
#############################################################################

sub _dummy {
}


1;
