package GUS::GOPredict::Plugin::RejectMotif;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
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
              descr => 'Motif Source ID',
              reqd  => 1,
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
              descr => 'external_database_id of the motif that has been rejected',
              reqd  => 1,
              constraintFunc=> undef,
              isList=>0,
           }),
   integerArg({name  => 'external_database_release_id',
              descr => 'external_database_release_id of the motif that has been rejected',
              reqd  => 1,
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
  $self->logAlgInvocationId;
  $self->logCommit;

  my $queryHandle = $self->getQueryHandle();
  my $db = $self->getDb(); #for undef pointer cache
  $self->setAdapter(GUS::GOPredict::DatabaseAdapter->new($queryHandle, $db));
		    
  my $rejectedMotif = $self->getRejectedMotif();

  $self->clearAssociations($rejectedMotif);
}

sub getRejectedMotif {
  my ($self) = @_;

  my $rejectedMotif = 
    GUS::Model::DoTS::RejectedMotif->new(
      { source_id => $self->getArg('source_id'),
        external_database_id => $self->getArg('external_database_id'),
        external_database_release_id => $self->getArg('external_database_release_id'),
        motif_rejection_reason_id => $self->getArg('motif_rejection_reason_id')
      });

  if ($rejectedMotif->retrieveFromDB() ) {
    die("Motif already in database");
  }

  $rejectedMotif->submit();

  return $rejectedMotif;
}

sub clearAssociations {
  my ($self, $rejectedMotif) = @_;

  my $sql = <<SQL;
    select distinct ga.row_id
    from DoTS.Evidence e,
         DoTS.AaMotifGoTermRule gtr,
         DoTS.AaMotifGoTermRuleSet gtrs,
         DoTS.MotifAaSequence mas,
         SRes.ExternalDatabaseRelease edr,
         DoTS.GoAssociationInstance gai
         DoTS.GoAssociation ga
    where edr.external_database_id = ?
      and mas.source_id = ?
      and edr.external_database_release_id = mas.external_database_release_id
      and mas.aa_sequence_id = gtrs.aa_sequence_id_1
      and gtrs.aa_motif_go_term_rule_set_id = gtr.aa_motif_go_term_rule_set_id
      and gtr.aa_motif_go_term_rule_id = e.fact_id
      and e.fact_table_id = ? /* DoTS.AaMotifGoTermRule */
      and e.target_table_id = ? /* DoTS.GoAssociationInstance */
      and e.target_id = gai.go_association_instance_id
      and gai.go_association_id = ga.go_association_id
      and ga.is_deprecated = 0
      and ga.is_not = 0
      and ga.table_id = ? /* DoTS.Protein */
SQL

  my $dbh = $self->getQueryHandle();
  my $stmt = $dbh->prepare($sql);
  my $bind1 = $self->getArg('external_database_id');
  my $bind2 = $self->getArg('source_id');
  my $bind3 = $self->getTableId('DoTS', 'AAMotifGOTermRule');
  my $bind4 = $self->getTableId('DoTS', 'GOAssociationInstance');
  my $proteinTableId = $self->getTableId('DoTS', 'Protein');
                 
  $stmt->execute($bind1, $bind2, $bind3, $bind4, $proteinTableId);

  $self->logVerbose("sql = $sql");
  $self->logVerbose("bind variables: $bind1, $bind2, $bind3, $bind4, $proteinTableId");
  
  my $goVersion = $self->getArg('go_ext_db_rls_id');
  my $goGraph = $self->getGoGraph($goVersion);

  my $allRejectedMotifs = $self->getAllRejectedMotifs();
  my $rejectedMotifId = $rejectedMotif->getRejectedMotifId();
  my $rejectedMotifVersion = $self->getArg('external_database_release_id');
  
  while (my ($proteinId) = $stmt->fetchrow_array()) {
      
      my $extent = GUS::GOPredict::GoExtent->new($self->getAdapter());
      my $associationGraph = $self->getAdapter()->getAssociationGraph($goGraph, $proteinId, $proteinTableId,
								      $goVersion, $extent);
 
      $self->logVeryVerbose("AssociationGraph before processing rejected motif: " . $associationGraph->toString());

      my $evidenceMap = $self->getEvidenceMap($proteinId, $goGraph);
      
      $associationGraph->processRejectedMotif($rejectedMotifId, $rejectedMotifId, $rejectedMotif, 
					      $allRejectedMotifs, $evidenceMap);
      
      $self->logVeryVerbose("processedRejectedMotif for AssociationGraph: " . $associationGraph->toString());
     
      my $assocList = $associationGraph->getAsList();
      foreach my $assocObject (@$assocList){
	  $assocObject->updateGusObject();
	  my $gusAssoc = $assocObject->getGusAssociationObject();
	  $gusAssoc->submit(1);
      }
      
      $associationGraph->killReferences();
      $self->undefPointerCache();
  }
}

sub getTableId {
  my ($self, $dbName, $tableName) = @_;

  my $id = $self->{tableIds}->{tableName};
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
      $self->{tableIds}->{tableName} = $id;
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
	"select distinct (ga.go_term_id, mas.external_database_release_id, mas.source_id)
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

	my $realGoId = $goGraph->getGoTermByGusGoId($gusGoId)->getRealId();
	$self->logVeryVerbose("EvidenceMap:  Adding triplet $realGoId, $motifVersion, $motifSourceId");
	$evidenceMap->{$realGoId}->{$motifVersion}->{$motifSourceId} = 1;
    }
    
    return $evidenceMap;
}

#returns map of all rejected motifs.  Assumes there will not be too many entries in the table 
#since they are all loaded into memory!
#map is of the form:
#{motif database release id} -> {motif source id}

sub getRejectedMotifs{

    my ($self) = @_;

    my $allRejectedMotifs;
    my $sql = 
	"select external_database_release_id, source_id
         from DoTS.RejectedMotif";
    
    my $sth = $self->getQueryHandle()->prepareAndExecute($sql);
    while (my ($motifVersion, $sourceId) = $sth->fetchrow_array()){
	$allRejectedMotifs->{$motifVersion}->{$sourceId} = 1;
    }
    return $allRejectedMotifs;
}

#creates new GoGraph given the external database release id for the release of GO Function terms
#currently associated with the protein set we are processing.
sub getGoGraph{
    
    my ($self, $goVersion) = @_;

    my $rootGoId = $self->getArg('function_root_go_id');

    my $goResultSet = $self->getAdapter()->getGoResultSet($goVersion); 
    my $newGoGraph = GUS::GOPredict::GoGraph->newFromResultSet($goVersion, $goResultSet, $rootGoId);
    
    return $newGoGraph();
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
