package GUS::GOPredict::Evidence;

use strict;
use Carp;

sub new{
    my ($class, $gusEvidenceObject) = @_;
    my $self = {};
    bless $self, $class;
    
    $self->setGusEvidenceObject($gusEvidenceObject) if $gusEvidenceObject;

    return $self;

}

sub setGusEvidenceObject{
    my ($self, $gusEvidenceObject) = @_;
    $self->{GusEvidenceObject} = $gusEvidenceObject;
}

sub getGusEvidenceObject{
    my ($self) = @_;
    return $self->{GusEvidenceObject};
}

sub toString{
    my ($self) = @_;
    return $self->getGusEvidenceObject();
}

1;
