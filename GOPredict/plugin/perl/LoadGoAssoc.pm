package GUS::GOPredict::Plugin::LoadGoAssoc;
@ISA = qw( GUS::PluginMgr::Plugin);
use CBIL::Bio::DbFfWrapper::GeneAssoc::Parser;

use Env qw(GUS_HOME); #this will have to change obviously dtb why?
use strict 'vars';

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

    
    my $easycsp =
	[
	 {o=> 'flat_file',
	  h=> 'read data from this flat file',
	  t=> 'string',
	  r=> 1,
      },

	 {o => 'organism',
	  h => 'what organism is the data for',
	  t => 'string',
	  r => 1,
      },
	
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
		 assoc_meth    => 'getDBObjectId',
	     },
	fb  => { id_col   => 'source_id',
		 id_tbl   => 'Dots.ExternalAASequence',
		 db_id    => [ 2193, 144 ],
		 clean_id => sub { [ $_[ 0 ] ] },
		 assoc_meth    => 'getDBObjectId',
	     },
	wb  => { id_col   => 'source_id',
		 id_tbl   => 'ExternalAASequence',
		 db_id    => [ 2993 ],
		 clean_id => sub { $_[0] =~ s/WP\://g; [ $_[0] ]; },
		 assoc_meth    => 'getDBObjectSymbol',
	     },
	tair => { id_col   => 'source_id',
		  id_tbl   => 'ExternalAASequence',
		  db_id    => [ 2693 ],
		  clean_id => sub { [ $_[ 0 ] ] },
		  assoc_meth    => 'getDBObjectSymbol',
	      },
	mgi => { id_col   => 'source_id',
		 id_tbl   => 'ExternalAASequence',
		 db_id    => [ 22, 2893, 3093 ],
		 clean_id => sub { $self->{ maps }->{ mgi }->{ $_[ 0 ] } },
		 assoc_meth    => "\t+",
	     },
	hum => { id_col   => 'source_id',
		 id_tbl   => 'ExternalAASequence',
		 db_id    => [2893, 3093 ],
		 clean_id => sub { [ $_[ 0 ] ] },
		 assoc_meth    => "\t+",
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
    print STDERR "LoadGoAssoc::new() is finished \n";
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
    print STDERR "beginning method LoadGoAssoc::run \n";
    use FileHandle;

    #dtb: make sure that when retrieving CLA, this is the right usage
    #here 'flat_file' because that was what o was set to in easyCSP
#don't worry about filehandle here.  
    
    my $fh = FileHandle->new( '<'. $self->getCla->{flat_file } );
    unless ( $fh ) {
	my @msg = 'unable to open file', $self->getCla ->{ flat_file }, $!;
      
	#correct way to log?
     
	return join( "\t", 'no terms loaded', @msg );
    }
    my $fileName = $self->getCla->{flat_file};
    print STDERR "\n LoadGOAssoc::run : filehandle is $fh";
    print STDERR "\n LoadGOAssoc::run file name is $fileName";
    my $msg;
    
    $msg = $self->__load_associations($fileName);
    
     
    # return value
     return $msg
}

# ---------------------------------------------------------------------- #
# ---------------------------------------------------------------------- #


sub __load_associations {
    my ($self, $file) = @_;
    print STDERR "beginning LoadGoAssoc::__load_associations \n";
    # require a few things.
    open (BIGLOG, ">>logs/pluginLog") || die "pluginLog could not be opened";
    my $logFile;
    # get the list of sequences we've already annotated.
    #right now should be empty
    my $old_seqs = $self->__load_processed_sequences();
    
    #test table
    
    
    
    my $id_file = $self->getCla->{id_file}; 
    if ($id_file){
	$logFile = FileHandle->new( '>>'. $self->getCla->{ id_file } ); 
    }
    # get the GO graph
    my $goGraph = $self->__load_go_graph( );
    
    # measure of progress
    my $termCount      = 0;
    my $ancestorCount  = 0;
    my $skipCount      = 0;
    my $oldCount       = 0;
    my $unknownCount   = 0;
    
    #make path to file configurable, eventually go into data
    my $parser = CBIL::Bio::DbFfWrapper::GeneAssoc::Parser->new("$GUS_HOME/lib/perl/GUS/GOPredict/Plugin");
    
    $parser->loadFile($file);
    my $fileStore = $parser->parseFile($file);
    my $allEntries = $fileStore->getParsedEntries();
    
    my $tempOrgInfo = $self->{orgInfo}->{$self->getCla->{organism}} ;
    my $assocMethod = $tempOrgInfo->{assoc_meth};

    #retrieve Ids for external info 
    my $allGusIds = $self->__get_sequence_id($self->getCla->{organism}, $allEntries);
    my $allEvdIds = $self->__get_evidence_ids($allEntries);
    my $evidenceMap = $self->__get_evidence_review_status_map();
    
    #convert file store into hash to be used by algorithm
    my $assocData;
    foreach my $key (keys %$allEntries){
	my $entry = $allEntries->{$key};
	my $tempGoTerm = $entry->getGOId();
	my $tempEvd = $entry->getEvidence();
	my $newKey = $entry->$assocMethod;
	$assocData->{$newKey}->{goTerms}->{$tempGoTerm}->{$tempEvd} = $entry;
	$assocData->{$newKey}->{extSeqGusId} = $allGusIds->{$key};
	$assocData->{$newKey}->{evdGusId} = $allEvdIds->{$key};
    }
    
    
    #for each external sequence
    foreach my $key (keys %$assocData){
	
	my $goIds = $assocData->{$key}->{goTerms};
	my $extSeqGusId = $assocData->{$key}->{extSeqGusId};
	my $evdGusId = $assocData->{$key}->{evdGusId};  
	my $ancestorsMade;
	
	unless ($goIds) {
	    print BIGLOG "LoadAssoc:  no entry for key: $key";
	}
	
	# reasons not to process this line
	
	if ( ! $extSeqGusId ){ # examine this to see if its necessary see loop issue below|| scalar @{ $extSeqGusIds } <= 0 ) {
	    
	    $skipCount++;
	    next
	    }
	elsif ( $old_seqs->{ $key  } ) {
	    $oldCount++;
	    
	    next
	    }
	
	# attach annotation to each sequence
	#don't make this a loop if there's never more than one extseqgusid
	#foreach my $extSeqGusId ( @{ $extSeqGusIds } ) {
	
	# process each GO term listed
	#my $shortGoId =  $entry->getGOId;
	#$shortGoId=~ s/GO(:| )0*//g;
	
	
	#my $longGoId = $entry->getGOId;
	#for each go term associated with this external sequence
	foreach my $goId (keys %$goIds){
	    
         #will there ever be more than one GOid in an association row?  old plugin used to split them on ,'s
	    #that doesn't look like it applies anymore (maybe mgi?)
	    print BIGLOG "making association with GOTerm $goId \n";   
	    # GUS id for this GO id
	    my $goTermGusId = $goGraph->{ goToGus }->{ $goId };
	    unless ( $goTermGusId ) {
		$unknownCount++;
		print BIGLOG "could not find goTermGusId for goId $goId $unknownCount \n";
		next
		}

	    my @goAncestors = @{ $self->__get_ancestors( $goTermGusId, $goGraph ) };
	    
	    my $evdIds = $goIds->{$goId};
	    #for each evidence code determining how the external sequence
	    #was associated with the go term
	    foreach my $evdId (keys %$evdIds){
		
		my $entry = $evdIds->{$evdId};
                #make association for the term itself
		print BIGLOG "\tmaking real term association with $goId and " . $entry->getDBObjectId . " on code " . $entry->getEvidence . "\n";
		$termCount += $self->__make_association( $entry, $extSeqGusId, $goTermGusId, $evdGusId, $evidenceMap, $self->getCla->{ organism }, 1);
		
		
		if ($entry->getIsNot()){
		    $ancestorsMade->{$key . $evdId}->{$goId} = -1; }
		else {$ancestorsMade->{$key . $evdId}->{$goId} = 1;
		  print BIGLOG " made real term association and mapping $key $evdId  to $goId as 1"; }
		
		#make association for terms on path to root.
		foreach my $goAncestor ( @goAncestors ) {
		    my $ancestorGoId = $goGraph->{gusToGo}->{$goAncestor};		
		    print BIGLOG "\t\tmaking ancestor association for $ancestorGoId and " . $entry->getDBObjectId . "on code " . $entry->getEvidence . "\n";
		
                    #don't make if already made from common descendant
		    #or if other descendant is 'isnot'
		    if ($ancestorsMade->{$key . $evdId}->{$ancestorGoId} == 1){
			print BIGLOG "\t\t skipping this ancestor assignment as $key $evdId  mapped to $ancestorGoId is true\n";
			next;}
		    
		    $ancestorCount += $self->__make_association( $entry,
								 $extSeqGusId,
								 $goAncestor,
								 $evdGusId,
								 $evidenceMap,
								 $self->getCla->{ organism},
								 0
								 );
		    print BIGLOG "\t\t made ancestor\n";
		    if ($entry->getIsNot()){
			$ancestorsMade->{$key . $evdId}->{$ancestorGoId} = -1; }
		    else {$ancestorsMade->{$key . $evdId}->{$ancestorGoId} = 1;}	       
		} # end ancestor association
	    } # end this evidence
	}  #end this go term    
    } #end this external sequence

    # log processing of this sequence.
#	print $fh_log $assocRow->{ id }, "\n" if $fh_log;
    
#	} # line of file
	
# return value
    "loaded: ". join( ', ',
		      "terms=$termCount",
		      "ancestors=$ancestorCount",
		      "old=$oldCount",
		      "unknown=$unknownCount",
		      "and skipped=$skipCount"
		      );
}




# ......................................................................

sub __get_evidence_ids{
    my ($self, $assocData) = @_;
    print STDERR "running get_evidence_ids\n";
    my %evdIds = {};
    my $queryHandle = $self->getQueryHandle();
    my $sql =  
	"select go_evidence_code_id from SRes.GOEvidenceCode 
         where name = ?";
    my $sth = $queryHandle->prepare($sql);
    foreach my $key (keys %$assocData){
	my $entry = $assocData->{$key};
	my $evdName = $entry->getEvidence;
	$sth->execute($evdName);
	while (my ($evdId) = $sth->fetchrow_array()){
	    %evdIds->{$key} = $evdId;
	}
    }
    print STDERR "end get_evidence_ids\n";
    return \%evdIds;
}
	

sub __get_sequence_id {
    my ($self, $organism, $assocData) = @_;
    print STDERR "running LoadGoAssoc::get_sequence_id\n";
    # prepare SQL to get GUS id.
    my $orgInfo = $self->{ orgInfo }->{ $organism };
    my %gusIds = {};
    open (GETSEQID, ">>logs/getSeqLog") || die "getSeqLog could not be opened";


    my $queryHandle = $self->getQueryHandle();

    my $dbList = '( '. join( ', ', @{ $orgInfo->{ db_id } } ). ' )';
    my $assocMethod = $orgInfo->{assoc_meth};
    my $fromTbl = $orgInfo-> { id_tbl};
    my $whereCol = $orgInfo -> {id_col};

    my $prepareSql = "
                select aa_sequence_id 
                from $fromTbl 
                where external_database_release_id in $dbList
                and $whereCol = ?" ;
    my $sth = $queryHandle->prepare($prepareSql);
    
    foreach my $key (keys %$assocData){
	my $entry = $assocData->{$key};
	my $extId = $entry->$assocMethod;
	my $cleanId =  $orgInfo->{ clean_id }->( $extId ) ;
	$sth->execute($extId);
	while (my ($gusId) = $sth->fetchrow_array()){
	    %gusIds->{$key}= $gusId;
	    
	    if ($gusId){
	       print GETSEQID "$extId, $cleanId, $gusId \n";
	    }
	    else{
		print GETSEQID "no GUS for $extId \n";
	    }
	}
    }

	#old version of plugin, clean id could be @.  Find out if this can really happen (mgi maybe?)

   #    return [] unless scalar @cleanId;
      #?
 # my $cleanId = join( ', ', map { "'$_'" } @cleanId );
    

    close (GETSEQID);
    # return value
    print STDERR "end get_sequence_id\n";
    return \%gusIds;
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
#    open (GOGRAPH, ">>./goGraphLog") || die "go graph log could not be opened";

    my $sql = "

    select h.child_term_id, h.parent_term_id, f.go_id, f.name
      from SRes.GOTerm f, SRes.GORelationship h
     where f.go_term_id = h.child_term_id

  "; #and f.name <> 'root'
    
    # execute the SQL and get the graph
    my $sth = $queryHandle->prepareAndExecute($sql);
    while ( my ( $childId, $parentId, $childGoId, $name ) = $sth->fetchrow_array()) {
	
	# parent link for child
	$graph->{ childToParent }->{ $childId }->{ $parentId } = 1;
	  #print GOGRAPH "$parentId is parent of $childId\t";
	 
        # child link for parent
	$graph->{ parentToChild }->{ $parentId }->{ $childId } = 1;
	  #print GOGRAPH "$childId is child of $parentId\t";

	# map from (GUS) child to GO id
	$graph->{ gusToGo }->{ $childId } = $childGoId;
	#if we don't need the above then don't store it

	# map from GO id to (GUS) child
	$graph->{ goToGus }->{ $childGoId } = $childId;
	  #print GOGRAPH "GUS id of $childGoId is $childId\n"; 

	# name of function
	$graph->{ name }->{ $childId } = $name;
    }
#    close (GOGRAPH);
    # return value
    return $graph
    }

# ......................................................................

sub __get_ancestors {
    my ($self, $goTermGusId, $goGraph) = @_;

    # set (hash) of nodes on path to root.
    my $path;
    
    # breadth first queue
    my @queue = ( $goTermGusId );
    
    while ( my $nextTerm = shift @queue ) {
	foreach my $parentOfNextTerm ( keys %{ $goGraph->{ childToParent }->{ $nextTerm } }) {
	    next if $path->{ $parentOfNextTerm };
	    $path->{ $parentOfNextTerm } = 1;
	    push( @queue, $parentOfNextTerm );
	}
    }
    
    # return value;
    [ sort { $goGraph->{ gusToGo }->{ $a } <=> $goGraph->{ gusToGo }->{ $b } } keys %{ $path } ];
}



# ......................................................................

sub __make_association {
    
    #Association:
    #table_id, row_id, go_term id, is not, defining, review status id
    
    #AssociationInstance
    #go_assoc_inst_loe, external_db_id, association_id (above), is_not, defining, reviewstatus id, 
    
    #GoassocInstEvidCode:
    #evidence code id, associationInstanceId, reviewStatusId
    
    my ($self, $entry, $externalSeqGusId, $goTermGusId, $evdGusId, $evidenceMap, $organism, $defining) = @_; 

    open (ASSOCLOG, ">>logs/assocLog") || die "assocLog could not be opened";
    open (AILOG, ">>logs/assocInstLog") || die "assocInstLog could not be opened";
    open (EVDLOG, ">>logs/evdLog") || die "evdlog could not be opened";

    my $orgInfo = $self->{ orgInfo }->{ $organism };
    my $extEvd = $entry->getEvidence;
    my $reviewStatus = $evidenceMap->{$extEvd}->{reviewStatus};
    
    my $dbs = $orgInfo->{db_id};
    my $is_not = $entry->getIsNot(); #test this with both cases;

   
    
    my $gusAssoc = GUS::Model::DoTS::GOAssociation->new( {
 	row_id => $externalSeqGusId,
 	go_term_id => $goTermGusId,
 	is_not => $is_not, #make sure this works
 	review_status_id => $reviewStatus, 
 	defining=> $defining, 
    });
    #need to make configurable but needs to be in "::" form
    #my $tableId = $gusAssoc->getTableIdFromTableName("DoTS::ExternalSequence" );
#     $gusAssoc->setTableId($tableId);

    my $gusAssocInst = GUS::Model::DoTS::GOAssociationInstance->new( {
 	external_database_release_id=> $dbs->[0], #take first db for now, this is bigger issue (make sure you can read second)
 	is_not => $is_not,
 	review_status_id => $reviewStatus,
 	defining => $defining,
 	go_assoc_inst_loe_id => 1, #hardcoded for now
	#see above
    });
    
    $gusAssoc->addChild($gusAssocInst); #big test
    
    my $realEvidGusCode = $evidenceMap->{$extEvd}->{evdGusId};
    my $evidCodeInst = GUS::Model::DoTS::GOAssocInstEvidCode->new ({
 	go_evidence_code_id => $realEvidGusCode,
 	review_status_id => $reviewStatus,
     });
    
     $gusAssocInst->addChild($evidCodeInst);
 

     print ASSOCLOG $gusAssoc->toString() . "\n";
     print AILOG $gusAssocInst->toString() . "\n";
     print EVDLOG $evidCodeInst->toString() . " and evidence code is " . $entry->getEvidence . " \n";

    #$gusAssoc->submit() unless isReadOnly();
    
    $self->undefPointerCache();

    1;
}

sub __get_evidence_review_status_map {
    my ($self) = @_;
    my $queryHandle = $self->getQueryHandle();
    my $sql = "select name, go_evidence_code_id from sres.goevidencecode";
    my $sth = $queryHandle->prepareAndExecute($sql);
    my $evidenceMap;
    while (my ($name, $evdGusId) = $sth->fetchrow_array()){
	$evidenceMap->{$name}->{evdGusId} = $evdGusId;
    }
    
    $evidenceMap->{IC}-> {reviewStatus} = 1; 
    $evidenceMap->{IDA}->{reviewStatus} = 1;
    $evidenceMap->{IEA}->{reviewStatus} = 0;
    $evidenceMap->{IEP}->{reviewStatus} = 1,
    $evidenceMap->{IGI}->{reviewStatus} = 1;
    $evidenceMap->{IMP}->{reviewStatus} = 1;
    $evidenceMap->{IPI}->{reviewStatus} = 1;
    $evidenceMap->{ISS}->{reviewStatus} = 1;
    $evidenceMap->{NAS}->{reviewStatus} = 1;
    $evidenceMap->{ND}-> {reviewStatus} = 0;
    $evidenceMap->{TAS}->{reviewStatus} = 1;
    $evidenceMap->{NR}-> {reviewStatus} = 0;
    
    return $evidenceMap;
}






# ---------------------------------------------------------------------- #
# ---------------------------------------------------------------------- #

1;

