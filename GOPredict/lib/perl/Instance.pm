package GUS::GOPredict::Instance;

use strict;
use Carp;

my $nextId = 10000;
sub new{
    my ($class, $id) = @_;
    my $self = {};
    bless $self, $class;
    
    $id = $nextId++ unless $id;
    $self->setId($id);
    return $self;

}

sub getReviewStatusId{
    my ($self) = @_;
    return $self->{ReviewStatusId};
}

sub setReviewStatusId{
    my ($self, $reviewStatusId) = @_;
    $self->{ReviewStatusId} = $reviewStatusId;
}

sub getId{
    my ($self) = @_;
    return $self->{Id};
}

sub setId{
    my ($self, $id) = @_;
    $self->{Id} = $id;
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

    return $newInstance;

}

sub cloneNotPrimary{
    my ($self) = @_;
    
    my $newInstance = $self->clone();
    $newInstance->setIsPrimary(0);
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
 
    return "$tab InstanceId: $self->{Id}  LOE Id: $self->{LOEId}  IsPrimary: $self->{IsPrimary}";
}

1;
