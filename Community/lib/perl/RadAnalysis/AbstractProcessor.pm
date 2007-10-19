package GUS::Community::RadAnalysis::AbstractProcessor;

use strict;

use Tie::IxHash;

use GUS::Community::RadAnalysis::RadAnalysisError;

use GUS::Model::RAD::LogicalGroup;
use GUS::Model::RAD::LogicalGroupLink;

use Data::Dumper;

sub new {
  my ($class, $args, $expectedArrayRef) = @_;

  if(ref($class) eq 'AbstractProcessor') {
    GUS::Community::RadAnalysis::ProcessorError->
        new("try to instantiate an abstract class AbstractProcessor")->throw();
  }

  if($expectedArrayRef) {
    foreach my $param (@$expectedArrayRef) {
      unless($args->{$param}) {
        GUS::Community::RadAnalysis::InputError->new("Parameter [$param] is missing in the config file")->throw();
      }
    }
  }
  
  bless $args, $class; 
}

#================================================================================

sub process {}

#================================================================================

sub getElementData {$_[0]->{_element_data}}

sub getElements {$_[0]->{_elements}}

sub setPathToExecutable {$_[0]->{_path_to_executable} = $_[1]}
sub getPathToExecutable {$_[0]->{_path_to_executable}}

#--------------------------------------------------------------------------------

sub standardParameterValues {
  my ($self, $input)  = @_;

  return unless($input);

  unless(ref($input) eq 'ARRAY') {
    GUS::Community::RadAnalysis::InputError->new("Illegal param to method call [standardParameterValues].  Expected ARRAYREF")->throw();
  }

  my %rv;

  foreach my $param (@$input) {
    my ($name, $value) = split(/\|/, $param);
    $rv{$name} = $value;
  }

  return \%rv;
}

#--------------------------------------------------------------------------------

# [LGName|QuantUri, ...] or [LGName|AnalysisName]
sub standardLogicalGroupInputs {
  my ($self, $input) = @_;

  my %rv;
  tie %rv, "Tie::IxHash";

  return \%rv unless($input);

  unless(ref($input) eq 'ARRAY') {
    GUS::Community::RadAnalysis::InputError->new("Illegal param to method call [standardParameterValues].  Expected ARRAYREF")->throw();
  }

  foreach my $lg (@$input) {
    my ($name, $link) = split(/\|/, $lg);

    push @{$rv{$name}}, $link;
  }

  return \%rv;
}

#--------------------------------------------------------------------------------

sub makeStandardLogicalGroups {
  my ($self, $dbh, $quantLgHash, $analysisLgHash, $studyName, $isPaired, $prependStudyName) = @_;

  my @logicalGroups;

  my $prepend =  substr($studyName, 0, 35) . " ..." if($prependStudyName);

  foreach my $lgName (keys %$quantLgHash) {
    my $linkNames = $quantLgHash->{$lgName};

    $lgName = "$prepend $lgName" if($prependStudyName); 

    my $logicalGroup = $self->makeLogicalGroup($lgName, '', 'quantification', $linkNames, $studyName, $dbh, $isPaired);

    push(@logicalGroups, $logicalGroup);
  }

  foreach my $lgName (keys %$analysisLgHash) {
    my $ids = $analysisLgHash->{$lgName};

    $lgName = "$prepend: $lgName" if($prependStudyName); 

    my $logicalGroup = $self->makeLogicalGroup($lgName, '', 'analysis', $ids, $studyName, $dbh, $isPaired);

    push(@logicalGroups, $logicalGroup);
  }
  return \@logicalGroups;
}

#--------------------------------------------------------------------------------

sub queryForArrayTable {
  my ($self, $dbh, $arrayDesignName) = @_;

  my $sql = <<Sql;
select oe.value
from study.ontologyentry oe, Rad.ARRAYDESIGN a
where a.technology_type_id = oe.ontology_entry_id
and (a.name = ? or a.source_id = ?)
Sql

  my $sh = $dbh->prepare($sql);
  $sh->execute($arrayDesignName, $arrayDesignName);  

  my ($type) = $sh->fetchrow_array();
  $sh->finish();

  if($type eq 'in_situ_oligo_features') {
    return 'RAD.ShortOligoFamily';
  }

  return 'RAD.Spot';
}

#--------------------------------------------------------------------------------
# Currently excludes all Controls (RAD.Control)
sub queryForElements {
  my ($self, $dbh, $arrayDesignName) = @_;

  my $arrayTable = $self->queryForArrayTable($dbh, $arrayDesignName);
  my $coreTableHash = $self->queryForTable($dbh);

  my $tableId;
  if($arrayTable eq 'RAD.Spot') {
    $tableId = $coreTableHash->{spot};
  }
  elsif($arrayTable eq 'RAD.ShortOligoFamily') {
    $tableId = $coreTableHash->{shortoligofamily};
  }
  else {
    GUS::Community::RadAnalysis::ProcessorError->new("Illegal ArrayTable [$arrayTable].")->throw();
  }

  my %allSql = ('RAD.ShortOligoFamily' => <<Sql,
select e.composite_element_id
from  Rad.ARRAYDESIGN a, $arrayTable e left join Rad.Control c on c.row_id = e.composite_element_id and c.table_id = $tableId 
where c.control_id is null 
 and a.array_design_id = e.array_design_id 
 and e.name not like 'AFFX%'
 and (a.name = ? or a.source_id = ?)
Sql
                'RAD.Spot' => <<Sql,
select e.element_id
from  Rad.ARRAYDESIGN a, $arrayTable e left join Rad.Control c on c.row_id = e.element_id and c.table_id = $tableId 
where c.control_id is null 
 and a.array_design_id = e.array_design_id
 and (a.name = ? or a.source_id = ?)
Sql
                );

  my $sql = $allSql{$arrayTable};

  my $sh = $dbh->prepare($sql);
  $sh->execute($arrayDesignName, $arrayDesignName);

  my @elementIds;

  while(my ($elementId) = $sh->fetchrow_array()) {
    push(@elementIds, $elementId);
  }
  $sh->finish();

  $self->{_elements} = \@elementIds;

  unless(scalar(@elementIds) > 0) {
    GUS::Community::RadAnalysis::SqlError->new("Query did not retrieve any values\n$sql\n")->throw();
  }

  return \@elementIds;
}

#--------------------------------------------------------------------------------
# add elements to a matrix... will insert an "NA" for missing values
sub addElementData {
  my ($self, $name, $queryParam, $queryTable, $dbh) = @_;

  my $elements = $self->getElements();

  my $sh = $self->getSqlHandle($queryTable, $dbh);
  $sh->execute($queryParam);

  my %data;
  while(my ($id, $data) = $sh->fetchrow_array()) {
    $data{$id} = $data;
  }
  $sh->finish();

  foreach my $element (@$elements) {
    my $data = $data{$element} ? $data{$element} : 'NA';

    push @{$self->{_element_data}->{$element}->{$name}}, $data;    
  }

  return $self->getElementData();
}

#--------------------------------------------------------------------------------
# TODO:  Add for other views/tables as needed
sub getSqlHandle {
  my ($self, $table, $dbh) = @_;

    my %allSql = ('RMAExpress' => <<Sql,
select composite_element_id, rma_expression_measure
from Rad.RMAExpress 
where quantification_id = ?
Sql
                  'DataTransformationResult' => <<Sql,
select row_id, float_value
from Rad.DataTransformationResult
where analysis_id = ?
Sql
                  'AffymetrixMAS5' => <<Sql,
select composite_element_id, signal
from Rad.AffymetrixMas5
where quantification_id = ?
Sql
               );

  my $sql = $allSql{$table};

  my $sh = $dbh->prepare($sql);

  return $sh;
}

#--------------------------------------------------------------------------------

sub makeLogicalGroup {
  my ($self, $name, $description, $category, $queryLinkNames, $studyName, $dbh, $isPaired) = @_;

  my $logicalGroup = GUS::Model::RAD::LogicalGroup->new({name => $name,
                                                         category => $category,
                                                        });

  $logicalGroup->setDescription($description);

  if($logicalGroup->retrieveFromDB()) {
    my @links = $logicalGroup->getChildren('RAD::LogicalGroupLink', 1);
    map { $_->setParent($logicalGroup) } @links;
  }
  else {
    $self->makeLogicalGroupLinks($logicalGroup, $queryLinkNames, $category, $studyName, $dbh, $isPaired);
  }

  return $logicalGroup;
}


#--------------------------------------------------------------------------------

sub makeLogicalGroupLinks {
  my ($self, $lg, $names, $type, $studyName, $dbh, $isPaired) = @_;

  my $coreHash = $self->queryForTable($dbh);

  my %allSql = (quantification => <<Sql,
select quantification_id
from Rad.QUANTIFICATION q, Rad.ACQUISITION a,
     Rad.STUDYASSAY sa, Study.Study s
where q.acquisition_id = a.acquisition_id
 and a.assay_id = sa.assay_id
 and sa.study_id = s.study_id
 and s.name = ?
 and (q.uri = ? OR q.name = ?)
Sql
                analysis => <<Sql,
select distinct aa.analysis_id
from Rad.STUDYASSAY sa, Study.Study s,
     Rad.ASSAYANALYSIS aa LEFT JOIN Rad.ANALYSISPARAM ap on ap.analysis_id = aa.analysis_id
where aa.assay_id = sa.assay_id
 and s.name = ?
 and (aa.analysis_id = ? OR aa.analysis_id = ?)
Sql
                analysis_param_value => <<Sql,
select distinct aa.analysis_id
from Rad.STUDYASSAY sa, Study.Study s,
     Rad.ASSAYANALYSIS aa LEFT JOIN Rad.ANALYSISPARAM ap on ap.analysis_id = aa.analysis_id
where aa.assay_id = sa.assay_id
 and s.name = ?
 and (ap.value = ? OR ap.value = ?)
Sql
                );

  my $key = $type;
  if($key eq 'analysis' && $names->[0] =~ /\D/) {
    $key = $key . "_param_value";
  }

  my $sql = $allSql{$key};

  #print STDERR $sql;

  my $sh = $dbh->prepare($sql);

  my @links;
  my $orderNum;

  foreach my $name (@$names) {
    $orderNum++ if($isPaired);

    $sh->execute($studyName, $name, $name);

    my ($id) = $sh->fetchrow_array();
    $sh->finish();

    unless($id) {
      GUS::Community::RadAnalysis::SqlError->new("Could not retrieve ($type)_id for [$name]")->throw();
    }

    my $link = GUS::Model::RAD::LogicalGroupLink->new({order_num => $orderNum,
                                                       table_id => $coreHash->{$type},
                                                       row_id => $id,
                                                      });
    $link->setParent($lg);
  }

  return \@links;
}


#--------------------------------------------------------------------------------

sub queryForTable {
  my ($self, $dbh) = @_;

  if(my $cth = $self->{_core_table_hashref}) {
    return $cth;
  }

  my %rv;

  my $sql = "select lower(t.name), t.table_id from Core.TableInfo t, Core.DATABASEINFO d
             where t.database_id = d.database_id
              and d.name = 'RAD'
              and t.name in ('Quantification', 'Analysis','Spot', 'ShortOligoFamily')";

  my $sh = $dbh->prepare($sql);
  $sh->execute();

  while(my ($name, $id) = $sh->fetchrow_array()) {
    $rv{$name} = $id;
  }
  $sh->finish();

  $self->{_core_table_hashref} = \%rv;

  return \%rv;
}

#--------------------------------------------------------------------------------

sub createDataMatrixFromLogicalGroups {
  my ($self, $logicalGroups, $quantView, $analysisView, $dbh) = @_;

  foreach my $lg (@$logicalGroups) {
    my $name = $lg->getName();
    my $category = $lg->getCategory();

    my @links = $lg->getChildren('RAD::LogicalGroupLink');

    my @orderedLinks  = map { $_->[0] }
      sort { $a->[1] ? $a->[1] <=> $b->[1] : $a->[2] <=> $b->[2] }
        map { [$_, $_->getOrderNum(), $_->getRowId()] } @links;

    foreach my $link (@orderedLinks) {
      my $id = $link->getRowId();

      if($category eq 'quantification') {
        $self->addElementData($name, $id, $quantView, $dbh);
      }
      elsif($category eq 'analysis') {
        $self->addElementData($name, $id, $analysisView, $dbh);
      }
      else {
        GUS::Community::RadAnalysis::ProcessorError->new("Only Categories of analysis or quantification are allowed")->throw();
      }
    }
  }
  return $self->getElementData();
}

#--------------------------------------------------------------------------------
# Will try to retrieve a protocol and set all existing param children for 
#  regular protocol and for a series
sub retrieveProtocolFromName {
  my ($self, $name) = @_;

  my $protocol = GUS::Model::RAD::Protocol->new({name => $name});

  unless($protocol->retrieveFromDB) {
    return undef;
  }

  $self->setProtocolParameters($protocol);

  return $protocol;
}

#--------------------------------------------------------------------------------

sub setProtocolParams {
  my ($self, $protocol) = @_;

  my @protocolQcParams = $protocol->getChildren('RAD::ProtocolQCParam', 1);

  foreach my $paramQc (@protocolQcParams) {
    $paramQc->setParent($protocol);
  }

  my @protocolParams = $protocol->getChildren('RAD::ProtocolParam', 1);

  foreach my $param (@protocolParams) {
    $param->setParent($protocol);
  }

  return $protocol;
}


1;

