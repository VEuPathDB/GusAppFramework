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
use GUS::Model::DoTS::PlasmoAPFeature;        #<<<<<<<<  No Object
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
  my $usage = 'loads gene features from an XML data file...';

  my $easycsp =
    [{
     { h => 'project name',
       t => 'string',
       o => 'Project',
       d => 'PlasmodiumDB-4.0',
     },
     { h => 'Indicates what task to accomplish',
       t => 'string',
       e => [qw( LoadGenomicSequence UpdateGenomicSequence
		 ScaffoldGapFeatures
		 GeneFeatures FixGeneFeatures
		 GoAnnotation EcAnnotation )],
       o => 'taskFlag',
     },
     {
      t => 'integer',
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
      l => 1,
      o => 'project_id',
      t => 'integer',
      h => 'project_id of this release',
      d => 713
     },
     {
      l => 1,
      o => 'external_db_id',
      t => 'integer',
      h => 'external database identifier for the contigs',
      d => 151
     },
     {
      t => 'boolean',
      o => 'reload',
      h => 'For loading new Ids and scores for HmmPfam entries',
     },
     {
      t => 'boolean',
      o => 'commit',
      h => 'Set flag to commit changes to database. Default: off',
      d => 0,
     },
     {
      l => 1,
      t => 'integer',
      o => 'extDBRelId',
      h => 'Sets the External Database Release Id',
     },
   }];

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

my $seq_source_id = "";;
my $seq_description = "";
my %finished;
my $countInserts = 0;
my %counter =();
my $verbose = 0;
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


  print $self->getArgs()->{'commit'} ? "COMMIT ON\n" : "COMMIT TURNED OFF\n";
  print "Testing on $self->getArgs()->{'testnumber'}\n" if $self->getArgs()->{'testnumber'};

  my $external_db_id=$self->getArgs()->{'external_db_id'};
  my $project_id=$self->getArgs()->{'project_id'};
  my $aa_sequence_id;


  die "\n\nPlease specify the project_id, e.g. with --project_id=313\n\n" unless $project_id;
  die "\n\nPlease specify the external_db_id, e.g. with --external_db_id=151\n\n" unless $external_db_id;

  #
  # make sure the input file is provided
  #
  if (!-e "$self->getArgs()->{'filename'}") {
    die "You must provide a valid tab delimited file on the command line\n";
  }



  die "Please specify name of the input file\n" unless $self->getArgs()->{'filename'};
  my $external_database_release_id = $self->getArgs()->{'extDbRelId'} ||  die 'external_database_release_id not supplied\n';

  $dbh = $self->getQueryHandle;

  ### GusApplication::Log('INFO', 'RAIID', $ctx->{self_inv}->getId);


  if ($self->setAlgId) {
    foreach my $glob (@{$ctx->{cla}->{filename}}) {
      my @files = glob($glob);
      foreach my $file (@files) {
	my $tree = $self->parseFile($file);

	##$self->createObjects($tree) if ($self->setProjId && $self->setExtDbId($tree) && $self->setExtDbRelId($tree));
      }
    }
  }
  return 1;
}

####################################################
## Parses input files into appropriate variables
## and then calls subroutine 'process' to insert values
####################################################
sub parseFile {
  my $self = shift;
  my $file=shift;
    open(F,"<$file") || print STDERR  "Could not open $file : $!\n\n" && return undef;


    my $seq;
    while (<F>) {
	chomp;
	#
	# skip comments and blank lines, shouldn't be in there anyway
	#
	next if ( (/^\s*\#/) || (/^\s+$/) );
	print STDERR $_ ."\n" if $self->getArgs()->{'$debug'};

	my @tmp = split(/\t/,$_);	
	if ($tmp[2] eq 'AA_sequence') {
	    $counter{'sequence'}++;
	
	    if ($self->getArgs()->{'verbose'}) {
		print STDERR "$tmp[2] $tmp[0] with UID $tmp[1] is the $counter{'sequence'}\. sequence\n";
	    }
	
	    # if testnumber is reached then exit out of loop.
	
	    last if (($self->getArgs()->{'testnumber'}) && ($counter{'sequence'} >= ($self->getArgs()->{'testnumber'})));
	    print STDERR "Processing peptide $counter{'sequence'} on " . `date`;
	
	    if ($seq) {
		#submit data of previous entry if $seq  exists
		$seq->submit();
		##following allows garbage collection...
		$self->getArgs()->{'self_inv'}->undefPointerCache();
		#undef $seq;
	    }

	    ($seq,$aa_sequence_id) = &get_object(@tmp);
	    next unless ($seq);  
	
	  } else {
	    # if it is not an AA_sequence entry it must be a motif for the sequence
	    # but if there has been an error while retrieving the sequence, there will be not object $seq
	    # therefore skip until $seq defined (next AA_sequence entry)	
	
	    &process($seq,$aa_sequence_id,@tmp) if $seq;
	  }
      } # end while LOOP

    print STDERR "submitting $counter{'sequence'} . sequence\n" if $verbose;
    $seq->submit() if $seq;
    # to submit last sequence


    #
    # generate summary
    #

    my $results= "Run finished: Processed ". $counter{'sequence'}." peptides\n";
    foreach my $key (keys %counter) {
	$results .= $counter{$key} . " $key features\n";
    }

    print STDERR "\n" . $results . "\n\n"; 

} # end run





############################################################
#              S  u  b  r  o  u  t  i  n  e  s
############################################################


############################################################
# Query to retrieve Object from database (eg if no GUS ID available)
############################################################
sub get_object{
    my @tmp=@_;
    my $seq;
    my $aa_sequence_id;
    my $project_id=$self->getArgs()->{'project_id'};

    if ($tmp[1]=~m/^(\d+)/) {
	my $id=$1; 
	$seq = TranslatedAASequence->new({'aa_sequence_id' => $id});
	print STDERR  "Found UID $id !\n" if $self->getArgs()->{'verbose'};

    } else {
	## if no GUS UID exists query the database with the source_id
	## which is stored as the first value on the tab-delimited line
	
	my $key=$tmp[0];
	$key=~s/\.pep$//;
	print STDERR  "No UID. Querying DB for source_id $key !\n" if $self->getArgs()->{'verbose'};

	#retrieve the sequence_id to which the features will be linked
	#prepare connection to DB
	
	my $dbh = $self->getArgs()->{'self_inv'}->getQueryHandle();   
	#my $stmt = $dbh->prepare("select ts.* from TranslatedAASequence ts, TranslatedAAFeature tf, RNAFeature rf, ProjectLink pl where pl.project_id = $project_id and pl.table_id = 108 and rf.parent_id = pl.id and tf.na_feature_id = rf.na_feature_id and ts.aa_sequence_id = tf.aa_sequence_id and ts.source_id = ? ");
	
	my $stmt = $dbh->prepare("select tas.*
from  dots.genefeature gf, dots.projectlink pl, dots.rnafeature rnaf, dots.translatedaafeature taf, sres.translatedaasequence tas
where  gf.na_sequence_id = pl.id
and  pl.table_id = 89
and  pl.project_id = $project_id
and  rnaf.parent_id = gf.na_feature_id
and  rnaf.na_feature_id = taf.na_feature_id
and  taf.aa_sequence_id = tas.aa_sequence_id
and  gf.source_id=\'$key\'");


	##execute statement
	$stmt->execute();
	
	my $countRows = 0;
	while (my $row = $stmt->fetchrow_hashref('NAME_lc')) {
	    $seq = TranslatedAASequence->new($row);
	    $aa_sequence_id = $$row{'aa_sequence_id'};
	    $countRows++;
	}



	### SOME DEBUG STUFF
	if ($countRows>1) {
	    print STDERR "\n********************************************\n";
	    print STDERR "Too many Rows returned !\n";
	    print STDERR "SQL returned $countRows for $key !!\n";
	    print STDERR "********************************************\n\n";
	    return undef;
	} elsif ($countRows<1) {
	    print STDERR "\n********************************************\n";
	    print STDERR "No Row returned !!\n";
	    print STDERR "I was looking for id $key !!\n";
	    print STDERR "********************************************\n\n";
	    return undef;
	
	} elsif ($countRows==1) {
	    print STDERR "\n>>>>> SQL returned exactly 1 row for $key <<<<<<\n\n" if $self->getArgs()->{'verbose'};
	    print STDERR "\n>>>>> aa_sequence_id for $key is $aa_sequence_id <<<<<<\n\n" if $self->getArgs()->{'verbose'};
	    return ($seq,$aa_sequence_id);
	}
    }
}  # end sub





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
  my($seq,$aa_sequence_id,@tmp) = @_;

  if (!$seq) {
    die ("ERROR: sequence object does not exist!\n");
  }

  #
  # Set the fields that we need.
  #
  my $source_id = $tmp[0];
  $source_id=~s/\.pep$//;       #in case it is still there
  my $alg_name = $tmp[1];



  if ($self->getArgs()->{'verbose'} && $source_id) {
    print STDERR "source_id is $source_id\n";
    print STDERR "alg_name is $alg_name\n\n";
  }


  ## WILL HAVE TO CHANGE THAT TO A GFF FORMAT INPUT, 
  ## SO I CAN GET RID OF THE ELSIF LOOPS
  ## On the other hand: GFF sucks !!

  ##################
  ## SignalpNN
  ##################
  if ($alg_name eq "SignalP") {
    my $feature = &createNewSignalPeptideFeature(@tmp);

    if ($feature) {
	$seq->addChild($feature);
	$counter{'signal'}++;
    } else {
	print STDERR "ERROR: Unable to create PredictedAAFeature for $source_id $alg_name\n\n";
	$counter{'unprocessed'}++;
    }
  } # end SIGNALP
  
  

  ##################
  ## SignalPHMM
  ##################
  if ($alg_name=~m/SignalPHMM/i) {
      my $feature = &UpdateSignalPeptideHMMFeature(@tmp);

      if ($feature) {
	  $seq->addChild($feature);
	  $counter{'signalhmm'}++;
      } else {
	  print STDERR "ERROR: Unable to create PredictedAAFeature for $source_id $alg_name\n\n";
	  $counter{'unprocessed'}++;
      }
  } # end SIGNALP


  ##################
  ## PlasmoAP
  ##################
  elsif ($alg_name=~m/PlasmoAP/i) {

      my ($file,$algorithm,$lengthA,$cutoffA,$lengthB,$cutoffB,$lengthC,
	  $minimumKN,$maxGap,$cutoffC,$lengthD,$cutoffD,$valueA,$valueB,
	  $valueC,$valueD,$A_ok,$B_ok,$C_ok,$D_ok,$APloc)  =  @tmp;

      my $feature = &createNewPredictedTransitPeptide($aa_sequence_id,@tmp);

      if ($feature) {
	  $seq->addChild($feature);
	  $counter{'plasmoap'}++;
    } else {
	print STDERR "ERROR: Unable to create PredictedAAFeature for $source_id $alg_name\n\n";
	$counter{'unprocessed'}++;
    }
  }  # END PlasmoAP


  ##################
  ## TMPRED
  ##################
  elsif ($alg_name eq "TMPRED") {
 
    my ($file,$algorithm,$featuretype,$score,$start,$stop,$center,$orientation,$helix_min_len,$helix_max_len)=@tmp;
    my $feature = &createNewPredictedAAFeature($source_id, 'transmembrane region',
                                               $alg_name, 'TMhelix' , $score, $start, $stop);
 
    if ($feature) {
	$seq->addChild($feature);
	$counter{'tmpred'}++;
    } else {
	print STDERR "ERROR: Unable to create PredictedAAFeature for $source_id $alg_name\n\n";
	$counter{'unprocessed'}++;
    }

  }    # END TMPRED

  ##################
  ## TMHMM2
  ##################
  elsif ($alg_name=~/TMHMM2/) {

    my ($file,$algorithm,$featuretype,$start,$stop,undef,undef,undef)=@tmp;
    $algorithm=~s/\.\d+$//; #remove trailing .0

    my $feature = &createNewPredictedAAFeature($file, 'transmembrane region',
                                               $algorithm, 'TMhelix', '', $start, $stop);

    if ($feature) {
      $seq->addChild($feature);
      $counter{'tmhmm'}++;
    } else {
      print STDERR "ERROR: Unable to create PredictedAAFeature for $source_id $alg_name\n\n";
      $counter{'unprocessed'}++;
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

    my $feature = &createNewPredictedAAFeature($source_id, 'transmembrane region',
                                               $alg_name, 'TMhelix', $helix_score, $helix_begin, $helix_end);

    if ($feature) {

      $seq->addChild($feature);
      $counter{'toppred'}++;
    } else {
      print STDERR "ERROR: Unable to create PredictedAAFeature for $source_id $alg_name\n\n";
      $counter{'unprocessed'}++;
    }
  }  # END TOPPRED



  ##################
  ## TMAP
  ##################

  elsif ($alg_name eq "TMAP") {

    my ($file,$algorithm,$featuretype,$start,$stop,$tmap_helix_len) = @tmp;

    my $feature = &createNewPredictedAAFeature($source_id,'transmembrane region',
                                               $alg_name, 'TMhelix', '', $start, $stop); ########### no score available


    if ($feature) {
      $seq->addChild($feature);
      $counter{'tmap'}++;
    } else {
      print STDERR "ERROR: Unable to create PredictedAAFeature for $source_id $alg_name\n\n";
      $counter{'unprocessed'}++; 
  }
} # END TMAP



  ##################
  ## PFSCAN
  ##################
  elsif ($alg_name eq "PFSCAN") {
	 
    my ($file,$algorithm,$featuretype,$database,$score1,$score2,$start,$stop,$donknow1,$donknow2,$PSID,$PSABBR,$PS_TITLE)=@tmp;
    my $feature = &createNewPredictedAAFeature($source_id, "PROSITE motif $PSID, accession $PS_TITLE",
                                               $alg_name, 'PROSITE motif', $score1, $start, $stop);


    if ($feature) {
      $seq->addChild($feature);
      $counter{'pfscan'}++;
    } else {
      print STDERR "ERROR: Unable to create PredictedAAFeature for $source_id $alg_name\n\n";
      $counter{'unprocessed'}++;
  }

  } #END PFSCAN



  ##################
  ## Patmatmotifs
  ##################
  elsif ($alg_name=~/PATMATMOTIF/) { ######### WORKAROUND DUE TO TYPO -> patmatmotifs

    my ($file,$algorithm,$featuretype,$database,$start,$stop,$PSID,$PSACC)=@tmp;
    my $feature = &createNewPredictedAAFeature($source_id, "PROSITE motif $PSID, accession $PSACC",
                                               "PATMATMOTIFS", 'PROSITE motif', '0', $start, $stop);

    if ($feature) {
      $seq->addChild($feature);
      $counter{'patmat'}++;
    } else {
      print STDERR "ERROR: Unable to create PredictedAAFeature for $source_id $alg_name\n\n";
      $counter{'unprocessed'}++;
    }
  }   #END PATMATMOTIFS


  ##################
  ## HMMPFAM
  ##################
  elsif ($alg_name eq "HMMPFAM") {

      my ($file,$algorithm,$featuretype,$database,$accession,$model,$info,$domain,$start,$stop,$hmmf,$hmmt,$score,$evalue)=@tmp;

      # return if there is no matching entry in PFAM
      my $pf = PfamEntry->new({'release' => '7.5',
			       'accession' => $accession});
      $pf->retrieveFromDB() || print STDERR "Could not retrieve PFAMEntry for SOURCE $source_id :  ACC: $accession\n\n" && return undef;


      my $motif_id=$pf->getPfamEntryId;


      my ($feature,$aafid)=&existenceHmmPfamFeature($aa_sequence_id, $alg_name, 'PFAM motif', 
						    $score, $start, $stop);


      print STDERR "Got HmmPfamFeature with ID $aafid....\n\n" if $self->getArgs()->{'verbose'};

      ## if the feature exists, we might want to update it (e.g. is values are missing)....
      if ($feature){
	  
	  ## ... but only if 'reload' is set !!! 
	  unless ($self->getArgs()->{'reload'}){

	      ## else return to parser !
	      print STDERR "\n\nCannot create the new HmmPFAM Feature. Returning....\n\n";
	      $counter{'existsPfam'}++;
	      return;
	  }
	   
	  print STDERR "\n\nSetting MotifID $motif_id for FeatureId $aafid....\n\n";
	  $feature->set('score', $score);
	  $feature->set('motif_id', $motif_id) ; 
	  $feature->setParent($pf);
	      
	  $counter{'updatePfam'}++;
	  
      }else{
	  ## if the feature does not exist, we create it


	  my $newFeature = &createNewPredictedAAFeature( $source_id, $info,
							 $alg_name, 'PFAM motif', 
							 $score, $start, $stop, $motif_id);

	  if ($newFeature) {
	      print STDERR "\n\nNo Entry yet!!  Creating new HMMPFAM Feature for $source_id...\n\n";
	      $seq->addChild($newFeature); 
	      $newFeature->setParent($pf);
	      $counter{'newPfam'}++;
	  }else{	
	      print STDERR "\n\nCannot create the new HmmPFAM Feature.\n\n";
	      $counter{'missedPfam'}++;
	  }
      }
  } # end HMMPFAM



}  # end sub process


#######################################################
## Checks if AAFeature already exists.
## for some we will need separate subs (see below)
#######################################################
sub existenceAAFeature{
  my ($source_id, $alg_name, $feature_name, $start, $stop) = @_;

  my $project_id=$self->getArgs()->{'project_id'};
  my $dbh = $self->getArgs()->{'self_inv'}->getQueryHandle();
  my $sql = "select paf.name, paf.algorithm_name, paf.description,
        	paf.score, aal.start_min, aal.end_max
	        from dots.GeneFeature gf, dots.RNAFeature rf,
	        dots.TranslatedAAFeature taf,
	        dots.PredictedAAFeature paf, sres.AALocation aal, dots.ProjectLink pl
	        where gf.source_id = \'$source_id\'
	        and rf.parent_id = gf.na_feature_id
	        and rf.na_feature_id = taf.na_feature_id
	        and taf.aa_sequence_id = paf.aa_sequence_id
	        and paf.aa_feature_id = aal.aa_feature_id
                and paf.algorithm_name = \'$alg_name\'
	        and aal.start_min=$start
	        and aal.end_max=$stop
	        and paf.name = \'$feature_name\'
	        and gf.na_feature_id = pl.id
	        and pl.table_id = 108
	        and pl.project_id = $project_id";


  my $stmt = $dbh->prepare( $sql );
    
  $stmt->execute();

  my $countRows = 0;
  while (my $row = $stmt->fetchrow_hashref('NAME_lc')) {
      $countRows++;
  }
    
  if ($countRows > 0){
    print STDERR ">>>>>>>>>>Skipping feature $feature_name for $source_id (from $start to $stop)....\n\n\n";
    print STDERR "$countRows rows returned for :\n$sql\n\n";
    return $countRows;
  } else {
    return undef;
  }
   
} #end Sub




#######################################################
## Checks if HmmPfamFeature already exists.
#######################################################
sub existenceHmmPfamFeature{
  my ($aa_sequence_id, $alg_name, $feature_name,$score, $start, $stop) = @_;

  my $project_id=$self->getArgs()->{'project_id'};
  my $dbh = $self->getArgs()->{'self_inv'}->getQueryHandle();
  my $sql = "select paf.*
	        from dots.TranslatedAAFeature taf, dots.PredictedAAFeature paf, sres.AALocation aal
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
      $paf=PredictedAAFeature->new($row);
      $aafid=$$row{'aa_feature_id'};
      $countRows++;
  }
  
  if ($countRows==1){
      print STDERR "\n>>>>> SQL returned  1 row  <<<<<<\n\n";
      return ($paf,$aafid);
  }elsif($countRows>1){
      print STDERR "#### $countRows rows returned, featurequery is not stringent enough \n\n\n"; 
      return undef;
  } else {
      print STDERR "No rows returned for query\n\n";
    return undef;
  }
} #end Sub


#######################################
# Create the new PredictedAAFeature
#######################################
sub createNewPredictedAAFeature {
  my ($source_id, $description, $alg_name, $feature_name, $score, $start, $stop, $motif_id) = @_;


  # check, if feature already exists
  # rather do this with the method call retrieveFromDB <- see below 
  # since the constraints of retrieveFromDB() do not check for aa_sequence_id or AAlocation

  my $exists=&existenceAAFeature($source_id, $alg_name, $feature_name, $start, $stop);
  if ($exists) {
      print STDERR "Feature exists...\n\n";
      return undef;
  }

  my $newFeature = PredictedAAFeature->new({
                                            'is_predicted'           => 1,
                                            'manually_reviewed'      => 0,
                                            'algorithm_name'         => $alg_name,
                                            'prediction_algorithm_id'=> $alg_id{$alg_name},
                                            'description'            => $description,
					    'name'                   => $feature_name,
					    'score'                  => $score,
					    'motif_id'               => $motif_id
					    });
	
	
  #
  # Create the AALocation object and add it as a child of
  # the created PredictedAAFeature.
  #

  my $aa_location = &createNewAALocation($start, $stop);
  $newFeature->addChild($aa_location) if $aa_location;

  return $newFeature;
}

#######################################################
## Creates new AAlocation
#######################################################
sub createNewAALocation {
  my($start,$end) = @_;
  return undef if (!$start || !$end);
  my $aa_loc = AALocation->new({'start_min' => $start,
                                'start_max' => $start,
                                'end_min'   => $end,
                                'end_max'   => $end});
  return $aa_loc;
}


#######################################################
## Creates new signalpeptide feature
#######################################################
sub createNewSignalPeptideFeature {


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

    my ($exists,$aafid)=&existenceSPFeature($source_id, $algorithm, $featuretype, $meanS_start, $meanS_stop);
    if ($exists) {
	print STDERR "SignalPeptideFeature with aa_feature_id $aafid exists. Skipping ...\n\n" if $self->getArgs()->{'verbose'};
	return undef;
    }

    #
    # Create the new SignalPeptideFeature if it doe not exist yet.
    #
    my $newSignalPeptide = SignalPeptideFeature->new({
                                                    'is_predicted'      => 1,
                                                    'manually_reviewed' => 0,
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
    
    print STDERR $newSignalPeptide->toString() if $self->getArgs()->{'debug'};


### DOES NOT WORK FOR THAT PURPOSE    
#    #if ($newSignalPeptide->retrieveFromDB()){
#	print STDERR "$algorithm feature exists for $source_id !!!\n\n" if $self->getArgs()->{'verbose'};
#	return undef;
#    }

   
    return $newSignalPeptide;
}


#######################################################
## Checks if HmmPfamFeature already exists and Updates
## Entry
#######################################################
sub UpdateSignalPeptideHMMFeature {

    my ($source_id, $algorithm,$featuretype, $prediction, $SPP, $SAP, $CSP, $start, $signal)=@_;

    $source_id=~s/\.pep$//;

	my ($SignalPeptideFeature, $aafid)=&existenceSPFeature($source_id, $algorithm, $featuretype, 1, $start);
	if ($SignalPeptideFeature){
	    print STDERR "Updating tokens for aa_feature_id $source_id ...\n\n" if $self->getArgs()->{'verbose'};

	    $SignalPeptideFeature->set('anchor_probability', $SAP);
	    $SignalPeptideFeature->set('signal_probability', $SPP);
	    
	    return $SignalPeptideFeature;
	}else{
	    print STDERR "No SP Feature for $source_id...\n\n" if $self->getArgs()->{'verbose'};
	    return undef;
	}
}


#######################################################
## Create new transitpeptidefeature (only for falcip!!)
#######################################################
sub createNewPredictedTransitPeptide{
    my ($aa_sequence_id,$source_id,$algorithm,$lengthA,$cutoffA,$lengthB,$cutoffB,
	$lengthC,$minimumKN,$maxGap,$cutoffC,$lengthD,$cutoffD,$valueA,$valueB,
	$valueC,$valueD,$A_ok,$B_ok,$C_ok,$D_ok,$APloc)  =  @_;
    
    my $project_id=$self->getArgs()->{'project_id'};
    $source_id=~s/\.pep$//;

    $algorithm="PlasmoAP"; #set it, so that we do not set PlasmoAPv1.0 or something similar


    my $newTransitPeptide = PlasmoAPFeature->new({
	'is_predicted'      => 1,
	'manually_reviewed' => 0,
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
    
    #
    # Can we create the AALocation object and add it as a child of the created PredictedAAFeature ?
    # No !!! For this analysis there is no AALocation !!!
    # 

    $newTransitPeptide->setAaSequenceId($aa_sequence_id);

    print STDERR $newTransitPeptide->toString() if $self->getArgs()->{'debug'};
    if ($newTransitPeptide->retrieveFromDB()){
	print STDERR "$algorithm feature exists for $source_id !!!\n\n" if $self->getArgs()->{'verbose'};
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
  my ($source_id, $alg_name, $feature_name, $start, $stop) = @_;
  my $project_id=$self->getArgs()->{'project_id'};
  my $dbh = $self->getArgs()->{'self_inv'}->getQueryHandle();


  my $sql = "select spf.*
	        from dots.GeneFeature gf, dots.RNAFeature rf,
	        dots.TranslatedAAFeature taf,
	        dots.SignalPeptideFeature spf, dots.ProjectLink pl
	        where gf.source_id = \'$source_id\'
	        and rf.parent_id = gf.na_feature_id
	        and rf.na_feature_id = taf.na_feature_id
	        and taf.aa_sequence_id = spf.aa_sequence_id
                and spf.algorithm_name = 'SignalP'
	        and spf.name = 'SIGNAL'
	        and gf.na_feature_id = pl.id
	        and pl.table_id = 108
	        and pl.project_id = $project_id";


  my $stmt = $dbh->prepare( $sql );
  $stmt->execute();

  my $countRows = 0;
  my $aafeatureid;
  my $spf;
  while (my $row = $stmt->fetchrow_hashref('NAME_lc')) {
      $spf = SignalPeptideFeature->new($row);
      $aafeatureid = $$row{'aa_feature_id'};
      $countRows++;
  }

  if ($countRows>0) {
    print STDERR "\n\n$sql\n";
    print STDERR "\n>>>>> SQL returned 1 row  <<<<<<\n\n";
    print STDERR "Skipping feature $feature_name for $source_id (from $start to $stop)....\n\n\n";
    return ($spf,$aafeatureid);
  } else {
    return undef;
  }

}  # end Sub

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



