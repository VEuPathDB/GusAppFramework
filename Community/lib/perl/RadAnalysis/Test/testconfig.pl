#!/usr/bin/perl

use strict;

use XML::Simple;
use Data::Dumper;

my $xml = XMLin('sampleConfig.xml',  'ForceArray' => 1);

foreach my $process (@{$xml->{process}}) {
  my $class = $process->{class};
  my $properties = $process->{property};

  my $args = {};
  foreach my $property (keys %$properties) {
    $args->{$property} = $properties->{$property}->{value};
  }
}




