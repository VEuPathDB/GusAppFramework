package GUS::GOPredict::GoGraph;

use strict;
use GUS::GOPredict::GoTerm;
use CBIL::Util::Disp;


#param $goArray
#each entry = array representing one go term row
#each row = [realGoId][GusGoId][childGusId]
sub new{
    my ($class, $goArray, $functionRootGoId) = @_;
    my $self = {};
    bless $self, $class;
    
    foreach my $goRow (@$goArray){
	
	my ($realId, $gusId, $childGusId) = @$goRow;
	my $goTerm = $self->makeGoTerm($gusId, $realId, $functionRootGoId);
	
	if ($childGusId){
	    my $childGoTerm = $self->makeGoTerm($childGusId, undef, $functionRootGoId);
	    
	    $goTerm->addChild($childGoTerm);
	    #DTB: Make sure don't add child twice; depends on query
	}
    } 

    return $self;
}
    
sub makeGoTerm{
    my ($self, $gusId, $realId, $functionRootGoId) = @_;
 
    my $goTerm = $self->getGoTermFromGusGoId($gusId);

    if ($goTerm){
	if(!$goTerm->getRealId() && $realId){   #previously added child with no real id set yet
            	                             #still might not be there because GO Term 
	    $goTerm->setRealId($realId);     #is being made as a child again	
	    $self->_addGoTermToRealIdHash($goTerm); 
	}
    }

    else{
	$goTerm = GUS::GOPredict::GoTerm->new($realId, $gusId);

	$self->addGoTerm($goTerm);

	if ($realId eq $functionRootGoId){
	    $self->setRootTerm($goTerm);
	}
     }
    
    return $goTerm;

}

sub toString{
    my ($self) = @_;
    $self->getRootTerm()->toStringFull("");
}

sub getGoTermFromRealGoId{
    my ($self, $realGoId) = @_;
    my $goTerm = $self->{realIdHash}->{$realGoId};

    return $goTerm;
}

sub addGoTerm{
    my ($self, $goTerm) = @_;
    my $realGoId = $goTerm->getRealId();
    
    $self->{realIdHash}->{$realGoId} = $goTerm;
    $self->{gusIdHash}->{$goTerm->getGusId()} = $goTerm;
}

sub _addGoTermToRealIdHash{
    my ($self, $goTerm) = @_;
    
    $self->{realIdHash}->{$goTerm->getRealId()} = $goTerm;
}

sub _addGoTermToGusIdHash{
    my ($self, $goTerm) = @_;
       
    $self->{gusIdHash}->{$goTerm->getGusId()} = $goTerm;
}




sub makeGoTermMap{

    my ($oldGraph, $newGraph) = @_;
    my $goTermMap;
    my $list = $oldGraph->getAsList();
    foreach my $oldTerm (@$list){
	my $newTerm = $newGraph->getGoTermFromRealGoId($oldTerm->getRealId());
	$goTermMap->{$oldTerm} = $newTerm;
    }
    return $goTermMap;
}

sub getGoTermFromGusGoId{
    my ($self, $gusGoId) = @_;
    return $self->{gusIdHash}->{$gusGoId};
}


sub setRootTerm{
    my ($self, $rootTerm) = @_;
    $self->{RootTerm} = $rootTerm;

}

sub getRootTerm{
    my ($self) = @_;
    return $self->{RootTerm};

}

sub getAsList{
    my ($self) = @_;
    my $goTermList;
    my $goTermHash = $self->{realIdHash};
    foreach my $realGoId (keys %$goTermHash){
	push (@$goTermList, $goTermHash->{$realGoId});
    }
    return $goTermList;
}


1;
