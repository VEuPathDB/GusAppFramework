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

A class for representing and processing Metabolic Pathways (KEGG, potentially others ex BioPax)

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
  my $self = {};  
  bless($self,$class);
  
  $self->{pathwayName} = $pathwayName;
  return $self;
}


sub setPathwayNode {
  my ($self,$nodeName, $node) = @_;
  $self->{nodes}->{$nodeName} = $node;
  #every node has a Type(Enzyme) and Name (ec:1.1.1.1)
}

sub getPathwayNode {
  my ($self, $nodeName) = @_;
  return $self->{nodes}->{$nodeName};
}

sub setNodeGraphics {
  my ($self,$nodeName, $graphics) = @_;
  $self->{graphics}->{$nodeName} = $graphics;
}

sub getNodeGraphics {
  my ($self, $nodeName) = @_;
  return $self->{graphics}->{$nodeName};
}


sub getPathwayName {
  my ($self) = @_;
  return $self->{pathwayName};
  #string
}

sub setPathwayNodeAssociation {
  my ($self,$asscName,$association) = @_;
  $self->{associations}->{$asscName} = $association;
}


sub getPathwayNodeAssociation {
  my ($self,$asscName) = @_;
  return $self->{associations}->{$asscName};
}

sub setPathwayInteractions {
  my ($self,$interactions) = @_;
  $self->{pathwayInteractions} = $interactions;
}

sub getPathwayNodeInteractions {
  my ($self) = @_;
  return $self->{pathwayInteractions};
}

1; 
