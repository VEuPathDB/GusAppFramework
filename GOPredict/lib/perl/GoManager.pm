package GUS::GOPredict::GoManager;

use GUS::GOPredict::GoRuleEngine;
use GUS::GOPredict::GoGraph;
use GUS::GOPredict::Association;
use GUS::GOPredict::AssociationGraph;
use GUS::GOPredict::GoExtent;

use strict;
use Carp;
use FileHandle;

##################################### GoManager.pm #######################################

# A module that oversees operations on associations between proteins and GO Terms.  It   #
# has an Adapter from which it gets all of its data; possible implementations of this    #
# Adapter can be a TestAdapter or a DatabaseAdapter, which feed the GoManager test/fake #
# data or data directly from GUS, respectively.  With this data, the GoManager creates  #
# AssociationGraphs, which it uses to perform any number of operations as requested by   #
# whatever created and controls the GoManager (for example, GoPlugin.pm or an           #
# executable).                                                                           #

# GoManager contains a few important objects as private data, including a GoGraph, which#
# represents the GO Hierarchy used to create AssociationGraphs (when upgrading           #
# Associations to a new release of the GO Hierarchy, the GoManager stores two GoGraphs, #
# one for the old release and one for the new.)  It also stores a GoRuleEngine which     #
# produces rules and assigns GO Terms to Sequences if they match the given similarity    #
# criteria to an annotated protein motif.                                                #

# Care must be taken that operations are perfromed in the correct order on proteins, see #
# the documentation in $PROJECT_HOME/GUS/GOPredict/doc for more information.             #

# Created: May 2003. Authors: Dave Barkan, Steve Fischer.                                #
# Last Modified: July 1, 2003, Dave Barkan; separated private methods and added          # 
# documentation.                                                                         #

##########################################################################################


#global verbosity levels to fake the Plugin.pm's logging mechanism.
my $verboseLevel = 1;
my $veryVerboseLevel = 2;
my $noVerboseLevel = 0;


my $curatorLOEId = 4;

############################################################################################
#################################  Constructor #############################################
############################################################################################

#takes only the adapter from which the GoManager will be getting its data.
sub new{

    my ($class, $adapter) = @_;
    my $self = {};
    bless $self, $class;
    $self->setAdapter($adapter);
   
    return $self;
}

############################################################################################
#################################  Top Level Methods #######################################
############################################################################################

#upgrade all associations for all proteins to the new release of the GO Hierarchy
sub evolveGoHierarchy{

    my ($self, $oldGoVersion, $newGoVersion, $deleteInstances, $recache, $proteinTableId, 
	$doNotScrub, $testNumber, $taxonId, $excludeAlgIds, $validate) = @_;
    
    my $goSynMap = $self->getAdapter()->makeGoSynMap($newGoVersion);

    $self->initializeOldGoGraph($oldGoVersion, $goSynMap);
    $self->initializeNewGoGraph($newGoVersion);
    $self->setOldGoVersion($oldGoVersion);
    $self->setNewGoVersion($newGoVersion);

    my $goTermMap = GUS::GOPredict::GoGraph::makeGoTermMap($self->getOldGoGraph(),
							   $self->getNewGoGraph());

    $self->log("Evolve Go Hierarchy: getting proteins to process");

    my $gusProteinIdResultSet = $self->getAdapter()->getGusProteinIdResultSet($proteinTableId, $oldGoVersion, 
									      $taxonId, $excludeAlgIds);
    my $proteinCounter = 0;
    
    while (my ($proteinId) = $gusProteinIdResultSet->fetchrow_array()){
	last if ($testNumber && $proteinCounter > $testNumber);

	$proteinCounter++;
	$self->_logProtein("evolveGoHierarchy", $proteinId, $proteinCounter);

	my $extent = GUS::GOPredict::GoExtent->new($self->getAdapter());

	my $originalAssociationGraph = $self->_getExistingAssociations($proteinId, $oldGoVersion, $extent, 
								       $proteinTableId);
	
	$self->_deleteCachedInstances($originalAssociationGraph) if $deleteInstances;

	my $newAssociationGraph = $originalAssociationGraph->evolveGoHierarchy($goTermMap,
									       $self->getNewGoGraph(),
									       $self->getOldGoGraph()->getGoSynMap());
	
	if ($newAssociationGraph){
	    $self->_scrubGraph($newAssociationGraph, $recache) unless $doNotScrub;

	    $newAssociationGraph->validateEvolution($self->getNewGoGraph(), $proteinId) if $validate;
	    $self->validateGusData($newAssociationGraph, $proteinId) if $validate;
	    $self->_prepareAndSubmitGusObjects($newAssociationGraph, $extent, $proteinTableId, $proteinId, $goTermMap, $goSynMap);
	}
	else {
	    $self->log("GoManager.evolveGoHiearchy:  did not create new Association Graph for protein $proteinId");
	}
    }

    return $proteinCounter;
}

#uses the Go Rule Engine and the results of similarities between proteins and motifs to 
#predict new Associations with the CBIL GO Function Predictor Algorithm

#param $cla: hash of bulky command line arguments for running queries
#            includes queryTableId, queryTablePkAtt, subjectDbList,
#            queryDbList, queryTaxonId, proteinTableId
sub applyRules{

    my ($self, $goVersion, $cla, $doNotScrub, $simsFilePath, $createNewSimsFile, $excludeInvocationIdList, 
	$testNumber, $validate) = @_;
    
    $self->log("beginning applyRules");

    my $counter = 0;
    my $doneAssems;

    
    my ($currentQueryId, $firstMotifId, $firstSimId, 
	$currentProteinId, $proteinId, $currentProteinInfoList);
    $self->initializeGoRuleEngine($goVersion, $cla);
    $self->initializeNewGoGraph($goVersion);
    $self->setNewGoVersion($goVersion);
    

    my $proteinSth = $self->getAdapter()->runProteinSimQuery($cla, $simsFilePath, $createNewSimsFile, 
							     $excludeInvocationIdList);
    $self->logVerbose("protein sim query done; processing first protein id");
    while (!$currentProteinId){  #get first query for which there is a translation
	($currentQueryId, $firstMotifId, $firstSimId) = $proteinSth->fetchrow_array();
	$currentProteinId = $self->getAdapter()->getTranslatedProteinId($currentQueryId);
    }
    push (@$currentProteinInfoList, ($firstMotifId, $firstSimId));
    
    while (my ($queryId, $motifId, $simId) = $proteinSth->fetchrow_array()){   #process the rest
	if ($testNumber && $counter == $testNumber){
	    last;
	}
	$proteinId = $self->getAdapter()->getTranslatedProteinId($queryId);
	$self->logVeryVerbose("applyRules: retrieved from result set query $queryId, with similarity $simId to motif $motifId; translation is $proteinId");
		       
	next if !$proteinId; #no translation for this query
	if ($proteinId != $currentProteinId){   #we are done getting info for currentProtein
	    
	    $self->_processProteinAndRules($currentProteinId, $cla, $currentProteinInfoList, $goVersion, $doNotScrub);
	    if ($counter % 1000 == 0){
		$self->log("applyRules: processing $currentProteinId; total processed: $counter");
	    }
	    $counter++;
	    $currentProteinId = $proteinId;
	    my $nextProteinInfoList;
	    push (@$nextProteinInfoList, ($motifId, $simId));
	    $currentProteinInfoList = $nextProteinInfoList;
	}
	else{          #keep getting info for current protein
	    
	    push (@$currentProteinInfoList, ($motifId, $simId));
	}
    }
    #process the last one
    $self->_processProteinAndRules($proteinId, $cla, $currentProteinInfoList, $goVersion, $doNotScrub, $validate);
    return $counter;
}

#retrieve given result set of proteins and deprecate them if they have only predicted instances.  Currently,
#this is run after running applyRules to deprecate all proteins that applyRules didn't hit.  Needs to be 
#updated to deprecate Associations that were not resubmitted after evolving the GO Hierarchy.
sub deprecateAssociations{

    my ($self, $raidList, $proteinTableId, $goVersion, $taxonId, $validate) = @_;
    $self->initializeNewGoGraph($goVersion);
    my $goGraph = $self->getNewGoGraph();
    my $counter = 0;
    my $proteinsToSkip = $self->getAdapter()->loadProteinsToSkip();
    my $proteinsToDeprecate = $self->getAdapter()->getProteinsToDeprecate($raidList, $proteinTableId, $taxonId);
    while (my ($proteinId) = $proteinsToDeprecate->fetchrow_array()){
	$self->logVerbose("deprecateAssociations: processing protein $proteinId");
	my $gusAssocIdResultSet = $self->getAdapter()->getGusAssocIdResultSet($proteinId,
									      $proteinTableId,
									      $goVersion);
	next if ($proteinsToSkip->{$proteinId});
	$counter++;
	while (my ($gusAssocId) = $gusAssocIdResultSet->fetchrow_array()){
	    my $gusAssoc = $self->getAdapter()->getGusAssociationFromId($gusAssocId);
	    my $assoc = GUS::GOPredict::Association->newFromGusAssociation($gusAssoc, $goGraph);
	    $assoc->deprecatePredictedInstances();
	    $assoc->deprecateIfInstancesDeprecated();
	    $assoc->updateGusObject();
	    $assoc->submitGusObject($self->getAdapter());
	    $self->getAdapter()->undefPointerCache();
	}
	$self->log("deprecator: done processing protein id $proteinId") if ($counter % 100 == 0);
	$self->logVerbose("deprecator: done processing protein id $proteinId") if ($counter % 100 != 0);
    }
    
    return $counter;
}

#scrub proteins without doing anything else to them (i.e., do not apply rules, do not evolve GO, etc.)
#probably only necessary if we ran evolve GO or apply rules but set $doNotScrub to be true then, a
#situation which should rarely happen.
sub scrubProteinsOnly{

    my ($self, $newGoVersion, $proteinTableId, $taxonId, $deleteInstances, $recacheInstances, $validate) = @_;
    $self->initializeNewGoGraph($newGoVersion);

    $self->setNewGoVersion($newGoVersion);
  
    my $counter = 0;

    my $gusProteinIdResultSet = $self->getAdapter()->getGusProteinIdResultSet($proteinTableId, $newGoVersion, $taxonId);
    my $extent = GUS::GOPredict::GoExtent->new($self->getAdapter());
  
    while (my ($proteinId) = $gusProteinIdResultSet->fetchrow_array()){
	$self->logVerbose("scrubProteinsOnly: processing protein id $proteinId");
	$self->getAdapter()->undefPointerCache();
	my $associationGraph = $self->_getExistingAssociations($proteinId, $newGoVersion, $extent, $proteinTableId);
	$self->logVeryVerbose("AssociationgGraph for protein $proteinId before scrubbing:\n" . $associationGraph->toString());
	$self->_deleteCachedInstances($associationGraph) if ($deleteInstances && $associationGraph);
	$self->_scrubGraph($associationGraph, $recacheInstances);
	$self->logVeryVerbose("AssociationgGraph for protein $proteinId after scrubbing:\n" . $associationGraph->toString());
	$associationGraph->validateScrub($proteinId) if $validate;
	$self->_prepareAndSubmitGusObjects($associationGraph, $extent, $proteinTableId, $proteinId, undef);
	$extent->empty();
	$counter++;
	
    }
    return $counter;
}

############################################################################################
############################  Private General Utility Methods ##############################
############################################################################################

#Gets existing associations for the given protein and returns them as an AssociationGraph. Retrieves
#only non-deprecated associations, but does not restrict associations by their GO release (the assumption
#being that any associations other than those to the current GO release have been deprecated).
sub _getExistingAssociations{

    my ($self, $proteinId, $goVersion, $extent, $proteinTableId) = @_;
    #returns a list of gus associations for given protein
    my $gusAssocIdResultSet = $self->getAdapter()->getGusAssocIdResultSet($proteinId, $proteinTableId, $goVersion);
    my $gusAssocIdList;
    while (my ($id) = $gusAssocIdResultSet->fetchrow_array()){
	$self->logVeryVerbose("getExistingAssociations: found association ID $id for protein $proteinId");
	push (@$gusAssocIdList, $id);
    }
    my $gusAssocObjectList;

    foreach my $assocId (@$gusAssocIdList){
	my $gusAssocObject = $extent->getGusAssociationFromId($assocId);
	push (@$gusAssocObjectList, $gusAssocObject);
    }

    my $goGraphToUse;

    #HACK: since this is a generic method, use the goGraph corresponding to the version passed in
    if ($goVersion == $self->getOldGoVersion()){
	$goGraphToUse = $self->getOldGoGraph();
    }
    else{
	$goGraphToUse = $self->getNewGoGraph();
    }
    my $associationGraph;
    if ($gusAssocObjectList){   #when applying rules, a protein might not have had any predictions made yet
	if (scalar @$gusAssocObjectList > 0){
	    $associationGraph = GUS::GOPredict::AssociationGraph->newFromGusObjects($gusAssocObjectList, $goGraphToUse);
	}
    }
    $gusAssocIdResultSet->finish();
    $self->logVeryVerbose("retrieved existing associations from database: " . $associationGraph->toString()) if $associationGraph;
    return $associationGraph;
}


#handles Adapter/Database interaction for submitting Associations in an AssociationGraph.  Uses
#extent to track whether a GUS Association Object exists for an Association or whether a new one
#must be made.  Ensures that the GUS Association Object to be submitted is correctly set according
#to the data presented in the Association.  Also handles any existing synonym associations; submits
#them as deprecated.  Also manages memory for AssociationGraphs and GUS objects.

#param $goTermMap:  undefined unless calling from evolveGoHierarchy
#param $goSynMap:   undefined unless calling from evolveGoHierarchy
sub _prepareAndSubmitGusObjects{

    my ($self, $associationGraph, $extent, $tableId, $proteinId, $goTermMap, $goSynMap) = @_;

    foreach my $association (@{$associationGraph->getAsList()}){
	
	my $gusAssociation = $association->getGusAssociationObject();
	
	if (!$gusAssociation){   #newly created primary assoc or newly created parent assoc 
                                 #that may have gus assoc object in extent
	
	    my $goTerm = $self->_getGoTermForExtent($association, $goTermMap);
	
	    $gusAssociation = $extent->getGusAssociationFromGusGoId($goTerm->getGusId());
	    if (!$gusAssociation){ #newly created primary assoc
		
		$self->_createGusAssociation($association, $tableId, $proteinId);
					    }
	    else{    #old parent assoc
		$association->setGusAssociationObject($gusAssociation);
	    }
	}

	$association->updateGusObject();
	$association->submitGusObject($self->getAdapter());
    }
    my $unevolvedAssociations = $associationGraph->getUnevolvedAssociations();
    #get all unevolved associations, which have been marked deprecated, update gus objects, and submit
    if ($unevolvedAssociations){
	foreach my $unevolvedAssociation (@$unevolvedAssociations){
	    if ($unevolvedAssociation){
		$self->log("searching for association in extent for gus go id " . $unevolvedAssociation->getGoTerm()->getGusId());
		my $unevolvedGoTerm = $self->_getGoTermForExtent($unevolvedAssociation, $goTermMap);
		my $unevolvedGusObject = $extent->getGusAssociationFromGusGoId($unevolvedGoTerm->getGusId());
		if ($unevolvedGusObject){
		    $unevolvedAssociation->updateGusObject();
		    $unevolvedAssociation->submitGusObject($self->getAdapter());
		}
	    }
	}
    }

    $self->logVeryVerbose("PrepareAndSubmitGusObjects: Association Graph right after submitting: " . $associationGraph->toString() . "\n");
    $self->getAdapter()->undefPointerCache();
    $associationGraph->killReferences();
}

#given an Association, gets its GO Term.  If the GO Term has evolved, gets the old GO Term
#so it can be used to check the extent.  If the GO Term was newly created in this release of 
#GO, just returns the newly created GO Term (so obviously there will be no existing GUS 
#in the extent).
sub _getGoTermForExtent{
    
    my ($self, $association, $goTermMap) = @_;
    
    my $goTerm;
    
    if (!$goTermMap){  #association has not been evolved, get its go term to check the extent
	$goTerm = $association->getGoTerm();
    }
    else { #association has been evolved, get its old go term to check the extent
	my $tempGoTerm = $association->getGoTerm();
	
	$goTerm = $goTermMap->{$tempGoTerm};
	$goTerm = $tempGoTerm if !$goTerm;    #go term did not exist in previous hierarchy
    }
    return $goTerm;
}

#post-processing method to ensure data consistency on associations for a given protein.
sub _scrubGraph{
    
    my ($self, $associationGraph, $recache) = @_;

    #dtb: switched this order to cache and deprecated before doing is not and defining
    $associationGraph->cachePrimaryInstances() if $recache; 
    
    $associationGraph->deprecateAssociations();

    $associationGraph->adjustIsNots();

    $associationGraph->setDefiningLeaves();

}

#Given an AssociationGraph, mark all non-primary instances as deleted.
sub _deleteCachedInstances{

    my ($self, $associationGraph) = @_;
   
    my $associations = $associationGraph->getAsList();
    foreach my $association (@$associations){

	my $instances = $association->getInstances();
	foreach my $instance (@$instances){
	    if (!$instance->getIsPrimary()){
		if ($instance->getGusInstanceObject()){ 
		    $instance->getGusInstanceObject()->markDeleted(0);
		}
	    }
	}
    }
}

sub _createGusAssociation{
    my ($self, $association, $tableId, $proteinId) = @_;
    my $existingGusAssocObject = $self->_checkIfDeprecated($association, $proteinId);
    if (!$existingGusAssocObject){
	$association->createGusAssociation($tableId, $proteinId);
    }
}

sub _checkIfDeprecated{
    
    my ($self, $association, $proteinId) = @_;
    my $deprecatedAssociations = $self->getDeprecatedAssociations();
    my $existingAssocObject;
    if ($deprecatedAssociations){
        $self->logVeryVerbose("GoManager.CheckIfDeprecated: checking if $proteinId and " . $association->getGoTerm()->getRealId() . " is in our list");
	my $gusAssocId = $deprecatedAssociations->{$proteinId}->{$association->getGoTerm()->getRealId()}->{assocId};   
	
	if ($gusAssocId){

	    $association->setDeprecated(0);
	    $self->logVeryVerbose("found deprecated association for go term " . $association->getGoTerm()->getRealId() . ", assoc id = $gusAssocId");
	    $existingAssocObject = $self->getAdapter()->getGusAssociationFromId($gusAssocId);
	    $association->setGusAssociationObject($existingAssocObject);
	    $association->updateGusObject();
	}
    }
    return $existingAssocObject;
}

sub _logProtein{
    my ($self, $methodName, $proteinId, $currentProteinCounter) = @_;

    $self->logVerbose("$methodName: processing protein $proteinId");
	
    if ($currentProteinCounter % 1000 == 0){
	$self->log("evolveGoHierarchy: processing $proteinId; total processed: $currentProteinCounter");
    }
}


############################################################################################
########################  Private Methods for Applying Rules ###############################
############################################################################################

#does the bulk of the work of applyRules; for the given protein, build an AssociationGraph
#of its existing Associations, use the GO Rule Engine to get a list of additional Associations
#for which the protein qualifies based on similarities to its motifs, and then add those
#Associations to the AssociationGraph in preparation for submitting.
sub _processProteinAndRules{
    
    my ($self, $currentProteinId, $cla, $currentProteinInfoList, $goVersion, $doNotScrub, $validate) = @_;
    
    my $extent = GUS::GOPredict::GoExtent->new($self->getAdapter());
    
    $self->logVerbose("processProteinAndRules: processing protein $currentProteinId");
    
    my $associationGraph = $self->_getExistingAssociations($currentProteinId, $goVersion, $extent, 
							   $cla->{proteinTableId});
    
    if ($associationGraph){
	$self->_scrubGraph($associationGraph, 1);
	$self->_deleteCachedInstances($associationGraph);
	$associationGraph->deprecateAllPredictedInstances();
    }

    my $newPredictedAssociationList = $self->_getNewAssociationsFromRules($currentProteinId, 
									  $currentProteinInfoList);
    foreach my $newAssoc (@$newPredictedAssociationList){
	$self->logVeryVerbose("found prediction for Association with GO Term " 
			      . $newAssoc->getGoTerm()->getRealId()) . "\n";
    }

    if ($associationGraph){
	$associationGraph->_addAssociations($newPredictedAssociationList, $self->getNewGoGraph());
    }
    
    else{
	$associationGraph = GUS::GOPredict::AssociationGraph->newFromAssocList($newPredictedAssociationList, 
									       $self->getNewGoGraph());
    }
    if ($associationGraph){

	if ($doNotScrub){   #always deprecate and recache
	    
	    $associationGraph->cachePrimaryInstances();
	    $associationGraph->deprecateAssociations();
	}
	else{
	    $self->logVeryVerbose("processProteinAndRules: AssociationGraph after rules applied, before scrubbing: " .
				  $associationGraph->toString() . "\n");
	    $self->_scrubGraph($associationGraph, 1);
	    $associationGraph->validateScrub($currentProteinId);
	    
	}

	$self->_prepareAndSubmitGusObjects($associationGraph, $extent, $cla->{proteinTableId},
					   $currentProteinId, undef);
	$self->_validateApply($associationGraph, $currentProteinId) if $validate;
    }
    else {
	$self->logVerbose("no existing associations or new predictions for $currentProteinId");
    }
    $self->getAdapter()->undefPointerCache();
}

#Middle-man function that feeds information to the GO Rule Engine and returns a list of new predicted
#associations to the given Protein.
sub _getNewAssociationsFromRules{

    my ($self, $proteinId, $proteinInfo) = @_;

    my $newAssocList;

    while (my $motifId = (shift(@$proteinInfo))){
	
	my $simId = shift(@$proteinInfo); 
	my $gusSimObject = $self->getAdapter()->getSimObjectFromId($simId);
	my $simScore = ($gusSimObject->getPvalueMant()*10**$gusSimObject->getPvalueExp());
	
	my $ruleList = $self->getGoRuleEngine()->getRuleSetAsListFromMotif($motifId, $simScore);
	while (my $returnedRuleInfo = shift(@$ruleList)){

	    my $ruleId = $returnedRuleInfo->{ruleId};
	    my $gusGoId = $returnedRuleInfo->{gusGoId};
	    my $ratio = $returnedRuleInfo->{ratio};
	    my $gusRuleObject = $self->getAdapter()->getRuleObjectFromId($ruleId);

	    my $goTerm = $self->getNewGoGraph()->getGoTermFromGusGoId($gusGoId);

	    &confess ("no go term for $gusGoId") if !$goTerm;

	    my $association = GUS::GOPredict::Association->newFromPrediction($goTerm, $gusRuleObject, $gusSimObject, $ratio);
	    $self->logVeryVerbose("predicted new association, go term: " . $association->getGoTerm()->getRealId() . ", sim object: $gusSimObject");	    
	    push(@$newAssocList, $association);
	}
    }
    return $newAssocList;
}


############################################################################################
############################  Object Initialization Methods  ###############################
############################################################################################

#initialize the internal GO Rule Engine using given input parameters (generally passed in
#from the plugin).

#param $cla:  A hash containing ratioCutoff and absoluteCutoff for determining similarity thresholds.
sub initializeGoRuleEngine{
    my ($self, $goVersion, $cla) = @_;

    my $goRuleEngine = GUS::GOPredict::GoRuleEngine->new();
    my $goRuleResultSet = $self->getAdapter()->getGoRuleResultSet($goVersion);
    $goRuleEngine->setGoRulesFromResultSet($goRuleResultSet);
    $goRuleEngine->setRatioCutoff($cla->{ratioCutoff});
    $goRuleEngine->setAbsoluteCutoff($cla->{absoluteCutoff});
    $self->setGoRuleEngine($goRuleEngine);
}

#initialize GO Graphs using data from adapter.
sub initializeOldGoGraph{

    my ($self, $goVersion, $goSynMap) = @_;
    if (!$self->getOldGoGraph()){
	my $goResultSet = $self->getAdapter()->getGoResultSet($goVersion); 
	
	my $oldGoGraph = GUS::GOPredict::GoGraph->newFromResultSet($goVersion, $goResultSet,
								   $self->getFunctionRootGoId(), $goSynMap);
	$self->setOldGoGraph($oldGoGraph);
    }
}

sub initializeNewGoGraph{

    my ($self, $goVersion) = @_;
    if (!$self->getNewGoGraph()){

	my $goResultSet = $self->getAdapter()->getGoResultSet($goVersion); 

	my $newGoGraph = GUS::GOPredict::GoGraph->newFromResultSet($goVersion, $goResultSet, 
								   $self->getFunctionRootGoId());
	$self->setNewGoGraph($newGoGraph);
    }
}

############################################################################################
##################################  Data Accessors  ########################################
############################################################################################


sub setAdapter{
    my ($self, $adapter) = @_;
    $self->{Adapter} = $adapter;
}

sub getAdapter{
    my ($self) = @_;
    return $self->{Adapter};
}
sub setOldGoGraph{
    my ($self, $goGraph) = @_;
    $self->{OldGoGraph} = $goGraph;
}

sub setNewGoGraph{
    my ($self, $goGraph) = @_;
    $self->{NewGoGraph} = $goGraph;
}

sub getOldGoGraph{
    my ($self) = @_;
    return $self->{OldGoGraph};
}

sub getNewGoGraph{
    my ($self) = @_;
    return $self->{NewGoGraph};
}

sub setOldGoVersion{
    my ($self, $goVersion) = @_;
    $self->{OldGoVersion} = $goVersion;
}

sub setNewGoVersion{
    my ($self, $goVersion) = @_;
    $self->{NewGoVersion} = $goVersion;
}

sub getOldGoVersion{
    my ($self) = @_;
    return $self->{OldGoVersion};
}

sub getNewGoVersion{
    my ($self) = @_;
    return $self->{NewGoVersion};
}

sub setFunctionRootGoId{
    my ($self, $newRootId) = @_;
    $self->{FunctionRootId} = $newRootId;
}

sub getFunctionRootGoId{
    my ($self) = @_;
    return $self->{FunctionRootId};
}

sub setGoRuleEngine{
    my ($self, $goRuleEngine) = @_;
    $self->{GoRuleEngine} = $goRuleEngine;
}

sub getGoRuleEngine{
    my ($self) = @_;
    return $self->{GoRuleEngine};
}

sub setDeprecatedAssociations{
    my ($self, $deprecatedAssociations) = @_;
    $self->{DeprecatedAssociations} = $deprecatedAssociations;
}

sub getDeprecatedAssociations{
    my ($self) = @_;
    return $self->{DeprecatedAssociations};
}

sub setVerbosityLevel{
    my ($self, $verbosityLevel) = @_;
    $self->{VerbosityLevel} = $verbosityLevel;
}

sub getVerbosityLevel{
    my ($self) = @_;
    return $self->{VerbosityLevel};
}

############################################################################################
############################  Validation Methods   #########################################
############################################################################################


sub validateGusData {
    my ($self, $associationGraph, $proteinId) = @_;
    
    foreach my $association (@{$associationGraph->getAsList()}){
	foreach my $instance (@{$association->getInstances()}){
	    if (!$instance->getGusInstanceObject() && $instance->getIsPrimary()){ #only checking newly created instances
		if (scalar @{$instance->getEvidence()} == 0){
		    print STDERR "Error: $proteinId association with GO Term " . $association->getGoTerm()->getRealId() . " has instance (LOE " . $instance->getLOEId() . ") with no evidence!\n";
		}
	    }		
	}
    }
}


#this goes as a function of GOManager because the Association Graph itself doesn't
#necessarily know what 'apply rules' is.
sub _validateApply{
    
    my ($self, $associationGraph, $proteinId) = @_;
    $associationGraph->validateInstanceManagement($proteinId);
    $self->validateGusData($associationGraph, $proteinId);
}


############################################################################################
############################  Logging Functionality  #######################################
############################################################################################

#these methods will execute if they are below the verbosity level defined when running GoPlugin.pm
sub log{

    my ($self, $msg) = @_;
    my $timeStamp = localtime;

    my $finalMsg = join("\t", $timeStamp, $msg);

    print STDERR "$finalMsg\n";
}

sub logVerbose{

    my ($self, $msg) = @_;
    
    if ($self->getVerbosityLevel() >= $verboseLevel){
	my $timeStamp = localtime;
	my $finalMsg = join("\t", $timeStamp, $msg);
	print STDERR "$finalMsg\n";
    }
}

sub logVeryVerbose{

    my ($self, $msg) = @_;
    
    if ($self->getVerbosityLevel() >= $veryVerboseLevel){
	my $timeStamp = localtime;
	
	my $finalMsg = join("\t", $timeStamp, $msg);
	
	print STDERR "$finalMsg\n";
    }
}





1;
