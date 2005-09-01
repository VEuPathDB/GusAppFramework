#! /usr/bin/perl -w
#
# MakeLoadAffyArrayDesignInput.pl
# Written by R. Gorsky upon a previous script by H. He.
# This script generates the data file that can be used by 
# GUS::Supported::Plugin::LoadArrayDesign
# to load Affymetrix chips into RAD. 
# It uses the Bio::Expression bioperl package (and a couple of modified 
# modules in this package)
#
# There are three input files: target_file, probe_tab_file, and CDF file, 
# all of which can be downloaded from www.affymetrix.com 
#

use strict;
use Getopt::Long;
use GUS::Community::ArrayDesign;
use Bio::Expression::FeatureGroup;

my %opts = ();
my $result = GetOptions(\%opts,'help|h', 'target_file=s','probe_tab_file=s','cdf_file=s','testnumber=i');

if ($opts{'help'}) {
  print "Usage: perl generate-arrayload.pl --target target_file --probe probe_tab_file --cdf cdf_file [-testnumber n] > out_file\n";
  exit;
}

#my $array = Bio::Expression::Microarray::Affymetrix::ArrayDesign->new();
my $array = ArrayDesign->new();

my $target_file = $opts{'target_file'} 
  || die "Please specify the target file for the Affymetrix chip by [-target_file target_file]\n";
my $probe_file = $opts{'probe_tab_file'} 
  || die "Please specify the probe set file for the Affymetrix chip by [-probe_tab_file probe_tab_file]\n";
my $cdf_file = $opts{'cdf_file'} 
  || die "Please specify the CDF file for the Affymetrix chip by [-cdf_file cdf_file]\n";
my $testnumber = $opts{'testnumber'};

print STDERR "Please make sure the CDF file does not have ^M characters. Otherwise, run dos2unix to convert the file first!\n";

# read target file
my $gb_map_ref = &load_target_file($target_file);

# read probe_tab file
my $probe_map_ref = &load_probe_file($probe_file);

my $c = 0;
# read CDF files
open CDF, $cdf_file;
print STDERR "reading CDF file $cdf_file...\n";
while(<CDF>) {
  chomp;
  $array->load_data($_);
  $c++; 
  last if ($testnumber && $c>=$testnumber);
}
close(CDF);
print STDERR "finished reading CDF file $cdf_file.\n";

# QC feature sets
# need only x, y information
# my @qcfeatureset = $array->each_qcfeatureset();
# foreach my $qcset (@qcfeatureset) {
#    foreach my $qcftr ($qcset->each_feature) {
#	 print join "\t","QC", $qcftr->x, $qcftr->y, "\n";
#     }
#}

my $header = join "\t","x_pos", "y_pos", "sequence", "match", "name", "ext_db_rel_id", "source_id", "element_type_id";
print $header, "\n";

# each featuregroup corresponds to a unique probe set
# need x, y, is_match information for each probe
# sequence derived from PM (probe_tab_file) 

my $ele_type_id = 2739;

my @featuregroup = $array->each_featuregroup();
my ($set, $name, $ftr);
foreach $set ($array->each_featuregroup) {
  $name = $set->id;
  $name =~ s/\s+$//;

  # sort probe pairs based on their x_position, then by y_position
  # PM and MM pair has the same x_position, with PM on top of MM	
  my @sorted_ftrs = sort {$a->x <=> $b->x || $a->y <=> $b->y} $set->each_feature;

  foreach $ftr (@sorted_ftrs) {
    my $key = join "\t", $name, $ftr->x, $ftr->y;
    my $probe_seq = $probe_map_ref->{$key} || "";
    my $gb = $gb_map_ref->{$name} || "";
 
    my $ext_db_rel_id = 2; #GenBank

    if ($gb eq "") {
      $ext_db_rel_id = "";
    } elsif ($gb =~ /^NM_/) {
      $ext_db_rel_id = 992; #RefSeq
    }

    print join "\t", $ftr->x, $ftr->y, $probe_seq, $ftr->is_match, $name, $ext_db_rel_id, $gb, $ele_type_id; 
    print "\n";
  }
}

# retrieve source_id for each probe set (CompositeElement)
#----------------------
sub load_target_file {
#----------------------
  my ($target_file) = @_;

  print STDERR "reading target_file $target_file\n";

  open TARGET, "grep \">target\" $target_file |"; 

  my %gb_map;

  while(<TARGET>){
    chomp;
    my ($id, $source, $res) = split(/;/, $_, 3);

    my $gb;

    my $probe_set = (split(/:/,$id))[2]; 

    #$gb= $1 if ($F[1] =~ /gb\|([\w\_\.]+)$/);

    $source =~ s/^\s//;
    $res =~ s/^\s//;

    if ($source =~ /^gb\|([\w\_]+)(\.\d)?$/) {
      $gb = $1; # if source_id has version number, e.g., gb|NM_030770.1, trim it off
    } else {
       if ($res =~ /gb:([\w\_]+)(\.\d)?\s/) {
         $gb = $1;
       } elsif ($res =~ /^\"?([A-Z]+\d+)\s/) {
         $gb = $1;
       } elsif ($res =~ /gb=(\w+)\s/) {
         $gb = $1;
       }
       
    } 
    $gb_map{$probe_set} = $gb;
  }
  return \%gb_map;
}

# retrieve probe sequence info for each probe pair (PM only) (Element)
#--------------------
sub load_probe_file {
#--------------------
  my ($probe_file) = @_;

  my %probe_map;

  print STDERR "reading probe_tab_file $probe_file\n";

  my $header = 0;
  my %fields;

  open PROBE, "$probe_file";
  while(<PROBE>){
    chomp;
    my @F = split(/\t/);

    unless ($header) {
      foreach my $i (0..$#F) {
        $fields{"$F[$i]"} = $i;
      }
      $header = 1;
      next;
    }
    
    my $key = join "\t", $F[$fields{"Probe Set Name"}], $F[$fields{"Probe X"}], $F[$fields{"Probe Y"}]; #probe_set x_pos y_pos
    $probe_map{$key} = $F[$fields{"Probe Sequence"}];
  }
  return \%probe_map;
}

