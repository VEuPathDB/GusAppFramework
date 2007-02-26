package GUS::Community::RadAnalysis::AbstractProcesser;

use strict;

sub new {
  my $class = shift;

  if(ref($class) eq 'AbstractProcesser') {
    GUS::Community::RadAnalysis::ProcesserError->
        new("try to instantiate an abstract class AbstractProcesser")->throw();
  }
  bless {}, $class; 
}

sub process {}

1;

