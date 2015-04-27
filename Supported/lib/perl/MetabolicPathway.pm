package GUS::Supported::MetabolicPathway;

use strict;

=pod

=head1 Description

Superclass for specific metabolic pathway map (KEGG, MPMP, BioCyc) as GUS Model Objects.  Subclasses must implement makeGusObjects and getReaderClass methods.  
The makeGusObjecs method can be called by a plugin to load into SRes tables

=cut

#--------------------------------------------------------------------------------
# Abstract Object Methods
#--------------------------------------------------------------------------------
sub makeGusObjects {}
sub getReaderClass {}

#--------------------------------------------------------------------------------
# Object Methods
#--------------------------------------------------------------------------------
sub new {
  my ($class, $file) = @_;
  my $self = {};  
  bless($self, $class);

  my $readerClass = $self->getReaderClass();

  eval "require $readerClass";

  my $reader = eval {
    $readerClass->new($file);
  };

  $reader->read();
  
  $self->{_reader} = $reader;
  return $self;
}

sub getReader {
  my ($self) = @_;

  return $self->{_reader};
}


sub addNode {
  my ($self, $gusNode, $uniqueNodeId) = @_;

  my $expected = 'GUS::Model::SRes::PathwayNode';
  my $className = ref($gusNode);
  &checkClass($className, $expected);

  $self->{_gus_nodes}->{$uniqueNodeId} = $gusNode;
}

sub getNodeByUniqueId {
  my ($self, $uniqueId) = @_;
  return $self->{_gus_nodes}->{$uniqueId};
}

sub getNodes {
  my ($self) = @_;
  my @rv = values %{$self->{_gus_nodes}};
  return \@rv;
}

sub setPathway {
  my ($self, $gusPathway) = @_;

  my $expected = 'GUS::Model::SRes::Pathway';
  my $className = ref($gusPathway);
  &checkClass($className, $expected);

  $self->{_gus_pathway} = $gusPathway;
}

sub getPathway {
  my ($self) = @_;
  return $self->{_gus_pathway};;
}


sub addRelationship {
  my ($self, $gusRelationship) = @_;

  my $expected = 'GUS::Model::SRes::PathwayRelationship';
  my $className = ref($gusRelationship);
  &checkClass($className, $expected);

  push @{$self->{_gus_relationships}}, $gusRelationship;
}

sub getRelationships {
  my ($self) = @_;
  my @rv = @{$self->{_gus_relationships}};
  return \@rv;
}


#--------------------------------------------------------------------------------
#Static Util methods
#--------------------------------------------------------------------------------

sub checkClass {
  my ($className, $expected) = @_;

  unless($className eq $expected) {
    die "ClassName $className did not match expected $expected;";
  }
  
}



1; 
