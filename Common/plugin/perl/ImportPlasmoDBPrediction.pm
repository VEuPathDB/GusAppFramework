
package GUS::Common::Plugin::ImportPlasmoDBPrediction;

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
       h => 'Name of file(s) containing the predicted gene features',
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
      
     } ];

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






############################################################
#                Let's get started
############################################################
my $debug = 0;  #my personal debug !!
my $project_id=undef;
my $NAseqId;
my $external_db_id=undef;
my $source_id=undef;
my %data;
my %allFeatures;
my $ctx;
$| = 1;

sub Run {
	my $self = shift;
    
	$external_db_id=$self->getArgs()->{'external_db_id'};
	$project_id=$self->getArgs()->{'project_id'};
	$source_id=$self->getArgs()->{'source_id'};
	$NAseqId=$self->getArgs()->{'NAseqId'};
	#$debug=($self->getArgs()->{'debug'}) ? 1 : 0;   #is too verbose for my debug purposes

	die "\n\nPlease specify the project_id, e.g. with --project_id=313\n\n" unless $project_id;
	die "\n\nPlease specify the external_db_id, e.g. with --external_db_id=151\n\n" unless $external_db_id;
	print STDERR  "\n\nsource_id or na_sequence_id has not been set, will use source_id supplied by genegff-file\n\n" unless ($source_id || $NAseqId);


	## IS COMMIT TURNED ON ?
	print $self->getArgs()->{'commit'} ? "*** COMMIT ON ***\n" : "*** COMMIT TURNED OFF ***\n";
	print "Testing on $self->getArgs()->{'testnumber'} examples\n" if $self->getArgs()->{'testnumber'};
	print "\n\nExternal_db_id: $external_db_id\n";
	print "Project_id:     $project_id\n";
	print "Source_id:      $source_id\n";
	print "NA_sequence_id: $NAseqId\n\n";


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
		($genename,$contig,$method,$type,$start,$stop,$strand,$phase,$numexons) = (split /\t/,$gene);
		print STDERR " GENE $genename $contig,$method,$type,$start,$stop,$strand,$phase,$numexons\n";
		if ($genename eq ""){
		    print STDERR "Oops. One entry empty !! Skipping ...\n";
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
	if ($self->getArgs()->{'verbose'}){
	    print STDERR "\n\n\n##################################\n";
	    print STDERR scalar(keys %genes) . " contigs found\n";
	    print STDERR "##################################\n\n\n";
	}


	## execute loop:  foreach contig of chromosome (keys %genes)->Sorry, that the naming is misleading
	## BTW: every genegff file can contain genemodels of multiple contigs, since this plugin has 
	## evolved out ot the need to load gene predictions for unfinished contig data
	
	foreach my $key (keys %genes){

	    print STDERR "\n##################################\n";
	    print STDERR "working on contig $key\n";
	    print STDERR "##################################\n\n";
	   




 
	    # retrieve the sequence_id to which the features will be linked
	    # external_db_id for PlasmoDB_RoosLab is '151'
	    # source_id is eqivalent to contig id of PlasmoDB ($key)
	    # unless specified otherwis on the CL with --source_id option
	    
	    #prepare connection to DB
	    my $dbh = $self->getArgs()->{'self_inv'}->getQueryHandle(); 


	    # get the sequence_object
	    my $naseq;



	    ## if na_sequence_id specified, retrieve object by id
	    if ($NAseqId){

		$naseq = ExternalNASequence->new({ na_sequence_id => $NAseqId });
		$naseq->retrieveFromDB(['sequence']);

		#	my $stmt = $dbh->prepare("SELECT s.*  FROM ExternalNASequence s WHERE s.na_sequence_id=?") || die "could not prepare statement: $!\n";
		#	$stmt->execute($NAseqId);
		#	while(my $row = $stmt->fetchrow_hashref()){
		#	    $naseq=ExternalNASequence->new($row);	    
		#	}
		

		## BREAK IF NO SEQUENCE OBJECT
		unless ($naseq){
		    my $errormessage="ERROR: $NAseqId did not retrieve a sequence object\n";
		    print STDERR $errormessage;
		    $self->getArgs()->{'self_inv'}->undefPointerCache();
		    return $errormessage;
		}
		
	    }else{
		## ELSE GET THE NASEQUENCE OBJECT FOR THE CONTIG, USING SOURCE_ID
		
		my $stmt = $dbh->prepare("SELECT s.*  FROM ExternalNASequence s, ProjectLink pl
WHERE s.source_id=?
AND pl.table_id = 89
AND pl.id = s.na_sequence_id
AND pl.project_id = $project_id") || die "could not prepare statement: $!\n";

		
		## execute statement with source_id if specified on CL
		## or use 'chr1' notation if otherwise
		if ($source_id) {
		    $stmt->execute($source_id);
		}else{ 
		    $stmt->execute($key);
		}
		
		
		my $countRows = 0;
		while(my $row = $stmt->fetchrow_hashref('NAME_lc')){
		    $naseq=ExternalNASequence->new($row);	    
		    $countRows++;
		}
		
		
		## ERROR AND EXIT ON TOO MANY OR ZERO RETURNED ROWS
		my $contigid=($source_id) ? $source_id : $key;
		if ($countRows > 1){	    
		    my $errormessage="ERROR: query with $contigid returns $countRows rows\n";
		    print STDERR $errormessage;
		    $self->getArgs()->{'self_inv'}->undefPointerCache();
		    return $errormessage;
		}elsif($countRows < 1){
		    my $errormessage="ERROR: query with $contigid returned no rows\n";
		    print STDERR $errormessage;
		    $self->getArgs()->{'self_inv'}->undefPointerCache();
		    return $errormessage;
		}
		
		if ($debug){
		    print STDERR "################################################\n";
		    print STDERR "# NAsequence: $countRows rows returned for $contigid\n";
		    print STDERR "################################################\n\n";
		}
	    }



	    # get the genelist for each contig
	    my @todogene=split(/\t/,$genes{$key});
	
	    ## FOREACH GENE
	    foreach my $tdg (@todogene){
		my $transl_start;
		my ($ggenename,$gcontig,$gmethod,$gtype,$gstart,$gstop,
		    $gstrand,$gphase,$gnumexons) = @{$coord{$tdg}};
		
		print STDERR "#### Making GeneFeature for $ggenename\n" if $debug;
		my $gf = GeneFeature->new({
		
		    'name' => 'GeneFeature',
		    'is_predicted' => 1,
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
		###### STUPID, ISN'T IT

		if ($gphase!=0){
		    $transl_start = ($gphase+1);
		    print STDERR "\n#### $ggenename GP=$gphase -> TS=$transl_start\n\n";
		}else{
		    $transl_start=1;
		}
		

		##set the sequence attributes:
		$gf->setParent($naseq);
		$gf->set('manually_reviewed',0);
		$gf->set('gene_type','protein_coding');
#####		$gf->set('gene_type',$gtype);

		$gf->set('external_db_id', '151');   #this is PlasmoDBs external_db_id
		$gf->set('source_id',$ggenename); 
		$gf->set('prediction_algorithm_id',$method{$gmethod});
		$gf->set('number_of_exons',$gnumexons);
		
		##set the location
		my $isrev;
		$isrev = $gstrand eq "+" ? 0 : 1;
		my $loc = &makeNALocation($gstart,$gstop,0,$isrev);
		$gf->addChild($loc) if $loc;
		
		# Now we are importing the exons for the gene
		print STDERR "Making ExonFeatures for $ggenename\n" if $debug;
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
		    
		    
		    print STDERR "********\n\nEXON $egenename: TS=$etransl_start\n\n******\n\n" if ($transl_start != 1); 
                    #temp. debug
		    #if the predicted gene does not begin with an initial but an internal exon
		    #ie the ATG is of the Contig, then set the translation start of the initial exon
		    
		    print STDERR "Making ExonFeatures for $egenename\n" if $debug;
		    $is_final  = ($extype=~m/term/i) ? 1 : 0;
		    $is_initial= ($extype=~m/init/i) ? 1 : 0;

		    #is_initial should probably be set by: ($eorder==1) ? 1 : 0;
		    #to avoid errors from incomplete genefinder predictions

		    $score     = ($equality eq "na") ? undef : $equality;
		    $exon = ExonFeature->new({'name' => 'ExonFeature',
					      'is_predicted' => 1,
					      'manually_reviewed' => 0,
					      'is_initial_exon' => $is_initial,
					      'is_final_exon' => $is_final,
					      'order_number' => $eorder,
					      'coding_start' => 1,
					      'reading_frame' => $etransl_start
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
		$haveExons = $gf->getChildren('ExonFeature') ? 1 : 0;
		
		##now create rnafeature and translated features and protein

		if($haveExons){
		    $gf->makePredictedRnaToProtein(undef,$gf->getExternalDbId(),$gf->getSourceId());
		    
		    ## now need to set the protein_sequence....
		    ## this method preferred over parseAAsequence 
		    my $tas = $gf->getChild('RNAFeature')->getChild('TranslatedAAFeature')->getParent('TranslatedAASequence');
		    $tas->setSequence($tas->getSequence());
		    $tas->setDescription("predicted gene");
		    
		    ## now set the sequence for the splicednasequence
		    my $snas = $gf->getChild('RNAFeature')->getParent('SplicedNASequence');
		    $snas->setSequence($snas->getSequence());
		}
		
		
		##following must be in loop to allow garbage collection...
		$gf->submit();	  
		
		$self->getArgs()->{'self_inv'}->undefPointerCache();
		$genecount++;
		print STDERR "#####\n#### genecount $genecount\n#####\n" if $debug;
		#limit the test to a number of genes for testing
		if (($self->getArgs()->{'testnumber'}) && ($genecount == $self->getArgs()->{'testnumber'} ) ) {
		    print STDERR "##### Reached number " . $self->getArgs()->{'testnumber'} . ". Aborting...\n\n" ;
		    last;
		}
		
	    } #end foreach gene 
	    $contigcount++;
	    
	} # end foreach contig (keys)
	
	my $results = "Processed " . $contigcount ." contig(s) with $genecount gene features and a total of $exoncount exon features\n\n";
	print STDOUT $results;
	return $results;
    } # end Run loop
    


#######################################################
## Make a location !!
#######################################################
sub makeNALocation {
    my($start,$end,$order,$is_reversed) = @_;    return undef if (!$start || !$end);
    my $l = NALocation->new({'start_min' => $start,
			     'start_max' => $start,
			     'end_min' => $end,
			     'end_max' => $end});
    $l->set('loc_order',$order) if $order;
    $l->set('is_reversed',$is_reversed);
    return $l;
}


### END SUBS



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




















