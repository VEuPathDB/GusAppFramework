package GUS::GOPredict::AssociationGraph;

use strict;
use Carp;
use GUS::GOPredict::Association;

################################# AssociationGraph.pm ####################################

# A module representing a set of Associations.  These Associations in turn keep track of # 
# the GO terms to which they are associated and also point to the associations to the    #
# respective parents and children of their GO Terms.  An AssociationGraph knows which    #
# association in its set is with the root of the Molecular Function branch of the Go     #
# Ontology, thus forming a complete graph that can be traversed or searched recursively. #
 
# Association Graphs are generally created by calling newBasicGraph on one association   #
# to create an initial graph consisting of all associations along all paths from the     #
# association to the root of the ontology, and then calling addAssociations on any       #
# other associations that are to be added to the graph.  

# Since associations all point to their children and parents, there are circular         #
# references in an AssociationGraph, so care must be taken to destroy them when they are #
# no longer in use with the killReferences method.  This must be done by any application #
# using an AssociationGraph as well as internally when calling addAssociations, which    #
# creates temporary AssociationGraphs that are used to add new Associations to an        #
# existing graph.

# Created: May 2003. Authors: Dave Barkan, Steve Fischer.                                #
# Last Modified: June 30, 2003, Dave Barkan; separated private methods and added         # 
# documentation.                                                                         #

##########################################################################################

my $unreviewedId = 0;
my $reviewedId = 1;
my $needsReviewId = 5; 

#ids in GUS of various LinesOfEvidence that are assigned to Instances.  A better way to implement
#would be to make them static somewhere.
my $obsoleteLOE = 5;
my $scrubberLOE = 6;
my $cbilPredictLOE = 3;


############################################################################################
#################################  Constructors ############################################
############################################################################################


#given $association, creates an association graph consisting of all associations along all paths
#from $association to the root.  Uses $goGraph to get these paths.
sub newBasicGraph{
    my ($class, $association, $goGraph) = @_;

    my $self = {};
    bless $self, $class;
    $self->_initializeDataStructures();

    $self->_growBasicGraph($association, $goGraph);

    $self->_setRoot($goGraph);

    return $self;
}

#given a list of associations, creates a new basic graph with the first to create a new graph
#and calls addAssociations with the rest to form a complete association graph.
#returns undef if $associationList is null or empty.
sub newFromAssocList{

    my ($class, $associationList, $goGraph) = @_;
    my $self = {};
    bless $self, $class;
    $self->_initializeDataStructures();

    
    return undef if !$associationList;
    if ($associationList){
	if ((scalar (@$associationList) == 0)){
	    return undef;
	}
    }

    $self = GUS::GOPredict::AssociationGraph->newBasicGraph(pop(@$associationList), $goGraph);

    $self->_addAssociations($associationList, $goGraph);

    return $self;
}

#given a list of gus association objects (currently GUS::Model::DoTS::GOAssociation), create an
#AssociationGraph reflecting these objects as a normal set of Association objects with correctly
#instantiated relationships.
sub newFromGusObjects {
    my ($class, $gusObjectList, $goGraph) = @_;
    my $self = {};
    bless $self, $class;
    $self->_initializeDataStructures();
    my $associationsHash =
	&GUS::GOPredict::Association::makeAssociationHashFromGusObjects($gusObjectList, $goGraph);
    my @associationList = values %$associationsHash;
    
    $self = GUS::GOPredict::AssociationGraph->newBasicGraph(pop(@associationList), $goGraph);
    $self->_addAssociations(\@associationList, $goGraph);
    return $self;
}

############################################################################################
#################################  Public methods ##########################################
############################################################################################


#For each Association in $self, replace the existing GO Term object with one representing the GO Term
#with an updated ID in GUS reflecting a new release of the GO Hierarchy.  This involves resolving 
#GO Terms that have become obsolete and those that have been 'merged' with other GO IDs as synonyms.
#All Associations in the AssociationGraph are upgraded to new GO Terms, but the return value is a new
#AssociationGraph consisting of only the primary Associations (see definition in Association.pm) in the
#old AssociationGraph and all associations along their paths to the root.  Note that this means that 
#non-primary Associations will not be returned (and generally not resubmitted to the database when
#running in conjunction with GUS) unless they are also present in the new AssociationGraph.  Post-processing
#is necessary to deprecate these old associations, as well as Associations whose GO Terms have become 
#synonyms to other GO Terms.  The reason that non-primary Associations have their GO Terms upgraded 
#(or 'evolved') is to correctly handle those that may have descendant GO Terms become obsolete.

#param $goTermMap:  A data structure consisting of a map from GO Term objects for one release of the
#GO Hierarchy to the corresponding GO Term object for another release of the GO Hierarchy, and vice-versa.

#param $goSynMap:  A hash where the keys are GO Terms that exist as normal GO Terms in the old Hierarchy
#but only as synonyms in the new Hierarchy, and the values are the normal GO Terms to which the keys are 
#synonyms.  Both the keys and the values of the hash are GO Terms that exist in the old Hierarchy.

sub evolveGoHierarchy{
    my ($self, $goTermMap, $newGoGraph, $goSynMap) = @_;
    
    my $newAssociationGraph;

    $self->_upgradeGoTermGusIds($goTermMap, $goSynMap, $newGoGraph);

    $self->_upgradeObsolete();

    my $strongAssocList = $self->_findPrimaryAssociations($newGoGraph);
    
    if (scalar @$strongAssocList){
	$newAssociationGraph = GUS::GOPredict::AssociationGraph->newBasicGraph(pop(@$strongAssocList), $newGoGraph);

	$newAssociationGraph->_addAssociations($strongAssocList, $newGoGraph);
	$self->_processUnevolvedAssociations($newAssociationGraph);
    }
    
    else { print STDERR "no strong associations in this graph\n";}

    return $newAssociationGraph;
}

#return a list of Associations that were not carried over to this AssociationGraph when it was
#evolved from an AssociationGraph with a old GO Hierarchy.   These Associations
#should be deprecated so this is a handy method to prepare for that operation.
sub getUnevolvedAssociations{
    my ($self) = @_;
    return $self->{UnevolvedAssociations};
}


#updates all Associations in the AssociationGraph so that the contained GUS Association objects have the 
#same values as the Associations themselves.  Creates new GUS Instances where necessary and adds them as
#children (i.e. creates a foreign key reference from the GUS Instance to the GUS Association).
sub updateGusObjects{
    
    my ($self) = @_;
    my $associationList = $self->getAsList();
    foreach my $association (@$associationList){
	$association->updateGusObject();
    }
}

#return a list of all Associations in the AssociationGraph; handy for other methods that iterate over the 
#Associations without regard to their parent/child relationships.
sub getAsList{
    my ($self) = @_;
   
    my $assoc = $self->{AssociationHash};
    my @x = values %$assoc;
    
    return \@x;
}

#for each Association in the AssociationGraph, deprecates all predicted instances.
sub deprecateAllPredictedInstances{
    my ($self) = @_;
    foreach my $association (@{$self->getAsList()}){
	$association->deprecatePredictedInstances();
    }
}

#for each Association in the AssociationGraph, deprecates the Association if it has no non-deprecated 
#Instances
sub deprecateAssociations{
    my ($self) = @_;
    foreach my $association (@{$self->getAsList()}){
	$association->deprecateIfInstancesDeprecated();
    }
}


#a post-processing 'scrubber' method, this sets the value of the 'is not' flag in the Association to
#reflect its place in the rest of the Hierarchy.  This takes place according to the following rules:
#1. If a primary Association is set to 'is' (i.e., not 'is_not') but has an Ancestor Association that
# is set to 'is not', then the 'is' association also gets set to 'is not'.
#2. The association gets an Instance reflecting this change.  
#3. If this Association was manually reviewed, it gets another Instance
#   indicating needs to be rereviewed.
#4. Instances in #2 and #3 are not created if $doNotCreateNewInstances is set   
sub adjustIsNots{
    my ($self, $doNotCreateNewInstances) = @_;
    $self->getRoot()->initializeOnIsNotPath();
    foreach my $association (@{$self->getAsList()}){
	$association->setIsNotFromPath($doNotCreateNewInstances);
    }
}

#a post-processing 'scrubber' method, this sets the value of the 'defining' flag in all Associations 
#that have no children or do not have children that are 'is', primary, not obsolete, and not deprecated.
#Generally, a defining Association will be the lowest one in each branch of the Associations that comprise
#the graph.
sub setDefiningLeaves{
    my ($self) = @_;
    $self->getRoot()->determineAndSetDefining();

}

#A post-processing 'scrubber' method, this copies all primary instances for each primary Association Ap
# to each parent Association B according to the following rules:
#1. Ap is not obsolete.
#2. The primary Instance is not deprecated, predicted to be 'is not' (except in one case, #3)
#   or reflects an Instance created by another 'scrubber' method
#3. If the instance to be propogated is 'is not', then it is only propogated to B if B has no other 
#   descendants that are 'is.'  In this case, B is set to 'is not' as well.  
#4. Once cached, the Instance is no longer primary.  It gets its own GUS Instance object and has no Evidence. 
sub cachePrimaryInstances{
    my ($self) = @_;
    foreach my $association (@{$self->getAsList()}){
#	print STDERR "AssociationGraph.cachePrimaryInstances: caching instances for assoc " . $assoc->getGoTerm()->getGoId() . "\n";
	if ($association->isPrimary() && !$association->getGoTerm()->isObsolete()){
	    my $instanceList;
	    foreach my $instance (@{$association->getInstances()}){
		if ($instance->getIsPrimary() &&
		    !$instance->isDeprecated() &&
		    !($association->getIsNot() && $instance->getLOEId() == $cbilPredictLOE)){
	#	    print STDERR "\tadding instance with loe id " . $instance->getLOEId() . " to the list\n":
		    push (@$instanceList, $instance);
		} 
	    }
	    my $instanceInfoHash;
	    $instanceInfoHash->{$association->getGoTerm()->getGusId()} = $instanceList;
	    foreach my $parent (@{$association->getParents()}){
		$parent->propogateInstances($instanceInfoHash);
	    }
	}
    }
    foreach my $association (@{$self->getAsList()}){
	$association->cacheDescendantInstances();
    }
}

#    foreach my $instance (@{$association->getInstances()}){
#		if ($instance->getIsPrimary() &&
#		    !$instance->isDeprecated() &&
#		    !($association->getIsNot() && $instance->getLOEId() == $cbilPredictLOE) && 
#		    !($instance->getLOEId() == $obsoleteLOE) && 
#		    !($instance->getLOEId() == $scrubberLOE)){
#		    push (@$instanceList, $instance);
#		}
	

#if any association has no instances at all; create one non-primary instance for it
sub createNonPrimaryInstances{

    my ($self, $loeId) = @_;
    my $associations = $self->getAsList();
    foreach my $association (@$associations){
	$association->createNonPrimaryInstance($loeId);
    }
}

#given a rejected motif, find all associations that in this graph that have been predicted with
#rules from this motif (and no other rules from good motifs) and mark them as 'is_not'
#param $rejectedMotifVersion: external database release id of motif to be rejected
#param $rejectedMotifId:      source id of motif to be rejected
#param $gusMotifObject:       object in DoTS.RejectedMotif that will be used as evidence
#param $allRejectedMotifs:    map containing unique identifiers (database release ids and source ids)
#                             representing all rejected motifs in the database.
#param $evidenceMap:          map going from GO Ids in this AssociationGraph to the motifs whose rules
#                             were used to predict their associations.  Includes good and rejected motifs.
sub processRejectedMotif{

    my ($self, $rejectedMotifVersion, $rejectedMotifId, $gusMotifObject, $allRejectedMotifs, $evidenceMap) = @_;
    my $processedAssocMap = $self->findGoodAssociations($rejectedMotifId, $allRejectedMotifs, $evidenceMap);
    
    foreach my $processedAssoc (keys %$processedAssocMap){
#	print STDERR "processRejectedMotif, done finding good assoc:: " . $processedAssoc . " is a good assoc\n";
    }
    $self->findBadAssociations($rejectedMotifVersion, $rejectedMotifId, 
			       $processedAssocMap, $evidenceMap, $gusMotifObject);

    $processedAssocMap = {};
    undef $processedAssocMap;
}

#finds all Associations that have been predicted with non-rejected motifs and adds their GO Ids to 
#the keys of $processedAssocMap.  Also adds the GO Ids of all their ancestors to this map.
sub findGoodAssociations{

    my ($self, $rejectedMotifId, $allRejectedMotifs, $evidenceMap) = @_;
    my $processedAssocMap;
    foreach my $realGoId (keys %$evidenceMap){
	
	next if ($processedAssocMap->{$realGoId});
	my $assoc = $self->find($realGoId);
	&confess ("no association in this graph for real go Id " . $realGoId) if !$assoc;
#	print STDERR "AssocGraph.findGoodAssociation: processing assoc $realGoId\n";

	if (!$assoc->getIsNot() && $assoc->hasGoodEvidence($evidenceMap, $allRejectedMotifs)){
	
#	    print STDERR "AssocGraph.findGoodAssociation: assoc $realGoId is good, marking its parents\n";
	    my $assocParents = $assoc->getParents();
	    foreach my $parent (@$assocParents){
		#initialize recursive method on each parent
		$processedAssocMap = $parent->markAncestorsGoodEvidence($processedAssocMap);
	    }
	    $processedAssocMap->{$realGoId} = 1;	
	}
    }
    foreach my $processedAssoc (keys %$processedAssocMap){
#	print STDERR "findGoodAssociations, done everything:: " . $processedAssoc . " is a good assoc\n";
    }
    return $processedAssocMap;
}

#For any Association in this graph that has been predicted only with rules that come from rejected motifs,
#mark the Association as 'is_not' and do the same for all ancestors of this association that do not have
#descendants that come from a good motif (the GO Ids of which are listed in $processedAssocMap).
sub findBadAssociations{

    my ($self, $rejectedMotifVersion, $rejectedMotifId, $processedAssocMap, $evidenceMap, $gusMotifObject) = @_;
    my $allAssoc = $self->getAsList();
    foreach my $processedAssoc (keys %$processedAssocMap){
#	print STDERR "findBadAssoc: " . $processedAssoc . " is a good assoc\n";
    }
    foreach my $assoc (@$allAssoc){
	my $realGoId = $assoc->getGoTerm()->getRealId();
#	print STDERR "AssocGraph.findBadEvidence: checking $realGoId on version $rejectedMotifVersion and motif $rejectedMotifId\n";
	if ($evidenceMap->{$realGoId}->{$rejectedMotifVersion}->{$rejectedMotifId}){
	#    print STDERR "AssocGraph.findBadEvidence: bad evidence for assoc $realGoId\n";
	    #method will first check to make sure we haven't processed this already (which would mean that
	    #it has good motifs in addition to $rejectedMotifId)
	    $processedAssocMap = $assoc->processRejectedMotif($processedAssocMap, $rejectedMotifVersion, $rejectedMotifId, 
							      $gusMotifObject);
	}
    }
}


#destroys all parent/child references for the Associations in this AssociationGraph to prevent memory leaks.
sub killReferences{
    my ($self) = @_;
    my $associations = $self->getAsList();
    foreach my $association (@$associations){
	$association->killReferences();
    }
}

#given a $realGoId of a GO Term for some Association in the AssociationGraph, return that Association.
sub find{
    my ($self, $realGoId) = @_;
    return $self->{AssociationHash}->{$realGoId};
}

#return the Association whose GO Term is the root of the GO Molecular Function branch.
sub getRoot(){
    my ($self) = @_;
    return $self->{RootAssociation};
}

#print toString() information on all Associations in the AssociationGraph.  This gives all the information
#for each association as well as an indication of where it is in the Hierarchy.
sub toString(){
    my ($self) = @_;

    return "$self:\n" . $self->getRoot()->toString("\t");
}

############################################################################################
##############################  Validation methods #########################################
############################################################################################

#validation method run on an AssociationGraph after the following methods have taken place:
#evolveGoHierarchy, cachePrimaryInstances, deprecateAssociations, adjustIsNots, setDefiningLeaves.
#If an invalid state is detected, prints the name of the protein and the error to STDERR
sub validateEvolution{

    my ($self, $currentGoGraph, $proteinId) = @_;
    $self->_validateAllNewGoVersion($currentGoGraph, $proteinId);
    $self->_validateIsNot($proteinId);
#    $self->_validateDefining();
    $self->_validateCacheIsNot($proteinId);
    $self->_validateAllHaveInstances($proteinId);
    $self->_validateNoDeprecated($proteinId);
    $self->_validateNoPrimaryOldAssoc($currentGoGraph, $proteinId);
    $self->_validateCachedInstancesDeleted($proteinId);
    print STDERR "AssociationGraph.validateEvolution: done\n";
}

sub validateApplyRules{

    my ($self, $proteinId) = @_;
    
}

sub validateScrub{

    my ($self, $proteinId) = @_;
    $self->_validateIsNot($proteinId);
    $self->_validateCacheIsNot($proteinId);
    $self->_validateAllHaveInstances($proteinId);

}

sub validateInstanceManagement{
    my ($self, $proteinId) = @_;
    my $allAssoc = $self->getAsList();
    foreach my $assoc (@$allAssoc){
	my $instances = $assoc->getInstances();
	foreach my $instance (@$instances){
	    if ($instance->getGusInstanceObject()){
		
		if ($instance->getIsPrimary() && !$instance->isDeprecated() && $instance->getLOEId() == $cbilPredictLOE){
		    print STDERR "Invalid data for protein $proteinId: " . $assoc->getGoTerm()->getGusId() . " has a primary instance that was not deprecated\n";
		}
	    }
	}
    }
    $self->_validateCachedInstancesDeleted($proteinId);
}

#For a given GO Graph, checks to make sure that all Associations in this
#AssociationGraph are in the GO Graph
sub _validateAllNewGoVersion{

    my ($self, $currentGoGraph, $proteinId) = @_;
    my $allAssoc = $self->getAsList();
    foreach my $assoc (@$allAssoc){
	if (!$currentGoGraph->getGoTermFromGusGoId($assoc->getGoTerm()->getGusId())){
	    print STDERR "Invalid data for protein $proteinId:  " . $assoc->getGoTerm()->getGusId() . " is in this AssociationGraph but is not in the latest GO Hiearchy!\n";
	}
    }
}

#initializer for recursive Association->validateIsNot; starts at the root of the graph.
sub _validateIsNot{

    my ($self, $proteinId) = @_;
    $self->getRoot()->validateIsNot($proteinId, 0);
}

#makes sure every association is defining that should be (needs completion)
sub _validateDefining{
    my ($self, $proteinId) = @_;
    my $allAssoc = $self->getAsList();
    foreach my $assoc (@$allAssoc){
	my $children = $assoc->getChildren();
	if (scalar @$children == 0){
	    if (!$assoc->getDefining == 1){
	    }
	}
    }
}

#makes sure that if an Association has a non-primary instance that is set to is_not,
#then all of its descendants are also is_not
sub _validateCacheIsNot{
    my ($self, $proteinId) = @_;
    my $allAssoc = $self->getAsList();
    foreach my $assoc (@$allAssoc){
	if (!$assoc->isPrimary()){
	    my $instances = $assoc->getInstances();
	    foreach my $instance (@$instances){
		if (!$instance->getIsPrimary() && $instance->getIsNot()){
		    if (!$assoc->hasNoIsDescendants()){
			print STDERR "Invalid data for protein $proteinId:  " . $assoc->getGoTerm()->getGusId() . " has a cached 'is_not' instance but has descendants set to 'is'\n";
		    }
		    next;
		}
	    }
	}
    }
}

#ensures that no unevolved Associations are primary, or if they are, that they are only synonyms
#that don't exist in the new hierarchy.
sub _validateNoPrimaryOldAssoc{

    my ($self, $currentGoGraph, $proteinId) = @_;
    my $oldAssocs = $self->getUnevolvedAssociations();
    foreach my $oldAssoc (@$oldAssocs){
	if ($oldAssoc->isPrimary()){
	    if ($currentGoGraph->getGoTermFromRealGoId($oldAssoc->getGoTerm()->getRealId())){
		print STDERR "Invalid data for protein $proteinId:  Did not evolve primary Association " . $oldAssoc->getGoTerm()->getGusId() . "\n";
	    }
	}
    }
}

#makes sure every Association has at least one instance.
sub _validateAllHaveInstances{
    
    my ($self, $proteinId) = @_;
    my $allAssoc = $self->getAsList();
    foreach my $assoc (@$allAssoc){
	my $instances = $assoc->getInstances();
	if (scalar @$instances == 0 && !$assoc->getGoTerm()->getIsObsoleteRoot()){
	    print STDERR "Invalid data for protein $proteinId:  " . $assoc->getGoTerm()->getGusId() . " has no instances!\n";
	    if (!$assoc->isPrimary() && scalar @{$assoc->getChildren()} == 0){
		print STDERR "\t but it is not primary and has no children\n";
	    }
	    if ($assoc->getReviewStatusId() == $reviewedId){
		print STDERR "\t but it has been reviewed\n";
	    }
	    if ($assoc->getGoTerm()->getRealId eq 'GO:0003674' && scalar @{$assoc->getChildren()} == 1){
		print STDERR "\t but it is the root and has only one child\n";
	    }
	}
    }

}

#makes sure there are no deprecated Associations in this graph; evolve does not deprecate any Associations
#except those that were not carried over to the new graph.
sub _validateNoDeprecated{

    my ($self, $proteinId) = @_;
    my $allAssoc = $self->getAsList();
    foreach my $assoc (@$allAssoc){
	if ($assoc->isDeprecated()){
	    print STDERR "Invalid data for protein $proteinId:  " . $assoc->getGoTerm()->getGusId() . " is deprecated even though all we did was evolve!\n";
	}
    }

}

#ensures that all cached instances were deleted before any more processing has occurred.
#Note: assumes that any newly created cached instances have not created a GUS Instance yet,
#so this will fail if that assumption is false.  Perhaps it would be better to run this
#as a global query
sub _validateCachedInstancesDeleted{
    
    my ($self, $proteinId) = @_;
    my $allAssoc = $self->getAsList();
    foreach my $assoc (@$allAssoc){
	my $instances = $assoc->getInstances();
	foreach my $instance (@$instances){
	    if ($instance->getGusInstanceObject()){
		if (!$instance->getIsPrimary() && !$instance->isDeprecated() && $instance->getGusInstanceObject()->isMarkedDeleted()){
		    print STDERR "Invalid data for protein $proteinId:  " . $assoc->getGoTerm()->getGusId() . " has a cached instances that was not deleted\n";
		}
	    }
	}
    }
}


############################################################################################
#################################  Private methods #########################################
############################################################################################

# grow each Association into its own graph, and then graft each graph.
sub _addAssociations{
    my ($self, $associationList, $goGraph) = @_;
    my @tempAssocGraphs;

    foreach my $association (@{$associationList}) {
	&confess ("no go term for assoc that I am trying to add!") if !$association->getGoTerm();
	#create a new graph for this associatoin
        my $tempAssocGraph = GUS::GOPredict::AssociationGraph->newBasicGraph($association, $goGraph);
	
	$self->_graftAssociation($association);
	#track all temporary graphs used when adding this association list
	push (@tempAssocGraphs, $tempAssocGraph);
	
    }
    #get rid of all temporary graphs to free up memory
    foreach my $assocGraph (@tempAssocGraphs){

	$self->_clearFloatingAssociations($assocGraph);
    }
}

#examine another graph and see if it has Associations that are not in $self.  For each such
#Association, kill all of its references (necessary for garbage collection)
sub _clearFloatingAssociations{
    my ($self, $tempAssocGraph) = @_;

    my $assocHash = $self->_createAssocHash();
    my $tempsAssociations = $tempAssocGraph->getAsList();
    foreach my $tempsAssociation (@$tempsAssociations){

	if (!$assocHash->{$tempsAssociation}){
	    $tempsAssociation->killReferences();
	}
    }
}

#returns a hash where the keys are all Association in $self, and the values are 1
sub _createAssocHash{

    my ($self) = @_;
    my $assocHash;
    my $assocs = $self->getAsList();

    foreach my $assoc (@$assocs){
	$assocHash->{$assoc} = 1;
    }
    return $assocHash;
}

#recursive method called from newBasicGraph; it actually does the work of creating new
#Associations that lead up to the root from the given Association.  Creates relationships
#between parents and children as necessary.
sub _growBasicGraph {
    my ($self, $association, $goGraph) = @_;

    &confess ("association is null") unless $association;

    my $goTerm = $association->getGoTerm();
    &confess ("go term is null for " . $association->toString()) if !$goTerm;
    $self->{AssociationHash}->{$goTerm->getRealId()} = $association;
    
    my $goParents = $goTerm->getParents();
    foreach my $goParent (@$goParents) {
	
	my $parent = $self->find($goParent->getRealId());
	if (!$parent) {
	    $parent = GUS::GOPredict::Association->new($goParent);
	    
	    $self->_growBasicGraph($parent, $goGraph);
	}

	$parent->addChild($association); 
    }
}

#initializer for recursive method on Associations that makes Associations primary if they 
#have children that have become obsolete in the new GO Hierarchy.
sub _upgradeObsolete{
    my ($self) = @_;
    my $rootAssociation = $self->getRoot();
    $rootAssociation->inheritStrength();
}

#upgrades all associations' GO Terms to new GUS Id's in the new GO Hierarchy.
#Handles synonyms according to the following rules:
#1. If the GO Term S1 that evolves to a synonym was in the old AssociationGraph along with the 
#   GO Term G1 to which S1 will be a synonym, then schedule the Association to S1 to be deprecated.
#2. If S1 is in the old AssociationGraph but G1 is not, then upgrade S1 to be the GO Term
#   to which G1 would have been upgraded.
sub _upgradeGoTermGusIds{
    my ($self, $goTermMap, $goSynMap, $newGoGraph) = @_;

    my $list = $self->getAsList();
    foreach my $association (@$list){
	my $oldGoRealId = $association->getGoTerm()->getRealId();
	my $newGoTerm = $goTermMap->{$association->getGoTerm()};
	
	if (!$newGoTerm){
	    if ($goSynMap->{$oldGoRealId}){  #assoc to go synonym, handle accordingly
		my $altAssoc = $self->find($goSynMap->{$oldGoRealId});
		if ($altAssoc){  #Synonym Rule 1 above
		    if ($association->isPrimary()){ #give alt assoc another instance indicating possible state change
			my $instance = GUS::GOPredict::Instance->new();
			$instance->setIsNot($altAssoc->getIsNot());
			$instance->setIsPrimary(1);
			$instance->setLOEId($scrubberLOE);
			$instance->setDeprecated(0);
			if ($altAssoc->getReviewStatusId() != $unreviewedId){
			    $instance->setReviewStatusId($needsReviewId);
			    $association->setReviewStatusId($needsReviewId);
			}
			else {
			    $instance->setReviewStatusId($unreviewedId);
			    $association->setReviewStatusId($unreviewedId);
			}
			$altAssoc->addInstance($instance);
			my $synonymComment = GUS::Model::DoTS::Comments->new();
			$synonymComment->setCommentString("GO Term for this Association is now a synonym with old GO Term " . $oldGoRealId);
		    }

		
		    $association->setDeprecated(1);
#		    $self->_addSynonymAssociation($association);
		    #dtb: this will be taken care of in processUnevolvedAssociations
		    
		    next;
		}
		else{  #Synonym Rule 2 above
		    $newGoTerm = $newGoGraph->getGoTermFromRealGoId($goSynMap->{$oldGoRealId});
		}
	    }
	    else{
		&confess("no go term for " . $association->toString()) unless $newGoTerm;
	    }
	}  
	$association->setGoTerm($newGoTerm);
    }
}

#finds all Primary Associations in the Graph, removes their relationships to parents and children,
#and returns all such associations in a list.  Used in evolving the GO Hierarchy.
sub _findPrimaryAssociations{
    my ($self, $newGoGraph) = @_;

    my @strongAssocList;
    my $list = $self->getAsList();
    foreach my $association (@$list){
	my $goTerm = $association->getGoTerm();
#	print STDERR "not primary " if !$association->isPrimary();
#	print STDERR "deprecated " if $association->isDeprecated();
#	print sTDERR "obsolete " if  $goTerm->isObsolete() || $goTerm->getIsObsoleteRoot()){  
	if (($association->isPrimary() && !$association->isDeprecated()) || $goTerm->isObsolete() || $goTerm->getIsObsoleteRoot()){  

	    $association->killFamily();
	    push(@strongAssocList, $association);
	}
    }
    return \@strongAssocList;
}

#finds the Association with the GO Term that is the root of the Molecular Function Branch
#of the GO Hierarchy and sets it to be the root of $self
sub _setRoot{

    my ($self, $goGraph) = @_;
    
    my $rootGoId = $goGraph->getRootTerm()->getRealId();
    &confess ("no root go id!") if !$rootGoId;
    
    my $rootAssociation = $self->find($rootGoId);
    &confess ("no association for root go id!") if !$rootAssociation;
    
    $self->{RootAssociation} = $self->find($rootGoId);
}


#recursive function that takes an Association that has its path to the root instantiated
#and merges it with $self, adding Associations along the path as necessary.  Handles
#copying instances and replacing the parent links from $association to the correct
#parent in $self if the parent is present in $self.

#param $association: the Association that is currently being added to $self.
#param $child: the Association from the previous call of _graftAssociation. 
sub _graftAssociation{

    my ($self, $association, $child) = @_;

    my $realGoId = $association->getGoTerm()->getRealId();
    &confess ("no go term for assoc") if !$association->getGoTerm();

    #determine if the Association to be grafted already exists in $self
    my $prevAssociation = $self->find($realGoId);

    #if the Association object already exists in $self, return here.  (Note: is this redundant with AlreadyAdded below?)
    if ($prevAssociation == $association && $prevAssociation->getGoTerm()->getRealId() eq $association->getGoTerm()->getRealId()) {
	return;
    }

    #if the Association already exists in $self, and $child's link has not been made with it, then make the link
    #This replaces the parent of $child from $association to the equivalent Association in $self 
    if ($child && $prevAssociation) {
	$child->replaceParent($prevAssociation);
    }
    #AlreadyAdded: keying on hash reference of association and go id of association
    #used to key only on hash reference but that was wrong because sometimes that 
    #hash reference would be used and then deallocated, but still be in AlreadyAdded
    if ($self->{AlreadyAdded}->{$association->getGoTerm()->getRealId()}->{$association}){

	return;
    }
    $self->{AlreadyAdded}->{$association->getGoTerm()->getRealId()}->{$association} = 1;

    my $needsLink;
    if ($prevAssociation){   #copy instances and bits to be correct

	my $instances = $association->getInstances();
	foreach my $instance (@$instances){
	    $prevAssociation->addInstance($instance);
	}

	if ($association->getGusAssociationObject()){ #then prev was created as a parent of another Association
    	    $prevAssociation->absorbStateFromAssociation($association);
	}
	$needsLink = undef;
    }
    else{
	$self->{AssociationHash}->{$realGoId} = $association;
        $needsLink = $association;
    }
    my $parents = $association->getParents();
    foreach my $parent(@$parents){
	$self->_graftAssociation($parent,$needsLink);
    }
}

#instantiate UnevolvedAssociations to be an empty array.
sub _initializeDataStructures{
    my ($self) = @_;
    $self->{UnevolvedAssociations} = [];
}

#for each Association that is in $self but not $newAssociationGraph, copy the Association
#to $newAssociationGraph's list of Unevolved Associations and deprecate it.
sub _processUnevolvedAssociations{
    my ($self, $newAssociationGraph) = @_;
    
    my $allAssociations = $self->getAsList();
    foreach my $assoc (@$allAssociations){
	if (!$newAssociationGraph->find($assoc->getGoTerm()->getRealId())){
#	    print STDERR "AssociationGraph.processUnevolvedAssociations: assoc with GO Term " . $assoc->getGoTerm()->getRealId() . " is not being evolved and should be deprecated\n";
	    $assoc->setDeprecated(1);
	    $newAssociationGraph->_addUnevolvedAssociation($assoc);
	}
    }
}

#adds an Unevolved Association to the internal array belonging to $self.
sub _addUnevolvedAssociation{
    
    my ($self, $oldAssoc) = @_;
    push (@{$self->{UnevolvedAssociations}}, $oldAssoc);
}


1;
