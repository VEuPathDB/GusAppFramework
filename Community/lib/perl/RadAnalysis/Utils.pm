package GUS::Community::RadAnalysis::Utils;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(getOntologyEntriesHashFromParentValue);

use strict;

use GUS::Community::RadAnalysis::RadAnalysisError;

use GUS::Model::Study::OntologyEntry;

#--------------------------------------------------------------------------------
# Requires default DBI database (If you're running from a plugin... you have it already)
sub getOntologyEntriesHashFromParentValue {
  my ($self, $value) = @_;

  return unless($value);

  my %ontologyEntries;

  my $dataTypeOntologyEntry = GUS::Model::Study::OntologyEntry->new({value => $value});

  unless($dataTypeOntologyEntry->retrieveFromDB()) {
    GUS::Community::RadAnalysis::SqlError->new("Could not Retrieve Study::OntologyEntry row for [$value]");
  }

  my @kids = $dataTypeOntologyEntry->getChildren('Study::OntologyEntry', 1);

  foreach my $oe (@kids) {
    my $value = $oe->getValue();

    $ontologyEntries{$_} = $oe;
  }

  return \%ontologyEntries;
}

#--------------------------------------------------------------------------------


1;
