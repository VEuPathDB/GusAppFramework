package GUS::GOPredict::Instance;

use GUS::Model::DoTS::GOAssociationInstance;

use strict;
use Carp;



sub new{
    my ($class) = @_;
    my $self = {};
    bless $self, $class;
    $self->{Evidence} = [];
    return $self;

}

sub newFromGusInstance{
    my ($class, $gusInstance) = @_;
    my $self = {};
    bless $self, $class;
    $self->{Evidence} = [];

    $self->setIsNot($gusInstance->getIsNot());
    $self->setIsPrimary($gusInstance->getIsPrimary());
    $self->setLOEId($gusInstance->getGoAssocInstLoeId());
    $self->setDeprecated($gusInstance->getIsDeprecated());
    $self->setReviewStatusId($gusInstance->getReviewStatusId());
    $self->setGusInstanceObject($gusInstance);
    return $self;
    #evidence?
}

sub setGusInstanceObject{
    my ($self, $gusInstance) = @_;
    $self->{GusInstanceObject} = $gusInstance;
}

sub getGusInstanceObject{
    my ($self) = @_;
    return $self->{GusInstanceObject};
}

sub createGusInstance{
    
    my ($self) = @_;
  
    my $gusInstance = GUS::Model::DoTS::GOAssociationInstance->new();
    $gusInstance->setGoAssocInstLoeId($self->getLOEId());

    $gusInstance->setIsNot($self->getIsNot());
    $gusInstance->setIsPrimary($self->getIsPrimary());
    if (!$self->getIsPrimary()){
	$gusInstance->setIsPrimary(0);
    }
    #update when schema changes
    $gusInstance->setReviewStatusId($self->getReviewStatusId());
    if (!$self->getReviewStatusId()){
	$gusInstance->setReviewStatusId(0);
    }
    $gusInstance->setPValueRatio(); #??
    $gusInstance->setIsDeprecated(0);

    my $evidenceList = $self->getEvidence();
    if ($evidenceList){

	foreach my $evidence (@$evidenceList){

	    $gusInstance->addEvidence($evidence->getGusEvidenceObject());

	}
	##maybe add as similarity evidence
    }
    $self->setGusInstanceObject($gusInstance);

}


sub addEvidence{
    my ($self, $evidence) = @_;
   
    push (@{$self->{Evidence} }, $evidence);
}

sub getEvidence{
    my ($self) = @_;
    return $self->{Evidence};
}

sub removeAllEvidence{
    my ($self) = @_;
    while (my $nextEvidence = shift (@{$self->{Evidence} }))
    {}
    
}

sub getReviewStatusId{
    my ($self) = @_;
    return $self->{ReviewStatusId};
}

sub setReviewStatusId{
    my ($self, $reviewStatusId) = @_;
    $self->{ReviewStatusId} = $reviewStatusId;
}

sub getLOEId{
    my ($self) = @_;
    return $self->{LOEId};
}

sub setLOEId{
    my ($self, $loeId) = @_;
    $self->{LOEId} = $loeId;
}

sub getRule{
    my ($self) = @_;
    return $self->{Rule};
}

sub setRule{
    my ($self, $rule) = @_;
    $self->{Rule} = $rule;
}

sub clone{
    my ($self) = @_;
    my $newInstance = GUS::GOPredict::Instance->new();
    $newInstance->setReviewStatusId($self->getReviewStatusId());
    $newInstance->setRule($self->getRule());
    $newInstance->setIsPrimary($self->getIsPrimary());
    $newInstance->setIsNot($self->getIsNot());
    $newInstance->setLOEId($self->getLOEId());

    my $evidenceList = $self->getEvidence();
    if ($evidenceList){
	foreach my $evidence (@$evidenceList){

	    $newInstance->addEvidence($evidence);
	}
    }

    my $gusInstance = $self->getGusInstanceObject();
    $newInstance->setGusInstanceObject($gusInstance) if $gusInstance;

    return $newInstance;

}

sub cloneNotPrimary{
    my ($self) = @_;
    
    my $newInstance = $self->clone();
    $newInstance->setIsPrimary(0);
    $newInstance->removeAllEvidence();
    return $newInstance;
}

sub getIsPrimary{
    my ($self) = @_;
    return $self->{IsPrimary};
}

sub setIsPrimary{
    my ($self, $isPrimary) = @_;
    $self->{IsPrimary} = $isPrimary;
}

sub setDeprecated{
    my ($self, $deprecated) = @_;
    $self->{Deprecated} = $deprecated;
}
sub isDeprecated{
    my ($self) = @_;
    return $self->{Deprecated};
}


sub getIsNot{
    my ($self) = @_;
    return $self->{IsNot};
}

sub setIsNot{
    my ($self, $isNot) = @_;
    $self->{IsNot} = $isNot;
}

sub toString{
    my ($self, $tab) = @_;

    my $gusId;
    my $evidenceString;
    my $evidenceList = $self->getEvidence();
    if ($evidenceList){
	foreach my $evidence (@$evidenceList){
	    $evidenceString .= $evidence->toString() . "$tab \n"; 
	}
    }
    my $gusInstance = $self->getGusInstanceObject();
    $gusId = $gusInstance->getGoAssociationInstanceId() if $gusInstance;
    
#    return
#"$tab INSTANCE gusId: $gusId self: $self
# $tab  LOE Id:         $self->{LOEId} 
# $tab  is not:         $self->{IsNot} 
# $tab  IsPrimary:      $self->{IsPrimary}
# $tab  Review Status:  $self->{ReviewStatusId}
# $tab  Deprecated:     $self->{Deprecated}
# $tab  Evidence:       $evidenceString
# $tab  GusObjectId:    $gusInstance";

    return
" $tab INSTANCE gusId: $gusId LOE Id: $self->{LOEId} isnot: $self->{IsNot} Pri: $self->{IsPrimary}  RS: $self->{ReviewStatusId} Dep: $self->{Deprecated} Ev: $evidenceString  ";
}

1;
