package GUS::GOPredict::TestSth;

use strict;
use Carp;

sub new{

    my ($class, $array) = @_;
    my $self = {};
    bless $self, $class;
    
    $self->{Array} = $array;
    $self->{Array} = [] if !$array;
    $self->{Counter}= 0;
    return $self;
}

sub addRow{

    my ($self, $row) = @_;
    my $ownArray = $self->{Array};
    my $ownArrayLength = scalar @$ownArray;
    for (my $i = 0; $i < scalar @$row; $i++){
	$ownArray->[$ownArrayLength][$i] = $row->[$i];
    }
}
   
    

sub fetchrow_array{

    my ($self) = @_;

    &confess ("array messed up") if $self->{Array} == 1;
    
    my $array = $self->{Array};
    
    my $rv = $array->[$self->{Counter}];
    $self->{Counter} ++;
    
    ##note: returns an error unless this loop is here 
    ##don't know why but try initializing all sth's with array instead of ArrayRefs and see if that works
    foreach my $newEntry (@$rv){
#	print STDERR $newEntry . "\n";
    }
    my @arrayRv = @$rv;

    return @arrayRv;
}

1;
