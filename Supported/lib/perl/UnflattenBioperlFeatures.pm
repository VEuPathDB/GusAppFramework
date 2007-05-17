package GUS::Supported::UnflattenBioperlFeatures;

use strict;
use Bio::SeqFeature::Tools::Unflattener;

sub preprocess {
  my ($bioperlSeq) = @_;

  my $unflattener = Bio::SeqFeature::Tools::Unflattener->new();

  $unflattener->unflatten_seq(-seq => $bioperlSeq, -use_magic => 1);
}

1;
