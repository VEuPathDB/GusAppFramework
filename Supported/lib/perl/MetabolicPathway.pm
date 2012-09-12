#!/usr/bin/perl

# =================================================
# Package MetabolicPathway 
# =================================================

package GUS::Supported::MetabolicPathway;

# =================================================
# Documentation
# =================================================

=pod

=head1 Description

A class for representing and processing a Metabolic Pathway (KEGG, potentially others ex BioPax)

=cut

# =================================================
# Pragmas
# =================================================

use strict;


# =================================================
# Package Methods
# =================================================


sub new {

  my ($class,$pathwayName) = @_;

  my $self = {#strings
              pathwayName => $pathwayName

              #Objs - these are placed optional for now via get/set
              #pathwayNodes,
              #pathwayNodeAssociations,
              #pathwayInteractions
              };  

  bless($self,$class);

}

sub setPathwayNodes {
  my ($self,$nodes) = @_;
  $self->{pathwayNodes} = $nodes;
  #every node has a Type(Enzyme) and Name (ec:1.1.1.1)
}

sub getPathwayNodes {
  my ($self) = @_;
  return $self->{pathwayNodes};
}


sub setPathwayName {
  my ($self,$name) = @_;
  $self->{pathwayName} = $name;
  #string
}

sub getPathwayName {
  my ($self) = @_;
  return $self->{pathwayName};
}

sub setPathwayNodeAssociations {
  my ($self,$associations) = @_;
  $self->{pathwayNodeAssociations} = $associations;
}


sub getPathwayNodeAssociations {
  my ($self) = @_;
  return $self->{pathwayNodeAssociations};
}

sub setPathwayInteractions {
  my ($self,$interactions) = @_;
  $self->{pathwayInteractions} = $interactions;
}

sub getPathwayNodeInteractions {
  my ($self) = @_;
  return $self->{pathwayInteractions};
}
 
