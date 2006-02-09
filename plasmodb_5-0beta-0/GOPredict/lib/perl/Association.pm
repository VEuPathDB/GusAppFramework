package GUS::GOPredict::Association;

use GUS::GOPredict::Instance;
use GUS::Model::DoTS::GOAssociation;
use GUS::Model::DoTS::GOAssociationInstance;
use GUS::Model::DoTS::Comments;
use GUS::GOPredict::Evidence;

use strict;
use Carp;

#################################### Association.pm ######################################

# A module representing an association between a sequence and a GO ID.  Associations are #
# usually grouped by their sequence in a set known as an AssociationGraph, so the        #
# sequence is not tracked but instead implied.

# An Association keeps track of other Associations that contain the parents and children #
# of its GO ID.  The GO ID, in turn, is represented by a GO Term object.  Associations   #
# also keep track of Instances, which can be thought of reasons for the existance of the #
# Association (for example, it was predicted by the CBIL GO Function Predictor or        #
# manually annotated by a curator).

# This module contains a number of recursive functions that are called on one Association#
# and passed down to its children.  These functions are normally initiated by the        #
# AssociationGraph to which the Association belongs.                                     #

# Created: May 2003. Authors: Dave Barkan, Steve Fischer.                                #
# Last Modified: July 1, 2003, Dave Barkan; separated private methods and added          # 
# documentation.                                                                         #

##########################################################################################


#ids in GUS of various LinesOfEvidence that are assigned to Instances, and Review Status Ids
#of Associations.  A better way to implement would be to make them static somewhere.

my $rootObsoleteGoId = 'GO:0008369'; 
my $unreviewedId = 0;
my $reviewedId = 1;
my $needsReviewId = 5; 

my $cbilPredictLOE = 3;
my $manuallyReviewedLOE = 4;
my $obsoleteLOE = 5;
my $scrubberLOE = 6;
my $badMotifLOE = 26;

############################################################################################
#################################  Constructors ############################################
############################################################################################

#basic new constructor.  Takes a GO Term and sets no further annotation.
sub new{
    my ($class, $goTerm) = @_;
    my $self = {};
    bless $self, $class;

    &confess("no go term") if !$goTerm;
    $self->setGoTerm($goTerm);

    $self->initializeDataStructures();
    return $self;
}

#constructor that takes a GUS Association Object (currently GUS::Model::DoTS::GOAssociation)
#and creates an Association using the data contained in the GUS object.  This data includes
#the GUS object's GUS ID for the GO Term, which is the source of the GO Term object for the
#Association, and its GUS AssociationInstances, which are the basis for the Association's
#Instances.
sub newFromGusAssociation{
    
    my ($class, $gusAssociation, $goGraph) = @_;
 
    my $self = {};
    bless $self, $class;
    &confess ("no gus association") if !$gusAssociation;

    $self->initializeDataStructures();

    $self->setGoTerm($goGraph->getGoTermFromGusGoId($gusAssociation->getGoTermId()));
    &confess ("no go term") if !$self->getGoTerm();
    $self->setIsNot($gusAssociation->getIsNot());
    $self->setReviewStatusId($gusAssociation->getReviewStatusId());
    $self->setGusAssociationObject($gusAssociation);
    $self->setDeprecated($gusAssociation->getIsDeprecated());
  
    foreach my $gusInstance ($gusAssociation->getChildren("DoTS::GOAssociationInstance")) {
	my $instance = GUS::GOPredict::Instance->newFromGusInstance($gusInstance);
	$self->addInstance($instance);
    }

    return $self;
}

#constructor that creates an Association.  Normally, this will be predicted from the CBIL
#GO Function Predictor algorithm; if another algorithm makes the prediction then these
#parameters may have to be changed.

#The following parameters are used as Evidence, assigned to an Instance of this Association.
#param $gusRuleObject:  The rule that trackes the GO Term that was assigned to the motif
#                       to which the associated protein has a similarity.  The object is of
#                       type GUS::Model::DoTS::AAMotifGoTermRule
#param $gusSimObject:   The object reprsenting the similarity between the protein and the
#                       motif.  The object is of type GUS::Model::DoTS::Similarity.

sub newFromPrediction{

    my ($class, $goTerm, $gusRuleObject, $gusSimObject, $ratio) = @_;
    
    my $self = {};
    bless $self, $class;

    $self->initializeDataStructures();
    &confess("no go term") if !$goTerm;
    $self->setGoTerm($goTerm);
    
    my $instance = GUS::GOPredict::Instance->new();
    $instance->setIsPrimary(1);
    $instance->setLOEId($cbilPredictLOE);
    $instance->setRatio($ratio);

    my $simEvidence = GUS::GOPredict::Evidence->new($gusSimObject); 
    $instance->addEvidence($simEvidence);

    my $ruleEvidence = GUS::GOPredict::Evidence->new($gusRuleObject); 
    $instance->addEvidence($ruleEvidence);

    $self->addInstance($instance);
    return $self;
}

############################################################################################
################################  Data Accessors ###########################################
############################################################################################

#param $gusAssociation:  An object of type GUS::Model::DoTS::GOAssociation representing the 
#                        GUS database entry for this Association.
sub setGusAssociationObject{
    my ($self, $gusAssociation) = @_;
    $self->{GusAssociationObject} = $gusAssociation;
}

sub getGusAssociationObject{
    my ($self) = @_;
    return $self->{GusAssociationObject};
}

sub setGoTerm{
    my ($self, $goTerm) = @_;
    &confess ("no GoTerm!") if (!$goTerm);
    $self->{GoTerm} = $goTerm;
}

sub getGoTerm{
    my ($self) = @_;
    return $self->{GoTerm};
}

sub setIsNot{
    my ($self, $isNot) = @_;
    $self->{IsNot} = $isNot;
}

sub getIsNot{
    my ($self) = @_;
    return $self->{IsNot};
}

sub getReviewStatusId{
    my ($self) = @_;
    return $self->{ReviewStatusId};
}

sub setReviewStatusId{
    my ($self, $reviewStatusId) = @_;
    $self->{ReviewStatusId} = $reviewStatusId;
}

sub setDeprecated{
    my ($self, $deprecated) = @_;
    $self->{Deprecated} = $deprecated;
}

sub isDeprecated{
    my ($self) = @_;
    return $self->{Deprecated};
}

#this accessor represents whether this Association is the lowest in a branch of 
#the AssociationGraph to which it belongs without being deprecated or 'is not'
sub setDefining{
    my ($self, $defining) = @_;
    $self->{Defining} = $defining;
}

sub getDefining{
    my ($self) = @_;
    
    return $self->{Defining};
}

#initializes the given arrays to be empty arrays so they do not return undefined.
sub initializeDataStructures{

    my ($self) = @_;

    $self->{Children} = [];
    $self->{Parents} = [];
    $self->{Instances} = [];
}

#if I have no instances at all, create a new non-primary one with a review status of unreviewed
sub createNonPrimaryInstance{

    my ($self, $loeId) = @_;
    if (scalar(@{$self->{Instances}}) == 0){
	my $instance = GUS::GOPredict::Instance->new();
	$instance->setIsNot($self->getIsNot());
	$instance->setIsPrimary(0);
	$instance->setLOEId($loeId);
	$instance->setDeprecated(0);
	$instance->setReviewStatusId($unreviewedId);
	$self->addInstance($instance);
    }
}


############################################################################################
###########################  Internal Data Structures ######################################
############################################################################################

sub _addParent{
    my ($self, $association) = @_;
    push(@{$self->{Parents}}, $association);
}

sub removeParents {
    my ($self) = @_;
    $self->{Parents} = [];
}

#given an association (param $newParent), find the existing parent association of self that has
#the same go term as the new parent and replace it with the new parent.  The rest of the parents
#remain unchanged.
sub replaceParent{
    my ($self, $newParent) = @_;
    
    my $existingParents = $self->getParents();
    
    $self->removeParents();
    #parents are now just floating around
    
    foreach my $existingParent (@$existingParents) {

	if (!($existingParent->getGoTerm()->getRealId() eq $newParent->getGoTerm()->getRealId())){

	    $self->_addParent($existingParent); #add all parents not corresponding to new parent
	}
    }
    
    $newParent->addChild($self);
    
}

#add $association as a child to me; also adds myself as a parent for the child
sub addChild{
    my ($self, $association) = @_;
    push(@{$self->{Children}}, $association);
    $association->_addParent($self);
}

sub getChildren{
    my ($self) = @_;
    return $self->{Children};
}

sub getParents{
    my ($self) = @_;
    return $self->{Parents};
}

sub addInstance{
    my ($self, $instance) = @_;
    push(@{$self->{Instances}}, $instance);
}

sub getInstances{
    my ($self) = @_;
    return $self->{Instances};
}

#remove all parents and children from my lists.
sub killFamily{
    my ($self) = @_;
    $self->{Children} = [];
    $self->{Parents} = [];
}

#remove all of my Instances, Relationship, GUS Object, and Go Term.
sub killReferences{
    
    my ($self) = @_;

    $self->killFamily();
    my $goTerm;

    $self->{Instances} = [];
#    $self->setGusAssociationObject(undef);
    
    #$self->{GoTerm} = $goTerm;

}

############################################################################################
##############################  Validation methods #########################################
############################################################################################

#recursive method that checks to make sure if I am set to is_not, then all of my descendants are too.
sub validateIsNot{

    my ($self, $proteinId, $parentIsNot) = @_;
    
    if ($parentIsNot && !$self->getIsNot()){
	print STDERR "Invalid data for protein $proteinId: " . $self->getGoTerm()->getRealId() . " is set to 'is' and has an ancestor set to 'is not'\n";
    }
    
    my $isNot = $self->getIsNot();
    $isNot = 0 if (!$self->getIsNot()); #account for unset variable
    $isNot = 1 if ($parentIsNot); #ancestor overrides self
   
    my $children = $self->getChildren();
    foreach my $child(@$children){
	$child->validateIsNot($proteinId, $isNot);
    }
}


############################################################################################
################################  Utility Methods ##########################################
############################################################################################


#given a map of all motifs that were used to create rules to predict me, and a list
#of motifs that have been rejected, determine if I have evidence that came from a motif
#that wasn't rejected.
sub hasGoodEvidence{

    my ($self, $evidenceMap, $allRejectedMotifs) = @_;
    
    my $realGoId = $self->getGoTerm()->getRealId();
    my $motifVersions = $evidenceMap->{$realGoId};
    
    #motifs are grouped by database; check each database in the map
    foreach my $motifVersion (keys %$motifVersions){
	my $sourceIds = $motifVersions->{$motifVersion};
	
	#check each source id of the motif used to predict me
	foreach my $sourceId (keys %$sourceIds){
	    if (!$allRejectedMotifs->{$motifVersion}->{$sourceId}){  #non-rejected motif
		return 1;
	    }
	}
    }
    
    #if we have gotten this far, we have no non-rejected motifs
    return 0;
}

#add this association to $processedAssocMap if it hasn't been added already
#(works by adding the GO ID of this Association's GO term to the keys of 
#$processedAssocMap).  Recursively adds this Associations ancestors to the map
#as well
sub markAncestorsGoodEvidence{
    
    my ($self, $processedAssocMap) = @_;
    
    my $realGoId = $self->getGoTerm()->getRealId();

    if (!$processedAssocMap->{$realGoId}){ #ie return if already processed
#	print STDERR "Association.markAncestorsGood: marking " . $realGoId . " as having good evidence from parent\n";
	$processedAssocMap->{$realGoId} = 1;
	my $assocParents = $self->getParents();
	foreach my $parent (@$assocParents){
	    $processedAssocMap = $parent->markAncestorsGoodEvidence($processedAssocMap);
	}
    }
    return $processedAssocMap;
}

sub processRejectedMotif{

    my ($self, $processedAssocMap, $rejectedMotifVersion, $rejectedMotifId, $gusMotifObject) = @_;
    
    my $realGoId = $self->getGoTerm()->getRealId();
#    print STDERR "AssociationGraph.processRejectedMotif: testing $realGoId\n";
    if (!$processedAssocMap->{$realGoId}){ #ie, return if already processed

	$processedAssocMap->{$realGoId} = 1;
	$self->setIsNot(1);
#	print STDERR "AssociationGraph.processRejectedMotif: found bad assoc $realGoId, setting is not\n";
	my $newInstance = GUS::GOPredict::Instance->new();
	$newInstance->setIsNot(1);
	$newInstance->setIsPrimary(1);
	$newInstance->setLOEId($badMotifLOE); 
	$newInstance->setReviewStatusId(1); 
	$newInstance->setDeprecated(0);
	
	my $motifEvidence = GUS::GOPredict::Evidence->new($gusMotifObject);
	$newInstance->addEvidence($motifEvidence);
	$self->addInstance($newInstance);
	
	my $assocParents = $self->getParents();
	foreach my $parent (@$assocParents){
	    $processedAssocMap = $parent->processRejectedMotif($processedAssocMap, $rejectedMotifVersion, $rejectedMotifId,
							       $gusMotifObject);
	}
    }
    return $processedAssocMap;
}

#sends the state of the Association (that is, the bits determining if the Association
#is Defining, Deprecated, 'is not', etc.) to the contained GUS Association Object.
#Typically, the GUS Association Object is not updated until the very end of processing
#the Association, at which point this method is called and the GUS Object is resubmitted
#to the database.
sub updateGusObject{
    
    my ($self) = @_;
    my $gusAssociation = $self->getGusAssociationObject();

    $self->processGusInstancesForAssociation();

    $gusAssociation->setGoTermId($self->getGoTerm()->getGusId());
    $gusAssociation->setIsNot($self->getIsNot()); 
    $gusAssociation->setDefining($self->getDefining()); 
    
    #note: right now the Association is always initialized as not being defining, and 
    #the Association->setDefining method is called by a post-processing scrubber.  Thus,
    #if the scrubber is not run, the Association will never be defining--might want
    #to change that.

    if (!$self->getIsNot()){
	$gusAssociation->setIsNot(0);
    }
    if (!$self->getDefining()){  #non-nullable column in db, account for undef here
	$gusAssociation->setDefining(0);
    }
    $gusAssociation->setReviewStatusId($self->getReviewStatusId()); 

    if (!$self->getReviewStatusId()){  #non-nullable column in db, account for undef here
	$gusAssociation->setReviewStatusId(0);
    }
    
    $gusAssociation->setIsDeprecated($self->isDeprecated());
    if (!$self->isDeprecated()){  #non-nullable column in db, account for undef here
	$gusAssociation->setIsDeprecated(0);
    }
}

#uses the given $adapter, normally a DatabaseAdapter that has access to GUS, to submit
#the GUS Association object for this Association back to GUS.
sub submitGusObject{
    my ($self, $adapter) = @_;
    
    $adapter->submitGusObject($self->getGusAssociationObject());
}

#prints out all possible information about this Association.  Can be called recursively on
#children of the Association.
#param $tab:            A string; with each recursive call, \t is added onto it to indent children 
#                       accordingly.
#param $doNotShowKids:  If true, do not make the recursive call on children.

sub toString{
   my ($self, $tab, $doNotShowKids) = @_;

   my $parents = $self->getParents();
   my @parentsGoTerms;
   &confess ("no go term in to string!") if !$self->getGoTerm();

   foreach my $parent(@$parents){
       &confess (" no go term for my parent, I am " . $self->getGoTerm()->getRealId()) if !$parent->getGoTerm();
       push (@parentsGoTerms, $parent->getGoTerm()->getRealId());
   }
   my $parentsGo = join (',', @parentsGoTerms); 

   my $kids = $self->getChildren();
   my @kidsGoTerms;
   foreach my $kid(@$kids){
       &confess (" no go term for my kid, I am " . $self->getGoTerm()->getRealId()) if !$kid->getGoTerm();
       push (@kidsGoTerms, $kid->getGoTerm()->getRealId());
   }
   my $kidsGo = join (',', @kidsGoTerms); 

   my $gusId;
   my $isNot = $self->getIsNot();
   my $defining = $self->getDefining();
   my $reviewStatusId = $self->getReviewStatusId();
   my $isDeprecated = $self->isDeprecated();
   &confess ("no go term!") if !$self->getGoTerm();
   my $goId = $self->getGoTerm()->getRealId();
   my $gusAssociation = $self->getGusAssociationObject();
   $gusId = $gusAssociation->getGoAssociationId() if $gusAssociation;
   my $primary = $self->isPrimary();
   my $goTermString = $self->getGoTerm()->toString();
   my $s =
"
$tab ASSOCIATION $goId $self
$tab primary:     $primary
$tab isNot:       $isNot
$tab Go Term:     $goTermString
$tab gusAssocId:  $gusId
$tab gusAssocObj: $gusAssociation
$tab reviewId:    $reviewStatusId
$tab deprecated:  $isDeprecated
$tab defining:    $defining
$tab parents:     $parentsGo
$tab children:    $kidsGo
";
   

   my $instances = $self->getInstances();
   foreach my $instance (@$instances){
       if ($instance){
	   $s .= $instance->toString($tab . "  ") . "\n";
       }
   }
   if (!$doNotShowKids){
       foreach my $child (@{$self->{Children}}){
	   $s .= $child->toString($tab . "  ");
       }
   }
   return $s;
}

#returns true if this Association has one or more primary Instances.
sub isPrimary{
    my ($self) = @_;
    my $instances = $self->getInstances();
    foreach my $instance (@$instances){
	return 1 if $instance->getIsPrimary();
    }
    return 0;
}

#a recursive method, this discovers if the Association has any descendants that are obsolete in 
#the next version of the GO Hierarchy.  Obsolete descendants only qualify as such if there is no
#Association on the path between $self and the obsolete descendant that is not obsolete; generally,
#then, these descendants will be children of $self, or a descendant of an obsolete child of $self.
#$self becomes primary and gets a 'needs re-review' Instance for each such obsolete descendant.
sub inheritStrength{
    my ($self) = @_;
    my @obsoleteAssociations;
 
    my @children = @{$self->getChildren()};   

    #build list of all obsolete descendants and propogate it back to me
    foreach my $child (@children){
	push (@obsoleteAssociations, $child->inheritStrength());
    }

    if ($self->getGoTerm()->isObsolete()){

	if ($self->isPrimary()){
	    push (@obsoleteAssociations, $self);
	}
    }
    
    #if I am not obsolete, make instances for all my obsolete descendants.
    else {
	#obsoleteAssociations will be empty after we go through it
	if (scalar @obsoleteAssociations){

	    #take care that obsolete descendants are not on the list more than once
	    my $obsAssocHash = $self->getAssocHashFromAssocList(@obsoleteAssociations);
	    my @distinctObsAssocList = values %$obsAssocHash;
	    
	    while (my $association = shift(@distinctObsAssocList)){  
		
		next if ($self->_isInheritedObsoleteId($association->getGoTerm()->getRealId()));
		$self->_addInheritedObsoleteId($association->getGoTerm()->getRealId());		
		#dtb: previous two lines necessary in case this association is hit more than once
		#in the recursive traversal 

		$self->setReviewStatusId($needsReviewId); 
		
		my $instance = GUS::GOPredict::Instance->new();
		$instance->setIsPrimary(1);      
		$instance->setReviewStatusId($needsReviewId);
		$instance->setIsNot($self->getIsNot());
		$instance->setLOEId($obsoleteLOE);
		my $gusObsAssociationObject = $association->getGusAssociationObject();
		&confess ("no gus object for obsolete association with go Id " . $association->getGoTerm()->getRealId())
		    if !$gusObsAssociationObject;
		$instance->addEvidence(GUS::GOPredict::Evidence->new($gusObsAssociationObject));
		
		$self->addInstance($instance);
	    }

	    while (my $association = shift(@obsoleteAssociations)){}
	    #empty this array so it doesn't propogate further to other ancestors
	}
    }
    return @obsoleteAssociations;
}

#keep track of go ids for associations that i have gotten instances from because
#they are obsolete.  Necessary because we can hit the same ids through different traversals
sub _addInheritedObsoleteId{

    my ($self, $inheritedId) = @_;
    $self->{InheritedIds}->{$inheritedId} = 1; 

}

sub _isInheritedObsoleteId{

    my ($self, $inheritedId) = @_;
    my $isId = 0;
    $isId = 1 if $self->{InheritedIds}->{$inheritedId};
    return $isId;
}

sub getAssocHashFromAssocList{
    my ($self, @assocList) = @_;
    my $assocHash;
    foreach my $assoc (@assocList){

	$assocHash->{$assoc->getGoTerm()->getRealId()} = $assoc;
    }
    return $assocHash;
}

#Deprecate this Association if it has no Instances that are not deprecated
sub deprecateIfInstancesDeprecated{

    my ($self) = @_;

    my $deprecate = 1;
    foreach my $instance (@{$self->getInstances()}){
	if (!$instance->isDeprecated()){
	    $deprecate = 0;
	}
    }
    $deprecate = 0 if ($self->getGoTerm->getRealId() eq $rootObsoleteGoId);
    if ((scalar @{$self->getInstances()}) == 0){
#	print STDERR "Association.deprecateIfInstancesDeprecated: not deprecating the association since it has no instances at all\n";
	$deprecate = 0;
    }
    $self->setDeprecated(1) if $deprecate;
}


#deprecate all Instances that represent a prediction by the CBIL Prediction Algorithm.
#Used when applying rules to see if any old predictions are outdated.
sub deprecatePredictedInstances{
    
    my ($self) = @_;

    my $instances = $self->getInstances();
    foreach my $instance (@$instances){
	
	$instance->setDeprecated(1) if $instance->getLOEId == $cbilPredictLOE;  
    }
}

sub initializeOnIsNotPath{
    my ($self) = @_;
    if ($self->getIsNot()){
	$self->_setOnIsNotPath();  #recursively sets for children too
    }
    else {
	foreach my $child (@{$self->getChildren()}){
	    $child->initializeOnIsNotPath();
	}
    }
}

sub _setOnIsNotPath{
    my ($self) = @_;
    $self->{onIsNotPath} = 1;
    foreach my $child (@{$self->getChildren()}){
	$child->_setOnIsNotPath();
    }
}
 
sub setIsNotFromPath{
    
    my ($self, $doNotCreateInstances) = @_; 

    if ($self->{onIsNotPath}){
	if (!$self->getIsNot() && !$self->isDeprecated()){
	    
	    my $instance = GUS::GOPredict::Instance->new();
	    $instance->setIsPrimary(1);  
	    $instance->setIsNot(1);
	    $instance->setLOEId($scrubberLOE);
	    
	    my $gusIsNotComment = GUS::Model::DoTS::Comments->new();
	    $gusIsNotComment->setCommentString("Association rejected due to an Ancestor Association being rejected.");
	    $gusIsNotComment->setReviewStatusId($unreviewedId);
	    $instance->addEvidence(GUS::GOPredict::Evidence->new($gusIsNotComment));
	    
	    if ( !$self->getReviewStatusId()== $unreviewedId){  #manually reviewed and not already is not
		$self->setReviewStatusId($needsReviewId); 
		$instance->setReviewStatusId($needsReviewId);
	    }
	    else{  
		$instance->setReviewStatusId($unreviewedId);
	    }
	    
	    $self->setIsNot(1);
	    $self->addInstance($instance) unless $doNotCreateInstances;
	}
    }
}

  

#a good example of a method name that gives an indication of what the method does.
sub countPrimaryInstances{

    my ($self) = @_;
    my $counter = 0;
    my $instances = $self->getInstances();
    foreach my $instance (@$instances){
	$counter++ if $instance->getIsPrimary();
    }
    return $counter;
}

#updates the GoAssociationId of this Association's contained object.
#right now only being used to modify associations that are deprecated
#in the database but created anew by the GoManager (might be a better
#way to do this).
sub updateGusAssociationId{
    my ($self, $gusAssocId) = @_;
    $self->getGusAssociationObject()->setGoAssociationId($gusAssocId);
}


#creates a new GUS Association object with all of the data set from this Association.
#does not handle instances
sub createGusAssociation{

    my ($self, $tableId, $rowId) = @_;
    my $gusAssociation = GUS::Model::DoTS::GOAssociation->new();
    $gusAssociation->setTableId($tableId);
    $gusAssociation->setRowId($rowId);
    $self->setGusAssociationObject($gusAssociation);    

    $self->updateGusObject();
    #evidence stuff


}

#creates GUS AssociationInstanceObjects and adds them as children of (having foreign keys to) 
#the GUS Association Object.  If the instance object already exists, simply updates its values.
sub processGusInstancesForAssociation{
    
    my ($self) = @_;
    my $gusAssociation = $self->getGusAssociationObject();
    &confess ("don't have gus association object set for this association!") if !$gusAssociation;
    foreach my $instance (@{$self->getInstances()}){  
	my $gusInstance = $instance->getGusInstanceObject();
	if (!$gusInstance){
	    $instance->createGusInstance();
	    $gusInstance = $instance->getGusInstanceObject();
	    $gusAssociation->addChild($gusInstance);
	}
	else {
	    $instance->updateGusInstance();
	}
    }
}

#returns true if this Association has no descendants that are not 'is not'.  Used when
#determining whether 'is not' Instances should be propogated to this Association (which
#happens if this method returns true to ensure that all Associations have Instances).
sub hasNoIsDescendants{

    my ($self) = @_;

    if ($self->isPrimary() && !$self->getIsNot()){
	return 0;
    }
    my $children = $self->getChildren();
    foreach my $child (@$children){
	return 0 if !$child->hasNoIsDescendants();
    }
    return 1;
	
}

#given an instance list, remove all of those that are 'is not.'  Used if $self->hasNoIsInstances
#evaluates to true.
sub stripIsNotInstances{

    my ($self, $instancesToCheck) = @_;
    my $instancesToCache;

    foreach my $instance (@$instancesToCheck){
	push (@$instancesToCache, $instance) if !$instance->getIsNot();
    }
    return $instancesToCache;
}


#recursive method that copies all primary instances of an Association to all of its ancestors.
#does not propogate 'is not' instances unless they are the only ones an Association will receive.

#param $instanceInfoHash: hash where the key is the go term of a primary descendant and the entry 
#                         is a list of that descendant's ancestors.  The parent association builds
#                         up a bunch of them and then the graph adds them all at the end with 
#                         cacheDescendantInstances.

sub propogateInstances{
    my ($self, $instanceInfoHash) = @_;

   # if (!$self->getIsNot()){  #if I am is not then I get no Instances regardless (already have one saying 'is not')
    foreach my $descendantId (keys %$instanceInfoHash){
	my $descendantInstances = $instanceInfoHash->{$descendantId};
	my $instancesToCache;
	
	if ($self->hasNoIsDescendants() && !$self->isPrimary()){  #cache is not instances if have no other 'is' descendents
	    $instancesToCache = $descendantInstances;
	    $self->setIsNot(1);
	}
	else{
	    $instancesToCache = $self->stripIsNotInstances($descendantInstances); #do not cache is not instances
	}
	$self->{CachedInstances}->{$descendantId} = $instancesToCache;
#	}
	foreach my $parent (@{$self->getParents()}){
	    $parent->propogateInstances($instanceInfoHash);
	}
    }
}

#having built up a list of instances to cache, go ahead and do it.  The cached instances are 
#not primary and get their own GUS Instance objects (later). 
#This method is not recursive; it is normally called by the AssociationGraph which iterates the
#method over its Associations.
sub cacheDescendantInstances{

    my ($self) = @_;
    foreach my $descendantId (keys % { $self->{CachedInstances} } ){
	my $descendantInstances = $self->{CachedInstances}->{$descendantId};
	foreach my $instance (@$descendantInstances){
	    my $newInstance = $instance->cloneNotPrimary();
	    $newInstance->setGusInstanceObject(undef); #kill instance object
	    $self->addInstance($newInstance);
	}
    }
    $self->{CachedInstances} = {};
}

#A recursive method which sets Association to be defining according to the rules laid out in
#AssociationGraph.pm
sub determineAndSetDefining{
    my ($self) = @_;

    my $haveDefiningChildren = 0;

    foreach my $child (@{$self->getChildren()}){
	$haveDefiningChildren |= $child->determineAndSetDefining();
    }
    
    return 1 if $haveDefiningChildren;

    #if we got here no child is defining (or have no children), check if self is defining
    &confess ("couldn't get go term") if !$self->getGoTerm();
    if ($self->isDeprecated() || $self->getGoTerm()->isObsolete() || $self->getIsNot() || !$self->isPrimary()){
	return 0;
    }
    
    $self->setDefining(1);
    return 1;
}

#utility method which takes a list of GUS Association Objects, makes Associations out of them, and
#stores and returns those Associations as values in a hash keyed on their GO Terms.
sub makeAssociationHashFromGusObjects{

    my ($gusAssocList, $goGraph) = @_;
    my $assocHash;
    foreach my $gusAssoc (@$gusAssocList){
	my $association = GUS::GOPredict::Association->newFromGusAssociation($gusAssoc, $goGraph);

	$assocHash->{$association->getGoTerm()} = $association;
    }
    
    return $assocHash;
}


#copies all information from another association over to myself
#used when grafting a primary association into a graph and finding
#an existing association (myself) that is only in the graph because
#it was made by a primary child
sub absorbStateFromAssociation{

    my ($self, $association) = @_;

    $self->setGusAssociationObject($association->getGusAssociationObject());
    $self->setReviewStatusId($association->getReviewStatusId());
    $self->setIsNot($association->getIsNot());
    &confess ("go term problems self!") if !$self->getGoTerm();
    &confess ("go term problems association!") if !$association->getGoTerm();
    
}



1;
