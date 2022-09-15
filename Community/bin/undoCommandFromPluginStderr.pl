#!/usr/bin/perl

use strict;

use Data::Dumper;

my $errFile = ".command.err";

if($ARGV[0]) {
  $errFile = $ARGV[0];
}

open(FILE, $errFile) or die "Cannot open $errFile for reading: $!";

my %res;
while(<FILE>) {
  chomp;

  if(/PLUGIN|AlgInvocationId/) {
    my @a = split(/\t/, $_);
    $res{$a[1]} = $a[2];
  }
}
close FILE;

my $plugin = $res{'PLUGIN'};
my $algInvocationId = $res{'AlgInvocationId'};

die unless($plugin && $algInvocationId);

print "ga GUS::Community::Plugin::Undo --plugin $plugin --algInvocationId $algInvocationId --commit\n";
