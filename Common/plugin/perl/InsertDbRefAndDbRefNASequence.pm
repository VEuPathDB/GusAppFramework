package GUS::Common::Plugin::InsertDbRefAndDbRefNASequence;

@ISA = qw(GUS::PluginMgr::Plugin);
 
use strict;

use GUS::Model::SRes::DbRef;
use GUS::Model::DoTS::DbRefNASequence;

sub new {
  my $class = shift;

  my $self = {};
  bless($self,$class);

  my $usage = 'Maps assemblies to other entities by inserting rows into DbRef and
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
     }
    ];

  $self->initialize({requiredDbVersion => {},
		  cvsRevision => '$Revision$', # cvs fills this in!
		  cvsTag => '$Name$', # cvs fills this in!
		  name => ref($m),
		  revisionNotes => 'make consistent with GUS 3.0',
		  easyCspOptions => $easycsp,
		  usage => $usage
		 });

  return $self;
}


$| = 1;

sub Run {

  my $self   = shift;

  die "Supply: --mappingfiles=s \n" unless ($self->getArgs()->{mappingfiles});
  die "Supply: --db_rel_id \n" unless ($self->getArgs()->{db_rel_id});
  die "Supply: --pattern1 \n" unless ($self->getArgs()->{pattern1});
  die "Supply: --pattern2 \n" unless ($self->getArgs()->{pattern2});
  die "Supply: --db_id \n" unless ($self->getArgs()->{db_id});

  print STDERR $self->getArgs()->{'commit'} ? "COMMIT ON\n" : "COMMIT TURNED OFF\n";
  print STDERR "Testing on ". $self->getArgs()->{'testnumber'}."\n" 
                if $self->getArgs()->{'testnumber'};

  my $dbh = $self->getQueryHandle();

  my ($sourceIdHash, $mapHash) = $self->getSourceIdsAndMap();  

  my $dbRefHash = $self->insertDbRef($sourceIdHash,$dbh);  

  $self->getCurrentAssemblyId($dbh,$mapHash); 

  my ($sourceIdDbrefHash) = $self->readDBRefs($dbh); 

  $self->insertDBRefNASeq($sourceIdDbrefHash,$mapHash); 

  $self->deleteDbRef($dbRefHash,$dbh);
}

sub getSourceIdsAndMap {

  my ($self) = @_;
  
  my (%sourceIdHash, %mapHash); 
  
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
      
      if (/pattern1/) {
	my $MappedFrom = $1;
	if (/pattern2/) {
	  my $MappedTo = $1;
	  $sourceIdHash{$MappedFrom} = 1;
	  push (@{$mapHash{$MappedFrom}},$MappedTo);
	  ++$nLinks;
	}
      }
      
      else {
	die "Unable to parse $_";
      }
    }
  }
  
  print STDERR ("$nLinks ids are mapped to the source's ids\n");

  foreach my $id (keys %sourceIdHash) {
    print "$id\n";
  }
  exit;
  return (\%sourceIdHash, \%mapHash);
}

sub insertDbRef {

    my ($sourceIdHash, $dbh) = @_;

    my %dbRefHash;

    my $db_rel_id = $ctx->{cla}->{db_rel_id};

    my $db_id = $ctx->{cla}->{db_id};

    my $sql = 'select external_database_release_id from sres.externaldatabaserelease 
               where external_database_id = $db_id'; 

    my $stmt = $dbh->prepareAndExecute($sql);

    my @relArray;

    while (my $old_rel_id = $stmt->fetchrow_array()) {
	push (@relArray, $old_rel_id);
    } 

    my $num =0;

    foreach my $id (keys %$sourceIdHash) {
	my $lowercase_primary_id = lc ($id);
	foreach my $old_rel_id (@relArray) {
	    my $newDbRef = GUS::Model::SRes::DbRef -> new ({'lowercase_primary_identifier'=>$lowercase_primary_id, 'external_database_release_id'=>$old_rel_id});
	    $newDbRef->retrieveFromDB();

	    if ($newDbRef->getPrimaryId() ne $id) {
		$newDbRef->setPrimaryId($id);
	    }
	    if ($newDbRef->getExternalDatabaseReleaseId != $db_rel_id) {
		$newDbRef->setExternalDatabaseReleaseId($db_rel_id);
	    }	
    
	    $num += $newDbRef->submit();

	    my $dbRefId = $newDbRef->getDbRefId();
	    
	    $dbRefHash{$dbRefId} = 1;
	 
	    $newDbRef->undefPointerCache();
	}
    }

    print STDERR ("$num ids inserted into DbRef table\n");

    return \%dbRefHash;
}

sub getCurrentAssemblyId {

    my($dbh, $mapHash) = @_;
    my $st = $dbh->prepare("select count(*) from dots.nasequenceimp where na_sequence_id = ?");
    my $num = 0;

    foreach my $sourceId (keys %$mapHash) {
	my $length = scalar(@{$mapHash->{$sourceId}});

	for (my $i = 0; $i < $length; $i++) {
	    my $assemblyId = $mapHash->{$sourceId}->[$i]; 

	    $st->execute($assemblyId);
	    my($count) = $st->fetchrow_array();
	    $st->finish();
	    
	    if ($count > 0) {
		next;
	    }
	    else {	    
		$st = $dbh->prepare("select new_id from dots.MergeSplit where old_id = ? and table_id = 56");
		$st->execute($assemblyId);
		my ($newId) = $st->fetchrow_array();
		$st->finish();
		$num++;
		print STDERR "Mapped old ID $assemblyId -> $newId\n";
		$mapHash->{$sourceId}->[$i] = $newId;
	    }
	}
    }

    print STDERR "Mapped $num old IDs to newIds\n";
}

sub readDBRefs {

    my($dbh) = @_;

    my %sourceIdDbrefHash;

    my $db_rel_id = $ctx->{cla}->{db_rel_id};

    my $sql = "select primary_identifier,db_ref_id from sres.dbref where external_database_release_id=$db_rel_id";

    my $st = $dbh->prepare($sql);

    $st->execute();
    while (my @a = $st->fetchrow_array()) {
	my $lowercase_source_id = lc ($a[0]);
	$sourceIdDbrefHash{$lowercase_source_id} = $a[1];
    }
    $st->finish();
    
    return \%sourceIdDbrefHash;
}

sub  insertDBRefNASeq {

    my ($sourceIdDbrefHash,$mapHash) = @_;

    my $num = 0;

    foreach my $Id (keys %$mapHash) {
	foreach my $assemblyId (@{$mapHash->{$Id}}) {
	    my $lowercase_Id = lc ($Id);
	    my $db_ref_id = $sourceIdDbrefHash->{$lowercase_Id};
	    
	    my $newDbRefNASeq = GUS::Model::DoTS::DbRefNASequence->new ({'db_ref_id'=>$db_ref_id, 'na_sequence_id'=>$assemblyId});
	    
	    $num += $newDbRefNASeq->submit() 
                       unless $newDbRefNASeq->retrieveFromDB();
	    
	    $newDbRefNASeq->undefPointerCache();
	}
    }
    print STDERR ("$num ids inserted into DbRefNASequence table\n");
}

sub deleteDbRef {

    my ($dbRefHash,$dbh) = @_;
    my $sql = 'select db_ref_id from sres.dbref';
    my $num;
    my $stmt = $dbh->prepareAndExecute($sql);
    while (my $db_ref_id  = $stmt->fetchrow_array()) {
	if ($dbRefHash->{$db_ref_id} != 1) {
	    my $newDbRef = SRes::DbRef -> new({'db_ref_id'=>$db_ref_id});
	    $newDbRef->retrieveFromDB();
	    $newDbRef->retrieveAllChildrenFromDB(1);
	    $newDbRef->markDeleted(1);
	    $newDbRef->submit();
	    $newDbRef->undefPointerCache();
	    $num++;
	}
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
