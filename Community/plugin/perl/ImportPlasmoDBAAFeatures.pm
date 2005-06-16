package GUS::Community::Plugin::ImportPlasmoDBAAFeatures;
# $Id$ 


## LAST WORKING VERSION: 1.3
## SINCE THEN LOTS OF TWEAKING

@ISA = qw(GUS::PluginMgr::Plugin);

use strict;

use GUS::Model::Core::Algorithm;
use GUS::Model::Core::ProjectInfo;
use GUS::Model::DoTS::AALocation;
use GUS::Model::DoTS::TranslatedAASequence;
use GUS::Model::DoTS::PredictedAAFeature;
use GUS::Model::DoTS::PfamEntry;
use GUS::Model::DoTS::SignalPeptideFeature;
#use GUS::Model::DoTS::PlasmoAPFeature;
use GUS::Model::DoTS::ExternalAASequence;
use GUS::Model::DoTS::ProjectLink;
use GUS::Model::SRes::ExternalDatabase;
use GUS::Model::SRes::ExternalDatabaseRelease;
use GUS::Model::DoTS::TranslatedAAFeature;
use GUS::Model::DoTS::Motif;


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
      o => 'Project',
      d => 'PlasmodiumDB-4.1',
     },
     {
      t => 'string',
      o => 'dataSource',
      h => 'Name of the data source; e.g. plasmodium-vivax_tigr',
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
      t => 'boolean',
      o => 'reload',
      h => 'For loading new Ids and scores for -up to now only- HmmPfam entries',
      d => 0
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



##################################
##   Set some global Variables:
##################################
my $Version;
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

my %desc=(
	    'TOPPRED2'    => 'transmembrane span',
	    'SignalP'     => 'signal peptide',
	    'PATMATMOTIFS'=> 'PROSITE motif',
	    'HMMPFAM'     => 'PFAM motif',
	    'TMAP'        => 'transmembrane span',
	    'TMPRED'      => 'transmembrane span',
	    'TMHMM2'      => 'transmembrane span',
	    'PlasmoAP'    => 'apicoplast transit peptide'
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

  my $project =  $self->getArgs()->{'Project'};
  unless ($project=~m/\S+/){
    $self->log("EE Please specify the project, e.g. with --Project=PlasmodiumDB-4.1");
    return 0 ;
  }

  unless ($self->getArgs()->{'dataSource'}=~m/\S+/){
    $self->log("EE Please specify the dataSource, e.g. \'plasmodium_vivax_tigr\'");
    return 0 ;
  }

  $self->setProjId($project) || $self->log("EE Could not set the projectId");
  my $projectId= $self->getProjectId();
  $self->log("II Determined projectId= " . $projectId );


  $self->setExtDbId($self->getArgs()->{'dataSource'})|| $self->log("EE Could not set the extDbId");

  $self->setExtDbRelId() || $self->log("EE Could not set ExtDbRelId");
  my $extDbRelId= $self->getExtDbRelId();
  $self->log("II Determined extDbRelId= " . $extDbRelId );

  $self->log("Please specify name of the input file") && return 0 unless $self->getArgs()->{'filename'};

  unless (-e $self->getArgs()->{'filename'}) {
     $self->log( "You must provide a valid tab delimited file on the command line") && return 0;
  }

   $self->log("Using filename ".  $self->getArgs()->{'filename'} . "\n") if $verbose;

  if ($verbose){
    $self->log("II Project: $project");
    $self->log("II ". $self->getArgs()->{'commit'}==1 ? "II *** COMMIT ON ***" : "II *** COMMIT TURNED OFF ***");
    $self->log("II Testing plugin on ". $self->getArgs()->{'testnumber'} . " examples\n") if $self->getArgs()->{'testnumber'};
    $self->log("II Using External_db_release_id: $extDbRelId");
    $self->log("II Project_id:     $projectId");
  }

  ## All values set ? OK. Let's parse the inputfile...
  my $parsed;
  if ($self->setAlgId("GUS::Community::Plugin::ImportPlasmoDBAAFeatures")) {
    $parsed = $self->parseFile();
  }
  return $parsed;
}


####################################################
## Parses input files into appropriate variables
## and then calls subroutine 'process' to insert values
####################################################
sub parseFile {
  my $self=shift;
  my $file=$self->getArgs()->{'filename'};
  open(F,"<$file") ||   $self->log("Could not open $file : $!\n") && die ("Aborting");
  my $seq;
  while (<F>) {
	chomp;
	##
	## skip comments and blank lines, shouldn't be in there anyway
	##
	next if ( (/^\s*\#/) || (/^\s+$/) );
	$self->log($_ . "\n") if $verbose;

	my @tmp = split(/\t/,$_);	
	if ($tmp[2] eq 'AA_sequence') {
	    $counter{'sequence'}++;
	
	    if ($verbose){
		$self->log("$tmp[2] $tmp[0] with UID $tmp[1] is the " . $counter{'sequence'} . ". sequence\n");
	    }	

	    ## if testnumber is reached then exit out of loop.	
	    last if (($self->getArgs()->{'testnumber'}) && ($counter{'sequence'} >= ($self->getArgs()->{'testnumber'})));
	    $self->log("Processing peptide ". $counter{'sequence'} ) if $verbose;
	    if ($seq) {

	      ####################
	      ### submit data of previous entry if $seq  exists
	      ####################

		$seq->submit();
		##following allows garbage collection...
		$self->undefPointerCache();
		#undef $seq;
	    }

	    $seq = $self->get_object(@tmp);
	    next unless ($seq);
	  } else {
	    ## if it is not an AA_sequence entry it must be a motif for the sequence
	    ## but if there has been an error while retrieving the sequence, 
	    ## there will be not object $seq
	    ## therefore skip until $seq defined (next AA_sequence entry)

	    ##########################
	    ### PROCESS/PARSE THE INPUT
	    ##########################
	    $self->process($seq,@tmp) if $seq;
	  }
      } ## end while LOOP
    $self->log("submitting ". $counter{'sequence'} . ". sequence\n") if $verbose;
    $seq->submit() if $seq;

  ## to submit last sequence

  ###########################
  ##    generate summary
  ###########################
  my $results= "Run finished: Processed ". $counter{'sequence'}." peptides\n";
  foreach my $key (keys %counter) {
    $results .= $counter{$key} . " $key\n";
  }
  $self->log("\n" . $results . "\n\n");
  return $results;

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
  my $projectId=$self->{'projectId'};
  my $extDbRelId=$self->{'extDbRelId'};
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

### if the projectlink is not set try to get aasequenceids with this query	
#	my $query="select tas.*
#from  dots.genefeature gf, dots.rnafeature rnaf, dots.translatedaafeature taf, dots.translatedaasequence tas
#where  gf.external_database_release_id = $extDbRelId
#and  rnaf.parent_id = gf.na_feature_id
#and  rnaf.na_feature_id = taf.na_feature_id
#and  taf.aa_sequence_id = tas.aa_sequence_id
#and  gf.source_id=\'$key\'";

	my $query="select tas.*
from  dots.genefeature gf, dots.projectlink pl, dots.rnafeature rnaf, dots.translatedaafeature taf, dots.translatedaasequence tas
where  gf.na_feature_id = pl.id
and  pl.table_id = 108
and  pl.project_id = $projectId
and  rnaf.parent_id = gf.na_feature_id
and  rnaf.na_feature_id = taf.na_feature_id
and  taf.aa_sequence_id = tas.aa_sequence_id
and  gf.source_id=\'$key\'";

	$self->log($query) if $verbose;
	my $stmt = $dbh->prepare($query);
	$stmt->execute();
	
	my $countRows = 0;
	while (my $row = $stmt->fetchrow_hashref('NAME_lc')) {
	    $seq = GUS::Model::DoTS::TranslatedAASequence->new($row);
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
	    #$self->setAaSeqId($seq->getAaSequenceId());
	    $self->log("II aa_sequence_id for $key is ".$seq->getAaSequenceId()) if $verbose;
	    return ($seq);
	}
    }
}  # end sub

####################################################
## Parses input files into appropriate variables
## and then calls subroutines to check/insert values
####################################################
sub process {
  my $self=shift;
  my($seq,@tmp) = @_;

  if (!$seq) {
    $self->log("EE sequence object does not exist");
    die ("Aborting...");
  }

  my $aa_sequence_id=$seq->getAaSequenceId();
  my $source_id = $tmp[0];
  $source_id=~s/\.pep$//;       #in case it is still there
  my $alg_name = $tmp[1];

  if ($verbose) {
    $self->log("II aa_)sequence_id is $aa_sequence_id");
    $self->log("II source_id is $source_id");
    $self->log("II alg_name is $alg_name");
  }

  ## WILL HAVE TO CHANGE THAT TO A GFF FORMAT INPUT, 
  ## SO I CAN GET RID OF THE ELSIF LOOPS, BUT I DO NOT WANT TO BE LIMITED TO 8 FIELDS

  ##################
  ## SignalpNN
  ##################
  if ($alg_name eq "SignalP") {
    my ($source_id, $algorithm, $featuretype, $maxC_position, $maxC_value, $maxC_cutoff,
        $maxC_conclusion, $maxY_position, $maxY_value, $maxY_cutoff, $maxY_conclusion,
        $maxS_position, $maxS_value, $maxS_cutoff, $maxS_conclusion, $meanS_start, $meanS_stop,
        $meanS_value, $meanS_cutoff, $meanS_conclusion, $quality, $signal)   = @tmp;

    my %hash=(
	      'algorithm_name'    => $algorithm,
	      'prediction_algorithm_id' => $alg_id{$algorithm},
	      'description'       => $desc{$algorithm},
	      'name'              => $featuretype,
	      'maxc_score'        => $maxC_value,
	      'maxc_conclusion'   => &conclude($maxC_conclusion),
	      'maxy_score'        => $maxY_value,
	      'maxy_conclusion'   => &conclude( $maxY_conclusion),
	      'maxs_score'        => $maxS_value,
	      'maxs_conclusion'   => &conclude( $maxS_conclusion),
	      'means_score'       => $meanS_value,
	      'means_conclusion'  => &conclude( $meanS_conclusion),
	      'num_positives'     => $quality
	     );
    my $feature = $self->createPredictedAAFeature($aa_sequence_id, \%hash, $meanS_start, $meanS_stop);
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
      my %hash=(
		'algorithm_name'    => $algorithm,
		'prediction_algorithm_id' => $alg_id{algorithm},
		'description'       => $desc{$algorithm},
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
	       );
      my $feature = $self->createPredictedAAFeature($aa_sequence_id, \%hash);
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

    my %hash=(
	      'algorithm_name'         => $alg_name,
	      'prediction_algorithm_id'=> $alg_id{$alg_name},
	      'description'            => $desc{$alg_name},
	      'name'                   => 'TMHelix',
	      'score'                  => $score
	     );

    my $feature = $self->createPredictedAAFeature($aa_sequence_id, \%hash, $start, $stop);
 
    if ($feature) {
	$seq->addChild($feature);
	$counter{'tmpred'}++;
    } else {
	$self->log("EE Unable to create PredictedAAFeature Tmpred for $source_id,  $alg_name");
	$counter{'unprocessed_Tmpred'}++;
    }

  }    # END TMPRED

  ##################
  ## TMHMM2
  ##################
  elsif ($alg_name=~/TMHMM2/) {

    my ($file,$algorithm,$featuretype,$start,$stop,undef,undef,undef)=@tmp;
    $algorithm=~s/\.\d+$//; #remove trailing .0
    my %hash=(
	      'algorithm_name'         => $algorithm,
	      'prediction_algorithm_id'=> $alg_id{$algorithm},
	      'description'            => $desc{$algorithm},
	      'name'                   => 'TMHelix'
	     );
    my $feature = $self->createPredictedAAFeature($aa_sequence_id, \%hash, $start, $stop);

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
    my %hash=(
	      'algorithm_name'         => $algorithm,
	      'prediction_algorithm_id'=> $alg_id{$algorithm},
	      'description'            => $desc{$algorithm},
	      'name'                   => 'TMHelix',
	      'score'                  => $helix_score
	     );
    my $feature = $self->createPredictedAAFeature($aa_sequence_id, \%hash,$helix_begin, $helix_end );

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
     my %hash=(
	      'algorithm_name'         => $algorithm,
	      'prediction_algorithm_id'=> $alg_id{$algorithm},
	      'description'            => $desc{$algorithm},
	      'name'                   => 'TMHelix',
	     );
    my $feature = $self->createPredictedAAFeature($aa_sequence_id, \%hash,$start,$stop);

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
	 
    my ($file,$algorithm,$featuretype,$database,$score1,$score2,$start,
	$stop,$donknow1,$donknow2,$PSID,$PSABBR,$PS_TITLE) = @tmp;

    my %hash=();
    my $feature = $self->createPredictedAAFeature(\%hash);

    my $feature = $self->createNewPredictedAAFeature($source_id, 
						     "PROSITE motif $PSID, accession $PS_TITLE",
						     $alg_name, 'PROSITE motif', 
						     $score1, $start, $stop);
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
    my %hash=(
	      'source_id'  => $PSACC,
	      'name'       => 'PROSITE motif',
	      'motif'      => $PSID,
	      'description'=> $desc{$algorithm} ,
	     );

    my $feature = $self->createPredictedAAFeature($aa_sequence_id, \%hash, $start,$stop);

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
					       'release'   => $self->getArgs()->{'pfamRel'},
					       'accession' => $accession,
						}
					       );
    $pf->retrieveFromDB() || $self->log( "EE Could not retrieve PFAMEntry for SOURCE $source_id :  PfamId: $accession") && $counter{'notInDb_Pfam'}++ && return undef;
 
    my $motif_id=$pf->getPfamEntryId; 

    my %hash=(
	      'source_id'  => $accession,
	      'name'       => 'PFAM motif',
	      'description'=> $desc{$algorithm}
	      'prediction_algorithm_id'=>$alg_id{$algorithm},
	      'pfam_entry_id' => $motif_id,
	      'score'         => $score
	     );


    my $feature = $self->createPredictedAAFeature($aa_sequence_id, \%hash, $start,$stop);

    ## if the feature exists, we might want to update it (e.g. is values are missing)....
    if ($feature==1){
      $self->log("EE Cannot create the new HmmPFAM Feature.Query too unspecific. Returning....");
      $counter{'unspecific_Pfam'}++;
      return;
    }elsif($feature->getAaFeatureId() ){
      $self->log ("II Got HmmPfamFeature with ID " .$feature->getAaFeatureId() . "....") if $verbose;
      unless ($self->getArgs()->{'reload'}){
	$self->log("EE Cannot create the new HmmPFAM Feature. Returning....");
	$counter{'exists_Pfam'}++;
	return;
      }
      $self->log( "II Setting MotifID $motif_id for FeatureId " .$feature->getAaFeatureId()." ....");
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

########################################################################
##
########################################################################
sub setExtDbId {
  my $self = shift;
  my $src = shift;
  $self->log("Finding ExternalDatabaseId ....");

  # ExternalDatabase
  my %extdb;
  $extdb{lowercase_name} = $src;

  my $extdb_gus = GUS::Model::SRes::ExternalDatabase->new(\%extdb);
  if ($extdb_gus->retrieveFromDB){
      $self->{'extDbId'} = $extdb_gus->getExternalDatabaseId;
  }
  else {
    $self->log("EE error in returning ExtDbId");
    return undef;
  }
  return 1;
}

sub getExtDbId {
  my $self=shift;
  return $self->{'extDbId'};
}

######################################################################
sub setProjId {
  my $self = shift;
  $self->log("Finding Project ". $self->getArgs()->{'Project'} );

  my %project = ( name => $self->getArgs()->{'Project'} );
  my $project_gus = GUS::Model::Core::ProjectInfo->new(\%project);
  if ($project_gus->retrieveFromDB) {
    $self->{'projectId'} = $project_gus->getId;
  } else {
    $self->log("EE Error while determining ProjectID of project " . $self->getArgs()->{'Project'} );
    return undef;
  }
  return 1;
}

sub getProjectId {
  my $self=shift;
  return $self->{'projectId'};
}

######################################################################

sub setExtDbRelId {
  my $self = shift;
  my $T = shift;

  my $id = $self->getExtDbId;   # the external_database_id;
  $self->log("the external_database_id = ". $id);
  $self->log("Finding ExternalDatabaseReleaseId...");

  # ExternalDatabaseRelease
  my %extdbrel;
  $extdbrel{external_database_id} = $id;
  $extdbrel{version} = 'unknown';  ## NOTE: may need to be modified

  my $extdbrel_gus = GUS::Model::SRes::ExternalDatabaseRelease->new(\%extdbrel);
  if ($extdbrel_gus->retrieveFromDB){
   $self->{'extDbRelId'} = $extdbrel_gus->getExternalDatabaseReleaseId;
  }
  else {
    $self->log( "EE error returning ExtDbRelId");
    return undef;
  }
  return 1;
}

sub getExtDbRelId {
  my $self=shift;
  return $self->{'extDbRelId'};
}

#######################################################
## Checks if AAFeature already exists.
## for some we will need separate subs (see below)
#######################################################

sub existenceAAFeature{
  my $self=shift;
  my ($aa_sequence_id, $algName, $featureName, $score, $start, $stop) = @_;

  my %TABLE = (
               'SIGNAL'   => 'signalpeptidefeature',
	       'PlasmoAP' => 'plasmoapfeature',
	       'PFAM'     => 'motif'
	       'PROSITE'  => 'motif'
              );

  my $tableName=(exists $TABLE{$algName})?  $TABLE{$algName}: "predictedaafeature";

  my $dbh = $self->getQueryHandle();
  my $sql = "select paf.name, paf.algorithm_name, paf.description,
                paf.score, aal.start_min, aal.end_max
                from dots.TranslatedAAFeature taf,
                dots.$tableName paf, sres.AALocation aal,
                dots.ProjectLink pl
                where taf.aa_sequence_id = $aa_sequence_id
                and taf.aa_sequence_id = paf.aa_sequence_id
                and paf.aa_feature_id = aal.aa_feature_id
                and paf.algorithm_name = \'$algName\'
                and aal.start_min=$start
                and aal.end_max=$stop
                and paf.name = \'$featureName\' ";


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
      $self->log("II SQL returned AaFeatureId " . $paf->getAaFeatureId());
      return ($paf);
  }elsif($countRows>1){
      $self->log("EE sub existenceAAFeature : $countRows rows returned, featurequery is
 not stringent enough");
      return 1;
  } else {
      $self->log("II No rows returned for query");
    return undef;
  }
} #end Sub

#######################################
# Create the new PredictedAAFeature
#######################################
sub createPredictedAAFeature {
  my $self=shift;
  my ($AaSequenceId, $thashref, $start,$stop)=@_;
  my %thash = %$thashref;
  my $alg_name= $thash{algorithm_name};
  my $desc    = $desc{algorithm_name};

  my $exists=$self->existenceAAFeature($AaSequenceId, $thash{algorithm_name}, $thash{name}, $start, $stop);

  if ($exists) {
      $self->log("EE predictedAAFeature exists. Returning ...");
      return 0;
  }
  my $newFeature;
  if ($alg_name=~m/signal/i){
    $newFeature= GUS::Model::DoTS::SignalPeptideFeature->new(\%thash);
  }elsif($alg_name=~m/(PFAM|PROSITE|PFSCAN|PATMATMOTIF)/i){
    $newFeature= GUS::Model::DoTS::Motif->new(\%thash);
  }elsif($alg_name=~m/PlasmoAP/i){
    $newFeature= GUS::Model::DoTS::PlasmoAPFeature->new(\%thash);
  }else{
    $newFeature= GUS::Model::DoTS::PredictedAAFeature->new(\%thash);
  }

  $newFeature->setIsPredicted(1);	
  $newFeature->setReviewStatusId(0);

  #
  # Create the AALocation object and add it as a child of
  # the created PredictedAAFeature.
  #
  if ($newFeature && $thash{start} && $thash{stop} ){
    my $aa_location = &createNewAALocation($thash{start}, $thash{stop});
    $newFeature->addChild($aa_location) if $aa_location;
    $self->log( $newFeature->toString()) if $verbose;
    return $newFeature;
  }elsif($newFeature){
    # if there should be a feature without start and stop information
    return $newFeature;
  }
  return 0;
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
## Checks if HmmPfamFeature already exists and Updates
## Entry
#######################################################
sub UpdateSignalPeptideHMMFeature {
  my $self=shift;
  my ($source_id, $algorithm,$featuretype, 
      $prediction, $SPP, $SAP, $CSP, $start, $signal) = @_;
  $source_id=~s/\.pep$//;
  my ($SignalPeptideFeature, $aafid)=$self->existencAAFeature($source_id, $algorithm, $featuretype, 1, $start);
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

###############################
## Convert human readable 'yes'
## to digital answer
###############################
sub conclude{
  my $value=shift;
  my $answer=($value=~m/yes/i) ? 1 : 0;
  return $answer;
}

###############################
##   set the AlgInvId
##
###############################
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


################################
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




