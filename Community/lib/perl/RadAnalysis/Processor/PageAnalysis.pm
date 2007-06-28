package  GUS::Community::RadAnalysis::Processor::PageAnalysis;
use base qw(GUS::Community::RadAnalysis::AbstractProcessor);

use strict;

use GUS::Community::RadAnalysis::RadAnalysisError;
use GUS::Community::RadAnalysis::ProcessResult;

use GUS::Model::RAD::Protocol;
use GUS::Model::RAD::ProtocolQCParam;
use GUS::Model::RAD::ProtocolParam;
use GUS::Model::RAD::LogicalGroup;
use GUS::Model::RAD::LogicalGroupLink;

use GUS::Model::Core::TableInfo;
use GUS::Model::Core::UserInfo;

use GUS::Model::SRes::Contact;

use  GUS::ObjRelP::DbiDatabase;

use Data::Dumper;

=head1 NAME

GUS::Community::RadAnalysis::Processor::PageAnalysis

=head1 SYNOPSIS

  my $args = {arrayDesignName => 'ARRAYDESIGN',
              ...
             };

  my $processer = GUS::Community::RadAnalysis::Processor::PageAnalysis->new($args);
  my $results = $processer->process();

=head1 CONFIG ARGS

=over 4

=item C<arrayDesignName>

RAD::ArrayDesign name

=item C<quantificationUrisConditionA>

**OPTIONAL  RAD::Quantification uris

=item C<quantificationUrisConditionB>

**OPTIONAL RAD::Quantification uris

=item C<analysisNamesConditionA>

**OPTIONAL  (Analyses do not have names... must use analysisparam)

=item C<analysisNamesConditionB>

**OPTIONAL (Analyses do not have names... must use analysisparam)

=item C<studyName>

Study::Study Name

=item C<nameConditionA>

The name for the input (RAD::LogicalGroup)

=item C<nameConditionB>

**OPTIONAL The name for the input (RAD::LogicalGroup)

=item C<numberOfChannels>

Parameter for page (1 or 2)

=item C<isDataLogged>

Parameter for page (1 or 0)

=item C<isDataPaired>

Parameter for page (1 or 0)

=item C<pageInputFile>

How should the input file be named??

=item C<design>

If this is a 2 channel experiment  (R for Reference, D for DyeSwap)

=item C<referenceCondition>

**OPTIONAL What is in the NUMERATOR of the ratio (or log2(ratio))

=back

=head1 DESCRIPTION

Subclass of GUS::Community::RadAnalysis::AbstractProcessor which implements the process().
Query Database to create a PageInput file and then Run Page.

=head1 TODO

  -Get Data from Analysis Tables (2 channel Experiments)

=cut

my $RESULT_VIEW = 'RAD::PaGE';
my $PAGE = 'PaGE_5.1.6_modifiedConfOutput.pl';
my $PAGE_VERSION = '5.1.6';
my $MISSING_VALUE = 'NA';
my $USE_LOGGED_DATA = 1;

#--------------------------------------------------------------------------------

sub new {
  my ($class, $args) = @_;

  unless(ref($args) eq 'HASH') {
    GUS::Community::RadAnalysis::InputError->new("Must provide a hashref to the constructor of TwoClassPage")->throw();
  }

  my $requiredParams = ['arrayDesignName',
                        'studyName',
                        'logDir',
                        'numberOfChannels',
                        'levelConfidence',
                        'minPrescence',
                        'statistic',
                       ];

  my $self = $class->SUPER::new($args, $requiredParams);

  $args->{quantificationInputs} = [] unless($args->{quantificationInputs});
  $args->{analysisInputs} = [] unless($args->{analysisInputs});


  unless($args->{isDataLogged} == 1 || $args->{isDataLogged} == 0) {
    GUS::Community::RadAnalysis::InputError->new("Parameter [isDataLogged] is missing in the config file")->throw();
  }

  unless($args->{isDataPaired} == 1 || $args->{isDataPaired} == 0) {
    GUS::Community::RadAnalysis::InputError->new("Parameter [isDataPaired] is missing in the config file")->throw();
  }

  if($args->{numberOfChannels} == 2 && !($args->{design} eq 'R' || $args->{design} eq 'D') ) {
    GUS::Community::RadAnalysis::InputError->new("Parameter [design] must be given (R|D) when specifying 2 channel data.")->throw();
  }

  return $self;
}

#--------------------------------------------------------------------------------

sub getArrayDesignName {$_[0]->{arrayDesignName}}
sub getStudyName {$_[0]->{studyName}}
sub getLogDir {$_[0]->{logDir}}
sub getTranslator {$_[0]->{translator}}

sub getNumberOfChannels {$_[0]->{numberOfChannels}}
sub getIsDataLogged {$_[0]->{isDataLogged}}
sub getIsDataPaired {$_[0]->{isDataPaired}}
sub getDesign {$_[0]->{design}}
sub getMinPrescence {$_[0]->{minPrescence}}
sub getLevelConfidence {$_[0]->{levelConfidence}}
sub getStatistic {$_[0]->{statistic}}

sub getQuantificationView {$_[0]->{quantificationView}}
sub getQuantificationInputs {$_[0]->{quantificationInputs}}

sub getAnalysisView {$_[0]->{analysisView}}
sub getAnalysisInputs {$_[0]->{analysisInputs}}

sub getReferenceCondition {$_[0]->{referenceCondition}}
sub setReferenceCondition {$_[0]->{referenceCondition} = $_[1]}

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

  my $userId = $database->getDefaultUserId;
  my $contact = $self->getContactFromUserId($userId);

  my $dbh = $database->getQueryHandle();

  my $quantLgHash = $self->standardLogicalGroupInputs($self->getQuantificationInputs);
  my $analysisLgHash = $self->standardLogicalGroupInputs($self->getAnalysisInputs);

  my @shortLgNames = (keys %$quantLgHash, keys %$analysisLgHash);
  $self->setReferenceCondition($shortLgNames[0]) unless($self->getReferenceCondition());

  my $logicalGroups = $self->makeStandardLogicalGroups($dbh, $quantLgHash, $analysisLgHash, $self->getStudyName(), $self->getIsDataPaired(), 1);

  # Get all the elements for an ArrayDesign
  my $arrayDesignName = $self->getArrayDesignName();
  my $arrayTable = $self->queryForArrayTable($dbh, $arrayDesignName);

  my $allElements = $self->queryForElements($dbh, $arrayDesignName);

  # make the page Input file
  my $quantView = $self->getQuantificationView();
  my $analysisView = $self->getAnalysisView();

  my $pageMatrix = $self->createDataMatrixFromLogicalGroups($logicalGroups, $quantView, $analysisView, $dbh);
  my $inputFileName = $self->writePageInputFile($pageMatrix, $logicalGroups);

  # run page
  my $pageRawOutputFile = $self->runPage($inputFileName);
  my $pageResultsArray = $self->readRawPageResults($pageRawOutputFile);
  my $resultFile = $self->writeResultFile($pageResultsArray, $pageRawOutputFile);

  # make the Process Result
  my $result = GUS::Community::RadAnalysis::ProcessResult->new();

  $result->setContact($contact) if($contact);

  $result->setArrayTable($arrayTable);
  $result->setResultFile($resultFile);
  $result->setResultView($RESULT_VIEW);

  $result->setXmlTranslator($self->getTranslator());

  my $translatorArgs = { numberOfChannels => $self->getNumberOfChannels(), design => $self->getDesign() };
  $result->addToTranslatorFunctionArgs($translatorArgs);

  my $protocol = $self->setupProtocol();
  $result->setProtocol($protocol);

  my $paramValues = $self->setupParamValues();
  $result->addToParamValuesHashRef($paramValues);

  my $qcParamValues = $self->parseQcParamValues($pageResultsArray);
  $result->addToQcParamValuesHashRef($qcParamValues);

  $result->addLogicalGroups(@$logicalGroups);

  return [$result];
}

#--------------------------------------------------------------------------------

sub setupParamValues {
  my ($self) = @_;

  my $useLoggedData = $USE_LOGGED_DATA ? 'TRUE' : 'FALSE';
  my $dataIsLogged = $self->getIsDataLogged() ? 'TRUE' : 'FALSE';
  my $dataIsPaired = $self->getIsDataPaired() ? 'TRUE' : 'FALSE';

  my $statistic = $self->getStatistic();
  if($statistic eq 'tstat') {
    $statistic = 't-statistic';
  }

  my $values = { level_confidence_list => $self->getLevelConfidence,
                 min_presence_list => $self->getMinPrescence,
                 data_is_logged => $dataIsLogged,
                 paired => $dataIsPaired,
                 use_logged_data => $useLoggedData,
                 software_version => $PAGE_VERSION,
                 software_language => 'Perl',
                 num_channels => $self->getNumberOfChannels(),
                 statistic => $statistic,
               };

  if(my $design = $self->getDesign()) {
    $values->{design} = $design;
  }

  if(my $ref = $self->getReferenceCondition()) {
    $values->{reference_condition} = $ref;
  }

  return $values;
}

#--------------------------------------------------------------------------------
# Used code from EPConDB/bin/makePaGEforRADModified.pl
#--------------------------------------------------------------------------------

sub readRawPageResults {
  my ($self, $fn) = @_;

  my @pageData;

  open(PAGEFILE, $fn) or die "Cannot open file $fn for reading: $!";

  while(<PAGEFILE>) {
    chomp;
    push(@pageData, $_);
  }

  close PAGEFILE;

  return \@pageData;
}

#--------------------------------------------------------------------------------
# Used code from EPConDB/bin/makePaGEforRADModified.pl
#--------------------------------------------------------------------------------

sub writeResultFile {
  my ($self, $pageData, $fileName) = @_;

  $fileName = $fileName . "-forRad.txt";

  open(DATAFILE, "> $fileName") or die "Cannot open file $fileName for writing.\n";
  print DATAFILE "row_id\tconfidence_list\tpattern\tstat_list\n";

  my $count = 0;

  foreach my $row(@$pageData) {
    if($row =~ /^(\w+)(\d+)(\d+)(\d+)(\d+)(\d+)/ ) {
      my ($id, $conf, $pattern, $means, $stat, $info) = split(/\t/, $row);
      print DATAFILE "$id\t$conf\t$pattern\t$stat\n";
      $count++;
    }
  }
  close DATAFILE;

  #print STDERR "There are [$count] lines of differentially expressed genes in the result file\n";
  unless($count) {
    GUS::Community::RadAnalysis::ProcessorError->new("The datafile [$fileName] has no rows")->throw();
  }
  return $fileName;
}

#--------------------------------------------------------------------------------
# This code was copied almost directly from EPConDB/bin/makePaGEforRADModified.pl
#--------------------------------------------------------------------------------
sub parseQcParamValues {
  my ($self, $pageData) = @_;
    
    my($pageLowerCutRatioList, $pageUpperCutRatioList, $pageStatisticMinList, $pageStatisticMaxList, $pageTStatUp, $pageTStatDown);

    foreach my $row(@$pageData) {    
	if($row =~ /^Lower cutratio for group (\d+): (.+).$/i ) {
	    #print "lower_cutratio_list = $2\n";
	    $pageLowerCutRatioList = $2;
	}
	
	if($row =~ /^Upper cutratio for group (\d+): (.+).$/i ) {
	    #print "upper_cutratio_list = $2\n";
	    $pageUpperCutRatioList = $2;
	}

	if($row =~ /^Statistic range for group (\d+): \[(.+),(.+)\]/i)  {
	    #print "statistic_min_list = $2\nstatistic_max_list = $3\n";
	    $pageStatisticMinList = $2;
	    $pageStatisticMaxList = $3;
	}
	
	if($row =~ /^t-stat tuning parameter for group (\d+): up: (.+), down: (.+)/i)  {
	    #print "tstat_tuning_parameter_up = $2\ntstat_tuning_parameter_down = $3\n";
	    $pageTStatUp = $2;
	    $pageTStatDown = $3;
	}
    }

  return { lower_cutratio_list => $pageLowerCutRatioList,
           upper_cutratio_list => $pageUpperCutRatioList,
           statistic_min_list => $pageStatisticMinList,
           statistic_max_list => $pageStatisticMaxList,
           tstat_tuning_parameters_up => $pageTStatUp,
           tstat_tuning_parameters_down => $pageTStatDown,
          };
}

#--------------------------------------------------------------------------------

sub runPage {
  my ($self, $pageIn) = @_;

  my $pageOut = $pageIn;
  $pageOut =~ s/in$/out/;

  my $channels = $self->getNumberOfChannels();
  my $isLogged = $self->getIsDataLogged();
  my $isPaired = $self->getIsDataPaired();
  my $levelConfidence = $self->getLevelConfidence();
  my $minPrescence = $self->getMinPrescence();

  my $design = "--design " . $self->getDesign if($self->getDesign && $channels == 2);

  my $isLoggedArg = $isLogged ? "--data_is_logged" : "--data_not_logged";
  my $isPairedArg = $isPaired ? "--paired" : "--unpaired";

  my $statistic = '--' . $self->getStatistic();
  my $useLoggedData = $USE_LOGGED_DATA ? '--use_logged_data' : '--use_unlogged_data';

  my $whichR = `which PaGE_5.1.6_modifiedConfOutput.pl`;
  if ($whichR =~ /Not Found/) {
    GUS::Community::RadAnalysis::ProcessorError->new("PaGE_5.1.6_modifiedConfOutput.pl is needed to run this plug-in. Set your PATH varible to include this script")->throw();
  }

  my $pageCommand = "$PAGE --infile $pageIn --outfile $pageOut --output_gene_confidence_list --output_text --num_channels $channels $isLoggedArg $isPairedArg --level_confidence $levelConfidence $useLoggedData $statistic --min_presence $minPrescence --missing_value $MISSING_VALUE $design";

  my $systemResult = system($pageCommand);

  unless($systemResult / 256 == 0) {
    GUS::Community::RadAnalysis::ProcessorError->new("Error while attempting to run PaGE:\n$pageCommand")->throw();
  }

  # PaGE appends .txt to the output
  return $pageOut . ".txt";
}

#--------------------------------------------------------------------------------

sub writePageInputFile {
  my ($self, $input, $logicalGroups) = @_;

  my @header;

  my $pageIn = $self->getLogDir() . "/" . $self->getReferenceCondition() . ".in";
  $pageIn =~ s/ //g;

  open(PAGE, "> $pageIn") or die "Cannot open file [$pageIn] for writing: $!";

  my $condition = 0;

  # make the header
  foreach my $lg (@$logicalGroups) {
    my $name = $lg->getName();
    my $count = $lg->getChildren('RAD::LogicalGroupLink');

    my $prefix = 'c' . $condition . 'r';
    push @header, @{$self->pageHeader($prefix, $count)};

    $condition++;
  }

  print PAGE join("\t", "id", @header) . "\n";

  # write the data
  foreach my $element (keys %$input) {
    my @output;

    foreach my $lg (@$logicalGroups) {
      push(@output, @{$input->{$element}->{$lg->getName}});
    }

    my $naCount;
    map {$naCount++ if($_ eq $MISSING_VALUE)} @output;

    # Don't print if they are all NA's
    unless(scalar(@output) == $naCount) {
      print PAGE join("\t", $element, @output) . "\n";
    }
  }
  close PAGE;

  return $pageIn;
}

#--------------------------------------------------------------------------------

sub pageHeader {
  my ($self, $prefix, $n) = @_;

  my @values;

  foreach my $i (1..$n) {
    my $value = $prefix . $i;
    push(@values, $value);
  }
  return \@values;
}

#================================================================================
# Try to retrieve the Protocol and params but if they aren't there.... make them
#================================================================================

sub setupProtocol {
  my ($self) = @_;

  my $protocol = GUS::Model::RAD::Protocol->new({name => 'PaGE'});

  unless($protocol->retrieveFromDB) {
    $protocol->setUri('http://www.cbil.upenn.edu/PaGE');
    $protocol->setProtocolDescription('PaGE can be used to produce sets of differentially expressed genes with confidence measures attached. These lists are generated the False Discovery Rate method of controlling the false positives.  But PaGE is more than a differential expression analysis tool.  PaGE is a tool to attach descriptive, dependable, and easily interpretable expression patterns to genes across multiple conditions, each represented by a set of replicated array experiments.  The input consists of (replicated) intensities from a collection of array experiments from two or more conditions (or from a collection of direct comparisons on 2-channel arrays). The output consists of patterns, one for each row identifier in the data file. One condition is used as a reference to which the other types are compared. The length of a pattern equals the number of non-reference sample types. The symbols in the patterns are integers, where positive integers represent up-regulation as compared to the reference sample type and negative integers represent down-regulation. The patterns are based on the false discovery rates for each position in the pattern, so that the number of positive and negative symbols that appear in each position of the pattern is as descriptive as the data variability allows. The patterns generated are easily interpretable in that integers are used to represent different levels of up- or down-regulation as compared to the reference sample type.');

    $protocol->setSoftwareDescription('There are Perl and Java implementations.	');

    my $oe = GUS::Model::Study::OntologyEntry->new({value => 'differential_expression'});
    unless($oe->retrieveFromDB) {
      die "Cannot retrieve RAD::OntologyEntry [differential_expression]";
    }

    $protocol->setProtocolTypeId($oe->getId());
  }

  my $oeHash = $self->getOntologyEntries();

  $self->setupProtocolParams($protocol, $oeHash);
  $self->setupProtocolQCParams($protocol, $oeHash);

  return $protocol;
}


#--------------------------------------------------------------------------------

sub getOntologyEntries {
  my ($self) = @_;

  my %ontologyEntries;

  my @dataTypes = ('positive_integer',
                   'float',
                   'nonnegative_float',
                   'list_of_nonnegative_floats',
                   'string_datatype',
                   'list_of_positive_integers',
                   'boolean',
                   'list_of_floats',
                  );

  foreach(@dataTypes) {
    my $oe = GUS::Model::Study::OntologyEntry->new({value => $_,
                                                    category => 'DataType',
                                                   });

    unless($oe->retrieveFromDB) {
      die "Cannot retrieve RAD::OntologyEntry [$_]";
    }
 
    $ontologyEntries{$_} = $oe;
  }

  return \%ontologyEntries;
}

#--------------------------------------------------------------------------------

sub setupProtocolQCParams {
  my ($self, $protocol, $oeHash) = @_;

  my %params = (lower_cutratio_list => 'list_of_floats',
                statistic_min_list => 'list_of_floats', 
                statistic_max_list => 'list_of_floats',
                upper_cutratio_list => 'list_of_floats',
                tstat_tuning_parameters_down => 'list_of_nonnegative_floats',
                tstat_tuning_parameters_up => 'list_of_nonnegative_floats',
               );

  my @protocolParams = $protocol->getChildren('RAD::ProtocolQCParam', 1);

  if(scalar(@protocolParams) == 0) {

    foreach(keys %params) {
      my $dataType = $params{$_};
      my $oe = $oeHash->{$dataType};

      my $oeId = $oe->getId();

      my $param = GUS::Model::RAD::ProtocolQCParam->new({name => $_,
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

sub setupProtocolParams {
  my ($self, $protocol, $oeHash) = @_;

  my %params = (level_confidence_list => 'list_of_nonnegative_floats', 
                min_presence_list => 'list_of_positive_integers',
                data_is_logged => 'boolean',
                paired => 'boolean',
                use_logged_data => 'boolean',
                reference_condition => 'string_datatype',
                design => 'string_datatype',
                software_version => 'string_datatype',
                software_language => 'string_datatype',
                statistic => 'string_datatype',
                num_channels => 'positive_integer',
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
# Should Refactor this to the superclass??
sub getContactFromUserId {
  my ($self, $userId) = @_;

  my $userInfo = GUS::Model::Core::UserInfo->new({user_id => $userId});

  unless($userInfo->retrieveFromDB()) {
    GUS::Community::RadAnalysis::SqlError->new("User Id [$userId] is not valid")->throw();
  }

  my $contact;
  if(my $contactId = $userInfo->getContactId()) {
    $contact = GUS::Model::SRes::Contact->new({contact_id => $contactId});

    unless($contact->retrieveFromDB()) {
      GUS::Community::RadAnalysis::SqlError->new("Contact Id [$contactId] is not valid")->throw();
    }
  }

  return $contact;
}

#--------------------------------------------------------------------------------

1;
