package GUS::GOPredict::GoGraph;

use strict;
use GUS::GOPredict::GoTerm;
use CBIL::Util::Disp;
use Carp;

#param $goArray
#each entry = array representing one go term row
#each row = [realGoId][GusGoId][childGusId]
sub new{
    my ($class, $goArray, $functionRootGoId, $realGoIdMap) = @_;
    my $self = {};
    bless $self, $class;
    $self->setGoSynMap($realGoIdMap);
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

#param $goArray
#each entry = array representing one go term row
#each row = [realGoId][GusGoId][childGusId]
sub newFromResultSet{
    my ($class, $goVersion, $goResultSet, $functionRootGoId, $realGoIdMap) = @_;
    my $self = {};
    bless $self, $class;
    $self->setGoSynMap($realGoIdMap);

    while (my ($realId, $gusId, $childGusId) = $goResultSet->fetchrow_array()){

	my $goTerm = $self->makeGoTerm($goVersion, $gusId, $realId, $functionRootGoId);
	
	if ($childGusId){
	    my $childGoTerm = $self->makeGoTerm($goVersion, $childGusId, undef, $functionRootGoId);
	    
	    $goTerm->addChild($childGoTerm);
	    #DTB: Make sure don't add child twice; depends on query
	}
    } 

    return $self;
}
    
sub makeGoTerm{
    my ($self, $goVersion, $gusId, $realId, $functionRootGoId) = @_;
 
    my $goTerm = $self->getGoTermFromGusGoId($gusId);
    
    if ($goTerm){
	if(!$goTerm->getRealId() && $realId){   #previously added child with no real id set yet
            	                             #still might not be there because GO Term 
	    $goTerm->setRealId($realId);     #is being made as a child again	
	    $self->_addGoTermToRealIdHash($goTerm); 
	}
    }

    else{
	$goTerm = GUS::GOPredict::GoTerm->new($goVersion, $realId, $gusId);

	$self->addGoTerm($goTerm);

	if ($realId eq $functionRootGoId){
	    print STDERR "GoGraph: Setting root term with go id $functionRootGoId\n";
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
	my $oldTermRealId = $oldTerm->getRealId();
	my $newTerm = $newGraph->getGoTermFromRealGoId($oldTerm->getRealId());
	#&confess ("no new term for old id $oldTermRealId\n") if !$newTerm;
	
	$goTermMap->{$oldTerm} = $newTerm;
	$goTermMap->{$newTerm} = $oldTerm;
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

sub setGoSynMap{
    my ($self, $goSynMap) = @_;
    
    $self->{GoSynMap} = $goSynMap;
}

sub getGoSynMap{
    my ($self) = @_;
    return $self->{GoSynMap};
}

sub getRealIdFromGoSynMap{

    my ($self, $realIdIn) = @_;
    my $realId;
    if ($self->getGoSynMap()){
	$realId = $self->getGoSynMap()->{$realIdIn};
    }
    $realId = $realIdIn if !$realId;
    return $realId;
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
