package GUS::Community::GeneModelLocations;

use strict;

use Bio::Location::Simple;
use Bio::Coordinate::Pair;
#use Bio::Coordinate::GeneMapper;

use Data::Dumper;


sub new {
  my ($class, $dbh, $geneExtDbRlsId, $wantTopLevel) = @_;

  my $self = bless {'_database_handle' => $dbh, '_gene_external_database_release_id' => $geneExtDbRlsId, '_want_top_level' => $wantTopLevel}, $class;

  my $agpMap = {};
  if($wantTopLevel) {
    $agpMap = $self->queryForAgpMap();
  }

  $self->setAgpMap($agpMap);

  $self->_initAllModelsHash();

  return $self;
}

#--------------------------------------------------------------------------------
# public methods start
#--------------------------------------------------------------------------------

sub getDatabaseHandle { $_[0]->{_database_handle} }
sub getGeneExternalDatabaseReleaseId { $_[0]->{_gene_external_database_release_id} }        
sub getWantTopLevel { $_[0]->{_want_top_level} }

sub getAgpMap { $_[0]->{_agp_map} }
sub setAgpMap { $_[0]->{_agp_map} = $_->[1] }

sub getAllGeneIds {
  my ($self) = @_;

  my @rv = keys %{$self->_getAllModelsHash()};

  return \@rv;
}


sub getGeneModelHashFromGeneSourceId {
  my ($self, $geneSourceId) = @_;

  return $self->_getAllModelsHash()->{$geneSourceId};
}

sub getTranscriptIdsFromGeneSourceId {
  my ($self, $geneSourceId) = @_;

  my @transcriptIds  = keys %{$self->_getAllModelsHash()->{$geneSourceId}->{transcripts}};

  return \@transcriptIds;
}

sub getTranscriptHashFromTranscriptId {
  my ($self, $transcriptId) = @_;

  my $geneSourceId = $self->_getTranscriptToGeneMap()->{$transcriptId};

  my $geneHash = $self->getGeneModelHashFromGeneSourceId($geneSourceId);

  return $geneHash->{transcripts}->{$transcriptId};
}


sub getProteinIdsFromTranscriptSourceId {
  my ($self, $transcriptSourceId) = @_;

  my $transcriptHash = $self->getTranscriptHashFromTranscriptId($transcriptSourceId);

  my @proteinIds  = keys %{$transcriptHash->{proteins}};

  return \@proteinIds;
}


sub getProteinHashFromProteinId {
  my ($self, $proteinId) = @_;

  my $transcriptId = $self->_getProteinToTranscriptMap->{$proteinId};

  my $transcriptHash = $self->getTranscriptHashFromTranscriptId($transcriptId);

  return $transcriptHash->{proteins}->{$proteinId};
}


# (handy) Makes objects needed for a Bio::Coordinate::GeneMapper
sub getExonLocationsFromProteinId {
  my ($self, $proteinId) = @_;

  my $proteinHash = $self->getProteinHashFromProteinId($proteinId);

  my $naSequenceSourceId = $proteinHash->{na_sequence_source_id};

  my ($minCds, $maxCds, $strand);

  my @exonLocs;

  foreach my $exon (@{$proteinHash->{exons}}) {
    # init min and max w/ first value
    $minCds = $exon->{cds_start} unless($minCds);
    $maxCds = $exon->{cds_start} unless($maxCds);

    my ($min, $max) = sort ($exon->{cds_start}, $exon->{cds_end});

    $minCds = $min if($min < $minCds);
    $maxCds = $max if($max > $maxCds);

    #used for exon and cds
    $strand = $exon->{strand};

    my $exonLoc = Bio::Location::Simple->new( -seq_id => $naSequenceSourceId, -start => $exon->{exon_start}  , -end => $exon->{exon_end} , -strand => $strand);  

    push @exonLocs, $exonLoc;
  }

    my $cdsRange = Bio::Location::Simple->new( -seq_id => $naSequenceSourceId, -start => $minCds  , -end => $maxCds , -strand => $strand);  

  return \@exonLocs, $cdsRange
}


#--------------------------------------------------------------------------------
# private methods
#--------------------------------------------------------------------------------


sub _getTranscriptToGeneMap { $_[0]->{_transcript_to_gene_map} }
sub _getProteinToTranscriptMap { $_[0]->{_protein_to_transcript_map} }
sub _getAllModelsHash { $_[0]->{_all_models_hash}}

sub _initAllModelsHash { 
  my ($self) = @_;


  my $dbh = $self->getDatabaseHandle();
  my $extDbRlsId = $self->getGeneExternalDatabaseReleaseId();

  my $sql = "select gf.source_id as gene_source_id
     , gf.na_feature_id as gene_na_feature_id
     , t.source_id as transcript_source_id
     , t.na_feature_id as transcript_na_feature_id
     , ef.source_id as exon_source_id
     , ef.na_feature_id as exon_na_feature_id
     , l.start_min as exon_start_min
     , l.end_max as exon_end_max
     , l.is_reversed as exon_is_reversed
     , taf.translation_start
     , taf.translation_stop
     , gfl.start_min as gene_start_min
     , gfl.end_max as gene_end_max
     , gfl.is_reversed as gene_is_reversed
     , s.source_id as sequence_source_id
     , aas.source_id as protein_source_id
     , taf.aa_feature_id as protein_aa_feature_id
     , aas.aa_sequence_id as protein_aa_sequence_id
     , afe.coding_start
     , afe.coding_end
from dots.genefeature gf
   , dots.nalocation gfl
   , dots.nasequence s
   , dots.exonfeature ef
   , dots.nalocation l
   , dots.transcript t
   , dots.rnafeatureexon rfe
   , dots.translatedaafeature taf
   , dots.aafeatureexon afe
   , dots.translatedaasequence aas
where gf.na_feature_id = ef.parent_id
and gf.na_feature_id = gfl.na_feature_id
and gf.na_sequence_id = s.na_sequence_id
and ef.na_feature_id = l.na_feature_id
and t.na_feature_id = rfe.rna_feature_id
and rfe.exon_feature_id = ef.na_feature_id
and t.parent_id = gf.na_feature_id
and t.na_feature_id = taf.na_feature_id
and taf.aa_feature_id = afe.aa_feature_id
and afe.exon_feature_id = ef.na_feature_id
and taf.aa_sequence_id = aas.aa_sequence_id
and gf.external_database_release_id = ?
order by gf.na_feature_id, t.na_feature_id, l.start_min
";


  my $sh = $dbh->prepare($sql);
  $sh->execute($extDbRlsId);

  my $geneModels = {};

  my $transcriptToGeneMap = {};
  my $proteinToTranscriptMap = {};

  my %seenGenes;
  my %seenTranscripts;
  my %seenProteins;
  my %seenExons;

  my $agpMap = $self->getAgpMap();

  while(my $a = $sh->fetchrow_arrayref()) {

    my $geneSourceId = $a->[0];
    my $geneNaFeatureId = $a->[1];
    my $transcriptSourceId = $a->[2];
    my $transcriptNaFeatureId = $a->[3];
    my $exonSourceId = $a->[4];
    my $exonNaFeatureId = $a->[5];
    my $exonStart = $a->[6];
    my $exonEnd = $a->[7];
    my $exonIsReversed = $a->[8];
    my $translationStart = $a->[9];
    my $translationStop = $a->[10];
    my $geneStart = $a->[11];
    my $geneEnd = $a->[12];
    my $geneIsReversed = $a->[13];
    my $sequenceSourceId = $a->[14];
    my $proteinSourceId = $a->[15];
    my $proteinAaFeatureId = $a->[16];
    my $proteinAaSequenceId = $a->[17];
    my $codingStart = $a->[18];
    my $codingEnd = $a->[19];

    my $strand = $geneIsReversed ? -1 : 1;


    unless($seenGenes{$geneSourceId}) {
      if(my $agp = $agpMap->{$sequenceSourceId}) {
        my $geneLocation = &mapLocation($agpMap, $sequenceSourceId, $geneStart, $geneEnd, $strand);
      }
      

      $geneModels->{$geneSourceId} = { 'source_id' => $geneSourceId,
                                 'na_feature_id' => $geneNaFeatureId,
                                 'sequence_source_id' => $geneLocation->seq_id,
                                 'start' => $geneLocation->start,
                                 'end' => $geneLocation->end,
                                 'strand' => $geneLocation->strand,
      };


      $seenGenes{$geneSourceId} = 1;
    }


    my $seenTranscript = $seenTranscripts{$transcriptSourceId};
    my $seenExon = $seenExons{$exonSourceId};

    unless($seenTranscript) {
      $geneModels->{$geneSourceId}->{transcripts}->{$transcriptSourceId} = {'source_id' => $transcriptSourceId,
                                                          'na_feature_id' => $transcriptNaFeatureId,
                                                          'sequence_source_id' => $sequenceSourceId,
      };

      $transcriptToGeneMap->{$transcriptSourceId} = $geneSourceId;
      $seenTranscripts{$transcriptSourceId} = 1;
    }



    unless($seenExon) {
      my $exonLocation = &mapLocation($agpMap, $sequenceSourceId, $exonStart, $exonEnd, $strand);

      $geneModels->{$geneSourceId}->{exons}->{$exonSourceId} = {'source_id' => $exonSourceId,
                                                    'na_feature_id' => $exonNaFeatureId,
                                                    'start' => $exonLocation->start,
                                                    'end' => $exonLocation->end,
                                                    'strand' => $exonLocation->strand,
                                                    'sequence_source_id' => $exonLocation->seq_id,
      };

      $seenExons{$exonSourceId} = 1;
    }

    unless($seenExon && $seenTranscript) {
      push @{$geneModels->{$geneSourceId}->{exons}->{$exonSourceId}->{transcripts}}, $transcriptSourceId;
    }

    unless($seenProteins{$proteinSourceId}) {
      $geneModels->{$geneSourceId}->{transcripts}->{$transcriptSourceId}->{proteins}->{$proteinSourceId} = {'source_id' => $proteinSourceId,
                                                                                                            'aa_feature_id' => $proteinAaFeatureId,
                                                                                                            'aa_sequence_id' => $proteinAaSequenceId,
                                                                                                            'translation_start' => $translationStart,
                                                                                                            'translation_end' =>  $translationStop,
                                                                                                            'na_sequence_source_id' => $geneModels->{$geneSourceId}->{sequence_source_id},
      };

      $proteinToTranscriptMap->{$proteinSourceId} = $transcriptSourceId;
      $seenProteins{$proteinSourceId} = 1;
    }

    push @{$geneModels->{$geneSourceId}->{transcripts}->{$transcriptSourceId}->{exonSourceIds}}, $exonSourceId;

    my @sortedCds = sort ($codingStart, $codingEnd);

    my $cdsLocation = &mapLocation($agpMap, $sequenceSourceId, $sortedCds[0], $sortedCds[1], $strand);

    my $cds = {source_id => $exonSourceId,
               na_feature_id => $exonNaFeatureId,
               strand => $cdsLocation->strand,
               exon_start => $geneModels->{$geneSourceId}->{exons}->{$exonSourceId}->{start},
               exon_end => $geneModels->{$geneSourceId}->{exons}->{$exonSourceId}->{end},
               cds_start => $cdsLocation->strand == -1 ? $cdsLocation->end : $cdsLocation->start,
               cds_end => $cdsLocation->strand == -1 ? $cdsLocation->start : $cdsLocation->end,
    };

    push @{$geneModels->{$geneSourceId}->{transcripts}->{$transcriptSourceId}->{proteins}->{$proteinSourceId}->{exons}}, $cds;
  }

  $self->{_all_models_hash} = $geneModels;
  $self->{_transcript_to_gene_map} = $transcriptToGeneMap;
  $self->{_protein_to_transcript_map} = $proteinToTranscriptMap;
}

#--------------------------------------------------------------------------------
# Static Methods Start
#--------------------------------------------------------------------------------

sub queryForAgpMap {
  my ($dbh) = @_;

  my %agpMap;

  my $sql = "select sp.virtual_na_sequence_id
                                , p.na_sequence_id as piece_na_sequence_id
                               , decode(sp.strand_orientation, '+', '+1', '-', '-1', '+1') as piece_strand
                               , p.length as piece_length
                               , sp.distance_from_left + 1 as virtual_start_min
                               , sp.distance_from_left + p.length as virtual_end_max
                               , p.source_id as piece_source_id
                               , vs.source_id as virtual_source_id
                   from dots.sequencepiece sp
                           , dots.nasequence p
                           ,  dots.nasequence vs
                   where  sp.piece_na_sequence_id = p.na_sequence_id
                    and sp.virtual_na_sequence_id = vs.na_sequence_id";

  my $sh = $dbh->prepare($sql);
  $sh->execute();

  while(my $hash = $sh->fetchrow_hashref()) {
    my $ctg = Bio::Location::Simple->new( -seq_id => $hash->{PIECE_SOURCE_ID}, 
                                          -start => 1, 
                                          -end =>  $hash->{PIECE_LENGTH}, 
                                          -strand => '+1' );

    my $ctg_on_chr = Bio::Location::Simple->new( -seq_id =>  $hash->{VIRTUAL_SOURCE_ID}, 
                                                 -start => $hash->{VIRTUAL_START_MIN},
                                                 -end =>  $hash->{VIRTUAL_END_MAX} , 
                                                 -strand => $hash->{PIECE_STRAND} );

    my $agp = Bio::Coordinate::Pair->new( -in  => $ctg, -out => $ctg_on_chr );
    my $pieceSourceId = $hash->{PIECE_SOURCE_ID};
 
    if($agpMap{$pieceSourceId}) {
      die "Piece $pieceSourceId can only map to one virtual sequence";
    }

    $agpMap{$pieceSourceId} = $agp;
  }

  $sh->finish();

  return \%agpMap;
}


sub mapLocation {
  my ($agpMap, $pieceSourceId, $start, $end, $strand) = @_;

  my $agp = $agpMap->{$pieceSourceId};

  my $match = Bio::Location::Simple->
    new( -seq_id => $pieceSourceId, -start =>   $start, -end =>  $end, -strand => $strand );

  my $result = $agp->map($match);

  my $resultIsPiece = $agpMap->{$result->seq_id};

  return $result if($match->seq_id eq $result->seq_id || !$resultIsPiece);

  &mapLocation($agpMap, $result->seq_id, $result->start, $result->end, $result->strand);
}
 

1;
