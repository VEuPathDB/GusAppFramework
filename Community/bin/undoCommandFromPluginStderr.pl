#!/usr/bin/perl

use strict;

use Data::Dumper;

my $errFile = ".command.err";

if($ARGV[0]) {
  $errFile = $ARGV[0];
}

my $force = $ARGV[1];

open(FILE, $errFile) or die "Cannot open $errFile for reading: $!";


my ($plugin, $count);
while(<FILE>) {
  chomp;
  my @a = split(/\t/, $_);
  if(/PLUGIN/) {
    $plugin = $a[2];
  }
  if(/AlgInvocationId/ && $plugin) {
    print "ga GUS::Community::Plugin::Undo --plugin $plugin --algInvocationId $a[2] --commit\n";
    $plugin = undef;
    $count++;
  }
}
close FILE;


unless($count) {
  if($force) {
    print STDERR "WARN:  Skipping file because we could not find plugin namd and algInvocationId: $errFile\n";
    exit;
  }
  else {
    die "could not find plugin namd and algInvocationId: $errFile";
  }
}



