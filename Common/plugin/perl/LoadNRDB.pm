########################################################################
##LoadNRDB.pm 
##
##This is a ga plug_in to populate the NRDBEntry and ExternalAASequence tables
##with entries from the nr files of non-redundant protein sequences.
##Can be run in three separate parts. Caution:the delete portion can be run at a 
##separate time but must be run after the first two portions.
##
##NRDB external_db_id = 4194
##
##Created Oct. 16, 2001
##Revised Oct. 28, 2002
##
##nrdb file:ftp://ncbi.nlm.nih.gov/blast/db/nr.Z 
##gi/tax_id file:ftp://ncbi.nlm.nih.gov/pub/taxonomy/gi_taxid_prot.dmp
##The nr file file should remain compressed for the plugin as written 
##Deborah Pinney 
##
##algorithm_id=5389       
##algorithm_imp_id=6624      
########################################################################
package LoadNRDB;
use FileHandle;
use strict;
use GUS::Model::::NRDBEntry;
use GUS::Model::::ExternalAASequence;
use DBI;

my $Cfg;
my $ctx;
my $count=0;
my $debug = 0;
$| = 1;

sub new {
	my $Class = shift;
	$Cfg = shift;
	return bless {}, $Class;
}
sub Usage {
	my $M   = shift;
	return 'Plug_in to populate the NRDBEntry table';
}
sub CBIL::Util::EasyCspOptions {
	my $M   = shift;
	{
  
  testnumber1  => {
                  o => 'testnumber1=i',
		  h => 'number of iterations for testing temp table insertion',
		 },
  testnumber2  => {
                  o => 'testnumber2=i',
		  h => 'number of iterations for testing insertion 
                        into NRDBEntry and ExternalAASequence',
		 },
  gitax       => {
                  o => 'gitax=s',
		  h => 'location of the gi_taxid_prot.dmp file',
                  d => '/usr/local/db/local/taxonomy/gi_taxid_prot.dmp',
                 },
  nrdb       =>  {
                  o => 'nrdb=s',
		  h => 'location of the nrdb file',
                  d => '/usr/local/db/local/nrdb/nr.Z',
                },
  maketemp  =>  {
                  o => 'maketemp!',
		  h => 'option to create temp table',
                }, 
  temp_login   => {
                  o => 'temp_login=s',
		  h => 'login for space being used for temp table eg.pinney',
                },
  temp_password   => {
                  o => 'temp_password=s',
		  h => 'password for space being used for temp table',
                },
  plugin     => {
                  o => 'plugin',
                  t => 'boolean',
		  h => 'choice of whether to run the remainder of the plug_in',
                },
  restart    => {
                  o => 'restart=i',
		  h => 'for restarting the interrupted plugin(use with plugin 
                        option), use number from last set number in log',
                },
  delete     => {
                o => 'delete!',
		h => 'option to run delete portion',
	        }
  restart_temp_table => {
                o => 'restart_temp_table!',
                h => 'indicates temp table insertion should be restarted,
                      table already exits';
  };
}

sub Run {
  my $M  = shift;
  $ctx = shift;
  print STDERR $ctx->{'commit'}?"***COMMIT ON***\n":"**COMMIT TURNED OFF**\n";
  print STDERR "Testing on $ctx->{'cla'}->{'testnumber1'} insertions 
                into temp table\n" 
                if $ctx->{'cla'}->{'testnumber1'};
  print STDERR "Testing on $ctx->{'cla'}->{'testnumber2'} insertions
                into NRDBEntry/ExternalAASequence\n" 
                if $ctx->{'cla'}->{'testnumber2'};

  my $dbHash = &getDB();

  my $taxonHash = &getTaxon ();

  my $tempresults = &makeTempTable($dbHash, $taxonHash) 
                    if ($ctx->{'cla'}->{'maketemp'});

  if (!$ctx->{'cla'}->{'plugin'} && !$ctx->{'cla'}->{'delete'}) {
      print STDERR ("NRDBTemp has been filled and the program is exiting\n");
      return $tempresults;
  }

  my $entryresults = &makeNRDBAndExternalAASequence($taxonHash, $dbHash) 
                    if ($ctx->{'cla'}->{'plugin'}); {      
     
  if (!$ctx->{'cla'}->{'delete'}){ 
      if ($tempresults) {
	  my $entryresults .= $tempresults;
      }
      return $entryresults;   
  }

  my $nrdbdelete = &deleteFromNRDB;
  my $aadelete = &deleteFromExtAASeq;
  my $results = "Processing completed:";
  $results = $results . $tempresults . $entryresults . $nrdbdelete . $aadelete; 
  print STDERR ("$results\n");
  return $results;
}

sub getDB {
  my %dbHash = ( 'prf' => 6,
                 'dbj' => 4,
                 'gnl' => 11,
                 'gb'  => 22,
                 'pir' => 5,
                 'sp'  => 7,
                 'emb' => 3,
                 'ref' => 168,
                 'pdb' => 8,
                 'genpept'=> 12);
  return \%dbHash;
}


#################################
##taxonHash{gi}=taxon_id
##taxHash{ncbi_tax_id}=taxon_id
#################################
sub getTaxon {
    
    my $dbh = $ctx->{'self_inv'}->getQueryHandle();
    open (TAXFILE, "$ctx->{'cla'}->{'gitax'} ") || 
                    die ("Can't open the gi/tax_id file\n");
    my %taxHash;
    my %taxonHash;
    my $st = $dbh->prepare("select taxon_id from taxon3 where ncbi_tax_id = ?");
    while (<TAXFILE>) {
	chomp;
	if (/(\d+)\s+(\d+)/) {
	    if (!$taxHash{$2}){
		$st->execute($2);
		($taxHash{$2}) = $st->fetchrow_array;
		$st->finish();
	    }
	    $taxonHash{$1} = $taxHash{$2};
	}
    }
    close (TAXFILE);
    my $length = scalar (keys %taxonHash);
    print STDERR ("There are $length gi to taxon_id pairs\n");

    $dbh->disconnect();
    return \%taxonHash;;
}

sub makeTempTable {
    my ($dbHash, $taxonHash) = @_;

    my $login = $ctx->{'cla'}->{'temp_login'} || die "must provide temp_login 
                and temp_password for temp table\n";
    my $password = $ctx->{'cla'}->{'temp_password'} || 
                   die "must provide temp_login 
                   and temp_password for temp table\n";
    my $DBI_STR = 'dbi:Oracle:host=erebus.pcbi.upenn.edu;sid=gusdev';
    my $dbh = DBI->connect($DBI_STR, $login, $password);

    if (!$ctx->{'cla'}->{'restart_temp_table'}) { 
	$dbh->do("create table NRDBTemp 
                 (SOURCE_ID	NOT NULL VARCHAR2(32),
                  EXTERNAL_DB_ID 	NOT NULL NUMBER(5),
                  SEQUENCE_VERSION		 VARCHAR2(10),
                  SET_NUM		NOT NULL NUMBER(10)
                  )");
    }
    my $st1 = $dbh->prepareAndExecute("select max(set_num) from NRDBTemp");
    my $max_num= $st1->fetchrow_array ? $st1->fetchrow_array : 0;
    my $set_num = 0;
    $st1->finish();

    my $st2 = $dbh->prepare("INSERT into NRDBTemp 
              (source_id,external_db_id,set_num,sequence_version) values (?,?,?,?)");
    my $nrdb = $ctx->{'cla'}->{'nrdb'};

    if ($nrdb =~ /\.Z/) {
	open (NRDB,"uncompress -c $nrdb |") || 
        die ("Can not open the nr file\n");
    }
    elsif ($nrdb =~ /\.gz/) {
	open (NRDB,"gunzip -c $nrdb |") || 
        die ("Can not open the nr file\n");
    }
    else {
	open (NRDB,"$nrdb") || 
        die ("Can not open the nr file\n");
    }
    while (<NRDB>) {
	chomp;
	if (/^\>/) {
	    if ($max_num && $set_num <= $max_num) { 
		next;
	    }
	    if ($ctx->{'cla'}->{'testnumber1'} && $set_num > 
                ($ctx->{'cla'}->{'testnumber1'})) {
		print STDERR ("The testnumber, $set_num, of temp table entries
                                have been processed\n");
		last;
	    }
	    my $line = $_;
	    my @arr = split (/\cA/, $line);
	    #$EntryHash{gid}->{source_id}=[external_db_id,description,taxon_id]
	    my %EntryHash;
	    &parseLine(\@arr, $dbHash, $taxonHash, \%EntryHash); 
	    foreach my $gid (keys %EntryHash) {
		foreach my $source_id (keys %{$EntryHash{$gid}}) {
		    my $sequence_version;
		    my $external_db_id = $EntryHash{$gid}{$source_id}[0];
		    #extension for 8 is not a version number,rather, part of its source_id
		    if ($source_id =~ /(\S*?)\.(\S*)/ && $external_db_id != 8){ 
			$source_id = $1;
			$sequence_version = $2;
		    }
		    $st2->execute($source_id,$external_db_id,
                                  $set_num,$sequence_version);
		    $set_num++;
		}
	    }
	    if ($set_num%1000 == 0) {
		$dbh->commit();
		print STDERR ("$set_num sets have been processed 
                               and put in the nrdbtemp table\n");
		$dbh->commit();
	    }
	}
    }
    $dbh->commit();
    $tempresults = "$set_num total entries have been made 
                    into the NRDBTemp table";
    print STDERR ("$tempresults\n");
    close NRDB;
    $dbh->disconnect();
    return $tempresults;
}

sub makeNRDBAndExternalAASequence {
    my ($taxonHash, $dbHash) = @_;

    my $count = 0;
    
    my $temp_login = $ctx->{'cla'}->{'temp_login'} || 
                     die "--temp_login required to 
                     load NRDBEntry and ExternalAASequence\n";

    my $dbh = $ctx->{'self_inv'}->getQueryHandle();
    my $st = $dbh->prepareAndExecute("select max(set_num) from $temp_login".".nrdbtemp");
    my ($max_set_num) = $st->fetchrow_array;
    $st->finish();

    print STDERR ("$max_set_num entries in temp table\n");
    
    if ($nrdb =~ /\.Z/) {
	open (NRDB,"uncompress -c $nrdb |") || 
        die ("Can not open the nr file\n");
    }
    elsif ($nrdb =~ /\.gz/) {
	open (NRDB,"gunzip -c $nrdb |") || 
        die ("Can not open the nr file\n");
    }
    else {
	open (NRDB,"$nrdb") || 
        die ("Can not open the nr file\n");
    }

    my %EntryHash; 
    my $seq;
    my $num_submit;
    if ($ctx->{'cla'}->{'restart'}) {
	$num_submit = $ctx->{'cla'}->{'restart'};
    }
    else {
	$num_submit = 0;
    }  
    my $st = $dbh->prepare("select aa_sequence_id from nrdbentry where source_id = ? and external_db_id = ?");

    while (<NRDB>) {
	chomp;
	# /^\>/ pattern indicating the beginning of the defline, if $seq exists, process the set 
	if (/^\>/) { 
	    if ($ctx->{'cla'}->{'testnumber2'} && $count > ($ctx->{'cla'}->{'testnumber2'})) {
		print STDERR ("The testnumber, $count, 
                              of entries has been processed\n");
		last;
	    }
	    if ($seq) {
		$count++;
		#get the preferred gi and source_id and get any one aa_sequence_id corresponding to a member of the set
		unless ($ctx->{'cla'}->{'restart'} && $count <= $ctx->{'cla'}->{'restart'}) {
		    if (scalar (keys %EntryHash) != 0) {
			my $newExtAASeq = &processHash(\%EntryHash,$seq,$st);
			$newExtAASeq->submit();
			$num_submit++;
			print STDERR ("Submitted set number:$num_submit\n");
			$newExtAASeq->undefPointerCache();
		    }
		}
		$seq = "";
		foreach my $ky (keys %EntryHash) {
		    delete $EntryHash{$ky};
		}
	    }
	    my $line = $_;
	    my @arr = split (/\cA/, $line);
	    &parseLine(\@arr, $dbHash, $taxonHash, \%EntryHash);
	    if (scalar (keys %EntryHash) == 0){
		next;
	    }
	}
	else {
	    $seq .= $_;
	}
    }
    my $newExtAASeq = &processHash(\%EntryHash,$seq,$st);
    $newExtAASeq->submit();
    $num_submit++;
    my $entryresult = ("Number of entries to NRDB/ExternalAASequence : 
                        $num_submit\n");
    print STDERR ("$entryresult");
    $newExtAASeq->undefPointerCache();
    return $entryresult;
}

sub parseLine {
    my ($arr, $dbHash, $taxonHash, $EntryHash) = @_;
    foreach my $line ( @$arr){
	if ($line =~ /gi\|(\d*)\|(\w*)\|(\S*?)\|\S*\s*(.*)/){
	    my $secondary_id = $1; 
	    my $external_db_id = $2;
	    if ($external_db_id eq 'tpg') {
		next;
	    }
	    my $source_id = $3;
	    
	    my $description = $4;
	    $description =~ s/\"//g;
	    $description =~ s/\gi\|.*//;
	    if (($external_db_id eq 'gnl') ||
		($external_db_id eq 'pir') ||
          ($external_db_id eq 'prf')){
		if ($line =~ /gi\|\d*\|\w*\|\w*\|(\S*)/){
		    $source_id = $1;
		}
		else{
		    print STDERR "ERROR: Unable to parse source id 
                                  for gnl, pir, or prf.\n";
		}
	    }
	    elsif ($external_db_id eq 'pdb'){
		if ($line =~ /gi\|\d*\|\w*\|\w*\|(\S*)/){
		    $source_id = $source_id . "." . "$1" if $1;
		}
		else{
		    print STDERR "ERROR: Unable to parse source id for pdb.\n";
		}
	    }
	    elsif (!$source_id){
		$source_id = $secondary_id;
		$external_db_id = 'genpept';
	    }
	    my $db_id = $dbHash->{$external_db_id};
	    
	    my $taxon_id = $taxonHash->{$secondary_id};
	    $EntryHash->{$secondary_id}->{$source_id} = [$db_id,$description,$taxon_id];
	}
    }
    return;
}

sub processHash {
    my ($EntryHash,$seq,$st) = @_;
    my $newExtAASeq;
    my $pref_gi;
    my $pref_source;
    my $sp_gi;
    my $sp_source;
    my $pir_gi;
    my $pir_source;
    my $default_gi;
    my $default_source;

    my $max_length = 0;
    foreach my $gid (keys %$EntryHash){
	foreach my $source_id (keys %{$$EntryHash{$gid}}){
	    my $db_id = $$EntryHash{$gid}->{$source_id}[0];
	    
	    my $description = $$EntryHash{$gid}->{$source_id}[1];
	    if ($db_id==7) {
		$sp_gi=$gid;
		$sp_source=$source_id;
	    }
	    if ($db_id==5) {
		$pir_gi=$gid;
		$pir_source=$source_id;
	    }
	    if (length($description) > $max_length) {
		$default_gi=$gid;
		$default_source=$source_id;
	    }
	    if (!$newExtAASeq) {
		my $source;
		if ($source_id =~ /(\S*?)\.(\S*)/ && $db_id != 8) { 
		    $source = $1;
		}
		else{
		    $source=$source_id;
		}
		$st->execute($source,$db_id);
		if (my ($aa_seq_id) = $st->fetchrow_array) {
		    $st->finish;
		    my $preExtAASeq = ExternalAASequence->new ({'aa_sequence_id'=>$aa_seq_id});
		    $preExtAASeq->retrieveFromDB();
		    if ($seq eq $preExtAASeq->getSequence()) {
			$newExtAASeq = $preExtAASeq;
		    }
		}
	    }
	}
    }
    $pref_gi = ($sp_gi?$sp_gi:($pir_gi?$pir_gi:$default_gi));
    $pref_source = ($sp_source?$sp_source:($pir_source?$pir_source:$default_source));
    
    if ($newExtAASeq) {
	&updateExtAASeq($newExtAASeq,$pref_gi,$pref_source,$$EntryHash{$pref_gi}->{$pref_source}[1]);
    }
    else {
	$newExtAASeq = &makeExtAASeq($seq,$pref_gi,$pref_source,$$EntryHash{$pref_gi}->{$pref_source}[1]);
    }
    &makeNRDBEntries($newExtAASeq,$pref_gi,$pref_source,$EntryHash);
    return $newExtAASeq;  
}

sub updateExtAASeq {
    my ($newExtAASeq,$secondary_identifier,$source_id,$description) = @_;
    my $external_db_id = 4194; 
    my $shortDescr = substr($description, 0, 255);
    if ($secondary_identifier!=$newExtAASeq->get('secondary_identifier')){
	$newExtAASeq->set('secondary_identifier',$secondary_identifier);
    }
    if ($source_id!=$newExtAASeq->get('source_id')){
	$newExtAASeq->set('source_id',$source_id);
    }
    if ($shortDescr!=$newExtAASeq->get('description')){
	$newExtAASeq->set('description',$shortDescr);
    }
    if ($external_db_id!=$newExtAASeq->get('external_db_id')){
	$newExtAASeq->set('external_db_id'=>$external_db_id);
    }
}

sub makeExtAASeq {
  my ($seq,$secondary_identifier,$source_id,$description) = @_;
  my $external_db_id = 4194; 
  my $shortDescr = substr($description, 0, 255);
  my $newExtAASeq = ExternalAASequence->new({'external_db_id' => $external_db_id,'source_id'=> $source_id,'secondary_identifier' => $secondary_identifier, 'description' => $shortDescr});
  $newExtAASeq->retrieveFromDB();
  if($seq){
      $newExtAASeq->set('sequence', $seq);
  }
  return $newExtAASeq;
}

sub makeNRDBEntries {
    my ($newExtAASeq,$pref_gi,$pref_source,$EntryHash) = @_;
    foreach my $secondary_id (keys %$EntryHash) {
	foreach my $source_id (keys %{$$EntryHash{$secondary_id}}) {
	    my $external_db_id = $$EntryHash{$secondary_id}->{$source_id}[0];
	    my $description = $$EntryHash{$secondary_id}->{$source_id}[1];
	    my $shortDescr = substr($description, 0, 255);
	    my $taxon_id = $$EntryHash{$secondary_id}->{$source_id}[2];
	    my $sequence_version;
	    my $is_preferred;
	    if ($pref_gi==$secondary_id && $pref_source eq $source_id) {
		$is_preferred=1;
	    }
	    else {
		$is_preferred=0;
	    }
	    
	    if ($source_id =~ /(\S*?)\.(\S*)/ && $external_db_id != 8) {
		$source_id = $1;
		$sequence_version = $2;
	    }
	    my $newNRDBEntry = NRDBEntry->new({'source_id'=>$source_id, 'external_db_id'=>$external_db_id});
	    $newNRDBEntry->retrieveFromDB(); 
	    if ($secondary_id!=$newNRDBEntry->get('gid')){
		$newNRDBEntry->set('gid',$secondary_id);
	    }
	    if ($shortDescr ne $newNRDBEntry->get('description')){
		$newNRDBEntry->set('description',$shortDescr);	  
	    }
	    if (!defined $newNRDBEntry->get('is_preferred') || $is_preferred != $newNRDBEntry->get('is_preferred')){
		$newNRDBEntry->set('is_preferred',$is_preferred);	  
	    }  
	    if ($taxon_id && $taxon_id!=$newNRDBEntry->get('taxon_id')) {
		$newNRDBEntry->set('taxon_id',$taxon_id);
	    }
	    if ($sequence_version && $sequence_version != $newNRDBEntry->get('sequence_version')) {
		$newNRDBEntry->set('sequence_version',$sequence_version);
	    }
	    my $s = $newNRDBEntry-> get('source_id');
	    my $p = $newNRDBEntry-> get('is_preferred');
	    $newNRDBEntry->setParent($newExtAASeq);
	}
    }
}

sub deleteFromNRDB {
    my $num_delete = 0;
    my $st = $dbh->prepareAndExecute("select nrdb_entry_id from nrdbentry where source_id not in (select /** RULE */ n.source_id from nrdbentry n, pinney.nrdbtemp p where n.source_id = p.source_id and n.external_db_id = p.external_db_id)");
    while (my ($nrdb_entry_id) = $st->fetchrow_array) {
	$num_delete++;
	my $newNRDBEntry = NRDBEntry->new ({'nrdb_entry_id'=>$nrdb_entry_id});
	$newNRDBEntry->retrieveFromDB();
	$newNRDBEntry->markDeleted();
	$newNRDBEntry->submit();
	$newNRDBEntry->undefPointerCache();
    }
    return $num_delete;
}

sub deleteFromExtAASeq {
    my $num_delete = 0;
    my $st = $dbh->prepareAndExecute("select aa_sequence_id from externalaasequence where external_db_id = 4194 and aa_sequence_id not in (select /** RULE */ distinct aa_sequence_id from nrdbentry n)");
    while (my ($aa_sequence_id) = $st->fetchrow_array) {
	$num_delete++;
	my $newExtAASeq = ExternalAASequence->new ({'aa_sequence_id'=>$aa_sequence_id});
	$newExtAASeq->retrieveFromDB();
	$newExtAASeq->retrieveAllChildrenFromDB(1);
	$newExtAASeq->markDeleted(1);
	$newExtAASeq->submit();
	$newExtAASeq->undefPointerCache();
    }
    return $num_delete;
}

1;
__END__
=pod
=head1 Description
B<LoadNRDB> - a plug-in that loads nr protein data from ncbi into NRDBEntry and ExternalAaSequence for C<ga> (GUS application) package.

=head1 Purpose
B<LoadNRDB> plug_in that inserts and updates rows in ExternalAASequence and NRDBEntry using data in the nr protein files downloaded from ncbi.
=cut
