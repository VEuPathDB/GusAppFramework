package GUS::GOPredict::Association;
use GUS::GOPredict::Instance;
use strict;
use Carp;


sub new{
    my ($class, $goTerm) = @_;
    my $self = {};
    bless $self, $class;
    $self->setGoTerm($goTerm);
    $self->{Children} = [];
    $self->{Parents} = [];
    $self->{Instances} = [];
    return $self;
}

sub setGoTerm{
    my ($self, $goTerm) = @_;
    &confess ("no GoTerm!") if (!$goTerm);
    $self->{GoTerm} = $goTerm;

}

sub getIsNot{
    my ($self) = @_;
    return $self->{IsNot};
}

sub setId{
    my ($self, $id) = @_;
    $self->{Id} = $id;
}
sub getId{
    my ($self) = @_;
    return $self->{Id};
}

sub setOnIsPath{
    my ($self, $onIsPath) = @_;
    $self->{OnIsPath} = $onIsPath;
}

sub isOnIsPath{
    my ($self) = @_;
    return $self->{OnIsPath};
}

sub isDeprecated{
    my ($self) = @_;
    my $instances = $self->getInstances();
    foreach my $instance (@$instances){
	return 0 if !$instance->isDeprecated();
    }
    return 1;
}


sub setIsNot{
    my ($self, $isNot) = @_;
    $self->{IsNot} = $isNot;
}


sub setReviewStatusId{
    my ($self, $reviewStatusId) = @_;
    $self->{ReviewStatusId} = $reviewStatusId;
}

sub _addParent{
    my ($self, $association) = @_;
    push(@{$self->{Parents}}, $association);
}

sub removeParents {
    my ($self) = @_;
    $self->{Parents} = [];
}

sub addChild{
    my ($self, $association) = @_;
    
    push(@{$self->{Children}}, $association);
    $association->_addParent($self);
}

sub addInstance{
    my ($self, $instance) = @_;

    push(@{$self->{Instances}}, $instance);
}

sub getChildren{
    my ($self) = @_;
    return $self->{Children};
}

sub getParents{
    my ($self) = @_;
    return $self->{Parents};
}

sub getInstances{
    my ($self) = @_;
    return $self->{Instances};
}

sub getReviewStatusId{
    my ($self) = @_;
    return $self->{ReviewStatusId};
}

sub getGoTerm{
    my ($self) = @_;
    return $self->{GoTerm};
}

sub union{
    my ($self, $association) = @_;

}

sub toStringUp{
    my ($self, $tab) = @_;
      my $s = $tab . $self->getGoTerm()->toString() . " assocRef: " . $self . "\n";
   
   
   foreach my $instance (@{$self->getInstances()}){
       $s .= $instance->toString($tab . "\t") . "\n";
   }

    foreach my $parent (@{$self->{Parents}}){
       
       $s .= $parent->toStringUp($tab . "\t");
   }
   return $s;
}


sub toString{
   my ($self, $tab) = @_;
   
   my $s = $tab . $self->getGoTerm()->toString() . " primary: " . $self->isPrimary() . " $self \n";
   my $instances = $self->getInstances();
   foreach my $instance (@$instances){
       $s .= $instance->toString($tab . "\t") . "\n";
   }

   foreach my $child (@{$self->{Children}}){
       $s .= $child->toString($tab . "\t");
   }

   return $s;
}

sub killFamily{
    my ($self) = @_;
    $self->{Children} = [];
    $self->{Parents} = [];
}

sub isPrimary{
    my ($self) = @_;
    my $instances = $self->getInstances();
    foreach my $instance (@$instances){
	return 1 if $instance->getIsPrimary();
    }
    return 0;
}

sub inheritStrength{
    my ($self) = @_;
    my @obsoleteAssociations;
 
    my @children = @{$self->getChildren()};   
    foreach my $child (@children){
	push (@obsoleteAssociations, $child->inheritStrength());
    }

    if ($self->getGoTerm()->isObsolete()){

	if ($self->isPrimary()){
	    push (@obsoleteAssociations, $self);
	}
    }
    else {
	#obsoleteAssociations will be empty after we go through it
	while (my $association = shift(@obsoleteAssociations)){  
	
	    $self->setReviewStatusId(3); ##?correct id?
	    my $instance = GUS::GOPredict::Instance->new();
	    $instance->setIsPrimary(1);      
	    $instance->setReviewStatusId(3);
	    $instance->setIsNot($self->getIsNot());
	    $instance->setLOEId(222);
	    #DTB: ADD $association as EVIDENCE--obsolete kid
	    
	    $self->addInstance($instance);
	}
    }
    return @obsoleteAssociations;
}


sub deprecatePredictedInstances{
    
    my ($self) = @_;

    my $instances = $self->getInstances();
    foreach my $instance (@$instances){
	$instance->setDeprecated(1) if $instance->getReviewStatusId == 0;  #configurable
    }
}

sub initializeOnIsPath{
    my ($self) = @_;

    if (!$self->getIsNot()){
	$self->setOnIsPath(1);

	foreach my $child (@{$self->getChildren()}){
	    $child->initializeOnIsPath();
	}
    }
}   


sub setIsNotFromIsPath{
    my ($self) = @_;
    
    if (!$self->isOnIsPath()){   #is not unless has no instances/is primary
	if ($self->isPrimary()){
	    
	    my $instance = GUS::GOPredict::Instance->new();
	    $instance->setIsPrimary(1);  
	    $instance->setIsNot(1);
	    $instance->setLOEId( $self->getInstances()->[0]->getLOEId() );
	    
	    if ( !$self->getReviewStatusId()==0 && !$self->getIsNot()){  #manually reviewed and not already is not
		$self->setReviewStatusId(3); 
		$instance->setReviewStatusId(3);
	    }
	    else{
		$instance->setReviewStatus(0);
	    }
	    
	    $self->setIsNot();
	    #DTB: ADD EVIDENCE TO INSTANCE: $association that forced is not
	    
	    $self->addInstance($instance);
	}
    }
}

sub determineAndSetDefining{
    my ($self) = @_;

    foreach my $child (@{$self->getChildren()}){
	return 1 if $child->determineAndSetDefining();
    }
    
    #if we got here no child is on defining, check if self is defining
    if ($self->isDeprecated() || $self->getIsNot() || !$self->isPrimary()){
	return 0;
    }
    
    $self->setDefining(1);
    return 1;
}


#assocQuery:
#RealGoId  GusGoID AssociationId ReviewStatus IsNot InstanceId Instance_LOE_id InstanceReviewStatus Instance.IsPrimaryInstance IsNot (#figure out what exactly we need to use here) 

sub makeAssociationHash{

    my ($assocQuery, $goGraph, $isBasic) = @_;
    my $assocHash;
    foreach my $assocRow(@$assocQuery){
	my ($realGoId, $gusGoId, $associationId, $assocReviewStatusId, $assocIsNot, $instanceId, $instanceLOEId,
	    $instanceReviewStatusId, $isPrimary, $instanceIsNot) = @$assocRow;
	my $goTerm = $goGraph->getGoTermFromRealGoId($realGoId);

	my $association = $assocHash->{$goTerm};
	if (!$association){

	    $association = GUS::GOPredict::Association->new($goTerm); #pass in go term?
	    $association->setId($associationId);
	    $association->setReviewStatusId($assocReviewStatusId);
	    $association->setIsNot($assocIsNot);
	    $assocHash->{$goTerm} = $association;

	}
	if (!$isBasic || $isPrimary){
	    my $instance = GUS::GOPredict::Instance->new($instanceId);
	    $instance->setReviewStatusId($instanceReviewStatusId);
	    $instance->setIsPrimary($isPrimary);
	    $instance->setIsNot($instanceIsNot);
	    $instance->setLOEId($instanceLOEId);
	    $association->addInstance($instance);
	}
    }
    return $assocHash;
}

1;
