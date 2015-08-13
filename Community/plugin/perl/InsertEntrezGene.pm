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
use Data::Dumper;

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
     fileArg({ name           => 'sequenceMappingFile',
             descr          => 'mapping between sequences source ids in the GFF3 file and those stored in SRes::ExternalNASequence (e.g., RefSeq Accession to chrN); tab-delimited file with two columns: <gff3 sequence source id>   <database sequence source id>.  If not specified plugin will create placeholder entries in SRes::ExternalNASequence for any sequence_source_id not in the table',
             reqd           => 0,
             mustExist      => 0,
             format         => 'tab-delim',
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
my %sequenceMap; # map of sequence source id from GFF3 file to sequence source ids in DB (e.g., RefSeq acccession to chrN)
my %naSequenceIds; # hash storing na_sequence_ids mapped to sequence_source_ids to reduce slow lookups
my $totalFeatureCount;   # total number of top-level features processed
my $extDbRlsId;         # Entrez Gene external database release ID
my $hugoQuery;         # prepared query for HUGO genes
my $hugoDbName;       # saved value of HUGO database-name parameter
my $hugoNotFound;    # count of HUGO IDs found in data file but not in database
my $codingRegionStmt; # prepared statement to set ExonFeature start and end

my %subfeatureCount; # for debugging: what non-top-level features do we encounter?

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

    $hugoDbName = $self->getArg('hugoExtDbRlsName');
    $self->getAlgInvocation()->setMaximumNumberOfObjects(100000);

    readSequenceIdMap($self) if $self->getArg('sequenceMappingFile');

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
    $self->processTopLevelFeature(\@featuresWorth)
	  if @featuresWorth;

    $self->undefPointerCache();
    $self->setFinalExon();

    $msg = "among top-level features, processed " .
	   join(", ", (map {$processedFeatureCount{$_} . " " . $_; } keys(%processedFeatureCount))) .
            "; ignored " .
	   join(", ", (map {$ignoredFeatureCount{$_} . " " . $_; } keys(%ignoredFeatureCount)));

# print "\$msg = \"$msg\"\n";

# print "subfeatures: " .
# 	   join(", ", (map {$subfeatureCount{$_} . " " . $_; } sort(keys(%subfeatureCount)))) .
#             "\n";

    $self->getQueryHandle()->commit() or die DBI::errstr;

    return $msg;
}

sub readSequenceIdMap {
  my ($self) = @_;

  open(FILE, $self->getArg('sequenceMappingFile'));

  while(<FILE>) {
    chomp;
    my ($fileSequence, $dbSequence) = split /\t/;
    $sequenceMap{$fileSequence} = $dbSequence;
  }
  close FILE;
  $self->log(Dumper(\%sequenceMap)) if $self->getArg('veryVerbose');
}
  

sub processTopLevelFeature {
  my ($self, $inputArrayRef) = @_;

  # first feature
  my ($sequenceSourceId, $source, $type, $start, $end, $score, $strand, $phase, $attributes)
    = split(/\t/, shift(@{$inputArrayRef}));

  if (%sequenceMap) {
      $sequenceSourceId = $sequenceMap{$sequenceSourceId}  if (exists $sequenceMap{$sequenceSourceId});
  }

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
  my $sequenceId = $self->getSequenceId($sequenceSourceId, $extDbRlsId);

  # gene
  my $geneId = $self->getGeneId($attributes, $extDbRlsId);

  # geneFeature
  my $geneFeatureId = $self->getGeneFeatureId($attributes, $sequenceId, $extDbRlsId);
  $self->setFeatureLocation($geneFeatureId, $start, $end, $strand);

  # geneInstance
  $self->createGeneInstance($geneId, $geneFeatureId);

  # dependent features
  my (%transcriptFeatureId, $exonOrderNumber);
  foreach my $line (@$inputArrayRef) {
    my ($sequence, $source, $type, $start, $end, $score, $strand, $phase, $attributes)
      = split(/\t/, $line);
    $subfeatureCount{$type}++;

    # make a hash of the attributes
    my %attr;
    map { my ($name, $value) = split("=", $_); $attr{$name} = $value;} split(";", $attributes);

    if ($type eq "transcript" || $type eq "mRNA" || $type eq "ncRNA" || $type eq "rRNA" || $type eq "primary_transcript" || $type eq "tRNA") {
      my $name = $attr{Name};
      $name = $attr{ID} unless $name;
      my $transcript = GUS::Model::DoTS::Transcript->new( {
                         "na_sequence_id" => $sequenceId,
                         "name" => $name,
                         "source_id" => $attr{ID},
                         "product" => $attr{product},
                         "parent_id" => $geneFeatureId,
                         "external_database_release_id" => $extDbRlsId,
					 } );
      $transcript->submit();
      $transcriptFeatureId{$attr{ID}} = $transcript->getNaFeatureId();
      $self->setFeatureLocation($transcript->getNaFeatureId(), $start, $end, $strand);
    } elsif ($type eq "exon") {
      # create ExonFeature record
      my $name = $attr{Name};
      $name = $attr{ID} unless $name;
      my $exonFeature = GUS::Model::DoTS::ExonFeature->new( {
                         "na_sequence_id" => $sequenceId,
                         "name" => $name,
                         "source_id" => $attr{ID},
                         "parent_id" => $geneFeatureId,
                         "external_database_release_id" => $extDbRlsId,
					 } );
      $exonFeature->submit();
      $self->setFeatureLocation($exonFeature->getNaFeatureId(), $start, $end, $strand);

      # create RnaFeatureExon record, if parent is a transcript
      if ($transcriptFeatureId{$attr{Parent}}) {
	my $rnaFeatureExon = GUS::Model::DoTS::RNAFeatureExon->new( {
                             "rna_feature_id" => $transcriptFeatureId{$attr{Parent}},
                             "exon_feature_id" => $exonFeature->getNaFeatureId(),
                             "order_number" => ++$exonOrderNumber,
                             "is_initial_exon" => ($exonOrderNumber == 1) ? 1 : 0,
                             "is_final_exon" => 0, # fix later for final exons
                                                                     } );
	$rnaFeatureExon->submit();
      }
    } elsif ($type eq "CDS") {
      $self->setCodingRegion($transcriptFeatureId{$attr{Parent}}, $start, $end);
    } else {
      $self->log("not handling feature type '$type'");
      next;
    }
  }

  unless (++$totalFeatureCount % 250) {
    print STDERR "processed $totalFeatureCount top-level features\n";
    $self->undefPointerCache();
  }
}

sub getGeneFeatureId {

  my ($self, $attributes, $naSequenceId, $extDbRlsId) = @_;

  my ($name, $product);

  # make a hash of the attributes
  my %attr;
  map { my ($name, $value) = split("=", $_); $attr{$name} = $value;} split(";", $attributes);

  # . . . and a hash of the database cross-references
  my %dbxref;
  map { my ($name, $value) = split(":", $_); $dbxref{$name} = $value;} split(",", $attr{Dbxref})
    if $attr{Dbxref};

  my $geneFeature = GUS::Model::DoTS::GeneFeature->new( {
                         'na_sequence_id' => $naSequenceId,
                         'source_id' => $dbxref{GeneID},
                         'name' => $attr{Name} ? $attr{Name} : $attr{ID},
                         'product' => $attr{product},
                         'is_pseudo' => ($attr{pseudo} eq "true") ? 1 : '',
                         'external_database_release_id' => $extDbRlsId,
                         'label' => $attributes,
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

sub getSequenceId {

  my ($self, $sequenceSourceId, $extDbRlsId) = @_;

  unless (exists $naSequenceIds{$sequenceSourceId}) {
      my $sequence = GUS::Model::DoTS::ExternalNASequence->new( {
          'source_id' => $sequenceSourceId,
								} );

      unless ( $sequence->retrieveFromDB() ) {
	  $self->log("No entry found for sequence $sequenceSourceId; creating record") if $self->getArg('verbose');
	  $sequence->setSequenceVersion(1);
	  $sequence->setExternalDatabaseReleaseId($extDbRlsId);
	  $sequence->submit();
	  $self->undefPointerCache();
      }
      $naSequenceIds{$sequenceSourceId} = $sequence->getNaSequenceId();
  }
  return $naSequenceIds{$sequenceSourceId};
}

sub getGeneId {

  my ($self, $attributes, $extDbRlsId) = @_;

  my ($hgncId, $gene);

  # if HUGO genes are loaded, link to those
  if ($hugoDbName) { # if HUGO external database info has been provided
      if ($attributes =~ /HGNC:([0-9]*)/) {
	  
	  $hgncId = $1;
 
	  if (!$hugoQuery) {
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
	  $hugoQuery->finish();
      
	  if ($geneId) {
	      $gene = GUS::Model::DoTS::Gene->new( {
					    'gene_id' => $geneId,
					    'source_id' => $hgncId,
						   } );
	  } else {
	      $hugoNotFound++;
	  }
      }
  }

  # else create new gene entries 
  if (!$gene) {
    my $geneId;
    if ($attributes =~ /GeneID:([0-9]*)[,;\s]/) {
      $geneId = $1;
    } else {
      die "can't find Gene ID in attributes \"$attributes\"";
    }

    my %attr;
    map { my ($name, $value) = split("=", $_); $attr{$name} = $value;} split(";", $attributes);
    $gene = GUS::Model::DoTS::Gene->new( {
                         'source_id' => $geneId,
                         'description' => $attr{description},
                         'name' => $attr{Name},
                         'gene_symbol' => $attr{Name},
                         'external_database_release_id' => $extDbRlsId,
					 } );
    $gene->submit();
  }

  return $gene->getGeneId();
}

sub setFeatureLocation {

  my ($self, $featureId, $start, $end, $strand) = @_;

  my $isReversed;

  $isReversed = 1 if $strand eq "-";
  $isReversed = 0 if $strand eq "+";

  my $location = GUS::Model::DoTS::NALocation->new( {
                         'na_feature_id' => $featureId,
                         'start_min' => $start,
                         'end_max' => $end,
                         'is_reversed' => $isReversed,
						      } );
  $location->submit();
}

sub setCodingRegion {
  my ($self, $transcriptId, $start, $end) = @_;

  if (!$codingRegionStmt) {
    my $algInvId   = $self->getAlgInvocation()->getId();
    $codingRegionStmt = $self->getQueryHandle()->prepare(<<SQL) or die DBI::errstr;
            update dots.ExonFeature
            set coding_start = ?, coding_end = ?
            where row_alg_invocation_id = $algInvId       -- current run
              and na_feature_id = (select rnaf.exon_feature_id
                                    from dots.RnaFeatureExon rnaf, dots.NaLocation nl
                                     where rnaf.exon_feature_id = nl.na_feature_id
                                       and rnaf.rna_feature_id = ?
                                       and nl.start_min <= ?
                                       and nl.end_max >= ?)
SQL
  }

  my $returnValue = $codingRegionStmt->execute($start, $end, $transcriptId, $start, $end);
  $codingRegionStmt->finish();
}

sub setFinalExon {
  my ($self) = @_;

  $self->getQueryHandle()->prepareAndExecute(<<SQL) or die DBI::errstr;
            update dots.RnaFeatureExon
            set is_final_exon = 1
            where order_number = (select max(order_number)
                                  from dots.RnaFeatureExon
                                  where rna_feature_exon_id = RnaFeatureExon.rna_feature_exon_id)
SQL
}

sub undoTables {
  my ($self) = @_;

  return ('DoTS.ExternalNaSequence',
	  'DoTS.NALocation',
	  'DoTS.GeneInstance',
	  'DoTS.GeneFeature',
  	  'DoTS.Gene',
	  'DoTS.GeneFeature',
	  'DoTS.GeneInstance',
	  'DoTS.RNAFeatureExon',
	  'DoTS.ExonFeature',
	  'DoTS.Transcript'
         );

}

1;
