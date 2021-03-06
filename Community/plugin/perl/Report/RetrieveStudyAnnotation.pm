##
## RetrieveStudyAnnotation Plugin
## $Id: $
##

package GUS::Community::Plugin::Report::RetrieveStudyAnnotation;
@ISA = qw( GUS::PluginMgr::Plugin );

use strict;
use IO::File;
use GUS::PluginMgr::Plugin;

# ----------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------

sub getArgumentsDeclaration {
  my $argumentDeclaration =
    [
     booleanArg({name  => 'publicOnly',
		 descr => 'If given, only public studies will be considered.',
		 reqd  => 0,
		 constraintFunc => undef,
		 isList => 0,
		 default => 0,
	       }),

     booleanArg({name => 'published',
		 descr => 'If given, only studies with non-null bibliographic reference will be considered.',
		 constraintFunc => undef,
		 reqd => 0,
		 isList => 0,
		 default => 0
		}),
     stringArg({name => 'studyList',
	     descr => 'Comma-separated list of studies ids. If given, only these studies will be considered.',
	     constraintFunc => undef,
	     reqd => 0,
	     isList => 1
	    }),
     stringArg({name  => 'projectList',
		descr => 'Comma-separated list of project names. If given, only studies within these projects will be considered.',
		reqd  => 0,
		constraintFunc => undef,
		isList => 1
	       }),
     stringArg({name  => 'filterProjectList',
		descr => 'Comma-separated list of project names. If given, studies within these projects will be discarded.',
		reqd  => 0,
		constraintFunc => undef,
		isList => 1
	       }),
     stringArg({name  => 'groupList',
		descr => 'Comma-separated list of group names. If given, only studies within these projects will be considered.',
		reqd  => 0,
		constraintFunc => undef,
		isList => 1
	       }),
     stringArg({name  => 'filterGroupList',
		descr => 'Comma-separated list of group names. If given, studies within these groups will be discarded.',
		reqd  => 0,
		constraintFunc => undef,
		isList => 1
	       }),
     stringArg({name => 'taxonList',
		descr => 'Comma-separated list of taxon scientific names. If given, only studies involving the specified taxons will be considered.',
		constraintFunc => undef,
		reqd => 0,
		isList => 1
	       }),
     fileArg({name  => 'outFile',
	      descr => 'File to which to write the results.',
	      reqd => 1,
	      constraintFunc => undef,
	      mustExist => 0,
	      isList => 0,
	      format => undef
	     })
    ];

  return $argumentDeclaration;
}

# ----------------------------------------------------------------------
# Documentation
# ----------------------------------------------------------------------

sub getDocumentation {
  my $purposeBrief = "Retrieves annotation data for a collection of studies in Study/RAD.";

  my $purpose = "For each study in the specified collection this plugin retrievs both 'intent' and 'context' information. Intent information consists of its study_design_type (category and value) list and its study_factor_type (category and value) list. Context information consist of: taxon list, biomaterial characteristic (category and value) list, and treatment_type list.";

  my $tablesAffected = [];
  my $tablesDependedOn = [['Study::Study', 'The studies to consider'], ['Core::ProjectInfo', 'The projects whose studies should be considered or discarded, if specified'], ['Core::GroupInfo', 'The groups whose studies should be considered or discarded, if specified'], ['Study::OntologyEntry', 'Retrieved categories and values'], ['Study::StudyDesign', 'The study designs for the studies under consideration'], ['Study::StudyDesignType', 'The study design types for the studies under consideration'], ['Study::Factor', 'The study factors for the studies under consideration'], ['SRes::TaxonName', 'The scientific names of the taxons for the studies under consideration'], ['SRes::Taxon', 'The taxons for the studies under consideration'], ['Study::BioMaterialImp', 'The biomaterials utilized in the studies under consideration'], ['RAD::StudyBioMaterial', 'Retrieves all biomaterials for each study under consideration'], ['Study::BioMaterialCharacteristic', 'The biomaterial characteristics for the biomaterials involved in the studies under consideration'], ['RAD::Treatment', 'The treatments employed in the studies under consideration']];
  my $howToRestart = "No restart option.";
  my $failureCases = "";
  my $notes = "";

  my $documentation = {purpose=>$purpose, purposeBrief=>$purposeBrief, tablesAffected=>$tablesAffected, tablesDependedOn=>$tablesDependedOn, howToRestart=>$howToRestart, failureCases=>$failureCases, notes=>$notes};

  return $documentation;
}

# ----------------------------------------------------------------------
# create and initalize new plugin instance.
# ----------------------------------------------------------------------

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  my $documentation = &getDocumentation();
  my $argumentDeclaration    = &getArgumentsDeclaration();

  $self->initialize({requiredDbVersion => 3.6,
		     cvsRevision => '$Revision: 6072 $',
		     name => ref($self),
		     revisionNotes => '',
		     argsDeclaration => $argumentDeclaration,
		     documentation => $documentation
		    });
  return $self;
}

sub run {
  my ($self) = @_;
  $self->logArgs();

  my $dbh = $self->getQueryHandle();


  $self->logData("Retrieving Studies");
  my $studies = $self->retrieveStudiesAllTaxons($dbh);

  $self->logData("Retrieving Taxons");  
  $self->retrieveTaxons($dbh, $studies);

  if (defined $self->getArg('taxonList')) {
    $self->logData("Restricting studies to specified taxons");
    my $studiesReduced = $self->reduceByTaxons($studies);
    $self->logDebug(scalar(@{$studies}));
    $self->logDebug(scalar(@{$studiesReduced}));
    $studies = $studiesReduced;
  }

  $self->logData("Retrieving Study Design Types");   
  $self->retrieveStudyDesignTypes($dbh, $studies);

  $self->logData("Retrieving Study Factor Types");   
  $self->retrieveStudyFactorTypes($dbh, $studies);

  $self->logData("Retrieving Biomaterial Characteristics");   
  $self->retrieveBioMaterialCharacteristics($dbh, $studies);

  $self->logData("Retrieving Treatment Types");   
  $self->retrieveTreatmentTypes($dbh, $studies);

  $self->logData("Writing output");   
  $self->writeResults($studies);
}

sub retrieveStudiesAllTaxons {
  my ($self, $dbh) = @_;
  my $query = "select study_id, name from Study.Study";
  my $whereUsed = 0;
  my $studies; 

  if ($self->getArg('publicOnly')) {
    $query .= " where other_read=1";
    $whereUsed = 1;
  }
  if ($self->getArg('published')) {
    $query .= $whereUsed ? " and " : " where ";
    $query .= "bibliographic_reference_id is not null";
    $whereUsed = 1;
  }
  if (defined $self->getArg('studyList')) { 
    my $studyList = "(" . join(",", @{$self->getArg('studyList')}) . ")";
    $query .= $whereUsed ? " and " : " where "; 
    $query .= "study_id in $studyList";
    $whereUsed = 1;   
  }
  if (defined $self->getArg('projectList')) { 
    my $projectList = "(\'" . $self->getArg('projectList')->[0] . "\'" ;
    foreach (my $i=1; $i<@{$self->getArg('projectList')}; $i++) {
      $projectList .= ", \'" . $self->getArg('projectList')->[$i] . "\'";
    }
    $projectList .= ")";
    my $sth = $dbh->prepare("select project_id from Core.ProjectInfo where name in $projectList");
    $sth->execute();
    my @projectIds;
    while (my ($projectId)=$sth->fetchrow_array()) {
      push(@projectIds, $projectId);
    }
    $sth->finish();
    my $projectIdList = "(" . join(",", @projectIds) . ")";   
    $query .= $whereUsed ? " and " : " where "; 
    $query .= "row_project_id in $projectIdList";
    $whereUsed = 1;   
  }
  if (defined $self->getArg('filterProjectList')) { 
    my $filterProjectList = "(\'" . $self->getArg('filterProjectList')->[0] . "\'" ;
    foreach (my $i=1; $i<@{$self->getArg('filterProjectList')}; $i++) {
      $filterProjectList .= ", \'" . $self->getArg('filterProjectList')->[$i] . "\'";
    }
    $filterProjectList .= ")";
    my $sth = $dbh->prepare("select project_id from Core.ProjectInfo where name in $filterProjectList");
    $sth->execute();
    my @filterProjectIds;
    while (my ($projectId)=$sth->fetchrow_array()) {
      push(@filterProjectIds, $projectId);
    }
    $sth->finish();
    my $filterProjectIdList = "(" . join(",", @filterProjectIds) . ")";   
    $query .= $whereUsed ? " and " : " where "; 
    $query .= "row_project_id not in $filterProjectIdList";
    $whereUsed = 1;   
  }
  if (defined $self->getArg('groupList')) { 
    my $groupList = "(\'" . $self->getArg('groupList')->[0] . "\'" ;
    foreach (my $i=1; $i<@{$self->getArg('groupList')}; $i++) {
      $groupList .= ", \'" . $self->getArg('groupList')->[$i] . "\'";
    }
    $groupList .= ")";
    my $sth = $dbh->prepare("select group_id from Core.GroupInfo where name in $groupList");
    $sth->execute();
    my @groupIds;
    while (my ($groupId)=$sth->fetchrow_array()) {
      push(@groupIds, $groupId);
    }
    $sth->finish();
    my $groupIdList = "(" . join(",", @groupIds) . ")";   
    $query .= $whereUsed ? " and " : " where "; 
    $query .= "row_group_id in $groupIdList";
    $whereUsed = 1;   
  }
  if (defined $self->getArg('filterGroupList')) { 
    my $filterGroupList = "(\'" . $self->getArg('filterGroupList')->[0] . "\'" ;
    foreach (my $i=1; $i<@{$self->getArg('filterGroupList')}; $i++) {
      $filterGroupList .= ", \'" . $self->getArg('filterGroupList')->[$i] . "\'";
    }
    $filterGroupList .= ")";
    my $sth = $dbh->prepare("select group_id from Core.GroupInfo where name in $filterGroupList");
    $sth->execute();
    my @filterGroupIds;
    while (my ($groupId)=$sth->fetchrow_array()) {
      push(@filterGroupIds, $groupId);
    }
    $sth->finish();
    my $filterGroupIdList = "(" . join(",", @filterGroupIds) . ")";   
    $query .= $whereUsed ? " and " : " where "; 
    $query .= "row_group_id not in $filterGroupIdList";
    $whereUsed = 1;   
  }
  $query .= " order by study_id";
  $self->logDebug($query);
  my $sth = $dbh->prepare($query);
  $sth->execute();
  my $count = 0;
  while (my ($studyId, $studyName)=$sth->fetchrow_array()) {
    $self->logDebug("$studyId");
    $studies->[$count]->{'studyId'} = $studyId;
    $studies->[$count]->{'studyName'} = $studyName;
    $count++;
  }
  return($studies);
}

sub retrieveTaxons {
  my ($self, $dbh, $studies) = @_;
  my $sth = $dbh->prepare("select distinct t.name, b.taxon_id from Study.BioSource b, RAD.StudyBioMaterial sb, SRes.TaxonName t where sb.study_id=? and sb.bio_material_id=b.bio_material_id and b.taxon_id is not null and b.taxon_id=t.taxon_id and t.name_class='scientific name' order by t.name");
  for (my $i=0; $i<@{$studies}; $i++) {
    $sth->execute($studies->[$i]->{'studyId'});
    while (my ($taxonName, $taxonId)=$sth->fetchrow_array()) {
      push(@{$studies->[$i]->{'taxons'}}, $taxonName);
    }
    $sth->finish();
  }
}

sub reduceByTaxons {
  my ($self, $studies) = @_;
  my @specifiedTaxons = @{$self->getArg('taxonList')};
  my $studiesReduced;
  my $count = 0;

  for (my $i=0; $i<@{$studies}; $i++) {
    my $include = 0;
    if (defined $studies->[$i]->{'taxons'}) {
      for (my $h=0; $h<@{$studies->[$i]->{'taxons'}}; $h++) {
	for (my $j=0; $j<@specifiedTaxons; $j++) {
	  if ($studies->[$i]->{'taxons'}->[$h] eq $specifiedTaxons[$j]) {
	    $include = 1;
	    last;
	  }
	}
	if ($include) {
	  last;
	}
      }
    }
    if ($include) {
      $studiesReduced->[$count] =  $studies->[$i];
      $count++;
    }
  }
  return($studiesReduced);
}

sub retrieveStudyDesignTypes {
  my ($self, $dbh, $studies) = @_;
  my $sth = $dbh->prepare("select distinct oe.value from Study.OntologyEntry oe, Study.StudyDesign sd, Study.StudyDesignType sdt where sd.study_id=? and sd.study_design_id=sdt.study_design_id and sdt.ontology_entry_id=oe.ontology_entry_id order by oe.value");
 
  for (my $i=0; $i<@{$studies}; $i++) {
    $sth->execute($studies->[$i]->{'studyId'});
    my @studyDesignTypes;
    while (my ($value)=$sth->fetchrow_array()) {
      push(@studyDesignTypes, "$value");
    }
    $sth->finish();
    $studies->[$i]->{'studyDesignTypes'} = join(",", @studyDesignTypes);
  }
}

sub retrieveStudyFactorTypes {
  my ($self, $dbh, $studies) = @_;
  my $sth = $dbh->prepare("select distinct oe.value from Study.OntologyEntry oe, Study.StudyDesign sd, Study.StudyFactor sf where sd.study_id=? and sd.study_design_id=sf.study_design_id and sf.study_factor_type_id=oe.ontology_entry_id order by oe.value");
 
  for (my $i=0; $i<@{$studies}; $i++) {
    $sth->execute($studies->[$i]->{'studyId'});
    my @studyFactorTypes;
    while (my ($value)=$sth->fetchrow_array()) {
      push(@studyFactorTypes, "$value");
    }
    $sth->finish();
    $studies->[$i]->{'studyFactorTypes'} = join(",", @studyFactorTypes);
  }
}

sub retrieveBioMaterialCharacteristics {
  my ($self, $dbh, $studies) = @_;
  my $sth = $dbh->prepare("select distinct bmc.bio_material_id, oe.category, oe.value, oe.name, bmc.value from Study.OntologyEntry oe, Study.BioMaterialCharacteristic bmc, RAD.StudyBioMaterial sb where sb.study_id=? and sb.bio_material_id=bmc.bio_material_id and bmc.ontology_entry_id=oe.ontology_entry_id order by oe.category, oe.value");

  for (my $i=0; $i<@{$studies}; $i++) {
    $sth->execute($studies->[$i]->{'studyId'});
    my @bioMatChar;
    my %isCounted;
    my $ages;
    while (my ($id, $category, $value, $name, $bmcValue)=$sth->fetchrow_array()) {
      if ($category ne 'Age') {
	if ($bmcValue eq 'null' || $bmcValue eq '' || !defined $bmcValue) { 
	  if (!$isCounted{$value}) {
	    $isCounted{$value} = 1;
	    push(@bioMatChar, "$category\|$value");
	  }
	}
	else {
	  if (!$isCounted{"$bmcValue $value"}) {
	    $isCounted{"$bmcValue $value"} = 1;
	    push(@bioMatChar, "$category\|$bmcValue $value");
	  }
	}
      }
      else {
	if ($name eq 'TimeUnit') {
	  push(@{$ages->{$id}->{'number'}}, $bmcValue);
	  push(@{$ages->{$id}->{'timeUnit'}}, $value);
	}
	if ($name eq 'InitialTimePoint') {
	  $ages->{$id}->{'initialTimePoint'} = $value;
	}
      }
    }
    foreach my $id (keys %{$ages}) {
      my $string = '';
      my @numbers = @{$ages->{$id}->{'number'}};
      my @timeUnits = @{$ages->{$id}->{'timeUnit'}};
      if (scalar(@numbers)==2) {
	  if ($timeUnits[0] eq $timeUnits[1] && $numbers[0]<$numbers[1]) {
	    $string .= "Age\|$numbers[0] $timeUnits[0] to $numbers[1] $timeUnits[0]";
	  }
	  if ($timeUnits[0] eq $timeUnits[1] && $numbers[1]<$numbers[0]) {
	    $string .= "Age\|$numbers[1] $timeUnits[0] to $numbers[0] $timeUnits[0]";
	  }
      }
      if (scalar(@numbers)==1) {
	$string .= "Age\|$numbers[0] $timeUnits[0]";
      }
      if (defined $ages->{$id}->{'initialTimePoint'}) {
	$string .= " since $ages->{$id}->{'initialTimePoint'}";
      }
      if (!$isCounted{$string}) {
	$isCounted{$string} = 1;
	push(@bioMatChar, "$string");
      }
    }
    $sth->finish();
    $studies->[$i]->{'bioMaterialCharacteristics'} = join(",", @bioMatChar);
  }
}

sub retrieveTreatmentTypes {
  my ($self, $dbh, $studies) = @_;
  my $sth = $dbh->prepare("select distinct oe.value from Study.OntologyEntry oe, RAD.Treatment t, RAD.StudyBioMaterial sb where sb.study_id=? and sb.bio_material_id=t.bio_material_id and t.treatment_type_id=oe.ontology_entry_id order by oe.value");

  for (my $i=0; $i<@{$studies}; $i++) {
    $sth->execute($studies->[$i]->{'studyId'});
    my @treatmentTypes;
      while (my ($value)=$sth->fetchrow_array()) {
      push(@treatmentTypes, "$value");
    }
    $sth->finish();
    $studies->[$i]->{'treatmentTypes'} = join(",", @treatmentTypes);
  }

}

sub writeResults {
  my ($self, $studies) = @_;
  
  my $file = $self->getArg('outFile');
  my $fh = IO::File->new(">$file") || die "Cannot write file '$file': $!";
  $fh->print("StudyId\tStudyName\tStudyDesignTypes\tStudyFactorTypes\tTaxons\tBioMaterialCharacteristics\tTreatmentTypes\n");

  $self->logDebug(scalar(@{$studies}));
  for (my $i=0; $i<@{$studies}; $i++) {
    my $taxons = $studies->[$i]->{'taxons'} ? join(",", @{$studies->[$i]->{'taxons'}}) : "";
    $fh->print("$studies->[$i]->{'studyId'}\t$studies->[$i]->{'studyName'}\t$studies->[$i]->{'studyDesignTypes'}\t$studies->[$i]->{'studyFactorTypes'}\t$taxons\t$studies->[$i]->{'bioMaterialCharacteristics'}\t$studies->[$i]->{'treatmentTypes'}\n");
  } 
  $fh->close();
}
