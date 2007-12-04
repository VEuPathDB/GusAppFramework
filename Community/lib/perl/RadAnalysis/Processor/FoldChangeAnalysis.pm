package  GUS::Community::RadAnalysis::Processor::FoldChangeAnalysis;
use base qw(GUS::Community::RadAnalysis::AbstractProcessor);

use strict;

use GUS::Community::RadAnalysis::RadAnalysisError;
use GUS::Community::RadAnalysis::ProcessResult;

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
                        'conditionC0',
                        'conditionC1',
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

sub getConditionC0 {$_[0]->{conditionC0}}
sub getConditionC1 {$_[0]->{conditionC1}}

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
    $foldChanger = TwoChannelDirectComparison->new($dir);
  }
  elsif($numberOfChannels == 2 && $design eq 'R' && $isDataLogged) {
    $foldChanger = TwoChannelReferenceDesign->new($dir);
  }
  elsif($numberOfChannels == 2 && $design eq 'R' && !$isDataLogged) {
    $foldChanger = TwoChannelUnpairedRatios->new($dir);
  }
  elsif($numberOfChannels == 1 && !$isDataPaired && $isDataLogged) {
    $foldChanger = OneChannelLogNormalized->new($dir);
  }
  elsif($numberOfChannels == 1 && $isDataPaired && !$isDataLogged) {
    $foldChanger = OneChannelPaired->new($dir);
  }
  elsif($numberOfChannels == 1 && !$isDataPaired && !$isDataLogged) {
    $foldChanger = OneChannelUnpaired->new($dir);
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

   return { condition_c0 => $self->getConditionC0(),
            condition_c1 => $self->getConditionC1(),
          };
}


#================================================================================

package FoldChanger;

use GUS::Model::RAD::Protocol;
use GUS::Model::RAD::ProtocolParam;

use CBIL::Util::V;

use GUS::Community::RadAnalysis::Utils qw(getOntologyEntriesHashFromParentValue);

#--------------------------------------------------------------------------------

sub new {
  my ($class, $dir) = @_;

  unless(-d $dir) {
    die "Directory [$dir] does not exist: $!";
  }

  my $dataTypeOeHash = &getOntologyEntriesHashFromParentValue('DataType');
  my $dataTransformationOeHash = &getOntologyEntriesHashFromParentValue('DataTransformationProtocolType');

  bless {data_type_oe_hash => $dataTypeOeHash,
         data_transformation_oe_hash => $dataTransformationOeHash,
         output_directory => $dir}, $class;
}

#--------------------------------------------------------------------------------

sub getDataTypeOeHash {$_[0]->{data_type_oe_hash}}
sub getDataTransformationOeHash {$_[0]->{data_transformation_oe_hash}}
sub getOutputDirectory {$_[0]->{output_directory}}

#--------------------------------------------------------------------------------

sub setupProtocolParams {
  my ($self, $protocol) = @_;

  my $oeHash = $self->getDataTypeOeHash();

  my %params = (condition_c0 => 'string_datatype',
                condition_c1 => 'string_datatype',
               );

  my @protocolParams = $protocol->getChildren('RAD::ProtocolParam', 1);

  if(scalar(@protocolParams) == 0) {

    foreach(keys %params) {
      my $dataType = $params{$_};
      my $oe = $oeHash->{$dataType};

      my $oeId = $oe->getId();

      my $param = GUS::Model::RAD::ProtocolParam->new({name => $_,
                                                       data_type_id => $oeId,
                                                      });

      push(@protocolParams, $param);
    }
  }

  foreach my $param (@protocolParams) {
    $param->setParent($protocol);
  }

  return \@protocolParams;
}

#--------------------------------------------------------------------------------

sub getProtocol{
  my ($self, $name, $description) = @_;

  my $protocol = GUS::Model::RAD::Protocol->new({name => $name});

  unless($protocol->retrieveFromDB) {
    $protocol->setProtocolDescription($description);

    my $typeOe = $self->getDataTransformationOeHash()->{across_bioassay_data_set_function};
    unless($typeOe) {
      die "Did NOT retrieve Study::OntologyEntry [across_bioassay_data_set_function]";
    }

    $protocol->setProtocolTypeId($typeOe->getId());
  }

  $self->setupProtocolParams($protocol);

  return $protocol;
}

#--------------------------------------------------------------------------------

sub makeFileHandle {
  my ($self, $logicalGroups) = @_;

  my $directory = $self->getOutputDirectory();

  my @names;
  foreach my $lg (@$logicalGroups) {
    my $name = $lg->getName();
    $name =~ s/ //g;

    my ($shorter) = $name =~ /:?([\w\d_]+)$/;
    push(@names, $shorter);

  }

  my $fn = join("_vs_", @names) . ".txt";

  open(FILE, "> $fn") or die "Cannot open file [$fn] for writing: $!";

  return \*FILE;
}

#--------------------------------------------------------------------------------

# This is the default... any subclass below where it doesn't apply should override
sub writeDataFile {
  my ($self, $input, $logicalGroups, $baseX, $isDataPaired) = @_;

  my $header = 'ratio';
  my $MISSING_VALUE = 'NA';

  my $lgCount = scalar(@$logicalGroups);

  if($baseX) {
    $header = "log" . $baseX . $header;
  }

  my $fh = $self->makeFileHandle($logicalGroups);

  print $fh "row_id\tconfidence_up\tconfidence_down\t$header\n";

  foreach my $element (keys %$input) {
    my @averages;

    foreach my $lg (@$logicalGroups) {
      my @output;

      foreach(@{$input->{$element}->{$lg->getName}}) {
        push(@output, $_) unless($_ eq $MISSING_VALUE);
      }

      # Don't average if they are all NA's
      if(scalar(@output) == 0) {
        push(@averages, $MISSING_VALUE);
      }
      else {
        push(@averages, CBIL::Util::V::average(@output));
      }
    }

    # Don't print if the averages are all NA's
    my $naCount;
    map {$naCount++ if($_ eq $MISSING_VALUE)} @averages;
    next if($naCount == scalar(@averages));

    my $value;
    if($lgCount == 1) {
      $value = $averages[0];
    }
    elsif($lgCount == 2 && $baseX) {
      $value = $averages[1] - $averages[0];
    }
    elsif($lgCount == 2 && !$baseX) {
      $value = $averages[1] / $averages[0];
    }
    else {
      die "Wrong Number of LocialGroups [$lgCount]";
    }

    print $fh "$element\t\t\t$value\n";
  }

  close $fh;
}

#================================================================================

package TwoChannelDirectComparison;
use base qw(FoldChanger);

sub getProtocol{

  my $name = 'Ratio and Fold Change calculation from M values in 2-channel direct comparisons';
  my $description = 'The input to this protocol are normalized M values from a collection of 2-channel assays comparing condition C1 and condition C2 in a direct design fashion, so that, for each reporter and each assay, M=log2(C1)-log2(C2). For each reporter its average normalized M value Mbar across the assays is first computed. Then its ratio r is set to 2^(Mbar), i.e. 2 to the Mbar power. Its fold change FC is obtained as follows. If r=1, then FC=0; if r>1, then FC=r; if r<1 then FC=-(1/r).';

  return shift()->SUPER::getProtocol($name, $description);

}
#================================================================================

package TwoChannelReferenceDesign;
use base qw(FoldChanger);

sub getProtocol{

  my $name = 'Ratio and Fold Change calculation from M values in 2-channel reference design comparisons';
  my $description = 'The input to this protocol are normalized M values from a collection of 2-channel assays comparing condition C1 and condition C2 in a reference design fashion. Thus, if the common reference is denoted by B, for each reporter and each assay in condition C1, we have M1=log2(C1)-log2(B). For each reporter and each assay in condition C2, we have M2=log2(C2)-log2(B). For each reporter, first its average normalized M1 value M1bar across the assays in condition C1 and its average normalized M2 value M2bar across the assays in condition C2 are computed. Then its ratio r is set to 2^(M1bar-M2bar), i.e. 2 to the (M1bar-M2bar) power. Its fold change FC is obtained as follows. If r=1, then FC=0; if r>1, then FC=r; if r<1 then FC=-(1/r).';

  return shift()->SUPER::getProtocol($name, $description);
}

#================================================================================

package OneChannelPaired;
use base qw(FoldChanger);

sub getProtocol{

  my $name = 'Ratio and Fold Change calculation from normalized intensities in 1-channel paired comparisons';
  my $description = 'The input to this protocol are normalized (un-logged) intensities from a collection of 1-channel assays comparing condition C1 and condition C2 in a paired fashion. For each reporter and each pair of corresponding assays (one from condition C1 and the other from condition C2), the ratio of its intentities in the two assays c1/c2 is computed. For each reporter its ratio r is set to the average of its pairwise ratios over all pairs of correponding assays. Its fold change FC is obtained as follows. If r=1, then FC=0; if r>1, then FC=r; if r<1 then FC=-(1/r).';

  # TODO: implement this!
  sub writeDataFile {
    die "The subroutine [writeDataFile] has not yet been implemented for " . __PACKAGE__;
  }

  return shift()->SUPER::getProtocol($name, $description);
}

#================================================================================

package OneChannelUnpaired;
use base qw(FoldChanger);

sub getProtocol{

  my $name = 'Ratio and Fold Change calculation from normalized intensities in 1-channel unpaired comparisons';
  my $description = 'The input to this protocol are normalized (un-logged) intensities from a collection of 1-channel assays comparing condition C1 and condition C2 in an unpaired fashion. For each reporter, its average normalized intensity in condition C1 and its average normalized intensity in condition C2 are computed. Then its ratio r is set to the ratio of these average normalized intensities. Its fold change FC is obtained as follows. If r=1, then FC=0; if r>1, then FC=r; if r<1 then FC=-(1/r).';

  return shift()->SUPER::getProtocol($name, $description);
}

#================================================================================

package OneChannelLogNormalized;
use base qw(FoldChanger);

sub getProtocol{

  my $name = 'Ratio and Fold Change calculation from normalized log intensities in 1-channel comparisons';
  my $description = 'The input to this protocol are normalized log2 intensities from a collection of 1-channel assays comparing condition C1 and condition C2. For each reporter its average log2 intensities CiBar in each condition are computed. Then its ratio r is set to 2^(C1bar-C2bar), i.e. 2 to the (C1bar-C2bar) power. Its fold change FC is obtained as follows. If r=1, then FC=0; if r>1, then FC=r; if r<1 then FC=-(1/r).';

  return shift()->SUPER::getProtocol($name, $description);
}

#================================================================================

package TwoChannelUnpairedRatios;
use base qw(FoldChanger);

sub getProtocol{

  my $name = 'Ratio and Fold Change calculation from ratios in 2-channel reference design unpaired comparisons';
  my $description = 'The input to this protocol are normalized (un-logged) ratios from a collection of 2-channel assays comparing condition C1 and condition C2 in a reference design unpaired fashion. Thus, if the common reference is denoted by B, for each reporter and each assay in condition C1, we have R1=c1/b where c1 and b denote the intensities of the reporter in C1 and B. For each reporter and each assay in condition C2, we have R2=c2/b, with similar notation. For each reporter, first its average normalized R1 value R1bar across the assays in condition C1 and its average normalized R2 value R2bar across the assays in condition C2 are computed. Then its ratio r is set to R1bar/R2bar. Its fold change FC is obtained as follows. If r=1, then FC=0; if r>1, then FC=r; if r<1 then FC=-(1/r).';

  return shift()->SUPER::getProtocol($name, $description);
}

#================================================================================

package  GUS::Community::RadAnalysis::Processor::FoldChangeAnalysis;


1;
