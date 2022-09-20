#!/usr/bin/perl

use strict;

use Data::Dumper;

my $errFile = ".command.err";

if($ARGV[0]) {
  $errFile = $ARGV[0];
}

my $force = $ARGV[1];

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

unless($plugin && $algInvocationId) {
  if($force) {
    print STDERR "WARN:  Skipping file because we could not find plugin namd and algInvocationId: $errFile\n";
    exit;
  }
  else {
    die "could not find plugin namd and algInvocationId: $errFile";
  }
}

print "ga GUS::Community::Plugin::Undo --plugin $plugin --algInvocationId $algInvocationId --commit\n";

