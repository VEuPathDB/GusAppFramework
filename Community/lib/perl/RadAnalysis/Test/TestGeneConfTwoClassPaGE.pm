package GUS::Community::RadAnalysis::Test::TestGeneConfTwoClassPaGE;
use base qw(Test::Unit::TestCase);

#================================================================================
use GUS::ObjRelP::DbiDatabase;
use Data::Dumper;

use GUS::Supported::GusConfig;

use GUS::Community::RadAnalysis::Processer::GeneConfTwoClassPaGE;

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
              studyName => 'Expression profiling of the 3 archetypal T. gondii lineages',
              nameConditionA => 'Pru - RMA Quantifications',
              nameConditionB => 'RH - RMA Quantifications',
              numberOfChannels => 1,
              isDataLogged => 1,
              isDataPaired => 0,
              quantificationView => 'RMAExpress',
              quantificationUrisConditionA => ['Pru_1.TXT',
                                               'Pru_2.TXT',
                                               'Pru_3.TXT',
                                              ],
              quantificationUrisConditionB => ['RH_1.TXT',
                                               'RH_2.TXT',
                                               'RH_3.TXT',
                                              ],
              pageInputFile => "/home/jbrestel/projects/GUS/Community/lib/perl/RadAnalysis/Test/testInput.txt",

              };

  $processer = GUS::Community::RadAnalysis::Processer::GeneConfTwoClassPaGE->new($args);

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


sub test_process {
  my $self = shift;

  $processer->process();

}


1;
