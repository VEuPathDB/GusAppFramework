#############################################################################
##                    LoadTemporaryTaxon.pm
##
## Plugin to insert rows into sres.taxon and sres.taxonname given a list of
## organisms with temporary NCBITaxIds.
##
#############################################################################

package GUS::Supported::Plugin::LoadTemporaryTaxon;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict;

use GUS::ObjRelP::DbiDatabase;
use GUS::Model::SRes::Taxon;
use GUS::Model::SRes::TaxonName;
use GUS::PluginMgr::Plugin;

$| = 1;

sub getArgumentsDeclaration {
  my $argsDeclaration =
    [
      stringArg({ name => 'inputFile',
        descr          => 'a tab-delimited file containing organisms with temporary NCBITaxonIds, reqd',
        constraintFunc => undef,
        reqd           => 1,
        isList         => 0
      }),
    ];

  return $argsDeclaration;
}

sub getDocumentation {

  my $purposeBrief = <<PURPOSEBRIEF;
Plug_in to add rows into sres.Taxon and into sres.TaxonName.
PURPOSEBRIEF

  my $purpose = <<PLUGIN_PURPOSE;
Plug_in that inserts rows into sres.Taxon and sres.TaxonName - adds rows not added by LoadTaxon plugin.
PLUGIN_PURPOSE

  #check the documentation for this
  my $tablesAffected = [ [ 'GUS::Model::SRes::Taxon', 'A single row is added' ], [ 'GUS::Model::SRes::TaxonName', 'A single row is added' ] ];

  my $tablesDependedOn = [ [ 'GUS::Model::SRes::Taxon', 'parent taxon_id must exist' ] ];

  my $howToRestart = <<PLUGIN_RESTART;
No explicit restart procedure.
PLUGIN_RESTART

  my $failureCases = <<PLUGIN_FAILURE_CASES;
unknown
PLUGIN_FAILURE_CASES

  my $notes = <<PLUGIN_NOTES;
PLUGIN_NOTES

  my $documentation = { purposeBrief => $purposeBrief,
    purpose                          => $purpose,
    tablesAffected                   => $tablesAffected,
    tablesDependedOn                 => $tablesDependedOn,
    howToRestart                     => $howToRestart,
    failureCases                     => $failureCases,
    notes                            => $notes
  };

  return $documentation;
}

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self, $class);

  my $documentation = &getDocumentation();
  my $argsDeclaration = &getArgumentsDeclaration();

  $self->initialize({ requiredDbVersion => 4,
    cvsRevision                         => '$$', # cvs fills this in!
    name                                => ref($self),
    argsDeclaration                     => $argsDeclaration,
    documentation                       => $documentation
  });

  return $self;
}


########################################################################
# Main Program
########################################################################

sub run {
  my ($self) = @_;

  $self->logAlgInvocationId();
  $self->logCommit();
  $self->logArgs();

  my $file = $self->getArg('inputFile');
  open(ORGLIST, $file) || die "Can't open input file '$file': $!\n";

  my $orgCount = 0;

  # Load all organisms in a single transaction.
  $self->getDb()->manageTransaction(0, 'begin');

  while (<ORGLIST>) {
    chomp;
    my ($ncbiTaxonId, $speciesNcbiTaxonId, $organismFullName) = split(/\t/, $_);

    my $parentTaxon = GUS::Model::SRes::Taxon->new({ 'ncbi_tax_id' => $speciesNcbiTaxonId });
    unless ($parentTaxon->retrieveFromDB()){
      $self->userError("The parent $speciesNcbiTaxonId provided for $organismFullName ($ncbiTaxonId) does not exist in the database.");
    }

    my $geneticCodeId = $parentTaxon->getGeneticCodeId();
    my $mitochondrialGeneticCodeId = $parentTaxon->getMitochondrialGeneticCodeId();

    my $taxon = GUS::Model::SRes::Taxon->new({
      'ncbi_tax_id'                   => $ncbiTaxonId,
      'genetic_code_id'               => $geneticCodeId,
      'mitochondrial_genetic_code_id' => $mitochondrialGeneticCodeId,
      'rank'                          => 'no rank',
    });

    if ($taxon->retrieveFromDB()){
      $self->userError("There is an existing record with ncbiTaxonId ($ncbiTaxonId) in the database.");
    }

    my $taxonName = GUS::Model::SRes::TaxonName->new({
      'name'       => $organismFullName,
      'name_class' => 'scientific name'
    });

    $taxon->setChild($taxonName);
    $taxon->setParent($parentTaxon);

    # Disable transaction here so all organisms are submitted in a single transaction.
    $taxon->submit(0, 1);
    $orgCount++;
  }

  $self->getDb()->manageTransaction(0, 'commit');

  my $resultDescr = "Records created in sres.Taxon and sres.TaxonName for $orgCount organisms with temporary NCBITaxonIds.";
  $self->setResultDescr($resultDescr);
  $self->logData($resultDescr);
}

#######################################################################
# Sub-routines
#######################################################################

sub undoTables {
  my ($self) = @_;

  return ('SRes.TaxonName', 'SRes.Taxon');
}

1;


