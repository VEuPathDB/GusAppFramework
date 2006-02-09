package GUS::GOPredict::Plugin::MakeGoPredictionRules;
@ISA = qw( GUS::PluginMgr::Plugin);

use lib "$ENV{GUS_HOME}/lib/perl";

use strict 'vars';

use FileHandle;

use GUS::Model::DoTS::MotifAASequence;
use GUS::Model::DoTS::GOAssociation;

use GUS::Model::DoTS::AAMotifGOTermRuleSet;
use GUS::Model::DoTS::AAMotifGOTermRule;

use GUS::Model::DoTS::Evidence;
use GUS::Model::DoTS::Similarity;
use GUS::Model::SRes::GOTerm;


$| = 1;


# ---------------------------------------------------------------------- #
# ---------------------------------------------------------------------- #

sub new {

    #create
    my $class = shift;
    my $self = bless{}, $class;

    #initialize

    my $usage = "creates RuleSets and Rules for predicting GO classification";

    my $easycsp = 
    [
     
     { o => 'aa_filter_file',
       h => 'filter protein with this list of table/id',
       t => 'string',
       d => 'AaFilters/all.aaf.tab', #dtb: change this once I know more about aa filter file
       r => 1,    
   },
     
     { o => 'motifs',
       t => 'string',
       h => 'restrict attention to these motifs',
   },

     { o => 'restart',
       t => 'boolean',
       h => 'restart an interrupted run of this plugin',
   },

     { o => 'previous_invocation_ids',
       t => 'string',
       h => 'comma separtated list of algorithm invocation ids of previous plugin runs.  Use with --restart',
   },
     
     { o => 'go_ext_db_rel_id',
       h => 'External Database Release Id for GO Function hierarchy associated with external AA Sequences',
       t => 'int',
       r => 1,
   },
	    
     { o => 'id_db',
       h => 'comma separated external db ids of motif database',
       d => '2293', # prodom
       t => 'string',
       r => 1,
   },
	    
     { o => 'no_iea!',
       h => 'exclude IEA annotations',
       t => 'boolean',
   },
     
     { o => 'no_csc!',
       h => 'do not check the number of contained sequences in DoTS.MotifAASequence',
       t => 'boolean',
   },
	     
     { o => 'sm_pv',
       h => 'BLAST similarities must have at most this pValue',
       d => 1e-50,  #Note: when sliding does not really restrict the similarities! But, uses pv as threshold. 
       t => 'float',
       r => 1,
   },
	
     { o => 'sm_len',
       h => 'BLAST similarities must have at least this total length',
       t => 'int',
       r => 1,
   },
	     
     { o => 'sm_ps',
       h => 'BLAST similarities must have at least this percent similarity',
       t => 'float',
       r => 1,
   },
	    
     { o => 'sm_nom',
       h => 'reject all similarities with more than this many HSPs',
       d => 5,
       t => 'int',
       r => 1,
   },
	    
     { o => 'sm_n',
       h => 'number of annotated proteins required to infer a rule',
       t => 'int',
       d => 1,
       r => 1,
   },
     
     { o => 'pd_n',
       h => 'minimum number of proteins in motif definition',
       d => 2,
       t => 'int',
       r => 1,
   },
     
     # extended rules
     { o => 'er_use!',
       h => 'use extended rules',
       t => 'boolean',
   },
     
     { o => 'er_n',
       h => 'must have at least this many annotated proteins to use ERs',
       t => 'int',
       d => 5,
       r => 1,
   },
		
     { o => 'er_ncf',
       h => 'near-consensus fraction',
       d => 0.8,
       t => 'float',
       r => 1,
   },
		
     { o => 'pa_ml',
       h => 'maximum number of levels to travel to look for parents',
       d => 99,
       t => 'int',
       r => 1,
   },
     
     { o => 'pa_sl',
       h => 'shallowest level for parents',
       d => 2,
       t => 'int',
       r => 1,
   },
		
     { o => 'sliding',
       h => 'type of sliding threshold to use',
       t => 'string',
       r => 1,
       d => 'most-generous',
   },
     
     { o => 'sl_gr',
       h => 'acceptable rules for sliding threshold',
       t => 'string',
       d => 'sing,leaf,ncle,npar,onep',
       r => 1,
   },
     
		# confidence setting
     { o => 'cf_hnp',
       h => 'minimum number of explained proteins to give high confidence',
       d => 10,
       t => 'int',
       r=> 1, 
   },

     { o => 'cf_mnp',
       h => 'minimum number of explained proteins to give medium confidence',
       d => 5,
       t => 'int',
       r => 1, 
   },
     
     
     { o => 'cf_hps',
       h => 'minimum percent (fraction) similarity for high confidence',
       d => 0.98,
       t => 'float',
       r => 1,
   },

     { o => 'cf_mps',
       h => 'minimum percent (fraction) similarity for medium confidence',
       d => 0.90,
       t => 'float',
       r => 1,
   },

     { o => 'cf_hpv',
       h => 'minimum p-value for high confidence',
       t => 'float',
       d => 1e-60,
       r => 1, 
   },
     
     { o => 'cf_mpv',
       h => 'minimum p-value for medium confidence',
       d => 1e-40,
       t => 'float',
       r => 1,
   },
     
     { o => 'gus_nobj',
       h => 'number of GSU objects to allow',
       d => 500000,
       t => 'int',
       r => 1,
   },
        
     ];
     
    $self->initialize({requiredDbVersion => {},
		       cvsRevision => '$Revision$', #cvs fills this in!
                       cvsTag => '$Name$', #cvs fills this in!
		       name => ref($self),
		       revisionNotes => 'makeConsistent with GUS 3.0',
		       easyCspOptions => $easycsp,
		       usage => $usage,
		   });

    return $self;
}


# ---------------------------------------------------------------------- #
# ---------------------------------------------------------------------- #
sub isReadOnly { 0 }
# ---------------------------------------------------------------------- #
# ---------------------------------------------------------------------- #

sub run {
    my $self = shift;

    #save this part for later
#    if ( $C->{ self_inv } ) {
#      GusApplication::Log( 'raid', $C->{ self_inv }->getId() );
#	$C->{ self_inv }->setMaximumNumberOfObjects( $C->{ cla }->{ gus_nobj } );
#    }
    
    $self->getDb()->setMaximumNumberOfObjects($self->getCla->{gus_nobj});


    $self->__verifySliding();
    
    my $hid_go_function = $self->GetGoFunctionGraph();
    
    # Get the aa seq ids of the GOAP that will use in rule generation.
    #
    my $aa_filter = $self->GetAaFilterFile();
    my $processedMotifs;
    if ($self->getCla()->{restart}){  #we are restarting an interrupted run of the plugin
  	
	$processedMotifs = $self->getProcessedMotifs();

    }

    # Get all the similarity information for the ids in aa_filter
    # keys of the $sim_dict hash are the motifaasequence ids.
    #
    my $sim_dict = $self->GetSimilarityDictionary( $aa_filter, $processedMotifs );

    my $badMotifs = $self->__getBadMotifs();
    
    my $id_motif_aa_sequences = 
	scalar @{$self->getCla->{motifs}} > 0 ?
	$self->getCla->{motifs} :
	[ keys %{ $sim_dict } ];
  
    $self->log("built similarity dictionary; preparing to process ". scalar @{$id_motif_aa_sequences} . "motifs"); 
    # Process each motif in the filter...

    
    foreach my $id_motif_aa_sequence ( @{ $id_motif_aa_sequences } ) {
	
	# Get the similarities for this motif.
	my $gus_similarities = $sim_dict->{ $id_motif_aa_sequence };
	my $databaseId = $gus_similarities->[0]->{databaseId};
	my $sourceId =  $gus_similarities->[0]->{sourceId};
	if ($badMotifs->{$databaseId}->{$sourceId}){
	    $self->log("skipping motif $sourceId from database id $databaseId since it has been flagged");
	    next;
	}
	# Save off the number of similarities for this motif - convenience.
	my $n_sim = scalar @{ $gus_similarities };
	#DTB: TAKE OUT ADDITIONS TO LOGS
	# Log some interesting info.
	$self->log( 'NEW MOTIF', 'INF', 'NSIM', 'id: $id_motif_aa_sequence', 'number of sims: $n_sim' );
	
	# Skip this motif if there aren't enough similarities.
	next if $n_sim < $self->getCla->{ sm_n };
	
	# Do all the work...
	my $id_go_functions =
	    $self->IntersectGoFunctions( $gus_similarities,
				  $id_motif_aa_sequence,
				  $hid_go_function,
				 );
	
	$self->undefPointerCache();
	
    }
    
    return "Completed Rule Generation";
    
}

sub __getBadMotifs{

    my ($self) = @_;

    my $badMotifs;

    my $sql = "select source_id, external_database_id
               from DoTS.RejectedMotif";
    my $sth = $self->getQueryHandle()->prepareAndExecute($sql);
    while (my ($motifSourceId, $databaseId) = $sth->fetchrow_array()){
	$badMotifs->{$databaseId}->{$motifSourceId} = 1;
    }
    return $badMotifs;
}


sub __verifySliding{
    my ($self) = @_;
    if (($self->getCla->{sliding} ne "most-generous")){
	
	my $msg = "The only supported threshold type is \"most-generous\"\n";
	$msg .= "Please set the --sliding command line argument to that value\n";
	$msg .= "(you entered: " . $self->getCla->{sliding} . ")\n";
	$self->userError($msg);
    }
}
    



# ----------------------------------------------------------------------
# get_pv_mant : returns the mantissa for the provided p-value. 
# ----------------------------------------------------------------------

sub get_pval_mant {
    my ($self, $pval) = @_;
    my $mant;
    if($pval =~ /^(\S+)e(\S+)$/){
	$mant = $1;
    }else{
	$mant = $pval == 0 ? 0 : $pval;
    }
    return $mant;
}

# ----------------------------------------------------------------------
# get_pv_exp : returns the exponent for the provided p-value. 
# ----------------------------------------------------------------------

sub get_pval_exp {
    my ($self, $pval) = @_;
    my $exp;
    if($pval =~ /^(\S+)e(\S+)$/){
	$exp = $2;
    }else{
	$exp = $pval == 0 ? -999999 : 0;
    }
    return $exp;
}
# ----------------------------------------------------------------------
# get_ids : gets a ref to list of id using an sql string.
# ----------------------------------------------------------------------

sub get_ids {
    my ($self, $sql) = @_;
    
    my $queryHandle = $self->getQueryHandle();
    
    $self->log( 'SQL', 'get_ids', $sql );
    
    my $ids;

    my $sth = $queryHandle->prepareAndExecute($sql);
    while ( my $id = $sth->fetchrow_array(  ) ) {
	$ids->{$id} = 1;
    }
    $sth->finish();
    my @idList = keys %$ids;
    \@idList;
}


# ----------------------------------------------------------------------
# GetGoFunctionHierachy :
# ----------------------------------------------------------------------

sub GetGoFunctionGraph {
    my ($self) = @_;

    my $goDbRelId = $self->getCla->{go_ext_db_rel_id};
    my $functionRoot = $self->getCla->{go_func_root};
    
    my $queryHandle = $self->getQueryHandle();

     my $sql = "
	select f.go_term_id, h.parent_term_id, f.minimum_level, f.maximum_level, f.go_id
     from SRes.GOTerm f, SRes.GORelationship h 
     where h.child_term_id = f.go_term_id
     and f.external_database_release_id = $goDbRelId
     
      ";
    #NOT ONTOLOGY ROOT
    my $graph;
    my $sth = $queryHandle->prepareAndExecute($sql);
    
    while ( my ( $id_function, $id_parent, $min_lvl, $max_lvl, $go_id ) 
	    = $sth->fetchrow_array()) {
	push( @{ $graph->{ $id_function }->{ parents  } }, $id_parent   );
	push( @{ $graph->{ $id_parent   }->{ children } }, $id_function );
	$graph->{ $id_function }->{ minimum_level } = $min_lvl;
	$graph->{ $id_function }->{ maximum_level } = $max_lvl;
	$graph->{ $id_function }->{ ancestor }->{ $id_parent } = 1;
	$graph->{ $id_function }->{ gus2go } = $go_id;
	$graph->{ $go_id }->{ go2gus } = $id_function;
    }
    $sth->finish();
    return $graph;
}

# ----------------------------------------------------------------------
# IsAncestorOf :
# ----------------------------------------------------------------------

sub IsAncestor {
	my ($self, $A) = @_;

	my $id_ch = $A->{ child };
	my $id_an = $A->{ ancestor };
	my $h     = $A->{ graph };

	# haven't determined the anwswer yet; figure it out.
	if ( not defined $h->{ $id_ch }->{ ancestor }->{ $id_an } ) {
	    my @parents = $self->GetParents([$id_ch],  $h);
	    my $b_is_ancestor = 0;
	    foreach my $ancestor ( @parents ) {
		$h->{ $id_ch }->{ ancestor }->{ $ancestor } = 1;
		$b_is_ancestor |= $ancestor == $id_an;
	    }
	    
	    $h->{ $id_ch }->{ ancestor }->{ $id_an } = $b_is_ancestor;
	}
	
	# the answer
	$h->{ $id_ch }->{ ancestor }->{ $id_an }
}

# ----------------------------------------------------------------------
# GetParents : returns a hash ref where the keys are all the terms on
# the path to the root from the list of _children_ according to the
# _graph_.
#
# Works by performing a breadth first traversal back up the graph.
# ----------------------------------------------------------------------

sub GetParents {
    my ($self, $children, $graph) = @_;
    
    # hash ref : id = 1 if on a path to root.
    my $rv = {};
    
    # prime the queue with the children we're given.
    my @queue = @$children;
    
    while ( my $id = shift @queue ) {
	foreach my $parent ( @{$graph->{ $id }->{ parents } } ) {
	    unless ( $rv->{ $parent } ) {
		$rv->{ $parent } = 1;
		push( @queue, $parent );
	    }
	}
    }
    
    # return value
    return $rv;
}

# ----------------------------------------------------------------------
# GetNthParents : returns all parents that are within N levels of a
# child but not those that are too close to the root.
# ----------------------------------------------------------------------

sub GetNthParents {
    my ($self, $A) = @_;
    
    # hash ref : id = minimum distance from child.
    my $rv;
    
    my @queue = ( { id => $A->{ child }, distance => 0 } );
    
  QUEUE_SCAN:
    while ( my $e = shift @queue ) {
	
	# process the parents of this node.
      PARENT_SCAN:
	foreach my $parent ( @{ $A->{ graph }->{ $e->{ id } }->{ parents } } ) {
	    unless ( $rv->{ $parent } ) {
		
		# skip this one if we've gone too far from leaf.
		my $d = $e->{ distance } + 1;
		next if $d > $A->{ max_dist };
		
		# skip those nodes that are too close to the root.
		next PARENT_SCAN if $A->{ graph }->{ $parent }->{ minimum_level }
		< $A->{ min_level } && ! $A->{ children }->{ $parent };
		
		$rv->{ $parent } = $d;
		push( @queue, { id => $parent, distance => $d } );
		}
	}
    }
    
    # return value
    return $rv;
}

# ----------------------------------------------------------------------
# GetAaFilterFile : read in file of table_id/sequence_id pairs.
#
# These are the GO proteins that will be included in rule generation.
#
# These should be tab-delimited in the file.  They are loaded into a
# hash ref which is { table }->{ sequence } = 1.
# ----------------------------------------------------------------------

sub GetAaFilterFile {
    my ($self) = @_;
    
    my $rv;
    my $aaFilterFile = $self->getCla->{ aa_filter_file};
    
    my $fh = FileHandle->new( '<'. $aaFilterFile );
    if ( $fh ) {
	while ( <$fh> ) {
	    chomp;
	    s/^ +//;
	    s/ +$//;
	    my ( $table, $id ) = split /\s+/;
	    $rv->{ $table }->{ $id } = 1
	    }
	$fh->close
	}
    else {
	$self->error( 'ERR: could not open aa-filter-file $aaFilterFile' );
    }
    
    # return value
    return $rv;
}

# ----------------------------------------------------------------------
# GetSimilarityFilterSQL : make the SQL necessary to filter
# similarities, either by p-value or precent similarity.  If CLA
# indicates a sliding threshold, then some thresholds will be turned
# off.
#
# Takes only the command line arguments as input.
# ----------------------------------------------------------------------

sub GetSimilarityFilterSQL {
    my ($self) = @_;
    
    my @sql;
    
    # first try simple p-value
    push( @sql, 's.pvalue_exp <= -5' );  # Never use p-val exp higher > -5
      
    
    # (total) percent similarity
    if ( $self->getCla->{ sm_ps }  && ! defined $self->getCla->{ sliding } ) {
	push( @sql,
	      'convert(float,s.number_positive)/convert(float,s.total_match_length) >= '.
	      $self->getCla->{ sm_ps } / 100
	      );
    }
        
    # length
    if ( $self->getCla->{ sm_len } ) {
	push( @sql, 's.total_match_length >= '. $self->getCla->{ sm_len } );
    }
    
    # number of matches
    if ( $self->getCla->{ sm_nom } ) {
	push( @sql, 's.number_of_matches < '. $self->getCla->{ sm_nom } );
    }
    
    # return value
    join( ' and ', @sql );
}

sub getProcessedMotifs {
    
    my ($self) = @_;

    my $queryHandle = $self->getQueryHandle();
    my $algInvIds = $self->getCla->{previous_invocation_ids};
    my $sql = "select aa_sequence_id_1 from DoTS.AAMotifGOTermRuleSet 
               where row_alg_invocation_id in (" . $algInvIds . ")";
    
    my $processedMotifs;

    my $sth = $queryHandle->prepareAndExecute($sql);
    
    while (my ($motifId) = $sth->fetchrow_array()){
	$processedMotifs->{$motifId} = 1;
    }

    return $processedMotifs;
}



# ----------------------------------------------------------------------
# GetSimilarityDictionary : given a list of aa sequences and table_ids
# that we're interested in, this routine returns a hash ref of the
# form { MOTIF_ID }->[ { similarity_id  => ,
#                        query_id       => ,
#                        query_table_id => ,
#                        threshold      => ,
#                        name           => ,
#                        description    => ,
#                       } ].
# ----------------------------------------------------------------------

sub GetSimilarityDictionary {
    my ($self, $aaFilter, $processedMotifs) = @_;
        
    my $n = 25;
    my $queryHandle = $self->getQueryHandle();
    # dictionary of motifs
    my $rv;

    my $databaseMap;
    
    my $sql_filter = $self->GetSimilarityFilterSQL();
    
    my $motifTableId = $self->getGusTableId("DoTS", "MotifAASequence");

    # try filter proteins from each
    foreach my $id_table ( keys %$aaFilter ) {
	
	my $seqs = $aaFilter->{$id_table};
	# list of ids from the current table
	my @id_aa_seq = keys %$seqs;

	for ( my $i = 0; $i < scalar @id_aa_seq; $i += $n ) {

	    my $j = $self->min( scalar @id_aa_seq - 1, $i + $n - 1 );
	    my $sql = join( ' ',
			    'select ',
			    join( ",\n    ",
				  ( 's.similarity_id',
				    's.subject_id',
				    's.query_id',
				    's.query_table_id',
				    's.pvalue_mant',
				    's.pvalue_exp',
				    's.number_positive',
				    's.total_match_length',
				    'q.description',
				    'q.name',
				    'm.external_database_release_id',
				    'm.source_id',
				    )
				  ),
			    "\n  from",
			    join( ",\n     ",
				  'DoTS.Similarity s',
				  'DoTS.MotifAASequence m',
				  'DoTS.ExternalAASequence q',
				  ),
			    "\n where",
			    join( "\n  and ",
				  's.subject_table_id = ' . $motifTableId,
				  's.query_table_id  =  '. $id_table,
				  $sql_filter,
				  's.query_id in ('.  join( ', ', @id_aa_seq[ $i .. $j ] ). ')',
				  's.subject_id =  m.aa_sequence_id',
				  'm.external_database_release_id in ('. $self->getCla->{ id_db } .')',
				  's.query_id = q.aa_sequence_id', 
				  ),
			    );
	    
	    # CDD-Pfam and CDD-Smart do not include number_of_contained_sequences, so only
	    # add if no_csc is not set.
	    
	    if (! defined $self->getCla->{ no_csc } ){
		$sql = $sql . " and m.number_of_contained_sequences >= ". $self->getCla->{ pd_n };
	    }
	    #figure out better way to do this
	    my $sth = $queryHandle->prepareAndExecute($sql);
	    while ( my ($similarityId, $subjectId, $queryId, $queryTableId, $pValueMant, $pValueExp, $numberPositive, $totalMatchLength, $description, $name, $releaseId, $sourceId) = $sth->fetchrow_array() ) {
		if ($processedMotifs->{$subjectId}){
		    $self->logVerbose ("not adding $subjectId to similarity dictionary");
		    next;
		}
		my $similarityHash;
		$similarityHash->{ similarity_id } = $similarityId;
		$similarityHash->{ subject_id } = $subjectId;
		$similarityHash->{ query_id} = $queryId;
		$similarityHash->{ query_table_id} = $queryTableId;
		$similarityHash->{ pvalue_mant} = $pValueMant;
		$similarityHash->{ pvalue_exp} = $pValueExp;
		$similarityHash->{ number_positive} = $numberPositive;
		$similarityHash->{ total_match_length} = $totalMatchLength;
		$similarityHash->{ description } = $description;
		$similarityHash->{ name} = $name;
		$similarityHash->{sourceId} = $sourceId;

		$similarityHash->{pValue} = $similarityHash->{pvalue_mant} * 10**$similarityHash->{pvalue_exp};
		
		if ( defined $self->getCla->{ sliding } ) {
		    if ( defined $self->getCla->{ sm_pv } ) {
			$similarityHash->{ threshold } = $similarityHash->{ pValue }
		    }
		    elsif ( defined $self->getCla->{ sm_ps } ) {
			$similarityHash->{ threshold } =
			    $similarityHash->{ number_positive } / $similarityHash->{ total_match_length };
		    }
		}
		
		my $databaseId = $databaseMap->{$releaseId};
		if (!$databaseId){
		    $databaseId = $self->getDatabaseIdForRelease($releaseId);
		    $databaseMap->{$releaseId} = $databaseId;
		}
		$similarityHash->{databaseId} = $databaseId;
	
		push( @{ $rv->{ $similarityHash->{ subject_id } } }, $similarityHash );
		
	    }
	    $sth->finish();
	    
	} # eo id bunch
    } # eo sequence table
    my $simcounter = 0;
    # instantiate an empty GUS object for each similarity
    foreach my $id_subj ( keys %{ $rv } ) {
	foreach ( @{ $rv->{ $id_subj } } ) {
	    $_->{ gus_obj } = GUS::Model::DoTS::Similarity->new( {
		similarity_id => $_->{ similarity_id }
	    } );
	    $simcounter++;
	}
    }
    print STDERR "made $simcounter sim objects and have " . scalar(keys %$rv) . " motifs\n";
    # return value
    $rv
    }

sub getDatabaseIdForRelease{

    my ($self, $releaseId) = @_;
    my $sql = "select external_database_id from sres.externaldatabaserelease where external_database_release_id = $releaseId";
    my $sth = $self->getQueryHandle()->prepareAndExecute($sql);
    while (my ($dbId) = $sth->fetchrow_array()){
	return $dbId;   
    }
}

sub getGusTableId {
    my ($self, $owner, $table) = @_;
    my $queryHandle = $self->getQueryHandle();
    my $sql = "select table_id 
               from core.tableinfo c, core.databaseinfo d
               where d.name = '$owner' and c.name = '$table' 
               and c.database_id = d.database_id
              ";
    
    my $sth = $queryHandle->prepareAndExecute($sql);
    my ($tableId) = $sth->fetchrow_array();
    return $tableId;
}

# ----------------------------------------------------------------------
# IntersectGoFunctions :
# ----------------------------------------------------------------------

sub IntersectGoFunctions {
    my ($self, $similarities, $motifId, $graph) = @_;
    
    my $queryHandle = $self->getQueryHandle();
    # how many similarities ( and therefore proteins ) do we have
    my $n_similarities = scalar @$similarities;
    
    # function {}-> number of occurrences.
    my $rv;
    
    # get the list of threshold values for this set of similarities and
    # also sort the similarities by threshold from high (more stringent)
    # to low (less stringent).
    # .................................................................
    
    my @sortedSims = defined $self->getCla->{ sm_ps } ?
	sort { $b->{ threshold } <=> $a->{ threshold } } @$similarities :
	sort { $a->{ threshold } <=> $b->{ threshold } } @$similarities;
    
    my @thresholds = map { $_->{ threshold } } @sortedSims;
    
    # get the _annotated_ GUS GO function ids for the AA sequences
    # linked by these similarities. 
    # 
    # NOTE: This will only retrieve the go function ids for the 
    #    _annotated_ GOAP that are included in the AaFilter (which is
    #    what we want).  We know this because we only retrieved the 
    #    similarities for these aa sequence ids.  So, there is no need
    #    to filter our GOAP from excluded organisms here.
    # .................................................................
    
    my $gusGoIdsBySimilarity  = {};
    my $gusSimilaritiesByGoId = {};
    my $goDbRelId = $self->getCla->{go_ext_db_rel_id};
    my $queryTableId = $self->getGusTableId("DoTS", "ExternalAASequence");
    {
	$self->log("getting ids for " . scalar(@$similarities) . " sims for this motif\n");
	
	my $sql = "select ga.go_term_id from DoTS.GOAssociation ga,  
                       DoTS.GOAssociationInstance gai, SRes.GOTerm gt 
                       where ga.table_id = $queryTableId
                       and ga.is_not != 1
                       and ga.row_id in ?                
                       and gt.go_term_id = ga.go_term_id 
                       and gt.external_database_release_id = $goDbRelId
                       and gai.go_association_id = ga.go_association_id
                       and gai.is_primary = 1";            
		
	
	my $queryHandle = $self->getQueryHandle();
	
	$self->log( 'SQL', 'get_ids', $sql );
	
	my $sth = $queryHandle->prepare($sql);
	foreach my $gus_similarity ( @$similarities ) {
	    my $ids;
	    $sth->execute($gus_similarity->{query_id});

	    while ( my $id = $sth->fetchrow_array( ) ) {
		$self->logVerbose("adding $id to the list for " . $gus_similarity->{query_id});
		push (@$ids, $id);
	    }
	    $self->logVerbose("finished processing external protein " . $gus_similarity->{query_id});	    
	    $gusGoIdsBySimilarity->{ $gus_similarity } = $ids;
	    if (scalar (@$ids) == 0){ print STDERR "no ids in database for sim\n";}
	    else{print STDERR "found " . scalar(@$ids) . " for sim in database \n";}
	    foreach my $id_go ( @{ $ids } ) {
		$gusSimilaritiesByGoId->{ $id_go }->{ $gus_similarity } = 1;
	    }

	}
	$sth->finish();
	    
    }

    
    $self->log( 'INF(ORMATION)', 'nfunc', $motifId, $n_similarities,
		scalar grep {
		    scalar @{ $gusGoIdsBySimilarity->{ $_ } } > 0
		    } keys %{ $gusGoIdsBySimilarity } 
		);
    

    
    # make the prediction, either using sliding threshold or with CLA
    # treshold.
    # .................................................................
    
    my $h_call;
    
    
    # just take the most generous threshold that yields a rule type that
    # is acceptable.
    # .................................................................
    
    # !!!
    # as set up this allows for threshold which are too loose.  See
    # 5070955 where the last two proteins added by lowering the
    # threshold do not match the call and so should not be included.
    #
    
    if ( $self->getCla->{ sliding } eq 'most-generous' ) {
	
	# hash of the rules (rule types) that we think are ok.
	my @ruleArray = split (/,/, $self->getCla->{ sl_gr });
	my $goodRules = {}; foreach (@ruleArray ) { $goodRules->{ $_ } = 1 }

      THRESHOLD_SCAN:
	for ( my $i = 0; $i < $n_similarities; $i++ ) {
	    my $this_call =
		$self->MakePredictionRule ($graph, $motifId,$gusGoIdsBySimilarity,
				    $gusSimilaritiesByGoId,
				    @sortedSims[ 0 .. $i ],
				    );
	    #dtb: pass sorted sims in with [] around it?
	    #dtb: take out my additions to this log
	    # count as good if is a good rule-type and explains weakest similarity.
	    if ( $goodRules->{ $this_call->{ ruleType } } &&
		 $this_call->{ predicted_similarities }->{ $sortedSims[ $i ] }
		 ) {
		$h_call                   = $this_call;
		$h_call->{ threshold }    = $thresholds[ $i ];
		$h_call->{ proteinsUsed } = $i + 1;
		$self->log( 'sig', 'ok', 'motifId: ' . $motifId,
			    'threshold: ' . $sortedSims[ $i ]->{ threshold },
			    'go terms: ' . $this_call->{ signature } );
	    }
	    else {
		$self->log( 'sig', 'bad', 'motifId: ' .  $motifId,
			    'threshold: ' . $sortedSims[ $i ]->{ threshold },
			    'go terms: ' . $this_call->{ signature } );
		
	    }
	    print STDERR "rule when adding next sim: " . $this_call->{ruleType} . "\n";
	    print STDERR "not on list of good rules\n" if  !$goodRules->{ $this_call->{ ruleType } };
	    print STDERR "not account for similarities\n" if !$this_call->{ predicted_similarities }->{ $sortedSims[ $i ] };
	   
	}
	
    }
     
    # extract final calls that are true subgraph leaves
    # .................................................................
    #
    # sometimes the calling mechanism includes some of the nodes on the
    # paths to the root.  This section eliminates those and resets the
    # finalLeaves attribute of the call to the true list.

    {
	my $allParents = $self->GetParents( $h_call->{ finalLeaves },
					    $graph
					    );
	
	my @true_leaves;
	
	foreach my $node ( @{ $h_call->{ finalLeaves } } ) {
	    push( @true_leaves, $node ) unless $allParents->{ $node };
	}
	
	$h_call->{ finalLeaves } = \@true_leaves;
    }
    
    # log the rule and some interesting statistics.
    # .................................................................
    
    $self->log( 'FINAL INF', 'ifl', $motifId,
		$h_call->{ ruleType }, $n_similarities,
		$h_call->{ proteinsUsed }                    || '-',
		$h_call->{ n_predicted_similarities }        || '-',
		sprintf( '%0.2e', $h_call->{ threshold } )   || '-',
		$h_call->{ confidence }                      || '-',
		join( ',', @{ $h_call->{ finalLeaves } } )   || '-',
		join( ',', map {
		    sprintf( "GO:%07d", $graph->{ $_ }->{ gus2go } )
		    } @{ $h_call->{ finalLeaves } } )            || '-',
		);
    
    # determine the terms on the paths-to-root for the selected terms.
    # .................................................................
    
    my @id_final_parents = keys %{ $self->GetParents( $h_call->{ finalLeaves },
						      $graph,
						      ) };
    
    # add the rule sets
    # .................................................................
    
    my @supportingSims = grep {
	$h_call->{ predicted_similarities }->{ $_ }
    } @sortedSims[ 0 .. $h_call->{ n_predicted_similarities } - 1 ];
    
    my @dissentingSims = grep {
	! $h_call->{ predicted_similarities }->{ $_ }
    } @sortedSims[ 0 .. $h_call->{ n_predicted_similarities } - 1 ];
    
    my @unusedSims     = $h_call->{ n_predicted_similarities } < scalar @sortedSims
	? @sortedSims[ $h_call->{ n_predicted_similarities } .. scalar @sortedSims - 1 ]
	: ();
    
    $self->MakeRuleSet(
		       $h_call->{ finalLeaves },     # leaf terms
		
		       \@id_final_parents,           # path-to-root terms
		       
		       {                             # rule  stuff
			   aa_sequence_id_1             => $motifId,
			   rule_type                    => $h_call->{ ruleType },
			   number_of_annotated_proteins => $h_call->{ n_predicted_similarities },
#							 p_value_threshold            => $h_call->{ threshold },
			   p_value_threshold_mant       => $self->get_pval_mant($h_call->{ threshold }),
			   p_value_threshold_exp        => $self->get_pval_exp($h_call->{ threshold }),
			   confidence                   => $h_call->{ confidence },
			   review_status_id             => 0,
		       },
		       #correct review_status_id?
		       
		       {                             # evidence stuff
			   supporting_sims              => \@supportingSims,
			   dissenting_sims              => \@dissentingSims,
			   unused_sims                  => \@unusedSims,
		       },
		       );
    
    return { };
    
}

# ----------------------------------------------------------------------
# MakePredictionRule :
#
# similarities
# ----------------------------------------------------------------------

sub MakePredictionRule {
    my ($self, $graph, $motifId, $gusGofIdsBySimilarity, 
	$gusSimilaritiesByGofId, @similarities) = @_;
	
    #two arrays in @_: ok?
    
    my $n_go_functions      = 0;
    my $n_assigned_proteins = 0;
    my $n_leaves            = 0;
    my $n_parents           = 0;
    
    # find the similarity that has the best p-value and has some
    # annotation.
    # ................................................. ................
    
    my $gus_best_similarity;
    {
	foreach my $gus_similarity ( @similarities ) {
	    
	    if ( scalar @{ $gusGofIdsBySimilarity->{ $gus_similarity } } ) {
		if ( defined $gus_best_similarity ) {
		    if ( $gus_best_similarity->{ pValue } > $gus_similarity->{ pValue } ) {
			$gus_best_similarity = $gus_similarity;
		    }
		}
		else {
		    $gus_best_similarity = $gus_similarity;
		}
	    }
	}
    }
    
    # process each Similarity to get counts of annotations.
    # .................................................................
    
    my $n_assigned_proteins = 0;
    my $id_leaf_terms       = {};
    my $id_parent_terms     = {};
    my $id_best_leaves      = {};
    my $goid_to_sims        = {};
    
    foreach my $gus_similarity ( @similarities ) {
	
	# get the GO term ids for the protein in this similarity
	# skip those that aren't annotated.
	# .................................................................
	
	my $ids = $gusGofIdsBySimilarity->{ $gus_similarity };
        next if scalar @{ $ids } == 0;
	
	my $id_hash; foreach ( @{ $ids } ) { $id_hash->{ $_ } = 1 }
	
	# determine set of leaf nodes in the subtree defined by the set of
	# GO terms annotated for the protein in this similarity.
	# .................................................................
	
	my $leaves;
      ID_LOOP: foreach my $id ( @{ $ids } ) {
	  foreach my $child ( @{ $graph->{ $id }->{ children } } ) {
	      next ID_LOOP if $id_hash->{ $child };  #do not add this id if it has children
	  }
	  $leaves->{ $id } = 1;
      }
	my @leaves = sort keys %{ $leaves };
	
	# this should not happen!
	if ( scalar @leaves <= 0 ) {
	    $self->log( 'ERR', 'no leaves', $motifId, @{ $ids } );
	    next;
	}
	
	# grab the leaves for the best similarity for fallback to pvalue.
	if ( $gus_similarity == $gus_best_similarity ) {
	    $id_best_leaves = { map { ( $_, 1 ) } @leaves };
	}
	
	# node on paths to root for the leaves.
	my $parents = $self->GetParents( \@leaves, $graph);
	
	# make list of parents.
	my @parents = sort keys %{ $parents };
	
	# set and list of all GO annotations.
	my $allCalls = { %{ $leaves }, %{ $parents } };
	my @allCalls = sort keys %{ $allCalls };
	
	# count things.
	$n_leaves  += scalar @leaves;
	$n_parents += scalar @parents;
	$n_assigned_proteins++; # if scalar @leaves > 0;
	
	# record leaf and parent counts
	foreach my $leaf   ( @leaves  ) { $id_leaf_terms->{ $leaf } += 1 }
	
	foreach my $leaf   ( @leaves  ) { $id_parent_terms->{ $leaf   } += 1 }
	foreach my $parent ( @parents ) { $id_parent_terms->{ $parent } += 1 }
	
	# build up id -> sim mapping
	foreach my $term ( @leaves, @parents ) {
	    $goid_to_sims->{ $term }->{ $gus_similarity } = 1;
	}
	
    } # eo similarity scan
    print STDERR "number of assigned proteins for this iteration: $n_assigned_proteins\n";    
    # leaf functions sort by frequency ( high to low )
    my @id_leaf_terms = sort {
	$id_leaf_terms->{ $b } <=> $id_leaf_terms->{ $a } ||  $a <=> $b
	} keys %{ $id_leaf_terms };
    
    my @id_parent_terms = sort {
	$id_parent_terms->{ $b } <=> $id_parent_terms->{ $a } || $a <=> $b
	} keys %{ $id_parent_terms };
    
    # make a call.
    # .................................................................
    
    # standard arguments to rule callers
    my $h_std_rc_args = {
	
	graph                 => $graph,
	
	a_id_leaf_terms       => \@id_leaf_terms,
	h_id_leaf_terms       => $id_leaf_terms,
	
	a_id_parent_terms     => \@id_parent_terms,
	h_id_parent_terms     => $id_parent_terms,
	
	n_assigned_proteins => $n_assigned_proteins,
	best_leaves         => [ keys %{ $id_best_leaves } ],
    };
    
    # the called rule
    my $h_rule;
    
    $h_rule = $self->RC_NoProteins( $h_std_rc_args );
    $h_rule = $self->RC_OneProtein( $h_std_rc_args )        unless $h_rule;
    $h_rule = $self->RC_SingleFunction( $h_std_rc_args )    unless $h_rule;
    $h_rule = $self->RC_ConsensusLeaf( $h_std_rc_args )     unless $h_rule;
    $h_rule = $self->RC_NearConsensusLeaf( $h_std_rc_args ) unless $h_rule;
    $h_rule = $self->RC_NearAncestor( $h_std_rc_args )      unless $h_rule;
    $h_rule = $self->RC_ConsensusAncestor( $h_std_rc_args ) unless $h_rule;
    $h_rule = $self->RC_MajorityLeaf( $h_std_rc_args )      unless $h_rule;
    $h_rule = $self->RC_MajorityAncestor( $h_std_rc_args )  unless $h_rule;
    $h_rule = $self->RC_NoCall( $h_std_rc_args )            unless $h_rule;
    
    # get list of similarities that are actually predicted 'correctly'
    # by the rule.
    # .................................................................
    
    my $predicted_similarities;
    foreach my $term ( @{ $h_rule->{ finalLeaves } } ) {
	foreach ( keys %{ $goid_to_sims->{ $term } } ) {
	    $predicted_similarities->{ $_ } = 1;
	}
    }
    my $n_predicted_similarities = scalar keys %{ $predicted_similarities };
    
    # assign confidence
    # .................................................................

    my $confidence = 'low';
    {
	
	# Check for High Confidence
	#
	
	# by number of proteins predicted
	if ( $n_predicted_similarities >= $self->getCla->{ cf_hnp } ) {
			$confidence = 'high';
		    }
	# by p-value of best match
	elsif ( $self->getCla->{ sm_pv } &&
		$similarities[ 0 ]->{ threshold } <= $self->getCla->{ cf_hpv } ) {
	    $confidence = 'high';
	}		
	# by similarity of best match
	elsif ( $self->getCla->{ sm_ps } &&
		$similarities[ 0 ]->{ threshold } >= $self->getCla->{ cf_hps } ) {
	    $confidence = 'high';
	}
	
	# Check for Medium Confidence
	#
	elsif ( $n_predicted_similarities >= $self->getCla->{ cf_mnp } ) {
	    $confidence = 'medium';
	}
	elsif ( $self->getCla->{ sm_pv } &&
		$similarities[ 0 ]->{ threshold } <= $self->getCla->{ cf_mpv } ) {
	    $confidence = 'medium';
	}
	elsif ( $self->getCla->{ sm_ps } &&
		$similarities[ 0 ]->{ threshold } >= $self->getCla->{ cf_mps } ) {
	    $confidence = 'medium';
	}
	
    }
    
    # return value
    # .................................................................
    
    +{
	%{ $h_rule },
	
	signature                => join( '-', sort( @{ $h_rule->{ finalLeaves } } ) ),
	
	predicted_similarities   => $predicted_similarities,
	n_predicted_similarities => $n_predicted_similarities,
	
	confidence               => $confidence,
    }
}

# ----------------------------------------------------------------------
# ----------------------------------------------------------------------

sub MakeMdlBasedPredictionRule {
	my $self = shift;
	my $A = shift;

	
}

# ----------------------------------------------------------------------
# Rule Callers
# ----------------------------------------------------------------------

sub RC_NoProteins {
	my ($self, $A) = @_;

	my $rv;

	if ( $A->{ n_assigned_proteins } <= 0 ) {
		$rv->{ ruleType }    = 'nopr';
		$rv->{ finalLeaves } = [],
	};

	return $rv;
}

sub RC_NoCall {
	my ($self, $A) = @_;

	my $rv;

	$rv->{ ruleType }    = 'none';
	$rv->{ finalLeaves } = [];

	return $rv;
}

sub RC_OneProtein {
	my ($self, $A) = @_;

	my $rv;

	if ( $A->{ n_assigned_proteins } == 1 ) {
		$rv->{ ruleType } = 'onep';
		$rv->{ finalLeaves } = $A->{ a_id_leaf_terms };
	}

	return $rv;
}

sub RC_SingleFunction {
	my ($self, $A) = @_;

	my $rv;

	if ( scalar @{ $A->{ a_id_leaf_terms } } == 1 ) {
		$rv->{ ruleType }    = 'sing';
		$rv->{ finalLeaves } = $A->{ a_id_leaf_terms };
	}

	return $rv;
}

sub RC_ConsensusLeaf {
	my ($self, $A) = @_;

	my $rv;

	my $b_is_a_full_leaf;
	my $b_contains_full_leaf;

	foreach my $leaf ( @{ $A->{ a_id_leaf_terms } } ) {
		if ( $A->{ h_id_leaf_terms }->{ $leaf } == $A->{ n_assigned_proteins } ) {
			$b_contains_full_leaf = 1;
			$b_is_a_full_leaf->{ $leaf } = 1;
		}
	}

	if ( $b_contains_full_leaf ) {
		$rv->{ ruleType } = 'leaf';
		$rv->{ finalLeaves } = [ keys %{ $b_is_a_full_leaf } ];
	}

	return $rv;
}

sub RC_NearConsensusLeaf {
	my ($self, $A) = @_;

	my $rv;

	if ( $self->getCla->{ er_use } ) {

		if ( $A->{ n_assigned_proteins } >= $self->getCla->{ er_n } ) {

			my $b_is_a_near_consensus;
			my $b_contains_near_consensus;

			foreach my $leaf ( @{ $A->{ a_id_leaf_terms } } ) {
				if ( $A->{ h_id_leaf_terms }->{ $leaf } / $A->{ n_assigned_proteins } >= 
						 $self->getCla->{ er_ncf } )  {
					$b_contains_near_consensus = 1;
					$b_is_a_near_consensus->{ $leaf } = 1;
				}
			}

			if ( $b_contains_near_consensus ) {
				$rv->{ ruleType } = 'ncle';
				$rv->{ finalLeaves } = [ keys %{ $b_is_a_near_consensus } ];
			}
		}
	}

	# return value
	return $rv;
}

sub RC_NearAncestor {
	my ($self, $A) = @_;

	my $rv;

	my $h_ncra = $self->RC_NearConsensusRecentAncestor( $A );
	my $h_cra  = $self->RC_ConsensusRecentAncestor( $A );

	if ( $h_ncra && $h_cra ) {
		$rv = $h_ncra->{ depth } > $h_cra->{ depth } ? $h_ncra : $h_cra;
	}
	elsif ( $h_ncra ) {
		$rv = $h_ncra;
	}
	elsif ( $h_cra ) {
		$rv = $h_cra;
	}

	# return value
	return $rv;
}

sub RC_ConsensusRecentAncestor {
    my ($self, $A) = @_;
    
    my $rv;
    
    if ( $self->getCla->{ er_use } ) {
	
	my $b_is_a_full_parent;
	my $b_contains_full_parent;
	
	# sort the terms so that we check the potentially deepest first.
	my @terms = sort {
	    $A->{ graph }->{ $b }->{ maximum_level } <=> $A->{ graph }->{ $a }->{ maximum_level }
	} @{ $A->{ a_id_leaf_terms } };
	
	foreach my $child ( @terms ) {
	    
	    # get list of close parents for this child
	    my $id_parents =
		$self->GetNthParents( { child     => $child,
				 max_dist  => $self->getCla->{ pa_ml },
				 min_level => $self->getCla->{ pa_sl },
				 graph     => $A->{ graph },
				 children  => $A->{ h_id_leaf_terms },
			     } ) || {};
	    my @id_parents = keys %{ $id_parents };
	    
	    # check each one.
	  PARENT_SCAN:
	    foreach my $parent ( @id_parents ) {
		next if $parent == 0;
		if ( ( $A->{ h_id_parent_terms }->{ $parent } 
		       #+ $A->{ h_id_leaf_terms }->{ $parent } 
		       ) == $A->{ n_assigned_proteins } ) {
		    foreach my $node_found_so_far ( keys %{ $b_is_a_full_parent } ) {
			next PARENT_SCAN if $self->IsAncestor( {
			    child    => $node_found_so_far,
			    ancestor => $parent,
			    graph    => $A->{ graph },
			} );
		    }
		    $b_contains_full_parent = 1;
		    $b_is_a_full_parent->{ $parent } = 1;
		}
	    }
	}

	if ( $b_contains_full_parent ) {
	    $rv->{ ruleType }    = 'npar';
	    $rv->{ finalLeaves } = [ keys %{ $b_is_a_full_parent } ];
	    $rv->{ depth } = $self->min( map {
		$A->{ graph }->{ $_ }->{ minimum_level }
	    } @{ $rv->{ finalLeaves } } );
	}
    }
    
    return $rv;
    }

sub RC_NearConsensusRecentAncestor {
    my ($self, $A) = @_;
    
    my $rv;
    
    if ( $self->getCla->{ er_use } ) {
	if ( $A->{ n_assigned_proteins } >= $self->getCla->{ er_n } ) {
	    
	    my $b_is_a_near_consensus_parent;
	    my $b_contains_near_consensus_parent;
	    
	    # sort the terms so that we check the potentially deepest first.
	    my @terms = sort { 
		$A->{ graph }->{ $b }->{ maximum_level } <=> $A->{ graph }->{ $a }->{ maximum_level }
	    } @{ $A->{ a_id_leaf_terms } };
	    
	    foreach my $child ( @terms ) {
		
		# get list of close parents for this child
		my $id_parents = $self->GetNthParents( { child     => $child,
							 max_dist  => $self->getCla->{ pa_ml },
							 min_level => $self->getCla->{ pa_sl },
							 graph     => $A->{ graph },
							 children  => $A->{ h_id_leaf_terms },
						     } ) || {};
		my @id_parents = keys %{ $id_parents };
		
		# check each one.
	      PARENT_SCAN:
		foreach my $parent ( @id_parents ) {
		    next if $parent == 0;
		    if ( ( $A->{ h_id_parent_terms }->{ $parent }
			   # + $A->{ h_id_leaf_terms }->{ $parent }
			   )
			 / $A->{ n_assigned_proteins } >=
			 $self->getCla->{ er_ncf } ) {
			foreach my $node_found_so_far ( keys %{ $b_is_a_near_consensus_parent } ) {
			    next PARENT_SCAN if $self->IsAncestor( {
				child    => $node_found_so_far,
				ancestor => $parent,
				graph    => $A->{ graph },
			    } );
			}
			$b_contains_near_consensus_parent = 1;
			$b_is_a_near_consensus_parent->{ $parent } = 1;
		    }
		}
	    }
	    
	    if ( $b_contains_near_consensus_parent ) {
		$rv->{ ruleType } = 'nncp';
		$rv->{ finalLeaves } = [ keys %{ $b_is_a_near_consensus_parent } ];
		$rv->{ depth } = $self->min( map { 
		    $A->{ graph }->{ $_ }->{ minimum_level } 
		} @{ $rv->{ finalLeaves } } );
	    }
	}
    }
    
    return $rv;
}

sub RC_ConsensusAncestor {
    my ($self, $A) = @_;
    
    my $rv;
    
    my $b_is_a_full_parent;
    my $b_contains_full_parent;

    # sort the terms so that we check the potentially deepest first.
    my @terms = sort { 
	$A->{ graph }->{ $b }->{ maximum_level } <=> $A->{ graph }->{ $a }->{ maximum_level }
    } @{ $A->{ a_id_parent_terms } };
    
  PARENT_SCAN:
    foreach my $parent ( @terms ) {
	next if $parent == 0;
	if ( ( $A->{ h_id_parent_terms }->{ $parent }
	       # + $A->{ h_id_leaf_terms }->{ $parent }
	       ) == $A->{ n_assigned_proteins } ) {
	    foreach my $node_found_so_far ( keys %{ $b_is_a_full_parent } ) {
		next PARENT_SCAN if $self->IsAncestor( {
		    child    => $node_found_so_far,
		    ancestor => $parent,
		    graph    => $A->{ graph },
		} );
	    }
	    $b_contains_full_parent = 1;
	    $b_is_a_full_parent->{ $parent } = 1;
	}
    }
    
    if ( $b_contains_full_parent ) {
	$rv->{ ruleType } = 'pare';
	$rv->{ finalLeaves } = [ keys %{ $b_is_a_full_parent } ];
    }
    
    return $rv;
}

sub RC_MajorityLeaf {
    my ($self, $A) = @_;
    
    my $rv;
    
    
    my $b_leaf_is_at_least_half;
    my $b_leaf_contains_majority;
    
    foreach my $leaf ( @{ $A->{ a_id_leaf_terms } } ) {
	if ( $A->{ h_id_leaf_terms }->{ $leaf } >=  $A->{ n_assigned_proteins } / 2 ) {
	    $b_leaf_is_at_least_half->{ $leaf } = 1;
	    $b_leaf_contains_majority = 1;
	}
    }
    
    if ( $b_leaf_contains_majority ) {
	$rv->{ ruleType } = 'mjle';
	$rv->{ finalLeaves } = [ keys %{ $b_leaf_is_at_least_half } ];
    }

    return $rv;
}

sub RC_MajorityAncestor {
    my ($self, $A) = @_;
    
    my $rv;
    
    my $b_parent_is_at_least_half;
    my $b_parent_contains_majority;
    
    
    # sort the terms so that we check the potentially deepest first.
    my @terms = sort { 
	$A->{ graph }->{ $b }->{ maximum_level } <=> $A->{ graph }->{ $a }->{ maximum_level }
    } @{ $A->{ a_id_leaf_terms } };
    
  PARENT_SCAN:
    foreach my $parent ( @{ $A->{ a_id_parent_terms } } ) {
	next if $parent == 0;
	if ( ( $A->{ h_id_parent_terms }->{ $parent } 
	       # + $A->{ h_id_leaf_terms }->{ $parent }
	       ) >= $A->{ n_assigned_proteins } / 2 ) {
	    
	    foreach my $node_found_so_far ( keys %{ $b_parent_contains_majority } ) {
		next PARENT_SCAN if $self->IsAncestor( {
		    child    => $node_found_so_far,
		    ancestor => $parent,
		    graph    => $A->{ graph },
		} );
	    }
	    
	    $b_parent_is_at_least_half->{ $parent } = 1;
	    $b_parent_contains_majority = 1;
	}
    }
    
    if ( $b_parent_contains_majority ) {
	$rv->{ ruleType } = 'mjpa';
	$rv->{ finalLeaves } = [ keys %{ $b_parent_is_at_least_half } ];
    }
    
    return $rv;
}

sub RC_BestSimilarity {
    my ($self, $A) = @_;
    
    my $rv;
    
    $rv->{ ruleType } = 'pval';
    $rv->{ finalLeaves } = $A->{ best_leaves };
    
    return $rv;
}


# ----------------------------------------------------------------------
# MakeRuleSet : Create the GUS entries for a RuleSet and the contained
# Rules.
# ----------------------------------------------------------------------

sub MakeRuleSet {
    my $self = shift; 
    my $Ch = shift;  # target terms
    my $Pa = shift;  # list of parent term
    my $Ru = shift;  # Rule template
    my $Ev = shift;  # Evidence material

    # skip things that have no call
    return unless length( $Ru->{ rule_type } ) > 0;
    
    
    # make a rule set to hold all the rules
    my $gus_ruleSet = GUS::Model::DoTS::AAMotifGOTermRuleSet->new( $Ru );
    
    # add evidence for the rule set, which is just the similarities
    # between the domain and the sequences.  Similarities are placed in
    # three evidence groups which are indicated in the list below.
    
    my @evidenceTypes = qw( supporting_sims dissenting_sims unused_sims );
    for ( my $i = 0; $i < @evidenceTypes; $i++ ) {
	my $sims = $Ev->{ $evidenceTypes[ $i ] };
	foreach my $sim ( @{ $sims } ) {
	    $gus_ruleSet->addEvidence( $sim->{ gus_obj }, $i + 1 );
	}
    }
    #defining = node_is_leaf?
    # precompute typical rule values
    my $typicalRule =
    {
	number_of_annotated_proteins => $Ru->{ number_of_annotated_proteins },
	defining                 => 0,
	review_status_id           => $Ru->{ review_status_id },
	confidence                   => $Ru->{ confidence },
    };
    
    # create leaf term rules
    foreach my $id ( @{ $Ch } ) {
	$self->log( 'RULE', 'leaf',
		    $Ru->{ aa_sequence_id_1 }, $Ru->{ rule_type },
		    $id );
	
	my $gus_rule = GUS::Model::DoTS::AAMotifGOTermRule->new( {
	    %{ $typicalRule },
	    defining   => 1,
	    go_term_id => $id,
	} );
	  $gus_rule->setParent( $gus_ruleSet );
      }
    
    # create parent term rules.
    foreach my $id ( @{ $Pa } ) {
      $self->log( 'RULE', 'path',
		  $Ru->{ aa_sequence_id_1 }, $Ru->{ rule_type },
		  $id );
	
	my $gus_rule = GUS::Model::DoTS::AAMotifGOTermRule->new( {
	    %{ $typicalRule },
	      go_term_id => $id,
	} );
	$gus_rule->setParent( $gus_ruleSet );
      }
    
    # submit
    $gus_ruleSet->submit() unless $self->isReadOnly();


}

# ---------------------------------------------------------------------- #
# ---------------------------------------------------------------------- #

#these methods for computing some simple stats are taken directly from
#Jonathan Schug's "V.pm" module.
sub min {
	my $rv = shift;
	foreach ( @_ ) {
		$rv = $_ if $rv > $_;
	}
	return $rv;
}

sub average {
    my ($self) = @_;	
    my $n  = scalar @_;
    return undef unless $n > 0;
    $self->sum( @_ ) / scalar @_
}



sub sum {
    my $rv = 0;
    foreach ( @_ ) { $rv += $_ }
    $rv
    }

sub intersection {
    my ($self, $alist, $blist) = @_;
    
    my $keys;
    
    foreach ( @{ $alist } ) { $keys->{ $_ } = 1 }
    foreach ( @{ $blist } ) { $keys->{ $_ }++ }
    
    return [ grep { $keys->{ $_ } == 2 } keys %{ $keys } ];
}

# ---------------------------------------------------------------------- #
# ---------------------------------------------------------------------- #




1;

__END__

