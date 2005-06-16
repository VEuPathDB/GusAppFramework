############################################################
## Change Package name....
############################################################
package GUS::Common::Plugin::MakeBestSimilarityPair;

@ISA = qw(GUS::PluginMgr::Plugin);
use strict;
############################################################
# Add any specific objects (Objects::GUSdev::Objectname) here
############################################################
use GUS::Model::DoTS::BestSimilarityPair;

sub new {
    my ($class) = @_;
    
    my $self = {};
    bless($self, $class);
    
    my $usage =  'To generate best similarity pairs for multiple genomes from similarity table';
    
    my $easycsp =
	
	[
	 {
	     o => 'testnumber',
	     t => 'int',
	     h => 'number of iterations for testing',
	 },
	 
	 {
	     o => 'set_percent_match',
	     t => 'boolean',
	     h => 'if true, will query Dots::SimilaritySpan table to retrieve best percent match information for similarities',
	 },

	 {
	     o => 'algorithm_id',
	     t => 'int',
	     d => '15820',
	     #d => '4089',
	     h => 'algorithm_id for ortholog group generation',
	 },

	 {
	     o => 'queryTableId',
	     t => 'int',
	     h => 'id of table where sequences that make up similarities are stored',
	     d => 83,
	 },
	 {
	     o => 'algInvoIds',
	     t => 'string',
	     h => 'row_alg_invocation_id from Similarity',
	 },
	 {
	     o => 'taxon_ids',
	     h => '(The ids from Taxon of the taxa from which the sequences come from separated by comma.)  for now external_database_release_ids; 211 for P.falciparum, 692 for P.yoelii.',
	     t => 'string',
	 },
	 
	 {
	     o => 'restart_alg_invocation_ids',
	     h => 'previous runs of the plugin that were interrupted if restarting; must also delete results for two species that were partially completed',
	     t => 'string',
	 },

	 ];

    $self->initialize({requiredDbVersion => {},
		       cvsRevision => '$Revision$', # cvs fills this in!
		       name => ref($self),
		       revisionNotes => 'optional now to set percent_match attribute ',
		       easyCspOptions => $easycsp,
		       usage => $usage
		       });
    
    return $self;
}


sub run {
    my $self = shift;
    my $RV;
    
    $self->logAlert('COMMIT', $self->getCla->{commit} ? 'ON' : 'OFF' );
    print "Testing on $self->getCla->{'testnumber'}\n" if $self->getCla->{'testnumber'};
    
    my $processedDbReleases = $self->getProcessedDbReleases() if ($self->getCla()->{restart_alg_invocation_ids});
    
    ##DBI handle to be used for queries outside the objects...
    
    my $dbh = $self->getQueryHandle();
    
    ############################################################
    # Put loop here...remember to undefPointerCache()!
    ############################################################
    my $algInvoIds = $self->getCla->{algInvoIds};
    my $algorithm_id = $self->getCla->{algorithm_id};
    my @taxa = split(',', $self->getCla->{taxon_ids});   
    my $pfdb = '5201,5202,5203';
    my $pyydb = 692;
#    push (@taxa,'211');
    print STDERR "make best similarity pairs from ".join(",",@taxa)."\n";
    
    my $stmtSpan =$dbh->prepare("select similarity_span_id,subject_start,subject_end,query_start,query_end from dots.SimilaritySpan where similarity_id=?");
    
    my $stmtLen = $dbh->prepare("select length from dots.AASequence where aa_sequence_id=?");

    my $queryTableId = $self->getCla()->{queryTableId};

    for(my $i=0;$i<scalar(@taxa)-1;$i++) {   
	for(my $j=$i+1;$j<scalar(@taxa);$j++) {
	    
	    my %sim;
	    my $firstTaxon = $taxa[$i];
	    my $secondTaxon = $taxa[$j];
	    $self->log("running query for database releases " . $firstTaxon . " and " . $secondTaxon . "\n");
	    if ($processedDbReleases->{$firstTaxon}->{$secondTaxon} || $processedDbReleases->{$secondTaxon}->{$firstTaxon}){
		$self->log("skipping $firstTaxon and $secondTaxon because they have already been run");
		next;
	    }
	    my $sql = "select s.query_id, s.subject_id, s.pvalue_mant,s.pvalue_exp,s.number_identical/s.total_match_length, s.similarity_id from dots.similarity s, dots.externalaasequence a1, dots.externalaasequence a2 where s.subject_table_id= $queryTableId and s.query_table_id= $queryTableId and s.query_id=a1.aa_sequence_id and a1.external_database_release_id = ? and s.subject_id=a2.aa_sequence_id and a2.external_database_release_id =? and s.row_alg_invocation_id in ($algInvoIds) order by s.pvalue_exp asc,s.pvalue_mant asc,s.number_identical/s.total_match_length desc";

	    my $sth = $dbh->prepare($sql);
	    $sth->execute($firstTaxon, $secondTaxon);
	    while(my($qid,$sid,$pm,$pe,$pi,$s) = $sth->fetchrow_array()) {
		@{$sim{$qid}} = ($sid,$pm,$pe,$pi,$s, $queryTableId, $queryTableId) unless(exists($sim{$qid}));
	    }
	    $sth->execute($secondTaxon,$firstTaxon);
	    while(my($qid,$sid,$pm,$pe,$pi,$s) = $sth->fetchrow_array()) {
		@{$sim{$qid}} = ($sid,$pm,$pe,$pi,$s, $queryTableId, $queryTableId) unless(exists($sim{$qid}));
	    }
	    $self->log("processing similarity info for " . $firstTaxon . " and " . $secondTaxon . "; have " . scalar(keys %sim) . " keys to process\n");
	    my $counter = 0;
	    foreach my $qid (keys %sim) {
		$counter++;
		if ($counter % 5000 == 0){
		    $self->log("processing similarity number $counter for " . $firstTaxon . " and " . $secondTaxon . "\n");
		}
		
		my $percentMatch = 0;
		
		if ($self->getCla->{percent_match}){
		    my (%sub_start,%sub_length,%query_start,%query_length);
		    $stmtSpan->execute($sim{$qid}->[4]);   
		    while(my (@row) = $stmtSpan->fetchrow_array()) {
			$sub_start{$row[0]}=$row[1]; 
			$sub_length{$row[0]}=$row[2]-$row[1]+1;
			$query_start{$row[0]}=$row[3];
			$query_length{$row[0]}=$row[4]-$row[3]+1;
		    }
		
		    my $match_lengthq = &matchlen(\%query_start,\%query_length);   
		    $stmtLen->execute($qid);
		    my ($lengthq) = $stmtLen->fetchrow_array();
		    $percentMatch = $match_lengthq/$lengthq; 
		}
		
		my $bmp = GUS::Model::DoTS::BestSimilarityPair->new();
		$bmp->set('sequence_id', $qid);
		$bmp->set('paired_sequence_id',$sim{$qid}->[0]);
		$bmp->set('pvalue_exp',$sim{$qid}->[2]);
		$bmp->set('pvalue_mant',$sim{$qid}->[1]);
#		$bmp->set('score',$values{$query.' '.$subject}->[5]);
		$bmp->set('percent_identity',$sim{$qid}->[3]);
		$bmp->set('percent_match', $percentMatch);
		$bmp->set('source_table_id',$sim{$qid}->[5]);
		$bmp->set('paired_source_table_id', $sim{$qid}->[6]);

		$bmp->submit();
		$self->getSelfInv->undefPointerCache();
	    }
	}
    }
    $RV = join(' ',
	       "inserted",
	       $self->getSelfInv->getTotalInserts(),
	       'and updated',
	       $self->getSelfInv->getTotalUpdates() || 0,
	       );
    $self->logAlert('RESULT', $RV);
    return $RV;
}

sub getProcessedDbReleases{

    my ($self) = @_;
    my $sql = "select distinct eas1.external_database_release_id, eas2.external_database_release_id from dots.bestsimilaritypair p, dots.externalaasequence eas1, dots.externalaasequence eas2 where p.paired_sequence_id = eas1.aa_sequence_id and p.sequence_id = eas2.aa_sequence_id  and p.row_alg_invocation_id in (" . $self->getCla()->{restart_alg_invocation_ids} . ")";

    my $processedReleases;
    
    my $sth = $self->getQueryHandle()->prepareAndExecute($sql);
    while (my ($release1, $release2) = $sth->fetchrow_array()){
	$processedReleases->{$release1}->{$release2} = 1;
    }
    return $processedReleases;
}


sub matchlen {
    my ($s, $l)=@_;
    my %start= %$s; my %length = %$l;
    my @starts = sort{$start{$a}<=>$start{$b}} (keys %start);
	my $i=0; my $match_length=0; 
    while($i<scalar(@starts)) {
	if(!$starts[$i+1]) { $match_length += $length{$starts[$i]}; last;}
	elsif($length{$starts[$i]} <= $start{$starts[$i+1]}-$start{$starts[$i]}) {
	    $match_length += $length{$starts[$i]}; $i++;}
	elsif($start{$starts[$i]}+$length{$starts[$i]}<=$start{$starts[$i+1]}+$length{$starts[$i+1]}){  
	    $match_length += $start{$starts[$i+1]}-$start{$starts[$i]}; $i++; }
	else { 
	    my $j=$i+1;
	    while($start{$starts[$i]}+$length{$starts[$i]}>$start{$starts[$j]}+$length{$starts[$j]} && $j<scalar(@starts))
	    { $j++;}
	    $match_length += $length{$starts[$i]};
	    $i=$j;
	}
    }
    return $match_length;
}

1;



