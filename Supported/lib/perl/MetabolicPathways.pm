#!/usr/bin/perl

# =================================================
# Package MetabolicPathways 
# =================================================

package GUS::Supported::MetabolicPathways;

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
# Includes
# =================================================

use GUS::Supported::MetabolicPathway;

# =================================================
# Package Methods
# =================================================


sub new {

  my ($class) = @_;
  my $self = {};  
  bless($self,$class);
  return $self;
}


sub getNewPathwayObj {
  my ($self, $pathwayName) = @_;

  $self->{$pathwayName} = GUS::Supported::MetabolicPathway->new($pathwayName);
  return $self->{$pathwayName};
}

sub setPathwayObj {
  my($self, $pathwayObj) = @_;
  my $name = $pathwayObj->getPathwayName; print "$name\n";
  $self->{$pathwayObj->getPathwayName} = $pathwayObj;
}


1; 
