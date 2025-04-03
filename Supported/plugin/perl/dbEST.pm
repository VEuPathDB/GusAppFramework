 package GUS::Supported::Plugin::dbEST;

@ISA = qw( GUS::PluginMgr::Plugin );
use GUS::PluginMgr::Plugin;
use CBIL::Util::PropertySet;

use strict;


$| = 1;

############################################################
# Add any specific objects you need (GUS30::<nams-space>::<table-name>
############################################################

use GUS::Model::DoTS::EST;
use GUS::Model::DoTS::Clone;
use GUS::Model::DoTS::Library;
use GUS::Model::DoTS::ExternalNASequence;
use GUS::Model::SRes::OntologyTerm;
use GUS::Model::DoTS::SequenceType;
use GUS::Model::SRes::Taxon;
use GUS::Model::SRes::TaxonName;
use GUS::Model::SRes::Contact;
use GUS::Model::SRes::ExternalDatabase;
use GUS::Model::SRes::ExternalDatabaseRelease;

use FileHandle;
use DBI;


sub new {
  my ($class) = @_;

  my $self = {};
  bless($self,$class);

  my $purpose = <<PURPOSE;
Module used to copy data from a mirrored dbEST into GUS
PURPOSE

  my $purposeBrief = <<PURPOSE_BRIEF;
Copy mirrored dbEST data into GUS
PURPOSE_BRIEF

  my $notes = <<NOTES;
Data is mapped from dbEST tables into GUS tables. Tables are mapped one to many.
NOTES

  my $tablesAffected = <<TABLES_AFFECTED;
TABLES_AFFECTED

  my $tablesDependedOn = <<TABLES_DEPENDED_ON;
TABLES_DEPENDED_ON

  my $howToRestart = <<RESTART;
Plugin will not clobber the db but using restart will save time.Use restart_number option and the last id_est entered from mirrored dbEST or line number of last est entered if using update file.
RESTART

  my $failureCases = <<FAIL_CASES;
FAIL_CASES

  my $documentation = { purpose          => $purpose,
			purposeBrief     => $purposeBrief,
			notes            => $notes,
			tablesAffected   => $tablesAffected,
			tablesDependedOn => $tablesDependedOn,
			howToRestart     => $howToRestart,
			failureCases     => $failureCases };


  my $argsDeclaration = 
    [
     booleanArg({name => 'no_sequence_update',
		 descr => 'No update of sequences in ExternalNASequence', 
		 constraintFunc => undef,
		 reqd => 0,
		}),
     booleanArg({name => 'do_not_update',
		 descr => 'Will do inserts only, if est already loaded will throw error and fail', 
		 constraintFunc => undef,
		 reqd => 0,
		}),
     stringArg({name => 'update_file',
		descr => 'An update file containing the EST entries that changed,one id_est per line',
		constraintFunc => undef,
		reqd => 0,
		isList => 0
	       }),
     integerArg({name => 'restart_number',
		 descr => 'line number if input is file, last id_est in log file if input is dbEST',
		 constraintFunc => undef,
		 reqd => 0,
		 isList => 0
		}),
     integerArg({name => 'test_number',
		 descr => 'number of iterations for testing',
		 constraintFunc => undef,
		 reqd => 0,
		 isList => 0
		}),
     stringArg({name => 'log',
		descr => 'log file (path relative to current/working directory)',
		constraintFunc => undef,
		reqd => 0,
		default => 'DataLoad_dbEST.log',
		isList => 0
	       }),
     integerArg({name => 'span',
		 descr => 'number of entries in each batch to retieve from dbEST',
		 reqd => 0,
		 constraintFunc => undef,
		 default => '100',
		 isList => 0
		}),
     stringArg({ name => 'ncbiTaxId',
		 descr => 'Comma delimited list of ncbi tax ids, alternative to taxon_id_list',
		 reqd => 0,
		 constraintFunc => undef,
		 isList => 1
	       }),
     stringArg({ name => 'taxon_id_list',
		 descr => 'Comma delimited list of taxon_ids to load,alternative to ncbiTaxId',
		 reqd => 0,
		 constraintFunc => undef,
		 isList => 1
	       }),
     fileArg({ name => 'taxonFile',
               descr => 'alternative to taxon_id_list or ncbiTaxId list, file containing a comma delimited list of taxon_ids used to load ESTs',
               reqd           => 0,
               mustExist => 0,
               format =>"comma delimited list all on one line",
               constraintFunc => undef,
               isList         => 0 }),
     booleanArg({name => 'fullupdate',
		 descr => 'flag indicating that atts should be checked for discrepensies',
		 reqd => 0,
		 constraintFunc => undef
		}),
     booleanArg({name => 'logNaSeqId',
		 descr => 'option to write all na_sequence_ids into a STDOUT file via logData',
		 reqd => 0,
		 constraintFunc => undef
		}),
     stringArg({ name => 'extDbName',
		 descr => 'dots.externaldatabase.name',
		 reqd => 0,
		 constraintFunc => undef,
		 isList => 0
	       }),
     stringArg({name => 'extDbRlsVer',
		descr => 'dots.externaldatabaserelease.version',
		reqd => 0,
		constraintFunc => undef,
		isList => 0
	       }),
     stringArg({name => 'SOExtDbRlsSpec',
		descr => 'The extDbRlsName of the Sequence Ontology to use',
		reqd => 1,
		constraintFunc => undef,
		isList => 0
	       }),
     stringArg({name => 'anatomyExtDbRlsSpec',
		descr => 'The extDbRlsName of the Sequence Ontology to use',
		reqd => 0,
		constraintFunc => undef,
		isList => 0
	       }),
     stringArg({name => 'dbestConnect',
                descr => 'connection string used for dbest Ex. dbi:oracle:musbld',
                reqd => 1,
                constraintFunc => undef,
                isList => 0
                }),
     stringArg({name => 'dbestLoginFile',
		descr => 'file with property=value pairs for dbestLogin and dbestPswd, alternative to the dbestPswd and dbestLogin arguments',
		reqd => 0,
		constraintFunc => undef,
		isList => 0
		}),
     stringArg({name => 'dbestLogin',
		descr => 'login used for dbest mirror',
		reqd => 0,
		constraintFunc => undef,
		isList => 0
	       }),
     stringArg({name => 'dbestPswd',
		descr => 'password  used for dbest mirror',
		reqd => 0,
		constraintFunc => undef,
		isList => 0
	       })
    ];

  $self->initialize({requiredDbVersion => 4.0,
		     cvsRevision => '$Revision$',	# cvs fills this in!
		     name => ref($self),
		     argsDeclaration   => $argsDeclaration,
		     documentation     => $documentation});


  return $self;
}


# ----------------------------------------------------------------------

sub run {
  my ($self)   = shift;

  $self->logAlgInvocationId;
  $self->logCommit;
  $self->logArgs;

  ## Set the log file
  $self->{'log_fh'}  = FileHandle->new(">" . $self->getArg('log'))
    or $self->userError("Log file " . $self->getArg('log') . "not open\n");
  $self->{'log_fh'}->autoflush(1);

  ## Make a few cache tables for common info
  $self->{libs} = {};          # dbEST library cache
  $self->{anat} = {};          # Anatomy (tissue/organ) cache
  $self->{taxon} = {};         # Taxonomy (est.organism) cache
  $self->{contact} = {};       # Contact info cache
  $self->setTableCaches();

  $self->{sequence_ontology_id} = $self->getSequenceOntologyId();

  $self->{dbest_ext_db_rel_id} = $self->getExternalDatabaseRelease();

  my $nameStrings = $self->getNameStrings();

  my  $dbestConnect = $self->getArg('dbestConnect');

  my  ($dbestLogin,$dbestPswd) = $self->getArg('dbestLogin') ? $self->getArg('dbestLogin') : $self->getDbESTLogin();

  $dbestPswd = $self->getArg('dbestPswd') unless $dbestPswd;

  my $estDbh = DBI->connect("$dbestConnect","$dbestLogin","$dbestPswd") || die "Can't connect to database: $DBI::errstr\n";

  my $count;

  if ($self->getArg('update_file')) {
    $count = $self->updateESTsInFile($estDbh);
  }
  else {
    $count = $self->updateAllEST($estDbh,$nameStrings);
  }

  my $sth = $estDbh->prepare("select count(est.id_est) from dbest.est est, dbest.library library where library.id_lib = est.id_lib and library.organism in ($nameStrings)and est.replaced_by is null");
  $sth->execute();
  my ($numDbEST) = $sth->fetchrow_array();

  my $dbh = $self->getQueryHandle();

  my $sth2 = $dbh->prepareAndExecute("select count(e.est_id) from dots.est e, dots.library l, sres.taxonname t where l.taxon_id = t.taxon_id and t.name in ($nameStrings) and t.name_class = 'scientific name' and l.library_id = e.library_id");

  my ($finalNumGus) = $sth2->fetchrow_array();

  my $diff = ($numDbEST-$finalNumGus);

  $self->logAlert("Number id_est for these taxon(s) in dbEST:$numDbEST\nTotal number id_est in dots.EST:$finalNumGus\nDifference dbEST and dots:$diff\n");

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

sub updateESTsInFile {
  my ($self,$estDbh) = @_;

  my $count = 0;

  my $fh = FileHandle->new( "<" . $self->getArg('update_file'))  or
    $self->userError ("Could not open update file ". $self->getArg('update_file') . "\n");

  my $sth = $estDbh->prepare("select * from dbest.est where id_est = ?");
  my $e = {};

  while (!$fh->eof()) {
    chomp;
    $count++;
    last if ($self->getArg('test_number') && $count > $self->getArg('test_number'));
    next if ($self->getArg('restart_number') && $self->getArg('restart_number') > $fh->input_line_number);

    my $eid = $_;
    next unless ($eid);

    $sth->execute($eid);
    my @ests;

    while (my $hsh_ref = $sth->fetchrow_hashref('NAME_lc')) {
      push (@ests, {%$hsh_ref});
    }
    foreach my $est ( @ests) {
      $e->{$est->{id_est}}->{e} = $est;
    }
    if ($count % $self->getArg('span') == 0) {
      $self->processEntries($e,$estDbh);
      $e = {};
      $self->undefPointerCache();
    }
  }
  $self->processEntries($e,$estDbh);
  $self->undefPointerCache();
  return $count;
}


sub updateAllEST {
  my ($self,$estDbh,$nameStrings) = @_;

  my $count = 0;

  my $sth = $estDbh->prepare("select est.* from dbest.est est, dbest.library library where est.id_est > ? and library.id_lib = est.id_lib and library.organism in ($nameStrings) and replaced_by is null order by est.id_est");

  my $min = 0;
  # Set the restart entry id if defined
  $min = $self->getArg('restart_number') ? $self->getArg('restart_number') : $min ;

  $sth->execute($min);

  my $ctRows = 0;
  my $e;
  while (my $hsh_ref = $sth->fetchrow_hashref('NAME_lc')) {
    $ctRows++;
    last if ($self->getArg('test_number') && $ctRows > $self->getArg('test_number'));
    $e->{$hsh_ref->{id_est}}->{e} = $hsh_ref;
    if($ctRows % $self->getArg('span') == 0){
      $count += $self->processEntries($e,$estDbh);
      $self->logAlert("Processed $ctRows ESTs ... last id: $hsh_ref->{id_est}"); 
      undef $e;
    }
  }
  $count += $self->processEntries($e,$estDbh) if $e;
  return $count;
}





sub getNameStrings {
  my ($self) = @_;
  my $nameStrings;
  foreach my $name (keys %{$self->{taxon}}) {
      $name =~ s/'/''/g;   # escape single quotes for oracle
      $nameStrings .= " '$name',";
  }
  $nameStrings =~ s/\,$//;
  return $nameStrings;
}

sub getTaxonIdListFromFile {
  my ($self) = @_;

  my $taxonFile = $self->getArg('taxonFile');

  die "$taxonFile is empty\n" if (-z $taxonFile);

  open (TAXONS, "$taxonFile") or die "Can't open $taxonFile for reading\n";

  my $taxonList;

  while (<TAXONS>) {
    chomp;
    next if $_ =~ /^$/;
    $taxonList = $_;
    $taxonList =~ s/,$//;
    $taxonList .= "," if $taxonList;
    $taxonList .+ $_;
  }

  $taxonList =~ s/,$//;

  print STDOUT "The taxons being processed: Taxon List: $taxonList\n";

  return $taxonList;
}

sub getDbESTLogin {
  my ($self) = @_;

  my $propertiesFile = $self->getArg('dbestLoginFile');

  my @properties = (["dbestLogin",   "",  "login to access dbEST mirror"],["dbestPswd",   "",  "password to access dbEST mirror"]);

  my $propertySet = CBIL::Util::PropertySet->new($propertiesFile, \@properties, 1);

  my $login = $propertySet->getProp('dbestLogin');

  my $pswd = $propertySet->getProp('dbestPswd');

  return ($login,$pswd);
}


sub processEntries {
  my ($self, $e , $estDbh) = @_;
  my $count = 0;
  return $count unless (keys %$e) ;
  $self->getDb()->manageTransaction(0,'begin');
  # get the most recent entry 
  foreach my $id (sort {$a <=> $b} keys %$e) {
    if ($e->{$id}->{e}->{replaced_by}){
      $self->logAlert ("Id being replaced: $id\n");
      my $re =  $self->getMostRecentEntry($e->{$id}->{e}, $estDbh);
      #this entry is bogus, delete from insert hash
      delete $e->{$id};
      #enter the new entry into the insert hash
      $e->{$re->{new}->{id_est}}->{e} = $re->{new};
      $e->{$re->{new}->{id_est}}->{old} = $re->{old};
    }
  }

  # get the sequences only for most current entry
  my $ids = join "," , sort {$a <=> $b} keys %$e;

  my $sth = $estDbh->prepare("select * from dbest.SEQUENCE where id_est in ($ids) order by id_est, local_id");
  $sth->execute();
  my @A;
  while (my $hsh_ref = $sth->fetchrow_hashref('NAME_lc')) {
    push (@A, {%$hsh_ref});
  }
  if (@A) {
    foreach my $s (@A){
	$e->{$s->{id_est}}->{e}->{sequence} .= $s->{data};
    }
  }

  # get the comments, if any
  $ids = join "," , keys %$e;
  $sth = $estDbh->prepare("select * from dbest.CMNT where id_est in ($ids) order by id_est, local_id");
  $sth->execute();
  while (my $hsh_ref = $sth->fetchrow_hashref('NAME_lc')) {
    push (@A, {%$hsh_ref});
  }

  if (@A) {
    foreach my $c (@A){
      $e->{$c->{id_est}}->{e}->{comment} .= $c->{data};
    }
  }
  
  # Now that we have all the information we need, start processing
  # this batch 
  foreach my $id (sort {$a <=> $b} keys %$e) {

    #####################################################################
    # If there are older entries, then we need to go through an update 
    # proceedure of historical entries. Else just insert if not already 
    # present.
    #####################################################################
    if (!$self->getArg('do_not_update') && $e->{$id}->{old} && @{$e->{$id}->{old}} > 0) {
      $count +=  $self->updateEntry($e->{$id},$estDbh);
    }else {
      $count += $self->insertEntry($e->{$id}->{e},$estDbh);
    }
  }
  $self->getDb()->manageTransaction(0,'commit');
  $self->undefPointerCache();
  return $count;
}

=pod 

=head2 updateEntry

Checks whether any of the historical entries are in GUS. Updates the 
Entry as necessary. 

Returns 1 if succesful update or 0 if not.

=cut

sub updateEntry {
  my ($self,$e,$estDbh) = @_;

  #####################################################################
  ## Go through the older entries and determine which is in GUS, if any.
  ## Since there should only be one entry in GUS, it is valid to just 
  ## update the first older entry encountered.
  #####################################################################

  foreach my $oe (@{$e->{old}}) { 
    next unless ($e->{id_est});
    my $est = GUS::Model::DoTS::EST->new({'dbest_id_est' => $e->{id_est}});

    if ($est->retrieveFromDB()) {
      # Entry present in the DB; UPDATE
      return  $self->insertEntry($e->{e},$estDbh,$est);
    }
  }
  ## No historical entries; INSERT if not already present
  return $self->insertEntry($e->{e},$estDbh);
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
  my ($self,$e,$estDbh,$est) = @_;
  my $needsUpdate = 0;
  #####################################################################
  ## Do a full update only if the dbest.id_est is not the same
  ## This is valid since all EST
  #####################################################################
  if ((defined $est) && ($est->getDbestIdEst() != $e->{id_est} )){
    $needsUpdate = 1;
  }else {
    $est = GUS::Model::DoTS::EST->new({'dbest_id_est' => $e->{id_est}});
  }
  
  if (!$self->getArg('do_not_update') && $est->retrieveFromDB()){    
    # The entry exists in GUS. Must check to see if valid
    if ($self->getArg('fullupdate') || $needsUpdate) {
      # Treat this as a new entry
      $self->populateEst($e,$est,$estDbh);
      # check to see if clone information already exists
      # for this EST
      $self->checkCloneInfo($e,$est,$estDbh);
    }
    # else this is already in the DB. Do Nothing.
    
  } else {
    # This is a new entry
    $self->populateEst($e,$est,$estDbh);
    # check to see if clone information already exists
    # for this EST
    $self->checkCloneInfo($e,$est,$estDbh);
  }
  

  #####################################################################
  # Check for an update of the sequence. Change the sequence unless 
  # the no_sequence_update flag is given
  #####################################################################

  my $sequence_ontology_id = $self->{sequence_ontology_id};

  my $seq;
  $seq = $est->getParent('GUS::Model::DoTS::ExternalNASequence',1) unless $self->getArg('do_not_update');

  if ((defined $seq) && $e->{sequence} ne $seq->getSequence()){
    if (! $self->getArg('no_sequence_update')) {
      $seq->setSequence($e->{sequence});
      # set the ExtDBId to dbEST if not already so.
      #$seq->setExternalDatabaseReleaseId( $DBEST_EXTDB_ID);
      # log the change of sequence
      $self->{'log_fh'}->print($self->logAlert('WARN: SEQ_UPDATE:', $seq->getId(),'\n'));
      $self->logAlert('WARN: SEQ_UPDATE:', $seq->getId(),'\n');
    } else {

      #####################################################################
      # There is a conflict, but the 'no_sequence_update' flag given
      # Output a message to the log
      #####################################################################

      $self->{'log_fh'}->print($self->logAlert('WARN: SEQ_NO_UPDATE: NA_SEQUENCE_ID=' , $seq->getId(), " DBEST_ID_EST=$e->{id_est}\n"));
      $self->logAlert('WARN: SEQ_NO_UPDATE: NA_SEQUENCE_ID=' , $seq->getId(), " DBEST_ID_EST=$e->{id_est}\n");
    }
  }else {
    #####################################################################
    ## This sequence entry does no0t exist. We must make it. 
    #####################################################################

    $seq = GUS::Model::DoTS::ExternalNASequence->new({'source_id' => $e->{gb_uid}, 'sequence_version' => 1, 'external_database_release_id' => $self->{dbest_ext_db_rel_id}});
    $self->checkExtNASeq($e,$seq,$sequence_ontology_id);
    $est->setParent($seq);
  }
  
  ## Add the clone entry (if there is one) to the submit list
  my $clone = $est->getParent('GUS::Model::DoTS::Clone');
  if ($clone) { $seq->addToSubmitList($clone); }
  
  # submit the sequence and EST entry. Return the submit() result.
  my $result = $seq->submit(0,1);

  my $naSeqId = $seq->getId();

  $self->logData("na_sequence_id\t$naSeqId")if $self->getArg('logNaSeqId');

#  if ($result) {
#    $self->{'log_fh'}->print($self->logAlert('INSERT/UPDATE', $e->{id_est}),"\n");
#  }
  return $result;
}

sub getSequenceOntologyId {
  my ($self) = @_;

  my $name = "EST";

  my $extDbRlsSpec = $self->getArg('SOExtDbRlsSpec');
  my $extDbRlsId = $self->getExtDbRlsId($extDbRlsSpec);
      
  my $sequenceOntology = GUS::Model::SRes::OntologyTerm->new({"name" => $name, "EXTERNAL_DATABASE_RELEASE_ID" => $extDbRlsId});

  $sequenceOntology->retrieveFromDB() || $self->error ("Unable to obtain ontology_term_id from sres.ontologyterm with term_name = EST");

  my $sequence_ontology_id = $sequenceOntology->getId();

  return $sequence_ontology_id;
}

sub getExtDbRlsVerFromExtDbRlsName {
  my ($self, $extDbRlsName) = @_;

  my $dbh = $self->getQueryHandle();

  my $sql = "select version from sres.externaldatabaserelease edr, sres.externaldatabase ed
             where ed.name = '$extDbRlsName'
             and edr.external_database_id = ed.external_database_id";
  my $stmt = $dbh->prepareAndExecute($sql);
  my @verArray;

  while ( my($version) = $stmt->fetchrow_array()) {
      push @verArray, $version;
  }

  die "No ExtDbRlsVer found for '$extDbRlsName'" unless(scalar(@verArray) > 0);

  die "trying to find unique ext db version for '$extDbRlsName', but more than one found" if(scalar(@verArray) > 1);

  return @verArray[0];

}

sub getExternalDatabaseRelease{

  my ($self) = @_;
  my $name = $self->getArg('extDbName');
  if (! $name) {
    $name = 'dbEST';
  }

  my $externalDatabase = GUS::Model::SRes::ExternalDatabase->new({"name" => $name});
  $externalDatabase->retrieveFromDB();

  if (! $externalDatabase->getExternalDatabaseId()) {
    $externalDatabase->submit();
  }
  my $external_db_id = $externalDatabase->getExternalDatabaseId();

  my $version = $self->getArg('extDbRlsVer');
  if (! $version) {
    $version = 'continuous';
  }

  my $externalDatabaseRel = GUS::Model::SRes::ExternalDatabaseRelease->new ({'external_database_id'=>$external_db_id,'version'=>$version});

  $externalDatabaseRel->retrieveFromDB();

  if (! $externalDatabaseRel->getExternalDatabaseReleaseId()) {
    $externalDatabaseRel->submit();
  }
  my $external_db_rel_id = $externalDatabaseRel->getExternalDatabaseReleaseId();
  return $external_db_rel_id;

}


=pod 

=head2 populateEST 

This is a doozy of a method that populate all the various parts of an EST, 
entry, including library, contact and sequence information. It also makes calls 
to other methods that parse fields for clone information and other columns.

No return value.

=cut

sub populateEst {
  my ($self,$e,$est,$estDbh) = @_;
  
  #parse the comment for hard to find information
  $self->parseEntry($e);
  
  ## Mapping to dots.EST columns
  my %atthash = ('id_est' => 'dbest_id_est',
                 'id_gi'         => 'g_id'             ,
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
  foreach my $a (keys %atthash) {
    my $att = $atthash{$a};
    if ( $est->isValidAttribute($att)) {
      my $method = 'set';
      $method .= ucfirst $att;
      $method =~s/\_(\w)/uc $1/ge;
      $est->$method($e->{$a});
    }
  }
  
  # Set the contact from the contact hash
  if ($self->{contact}->{$e->{id_contact}}){
    $est->setContactId($self->{contact}->{$e->{id_contact}});
  }else {
    # get from DB and cache
    # ONLY NEED SOURCE_ID HERE BECAUSE ID_CONTACT_ID IS DISTINCT ACCROSS DBEST
    my $c = GUS::Model::SRes::Contact->new({ 'source_id' => $e->{id_contact} });

    unless ($c->retrieveFromDB()) {
      $self->newContact($e,$c,$estDbh);
    }
    # Add to cache
    $self->{contact}->{$c->getSourceId()} = $c->getId();
    # Set the parent-child relationship
    $est->setParent($c);
  }

  # Set the library information
  if (exists $self->{libs}->{$e->{id_lib}}){
    $est->setLibraryId($self->{libs}->{$e->{id_lib}}->{dots_lib});
  }else {
    # get from DB and cache
    my $l = GUS::Model::DoTS::Library->new({'dbest_id' => $e->{id_lib},
                                           });
    unless ($l->retrieveFromDB()) {
      $self->newLibrary($e,$l,$estDbh);
    }
    # Add to cache
    $self->{libs}->{$l->getDbestId()}->{dots_lib} = $l->getId();
    $self->{libs}->{$l->getDbestId()}->{taxon} = $l->getTaxonId();    
    # set parent-child relationship
    $est->setParent($l);
  }
  $self;
}

=pod

=head2 checkCloneInfo

Checks a dbEST entry for presence of reliable clone 
information. If the EST comes from either WashU or the 
IMAGE Consortium, then the entry is processed.

=cut

sub checkCloneInfo {
  my ($self,$e,$est,$estDbh) = @_;

  my $c = $est->getParent("GUS::Model::DoTS::Clone",1);
  unless (defined $c) {
    $c =  GUS::Model::DoTS::Clone->new();
    if ($e->{is_image}) {
      $c->setImageId($e->{image_id});
    }
    elsif ($e->{washu_name}) {
      $c->setWashuName($e->{washu_name});
    }
    $est->setParent($c);
  }
  $self->updateClone($e,$c,$estDbh);  
}

=pod

=head2 updateClone

Populates the attributes of a new clone from a dbEST EST entry.
It only makes sense to do this if the EST came from 
WashU or the IMAGE Consortium, but these test have 
already been done by this point.

=cut

sub updateClone {
  my ($self, $e, $c,$estDbh) = @_;
  # Check the clone for updated attributes
  my %atthash = ('id_est' => 'dbest_id_est',
                 'id_gi'         => 'g_id'             ,
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
    my $att = $atthash{$a};
    if ( $c->isValidAttribute($att)) {
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
  unless  (exists $self->{libs}->{$e->{id_lib}}->{dots_lib}){
    # get from DB and cache
    my $l = GUS::Model::DoTS::Library->new({ 'dbest_id' => $e->{id_lib} });
    unless ($l->retrieveFromDB()) {
      $self->newLibrary($e,$l,$estDbh);
    }

    # Add to cache
    $self->{libs}->{$l->getDbestId()}->{dots_lib} = $l->getDbestId();
    $self->{libs}->{$l->getDbestId()}->{taxon} = $l->getTaxonId(); 
  }

  if ($e->{is_image} && !$self->{libs}->{$e->{id_lib}}->{is_image}) { 
    my $l = GUS::Model::DoTS::Library->new({'dbest_id' => $e->{id_lib}});
    $l->retrieveFromDB();
    $l->setIsImage(1);
    $l->submit(0,1);
   $self->{libs}->{$e->{id_lib}}->{is_image} = 1;
  }

  if ($c->getLibraryId() ne $self->{libs}->{$e->{id_lib}}->{dots_lib}){
    $c->setLibraryId($self->{libs}->{$e->{id_lib}}->{dots_lib});
  }

  $self;
}

=pod

=head2 getMostRecentEntry

Gets the most recent EST entry from dbEST. Shoves all older entries into

an array to check for in GUS.

Returns HASHREF{ new => newest entry,
                 old => array of all older entries,
               }

=cut

sub getMostRecentEntry {
  my ($self,$e,$estDbh,$R) = @_;
  $R->{new} = $e;

  my $sth = $estDbh->prepare("select * from dbest.est where id_est = $e->{replaced_by}");
  $sth->execute();
  my $re;

  my $re = $sth->fetchrow_hashref('NAME_lc');
  $sth->finish();
  #my $re = $self->sql_get_as_hash_refs_lc("select * from dbest.est$self->{dblink} where id_est = $e->{replaced_by}")->[0];
  # saved this line in case needed
  # angel:2/20/2003: Found that sometimes replaced_by points to non-existent id_est
  # Account for this by inserting the most recent & *valid* entry and
  # log the id_est of the entry that eventually needs an update

  if ($re) {
    print STDERR "Recent Entry=$re->{id_est};\n" ;
    $R->{new} = $re;
    push @{$R->{old}}, $e;
    if ($re->{replaced_by} ) {
      $R = $self->getMostRecentEntry($re,$estDbh,$R);
    }
  }else {
    $self->{'log_fh'}->print($self->logAlert("ERR:BOGUS REPLACED BY","ID_EST", $e->{id_est}, "REPLACED_BY=$e->{replaced_by}","\n"));
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
  my ($self,$e) = @_;

  ## Parse for WashU atts

  if (($e->{comment} =~ /Washington University Genome Sequencing
Center/i) || ( $e->{est_uid} =~ /([\w\-]+)\.[a-z]\d/)) {
    # probably a washu_id
    $e->{est_uid} =~ /([\w\-]+)\.\w{2}/;
    my $wname = $1;
    unless ($wname =~ /[\.\s]/) {
      $e->{washu_id} = $e->{est_uid};
      $e->{washu_name} = $1;
    }
  }

  
  
  #if (length ($e->{washu_id}) > 15) {
  #  $e->{washu_id} = undef;
  #  print STDOUT "dbest_id_est : $e->{id_est} \n";
  #}
	
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
  my ($self) = @_;
  
  # Library cache
  my $q = 'select dbest_id as dbest_lib_id, library_id, taxon_id, is_image from dots.Library';
  my $A = $self->sql_get_as_array_refs($q);
  foreach my $r (@$A) {
    $self->{libs}->{$r->[0]}->{dots_lib} = $r->[1];
    $self->{libs}->{$r->[0]}->{taxon} = $r->[2];
    $self->{libs}->{$r->[0]}->{is_image} = $r->[3];
  }
  
  # Contact info, get entries only from dbEST
  $q = qq[select contact_id, source_id
          from sres.contact
          where source_id is not null
          ];

  $A = $self->sql_get_as_array_refs($q);
  foreach my $r (@$A) {
    $self->{contact}->{$r->[1]} = $r->[0];
  }

  # Anatomy cache is on-demand

  # Taxon cache
  # changed to get all organism names for human and mouse
  # all else is on-demand cache

  my $taxon_id_list = $self->getArg('taxon_id_list');

  my $taxonIds = join(',',@$taxon_id_list) if $taxon_id_list;

  $taxonIds = $self->getTaxonIdListFromFile()  if (! $taxonIds && $self->getArg('taxonFile'));

  if (! $taxonIds) {
    my $ncbi_tax_id = $self->getArg('ncbiTaxId');
    my $ncbiTaxId = join(',',@$ncbi_tax_id);
    die "Supply taxon_id_list or ncbiTaxId list\n" unless $ncbiTaxId;
    my $dbh = $self->getQueryHandle();
    my $qTaxon = "select taxon_id from sres.taxon  where ncbi_tax_id in ($ncbiTaxId)";
    my $st = $dbh->prepareAndExecute($qTaxon);
    my @taxon_id_array;
    while (my ($taxon) = $st->fetchrow_array()) {
      push (@taxon_id_array,$taxon);
    }
    $st->finish();
    $taxonIds = join(',', @taxon_id_array);
  }

  $self->{taxon_id_list} = $taxonIds;

  $q = "select name, taxon_id  from sres.TaxonName where taxon_id in ($taxonIds)";

  $A = $self->sql_get_as_array_refs($q);
  foreach my $r (@$A) {
    $self->{taxon}->{$r->[0]} = $r->[1];
  }
}

=pod

=head2 newLibrary

Populates the attributes for a new DoTS.Library entry from dbEST.

=cut

sub newLibrary {
  my ($self,$e,$l,$estDbh) = @_;

  my $sth = $estDbh->prepare("select id_lib,name,organism,strain,cultivar,sex,organ,tissue_type,cell_type,cell_line,dev_stage,lab_host,vector,v_type,re_1,re_2 from dbest.library where id_lib = $e->{id_lib}");
  $sth->execute();

  my $dbest_lib = $sth->fetchrow_hashref('NAME_lc');

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

  ##truncate tissue_type to fit 

  $dbest_lib->{'tissue_type'} = substr($dbest_lib->{'tissue_type'},0,99);

  $dbest_lib->{'name'} = substr($dbest_lib->{'name'},0,119);

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
  if ($self->{taxon}->{$dbest_lib->{organism}}) {
    $l->setTaxonId($self->{taxon}->{$dbest_lib->{organism}});
  } 
  #else {
  # my $taxon = GUS::Model::SRes::TaxonName->new({'name' => $dbest_lib->{organism}});
  # if ($taxon->retrieveFromDB()){
  #   $self->{taxon}->{$dbest_lib->{organism}} = $taxon->getTaxonId();
  #   $l->setTaxonId($taxon->getTaxonId());
  # }
  else{
    my $dbh = $self->getQueryHandle();
    my $name = $dbest_lib->{organism};
    my $st = $dbh->prepareAndExecute("select taxon_id from sres.taxonname where name = '$name'");
    my $taxon_id = $st->fetchrow_array();
    $st->finish();
    if ($taxon_id) {
      $self->{taxon}->{$dbest_lib->{organism}} = $taxon_id;
      $l->setTaxonId($self->{taxon}->{$dbest_lib->{organism}});
    }
    else {
      #Log the fact that we couldn't parse out a taxon
      $self->logAlert('ERR:NEW LIBRARY: TAXON', ' LIB_ID:',  $l->getId(), ' DBEST_ID:',
		   $l->getDbestId(), ' ORGANISM:', $dbest_lib->{organism});
    }
  }
  
  
  ## parse out the anatomy of the library entry
  if ($self->{anat}->{$dbest_lib->{organ}}) {
    $l->setAnatomyId($self->{anat}->{$dbest_lib->{organ}});
  } else {

    my $anat = GUS::Model::SRes::OntologyTerm->new({'name' => $dbest_lib->{organ}});
    
    if(my $anatomyExtDbRlsSpec = $self->getArg('anatomyExtDbRlsSpec')) {
      my $anatomyExtDbRlsId = $self->getExtDbRlsId($anatomyExtDbRlsSpec); 
      $anat->setExternalDatabaseReleaseId($anatomyExtDbRlsId);
    }

    if ($anat->retrieveFromDB()){
      $self->{anat}->{$dbest_lib->{organ}} = $anat->getId();
      $l->setAnatomyId($anat->getId());
    }else {
      #Log the fact that we couldn't parse out an anatomy
      $self->logAlert('ERR: NEW LIBRARY: ANATOMY', ' LIB_ID:',  $l->getId(), ' DBEST_ID:',
              $l->getDbestId(), ' ORGAN:', $dbest_lib->{organ},"\n");
    }
  }
  
  ## Check to see whether this is an IMAGE library via EST entry
  if ($e->{is_image}) {
    $l->setIsImage(1);
  } else {
    $l->setIsImage(0);
  }

  ## Submit the new library
  $l->submit(0,1);
  # return
  $self;
}

=pod

=head2 newContact

Populate the attributes of a new SRes.Contact entry

=cut

  

sub newContact {
  my ($self,$e,$c,$estDbh)  = @_;

  my $sth = $estDbh->prepare("select * from dbest.contact where id_contact = $e->{id_contact}");

  $sth->execute();

  my $C = $sth->fetchrow_hashref('NAME_lc');

  $sth->finish();

  $C->{lab} = $C->{lab} ? "$C->{lab}; $C->{institution}":"$C->{institution}";

  my %atthash = ('id_contact' => 'source_id',
                 'name' => 'last',
                 'lab' => 'address1',
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
  #$c->setExternalDatabaseReleaseId($DBEST_EXTDB_ID);
  # submit the new contact to the DB
  $c->submit(0,1);
  $self;
}

=pod 

=head2 checkExtNASeq

Method that checks the attributes of a sequence entry and updates it as
necessary to reflect the EST entry. This is only if the C<no_sequence_update>
is not given.

=cut

sub checkExtNASeq {
  my ($self,$e,$seq,$sequence_ontology_id) = @_;

  my %seq_vals = ( 'taxon_id' => $self->{libs}->{$e->{id_lib}}->{taxon},
                   'sequence' => $e->{sequence},
                   'length' => length $e->{sequence},
                   'sequence_ontology_id' =>  $sequence_ontology_id,
                   'a_count' => (scalar($e->{sequence} =~ s/A/A/g)) || 0,
                   't_count' => (scalar($e->{sequence} =~ s/T/T/g)) || 0,
                   'c_count' => (scalar($e->{sequence} =~ s/C/C/g)) || 0,
                   'g_count' => (scalar($e->{sequence} =~ s/G/G/g)) || 0,
      # contains sequence - unneeded and fails with some db configurations  'description' => substr($e->{comment},0,1999)
                   );
  foreach my $a (keys %seq_vals) {
    if ( $seq->isValidAttribute($a)) {
      my $getmethod = 'get';
      my $setmethod = 'set';
      $setmethod .= ucfirst $a;
      $setmethod =~s/\_(\w)/uc $1/ge;
      $getmethod .= ucfirst $a;
      $getmethod =~s/\_(\w)/uc $1/ge;
      if ($seq->$getmethod() ne $seq_vals{$a}) {
        if ( $self->getArg('no_sequence_update')) {
          # Log an entry 
          $self->logAlert("WARN:", "ExternalNaSequence.$a not updated", $e->{id_est},"\n");
        } else {
          $seq->$setmethod($seq_vals{$a});
        }
      }
    }
  }
}


sub undoTables {
  my ($self) = @_;

  return ('DoTS.EST',
	  'DoTS.Clone',
	  'DoTS.Library',
	  'DoTS.NASequenceImp',
	  'SRes.ExternalDatabaseRelease',
	 );
}


1;

__END__
