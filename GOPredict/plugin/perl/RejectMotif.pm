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
   integerArg({name  => 'external_database_id',
              descr => 'external_database_id',
              reqd  => 1,
              constraintFunc=> undef,
              isList=>0,
           }),
   integerArg({name  => 'external_database_release_id',
              descr => 'external_database_release_id',
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
    select go_association_id
    from DoTS.Evidence e,
         DoTS.AaMotifGoTermRule gtr,
         DoTS.AaMotifGoTermRuleSet gtrs,
         DoTS.MotifAaSequence mas,
         SRes.ExternalDatabaseRelease edr,
         DoTS.GoAssociationInstance gai
    where edr.external_database_id = ?
      and mas.source_id = ?
      and edr.external_database_release_id = mas.external_database_release_id
      and mas.aa_sequence_id = gtrs.aa_sequence_id_1
      and gtrs.aa_motif_go_term_rule_set_id = gtr.aa_motif_go_term_rule_set_id
      and gtr.aa_motif_go_term_rule_id = e.fact_id
      and e.fact_table_id = ? /* DoTS.AaMotifGoTermRule */
      and e.target_table_id = ? /* DoTS.GoAssociationInstance */
      and e.target_id = gai.go_association_instance_id
    group by go_association_id
SQL

  my $dbh = $self->getQueryHandle();
  my $stmt = $dbh->prepare($sql);
  my $bind1 = $self->getArg('external_database_id');
  my $bind2 = $self->getArg('source_id');
  my $bind3 = getTableId('DoTS', 'AAMotifGOTermRule');
  my $bind4 = getTableId('DoTS', 'GOAssociationInstance');
                 
  $stmt->execute($bind1, $bind2, $bind3, $bind4);

  #print STDERR "sql = $sql\n";
  #print STDERR "bind variables: $bind1, $bind2, $bind3, $bind4\n";

  #my $goAssociationInstanceTableId = getTableId('DoTS', 'GOAssociationInstance');
  #my $rejectedMotifTableId = getTableId('DoTS', 'RejectedMotif'),

  my $rejectedMotifId = $rejectedMotif->getRejectedMotifId();
  while (my ($go_association_id) = $stmt->fetchrow_array()) {
    my $goAssociation = 
      GUS::Model::DoTS::GOAssociation->new( { go_association_id => $go_association_id } );

    if (!$goAssociation->retrieveFromDB()) {
      die("couldn't retrieve with go_association_id $go_association_id");
    }
    $goAssociation->setIsNot(1);

    my $goAssociationInstance =
      GUS::Model::DoTS::GOAssociationInstance->new(
        { go_association_id => $goAssociation->getGoAssociationId(),
          is_not => 1,
          is_primary => 1,
          is_deprecated => 0,
          review_status_id => 2, # reviewed, incorrect
          go_assoc_inst_loe_id => 3 }); # "CBIL Prediction"

    $goAssociation->addChild($goAssociationInstance);

    $goAssociation->submit();

    my $evidence =
      GUS::Model::DoTS::Evidence->new(
        { target_table_id => getTableId('DoTS', 'GOAssociationInstance'),
          target_id => $goAssociationInstance->getGoAssociationInstanceId(),
          fact_table_id => getTableId('DoTS', 'RejectedMotif'),
#         fact_id => $rejectedMotif->getRejectedMotifId(),
          fact_id => $rejectedMotifId,
          evidence_group_id => 0,
          best_evidence => 1 } );

    if ($evidence->retrieveFromDB() ) {
      die("Duplicate evidence row");
    }

    $evidence->submit();

    $self->undefPointerCache();
  }
}

sub getTableId {
  my ($dbName, $tableName) = @_;

  my $db =
    GUS::Model::Core::DatabaseInfo->new( { name => $dbName } );
  $db->retrieveFromDB();

  my $table =
    GUS::Model::Core::TableInfo->new(
      { name => $tableName,
        database_id => $db->getDatabaseId() } );

  $table->retrieveFromDB();

  my $id = $table->getTableId();

  if (! $id ) {
    die("can't get tableId for '$dbName\.$tableName'");
  }

  return $id;

}

1;
