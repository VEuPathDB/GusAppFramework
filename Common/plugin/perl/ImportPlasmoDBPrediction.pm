package GUS::Common::Plugin::ImportPlasmoDBPrediction;

# $Id$ 

# Martin Fraunholz

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



sub new {
  my $class = shift;
  my $self = {};
  my $usage = 'loads gene features from an XML data file...';

  my $easycsp =
    [
     # JC: Is this parameter used?  Should probably be used in place of project_id.
     { h => 'project name',
       t => 'string',
       o => 'Project',
       d => 'PlasmodiumDB-4.1'
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
      o => 'filename',
      h => 'Name of file(s) containing the predicted gene features',
     },
#     {
#      o => 'source_id',
#      t => 'string',
#      h => 'Source_id of origin of gene features',
#     },
#     {
#      o => 'NAseqId',
#      t => 'int',
#      h => 'NA_sequence_id of origin of gene features'
#     },
     {
      o => 'projectId',
      t => 'int',
      h => 'project_id of this release',
      d => 900
     },
     {
      o => 'extDbRelId',
      t => 'int',
      h => 'external database identifier for the contigs',
      d => 692
     },
     {
      t => 'boolean',
      o => 'reload',
      h => 'For loading new Ids and scores for HmmPfam entries',
     },
     {
      t => 'boolean',
      o => 'parseSequence',
      h => 'Experimental : parsing out the AA sequences to set them in the DB, default: OFF',
      d => 0
     },
     # JC: Isn't --commit provided by default?
     {
      t => 'boolean',
      o => 'commit',
      h => 'Set flag to commit changes to database. Default: off',
      d => 0,
     }
    ];

  bless($self, $class);
  $self->initialize({
		     requiredDbVersion => {},
		     cvsRevision => '$Revision$ ',# keyword filled in by cvs
		     cvsTag => '$Name$ ',     # keyword filled in by cvs
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
my $ctx;
my $debug = 1;  #my personal debug !!
my $projectId;
my $NAseqId;
my $Version;
my $extDbRelId;
my $source_id;
my %data;
my %allFeatures;
$| = 1;


#####
# RUN
#####

sub run {
  my $self = shift;
  #$ctx=shift;

  #$extDbRelId = $ctx->{cla}->{'extDbRelId'};
  $extDbRelId =  $self->getArgs()->{'extDbRelId'};

  $projectId  =  $self->getArgs()->{'projectId'};
  #$projectId = $ctx->{cla}->{'projectId'};

#  $source_id = $self->getArgs()->{'source_id'};
# # $source_id = $ctx->{cla}->{'source_id'};

#  $NAseqId = $self->getArgs()->{'NAseqId'};
# # $NAseqId = $ctx->{cla}->{'NAseqId'};



  unless ($projectId=~m/\d+/){
    $self->log("EE Please specify the project_id, e.g. with --project_id=900");
    return 0 ;
  }
  unless ($extDbRelId=~m/\d+/){
    $self->log("EE Please specify the external_db_release_id, e.g. with --extDbRelId=151");
    return 0;
  }
  unless ($source_id=~m/^\S+$/ || $NAseqId=~m/^\d+$/){
    $self->log("EE source_id or na_sequence_id has not been set, will use source_id supplied by genegff-file")
  }

  if ($debug){
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
	      'FullPhat'   => '83',
	      'GlimmerM'   => '47',
	      'Genefinder' => '84'
	     );
  my ($genename,$contig,$method,$type,$start,$stop,$strand,$phase,$numexons,$key,$transfer,$is_initial);
  my ($is_final,$haveExons,$order_number,$score,$exon);

  open(FILE, $self->getArgs()->{'filename'}) or die ( $self->getArgs()->{'filename'}. "\n$!\n");
  while (<FILE>){
    if (/^\>\>/){
      my $gene = $_;
      chomp($gene);
      ($genename,$contig,$method,$type,$start,$stop,$strand,$phase,$numexons) = (split /\t/,$gene);
      $self->log("II GENE $genename $contig,$method,$type,$start,$stop,$strand,$phase,$numexons");
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
      ## ELSE GET THE NASEQUENCE OBJECT FOR THE CONTIG, USING SOURCE_ID
      $self->log( "II no na_sequence_id provided for source_id $key. Querying database ...") if $debug;
      my $sql="SELECT s.*  FROM dots.ExternalNASequence s, dots.ProjectLink pl WHERE s.source_id=? AND pl.table_id = 89 AND pl.id = s.na_sequence_id AND pl.project_id = ?";

      my $stmt = $dbh->prepare($sql) || $self->log("could not prepare statement: $!\nSQL:\n$sql") && die ("Aborting...");

      $self->log("II SQL:\n$sql") if $debug;

      ## execute statement with source_id if specified on CL
      ## or use 'chr1' notation if otherwise
      if ($source_id) {
	$stmt->execute($source_id, $self->getArgs()->{'projectId'});
      }else{ 

	##### MJF
	##### BIIIIIG WORKARAOUND, SINCE OFR VIVAX DATA I DID NOT HAVE THE PV_ ADDITION TO THE  SOURCE_ID
	#####
	#####    $key is actually "Pv_". $key for this query only;
	#####

	$stmt->execute("Pv_".$key, $self->getArgs()->{'projectId'} );
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

    #$self->log($naseq->getSequence());

    # get the genelist for each contig
      my @todogene=split(/\t/,$genes{$key});
      
    ## FOREACH GENE
    foreach my $tdg (@todogene){
      my $transl_start;
      my ($ggenename,$gcontig,$gmethod,$gtype,$gstart,$gstop,$gstrand,$gphase,$gnumexons) = @{$coord{$tdg}};
      
      $self->log("II Making GeneFeature for $ggenename") if $debug;
      $self->log("II Got gene data:$ggenename,$gcontig,$gmethod,$gtype,$gstart,$gstop,$gstrand,$gphase,$gnumexons") if $debug;
      
      my $gf = GUS::Model::DoTS::GeneFeature->new({
						   'name' => 'GeneFeature',
						   'is_predicted' => 1,
						   #'na_sequence_id' =>  $naseq->getNaSequenceId()
						  });
      
	
      #######
      # if a gene is not 5' terminal complete the translationstart for the exonfeature is
      # given in $gphase (for genes !!)	
      # A workaround: difference between PHAT \/ Genefinder+GlimmerM
      # until I change the parsing
      ######
      my $regulation;
      if ($gphase!=0){                 
	if ($gmethod!~/phat/i){
	  $regulation = (3-$gphase);
	}else{
	  $regulation = $gphase;
	} 
      }else{
	$regulation=0;
      }
      $gphase=$regulation;	    
      ###### END WORKAROUND
	
      if ($gphase!=0){
	$transl_start = ($gphase+1);
	$self->log( "II $ggenename GP=$gphase -> TS=$transl_start");
      }else{
	$transl_start=1;
      }
	
	
      ##set the sequence attributes:
      #$naseq->addChild($gf);
      $gf->setParent($naseq);
      $gf->setReviewStatusId(0);
      $gf->setGeneType('protein_coding');

      $gf->setExternalDatabaseReleaseId($extDbRelId);      ###### TO WHAT DO I HAVE TO SET EXTDBRELID, IF I (PLASMODB) PREDICTS GENES FOR DATA GENERATED BY TIGR/SANGER/ETC
      $gf->setSourceId($ggenename);
      $gf->setName($ggenename);
      $self->log("II Setting gf->source_id to $ggenename") if $debug;
      $gf->setPredictionAlgorithmId($method{$gmethod});
      $gf->setNumberOfExons($gnumexons);
	
      ##set the location
      my $isrev = $gstrand eq "+" ? 0 : 1;
      my $loc = &makeNALocation($gstart,$gstop,0,$isrev);
      $gf->addChild($loc) if $loc;
	

      $self->log("II GF: source_id ". $gf->getSourceId(). ", GT " . $gf->getGeneType(). ", naseqid : ". $naseq->getNaSequenceId() ) if $debug;

      # Now we are importing the exons for the gene
      $self->log( "II Making ExonFeatures for $ggenename") if $debug;
      my @todoexon=split(/\n/,$exon{$ggenename});
		
		
	## FOREACH EXON
	## Exoncounter j
	my $j=0;
	foreach my $ex (@todoexon){
	  my ($econtigname,$emethodname,$etype,$estart,$estop,
	      $equality,$estrand,$startphase, $endphase,$egenename,
	      $eorder,$extype,$eframe) = split(/\t/,$ex);
	  
	  next if ($estart eq "");
	  
	  my $etransl_start = ($eorder==1) ? $transl_start : 1 ;
	  $self->log("II GOT: $econtigname,$emethodname,$etype,$estart,$estop,$equality,$estrand,$startphase, $endphase,$egenename,$eorder,$extype,$eframe") if $debug;
	  $self->log( "II EXON $egenename: TS=$etransl_start") if ($transl_start != 1); 
	  #temp. debug
	  #if the predicted gene does not begin with an initial but an internal exon
	  #ie the ATG is of the Contig, then set the translation start of the initial exon
	  
	  $self->log( "II Making ExonFeatures for $egenename") if $debug;
	  $is_final  = ($extype=~m/term/i) ? 1 : 0;
	  $is_initial= ($extype=~m/init/i) ? 1 : 0;
	  
	  #is_initial should probably be set by: ($eorder==1) ? 1 : 0;
	  #to avoid errors from incomplete genefinder predictions
	  
	  $score  = ($equality eq "na") ? undef : $equality;
	  
	  my $exon = GUS::Model::DoTS::ExonFeature->new({
						      'name'              => 'ExonFeature',
						      'na_sequence_id'    => $naseq->getNaSequenceId(),
						      'is_predicted'      => 1,
						      'review_status_id'  => 0,
						      'is_initial_exon'   => $is_initial,
						      'is_final_exon'     => $is_final,
						      'order_number'      => $eorder,
						      'coding_start'      => 1,
						      'reading_frame'     => $etransl_start
						     });
	
	  $exon->setScore($score) if $score;
	  $exon->setCodingEnd($estop-$estart+1);  
	  $exon->setParent($naseq);

	  my $naloc = &makeNALocation($estart,$estop,$eorder,$isrev);
	  $exon->addChild($naloc) if $naloc;
	  $gf->addChild($exon) if $exon;
	  $exoncount++;
	  $j++;
	} # END foreach exon
		

      ### retrieve the AA sequence, if parseAAsequence is set, DEFAULT: OFF
      my $cds;

      ##check to make certain that have exons...
      $haveExons = $gf->getChildren('DoTS::ExonFeature') ? 1 : 0;
		
      ##now create rnafeature and translated features and protein
      $self->log("II Has Exons: $haveExons") if $debug;
      if($haveExons){

	if ($self->getArgs()->{'parseSequence'}){
	  $self->log("EE parseSequence not implemented. Using supplied methods");


	}

	#################### MJF	
	my $rtp=$gf->makePredictedRnaToProtein(undef, $extDbRelId ,  "Pv_".$key ) || $self->log("EE makePredictedRNAtoProtein complains");
	$self->log("GB ". $gf->getGBLocation()) if $debug;

	my $rna = $gf->getChild('DoTS::RNAFeature');
	$rna->setReviewStatusId('0');


	my $tas = $gf->getChild('DoTS::RNAFeature')->getChild('DoTS::TranslatedAAFeature')->getParent('DoTS::TranslatedAASequence');
	$tas->setDescription("predicted gene");	
	$self->log("AASEQ: ". $tas->getSequence()) if $debug;

	my $snas = $rna->getParent('DoTS::SplicedNASequence');
	my $t=$snas->getSequence();
	$self->log("SNAS: " . $snas->getSequence() ) if $debug;
      }
	
      ##following must be in loop to allow garbage collection...
      $gf->submit();
      $self->undefPointerCache();
      $genecount++;
      $self->log( "II genecount $genecount") if $debug;
      #limit the test to a number of genes for testing
      if (($self->getArgs()->{'testnumber'}=~m/\d+/ ) && ($genecount > $self->getArgs()->{'testnumber'} ) ) {
	$self->log( "II Reached number " . $self->getArgs()->{'testnumber'} . ". Aborting...") ;
	last;
      }
    } #end foreach gene 
    $contigcount++;
  } # end foreach contig (keys)
  my $results = "Processed " . $contigcount ." contig(s) with $genecount gene features and a total of $exoncount exon features\n\n";
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
