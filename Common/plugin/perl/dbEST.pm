package GUS::Common::Plugin::DataLoad::dbEST;

@ISA = qw( GUS::PluginMgr::Plugin );

use strict;
my $DBEST_EXTDB_ID = 22; # global variable

$| = 1;

############################################################
# Add any specific objects you need (GUS30::<nams-space>::<table-name>
############################################################

use GUS::Model::DoTS::EST;
use GUS::Model::DoTS::Clone;
use GUS::Model::DoTS::Library;
use GUS::Model::DoTS::ExternalNASequence;
use GUS::Model::SRes::Taxon;
use GUS::Model::SRes::TaxonName;
use GUS::Model::SRes::Anatomy;

# ----------------------------------------------------------------------
# The new method should create and bless a new instance and call the
# following methods to initialize the necessary attributes of a
# plugin.

sub new {
	my $Class = shift;

	my $m = bless {}, $Class;
  
  my $easycsp = [{ h => 'number of iterations for testing',
                   t => 'int',
                   d => 10,
                   o => 'TestNumber',
                 },
                 { h => 'The span of entries to retrieve in batches',
                   t => 'int',
                   o => 'span',
                   d => 100,
                   r => 0,
                 },
                 { h => 'A log file (full path)',
                   t => 'string',
                   r => 0,
                   d => 'DataLoad_dbEST.log',
                   o => 'log',
                 },
                 { h => 'An update file containing the EST entries that changed',
                   t => 'string',
                   o => 'update_file',
                 },
                 { h => 'Signifies that the sequences in ExternalNASequence should NOT be updated, regardless of discrepencies in dbEST. An error message is output when there is a conflict.',
                   t => 'boolean',
                   o => 'no_sequence_update',
                 }];
  
  ## Initialize the plugin
  
  $m->initialize({requiredDbVersion => { DoTS => '3',
                                         Core => '3',
                                         SRes => '3',
                                       },
                  cvsRevision => ' $Revision$ ', # cvs fills this in
                  cvsTag => ' $Name$ ', # cvs fills this in!
                  name => ref($m),
                  revisionNotes => 'GUS 3.0 compliant',
                  easyCspOptions => $easycsp,
                  usage => 'Loads dbEST information into GUS',
                });
  
}

# ----------------------------------------------------------------------

sub run {
	my $M   = shift;

	$M->logRAIID;
	$M->logCommit;
	$M->logArgs;
  
#  my $ctx = $M->getCla();
  ## Make a few cache tables for common info
  $M->{libs} = {};          # dbEST library cache
  $M->{anat} = {};          # Anatomy (tissue/organ) cache
  $M->{taxon} = {};         # Taxonomy (est.organism) cache
  $M->{contact} = {};       # Contact info cache
  $M->setTableCaches(); 
  
  ## If an update file is given, use this as the basis 
  ## for an update. Otherwise query GUS for what needs to 
  ## be updated.

  my $count = 0;
  my $dbh = $M->getQueryhandle();
  my $est_q = 'select * from dbest.est@gus ';
  
	############################################################
	# Put loop here...remember to $M->undefPointerCache()!
	############################################################
  

  if ($M->getCla->{update_file}) {
    my $fh = FileHandle->new( "<" . $M->getCla->{update_file})  or 
      die "Could not open update file ". $M->getCla->{update_file} . "\n";
    $est_q .= " where id_est = ?";
    my $s = $dbh->prepare($est_q) or die "SQL=$est_q\n", $dbh->errstr;
    
    while (!$fh->eof()) {
      # A setof dbEST EST entries
      my ($e);
      for (my $i = 0; $i < $M->getCla->{span}; $i++) {
        my $l = $fh->getline();
        my ($eid) = split /\t/, $l;
        $s->execute($eid);
        while (my $r = $s->fetchrow_hashref('NAME_lc')){
          $e->{$r->{id_est}}->{e} = $r;
        }
      }
      $count += $M->processEntries($e,$dbh);
      $M->undefPointerCache();
    }
  }else {
    $est_q .= " where id_est >= ? and id_est < ?";    
    my $dbh = $M->getQueryHandle();
    my $s = $dbh->prepare($est_q) or die "SQL=$est_q\n", $dbh->errstr;
    
    # get the absolute max id_est
    my ($abs_max) = $M->sql_get_as_array('select max(id_est) from est@dbest');
    # get the min and max ids
    
    my $min = 0;
    my $max = $$M->{cla}->{span};
    while ($max <= $abs_max) {
      $s->execute($min,$max)  or die "SQL=$est_q\n", $dbh->errstr;
      my ($e);
      while (my $r = $s->fetchrow_hashref('NAME_lc')) {
        $e->{$r->{id_est}}->{e} = $r;
      }
      $count += $M->processEntries($e,$dbh);
      $M->undefPointerCache();
      $min = $max;
      $max += $M->{cla}->{span};
    }
  }
	############################################################
	# return status
	# replace word "done" with meaningful return value/summary of the
	# work that was done.
	############################################################
	return "Inserted/Updated $count dbEST est entries";
}


=pod

=head1 Description

B<DataLoad::dbEST> - A plugin for inserting/updating the EST information in GUS 
from a mirror of dbEST.

=head1 Purpose

B<DataLoad::dbEST> will insert or update DoTS.EST, DoTS.Clone, DoTS.Library, 
DoTS.ExternalNASequence and SRes.Contact tables.

Note that this plugin B<DOES NOT> update library or contact information from dbEST, 
It only handles insertions of new Library or Contact entries. For update of the 
DoTS.Library and SRes.Contact tables, see the C<DataLoad::dbESTLibrary> and C<DataLoad::dbESTContact> plugins, respectively.


=head1 Plugin methods

These methods are used by this plugin alone. 

=head2 processEntries

Process a set of EST entries and return the number of 
entries that were updated/inserted into GUS.

=cut

sub processEntries {
  my ($M, $e,$dbh ) = @_;
  my $count = 0;
  
  # get the most recent entry 
  foreach my $id (keys %$e) {
    if ($e->{$id}->{e}->{replaced_by}){
      my $re =  $M->getMostRecentEntry($e->{$id}->{e},$dbh);
      #this entry is bogus, delete from insert hash
      delete $e->{$id};
      #enter the new entry into the insert hash
      $e->{$re->{id_est}}->{e} = $re->{new};
      $e->{$re->{id_est}}->{old} = $re->{old};
    }
  }
  
  # get the sequences
  my $ids = join "," , keys %$e;
  my $A = $M->sql_get_as_hash_refs("select * from SEQUENCE\@dbest where id_est in ($ids) order by id_est, local_id");
  foreach my $s (@$A){
    $e->{$s->{id_est}}->{sequence} .= $s->{data};
  }
  # get the comments
  $ids = join "," , keys %$e;
  $A = $M->sql_get_as_hash_refs("select * from CMNT\@dbest where id_est in ($ids) order by id_est, local_id");
  foreach my $c (@$A){
    $e->{$c->{id_est}}->{comment} .= $c->{data};
  }
  
  ## Now that we have all the information we need, start processing
  ## this batch 
  foreach my $id (keys %$e) {
    # If there are older entries, then we need to go through an update 
    # proceedure of historical entries. Else just insert if not already present.
    if (@{$e->{$id}->{old}} > 0) {
      $count +=  $M->updateEntry($e->{$id},$dbh);
    }else {
      $count += $M->insertEntry($e->{$id}->{e},$dbh);
    }
  }
  return $count;
}

=pod 

=head2 updateEntry

Checks whether any of the historical entries are in GUS. Updates the 
Entry as necessary. 

Returns 1 if succesful update or 0 if not.

=cut

sub updateEntry {
  my ($M,$e,$dbh) = @_;
  my ($last,$present);
  ## Go through the older entries and determine whic is in GUS, if any
  ## Since there should only be one entry in GUS, it is valid to just 
  ## return after the first on is met.
  foreach my $oe (@{$e->{old}}) {
    my $est = GUS::Model::DoTS::EST->new({'source_id' => $e->{id_est},
                                          'external_database_release_id'
                                          => $DBEST_EXTDB_ID}
                                         );
    if ($est->retrieveFromDB()) {
      # Entry present in the DB; UPDATE
      return  $M->insertEntry($e->{e},$dbh,$est);
    }
  }
  #qq No historical entries; INSERT if not already present
  return $M->insertEntry($e->{e},$dbh);
}


=pod 

=head2 insertEntry

Checks for the entry in GUS. If not already present, then it inserts a 
new entry. If already present, it will check the atts for discrepencies 
if the 'fullupdate' flag was given. It will also determine whether we need 
to do anything at all.

In all cases it will check the sequence against DoTS.ExternalNASequence. 
Unless the C<no_sequence_update> flag is given, the sequence will be updated.
Else the conflict is reported to the log and sequence is left as-is.

Returns 1 if successful insert or 0 if not.

=cut

sub insertEntry{
  my ($M,$e,$dbh,$est) = @_;
  my $needsUpdate = 0;
  ## Do a full update only if the dbest.id_est is not the same
  ## This is valid since all EST 
  if (defined $est && ( $est->getSourceId() ne $e->{id_est})){
    $needsUpdate = 1;
  }else {
    $est = GUS::Model::DoTS::EST->new({'source_id' => $e->{id_est},
                                       'external_database_release_id'
                                       => $DBEST_EXTDB_ID}
                                     );
  }
  
  if ($est->retrieveFromDB()){    
    # The entry exists in GUS. Must check to see if valid
    if ($M->getCla()->{fullupdate} || $needsUpdate) {
      # Treat this as a new entry
      $M->populateEst($e,$est,$dbh);
      # check to see if clone information already exists
      # for this EST
      $M->checkCloneInfo($e,$est,$dbh);
    }
    # else this is already in the DB. Do Nothing.
    
  } else {
    # This is a new entry
    $M->populateEst($e,$est,$dbh);
    # check to see if clone information already exists
    # for this EST
    $M->checkCloneInfo($e,$est,$dbh);
  }
  
  # Check for an update of the sequence 
  my $seq = $est->getParent('GUS::Model::DoTS::ExternalNASequence',1);
  if ($e->{sequence} ne $seq->getSequence()){
    # change the sequence unless the no_sequence_update flag is given
    if (! $M->{cla}->{no_sequence_update}) {
      $seq->setSequence($e->{sequence});
      # set the ExtDBId to dbEST if not already so.
      $seq->setExternalDatabaseReleaseId( $DBEST_EXTDB_ID);
      # log the change of sequence
      $M->log('SEQ_UPDATE:', $seq->getId());
    } else {
      # There is a conflict, but the 'no_sequence_update' flag given
      # Output a message to the log
      $M->log('SEQ_NO_UPDATE: NA_SEQUENCE_ID=' , $seq->getId(), " DBEST_ID_EST=$e->{id_est}");
    }
  }
  # submit the sequence and EST entry. Return the submit() result.
  return $seq->submit();
}


=pod 

=head2 populateEST 

This is a doozy of a method that populate all the various parts of an EST, 
entry, including library, contact and sequence information. It also makes calls 
to other methods that parse fields for clone information and other columns.

No return value.

=cut

sub populateEst {
  my ($M,$e,$est) = @_;
  
  #parse the comment for hard to find information
  $M->parseEntry($e);
  
  ## Mapping to dots.EST columns
  my %atthash = ('id_est' => 'dbest_id_est',
                 'ID_gi'         => 'g_id'             ,
                 'id_lib'        => 'dbest_lib_id'     ,
                 'id_contact'    => 'dbest_contact_id' ,
                 'gb_uid'        => 'accession'        ,
                 'clone_uid'     => 'dbest_clone_uid'  ,
                 'insert_length' => 'seq_length'     ,
                 'seq_primer'    => 'seq_primer'      ,
                 'p_end'         => 'p_end'           ,
                 'dna_type'      => 'dna_type'        ,
                 'hiqual_start'  => 'quality_start'    ,
                 'hiqual_stop'   => 'quality_stop'     ,
                 'est_uid'       => 'est_uid'          ,
                 'polya'         => 'polya_signal'     ,
                 'gb_version'    => 'gb_version'       ,
                 'replaced_by'   => 'replaced_by'      ,
                 'est_uid'       => 'est_uid',
                 'washu_id' =>      'washu_id',
                 'washu_name' =>    'washu_name',
                 'image_id' =>      'image_id',
                 'is_image' =>      'is_image',
                 'possibly_reversed'   => 'possibly_reversed',
                 'putative_full_length_read'   => 'putative_full_length_read',
                 'trace_poor_quality'   => 'trace_poor_quality',
                );
  
  # set the easy stuff
  foreach my $a (keys %{$M->{atthash}}) {
    my $att = $atthash{$a};
    if ( $est->isValidAttribute($att)) {
      my $method = 'set';
      $method .= ucfirst $att;
      $method =~s/\_(\w)/uc $1/ge;
      $est->$method($e->{$a});
    }
  }
  
  # Set the contact from the contact hash
  if ($M->{contact}->{$e->{id_contact}}){
    $est->setContactId($M->{contact}->{$e->{id_contact}});
  }else {
    # get from DB and cache
    my $c = GUS::Model::SRes::Contact->new({'source_id' => $e->{id_contact},
                                            'external_database_release_id' => 22, #dbEST
                                           });
    unless ($c->retrieveFromDB()) {
      $M->newContact($e,$c);
    }
    # Add to cache
    $M->{contact}->{$c->getSourceId()} = $c->getId();
    # Set the parent-child relationship
    $est->setParent($c);
  }

  # Set the library information
  if (exists $M->{libs}->{$e->{id_lib}}){
    $est->setLibraryId($M->{libs}->{$e->{id_lib}}->{dots_lib});
  }else {
    # get from DB and cache
    my $l = GUS::Model::DoTS::Library->new({'dbest_id' => $e->{id_lib},
                                           });
    unless ($l->retrieveFromDB()) {
      $M->newLibrary($e,$l);
    }
    # Add to cache
    $M->{libs}->{$l->getDbestId()}->{dots_lib} = $l->getDbestId();
    $M->{libs}->{$l->getDbestId()}->{taxon} = $l->getTaxonId();    
    # set parent-child relationship
    $est->setParent($l);
  }
  $M;
}

=pod

=head2 checkCloneInfo

Checks a dbEST entry for presence of reliable clone 
information. If the EST comes from either WashU or the 
IMAGE Consortium, then the entry is processed.

=cut

sub checkCloneInfo {
  my ($M,$e,$est) = @_;
  
  # It only makes sense to check clone entries if the EST comes from
  # WashU or IMAGE
  return $M unless (($e->{is_image} && $e->{image_id}) 
                    || $e->{washu_name});
  
  # This is a clone. Try and grab the entry from GUS
  my $c = GUS::Model::DoTS::Clone->new();
  if ($e->{is_image}) {
    $c->setImageId($e->{image_id});
  } else {
    $c->setWashuName($e->{washu_name});
  }
  $c->retrieveFromDB();
  $M->updateClone($e,$c);
  
  $est->setParent($c);
  $est->addToSubmitList($c); ## NOTE: Must test this!!
}

=pod

=head2 newClone

Populates the attributes of a new clone from a dbEST EST entry.
It only makes sense to do this if the EST came from 
WashU or the IMAGE Consortium, but these test have 
already been done by this point.

=cut

sub updateClone {
  my ($M, $e, $c) = @_;
  # Check the clone for updated attributes
  my %atthash = ('id_est' => 'dbest_id_est',
                 'ID_gi'         => 'g_id'             ,
                 'id_lib'        => 'dbest_lib_id'     ,
                 'id_contact'    => 'dbest_contact_id' ,
                 'gb_uid'        => 'accession'        ,
                 'clone_uid'     => 'dbest_clone_uid'  ,
                 'insert_length' => 'seq_length'     ,
                 'seq_primer'    => 'seq_primer'      ,
                 'p_end'         => 'p_end'           ,
                 'dna_type'      => 'dna_type'        ,
                 'hiqual_start'  => 'quality_start'    ,
                 'hiqual_stop'   => 'quality_stop'     ,
                 'est_uid'       => 'est_uid'          ,
                 'polya'         => 'polya_signal'     ,
                 'gb_version'    => 'gb_version'       ,
                 'replaced_by'   => 'replaced_by'      ,
                 'est_uid'       => 'est_uid',
                 'washu_id' =>      'washu_id',
                 'washu_name' =>    'washu_name',
                 'image_id' =>      'image_id',
                 'is_image' =>      'is_image',
                 'possibly_reversed'   => 'possibly_reversed',
                 'putative_full_length_read'   => 'putative_full_length_read',
                 'trace_poor_quality'   => 'trace_poor_quality',
                 );

  foreach my $a (keys %atthash) {
    my $att = ${$a};
    if ( $c->isvalidAttribute($att)) {
      my $getmethod = 'get';
      my $setmethod = 'set';
      $setmethod .= ucfirst $att;
      $setmethod =~s/\_(\w)/uc $1/ge;
      $getmethod .= ucfirst $att;
      $getmethod =~s/\_(\w)/uc $1/ge;
      if ($c->$getmethod() ne $e->{$a}) {
        $c->$setmethod($e->{$a});
      }
    }
  }
  # check the library information 
  unless  (exists $M->{libs}->{$e->{id_lib}}->{dots_lib}){
    # get from DB and cache
    my $l = GUS::Model::DoTS::Library->new({'dbest_id' => $e->{id_lib},
                                           });
    unless ($l->retrieveFromDB()) {
      $M->newLibrary($e,$l);
    }
    # Add to cache
    $M->{libs}->{$l->getDbestId()}->{dots_lib} = $l->getDbestId();
    $M->{libs}->{$l->getDbestId()}->{taxon} = $l->getTaxonId();    
  }
  if ($c->getLibraryId() ne $M->{libs}->{$e->{id_lib}}->{dots_lib}){
    $c->setLibraryId($M->{libs}->{$e->{id_lib}}->{dots_lib});
  }
  
  # RETURN 
  $M;
}

=pod

=head2 getMostRecentEntry

Gets the most recent EST entry from dbEST. Shoves all older entries into
an array to check for in GUS.

Returns HASHREF (new => newest entry,
                 old => array of all older entries,
                )

=cut

sub getMostRecentEntry {
  my ($M,$e,$dbh,$R) = @_;
  push @{$R->{old}}, $e;
  my $s = $dbh->prepare("select * from EST\@dbest where id_est = $e->{replaced_by}") 
      or die $dbh->errstr;
  $s->execute() or die $dbh->errstr;
  my $re = $s->fetchrow_hashref('NAME_lc');
  if ($re->{replaced_by} ) {
    $R = $M->getMostRecentEntry($re,$dbh,$R);
  } else {
    $R->{new} = $re;
  }
  return $R;
}


=pod 

=head2 parseEntry

Method to parse various information from the EST\'s comment 
field, as well as a bit of clone information. It only makes 
sense in GUS to designate IMAGE and WashU clones as clones.

=cut

sub parseEntry {
  my ($M,$e) = @_;

  ## Parse for WashU atts
  if (($e->{comment} =~ /Washington University Genome Sequencing Center/i)) {
    $e->{washu_id} = $e->{est_uid};
    $e->{est_uid} =~ /(\w+)\.\w{2}/;
    $e->{washu_name} = $1;
  } elsif ( $e->{est_uid} =~ /\w+\.[a-z]\d/) { 
    # probably a washu_id
    $e->{washu_id} = $e->{est_uid};
    $e->{est_uid} =~ /(\w+)\.\w{2}/;
    $e->{washu_name} = $1;
  }
	
  ## Parse IMAGE clone information 
  if ($e->{clone_uid}  =~ /IMAGE\:(\d+)/) {
    $e->{image_id} = $1;
    $e->{is_image} = 1;
  }else {
    $e->{is_image} = 0;
  }

  ## Parse for trace_poor_quality
  if ($e->{comment} =~ /poor quality/i) {
    $e->{trace_poor_quality} = 1;
  } else { 
    $e->{trace_poor_quality} = 0;
  }
  ## Parse for possibly_reversed
  if ($e->{comment} =~ /possible\s+reversed/i) {
    $e->{possibly_reversed} = 1;
  } else {
    $e->{possibly_reversed} = 0;
  }
  ## Parse for putative_full_length_read
  if ($e->{comment} =~ /putative\s+full\s+length\s+read/i) {
    $e->{putative_full_length_read} = 1;
  } else {
    $e->{putative_full_length_read} = 0;
  }
  
  ## Parse p_end information
  if ($e->{p_end} eq " " || $e->{p_end} eq "" || $e->{p_end} =~ /\?/) {
    delete $e->{p_end};
  } elsif (($e->{p_end} =~ /5\'|5 prime|five prime/i) && 
           ($e->{p_end} =~ / 3\'|3 prime|three prime/i)) {
    delete $e->{p_end};
    # Look for 5 or 3 prime designation	
  } elsif ($e->{p_end} =~ /3\'|3\s?prime|three\s+prime/i) {
    $e->{p_end} = 3;
  } elsif ($e->{p_end} =~ /5\'|5\s?prime|five\s+prime/i) {
    $e->{p_end} = 5;
  } else {
    # not covered by cases above, so delete the biznatch
    delete $e->{p_end};
  }
}

=pod 

=head2 setTableCaches

A method to set certain cache information to speed up the load. 

=cut


sub setTableCaches {
  my $M = shift;
  
  # Library cache
  my $q = 'select dbest_id as dbest_lib_id, library_id, taxon_id from dots.Library';
  my $A = $M->sql_get_as_array_refs($q);
  foreach my $r (@$A) {
    $M->{libs}->{$r->[0]}->{dots_lib} = $r->[1];
    $M->{libs}->{$r->[0]}->{taxon} = $r->[2];
  }
  
  # Contact info, get entries only from dbEST
  $q = 'select contact_id, source_id from sres.contact where external_database_release_id = ?? and source_id is not null';
  $A = $M->sql_get_as_array_refs($q);
  foreach my $r (@$A) {
    $M->{contact}->{$r->[1]} = $r->[0];
  }
  
  # Anatomy cache
  # changed to on-demand caching
  
  # Taxon cache
  # changed to get all organism names for human and mouse
  # all else is on-demand cache
  $q = 'select name, taxon_id  from sres.TaxonName where taxon_id in (8,14)';
  $A = $M->sql_get_as_array_refs($q);
  foreach my $r (@$A) {
    $M->{taxon}->{$r->[0]} = $r->[1];
  }
}
=pod

=head2 newLibrary

Populates the attributes for a new DoTS.Library entry from dbEST.

=cut

sub newLibrary {
  my ($M,$e,$l) = @_;
  my ($dbest_lib) = $M->sql_get_as_hash_refs("select * from library where id_lib = $e->{id_lib}");
  my $atthash = {'id_lib' => 'dbest_id',
                 'name' => 'dbest_name',
                 'organism' => 'dbest_organism',
                 'strain' => 'strain',
                 'cultivar' => 'cultivar',
                 'sex' => 'sex',
                 'organ' => 'dbest_organ',
                 'tissue_type' => 'tissue_type',
                 'cell_type' => 'cell_type',
                 'cell_line' => 'cell_line',
                 'dev_stage' => 'stage',
                 'lab_host' => 'host',
                 'vector' => 'vector',
                 'v_type' => 'vector_type',
                 're_1' => 're_1',
                 're_2' => 're_2',
                 'description' => 'comment_string'
                };

  ## Set the easy of the attributes

  foreach my $a (keys %{$atthash}) {
    my $att = $atthash->{$a};
    if ($l->isValidAttribute($att)) {
      $l->set($att,$dbest_lib->{$a});
    }
  }

  ## Set the sex of the library 
  my $sex = $dbest_lib->{'sex'};
  if ($sex =~ /(male.+female)|(female.+male)|mix/i) {
    $l->set('sex', 'B');
  } elsif ($sex =~ /female/i) {
    $l->set('sex', 'F');
  } elsif ($sex =~ /male/i) {
    $l->set('sex', 'M');
  } elsif ($sex =~ /hemaph/i) {
    $l->set('sex', 'H');
  } elsif ($sex =~ /none|not/i) {
    $l->set('sex', 'n');
  } else {
    $l->set('sex', '?');
  }

  ## Set the library's taxon
  if ($M->{taxon}->{$dbest_lib->{organism}}) {
    $l->setTaxonId($M->{taxon}->{$dbest_lib->{organism}});
  } else {
    my $taxon = GUS::Model::SRes::TaxonName->new({'name' => $dbest_lib->{organism}});
    if ($taxon->retrieveFromDB()){
      $M->{taxon}->{$dbest_lib->{organism}} = $taxon->getTaxonId();
      $l->setTaxonId($taxon->getTaxonId());
    }else {
      #Log the fact that we couldn't parse out a taxon
      $M->log('ERR:NEW LIBRARY: TAXON', ' LIB_ID:',  $l->getId(), ' DBEST_ID:',
              $l->getDbestId(), ' ORGANISM:', $dbest_lib->{organism});
    }
  }
  
  ## parse out the anatomy of the library entry
  if ($M->{anat}->{$dbest_lib->{organ}}) {
    $l->setAnatomyId($M->{anat}->{$dbest_lib->{organ}});
  } else {
    my $anat = GUS::Model::SRes::Anatomy->new({'name' => $dbest_lib->{organ}});
    if ($anat->retrieveFromDB()){
      $M->{anat}->{$dbest_lib->{organ}} = $anat->getId();
      $l->setAnatomyId($anat->getId());
    }else {
      #Log the fact that we couldn't parse out a taxon
      $M->log('ERR: NEW LIBRARY: ANATOMY', ' LIB_ID:',  $l->getId(), ' DBEST_ID:',
              $l->getDbestId(), ' ORGAN:', $dbest_lib->{organ});
    }
  }
  
  ## Submit the new library
  $l->submit();
  # return
  $M;
}

=pod

=head2 newContact

Populate the attributes of a new SRes.Contact entry

=cut

  

sub newContact {
  my ($M,$e,$c)  = @_;
  
  my $q = qq[select * 
             from contact\@dbest 
             where id_contact = $e->{cid_contact}];
  my ($C) = $M->sql_get_as_has_refs($q);
  
  my %atthash = ('id_conact' => 'source_id',
                 'name' => 'name',
                 'lab' => 'lab',
                 'institution' =>  'address1',
                 'address' => 'address2',
                 'email' => 'email',
                 'phone' => 'phone',
                 'fax' => 'fax',
                 );
  
  foreach my $k (keys %atthash) {
    next if ($C->{$k} eq ' ' || $C->{$k} eq '') ;
    $c->set($atthash{$k}, $C->{$k});
  }
  # Set the external_database_release_id
  $c->setExternalDatabaseReleaseId($DBEST_EXTDB_ID);
  # submit the new contact to the DB
  $c->submit();
  $M;
}

1;

__END__
