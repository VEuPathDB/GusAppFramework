#######################################################################
##                 InsertEntrezGene.pm
##
## Loads (Entrez) Gene from a GFF3 file
## $Id$
##
#######################################################################

package GUS::Community::Plugin::InsertEntrezGene;
@ISA = qw( GUS::PluginMgr::Plugin);

use strict;

use GUS::PluginMgr::Plugin;
use lib "$ENV{GUS_HOME}/lib/perl";
use FileHandle;
use Carp;

use GUS::Model::DoTS::ExternalNASequence;
use GUS::Model::DoTS::Gene;
use GUS::Model::DoTS::GeneFeature;
use GUS::Model::DoTS::GeneInstance;
use GUS::Model::DoTS::Transcript;
use GUS::Model::DoTS::ExonFeature;
use GUS::Model::DoTS::RNAFeatureExon;
use GUS::Model::DoTS::NALocation;

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

my %processedFeatureCount; # top-level features processed, by feature type
my %ignoredFeatureCount;  # top-level features not processed, by feature type
my $totalFeatureCount;   # total number of top-level features processed
my $extDbRlsId;         # Entrez Gene external database release ID
my $hugoQuery;         # prepared query for HUGO genes
my $hugoDbName;       # saved value of HUGO database-name parameter
my $hugoNotFound;    # count of HUGO IDs found in data file but not in database

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

    open(GFF3, $self->getArg('inputFile'));

    my @featuresWorth; # one top-level-feature-sized bite of a GFF3 file

    while (<GFF3>) {
      chomp;
      next if substr($_, 0, 1) eq "#"; # skip comment lines

      if ($_ !~ /Parent=/) { # top-level feature
	$self->processTopLevelFeature(\@featuresWorth)
	  if @featuresWorth;
	undef @featuresWorth;
      }

      push(@featuresWorth, $_);
    }

    $msg = "among top-level features, processed " .
	   join(", ", (map {$processedFeatureCount{$_} . " " . $_; } keys(%processedFeatureCount))) .
            "; ignored " .
	   join(", ", (map {$ignoredFeatureCount{$_} . " " . $_; } keys(%ignoredFeatureCount)));

print "\$msg = \"$msg\"\n";
    return $msg;
}

sub processTopLevelFeature {
  my ($self, $inputArrayRef) = @_;

  # first feature
  my ($sequenceSourceId, $source, $type, $start, $end, $score, $strand, $phase, $attributes)
    = split(/\t/, shift(@{$inputArrayRef}));

  # not handling all top-level feature types
  if ($type ne 'gene' && $type ne 'tRNA'
      && $type ne 'V_gene_segment' && $type ne 'J_gene_segment'
      && $type ne 'C_gene_segment' && $type ne 'D_gene_segment') {
    $ignoredFeatureCount{$type}++;
    return;
  }
  $processedFeatureCount{$type}++;

  $extDbRlsId = $self->getExtDbRlsId($self->getArg('extDbRlsSpec'))
    unless $extDbRlsId;

  # sequence
  my $sequence = $self->getSequence($sequenceSourceId, $extDbRlsId);

  # gene
  my $geneId = $self->getGeneId($attributes, $extDbRlsId);

  # geneFeature
  my $geneFeatureId = $self->getGeneFeatureId($attributes, $sequence->getNaSequenceId(), $extDbRlsId);

  # geneInstance
  $self->createGeneInstance($geneId, $geneFeatureId);

  # dependent features
  foreach my $line (@$inputArrayRef) {
    my ($sequence, $source, $type, $start, $end, $score, $strand, $phase, $attributes)
      = split(/\t/, $line);
  }

  unless ($totalFeatureCount++ % 500) {
    print STDERR "processed $totalFeatureCount top-level features\n";
    $self->undefPointerCache();
  }
}

sub getGeneFeatureId {

  my ($self, $attributes, $naSequenceId, $extDbRlsId) = @_;

  my ($sourceId, $name, $product, $isPseudo);

  if ($attributes =~ /GeneID:([0-9]*)[,;\s]/) {
    $sourceId = $1;
  } else {
    die "can't find Gene ID in attributes \"$attributes\"";
  }

  if ($attributes =~ /Name=([^,;\s]*)[,;\s]/) {
    $name = $1;
  } elsif ($attributes =~ /ID=([^,;\s]*)[,;\s]/) {
    $name = $1;
  } else {
    die "can't find name in attributes \"$attributes\"";
  }

  $isPseudo = 1
    if $attributes =~ /pseudo=true/;

  if ($attributes =~ /product=([[^,;\s]*)/) {
    $product = $1;
  }

  my $geneFeature = GUS::Model::DoTS::GeneFeature->new( {
                         'source_id' => $sourceId,
                         'name' => $name,
                         'product' => $product,
                         'is_pseudo' => $isPseudo,
                         'external_database_release_id' => $extDbRlsId,
					 } );
  $geneFeature->submit();

  return $geneFeature->getNaFeatureId();
}

sub createGeneInstance {

  my ($self, $geneId, $geneFeatureId) = @_;

  my $geneInstance = GUS::Model::DoTS::GeneInstance->new( {
                         'gene_id' => $geneId,
                         'na_feature_id' => $geneFeatureId,
                         'is_reference' => 0,
					 } );
  $geneInstance->submit();
}

sub getSequence {

  my ($self, $sequenceSourceId, $extDbRlsId) = @_;

  my $sequence = GUS::Model::DoTS::ExternalNASequence->new( {
          'source_id' => $sequenceSourceId,
    } );

  unless ( $sequence->retrieveFromDB() ) {
    $sequence->setSequenceVersion(1);
    $sequence->setExternalDatabaseReleaseId($extDbRlsId);
    $sequence->submit();
    $self->undefPointerCache();
  }

  return $sequence;
}

sub getGeneId {

  my ($self, $attributes, $extDbRlsId) = @_;

  my ($hgncId, $gene);

  if ($attributes =~ /HGNC:([0-9]*)/) {
    $hgncId = $1;
    $hugoDbName = $self->getArg('hugoExtDbRlsName')
      unless $hugoDbName;
    if ($hugoDbName && !$hugoQuery) {
      $hugoQuery = $self->getQueryHandle()->prepare(<<SQL) or die DBI::errstr;
            select g.gene_id
            from dots.Gene g, sres.ExternalDatabaseRelease edr, sres.ExternalDatabase ed
            where g.source_id = ?
              and g.external_database_release_id = edr.external_database_release_id
              and edr.external_database_id = ed.external_database_id
              and ed.name = '$hugoDbName'
SQL
    }

    $hugoQuery->execute($hgncId) or die DBI::errstr;
    my ($geneId) = $hugoQuery->fetchrow_array();

    if ($geneId) {
      $gene = GUS::Model::DoTS::Gene->new( {
					    'gene_id' => $geneId,
					    'source_id' => $hgncId,
					   } );
    } else {
      $hugoNotFound++;
    }
  }

  if (!$gene) {
    my $geneId;
    if ($attributes =~ /GeneID:([0-9]*)[,;\s]/) {
      $geneId = $1;
    } else {
      die "can't find Gene ID in attributes \"$attributes\"";
    }

    $gene = GUS::Model::DoTS::Gene->new( {
                         'source_id' => $geneId,
                         'description' => $attributes,
                         'external_database_release_id' => $extDbRlsId,
					 } );
    $gene->submit();
  }

  return $gene->getGeneId();
}

sub undoTables {
  my ($self) = @_;

  return ('DoTS.ExternalNaSequence',
          'DoTS.Gene',
          'DoTS.GeneFeature',
          'DoTS.GeneInstance',
	  'DoTS.ExternalNASequence',
	  'DoTS.Gene',
	  'DoTS.GeneFeature',
	  'DoTS.GeneInstance',
	  'DoTS.Transcript',
	  'DoTS.ExonFeature',
	  'DoTS.RNAFeatureExon',
	  'DoTS.NALocation',
         );

}

1;
