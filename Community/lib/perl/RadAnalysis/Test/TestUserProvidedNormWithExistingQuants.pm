package GUS::Community::RadAnalysis::Test::TestUserProvidedNormWithExistingQuants;
use base qw(Test::Unit::TestCase);

#================================================================================
use GUS::ObjRelP::DbiDatabase;
use Data::Dumper;

use GUS::Supported::GusConfig;

use GUS::Model::RAD::Protocol;

use GUS::Community::RadAnalysis::Processer::UserProvidedNormWithExistingQuants;

use Error qw(:try);

use strict;

my $processer;
my $testCount;
my $database;

#================================================================================

sub new {
  my $self = shift()->SUPER::new(@_);

  $testCount = scalar $self->list_tests();

  return $self;
}

#--------------------------------------------------------------------------------

sub set_up {
  my $self = shift;

  my @properties;

  my $configFile = "$ENV{GUS_HOME}/config/gus.config";

  unless(-e $configFile) {
    my $error = "Config file $configFile does not exist.";
    die $error;
  }

  my $config = GUS::Supported::GusConfig->new($configFile);

  my $login       = $config->getDatabaseLogin();
  my $password    = $config->getDatabasePassword();
  my $core        = $config->getCoreSchemaName();
  my $dbiDsn      = $config->getDbiDsn();
  my $oraDfltRbs  = $config->getOracleDefaultRollbackSegment();

  unless($database = GUS::ObjRelP::DbiDatabase->getDefaultDatabase()) {
    $database = GUS::ObjRelP::DbiDatabase->new($dbiDsn, $login, $password,
                                                  0,0,1,$core, $oraDfltRbs);
  }

  my $args = {arrayDesignName => 'Tgondiia Custom Array - Expression',
              directoryPrefix => '/home/jbrestel/data/toxo_data/ToxoLineages/',
              studyName => 'Expression profiling of the 3 archetypal T. gondii lineages',
              normalizationProtocol => 'Robust Multi-Array Average expression measure (Bioconductor affy package)',
              inputQuantificationProtocol => 'Affymetrix MAS 5.0 Probe Cell Analysis',
              fileTranslatorName => '/home/jbrestel/data/toxo_data/ToxoLineages/bioconductorToDtr.xml'
              };

  $processer = GUS::Community::RadAnalysis::Processer::UserProvidedNormWithExistingQuants->new($args);

}

sub tear_down {
  my $self = shift;

  $testCount--;

  # LOG OUT AFTER ALL TESTS ARE FINISHED
  if($testCount <= 0) {
    GUS::ObjRelP::DbiDatabase->getDefaultDatabase()->logout();
    GUS::ObjRelP::DbiDatabase->setDefaultDatabase(undef);

    print STDERR "LOGGING OUT FROM DBI DATABASE\n";
  }

}


#--------------------------------------------------------------------------------

sub _test_process {
  my $self = shift;

  my $results = $processer->process();

  my $first =  $results->[0];

  my $dbh = $database->getQueryHandle();

  $first->writeAnalysisDataFile($dbh);
  #$first->writeAnalysisConfigFile();

}

#--------------------------------------------------------------------------------

sub test_createLogicalGroup {
  my $self = shift;

  my $quantification = GUS::Model::RAD::Quantification->new({name => 'CTG 2 - RMA Normalization'});
  $quantification->retrieveFromDB();

  my $logicalGroup = $processer->createLogicalGroup($database, $quantification);
}


1;
