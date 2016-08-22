package GUS::Supported::MetabolicPathwayReader;

use strict;

=pod

=head1 Description

Superclass for specific metabolic pathway map reader (KEGG, MPMP, BioCyc).  Subclasses must implement read method but then can create whatever other objects make sense to store the map.

=cut

#--------------------------------------------------------------------------------
# Abstract Object Methods
#--------------------------------------------------------------------------------
sub read {}


#--------------------------------------------------------------------------------
# Object Methods
#--------------------------------------------------------------------------------


sub new {
  my ($class, $file) = @_;
  my $self = {};  
  bless($self, $class);
  
  $self->{_file} = $file;
  return $self;
}

sub getFile {
  my ($self) = @_;

  return $self->{_file};
}

1;

