#! /usr/bin/perl 
#
# MakeLoadAffyArrayDesignInput.pl
# R. Gorski upon a previous script by H. He.
# This script generates the data file that can be used by 
# GUS::Supported::Plugin::LoadArrayDesign
# to load Affymetrix chips into RAD. 
# It uses the Bio::Expression bioperl package (and a couple of modified 
# modules in this package)
#
# There are three input files: target_file, probe_tab_file, and CDF file, 

use strict;

use DBI;
use DBD::Oracle;

use Getopt::Long;
use CBIL::Util::PropertySet;

use GUS::Community::AffymetrixArrayFileReader;

my ($targetFile, $probeFile, $cdfFile, $designElementType, $polymerType, $physicalBioSequenceType, $verbose, $help, $gusConfigFile, $out, $designElementIdArg, $polymerIdArg, $physicalBioSequenceIdArg, $genbankExtDbRelId, $genbankExtDbSpec, $refseqExtDbRelId, $refseqExtDbSpec, $customTarget);

# The Arguments which are ID's are left in for back compatability and shouldn't be used otherwise

&GetOptions('help|h' => \$help, 
            'target_file=s' => \$targetFile,
            'probe_tab_file=s' => \$probeFile,
            'cdf_file=s' => \$cdfFile,
            'design_element_type=s' => \$designElementType,
            'design_element_type_id=i' => \$designElementIdArg,
            'polymer_type=s' => \$polymerType, 
            'polymer_type_id=i' => \$polymerIdArg, 
            'physical_biosequence_type=s' => \$physicalBioSequenceType,
            'physical_biosequence_type_id=i' => \$physicalBioSequenceIdArg,
            'genbank_ext_db_rel_id=i' => \$genbankExtDbRelId,
            'genbank_ext_db_spec=s' => \$genbankExtDbSpec,
            'refseq_ext_db_rel_id=i' => \$refseqExtDbRelId,
            'refseq_ext_db_spec=s' => \$refseqExtDbSpec,
            'gus_config_file=s' => \$gusConfigFile,
            'output_file=s' => \$out,
            'non_fasta_target_file' => \$customTarget,
            'verbose' => \$verbose,
           );

&checkArgs();

my $dbh = &connectToDatabase();

my $targetType = $customTarget ? 'customTarget' : 'target';

my $cdfReader =  GUS::Community::AffymetrixArrayFileReader->new($cdfFile, 'cdf', $dbh);
my $probeReader =  GUS::Community::AffymetrixArrayFileReader->new($probeFile, 'probe', $dbh);
my $targetReader = GUS::Community::AffymetrixArrayFileReader->new($targetFile, $targetType, $dbh);

&setupExtDbStuff($targetReader);

my $array = $cdfReader->readFile();
my $probeMap = $probeReader->readFile();
my $targetMap = $targetReader->readFile();

my $designElementTypeId = $designElementIdArg ? $designElementIdArg : &getOntologyEntryId($designElementType, 'DesignElement', $dbh);
my $polymerTypeId = $polymerIdArg ? $polymerIdArg : &getOntologyEntryId($polymerType, 'PolymerType', $dbh);
my $physicalBioSequenceTypeId = $physicalBioSequenceIdArg ? $physicalBioSequenceIdArg : &getOntologyEntryId($physicalBioSequenceType, 'PhysicalBioSequenceType', $dbh);

&printLoadArrayDesignInput($array, $probeMap, $targetMap, $designElementTypeId, $polymerTypeId, $physicalBioSequenceTypeId);

$dbh->disconnect();

#-------------------------------------------------------------------------------
#  SUBROUTINES
#-------------------------------------------------------------------------------

sub checkArgs {

  &usage() if($help);

  unless($targetFile && $probeFile && $cdfFile && $out) {
    &usage();
  }

  unless($designElementIdArg || $designElementType) {
    &usage("Must provide either [design_element_type] OR [design_element_type_id]");
  }

  unless($polymerIdArg || $polymerType) {
    &usage("Must provide either [polymer_type] OR [polymer_type_id]");
  }

  unless($physicalBioSequenceIdArg || $physicalBioSequenceType) {
    &usage("Must provide either [physical_biosequence_type] OR [physical_biosequence_type_id]");
  }

  unless($gusConfigFile && -e $gusConfigFile) {
    $gusConfigFile = $ENV{GUS_HOME} .  "/config/gus.config";
  }

}

#-------------------------------------------------------------------------------

sub setupExtDbStuff {
  my ($reader) = @_;

  return if($customTarget);

  if(!$genbankExtDbRelId || !$refseqExtDbRelId) {
    $genbankExtDbRelId = $reader->retrieveExtDbRlsIdFromSpec($genbankExtDbSpec);
    $refseqExtDbRelId = $reader->retrieveExtDbRlsIdFromSpec($refseqExtDbSpec);
  }

  $reader->addToExternalDatabaseMap('Genbank', $genbankExtDbRelId);
  $reader->addToExternalDatabaseMap('RefSeq', $refseqExtDbRelId);
}

#-------------------------------------------------------------------------------

sub printLoadArrayDesignInput {
  my ($array, $probeMap, $targetMap, $designElementTypeId, $polymerTYpeId, $physicalBioSequenceTypeId) = @_;


  print STDERR "Write OUTput to $out\n";
  open(OUT, "> $out") or die "Cannot open file $out for writing: $!";

  my $header = join "\t","x_pos", "y_pos", "sequence", "match", "name", "ext_db_rel_id", "source_id", "design_element_type_id", 
  "polymer_type_id", "physical_biosequence_type_id";

  print OUT $header, "\n";

  foreach my $set ($array->each_featuregroup) {
    my $name = $set->id;
    $name =~ s/\s+$//;

    # sort probe pairs based on their x_position, then by y_position
    my @sorted_ftrs = sort {$a->x <=> $b->x || $a->y <=> $b->y} $set->each_feature;

    foreach my $ftr (@sorted_ftrs) {
      my $key = join "\t", $name, $ftr->x, $ftr->y;
      my $probeSequence = $probeMap->{$key} || "";

      my $sourceId = $targetMap->{$name}->{source_id};
      my $extDbRlsId = $targetMap->{$name}->{ext_db_rls_id};

      my $xpos = $ftr->x;
      my $ypos = $ftr->y;

    if(!$sourceId || !$name) {
      print STDERR "$name\t$xpos\t$ypos\t$probeSequence\t$sourceId\n" if($verbose);
    }

      print OUT join "\t", $xpos, 
        $ypos, 
          $probeSequence, 
            $ftr->is_match, 
              $name, 
                $extDbRlsId, 
                  $sourceId, 
                    $designElementTypeId, 
                      $polymerTypeId, 
                        $physicalBioSequenceTypeId; 
      print OUT "\n";
    }
  }
  close(OUT);
}

#-------------------------------------------------------------------------------

sub getOntologyEntryId {
  my ($value, $category, $dbh) = @_;

  my $sql = "select ontology_entry_id from Study.OntologyEntry where value = ? and category = ?";

  my $sh = $dbh->prepare($sql);
  $sh->execute($value, $category);

  my $rv;
  unless( ($rv) = $sh->fetchrow_array()) {
    die "No ontologyEntry with value of $value and category of $category";
  }
  return($rv);
}

#-------------------------------------------------------------------------------

sub connectToDatabase {

  my @properties = ();
  my $gusconfig = CBIL::Util::PropertySet->new($gusConfigFile, \@properties, 1);

  my $u = $gusconfig->{props}->{databaseLogin};
  my $pw = $gusconfig->{props}->{databasePassword};
  my $dsn = $gusconfig->{props}->{dbiDsn};

  my $dbh = DBI->connect($dsn, $u, $pw) or die DBI::errstr;

  return($dbh);
}

#-------------------------------------------------------------------------------

sub usage {
  my ($m) = @_;

  print STDERR $m."\n" if($m);
  print STDERR "usage: perl makeLoadArrayDesignInput \\
target_file < \"affy_probe<TAB>source_id<TAB>external_database_SPEC(NM|VERSION)\"> \\
probe_tab_file <AFFY PROBE TAB FILE> \\
cdf_file <AFFY CDF FILE> \\
[design_element_type] <study::OntologyEntry with category=DesignElement>  \\
[design_element_type_id]   \\
[polymer_type] <study::OntologyEntry with category=PolymerType> \\
[polymer_type_id]  \\
[physical_biosequence_type] <study::OntologyEntry with category=PhysicalBioSequenceType>  \\
[physical_biosequence_type_id]  \\
[genbank_ext_db_spec] ex:  Entrez gene|2005-10-13\\
[genbank_ext_db_rel_id] \\
[refseq_ext_db_spec] ex:  NCBI RefSeq|2005-10-13\\
[refseq_ext_db_rel_id] \\
output_file <OUTFILE>
";
  exit();
}


1;
