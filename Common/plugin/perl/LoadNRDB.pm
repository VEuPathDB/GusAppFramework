 package GUS::Common::Plugin::LoadNRDB;

@ISA = qw(GUS::PluginMgr::Plugin);
 
use strict;
use DBI;
use GUS::Model::DoTS::NRDBEntry;
use GUS::Model::DoTS::ExternalAASequence;

my $ctx;
my $count=0;
my $debug = 0;
$| = 1;

sub new {
  my $class = shift;

  my $self = {};
  bless($self,$class);

  my $usage = 'Plug_in to populate and update the NRDBEntry and ExternalAASequence tables';

  my $easycsp =
    [{o => 'testnumber1',
      t => 'int',
      h => 'number of iterations for testing temp table insertion',
     },
     {o => 'extDbRelId',
      t => 'int',
      h => 'external_database_release_id of the nr protein database',
     }, 
     {o => 'testnumber2',
      t => 'int',
      h => 'number of iterations for testing insertion 
                        into NRDBEntry and ExternalAASequence',
     },
     {o => 'gitax',
      t => 'string',
      h => 'location of the gi_taxid_prot.dmp file',
      d => '/usr/local/db/local/taxonomy/gi_taxid_prot.dmp',
     },
     {o => 'nrdb',
      t => 'string',
      h => 'location of the nrdb file',
      d => '/usr/local/db/local/nrdb/nr.Z',
     },
     {o => 'maketemp',
      t => 'boolean',
      h => 'option to create temp table',
     }, 
     {o => 'temp_login',
      t => 'string',
      h => 'login for space being used for temp table eg.pinney',
     },
     {o => 'temp_password',
      t => 'string',
      h => 'password for space being used for temp table',
     },
     {o => 'plugin',
      t => 'boolean',
      h => 'choice of whether to run the remainder of the plug_in',
     },
     {o => 'restart',
      t => 'int',
      h => 'for restarting the interrupted plugin(use with plugin 
            option), use number from last set number in log',
      },
     {o => 'delete',
      t => 'boolean',
      h => 'option to run delete portion',
     },
     {o=> 'restart_temp_table',
      t => 'boolean',
      h => 'indicates temp table insertion should be restarted because
            table already exits',
      },
     {o => 'dbi_str',
      t	=> 'string',
      h => 'server and machine for temp table, e.g. dbi:Oracle:host=erebus.pcbi.upenn.edu;sid=gusdev',
     },
     {o => 'sourceDB',
      t => 'string',
     h=> 'comma delimited pairs of source db name (from ExternalDatabase.name) and abreviations (from ncbi README file) 
          separated by a colon, 
          e.g. GENBANK (NRDB):gb,EMBL DATA LIBRARY (NRDB):emb',
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

sub run {
  my $self  = shift;
  $self->getArgs()->{'commit'} ? $self->log("***COMMIT ON***\n") : $self->log("**COMMIT TURNED OFF**\n");
  $self->log("Testing on " . $self->getArgs()->{'testnumber1'} . " insertions 
                into temp table\n") 
                if $self->getArgs()->{'testnumber1'};
  $self->log("Testing on " . $self->getArgs()->{'testnumber1'} . " insertions
                into NRDBEntry/ExternalAASequence\n") 
                if $self->getArgs()->{'testnumber2'};
  
  die "Supply the name of the nr protein file\n" unless $self->getArgs()->{'nrdb'};

  my $external_database_release_id = $self->getArgs()->{'extDbRelId'} || die 'external_database_release_id not supplied\n';

  my $dbHash = $self->getDB() if ($self->getArgs()->{'maketemp'} || $self->getArgs()->{'plugin'} );

  my $taxonHash = $self->getTaxon ()if ($self->getArgs()->{'maketemp'} || $self->getArgs()->{'plugin'});

  my $tempresults = $self->makeTempTable($dbHash, $taxonHash) 
                    if ($self->getArgs()->{'maketemp'});

  if (!$self->getArgs()->{'plugin'} && !$self->getArgs()->{'delete'}) {
      $self->log("NRDBTemp has been filled and the program is exiting\n");
      return $tempresults;
  }

  my $entryresults = $self->makeNRDBAndExternalAASequence($taxonHash, $dbHash,$external_database_release_id) 
    if ($self->getArgs()->{'plugin'});       
  
  if (!$self->getArgs()->{'delete'}){ 
    if ($tempresults) {
      my $entryresults .= $tempresults;
    }
    return $entryresults;   
  }
  
  my $nrdbdelete = $self->deleteFromNRDB if ($self->getArgs()->{'delete'});
  my $aadelete = $self->deleteFromExtAASeq if ($self->getArgs()->{'delete'});
  my $results = "Processing completed:";
  $results = $results . $tempresults . $entryresults . $nrdbdelete . $aadelete; 
  $self->log("$results\n");
  return $results;
}

sub getDB {
  my ($self) = @_;
  my $dbh = $self->getQueryHandle();

  my %dbNameHash;
  my @DBs = split(/,/, $self->getArgs()->{'sourceDB'});

  foreach my $db (@DBs) {
    my ($name, $abrev) = split(/:/, $db);
    $dbNameHash{$name}=$abrev;
  }
  my $sql = "select r.external_database_release_id from sres.externaldatabase d, sres.externaldatabaserelease r where upper(d.name) like ? and d.external_database_id=r.external_database_id and upper(r.version) = 'UNKNOWN'";

  my $stmt = $dbh->prepare($sql);

  my %dbHash;

  foreach my $dbName (keys %dbNameHash) {
    $stmt->execute($dbName);
    my $boundName = "%".$dbName."%";
    my ($db_rel_id) = $stmt->fetchrow_array();
    $stmt->finish();
    
    $dbHash{$dbNameHash{$dbName}} = $db_rel_id;
  }
  my $num = scalar keys %dbHash;

  print "There are $num entries in the database hash\n";

  return \%dbHash;
}


#################################
##taxonHash{gi}=taxon_id
##taxHash{ncbi_tax_id}=taxon_id
#################################
sub getTaxon {
    my ($self) = @_;
    my $dbh = $self->getQueryHandle();
    my $gi_tax = $self->getArgs->{'gitax'};
    open (TAXFILE, "$gi_tax") || 
                    die ("Can't open the gi/tax_id file\n");
    my %taxHash;
    my %taxonHash;
    my $st = $dbh->prepare("select t.taxon_id from sres.taxon t where t.ncbi_tax_id = ?"); 
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
    $self->log("There are $length gi to taxon_id pairs\n");
    return \%taxonHash;;
}

sub makeTempTable {
    my ($self,$dbHash, $taxonHash) = @_;
    my $login = $self->getArgs->{'temp_login'} || die "must provide temp_login 
                and temp_password for temp table\n";
    my $password = $self->getArgs->{'temp_password'} || 
                   die "must provide temp_login 
                     and temp_password for temp table\n";
    my $DBI_STR = $self->getArgs->{'dbi_str'} || die "must provide server and sid for temp table\n";
    my $dbh = DBI->connect($DBI_STR, $login, $password);

    if (!$self->getArgs->{'restart_temp_table'}) { 
      $dbh->do("truncate table NRDBTemp");
      $dbh->do("drop table NRDBTemp");
      $dbh->do("create table NRDBTemp (SOURCE_ID VARCHAR2(32) NOT NULL,EXTERNAL_DB_REL_ID NUMBER(5) NOT NULL,SEQUENCE_VERSION VARCHAR2(10),SET_NUM NUMBER(10) NOT NULL)");
      $dbh->do("grant select on NRDBTemp to gusrw");
    }
    my $st1 = $dbh->prepare("select max(set_num) from NRDBTemp");
    $st1->execute();
    my $max_num= $st1->fetchrow_array ? $st1->fetchrow_array : 0;
    my $set_num = 0;
    $st1->finish();
    my $st2 = $dbh->prepare("INSERT into NRDBTemp 
              (source_id,external_db_rel_id,set_num,sequence_version) values (?,?,?,?)");
    my $nrdb = $self->getArgs->{'nrdb'};
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
	    if ($self->getArgs->{'testnumber1'} && $set_num >= 
                ($self->getArgs->{'testnumber1'})) {
		$self->log("The testnumber, $set_num, of temp table entries
                                have been processed\n");
		last;
	    }
	    my $line = $_;
	    my @arr = split (/\cA/, $line);
	    #$EntryHash{gid}->{source_id}=[db_rel_id,description,taxon_id]
	    my %EntryHash;
	    $self->parseLine(\@arr, $dbHash, $taxonHash, \%EntryHash); 
	    foreach my $gid (keys %EntryHash) {
		foreach my $source_id (keys %{$EntryHash{$gid}}) {
		    my $sequence_version;
		    my $db_rel_id = $EntryHash{$gid}{$source_id}[0];
		    #extension for pdb is not a version number,rather, part of its source_id
		    if ($source_id =~ /(\S*?)\.(\S*)/ && $db_rel_id != $dbHash->{pdb}){ 
			$source_id = $1;
			$sequence_version = $2;
		    }
		    $st2->execute($source_id,$db_rel_id,
                                  $set_num,$sequence_version);
		    $set_num++;
		}
	    }
	    if ($set_num%1000 == 0) {
		$self->log("$set_num sets have been processed 
                               and put in the NRDBTemp table\n");
	    }
	}
    }
    my $tempresults = "$set_num total entries have been made 
                    into the NRDBTemp table";
    $self->log("$tempresults\n");
    close NRDB;
    return $tempresults;
}

sub makeNRDBAndExternalAASequence {
    my ($self,$taxonHash, $dbHash,$external_database_release_id) = @_;
    my $count = 0;
    
    my $temp_login = $self->getArgs->{'temp_login'} || 
                     die "--temp_login required to 
                     load NRDBEntry and ExternalAASequence\n";

    my $dbh = $self->getQueryHandle();
    my $st = $dbh->prepareAndExecute("select max(set_num) from $temp_login".".NRDBTemp");
    my ($max_set_num) = $st->fetchrow_array;
    $st->finish();

    $self->log("$max_set_num entries in temp table\n");
    
    my $nrdb = $self->getArgs->{'nrdb'};

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
	$num_submit = $self->getArgs->{'restart'};
    }
    else {
	$num_submit = 0;
    }  
    my $st = $dbh->prepare("select aa_sequence_id from dots.nrdbentry where source_id = ? and external_database_release_id = ?");

    while (<NRDB>) {
	chomp;
	# /^\>/ pattern indicating the beginning of the defline, if $seq exists, process the set 
	if (/^\>/) { 
	    if ($self->getArgs->{'testnumber2'} && $count > ($self->getArgs->{'testnumber2'})) {
		$self->log("The testnumber, $count, 
                              of entries has been processed\n");
		last;
	    }
	    if ($seq) {
		$count++;
		#get the preferred gi and source_id and get any one aa_sequence_id corresponding to a member of the set
		unless ($self->getArgs->{'restart'} && $count <= $self->getArgs->{'restart'}) {
		    if (scalar (keys %EntryHash) != 0) {
			my $newExtAASeq = &processHash(\%EntryHash,$seq,$st,$external_database_release_id,$dbHash);
			$newExtAASeq->submit();
			$num_submit++;
			print STDOUT ("Submitted set number:$num_submit\n");
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
	    $self->parseLine(\@arr, $dbHash, $taxonHash, \%EntryHash);
	    if (scalar (keys %EntryHash) == 0){
		next;
	    }
	}
	else {
	    $seq .= $_;
	}
    }
    my $newExtAASeq = &processHash(\%EntryHash,$seq,$st,$external_database_release_id,$dbHash);
    $newExtAASeq->submit();
    $num_submit++;
    my $entryresult = ("Number of entries to NRDB/ExternalAASequence : 
                        $num_submit\n");
    $self->log("$entryresult");
    $newExtAASeq->undefPointerCache();
    return $entryresult;
}

sub parseLine {
    my ($self,$arr, $dbHash, $taxonHash, $EntryHash) = @_;
    foreach my $line ( @$arr){
	if ($line =~ /gi\|(\d*)\|(\w*)\|(\S*?)\|\S*\s*(.*)/){
	    my $secondary_id = $1; 
	    my $external_db = $2;
	    if ($external_db eq 'tpg') {
		next;
	    }
	    my $source_id = $3;
	    
	    my $description = $4;
	    $description =~ s/\"//g;
	    $description =~ s/\gi\|.*//;
	    if (($external_db eq 'gnl') ||
		($external_db eq 'pir') ||
                ($external_db eq 'prf') || 
		($external_db eq 'pat')){
		if ($line =~ /gi\|\d*\|\w*\|\w*\|(\S*)/){
		    $source_id = $1;
		}
		else{
		    $self->log("ERROR: Unable to parse source id 
                                  for gnl, pir, pat, or prf.\n");
		}
	    }
	    elsif ($external_db eq 'pdb'){
		if ($line =~ /gi\|\d*\|\w*\|\w*\|(\S*)/){
		    $source_id = $source_id . "." . "$1" if $1;
		}
		else{
		    $self->log("ERROR: Unable to parse source id for pdb.\n");
		}
	    }
	    elsif (!$source_id){
		$source_id = $secondary_id;
		$external_db = 'genpept';
	    }
	    my $db_rel_id = $dbHash->{$external_db};
	    
	    my $taxon_id = $taxonHash->{$secondary_id};
	    $EntryHash->{$secondary_id}->{$source_id} = [$db_rel_id,$description,$taxon_id];
	}
    }
    return;
}

sub processHash {
    my ($EntryHash,$seq,$st,$external_database_release_id,$dbHash) = @_;
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
	    my $db_rel_id = $$EntryHash{$gid}->{$source_id}[0];
	    
	    my $description = $$EntryHash{$gid}->{$source_id}[1];
	    if ($db_rel_id==$dbHash->{sp}) {  
		$sp_gi=$gid;
		$sp_source=$source_id;
	    }
	    if ($db_rel_id==$dbHash->{pir}) {
		$pir_gi=$gid;
		$pir_source=$source_id;
	    }
	    if (length($description) > $max_length) {
		$default_gi=$gid;
		$default_source=$source_id;
	    }
	    if (!$newExtAASeq) {
		my $source;
		if ($source_id =~ /(\S*?)\.(\S*)/ && $db_rel_id != $dbHash->{pdb}) { 
		    $source = $1;
		}
		else{
		    $source=$source_id;
		}
		$st->execute($source,$db_rel_id);
		if (my ($aa_seq_id) = $st->fetchrow_array) {
		    $st->finish;
		    my $preExtAASeq =GUS::Model::DoTS::ExternalAASequence->new ({'aa_sequence_id'=>$aa_seq_id});
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
	&updateExtAASeq($newExtAASeq,$pref_gi,$pref_source,$$EntryHash{$pref_gi}->{$pref_source}[1],$external_database_release_id);
    }
    else {
	$newExtAASeq = &makeExtAASeq($seq,$pref_gi,$pref_source,$$EntryHash{$pref_gi}->{$pref_source}[1],$external_database_release_id);
    }
    &makeNRDBEntries($newExtAASeq,$pref_gi,$pref_source,$EntryHash,$dbHash);
    return $newExtAASeq;  
}

sub updateExtAASeq {
    my ($newExtAASeq,$secondary_identifier,$source_id,$description,$external_database_release_id) = @_;

    my $shortDescr = substr($description, 0, 255);
    if ($secondary_identifier != $newExtAASeq->getSecondaryIdentifier()){
	$newExtAASeq->setSecondaryIdentifier($secondary_identifier);
    }
    if ($source_id ne $newExtAASeq->getSourceId()){
      $newExtAASeq->setSourceId($source_id);
    }
    if ($shortDescr ne $newExtAASeq->getDescription()){
	$newExtAASeq->setDescription($shortDescr);
    }
    if ($external_database_release_id != $newExtAASeq->getExternalDatabaseReleaseId()){
	$newExtAASeq->setExternalDatabaseReleaseId($external_database_release_id);
    }
}

sub makeExtAASeq {
  my ($seq,$secondary_identifier,$source_id,$description, $external_database_release_id) = @_;
  my $shortDescr = substr($description, 0, 255);
  my $newExtAASeq = GUS::Model::DoTS::ExternalAASequence->new({'external_database_release_id' => $external_database_release_id,'source_id'=> $source_id,'secondary_identifier' => $secondary_identifier, 'description' => $shortDescr});
  $newExtAASeq->retrieveFromDB();
  if($seq){
      $newExtAASeq->setSequence($seq);
  }
  return $newExtAASeq;
}

sub makeNRDBEntries {
    my ($newExtAASeq,$pref_gi,$pref_source,$EntryHash,$dbHash) = @_;
    foreach my $secondary_id (keys %$EntryHash) {
	foreach my $source_id (keys %{$$EntryHash{$secondary_id}}) {
	    my $db_rel_id = $$EntryHash{$secondary_id}->{$source_id}[0];
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
	    
	    if ($source_id =~ /(\S*?)\.(\S*)/ && $db_rel_id != $dbHash->{pdb}) {
		$source_id = $1;
		$sequence_version = $2;
	    }
	    my $newNRDBEntry = GUS::Model::DoTS::NRDBEntry->new({'source_id'=>$source_id, 'external_database_release_id'=>$db_rel_id});
	    $newNRDBEntry->retrieveFromDB(); 
	    if ($secondary_id!=$newNRDBEntry->getGid()){
		$newNRDBEntry->setGid($secondary_id);
	    }
	    if ($shortDescr ne $newNRDBEntry->getDescription()){
		$newNRDBEntry->setDescription($shortDescr);	  
	    }
	    if (!defined $newNRDBEntry->getIsPreferred() || $is_preferred != $newNRDBEntry->get('is_preferred')){
		$newNRDBEntry->setIsPreferred($is_preferred);	  
	    }  
	    if ($taxon_id && $taxon_id!=$newNRDBEntry->getTaxonId()) {
		$newNRDBEntry->setTaxonId($taxon_id);
	    }
	    if ($sequence_version && $sequence_version != $newNRDBEntry->getSequenceVersion()) {
		$newNRDBEntry->setSequenceVersion($sequence_version);
	    }
	    $newNRDBEntry->setParent($newExtAASeq);
	}
    }
}

sub deleteFromNRDB {
    my ($self) = @_;
    my $num_delete = 0;

    my $dbh = $self->getQueryHandle();
    my $login = $self->getArgs()->{temp_login};
    my $st = $dbh->prepareAndExecute("select nrdb_entry_id from dots.nrdbentry where source_id not in (select n.source_id from dots.nrdbentry n, $login" . ".NRDBTemp p where n.source_id = p.source_id and n.external_database_release_id = p.external_db_rel_id)");
    while (my ($nrdb_entry_id) = $st->fetchrow_array) {
	$num_delete++;
	my $newNRDBEntry = GUS::Model::DoTS::NRDBEntry->new ({'nrdb_entry_id'=>$nrdb_entry_id});
	$newNRDBEntry->retrieveFromDB();
	$newNRDBEntry->markDeleted();
	$newNRDBEntry->submit();
	$newNRDBEntry->undefPointerCache();
      }
    return $num_delete;
}

sub deleteFromExtAASeq {
  my ($self) = @_;
  my $num_delete = 0;
  
  my $dbh = $self->getQueryHandle();
  my $ext_db_rel_id = $self->getArgs()->{extDbRelId};
  my $st = $dbh->prepareAndExecute("select aa_sequence_id from dots.externalaasequence where external_database_release_id = $ext_db_rel_id and aa_sequence_id not in (select distinct aa_sequence_id from dots.nrdbentry n)");
  while (my ($aa_sequence_id) = $st->fetchrow_array) {
    $num_delete++;
    my $newExtAASeq = GUS::Model::DoTS::ExternalAASequence->new ({'aa_sequence_id'=>$aa_sequence_id});
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
