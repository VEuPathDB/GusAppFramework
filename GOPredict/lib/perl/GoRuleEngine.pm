package GUS::GOPredict::GoRuleEngine;

use strict;
use Carp;

sub new{
    my ($class) = @_;
    my $self = {};
    bless $self, $class;
    
    return $self;
}

#param $goRuleResultSet:
#result set/statement handle where each entry is of the form
# (Motif Id, Rule Id, Go Term Gus Id (for the rule), 
#     Similarity Score (generally, the pvalue threshold for the rule's set))
sub setGoRulesFromResultSet{

    my ($self, $goRuleResultSet) = @_;
    while (my ($motifId, $ruleId, $gusGoId, $pValueMant, $pValueExp) = $goRuleResultSet->fetchrow_array()){

	my $ruleThreshold = $self->_getPvalue($pValueMant, $pValueExp);
	$self->_addRule($motifId, $ruleId, $gusGoId, $ruleThreshold);
    }
}

#returns list where each entry in the list is of the form (Rule Id, Gus Id for GoTerm in that rule)
sub getRuleSetAsListFromMotif{

    my ($self, $motifId, $motifProteinSimScore) = @_;
    
    my $returnedRuleList;
    my $ruleSets = $self->{RulesHash}->{$motifId};  #get hash where keys are pvalue, values are lists
        
    foreach my $ruleThreshold (keys %$ruleSets){
	
	my ($isGoodSimScore, $ratio) = $self->_isGoodSimScore($motifProteinSimScore, $ruleThreshold);    

	if ($isGoodSimScore){
	    my $ruleThresholdRuleSet = $ruleSets->{$ruleThreshold};
	    
	    foreach my $ruleInfo (@$ruleThresholdRuleSet){
		my $ruleId = $ruleInfo->{ruleId};
		my $gusGoId = $ruleInfo->{gusGoId};
		
		my $returnedRuleInfo;
		$returnedRuleInfo->{ruleId} = $ruleId;
		$returnedRuleInfo->{gusGoId} = $gusGoId;
		$returnedRuleInfo->{ratio} = $ratio;
		push (@$returnedRuleList, $returnedRuleInfo);
	    }
	}
    }
    return $returnedRuleList;
}

sub _isGoodSimScore{
    
    my ($self, $motifProteinSimScore, $ruleThreshold) = @_;
    return 0 if ($motifProteinSimScore == 0 || $ruleThreshold == 0);
    my $logScore = -1*($self->log10($motifProteinSimScore));

    my $logThresholdScore = -1*($self->log10($ruleThreshold));

    my $ratio = $logScore / $logThresholdScore;
   
    my $ratioCutoff = $self->getRatioCutoff();
    my $absoluteCutoff = $self->getAbsoluteCutoff();

    my $goodRatio = ($ratio >= $ratioCutoff);
    my $goodAbsolute = $motifProteinSimScore <= $absoluteCutoff;

    $ratioCutoff = 1 if !$ratioCutoff; 
    $goodAbsolute = 1 if !$absoluteCutoff; #if only specifying one criteria

    my $goodTotalScore = ($goodRatio && $goodAbsolute);
    
    return ($goodTotalScore, $ratio);
}

sub log10 { 
    my ($self, $value) = @_;
    return log($value) / log(10);
}

sub _addRule{

    my ($self, $motifId, $ruleId, $gusGoId, $ruleThreshold) = @_;
    my $ruleInfo;
    $ruleInfo->{ruleId} = $ruleId;
    $ruleInfo->{gusGoId} = $gusGoId;
    push (@{$self->{RulesHash}->{$motifId}->{$ruleThreshold}}, $ruleInfo);
}

sub _getPvalue{
    my ($self, $mantissa, $exponent) = @_;

    return $mantissa*10**$exponent;
}

sub setRatioCutoff{
    my ($self, $ratioCutoff) = @_;
    $self->{RatioCutoff} = $ratioCutoff;
}

sub getRatioCutoff{
    my ($self) = @_;
    return $self->{RatioCutoff};
}

sub setAbsoluteCutoff{
    my ($self, $absoluteCutoff) = @_;
    $self->{AbsoluteCutoff} = $absoluteCutoff;
}

sub getAbsoluteCutoff{
    my ($self) = @_;
    return $self->{AbsoluteCutoff};
}

1;
