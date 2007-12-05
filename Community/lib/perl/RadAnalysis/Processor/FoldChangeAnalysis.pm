package  GUS::Community::RadAnalysis::Processor::FoldChangeAnalysis;
use base qw(GUS::Community::RadAnalysis::AbstractProcessor);

use strict;

use GUS::Community::RadAnalysis::RadAnalysisError;
use GUS::Community::RadAnalysis::ProcessResult;
use GUS::Community::RadAnalysis::FoldChanger;

use  GUS::ObjRelP::DbiDatabase;

use File::Basename;

#--------------------------------------------------------------------------------

my $RESULT_VIEW = 'RAD::DataTransformationResult';

#--------------------------------------------------------------------------------

sub new {
  my ($class, $args) = @_;

  unless(ref($args) eq 'HASH') {
    GUS::Community::RadAnalysis::InputError->new("Must provide a hashref to the constructor of " .  __PACKAGE__)->throw();
  }

  my $requiredParams = ['arrayDesignName',
                        'studyName',
                        'logDir',
                        'analysisName',
                        'numberOfChannels',
                        'denominator',
                        'numerator',
                        'dummyResultFile',
                       ];

  my $self = $class->SUPER::new($args, $requiredParams);

  if($args->{design} eq 'D' && defined($args->{isDataPaired})) {
    GUS::Community::RadAnalysis::InputError->new("Parameter [isDataPaired] should not be specified with Dye swap design")->throw();
  }

  if($args->{design} ne 'D' && !defined($args->{isDataPaired})) {
    GUS::Community::RadAnalysis::InputError->new("Parameter [isDataPaired] is missing from the config file")->throw();
  }

  if($args->{numberOfChannels} == 2 && $args->{design} ne 'R' && $args->{design} ne 'D') {
    GUS::Community::RadAnalysis::InputError->new("Parameter [design] must be one of (D,R) for 2 channel data")->throw();
  }

  if($args->{numberOfChannels} == 1 && $args->{design}) {
    GUS::Community::RadAnalysis::InputError->new("Parameter [design] should not be given for one channel data")->throw();
  }

  if($args->{isDataLogged} && !$args->{baseX}) {
    GUS::Community::RadAnalysis::InputError->new("Parameter [baseX] must be specified when [isLoggedData] is true.")->throw();
  }

  if(!defined($args->{isDataLogged}) && $args->{baseX}) {
    GUS::Community::RadAnalysis::InputError->new("Parameter [isDataLogged] must be 1 when [baseX] is specified.")->throw();
  }

  $self->{quantificationInputs} = [] unless($args->{quantificationInputs});
  $self->{analysisInputs} = [] unless($args->{analysisInputs});

  return $self;
}

#--------------------------------------------------------------------------------

sub getArrayDesignName {$_[0]->{arrayDesignName}}
sub getStudyName {$_[0]->{studyName}}
sub getLogDir {$_[0]->{logDir}}
sub getTranslator {$_[0]->{translator}}
sub getAnalysisName {$_[0]->{analysisName}}
sub getDesign {$_[0]->{design}}
sub getNumberOfChannels {$_[0]->{numberOfChannels}}
sub getIsDataPaired {$_[0]->{isDataPaired}}
sub getIsDataLogged {$_[0]->{isDataLogged}}
sub getDummyResultFile {$_[0]->{dummyResultFile}}
sub getBaseX {$_[0]->{baseX}}

sub getQuantificationView {$_[0]->{quantificationView}}
sub getQuantificationInputs {$_[0]->{quantificationInputs}}

sub getAnalysisView {$_[0]->{analysisView}}
sub getAnalysisInputs {$_[0]->{analysisInputs}}

sub getDenominator {$_[0]->{denominator}}
sub getNumerator {$_[0]->{numerator}}

#--------------------------------------------------------------------------------

sub process {
  my ($self) = @_;

  my $logDir = $self->getLogDir();

  unless(-e $logDir) {
    GUS::Community::RadAnalysis::ProcessorError->new("Directory [$logDir] does not exist")->throw();
  }
  chdir $logDir;

  my $database;
  unless($database = GUS::ObjRelP::DbiDatabase->getDefaultDatabase()) {
    GUS::Community::RadAnalysis::ProcessorError->new("Package ".  __PACKAGE__ . " Requires Default DbiDatabase")->throw();
  }

  my $contact = $self->getContactFromDefaultUser($database);
  my $dbh = $database->getQueryHandle();

  my $quantLgHash = $self->standardLogicalGroupInputs($self->getQuantificationInputs);
  my $analysisLgHash = $self->standardLogicalGroupInputs($self->getAnalysisInputs);

  my $logicalGroups = $self->makeStandardLogicalGroups($dbh, $quantLgHash, $analysisLgHash, $self->getStudyName(), $self->getIsDataPaired(), 1);

  if($self->getDesign eq 'D' && scalar(@$logicalGroups) != 1) {
    GUS::Community::RadAnalysis::InputError->new("Only One Logical Group should be given with direct comparison design")->throw();
  }

  my $arrayDesignName = $self->getArrayDesignName();
  my $arrayTable = $self->queryForArrayTable($dbh, $arrayDesignName);

  my $allElements = $self->queryForElements($dbh, $arrayDesignName);

  my $quantView = $self->getQuantificationView();
  my $analysisView = $self->getAnalysisView();

  my $dataMatrix = $self->createDataMatrixFromLogicalGroups($logicalGroups, $quantView, $analysisView, $dbh);

  my $foldChanger = $self->findCalculationType();

  my $protocol = $foldChanger->getProtocol();

  $foldChanger->writeDataFile($dataMatrix, $logicalGroups, $self->getBaseX(), $self->getIsDataPaired());

  my $paramValues = $self->setupParamValues();

  my $result = GUS::Community::RadAnalysis::ProcessResult->new();

  $result->setResultView($RESULT_VIEW);
  $result->setResultFile($self->getDummyResultFile());

  $result->setContact($contact) if($contact);
  $result->setAnalysisName($self->getAnalysisName());
  $result->setArrayTable($arrayTable);
  $result->setProtocol($protocol);
  $result->addToParamValuesHashRef($paramValues);
  $result->addLogicalGroups(@$logicalGroups);

  return [$result];
}

#--------------------------------------------------------------------------------

sub findCalculationType {
  my ($self) = @_;

  my $design = $self->getDesign();
  my $numberOfChannels = $self->getNumberOfChannels();
  my $isDataPaired = $self->getIsDataPaired();
  my $isDataLogged = $self->getIsDataLogged();

  my $dir = $self->getLogDir();

  my $foldChanger;

  if($numberOfChannels == 2 && $design eq 'D' && $isDataLogged) {
    $foldChanger = GUS::Community::RadAnalysis::TwoChannelDirectComparison->new($dir);
  }
  elsif($numberOfChannels == 2 && $design eq 'R' && $isDataLogged) {
    $foldChanger = GUS::Community::RadAnalysis::TwoChannelReferenceDesign->new($dir);
  }
  elsif($numberOfChannels == 2 && $design eq 'R' && !$isDataLogged && !$isDataPaired) {
    $foldChanger = GUS::Community::RadAnalysis::TwoChannelUnpairedRatios->new($dir);
  }
  elsif($numberOfChannels == 1 && $isDataLogged) {
    $foldChanger = GUS::Community::RadAnalysis::OneChannelLogNormalized->new($dir);
  }
  elsif($numberOfChannels == 1 && $isDataPaired && !$isDataLogged) {
    $foldChanger = GUS::Community::RadAnalysis::OneChannelPaired->new($dir);
  }
  elsif($numberOfChannels == 1 && !$isDataPaired && !$isDataLogged) {
    $foldChanger = GUS::Community::RadAnalysis::OneChannelUnpaired->new($dir);
  }
  else {
    GUS::Community::RadAnalysis::InputError->
        new("Number of Channels [$numberOfChannels]; design [$design]; isDataLogged [$isDataLogged]; isDataPaired [$isDataPaired] Not supported")->throw();
  }

  print STDERR "Using " . ref($foldChanger) . "\n";

  return $foldChanger;
}

#--------------------------------------------------------------------------------

sub setupParamValues {
  my ($self) = @_;

   return { denominator => $self->getDenominator(),
            numerator => $self->getNumerator(),
          };
}

#--------------------------------------------------------------------------------

1;
