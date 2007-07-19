package GUS::Community::FileTranslator::DatabaseFunctions;

use strict;

sub new {
  my ($M) = @_;
  my $self = {};
  bless $self,$M;
  
  return $self;
}

#--------------------------------------------------------------------------------

sub physicalBioSequenceTypeOntologyEntryId {
  my ($self, $hash) = @_;

  my %mapping;

  unless($hash->{dbh}) {
    die "Function [nameToCompositeElementId] must give a database handle";
  }

  my $sql = "select value, ontology_entry_id 
             from Study.ONTOLOGYENTRY 
             where category = 'PhysicalBioSequenceType'";

  my $sh = $hash->{dbh}->prepare($sql);
  $sh->execute();

  while(my ($value, $id) = $sh->fetchrow_array()) {
    $mapping{$value} = $id;
  }
  $sh->finish();

  return \%mapping;
}


#--------------------------------------------------------------------------------

sub designElementOntologyEntryId {
  my ($self, $hash) = @_;

  my %mapping;

  unless($hash->{dbh}) {
    die "Function [nameToCompositeElementId] must give a database handle";
  }

  my $sql = "select value, ontology_entry_id 
             from Study.ONTOLOGYENTRY 
             where category = 'DesignElement'";

  my $sh = $hash->{dbh}->prepare($sql);
  $sh->execute();

  while(my ($value, $id) = $sh->fetchrow_array()) {
    $mapping{$value} = $id;
  }
  $sh->finish();

  return \%mapping;
}


#--------------------------------------------------------------------------------

sub polymerTypeOntologyEntryId {
  my ($self, $hash) = @_;

  my %mapping;

  unless($hash->{dbh}) {
    die "Function [nameToCompositeElementId] must give a database handle";
  }

  my $sql = "select value, ontology_entry_id 
             from Study.ONTOLOGYENTRY 
             where category = 'PolymerType'";

  my $sh = $hash->{dbh}->prepare($sql);
  $sh->execute();

  while(my ($value, $id) = $sh->fetchrow_array()) {
    $mapping{$value} = $id;
  }
  $sh->finish();

  return \%mapping;
}


#--------------------------------------------------------------------------------

sub extDbRlsIdFromSpec {
  my ($self, $hash) = @_;

  my %mapping;

  unless($hash->{dbh}) {
    die "Function [nameToCompositeElementId] must give a database handle";
  }

  my $sql = "select  e.name || '|' || r.version as spec, r.external_database_release_id
             from SRes.EXTERNALDATABASE e, Sres.EXTERNALDATABASERELEASE r
             where e.external_database_id = r.external_database_id";

  my $sh = $hash->{dbh}->prepare($sql);
  $sh->execute();

  while(my ($spec, $id) = $sh->fetchrow_array()) {
    $mapping{$spec} = $id;
  }
  $sh->finish();

  return \%mapping;
}

#--------------------------------------------------------------------------------

sub nameToCompositeElementId {
  my ($self, $hash) = @_;

  my %mapping;

  unless($hash->{dbh}) {
    die "Function [nameToCompositeElementId] must give a database handle";
  }

  unless($hash->{arrayDesignName}) {
    die "Function [nameTOCompositeElementId] must give an arrayDesignName";
  }

  my $sql = "select s.name, s.composite_element_id 
             from  Rad.ShortOligoFamily s, Rad.ArrayDesign a
             where s.array_design_id = a.array_design_id
              and a.name = ?";

  my $sh = $hash->{dbh}->prepare($sql);
  $sh->execute($hash->{arrayDesignName});

  while(my ($name, $id) = $sh->fetchrow_array()) {
    $mapping{$name} = $id;
  }
  $sh->finish();

  return \%mapping;
}


#--------------------------------------------------------------------------------

1;
