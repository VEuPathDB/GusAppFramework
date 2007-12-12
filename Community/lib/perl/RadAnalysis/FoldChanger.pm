package GUS::Community::RadAnalysis::FoldChanger;

use strict;

use GUS::Model::RAD::Protocol;
use GUS::Model::RAD::ProtocolParam;

use GUS::Community::RadAnalysis::RadAnalysisError;

use CBIL::Util::V;

use GUS::Community::RadAnalysis::Utils qw(getOntologyEntriesHashFromParentValue);

#--------------------------------------------------------------------------------

sub new {
  my ($class, $dir, $baseX, $isDataPaired) = @_;

  my $dataTypeOeHash = &getOntologyEntriesHashFromParentValue('DataType');
  my $dataTransformationOeHash = &getOntologyEntriesHashFromParentValue('DataTransformationProtocolType');

  my $self = bless {data_type_oe_hash => $dataTypeOeHash,
                    data_transformation_oe_hash => $dataTransformationOeHash}, $class;

  $self->setOutputDirectory($dir);
  $self->setBaseX($baseX);
  $self->setIsDataPaired($isDataPaired);

  return $self;
}

#--------------------------------------------------------------------------------

sub getDataTypeOeHash {$_[0]->{data_type_oe_hash}}
sub getDataTransformationOeHash {$_[0]->{data_transformation_oe_hash}}

sub getOutputDirectory {$_[0]->{output_directory}}
sub setOutputDirectory {
  my ($self, $dir) = @_;

  unless(-d $dir) {
    GUS::Community::RadAnalysis::DirectoryAccessError->new("Directory [$dir] does not exist")->throw();
  }

  $self->{output_directory} = $dir;
}

#--------------------------------------------------------------------------------
# expected is determined by the subclass
sub getBaseX {$_[0]->{baseX}}
sub setBaseX {
  my ($self, $baseX, $expected) = @_;


  if(($expected && !$baseX) || (!$expected && $baseX)) {
    GUS::Community::RadAnalysis::RadAnalysisError->new("baseX [$baseX] is wrong for " .  ref($self))->throw();
  }

  $self->{baseX} = $baseX;
}

#--------------------------------------------------------------------------------
# expected is determined by the subclass
sub getIsDataPaired {$_[0]->{isDataPaired}}
sub setIsDataPaired {
  my ($self, $isDataPaired, $expected) = @_;

  if(($expected && !$isDataPaired) || (!$expected && $isDataPaired)) {
    GUS::Community::RadAnalysis::RadAnalysisError->new("isDataPaired [$isDataPaired] is wrong for " . ref($self))->throw();
  }

  $self->{isDataPaired} = $isDataPaired;
}

#--------------------------------------------------------------------------------

sub setupProtocolParams {
  my ($self, $protocol) = @_;

  my $oeHash = $self->getDataTypeOeHash();

  my %params = (denominator => 'string_datatype',
                numerator => 'string_datatype',
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

  unless($name && $description) {
    GUS::Community::RadAnalysis::RadAnalysisError->new("Please implement the getProtocol method for " . ref($self))->throw();
  }

  my $protocol = GUS::Model::RAD::Protocol->new({name => $name});

  unless($protocol->retrieveFromDB) {
    $protocol->setProtocolDescription($description);

    my $typeOe = $self->getDataTransformationOeHash()->{across_bioassay_data_set_function};
    unless($typeOe) {
      GUS::Community::RadAnalysis::SqlError->new("Did NOT retrieve Study::OntologyEntry [across_bioassay_data_set_function]")->throw();
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

  open(FILE, "> $fn") or GUS::Community::RadAnalysis::FileAccessError->new("Cannot open file [$fn] for writing: $!")->throw();

  return \*FILE;
}

#--------------------------------------------------------------------------------

sub printHeader {
  my ($self, $baseX, $fh) = @_;

  my $header = 'ratio';

  if($baseX) {
    $header = "log" . $baseX . $header;
  }
  print $fh "row_id\t$header\n";
}

#--------------------------------------------------------------------------------

sub calculatePairedAverages {
  my ($self, $dataHash, $logicalGroups, $na) = @_;

  unless(scalar @$logicalGroups == 2) {
    GUS::Community::RadAnalysis::RadAnalysisError->new("Expected 2 logical groups as input to paired analysis")->throw();
  }

  my @averages;

  my @logicalGroupNames = map {$_->getName()} @$logicalGroups;

  my @data0 = @{$dataHash->{$logicalGroupNames[0]}};
  my @data1 = @{$dataHash->{$logicalGroupNames[1]}};

  unless(scalar @data0 == scalar @data1) {
    print STDERR join(',', @data0) . "\n";
    print STDERR join(',', @data1) . "\n";
    GUS::Community::RadAnalysis::RadAnalysisError->new("Unequal Number of data points for Paired Analysis")->throw();
  }

  my (@output0, @output1);

  for(my $i = 0; $i < scalar @data0; $i++) {
    next if($data0[$i] eq $na || $data1[$i] eq $na);

    push(@output0, $data0[$i]);
    push(@output1, $data1[$i]);
  }

  # Don't average if they are all NA's
  if(scalar(@output0) == 0) {
    push(@averages, $na, $na);
  }
  else {
    $averages[0] = CBIL::Util::V::average(@output0);
    $averages[1] = CBIL::Util::V::average(@output1);
  }

  return \@averages;
}

#--------------------------------------------------------------------------------

sub calculateUnpairedAverages {
  my ($self, $dataHash, $logicalGroups, $na) = @_;

  my @averages;

  foreach my $lg (@$logicalGroups) {
    my @output;

    foreach(@{$dataHash->{$lg->getName}}) {
      push(@output, $_) unless($_ eq $na);
    }

    # Don't average if they are all NA's
    if(scalar(@output) == 0) {
      push(@averages, $na);
    }
    else {
      push(@averages, CBIL::Util::V::average(@output));
    }
  }
  return \@averages;
}

#--------------------------------------------------------------------------------

sub calculateRatio {
  my ($self, $lgCount, $baseX, $averages) = @_;

  my $value;

  if($lgCount == 1) {
    $value = $averages->[0];
  }
  elsif($lgCount == 2 && $baseX) {
    $value = $averages->[1] - $averages->[0];
  }
  # Return null if either average is negative
  elsif($lgCount == 2 && !$baseX) {
    $value = $averages->[1] / $averages->[0] unless($averages->[0] < 0 || $averages->[1] < 0);
  }
  else {
    GUS::Community::RadAnalysis::RadAnalysisError->new("Wrong Number of LogicalGroups [$lgCount]")->throw();
  }
  return $value;
}

#--------------------------------------------------------------------------------

# Any subclass below can override this if need be
sub writeDataFile {
  my ($self, $input, $logicalGroups) = @_;

  my $baseX = $self->getBaseX();
  my $isDataPaired = $self->getIsDataPaired();

  my $MISSING_VALUE = 'NA';
  my $lgCount = scalar(@$logicalGroups);

  my $fh = $self->makeFileHandle($logicalGroups);
  $self->printHeader($baseX, $fh);

  foreach my $element (keys %$input) {
    my $averages;

    my $dataHash = $input->{$element};

    if($isDataPaired) {
      $averages = $self->calculatePairedAverages($dataHash, $logicalGroups, $MISSING_VALUE);
    }
    else {
      $averages = $self->calculateUnpairedAverages($dataHash, $logicalGroups, $MISSING_VALUE);
    }

    # Don't print if the averages any are NA's
    my $naCount = 0;
    map {$naCount++ if($_ eq $MISSING_VALUE)} @$averages;
    next if($naCount > 0);

    my $ratio = $self->calculateRatio($lgCount, $baseX, $averages);

    print $fh "$element\t$ratio\n" if($ratio);
  }
  close $fh;
}

1;

#================================================================================

package GUS::Community::RadAnalysis::TwoChannelDirectComparison;
use base qw(GUS::Community::RadAnalysis::FoldChanger);

sub setBaseX {$_[0]->SUPER::setBaseX($_[1], 1)}

sub getProtocol{

  my $name = 'Ratio and Fold Change calculation from M values in 2-channel direct comparisons';
  my $description = 'The input to this protocol are normalized M values from a collection of 2-channel assays comparing condition C1 and condition C2 in a direct design fashion, so that, for each reporter and each assay, its raw M=log2(c1)-log2(c2), where by c_i we denote the intensity of the reporter in condition C_i for that assay. For each reporter its average normalized M value Mbar across the assays is first computed, after removing assays with missing values for that reporter. Then its ratio r is set to 2^(Mbar), i.e. 2 to the Mbar power. Its fold change FC is obtained as follows. If r=1, then FC=0; if r>1, then FC=r; if r<1 then FC=-(1/r).';

  return shift()->SUPER::getProtocol($name, $description);

}

1;

#================================================================================

package GUS::Community::RadAnalysis::TwoChannelReferenceDesignPaired;
use base qw(GUS::Community::RadAnalysis::FoldChanger);

sub setBaseX {$_[0]->SUPER::setBaseX($_[1], 1)}
sub setIsDataPaired {$_[0]->SUPER::setIsDataPaired($_[1], 1)}

sub getProtocol{

  my $name = 'Ratio and Fold Change calculation from M values in 2-channel reference design paired comparisons';
  my $description = 'The input to this protocol are normalized M values from a collection of 2-channel assays comparing condition C1 and condition C2 in a reference design paired fashion. Thus, if the common reference is denoted by B, for each reporter and each assay in condition C1, we have (raw) M1=log2(c1)-log2(b) where c1 and b denote the intensities of the reporter in C1 and B for that assay. For each reporter and each assay in condition C2, we have (raw) M2=log2(c2)-log2(b), with similar notation. For each reporter, first its average normalized M1 value M1bar across the assays in condition C1 and its average normalized M2 value M2bar across the assays in condition C2 are computed, after removing the paired assays where at least one of the values is missing for that reporter. Then its ratio r is set to 2^(M1bar-M2bar), i.e. 2 to the (M1bar-M2bar) power. Its fold change FC is obtained as follows. If r=1, then FC=0; if r>1, then FC=r; if r<1 then FC=-(1/r).';

  return shift()->SUPER::getProtocol($name, $description);
}

1;

#================================================================================

package GUS::Community::RadAnalysis::TwoChannelReferenceDesignUnpaired;
use base qw(GUS::Community::RadAnalysis::FoldChanger);

sub setBaseX {$_[0]->SUPER::setBaseX($_[1], 1)}

sub getProtocol{

  my $name = 'Ratio and Fold Change calculation from M values in 2-channel reference design unpaired comparisons';
  my $description = 'The input to this protocol are normalized M values from a collection of 2-channel assays comparing condition C1 and condition C2 in a reference design unpaired fashion. Thus, if the common reference is denoted by B, for each reporter and each assay in condition C1, we have (raw) M1=log2(c1)-log2(b) where c1 and b denote the intensities of the reporter in C1 and B for that assay. For each reporter and each assay in condition C2, we have (raw) M2=log2(c2)-log2(b), with similar notation. For each reporter, first its average normalized M1 value M1bar across the assays in condition C1 and its average normalized M2 value M2bar across the assays in condition C2 are computed, after removing assays with missing values for that reporter. Then its ratio r is set to 2^(M1bar-M2bar), i.e. 2 to the (M1bar-M2bar) power. Its fold change FC is obtained as follows. If r=1, then FC=0; if r>1, then FC=r; if r<1 then FC=-(1/r).';

  return shift()->SUPER::getProtocol($name, $description);
}

1;

#================================================================================

package GUS::Community::RadAnalysis::OneChannelPaired;
use base qw(GUS::Community::RadAnalysis::FoldChanger);

sub setIsDataPaired {$_[0]->SUPER::setIsDataPaired($_[1], 1)}

sub getProtocol{

  my $name = 'Ratio and Fold Change calculation from normalized intensities in 1-channel paired comparisons';
  my $description = 'The input to this protocol are normalized (un-logged) intensities from a collection of 1-channel assays comparing condition C1 and condition C2 in a paired fashion. For each reporter and each pair of corresponding assays (one from condition C1 and the other from condition C2) with no missing values for that reporter, the ratio of the reporters intentities in the two assays c1/c2 is computed. For each reporter its ratio r is set to the average of its pairwise ratios over all pairs of correponding assays with no missing values for that reporter. Its fold change FC is obtained as follows. If r=1, then FC=0; if r>1, then FC=r; if r<1 then FC=-(1/r).';

  return shift()->SUPER::getProtocol($name, $description);
}

1;

#================================================================================

package GUS::Community::RadAnalysis::OneChannelUnpaired;
use base qw(GUS::Community::RadAnalysis::FoldChanger);

sub getProtocol{

  my $name = 'Ratio and Fold Change calculation from normalized intensities in 1-channel unpaired comparisons';
  my $description = 'The input to this protocol are normalized (un-logged) intensities from a collection of 1-channel assays comparing condition C1 and condition C2 in an unpaired fashion. For each reporter, its average normalized intensity c1 in condition C1 and its average normalized intensity c2 in condition C2 are computed, after removing assays with missing values for that reporter. Then its ratio r is set to the ratio of these average normalized intensities: c1/c2. Its fold change FC is obtained as follows. If r=1, then FC=0; if r>1, then FC=r; if r<1 then FC=-(1/r).';

  return shift()->SUPER::getProtocol($name, $description);
}

1;

#================================================================================

package GUS::Community::RadAnalysis::OneChannelLogNormalizedPaired;
use base qw(GUS::Community::RadAnalysis::FoldChanger);

sub setBaseX {$_[0]->SUPER::setBaseX($_[1], 1)}
sub setIsDataPaired {$_[0]->SUPER::setIsDataPaired($_[1], 1)}

sub getProtocol{

  my $name = 'Ratio and Fold Change calculation from normalized log intensities in 1-channel paired comparisons';
  my $description = 'The input to this protocol are normalized log2 intensities from a collection of 1-channel assays comparing condition C1 and condition C2 in a paired fashion. For each reporter its average log2 intensities CiBar in each condition are computed, after removing the paired assays where at least one of the values is missing for that reporter. Then its ratio r is set to 2^(C1bar-C2bar), i.e. 2 to the (C1bar-C2bar) power. Its fold change FC is obtained as follows. If r=1, then FC=0; if r>1, then FC=r; if r<1 then FC=-(1/r).';

  return shift()->SUPER::getProtocol($name, $description);
}

1;

#================================================================================

package GUS::Community::RadAnalysis::OneChannelLogNormalizedUnpaired;
use base qw(GUS::Community::RadAnalysis::FoldChanger);

sub setBaseX {$_[0]->SUPER::setBaseX($_[1], 1)}

sub getProtocol{

  my $name = 'Ratio and Fold Change calculation from normalized log intensities in 1-channel unpaired comparisons';
  my $description = 'The input to this protocol are normalized log2 intensities from a collection of 1-channel assays comparing condition C1 and condition C2 in an unpaired fashion. For each reporter its average log2 intensities CiBar in each condition are computed, after removing assays with missing values for that reporter. Then its ratio r is set to 2^(C1bar-C2bar), i.e. 2 to the (C1bar-C2bar) power. Its fold change FC is obtained as follows. If r=1, then FC=0; if r>1, then FC=r; if r<1 then FC=-(1/r).';

  return shift()->SUPER::getProtocol($name, $description);
}

1;

#================================================================================

package GUS::Community::RadAnalysis::TwoChannelUnpairedRatios;
use base qw(GUS::Community::RadAnalysis::FoldChanger);

sub getProtocol{

  my $name = 'Ratio and Fold Change calculation from ratios in 2-channel reference design unpaired comparisons';
  my $description = 'The input to this protocol are normalized (un-logged) ratios from a collection of 2-channel assays comparing condition C1 and condition C2 in a reference design unpaired fashion. Thus, if the common reference is denoted by B, for each reporter and each assay in condition C1, we have R1=c1/b where c1 and b denote the intensities of the reporter in C1 and B for that assay. For each reporter and each assay in condition C2, we have R2=c2/b, with similar notation. For each reporter, first its average normalized R1 value R1bar across the assays in condition C1 and its average normalized R2 value R2bar across the assays in condition C2 are computed, after removing assays with missing values for that reporter. Then its ratio r is set to R1bar/R2bar. Its fold change FC is obtained as follows. If r=1, then FC=0; if r>1, then FC=r; if r<1 then FC=-(1/r).';

  return shift()->SUPER::getProtocol($name, $description);
}

1;
