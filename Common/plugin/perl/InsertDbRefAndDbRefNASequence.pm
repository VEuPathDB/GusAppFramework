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
     {o => 'pattern',
      t => 'string',
      h => 'source identifier pattern, e.g. MGI:\d+',
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

my $ctx;
$| = 1;

sub Run {

  my $M   = shift;
  $ctx = shift;

  die "Supply: --mappingfiles=s \n" unless ($ctx->{cla}->{mappingfiles});
  die "Supply: --db_rel_id \n" unless ($ctx->{cla}->{db_rel_id});
  die "Supply: --pattern \n" unless ($ctx->{cla}->{pattern}); 

  print STDERR $ctx->{'commit'} ? "COMMIT ON\n" : "COMMIT TURNED OFF\n";
  print STDERR "Testing on $ctx->{'cla'}->{'testnumber'}\n" 
                if $ctx->{'cla'}->{'testnumber'};

  my $dbh = $ctx->{self_inv}->getQueryHandle();

  my ($sourceIdHash, $mapHash) = &getSourceIdsAndMap();  

  my $dbRefHash = &insertDbRef($sourceIdHash,$dbh);  

  &getCurrentAssemblyId($dbh,$mapHash); 

  my ($sourceIdDbrefHash) = &readDBRefs($dbh); 

  &insertDBRefNASeq($sourceIdDbrefHash,$mapHash); 

  &deleteDbRef($dbRefHash,$dbh);
}

sub getSourceIdsAndMap {

    my (%sourceIdHash, %mapHash); 

    my @files = split(",", $ctx->{cla}->{mappingfiles});
    my $pattern = $ctx->{cla}->{pattern};
    my $nLinks = 0;

    foreach my $file (@files) {
	open (F,$file);
	
	while (<F>) {

	    chomp;
	    
	    if ($ctx->{cla}->{testnumber} && $nLinks >= $ctx->{cla}->{testnumber}) {
		print STDERR "testing on $nLinks samples\n";
		last;
	    }
	    
	    if (/^DT.(\d+)\s+($pattern)$/) {
		my $dotsId = $1;
		my $Id = $2;
		$sourceIdHash{$Id} = 1;
		push (@{$mapHash{$Id}},$dotsId);
		++$nLinks;
	    }
	
	    else {
		die "Unable to parse $_";
	    }
	}
    }

    print STDERR ("$nLinks DoTS ids are mapped to the source's ids\n");

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
