package GUS::GOPredict::Plugin::RejectMotif;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
use Carp;

use GUS::PluginMgr::Plugin;
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

use FileHandle;

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  my $purposeBrief = "Reject a motif.";

  my $purpose = <<PLUGIN_PURPOSE;
    This plugin rejects a motif by inserting a record into DoTS.RejectedMotif
    (where the motif is identified by a 2-tuple of source_id and
    external_database_id).  It also disassociates any GO associations that have
    been made using the motif (by inserting a record into
    DoTS.GoAssociationInstance with the is_not field set).
PLUGIN_PURPOSE

  my $tablesAffected =
    [ ['DoTS::RejectedMotif', 'Insert a record for the rejected motif'],
      ['DoTS::GOAssociation', 'Update records, setting is_not, for associations based on the rejected motif'],
      ['DoTS::GOAssociationInstance', 'Insert a record for each updated GoAssociation'],
      ['DoTS::Evidence', 'For each rejected GoAssociation, insert a record pointing to the RejectedMotif'],
    ];

  my $tablesDependedOn =
    [ ['DoTS::MotifAaSequence', 'Identify motif by given source_id'],
      ['SRes::ExternalDatabaseRelease', 'Identify motif by given external_database_id'],
      ['DoTS::AaMotifGoTermRuleSet', 'Find rule sets that used the motif'],
      ['DoTS::AaMotifGoTermRule', 'Find rules that used the motif'],
      ['DoTS::Evidence', 'Find uses of rules as evidence for GO associations'],
      ['DoTS::GoAssociationInstance', 'Find GO associations based on rules based on motif'],
      ['Core::DatabaseInfo', 'Look up table IDs by database/table names'],
      ['Core::TableInfo', 'Look up table IDs by database/table names'],
    ];

  my $howToRestart = <<PLUGIN_RESTART;
This plugin has no restart facility.
PLUGIN_RESTART

  my $failureCases = <<PLUGIN_FAILURE_CASES;
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
PLUGIN_NOTES

  my $documentation = { purpose=>$purpose,
                        purposeBrief=>$purposeBrief,
                        tablesAffected=>$tablesAffected,
                        tablesDependedOn=>$tablesDependedOn,
                        howToRestart=>$howToRestart,
                        failureCases=>$failureCases,
                        notes=>$notes
                      };

  my $argsDeclaration =
  [
   stringArg({name  => 'source_id',
              descr => 'Motif Source ID.  Leave blank to process all motifs',
              reqd  => 0,
              constraintFunc=> undef,
              isList=>0,
           }),
   stringArg({name  => 'function_root_go_id',
              descr => 'GO Id (GO:XXXX format) of root of molecular function branch of GO Hierarchy',
              reqd  => 1,
              constraintFunc=> undef,
              isList=>0,
           }),
   integerArg({name  => 'external_database_id',
              descr => 'external_database_id of the motif that has been rejected.  Leave blank to process all motifs.',
              reqd  => 0,
              constraintFunc=> undef,
              isList=>0,
           }),
   integerArg({name  => 'external_database_release_id',
              descr => 'external_database_release_id of the motif that has been rejected.  Leave blank to process all motifs',
              reqd  => 0,
              constraintFunc=> undef,
              isList=>0,
           }),
   integerArg({name  => 'go_ext_db_rls_id',
              descr => 'external database release id corresponding to the current go function release of the affected proteins',
              reqd  => 1,
              constraintFunc=> undef,
              isList=>0,
           }),
   integerArg({name  => 'motif_rejection_reason_id',
              descr => 'motif_rejection_reason_id',
              reqd  => 1,
              constraintFunc=> undef,
              isList=>0,
           }),
   integerArg({name  => 'taxon_id',
              descr => 'taxon id of species to reject associations for.  If left blank, will do all species for this motif.',
             reqd => 0,
	       constraintFunc=> undef,
              isList=>0,
           }),
   fileArg({name => 'restart_file',
		  descr => 'write processed proteins into this file.  Use it to recover from an interrupted run of the plugin',
		  reqd => 1,
		  constraintFunc => undef,
		  isList => 0,
		  mustExist => 1,
		  format => 'Each line in the file is a space-separated quadruplet representing the external database id, external database release id, source id, and processed proteins of each motif.  The plugin automatically writes to it when running and reads from it when restarting.',
	      }),
   
  ];

  $self->initialize({requiredDbVersion => {},
                     cvsRevision => '$Revision$', # cvs fills this in!
                     cvsTag => '$Name$', # cvs fills this in!
                     name => ref($self),
                     revisionNotes => 'make consistent with GUS 3.0',
                     argsDeclaration => $argsDeclaration,
                     documentation => $documentation
                    });
  return $self;
}


sub run {
  my ($self) = @_;
  $self->log("beginning run");
  $self->logAlgInvocationId;
  $self->logCommit;

  my $queryHandle = $self->getQueryHandle();
  my $db = $self->getDb(); #for undef pointer cache
  $self->setAdapter(GUS::GOPredict::DatabaseAdapter->new($queryHandle, $db));
  $self->log("created adapter");
  
  my $motifList = $self->getAllRejectedMotifs();

  my $sourceId = $self->getArg("source_id");
  my $dbId = $self->getArg("external_database_id");
  my $version = $self->getArg("external_database_release_id");
  my $reason = $self->getArg("motif_rejection_reason_id");

  if ($sourceId && $dbId && $version){   #user has specified a specific motif to reject
      my $rejectedMotif = $self->createRejectedMotif($sourceId, $version, $reason, $dbId);
      $self->clearAssociations($rejectedMotif);
  }
  else{ #user want to process all rejected motifs in the database
      foreach my $nextMotifVersion (keys %$motifList){
	  my $sourceIds = $motifList->{$nextMotifVersion};
	  foreach my $nextSourceId (keys %$sourceIds){
	      my $rejectedMotif = $self->getRejectedMotif($nextSourceId, $nextMotifVersion);
	      $self->clearAssociations($rejectedMotif);
	  }
      }
  }

  my $returnMessage = "RejectMotif:  Plugin ran successfully";
  
}

sub getProcessedMotifs{
    my ($self) = @_;
    my $processedMotifs = $self->{ProcessedMotifs};
    if (!$processedMotifs){
	my $fileName = $self->getArg("restart_file");
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
    
    my $fileName = $self->getArg("restart_file");
    my $fh = FileHandle->new(">>$fileName");
        
    my $ruleTableId = $self->getTableId('DoTS', 'AAMotifGOTermRule');
    my $proteinTableId = $self->getTableId('DoTS', 'Protein');
    my $instanceTableId =   $self->getTableId('DoTS', 'GOAssociationInstance');
    my $databaseId = $self->getArg("external_database_id"); #should change this when have more than just 100 as id
    my $sourceId = $rejectedMotif->getSourceId();

    my $goVersion = $self->getArg('go_ext_db_rls_id');
    my $goGraph = $self->getGoGraph($goVersion);
    my $processedMotifs = $self->getProcessedMotifs();
    my $allRejectedMotifs = $self->getAllRejectedMotifs();
    my $rejectedMotifId = $rejectedMotif->getRejectedMotifId();
    my $rejectedMotifVersion = $rejectedMotif->getExternalDatabaseReleaseId();
    my $evidenceMap;
    
    my $taxonId = $self->getArg("taxon_id");
    
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
    
    my $dbh = $self->getQueryHandle();

    $self->log("executing $sql to get all Proteins with Associations created with this motif");
    
    my $stmt = $dbh->prepareAndExecute($sql);  
    my $extent;
    my $associationGraph;
    $extent = GUS::GOPredict::GoExtent->new($self->getAdapter());    
    while (my ($proteinId) = $stmt->fetchrow_array()) {

	$self->logVeryVerbose("checking if $databaseId $rejectedMotifVersion $sourceId $proteinId is processed");
	if ($processedMotifs->{$databaseId}->{$rejectedMotifVersion}->{$sourceId}->{$proteinId}){
	    $self->logVeryVerbose ("skipping motif $sourceId protein $proteinId as it has already been processed");
	    next;
	}

	$self->logVerbose("processing $databaseId $rejectedMotifVersion $proteinId");      

	$associationGraph = $self->getAdapter()->getAssociationGraph($goGraph, $proteinId, $proteinTableId,
								     $goVersion, $extent);


	# $self->getAdapter()->addEvidenceToGraph($associationGraph);
	
	$self->logVeryVerbose("AssociationGraph before processing rejected motif: " . $associationGraph->toString());
	
	$evidenceMap = $self->getEvidenceMap($proteinId, $goGraph);
	
	$associationGraph->processRejectedMotif($rejectedMotifVersion, $sourceId, $rejectedMotif, 
						$allRejectedMotifs, $evidenceMap);
	
	$self->logVeryVerbose("processedRejectedMotif for AssociationGraph: " . $associationGraph->toString());
	
	my $assocList = $associationGraph->getAsList();

	foreach my $assoc (@$assocList){
	    #temporary; should always be an object here
	    my $gusAssoc = $assoc->getGusAssociationObject();
	    if (!$gusAssoc){
		$gusAssoc = 
		    GUS::Model::DoTS::GOAssociation->new({ go_term_id => $assoc->getGoTerm()->getGusId(),
							   table_id => $proteinTableId,
							   row_id => $proteinId
							   });
		$gusAssoc->retrieveFromDB();
		&confess ("gusAssoc for go term " . $assoc->getGoTerm()->getRealId() . " was not even listed as deprecated in the db\n") 
		    if !$gusAssoc;
		$assoc->setGusAssociationObject($gusAssoc);
	  }
	  
	  $assoc->updateGusObject();
	  $gusAssoc->submit();
	}
	print $fh "$databaseId $rejectedMotifVersion $sourceId $proteinId\n";
	$extent->empty();
	$associationGraph->killReferences();
	my $assocList = $associationGraph->getAsList();
	foreach my $assoc (@$assocList){
	    undef $assoc;
	}
	undef $associationGraph;
	$self->getAdapter()->undefPointerCache();
	$self->undefPointerCache();

    }
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

    my $version = $self->getArg('external_database_release_id');

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

	my $rootGoId = $self->getArg('function_root_go_id');
	
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

1;
