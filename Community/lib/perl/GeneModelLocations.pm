package GUS::Community::GeneModelLocations;

use strict;

use Bio::SeqFeature::Gene::GeneStructure;
use Bio::SeqFeature::Gene::Transcript;
use Bio::SeqFeature::Gene::Exon;
use Bio::SeqFeature::Gene::UTR;

use Bio::Location::Simple;
use Bio::Coordinate::GeneMapper;

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

sub getGeneModelFromGeneSourceId {
  my ($self, $geneSourceId) = @_;

  my $geneModelHash = $self->_getGeneModelHashFromGeneSourceId($geneSourceId);

  my $geneModel = Bio::SeqFeature::Gene::GeneStructure->new( -start => $geneModelHash->{start},
                                                             -end => $geneModelHash->{end},
                                                             -strand => $geneModelHash->{is_reversed} ? -1 : 1, 
                                                             -primary => 'gene',
                                                             -seq_id => $geneModelHash->{sequence_source_id},
                                                             -display_name => $geneSourceId);


  $geneModel->add_tag_value('na_feature_id', $geneModelHash->{na_feature_id});
  $geneModel->add_tag_value('source_id', $geneSourceId);

  # JB:  Decided to make public methods to get transcript ids and to get the Bio::Seq Transcript Object;  
  #           This way we can reuse them in other contexts

  my $transcriptIds = $self->getTranscriptIdsFromGeneSourceId($geneSourceId);

  foreach my $transcriptId (@$transcriptIds) {
    my $transcript = $self->getTranscriptFromTranscriptId($transcriptId);

    $geneModel->add_transcript($transcript);
  }

  return $geneModel;
}


# better to call getGeneModelFromGeneSourceId if you can but if you only have a transcript id then ...
#  If you call this directly you will make a new Transcript Object which will not have access to the complete gene model
sub getTranscriptFromTranscriptId {
  my ($self, $transcriptSourceId) = @_;

  my $transcriptHash = $self->_getTranscriptHashFromTranscriptId($transcriptSourceId);

  my $transcript = Bio::SeqFeature::Gene::Transcript->new(-display_name => $transcriptSourceId,
                                                          -primary => 'transcript',
                                                          -seq_id => $transcriptHash->{sequence_source_id},
      );

  $transcript->add_tag_value('na_feature_id', $transcriptHash->{na_feature_id});
  $transcript->add_tag_value('source_id', $transcriptSourceId);

  my $isReversed = $transcriptHash->{is_reversed};

  my $translationStart = $transcriptHash->{translation_start};
  my $translationEnd = $transcriptHash->{translation_end};

  my @exons = sort { $a->[2] <=> $b->[2] } @{$transcriptHash->{exons}};

  for(my $i = 0; $i < scalar @exons; $i++) {
    my $isFirstExon = $i == 0 ? 1 : 0;
    my $isLastExon = $i == scalar @exons - 1 ? 1 : 0;

    my $ea = $exons[$i];
    my $exon = Bio::SeqFeature::Gene::Exon->new(-display_name => $ea->[0],
                                                -primary => 'exon',
                                                -start => $ea->[2],
                                                -end => $ea->[3],
                                                -strand => $ea->[4] ? -1 : 1
                                                -seq_id => $transcriptHash->{sequence_source_id},
        );

    $transcript->add_exon($exon);
  }


  my @exonLocations = map { $_->location() } $transcript->exons();

  my $sumExonLength;
  my $minExonLoc = $exonLocations[0]->start;
  my $maxExonLoc = $exonLocations[0]->start;;

  foreach(@exonLocations) {
    $sumExonLength += $_->end() - $_->start + 1;

    $minExonLoc = $_->start if($minExonLoc > $_->start);
    $minExonLoc = $_->end if($minExonLoc > $_->end);

    $maxExonLoc = $_->start if($maxExonLoc < $_->start);
    $maxExonLoc = $_->end if($maxExonLoc < $_->end);
  }

  # JB:  I am tricking the mapper to generate the coordinates for my cds
  #      by creating my mapper object only knowing of exons and asking for 
  #      a "cds->chr" mapping from translation_start translation_stop

  my $mapper = Bio::Coordinate::GeneMapper->new(
    -in  => "cds",
    -out => "chr",
    -exons => \@exonLocations
    );


  my ($codingStart, $codingEnd);

  # make the 5' utr if there is one
  if($translationStart - 1 > 0) {
    my ($min, $max) = $self->_makeAndAddUTRsOnTranscript($mapper, $transcript, 1, $translationStart - 1, 'utr5prime');

    $codingStart = $isReversed ? $min - 1 : $max + 1;
  }
  else {
    $codingStart = $isReversed ? $maxExonLoc : $minExonLoc;

  }

  # make the 3' utr if there is one
  if($sumExonLength - $translationEnd > 0) {
    my ($min, $max) = $self->_makeAndAddUTRsOnTranscript($mapper, $transcript, $translationEnd + 1, $sumExonLength, 'utr3prime');

    $codingEnd = $isReversed ? $max + 1 : $min - 1;
  }
  else {
    $codingEnd = $isReversed ? $minExonLoc : $maxExonLoc;
  }

  $transcript->add_tag_value('coding_start', $codingStart);
  $transcript->add_tag_value('coding_end', $codingEnd);

  return $transcript;
}

sub _makeAndAddUTRsOnTranscript {
  my ($self, $mapper, $transcript, $start, $end, $primary) = @_;

  my $loc =   Bio::Location::Simple->new(-start => $start,
                                         -end   => $end
                                         -strand => +1,
      );
  my $map = $mapper->map($loc);    
  
  my $utrs = $self->_makeUTRsFromMapResult($map, 'utr5prime');

  my $max = $utrs->[0]->start;
  my $min = $utrs->[0]->start;

  foreach(@$utrs) {
    $transcript->add_utr($_);

    $min = $_->start if($min > $_->start);
    $min = $_->end if($min > $_->end);

    $max = $_->start if($max < $_->start);
    $max = $_->end if($max < $_->end);
  }

  return($min, $max);
}



sub getTranscriptIdsFromGeneSourceId {
  my ($self, $geneSourceId) = @_;

  my @transcriptIds  = keys %{$self->_getAllModelsHash()->{$geneSourceId}->{transcripts}};

  return \@transcriptIds;
}


#--------------------------------------------------------------------------------
# private methods
#--------------------------------------------------------------------------------


sub _getTranscriptToGeneMap { $_[0]->{_transcript_to_gene_map} }
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
from dots.genefeature gf
   , dots.nalocation gfl
   , dots.nasequence s
   , dots.exonfeature ef
   , dots.nalocation l
   , dots.transcript t
   , dots.rnafeatureexon rfe
   , dots.translatedaafeature taf
where gf.na_feature_id = ef.parent_id
and gf.na_feature_id = gfl.na_feature_id
and gf.na_sequence_id = s.na_sequence_id
and ef.na_feature_id = l.na_feature_id
and t.na_feature_id = rfe.rna_feature_id
and rfe.exon_feature_id = ef.na_feature_id
and t.parent_id = gf.na_feature_id
and t.na_feature_id = taf.na_feature_id
and gf.external_database_release_id = ?
and gf.source_id = 'PF3D7_0219400'
";


  my $sh = $dbh->prepare($sql);
  $sh->execute($extDbRlsId);

  my $geneModels = {};

  my $transcriptToGeneMap = {};

  my %seenGenes;
  my %seenTranscripts;

  while(my $a = $sh->fetchrow_arrayref()) {

    unless($seenGenes{$a->[0]}) {
      $geneModels->{$a->[0]} = { 'source_id' => $a->[0],
                                 'na_feature_id' => $a->[1],
                                 'sequence_source_id' => $a->[14],
                                 'start' => $a->[11],
                                 'end' => $a->[12],
                                 'is_reversed' => $a->[13],
      };
      
    }

    unless($seenTranscripts{$a->[2]}) {
      $geneModels->{$a->[0]}->{transcripts}->{$a->[2]} = {'source_id' => $a->[2],
                                                          'na_feature_id' => $a->[3],
                                                          'translation_start' => $a->[9],
                                                          'translation_end' => $a->[10],
                                                          'is_reversed' => $a->[8],
                                                          'sequence_source_id' => $a->[14],
      };

      $transcriptToGeneMap->{$a->[2]} = $a->[0];
    }

    $seenGenes{$a->[0]} = 1;
    $seenTranscripts{$a->[2]} = 1;
 
    push @{$geneModels->{$a->[0]}->{transcripts}->{$a->[2]}->{exons}}, [$a->[4],$a->[5],$a->[6],$a->[7], $a->[8]];
  }

  $self->{_all_models_hash} = $geneModels;
  $self->{_transcript_to_gene_map} = $transcriptToGeneMap;
}



sub _makeUTRsFromMapResult {
  my ($self, $map, $primary) = @_;

  my @rv;
  if(ref($map) eq 'Bio::Coordinate::Result') {
    foreach($map->each_match()) {
      my $utr = $self->_makeUTRFromMatch($_, $primary);
      push @rv, $utr;
    }
  }
  # exactly one match
  else {
    my $utr = $self->_makeUTRFromMatch($map, $primary);
    push @rv, $utr;
  }

  return \@rv;
}


# the match object is just a Simple Location
# the match will always be in genomic coords so +1 for strand
sub _makeUTRFromMatch {
  my ($self, $match, $primary) = @_;

  return Bio::SeqFeature::Gene::UTR->new(-primary => $primary,
                                         -start => $match->start,
                                         -end => $match->end,
                                         -strand => +1,
      );
}



sub _getGeneModelHashFromGeneSourceId {
  my ($self, $geneSourceId) = @_;

  return $self->_getAllModelsHash()->{$geneSourceId};
}



sub _getTranscriptHashFromTranscriptId {
  my ($self, $transcriptId) = @_;

  my $geneSourceId = $self->_getTranscriptToGeneMap()->{$transcriptId};

  return $self->_getAllModelsHash()->{$geneSourceId}->{transcripts}->{$transcriptId};

}


1;
