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


#for each Association in $self, replace the existing GO Term object with one representing the GO Term
#with an updated ID in GUS reflecting a new release of the GO Hierarchy.  This involves resolving 
#GO Terms that have become obsolete and those that have been 'merged' with other GO IDs as synonyms.
#All Associations in the AssociationGraph are upgraded to new GO Terms, but the return value is a new
#AssociationGraph consisting of only the primary Associations (see definition in Association.pm) in the
#old AssociationGraph and all associations along their paths to the root.  Note that this means that 
#non-primary Associations will not be returned (and generally not resubmitted to the database when
#running in conjunction with GUS) unless they are also present in the new AssociationGraph.  Post-processing
#is necessary to deprecate these old associations.  The reason that non-primary Associations have
#their GO Terms upgraded (or 'evolved') is to correctly handle those that may have descendant GO Terms
#become obsolete.

#param $goTermMap:  A data structure consisting of a map from GO Term objects for one release of the
#GO Hierarchy to the corresponding GO Term object for another release of the GO Hierarchy, and vice-versa.

#param $goSynMap:  A hash where the keys are GO Terms that exist as normal GO Terms in the old Hierarchy
#but only as synonyms in the new Hierarchy, and the values are the normal GO Terms to which the keys are 
#synonyms.  Both the keys and the values of the hash are GO Terms that exist in the old Hierarchy.

sub evolveGoHierarchy{
    my ($self, $goTermMap, $newGoGraph, $goSynMap) = @_;
    
    $self->_upgradeGoTermGusIds($goTermMap, $goSynMap, $newGoGraph);

    $self->_upgradeObsolete();

    my $strongAssocList = $self->_findPrimaryAssociations($newGoGraph);

    my $newAssociationGraph = GUS::GOPredict::AssociationGraph->newBasicGraph(pop(@$strongAssocList), $newGoGraph);

    $newAssociationGraph->_addAssociations($strongAssocList, $newGoGraph);

    $self->_processSynonymAssociations($newAssociationGraph);
        
    return $newAssociationGraph;
}

#return a list of Associations that have GO Terms that are now only synonyms.  These Associations
#should be deprecated so this is a handy method to prepare for that operation.
sub getSynonymAssociations{
    
    my ($self) = @_;
    return $self->{SynonymAssociations};
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
#1. If a primary Association is set to 'is' (i.e., not 'is_not') but its only path(s) to the root is through
#   an 'is not' Association, then the 'is' Association is set to 'is not'.  
#2. The association gets an Instance reflecting this change.  
#3. If this Association was manually reviewed, it gets another Instance
#   indicating needs to be rereviewed.   
sub adjustIsNots{
    my ($self) = @_;
    $self->getRoot()->initializeOnIsPath();
    foreach my $association (@{$self->getAsList()}){
	$association->setIsNotFromIsPath();
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
#2. The primary Instance is not deprecated, predicted to be 'is not', or reflects an Instance created by 
#   another 'scrubber' method
#3. If the instance to be propogated is 'is not', then it is only propogated to B if B has no other 
#   descendants that are 'is.'  In this case, B is set to 'is not' as well.  
#4. Once cached, the Instance is no longer primary.  It gets its own GUS Instance object and has no Evidence. 
sub cachePrimaryInstances{
    my ($self) = @_;
    foreach my $association (@{$self->getAsList()}){
	
	if ($association->isPrimary() 
	    && !$association->getGoTerm()->isObsolete()){
	    	
	    my $instanceList;
	    foreach my $instance (@{$association->getInstances()}){
		if ($instance->getIsPrimary() &&
		    !$instance->isDeprecated() &&
		    !($association->getIsNot() && $instance->getLOEId() == $cbilPredictLOE) && 
		    !($instance->getLOEId() == $obsoleteLOE) && 
		    !($instance->getLOEId() == $scrubberLOE)){
		   
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

    my $assocHash = $self->createAssocHash();
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
	    if ($goSynMap->{$association->getGoTerm()->getRealId()}){  #assoc to go synonym, handle accordingly
		if ($self->find($goSynMap->{$association->getGoTerm()->getRealId()})){  #already has assoc to real id of syn
		    $association->setDeprecated(1);
		    $self->_addSynonymAssociation($association);
		    next;
		}
		else{  #upgrade syn to correct real id
		    $newGoTerm = $newGoGraph->getGoTermFromRealGoId($goSynMap->{$association->getGoTerm()->getRealId()});
		    #a bit of a hack since not using go term map.  Better way?  Maybe have go term map also 
		    #map from syn go terms to real go terms
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
	
	if ($association->isPrimary() && !$association->isDeprecated()){
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

#instantiate SynonymAssociations to be an empty array.
sub _initializeDataStructures{
    my ($self) = @_;
    $self->{SynonymAssociations} = [];
}

#copy all Synonym Associations from $self to the given AssociationGraph, so they can later
#be submitted as deprecated.
sub _processSynonymAssociations{
    my ($self, $newAssociationGraph) = @_;
    
    my $synonymAssociations = $self->getSynonymAssociations();
    foreach my $assoc (@$synonymAssociations){
	$newAssociationGraph->_addSynonymAssociation($assoc);
    }
}

#adds a SynonymAssociation to the internal array belonging to $self.
sub _addSynonymAssociation{
    
    my ($self, $synAssoc) = @_;

    push (@{$self->{SynonymAssociations}}, $synAssoc);
}



1;
