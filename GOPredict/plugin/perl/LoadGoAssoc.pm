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

    #good go id: 5996
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
	
	 {o=> 'loadSeqsFromDb',
	  h=> 'Set this to retrieve all sequences that have already been loaded so they will not be duplicated.  Appends loaded sequences to file specified with --id_file',
	  t=> 'boolean',
      },

	 {o=> 'loadAgain',
	  h=> 'set this to load sequences even if some with the same external database release are already loaded',
	  t=> 'boolean',
      },

	 {o => 'id_file',
	  h => 'read and append successfully processed ID here.  If --loadSeqsFromDb is also set, it will append loaded sequences to whatever is already in this file.',
	  t => 'string',
	  r => 1,
      },
	 {o => 'increment',
	  h => 'number of lines in associations to parse in each iteration',
	  t => 'int',
      }, 
	 
	 {o => 'start_line',
	  h => 'Line of association file on which to start parsing',
	  t => 'int',
      }, 
	 {o => 'end_line', 
	  h => 'Line of association file on which to stop parsing',
	  t => 'int',
      }, 
	 {o => 'yeast_db_rls_id', #2794
	  h => 'External database release id for yeast sequences',
	  t => 'int',
      }, 
	 {o => 'fb_db_rls_id',  #2193
	  h => 'External database release id for fly sequences',
	  t => 'int',
      },
	 {o => 'tair_db_rls_id', #2693
	  h => 'External database release id for Arabidopsis sequences',
	  t => 'int',
      },
	 {o => 'worm_db_rls_id',  #6674
	  h => 'External database release id for worm sequences',
	  t => 'int',
      },
	 {o => 'sp_db_rls_id',  #2893
	  h => 'External database release id for worm sequences',
	  t => 'int',
      },
	 {o => 'tr_db_rls_id',  #3093
	  h => 'External database release id for worm sequences',
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
    
    $self->log("LoadGoAssoc: starting run method" );
    my $globalStart = $self->getCla->{start_line};
    my $globalEnd = $self->getCla->{end_line};
    my $path = $self->getCla->{file_path};
    my $parser;

    my $msg;
    my $fileName = $self->getCla->{flat_file};    
    my $increment = $self->getCla->{increment};
   
    $self->__validateIncrement();

    my $oneFileMsg = "CBIL:Bio:GeneAssocParser:Parser is loading $fileName in preparation for parsing";

    $self->__loadOrgInfo();

    my $currentCounters;

    if (!($increment)){
	
	$parser = CBIL::Bio::GeneAssocParser::Parser->new($path, $globalStart, $globalEnd);
	
	if ($fileName){
	    $self->log($oneFileMsg);
	    $parser->loadFile($fileName);
	}
	else {
	    my $logMsg = "CBIL:Bio:GeneAssocParser:Parser is loading all gene_association files in ";
	    $logMsg .= $path;
	    $self->log($logMsg);
	    $parser->loadAllFiles();
	}
	$parser->parseAllFiles();
	$currentCounters = $self->loadAssociations($parser);
    }
    else{  #parse only one file in increments
	if ($fileName){
	    $self->log($oneFileMsg);
	    for (my $j = $globalStart; $j <= $globalEnd; $j += $increment){ 
		$parser = CBIL::Bio::GeneAssocParser::Parser->new($path, $j, $j + $increment - 1);
		$parser->loadFile($fileName);
		$parser->parseAllFiles();
		my $returnedCounters = $self->loadAssociations($parser);
		$currentCounters = $self->__combineResults($currentCounters, $returnedCounters);
	    }
	}
	else {
	    my $incError = "--increment flag is set but no file is specified to parse. \n ";
	    $incError .= "Either specify a file or do not parse files incrementally (turn --increment off)";
	    $self->userError($incError);
 	}
    }

    $msg = $self->__createReturnMsg($currentCounters);
    # return value
    return $msg;
}

# ---------------------------------------------------------------------- #
# ---------------------------------------------------------------------- #



sub loadAssociations {
    my ($self, $parser) = @_;

    $self->log("Association file(s) parsed; preparing to insert into database");

    my $idFile;
    
  
    
    my $claIdFile = $self->getCla->{id_file}; 
    if ($claIdFile){
	$idFile = FileHandle->new( '>>'. $self->getCla->{ id_file } ); 
    }
    my $goGraph = $self->__loadGoGraph( );
    my $allGoAncestors = $self->__loadGoAncestors($goGraph);
    
    # variables for counting progress
    my $termCount      = 0;
    my $ancestorCount  = 0;
    my $skipCount      = 0;
    my $oldCount       = 0;
    my $unknownCount   = 0;
    my $evidenceCount = 0;
   
    #get all parsed files
    my $stores = $parser->getFileStores();

    foreach my $file (keys %$stores){

	my $fileStore = $stores->{$file};
	
	my $allEntries = $fileStore->getParsedEntries();
	
	my ($organism) = $file =~ /gene_association\.(\w+)$/;
	my $orgInfo = $self->{orgInfo}->{$organism};
	
	$self->__checkDatabaseRelease($organism);

	next if ($self->__checkIfSeqsLoaded($orgInfo, $file));

	# get the list of sequences we've already annotated.
	my $old_seqs = $self->__loadProcessedSequences($organism);
		
	$self->__loadMgiMapIfMouse($organism);

#	open (BIGLOG, ">>logs/pluginLog$organism") || die "pluginLog could not be opened";

	my $assocMethod = $orgInfo->{assoc_meth};
	
	#retrieve Ids for external info 
	my $allGusIds = $self->__getSequenceIds($organism, $allEntries);
	my $allEvdIds = $self->__getEvidenceIds($allEntries);
	my $evidenceMap = $self->__getEvidenceReviewStatusMap();
	
	#get table id for table name that external sequences are in
	my $tableId = $self->__getTableIdForOrg($orgInfo->{id_tbl});
		
	#convert file store into hash to be used by algorithm
	my $assocData = $self->__createAssocData($allEntries, $allGusIds, $assocMethod, $organism);
	
#	$self->__adjustIsNots($assocData, $allGoAncestors, $goGraph, $organism);

	#for each external sequence
	foreach my $extSeq (keys %$assocData){

	   # print BIGLOG "loading association for $extSeq\n";
	    $self->logVerbose("loading association for $extSeq");

	    my $goIds = $assocData->{$extSeq}->{goTerms};
	    my $extSeqGusId = $assocData->{$extSeq}->{extSeqGusId};
	    
	    my $ancestorsMade;
   
	    # reasons not to process this line
	    if ( ! $extSeqGusId ){ 
		$self->logVerbose("skipped $extSeq because could not find corresponding GUS Id for this sequence");
#		print BIGLOG "skipped $extSeq because could not find corresponding GUS Id for this sequence\n";
		$skipCount++; next
		}
	    elsif ( $old_seqs->{ $extSeq  } ) {
		$self->logVerbose("skipped $extSeq because there is already an association made for this version");
		
		$oldCount++; next
		}
	    
	    #for each go term associated with this external sequence
	    foreach my $goId (keys %$goIds){
		
		$self->logVerbose ("making defining association between $extSeq and $goId");
#		print BIGLOG "making defining association between $extSeq and $goId\n";
		
		#variables for this potential association
		my $evdIds = $goIds->{$goId}->{evidence};
		my $entry = $goIds->{$goId}->{entry};	

		my $goTermGusId = $goGraph->{ goToGus }->{ $goId };	
		my @goAncestors = keys %{ $allGoAncestors->{$goTermGusId} };		
	
	
		
		#reasons to skip this defining association:
		unless ( $goTermGusId ) {
		    $unknownCount++;
		    $self->logVerbose("could not find gus ID for go term $goId");
#		    print BIGLOG "could not find goTermGusId for goId $goId $unknownCount \n";
		    next;
		}
				
		if ($entry->getEvidence() eq 'NULL') {
		    #so far only have seen in wb associations, no counter incrementing
		    $self->logVerbose("skipped $extSeq association with go id $goId because evidence is NULL");
		    next;
		}
		
		if ($self->__hasDefiningDescendant($goIds, $allGoAncestors, $goId, $goGraph)){
		    my $desMsg = "\t\t skipping this defining assignment as another descendant will be making it\n";
#		    print BIGLOG $desMsg . "\n";
		    $self->logVeryVerbose($desMsg);
		    next;
		}
		
		#make association for the term itself

		$evidenceCount+= 
		    $self->__makeAssociation( $entry, $tableId, $extSeqGusId, 
					      $goTermGusId, $evdIds, $evidenceMap, 
					      $organism, 1);
		$termCount++;
		
		if ($entry->getIsNot()){
		    $ancestorsMade->{$extSeqGusId}->{$goId} = -1; }
		else {$ancestorsMade->{$extSeqGusId}->{$goId} = 1;}
				
		#make association for terms on path to root.
		
		foreach my $goAncestor ( @goAncestors ) {
		    my $ancestorGoId = $goGraph->{gusToGo}->{$goAncestor};
		    
		    my $ancMsg = "\t\tmaking ancestor association for $goAncestor ($ancestorGoId) and $extSeq";
#		    print BIGLOG $ancMsg . "\n";
		    $self->logVeryVerbose($ancMsg);
		 
		    #reasons to skip this ancestor association:

		    #don't make if already made from common descendant
		    if ($ancestorsMade->{$extSeqGusId}->{$ancestorGoId}){
			
			my $skipAncMsg = "\t\t skipping this ancestor assignment; it was made from a different descendant";
			$skipAncMsg .= $ancestorsMade->{$extSeqGusId}->{$ancestorGoId};
#			print BIGLOG $skipAncMsg . "\n";
			$self->logVeryVerbose($skipAncMsg);
			next;
		    }
		    
		    #don't make if ancestor should be set to 'is' even though the descendant goId 'is not'
		    elsif ($entry->getIsNot()){
			
			if ($self->__ancestorShouldBeIs($goAncestor, $goIds, $allGoAncestors, $goGraph)){
			    my $isMsg = "\t\t skipping this ancestor assignment because descendant IS NOT";
			    $isMsg .= "but ancestor should be IS\n";
#			    print BIGLOG $isMsg;
			    $self->logVeryVerbose($isMsg);
			    next;
			}
		    }
		    
		    #make if ancestor passes the previous conditions
		    $self->__makeAssociation( $entry, $tableId, $extSeqGusId,
					      $goAncestor, $evdIds, $evidenceMap,
					      $organism, 0
					      );
		    $ancestorCount++;
		    
		    if ($entry->getIsNot()){
			$ancestorsMade->{$extSeqGusId}->{$ancestorGoId} = -1; }
		    else {$ancestorsMade->{$extSeqGusId}->{$ancestorGoId} = 1;}	       
		    
		} # end ancestor association
	    }  #end this go term    
	    
	    print $idFile $extSeq . "\n";
	} #end this external sequence
#	close BIGLOG;
    } #end this association file
    
    
    # return value
    my $returnCounter;
    $returnCounter->{term_count} = $termCount;
    $returnCounter->{ancestor_count} = $ancestorCount;
    $returnCounter->{skip_count} = $skipCount;
    $returnCounter->{old_count} = $oldCount;
    $returnCounter->{unknown_count} = $unknownCount;
    $returnCounter->{evidence_count} = $evidenceCount;

    return $returnCounter;
}


# ......................................................................

#make GUS Objects for each association and submit to db
sub __makeAssociation {
    
    my ($self, $entry, $tableId, $externalSeqGusId, $goTermGusId,  $evdIds, $evidenceMap, $organism, $defining) = @_; 
  #  open (ASSOCLOG, ">>logs/assocLog$organism") || die "assocLog could not be opened";
  #  open (AILOG, ">>logs/assocInstLog$organism") || die "assocInstLog could not be opened";
   
    my $evidenceCount = 0;
    my $orgInfo = $self->{ orgInfo }->{ $organism };
    my $extEvd = $entry->getEvidence();
    if (!($extEvd)){
	$extEvd = $entry->getWith();  #account for errors in wb association file and possibly others
    }

    #$entry->showMyInfo();
 #   print ASSOCLOG "getting evidence for $externalSeqGusId on $goTermGusId, outside code is $extEvd\n";
    my $reviewStatus = $evidenceMap->{$extEvd}->{reviewStatus};
    my $isNot = 0;
    my $dbs = $orgInfo->{db_id};
    if ($entry->getIsNot()){
	$isNot = 1;
    }

    my $assocDate = $self->__getEntryDate($entry->getEntryDate());

    #make association
    my $gusAssoc = GUS::Model::DoTS::GOAssociation->new( {
 	table_id => $tableId,    #hack for testing
	row_id => $externalSeqGusId,
 	go_term_id => $goTermGusId,
 	is_not => $isNot, 
 	review_status_id => $reviewStatus, 
 	defining=> $defining,
	go_association_date => $assocDate,
    });
    
    #make instance of this association; 1:1 Association:AssociationInstance ratio
    my $gusAssocInst = GUS::Model::DoTS::GOAssociationInstance->new( {
 	external_database_release_id=> $self->getCla->{go_ext_db_rel_id},
 	is_not => $isNot,
 	review_status_id => $reviewStatus,
 	defining => $defining,
 	go_assoc_inst_loe_id => 1, #hardcoded for now
    });

    #make evidence code link for each 
    if ($defining){
	foreach my $evdId (keys %$evdIds){
	    my $evdCodeInst = $self->__makeEvidenceCodeInst($evdId, $evidenceMap);
	    if ($evdCodeInst){
		$gusAssocInst->setChild($evdCodeInst);
		$evidenceCount++;
	    }
	}
    }
   $gusAssoc->setChild($gusAssocInst); #big test
    
  #  print ASSOCLOG "before: " . $gusAssoc->toString() . "\n";
  #  print AILOG "before: " . $gusAssocInst->toString() . "\n";
        
    $gusAssoc->submit() unless isReadOnly();

    
 #   print ASSOCLOG "after: " . $gusAssoc->toString() . "\n";
 #   print AILOG "after: " . $gusAssocInst->toString() . "\n";
    $self->undefPointerCache();    
    return $evidenceCount;

}

# ......................................................................
#given external sequences and the evidence codes used to associate them with GO Terms,
#get the GUS Id for each evidence code and put it in the supplied hash of sequences 
sub __getEvidenceIds{
    my ($self, $assocData) = @_;
    
    $self->log("getting gus evidence code ids for GO Evidence codes");

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
    
    $self->log("finished getting go evidence codes");
    return \%evdIds;
}

#given a go term that has been associated with a sequence, check if the go term has any
#descendants that are also associated with this sequence.  We only want to have the lowest go term
#in the graph get the defining tag; the ancestor association will be made later.

sub __hasDefiningDescendant{
    my ($self, $goIds, $allGoAncestors, $goIdToTest, $graph) = @_;

    my $entryToTest = $goIds->{$goIdToTest}->{entry}; #entry of term we are checking
       
    foreach my $goId (keys %$goIds){  #for all other go terms associated with the sequence  
	my $descendantsGoAncestors = $allGoAncestors->{ $graph->{goToGus}->{$goId} };
	if ($descendantsGoAncestors->{ $graph->{goToGus}->{$goIdToTest} }) { #found a descendant that is explicitly set
	    
	    my $descendantEntry = $goIds->{$goId}->{entry};
	    if ($descendantEntry->getIsNot() == $entryToTest->getIsNot()){  #same isNots()
		return 1;
	    }
	}
    }
    return 0;
}

#given an organism and its external primary sequence identifiers, get the GUS Id's
#for those sequences
sub __getSequenceIds {
    my ($self, $organism, $allEntries) = @_;

    $self->log("getting gus Ids for external $organism sequences");

    my $orgInfo = $self->{ orgInfo }->{ $organism };

    my %gusIds = {};

#    open (GETSEQID, ">>logs/getSeqLog$organism") || die "getSeqLog could not be opened";

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
    
    $self->logVerbose("prepared query to get sequences: $prepareSql");
 #   print GETSEQID "prepared query to get sequences: $prepareSql";
    my $sth = $queryHandle->prepare($prepareSql);
    
    foreach my $entryKey (keys %$allEntries){
	
	my $entry = $allEntries->{$entryKey};
	my $entryId = $entry->$assocMethod;
	if ($entryId){  #account for missing id's in wormpep file!!
	    my @cleanIds = @{ $orgInfo->{ clean_id }->( $entryId ) };
	
	    
	    #	$cleanId = '(' . join( ', ', map { "$_" } @cleanId ) . ')';  #get sp id's if mgi
	    #$cleanId = join( ', ', map { "$_" } @cleanId );  #get sp id's if mgi
	    
	#    print GETSEQID "$entryKey: executing sequence $entryId, mapping to " . join (',', @cleanIds) . "\n";
	    
	    foreach my $extId (@cleanIds){
		$sth->execute($extId);
		while (my ($gusId) = $sth->fetchrow_array()){
		#    print GETSEQID "\t$extId in gus is $gusId\n";
		    %gusIds->{$entryKey}->{$extId}= $gusId;
		}
	    }
	}
    }
#    close (GETSEQID);

    $self->log("done getting gus ids for sequences for this organism");
    return \%gusIds;
}


# ......................................................................

#load sequences that have already had associations made for them in this version
sub __loadProcessedSequences {
    my ($self, $organism) = @_;
    
    my $orgIdCol = $self->{orgInfo}->{$organism}->{id_col};
    if ($orgIdCol =~ /upper\((.*)\)/){
	$orgIdCol = $1;
    }
    my $old_seqs = {};
    if ($self->getCla->{loadSeqsFromDb}){
	my $dbList = '( '. join( ', ', @{ $self->{orgInfo}->{$organism}->{ db_id } } ). ' )';
	my $goDb = $self->getCla->{go_ext_db_rel_id};
	my $loadedSeqs;
	my $queryHandle = $self->getQueryHandle();
	my $sql = "select eas." . "$orgIdCol ";
	$sql .= "from DoTS.GOAssociation ga, DoTS.ExternalAASequence eas, DoTS.GOAssociationInstance gai ";
	$sql .= "where eas.aa_sequence_id = ga.row_id and ga.go_association_id = gai.go_association_id ";
	$sql .= "and eas.external_database_release_id in $dbList and gai.external_database_release_id = $goDb ";
	$sql .= "and ga.defining = 1";
	
	my $sth = $queryHandle->prepareAndExecute($sql);
	my $counter = 0;
	my $writeFh = FileHandle->new( '>>'. $self->getCla ->{ id_file } );
	while (my $oldId = $sth->fetchrow_array()){
	    $loadedSeqs->{$oldId} = 1;
	}
	foreach my $loadedSeq (keys %$loadedSeqs){
	    print $writeFh $loadedSeq . "\n";
	}
	$writeFh->close();
    }	

    my $readFh = FileHandle->new( '<'. $self->getCla ->{ id_file } );
    if ( $readFh ) {
	while ( <$readFh>){
	    chomp;
	    $old_seqs->{$_} = 1;   #reads seqs just written from db and ones already in file
	}
    }
    $readFh->close();
    
    # return the set
    return $old_seqs;
}

# ......................................................................

#check to see if an ancestor should still be associated with an external sequence
#even though it has a descendant set to 'is not', because it has another descendant
#set to 'is', or if ancestor is explicitly set to is in gene_association file
sub __ancestorShouldBeIs{
    my ($self, $ancestorGusId, $goIds, $allGoAncestors, $graph) = @_; 

    
    #check if ancestor explicitly set to 'is' in association file
    #$my $ancestorEntry = $goIds->{ $graph->{gusToGo}->{$ancestorGusId} }->{entry};
    #if ($ancestorEntry) {
        #if !($ancestorEntry->getIsNot()){ 
    #      return 1;   }
    #    }
        
    
    #check if another descendant of this ancestor explicitly set to is in association file
    foreach my $goId (keys %$goIds){
	if (!($goIds->{$goId}->{entry}->getIsNot())){
	    my $goAncestors = $allGoAncestors->{ $graph->{goToGus}->{$goId} };
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

#create hash keyed on go terms; for each key (the go term), value is hash w/keys being 
#the ancestors of the go term
sub __loadGoAncestors{
    my ($self, $graph) = @_;
    my $ancestorsArray;
    my $ancestors;
    #keys of $gusIds will be GUS ids, not GO ids.
    my $gusIds = $graph->{gusToGo};

    my $rootGusIds = $self->__getOntologyRoots();

    foreach my $gusId (keys %$gusIds){
	$ancestorsArray->{$gusId} = $self->__getAncestors($gusId, $graph, $rootGusIds);
    }
    foreach my $gusIdWithAnc(keys %$ancestorsArray){
	$ancestors->{$gusIdWithAnc}= $self->__makeAncestorHash($ancestorsArray->{$gusIdWithAnc});
    }
    return $ancestors;
}

#get gus ID for root of GO ontology so it doesn't get set as an ancestor
sub __getOntologyRoots{

    my ($self) = @_;

    my $roots;

    my $queryHandle = $self->getQueryHandle();
    my $sql = "select go_term_id from sres.goterm where name = 'Gene_Ontology'";

    my $sth = $queryHandle->prepareAndExecute($sql);
    
    #need to get roots for all external db ids because no guarantee ontology root
    #is loaded with the external db release of a given branch

    while (my ($root) = $sth->fetchrow_array()){
	$roots->{$root} = 1;
    }

    return $roots;
}
   


#create hash containing info about each go term; its children, parents, and maps
#from its gusID to its GO ID and vice versa
sub __loadGoGraph {
    my ($self) = @_;

    $self->log("creating graph of go hierarchy");
    my $queryHandle = $self->getQueryHandle();

    # object to return
    my $graph;
    
    my $goDbId = $self->getCla->{go_ext_db_rel_id};

    my $sql = "

     select h.child_term_id, h.parent_term_id, f.go_id, f.name
     from SRes.GOTerm f, SRes.GORelationship h
     where f.go_term_id = h.child_term_id
     and f.external_database_release_id = $goDbId

  "; 
    
    # execute the SQL and get the graph
    my $sth = $queryHandle->prepareAndExecute($sql);
    while ( my ( $childId, $parentId, $childGoId, $name ) = $sth->fetchrow_array()) {
	
	# parent link for child
	$graph->{ childToParent }->{ $childId }->{ $parentId } = 1;
		 
        # child link for parent
	$graph->{ parentToChild }->{ $parentId }->{ $childId } = 1;
	
	# map from (GUS) child to GO id
	$graph->{ gusToGo }->{ $childId } = $childGoId;
	#if we don't need the above then don't store it

	# map from GO id to (GUS) child
	$graph->{ goToGus }->{ $childGoId } = $childId;
	
	# name of function
	$graph->{ name }->{ $childId } = $name;
    }
    
    # return value
    return $graph
    }

# ......................................................................

#get array of ancestors, except for ontology root, for one go term 
sub __getAncestors {
    my ($self, $goTermGusId, $goGraph, $roots) = @_;

    # set (hash) of nodes on path to root.
    my $path;
    
    # breadth first queue
    my @queue = ( $goTermGusId );
    
    while ( my $nextTerm = shift @queue ) {
	foreach my $parentOfNextTerm ( keys %{ $goGraph->{ childToParent }->{ $nextTerm } }) {
	    next if $path->{ $parentOfNextTerm };
	    next if $roots->{$parentOfNextTerm};
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

sub __makeEvidenceCodeInst{
    
    my ($self, $extEvd, $evidenceMap) = @_;
   # open(EVDLOG, ">>logs/evdLog") || die "evdlog could not be opened";
    my $reviewStatus = $evidenceMap->{$extEvd}->{reviewStatus};
    my $realEvidGusCode = $evidenceMap->{$extEvd}->{evdGusId};
    if (!($realEvidGusCode)){  #skip if evidence set to null
	return undef;
    }
    my $evidCodeInst = GUS::Model::DoTS::GOAssocInstEvidCode->new ({
	go_evidence_code_id => $realEvidGusCode,
     	review_status_id => $reviewStatus,
    });
   # print EVDLOG $evidCodeInst->toString();
    return $evidCodeInst;
}

#create hash mapped on source_id of association containing the association's go terms, evidence, etc.
sub __createAssocData{
    my ($self, $allEntries, $allGusIds, $assocMethod, $organism) = @_;
    my $assocData;

    foreach my $entryKey (keys %$allEntries){
	my $entry = $allEntries->{$entryKey};
	my $tempGoTerm = $entry->getGOId();
	
	my $tempEvd = $entry->getEvidence();
	my $entryId = $entry->$assocMethod; 
	if ($entryId){ #account for missing identifiers in wormpep file!
	    my @cleanIds = @{ $self->{orgInfo}->{$organism}->{clean_id}->($entryId) };

	    foreach my $extId (@cleanIds){
		$assocData->{$extId}->{goTerms}->{$tempGoTerm}->{evidence}->{$tempEvd} = 1;
		$assocData->{$extId}->{extSeqGusId} = $allGusIds->{$entryKey}->{$extId};
		
		#don't make an entry if it already exists with isNot flag set (happens rarely)
		if ($assocData->{$extId}->{goTerms}->{$tempGoTerm}->{entry}){
		    if (($assocData->{$extId}->{goTerms}->{$tempGoTerm}->{entry}->getIsNot()) &&
			(!($entry->getIsNot()))) {
			next;
		    }
		}	
		$assocData->{$extId}->{goTerms}->{$tempGoTerm}->{entry} = $entry;
	    }
	}
    }
    
    return $assocData;
}

#dtb: decide if I want to keep this
#go through entries and set descendants' 'is not' to match their ancestors' 'is not' where necessary
#(protect against rare case where a descendant is set to 'is' one but ancestor is set to 'is not'r)
sub __adjustIsNots{
    my ($self, $assocData, $allGoAncestors, $goGraph, $organism) = @_;
 #   open (ISLOG, ">>logs/isNotLog$organism") || die "pluginLog could not be opened";
    
    #for each external sequence
    foreach my $sourceId (keys %$assocData){
#	print ISLOG "adjusting is not for terms associated with $sourceId\n";
	my $goIds = $assocData->{$sourceId}->{goTerms};
	
	#for each go term associated with external sequence
	foreach my $childGoId (keys %$goIds){
	    
	    my $goGusId = $goGraph->{goToGus}->{$childGoId};
	    my $ancestorHash = $allGoAncestors->{$goGusId};
	    my @ancestors = keys %$ancestorHash;
	    
	    #for each ancestor of the go term
	    foreach my $ancestorGusId (@ancestors) {  
		
		#see if there is an explicit association in file with sequence
		my $ancestorGoId = $goIds->{$goGraph->{gusToGo}->{$ancestorGusId}};
		
		if ($ancestorGoId){  #there is
#		    print ISLOG "found ancestor $ancestorGoId that may be conflict, checking\n";
		    my $ancestorIsNot = $ancestorGoId->{entry}->getIsNot();
		    my $childIsNot = $goIds->{$childGoId}->{entry}->getIsNot();
#		    print ISLOG "ancestor: $ancestorIsNot child: $childIsNot\n";
		    if ($ancestorIsNot == 1 && !($childIsNot)){ #is nots have conflict
			print ISLOG "conflict: $ancestorGoId isnot and $childGoId is\n";
			foreach my $testGoId (keys %$goIds){  #see if other ancestors can resolve
			    if (!($goIds->{$testGoId}->{entry}->getIsNot())){  #another ancestor is
#				print ISLOG "but another ancestor $testGoId is\n";
				my $testGoGusId = $goGraph->{goToGus}->{$testGoId};
				my $testGoAncestorHash = $allGoAncestors->{$testGoGusId};
				my $ancestorsAncestorHash = $allGoAncestors->{$ancestorGusId};
				if (!($testGoAncestorHash->{$ancestorGusId}) &&  
				    !($ancestorsAncestorHash->{$testGoGusId})){  #if two ancestors are related, it's fine
#				    print ISLOG "and it is not an ancestor or descendant of $ancestorGoId\n";
				}
			    }
			}
			#DTB: STILL MAKE SURE THIS IS BEING SET IN THE CORRECT SCOPE			
			#not done testing this yet
			$goIds->{$childGoId}->{entry}->setIsNot($ancestorIsNot);
		    }
		}
	    }
	}
    }
}


#make sure database release has been passed in for this file
#arbitrary number of files may be parsed (1 to 7) so cannot make required in CLA
sub __checkDatabaseRelease{
    my ($self, $organism) = @_;

    $self->log("verifying external database release for organism $organism");

    my $dbs = $self->{orgInfo}->{$organism}->{db_id};
     
    if (!($dbs->[0])){
	$self->userError("Please supply an external database release id for sequences in file gene_association.$organism");
    }
    
}

#load mapping in MRK_SwissProt.rpt file from MGI ID's to SwissProt Ids that have been loaded.
sub __loadMgiMapIfMouse{
    my ($self, $organism) = @_;
    
    if ($organism eq 'mgi'){
	my $mgiDirectory = $self->getCla->{mgi_file_path};
	if (!($mgiDirectory)){
	    my $msg = "Please specifiy the full path of the directory that file MRK_SwissProt.rpt\n";
	    $msg .= " is located in with the command line argument '--mgi_file_path'";
	    $self->userError($msg);
	}
	my $fhName = '<' . $mgiDirectory . '/MRK_SwissProt.rpt';
	my $fh = FileHandle->new($fhName);
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

	$self->log("Loaded $mgiDirectory/MRK_SwissProt.rpt for mapping from MGI Id's to SwissProt Id's");
    }

}

sub __checkIfSeqsLoaded{
    my ($self, $orgInfo, $fileName) = @_;
  
    my $orgTable = $orgInfo->{id_tbl};

    my $dbList = '( '. join( ', ', @{ $orgInfo->{ db_id } }  ). ' )';

    $self->log("checking if sequences are already loaded in database for external database release(s) $dbList");

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
	    $self->userError($errorM);
	    return 1;
	}
    }
    return 0;
}

sub __loadOrgDbs{
    my ($self) = @_;
    print STDERR "loading org dbs\n";
    #maybe make this more dynamic later, but for now, HACK
   
    
    if ($self->getCla->{yeast_db_rls_id}) {
	my @orgArray = ($self->getCla->{yeast_db_rls_id});
	$self->{ orgInfo }->{sgd}->{db_id} = \@orgArray;	
    }
    if ($self->getCla->{fb_db_rls_id}) {
	my @orgArray = ($self->getCla->{fb_db_rls_id});
	$self->{ orgInfo }->{fb}->{db_id} = \@orgArray;	
    }
    if ($self->getCla->{worm_db_rls_id}) {
	my @orgArray = ($self->getCla->{worm_db_rls_id});
	$self->{ orgInfo }->{wb}->{db_id} = \@orgArray;	
    }
    if ($self->getCla->{tair_db_rls_id}) {
	my @orgArray = ($self->getCla->{tair_db_rls_id});
	$self->{ orgInfo }->{tair}->{db_id} = \@orgArray;	
    }
    if ($self->getCla->{sp_db_rls_id}) {
	my @orgArray = ($self->getCla->{sp_db_rls_id}, $self->getCla->{tr_db_rls_id} );
	$self->{ orgInfo }->{goa_sptr}->{db_id} = \@orgArray;	
	$self->{ orgInfo }->{mgi}->{db_id} = \@orgArray;	
    }
    #push tr

}

sub __loadOrgInfo{
    
    my ($self) = @_;
    
    #set private configuration data for this plugin
    my $flyDb = $self->getCla->{fb_db_rls_id};

    $self->{ orgInfo } = {
	sgd => { id_col   => 'secondary_identifier', 
		 id_tbl   => 'Dots.ExternalAASequence',
		 clean_id => sub { [ $_[ 0 ] ] },
		 assoc_meth    => 'getDBObjectId',
	     },

	fb  => { id_col   => 'secondary_identifier',  #FBgn style CHANGE BACK
		 id_tbl   => 'Dots.ExternalAASequence',
		 clean_id => sub { [ $_[ 0 ] ] },
		 assoc_meth    => 'getDBObjectId',
	     },

	wb  => { id_col   => 'source_id',
		 id_tbl   => 'Dots.ExternalAASequence',
 		 clean_id => sub { [ $_[ 0 ] ] },
		 db_id    => [  $self->getCla->{worm_db_rls_id} ], 
		 assoc_meth    => 'getDBObjectId',
	     },
	
	tair => { id_col   => 'upper(source_id)',
		  id_tbl   => 'Dots.ExternalAASequence',
		  clean_id => sub { [ $_[ 0 ] ] }, 
		  assoc_meth    => 'getDBObjectSymbol',
	      },

	mgi => { id_col   => 'source_id',
		 id_tbl   => 'Dots.ExternalAASequence',
		 clean_id => sub { $self->{ maps }->{ mgi }->{ $_[ 0 ] } },
		 assoc_meth    => 'getDBObjectId',
	     },

	goa_sptr => { id_col => 'source_id',
		      id_tbl => 'Dots.ExternalAASequence',
		      clean_id => sub { [ $_[ 0 ] ] },
		      assoc_meth => 'getDBObjectId',
		  },
    };

    $self->__loadOrgDbs();
}

sub __validateIncrement{
    
    my ($self) = @_;
    my $start = $self->getCla->{start_line};
    my $end = $self->getCla->{end_line};
    my $increment = $self->getCla->{increment};

    if ($increment){
	if (!($start) || !($end)){
	    my $msg = "--increment flag set but no start or end specified. \n";
	    $msg .= "Please specify --start_line and --end_line if parsing file incrementally,\n";
	    $msg .= "to give plugin indication of how many increments to iterate over";
	    
	    $self->userError($msg);
	}
    }

}

sub __combineResults{
    my ($self, $currentCounter, $counterToJoin) = @_;
    my $newCounter;
    $newCounter->{term_count} = $currentCounter->{term_count} + $counterToJoin->{term_count};
    $newCounter->{ancestor_count} = $currentCounter->{ancestor_count} + $counterToJoin->{ancestor_count};
    $newCounter->{skip_count} = $currentCounter->{skip_count} + $counterToJoin->{skip_count};
    $newCounter->{old_count} = $currentCounter->{old_count} + $counterToJoin->{old_count};
    $newCounter->{unknown_count} = $currentCounter->{unknown_count} + $counterToJoin->{unknown_count};
    $newCounter->{evidence_count} = $currentCounter->{evidence_count} + $counterToJoin->{evidence_count};

    return $newCounter;
}

sub __createReturnMsg{
    my ($self, $counters) = @_;
    my $msg;
    my $termCount = $counters->{term_count};
    my $ancestorCount = $counters->{ancestor_count};
    my $skipCount = $counters->{skip_count};
    my $oldCount = $counters->{old_count};
    my $unknownCount = $counters->{unknown_count};
    my $evidenceCount =  $counters->{evidence_count};
    my $returnMsg = "loaded: ". join( ', ',
				      "terms=$termCount",
				      "ancestors=$ancestorCount",
				      "old=$oldCount",
				      "unknownGOTerm=$unknownCount",
				      "unknownExternalSeq=$skipCount",
				      "on $evidenceCount evidence entries"
				      );
}


#change entry date from what is in association file to something to go in Dots.GoAssociation table
sub __getEntryDate{
    my ($self, $date) = @_;
    my $sqlDate;
    #format: 20030109 yearmonthday
    if ($date =~ /(\d\d\d\d)(\d\d)(\d\d)/){
	$sqlDate = $1 . "-" . $2 . "-" . $3;
    }
    return $sqlDate;
}

#map from the name of an evidence code to its review status
sub __getEvidenceReviewStatusMap {
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

