package GUS::GOPredict::GoTerm;

use strict;

my $rootObsoleteGoId = 'GO:0008369';

sub new{
    my ($class, $version, $realId, $gusId) = @_;

    my $self = {};
    bless $self, $class;
    $self->setVersion($version);
    $self->setRealId($realId);
    $self->setGusId($gusId);
    $self->{Children} = [];
    $self->{Parents} = [];

    return $self;

    #if child of obsolete, MAKE SURE TO SET OBSOLETE BIT
    #DTB: see addParent
}

sub toString{
    my ($self) = @_;

   my $parents = $self->getParents();
   my @parentsGoIds;
   foreach my $parent(@$parents){
       push (@parentsGoIds, $parent->getGusId());
   }
   my $parentsGo = join (',', @parentsGoIds); 

   my $kids = $self->getChildren();
   my @kidsGoIds;
   foreach my $kid(@$kids){
       push (@kidsGoIds, $kid->getRealId());
   }
   my $kidsGo = join (',', @kidsGoIds); 
    #dtb eventually put obsolete, obsolete root in here 
    return "Real id: " . $self->{RealId} . " GusId: " . $self->{GusId} . " Obsolete: " . $self->{Obsolete} . " Parents: $parentsGo";
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

sub setGusId{
    my ($self, $gusId) = @_;
    $self->{GusId} = $gusId;
}

sub getVersion{
    my ($self) = @_;
    return $self->{Version};
}

sub setVersion{
    my ($self, $version) = @_;
    $self->{Version} = $version;
}

sub setRealId{
    my ($self, $realId) = @_;
    $self->{RealId} = $realId;
}


sub getRealId{
    my ($self) = @_;
    return $self->{RealId};
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


