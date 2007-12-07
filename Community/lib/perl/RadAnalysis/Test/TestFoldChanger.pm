package GUS::Community::RadAnalysis::Test::TestFoldChanger;
use base qw(Test::Unit::TestCase); 

use strict;

use GUS::Community::RadAnalysis::FoldChanger;

use GUS::Supported::GusConfig;
use GUS::ObjRelP::DbiDatabase;

use GUS::Community::RadAnalysis::RadAnalysisError;

use GUS::Model::RAD::LogicalGroup;

use Data::Dumper;

use Error qw(:try);

my $testCount;
my $database;
my $dir = $ENV{HOME};

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

    $database->setDefaultUserId(1226);
  }
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

sub test_new {
  my $self = shift;

  try {
    GUS::Community::RadAnalysis::TwoChannelDirectComparison->new($dir, undef, undef);
    $self->assert(0);
  } catch GUS::Community::RadAnalysis::RadAnalysisError with {   };

  try {
    GUS::Community::RadAnalysis::TwoChannelDirectComparison->new($dir, 2, 2);
    $self->assert(0);
  } catch GUS::Community::RadAnalysis::RadAnalysisError with {   };

  my $twoChannelDirect = GUS::Community::RadAnalysis::TwoChannelDirectComparison->new($dir, 2, undef);

  my $baseX = $twoChannelDirect->getBaseX();
  $self->assert_equals(2, $baseX);


  try {
    GUS::Community::RadAnalysis::OneChannelPaired->new($dir, undef, undef);
  } catch GUS::Community::RadAnalysis::RadAnalysisError with {   };

  try {
    GUS::Community::RadAnalysis::OneChannelPaired->new($dir, 2, 1);
  } catch GUS::Community::RadAnalysis::RadAnalysisError with {   };

  my $oneChannelPaired = GUS::Community::RadAnalysis::OneChannelPaired->new($dir, undef, 1);

  my $isDataPaired = $oneChannelPaired->getIsDataPaired();
  $self->assert_equals(1, $isDataPaired);

}


sub test_getProtocol {
  my $self = shift;

  my $twoChannelDirect = GUS::Community::RadAnalysis::TwoChannelDirectComparison->new($dir, 2, undef);
  my $oneChannelPaired = GUS::Community::RadAnalysis::OneChannelPaired->new($dir, undef, 1);

  my $twoChannelProtocolName = $twoChannelDirect->getProtocol()->getName();
  my $oneChannelProtocolName = $oneChannelPaired->getProtocol()->getName();

  $self->assert_equals('Ratio and Fold Change calculation from M values in 2-channel direct comparisons', $twoChannelProtocolName);
  $self->assert_equals('Ratio and Fold Change calculation from normalized intensities in 1-channel paired comparisons', $oneChannelProtocolName);

  my @kids = $twoChannelDirect->getProtocol()->getChildren('RAD::ProtocolParam');
  $self->assert_equals(2, scalar @kids);

}

sub test_calculateUnpairedAverages {
  my $self = shift;

  my $na = 'NA';
  my $dataHash = {};

  push @{$dataHash->{logical_group0}}, 1;
  push @{$dataHash->{logical_group0}}, 2;
  push @{$dataHash->{logical_group0}}, 3;
  push @{$dataHash->{logical_group0}}, 4;

  push @{$dataHash->{logical_group1}}, 1;
  push @{$dataHash->{logical_group1}}, 2;
  push @{$dataHash->{logical_group1}}, 'NA';
  push @{$dataHash->{logical_group1}}, 4;

  my $lg0 = GUS::Model::RAD::LogicalGroup->new({name => 'logical_group0'});
  my $lg1 = GUS::Model::RAD::LogicalGroup->new({name => 'logical_group1'});

  my $logicalGroups = [$lg0, $lg1];

  my $foldChanger = GUS::Community::RadAnalysis::OneChannelUnpaired->new($dir);

  my $averages = $foldChanger->calculateUnpairedAverages($dataHash,$logicalGroups, $na);

  $self->assert_equals(2, scalar(@$averages));

  $self->assert_equals(10/4, $averages->[0]);
  $self->assert_equals(7/3, $averages->[1]);
}


sub test_calculatePairedAverages {
  my $self = shift;

  my $na = 'NA';
  my $dataHash = {};

  push @{$dataHash->{logical_group0}}, 1;
  push @{$dataHash->{logical_group0}}, 2;
  push @{$dataHash->{logical_group0}}, 3;
  push @{$dataHash->{logical_group0}}, 4;

  push @{$dataHash->{logical_group1}}, 1;
  push @{$dataHash->{logical_group1}}, 2;
  push @{$dataHash->{logical_group1}}, 'NA';
  push @{$dataHash->{logical_group1}}, 4;

  my $lg0 = GUS::Model::RAD::LogicalGroup->new({name => 'logical_group0'});
  my $lg1 = GUS::Model::RAD::LogicalGroup->new({name => 'logical_group1'});

  my $logicalGroups = [$lg0, $lg1];

  my $foldChanger = GUS::Community::RadAnalysis::OneChannelPaired->new($dir, '', 1);

  my $averages = $foldChanger->calculatePairedAverages($dataHash,$logicalGroups, $na);

  $self->assert_equals(2, scalar(@$averages));

  $self->assert_equals(7/3, $averages->[0]);
  $self->assert_equals(7/3, $averages->[1]);
}

sub test_calculateRatio {
  my $self = shift;

  my $foldChanger =   my $foldChanger = GUS::Community::RadAnalysis::OneChannelUnpaired->new($dir);
  
  try {
    $foldChanger->calculateRatio(0, '', [2, 4]);
    $self->assert(0);
  } catch GUS::Community::RadAnalysis::RadAnalysisError with {   };

  try {
    $foldChanger->calculateRatio(3, '', [2, 4]);
    $self->assert(0);
  } catch GUS::Community::RadAnalysis::RadAnalysisError with {   };

  my $ratio0 = $foldChanger->calculateRatio(2, '', [2, 4]);
  $self->assert_equals(4/2, $ratio0);

  my $ratio1 = $foldChanger->calculateRatio(1, '', [4]);
  $self->assert_equals(4, $ratio1);

  my $ratio2 = $foldChanger->calculateRatio(1, 2, [1]);
  $self->assert_equals(1, $ratio2);
  
  my $ratio3 = $foldChanger->calculateRatio(2, 2, [1, 4]);
  $self->assert_equals(3, $ratio3);
}

1;
