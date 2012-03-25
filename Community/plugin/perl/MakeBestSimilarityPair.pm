############################################################
## Change Package name....
############################################################
package GUS::Community::Plugin::MakeBestSimilarityPair;

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
	     o => 'algorithm_id',
	     t => 'int',
	     d => '15820',
	     #d => '4089',
	     h => 'algorithm_id for ortholog group generation',
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
	 ];

    $self->initialize({requiredDbVersion => {},
		       cvsRevision => '$Revision$', # cvs fills this in!
		     cvsTag => '$Name$', # cvs fills this in!
		       name => ref($self),
		       revisionNotes => 'make consistent with GUS 3.0',
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
    print STDERR "make best similarity pairs from".join(",",@taxa)."\n";
    
    my $stmtSpan =$dbh->prepare("select similarity_span_id,subject_start,subject_end,query_start,query_end from dots.SimilaritySpan where similarity_id=?");
    
    my $stmtLen = $dbh->prepare("select length from dots.AASequence where aa_sequence_id=?");

    for(my $i=0;$i<scalar(@taxa)-1;$i++) {   
	for(my $j=$i+1;$j<scalar(@taxa);$j++) {

	    my %sim;

	    if(($taxa[$i] == 211 && $taxa[$j] == 692) || ($taxa[$j] == 211 && $taxa[$i] == 692) ) {
		
		my $sth = $dbh->prepare("select s.query_id, s.subject_id, s.pvalue_mant,s.pvalue_exp,s.number_identical/s.total_match_length, s.similarity_id from dots.similarity s, dots.translatedaasequence a1, dots.translatedaasequence a2 where s.subject_table_id=337 and s.query_table_id=337 and s.query_id=a1.aa_sequence_id and a1.external_database_release_id in ($pfdb) and s.subject_id=a2.aa_sequence_id and a2.external_database_release_id = $pyydb and s.row_alg_invocation_id in ($algInvoIds) order by s.pvalue_exp asc,s.pvalue_mant asc,s.number_identical/s.total_match_length desc");
		$sth -> execute();
		while(my($qid,$sid,$pm,$pe,$pi,$s) = $sth->fetchrow_array()) {
		    @{$sim{$qid}} = ($sid,$pm,$pe,$pi,$s,337,337) unless(exists($sim{$qid}));
		}
		$sth->finish();
		
		$sth = $dbh->prepare("select s.query_id, s.subject_id, s.pvalue_mant,s.pvalue_exp,s.number_identical/s.total_match_length, s.similarity_id from dots.similarity s, dots.translatedaasequence a1, dots.translatedaasequence a2 where s.subject_table_id=337 and s.query_table_id=337 and s.query_id=a1.aa_sequence_id and a1.external_database_release_id in ($pyydb) and s.subject_id=a2.aa_sequence_id and a2.external_database_release_id in ($pfdb) and s.row_alg_invocation_id in ($algInvoIds) order by s.pvalue_exp asc,s.pvalue_mant asc,s.number_identical/s.total_match_length desc");
		$sth -> execute();
		while(my($qid,$sid,$pm,$pe,$pi,$s) = $sth->fetchrow_array()) {
		    @{$sim{$qid}} = ($sid,$pm,$pe,$pi,$s,337,337) unless(exists($sim{$qid}));
		}
		
	    }elsif($taxa[$i] == 211 || $taxa[$j] == 211) {

		my $t = $taxa[$i] == 211 ? $taxa[$j] : $taxa[$i];
		my $sth = $dbh->prepare("select s.query_id, s.subject_id, s.pvalue_mant,s.pvalue_exp,s.number_identical/s.total_match_length, s.similarity_id from dots.similarity s, dots.translatedaasequence a1, dots.externalaasequence a2 where s.subject_table_id=83 and s.query_table_id=337 and s.query_id=a1.aa_sequence_id and a1.external_database_release_id in ($pfdb) and s.subject_id=a2.aa_sequence_id and a2.external_database_release_id = $t and s.row_alg_invocation_id in ($algInvoIds) order by s.pvalue_exp asc,s.pvalue_mant asc,s.number_identical/s.total_match_length desc");
		$sth -> execute();
		while(my($qid,$sid,$pm,$pe,$pi,$s) = $sth->fetchrow_array()) {
		    @{$sim{$qid}} = ($sid,$pm,$pe,$pi,$s,337,83) unless(exists($sim{$qid}));
		}
		$sth->finish();
		
		$sth = $dbh->prepare("select s.query_id, s.subject_id, s.pvalue_mant,s.pvalue_exp,s.number_identical/s.total_match_length, s.similarity_id from dots.similarity s, dots.externalaasequence a1, dots.translatedaasequence a2 where s.subject_table_id=337 and s.query_table_id=83 and s.query_id=a1.aa_sequence_id and a1.external_database_release_id = $t and s.subject_id=a2.aa_sequence_id and a2.external_database_release_id in ($pfdb) and s.row_alg_invocation_id in ($algInvoIds) order by s.pvalue_exp asc,s.pvalue_mant asc,s.number_identical/s.total_match_length desc");
		$sth -> execute();
		while(my($qid,$sid,$pm,$pe,$pi,$s) = $sth->fetchrow_array()) {
		    @{$sim{$qid}} = ($sid,$pm,$pe,$pi,$s,83,337) unless(exists($sim{$qid}));
		}
	
	    }elsif($taxa[$i] == 692 || $taxa[$j] == 692) {
		
		my $t = $taxa[$i] == 692 ? $taxa[$j] : $taxa[$i];
		my $sth = $dbh->prepare("select s.query_id, s.subject_id, s.pvalue_mant,s.pvalue_exp,s.number_identical/s.total_match_length, s.similarity_id from dots.similarity s, dots.translatedaasequence a1, dots.externalaasequence a2 where s.subject_table_id=83 and s.query_table_id=337 and s.query_id=a1.aa_sequence_id and a1.external_database_release_id in ($pyydb) and s.subject_id=a2.aa_sequence_id and a2.external_database_release_id = $t and s.row_alg_invocation_id in ($algInvoIds) order by s.pvalue_exp asc,s.pvalue_mant asc,s.number_identical/s.total_match_length desc");
		$sth -> execute();
		while(my($qid,$sid,$pm,$pe,$pi,$s) = $sth->fetchrow_array()) {
		    @{$sim{$qid}} = ($sid,$pm,$pe,$pi,$s,337,83) unless(exists($sim{$qid}));
		}
		$sth->finish();
		
		$sth = $dbh->prepare("select s.query_id, s.subject_id, s.pvalue_mant,s.pvalue_exp,s.number_identical/s  .total_match_length, s.similarity_id from dots.similarity s, dots.externalaasequence a1, dots.translatedaasequence a2 where s.subject_table_id=337 and s.query_table_id=83 and s.query_id=a1.aa_sequence_id and a1.external_database_release_id = $t and s.subject_id=a2.aa_sequence_id and a2.external_database_release_id in ($pyydb) and s.row_alg_invocation_id in ($algInvoIds) order by s.pvalue_exp asc,s.pvalue_mant asc,s.number_identical/s.total_match_length desc");
		$sth -> execute();
		while(my($qid,$sid,$pm,$pe,$pi,$s) = $sth->fetchrow_array()) {
		    @{$sim{$qid}} = ($sid,$pm,$pe,$pi,$s,83,337) unless(exists($sim{$qid}));
		}
		
	    }else{
		
		my $sth = $dbh->prepare("select s.query_id, s.subject_id, s.pvalue_mant,s.pvalue_exp,s.number_identical/s.total_match_length, s.similarity_id from dots.similarity s, dots.externalaasequence a1, dots.externalaasequence a2 where s.subject_table_id=83 and s.query_table_id=83 and s.query_id=a1.aa_sequence_id and a1.external_database_release_id = ? and s.subject_id=a2.aa_sequence_id and a2.external_database_release_id =? and s.row_alg_invocation_id in ($algInvoIds) order by s.pvalue_exp asc,s.pvalue_mant asc,s.number_identical/s.total_match_length desc");
		$sth -> execute($taxa[$i],$taxa[$j]);
		while(my($qid,$sid,$pm,$pe,$pi,$s) = $sth->fetchrow_array()) {
		    @{$sim{$qid}} = ($sid,$pm,$pe,$pi,$s,83,83) unless(exists($sim{$qid}));
		}
		$sth -> execute($taxa[$j],$taxa[$i]);
		while(my($qid,$sid,$pm,$pe,$pi,$s) = $sth->fetchrow_array()) {
		    @{$sim{$qid}} = ($sid,$pm,$pe,$pi,$s,83,83) unless(exists($sim{$qid}));
		}
	    }
	    
	    foreach my $qid (keys %sim) {
		my (%sub_start,%sub_length,%query_start,%query_length);
		$stmtSpan->execute($sim{$qid}->[4]);   
		while(my (@row) = $stmtSpan -> fetchrow_array()) {
		    $sub_start{$row[0]}=$row[1]; 
		    $sub_length{$row[0]}=$row[2]-$row[1]+1;
		    $query_start{$row[0]}=$row[3];
		    $query_length{$row[0]}=$row[4]-$row[3]+1;
		}
		
		my $match_lengthq = &matchlen(\%query_start,\%query_length);   
		$stmtLen->execute($qid);
		my ($lengthq) = $stmtLen -> fetchrow_array();
		my $percent_matchq = $match_lengthq/$lengthq; 
		
		my $bmp = GUS::Model::DoTS::BestSimilarityPair->new();
		$bmp -> set('sequence_id', $qid);
		$bmp -> set('paired_sequence_id',$sim{$qid}->[0]);
		$bmp -> set('pvalue_exp',$sim{$qid}->[2]);
		$bmp -> set('pvalue_mant',$sim{$qid}->[1]);
#		$bmp -> set('score',$values{$query.' '.$subject}->[5]);
		$bmp -> set('percent_identity',$sim{$qid}->[3]);
		$bmp -> set('percent_match', $percent_matchq);
		$bmp -> set('source_table_id',$sim{$qid}->[5]);
		$bmp -> set('paired_source_table_id', $sim{$qid}->[6]);

		$bmp -> submit();
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



