
package GUS::GOPredict::Plugin::LoadGoAssoc;
@ISA = qw( GUS::PluginMgr::Plugin);
use CBIL::Bio::DbFfWrapper::GeneAssoc::Parser;

use strict;

use GUS::Model::DoTS::GOAssociationInstance;
use GUS::Model::DoTS::GOAssociation;
use GUS::Model::DoTS::GOAssocInstEvidCode;
use FileHandle;

#use V; #if necessary

# ---------------------------------------------------------------------- #
# ---------------------------------------------------------------------- #

sub new {
    
    my $class = shift;
    # create

    my $self = bless {}, $class;
    
    
    # initialize--for now do not override initialize in plugin.pm just set methods
    my $usage = 'loads associations of external sequences to GO terms into GUS';

    #eventually take out Ontology args
    my $easycsp =
	[
	 {o=> 'flat_file',
	  h=> 'read data from this flat file',
	  t=> 'string',
	  r=> 1,
      },
	
#	 {o => 'cvs_ver',
#	  h => 'go version to be entered as go_cvs_version in GOFunction',
#	  t => 'string',
#	  r => 1,
#      },
#	 {o => 'branch',
#	  h => 'what branch of the ontology are you loading',
#	  t => 'string',
#	  r => 1,
#	  d => 'GOFunction',
#      },
	 {o => 'organism',
	  h => 'what organism is the data for',
	  t => 'string',
	  r => 1,
      },
	# {o => 'version',
	#  h => 'SQL-like term to select version of GO ontology',
	#  t => 'string',
	#  r => 1,
    #  },
	 {o => 'id_file',
	  h => 'read and append successfully processed ID here',
	  t => 'string',
	  r => 1,
      }
	 ];

    $self->initialize({requiredDbVersion => {},
		       cvsRevision => '$Revision$', # cvs fills this in!
		     cvsTag => '$Name$', # cvs fills this in!
		       name => ref($self),
		       revisionNotes => 'make consistent with GUS 3.0',
		     easyCspOptions => $easycsp,
		       usage => $usage
		       });


    
    #set private configuration data for this plugin
    #will need to change this!
    #might need to rewrite clean id methods

      
    $self->{ orgInfo } = {
	sgd => { id_col   => 'secondary_identifier',
		 id_tbl   => 'ExternalAASequence',
		 db_id    => [ 2794 ],
		 clean_id => sub { [ $_[ 0 ] ] },
		 delim    => "\t+",
	     },
	fb  => { id_col   => 'source_id',
		 id_tbl   => 'Dots.ExternalAASequence',
		 db_id    => [ 2193, 144 ],
		 clean_id => sub { [ $_[ 0 ] ] },
		 delim    => "\t+",
	     },
	wb  => { id_col   => 'source_id',
		 id_tbl   => 'ExternalAASequence',
		 db_id    => [ 2993 ],
		 clean_id => sub { $_[0] =~ s/WP\://g; [ $_[0] ]; },
		 delim    => "\t+",
	     },
	tair => { id_col   => 'source_id',
		  id_tbl   => 'ExternalAASequence',
		  db_id    => [ 2693 ],
		  clean_id => sub { [ $_[ 0 ] ] },
		  delim    => "\t+",
	      },
	mgi => { id_col   => 'source_id',
		 id_tbl   => 'ExternalAASequence',
		 db_id    => [ 22, 2893, 3093 ],
		 clean_id => sub { $self->{ maps }->{ mgi }->{ $_[ 0 ] } },
		 delim    => "\t+",
	     },
	hum => { id_col   => 'source_id',
		 id_tbl   => 'ExternalAASequence',
		 db_id    => [2893, 3093 ],
		 clean_id => sub { [ $_[ 0 ] ] },
		 delim    => "\t+",
	     },
    };
    
    # load mapping MGI: to SwissProt/TrEMBL
 #   {
#	my $fh = new FileHandle '<'. 'Mappings/MRK_SwissProt.rpt';
#	while ( <$fh> ) {
#	    chomp;
#	    my @parts = split /\t/, $_;
#	    my @id_sp = split /\s/, $parts[ 5 ];
#	    $self->{ maps }->{ mgi }->{ $parts[ 0 ] } = \@id_sp;
#	}
#		Disp::Display( $m->{ maps }->{ mgi }, 'MAPS' );
#	$fh->close if $fh;
#    }
    
    # return object.
    print STDERR "LoadGoAssoc::new() is finished";
    return $self;
}

# ---------------------------------------------------------------------- #
# ---------------------------------------------------------------------- #

sub isReadOnly { 0 }

#---------------------------------------------------------------------- #
# ---------------------------------------------------------------------- #

 
# ---------------------------------------------------------------------- #
# ---------------------------------------------------------------------- #

sub run {
    my $self = shift;
    
    # open the file
    # .................................................................
    
    use FileHandle;

    #dtb: make sure that when retrieving CLA, this is the right usage
    #here 'flat_file' because that was what o was set to in easyCSP

    my $fh = FileHandle->new( '<'. $self->getCla->{flat_file } );
    unless ( $fh ) {
	my @msg = 'unable to open file', $self->getCla ->{ flat_file }, $!;
      
	#correct way to log?
      GusApplication::Log( 'err', @msg );
	return join( "\t", 'no terms loaded', @msg );
    }
    my $msg;
    
    $msg = $self->__load_associations($fh);
    
     
    # return value
  GusApplication::Log( 'msg', $msg );
    return $msg
}

# ---------------------------------------------------------------------- #
# ---------------------------------------------------------------------- #


sub __load_associations {
    my ($self, $fh) = @_;
    print STDERR "beginning LoadGoAssoc::__load_associations";
    # require a few things.
    
    my $logFile;
    # get the list of sequences we've already annotated.
    #right now should be empty
    my $old_seqs = $self->__load_processed_sequences();
    
    my $id_file = $self->getCla->{id_file}; 
    if ($id_file){
	$logFile = FileHandle->new( '>>'. $self->getCla->{ id_file } ); 
    }
    # get the GO graph
    my $goGraph = $self->__load_go_graph( );

# measure of progress
    my $termCount     = 0;
    my $ancestorCount = 0;
    my $skipCount   = 0;
    my $oldCount       = 0;
    my $unknownCount   = 0;
    
    # organism structure
#    my $organism = $self->{ orgInfo }->{ $self->getCla->{ organism } };
    my $parser = CBIL::Bio::DbFfWrapper::GeneAssoc::Parser->new(".");
    $parser->loadFile($fh);
    my $fileStore = $parser->parseFile($fh);
    my $assocData = $fileStore->getParsedEntries();

    foreach my $key (keys %$assocData){
 	my $entry = $assocData->{key};
	
	# visual separator
      GusApplication::Log( '---', '-' x 70 );
	
	# locate sequence.
	my $extSeqGusIds = $self->__get_sequence_id( $entry->getDbObjectId ,
						     $self-> getCla->{ organism }
						     );
	
	# reasons not to process this line
	if ( ! $extSeqGusIds || scalar @{ $extSeqGusIds } <= 0 ) {
	    $skipCount++;
	  GusApplication::Log( 'miss', $entry->getDbObjectId , $skipCount, undef, 'missing sequence' );
	    next
	    }
	elsif ( $old_seqs->{ $entry->getDbObjectId  } ) {
	    $oldCount++;
	  GusApplication::Log( 'old', $entry->getDbObjectId, $oldCount );
	    next
	    }
	
	# attach annotation to each sequence
	#when more than one extSeqGusId?  extSeqGusId's obtained from DBObjId map in ExternalAAsequence.  Should be only one?
	foreach my $extSeqGusId ( @{ $extSeqGusIds } ) {
	    
	    # process each GO term listed
	    my $shortGoId =  $entry->getGOId;
	    $shortGoId=~ s/GO(:| )0*//g;
	    
	    #strip 0's?--yes for child_term_id + parent_term_id
	    
	    #will there ever be more than one GOid in an association row?  this used to split them on ,'s
	    #that doesn't look like it applies anymore
	    
            # GUS id for this GO id
	    my $goTermGusId = $goGraph->{ goToGus }->{ $shortGoId };
	    unless ( $goTermGusId ) {
		$unknownCount++;
	      GusApplication::Log( 'unk', $entry->getDbObjId, $unknownCount, $shortGoId );
		next
		}
	    
	    # for the term.
 

	    $termCount += $self->__make_association( $entry, $extSeqGusId, $goTermGusId, $self->getCla->{ organism });
#	  GusApplication::Log( 'term', $assocRow->{ id },
#			       $termCount, $goTermGusId,
#			       $goGraph->{ name }->{ $goTermGusId },
#			       );
	    
	    # for terms on path to root.
#	    my @gi_ancestors = @{ $self->__get_ancestors( $goTermGusId, $goGraph ) };
#	    foreach my $gi_ancestor ( @gi_ancestors ) {
#		$ancestorCount += $self->__make_association( $extSeqGusId,
#							     $gi_ancestor,
#							     undef,
#							     );
#	      GusApplication::Log( 'path', $assocRow->{ id },
#				   $ancestorCount, $gi_ancestor,
##				   $goGraph->{ name }->{ $gi_ancestor },
#				   );
#	    } # ancestor nodes
	    # term nodes
#	}
	
    # log processing of this sequence.
#	print $fh_log $assocRow->{ id }, "\n" if $fh_log;
	
 #   } # line of file

# return value
#    "loaded: ". join( ', ',
#		      "terms=$termCount",
#		      "ancestors=$ancestorCount",
#		      "old=$oldCount",
#		      "unknown=$unknownCount",
#		      "and skipped=$skipCount"
#		      );
	}
    }

}

# ......................................................................

sub __get_sequence_id {
    my ($self, $dbObjId, $organism) = @_;
    print STDERR "running LoadGoAssoc::get_sequence_id";
    # prepare SQL to get GUS id.
    my $orgInfo = $self->{ orgInfo }->{ $organism };
    
    my $queryHandle = $self->getQueryHandle();

    my $dbList = '( '. join( ', ', @{ $orgInfo->{ db_id } } ). ' )';
    
    my @cleanId = @{ $orgInfo->{ clean_id }->( $dbObjId ) };
    return [] unless scalar @cleanId;
  
    #?
    my $cleanId = join( ', ', map { "'$_'" } @cleanId );
    
   
    my $sql = "
    select aa_sequence_id
      from $orgInfo->{ id_tbl }
     where $orgInfo->{ id_col } in ( $cleanId )
       and external_database_release_id in $dbList
  ";
    
    print STDERR "get_sequence_id: executing sql: $sql";

    # execute the SQL.
    my @gusIds;
    my $sth = $queryHandle->prepareAndExecute($sql);
    open (GETSEQID, ">>./getSeqLog") || die "getSeqLog could not be opened";

    while ( my ( $gusId ) = $sth->fetchrow_array()) {
	push( @gusIds, $gusId );
	if ($gusId){
	    print GETSEQID "$dbObjId, $cleanId, $gusId";
	}
	else{
	    print GETSEQID "no GUS for $dbObjId";
	}
	
    }
    close (GETSEQID);
    # return value
    return @gusIds
    }


# ......................................................................

sub __load_processed_sequences {
    my $self = shift;
    
    my $old_seqs = {};
    
    my $fh = FileHandle->new( '<'. $self->getCla ->{ id_file } );
    if ( $fh ) {
	while ( <$fh> ) {
	    chomp; 
	    $old_seqs->{ $_ } = 1 
	    }
	$fh->close;
    }
    
    # return the set
    return $old_seqs
    }

# ......................................................................

sub __load_go_graph {
    my ($self) = @_;
    print STDERR "Running LoadGoAssoc::load_go_graph";
    my $queryHandle = $self->getQueryHandle();
    # object to return
    my $graph;
    
    #temp output file for debugging:
    open (GOGRAPH, ">>./goGraphLog") || die "go graph log could not be opened";

    my $sql = "

    select h.child_term_id, h.parent_term_id, f.go_id, f.name
      from SRes.GOTerm f, SRes.GORelationship h
     where f.go_function_id = h.child_term_id

  "; #and f.name <> 'root'
    
    # execute the SQL and get the graph
    my $sth = $queryHandle->prepareAndExecute($sql);
    while ( my ( $childId, $parentId, $childGoId, $name ) = $sth->fetchrow_array()) {
	
	# parent link for child
	$graph->{ childToParent }->{ $childId }->{ $parentId } = 1;
	print GOGRAPH "$parentId is parent of $childId\t";
	# child link for parent
	$graph->{ parentToChild }->{ $parentId }->{ $childId } = 1;
	print GOGRAPH "$childId is child of $parentId\t";
	# map from (GUS) child to GO id
	$graph->{ gusToGo }->{ $childId } = $childGoId;
	#if we don't need the above then don't store it
	# map from GO id to (GUS) child
	$graph->{ goToGus }->{ $childGoId } = $childId;
	print GOGRAPH "GUS id of $childGoId is $childId\n"; 
	# name of function
	$graph->{ name }->{ $childId } = $name;
    }
    close (GOGRAPH);
    # return value
    return $graph
    }

# ......................................................................

sub __get_ancestors {
    my $self = shift;
    my $T = shift;
    my $G = shift;

    # set (hash) of nodes on path to root.
    my $path;
    
    # breadth first queue
    my @queue = ( $T );
    
    while ( my $t = shift @queue ) {
	foreach my $p ( keys %{ $G->{ p }->{ $t } } ) {
	    next if $path->{ $p };
	    $path->{ $p } = 1;
			push( @queue, $p );
	}
    }
    
    # return value;
    [ sort { $G->{ o }->{ $a } <=> $G->{ o }->{ $b } } keys %{ $path } ];
}

sub __get_evidence_review_status_map {
    my ($self) = @_;
    my %evidenceMap = {
	IC=>1,
	IDA=>1,
	IEA=>0,
	IEP=>1,
	IGI=>1,
	IMP=>1,
	IPI=>1,
	ISS=>1,
	NAS=>1,
	ND=>0,
	TAS=>1,
	NR=>0,
    };
    return %evidenceMap;
}

sub __get_id_for_evidence_name{
    my ($self, $evdName ) = @_;
    my $queryHandle = $self->getQueryHandle();
    my $sql = "select go_evidence_code_id from SRes.GOEvidenceCode where name = $evdName";
    my $sth = $queryHandle->prepareAndExecute($sql);
    my ( $evdId ) = $sth->fetchrow_array();
    return $evdId;

}

# ......................................................................

sub __make_association {
    
    #Association:
    #table_id, row_id, go_term id, is not, defining, review status id
    
    #AssociationInstance
    #go_assoc_inst_loe, external_db_id, association_id (above), is_not, defining, reviewstatus id, 
    
    #GoassocInstEvidCode:
    #evidence code id, associationInstanceId, reviewStatusId
    
    my ($self, $entry, $externalSeqGusId, $goTermGusId, $organism) = @_; 
    my $orgInfo = $self->{ orgInfo }->{ $organism };
    my $tableId = getTableIdFromTableName( $orgInfo->{id_tbl});
    
    my $evidenceMap = $self->__get_evidence_review_status_map();
    my $reviewStatus = $evidenceMap->{$entry->getEvidence()};
    my @dbs = $orgInfo->{db_id};
    my $is_not = entry->getIsNot(); #test this with both cases;

    #need to add full path for all objects--this one is not valid currently
    my $gusAssoc = GUS::Model::DoTS::GOAssociation->new( {
	table_id => $tableId,
	row_id => $externalSeqGusId,
	go_term_id => $goTermGusId,
	is_not => $is_not, #make sure this works
	review_status_id => $reviewStatus, #check to make sure ok--0 means never manually reviewed
	defining=> 1, #need to differentiate between defining and not--parameter?
    });

    my $gusAssocInst = GUS::Model::DoTS::GOAssociationInstance->new( {
	external_db_id=> $dbs[0], #take first db for now, this is bigger issue
	is_not => $is_not,
	review_status_id => $reviewStatus,
	defining => 1,
	go_assoc_inst_loe_id => 1, #hardcoded for now
	#see above
    });
    
    $gusAssoc->addChild($gusAssocInst); #big test
    
    my $evidCodeInst = GUS::Model::DoTS::GOAssocInstEvidCode->new ({
	go_evidence_code_id => __get_id_for_evidence_name($entry->getEvidence()),
	review_status_id => $reviewStatus,
    });
    
    $gusAssocInst->addChild($evidCodeInst);
    
    #$gusAssoc->submit() unless isReadOnly();
    
    $self->undefPointerCache();

    1;
}

# ---------------------------------------------------------------------- #
# ---------------------------------------------------------------------- #

1;

