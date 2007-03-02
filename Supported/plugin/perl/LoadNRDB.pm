#############################################################################
##                    LoadNRDB.pm
##
## Plug_in to populate and update the NRDBEntry and ExternalAASequence tables
## $Id$
##
#############################################################################

package GUS::Supported::Plugin::LoadNRDB;
@ISA = qw(GUS::PluginMgr::Plugin);


use strict;

use DBI;
use GUS::Model::DoTS::NRDBEntry;
use GUS::Model::DoTS::ExternalAASequence;
use GUS::PluginMgr::Plugin;

my $count=0;
my $debug = 0;
$| = 1;


my $argsDeclaration =
[

 integerArg({name => 'testnumber1',
	     descr => 'number of iterations for testing temp table insertion',
	     constraintFunc => undef,
	     reqd => 0,
	     isList => 0
	     }),
 
 integerArg({name => 'testnumber2',
	     descr => 'number of iterations for testing insertion into NRDBEntry and ExternalAASequence',
	     constraintFunc => undef,
	     reqd => 0,
	     isList => 0
	     }),
 
 stringArg({name => 'externalDatabaseName',
	    descr => 'sres.externaldatabase.name for NRDB',
	    constraintFunc => undef,
	    reqd => 1,
	    isList => 0
	    }),
 
 stringArg({name => 'externalDatabaseVersion',
	    descr => 'sres.externaldatabaserelease.version for this instance of NRDB',
	    constraintFunc => undef,
	    reqd => 1,
	    isList => 0
	    }),

 fileArg({name => 'gitax',
	  descr => 'pathname for the gi_taxid_prot.dmp file',
	  constraintFunc => undef,
	  reqd => 1,
	  isList => 0,
	  mustExist => 1,
	  format => 'Text'
        }),

 fileArg({name => 'nrdbFile',
	  descr => 'pathname for the nrdb file',
	  constraintFunc => undef,
	  reqd => 1,
	  isList => 0,
	  mustExist => 1,
	  format => 'Text'
         }),

 booleanArg({name => 'makeTemp',
             descr => 'option to create temp table',
             reqd => 0,
             default => 0
            }),

 stringArg({name => 'tempLogin',
	    descr => 'login for space being used for temp table eg.pinney',
	    constraintFunc => undef,
	    reqd => 0,
	    isList => 0
	   }),

 stringArg({name => 'tempPassword',
	    descr => 'password for space being used for temp table',
	    constraintFunc => undef,
	    reqd => 0,
	    isList => 0
	   }),

 booleanArg({name => 'plugin',
             descr => 'choice of whether to run the remainder of the plug_in',
             reqd => 0,
             default => 0
            }),

 integerArg({name => 'restart',
	     descr => 'for restarting the interrupted plugin(use with plugin 
             option), use number from last set number in log',
	     constraintFunc => undef,
	     reqd => 0,
	     isList => 0
	    }),

 booleanArg({name => 'delete',
             descr => 'option to run delete portion',
             reqd => 0,
             default => 0
            }),

 booleanArg({name => 'restartTempTable',
             descr => 'indicates temp table insertion should be restarted because table already exists',
             reqd => 0,
             default => 0
            }),

 stringArg({name => 'dbiStr',
	    descr => 'server and machine for temp table, e.g. dbi:Oracle:host=erebus.pcbi.upenn.edu;sid=gusdev',
	    constraintFunc => undef,
	    reqd => 0,
	    isList => 0
	   }),

 stringArg({name => 'sourceDB',
	    descr => 'comma delimited pairs of source external_database_release_id for each db in the defline and abreviations (from ncbi README file) separated by a colon, e.g. 6501:gb, 6502:emb',
	    constraintFunc => undef,
	    reqd => 1,
	    isList => 0
	   })
 ];


my $purposeBrief = <<PURPOSEBRIEF;
Plug_in to populate and update the NRDBEntry and ExternalAASequence tables.
PURPOSEBRIEF

my $purpose = <<PLUGIN_PURPOSE;
plug_in that inserts and updates rows in ExternalAASequence and NRDBEntry using data in the nr protein files downloaded from ncbi.
PLUGIN_PURPOSE

#check the documentation for this
my $tablesAffected = [['GUS::Model::DoTS::ExternalAASequence', 'New ExternalAASequences are added to this table'],['GUS::Model::DoTS::NRDBEntry', 'New NRDBEntries are added to this table, the parents of the entries are the new ExternalAASequences']];

my $tablesDependedOn = [['GUS::Model::DoTS::NRDBEntry', 'pulls aa_sequence_id from here when id and extDbId match requested']];

my $howToRestart = <<PLUGIN_RESTART;
use 'restart' for restarting the interrupted plugin(use with plugin option), use number from last set number in log
use 'restartTempTable' indicates temp table insertion should be restarted because table already exits
PLUGIN_RESTART

my $failureCases = <<PLUGIN_FAILURE_CASES;
unknown
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
For arguments,plugin and makeTemp should be included if you want the plugin to create new entries in the NRDB and ExtAASeq databases, and to use plugin and makeTemp, you must include the arguments tempLogin, tempPassword, and dbiStr.
Note that none of these arguments are set to 'required' because they are only conditionally required (i.e. you only need them if you call something that requires them).
PLUGIN_NOTES

my $documentation = {purposeBrief => $purposeBrief,
		     purpose => $purpose,
		     tablesAffected => $tablesAffected,
		     tablesDependedOn => $tablesDependedOn,
		     howToRestart => $howToRestart,
		     failureCases => $failureCases,
		     notes => $notes
		    };

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  $self->initialize({requiredDbVersion => 3.5,
		     cvsRevision => '$Revision$', # cvs fills this in!
		     name => ref($self),
		     argsDeclaration   => $argsDeclaration,
		     documentation     => $documentation
		    });

  return $self;
}

########################################################################
# Main Program
########################################################################

sub run {
  my ($self) = @_;
  $self->log("Testing on " . $self->getArg('testnumber1') . " insertions 
                into temp table\n") 
                if $self->getArg('testnumber1');
  $self->log("Testing on " . $self->getArg('testnumber1') . " insertions
                into NRDBEntry/ExternalAASequence\n") 
                if $self->getArg('testnumber2');
# TODO: remove this once the new API is implemented  
  die "Supply the name of the nr protein file\n" unless $self->getArg('nrdbFile');

  $self->{failNum} = 0;

  $self->{'extDbRelId'} =
    $self->getExtDbRlsId($self->getArg('externalDatabaseName'),
			 $self->getArg('externalDatabaseVersion'));

  my $dbHash = $self->getDB();
  my $taxonHash = $self->getTaxon ()if ($self->getArg('makeTemp') || $self->getArg('plugin'));
  my $tempresults = $self->makeTempTable($dbHash, $taxonHash) 
                    if ($self->getArg('makeTemp'));

# there are cases where this if will execute and tempresults will not exist
  if (!$self->getArg('plugin') && !$self->getArg('delete')) {
      $self->log("NRDBTemp has been filled and the program is exiting\n");
      return $tempresults;
  }

  my $entryresults = 
    $self->makeNRDBAndExternalAASequence($taxonHash, $dbHash,
					 $self->{'extDbRelId'}) 
      if ($self->getArg('plugin'));

  if (!$self->getArg('delete')){
    if ($tempresults) {
       my $entryresults .= $tempresults;
     }
    return $entryresults;
  }

  my $nrdbdelete = $self->deleteFromNRDB ($dbHash) if ($self->getArg('delete'));
  my $aadelete = $self->deleteFromExtAASeq($dbHash) if ($self->getArg('delete'));
  my $results = "Processing completed:";
  $results = $results . $tempresults . $entryresults . $nrdbdelete . $aadelete; #not all of these will be initialized 
  $self->log("$results\n");

  return $results;
}

#######################################################################
# Sub-routines
#######################################################################

# ---------------------------------------------------------------------
# Get DB
# ---------------------------------------------------------------------

sub getDB {
  my ($self) = @_;
  my $dbh = $self->getQueryHandle();

  my %dbHash;
  my @DBs = split(/,/, $self->getArg('sourceDB'));

  foreach my $db (@DBs) {
    my ($db_rel_id, $abrev) = split(/:/, $db);
# TODO: remove die once new API is implemented?
    die "--sourceDB db_rel_id:abreviation pairs must be provided\n" if (!$db_rel_id || !$abrev);
    $dbHash{$abrev} = $db_rel_id;
  }

  my $num = scalar keys %dbHash;

  $self->log("There are $num entries in the source database hash");

  return \%dbHash;
}


# ---------------------------------------------------------------------
# taxonHash{gi}=taxon_id
# taxHash{ncbi_tax_id}=taxon_id
# ---------------------------------------------------------------------

sub getTaxon {
    my ($self) = @_;
    my $dbh = $self->getQueryHandle();
    my $gi_tax = $self->getArg('gitax');

    open (TAXFILE, "$gi_tax") || 
                    die ("Can't open the gi/tax_id file\n");
# TODO: remove die once new API is implemented
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
    $st->finish();

    close (TAXFILE);
    my $length = scalar (keys %taxonHash);
    $self->log("There are $length gi to taxon_id pairs\n");

    return \%taxonHash;;
}

# ---------------------------------------------------------------------
# Make a Temp Table
# ---------------------------------------------------------------------

sub makeTempTable {
    my ($self,$dbHash, $taxonHash) = @_;

# TODO: remove die statements once new API is implemented
    my $login = $self->getArg('tempLogin') || die "must provide tempLogin 
                and tempPassword for temp table\n";
    my $password = $self->getArg('tempPassword') || 
                   die "must provide tempLogin and tempPassword for temp table\n";
    my $DBI_STR = $self->getArg('dbiStr') || die "must provide server and sid for temp table\n";
    my $dbh = DBI->connect($DBI_STR, $login, $password,{AutoCommit => 0}) || die "Can't connect to db with DBI\n";

    if (! $self->getArg('restartTempTable')) { 
      $dbh->do("truncate table NRDBTemp");
      $dbh->do("drop table NRDBTemp");
      $dbh->do("create table NRDBTemp (SOURCE_ID VARCHAR(32) NOT NULL,EXTERNAL_DB_REL_ID FLOAT(5) NOT NULL,SEQUENCE_VERSION VARCHAR(10),SET_NUM FLOAT(10) NOT NULL)");
      $dbh->do("grant select on NRDBTemp to public");
    }

    my $st1 = $dbh->prepare("select max(set_num) from NRDBTemp");
    $st1->execute();
    my $max_num= $st1->fetchrow_array ? $st1->fetchrow_array : 0;
    my $set_num = 0;
    $st1->finish();
    my $st2 = $dbh->prepare("INSERT into NRDBTemp 
              (source_id,external_db_rel_id,set_num,sequence_version) values (?,?,?,?)");

# TODO: Remove all die statements once new API is implemented
    my $nrdb = $self->getArg('nrdbFile');

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
	    if ($self->getArg('testnumber1') && $set_num >= 
                ($self->getArg('testnumber1'))) {
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
		$dbh->commit();
	    }
	}
    }
    $dbh->commit();
    my $tempresults = "$set_num total entries have been made 
                    into the NRDBTemp table";
    $self->log("$tempresults\n");
    close NRDB;

    return $tempresults;
}

# ---------------------------------------------------------------------
# Make NRDB and External AA Sequence
# ---------------------------------------------------------------------

sub makeNRDBAndExternalAASequence {
    my ($self,$taxonHash, $dbHash,$external_database_release_id) = @_;
    my $count = 0;
    my %EntryHash; 
    my $seq;
    my $num_submit;
    my $restart_arg;

    my $dbh = $self->getQueryHandle();
    my $st = $dbh->prepareAndExecute("select max(set_num) from NRDBTemp");
    my ($max_set_num) = $st->fetchrow_array;
    $st->finish();

    $self->log("$max_set_num entries in temp table\n");  
    my $nrdb = $self->getArg('nrdbFile');

# TODO: remove all die statements after new API is implemented
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

    $restart_arg = $self->getArg('restart');

    if ($restart_arg){
	$num_submit = $restart_arg;
    }
    else {
	$num_submit = 0;
    }
  
    $st = $dbh->prepare("select aa_sequence_id from dots.nrdbentry where source_id = ? and external_database_release_id = ?");

    while (<NRDB>) {
	chomp;
	# /^\>/ pattern indicating the beginning of the defline, if $seq exists, process the set 
	if (/^\>/) { 
	    if ($self->getArg('testnumber2') && $count > ($self->getArg('testnumber2'))) {
		$self->log("The testnumber, $count, of entries has been processed\n");
		last;
	    }
	    if ($seq) {
		$count++;
		#get the preferred gi and source_id and get any one aa_sequence_id corresponding to a member of the set
		unless ($restart_arg && $count <= $restart_arg) {
		    if (scalar (keys %EntryHash) != 0) {
			my $newExtAASeq = &processHash(\%EntryHash,$seq,$st,$external_database_release_id,$dbHash);
			eval {
			    $newExtAASeq->submit();
			};

			$self->handleFailure($seq,$@) if ($@); 

			$num_submit++;
		        $self->log("Submitted set number:$num_submit");
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
    $st->finish();

    my $newExtAASeq = &processHash(\%EntryHash,$seq,$st,$external_database_release_id,$dbHash);
    $newExtAASeq->submit();
    $num_submit++;
    my $entryresult = ("Number of entries to NRDB/ExternalAASequence : 
                        $num_submit\n");
    $self->log("$entryresult");
    $newExtAASeq->undefPointerCache();

    return $entryresult;
  }

# ---------------------------------------------------------------------
# Parse Line
# ---------------------------------------------------------------------

sub parseLine {
    my ($self,$arr, $dbHash, $taxonHash, $EntryHash) = @_;

    foreach my $line ( @$arr){
	if ($line =~ /gi\|(\d*)\|(\w*)\|(\S*?)\|\S*\s*(.*)/){
	    my $secondary_id = $1; 
	    my $external_db = $2;
	    my $source_id = $3;
	    my $description = $4;
	    $description =~ s/\"//g;
# TODO: \g is not a valid escape character	   
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

# ---------------------------------------------------------------------
# Process Hash
# ---------------------------------------------------------------------

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

# ---------------------------------------------------------------------
# Update External AA Sequence
# ---------------------------------------------------------------------

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

# ---------------------------------------------------------------------
# Make an External AA Sequence
# ---------------------------------------------------------------------

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

# ---------------------------------------------------------------------
# Error Handling: Handle Failure
# ---------------------------------------------------------------------

sub handleFailure {
  my ($self, $seq, $errMessage) = @_;
  $self->{failNum}++;

  $self->log("$errMessage:\n$seq");
  die "Number of failures exceeds 100" if ($self->{failNum} > 100);
}
  
# ---------------------------------------------------------------------
# Make NRDB Entries
# ---------------------------------------------------------------------

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

# ---------------------------------------------------------------------
# Delete Entry from NRDB
# ---------------------------------------------------------------------

sub deleteFromNRDB {
  my ($self, $dbHash) = @_;
  my $num_delete = 0;
  my $rel_list = join(',', values %{$dbHash});
  my $dbh = $self->getQueryHandle();
  my %nrdbId;
  my $sql1 = "select n.nrdb_entry_id from dots.nrdbentry n, NRDBTemp p where n.source_id = p.source_id and n.external_database_release_id = p.external_db_rel_id";
  my $st1 = $dbh->prepareAndExecute($sql1) || die "SQL failed: $sql1\n";

  while (my ($nrdb_entry_id) = $st1->fetchrow_array) {
    $nrdbId{$nrdb_entry_id} = 1;
  }
  $st1->finish();

  my $sql2 = "select nrdb_entry_id from dots.nrdbentry where external_database_release_id in ($rel_list)";
  my $st2 = $dbh->prepareAndExecute($sql2) || die "SQL failed: $sql2\n";

  while (my ($nrdb_entry_id) = $st2->fetchrow_array) {
    if ($nrdbId{$nrdb_entry_id} != 1) {
      $num_delete++;
      my $newNRDBEntry = GUS::Model::DoTS::NRDBEntry->new ({'nrdb_entry_id'=>$nrdb_entry_id});
      $newNRDBEntry->retrieveFromDB();
      $newNRDBEntry->markDeleted();
      $newNRDBEntry->submit();
      $newNRDBEntry->undefPointerCache();
    }
  }
  $st2->finish();

  my $results = "Number of rows deleted from NRDB : $num_delete\n";

  return $results;
}

# ---------------------------------------------------------------------
# Delete Entry From External AA Sequence
# ---------------------------------------------------------------------

sub deleteFromExtAASeq {
  my ($self, $dbHash) = @_;
  my $num_delete = 0;
  my $rel_list = join (',', values %{$dbHash});
  my $ext_db_rel_id = $self->{'extDbRelId'};

  my $sql = "select aa_sequence_id from dots.externalaasequence where external_database_release_id = $ext_db_rel_id and aa_sequence_id not in (select aa_sequence_id from dots.nrdbentry)";
  my $st = $self->prepareAndExecute($sql);

  while (my ($aa_sequence_id) = $st->fetchrow_array) {
    $num_delete++;
    my $newExtAASeq = GUS::Model::DoTS::ExternalAASequence->new ({'aa_sequence_id'=>$aa_sequence_id});
    $newExtAASeq->retrieveFromDB();
    $newExtAASeq->retrieveAllChildrenFromDB(1);
    $newExtAASeq->markDeleted(1);
    $newExtAASeq->submit();
    $newExtAASeq->undefPointerCache();
  }
  $st->finish();

  my $results = "Number of rows deleted from ExternalAASequence : $num_delete\n";

  return $results;
}


1;


__END__
=pod
=head1 Description
B<LoadNRDB> - a plug-in that loads nr protein data from ncbi into NRDBEntry and ExternalAaSequence for C<ga> (GUS application) package.

=head1 Purpose
B<LoadNRDB> plug_in that inserts and updates rows in ExternalAASequence and NRDBEntry using data in the nr protein files downloaded from ncbi.
=cut
