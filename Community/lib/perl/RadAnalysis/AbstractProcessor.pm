package GUS::Community::RadAnalysis::AbstractProcessor;

use strict;

use GUS::Community::RadAnalysis::RadAnalysisError;

use GUS::Model::RAD::LogicalGroup;
use GUS::Model::RAD::LogicalGroupLink;

use Data::Dumper;

sub new {
  my $class = shift;

  if(ref($class) eq 'AbstractProcessor') {
    GUS::Community::RadAnalysis::ProcessorError->
        new("try to instantiate an abstract class AbstractProcessor")->throw();
  }

  bless {}, $class; 
}

#================================================================================

sub process {}

#================================================================================

sub getElementData {$_[0]->{_element_data}}

sub getElements {$_[0]->{_elements}}

#--------------------------------------------------------------------------------

sub queryForArrayTable {
  my ($self, $dbh, $arrayDesignName) = @_;

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

sub queryForElements {
  my ($self, $dbh, $arrayDesignName) = @_;

  my $arrayTable = $self->queryForArrayTable($dbh, $arrayDesignName);

  my %allSql = ('RAD.ShortOligoFamily' => <<Sql,
select composite_element_id 
from $arrayTable e, Rad.ARRAYDESIGN a
where a.array_design_id = e.array_design_id
 and a.name = ?
Sql
                'RAD.Spot' => <<Sql,
select element_id 
from $arrayTable e, Rad.ARRAYDESIGN a
where a.array_design_id = e.array_design_id
 and a.name = ?
Sql
                );

  my $sql = $allSql{$arrayTable};

  my $sh = $dbh->prepare($sql);
  $sh->execute($arrayDesignName);

  my @elementIds;

  while(my ($elementId) = $sh->fetchrow_array()) {
    push(@elementIds, $elementId);
  }
  $sh->finish();

  $self->{_elements} = \@elementIds;

  return \@elementIds;
}

#--------------------------------------------------------------------------------
# add elements to a matrix... will insert an "NA" for missing values
sub addElementData {
  my ($self, $name, $queryParam, $queryTable, $dbh) = @_;

  my $elements = $self->getElements();
  unless($elements) {
    die "";
  }

  my $sh = $self->getSqlHandle($queryTable, $dbh);

  foreach my $element (@$elements) {
    $sh->execute($queryParam, $element);

    my ($data) = $sh->fetchrow_array();
    $data = $data ? $data : 'NA';

    push @{$self->{_element_data}->{$element}->{$name}}, $data;
  }
  $sh->finish();

  return $self->getElementData();
}

#--------------------------------------------------------------------------------
# TODO:  Add for other views/tables as needed
sub getSqlHandle {
  my ($self, $table, $dbh) = @_;

    my %allSql = ('RMAExpress' => <<Sql,
select rma_expression_measure
from Rad.RMAExpress 
where quantification_id = ?
 and composite_element_id = ?
Sql
                  'DataTransformationResult' => <<Sql
select float_value
from Rad.DataTransformationResult
where analysis_id = ?
 and row_id = ?
Sql
               );

  my $sql = $allSql{$table};
  my $sh = $dbh->prepare($sql);

  return $sh;
}

#--------------------------------------------------------------------------------

sub makeLogicalGroup {
  my ($self, $name, $description, $category, $queryLinkNames, $studyName, $dbh) = @_;

  my $logicalGroup = GUS::Model::RAD::LogicalGroup->new({name => $name,
                                                         category => $category,
                                                        });

  $logicalGroup->setDescription($description);

  if($logicalGroup->retrieveFromDB()) {
    my @links = $logicalGroup->getChildren('RAD::LogicalGroupLink', 1);
    map { $_->setParent($logicalGroup) } @links;
  }
  else {
    $self->makeLogicalGroupLinks($logicalGroup, $queryLinkNames, $category, $studyName, $dbh);
  }

  return $logicalGroup;
}


#--------------------------------------------------------------------------------

sub makeLogicalGroupLinks {
  my ($self, $lg, $names, $type, $studyName, $dbh) = @_;

  my $coreHash = $self->queryForTable($dbh);

  my %allSql = (quantification => <<Sql,
select quantification_id
from Rad.QUANTIFICATION q, Rad.ACQUISITION a,
     Rad.STUDYASSAY sa, Study.Study s
where q.acquisition_id = a.acquisition_id
 and a.assay_id = sa.assay_id
 and sa.study_id = s.study_id
 and s.name = ?
 and q.uri = ?
Sql
                analysis => <<Sql,
Sql
                );

  my $sql = $allSql{$type};

  my $sh = $dbh->prepare($sql);

  my @links;
  my $orderNum = 1;

  foreach my $name (@$names) {
    $sh->execute($studyName, $name);

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

    $orderNum++;
  }

  return \@links;
}


#--------------------------------------------------------------------------------

sub queryForTable {
  my ($self, $dbh) = @_;

  my %rv;

  my $sql = "select lower(t.name), t.table_id from Core.TableInfo t, Core.DATABASEINFO d
             where t.database_id = d.database_id
              and d.name = 'RAD'
              and t.name in ('Quantification', 'Analysis')";

  my $sh = $dbh->prepare($sql);
  $sh->execute();

  while(my ($name, $id) = $sh->fetchrow_array()) {
    $rv{$name} = $id;
  }
  $sh->finish();

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
      sort { $a->[1] <=> $b->[1] }
        map { [$_, $_->getOrderNum()] } @links;

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

1;

