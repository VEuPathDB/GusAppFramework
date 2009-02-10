package GUS::Supported::Plugin::CalculateTranslatedAASequences;

use strict;
#use warnings;

use GUS::PluginMgr::Plugin;
use base qw(GUS::PluginMgr::Plugin);

use Bio::Tools::CodonTable;

use GUS::Model::DoTS::TranslatedAASequence;
use GUS::Model::DoTS::TranslatedAAFeature;
use GUS::Model::DoTS::Transcript;
use GUS::Model::DoTS::NAFeature;
use GUS::Model::DoTS::ExonFeature;
use GUS::Model::SRes::GeneticCode;

my $argsDeclaration =
  [
   stringArg({ name => 'extDbRlsName',
	       descr => 'External Database Release name of the transcripts to be translated',
	       constraintFunc => undef,
	       isList => 0,
	       reqd => 1,
	     }),

   stringArg({ name => 'extDbRlsVer',
	       descr => 'External Database Release version of the transcripts to be translated',
	       constraintFunc => undef,
	       isList => 0,
	       reqd => 1,
	     }),

   stringArg({ name => 'soCvsVersion',
	       descr => 'CVS revision of Sequence Ontology',
	       constraintFunc => undef,
	       reqd => 1,
	       isList => 0,
	     }),

   booleanArg({ name => 'overwrite',
		descr => 'whether to overwrite an existing translation or not; defaults to false',
		reqd => 0,
		default => 0,
	      }),
   integerArg({ name => 'ncbiGeneticCodeId',
		descr => 'ncbi genetic code id, alternative to the genetic code associated with the taxon, e.g. mitochondria',
		constraintFunc => undef,
		reqd => 0,
		isList => 0
		})
  ];


my $purposeBrief = <<PURPOSEBRIEF;
Calculates amino acid translations of CDS-defining transcripts.
PURPOSEBRIEF

my $purpose = <<PLUGIN_PURPOSE;
Calculates amino acid translations of CDS-defining transcripts.
PLUGIN_PURPOSE

my $tablesAffected =
  [
   ['DoTS.TranslatedAASequence' =>
    'Translations are deposited in the `sequence` field of DoTS.TranslatedAASequence'
   ],
   ['DoTS.TranslatedAAFeature' =>
    'TranslatedAASequences are associated with Transcripts by TranslatedAAFeatures'
   ],
  ];

my $tablesDependedOn = [];

my $howToRestart = <<PLUGIN_RESTART;
This plugin can be restarted, but unless --overwrite is set, any
any previously calculated translations will not be overwritten.
PLUGIN_RESTART

my $failureCases = <<PLUGIN_FAILURE_CASES;
Not all of the SO-defined translation expections have been implemented.
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
No additional notes.
PLUGIN_NOTES

my $documentation = { purposeBrief => $purposeBrief,
		      purpose => $purpose,
		      tablesAffected => $tablesAffected,
		      tablesDependedOn => $tablesDependedOn,
		      howToRestart => $howToRestart,
		      failureCases => $failureCases,
		      notes => $notes,
		    };

sub new {

  my $class = shift;
  $class = ref $class || $class;
  my $self = {};

  bless $self, $class;

  $self->initialize({ requiredDbVersion => 3.5,
		      cvsRevision =>  '$Revision$',
		      name => ref($self),
		      argsDeclaration   => $argsDeclaration,
		      documentation     => $documentation
		    });
  return $self;
}

sub run {

  my ($self) = @_;

  my $extDbRlsName = $self->getArg("extDbRlsName");
  my $extDbRlsVer = $self->getArg("extDbRlsVer");

  my $extDbRlsId = $self->getExtDbRlsId($extDbRlsName, $extDbRlsVer);

  unless ($extDbRlsId) {
    die "No such External Database Release / Version:\n $extDbRlsName / $extDbRlsVer\n";
  }

  my $codonTable = Bio::Tools::CodonTable->new();

  my $dbh = $self->getQueryHandle();

  my $transcriptExonsHash = $self->_makeTranscriptExonsHash($extDbRlsId);

  my $transcriptTypeHash = $self->_makeTranscriptTypeHash($extDbRlsId);

  my $sql = <<EOSQL;
  SELECT na_feature_id
  FROM   DoTS.Transcript
  WHERE  external_database_release_id = ?
EOSQL

  my $sth = $dbh->prepare($sql);
  $sth->execute($extDbRlsId);

  my $exceptions = $dbh->prepare(<<EOSQL);

  SELECT naf.na_feature_id, so.term_name
  FROM   DoTS.NAFeature naf,
         DoTS.NALocation nal,
         SRes.SequenceOntology so
  WHERE  naf.sequence_ontology_id = so.sequence_ontology_id
  AND    nal.na_feature_id = naf.na_feature_id
  AND    so.term_name in ('stop_codon_redefinition_as_selenocysteine',
                          'stop_codon_redefinition_as_pyrrolysine',
		          'plus_1_translational_frameshift',
		          'minus_1_translational_frameshift',
		          'four_bp_start_codon',
		          '4bp_start_codon',
		          'stop_codon_readthrough',
		          'CTG_start_codon'
		         )
  AND    nal.start_min BETWEEN ? AND ?
  AND    nal.is_reversed = ?
  AND    naf.na_sequence_id = ?
  AND    naf.external_database_release_id = ?
ORDER BY CASE WHEN nal.is_reversed = 1 THEN nal.end_max ELSE nal.start_min END

EOSQL

  while (my ($transcriptId) = $sth->fetchrow()) {

    my $transcript = GUS::Model::DoTS::Transcript->new({ na_feature_id => $transcriptId });

    unless ($transcript->retrieveFromDB()) {
      die "Not sure what happened: $transcriptId was supposed to fetch a Transcript, but couldn't\n";
    }

    my $transcriptSOTerm = $transcriptTypeHash->{$transcript->getId()};
    unless ($transcriptSOTerm) {
      die "No SO term for transcript; how can I tell if this is protein-coding or not?\n";
    }

    if ($transcriptSOTerm ne 'protein_coding' && $transcriptSOTerm ne 'pseudogene') {
      warn "Skipping transcript " . $transcript->getSourceId() . ", not a protein-coding transcript\n";
      next;
    }

    my @translatedAAFeatures = $transcript->getChildren("DoTS::TranslatedAAFeature", 1);

    unless (@translatedAAFeatures) {
      my $transAAFeat = GUS::Model::DoTS::TranslatedAAFeature->new();
      $transAAFeat->setIsPredicted(0);

      my $aaSeq = GUS::Model::DoTS::TranslatedAASequence->new();

      $aaSeq->setSourceId($transcript->getSourceId());
      $aaSeq->setDescription($transcript->getProduct());
      $aaSeq->setExternalDatabaseReleaseId($transcript->getExternalDatabaseReleaseId());
      $aaSeq->setSequenceOntologyId($self->{plugin}->{soPrimaryKeys}->{'polypeptide'});

      $aaSeq->submit();

      $transAAFeat->setSourceId($transcript->getSourceId());
      $transAAFeat->setAaSequenceId($aaSeq->getId());
      $transAAFeat->setNaFeatureId($transcript->getId());
      $transAAFeat->setExternalDatabaseReleaseId($transcript->getExternalDatabaseReleaseId());
      my $translationStart = $self->_getTranslationStart($transcript->getExternalDatabaseReleaseId(),$transcript->getSourceId());
      my $translationStop = $self->_getTranslationStop($transcript->getExternalDatabaseReleaseId(),$transcript->getSourceId());
      $transAAFeat->setTranslationStart($translationStart);
      $transAAFeat->setTranslationStop($translationStop);
      $transAAFeat->submit();

      push @translatedAAFeatures, $transAAFeat;
    }

    if (@translatedAAFeatures > 1) {
      die "Transcript had more than one translated AA feature associated with it; what now?\n";
    }

    my $transAAFeature = shift @translatedAAFeatures;

    ## want to die if is_simple is equal to 0 because can't do a simple translation
    ## uncomment when actually populate the is_simple field.
    ## die "Translation is not simple for ".$transcript->getSourceId()."\n" if $transAAFeature->getIsSimple() == 0;

    my $aaSeqId = $transAAFeature->getAaSequenceId();

    unless ($aaSeqId) {
      die "Translated AA Feature did not have an Translated AA Sequence associated with it\n";
    }

    my $aaSeq = GUS::Model::DoTS::TranslatedAASequence->new({ aa_sequence_id => $aaSeqId });

    unless ($aaSeq->retrieveFromDB()) {
      die "Could not retrieve translated AA sequence $aaSeqId\n";
    }

    if (!$self->getArg("overwrite") && $aaSeq->get('sequence')) {
	$self->undefPointerCache();
      warn "Skipping transcript, already has a sequence.\n";
      next;
    }

    my $ntSeq = $transcript->getParent("DoTS::NASequence", 1);

    unless ($ntSeq) {
	$self->undefPointerCache();
      die "Transcript had no associated NASequence: " . $transcript->getSourceId() . "\n";
    }

    my $taxon = $ntSeq->getParent("SRes::Taxon", 1);


    unless ($taxon) {
      die "NASequence was not associated with an organism in SRes.Taxon: " . $ntSeq->getSourceId() . "\n";
    }

    my $geneticCodeId = $taxon->getGeneticCodeId() || $self->log("there is no genetic_code_id associated with taxon_id " . $taxon->getId());

    my $geneticCode = GUS::Model::SRes::GeneticCode->new({'genetic_code_id' => $geneticCodeId});

    $geneticCode->retrieveFromDB();

    $codonTable->id($geneticCode->getNcbiGeneticCodeId() || $self->getArg('ncbiGeneticCodeId') || 1);

    my @exons = $self->exonIds2ExonObjects($transcriptExonsHash->{$transcript->getSourceId()});

    unless (@exons) {
      die "Transcript had no exons: " . $transcript->getSourceId() . "\n";
    }

    @exons = map { $_->[0] }
      sort { $a->[3] ? $b->[1] <=> $a->[1] : $a->[1] <=> $b->[1] }
	map { [ $_, $_->getFeatureLocation ]}
	  @exons;

    my $cds = "";
    my $translation;

    my @exceptions;
    for my $exon (@exons) {
      my ($exonStart, $exonEnd, $exonIsReversed) = $exon->getFeatureLocation();

      my $codingStart = $exon->getCodingStart();
      my $codingEnd = $exon->getCodingEnd();

      next unless ($codingStart && $codingEnd);

      my $chunk = $exon->getFeatureSequence();

      $exceptions->execute($exonStart, $exonEnd, $exonIsReversed, $exon->getNaSequenceId(), $extDbRlsId);

      while (my ($exceptionId, $soTerm) = $exceptions->fetchrow()) {
	if ($soTerm eq "stop_codon_redefinition_as_selenocysteine") {
	  my $exception = GUS::Model::DoTS::NAFeature->new({ na_feature_id => $exceptionId });
	  $exception->retrieveFromDB();

	  my ($start, $end, $isReversed) = $exception->getFeatureLocation();
	  push @exceptions, [ length($cds) + 1 + $isReversed ? $codingStart - $end : $start - $codingStart,
			      length($cds) + 1 + $isReversed ? $codingStart - $start : $end - $codingStart,
			      "TGA", "U"
			    ];
	} else {
	  die "Sorry, translation expections for '$soTerm' not yet handled!\n";
        }
      }

      my $trim5 = $exonIsReversed ? $exonEnd - $codingStart : $codingStart - $exonStart;
      substr($chunk, 0, $trim5, "") if $trim5 > 0;  

      my $trim3 = $exonIsReversed ? $codingEnd - $exonStart : $exonEnd - $codingEnd;
      substr($chunk, -$trim3, $trim3, "") if $trim3 > 0;  

      $cds .= $chunk;
    }

    $translation = $codonTable->translate($cds);

    for (my $i = 0 ; $i < @exceptions ; $i++) {
      my ($start, $end, $codon, $residue) = @{$exceptions[$i]};
      # warn "changing codon @{[substr($cds, $start-1, $end - $start + 1)]} to $codon ($residue)\n";
      substr($cds, $start-1, $end - $start + 1, $codon);

      substr($translation, int(($start-1)/3), 1, $residue);

      # adjust remaining coordinates, if necessary (e.g. 4 bp start codon)
      unless (length($codon) == ($end - $start + 1)) {
	my $delta = $end - $start + 1 - length($codon);
	for (my $j = $i+1 ; $j < @exceptions ; $j++) {
	  $exceptions[$i]->[0] += $delta;
	  $exceptions[$i]->[1] += $delta;
	}
      }
    }

    $translation =~ s/\*$//; # strip terminal stop codon, if present

    if ($translation =~ m/\*/ && !$transcript->getIsPseudo) {
      warn "Warning: translation for " . $transcript->getSourceId() . " contains stop codons:\n$translation\n";
    }

    $aaSeq->setSequence($translation) if ($translation ne $aaSeq->get('sequence'));
    $aaSeq->submit();
    $self->undefPointerCache();
  }

  warn "Done.\n";
}


sub _makeTranscriptTypeHash {
  my ($self, $extDbRlsId) = @_;

  my $sql = "
SELECT s.term_name, t.na_feature_id
FROM dots.Transcript t,
     dots.GeneFeature g,
     sres.SequenceOntology s
WHERE s.sequence_ontology_id = g.sequence_ontology_id
AND g.na_feature_id = t.parent_id
AND t.external_database_release_id = $extDbRlsId
";

  my $sth = $self->prepareAndExecute($sql);

  my %transcriptTypeHash;
  while (my ($soTerm, $transFeatId) = $sth->fetchrow()) {
    $transcriptTypeHash{$transFeatId} = $soTerm;
  }
  return \%transcriptTypeHash;
}

sub _makeTranscriptExonsHash {
  my ($self, $extDbRlsId) = @_;

  my $sql = "
SELECT t.source_id, e.na_feature_id
FROM dots.Transcript t,
     dots.RnaFeatureExon rfe,
     dots.ExonFeature e
WHERE t.na_feature_id = rfe.rna_feature_id
AND e.na_feature_id = rfe.exon_feature_id
AND t.external_database_release_id = $extDbRlsId
ORDER BY t.source_id
";

  my $sth = $self->prepareAndExecute($sql);

  my %transcriptExonsHash;
  my $curTranscriptSrcId = "-1";
  while (my ($transcriptSrcId, $exonFeatId) = $sth->fetchrow()) {
    if ($transcriptSrcId ne $curTranscriptSrcId) {
      $transcriptExonsHash{$transcriptSrcId} = [];
      $curTranscriptSrcId = $transcriptSrcId;
    }

    push(@{$transcriptExonsHash{$transcriptSrcId}}, $exonFeatId);
  }
  return \%transcriptExonsHash;
}

sub exonIds2ExonObjects{
  my ($self, $exonIds) = @_;
  my @exonObjs;

  foreach my $exonId (@{$exonIds}){
    my $exon =
      GUS::Model::DoTS::ExonFeature->new({na_feature_id => $exonId});

    $exon->retrieveFromDB();

    push(@exonObjs, $exon);

  }

  return @exonObjs;
}

sub _getTranslationStart{
  my ($self, $extDbRlsId, $transcriptSourceId) = @_;
  my $sql = "
select ef.coding_start,nl.is_reversed,nl.start_min,nl.end_max from dots.exonfeature ef, dots.nalocation nl, dots.transcript t, dots.rnafeatureexon rfe where
ef.na_feature_id = nl.na_feature_id
and ef.order_number = 1
and ef.external_database_release_id = $extDbRlsId
and t.source_id = '$transcriptSourceId'
and t.na_feature_id = rfe.rna_feature_id
and ef.na_feature_id = rfe.exon_feature_id";
  my $sth = $self->prepareAndExecute($sql);

  my $translationStart;

  while (my ($codingStart,$isReversed,$exonStart,$exonStop) = $sth->fetchrow()) {
  
      if($isReversed){

	  $translationStart = $exonStop - $codingStart + 1;

      }else{

	  $translationStart = $codingStart - $exonStart + 1;
      }
  }
  return $translationStart;
}

sub _getTranslationStop{
  my ($self, $extDbRlsId, $transcriptSourceId) = @_;

  my $translationStop;

  my $sql = "
select max(ef.order_number) from dots.exonfeature ef , dots.transcript t, dots.rnafeatureexon rfe where
ef.external_database_release_id = $extDbRlsId
and t.source_id = '$transcriptSourceId'
and t.na_feature_id = rfe.rna_feature_id
and ef.na_feature_id = rfe.exon_feature_id
and ef.coding_end is not null
and ef.coding_start is not null
";
  my $sth = $self->prepareAndExecute($sql);

  my ($finalCodingExon) = $sth->fetchrow();

  $sql = "
select ef.coding_end,nl.is_reversed,nl.start_min,nl.end_max,snas.length from dots.exonfeature ef, dots.nalocation nl, dots.transcript t, dots.rnafeatureexon rfe, dots.splicednasequence snas where
ef.na_feature_id = nl.na_feature_id
and ef.order_number = $finalCodingExon
and ef.external_database_release_id = $extDbRlsId
and t.source_id = '$transcriptSourceId'
and t.na_feature_id = rfe.rna_feature_id
and ef.na_feature_id = rfe.exon_feature_id
and t.na_sequence_id = snas.na_sequence_id";

    $sth = $self->prepareAndExecute($sql);
  while (my ($codingStop,$isReversed,$exonStart,$exonStop,$transcriptLength) = $sth->fetchrow()) {
      if($isReversed){

	  $translationStop = $transcriptLength - ($codingStop - $exonStart);

      }else{

	  $translationStop = $transcriptLength - ($exonStop - $codingStop);
      }
  }
  return $translationStop;
}


sub undoTables {
  my ($self) = @_;

  return ('DoTS.TranslatedAASequence',
	  'DoTS.TranslatedAAFeature',
	 );
}


sub undoUpdatedTables {
  my ($self) = @_;

  return ('DoTS.TranslatedAASequence',
	  'DoTS.TranslatedAAFeature',
	 );
}


1;
