############################################################
##plugin that inserts entries into DbRef and DbRefNASequence
##mapping assemblies to other ids (eg MGI or Genecards)
##
##10/09/02 Deborah Pinney 
##
##Currently works for MGI<->DoTS, should be revised for GeneCards.
##Can't anticipate the form of other mappings, generalize if possible
##
##algorithm_id = 9095
##algorithm_imp_id = 10927
############################################################
package InsertDbRefAndDbRefNASequence;

use strict;

use Objects::GUSdev::DbRef;
use Objects::GUSdev::DbRefNASequence;


sub new {
  my $Class = shift;

  return bless {}, $Class;
}

sub Usage {
  my $M   = shift;
  return 'Maps assemblies to other entities by inserting rows into DbRef and
          DbRefNASequence\n';
}


sub EasyCspOptions {
    my $M   = shift;
    {
	
	
	testnumber   => {
	             o => 'testnumber=i',
                     h => 'number of iterations for testing',
                     },
	mappingfiles => {
                     o => 'mappingfiles=s',
                     h => 'mapping files of DoTS assemblies to ids from 
                           external source, file names delimited by commas',
                     },
	db_id        => {
                     o => 'db_id=i',
                     h => 'external_database_id for external source of ids',
                     },
	pattern      => {
                     o => 'pattern=s',
                     h => 'source identifier pattern, e.g. MGI:\d+',
                     },
    };
}

my $ctx;
$| = 1;

sub Run {

  my $M   = shift;
  $ctx = shift;

  die "Supply: --mappingfiles=s \n" unless ($ctx->{cla}->{mappingfiles});
  die "Supply: --db_id \n" unless ($ctx->{cla}->{db_id});
  die "Supply: --pattern \n" unless ($ctx->{cla}->{pattern}); 

  print STDERR $ctx->{'commit'} ? "COMMIT ON\n" : "COMMIT TURNED OFF\n";
  print STDERR "Testing on $ctx->{'cla'}->{'testnumber'}\n" 
                if $ctx->{'cla'}->{'testnumber'};

  my $dbh = $ctx->{self_inv}->getDbHandle();

  my ($sourceIdHash, $mapHash) = &getSourceIdsAndMap();  

  &insertDbRef($sourceIdHash);  

  &getCurrentAssemblyId($dbh,$mapHash); 

  my ($sourceIdDbrefHash) = &readDBRefs($dbh); 

  &insertDBRefNASeq($sourceIdDbrefHash,$mapHash); 
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

    my ($sourceIdHash) = @_;

    my $db_id = $ctx->{cla}->{db_id};

    my $num =0;

    foreach my $id (keys %$sourceIdHash) {
	my $lowercase_primary_id = lc ($id);
	my $newDbRef = DbRef -> new ({'lowercase_primary_identifier'=>$lowercase_primary_id, 
                                     'external_db_id'=>$db_id});

	if (!$newDbRef->retrieveFromDB()) {
	    $newDbRef->setPrimaryId($id);
	    $num += $newDbRef->submit();
	}

	$newDbRef->undefPointerCache();
    }

    print STDERR ("$num ids inserted into DbRef table\n");
}

sub getCurrentAssemblyId {

    my($dbh, $mapHash) = @_;
    my $st = $dbh->prepare("select count(*) from nasequenceimp where na_sequence_id = ?");
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
		$st = $dbh->prepare("select new_id from MergeSplit where old_id = ? and table_id = 56");
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

    my $db_id = $ctx->{cla}->{db_id};

    my $sql = "select primary_identifier,db_ref_id from dbref where external_db_id=$db_id";

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
	    
	    my $newDbRefNASeq = DbRefNASequence->new ({'db_ref_id'=>$db_ref_id, 'na_sequence_id'=>$assemblyId});
	    
	    $num += $newDbRefNASeq->submit() 
                       unless $newDbRefNASeq->retrieveFromDB();
	    
	    $newDbRefNASeq->undefPointerCache();
	}
    }
    print STDERR ("$num ids inserted into DbRefNASequence table\n");
}

    
