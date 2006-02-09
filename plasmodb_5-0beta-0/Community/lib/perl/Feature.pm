# $Id: $
# Human Genetics, UCLA Medical School, University of California, Los Angeles

# POD documentation - main docs before the code

=head1 NAME

GUS::Community::Feature - an Affymetrix feature.

=head1 DESCRIPTION

Modification (by R. Gorski) of the BioPerl module for Bio::Expression::Microarray::Feature
(Copyright Allen Day <allenday@ucla.edu>, Stanley Nelson <snelson@ucla.edu>
Human Genetics, UCLA Medical School, University of California, Los Angeles)

=head1 FEEDBACK

Direct feedback to E<lt>rgorski@mail.med.uprnn.edu<gt>

=cut

package GUS::Community::Feature;

use strict;
use base qw(Bio::Expression::FeatureI Bio::Root::Root);

use vars qw($DEBUG);

use Class::MakeMethods::Template::Flyweight
  scalar => [qw(
				probe feat expos pos cbase pbase tbase
				atom index codon_index codon regiontype region
				length value standard_deviation sample_count
				display_id
				x y is_match is_masked is_outlier is_modified is_singleton
			   )
			],
  new => 'new',
;

=head2 new

 Title   : new
 Usage   : $ftr = Bio::Expression::Microarray::Affymetrix::Feature->new();
 Function: create a new feature object
 Returns : a Bio::Expression::Microarray::Affymetrix::Feature object
 Args    : none.  all attributes must be set by calling the
           appropriate method
=cut

=head2 get/set methods

The following methods can be used to set or retrieve an attribute
for a feature object.  Call them as in (a) to set an attribute, or
as in (b) to retrieve the value of an attribute:

 (a) $ftr->method('new_value');
 (b) $ftr->method();

Note that no attempt is made to validate the values you store
using an accessor method.

The following methods, along with brief descriptions of their
purpose, are available:

 Method                   Purpose
 ------                   -------
 probe                    ???
 feat                     ???
 expos                    ???
 pos                      ???
 cbase                    ???
 pbase                    ???
 tbase                    ???
 atom                     ???
 index                    ???
 codon_index              ???
 codon                    ???
 regiontype               ???
 region                   ???

=cut


1;
