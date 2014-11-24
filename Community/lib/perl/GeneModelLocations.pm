package GUS::Community::GeneModelLocations;

use strict;

use Bio::Location::Simple;
#use Bio::Coordinate::GeneMapper;

use Data::Dumper;


sub new {
  my ($class, $dbh, $geneExtDbRlsId) = @_;

  my $self = bless {'_database_handle' => $dbh, '_gene_external_database_release_id' => $geneExtDbRlsId}, $class;

  $self->_initAllModelsHash();

  return $self;
}

#--------------------------------------------------------------------------------
# public methods start
#--------------------------------------------------------------------------------

sub getDatabaseHandle { $_[0]->{_database_handle} }
sub getGeneExternalDatabaseReleaseId { $_[0]->{_gene_external_database_release_id} }        

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
    $strand = $exon->{is_reversed} ? -1 : 1;

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

  while(my $a = $sh->fetchrow_arrayref()) {

    unless($seenGenes{$a->[0]}) {
      $geneModels->{$a->[0]} = { 'source_id' => $a->[0],
                                 'na_feature_id' => $a->[1],
                                 'sequence_source_id' => $a->[14],
                                 'start' => $a->[11],
                                 'end' => $a->[12],
                                 'is_reversed' => $a->[13],
      };
      

      $seenGenes{$a->[0]} = 1;
    }

    unless($seenTranscripts{$a->[2]}) {
      $geneModels->{$a->[0]}->{transcripts}->{$a->[2]} = {'source_id' => $a->[2],
                                                          'na_feature_id' => $a->[3],
                                                          'is_reversed' => $a->[8],
                                                          'sequence_source_id' => $a->[14],
      };

      $transcriptToGeneMap->{$a->[2]} = $a->[0];
      $seenTranscripts{$a->[2]} = 1;
    }


    unless($seenProteins{$a->[15]}) {
      $geneModels->{$a->[0]}->{transcripts}->{$a->[2]}->{proteins}->{$a->[15]} = {'source_id' => $a->[15],
                                                                                  'aa_feature_id' => $a->[16],
                                                                                  'aa_sequence_id' => $a->[17],
                                                                                  'translation_start' => $a->[9],
                                                                                  'translation_end' => $a->[10],
                                                                                  'na_sequence_source_id' => $a->[14],
      };

      $proteinToTranscriptMap->{$a->[15]} = $a->[2];
      $seenProteins{$a->[15]} = 1;
    }


    unless($seenExons{$a->[5]}) {
      push @{$geneModels->{$a->[0]}->{transcripts}->{$a->[2]}->{exonSourceIds}}, $a->[4];
    }



    my $exon = {source_id => $a->[4],
                na_feature_id => $a->[5],
                exon_start => $a->[6],
                exon_end => $a->[7],
                is_reversed => $a->[8],
                cds_start => $a->[18],
                cds_end => $a->[19],
    };


    push @{$geneModels->{$a->[0]}->{transcripts}->{$a->[2]}->{proteins}->{$a->[15]}->{exons}}, $exon;
  }

  $self->{_all_models_hash} = $geneModels;
  $self->{_transcript_to_gene_map} = $transcriptToGeneMap;
  $self->{_protein_to_transcript_map} = $proteinToTranscriptMap;
}



1;
