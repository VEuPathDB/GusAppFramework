package GUS::GOPredict::Protein;

use strict;

sub setAssociationGraph{
    my ($self, $assocGraph) = @_;
    $self->{AssociationGraph} = $assocGraph;
}

sub getAssociationGraph{
    my ($self) = @_;
    return $self->{AssociationGraph};
}

sub addMotif{
    my ($self, $motif) = @_;
    push(@{$self->{Motifs}}, $motif);
}

sub getMotifs{
    my ($self) = @_;
    return $self->{Motifs};
}
