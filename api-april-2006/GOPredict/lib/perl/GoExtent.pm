package GUS::GOPredict::GoExtent;

use GUS::GOPredict::TestSth;
use GUS::GOPredict::TestAdapter;
use GUS::GOPredict::Association;

use strict;
use Carp;

sub new{

    my ($class, $adapter) = @_;
    my $self = {};
    bless $self, $class;
    $self->setAdapter($adapter);
    return $self;
}

sub setAdapter{
    my ($self, $adapter) = @_;
    $self->{Adapter} = $adapter;
}

sub getAdapter{
    my ($self) = @_;
    return $self->{Adapter};
}

sub _setAssociation{

     my ($self, $gusAssociation) = @_;

     $self->{AssocIdHash}->{$gusAssociation->getGoAssociationId()} = $gusAssociation;

     $self->{GoIdHash}->{$gusAssociation->getGoTermId()} = $gusAssociation;

}

sub toString{
    my ($self) = @_;
    my $s = "extent: list of go ids:\n";
    foreach my $gusGoId (keys %{$self->{GoIdHash}}){
	$s .= "$gusGoId, ";
    }
    return $s;
}

sub getGusAssociationFromId{
    
    my ($self, $assocId) = @_;
    my $gusAssociation = $self->{AssocIdHash}->{$assocId};
    if (!$gusAssociation){
	$gusAssociation = $self->getAdapter()->getGusAssociationFromId($assocId);
       
	$self->_setAssociation($gusAssociation);
    }
    
    return $gusAssociation;
}

sub empty{
    my ($self) = @_;
    undef %{$self->{GoIdHash}};
    undef %{$self->{AssocIdHash}};

}

sub getGusAssociationFromGusGoId{

    my ($self, $gusGoId) = @_;

    my $gusAssociation = $self->{GoIdHash}->{$gusGoId};
    
    #for now assume that only ask by go id if already checked out from db

    return $gusAssociation;

}


1;
