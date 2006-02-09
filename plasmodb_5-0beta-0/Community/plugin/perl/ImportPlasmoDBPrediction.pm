package GUS::Community::Plugin::ImportPlasmoDBPrediction;

# $Id$ 


@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
use GUS::Model::Core::Algorithm;
use GUS::Model::Core::ProjectInfo;
use GUS::Model::DoTS::GeneFeature;
use GUS::Model::DoTS::ExonFeature;
use GUS::Model::DoTS::ExternalNASequence;
use GUS::Model::DoTS::NAFeatureComment;
use GUS::Model::DoTS::NALocation;
use GUS::Model::DoTS::ProjectLink;
use GUS::Model::DoTS::RNAFeature;
use GUS::Model::SRes::ExternalDatabaseRelease;
use GUS::Model::SRes::ExternalDatabase;

sub new {
  my $class = shift;
  my $self = {};
  my $usage = 'loads gene features from an XML data file...';

  my $easycsp =
    [
     { h => 'project name',
       t => 'string',
       o => 'Project'
     },
     {
      t => 'int',
      o => 'testnumber',
      h => 'Number of iterations for testing'
     },
     {
      t => 'string',
      o => 'restart',
      h => 'For restarting script...takes list of row_alg_invocation_ids to exclude'
     },   
     {
      t => 'string',
      o => 'dataSource',
      h => 'Name of the data source; e.g. plasmodium-vivax_tigr',
     },
     {
      t => 'string',
      o => 'filename',
      h => 'Name of file(s) containing the predicted gene features',
     },
     {
      t => 'int',
      o => 'NAseqId',
      h => 'supply NA_sequence_id of origin of gene features'
     },
     {
       t => 'int',
       o => 'extDbRelId',
       h => 'supply the external_database_release_id'
     }
    ];

  bless($self, $class);
  $self->initialize({
		     requiredDbVersion => {},
		     cvsRevision => '$Revision$ ',
# keyword filled in by cvs

		     cvsTag => '$Name$ ',
# keyword filled in by cvs
		     name => ref($self),
		     revisionNotes => 'first pass of plugin for GUS 3.0',
		     easyCspOptions => $easycsp,
		     usage => $usage
		    });

  return $self;
}


############################################################
#                Let's get started
############################################################
#my $debug = 0;  #my personal debug !!

my $NAseqId;
my $Version;
my $source_id;
my %data;
my %allFeatures;
$| = 1;

### Expected format of input file
### Not exactly gff, but woiks:

#>> 395454.phat_1        395454  FullPhat        predicted_gene  36      6338    +       0       3
#395454  FullPhat        exon    36      1899    0.43    +       0       na      395454.phat_1   1       intl    frame "2"
#395454  FullPhat        exon    1992    4696    0.91    +       2       na      395454.phat_1   2       intl    frame "1"
#395454  FullPhat        exon    4877    6338    0.81    +       0       na      395454.phat_1   3       intl    frame "1"
#
#>> 395455.phat_1        395455  FullPhat        predicted_gene  25      6838    -       0       4
#395455  FullPhat        exon    6725    6838    0.87    -       0       na      395455.phat_1   1       init    frame "1"


#####
# RUN
#####

sub run {
  my $self = shift;
  my $debug   =  $self->getArgs()->{'verbose'} ? 1: 0;

  my $project =  $self->getArgs()->{'Project'};
  $source_id  =  $self->getArgs()->{'source_id'};
  $NAseqId    =  $self->getArgs()->{'NAseqId'};


  unless ($project=~m/\S+/){
    $self->log("EE Please specify the project, e.g. with --Project=PlasmodiumDB-4.1");
    return 0 ;
  }
  unless ($self->getArgs()->{'dataSource'}=~m/\S+/){
    $self->log("EE Please specify the dataSource, e.g. \'plasmodium_vivax_tigr\'");
    return 0 ;
  }

  $self->setProjId($project) || $self->log("EE Could not set the projectId");
  my $projectId= $self->getProjId();
  $self->log("II Determined projectId= " . $projectId );

  my $extDbRelId;
  if ($self->getArgs()->{'extDbRelId'}=~m/(\d+)/ ){
    $extDbRelId=$1;
  }else{
    $self->setExtDbId($self->getArgs()->{'dataSource'})|| $self->log("EE Could not set the extDbId");
    $self->setExtDbRelId() || $self->log("EE Could not set ExtDbRelId: ***CRITICAL**");
    $extDbRelId=$self->getExtDbRelId();
  }


  $self->log("II Determined extDbRelId= " . $extDbRelId );

  unless ($source_id=~m/^\S+$/ || $NAseqId=~m/^\d+$/){
    $self->log("EE source_id or na_sequence_id has not been set, will use source_id supplied by genegff-file")
  }

  if ($debug){
    $self->log("II Project: $project");
    $self->log("II ". $self->getArgs()->{'commit'}==1 ? "II *** COMMIT ON ***" : "II *** COMMIT TURNED OFF ***");
    $self->log("II Testing plugin on ". $self->getArgs()->{'testnumber'} . " examples\n") if $self->getArgs()->{'testnumber'};
    $self->log("II Using External_db_release_id: $extDbRelId");
    $self->log("II Project_id:     $projectId");
    $self->log("II Source_id:      $source_id");
    $self->log("II NA_sequence_id: $NAseqId");
  }


  ## PARSE THE GENEGFF FILE
  ## a couple of counters for the result
  my $contigcount=0;
  my $exoncount=0;
  my $genecount=0;
  
  ## Parse features og .genegff-file into appropriate hashes
  my %genes=();
  my %exon=();
  my %coord=();
  my %method=(
	      'Phat'       => '83',
	      'FullPhat'   => '83',
	      'GlimmerM'   => '47',
	      'GeneFinder' => '84'
	     );
  my ($genename,$contig,$method,$type,$start,$stop,$strand,$phase,$numexons,$key,$transfer,$is_initial);
  my ($is_final,$haveExons,$order_number,$score,$exon);

  open(FILE, $self->getArgs()->{'filename'}) or die ( $self->getArgs()->{'filename'}. "\n$!\n");
  while (<FILE>){
    if (/^\>\>/){
      my $gene = $_;
      chomp($gene);
      ($genename,$contig,$method,$type,$start,$stop,$strand,$phase,$numexons) = (split /\t/,$gene);
      #$self->log("II GENE $genename $contig,$method,$type,$start,$stop,$strand,$phase,$numexons");
      if ($genename eq ""){
	$self->log( "EE Oops. One entry empty !! Skipping ...");
	next;
      }
      $genename=~s/^\>\>\s*//g;
      $genes{$contig}.="$genename\t";
      $numexons=~s/\s+//;
      $transfer=[$genename,$contig,$method,$type,$start,$stop,$strand,$phase,$numexons];
      $coord{$genename}=$transfer;
    }else {
      next if ($genename eq "");
      $exon{$genename}.=$_;
    }
  }
  close FILE;


  ## DONE PARSING

  if ($debug){
    $self->log( scalar(keys %genes) . " contigs found");
  }

  ## execute loop:  foreach contig of chromosome (keys %genes)->Sorry, that the naming is misleading
  ## BTW: every genegff file can contain genemodels of multiple contigs, since this plugin has 
  ## evolved out ot the need to load gene predictions for unfinished contig data
	
  foreach my $key (keys %genes){

    $self->log( "II working on contig $key") if $debug;
    # retrieve the sequence_id to which the features will be linked
    # external_db_id for PlasmoDB_RoosLab is '151'
    # source_id is eqivalent to contig id of PlasmoDB ($key)
    # unless specified otherwis on the CL with --source_id option

    #prepare connection to DB
    my $dbh = $self->getQueryHandle();

    # get the sequence_object
    my $naseq;

    ## if na_sequence_id specified, retrieve object by id
    if ($NAseqId){
      $naseq = GUS::Model::DoTS::ExternalNASequence->new({ na_sequence_id => $NAseqId });
      $naseq->retrieveFromDB(['sequence']); # all but sequence		

      ## BREAK IF NO SEQUENCE OBJECT
      unless ($naseq){
	my $errormessage="EE $NAseqId did not retrieve a sequence object";
	$self->log($errormessage);
	$self->undefPointerCache();
	return 0;
      }
		
    }else{
      ## ELSE GET THE NASEQUENCE OBJECT FOR THE CONTIG, USING SOURCE_ID (if specified)
      ## OR SEQUENCE NAME ($key; which should be the same as source_id)

      $self->log( "II no na_sequence_id provided for source_id $key. Querying database ...") if $debug;
      my $sql="SELECT s.*  FROM dots.ExternalNASequence s, dots.ProjectLink pl WHERE s.source_id=? AND pl.table_id = 89 AND pl.id = s.na_sequence_id AND pl.project_id = ?";

      my $stmt = $dbh->prepare($sql) || $self->log("could not prepare statement: $!\nSQL:\n$sql") && die ("Aborting...");

      $self->log("II SQL:\n$sql") if $debug;

      ## execute statement with source_id if specified on CL
      ## or use 'chr1' notation if otherwise
      if ($source_id) {
	$stmt->execute($source_id, $projectId);
      }else{ 

	## NOT A GOOD HACK
	##  used by MFG, when Pv_ was not at start of vivax source_id
	## $stmt->execute("Pv_".$key, $projectId );

	$stmt->execute($key, $projectId );
      }
		
		
      my $countRows = 0;
      while(my $row = $stmt->fetchrow_hashref('NAME_lc')){
	$naseq= GUS::Model::DoTS::ExternalNASequence->new($row);	    
	$countRows++;
      }
      
      ## ERROR AND EXIT ON TOO MANY OR ZERO RETURNED ROWS
      my $contigid=($source_id) ? $source_id : $key;
      if ($countRows > 1){
	my $errormessage="EE query with $contigid returns $countRows rows";
	$self->log($errormessage);
	$self->undefPointerCache();
	return 0;
      }elsif($countRows < 1){
	my $errormessage="EE query with $contigid returned no rows";
	$self->log($errormessage);
	$self->undefPointerCache();
	return 0;
      }else{
	if ($debug){
	  $self->log( "II NAsequence: $countRows row returned for $contigid");
	}
      }
    }


    # get the genelist for each contig
      my @todogene=split(/\t/,$genes{$key});

    ## FOREACH GENE
    foreach my $tdg (@todogene){
      my $transl_start;
      my ($ggenename,$gcontig,$gmethod,$gtype,$gstart,$gstop,$gstrand,$gphase,$gnumexons) = @{$coord{$tdg}};

      $self->log("II Making GeneFeature for $ggenename") if $debug;


      # Gotta set the 'external_database_release_id', I guess....
      my $gf = GUS::Model::DoTS::GeneFeature->new({
						   'name' => 'GeneFeature',
						   'is_predicted' => 1,
						   'external_database_release_id' => $extDbRelId,
						  });

      ######
      ###### TO WHAT DO I HAVE TO SET EXTDBRELID, IF I (PLASMODB) 
      ###### PREDICTS GENES FOR DATA GENERATED BY TIGR/SANGER/ETC   ????
      ######

      #################################
      # if a gene is not 5' terminal complete the translationstart for the exonfeature is
      # given in $gphase (for genes !!)	
      # A workaround: difference between PHAT \/ Genefinder+GlimmerM
      # until I change the parsing method elsewhere
      ######
      my $regulation;
      if ($gphase!=0){
	if ($gmethod=~m/phat/i){
	  $regulation = $gphase;     ## in the case of PHAT
	  $self->log( "II A- $gmethod phase=$gphase") if $debug;
	}else{
	  $regulation = (3-$gphase); ## in the case of GlimmerM and Genefinder
	  $self->log( "II B- $gmethod phase=$gphase regulation=$regulation");
	}
      }else{
	$regulation=0;
	$self->log( "II C- $gmethod phase =$phase regulation=$regulation");
      }
      $gphase=$regulation;
      ######
      #
      ###### END WORKAROUND#############
	

      #determine the translation start of the gene -> to be set in the first exon feature
      if ($gphase!=0){
	$transl_start = ($gphase+1);
	$self->log( "II $ggenename GP=$gphase -> TS=$transl_start") if $debug;
      }else{
	$transl_start=1;
      }
	
	
      ##set some  GeneFeature  attributes
      $gf->setParent($naseq);
      $gf->setReviewStatusId(0);
      ## $gf->setGeneType('protein_coding');
      $gf->setGeneType('protein coding');
      $gf->setSourceId($ggenename);
      $self->log("II Setting gf->source_id to $ggenename") if $debug;
      $gf->setPredictionAlgorithmId($method{$gmethod});
      $gf->setNumberOfExons($gnumexons);
	
      ##set the location for the GeneFeature
      my $isrev = $gstrand eq "+" ? 0 : 1;
      my $loc = &makeNALocation($gstart,$gstop,0,$isrev);
      $gf->addChild($loc) if $loc;
	
      # Now add the ExonFeatures for the current GeneFeature
      # Exons for the gene 'ggenename' are stored in an array within the hash %exon
      $self->log( "II Making ExonFeatures for $ggenename") if $debug;
      my @todoexon=split(/\n/,$exon{$ggenename});
		
		
	## FOREACH EXON
	## Exoncounter j
	my $j=0;
	foreach my $ex (@todoexon){
	  my ($econtigname,$emethodname,$etype,$estart,$estop,
	      $equality,$estrand,$startphase, $endphase,$egenename,
	      $eorder,$extype,$eframe) = split(/\t/,$ex);
	
	  next if ($estart eq ""); # can happen -> reject;
	
	  my $etransl_start = ($eorder==1) ? $transl_start : 1;
	  $self->log( "II EXON $egenename: TS=$etransl_start") if ($transl_start != 1) && $debug ;
	  #
	  # if the predicted gene does not begin with an initial but an internal exon
	  # i.e. the ATG is off the Contig (especially when dealing with small contigs in unfinished data), 
	  # then set the translation start of the initial exon
	  #

	  $self->log( "II Making ExonFeatures for $egenename") if $debug;
	  $is_final  = ($extype=~m/term/i) ? 1 : 0;
	  $is_initial= ($extype=~m/init/i) ? 1 : 0;
	
	  #is_initial should probably be set by: ($eorder==1) ? 1 : 0;
	  #but it is not true for incomplete genes !!!
	  #errors from incomplete genefinder predictions expected!

	  $score  = ($equality eq "na") ? undef : $equality;
	
	  my $exon = GUS::Model::DoTS::ExonFeature->new({
							 'name'              => 'ExonFeature',
							 'na_sequence_id'    => $naseq->getNaSequenceId(),
							 'is_predicted'      => 1,
							 'review_status_id'  => 0,
							 'is_initial_exon'   => $is_initial,
							 'is_final_exon'     => $is_final,
							 'order_number'      => $eorder,
							 'coding_start'      =>	$etransl_start,
							 #'coding_start'      => 1,
							 'reading_frame'     => $etransl_start,
							 'source_id'         => $ggenename."_e".$eorder          #set source_id to that of gene + exon_ordernumber
						     });
	
	  if ($is_final)  {$gf->setHasFinalExon(1)}
	  if ($is_initial){$gf->setHasInitialExon(1)}
	  $exon->setScore($score) if $score;
	  $exon->setCodingEnd($estop-$estart+1);
	  $exon->setParent($naseq);

	  ## Add the location for the ExonFeature
	  my $naloc = &makeNALocation($estart,$estop,$eorder,$isrev);
	  $exon->addChild($naloc) if $naloc;
	  $gf->addChild($exon) if $exon;
	  $exoncount++;
	  $j++;
	}  # END foreach exon



		
      ###
      ### set the AA and SNAS sequences
      ###

      ### check to make certain, that GF has actually exons...
      $haveExons = $gf->getChildren('DoTS::ExonFeature') ? 1 : 0;
		
      ##now create rnafeature and translated features and protein
      if($haveExons){

	$gf->makePredictedRnaToProtein(undef, $extDbRelId ,  $ggenename );


	my $rna = $gf->getChild('DoTS::RNAFeature');
	$rna->setReviewStatusId('0');

	my $tas = $gf->getChild('DoTS::RNAFeature')->getChild('DoTS::TranslatedAAFeature')->getParent('DoTS::TranslatedAASequence');
	$tas->setDescription("predicted gene");	
	$self->log("AASEQ: ". $tas->getSequence()) if $debug;  #just to see if frame is continuous

	my $snas = $rna->getParent('DoTS::SplicedNASequence');
	my $t=$snas->getSequence();
	$self->log("II Setting SplicedNASequenceSNAS") if $debug;
	#$self->log("SNAS:\n" . $snas->getSequence() ) if $debug;
      }
	

      $gf->submit();

      ##MakeProjectLink
      $self->makeProjLink($gf);

      $genecount++;
      $self->log( "II genecount $genecount") if $debug;


      #limit the test to a number of genes for testing
      last if ( ( $self->getArgs()->{'testnumber'} )  &&  ( $genecount > $self->getArgs()->{'testnumber'} )  );

      $self->undefPointerCache();

    } #end foreach gene 
    last if ( ( $self->getArgs()->{'testnumber'} )  &&  ( $genecount > $self->getArgs()->{'testnumber'} )  );
    $contigcount++;
  } # end foreach contig (keys)
  my $results = "Processed " . $contigcount ." contig(s) with $genecount gene features and a total of " . $exoncount . " exon features\n\n";
  return $results;
} # end Run loop



#######################################################
## Make a location !!
#######################################################
sub makeNALocation {
    my($start,$end,$order,$is_reversed) = @_;    return undef if (!$start || !$end);
    my $l = GUS::Model::DoTS::NALocation->new({'start_min' => $start,
			     'start_max' => $start,
			     'end_min' => $end,
			     'end_max' => $end});
    $l->set('loc_order',$order) if $order;
    $l->set('is_reversed',$is_reversed);
    return $l;
}
# --------------------------------------------------------------------

sub makeProjLink {
  my $self = shift;
  my $T = shift;         # table object;


  my %plink;
  # table
  $plink{table_id} = $T->getTableIdFromTableName($T->getClassName);
  $plink{id}       = $T->getId();

  my $projlink_gus = GUS::Model::DoTS::ProjectLink->new(\%plink);
  if ($projlink_gus->retrieveFromDB) {
    # case when projectLink is in dB
    $self->log ("ProjectLink already in DB with ID " . $projlink_gus->getId);
    return undef;
  } else {
    $projlink_gus->setProjectId($self->getProjId());
    # using setParent method here creates a NEW row in ProjectInfo table, if needed:
    # $projlink_gus->setParent($project_gus);
    $projlink_gus->submit();
    return 1;
  }
}


# --------------------------------------------------------------------
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

# --------------------------------------------------------------------
sub setProjId {
  my $self = shift;
  $self->log("Finding Project ". $self->getArgs()->{'Project'} );

  my %project = ( name => $self->getArgs()->{'Project'} );;

  my $project_gus = GUS::Model::Core::ProjectInfo->new(\%project);
  if ($project_gus->retrieveFromDB) {
    $self->{'projectId'} = $project_gus->getId;
  } else {
    $self->log("EE Error while determining ProjectID of project " . $self->getArgs()->{'Project'} );
    return undef;
  }
  return 1;
}

sub getProjId {
  my $self=shift;
  return $self->{'projectId'};
}

# --------------------------------------------------------------------

sub setExtDbRelId {
  my $self = shift;
  my $T = shift;

  my $id = $self->getExtDbId;   # the external_database_id;
  $self->log("the external_database_id = ". $id);
  $self->log("Finding ExternalDatabaseReleaseId...");

  # ExternalDatabaseRelease
  my %extdbrel;
  $extdbrel{external_database_id} = $id;
  #$extdbrel{version} = 'unknown';  ## NOTE: may need to be modified
  $extdbrel{version} = 'final';

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
