package GUS::GOPredict::GoTerm;

use strict;

my $rootObsoleteGoId = 'GO:999';

sub new{
    my ($class, $realId, $gusId) = @_;

    my $self = {};
    bless $self, $class;
    
    $self->setRealId($realId);
    $self->setGusId($gusId);
    $self->{Children} = [];
    $self->{Parents} = [];

    return $self;

    #if child of obsolete, MAKE SURE TO SET OBSOLETE BIT
    #DTB: see addParent
}

sub getRealId{
    my ($self) = @_;
    return $self->{RealId};
}

sub toString{
    my ($self) = @_;
    return "Real id: " . $self->{RealId} . " GusId: " . $self->{GusId} . " obsolete: " . $self->isObsolete() . " obsoleteRoot: " . $self->getIsObsoleteRoot(); 
}

sub toStringFull{
    my ($self, $tab) = @_;

    my $s = $tab . $self->toString() . "\n";
    foreach my $child (@{$self->{Children} }) {
	$s .= $child->toStringFull("\t$tab");
    }
	
    return $s; 
}

sub getGusId{
    my ($self) = @_;
    return $self->{GusId};
}

sub setRealId{
    my ($self, $realId) = @_;
    $self->{RealId} = $realId;
}

sub setGusId{
    my ($self, $gusId) = @_;
    $self->{GusId} = $gusId;
}

#Term Id is the obsolete GO Term Id
sub getIsObsoleteRoot{
    my ($self) = @_;
    return $self->getRealId() eq $rootObsoleteGoId;
}

sub isObsolete{
    my ($self) = @_;
    return $self->{Obsolete};
}

sub _setObsolete{
    my ($self) = @_;
    $self->{Obsolete} = 1;
}

sub getChildren{
    my ($self) = @_;
    return $self->{Children};
}

sub getParents{
    my ($self) = @_;
    return $self->{Parents};
}

sub _addParent{
    my ($self, $parentGoTerm) = @_;
    if ($parentGoTerm->getIsObsoleteRoot()){
	$self->_setObsolete();
    }
    push(@{$self->{Parents}}, $parentGoTerm);
}

sub addChild{
    my ($self, $childGoTerm) = @_;
    
    push(@{$self->{Children}}, $childGoTerm);

    $childGoTerm->_addParent($self);

    if ($self->isObsolete()){
	$childGoTerm->_setObsolete();
    }

}

1;


