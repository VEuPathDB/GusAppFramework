#######################################################################
##                 InsertEntrezGene.pm
##
## Loads (Entrez) Gene from a GFF3 file
## $Id$
##
#######################################################################

package GUS::Community::Plugin::InsertEntrezGene;
@ISA = qw( GUS::PluginMgr::Plugin);

use strict 'vars';


use GUS::PluginMgr::Plugin;
use lib "$ENV{GUS_HOME}/lib/perl";
use FileHandle;
use Carp;
use GUS::Model::DoTS::Gene;

my $argsDeclaration =
  [
   fileArg({ name           => 'inputFile',
             descr          => 'Gene input file, in GFF3 format',
             reqd           => 1,
             mustExist      => 1,
             format         => 'GFF3 format',
             constraintFunc => undef,
             isList         => 0,
           }),
     stringArg({ name  => 'extDbRlsSpec',
                  descr => "The ExternalDBRelease specifier for (Entrez) Gene records to be loaded. Must be in the format 'name|version', where the name must match an name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
                  constraintFunc => undef,
                  reqd           => 1,
                  isList         => 0 }),
   stringArg({ name           => 'hugoExtDbRlsName',
               descr          => 'external database release name for HUGO genes, if they have been loaded',
               reqd           => 0,
               constraintFunc => undef,
               isList         => 0,
             }),
  ];


my $purposeBrief = <<PURPOSEBRIEF;
Load (Entrez) Gene from a GFF3 file
PURPOSEBRIEF

my $purpose = <<PLUGIN_PURPOSE;
Read a GFF3 file from NCBI, putting the genes in GeneFeature, the exons in ExonFeature, and the transcripts in Transcript. Each GeneFeature record will be linked to a Gene record with a new GeneInstance record. HUGO cross-references in the input file will be used to link each GeneFeature to a Gene, provided it has a HGNC cross-reference and Gene has been populated with HUGO. Otherwise, a new Gene record will be created.
PLUGIN_PURPOSE

my $tablesAffected = [
                      ['DoTS.GeneFeature', 'Each input gene record creates a record here'],
                      ['DoTS.ExonFeature', 'Each input exon record creates a record here'],
                      ['DoTS.Transcript', 'Each input transcript record creates a record here'],
                      ['DoTS.Gene', 'Each input gene record is linked to a record in this table. One will be created if needed.'],
                      ['DoTS.GeneInstance', 'Each input gene record creates a record here'],
                      ['DoTS.ExternalNaSequence', 'New records will be created if needed'],
                     ];

my $tablesDependedOn = [
                        ['DoTS.Gene', 'This table will be searched for an existing HUGO gene for each input gene record with an HGNC cross-reference'],
                        ['DoTS.ExternalNaSequence', 'This will be searched for sequences with the given source IDs'],
                       ];

my $howToRestart = <<PLUGIN_RESTART;
No restart facility is provided.
PLUGIN_RESTART

my $failureCases = <<PLUGIN_FAILURE_CASES;
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
PLUGIN_NOTES

my $documentation = { purpose=>$purpose,
                      purposeBrief=>$purposeBrief,
                      tablesAffected=>$tablesAffected,
                      tablesDependedOn=>$tablesDependedOn,
                      howToRestart=>$howToRestart,
                      failureCases=>$failureCases,
                      notes=>$notes
                    };

sub new {
    my ($class) = @_;
    my $self = {};
    bless($self,$class);


    $self->initialize({requiredDbVersion => 4.0,
                       cvsRevision => '$Revision$', # cvs fills this in!
                       name => ref($self),
                       argsDeclaration => $argsDeclaration,
                       documentation => $documentation
                      });

    return $self;
}

#######################################################################
# Main Routine
#######################################################################

sub run {
    my ($self) = @_;
    my $msg;

    my $extDbRlsId = $self->getExtDbRlsId($self->getArg('extDbRlsSpec'));

    open(GENE, $self->getArg('inputFile'));

    my $lastGene;
    my @genesWorth;
    while (<GENE>) {
      chomp;

      next if substr($_, 0, 1) eq "#"; # skip comment lines

      my ($sequence, $source, $type, $etc) = split /\t/;
      if ($type eq "gene" || $type eq "tRNA" || $type eq "J_gene_segment"
          || $type eq "C_gene_segment" || $type eq "D_gene_segment"
	  || $type eq "V_gene_segment") {
	processGene(\@genesWorth)
	  if @genesWorth;
	undef @genesWorth;
      }
      push(@genesWorth, $_);
    }

    return $msg;
}

sub processGene {
  my ($inputArrayRef) = @_;

  foreach my $line (@$inputArrayRef) {
    print "got a line like this: \"$line\"\n";
  }
}

1;
