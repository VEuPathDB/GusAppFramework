package GUS::Community::RadAnalysis::Processor::GenericAnalysis;
use base qw(GUS::Community::RadAnalysis::AbstractProcessor);

use strict;

use GUS::Community::RadAnalysis::RadAnalysisError;
use GUS::Community::RadAnalysis::ProcessResult;

use GUS::Model::RAD::Protocol;
use GUS::Model::RAD::ProtocolParam;

use  GUS::ObjRelP::DbiDatabase;

use Data::Dumper;

=head1 NAME

GUS::Community::RadAnalysis::Processor::UserProvidedNormWithExistingQuants

=head1 SYNOPSIS

Create ProcessResult for Files Which Have been Normalized by an outside User.

=head1 CONFIG ARGS

=over 4

=item C<arrayDesignName>

Exactly as it appears in RAD::ArrayDesign

=item C<dataFile>

The Analysis Is already done... this is the file to be loaded

=item C<studyName>

Study::Study.Name

=item C<fileTranslatorName>

File Name (NOT full Path) for the FileTranslator (GUS/Community/config)

=item C<resultView>

View of RAD::AnalysisResultImp

=item C<protocolName>

RAD::Protocol name for this analysis

=back

=head1 DESCRIPTION

If you have run an analysis and want to use BatchRadAnalysis instead of RadAnalysis.  (Useful for pipeline stuff)


=cut

#--------------------------------------------------------------------------------

sub new {
  my ($class, $argsHash) = @_;

  my $args = ref($argsHash) eq 'HASH' ? $argsHash : {};

  unless($args->{arrayDesignName}) {
    GUS::Community::RadAnalysis::InputError->new("Parameter [arrayDesignName] is missing in the config file")->throw();
  }

  unless($args->{dataFile}) {
    GUS::Community::RadAnalysis::InputError->new("Parameter [dataFile] is missing in the config file")->throw();
  }

  unless($args->{studyName}) {
    GUS::Community::RadAnalysis::InputError->new("Parameter [studyName] is missing in the config file")->throw();
  }

  unless($args->{fileTranslatorName}) {
    GUS::Community::RadAnalysis::InputError->new("Parameter [fileTranslatorName] is missing in the config file")->throw();
  }

  unless($args->{resultView}) {
    GUS::Community::RadAnalysis::InputError->new("Parameter [resultView] is missing in the config file")->throw();
  }

  unless($args->{protocolName}) {
    GUS::Community::RadAnalysis::InputError->new("Parameter [protocolName] is missing in the config file")->throw();
  }

  unless($args->{paramValues}) {
    GUS::Community::RadAnalysis::InputError->new("Parameter [paramValues] is missing in the config file")->throw();
  }

  bless $args, $class;
}

#--------------------------------------------------------------------------------

sub getArrayDesignName {$_[0]->{arrayDesignName}}
sub getDataFile {$_[0]->{dataFile}}
sub getStudyName {$_[0]->{studyName}}
sub getFileTranslatorName {$_[0]->{fileTranslatorName}}
sub getResultView {$_[0]->{result_view}}
sub getQuantificationInputs {$_[0]->{quantificationInputs}}
sub getProtocolName {$_[0]->{protocolName}}
sub getTranslatorArgs {$_[0]->{translatorArgs}}
sub getParamValues {$_[0]->{paramValues}}


#--------------------------------------------------------------------------------

sub process {
  my ($self) = shift;

  my $database;
  unless($database = GUS::ObjRelP::DbiDatabase->getDefaultDatabase()) {
    GUS::Community::RadAnalysis::ProcessorError->new("Package [UserProvidedNorm] Requires Default DbiDatabase")->throw();
  }

  my $dbh = $database->getQueryHandle();

  my $quantLgHash = $self->standardLogicalGroupInputs($self->getQuantificationInputs);
  # TODO:  analysis lg hash ??

  my $logicalGroups = $self->setupLogicalGroups($dbh, $quantLgHash);

  my $arrayDesignName = $self->getArrayDesignName();
  my $arrayTable = $self->queryForArrayTable($dbh, $arrayDesignName);

  # make the Process Result
  my $result = GUS::Community::RadAnalysis::ProcessResult->new();

  $result->setArrayTable($arrayTable);
  $result->setResultFile($self->getDataFile);
  $result->setResultView($self->getResultView);
  $result->setXmlTranslator($self->getFileTranslatorName());

  my $protocol = $self->setupProtocol();
  $result->setProtocol($protocol);

  # TODO Add any other translator Args...
  $result->addToTranslatorFunctionArgs({dbh => $dbh, arrayDesignName => $arrayDesignName});

  my $paramValues = $self->setupParamValues($self->getParamValues());
  $result->addToParamValuesHashRef($paramValues);

  #TODO:  Generic Parameter values for the Retrieved Protocol ...

  $result->addLogicalGroups(@$logicalGroups);

  return [$result];
}

#--------------------------------------------------------------------------------

sub setupLogicalGroups {
  my ($self, $dbh, $quantLgHash) = @_;

  my @logicalGroups;

  my $studyName = $self->getStudyName();

  foreach my $lgName (keys %$quantLgHash) {
    my $uris = $quantLgHash->{$lgName};

    my $logicalGroup = $self->makeLogicalGroup($lgName, '', 'quantification', $uris, $studyName, $dbh);

    push(@logicalGroups, $logicalGroup);
  }

  return \@logicalGroups;
}

#--------------------------------------------------------------------------------

sub setupProtocol {
  my ($self) = @_;

  my $protocolName = $self->getProtocolName();

  my $protocol = GUS::Model::RAD::Protocol->new({name => $protocolName});

  unless($protocol->retrieveFromDB) {
    GUS::Community::RadAnalysis::ProcessorError->new("Could not Retrieve RAD::Protocol [$protocolName]")->throw();
  }

  my @params = $protocol->getChildren('RAD::ProtocolParam', 1);

  my $seenAnalysisName;

  foreach my $param (@params) {
    $seenAnalysisName = 1 if($param->getName() eq 'Analysis Name');

    $param->setParent($protocol);
  }

  # TODO:  Set the unit type to the ontologyentryid for string
  unless($seenAnalysisName) {
    my $nameParam = GUS::Model::RAD::ProtocolParam->new({name => 'Analysis Name'});
    $nameParam->setParent($protocol);

  }

  return $protocol;
}


1;
