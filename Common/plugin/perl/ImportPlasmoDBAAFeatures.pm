package GUS::Common::Plugin::ImportPlasmoDBAAFeatures;
# $Id$ 

@ISA = qw(GUS::PluginMgr::Plugin);

use strict;

use GUS::Model::Core::Algorithm;     #
use GUS::Model::Core::ProjectInfo;   #
use GUS::Model::DoTS::GeneFeature;   #
use GUS::Model::DoTS::RNAFeature;    #
use GUS::Model::DoTS::AALocation;    #
use GUS::Model::DoTS::TranslatedAASequence;   #
use GUS::Model::DoTS::PredictedAAFeature;     #
use GUS::Model::DoTS::PfamEntry;              #
use GUS::Model::DoTS::SignalPeptideFeature;   #
#use GUS::Model::DoTS::PlasmoAPFeature;        #<<<<<<<<  No Object
use GUS::Model::DoTS::ExonFeature;            #
use GUS::Model::DoTS::ExternalAASequence;     #
use GUS::Model::DoTS::ExternalNASequence;     #
use GUS::Model::DoTS::NAFeatureComment;       #
use GUS::Model::DoTS::NALocation;             #
use GUS::Model::DoTS::ProjectLink;            #
use GUS::Model::SRes::ExternalDatabase;       #
use GUS::Model::SRes::ExternalDatabaseRelease;#
use GUS::Common::Sequence;
use GUS::Model::DoTS::TranslatedAAFeature;    #


sub new {
  my $class = shift;
  my $self = {};
  my $usage = 'loads PlasmoDB amino acid features in an -sad to say - as of yet unspecified tab delimited format (will migrate to GFF)...';
  
  my $easycsp =
    [
     {
      h => 'Pfam release, e.g. 8.0',
      t => 'string',
      o => 'pfamRel',
      d => '8.0',
     },
     {
      h => 'project name',
      t => 'string',
      o => 'project',
      d => 'PlasmodiumDB-4.1',
     },
     {
      t => 'int',
      o => 'testnumber',
      h => 'Number of iterations for testing',
     },
     {
      t => 'string',
      o => 'restart',
      h => 'For restarting script...takes list of row_alg_invocation_ids to exclude',
     },
     {
      t => 'string',
      o => 'filename',
      h => 'Name of file(s) containing the predicted aa features',
     },
     {
      o => 'projectId',
      t => 'int',
      h => 'project_id of this release, default 900',
      d => 900,
     },
     {
      t => 'boolean',
      o => 'reload',
      h => 'For loading new Ids and scores for -up to now only- HmmPfam entries',
      d => 0
     },
     {
      t => 'boolean',
      o => 'commit',
      h => 'Set flag to commit changes to database. Default: off',
      d => 0,
     },
     {

      t => 'int',
      o => 'extDbRelId',
      h => 'Sets the External Database Release Id, default 151',
      d => 151,
     }
    ];

  bless($self, $class);
  $self->initialize({requiredDbVersion => {},
		     cvsRevision => '$Revision$ ', # keyword filled in by cvs
		     cvsTag => '$Name$ ',             # keyword filled in by cvs
		     name => ref($self),
		     revisionNotes => 'first pass of plugin for GUS 3.0',
		     easyCspOptions => $easycsp,
		     usage => $usage
		    }); 
  return $self;
}


#----------------------------------------------------------
# Set some global Variables:
#----------------------------------------------------------
my $Version;
my $seq_source_id = "";;
my $seq_description = "";
my %finished;
my $countInserts = 0;
my %counter =();
my $verbose = 1;
my $algId;
my %alg_id=(
	    'TOPPRED2'    => '306',
	    'SignalP'     => '305',
	    'PATMATMOTIFS'=> '304',
	    'HMMPFAM'     => '303',
	    'TMAP'        => '302',
	    'TMPRED'      => '301',
	    'TMHMM2'      => '7392',
	    'PlasmoAP'    => '7391'
           );


##########
###
### RUN
###
#########


sub run {
  my $self = shift;

  $self->logRAIID;
  $self->logCommit;
  $self->logArgs;


  $self->log( $self->getArgs()->{'commit'} ? "COMMIT ON\n" : "COMMIT TURNED OFF\n" );
  $self->log( "Testing on ". $self->getArgs()->{'testnumber'}. "\n") if $self->getArgs()->{'testnumber'} ;


  my $project_id=$self->getArgs()->{'projectId'};
  my $aa_sequence_id;
  my $external_database_release_id = $self->getArgs()->{'extDbRelId'} ||  $self->log("external_database_release_id not supplied") && die ("Aborting");

  $self->log("\n\nPlease specify the project_id, e.g. with --projectId=900\n") && return 0 
    unless (length($project_id));
  $self->log("\n\nPlease specify the external_db_release_id, e.g. with --extDbRelId=151\n") && return 0 
    unless (length($external_database_release_id));

  #
  # make sure the input file is provided
  #

   $self->log("Please specify name of the input file") && return 0 unless $self->getArgs()->{'filename'};
  unless (-e $self->getArgs()->{'filename'}) {
     $self->log( "You must provide a valid tab delimited file on the command line") && return 0;
  }
   $self->log("Using filename ".  $self->getArgs()->{'filename'} . "\n") if $verbose;  #my own verbose


#  #get the queryhandle only once
#  my $dbh = $self->getQueryHandle;
  my $parsed;
  if ($self->setAlgId("GUS::Common::Plugin::ImportPlasmoDBAAFeatures")) {
    $parsed = $self->parseFile($self->getArgs()->{'filename'});
  }
  return $parsed;
}



####################################################
## Parses input files into appropriate variables
## and then calls subroutine 'process' to insert values
####################################################
sub parseFile {
  my $self=shift;
  my $file=shift;

  open(F,"<$file") ||   $self->log("Could not open $file : $!\n") && die ("Aborting");

  my $aa_sequence_id;
  my $seq;
  while (<F>) {
	chomp;
	#
	# skip comments and blank lines, shouldn't be in there anyway
	#
	next if ( (/^\s*\#/) || (/^\s+$/) );
	#$self->log($_ ."\n") if $self->getArgs()->{'$debug'};
	$self->log($_ . "\n") if $verbose;

	my @tmp = split(/\t/,$_);	
	if ($tmp[2] eq 'AA_sequence') {
	    $counter{'sequence'}++;
	
	    if ($verbose){
	    #if ($self->getArgs()->{'verbose'}) {
		$self->log("$tmp[2] $tmp[0] with UID $tmp[1] is the " . $counter{'sequence'} . ". sequence\n");
	    }
	
	    # if testnumber is reached then exit out of loop.
	
	    last if (($self->getArgs()->{'testnumber'}) && ($counter{'sequence'} >= ($self->getArgs()->{'testnumber'})));
	    $self->log("Processing peptide ". $counter{'sequence'} . " on " . `date`) if $verbose;
	
	    if ($seq) {
		#submit data of previous entry if $seq  exists
		$seq->submit();
		##following allows garbage collection...
		$self->undefPointerCache();
		#undef $seq;
	    }

	    ($seq,$aa_sequence_id) = $self->get_object(@tmp);
	    next unless ($seq);
	
	  } else {
	    # if it is not an AA_sequence entry it must be a motif for the sequence
	    # but if there has been an error while retrieving the sequence, there will be not object $seq
	    # therefore skip until $seq defined (next AA_sequence entry)	
	
	    $self->process($seq,$aa_sequence_id,@tmp) if $seq;
	  }
      } # end while LOOP

    $self->log("submitting ". $counter{'sequence'} . ". sequence\n") if $verbose;
    $seq->submit() if $seq;
    # to submit last sequence


    #
    # generate summary
    #

    my $results= "Run finished: Processed ". $counter{'sequence'}." peptides\n";
    foreach my $key (keys %counter) {
	$results .= $counter{$key} . " $key features\n";
    }

    $self->log("\n" . $results . "\n\n");

} # end run





############################################################
#              S  u  b  r  o  u  t  i  n  e  s
############################################################

############################################################
# Query to retrieve Object from database (eg if no GUS ID available)
############################################################
sub get_object{
  my $self=shift;
  my @tmp=@_;
  my $seq;
  my $aa_sequence_id;
  my $projectId=$self->getArgs()->{'projectId'};
  my $extDbRelId=$self->getArgs()->{'extDbRelId'};
    if ($tmp[1]=~m/^(\d+)/) {
	my $id=$1; 
	$seq = TranslatedAASequence->new({'aa_sequence_id' => $id});
	$self->log("II Found UID $id ") if $verbose; # if $self->getArgs()->{'verbose'};

    } else {
	## if no GUS UID exists query the database with the source_id
	## which is stored as the first value on the tab-delimited line
	
	my $key=$tmp[0];
	$key=~s/\.pep$//;
	$self->log("II No UID found. Querying DB for source_id $key...") if $verbose; # if $self->getArgs()->{'verbose'};

	#retrieve the sequence_id to which the features will be linked
	#prepare connection to DB
	
	my $dbh = $self->getQueryHandle();
	
	my $query="select tas.*
from  dots.genefeature gf, dots.rnafeature rnaf, dots.translatedaafeature taf, dots.translatedaasequence tas
where  gf.external_database_release_id = $extDbRelId
and  rnaf.parent_id = gf.na_feature_id
and  rnaf.na_feature_id = taf.na_feature_id
and  taf.aa_sequence_id = tas.aa_sequence_id
and  gf.source_id=\'$key\'";

#	my $query="select tas.*
#from  dots.genefeature gf, dots.projectlink pl, dots.rnafeature rnaf, dots.translatedaafeature taf, dots.translatedaasequence tas
#where  gf.na_feature_id = pl.id
#and  pl.table_id = 108
#and  pl.project_id = $projectId
#and  rnaf.parent_id = gf.na_feature_id
#and  rnaf.na_feature_id = taf.na_feature_id
#and  taf.aa_sequence_id = tas.aa_sequence_id
#and  gf.source_id=\'$key\'";

	$self->log($query) if $verbose; #if $self->getArgs()->{'verbose'};


	my $stmt = $dbh->prepare($query);

	##execute statement
	$stmt->execute();
	
	my $countRows = 0;
	while (my $row = $stmt->fetchrow_hashref('NAME_lc')) {
	    $seq = GUS::Model::DoTS::TranslatedAASequence->new($row);
	    $aa_sequence_id = $$row{'aa_sequence_id'};
	    $countRows++;
	}

	### SOME DEBUG STUFF
	if ($countRows>1) {
	    $self->log("EE SQL returned $countRows for $key !");
	    return 0;
	} elsif ($countRows<1) {
	    $self->log("EE Query for AA object ($key) No Rows returned !!");
	    return 0;
	} elsif ($countRows==1) {
	    $self->log("II aa_sequence_id for $key is $aa_sequence_id") if $verbose;
	    $self->setAaSeqId("$aa_sequence_id");
	    return ($seq,$aa_sequence_id);
	}
    }
}  # end sub



#####MMMMMM

sub setAaSeqId{
  my $self=shift;
  my $AaSeqId=shift;
  $self->log("II Setting AaSeqId to $AaSeqId") if $verbose;
  $self->{'AaSeqId'}=$AaSeqId;
}
sub getAaSeqId{
  my $self=shift;
  return $self->{'AaSeqId'};
}


##########################
## Throws error on STDERR
##########################
sub error{
  my $errcode=shift;
  my $errtxt=shift;
  print STDERR "###########################################\n";
  print STDERR $errtxt ."\n\n";
  print STDERR "\n\ngoing on to next sequence\n\n";
  print STDERR "and deleting PointerCache\n";
  print STDERR "###########################################\n";
}


####################################################
## Parses input files into appropriate variables
## and then calls subroutines to check/insert values
####################################################
sub process {
  my $self=shift;
  my($seq,$aa_sequence_id,@tmp) = @_;

  if (!$seq) {
    $self->log("EE sequence object does not exist");
    die ("Aborting...");
  }

  #
  # Set the fields that we need.
  #
  my $source_id = $tmp[0];
  $source_id=~s/\.pep$//;       #in case it is still there
  my $alg_name = $tmp[1];



  if ($verbose && $source_id) {
    $self->log("II source_id is $source_id");
    $self->log("II alg_name is $alg_name");
  }


  ## WILL HAVE TO CHANGE THAT TO A GFF FORMAT INPUT, 
  ## SO I CAN GET RID OF THE ELSIF LOOPS

  ##################
  ## SignalpNN
  ##################
  if ($alg_name eq "SignalP") {
    my $feature = $self->createNewSignalPeptideFeature(@tmp);

    if ($feature) {
	$seq->addChild($feature);
	$counter{'signal'}++;
    } else {
	$self->log("EE Unable to create PredictedAAFeature SIGNAL for $source_id $alg_name");
	$counter{'unprocessed_signal'}++;
    }
  } # end SIGNALP
  
  

  ##################
  ## SignalPHMM
  ##################
  if ($alg_name=~m/SignalPHMM/i) {
      my $feature = $self->UpdateSignalPeptideHMMFeature(@tmp);

      if ($feature) {
	  $seq->addChild($feature);
	  $counter{'signalhmm'}++;
      } else {
	  $self->log("EE Unable to create PredictedAAFeature SignalPHMM for $source_id $alg_name");
	  $counter{'unprocessed_Signalphmm'}++;
      }
  } # end SIGNALP


  ##################
  ## PlasmoAP
  ##################
  elsif (0 && $alg_name=~m/PlasmoAP/i) {

      my ($file,$algorithm,$lengthA,$cutoffA,$lengthB,$cutoffB,$lengthC,
	  $minimumKN,$maxGap,$cutoffC,$lengthD,$cutoffD,$valueA,$valueB,
	  $valueC,$valueD,$A_ok,$B_ok,$C_ok,$D_ok,$APloc)  =  @tmp;

      my $feature = $self->createNewPredictedTransitPeptide($aa_sequence_id,@tmp);

      if ($feature) {
	  $seq->addChild($feature);
	  $counter{'plasmoap'}++;
    } else {
	$self->log("EE Unable to create PredictedAAFeature PlasmoAP for $source_id $alg_name");
	$counter{'unprocessed_PlasmoAP'}++;
    }
  }  # END PlasmoAP


  ##################
  ## TMPRED
  ##################
  elsif ($alg_name eq "TMPRED") {
 
    my ($file,$algorithm,$featuretype,$score,$start,$stop,$center,
	$orientation,$helix_min_len,$helix_max_len) = @tmp;

    my $feature = $self->createNewPredictedAAFeature($source_id, 'transmembrane region',
                                               $alg_name, 'TMhelix' , $score, $start, $stop);
 
    if ($feature) {
	$seq->addChild($feature);
	$counter{'tmpred'}++;
    } else {
	$self->log("EE Unable to create PredictedAAFeature Tmpred for $source_id $alg_name");
	$counter{'unprocessed_Tmpred'}++;
    }

  }    # END TMPRED

  ##################
  ## TMHMM2
  ##################
  elsif ($alg_name=~/TMHMM2/) {

    my ($file,$algorithm,$featuretype,$start,$stop,undef,undef,undef)=@tmp;
    $algorithm=~s/\.\d+$//; #remove trailing .0

    my $feature = $self->createNewPredictedAAFeature($file, 'transmembrane region',
                                               $algorithm, 'TMhelix', '', $start, $stop);

    if ($feature) {
      $seq->addChild($feature);
      $counter{'tmhmm'}++;
    } else {
      $self->log("EE Unable to create PredictedAAFeature TmHmm for $source_id $alg_name");
      $counter{'unprocessed_Tmhmm'}++;
}

  }  # END TMHMM2




  ##################
  ## TOPPRED2
  ##################
  elsif ($alg_name eq "TOPPRED2") {

    my ($file,$algorithm,$featuretype,$helix_num,$helix_begin,$helix_end,
	$helix_score,$helix_certainity,$hydrophob_file,$cyt_ext_file,
	$org_type,$charge_pair,$full_wdw,$core_wdw,$num_res,$crit_len,
	$upcandcutoff,$lowcandcutoff)   =   @tmp;

    my $feature = $self->createNewPredictedAAFeature($source_id, 'transmembrane region',
                                               $alg_name, 'TMhelix', $helix_score, $helix_begin, $helix_end);

    if ($feature) {

      $seq->addChild($feature);
      $counter{'toppred'}++;
    } else {
      print STDERR "ERROR: Unable to create PredictedAAFeature TOPPRED for $source_id $alg_name\n\n";
      $counter{'unprocessed_Toppred'}++;
    }
  }  # END TOPPRED



  ##################
  ## TMAP
  ##################

  elsif ($alg_name eq "TMAP") {

    my ($file,$algorithm,$featuretype,$start,$stop,$tmap_helix_len) = @tmp;

    my $feature = $self->createNewPredictedAAFeature($source_id,'transmembrane region',
                                               $alg_name, 'TMhelix', '', $start, $stop); 
    ### Note that there is no score available

    if ($feature) {
      $seq->addChild($feature);
      $counter{'tmap'}++;
    } else {
      $self->log("EE Unable to create PredictedAAFeature TMAP for $source_id $alg_name");
      $counter{'unprocessed_Tmap'}++; 
  }
} # END TMAP


  ##################
  ## PFSCAN
  ##################
  elsif ($alg_name eq "PFSCAN") {
	 
    my ($file,$algorithm,$featuretype,$database,$score1,$score2,$start,$stop,$donknow1,$donknow2,$PSID,$PSABBR,$PS_TITLE)=@tmp;
    my $feature = $self->createNewPredictedAAFeature($source_id, "PROSITE motif $PSID, accession $PS_TITLE",
                                               $alg_name, 'PROSITE motif', $score1, $start, $stop);

    if ($feature) {
      $seq->addChild($feature);
      $counter{'pfscan'}++;
    } else {
      $self->log("EE Unable to create PredictedAAFeature PFSCAN for $source_id $alg_name");
      $counter{'unprocessed_Pfscan'}++;
    }
  } #END PFSCAN

  ##################
  ## Patmatmotifs
  ##################
  elsif ($alg_name=~/PATMATMOTIF/) {

    my ($file,$algorithm,$featuretype,$database,$start,$stop,$PSID,$PSACC)=@tmp;
    my $feature = $self->createNewPredictedAAFeature($source_id, "PROSITE motif $PSID, accession $PSACC",
                                               "PATMATMOTIFS", 'PROSITE motif', '0', $start, $stop);

    if ($feature) {
      $seq->addChild($feature);
      $counter{'patmat'}++;
    } else {
      $self->log("EE Unable to create PredictedAAFeature PATMAT for $source_id $alg_name");
      $counter{'unprocessed_Patmat'}++;
    }
  }   #END PATMATMOTIFS

  ##################
  ## HMMPFAM
  ##################
  elsif ($alg_name eq "HMMPFAM") {

      my ($file,$algorithm,$featuretype,$database,$accession,$model,
	  $info,$domain,$start,$stop,$hmmf,$hmmt,$score,$evalue) = @tmp;

      # return if there is no matching entry in PFAM
      my $pf = GUS::Model::DoTS::PfamEntry->new({
						 'release' => $self->getArgs()->{'pfamRel'},
						 'accession' => $accession,
						 #'identifier' => $model
						}
					       );
   

      $pf->retrieveFromDB() || $self->log( "EE Could not retrieve PFAMEntry for SOURCE $source_id :  PfamId: $accession") && $counter{'notInDb_Pfam'}++ && return undef;

      my $motif_id=$pf->getPfamEntryId; 
      my ($feature,$aafid)=$self->existenceHmmPfamFeature($aa_sequence_id, $alg_name, 'PFAM motif', 
						    $score, $start, $stop);

      ## if the feature exists, we might want to update it (e.g. is values are missing)....
      if ($feature){
	## ... but only if 'reload' is set !!! 
	$self->log ("II Got HmmPfamFeature with ID $aafid....") if $verbose;
	  unless ($self->getArgs()->{'reload'}){

	    ## else return to parser !
	    $self->log("EE Cannot create the new HmmPFAM Feature. Returning....");
	    $counter{'exists_Pfam'}++;
	    return;
	  }
	$self->log( "II Setting MotifID $motif_id for FeatureId $aafid....");
	
	$feature->setScore($score);
	$feature->setMotifId($motif_id);
	$feature->setParent($pf);
	$counter{'updated_Pfam'}++;
      }else{
	## if the feature does not exist, we create it

	  my $newFeature = $self->createNewPredictedAAFeature( $source_id, $info,
							 $alg_name, 'PFAM motif', 
							 $score, $start, $stop, $motif_id);

	  if ($newFeature) {
	      $self->log("II No Entry !! Creating new HMMPFAM Feature for $source_id...") if $verbose;
	      $seq->addChild($newFeature);
	      $newFeature->setParent($pf);
	      $counter{'new_Pfam'}++;
	  }else{	
	      $self->log("EE Cannot create the new HmmPFAM Feature");
	      $counter{'unprocessed_Pfam'}++;
	  }
      }
  } # end HMMPFAM



}  # end sub process


#######################################################
## Checks if AAFeature already exists.
## for some we will need separate subs (see below)
#######################################################
sub existenceAAFeature{
  my $self=shift;
  my ($source_id, $alg_name, $feature_name, $start, $stop) = @_;
  my $aaseqid=$self->getAaSeqId();
  my $dbh = $self->getQueryHandle();


#  my $sql = "select paf.name, paf.algorithm_name, paf.description,
#        	paf.score, aal.start_min, aal.end_max
#	        from dots.GeneFeature gf, dots.RNAFeature rf,
#	        dots.TranslatedAAFeature taf,
#	        dots.PredictedAAFeature paf, dots.AALocation aal, dots.ProjectLink pl
#	        where gf.source_id = \'$source_id\'
#	        and rf.parent_id = gf.na_feature_id
#	        and rf.na_feature_id = taf.na_feature_id
#	        and taf.aa_sequence_id = paf.aa_sequence_id
#	        and paf.aa_feature_id = aal.aa_feature_id
#                and paf.algorithm_name = \'$alg_name\'
#	        and aal.start_min=$start
#	        and aal.end_max=$stop
#	        and paf.name = \'$feature_name\'
#	        and gf.na_feature_id = pl.id
#	        and pl.table_id = 108
#	        and pl.project_id = $project_id";

  my $sql = "select paf.name, paf.algorithm_name, paf.description,
        	paf.score, aal.start_min, aal.end_max
	        from
	        dots.TranslatedAAFeature taf,
	        dots.PredictedAAFeature paf, dots.AALocation aal
	        where
	        taf.aa_sequence_id = paf.aa_sequence_id
	        and paf.aa_feature_id = aal.aa_feature_id
                and paf.algorithm_name = \'$alg_name\'
	        and aal.start_min=$start
	        and aal.end_max=$stop
	        and paf.name = \'$feature_name\'
                and taf.aa_sequence_id= $aaseqid";



  $self->log ($sql) if $verbose; #if $self->getArgs()->{'verbose'};


  my $stmt = $dbh->prepare( $sql );
  $stmt->execute();

  my $countRows = 0;
  while (my $row = $stmt->fetchrow_hashref('NAME_lc')) {
      $countRows++;
  }
    
  if ($countRows > 0){
    $self->log("Skipping feature $feature_name for $source_id (from $start to $stop)....\n");
    $self->log("$countRows rows returned for :\n$sql\n"); 
    return $countRows;
  } else {
    return undef;
  }

} #end Sub




#######################################################
## Checks if HmmPfamFeature already exists.
#######################################################
sub existenceHmmPfamFeature{
  my $self=shift;
  my ($aa_sequence_id, $alg_name, $feature_name,$score, $start, $stop) = @_;
#  my $project_id=$self->getArgs()->{'projectId'};

  #do I have to invoke queryhandle again ???
  my $dbh = $self->getQueryHandle();
  my $sql = "select paf.*
	        from dots.TranslatedAAFeature taf, dots.PredictedAAFeature paf, DoTS.AALocation aal
	        where taf.aa_sequence_id=$aa_sequence_id
	        and taf.aa_sequence_id = paf.aa_sequence_id
	        and paf.aa_feature_id = aal.aa_feature_id
                and paf.algorithm_name = \'$alg_name\'
                and paf.score = $score
	        and aal.start_min=$start
	        and aal.end_max=$stop
	        and paf.name = \'$feature_name\'";

  my $stmt = $dbh->prepare( $sql );
  $stmt->execute();
  my $paf;
  my $aafid;
  my $countRows = 0;
  while (my $row = $stmt->fetchrow_hashref('NAME_lc')) {
      $paf=GUS::Model::DoTS::PredictedAAFeature->new($row);
      $aafid=$$row{'aa_feature_id'};
      $countRows++;
  }
  if ($countRows==1){
      $self->log("II SQL returned 1 row for predictedAAfeature. Feature exists") if $verbose;
      return ($paf,$aafid);
  }elsif($countRows>1){
      $self->log("EE $countRows rows returned, featurequery is not stringent enough !") if $verbose; 
      return 0; #$countRows;
  } else {
      $self->log("II No rows returned for predictedAAfeature. New Feature.");
    return 0;
  }
} #end Sub


#######################################
# Create the new PredictedAAFeature
#######################################
sub createNewPredictedAAFeature {
  my $self=shift;
  my ($source_id, $description, $alg_name, $feature_name, $score, $start, $stop, $motif_id) = @_;


  # check, if feature already exists
  # rather do this with the method call retrieveFromDB <- see below 
  # since the constraints of retrieveFromDB() do not check for aa_sequence_id or AAlocation

  my $exists=$self->existenceAAFeature($source_id, $alg_name, $feature_name, $start, $stop);

  if ($exists) {
      $self->log("EE predictedAAFeature exists. Returning ...");
      return 0;
  }

  my $newFeature = GUS::Model::DoTS::PredictedAAFeature->new({
							      'is_predicted'           => 1,
							      'algorithm_name'         => $alg_name,
							      'prediction_algorithm_id'=> $alg_id{$alg_name},
							      'description'            => $description,
							      'name'                   => $feature_name,
							      'score'                  => $score,
							      'review_status_id'       => 0,     # unreviewed
							      'pfam_entry_id'               => $motif_id
							     });
	
	
  #
  # Create the AALocation object and add it as a child of
  # the created PredictedAAFeature.
  #

  my $aa_location = &createNewAALocation($start, $stop);
  $newFeature->addChild($aa_location) if $aa_location;
  $self->log( $newFeature->toString()) if $verbose;
  return $newFeature;
}

#######################################################
## Creates new AAlocation
#######################################################
sub createNewAALocation {
  my($start,$end) = @_;
  return undef if (!$start || !$end);
  my $aa_loc = GUS::Model::DoTS::AALocation->new({'start_min' => $start,
						  'start_max' => $start,
						  'end_min'   => $end,
						  'end_max'   => $end});
  return $aa_loc;
}


#######################################################
## Creates new signalpeptide feature
#######################################################
sub createNewSignalPeptideFeature {

  my $self=shift;
    ### The feature will be created using the NN data from SignalP
    ### UpdateSignalPeptideFeature will add additional information:
    ### The signal_probability and the anchor_probability
    ### Ideally we would have to have two tables, storing the different sets od data,
    ### so view this as a workaround

    my ($source_id, $algorithm, $featuretype, $maxC_position, $maxC_value, $maxC_cutoff,
	$maxC_conclusion, $maxY_position, $maxY_value, $maxY_cutoff, $maxY_conclusion,
	$maxS_position, $maxS_value, $maxS_cutoff, $maxS_conclusion, $meanS_start, $meanS_stop,
	$meanS_value, $meanS_cutoff, $meanS_conclusion, $quality, $signal)   =   @_;

    $source_id=~s/\.pep$//;

    # check, if feature already exists. Do this with specific SQL
    # rather than with the retrieveFromDB() call, 
    # since the constraints of retrieveFromDB() do not check for aa_sequence_id or AAlocation

    my ($exists,$aafid)=$self->existenceSPFeature($source_id, $algorithm, $featuretype, $meanS_start, $meanS_stop);

    if ($exists) {
	$self->log("EE SignalPeptideFeature with aa_feature_id $aafid exists. Skipping ...");
	return undef;
    }

    #
    # Create the new SignalPeptideFeature if it doe not exist yet.
    #
    my $newSignalPeptide = GUS::Model::DoTS::SignalPeptideFeature->new({
                                                    'is_predicted'      => 1,
						    'review_status_id'       => 0,     # unreviewed
                                                    #'manually_reviewed' => 0,
                                                    'algorithm_name'    => $algorithm,
                                                    'prediction_algorithm_id' => '305',
                                                    'description'       => 'Signal Peptide',
                                                    'name'              => $featuretype,
                                                    'maxc_score'        => $maxC_value,
                                                    'maxc_conclusion'   => &conclude($maxC_conclusion),
                                                    'maxy_score'        => $maxY_value,
                                                    'maxy_conclusion'   => &conclude( $maxY_conclusion),
                                                    'maxs_score'        => $maxS_value,
                                                    'maxs_conclusion'   => &conclude( $maxS_conclusion),
                                                    'means_score'       => $meanS_value,
                                                    'means_conclusion'  => &conclude( $meanS_conclusion),
                                                    'num_positives'     => $quality });
      
  #
  # Create the AALocation object and add it as a child of
  # the created PredictedAAFeature.
  #
    my $aa_location = &createNewAALocation($meanS_start, $meanS_stop);
    $newSignalPeptide->addChild($aa_location) if $aa_location;

    $self->log( $newSignalPeptide->toString()) if $verbose;
    return $newSignalPeptide;
}


#######################################################
## Checks if HmmPfamFeature already exists and Updates
## Entry
#######################################################
sub UpdateSignalPeptideHMMFeature {
  my $self=shift;
  my ($source_id, $algorithm,$featuretype, 
      $prediction, $SPP, $SAP, $CSP, $start, $signal) = @_;
  $source_id=~s/\.pep$//;
  my ($SignalPeptideFeature, $aafid)=$self->existenceSPFeature($source_id, $algorithm, $featuretype, 1, $start);
  if ($SignalPeptideFeature){
    $self->log("Updating tokens for aa_feature_id $source_id ...\n") if $verbose;
    $SignalPeptideFeature->setAnchorProbability($SAP);
    $SignalPeptideFeature->setSignalProbability($SPP);
    return $SignalPeptideFeature;
  }else{
    $self->log( "EE No SP Feature for $source_id...\n\n") if $verbose;
    return undef;
  }
}


#######################################################
## Create new transitpeptidefeature (only for falcip!!)
#######################################################
sub createNewPredictedTransitPeptide{
    my $self=shift;
    my ($aa_sequence_id,$source_id,$algorithm,$lengthA,$cutoffA,$lengthB,$cutoffB,
	$lengthC,$minimumKN,$maxGap,$cutoffC,$lengthD,$cutoffD,$valueA,$valueB,
	$valueC,$valueD,$A_ok,$B_ok,$C_ok,$D_ok,$APloc)  =  @_;
    
   # my $project_id=$self->getArgs()->{'projectId'};
    $source_id=~s/\.pep$//;

    $algorithm="PlasmoAP";

    my $newTransitPeptide = GUS::Model::DoTS::PlasmoAPFeature->new({
	'is_predicted'      => 1,
	'review_status_id'       => 0,     # unreviewed
	#'manually_reviewed' => 0,
	'algorithm_name'    => $algorithm,
	'prediction_algorithm_id' => '7391',
	'description'       => 'predicted apicoplast transit peptide',
	'name'              => 'Transit Peptide',
	'cutoff_criterion_b'=> $cutoffB,
	'result_criterion_b'=> $valueB,
	'cutoff_criterion_c'=> $cutoffC,
	'result_criterion_c'=> $valueC,
	'cutoff_criterion_d'=> $cutoffD,
	'result_criterion_d'=> $valueD,
	'decision_criterion_a' => $A_ok,
	'decision_criterion_b' => $B_ok,
	'decision_criterion_c' => $C_ok,
	'decision_criterion_d' => $D_ok,
	'decision_targeting'   => $APloc,
	'length_criterion_a'   => $lengthA,
	'cutoff_criterion_a' => $cutoffA,
	'result_criterion_a' => $valueA,
	'length_criterion_b' => $lengthB,
	'length_criterion_c' => $lengthC,
	'length_criterion_d' => $lengthD,
	'maxgap'             => $maxGap,
	'minimumkn'          => $minimumKN,
	'other_criteria'     => ""
	});

    # For this analysis there is no AALocation !!!

    $newTransitPeptide->setAaSequenceId($aa_sequence_id);

    $self->log($newTransitPeptide->toString() ) if $self->getArgs()->{'debug'};
    if ($newTransitPeptide->retrieveFromDB()){
	$self->log("EE $algorithm feature exists for $source_id !!!\n\n") if $verbose;
	return undef;
    }
    return $newTransitPeptide;
}



###############################
## Convert human readable 'yes'
## to digital answer
###############################
sub conclude{
  my $value=shift;
  my $answer=($value=~m/yes/i) ? 1 : 0;
  return $answer;
}



#######################################################
## Checks if Signalpeptide exists !!
#######################################################
sub existenceSPFeature{
  my $self=shift;
  my ($source_id, $alg_name, $feature_name, $start, $stop) = @_;
  my $AaSeqId=$self->getAaSeqId();

#  my $project_id=$self->getArgs()->{'projectId'};

  my $dbh = $self->getQueryHandle();

#  my $sql = "select spf.*
#	        from dots.GeneFeature gf, dots.RNAFeature rf,
#	        dots.TranslatedAAFeature taf,
#	        dots.SignalPeptideFeature spf, dots.ProjectLink pl
#	        where gf.source_id = \'$source_id\'
#	        and rf.parent_id = gf.na_feature_id
#	        and rf.na_feature_id = taf.na_feature_id
#	        and taf.aa_sequence_id = spf.aa_sequence_id
#                and spf.algorithm_name = 'SignalP'
#	        and spf.name = 'SIGNAL'
#	        and gf.na_feature_id = pl.id
#	        and pl.table_id = 108
#	        and pl.project_id = $project_id";


  my $sql = "select spf.*
	        from
	        dots.TranslatedAAFeature taf,
	        dots.SignalPeptideFeature spf
	        where
                taf.aa_sequence_id = spf.aa_sequence_id
                and spf.algorithm_name = 'SignalP'
	        and spf.name = 'SIGNAL'
	        and taf.aa_sequence_id= $AaSeqId";




  ## could be replaced with retrieveFromDB ???

  my $stmt = $dbh->prepare( $sql );
  $stmt->execute();

  my $countRows = 0;
  my $aafeatureid;
  my $spf;
  while (my $row = $stmt->fetchrow_hashref('NAME_lc')) {
      $spf = GUS::Model::DoTS::SignalPeptideFeature->new($row);
      $aafeatureid = $$row{'aa_feature_id'};
      $countRows++;
  }

  if ($countRows>0) {
    $self->log("$sql\n") if $verbose;
    $self->log("II SQL returned rows");
    $self->log("II Skipping feature $feature_name for $source_id (from $start to $stop)...\n");
    return ($spf,$aafeatureid);
  } else {
    return undef;
  }

}  # end Sub




sub setAlgId {
  my $self = shift;
  my $desc = shift;
  $self->log("Finding AlgorithmId for $desc");

  my %alg = ( name => "$desc" );

  my $alg_gus = GUS::Model::Core::Algorithm->new(\%alg);
  if ($alg_gus->retrieveFromDB() ){
    $algId = $alg_gus->getId;
  } else {
    $self->log("EE ERROR in returning AlgId");
    return undef;
  }
  return 1;
}

sub getAlgId {
  return $algId;
}

##
## END SUBS
##


# --------------------------------------------------------------------
if ( $0 !~ /ga$/i ) {

  my $usg = Usage();
  my $name = $0; $name =~ s/\.pm$//; $name =~ s/^.+\///;
  my $md5 = `/usr/bin/md5sum $0`;
  chomp $md5;
  $md5 =~ s/^(\S+).+/$1/;

  print <<XML;
<Algorithm xml_id="1001">
  <name>$name</name>
  <description>$usg</description>
</Algorithm>

<AlgorithmImplementation xml_id="1002" parent="1001">
  <version>$Version</version>
  <executable>$0</executable>
  <executable_md5>$md5</executable_md5>
</AlgorithmImplementation>
XML

}

1;

__END__


