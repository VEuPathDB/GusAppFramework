package GUS::Community::RadAnalysis::Test::TestAbstractProcessor;
use base qw(Test::Unit::TestCase); 

use strict;

use XML::Simple;

use Data::Dumper;

use Error qw(:try);

my $abstractProcessor;

sub set_up {
  $abstractProcessor = _TestProcessor->new({});
}

#--------------------------------------------------------------------------------

sub test_standardParameterValues {
  my $self = shift;

  # Should work with no value
  my $nullInput;
  my $shouldBeNull =  $abstractProcessor->standardParameterValues($nullInput);
  $self->assert_null($shouldBeNull);

  my $nonArrayInput = {};
  try {
    $abstractProcessor->standardParameterValues($nonArrayInput);
    $self->assert(0);
  } catch GUS::Community::RadAnalysis::InputError with { };

  my $paramValues = ['param_1|1',
                     'param_2|2',
                     'param_3|3',
                    ];

  my $out = $abstractProcessor->standardParameterValues($paramValues);
  $self->assert_equals(1, $out->{param_1});
  $self->assert_equals(2, $out->{param_2});
  $self->assert_equals(3, $out->{param_3});
}

#--------------------------------------------------------------------------------

sub test_standardLogicalGroupInputs {
  my $self = shift;

  # Should work with no value
  my $nullInput;
  my $emptyHash =  $abstractProcessor->standardLogicalGroupInputs($nullInput);
  $self->assert_equals('HASH', ref($emptyHash));

  my $nonArrayInput = {};
  try {
    $abstractProcessor->standardLogicalGroupInputs($nonArrayInput);
    $self->assert(0);
  } catch GUS::Community::RadAnalysis::InputError with { };

  my $paramValues = ['logical_group_1|1.1',
                     'logical_group_1|1.2',
                     'logical_group_1|1.3',
                     'logical_group_2|2.1',
                     'logical_group_2|2.2',
                     'logical_group_3|3.1',
                     'logical_group_3|3.2',
                    ];

  my $out = $abstractProcessor->standardLogicalGroupInputs($paramValues);

  my @orderedLogicalGroupNames = keys %$out;
  $self->assert_str_equals('logical_group_1', $orderedLogicalGroupNames[0]);
  $self->assert_str_equals('logical_group_2', $orderedLogicalGroupNames[1]);
  $self->assert_str_equals('logical_group_3', $orderedLogicalGroupNames[2]);

  my $logicalGroup1 = $out->{logical_group_1};
  $self->assert_equals(3, scalar(@$logicalGroup1));

  $self->assert_equals('1.1', $logicalGroup1->[0]);
  $self->assert_equals('1.2', $logicalGroup1->[1]);
  $self->assert_equals('1.3', $logicalGroup1->[2]);

  my $logicalGroup3 = $out->{logical_group_3};
  $self->assert_equals(2, scalar(@$logicalGroup3));

  $self->assert_equals('3.1', $logicalGroup3->[0]);
  $self->assert_equals('3.2', $logicalGroup3->[1]);

}




sub test_makeStandardLogicalGroups {}
sub test_queryForArrayTable {}
sub test_queryForElements {}
sub test_addElementData {}
sub test_getSqlHandle {}
sub test_makeLogicalGroup {}
sub test_makeLogicalGroupLinks {}
sub test_queryForTable {}
sub test_createDataMatrixFromLogicalGroups {}
sub test_retrieveProtocolFromName {}
sub test_setProtocolParams {}


#================================================================================

package _TestProcessor;
use base qw(GUS::Community::RadAnalysis::AbstractProcessor);

sub new {
  shift()->SUPER::new(@_);
}

#================================================================================


package GUS::Community::RadAnalysis::Test::TestAbstractProcessor;


1;



