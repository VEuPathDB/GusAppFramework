package GUS::GOPredict::AssociationGraph;

use strict;
use Carp;
use GUS::GOPredict::Association;

sub newBasicGraph{
    my ($class, $association, $goGraph) = @_;

    my $self = {};
    bless $self, $class;

    $self->_growBasicGraph($association, $goGraph);

    $self->_setRoot($goGraph);

    return $self;
}

sub newFromResultSet {
    my ($class, $resultSet, $goGraph, $isBasic) = @_;

    my $self = {};
    bless $self, $class;

    my $associationsHash =
      GUS::GOPredict::Association::makeAssociationHash($resultSet, $goGraph, $isBasic);

    foreach my $association (values %$associationsHash) {

	my $goTerm = $association->getGoTerm();
	my $graphTempGoTerm = $goGraph->getGoTermFromRealGoId($goTerm->getRealId());
	
	my $kids = $goTerm->getChildren();
	foreach my $kidTerm (@$kids) {

	    my $kidAssoc = $associationsHash->{$kidTerm};
	    $association->addChild($kidAssoc) if $kidAssoc;
	}
	$self->{AssociationHash}->{$goTerm->getRealId()} = $association;
    }
    
    $self->_setRoot($goGraph);
    
    return $self;
}


sub evolveGoHierarchy{
    my ($self, $goTermMap, $newGoGraph) = @_;
    
    $self->_upgradeGoTermGusIds($goTermMap);

    $self->_upgradeObsolete();

    my $strongAssocList = $self->_findStrongAssociations($newGoGraph);

    my $newAssociationGraph = GUS::GOPredict::AssociationGraph->newBasicGraph(pop(@$strongAssocList), $newGoGraph);

    $newAssociationGraph->_addAssociations($strongAssocList, $newGoGraph);

    return $newAssociationGraph;
}

sub getAsList{
    my ($self) = @_;
   
    my $assoc = $self->{AssociationHash};
    my @x = values %$assoc;
    
    return \@x;
}

sub _makePrimaryAssociationsFromRules{
   my ($self, $motifs) = @_;
}

sub applyRules{
    my ($self, $motifs) = @_;
    my $primaryAssociations = $self->_makePrimaryAssociationsFromRules($motifs);
    $self->_addAssociations($primaryAssociations);
}

sub deprecateAllPredictedInstances{
    my ($self) = @_;
    foreach my $association (@{$self->getAsList()}){
	$association->deprecatePredictedInstances();
    }
}

sub adjustIsNots{
    my ($self) = @_;
    $self->getRoot()->initializeOnIsPath();
    foreach my $association (@{$self->getAsList()}){
	$association->setIsNotFromIsPath();
    }
}

sub setDefiningLeaves{
    my ($self) = @_;
    $self->getRootTerm()->determineAndSetDefining();

}

sub propogateInstances{
    my ($self) = @_;
}

sub makeAssociations{
    my ($self, $rules) = @_;
}

sub find{
    my ($self, $realGoId) = @_;
    return $self->{AssociationHash}->{$realGoId};
}

sub getRoot(){
    my ($self) = @_;
    return $self->{RootAssociation};
}

sub toString(){
    my ($self) = @_;

    return "$self:\n" . $self->getRoot()->toString("\t");
}


###########################################################################
################  Private methods #########################################
###########################################################################

# grow each assoc. into its own graph, and then graft each graph
sub _addAssociations{
    my ($self, $associationList, $goGraph) = @_;
    foreach my $association (@{$associationList}) {
	# give our assoc its path to root before grafting
	
        GUS::GOPredict::AssociationGraph->newBasicGraph($association, $goGraph);
	
	  $self->_graftAssociation($association);
    }
}

sub _growBasicGraph {
    my ($self, $association, $goGraph) = @_;

    my $goTerm = $association->getGoTerm();
    
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

sub _generateInstances {
  my ($self) = @_;

  
}

sub _upgradeObsolete{
    my ($self) = @_;
    my $rootAssociation = $self->getRoot();
    $rootAssociation->inheritStrength();
}


#upgrades all associations' GO Terms to new GUS Id's 

sub _upgradeGoTermGusIds{
    my ($self, $goTermMap) = @_;

    my $list = $self->getAsList();
    foreach my $association (@$list){

	my $newGoTerm = $goTermMap->{$association->getGoTerm()};

	$association->setGoTerm($newGoTerm);
    }
}

#finds associations that will be carried over to the new GO predictor release.
#returns all such associations in a list
sub _findStrongAssociations{
    my ($self, $newGoGraph) = @_;

    my @strongAssocList;
    my $list = $self->getAsList();
    
    foreach my $association (@$list){

	if ($association->isPrimary()){
	
	    $association->killFamily();
	    push(@strongAssocList, $association);
	}
    }
	    
    return \@strongAssocList;
}



sub _setRoot{

    my ($self, $goGraph) = @_;
    &confess ("no go graph") if !$goGraph;
    my $rootGoId = $goGraph->getRootTerm()->getRealId();
    
    $self->{RootAssociation} = $self->find($rootGoId);
    
    &confess ("couldn't set root") if !$self->getRoot();
    
}


sub _graftAssociation{

    my ($self, $association, $child) = @_;


    my $realGoId = $association->getGoTerm()->getRealId();

    my $prevAssociation = $self->find($realGoId);

    &confess("trying to graft onto self") if $prevAssociation == $association;

    if ($child && $prevAssociation) {
	
	$child->removeParents();
	$prevAssociation->addChild($child);
    }

    return if ($self->{AlreadyAdded}->{$association});
    $self->{AlreadyAdded}->{$association} = 1;

    my $needsLink;
    if ($prevAssociation){
	my $instances = $association->getInstances();
	foreach my $instance (@$instances){
	    $prevAssociation->addInstance($instance);
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


1;
