package GUS::GOPredict::Plugin::LoadGoAssoc;
@ISA = qw( GUS::PluginMgr::Plugin);

use CBIL::Bio::GeneAssocParser::Parser;
use GUS::PluginMgr::Plugin;
use Carp;

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
    
    my ($class) = @_;
    # create

    my $self = bless {}, $class;
    
    
    # initialize--for now do not override initialize in plugin.pm just set methods
    my $purposeBrief = "Loads associations of external sequences to GO terms into GUS";
    
    my $purpose = "This plugin uses CBIL's Gene Association parser to parse a file representing amino acid sequences of an organism annotated with a Gene Ontology term and support for that annotation.  The file is provided by organizations participating in the Gene Ontology Consortium.  The data is then loaded into GUS, using the policies set out by CBIL to track GO Associations through the GO Hierarchy.\n\n"; 
    
    my $tablesAffected = 
	[['DoTS.GOAssociation', 'Writes the pertinent information of sequence/GO Term mapping here'],
	 ['DoTS.GOAssociationInstance', 'Writes information supporting the Association here'],
	 ['DoTS.GOAssocInstEvidCode', 'Writes an entry here linking the Instance with a GO Evidence Code supporting the instance, as provided in the input file']];
    
    my $tablesDependedOn = 
	[['SRes.GOTerm', 'Retrieves information about a GOTerm from this table'],
	 ['SRes.GORelationship', 'Retrieves information about GO Hierarchy relationships among GO Terms from this table'],
	 ['SRes.ExternalDatabaseRelease', 'Information about the latest release of the Gene Ontology and the organism to be loaded must be provided here'],
	 ['SRes.GOEvidenceCode', 'The different GO Evidence Codes as defined by the GO Consortium must be provided in this table'],
	 ['DoTS.ExternalAASequence', 'Sequences with which to make Associations must be provided here'],
	 ['Core.TableInfo', 'An entry for DoTS.ExternalAASequence must be provided here']];

    my $howToRestart = "There are a few ways.  The first two involve setting the --restart_line option to specify the line in the input file on which to restart, and the plugin will begin at that line.  To determine this line using a previous run, you could do one of two things.  The first is to have run the plugin in --verbose mode previously; this logs the line of each entry in the file as it is processed.  The last line in the log is the last line processed.  The second is to go into the database and find the last entry (using the 'modification_date' column) that was inserted into the database.  Find the GOAssociation with the latest modification date, and then find the GOAssocInstEvidCode with the latest modification date that is a child of the GOAssociationInstance pointing to the GOAssociation.  The sequence Id/GO Id/Evidence Code triplet that you find this way is in the file as well; the first occurrence of this code in the file is where the plugin left off.  The final way is to not provide the restart_line; the plugin will go through the file and skip everything that it already did, but it will still take the same amount of time.";

    my $notes = "The review_status_id attribute for the Association is set automatically according to the GO Evidence Code provided; in this context, the value for the review status indicates whether the Association has been annotated by whomever created the file in the first place.  For a discussion of some of the finer points of the algorithms used in this plugin, see the file in {PROJECT_HOME}/GUS/GOPredict/doc.";

    my $failureCases = "None that we've found so far.";

    my $documentation = { purpose=>$purpose,
			  purposeBrief=>$purposeBrief,
			  tablesAffected=>$tablesAffected,
			  tablesDependedOn=>$tablesDependedOn,
			  howToRestart=>$howToRestart,
			  failureCases=>$failureCases,
			  notes=>$notes
			  };
 
    my $argsDeclaration =
	[
	 integerArg({name => 'go_ext_db_rel_id',
		     descr => 'external database release id in GUS for terms in the molecular function branch of GO which will be associated with external sequences',
		     reqd => 1,
		     constraintFunc => undef,
		     isList => 0,
		 }),
	 
	 fileArg ({name => 'flat_file',
		   descr => 'read GO Association data from this flat file.', 
		   reqd => 1,
		   constraintFunc => undef,
		   mustExist => 0,
		   format => 'one of the gene association files available at ftp://ftp.geneontology.org/pub/go/gene-associations.  The file name must remain in the gene_ontology.<organsim short name> format.',
		   isList => 0,
	      }),

	 booleanArg ({name => 'delete',
	  descr => 'Set this to delete all GO Associations for sequences with the specified external database release id and organism specified by the given file',
	  reqd => 0,
      }),
 
	  integerArg ({name  => 'restart_line',
	  descr => 'Set this to restart loading a file that was interrupted previously; the value indicates the line on which to resume parsing.',
	  reqd  => 0,
          constraintFunc => undef,
          isList => 0,
      }), 

	  integerArg ({name  => 'instance_loe_id',
	  descr => 'The line of evidence value for a GO Association Instance created for Associations that wil be loaded witht his plugin.',
	  reqd  => 0,
          constraintFunc => undef,
          isList => 0,
          default => 1,
      }), 

	 fileArg ({name => 'mgi_file',
		   descr => 'if loading mgi associations, this file must be used to give the map between MGI sequences and Swissprot sequences (the latter being the sequences to which the GO Terms will be actually associated',
		   reqd => 0,
		   constraintFunc => undef,
		   mustExist => 1,
		   format => 'the file MRK_SwissProt.rpt currently located at ftp://ftp.informatics.jax.org/pub/reports/',
		   isList => 0,
	      }),
          stringArg({name => 'function_root_go_id',
                     descr => 'The GO Id (in normal GO:XXXXXXX format) of the root of the molecular function branch of the Gene Ontology.',
                     reqd => 0,
                     default => 'GO:0003674',
                     constraintFunc => undef,
                     isList => 0,
                }),
        
          stringArg({name => 'database_id_col',
                     descr => 'column in the DoTS.ExternalAASequence table that indicates the unique external ID provided for sequences of this organism.  Defaults are provided, but vary depending on the organism',
                     reqd => 0,
                     constraintFunc => undef,
                     isList => 0,
                }),
          stringArg({name => 'file_id_accessor',
                     descr => 'method name (without parenthesis) of the accessor method to retrieve the unique external ID of a sequence of this organism from an object of type CBIL::Bio::GeneAssocParser::Assoc, which represents one parsed entry of the input file.  Defaults are provided, but vary depending on the organism.  It is recommended that you do not set this parameter unless you are very familiar with the Assoc module.',
                     reqd => 0,
                     constraintFunc => undef,
                     isList => 0,
                }),
	 integerArg({name => 'org_external_db_release_list',
	  descr => 'External database release id for the sequences of the organism you are loading.  Most organisms only need one, but if you are loading gene_association.goa_sptr, it is recommended you provide the release ids for both Swissprot and Trembl sequences',
	  reqd => 1,
          constraintFunc => undef,
          isList => 1,
          }),

	 integerArg({name => 'test_number',
	  descr => 'if only testing, only process this number of sequences',
	  reqd => 0,
          constraintFunc => undef,
          isList => 0,
         }), 
	 ];



    $self->initialize({requiredDbVersion => {},
		       cvsRevision => '$Revision$', # cvs fills this in!
		     cvsTag => '$Name$', # cvs fills this in!
		       name => ref($self),
		       revisionNotes => 'refactored and optomized version; same functionality',
		       argsDeclaration => $argsDeclaration,
		       documentation => $documentation
		       });

    return $self;
}

# ---------------------------------------------------------------------- #
# ---------------------------------------------------------------------- #

sub isReadOnly { 0 }

#---------------------------------------------------------------------- #
# ---------------------------------------------------------------------- #


sub run {
    my ($self) = @_;

    my $msg;

    my $fileName = $self->getCla->{flat_file};    

    my ($orgName) = $fileName =~ /gene_association\.(\w+)$/;

    $self->log("Running plugin; loading $orgName associations");
    
    $self->__loadOrgInfo($orgName);
    $self->__loadGlobalData($orgName);

    if ($self->getCla->{delete}){
	$msg = $self->deleteAssociations();
    }

    else{

	#deal with restart file line
	my $currentSourceId;
	my $nextSourceId;
	my $currentEntries;
	my $idAccessor = $self->{orgInfo}->{idAccessor};
	my $fh = FileHandle->new("<$fileName");

	my $counter;
	my $fileStartLine = $self->getCla()->{restart_line};
       
	if (!$fileStartLine){
	    $fileStartLine = 0;
	}

	while(<$fh>){
	    chomp;
	    $counter++;
	    last if ($self->getCla()->{test_number} && $counter > $self->getCla()->{test_number});

	    unless(/^!/ || ($counter < $fileStartLine)){  #skip all lines before restart line
		
		my $fileEntry = CBIL::Bio::GeneAssocParser::Assoc->new($_);
		if (!$currentSourceId){  #first entry in file
		    $currentSourceId = $fileEntry->$idAccessor;
		    $self->log("LoadGoAssoc.run: processing first entry in file, $currentSourceId");
		    $nextSourceId = $currentSourceId;
		    push (@$currentEntries, $fileEntry);
		}

		else{  #every other case
		    $nextSourceId = $fileEntry->$idAccessor;
		    $self->log("LoadGoAssoc.run: next source id is: $nextSourceId");
		    if ($currentSourceId ne $nextSourceId){
			$self->__processAssociations($orgName, $currentEntries);
			undef($currentEntries);
		    }
		    else{
			$self->log("LoadGoAssoc.run: adding $nextSourceId to list");
			push (@$currentEntries, $fileEntry);
			$currentSourceId = $nextSourceId;
		    }
		}
	    }
	}

	#terminating case
	$self->__processAssociations($currentEntries);
			 
	my $currentCounters;
	
	$msg = $self->__createReturnMsg($currentCounters);
    }
    #return value
    return $msg;
}

# ---------------------------------------------------------------------- #
# ---------------------------------------------------------------------- #
sub __processAssociations{

    my ($self, $orgName, $entries) = @_;

    my $idAccessor = $self->{orgInfo}->{idAccessor};
    my $dbIdCol = $self->{orgInfo}->{dbIdCol};

    my $dbList = '( ' . $self->getCla()->{org_external_db_release_list} . ') ';

    my $sourceId = $entries->[0]->$idAccessor;

    $self->logVerbose("processing external source id: $sourceId");

    my $seqGusId = $self->__getSeqGusId($sourceId);
    if (!$seqGusId){
	$self->log("LoadGoAssoc.processAssociations: no gus id for $sourceId");
	return 0;
    }
    
    my $assocGraph = $self->__getExistingAssocGraph($seqGusId, 
						    $self->getCla()->{go_ext_db_rel_id});
    
    my $processedGoIds;
    my $assocList;
    foreach my $entry (@$entries){

	my $goId = $entry->getGOId();
	
	next if (!($self->{goGraph}->getGoTermFromRealGoId($goId)));
	
	if (!($processedGoIds->{$goId})){
	    $self->log("LoadGoAssoc.processAssociations: adding $goId to the list for $sourceId");
	    my $nextAssoc = $self->__makeAssociation($entry);
	    push (@$assocList, $nextAssoc);
	    $processedGoIds->{$goId} = 1;
	}	    
    }

    if ($assocGraph){
	$assocGraph->_addAssociations($assocList, $self->{goGraph});
    }
    else{
	$assocGraph = GUS::GOPredict::AssociationGraph->newFromAssocList($assocList);
    }

    $assocGraph->createNonPrimaryInstances($self->getCla()->{instance_loe_id});
    $assocGraph->setDefiningLeaves();
    $assocGraph->adjustIsNots(1);

    $self->__trimRedundantInstances($assocGraph);

    foreach my $assoc (@{$assocGraph->getAsList()}){
	my $gusAssoc = $assoc->getGusAssociationObject();
	if (!$gusAssoc){
	    $assoc->createGusAssociation($self->{tableId}, $seqGusId);
	}
	else{
	    $assoc->updateGusObject();
	}
    }
    
    $self->__addEvidenceCodes($assocGraph, $entries);
    
    foreach my $assoc(@{$assocGraph->getAsList()}){
	my $gusAssoc = $assoc->getGusAssociationObject();
	$gusAssoc->submit();
    }
    
    #cache evidence codes!

    $assocGraph->killReferences();
    $self->undefPointerCache();

}

sub __addEvidenceCodes{

    my ($self, $assocGraph, $entries) = @_;
    foreach my $entry (@$entries){
	my $entryGoId = $entry->getGoId();
	my $assoc = $assocGraph->find($entryGoId);
	my $instances = $assoc->getInstances();
	my $primaryInstance;
	foreach my $testInstance(@$instances){
	    if ($testInstance->getIsPrimary()){
		$primaryInstance = $testInstance;
	    }
	}
	my $gusInstance = $primaryInstance->getGusInstanceObject();
	my $goEvidenceCodeInst = $self->__makeGoEvidenceCodeInst($entry, $gusInstance);
	if ($self->__isNewEvidenceCodeInst($gusInstance, $goEvidenceCodeInst)){
	    $gusInstance->addChild($goEvidenceCodeInst);
	    my $evidenceCodeRS = $goEvidenceCodeInst->getReviewStatusId();
	    $assoc->setReviewStatusId($evidenceCodeRS) if $evidenceCodeRS;
	    $primaryInstance->setReviewStatusId($evidenceCodeRS) if $evidenceCodeRS;
	    $assoc->updateGusAssociationObject();
	}
    }
}

sub __isNewEvidenceCodeInst{

    my ($self, $gusInstance, $evidCodeInst) = @_;
    
    my $evidCodeId = $evidCodeInst->getGoEvidenceCodeId();
    my $evidCodeInstList = $gusInstance->getChildren("DoTS.GOAssocInstEvidCode");
    foreach my $nextEvidCodeInst (@$evidCodeInstList){
	if ($nextEvidCodeInst->getGoEvidenceCodeId() == $evidCodeId){
	    return 0;
	}
    }
    return 1;
}

sub __trimRedundantInstances{

    my ($self, $assocGraph) = @_;
    my $assocList = $assocGraph->getAsList();
    my @oldPrimaryInstances;
    my @newPrimaryInstances;
    my @oldNonPrimaryInstances;
    my @newNonPrimaryInstances;

    foreach my $assoc (@$assocList){
	my $instanceList = $assoc->getInstances();
	while (my $nextInstance  = shift(@$instanceList)){

	    my $gusInstance = $nextInstance->getGusInstanceObject();
	    my $isPrimary = $nextInstance->getIsPrimary();

	    if ($gusInstance && $isPrimary){
		push (@oldPrimaryInstances, $nextInstance);
	    }
	    elsif (!$gusInstance && $isPrimary){
		push (@newPrimaryInstances, $nextInstance);
	    }
	    elsif ($gusInstance && !$isPrimary){
		push (@oldNonPrimaryInstances, $nextInstance);
	    }
	    else {
		push (@newNonPrimaryInstances, $nextInstance);
	    }
	}
	print STDERR "Should be 0 instances in this assoc: " . scalar(@{$assoc->getInstances}) . "\n";
	if (scalar (@oldPrimaryInstances)){
	    foreach my $instance (@oldPrimaryInstances) { $assoc->addInstance($instance);}
	}
	else{
	    foreach my $instance (@newPrimaryInstances) { $assoc->addInstance($instance);}
	}
	if (scalar (@oldNonPrimaryInstances)){
	    foreach my $instance (@oldNonPrimaryInstances) { $assoc->addInstance($instance);}
	}
	else{
	    foreach my $instance (@newNonPrimaryInstances) { $assoc->addInstance($instance);}
	}
    }
}

sub __getExistingAssocGraph{

    my ($self, $seqGusId) = @_;

    my $tableId = $self->{extTableId};
    my $goVersion = $self->getCla()->{go_ext_db_rel_id};
    
    my $sql = "select distinct ga.go_association_id
               from dots.goassociation ga, dots.externalaasequence eas,
               SRes.GOTerm gt
               where ga.table_id = $tableId
               and ga.row_id = eas.aa_sequence_id
               and eas.aa_sequence_id = $seqGusId
               and ga.go_term_id = gt.go_term_id
               and gt.external_database_release_id = $goVersion";
    
    my $sth = $self->getQueryHandle()->prepareAndExecute($sql);
    my $assocList;
    while (my ($goAssocId) = $sth->fetchrow_array()){
	my $gusAssoc = GUS::Model::DoTS::GOAssociation->new();
	$gusAssoc->setGoAssociationId($goAssocId);
	$gusAssoc->retrieveFromDb();
	
	$gusAssoc->retrieveAllChildrenFromDB(1);  #get evidence codes too
	
	my $association = GUS::GOPredict::Association->newFromGusAssociation($gusAssoc, $self->{goGraph});
	push (@$assocList, $association); 
    }
    
    my $assocGraph = GUS::GOPredict::AssociationGraph->newFromAssocList($assocList, $self->{goGraph});
    return $assocGraph;
}


sub __getSeqGusId{
    
    my ($self, $sourceId) = @_;
    my $dbIdCol = $self->{orgInfo}->{dbIdCol};
    my $dbList = '( ' . $self->getCla()->{org_external_db_release_list} . ') ';
    my $sql = "select eas.aa_sequence_id
               from dots.externalAASequence eas
               where eas." . $dbIdCol . " = $sourceId
               and eas.external_database_release_id in ($dbList)";

    my $sth = $self->getQueryHandle()->prepareAndExecute($sql);
    my ($seqGusId) = $sth->fetchrow_array();
    return $seqGusId;
}

# ......................................................................

sub deleteAssociations{

    my ($self) = @_;
    
    my $goDb = $self->getCla->{go_ext_db_rel_id};
   
    my $file = $self->getCla->{flat_file};
    my ($organism) = $file =~ /gene_association\.(\w+)$/;
    my $dbList = '( '. join( ', ', @{ $self->{orgInfo}->{$organism}->{ db_id } } ). ' )'; 
    
    my $msg;
    my $counter = 0;

    open (DELLOG, ">>logs/deleteLog") || die "pluginLog could not be opened";

    my $sql = "select ga.go_association_id 
               from DoTS.GOAssociation ga, DoTS.ExternalAASequence eas,
               DoTS.GOAssociationInstance gai
               where ga.table_id = 83 and ga.row_id = eas.aa_sequence_id
               and gai.go_association_id = ga.go_association_id
               and eas.external_database_release_id in $dbList 
               and gai.external_database_release_id = $goDb"; 

    my $queryHandle = $self->getQueryHandle();
    my $sth = $queryHandle->prepareAndExecute($sql);
    while (my ($assocId) = $sth->fetchrow_array()){

	my $assocObject = 
	  GUS::Model::DoTS::GOAssociation->new( {go_association_id=>$assocId,});
	$assocObject->retrieveFromDB();
	$assocObject->retrieveAllChildrenFromDB(1);
	$assocObject->markDeleted(1);
	$assocObject->submit();
	$counter++;
	$self->undefPointerCache();
    }
    $msg = "Deleted $counter DoTS.Association Objects and their children";
    return $msg;
							      
}

# ......................................................................

sub __makeAssociation{
    
    my ($self, $entry) = @_;
    my $goTerm = $self->{goGraph}->getGoTermFromRealGoId($entry->getGOId());
    my $assoc = GUS::GOPredict::Association->new($goTerm);

    $assoc->setReviewStatusId(0);
    $assoc->setIsNot($entry->getIsNot());
    $assoc->setDeprecated(0);
    $assoc->setDefining(0);
    
    return $assoc;
}

sub __makeGoEvidenceCodeInst{
    
    my ($self, $entry) = @_;

    my $evidenceCode = $entry->getEvidence();
    if (!$evidenceCode){
	$evidenceCode = $entry->getWith();
    }
    my $evidenceGusId = $self->{evidenceMap}->{$evidenceCode}->{evdGusId};
    my $reviewStatusId = $self->{evidenceMap}->{$evidenceCode}->{reviewStatus};

    my $evidCodeInst = GUS::Model::DoTS::GOAssocInstEvidCode->new ({
	go_evidence_code_id => $evidenceGusId,
     	review_status_id => $reviewStatusId,
    });
    
    return $evidCodeInst;
}



# ......................................................................

#make an object of type GUS::Model::DoTS::GOAssocInstEvidCode and add it as 
#a child of the GOAssociationInstance of the supplied $gusAssociation.  
#Assumes the $gusAssociation has the child instance already set, and adds the 
#evidence code as a child by side effect.
sub __makeGoEvidenceCode{

    my ($self, $entry, $gusAssociation) = @_;
    my $gusInstance = $gusAssociation->getChild("DoTS.GOAssociationInstance");

    my $evidenceCode = $entry->getEvidence();
    if (!$evidenceCode){
	$evidenceCode = $entry->getWith();
    }
    my $evidenceGusId = $self->{evidenceMap}->{$evidenceCode}->{evdGusId};
    my $reviewStatusId = $self->{evidenceMap}->{$evidenceCode}->{reviewStatus};

    $gusAssociation->setReviewStatusId(1) if $reviewStatusId;  
    $gusInstance->setReviewStatusId(1) if $reviewStatusId;

    my $evidCodeInst = GUS::Model::DoTS::GOAssocInstEvidCode->new ({
	go_evidence_code_id => $evidenceGusId,
     	review_status_id => $reviewStatusId,
    });
    
    $gusInstance->addChild($evidCodeInst);

}

#load mapping in MRK_SwissProt.rpt file from MGI ID's to SwissProt Ids that have been loaded.
sub __loadMgiMapIfMouse{
    my ($self, $organism) = @_;
    
    if ($organism eq 'mgi'){
	my $mgiFile = $self->getCla->{mgi_file};
	
	my $fh = FileHandle->new($mgiFile);

	if (!($fh)){
	    my $msg = "Could not open file MRK_SwissProt.rpt to load mgi associations\n";
	    $msg .= "Please check that the file exists as $mgiFile if loading this type of associations.";
	    $self->userError($msg);
	}

	while ( <$fh> ) {
	    chomp;
	    my @parts = split /\t/, $_;
	    my @id_sp = split /\s/, $parts[ 5 ];
	    $self->{ maps }->{ mgi }->{ $parts[ 0 ] } = \@id_sp;
	}
	$fh->close if $fh;

	$self->log("Loaded $mgiFile for mapping from MGI Id's to SwissProt Id's");
    }

}

sub __loadGlobalData{
    my ($self, $orgName) = @_;
    $self->__loadGoGraph();
    $self->__loadMgiMapIfMouse($orgName);
    $self->__loadEvidenceMaps();
    $self->__loadSeqTableId();
}

sub __loadSeqTableId{

    my ($self) = @_;
    my $sql = "select table_id from core.tableinfo where name = 'ExternalAASequence'";
    my $sth = $self->getQueryHandle()->prepareAndExecute($sql);
    my ($tableId) = $sth->fetchrow_array();
    $self->{seqTableId} = $tableId;
}

sub __loadGoGraph{

    my ($self) = @_;
    my $goVersion = $self->getCla()->{go_ext_db_rel_id};
    my $functionRootGoId = $self->getCla()->{function_root_go_id};

    my $sql = "
     select term.go_id, term.go_term_id, hier.child_term_id
     from SRes.GOTerm term, SRes.GORelationship hier
     where term.external_database_release_id = $goVersion
     and term.name != 'Gene_Ontology'
     and term.go_term_id = hier.parent_term_id (+) 
";
    my $sth = $self->getQueryHandle()->prepareAndExecute($sql);

    my $goGraph = GUS::GOPredict::GoGraph->newFromResultSet($goVersion, $sth, $functionRootGoId);
    $self->logVeryVerbose("Loaded Go Graph:\n" . $goGraph->toString());
    $self->{goGraph} = $goGraph;
}

#load configuration data for this organism.  
sub __loadOrgInfo{
    
    my ($self, $orgName) = @_;

    my $dbIdCol = $self->__getDbIdColForOrg($orgName);
    my $fileIdAccessor = $self->__getFileIdAccessorForOrg($orgName);

    my $cleanId;
    if ($orgName eq 'mgi'){
	$cleanId = sub { $self->{ maps }->{ mgi }->{ $_[ 0 ] } };
    }
    else{
	$cleanId = sub { [ $_[ 0] ] };
    }
    
    $self->{orgInfo} = {
	dbIdCol => $dbIdCol,
	idAccessor => $fileIdAccessor,
	extDbRelId => $self->getCla()->{org_external_database_release_id},
	cleanId => $cleanId,
    };
    my $logMessage = "loaded org info:\n database ID column: $dbIdCol\n";
    $logMessage .= "id accessor method: $fileIdAccessor\n";
    $logMessage .= "external database release id(s): $dbIdCol\n";
    $self->logVerbose($logMessage);
}

#gets the name of the column in DoTS.ExternalAASequence where the primary external
#identifier for this organism is stored.  The user can supply the column name through
#a command line parameter, but if not, defaults are provided for each organism.
sub __getDbIdColForOrg{

    my ($self, $orgName) = @_;
    my $dbIdCol = $self->getCla()->{database_id_col};
    if (!$dbIdCol){
	if ($orgName eq 'sgd' || $orgName eq 'fb'){
	    $dbIdCol = 'secondary_identifier';
	}
	elsif ($orgName eq 'wb' || $orgName eq 'mgi' || $orgName eq 'goa_sptr'){
	    $dbIdCol = 'source_id';
	}
	elsif ($orgName eq 'tair'){
	    $dbIdCol = 'upper(source_id)';
	}
	else {
	    $self->userError("Did not get proper organism name; \'$orgName\' does not match one of the expected types.");
	}
    }
    return $dbIdCol;
}

#gets the method name to return the primary external identifier, given a parsed entry
#of type CBIL::Bio::GeneAssocParser::Assoc.  The user can supply the method name through
#a command line parameter, but if not, defaults are provided for each organism.
sub __getFileIdAccessorForOrg{

    my ($self, $orgName) = @_;
    
    my $fileIdAccessor = $self->getCla()->{file_id_accessor};
    
    if (!$fileIdAccessor){
	if ($orgName eq 'tair'){
	    $fileIdAccessor = 'getDBObjectSymbol';
	}
	elsif ($orgName eq 'wb' || $orgName eq 'mgi' || $orgName eq 'goa_sptr' ||
	       $orgName eq 'sgd' || $orgName eq 'fb'){
	    $fileIdAccessor = 'getDBObjectId';
	}
	else {
	    $self->userError("Did not get proper organism name; \'$orgName\' does not match one of the expected types.");
	}
    }
    return $fileIdAccessor;
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
sub __formatEntryDate{
    my ($self, $date) = @_;
    my $sqlDate;
    #format: 20030109 yearmonthday
    if ($date =~ /(\d\d\d\d)(\d\d)(\d\d)/){
	$sqlDate = $1 . "-" . $2 . "-" . $3;
    }
    return $sqlDate;
}

#map from the name of an evidence code to its GUS Id and review status
sub __loadEvidenceMaps {
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
    
    $self->{evidenceMap} = $evidenceMap;
}

# ---------------------------------------------------------------------- #
# ---------------------------------------------------------------------- #

1;

