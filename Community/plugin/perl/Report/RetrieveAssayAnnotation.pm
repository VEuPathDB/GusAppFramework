##
## RetrieveAssayAnnotation Plugin
## $Id: $
##

package GUS::Community::Plugin::Report::RetrieveAssayAnnotation;
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
     stringArg({name => 'studyList',
		descr => 'If given, only assays from these studies should be considered',
		constraintFunc => undef,
		reqd => 0,
		isList => 1
	       }),
     stringArg({name  => 'filterStudyList',
		descr => 'Comma-separated list of study_ids. If given, assays from these studies will be discarded.',
		reqd  => 0,
		constraintFunc => undef,
		isList => 1
	       }),
     booleanArg({name  => 'publicOnly',
		 descr => 'If given, only assays from public studies will be considered.',
		 reqd  => 0,
		 constraintFunc => undef,
		 isList => 0,
		 default => 0,
	       }),
     booleanArg({name => 'published',
		 descr => 'If given, only assays from studies with non-null bibliographic reference will be considered.',
		 constraintFunc => undef,
		 reqd => 0,
		 isList => 0,
		 default => 0
		}),
     stringArg({name => 'assayList',
	     descr => 'Comma-separated list of assay ids. If given, only these assays will be considered.',
	     constraintFunc => undef,
	     reqd => 0,
	     isList => 1
	    }),
     stringArg({name => 'channelList',
	     descr => 'Comma-separated list of channel names. Should be given only if assayList is provided and should have the same length and be ordered correspondingly. If given, only these channels for those assays will be considered.',
	     constraintFunc => undef,
	     reqd => 0,
	     isList => 1
	    }),
     stringArg({name  => 'projectList',
		descr => 'Comma-separated list of project names. If given, only assay from studies within these projects will be considered.',
		reqd  => 0,
		constraintFunc => undef,
		isList => 1
	       }),
     stringArg({name  => 'filterProjectList',
		descr => 'Comma-separated list of project names. If given, assays from studies within these projects will be discarded.',
		reqd  => 0,
		constraintFunc => undef,
		isList => 1
	       }),
     stringArg({name  => 'groupList',
		descr => 'Comma-separated list of group names. If given, only assays from studies within these projects will be considered.',
		reqd  => 0,
		constraintFunc => undef,
		isList => 1
	       }),
     stringArg({name  => 'filterGroupList',
		descr => 'Comma-separated list of group names. If given, assays from studies within these groups will be discarded.',
		reqd  => 0,
		constraintFunc => undef,
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
  my $purposeBrief = "Retrieves annotation data for a collection of assays in RAD.";

  my $purpose = "For each assay in the specified collection this plugin retrievs 'context' information for each of its channels. This includes Taxon, and most Biomaterial Characteristics and Protocol Types and Descriptions";

  my $tablesAffected = [];
  my $tablesDependedOn = [['Study::Study', 'The studies to consider'], ['RAD::StudyAssay', 'The assays and studies to consider'], ['Core::ProjectInfo', 'The projects whose studies should be considered or discarded, if specified'], ['Core::GroupInfo', 'The groups whose studies should be considered or discarded, if specified'], ['Study::OntologyEntry', 'Retrieved categories and values'], ['SRes::TaxonName', 'The preferred common names of the taxons for the assays under consideration'], ['SRes::Taxon', 'The taxons for the assays under consideration'], ['Study::BioMaterialImp', 'The biomaterials utilized in the assays under consideration'], ['RAD::AssayBioMaterial', 'Retrieves all biomaterials for each assay under consideration'], ['Study::BioMaterialCharacteristic', 'The biomaterial characteristics for the biomaterials involved in the assays under consideration'], ['RAD::Treatment', 'The treatments employed in the assays under consideration'], ['RAD::Protocol', 'The protocols employed in the assays under consideration'], ['RAD::Assay', 'The assays to consider'], ['RAD::Acquisition', 'The acquisition(s) for the assays under consideration']];
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

  $self->initialize({requiredDbVersion => 3.5,
		     cvsRevision => '$Revision: $',
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

  if (defined $self->getArg('channelList')) {
    $self->checkChannelList();
  }

  $self->logData("Retrieving Assays");
  my $assays = $self->retrieveAssays($dbh);

  $self->logData("Retrieving Channels");   
  $self->retrieveChannels($dbh, $assays);

  $self->logData("Retrieving Biomaterials");   
  $self->retrieveBioMaterials($dbh, $assays);

  $self->logData("Retrieving Taxons");  
  $self->retrieveTaxons($dbh, $assays);

  $self->logData("Retrieving Biomaterial Characteristics");   
  $self->retrieveBioMaterialCharacteristics($dbh, $assays);

  $self->logData("Retrieving Protocols");   
  $self->retrieveProtocols($dbh, $assays);

  $self->logData("Writing output");   
  $self->writeResults($assays);
}

sub checkChannelList {
  my ($self) = @_;
  if (!defined $self->getArg('assayList')) {
    die "Must provide --assayList if --channelList is provided.\n";
  } 
  elsif (scalar(@{$self->getArg('assayList')})!=scalar(@{$self->getArg('channelList')})) {
    die "The length of --channelList should equal that of --assayList.\n";
  }
}

sub retrieveAssays {
  my ($self, $dbh) = @_;
  my $query = "select s.study_id, s.name, a.assay_id, a.name from RAD.Assay a, RAD.StudyAssay sa, Study.Study s where a.assay_id=sa.assay_id and sa.study_id=s.study_id";
  my $assays; 

  if (defined $self->getArg('studyList')) { 
    my $studyList = "(" . join(",", @{$self->getArg('studyList')}) . ")";
    $query .= " and s.study_id in $studyList";
  }
  if (defined $self->getArg('filterStudyList')) { 
    my $filterStudyIdList = "(" . join(",", @{$self->getArg('filterStudyList')}) . ")";   
    $query .= " and s.study_id not in $filterStudyIdList";
  }
  if ($self->getArg('publicOnly')) {
    $query .= " and s.other_read=1";
  }
  if ($self->getArg('published')) {
    $query .= " and s.bibliographic_reference_id is not null";
  }
  if (defined $self->getArg('assayList')) { 
    my $assayList = "(" . join(",", @{$self->getArg('assayList')}) . ")";
    $query .= " and a.assay_id in $assayList";
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
    $query .= " and s.row_project_id in $projectIdList";   
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
    $query .= " and s.row_project_id not in $filterProjectIdList";
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
    $query .= " and s.row_group_id in $groupIdList";
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
    $query .= " and s.row_group_id not in $filterGroupIdList";
  }
  $query .= " order by s.study_id, a.assay_id";
  $self->logDebug($query);
  my $sth = $dbh->prepare($query);
  $sth->execute();
  my $count = 0;
  while (my ($studyId, $studyName, $assayId, $assayName)=$sth->fetchrow_array()) {
    $self->logDebug("assay: $assayId");
    $assays->[$count]->{'study'} = "$studyId: $studyName";
    $assays->[$count]->{'assayId'} = $assayId;
    $assays->[$count]->{'assayName'} = $assayName;
    $count++;
  }
  return($assays);
}

sub retrieveChannels {
  my ($self, $dbh, $assays) = @_;
  my $sth = $dbh->prepare("select distinct le.bio_material_id, oe.value from RAD.AssayLabeledExtract ale, Study.LabeledExtract le, RAD.LabelMethod lm, Study.OntologyEntry oe where ale.assay_id=? and ale.labeled_extract_id=le.bio_material_id and le.label_method_id=lm.label_method_id and lm.channel_id=oe.ontology_entry_id");

  for (my $i=0; $i<@{$assays}; $i++) {
    $sth->execute($assays->[$i]->{'assayId'});
    while (my ($id, $channel)=$sth->fetchrow_array()) {
      push(@{$assays->[$i]->{'channels'}}, $channel);
      push(@{$assays->[$i]->{'lex'}}, $id);
    }
    $sth->finish();
  }
}

sub recBioMaterials {
  my ($self, $dbh, $bms) = @_;
  my $sth = $dbh->prepare("select distinct bmm.bio_material_id from RAD.BioMaterialMeasurement bmm, RAD.Treatment t where t.bio_material_id=? and t.treatment_id=bmm.treatment_id");
  $self->logDebug("biomaterial: $bms->[0]");
  $sth->execute($bms->[0]);
  while (my ($parent)=$sth->fetchrow_array()) { 
    unshift(@{$bms}, $parent);
    $self->recBioMaterials($dbh, $bms);
  }
}

sub retrieveBioMaterials {
  my ($self, $dbh, $assays) = @_;
  for (my $i=0; $i<@{$assays}; $i++) {
    for (my $j=0; $j<@{$assays->[$i]->{'lex'}}; $j++) {
      my $bms;
      @{$bms} = ($assays->[$i]->{'lex'}->[$j]);
      $self->recBioMaterials($dbh, $bms);
      $assays->[$i]->{'bioMaterials'}->[$j] = $bms;
    }
  }
}

sub retrieveTaxons {
  my ($self, $dbh, $assays) = @_;
  my $sth = $dbh->prepare("select distinct t.name from Study.BioSource b, SRes.TaxonName t where b.bio_material_id=? and b.taxon_id is not null and b.taxon_id=t.taxon_id and t.name_class='preferred common name' order by t.name");
  for (my $i=0; $i<@{$assays}; $i++) {
    for (my $j=0; $j<@{$assays->[$i]->{'lex'}}; $j++) {
      my %isIn;
      for (my $k=0; $k<@{$assays->[$i]->{'bioMaterials'}->[$j]}; $k++) {
	$sth->execute($assays->[$i]->{'bioMaterials'}->[$j]->[$k]);
	while (my ($taxonName)=$sth->fetchrow_array()) {
	  if (!$isIn{$taxonName}) {
	    push(@{$assays->[$i]->{'taxons'}->[$j]}, $taxonName);
	    $isIn{$taxonName} = 1;
	  }
	}
	$sth->finish();
      }
    }
  }
}

sub retrieveBioMaterialCharacteristics {
  my ($self, $dbh, $assays) = @_;
  my  $sth = $dbh->prepare("select distinct oe.category, oe.name, oe.value, bmc.value from Study.OntologyEntry oe, Study.BioMaterialCharacteristic bmc where bmc.bio_material_id=? and bmc.ontology_entry_id=oe.ontology_entry_id and oe.category=? order by oe.name, oe.value");
  my @categories = ('Age', 'DevelopmentalStage', 'StrainOrLine', 'Genotype', 'GeneticModification', 'CellLine', 'CellType', 'OrganismPart', 'Sex', 'DiseaseState', 'DiseaseStaging');
  for (my $i=0; $i<@{$assays}; $i++) {
    for (my $j=0; $j<@categories; $j++) {
      for (my $k=0; $k<@{$assays->[$i]->{'lex'}}; $k++) {
	my %isIn;
	for (my $h=0; $h<@{$assays->[$i]->{'bioMaterials'}->[$k]}; $h++) {
	  $sth->execute($assays->[$i]->{'bioMaterials'}->[$k]->[$h], $categories[$j]);
	  while (my ($category, $name, $term, $value)=$sth->fetchrow_array()) {
	    if ($name ne 'null' && $name ne 'NULL' && $name ne "") {
	      $term = $name . "." . $term;
	    }
	    if ($value ne 'null' && $value ne 'NULL' && $value ne "") {
	      $term .= "." . $value;
	    }
	    if (!$isIn{$term}) {
	      push(@{$assays->[$i]->{$categories[$j]}->[$k]}, "$term");
	    }
	    $isIn{$term} = 1;
	  }
	  $sth->finish();
	}
      }
    }
  }
}


sub retrieveProtocols {
  my ($self, $dbh, $assays) = @_;
  my $sth = $dbh->prepare("select distinct t.order_num, oe.category, oe.value, p.protocol_description from Study.OntologyEntry oe, RAD.Treatment t, RAD.Protocol p where t.bio_material_id=? and t.protocol_id=p.protocol_id and p.protocol_type_id=oe.ontology_entry_id and oe.value not in ('labeling', 'dissect', 'nucleic_acid_extraction', 'linear_amplification', 'PCR_amplification', 'split', 'pool' ) order by t.order_num");

  for (my $i=0; $i<@{$assays}; $i++) {
    for (my $j=0; $j<@{$assays->[$i]->{'lex'}}; $j++) {
      my %isIn;
      for (my $k=0; $k<@{$assays->[$i]->{'bioMaterials'}->[$j]}; $k++) {
	$sth->execute($assays->[$i]->{'bioMaterials'}->[$j]->[$k]);
	while (my ($order, $category, $value, $description)=$sth->fetchrow_array()) {
	  my $result = $value . ":: '$description'";
	  if (!$isIn{$result}) {
	    push(@{$assays->[$i]->{'protocols'}->[$j]}, $result);
	    $isIn{$result} = 1;
	  }
	}
	$sth->finish();
      }
    }
  }
}

sub writeResults {
  my ($self, $assays) = @_;
  my @channels;
  if (defined $self->getArg('channelList')) {
    @channels = @{$self->getArg('channelList')};
  }
  my $file = $self->getArg('outFile');
  my $fh = IO::File->new(">$file") || die "Cannot write file '$file': $!";
  $fh->print("Study\tAssayId\tAssayName\tChannel\tTaxons\tAge\tDevelopmentalStage\tStrainOrLine\tGenotype\tGeneticModification\tCellLine\tCellType\tOrganismPart\tSex\tDiseaseState\tDiseaseStaging\tProtocols\n");

  $self->logDebug("num assays: " . scalar(@{$assays}));
  for (my $i=0; $i<@{$assays}; $i++) {
    for (my $j=0; $j<@{$assays->[$i]->{'lex'}}; $j++) {
      if (defined $channels[$i] && $assays->[$i]->{'channels'}->[$j] ne $channels[$i]) {
	next;
      }
      my $taxons = defined($assays->[$i]->{'taxons'}->[$j]) ? join(",", @{$assays->[$i]->{'taxons'}->[$j]}) : "";
      my $ages = defined($assays->[$i]->{'Age'}->[$j]) ? join(",", @{$assays->[$i]->{'Age'}->[$j]}) : "";
      my $devStages = defined($assays->[$i]->{'DevelopmentalStage'}->[$j]) ? join(",", @{$assays->[$i]->{'DevelopmentalStage'}->[$j]}) : "";
      my $strainLines = defined($assays->[$i]->{'StrainOrLine'}->[$j]) ? join(",", @{$assays->[$i]->{'StrainOrLine'}->[$j]}) : "";
      my $genotypes = defined($assays->[$i]->{'Genotype'}->[$j]) ? join(",", @{$assays->[$i]->{'Genotype'}->[$j]}) : "";
      my $geneticModifications = defined($assays->[$i]->{'GeneticModifications'}->[$j]) ? join(",", @{$assays->[$i]->{'GeneticModifications'}->[$j]}) : "";
      my $cellLines = defined($assays->[$i]->{'CellLine'}->[$j]) ? join(",", @{$assays->[$i]->{'CellLine'}->[$j]}) : "";
      my $cellTypes = defined($assays->[$i]->{'CellTypes'}->[$j]) ? join(",", @{$assays->[$i]->{'CellTypes'}->[$j]}) : "";
      my $organismParts = defined($assays->[$i]->{'OrganismPart'}->[$j]) ? join(",", @{$assays->[$i]->{'OrganismPart'}->[$j]}) : "";
      my $sex = defined($assays->[$i]->{'Sex'}->[$j]) ? join(",", @{$assays->[$i]->{'Sex'}->[$j]}) : "";
      my $diseaseStates = defined($assays->[$i]->{'DiseaseState'}->[$j]) ? join(",", @{$assays->[$i]->{'DiseaseState'}->[$j]}) : "";
      my $diseaseStagings = defined($assays->[$i]->{'DiseaseStaging'}->[$j]) ? join(",", @{$assays->[$i]->{'DiseaseStaging'}->[$j]}) : "";
      my $protocols = defined($assays->[$i]->{'protocols'}->[$j]) ? join(",", @{$assays->[$i]->{'protocols'}->[$j]}) : "";

      $fh->print("$assays->[$i]->{'study'}\t$assays->[$i]->{'assayId'}\t$assays->[$i]->{'assayName'}\t$assays->[$i]->{'channels'}->[$j]\t$taxons\t$ages\t$devStages\t$strainLines\t$genotypes\t$geneticModifications\t$cellLines\t$cellTypes\t$organismParts\t$sex\t$diseaseStates\t$diseaseStagings\t$protocols\n");   
    } 
  }
  $fh->close();
}
