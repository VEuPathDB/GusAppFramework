#!/usr/bin/perl

# =================================================
# Package MetabolicPathway 
# =================================================

package ApiCommonData::Load::MetabolicPathway;

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
}

sub getPathwayNodes {
  my ($self) = @_;
  return $self->{pathwayNodes};
}


sub setPathwayName {
  my ($self,$name) = @_;
  $self->{pathwayName} = $name;
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
 
