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

GUS::Community::RadAnalysis::Processor::GenericAnalysis

=head1 SYNOPSIS

Create ProcessResult for files which have already had some analysis applied to them.

=head1 CONFIG ARGS

=over 4

=item C<arrayDesignName> or C<arrayDesign>

Exactly as it appears in RAD::ArrayDesign name or source_id

=item C<dataFile>

The Analysis Is already done... this is the file which has the data

=item C<studyName>

Study::Study.Name

=item C<fileTranslatorName>

File Name (Full Path) or a name for one in the config directory of your gus_home (minus the .xml) for the FileTranslator

=item C<resultView>

View of RAD::AnalysisResultImp

=item C<protocolName>

RAD::Protocol name for this analysis

=item C<paramValues>

list of Rad.ProtocolParam.name|value

=item C<quantificationInputs>

list of LogicalGroupName|QuantificationName

=back

=head1 DESCRIPTION

If you have run an analysis and want to use BatchRadAnalysis instead of RadAnalysis.  (Useful for pipeline stuff)


=cut

#--------------------------------------------------------------------------------

sub new {
  my ($class, $argsHash) = @_;

  my $args = ref($argsHash) eq 'HASH' ? $argsHash : {};

  my $requiredParams = ['arrayDesignName',
                        'dataFile',
                        'studyName',
                        'resultView',
                        'protocolName',
                        'paramValues',
                        'analysisName',
                       ];

  return $class->SUPER::new($args, $requiredParams);
}

#--------------------------------------------------------------------------------

sub getArrayDesignName {$_[0]->{arrayDesignName}}
sub getDataFile {$_[0]->{dataFile}}
sub getStudyName {$_[0]->{studyName}}
sub getFileTranslatorName {$_[0]->{fileTranslatorName}}
sub getResultView {$_[0]->{resultView}}
sub getQuantificationInputs {$_[0]->{quantificationInputs}}
sub getProtocolName {$_[0]->{protocolName}}
sub getParamValues {$_[0]->{paramValues}}
sub getAnalysisName {$_[0]->{analysisName}}

#--------------------------------------------------------------------------------

sub process {
  my ($self) = shift;

  my $database;
  unless($database = GUS::ObjRelP::DbiDatabase->getDefaultDatabase()) {
    GUS::Community::RadAnalysis::ProcessorError->new("Package [UserProvidedNorm] Requires Default DbiDatabase")->throw();
  }

  my $dbh = $database->getQueryHandle();

  # TODO:  analysis as input lg hash ??
  my $quantLgHash = $self->standardLogicalGroupInputs($self->getQuantificationInputs);

  #TODO:  add analysis as input stuff
  my $logicalGroups = $self->setupLogicalGroups($dbh, $quantLgHash);

  my $arrayDesignName = $self->getArrayDesignName();
  my $arrayTable = $self->queryForArrayTable($dbh, $arrayDesignName);

  my $result = GUS::Community::RadAnalysis::ProcessResult->new();

  $result->setArrayTable($arrayTable);
  $result->setResultFile($self->getDataFile);
  $result->setResultView($self->getResultView);
  $result->setXmlTranslator($self->getFileTranslatorName());

  my $protocol = $self->setupProtocol($dbh);
  $result->setProtocol($protocol);

  $result->addToTranslatorFunctionArgs({dbh => $dbh, arrayDesignName => $arrayDesignName});

  my $paramValues = $self->standardParameterValues($self->getParamValues());
  $result->addToParamValuesHashRef($paramValues);

  $result->addLogicalGroups(@$logicalGroups);

  my $analysisName = $self->getAnalysisName();
  $result->setAnalysisName($analysisName);

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
  my ($self, $dbh) = @_;

  my $protocolName = $self->getProtocolName();

  my $protocol = GUS::Model::RAD::Protocol->new({name => $protocolName});

  unless($protocol->retrieveFromDB) {
    GUS::Community::RadAnalysis::ProcessorError->new("Could not Retrieve RAD::Protocol [$protocolName]")->throw();
  }

  my @params = $protocol->getChildren('RAD::ProtocolParam', 1);
  my @qcParams = $protocol->getChildren('RAD::ProtocolQcParam', 1);

  # Treat everything as a protocol Series
  my $sql = "select child_protocol_id from Rad.PROTOCOLSTEP where parent_protocol_id = ?";

  my $sh = $dbh->prepare($sql);
  $sh->execute($protocol->getId());

  while(my ($childId) = $sh->fetchrow_array()) {

    my $child = GUS::Model::RAD::Protocol->new({protocol_id => $childId});
    unless($child->retrieveFromDB) {
      GUS::Community::RadAnalysis::ProcessorError->new("Could not Retrieve RAD::Protocol ID [$childId]")->throw();
    }

    push(@params, $child->getChildren('RAD::ProtocolParam', 1));
    push(@qcParams, $child->getChildren('RAD::ProtocolQcParam', 1));
  }

  $sh->finish();

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
