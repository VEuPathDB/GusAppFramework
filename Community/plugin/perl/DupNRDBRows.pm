package GUS::Community::Plugin::DupNRDBRows;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
use CBIL::Util::Disp;
use GUS::PluginMgr::Plugin;
use GUS::Model::DoTS::NRDBEntry;
use GUS::Model::DoTS::ExternalAASequence;

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  my $purposeBrief = 'Provides a second copy of NRDB in the database by creating duplicating rows in NRDBEntry and rows in AASequenceImp containing nr protein sequences';

  my $purpose = <<PLUGIN_PURPOSE;
This plugin provides a second copy of the nr protein database in GUS by duplicating all rows in NRDBEntry and rows in AASequenceImp specific to nr protein sequences. All relevant external_db_release_ids will be recreated. PKs will be created new and FK in NRDBEntry will be made consistent.
PLUGIN_PURPOSE

  my $tablesAffected = 
    'dots.NRDBEntry,dots.AASequenceImp';

  my $tablesDependedOn =
    [
    ];

  my $howToRestart = <<PLUGIN_RESTART;
This plugin has no restart facility.
PLUGIN_RESTART

  my $failureCases = <<PLUGIN_FAILURE_CASES;
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
This plugin is intended for specific and single use.
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
   stringArg({name  => 'dbRelPairs',
		 descr => 'List of comma delimited pairs original source db_rel_id:duplicate source db_rel_id, for dots.NRDBEntry',
		 reqd  => 1,
		 constraintFunc=> undef,
		 isList=>0,
	   }),
   integerArg({name  => 'orig_NRDB_rel_id',
	      descr => 'Original release id for NRDB, in dots.ExternalAASequence',
	      reqd  => 1,
	      constraintFunc=> undef,
	      isList=>0,
	   }),
   integerArg({name  => 'dup_NRDB_rel_id',
	      descr => 'Duplicate release id for NRDB, in dots.ExternalAASequence',
	      reqd  => 1,
	      constraintFunc=> undef,
	      isList=>0,
	   }),
   integerArg({name => 'testnumber',
	       descr => 'number on which to test the plugin',
	       reqd => 0,
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

  $self->{dbHash} = $self->makeDBHash();

  $self->{aaSeqIdArr} = $self->getAASeqIds();

  $self->{origDupIdHash} = $self->makeExtAASeqDups();

  $self->{nrdbEntryIdArr} = $self->getNRDBEntryIds();

  $self->makeNRDBEntryDups();

}

sub makeDBHash {
  my ($self) = @_;
  my %dbHash;
  my @dbRelPairs = split (/,/, $self->getArgs->{dbRelPairs});
  foreach my $pair (@dbRelPairs) {
    my ($origDB,$dupDB) = split (/:/, $pair);
    $self->log("orig db:dup db - $origDB,$dupDB\n");
    $self->userError ("db release ids must be listed as original_db_rel_id:duplicate_db_rel_id") if (!$origDB || !$dupDB); 
    $dbHash{$origDB} = $dupDB;
  } 
  return \%dbHash;
}

sub getAASeqIds {
  my ($self) = @_;
  my @aaSeqIdArr;
  my $dbh = $self->getQueryHandle();
  my $origNRDBrel = $self->getArgs->{orig_NRDB_rel_id};
  my $testnumber = $self->getArgs->{testnumber} if $self->getArgs->{testnumber}; 
  my $sql = "select aa_sequence_id from dots.externalaasequence where external_database_release_id = $origNRDBrel";
  $sql.= " and rownum < $testnumber" if $self->getArgs->{testnumber};
  $self->log("$sql\n");
  my $stmt = $dbh->prepareAndExecute($sql);
  while (my $id = $stmt->fetchrow_array()) {
    push (@aaSeqIdArr,$id);
  }
  return \@aaSeqIdArr;
}

sub makeExtAASeqDups {
  my ($self) = @_;
  my %origDupIdHash;
  my $num;
  my $dbh = $self->getQueryHandle();
  my $sql = "select subclass_view,molecular_weight,sequence,length,description,source_id,secondary_identifier,name,molecule_type,crc32_value from dots.externalaasequence where aa_sequence_id = ?";
  $self->log("$sql\n");
  my $stmt = $dbh->prepare($sql);
  my $dupNRDBrel = $self->getArgs->{dup_NRDB_rel_id};
  foreach my $orig_aa_seq_id (@{$self->{aaSeqIdArr}}) {
    $stmt->execute($orig_aa_seq_id);
    my ($subclass_view,$molecular_weight,$sequence,$length,$description,$source_id,$secondary_identifier,$name,$molecule_type,$crc32_value) = $stmt->fetchrow_array();
    my $newExtAASeq = GUS::Model::DoTS::ExternalAASequence->new ({'subclass_view'=>$subclass_view,'molecular_weight'=>$molecular_weight,'length'=>$length,'description'=>$description,'external_database_release_id'=>$dupNRDBrel,'source_id'=>$source_id,'secondary_identifier'=>$secondary_identifier,'name'=>$name,'molecule_type'=>$molecule_type,'crc32_value'=>$crc32_value});
    if (!$newExtAASeq->retrieveFromDB()) {
      if ($sequence) {
	$newExtAASeq->setSequence($sequence);
      }
      $num += $newExtAASeq ->submit();
    }
    my $dup_aa_seq_id = $newExtAASeq->getAaSequenceId();
    $self->undefPointerCache();
    $origDupIdHash{$orig_aa_seq_id}=$dup_aa_seq_id;
    $self->log("$num duplicate ExternalAASequence rows submitted\n" ) if ($num % 10000 == 0);
  }
  $self->log("$num duplicate ExternalAASequence rows submitted total\n"); 
  return \%origDupIdHash;
}

sub getNRDBEntryIds {
  my ($self) = @_;
  my @nrdbEntryIdArr;
  my $dbh = $self->getQueryHandle();
  my $sql = "select nrdb_entry_id from dots.nrdbentry";
  if ($self->getArgs->{testnumber}) {
    my $idlist = join ("," , keys %{$self->{origDupIdHash}});
    $sql .= " where aa_sequence_id in ($idlist)";
  }
  $self->log("$sql\n");
  my $stmt = $dbh->prepareAndExecute($sql);
  while (my $id = $stmt->fetchrow_array()) {
    push (@nrdbEntryIdArr,$id);
  }
  return \@nrdbEntryIdArr;
}

sub makeNRDBEntryDups {
  my ($self) = @_;
  my $num;
  my $dbh = $self->getQueryHandle();
  my $sql = "select aa_sequence_id,gid,source_id,sequence_version,external_database_release_id,description,taxon_id,is_preferred from dots.nrdbentry where nrdb_entry_id = ?";
  $self->log("$sql\n");
  my $stmt = $dbh->prepare($sql);
  foreach my $orig_nrdb_entry_id (@{$self->{nrdbEntryIdArr}}) {
    $stmt->execute($orig_nrdb_entry_id);
    my ($orig_aa_sequence_id,$gid,$source_id,$sequence_version,$orig_external_database_release_id,$description,$taxon_id,$is_preferred) = $stmt->fetchrow_array();
    my $newNRDBEntry = GUS::Model::DoTS::NRDBEntry->new({'aa_sequence_id'=> $self->{origDupIdHash}->{$orig_aa_sequence_id},'gid'=>$gid,'source_id'=>$source_id,'sequence_version'=>$sequence_version,'external_database_release_id'=>$self->{dbHash}->{$orig_external_database_release_id},'description'=>$description,'taxon_id'=>$taxon_id,'is_preferred'=>$is_preferred});
    if (!$newNRDBEntry->retrieveFromDB()) {
      $num += $newNRDBEntry ->submit();
    }
    $self->undefPointerCache();

    $self->log("$num duplicate NRDBEntry rows submitted\n" ) if ($num % 10000 == 0);
  }
  $self->log("$num duplicate NRDBEntry rows submitted total\n" );
  return;
}

1;
