package GUS::GOPredict::TestAdapter;

use GUS::GOPredict::TestSth;
use GUS::GOPredict::Association;
use GUS::Model::DoTS::AAMotifGOTermRule;
use GUS::Model::DoTS::Similarity;

use strict;
use Carp;

my $proteinTableId = 70;
my $firstProteinRowId = 5555;
my $oldGoVersion = 1;
my $newGoVersion = 2;

sub new{

    my ($class) = @_;
    my $self = {};
    bless $self, $class;

    $self->_initGusAssocIdsByProtein();
    $self->_initGusProteinIds();
    return $self;
}

sub getGusProteinIdResultSet{

    my ($self, $proteinTableId, $queryHandle) = @_;

    my $gusProteinIdArray = $self->_getProteinIds();

    my $testSth = GUS::GOPredict::TestSth->new($gusProteinIdArray);

    return $testSth;
}

#done, needs more data
sub runProteinSimQuery{

    my ($self) = @_;
    my $proteinSimArray = $self->_createProteinSimArray();

    
    my $testSth = GUS::GOPredict::TestSth->new($proteinSimArray);
    return $testSth;
}

#done
sub getGusAssocIdResultSet{

    my ($self, $proteinId) = @_;
    
    my $gusAssocIdArray = $self->_getAssocIdsFromProtein($proteinId);

    my $testSth = GUS::GOPredict::TestSth->new($gusAssocIdArray);
    return $testSth;
}

#just create a rule object and return it
sub getRuleObjectFromId{

    my ($self, $ruleId) = @_;
    my $ruleObject = GUS::Model::DoTS::AAMotifGOTermRule->new();
    $ruleObject->setAaMotifGoTermRuleId($ruleId);
    return $ruleObject;

}

sub submitGusObject{

    my ($self, $gusObject) = @_;
    print STDERR "test: submitting gus object: " .  $gusObject->toString() . "\n";
}


sub getTranslatedProteinId{

    my ($self, $queryId) = @_;
    return $queryId;
}


#done
sub getGusAssociationFromId{

    my ($self, $assocId) = @_;

    my $gusAssociation = $self->{GusAssocObjects}->{$assocId};

    return $gusAssociation;
}

#done
sub getGoResultSet{
    
    my ($self, $goVersion) = @_;

    my $goArray = $self->_createGoArray($goVersion);
    my $testSth = GUS::GOPredict::TestSth->new($goArray);
    return $testSth;
}


sub getGoRuleResultSet{

    my ($self) = @_;

    my $goRuleArray = $self->_createGoRuleArray();
    my $testSth = GUS::GOPredict::TestSth->new($goRuleArray);
    return $testSth;
}

sub _createGoRuleArray{

    my ($self) = @_;
    #motifId, $ruleId, $gusGoId, $simScore
    my $goRuleArray =
	[
	 [7, 0001, 208,  5],
	 [8, 0002, 203,  5],
	 [9, 0003, 204,  5],
	 [7, 0004, 209,  5],
	 [8, 0005, 2014, 5],
	 ];

    return $goRuleArray;
}

sub getSimObjectFromId{

    my ($self, $simId) = @_;

    my $gusSimObject = GUS::Model::DoTS::Similarity->new();

    $gusSimObject->setSimilarityId($simId);
    $gusSimObject->setPvalueMant(2);
    $gusSimObject->setPvalueExp(1);

    return $gusSimObject;
}


sub _createProteinSimArray{

    my ($self) = @_;

    #protein Id MotifId SimId
    my $proteinSimArray =
	[
	 [5555, 7, 100],
	 [5555, 8, 200],
	 [5555, 9, 300],
	 [6666, 25, 400],
	 ];

    return $proteinSimArray;

}

sub _createGoArray{

    my ($self, $goVersion) = @_;
    my $newGoGraphInput = 
	[
	 ['GO:001', 201, 202],
	 ['GO:001', 201, 203],
	 ['GO:001', 201, 20999],   
	 ['GO:002', 202, 204],
	 ['GO:002', 202, 207],
	 ['GO:002', 202, 2013],
	 ['GO:003', 203, 209],  
	 ['GO:004', 204, 2010 ],
	 ['GO:004', 204, 2011 ],
	 ['GO:005', 205, ],
	 ['GO:006', 206, ],
	 ['GO:007', 207, 208],
	 ['GO:008', 208,  ],
	 ['GO:009', 209, 2015],
	 ['GO:0010', 2010, 2012 ],
	 ['GO:0010', 2010, 2016 ],
	 ['GO:0011', 2011, 2012 ],
	 ['GO:0012', 2012,  ],
	 ['GO:0013', 2013, 2014 ],
	 ['GO:0014', 2014, ],
	 ['GO:0015', 2015, ],
	 ['GO:0016', 2016,  ],
	 ['GO:999', 20999, 205 ],
	 ['GO:999', 20999, 206 ],
	 
	 ];

    my $oldGoGraphInput = 
    [
     ['GO:001', 101, 102],
     ['GO:001', 101, 103],
     ['GO:001', 101, 1015],
     ['GO:001', 101, 10999],
     ['GO:002', 102, 105],
     ['GO:002', 102, 107],
     ['GO:002', 102, 1013],
     ['GO:003', 103, 105],
     ['GO:003', 103, 109],
     ['GO:003', 103, 104],
     ['GO:004', 104, 1010 ],
     ['GO:004', 104, 1011 ],
     ['GO:005', 105, 106 ],
     ['GO:006', 106,  ],
     ['GO:007', 107, 108],
     ['GO:008', 108,  ],
     ['GO:009', 109,  ],
     ['GO:0010', 1010, 1012 ],
     ['GO:0011', 1011, 1012 ],
     ['GO:0012', 1012,  ],
     ['GO:0013', 1013, 1014 ],
     ['GO:0014', 1014,  ],
     ['GO:0015', 1015, 1016  ],
     ['GO:0016', 1016,  ],
     ['GO:999', 10999,  ],
     
   ];

    if ($goVersion == $oldGoVersion){
	return $oldGoGraphInput;
    }
    elsif ($goVersion == $newGoVersion){
	return $newGoGraphInput;
    }
    else {
	&confess ("unknown GO version passed in: $goVersion");
    }
}

sub _getProteinIds{

    my ($self) = @_;
    return $self->{ProteinIds};

}


sub _getAssocIdsFromProtein{

    my ($self, $proteinId) = @_;
    my $assocIdArray = $self->{AssocIdsByProtein}->{$proteinId};

    return $assocIdArray;
}

sub _initGusProteinIds{
   my ($self) = @_;
   
   my $proteinIds = [[5555]];
   $self->{ProteinIds} = $proteinIds;


}

sub _initGusAssocIdsByProtein{
    my ($self) = @_;

    my $firstProteinIds = 
	[
	 [1001],
	 [1002],
	 [1003],
	 [1004],
	 [1005],
	 [1006],
	 [10010],
	 [10011],
	 [10012],
	 [10013],
	 [10015],
	 [10016],
	 ];

    $self->{AssocIdsByProtein}->{$firstProteinRowId} = $firstProteinIds;
}

#only meant to be called by test runner; ensures that the correct 
#gus objects are set when requested by RuleApplier/Manager 
sub loadOldGusAssociationObjects{

    my ($self) = @_;
# resultSet:
# GusGoID AssociationId ReviewStatus IsNot InstanceId Instance_LOE_id InstanceReviewStatus Instance.IsNot
    my $assocResultSet = 
	[
	 [101, 1001, 0, 0, , , , , ],
	 [102, 1002, 0, 0, , , , , ],
	 [103, 1003, 0, 0, 100303, 3, 0, 0],
	 [104, 1004, 1, 0, 100403, 3, 0, 0],
	 [104, 1004, 1, 0, 100401, 1, 1, 0],
	 [105, 1005, 0, 0, , , , , ],
	 [106, 1006, 1, 0, 100603, 3, 0, 0],
	 [106, 1006, 1, 0, 100601, 1, 1, 0],
	 [1010, 10010, 1, 1, 1001001, 1, 1, 1],
	 [1010, 10010, 1, 1, 1001003, 3, 0, 0],
	 [1011, 10011, 0, 0, , , , , ],
	 [1012, 10012, 1, 0, 1001203, 3, 0, 0],
	 [1012, 10012, 1, 0, 1001201, 1, 1, 0],     
	 [1013, 10013, 1, 1, 1001301, 1, 1, 1],
	 [1013, 10013, 1, 1, 1001303, 3, 0, 0],
	 [1015, 10015, 0, 0, 1001503, 3, 0, 0],
	 [1016, 10016, 1, 0, 1001603, 1, 1, 0],
	 [1016, 10016, 1, 0, 1001603, 3, 0, 0],
	 
	 ];

    my $gusAssocList = &GUS::GOPredict::Association::makeGUSAssociationObjectsFromResultSet($assocResultSet, 
											    $proteinTableId, 
											    $firstProteinRowId);
    foreach my $gusAssocObject (@$gusAssocList){
	$self->{GusAssocObjects}->{$gusAssocObject->getGoAssociationId()} = $gusAssocObject;
    } 
}

sub loadNewGusAssociationObjects{

    my ($self) = @_;
    
    my $assocResultSet = 
    [
     [201, 1001, 0, 0, , , , , ],
     [202, 1002, 0, 0, , , , , ],
     [203, 1003, 0, 0, 100303, 3, 0, 0],
     [204, 1004, 1, 0, 100403, 3, 0, 0],
     [204, 1004, 1, 0, 100401, 1, 1, 0],
     [205, 1005, 0, 0, , , , , ],
     [206, 1006, 1, 0, 100603, 3, 0, 0],
     [206, 1006, 1, 0, 100601, 1, 1, 0],
     [2010, 10010, 1, 1, 1001001, 1, 1, 1],
     [2010, 10010, 1, 1, 1001003, 3, 0, 0],
     [2011, 10011, 0, 0, , , , , ],
     [2012, 10012, 1, 0, 1001203, 3, 0, 0],
     [2012, 10012, 1, 0, 1001201, 1, 1, 0],     
     [2013, 10013, 1, 1, 1001301, 1, 1, 1],
     [2013, 10013, 1, 1, 1001303, 3, 0, 0],
     [2015, 10015, 0, 0, 1001503, 3, 0, 0],
     [2016, 10016, 1, 0, 1001603, 1, 1, 0],
     [2016, 10016, 1, 0, 1001603, 3, 0, 0],
     
     ];
    
    my $gusAssocList = &GUS::GOPredict::Association::makeGUSAssociationObjectsFromResultSet($assocResultSet, 
											    $proteinTableId, 
											    $firstProteinRowId);
    foreach my $gusAssocObject (@$gusAssocList){

	$self->{GusAssocObjects}->{$gusAssocObject->getGoAssociationId()} = $gusAssocObject;
    } 

}

1;
