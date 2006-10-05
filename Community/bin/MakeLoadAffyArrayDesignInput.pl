#! /usr/bin/perl 
#
# MakeLoadAffyArrayDesignInput.pl
# Written by R. Gorski upon a previous script by H. He.
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
use Bio::Expression::FeatureGroup;

use GUS::Community::AffymetrixArrayFileReader;

my ($target_file, $probe_file, $cdf_file, $genbank_ext_db_rel_id, $refseq_ext_db_rel_id, $ele_type_id, $polymer_type, $phys_bioseq_type, $requireSourceAndAffyName, $verbose, $help);

&GetOptions('help|h' => \$help, 
            'target_file=s' => \$target_file,
            'probe_tab_file=s' => \$probe_file,
            'cdf_file=s' => \$cdf_file,
            'genbank_ext_db_rel_id=s' => \$genbank_ext_db_rel_id,
            'refseq_ext_db_rel_id=s' => \$refseq_ext_db_rel_id,
            'design_element_type=s' => \$ele_type_id,
            'polymer_type_id=s' => \$polymer_type, 
            'physical_biosequence_type_id=s' => \$phys_bioseq_type,
            'require_source_and_affy_name' => \$requireSourceAndAffyName,
            'verbose' => \$verbose,
           );

if ($help) {
  print "Usage: perl MakeLoadAffyArrayDesignInput.pl  --target target_file --probe probe_tab_file --cdf cdf_file  --genbank_ext_db_rel_id external database release id for GenBank; can be found in SRes.ExternalDatabaseRelease --refseq_ext_db_rel_id external database release id for RefSeq; can be found in SRes.ExternalDatabaseRelease --design_element_type design_element_type_id for the elements (short oligos) on the Affymetrix chip; can be found in Study.OntologyEntry --polymer_type_id  polymer type for elements on the Affymetrix Chip; can be found in Study.OntologyEntry --physical_biosequence_type_id  physical_biosequence type id for the elements on the Affymetrix Chip; can be found in Study.OntologyEntry > out_file\n";
  exit;
}


my $cdfReader =  GUS::Community::AffymetrixArrayFileReader->new($cdf_file, 'cdf');
my $targetReader =  GUS::Community::AffymetrixArrayFileReader->new($target_file, 'target');
my $probeReader =  GUS::Community::AffymetrixArrayFileReader->new($probe_file, 'probe');

my $array = $cdfReader->readFile();
my $gb_map_ref = $targetReader->readFile();
my $probe_map_ref = $probeReader->readFile();

my $header = join "\t","x_pos", "y_pos", "sequence", "match", "name", "ext_db_rel_id", "source_id", "design_element_type_id", 
  "polymer_type_id", "physical_biosequence_type_id";
print $header, "\n";

# each featuregroup corresponds to a unique probe set
# need x, y, is_match information for each probe
# sequence derived from PM (probe_tab_file) 

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
 
    my $ext_db_rel_id = $genbank_ext_db_rel_id; #GenBank

    if ($gb eq "") {
      $ext_db_rel_id = "";
    } elsif ($gb =~ /^NM_/) {
      $ext_db_rel_id = $refseq_ext_db_rel_id; #RefSeq
    }

    my $xpos = $ftr->x;
    my $ypos = $ftr->y;

    if($requireSourceAndAffyName && (!$gb || !$name)) {
      print STDERR "$name\t$xpos\t$ypos\t$probe_seq\t$gb\n" if($verbose);
      next;
    }

    print join "\t", $xpos, $ypos, $probe_seq, $ftr->is_match, $name, $ext_db_rel_id, $gb, $ele_type_id, $polymer_type, $phys_bioseq_type; 
    print "\n";
  }
}

