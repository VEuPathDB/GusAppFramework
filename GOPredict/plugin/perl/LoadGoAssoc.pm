package GUS::GOPredict::Plugin::LoadGoAssoc;
@ISA = qw( GUS::PluginMgr::Plugin);
use CBIL::Bio::GeneAssocParser::Parser;

use lib "$ENV{GUS_HOME}/lib/perl";

use strict 'vars';

use GUS::Model::DoTS::GOAssociationInstance;
use GUS::Model::DoTS::GOAssociation;
use GUS::Model::DoTS::GOAssocInstEvidCode;
use GUS::Model::Core::TableInfo;
use FileHandle;

# ---------------------------------------------------------------------- #
# ---------------------------------------------------------------------- #

sub new {
    
    my $class = shift;
    # create

    my $self = bless {}, $class;
    
    
    # initialize--for now do not override initialize in plugin.pm just set methods
    my $usage = 'loads associations of external sequences to GO terms into GUS';

    #good go id: 6532
    my $easycsp =
	[
	 {o=> 'go_ext_db_rel_id',
	  h=> 'external database release id for GO Terms to associate with external sequences',
	  t=> 'int', 
	  r=> 1,
      },
	 {o=> 'flat_file',
	  h=> 'read data from this flat file.  If blank, read data from all gene_association files in filepath',
	  t=> 'string',
	  
      },
	 {o=> 'file_path',
	  h=> 'location of gene_association files to read',
	  t=> 'string',
	  r=> 1,
      },
	 {o=> 'mgi_file_path',
	  h=> 'location of mgi/swissprot mapping file if loading mgi associations',
	  t=> 'string',
      },
	
	 {o=> 'loadAgain',
	  h=> 'Set this to reload a release of External Sequences that have already been loaded',
	  t=> 'boolean',
      },

	 {o => 'id_file',
	  h => 'read and append successfully processed ID here (necessary for crash-recovery)',
	  t => 'string',
	  r => 1,
      },
	 {o => 'yeast_db_rls_id',
	  h => 'External database release id for yeast sequences',
	  t => 'int',
      },
	 {o => 'fb_db_rls_id',
	  h => 'External database release id for fly sequences',
	  t => 'int',
      },
	 {o => 'tair_db_rls_id',
	  h => 'External database release id for Arabidopsis sequences',
	  t => 'int',
      },
	 {o => 'worm_db_rls_id',
	  h => 'External database release id for worm sequences',
	  t => 'int',
      },
	 {o => 'sp_db_rls_id',
	  h => 'External database release id for yeast sequences',
	  t => 'int',
      },
	 {o => 'tr_db_rls_id',
	  h => 'External database release id for yeast sequences',
	  t => 'int',
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

    # return object.
    #print STDERR "LoadGoAssoc::new() is finished \n";
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
    #print STDERR "beginning method LoadGoAssoc::run \n";
    
    my $path = $self->getCla->{file_path};
    my $parser = CBIL::Bio::GeneAssocParser::Parser->new($path);

    $self->loadOrgInfo();


    my $fileName = $self->getCla->{flat_file};

    if ($fileName){
	$parser->loadFile($fileName);
    }
    else {
	$parser->loadAllFiles();
    }
    $parser->parseAllFiles();
        
    my $msg;
    
    $msg = $self->__load_associations($parser);
    
     
    # return value
     return $msg
}

# ---------------------------------------------------------------------- #
# ---------------------------------------------------------------------- #


sub __load_associations {
    my ($self, $parser) = @_;

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
    my $allGoAncestors = $self->__load_go_ancestors($goGraph);
    # measure of progress
    my $termCount      = 0;
    my $ancestorCount  = 0;
    my $skipCount      = 0;
    my $oldCount       = 0;
    my $unknownCount   = 0;
    my $evidenceCount = 0;
   

    my $stores = $parser->getFileStores();
    foreach my $file (keys %$stores){
	my $fileStore = $stores->{$file};
	
	my $allEntries = $fileStore->getParsedEntries();
	my ($organism) = $file =~ /gene_association\.(\w+)$/;
	$self->__checkDatabaseRelease($organism);
	$self->__loadMgiMapIfMouse($organism);

	open (BIGLOG, ">>logs/pluginLog$organism") || die "pluginLog could not be opened";

	#print STDERR "loading organism $organism\n";
	my $orgInfo = $self->{orgInfo}->{$organism};
	
	next if ($self->__checkIfSeqsLoaded($orgInfo, $file));

	my $assocMethod = $orgInfo->{assoc_meth};
	
	#retrieve Ids for external info 
	my $allGusIds = $self->__get_sequence_id($organism, $allEntries);
	my $allEvdIds = $self->__get_evidence_ids($allEntries);
	my $evidenceMap = $self->__get_evidence_review_status_map();
	
	#get table id for table name that external sequences are in
	my $tableId = $self->__getTableIdForOrg($orgInfo->{id_tbl});
		
	#convert file store into hash to be used by algorithm
	my $assocData = $self->__createAssocData($allEntries, $allGusIds, $assocMethod);
	print STDERR "starting adjust isnots\n";
	$self->__adjustIsNots($assocData, $allGoAncestors, $goGraph);
	print STDERR "ending adjust isnots\n";
	
	#for each external sequence
	foreach my $extSeq (keys %$assocData){
	    
	    print BIGLOG "loading association for $extSeq\n";

	    my $goIds = $assocData->{$extSeq}->{goTerms};
	    my $extSeqGusId = $assocData->{$extSeq}->{extSeqGusId};
	    
	    my $ancestorsMade;
   
	    # reasons not to process this line
	    
	    if ( ! $extSeqGusId ){ 
		$skipCount++; next
		}
	    elsif ( $old_seqs->{ $extSeq  } ) {
		$oldCount++; next
		}
	    
	    #for each go term associated with this external sequence
	    foreach my $goId (keys %$goIds){
		
		
		
		my $goTermGusId = $goGraph->{ goToGus }->{ $goId };
		unless ( $goTermGusId ) {
		    $unknownCount++;
		    print BIGLOG "could not find goTermGusId for goId $goId $unknownCount \n";
		    next
		    }
	
	
		my @goAncestors = @{ $allGoAncestors->{$goTermGusId} };		
		my $entry = $goIds->{$goId}->{entry};
		my $tempIsNot = $entry->getIsNot();
		
		print BIGLOG "making association with GOTerm $goId is not: $tempIsNot\n";   
		my $evdIds = $goIds->{$goId}->{evidence};
		if ($ancestorsMade->{$extSeqGusId}->{$goId}){
			my $msg = "\t\t skipping this defining assignment as $extSeq  mapped to $goId is ";
			$msg .= $ancestorsMade->{$extSeqGusId}->{$goId};
			print BIGLOG $msg . "\n";
			next;
		    }
		    
                #make association for the term itself
		$evidenceCount += 
		    $self->__make_association( $entry, $tableId, $extSeqGusId, 
					       $goTermGusId, $evdIds, $evidenceMap, 
					       $organism, 1);
		$termCount++;
		
		if ($entry->getIsNot()){
		    $ancestorsMade->{$extSeqGusId}->{$goId} = -1; }
		else {$ancestorsMade->{$extSeqGusId}->{$goId} = 1;}
		
		
		#make association for terms on path to root.
		
		foreach my $goAncestor ( @goAncestors ) {
		    my $ancestorGoId = $goGraph->{gusToGo}->{$goAncestor};		
		    print BIGLOG "\t\tmaking ancestor association for $ancestorGoId and " . $entry->getDBObjectId . " is not: $tempIsNot \n";
		    
		    #don't make if already made from common descendant
		    
		    if ($ancestorsMade->{$extSeqGusId}->{$ancestorGoId}){
			my $msg = "\t\t skipping this ancestor assignment as $extSeq  mapped to $ancestorGoId is ";
			$msg .= $ancestorsMade->{$extSeqGusId}->{$ancestorGoId};
			print BIGLOG $msg . "\n";
			next;
		    }

		    #don't make if ancestor should be set to 'is' even though the descendant goId 'is not'
		    elsif ($entry->getIsNot()){
			print BIGLOG "\t\t entry isNot, check to see if ancestor $ancestorGoId should be is\n";
			if ($self->__ancestorShouldBeIs($goAncestor, $goIds, $allGoAncestors, $goGraph)){
			    print BIGLOG "\t\t skipping this ancestor assignment because it should be IS\n";
			    next;
			}
			else {print BIGLOG "\t\tthis ancestor should be isNot\n";}
		    }

		    #make if ancestor passes the previous conditions
		    $self->__make_association( $entry, $tableId, $extSeqGusId,
					       $goAncestor, $evdIds, $evidenceMap,
					       $organism, 0
					       );
		    $ancestorCount++;
		    
		    if ($entry->getIsNot()){
			$ancestorsMade->{$extSeqGusId}->{$ancestorGoId} = -1; }
		    else {$ancestorsMade->{$extSeqGusId}->{$ancestorGoId} = 1;}	       
		
		} # end ancestor association
	    }  #end this go term    

	    print $logFile $extSeq . "\n";
	} #end this external sequence
	close BIGLOG;
    }#end this association file
    

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

sub __make_association {
    
    my ($self, $entry, $tableId, $externalSeqGusId, $goTermGusId,  $evdIds, $evidenceMap, $organism, $defining) = @_; 
    open (ASSOCLOG, ">>logs/assocLog$organism") || die "assocLog could not be opened";
    open (AILOG, ">>logs/assocInstLog$organism") || die "assocInstLog could not be opened";
    
    my $evidenceCount = 0;
    my $orgInfo = $self->{ orgInfo }->{ $organism };
    my $extEvd = $entry->getEvidence();
    my $reviewStatus = $evidenceMap->{$extEvd}->{reviewStatus};
    my $isNot = 0;
    my $dbs = $orgInfo->{db_id};
    if ($entry->getIsNot()){
	$isNot = 1;
    }

    my $assocDate = $self->__getEntryDate($entry->getEntryDate());

    my $gusAssoc = GUS::Model::DoTS::GOAssociation->new( {
 	table_id => $tableId - 1,    #hack for testing
	row_id => $externalSeqGusId,
 	go_term_id => $goTermGusId,
 	is_not => $isNot, 
 	review_status_id => $reviewStatus, 
 	defining=> $defining,
	go_association_date => $assocDate,
    });
    
    my $gusAssocInst = GUS::Model::DoTS::GOAssociationInstance->new( {
 	external_database_release_id=> $self->getCla->{go_ext_db_rel_id},
 	is_not => $isNot,
 	review_status_id => $reviewStatus,
 	defining => $defining,
 	go_assoc_inst_loe_id => 1, #hardcoded for now
    });

    if ($defining){
	foreach my $evdId (keys %$evdIds){
	    my $evdCodeInst = $self->__make_evidence_code_inst($evdId, $evidenceMap);
	    $gusAssocInst->setChild($evdCodeInst);
	    $evidenceCount++;
	}
    }
   $gusAssoc->setChild($gusAssocInst); #big test
    
    print ASSOCLOG "before: " . $gusAssoc->toString() . "\n";
    print AILOG "before: " . $gusAssocInst->toString() . "\n";
        
    $gusAssoc->submit() unless isReadOnly();

    
    print ASSOCLOG "after: " . $gusAssoc->toString() . "\n";
    print AILOG "after: " . $gusAssocInst->toString() . "\n";
    $self->undefPointerCache();    
    return $evidenceCount;
    #return $gusAssocInst;

}

# ......................................................................

sub __get_evidence_ids{
    my ($self, $assocData) = @_;
    #print STDERR "running get_evidence_ids\n";
    #prepare sql to get GUS id for evidence code for each external sequence
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
    #print STDERR "end get_evidence_ids\n";
    return \%evdIds;
}
	
#given an organism and its external primary sequence identifiers, get the GUS Id's
#for those sequences
sub __get_sequence_id {
    my ($self, $organism, $assocData) = @_;
    print STDERR "running LoadGoAssoc::get_sequence_id\n";
    # prepare SQL to get GUS id for external sequence.
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
                and $whereCol in ?" ;
    my $sth = $queryHandle->prepare($prepareSql);
    
    foreach my $key (keys %$assocData){
	my $entry = $assocData->{$key};
	my $extId = $entry->$assocMethod;
	my @cleanId = @{ $orgInfo->{ clean_id }->( $extId ) };
	my $cleanId = '(' . join( ', ', map { "'$_'" } @cleanId ) . ')'; #get sp id's if mgi
	$sth->execute($extId);
	while (my ($gusId) = $sth->fetchrow_array()){
	    %gusIds->{$key}= $gusId;
	    
	}
    }
    close (GETSEQID);
    # return value
    #print STDERR "end get_sequence_id\n";
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

#check to see if an ancestor should still be associated with an external sequence
#even though it has a descendant set to 'is not', because it has another descendant
#set to 'is'
sub __ancestorShouldBeIs{
    my ($self, $ancestorGusId, $goIds, $allGoAncestors, $graph) = @_; 

    foreach my $goId (keys %$goIds){
	if (!($goIds->{$goId}->{entry}->getIsNot())){
	    my $goAncestors = $self->__makeAncestorHash($allGoAncestors->{ $graph->{goToGus}->{$goId} });
	    my $number = scalar(keys %$goAncestors);
	    if ($goAncestors->{$ancestorGusId}){
		return 1;
	    }
	}
    }
    return 0;
}

# ......................................................................

#convert array of ancestors to a hash keyed on ancestor id.  
#only called by __ancestorShouldBeIs
sub __makeAncestorHash{
    my ($self, $ancestors) = @_;
    my $ancestorHash;
    foreach my $ancestor (@$ancestors){
	$ancestorHash->{$ancestor} = 1;
    }
    return $ancestorHash;
}

#create hash keyed on go terms; for each term entry is array of its ancestors
sub __load_go_ancestors{
    my ($self, $graph) = @_;
    my $ancestors;
    my $gusIds = $graph->{gusToGo};
    foreach my $gusId (keys %$gusIds){
	$ancestors->{$gusId} = $self->__get_ancestors($gusId, $graph);

    }
    return $ancestors;
}

#create hash containing info about each go term; its children, parents, and maps
#from its gusID to its GO ID and vice versa
sub __load_go_graph {
    my ($self) = @_;
    #print STDERR "Running LoadGoAssoc::load_go_graph";
    my $queryHandle = $self->getQueryHandle();
    # object to return
    my $graph;
    
    #temp output file for debugging:
#    open (GOGRAPH, ">>./goGraphLog") || die "go graph log could not be opened";
    my $goDbId = $self->getCla->{go_ext_db_rel_id};

    my $sql = "

     select h.child_term_id, h.parent_term_id, f.go_id, f.name
     from SRes.GOTerm f, SRes.GORelationship h
     where f.go_term_id = h.child_term_id
     and f.external_database_release_id = $goDbId

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

#get array of ancestors for one go term
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


sub __getTableIdForOrg{
    my ($self, $orgTable) = @_;

    $orgTable =~ s/\./::/; 

    my $tableIdGetter = GUS::Model::Core::TableInfo->new({});
    my $tableId = $tableIdGetter->getTableIdFromTableName($orgTable);
    return $tableId;
}

sub __make_evidence_code_inst{
    
    my ($self, $extEvd, $evidenceMap) = @_;
    open (EVDLOG, ">>logs/evdLog") || die "evdlog could not be opened";
    my $reviewStatus = $evidenceMap->{$extEvd}->{reviewStatus};
    my $realEvidGusCode = $evidenceMap->{$extEvd}->{evdGusId};
    
    my $evidCodeInst = GUS::Model::DoTS::GOAssocInstEvidCode->new ({
	go_evidence_code_id => $realEvidGusCode,
     	review_status_id => $reviewStatus,
    });
    print EVDLOG $evidCodeInst->toString();
    return $evidCodeInst;
}

#create hash mapped on source_id of association containing the association's go terms, evidence, etc.
sub __createAssocData{
    my ($self, $allEntries, $allGusIds, $assocMethod) = @_;
    my $assocData;
    foreach my $key (keys %$allEntries){
	my $entry = $allEntries->{$key};
	my $tempGoTerm = $entry->getGOId();
	
	my $tempEvd = $entry->getEvidence();
	my $newKey = $entry->$assocMethod;
	$assocData->{$newKey}->{goTerms}->{$tempGoTerm}->{evidence}->{$tempEvd} = 1;
	$assocData->{$newKey}->{extSeqGusId} = $allGusIds->{$key};

	#change to unless 
	#don't make an entry if it already exists with isNot flag set (happens rarely)
	if ($assocData->{$newKey}->{goTerms}->{$tempGoTerm}->{entry}){
	    if (($assocData->{$newKey}->{goTerms}->{$tempGoTerm}->{entry}->getIsNot()) &&
		(!($entry->getIsNot()))) {
		next;
		}
	}	
	$assocData->{$newKey}->{goTerms}->{$tempGoTerm}->{entry} = $entry;
    }
        
    return $assocData;
}

#go through entries and set descendants is nots to match ancestors is nots where necessary
#(protect against rare case where a descendant is set to one but ancestor is set to another)
sub __adjustIsNots{
    my ($self, $assocData, $allGoAncestors, $goGraph) = @_;

    foreach my $sourceId (keys %$assocData){
	my $goIds = $assocData->{$sourceId}->{goTerms};
	foreach my $childGoId (keys %$goIds){
	    my $goGusId = $goGraph->{goToGus}->{$childGoId};
	    my @ancestors = @ { $allGoAncestors->{$goGusId} };
	    foreach my $ancestorGusId (@ancestors) {  #two nested loops! But both average about 5 iterations
		#can't call get is not on ancestor go id
		my $ancestorGoId = $goIds->{$goGraph->{gusToGo}->{$ancestorGusId}};
		
		#if ancestor is also associated with this source id:
		if ($ancestorGoId){
		    my $tempAncestorGoId = $goGraph->{gusToGo}->{$ancestorGusId};
		  
		    my $ancestorIsNot = $ancestorGoId->{entry}->getIsNot();
		    my $childIsNot = $goIds->{$childGoId}->{entry}->getIsNot();
		 #   print STDERR "$sourceId: associated with both $tempAncestorGoId and $childGoId\n";
		    if ($ancestorIsNot != $childIsNot){
			print STDERR "$sourceId: ancestor $tempAncestorGoId is not $childGoId\n";
			$goIds->{$childGoId}->{entry}->setIsNot($ancestorIsNot);
		    }
		}
	    }
	}
    }
}

sub __checkDatabaseRelease{
    my ($self, $organism) = @_;
    my $orgVar = $organism . "_db_rls_id";
    print STDERR "checking database release for $organism\n";
    my $dbs = $self->getCla->{$orgVar};
    #my $dbNumber = scalar (@$dbs);
    if (!($dbs)){
	print STDERR "didn't find db's\n";
	$self->userError("Please supply an external database release id for sequences in file gene_association.$organism");
    }
    else{
	$self->{ orgInfo }->{$organism}->{db_id} = $dbs;
    }
    
    print STDERR "apparently found dbs:  $dbs\n";
}

sub __loadMgiMapIfMouse{
    my ($self, $organism) = @_;
    
    if ($organism eq 'mgi'){
	my $mgiDirectory = $self->getCla->{mgi_file_path};
	my $fh = new FileHandle '<'. '$mgiDirectory/MRK_SwissProt.rpt';
	if (!($fh)){
	    my $msg = "Could not open file MRK_SwissProt.rpt to load mgi associations\n";
	    $msg .= "Please check that the file is in $mgiDirectory";
	    $self->userError($msg);
	}

	while ( <$fh> ) {
	    chomp;
	    my @parts = split /\t/, $_;
	    my @id_sp = split /\s/, $parts[ 5 ];
	    $self->{ maps }->{ mgi }->{ $parts[ 0 ] } = \@id_sp;
	}
	$fh->close if $fh;
    }

}

sub __checkIfSeqsLoaded{
    my ($self, $orgInfo, $fileName) = @_;
    
    my $orgTable = $orgInfo->{id_tbl};
    my $dbList = '( '. join( ', ', @{$orgInfo->{ db_id } } ). ' )';


    my $queryHandle = $self->getQueryHandle();
    my $sql = "select count(*) from $orgTable 
               where external_database_release_id in $dbList";

    my $sth = $queryHandle->prepareAndExecute($sql);

    while (my $count = $sth->fetchrow_array()){
	if (($count > 1) && (!($self->getCla->{loadAgain}))){
	    my $errorM = "Note: external sequences with database release id(s) $dbList, read from file\n";
	    $errorM = $errorM . "$fileName, have already been associated with GO Terms.\n";
	    $errorM = $errorM . "To reload, set --loadAgain command line argument to true.  Plugin will skip\n";
	    $errorM = $errorM . "this file for now.\n";
	    print STDERR $errorM;
	    return 1;
	}
    }
    return 0;
}

sub loadOrgDbs{
    my ($self) = @_;
    print STDERR "loading org dbs\n";
    #maybe make this more dynamic later, but for now, HACK


    $self->{orgInfo}->{sgd}->{db_id} = ($self->getCla->{yeast_db_rls_id}) 
	if $self->getCla->{yeast_db_rls_id};



    $self->{orgInfo}->{fb}->{db_id} = ($self->getCla->{fb_db_rls_id}) 
	if $self->getCla->{fb_db_rls_id};



    $self->{orgInfo}->{wb}->{db_id} = ($self->getCla->{worm_db_rls_id}) 
	if $self->getCla->{worm_db_rls_id};

    $self->{orgInfo}->{goa_sptr}->{db_id} = ($self->getCla->{sp_db_rls_id}, $self->getCla->{tr_db_rls_id}) 
	if $self->getCla->{sp_db_rls_id};

    $self->{orgInfo}->{mgi}->{db_id} = ($self->getCla->{sp_db_rls_id}, $self->getCla->{tr_db_rls_id})
	if $self->getCla->{sp_db_rls_id};

    $self->{orgInfo}->{tair}->{db_id} = ($self->getCla->{tair_db_rls_id}) 
	if $self->getCla->{tair_db_rls_id};
}

sub loadOrgInfo{
    
    my ($self) = @_;

  #set private configuration data for this plugin
    my $flyDb = $self->getCla->{fb_db_rls_id};

    $self->{ orgInfo } = {
	sgd => { id_col   => 'secondary_identifier', 
		 id_tbl   => 'Dots.ExternalAASequence',
	#	 db_id    => [ $self->getCla->{yeast_db_rls_id} ],
		 clean_id => sub { [ $_[ 0 ] ] },
		 assoc_meth    => 'getDBObjectId',
	     },

	fb  => { id_col   => 'source_id',
		 id_tbl   => 'Dots.ExternalAASequence',
	#	 db_id    => [ $flyDb ], 
		 clean_id => sub { [ $_[ 0 ] ] },
		 assoc_meth    => 'getDBObjectId',
	     },

	wb  => { id_col   => 'source_id',
		 id_tbl   => 'Dots.ExternalAASequence',
		 db_id    => [  $self->getCla->{worm_db_rls_id} ], 
	#	 clean_id => sub { [ $_[ 0 ] ] },
		 assoc_meth    => 'getDBObjectSymbol',
	     },
	
	tair => { id_col   => 'source_id',
		  id_tbl   => 'Dots.ExternalAASequence',
	#	  db_id    => [  $self->getCla->{tair_db_rls_id} ],
		  clean_id => sub { [ $_[ 0 ] ] }, 
		  assoc_meth    => 'getDBObjectSymbol',
	      },

	mgi => { id_col   => 'source_id',
		 id_tbl   => 'Dots.ExternalAASequence',
	#	 db_id    => [  $self->getCla->{sp_db_rls_id},  $self->getCla->{tr_db_rls_id} ], 
		 clean_id => sub { $self->{ maps }->{ mgi }->{ $_[ 0 ] } },
		 assoc_meth    => 'getDBObjectId',
	     },

	goa_sptr => { id_col => 'source_id',
		      id_tbl => 'Dots.ExternalAASequence',
	#	      db_id => [$self->getCla->{sp_db_rls_id},  $self->getCla->{tr_db_rls_id}],
		      clean_id => sub { [ $_[ 0 ] ] },
		      assoc_meth => 'getDBObjectId',
		  },
    };

  #  $self->loadOrgDbs();
}


sub __getEntryDate{
    my ($self, $date) = @_;
    my $sqlDate;
    #format: 20030109 yearmonthday
    if ($date =~ /(\d\d\d\d)(\d\d)(\d\d)/){
	$sqlDate = $1 . "-" . $2 . "-" . $3;
    }
    return $sqlDate;
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

