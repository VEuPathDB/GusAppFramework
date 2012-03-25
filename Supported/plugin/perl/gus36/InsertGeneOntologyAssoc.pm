#######################################################################
##             LoadGeneOntologyAssoc.pm
##
## $Id$
##
#######################################################################

package GUS::Supported::Plugin::InsertGeneOntologyAssoc;
@ISA = qw( GUS::PluginMgr::Plugin);

use CBIL::Bio::GeneAssocParser::Parser;
use GUS::PluginMgr::Plugin;
use GUS::GOPredict::GoGraph;
use GUS::GOPredict::AssociationGraph;
use GUS::GOPredict::Association;
use GUS::GOPredict::Instance;
use GUS::GOPredict::GoTerm;
use GUS::Model::DoTS::GOAssociationInstance;
use GUS::Model::DoTS::GOAssociation;
use GUS::Model::DoTS::GOAssocInstEvidCode;
use GUS::Model::Core::TableInfo;

use FileHandle;
use Carp;
use lib "$ENV{GUS_HOME}/lib/perl";
use strict 'vars';


my $purposeBrief = <<PURPOSEBRIEF;
Loads associations of external sequences to GO terms into GUS.
PURPOSEBRIEF

my $purpose = <<PLUGIN_PURPOSE;
This plugin uses CBIL's Gene Association parser to parse a file representing amino acid sequences of an organism annotated with a Gene Ontology term and support for that annotation.  The file is provided by organizations participating in the Gene Ontology Consortium.  The data is then loaded into GUS, using the policies set out by CBIL to track GO Associations through the GO Hierarchy.
PLUGIN_PURPOSE

    
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

my $howToRestart = <<PLUGIN_RESTART;
There are a few ways.  The first two involve setting the --restartLine option to specify the line in the input file on which to restart, and the plugin will begin at that line.  To determine this line using a previous run, you could do one of two things.  The first is to have run the plugin in --verbose mode previously; this logs the line of each entry in the file as it is processed.  The last line in the log is the last line processed.  The second is to go into the database and find the last entry (using the 'modification_date' column) that was inserted into the database.  Find the GOAssociation with the latest modification date, and then find the GOAssocInstEvidCode with the latest modification date that is a child of the GOAssociationInstance pointing to the GOAssociation.  The sequence Id/GO Id/Evidence Code triplet that you find this way is in the file as well; the first occurrence of this code in the file is where the plugin left off.  The final way is to not provide the restartLine; the plugin will go through the file and skip everything that it already did, but it will still take the same amount of time.
PLUGIN_RESTART

my $failureCases = <<PLUGIN_FAILURE_CASES;
None that we've found so far.
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
The review_status_id attribute for the Association is set automatically according to the GO Evidence Code provided; in this context, the value for the review status indicates whether the Association has been annotated by whomever created the file in the first place.  For a discussion of some of the finer points of the algorithms used in this plugin, see the file in {PROJECT_HOME}/GUS/GOPredict/doc.
PLUGIN_NOTES


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

         stringArg({name => 'externalDatabaseName',
	    descr => 'sres.externaldatabase.name for this GO file',
	    constraintFunc => undef,
	    reqd => 1,
	    isList => 0
	    }),
 
         stringArg({name => 'externalDatabaseVersion',
	    descr => 'sres.externaldatabaserelease.version for this instance of GO file',
	    constraintFunc => undef,
	    reqd => 1,
	    isList => 0
	    }),
	 
	 fileArg ({name => 'flatFile',
		   descr => 'read GO Association data from this flat file, provide the full filepath', 
		   constraintFunc => undef,
		   reqd => 1,
		   isList => 0,
		   mustExist => 0,
		   format => 'one of the gene association files available at ftp://ftp.geneontology.org/pub/go/gene-associations.  The file name must remain in the gene_ontology.<organsim short name> format.'
	          }),

         fileArg ({name => 'reviewStatusFile',
		   descr => 'read controlled vocabulary data from this flat file, provide the full filepath', 
		   constraintFunc => undef,
		   reqd => 1,
		   isList => 0,
		   mustExist => 0,
		   format => 'Tab delimited file with structure like evidenceCodeSynonym \t reviewStatus.'
	          }),

	 stringArg({name => 'orgExternalDbReleaseList',
	            descr => 'External database release id for the sequences of the organism you are loading.  Most organisms only need one, but if you are loading gene_association.goa_uniprot, it is recommended you provide the release ids for both Swissprot and Trembl sequences',
                    constraintFunc => undef,
	            reqd => 1,
                    isList => 0
                   }),

 	 booleanArg ({name => 'delete',
	              descr => 'Set this to delete all GO Associations for sequences with the specified external database release id and organism specified by the given file',
	              reqd => 0,
                      default => 0
                     }),

 	 booleanArg ({name => 'excludeIEA',
	              descr => 'Set this to quickly skip all sequences that only have GO Associations annotated with evidence set to IEA (inferred by electronic annotation)',
	              reqd => 0,
                      default =>0
                     }),
 
	 integerArg ({name  => 'restartLine',
	              descr => 'Set this to restart loading a file that was interrupted previously; the value indicates the line on which to resume parsing.',
                      constraintFunc => undef,
	              reqd  => 0,
                      isList => 0
                     }), 

	 integerArg ({name  => 'logFrequency',
	              descr => 'Frequency of entries in the file with which to write a line out to the log',
                      constraintFunc => undef,
	              reqd  => 0,
                      isList => 0,
                      default => 1000
                     }), 

	 integerArg ({name  => 'instanceLoeId',
	              descr => 'The line of evidence value for a GO Association Instance created for Associations that will be loaded witht this plugin',
                      constraintFunc => undef,
	              reqd  => 0,
                      isList => 0,
                      default => 1,
                     }), 

	 fileArg ({name => 'mgiFile',
		   descr => 'if loading mgi associations, this file must be used to give the map between MGI sequences and Swissprot sequences (the latter being the sequences to which the GO Terms will be actually associated',
		   reqd => 0,
		   constraintFunc => undef,
		   mustExist => 1,
		   format => 'the file MRK_SwissProt.rpt currently located at ftp://ftp.informatics.jax.org/pub/reports/',
		   isList => 0,
	          }),

         stringArg({name => 'functionRootGoId',
                    descr => 'The GO Id (in normal GO:XXXXXXX format) of the root of the molecular function branch of the Gene Ontology.',
                     constraintFunc => undef,
                     reqd => 0,
                     isList => 0,
                     default => 'GO:0003674'
                    }),
        
         stringArg({name => 'databaseIdCol',
                    descr => 'column in the DoTS.ExternalAASequence table that indicates the unique external ID provided for sequences of this organism.  Defaults are provided, but vary depending on the organism',
                     constraintFunc => undef,
                     reqd => 0,
                     isList => 0
                    }),

         stringArg({name => 'fileIdAccessor',
                    descr => 'method name (without parenthesis) of the accessor method to retrieve the unique external ID of a sequence of this organism from an object of type CBIL::Bio::GeneAssocParser::Assoc, which represents one parsed entry of the input file.  Defaults are provided, but vary depending on the organism.  It is recommended that you do not set this parameter unless you are very familiar with the Assoc module.',
                     constraintFunc => undef,
                     reqd => 0,
                     isList => 0
                    }),

	 integerArg({name => 'testNumber',
	             descr => 'if only testing, process only this number of sequences',
                     constraintFunc => undef,
	             reqd => 0,
                     isList => 0,
                    }) 

    ];


#######################################################################
# Create a new object
#######################################################################
sub new {
    my ($class) = @_;
    my $self = {};
    bless($self,$class);

    $self->initialize({requiredDbVersion => 3.6,
		       cvsRevision => '$Revision$', # cvs fills this in!
		       name => ref($self),
		       argsDeclaration => $argsDeclaration,
		       documentation => $documentation
		      });

    return $self;
}


#######################################################################
# Main Routine
#######################################################################

sub run {
    my ($self) = @_;
    my $msg;
    my $zipfileName = $self->getArg('flatFile');
    my $logFrequency = $self->getArg('logFrequency');
    my $fileName;

    if ($zipfileName =~ /(.*)\.gz$/){
	system("gunzip $zipfileName");
	$fileName = $1;
    }
    else {
	$fileName = $zipfileName;
    }
    
    my ($shortFileName) = $fileName =~ /\S+(gene_association.*)$/;
    my ($orgName) = $fileName =~ /gene_association\.(\w+)$/;

    $self->log("Running plugin; loading $orgName associations");
    $self->__loadOrgInfo($orgName);
    $self->__loadGlobalData($orgName);

    if ($self->getArg('delete')){
	$msg = $self->deleteAssociations();
    }
    else{
	$msg .= $self->__processEntries($fileName, $logFrequency, $orgName, $shortFileName);
    }

    return $msg;
}

#######################################################################
# Subroutines
#######################################################################
# ---------------------------------------------------------------------
# isReadOnly - returns nothing
# ---------------------------------------------------------------------

sub isReadOnly { 0 }

# ---------------------------------------------------------------------
# processEntries
# ---------------------------------------------------------------------

sub __processEntries{
    my ($self, $fileName, $logFrequency, $orgName, $shortFileName) = @_;
    my $msg;

    #deal with restart file line
    my $currentSourceId;
    my $nextSourceId;
    my @currentEntries;
    my $idAccessor = $self->{orgInfo}->{idAccessor};
    my $counter;
    my $assocCount = 0;
    my $wrongBranchCount = 0;
    my $noSeqCount = 0;
    my $totalSeqCount = 0;

    my $fh = FileHandle->new("<$fileName") || die ("cannot open $fileName");
    my $fileStartLine = $self->getArg('restartLine');
       
    if (!$fileStartLine){
	$fileStartLine = 0;
    }

    while(<$fh>){
	chomp;
	next if (/^!/);
	$counter++;
	last if ($self->getArg('testNumber') && $counter > $self->getArg('testNumber'));
	
	unless(/^!/ || ($counter < $fileStartLine)){  #skip all lines before restart line
	    
	    my $fileEntry = CBIL::Bio::GeneAssocParser::Assoc->new($_);
   
	    if (!$currentSourceId){  #first entry in file
		$currentSourceId = $fileEntry->$idAccessor;
		$nextSourceId = $currentSourceId;
		push (@currentEntries, $fileEntry);
	    }
	    else{  #every other case
		$nextSourceId = $fileEntry->$idAccessor;
		
		if ($currentSourceId ne $nextSourceId){
		    my ($newAssocCount, $newWrongBranchCount, $newNoSeqCount) = 
			$self->__processAssociations($orgName, \@currentEntries);
		    
		    #increment results of process
		    $assocCount += $newAssocCount;
		    $wrongBranchCount += $newWrongBranchCount;
		    $noSeqCount += $newNoSeqCount;
		    $totalSeqCount++ if !$newNoSeqCount;
		    
		    undef(@currentEntries);
		}
		
		$self->log("processing entry with id " . $fileEntry->$idAccessor . "; total entries processed: $counter")
		    if ($logFrequency && ($counter % $logFrequency == 0));
		push (@currentEntries, $fileEntry);
		$currentSourceId = $nextSourceId;
	    }
	}
    }

    #terminating case
    my ($newAssocCount, $newWrongBranchCount, $newNoSeqCount) = 
	$self->__processAssociations($orgName, \@currentEntries);
    
    $assocCount += $newAssocCount;
    $wrongBranchCount += $newWrongBranchCount;
    $noSeqCount += $newNoSeqCount;
    $totalSeqCount++ if !$newNoSeqCount;
    
    
    $msg = "processed $totalSeqCount entries (give or take a few) from file $shortFileName\n";
    $msg .= "created $assocCount new Associations; skipped $wrongBranchCount entries because they were not\n";
    $msg .= "in the molecular function branch of GO, and skipped $noSeqCount sequences because they were not\n";
    $msg .= "in GUS\n";
 

    return $msg;
}


# ---------------------------------------------------------------------
# processAssociations
# ---------------------------------------------------------------------

sub __processAssociations{
    my ($self, $orgName, $entries) = @_;
    my $processedGoIds;
    my $assocList;
    my $newAssocCount = 0;
    my $wrongBranchCount = 0;

    if ($self->getArg('excludeIEA')){
	return (0, 0, 0) if $self->__onlyIEAForSeq($entries);
    }

    my $idAccessor = $self->{orgInfo}->{idAccessor};
    my $dbIdCol = $self->{orgInfo}->{dbIdCol};
    my $dbList = '( ' . $self->getArg('orgExternalDbReleaseList') . ') ';
    my $tempSourceId = $entries->[0]->$idAccessor;
    my $sourceId = $tempSourceId;

    if ($orgName eq 'mgi'){
	$sourceId = $self->{mgiMap}->{$tempSourceId};
    }

    #DTB and DFP 1/03/05 We put this clause in here because the gene_assocation.sgd file had put in two 
    #extra 0's for the secondary_identifier for yeast.  This did not match up with the fasta file for yeast
    #so it was not finding the sequences as they were loaded in GUS.  If the gene_association.sgd file fixes
    #this error, we will have to remove this clause.
    if ($orgName eq 'sgd'){
	my $origSourceId = $sourceId;
	$sourceId =~ s/S00/S/;
	$self->logVerbose("converted $origSourceId to $sourceId for yeast");
    }
    
    $self->logVerbose("\tLoadGeneOntologyAssoc.processAssociations: processing external source id: $sourceId");
    
    #exclude iea code here
    my $seqGusId = $self->__getSeqGusId($sourceId);
    if (!$seqGusId){
	$self->logVerbose("\tLoadGeneOntologyAssoc.processAssociations: no gus id for $sourceId");
	return ($newAssocCount, $wrongBranchCount, 1);
    }
    
    my $assocGraph = $self->__getExistingAssocGraph($seqGusId);
    
    foreach my $entry (@$entries){

	my $goId = $entry->getGOId();

	if (!($self->{goGraph}->getGoTermFromRealGoId($goId))){
	    $wrongBranchCount++;
	    next;
	}

	if (!($processedGoIds->{$goId})){
	    my $nextAssoc = $self->__makeAssociation($entry);
	    $newAssocCount++;
	    push (@$assocList, $nextAssoc);
	    $processedGoIds->{$goId} = 1;
	}	    
    }

    if ($assocGraph){
	$self->logVerbose("\t\t LoadGeneOntologyAssoc.processAssociation: already have associations for this sequence; adding more");
	$assocGraph->_addAssociations($assocList, $self->{goGraph});
    }
    else{
	$assocGraph = GUS::GOPredict::AssociationGraph->newFromAssocList($assocList, $self->{goGraph});
    }
    if (!$assocGraph){ # no GO terms in function branch for this sequence
	return ($newAssocCount, $wrongBranchCount, 0);
    }
	
    $assocGraph->createNonPrimaryInstances($self->getArg('instanceLoeId'));
    $assocGraph->setDefiningLeaves();
    $assocGraph->adjustIsNots(1);
    
    $self->__trimRedundantInstances($assocGraph);
    
    foreach my $assoc (@{$assocGraph->getAsList()}){
	my $gusAssoc = $assoc->getGusAssociationObject();

	if (!$gusAssoc){
	    $assoc->createGusAssociation($self->{seqTableId}, $seqGusId);
	}
	else{
	    $assoc->updateGusObject();
	}
    }
    
    $self->__addEvidenceCodes($assocGraph, $entries);
    $self->__cacheEvidenceCodes($assocGraph);

    $self->logVeryVerbose("\t\t LoadGeneOntologyAssoc.processAssociation: done processing assocGraph for sequence $sourceId: " . $assocGraph->toString . "\n");

    foreach my $assoc(@{$assocGraph->getAsList()}){
	$assoc->updateGusObject(); #in case evidence codes have changed review status id
	my $gusAssoc = $assoc->getGusAssociationObject();
	$gusAssoc->submit();
    }
    
    $assocGraph->killReferences();
    $self->undefPointerCache();
    
    return ($newAssocCount, $wrongBranchCount, 0);
}

# ---------------------------------------------------------------------
# addEvidenceCodes - assumes instances have been trimmed
# ---------------------------------------------------------------------

sub __addEvidenceCodes{
    my ($self, $assocGraph, $entries) = @_;

    foreach my $entry (@$entries){
	if ($entry->getEvidence()){ #some entries in worm file have no evidence!
	    my $entryGoId = $entry->getGOId();
	    my $assoc = $assocGraph->find($entryGoId);

	    if ($assoc) {     #some go ids not in assoc graph because they are in a different branch
		my $goEvidenceCodeInst = $self->__makeGoEvidenceCodeInst($entry);
		$self->__addEvidenceCodeAux($assoc, $goEvidenceCodeInst);
	    }
	}
    }
}

# ---------------------------------------------------------------------
# cacheEvidenceCodes
# ---------------------------------------------------------------------

sub __cacheEvidenceCodes{
    my ($self, $assocGraph) = @_;

    foreach my $assoc (@{$assocGraph->getAsList()}){
	if ($assoc->isPrimary() && !$assoc->getIsNot()){
	    my $instances = $assoc->getInstances();
	    my @evidenceCodes;

	    foreach my $instance(@$instances){ 
		my $gusInstance = $instance->getGusInstanceObject();
		my @childEvidCodes = $gusInstance->getChildren('DoTS::GOAssocInstEvidCode');

		foreach my $evidCode (@childEvidCodes){
		    push (@evidenceCodes, $evidCode);
		}
	    }

	    foreach my $evidCode(@evidenceCodes){
		my $parents = $assoc->getParents();

		foreach my $parentAssoc (@$parents){
		    $self->__addEvidenceCodeToParent($parentAssoc, $evidCode);
		}
	    }
	}
    }
}

# ---------------------------------------------------------------------
# addEvidenceCodeToParent
# ---------------------------------------------------------------------

sub __addEvidenceCodeToParent{
    my ($self, $parentAssoc, $evidCodeInst) = @_;

    if ($parentAssoc->getGoTerm()->getRealId() ne $self->{goGraph}->getRootTerm()->getRealId()){

	my $evidCodeId = $evidCodeInst->getGoEvidenceCodeId();
	my $reviewStatusId = $evidCodeInst->getReviewStatusId();

	my $evidCodeCopy = GUS::Model::DoTS::GOAssocInstEvidCode->new ({
	    go_evidence_code_id => $evidCodeId,
	    review_status_id => $reviewStatusId,
	});
	
	$self->__addEvidenceCodeAux($parentAssoc, $evidCodeCopy);
    }

    foreach my $grandParent (@{$parentAssoc->getParents()}){
	$self->__addEvidenceCodeToParent($grandParent, $evidCodeInst);
    }
}

# ---------------------------------------------------------------------
# addEvidenceCodeAux
# ---------------------------------------------------------------------

sub __addEvidenceCodeAux{
    my ($self, $assoc, $evidCodeInst) = @_;
    my $instances = $assoc->getInstances();
    my $instanceForCode;

    foreach my $testInstance(@$instances){
	if ($testInstance->getIsPrimary() || !$assoc->isPrimary()){ 
	    $instanceForCode = $testInstance;
	    last;
	}
    }

    my $gusInstance = $instanceForCode->getGusInstanceObject();
    
    if ($self->__isNewEvidenceCodeInst($gusInstance, $evidCodeInst)){
	$gusInstance->addChild($evidCodeInst);
	my @evidCodes = $gusInstance->getChildren('DoTS::GOAssocInstEvidCode');
	my $evidenceCodeRS = $evidCodeInst->getReviewStatusId();
	$assoc->setReviewStatusId($evidenceCodeRS) if $evidenceCodeRS;
	$instanceForCode->setReviewStatusId($evidenceCodeRS) if $evidenceCodeRS;
    }
}

# ---------------------------------------------------------------------
# isNewEvidenceCodeInst
# ---------------------------------------------------------------------

sub __isNewEvidenceCodeInst{
    my ($self, $gusInstance, $evidCodeInst) = @_;
    my $evidCodeId = $evidCodeInst->getGoEvidenceCodeId();
    my @evidCodeInstList = $gusInstance->getChildren('DoTS::GOAssocInstEvidCode');

    foreach my $nextEvidCodeInst (@evidCodeInstList){
	if ($nextEvidCodeInst->getGoEvidenceCodeId() == $evidCodeId){
	    return 0;
	}
    }

    return 1;
}

# ---------------------------------------------------------------------
# trimRedundantInstances
# ---------------------------------------------------------------------

sub __trimRedundantInstances{
    my ($self, $assocGraph) = @_;
    my $assocList = $assocGraph->getAsList();

    foreach my $assoc (@$assocList){
	my @oldPrimaryInstances;
	my @newPrimaryInstances;
	my @oldNonPrimaryInstances;
	my @newNonPrimaryInstances;
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

# ---------------------------------------------------------------------
# getExistingAssocGraph
# ---------------------------------------------------------------------

sub __getExistingAssocGraph{
    my ($self, $seqGusId) = @_;
    my $tableId = $self->{seqTableId};
    my $goVersion=$self->getExtDbRlsId($self->getArg('externalDatabaseName'),
				       $self->getArg('externalDatabaseVersion'));
    my $assocList;
 
    my $sql = "select distinct ga.go_association_id
               from dots.goassociation ga, dots.externalaasequence eas,
               SRes.GOTerm gt
               where ga.table_id = $tableId
               and ga.row_id = eas.aa_sequence_id
               and eas.aa_sequence_id = $seqGusId
               and ga.go_term_id = gt.go_term_id
               and gt.external_database_release_id = $goVersion";

    my $sth = $self->prepareAndExecute($sql); #in test mode need to use db handle
   
    while (my ($goAssocId) = $sth->fetchrow_array()){
	my $gusAssoc = GUS::Model::DoTS::GOAssociation->new();

	$gusAssoc->setGoAssociationId($goAssocId);
	$gusAssoc->retrieveFromDB();
	$gusAssoc->retrieveAllChildrenFromDB(1);  #get evidence codes too
	
	my $association = GUS::GOPredict::Association->newFromGusAssociation($gusAssoc, $self->{goGraph});

	push (@$assocList, $association); 
    }
    
    my $assocGraph = GUS::GOPredict::AssociationGraph->newFromAssocList($assocList, $self->{goGraph});

    return $assocGraph;
}

# ---------------------------------------------------------------------
# getSeqGusId
# ---------------------------------------------------------------------

sub __getSeqGusId{
    my ($self, $sourceId) = @_;
    my $dbIdCol = $self->{orgInfo}->{dbIdCol};
    my $dbList = $self->getArg('orgExternalDbReleaseList');
    #my $dbList = '( ' . join (',', @{$self->getArg('orgExternalDbReleaseList') }) . ') ';

    my $sql = "select eas.aa_sequence_id
               from dots.externalAASequence eas
               where $dbIdCol = '$sourceId'
	       and eas.external_database_release_id in ($dbList)";

    my $sth = $self->prepareAndExecute($sql);
    my ($seqGusId) = $sth->fetchrow_array();

    return $seqGusId;
}

# ---------------------------------------------------------------------
# deleteAssociations
# ---------------------------------------------------------------------

sub deleteAssociations{
    my ($self) = @_;
    my $goDb = $self->getExtDbRlsId($self->getArg('externalDatabaseName'),
				    $self->getArg('externalDatabaseVersion'));
    my $file = $self->getArg('flatFile');
    my ($organism) = $file =~ /gene_association\.(\w+)$/;
    my $dbList = '( '. join( ', ', @{ $self->{orgInfo}->{$organism}->{ db_id } } ). ' )'; #if this is not set the program will die at the database level - will not be set if the organism is not in the database
    my $msg;
    my $counter = 0;

    my $sql = "select ga.go_association_id 
               from DoTS.GOAssociation ga, DoTS.ExternalAASequence eas,
               DoTS.GOAssociationInstance gai
               where ga.table_id = 83 and ga.row_id = eas.aa_sequence_id
               and gai.go_association_id = ga.go_association_id
               and eas.external_database_release_id in $dbList 
               and gai.external_database_release_id = $goDb"; 

    my $sth = $self->prepareAndExecute($sql);

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

# ---------------------------------------------------------------------
# makeAssociation
# ---------------------------------------------------------------------

sub __makeAssociation{
    my ($self, $entry) = @_;
    my $goTerm = $self->{goGraph}->getGoTermFromRealGoId($entry->getGOId());
    my $assoc = GUS::GOPredict::Association->new($goTerm);

    $assoc->setReviewStatusId(0);

    if ($entry->getIsNot()){ #returns 'NOT' so need to do conversion
	$assoc->setIsNot(1);
    }
    else{
	$assoc->setIsNot(0);
    }

    $assoc->setDeprecated(0);
    $assoc->setDefining(0);
    
    my $instance = GUS::GOPredict::Instance->new();
    $instance->setIsNot($assoc->getIsNot());
    $instance->setIsPrimary(1);
    $instance->setLOEId($self->getArg('instanceLoeId'));
    $instance->setDeprecated(0);
    $instance->setReviewStatusId(0);
    
    $assoc->addInstance($instance);

    return $assoc;
}

# ---------------------------------------------------------------------
# makeGoEvidenceCodeInst
# ---------------------------------------------------------------------

sub __makeGoEvidenceCodeInst{
    my ($self, $entry) = @_;
    my $evidenceCode = $entry->getEvidence();

    if (!$evidenceCode){
	my $idAccessor = $self->{orgInfo}->{idAccessor};
	$self->log("LoadGeneOntologyAssoc.makeGoEvidenceCodeInst: sequence " . $entry->$idAccessor . " GO Term " . $entry->getGOId() . " has no evidence");
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

# ---------------------------------------------------------------------
# loadMgiMapIfMouse -
# load mapping in MRK_SwissProt.rpt file from MGI ID's to SwissProt Ids that have been loaded.
# ---------------------------------------------------------------------

sub __loadMgiMapIfMouse{
    my ($self, $organism) = @_;
    
    if ($organism eq 'mgi'){
	my $mgiFile = $self->getArg('mgiFile');
	my $fh = FileHandle->new($mgiFile);

	if (!($fh)){
	    my $msg = "Could not open file MRK_SwissProt.rpt to load mgi associations\n";
	    $msg .= "Please check that the file exists as $mgiFile if loading this type of associations.";
	    $self->userError($msg);
	}

	while ( <$fh> ) {
	    chomp;
	    my @parts = split /\t/, $_;
	    my $id_sp =  $parts[ 6 ];
	    $self->{ mgiMap }->{ $parts[ 0 ] } = $id_sp;
	}
	$fh->close if $fh;

	$self->log("Loaded $mgiFile for mapping from MGI Id's to SwissProt Id's");
    }
}

# ---------------------------------------------------------------------
# loadGlobalData
# ---------------------------------------------------------------------

sub __loadGlobalData{
    my ($self, $orgName) = @_;

    $self->__loadGoGraph();
    $self->__loadMgiMapIfMouse($orgName);
    $self->__loadEvidenceMaps();
    $self->__loadSeqTableId();
}

# ---------------------------------------------------------------------
# loadSeqTableId
# ---------------------------------------------------------------------

sub __loadSeqTableId{
    my ($self) = @_;

    my $sql = "select table_id from core.tableinfo where name = 'ExternalAASequence'";

    my $sth = $self->prepareAndExecute($sql);
    my ($tableId) = $sth->fetchrow_array();

    $self->{seqTableId} = $tableId;
}

# ---------------------------------------------------------------------
# loadGoGraph
# ---------------------------------------------------------------------

sub __loadGoGraph{
    my ($self) = @_;
    my $goVersion = $self->getExtDbRlsId($self->getArg('externalDatabaseName'),
					 $self->getArg('externalDatabaseVersion'));
    my $functionRootGoId = $self->getArg('functionRootGoId');

    my $sql = "
     select term.go_id, term.go_term_id, hier.child_term_id
     from SRes.GOTerm term Left Outer Join SRes.GORelationship hier On term.go_term_id = hier.parent_term_id
     where term.external_database_release_id = $goVersion
     and term.name != 'Gene_Ontology'
";
    my $sth = $self->prepareAndExecute($sql);

    $self->log("LoadGeneOntologyAssoc.loadGoGraph: making new go graph with root = $functionRootGoId");

    my $goGraph = GUS::GOPredict::GoGraph->newFromResultSet($goVersion, $sth, $functionRootGoId);
    $self->{goGraph} = $goGraph;
}

# ---------------------------------------------------------------------
# loadOrgInfo - load configuration data for this organism.
# ---------------------------------------------------------------------

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
	extDbRelId => $self->getArg('orgExternalDbReleaseList'),#this used to be org_external_database_release_id, why?
	cleanId => $cleanId
    };

    my $logMessage = "loaded org info:\n database ID column: $dbIdCol\n";
    $logMessage .= "id accessor method: $fileIdAccessor\n";
    $logMessage .= "external database release id(s): $dbIdCol\n";
    $self->logVerbose($logMessage);
}

# ---------------------------------------------------------------------
# getDbIdColForOrg -
# gets the name of the column in DoTS.ExternalAASequence where the primary external
# identifier for this organism is stored.  The user can supply the column name through
# a command line parameter, but if not, defaults are provided for each organism.
# ---------------------------------------------------------------------

sub __getDbIdColForOrg{
    my ($self, $orgName) = @_;
    my $dbIdCol = $self->getArg('databaseIdCol');
#this seems to limit the type of organism that goes into the db, is this correct?
    if (!$dbIdCol){
	if ($orgName eq 'sgd' || $orgName eq 'fb'){
	    $dbIdCol = 'eas.secondary_identifier';
	}
	elsif ($orgName eq 'wb' || $orgName eq 'mgi' || $orgName eq 'goa_uniprot'){
	    $dbIdCol = 'eas.source_id';
	}
	elsif ($orgName eq 'tair'){
	    $dbIdCol = 'upper(eas.source_id)';
	}
	else {
	    $self->userError("Did not get proper organism name; \'$orgName\' does not match one of the expected types.");
	}
    }

    return $dbIdCol;
}

# ---------------------------------------------------------------------
# getFileIdAccessorForOrg -
# gets the method name to return the primary external identifier, given a parsed entry
# of type CBIL::Bio::GeneAssocParser::Assoc.  The user can supply the method name through
# a command line parameter, but if not, defaults are provided for each organism.
# ---------------------------------------------------------------------

sub __getFileIdAccessorForOrg{
    my ($self, $orgName) = @_;
    my $fileIdAccessor = $self->getArg('fileIdAccessor');
    
    if (!$fileIdAccessor){
	if ($orgName eq 'tair'){
	    $fileIdAccessor = 'getDBObjectSymbol';
	}
	elsif ($orgName eq 'wb' || $orgName eq 'mgi' || $orgName eq 'goa_uniprot' ||
	       $orgName eq 'sgd' || $orgName eq 'fb'){
	    $fileIdAccessor = 'getDBObjectId';
	}
	else {
	    $self->userError("Did not get proper organism name; \'$orgName\' does not match one of the expected types.");
	}
    }

    return $fileIdAccessor;
}

# ---------------------------------------------------------------------
# formatEntryDate -
# change entry date from what is in association file to something to go in Dots.GoAssociation table
# ---------------------------------------------------------------------

sub __formatEntryDate{
    my ($self, $date) = @_;
    my $sqlDate;

    #format: 20030109 yearmonthday
    if ($date =~ /(\d\d\d\d)(\d\d)(\d\d)/){
	$sqlDate = $1 . "-" . $2 . "-" . $3;
    }

    return $sqlDate;
}

# ---------------------------------------------------------------------
# onlyIEAForSeq
# ---------------------------------------------------------------------

sub __onlyIEAForSeq {
    my ($self, $entries) = @_;

    foreach my $entry (@$entries){
	return 0 if ($entry->getEvidence() ne 'IEA');
    }

    $self->logVeryVerbose("skipping this sequence since it only has IEA annotation");

    return 1;
}

# ---------------------------------------------------------------------
# loadEvindenceMaps -
# map from the name of an evidence code to its GUS Id and review status
# ---------------------------------------------------------------------

sub __loadEvidenceMaps {
    my ($self) = @_;
    my $evidenceMap;

    my $sql = "select name, go_evidence_code_id from sres.goevidencecode";
    my $sth = $self->prepareAndExecute($sql);

    while (my ($name, $evdGusId) = $sth->fetchrow_array()){
	$evidenceMap->{$name}->{evdGusId} = $evdGusId;
    }

    my $file_name = $self->getArg('reviewStatusFile');
    my $reviewStatus = $self->getControlledVocabMapping($file_name, 'SRes.reviewStatus', 'name');

    $evidenceMap->{IC}->{reviewStatus} = $reviewStatus->{IC}->{primaryKey}; 
    $evidenceMap->{IDA}->{reviewStatus} = $reviewStatus->{IDA}->{primaryKey};
    $evidenceMap->{IEA}->{reviewStatus} = $reviewStatus->{IEA}->{primaryKey};
    $evidenceMap->{IEP}->{reviewStatus} = $reviewStatus->{IEP}->{primaryKey};
    $evidenceMap->{IGI}->{reviewStatus} = $reviewStatus->{IGI}->{primaryKey};
    $evidenceMap->{IMP}->{reviewStatus} = $reviewStatus->{IMP}->{primaryKey};
    $evidenceMap->{IPI}->{reviewStatus} = $reviewStatus->{IPI}->{primaryKey};
    $evidenceMap->{ISS}->{reviewStatus} = $reviewStatus->{ISS}->{primaryKey};
    $evidenceMap->{NAS}->{reviewStatus} = $reviewStatus->{NAS}->{primaryKey};
    $evidenceMap->{ND}->{reviewStatus} = $reviewStatus->{ND}->{primaryKey};
    $evidenceMap->{TAS}->{reviewStatus} = $reviewStatus->{TAS}->{primaryKey};
    $evidenceMap->{NR}->{reviewStatus} = $reviewStatus->{NR}->{primaryKey};
    
    $self->{evidenceMap} = $evidenceMap;
}



1;

