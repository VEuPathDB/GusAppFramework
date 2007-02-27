package GUS::Community::RadAnalysis::Processer::UserProvidedNormWithExistingQuants;
use base qw(GUS::Community::RadAnalysis::AbstractProcesser);

use strict;

use GUS::Community::RadAnalysis::RadAnalysisError;
use GUS::Community::RadAnalysis::ProcessResult;

use GUS::Model::RAD::Quantification;
use GUS::Model::RAD::Protocol;
use GUS::Model::RAD::ProtocolParam;
use GUS::Model::RAD::LogicalGroup;
use GUS::Model::RAD::LogicalGroupLink;

use GUS::Model::Study::OntologyEntry;

use GUS::Model::Core::TableInfo;

use  GUS::ObjRelP::DbiDatabase;

use Data::Dumper;

=head1 NAME

GUS::Community::RadAnalysis::Processer::UserProvidedNormWithExistingQuants

=head1 SYNOPSIS

Create ProcessResult for Files Which Have been Normalized by an outside User.

=head1 CONFIG ARGS

=over 4

=item C<arrayDesignName>

Exactly as it appears in RAD::ArrayDesign

=item C<directoryPrefix>

Prepended to the Quantification.uri

=item C<studyName>

Study::Study.Name

=item C<normalizationProtocol>

RAD::Protocol.name for the Resulting feature extraction protocol

=item C<inputQuantificationProtocol>

RAD::Protocol.name for the input (cel, gpr) feature extraction protocol

=item C<fileTranslatorName>

File Name (NOT full Path) for the FileTranslator (GUS/Community/config)

=back

=head1 DESCRIPTION

Get all uri's from a given study/quantification protocol and add the directory prefix to each
Each of these files represents one analysis

The Analysis protocol is the same as the NormalizationProtocol (Also Copy the QuantParams to AnalysisParam)
The Result_View is always DataTransformationResult
TechnologyType of the ArrayDesign is used to Determine the ArrayTable (in_situ_oligo_features = Rad::ShortOligoFamily, else Spot)
The LogicalGroupLink Table_id will always point to Rad::Quantification

=cut

#--------------------------------------------------------------------------------

sub new {
  my ($class, $argsHash) = @_;

  my $args = ref($argsHash) eq 'HASH' ? $argsHash : {};

  $args->{result_view} = 'RAD::DataTransformationResult';

  unless($args->{arrayDesignName}) {
    GUS::Community::RadAnalysis::InputError->new("Parameter [arrayDesignName] is missing in the config file")->throw();
  }

  unless($args->{directoryPrefix}) {
    GUS::Community::RadAnalysis::InputError->new("Parameter [directoryPrefix] is missing in the config file")->throw();
  }

  unless($args->{studyName}) {
    GUS::Community::RadAnalysis::InputError->new("Parameter [studyName] is missing in the config file")->throw();
  }

  unless($args->{normalizationProtocol}) {
    GUS::Community::RadAnalysis::InputError->new("Parameter [normalizationProtocol] is missing in the config file")->throw();
  }

  unless($args->{inputQuantificationProtocol}) {
    GUS::Community::RadAnalysis::InputError->new("Parameter [inputQuantificationProtocol] is missing in the config file")->throw();
  }

  unless($args->{fileTranslatorName}) {
    GUS::Community::RadAnalysis::InputError->new("Parameter [fileTranslatorName] is missing in the config file")->throw();
  }

  bless $args, $class;
}

#--------------------------------------------------------------------------------

sub getArrayDesignName {$_[0]->{arrayDesignName}}
sub getStudyName {$_[0]->{studyName}}
sub getDirectoryPrefix {$_[0]->{directoryPrefix}}
sub getNormalizationProtocol {$_[0]->{normalizationProtocol}}
sub getInputQuantificationProtocol {$_[0]->{inputQuantificationProtocol}}
sub getFileTranslatorName {$_[0]->{fileTranslatorName}}
sub getResultView {$_[0]->{result_view}}

#--------------------------------------------------------------------------------

sub process {
  my ($self) = shift;

  my $database;
  unless($database = GUS::ObjRelP::DbiDatabase->getDefaultDatabase()) {
    GUS::Community::RadAnalysis::ProcesserError->new("Package [UserProvidedNorm] Requires Default DbiDatabase")->throw();
  }

  my @results;

  my $analysisQuantifications = $self->getQuantifications($database);

  my $directoryPrefix = $self->getDirectoryPrefix();
  my $resultView = $self->getResultView();
  my $fileTranslator = $self->getFileTranslatorName();
  my $arrayDesignName = $self->getArrayDesignName();

  my $protocol = $self->getProtocol();
  my $arrayTable = $self->queryForArrayTable($database);


  foreach my $quantification (@$analysisQuantifications) {
    my $result = GUS::Community::RadAnalysis::ProcessResult->new();

    my $resultFile = $directoryPrefix . $quantification->getUri();

    my $paramValues = $self->getParamValues($quantification);
    my $logicalGroup = $self->createLogicalGroup($database, $quantification, $paramValues);

    $result->setResultFile($resultFile);
    $result->setArrayTable($arrayTable);
    $result->setXmlTranslator($fileTranslator);
    $result->setResultView($resultView);
    $result->setProtocol($protocol);
    $result->setArrayDesignName($arrayDesignName);
    $result->addToParamValuesHashRef($paramValues);
    $result->addLogicalGroups($logicalGroup);

    push(@results, $result);
  }

  return \@results;
}

#--------------------------------------------------------------------------------

sub createLogicalGroup {
  my ($self, $database, $quantification, $paramValues) = @_;

  my $dbh = $database->getQueryHandle();

  my $inputQuantificationProtocol = $self->getInputQuantificationProtocol();
  my $quantificationId = $quantification->getId();

  my $sql = <<Sql;
select q.quantification_id, q.name
from Rad.Quantification q, Rad.RELATEDQUANTIFICATION rq, Rad.PROTOCOL p
where rq.associated_quantification_id = q.quantification_id
and p.protocol_id = q.protocol_id
and p.name = ?
and rq.quantification_id = ?
Sql

  my $sh = $dbh->prepare($sql);
  $sh->execute($inputQuantificationProtocol, $quantificationId);

  my ($id, $name) = $sh->fetchrow_array();
  $sh->finish();

  my $table = GUS::Model::Core::TableInfo->new({name => 'Quantification',
                                                is_view => 0
                                               });
  unless($table->retrieveFromDB) {
    GUS::Community::RadAnalysis::SqlError->new("Could Not Create a Core::TableInfo object for [Quantification]")->throw();
  }

  my $group = GUS::Model::RAD::LogicalGroup->new({name => $name,
                                                  category => 'quantification'
                                                 });

  my $link = GUS::Model::RAD::LogicalGroupLink->new({row_id => $id});
  $link->setParent($table);
  $link->setParent($group);

  $paramValues->{AnalysisName} = $name . " - Normalization";

  return $group;
}

#--------------------------------------------------------------------------------

sub getParamValues {
  my ($self, $quantification) = @_;

  my %analysisParams;

  my @quantParams = $quantification->getChildren('RAD::QuantificationParam', 1);

  foreach my $param (@quantParams) {
    my $protocolParam = $param->getParent('RAD::ProtocolParam', 1);

    my $name = $protocolParam->getName();
    my $value = $param->getValue();

    $analysisParams{$name} = $value;
  }

  return \%analysisParams;
}

#--------------------------------------------------------------------------------

sub getProtocol {
  my ($self) = @_;

  my $protocolName = $self->getNormalizationProtocol();

  my $protocol = GUS::Model::RAD::Protocol->new({name => $protocolName});

  unless($protocol->retrieveFromDB()) {
    GUS::Community::RadAnalysis::SqlError->new("Could Not Create a RAD::Protocol object for [$protocolName]")->throw();
  }

  my @params = $protocol->getChildren('RAD::ProtocolParam', 1);

  my $oe = GUS::Model::Study::OntologyEntry->new({value => 'quantile_normalization_protocol_type'});
  unless($oe->retrieveFromDB()) {
    GUS::Community::RadAnalysis::SqlError->new("Could Not Retrieve Study::OntologyEntry object for [quantile_normalization_protocol_type]")->throw();
  }

  my $name = $protocol->getName() . " - quantile Norm";

  my $dtrProtocol = GUS::Model::RAD::Protocol->new({name => $name,
                                                    protocol_description => $protocol->getProtocolDescription()
                                                   });
  $dtrProtocol->setParent($oe);

  foreach my $param (@params) {
    my $dtrParam = GUS::Model::RAD::ProtocolParam->new({name => $param->getName(),
                                                        unit_type_id => $param->getUnitTypeId()
                                                       });

    $dtrParam->setParent($dtrProtocol);
  }

  my $nameParam = GUS::Model::RAD::ProtocolParam->new({name => 'AnalysisName' });
  $nameParam->setParent($dtrProtocol);

  return $dtrProtocol;
}


#--------------------------------------------------------------------------------

sub queryForArrayTable {
  my ($self, $database) = @_;

  my $arrayDesignName = $self->getArrayDesignName();

  my $dbh = $database->getQueryHandle();

  my $sql = <<Sql;
select oe.value
from study.ontologyentry oe, Rad.ARRAYDESIGN a
where a.technology_type_id = oe.ontology_entry_id
and a.name = ?
Sql

  my $sh = $dbh->prepare($sql);
  $sh->execute($arrayDesignName);  

  my ($type) = $sh->fetchrow_array();
  $sh->finish();

  if($type eq 'in_situ_oligo_features') {
    return 'RAD.ShortOligoFamily';
  }

  return 'RAD.Spot';
}


#--------------------------------------------------------------------------------

sub getQuantifications {
  my ($self, $database) = @_;

  my @quantifications;

  my $studyName = $self->getStudyName();
  my $normalizationProtocol = $self->getNormalizationProtocol();

  my $dbh = $database->getQueryHandle();

  my $sql = <<Sql;
select q.quantification_id
from Rad.QUANTIFICATION q, Rad.ACQUISITION a, 
Rad.STUDYASSAY sa, Study.Study s, Rad.PROTOCOL p
where q.acquisition_id = a.acquisition_id
 and a.assay_id = sa.assay_id
 and q.protocol_id = p.protocol_id
 and sa.study_id = s.study_id
 and s.name = ?
 and p.name = ?
Sql

  my $sh = $dbh->prepare($sql);
  $sh->execute($studyName, $normalizationProtocol);

  while(my ($id) = $sh->fetchrow_array()) {
    my $quantification = GUS::Model::RAD::Quantification->new({quantification_id => $id});

    unless($quantification->retrieveFromDB) {
      GUS::Community::RadAnalysis::SqlError->new("Could Not Create a RAD::Quantification object for quantification_id [$id]")->throw();
    }

    push(@quantifications, $quantification);
  }
  $sh->finish();


  return \@quantifications;
}




1;
