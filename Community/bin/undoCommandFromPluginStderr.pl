#!/usr/bin/perl

use strict;

use Data::Dumper;

my $errFile = ".command.err";

if($ARGV[0]) {
  $errFile = $ARGV[0];
}

my $force = $ARGV[1];
my $gusConfigFileArg = $ARGV[2];

open(FILE, $errFile) or die "Cannot open $errFile for reading: $!";

my ($plugin, $workflowStepId, $gusConfigFile, $lastCommand);
while(<FILE>) {
  chomp;
  next unless /\tPLUGIN\t|\tARG\t|\tAlgInvocationId\t|\tTIME\t/;
  my @a = split(/\t/, $_);
  if($a[1] eq 'TIME') {
    $plugin = undef;
    $workflowStepId = undef;
    $gusConfigFile = undef;
  }
  elsif($a[1] eq 'PLUGIN') {
    $plugin = $a[2];
  }
  elsif($a[1] eq 'ARG') {
    if($a[2] eq 'gusConfigFile') {
      $gusConfigFile = $a[3];
    }
    elsif($a[2] eq 'workflowstepid') {
      $workflowStepId = $a[3];
    }
  }
  elsif($a[1] eq 'AlgInvocationId' && $plugin) {
    my $effectiveGusConfig = $gusConfigFileArg || $gusConfigFile;
    if($workflowStepId) {
      my $gusConfigOpt = $effectiveGusConfig ? " --gusConfigFile '$effectiveGusConfig'" : "";
      $lastCommand = "ga GUS::Community::Plugin::Undo --plugin $plugin --workflowContext --undoWorkflowStepId $workflowStepId --algInvocationId '$a[2]'$gusConfigOpt --commit\n";
    } else {
      my $gusConfigOpt = $effectiveGusConfig ? " --gusConfigFile $effectiveGusConfig" : "";
      $lastCommand = "ga GUS::Community::Plugin::Undo --plugin $plugin --algInvocationId $a[2] --commit$gusConfigOpt\n";
    }
  }
}
close FILE;

print $lastCommand if $lastCommand;

unless($lastCommand) {
  if($force) {
    print STDERR "WARN:  Skipping file because we could not find plugin namd and algInvocationId: $errFile\n";
    exit;
  }
  else {
    die "could not find plugin namd and algInvocationId: $errFile";
  }
}



