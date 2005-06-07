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

  my %vocabFromDb;
  while (my ($primaryKey, $term) = $sth->fetchrow_array()) {
    $vocabFromDb{$term} = $primaryKey;
  }

  # validate the GUS values in the file against the db
  open(MAPPING_FILE, $file) || return "can't open file '$value'";
  my %controlledVocab;
  my @termsNotInDb;
  while (<MAPPING_FILE>) {
    if (!/^(\w+)\t(\w+)\s*$/) { die "Controlled vocab mapping file '$file' is not in the correct two column tab-delimited format";}
    my $inputTerm = $1;
    my $gusTerm = $2;
    (defined $vocabFromDb{$gusTerm}) || push(@termsNotInDb, "'$gusTerm'");
    
    $controlledVocab{$inputTerm} = [$gusTerm, $vocabFromDb{$gusTerm}];
  }

  my $problem = undef;
  if (scalar @termsNotInDb > 0) {
    $problem = "The following terms found in file '$file' are not in GUS table $self->{table}: " . join(" ", @termsNotInDb);
  }

  # this is a bit nasty:  changing the value from a file name to a hash.
  $self->{value} = \%controlledVocab;
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
