package GUS::GOPredict::Plugin::RejectMotifTest;
@ISA = qw(GUS::PluginMgr::Plugin);

use lib "$ENV{GUS_HOME}/lib/perl";

use strict;
use Carp;


use GUS::Model::DoTS::RejectedMotif;
use GUS::Model::DoTS::Evidence;
use GUS::Model::DoTS::GOAssociation;
use GUS::Model::DoTS::GOAssociationInstance;
use GUS::Model::Core::DatabaseInfo;
use GUS::Model::Core::TableInfo;

use GUS::GOPredict::DatabaseAdapter;
use GUS::GOPredict::GoExtent;
use GUS::GOPredict::Association;
use GUS::GOPredict::AssociationGraph;
use GUS::GOPredict::GoGraph;
use GUS::GOPredict::GoManager;

use FileHandle;

$| = 1;

sub new {
  my ($class) = @_;
  print STDERR "class: $class";
  my $self = {};
  bless($self,$class);
  print STDERR "self: $self";
  my $usage = "TEST Plugin to investigate memory leaks for RejectMotif.pm.  Do not use in commit mode!.";
  
  


  my $easycsp = 
  [

   { o => 'source_id',
     t => 'string',
     h => 'source id'
     },

   { o => 'external_database_id',
     t => 'int',
     h => 'external database id',
     },
   { o => 'external_database_release_id',
     t => 'int',
     h => 'release id',
     r => 0,
 },
   
   { o => 'go_ext_db_rls_id',
     t => 'int',
     h => 'go version',
     r => 1,
 },
   
   
   { o => 'motif_rejection_reason_id',
     t => 'int',
     h => 'reason',
     r => 1,
 },
   { o => 'taxon_id',
     t => 'int',
     h => 'taxon',
 },
   
   { o => 'restart_file',
     t => 'string',
     h => 'restart file',
 },

   { o  => 'function_root_go_id',
     t => 'string',
     h => 'root go id',
 },
   
   
   ];
  
  $self->initialize({requiredDbVersion => {},
                     cvsRevision => '$Revision$', # cvs fills this in!
                     cvsTag => '$Name$', # cvs fills this in!
                     name => ref($self),
                     revisionNotes => 'TEST',
		     easyCspOptions => $easycsp,
		     usage => $usage,
		 });
  
  return $self;
}

my $verboseLevel = 1;
my $veryVerboseLevel = 2;
my $noVerboseLevel = 0;



sub run {
  my ($self) = @_;
  $self->log("beginning run");
  $self->logAlgInvocationId;
  $self->logCommit;

  my $queryHandle = $self->getQueryHandle();
  my $db = $self->getDb(); #for undef pointer cache
  my $databaseAdapter = GUS::GOPredict::DatabaseAdapter->new($queryHandle, $db);
  $self->log("created adapter");
  
#  my $motifList = $self->getAllRejectedMotifs();

  my $sourceId = $self->getCla()->{"source_id"};
  my $dbId = $self->getCla()->{"external_database_id"};
  my $version = $self->getCla()->{"external_database_release_id"};
  my $reason = $self->getCla()->{"motif_rejection_reason_id"};
  my $proteinTableId = $self->getTableId('DoTS', 'Protein');
  my $newGoVersion = $self->getCla()->{"go_ext_db_rls_id"};
  my $taxonId = $self->getCla()->{"taxon_id"};

  my $goManager = GUS::GOPredict::GoManager->new($databaseAdapter);
  $goManager->setNewFunctionRootGoId($self->getCla()->{"function_root_go_id"});
  $goManager->setVerbosityLevel($self->_getVerbosityLevel());

  #probably shouldn't have to do this step in the future
  $goManager->setDeprecatedAssociations($databaseAdapter->getDeprecatedAssociations($self->getCla->{query_taxon_id},
										    $newGoVersion,
										    $proteinTableId));
 
  my $proteinsAffected = $goManager->scrubProteinsOnly($newGoVersion, 180, $taxonId, 1, 1);

#  if ($sourceId && $dbId && $version){   #user has specified a specific motif to reject
#      my $rejectedMotif = $self->createRejectedMotif($sourceId, $version, $reason, $dbId);
#      $goManager->processRejectedMotifs($newGoVersion, $taxonId); #add to this after finishing goManager stuff
#  }
#  else{ #user want to process all rejected motifs in the database
#      foreach my $nextMotifVersion (keys %$motifList){
#	  my $sourceIds = $motifList->{$nextMotifVersion};
#	  foreach my $nextSourceId (keys %$sourceIds){
	#      my $rejectedMotif = $self->getRejectedMotif($nextSourceId, $nextMotifVersion);
#	      $goManager->processRejectedMotifs($newGoVersion, $taxonId);
#	  }
#      }
#  }

  my $returnMessage = "RejectMotif:  Plugin ran successfully";
  
}

sub getProcessedMotifs{
    my ($self) = @_;
    my $processedMotifs = $self->{ProcessedMotifs};
    if (!$processedMotifs){
	my $fileName = $self->getCla()->{"restart_file"};
	my $fh = FileHandle->new("<$fileName");
 	die ("error: could not open file!") unless $fh;
	
	$self->log("getting processed motifs");
	while (<$fh>){
	    chomp;
	    my $line = $_;
	    my ($databaseId, $version, $sourceId, $proteinId) = $line =~ /(\S+)\s(\S+)\s(\S+)\s(\S+)/;
	    $self->logVeryVerbose("adding $databaseId, $version, $sourceId, $proteinId to processed");
	    $processedMotifs->{$databaseId}->{$version}->{$sourceId}->{$proteinId} = 1;
	}
	if (!$processedMotifs->{100}){ $self->logVeryVerbose("getProcessedmOtifs: no entry for 100 part 1")};
	$self->{ProcessedMotifs} = $processedMotifs;
    }
    if (!$processedMotifs->{100}){ $self->logVeryVerbose("getProcessedmOtifs: no entry for 100 part 2")};
    return $processedMotifs;
}

#retrieves a rejected motif given the external database release id of the motif and its source id
sub getRejectedMotif {
  my ($self, $sourceId, $version) = @_;
  
  my $rejectedMotif = 
      GUS::Model::DoTS::RejectedMotif->new(
					   { source_id => $sourceId,
					     external_database_release_id => $version,
					 });
  
  $rejectedMotif->retrieveFromDB();
  return $rejectedMotif;
}

#creates a new rejected motif, setting attributes according to parameters.  Fails if the motif already
#exists.  Returns the motif object (GUS::Model::DoTS::RejectedMotif)
sub createRejectedMotif {
  my ($self, $sourceId, $version, $dbId, $reason) = @_;
  
  my $rejectedMotif = 
      GUS::Model::DoTS::RejectedMotif->new(
					   { source_id => $sourceId,
					     external_database_id => $dbId,
					     external_database_release_id => $version,
					     motif_rejection_reason_id => $reason,
					 });
  
  if ($rejectedMotif->retrieveFromDB() ) {
      die("Motif already in database");
  }
  
  $rejectedMotif->submit();
  return $rejectedMotif;
}

sub clearAssociations {
    my ($self, $rejectedMotif) = @_;
    
    my $fileName = $self->getCla()->{"restart_file"};
#    my $fh = FileHandle->new(">>$fileName");
        
    my $ruleTableId = $self->getTableId('DoTS', 'AAMotifGOTermRule');
    my $proteinTableId = $self->getTableId('DoTS', 'Protein');
    my $instanceTableId =   $self->getTableId('DoTS', 'GOAssociationInstance');
    my $databaseId = $self->getCla()->{"external_database_id"}; #should change this when have more than just 100 as id
    my $sourceId = $rejectedMotif->getSourceId();

    my $goVersion = $self->getCla()->{'go_ext_db_rls_id'};
    my $goGraph = $self->getGoGraph($goVersion);
#    my $processedMotifs = $self->getProcessedMotifs();
#    my $allRejectedMotifs = $self->getAllRejectedMotifs();
    my $rejectedMotifId = $rejectedMotif->getRejectedMotifId();
    my $rejectedMotifVersion = $rejectedMotif->getExternalDatabaseReleaseId();
    my $evidenceMap;
    
    my $taxonId = $self->getCla()->{"taxon_id"};
    
    my $taxonFromSql = "";
    my $taxonWhereSql = "";

    if ($taxonId){
	$taxonFromSql = ",  DoTS.RNAFeature rnaf, DoTS.RNAInstance rnai, DoTS.Assembly am ";
	$taxonWhereSql = "  and p.rna_id = rnai.rna_id and rnai.na_feature_id = rnaf.na_feature_id and rnaf.na_sequence_id = am.na_sequence_id and am.taxon_id = $taxonId";
    }

    my $sql = "select distinct ga.row_id
    from DoTS.Evidence e,
	 DoTS.Protein p,
         DoTS.AaMotifGoTermRule gtr,
         DoTS.AaMotifGoTermRuleSet gtrs,
         DoTS.MotifAaSequence mas,
         SRes.ExternalDatabaseRelease edr,
         DoTS.GoAssociationInstance gai,
         DoTS.GoAssociation ga" . $taxonFromSql . "
    where edr.external_database_id = $databaseId
      and mas.source_id = '$sourceId'
      and edr.external_database_release_id = mas.external_database_release_id
      and mas.aa_sequence_id = gtrs.aa_sequence_id_1
      and gtrs.aa_motif_go_term_rule_set_id = gtr.aa_motif_go_term_rule_set_id
      and gtr.aa_motif_go_term_rule_id = e.fact_id
      and e.fact_table_id = $ruleTableId
      and e.target_table_id = $instanceTableId
      and e.target_id = gai.go_association_instance_id
      and gai.go_association_id = ga.go_association_id
      and ga.is_deprecated = 0 
      and ga.row_id = p.protein_id and ga.table_id = $proteinTableId 
      $taxonWhereSql";
    
    my $dbh = $self->getDb()->getDbHandle();

    $self->log("executing $sql to get all Proteins with Associations created with this motif");
    
    my $stmt = $dbh->prepareAndExecute($sql);  
    my $extent;
    my $associationGraph;
    $extent = GUS::GOPredict::GoExtent->new($self->getAdapter());    
    while (my ($proteinId) = $stmt->fetchrow_array()) {

#	if (!$processedMotifs->{$databaseId}){
#	    $self->logVeryVerbose("processed motifs does not contain $databaseId");
#	}

#	$self->logVeryVerbose("checking if $databaseId $rejectedMotifVersion $sourceId $proteinId is processed");
#	if ($processedMotifs->{$databaseId}->{$rejectedMotifVersion}->{$sourceId}->{$proteinId}){
#	    $self->logVeryVerbose ("skipping motif $sourceId protein $proteinId as it has already been processed");
#	    next;
#	}

	$self->logVerbose("processing $databaseId $rejectedMotifVersion $proteinId");      

	$associationGraph = $self->getAdapter()->getAssociationGraph($goGraph, $proteinId, $proteinTableId,
								     $goVersion, $extent);


	# $self->getAdapter()->addEvidenceToGraph($associationGraph);
	
	$self->logVeryVerbose("AssociationGraph before processing rejected motif: " . $associationGraph->toString());
	
#	$evidenceMap = $self->getEvidenceMap($proteinId, $goGraph);
	
#	$associationGraph->processRejectedMotif($rejectedMotifVersion, $sourceId, $rejectedMotif, 
	#					$allRejectedMotifs, $evidenceMap);
	
	$self->logVeryVerbose("processedRejectedMotif for AssociationGraph: " . $associationGraph->toString());
	
#	my $assocList = $associationGraph->getAsList();

#	foreach my $assoc (@$assocList){
	    #temporary; should always be an object here
#	    my $gusAssoc = $assoc->getGusAssociationObject();
#	    if (!$gusAssoc){
#		$gusAssoc = 
#		    GUS::Model::DoTS::GOAssociation->new({ go_term_id => $assoc->getGoTerm()->getGusId(),
#							   table_id => $proteinTableId,
#							   row_id => $proteinId
#							   });
#		$gusAssoc->retrieveFromDB();
#		&confess ("gusAssoc for go term " . $assoc->getGoTerm()->getRealId() . " was not even listed as deprecated in the db\n") 
#		    if !$gusAssoc;
#		$assoc->setGusAssociationObject($gusAssoc);
#	  }
	  
#	  $assoc->updateGusObject();
#	  $gusAssoc->submit();
#	}
#	print $fh "$databaseId $rejectedMotifVersion $sourceId $proteinId\n";
	$extent->empty();
	$associationGraph->killReferences();
#	$self->undefPointerCache();
	$self->getAdapter()->undefPointerCache();
	undef $associationGraph;
#	$self->_prepareAndSubmitGusObjects($associationGraph, $extent, $proteinTableId, $proteinId, undef);

    }
}


sub _prepareAndSubmitGusObjects{

    my ($self, $associationGraph, $extent, $tableId, $proteinId, $goTermMap, $goSynMap) = @_;

    foreach my $association (@{$associationGraph->getAsList()}){
	
	my $gusAssociation = $association->getGusAssociationObject();
	
	if (!$gusAssociation){   #newly created primary assoc or newly created parent assoc 
                                 #that may have gus assoc object in extent
	
	    my $goTerm = $self->_getGoTermForExtent($association, $goTermMap);
	
	    $gusAssociation = $extent->getGusAssociationFromGusGoId($goTerm->getGusId());
	    if (!$gusAssociation){ #newly created primary assoc
		
		$self->_createGusAssociation($association, $tableId, $proteinId);
					    }
	    else{    #old parent assoc
		$association->setGusAssociationObject($gusAssociation);
	    }
	}

	$association->updateGusObject();
	$association->submitGusObject($self->getAdapter());
    }
    my $unevolvedAssociations = $associationGraph->getUnevolvedAssociations();
    if ($unevolvedAssociations){
	foreach my $unevolvedAssociation (@$unevolvedAssociations){
	    if ($unevolvedAssociation){
		$self->log("searching for association in extent for gus go id " . $unevolvedAssociation->getGoTerm()->getGusId());
		my $unevolvedGoTerm = $self->_getGoTermForExtent($unevolvedAssociation, $goTermMap);
		my $unevolvedGusObject = $extent->getGusAssociationFromGusGoId($unevolvedGoTerm->getGusId());
		if ($unevolvedGusObject){
		    $unevolvedAssociation->updateGusObject();
		    $unevolvedAssociation->submitGusObject($self->getAdapter());
		}
		else {  #there should be none of these; see goUsage.txt
		    $self->log("creating new GUS Association for unevolved Association, go term " . $unevolvedAssociation->getGoTerm()->getRealId());
		    my $deprecatedAssociations = $self->getDeprecatedAssociations();
		    my $depGusAssocId = $deprecatedAssociations->{$proteinId}->{$unevolvedAssociation->getGoTerm()->getRealId()};
		    if (!$depGusAssocId && !$goSynMap->{$unevolvedAssociation->getGoTerm()->getRealId()}){
			&confess("no deprecated gus association for unevolved association with go term " . $unevolvedAssociation->getGoTerm()->getRealId());
		    }
		    $self->_createGusAssociation($unevolvedAssociation, $tableId, $proteinId);
		}
	    }
	}
    }

    $self->logVeryVerbose("PrepareAndSubmitGusObjects: Association Graph right after submitting: " . $associationGraph->toString() . "\n");
    $associationGraph->killReferences();
    undef $associationGraph;
    $self->getAdapter()->undefPointerCache();
    $self->undefPointerCache();
}

sub _getGoTermForExtent{
    
    my ($self, $association, $goTermMap) = @_;
    
    my $goTerm;
    
    if (!$goTermMap){  #association has not been evolved, get its go term to check the extent
	$goTerm = $association->getGoTerm();
    }
    else { #association has been evolved, get its old go term to check the extent
	my $tempGoTerm = $association->getGoTerm();
	
	$goTerm = $goTermMap->{$tempGoTerm};
	$goTerm = $tempGoTerm if !$goTerm;    #go term did not exist in previous hierarchy
    }
    return $goTerm;
}



sub getTableId {
  my ($self, $dbName, $tableName) = @_;

  my $id = $self->{tableIds}->{$tableName};
  if (!$id){
      
      my $db =
	GUS::Model::Core::DatabaseInfo->new( { name => $dbName } );
      $db->retrieveFromDB();
      
      my $table =
	GUS::Model::Core::TableInfo->new(
					 { name => $tableName,
					   database_id => $db->getDatabaseId() } );
      $table->retrieveFromDB();
      $id = $table->getTableId();
      if (! $id ) {
	  die("can't get tableId for '$dbName\.$tableName'");
      }
      $self->{tableIds}->{$tableName} = $id;
  }

  return $id;

}

#returns map of go terms to motifs, where the go terms are associated to a protein
#and the motifs were the ones used to create the rules that are used as evidence for
#those associations.

#map is of the form:
#{ realGoId } -> { motif database release id } -> { motif source id } 
#should probably go in database adapter
sub getEvidenceMap{

    my ($self, $proteinId, $goGraph) = @_;
    
    my $ruleTableId = $self->getTableId('DoTS', 'AAMotifGOTermRule');
    my $instanceTableId = $self->getTableId('DoTS', 'GOAssociationInstance');
    my $proteinTableId = $self->getTableId('DoTS', 'Protein');
    
    my $evidenceMap;

    my $sql = 
	"select ga.go_term_id, mas.external_database_release_id, mas.source_id
    from DoTS.Evidence e,
          DoTS.AaMotifGoTermRule gtr,
          DoTS.AaMotifGoTermRuleSet gtrs,
          DoTS.MotifAaSequence mas,
          DoTS.GoAssociationInstance gai,
          DoTS.GoAssociation ga
    where mas.aa_sequence_id = gtrs.aa_sequence_id_1
       and gtrs.aa_motif_go_term_rule_set_id = gtr.aa_motif_go_term_rule_set_id
       and gtr.aa_motif_go_term_rule_id = e.fact_id
       and e.fact_table_id = $ruleTableId
       and e.target_table_id = $instanceTableId
       and e.target_id = gai.go_association_instance_id
       and gai.go_association_id = ga.go_association_id
       and ga.is_deprecated = 0
       and ga.table_id = $proteinTableId
       and ga.row_id = $proteinId";
    
    my $sth = $self->getQueryHandle()->prepareAndExecute($sql);
    
    while (my ($gusGoId, $motifVersion, $motifSourceId) = $sth->fetchrow_array()){

	my $realGoId = $goGraph->getGoTermFromGusGoId($gusGoId)->getRealId();
	$self->logVeryVerbose("EvidenceMap:  Adding triplet $realGoId, $motifVersion, $motifSourceId");
	$evidenceMap->{$realGoId}->{$motifVersion}->{$motifSourceId} = 1;
    }
    
    return $evidenceMap;
}

#returns map of all rejected motifs.  Assumes there will not be too many entries in the table 
#since they are all loaded into memory!
#map is of the form:
#{motif database release id} -> {motif source id}
sub getAllRejectedMotifs{

    my ($self) = @_;
    
    my $allRejectedMotifs = $self->{RejectedMotifs};

    my $version = $self->getCla()->{'external_database_release_id'};

    if (!$allRejectedMotifs){
	my $sql = "select external_database_release_id, source_id from DoTS.RejectedMotif";
	$sql .= " where external_database_release_id = $version" if $version;
	$self->log("getAllRejectedMotifs: executing $sql");
	my $sth = $self->getQueryHandle()->prepareAndExecute($sql);
	while (my ($motifVersion, $sourceId) = $sth->fetchrow_array()){
	    $allRejectedMotifs->{$motifVersion}->{$sourceId} = 1;
	}
	$self->{RejectedMotifs} = $allRejectedMotifs;
	$self->log("got rejected motifs");
    }
    return $allRejectedMotifs;
}

#creates new GoGraph given the external database release id for the release of GO Function terms
#currently associated with the protein set we are processing.
sub getGoGraph{
    
    my ($self, $goVersion) = @_;

    my $goGraph = $self->{GoGraph};
    if (!$goGraph){

	my $rootGoId = $self->getCla()->{'function_root_go_id'};
	
	my $goResultSet = $self->getAdapter()->getGoResultSet($goVersion); 
	$goGraph = GUS::GOPredict::GoGraph->newFromResultSet($goVersion, $goResultSet, $rootGoId);
	$self->{GoGraph} = $goGraph;
    }
    return $goGraph;
}

#DatabaseAdapter accessor method
sub setAdapter{
    my ($self, $adapter) = @_;
    $self->{Adapter} = $adapter;
}

#DatabaseAdapter accessor method
sub getAdapter{
    my ($self) = @_;
    return $self->{Adapter};
}

sub _getVerbosityLevel{

    my ($self) = @_;

    my $tempVerboseLevel = $noVerboseLevel;
    $tempVerboseLevel = $verboseLevel if $self->getCla()->{verbose};
    $tempVerboseLevel = $veryVerboseLevel if $self->getCla()->{veryVerbose};
    return $tempVerboseLevel;

}

1;
