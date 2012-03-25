package GUS::Community::Plugin::InsertDbRefAndDbRefNaSequenceGeneral;

@ISA = qw(GUS::PluginMgr::Plugin);
 
use strict;

use GUS::Model::SRes::DbRef;
use GUS::Model::DoTS::DbRefNASequence;

sub new {
  my $class = shift;

  my $self = {};
  bless($self,$class);

  my $usage = 'Maps na_sequence_ids to other entities by inserting rows into DbRef and
          DbRefNASequence';

  my $easycsp =
    [{o => 'testnumber',
      t => 'int',
      h => 'number of iterations for testing',
     },
     {o => 'mappingfiles',
      t => 'string', 
      h => 'mapping files of DoTS assemblies to ids from 
            external source, file names delimited by commas',
     },
     {o => 'db_rel_id',
      t => 'int',
      h => 'external_database_release_id for external source of ids',
     },
     {o => 'db_id',
      t => 'int',
      h => 'external_database_id for external source of ids',
     },
     {o => 'pattern1',
      t => 'string',
      h => 'source identifier pattern with parenthesis around the id to be stored, e.g. ^(MGI:\d+)',
     },
     {o => 'pattern2',
      t => 'string',
      h => 'identifier pattern for the na_sequence_id stored in the DbRefNASequence table, with parenthesis, e.g. \s+DT.(\d+)',
     },
     {o => 'delete',
      t => 'boolean',
      h => 'option to delete entries in dbref that are not in the current mapping',
     }
    ];

  $self->initialize({requiredDbVersion => {},
		  cvsRevision => '$Revision$', # cvs fills this in!
		  cvsTag => '$Name$', # cvs fills this in!
		  name => ref($self),
		  revisionNotes => 'make consistent with GUS 3.0',
		  easyCspOptions => $easycsp,
		  usage => $usage
		 });

  return $self;
}


$| = 1;

sub run {

  my $self   = shift;

  die "Supply: --mappingfiles=s \n" unless ($self->getArgs()->{mappingfiles});
  die "Supply: --db_rel_id \n" unless ($self->getArgs()->{db_rel_id});
  die "Supply: --pattern1 \n" unless ($self->getArgs()->{pattern1});
  die "Supply: --pattern2 \n" unless ($self->getArgs()->{pattern2});
  die "Supply: --db_id \n" unless ($self->getArgs()->{db_id});

  print STDERR $self->getArgs()->{'commit'} ? "COMMIT ON\n" : "COMMIT TURNED OFF\n";
  print STDERR "Testing on ". $self->getArgs()->{'testnumber'}."\n" 
                if $self->getArgs()->{'testnumber'};

  my ($mapHash) = $self->getMapHash();

  my ($dbRefHash) = $self->insertDbRef($mapHash); 

  $self->insertDBRefNASeq($dbRefHash);

  $self->deleteDbRef() if $self->getArgs()->{'delete'};
}

sub getMapHash {

  my ($self) = @_;
  
  my %mapHash; 

  my @files = split(",", $self->getArgs()->{mappingfiles});
  my $pattern1 = $self->getArgs()->{pattern1};
  my $pattern2 = $self->getArgs()->{pattern2};
  my $nLinks = 0;

  foreach my $file (@files) {
    open (F,$file);
    while (<F>) {
      chomp;

      if ($self->getArgs()->{testnumber} && $nLinks >= $self->getArgs()->{testnumber}) {
	print STDERR "testing on $nLinks samples\n";
	last;
      }

      if (/$pattern1/) {
	my $MappedFrom = $1;
	if (/$pattern2/) {
	  my $MappedTo = $1;
	  $mapHash{$MappedFrom} = $MappedTo;
	  ++$nLinks;
	}
      }
      
      else {
	die "Unable to parse $_";
      }
    }
  }

  print STDERR ("$nLinks ids are mapped to the source's ids\n");

  return (\%mapHash);
}

sub insertDbRef {

  my ($self,$mapHash) = @_;

  my $db_rel_id = $self->getArgs()->{db_rel_id};

  print "$db_rel_id   db_rel_id\n";

  my $db_id = $self->getArgs()->{db_id};

  my %dbRefHash;

  my $num =0;

  foreach my $id (keys %$mapHash) {
    my $lowercase_primary_id = lc ($id);
    my $newDbRef = GUS::Model::SRes::DbRef -> new ({'lowercase_primary_identifier'=>$lowercase_primary_id, 'external_database_release_id'=>$db_rel_id});
    $newDbRef->retrieveFromDB();

    if ($newDbRef->getPrimaryIdentifier() ne $id) {
      $newDbRef->setPrimaryIdentifier($id);
    }
    if ($newDbRef->getExternalDatabaseReleaseId != $db_rel_id) {
      $newDbRef->setExternalDatabaseReleaseId($db_rel_id);
    }

    $num += $newDbRef->submit();

    my $dbRefId = $newDbRef->getDbRefId();

    $dbRefHash{$dbRefId} = $mapHash->{$id};

    $newDbRef->undefPointerCache();
  }

  print STDERR ("$num ids inserted into DbRef table\n");

  return \%dbRefHash;
}



sub  insertDBRefNASeq {
  my ($self,$dbRefHash) = @_;

  my $num = 0;

  foreach my $dbRefId (keys %$dbRefHash) {

    my $naSeqId = $dbRefHash->{$dbRefId};

    my $newDbRefNASeq = GUS::Model::DoTS::DbRefNASequence->new ({'db_ref_id'=>$dbRefId, 'na_sequence_id'=>$naSeqId});

    $num += $newDbRefNASeq->submit() unless $newDbRefNASeq->retrieveFromDB();

    $newDbRefNASeq->undefPointerCache();
  }

  print STDERR ("$num ids inserted into DbRefNASequence table\n");
}

sub deleteDbRef {
  my ($self) = @_;

  my $dbh = $self->getDb()->getDbHandle();
  my $db_rel_id = $self->getArgs()->{db_rel_id};
  my $sql = "select db_ref_id from sres.dbref where external_database_release_id = $db_rel_id and db_ref_id not in (select db_ref_id from dots.dbrefnasequence)";
  my $num = 0;
  my $stmt = $dbh->prepareAndExecute($sql);
  while (my $db_ref_id  = $stmt->fetchrow_array()) {
    my $newDbRef = GUS::Model::SRes::DbRef -> new({'db_ref_id'=>$db_ref_id});
    $newDbRef->retrieveFromDB();
    $newDbRef->retrieveAllChildrenFromDB(1);
    $newDbRef->markDeleted(1);
    $newDbRef->submit();
    $newDbRef->undefPointerCache();
    $num++;
  }
  print STDERR "$num DbRef entries and its children were deleted\n";
}

1;

__END__

=pod
=head1 Description
B<InsertDbRefAndDbRefNASequence>  plug-in to ga that adds and updates entries to SRes.DbRef and to the linking table DoTS.DbRefNASequence.

=head1 Purpose
B<InsertDbRefAndDbRefNASequence> adds and updates entries to SRes.DbRef and to the linking table DoTS.DbRefNASequence.

=cut
