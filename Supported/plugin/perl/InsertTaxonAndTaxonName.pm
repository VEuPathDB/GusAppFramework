package GUS::Supported::Plugin::InsertTaxonAndTaxonName;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict;

use GUS::Model::SRes::Taxon;
use GUS::Model::SRes::TaxonName;
use GUS::PluginMgr::Plugin;
use GUS::PluginMgr::PluginUtilities::ConstraintFunction;

$| = 1;

sub getArgumentsDeclaration {
  my $argsDeclaration =
    [
      integerArg({name => 'ncbiTaxId',
        descr => 'ncbi_tax_id of the organism to be inserted',
        constraintFunc => undef,
        reqd => 1,
        isList => 0
      }),
      stringArg({name => 'rank',
        descr => 'taxonomic level such as order,family,species - should conform to ranks used by the NCBI taxonomy db - see PLUGIN_NOTES',
        constraintFunc => undef,
        reqd => 0,
        isList => 0
      }),
      stringArg({name => 'name',
        descr => 'name for organism such as scientific name',
        constraintFunc => undef,
        reqd => 0,
        isList => 0
      }),
      stringArg({name => 'parentNcbiTaxId',
        descr => 'ncbi_tax_id of the parent of the organism to be inserted in the taxonomic hierarchy ',
        constraintFunc => sub { CfMatchesRx('numeric', '([0-9]*)',@_) },
        reqd => 0,
        isList => 0
      }),
      stringArg({name => 'geneticCodeId',
        descr => 'Genetic Code of the organism to be inserted in the taxonomic hierarchy ',
        constraintFunc => sub { CfMatchesRx('numeric', '([0-9]*)',@_) },
        reqd => 0,
        isList => 0
      }),
      stringArg({name => 'mitochondrialGeneticCodeId',
        descr => 'Mitochondrial Genetic Code of the organism to be inserted in the taxonomic hierarchy ',
        constraintFunc => sub { CfMatchesRx('numeric', '([0-9]*)',@_) },
        reqd => 0,
        isList => 0
      }),
      enumArg({
        name => 'mode',
        descr => 'Operating mode. Either insert or update.',
        enum => 'insert, update',
        default => 'insert',
        constraintFunc => undef,
        reqd => 0,
        isList => 0
      }),
    ];
  return $argsDeclaration;
}

sub getDocumentation {

  my $purposeBrief = <<PURPOSEBRIEF;
Plug_in to insert or update a single record in sres.Taxon and in sres.TaxonName.
PURPOSEBRIEF

  my $purpose = <<PLUGIN_PURPOSE;
Plug_in that inserts a row into sres.Taxon and sres.TaxonName or updates an existing record - Used to add rows not added by LoadTaxon plugin or for applying manual patches as needed.
PLUGIN_PURPOSE

  #check the documentation for this
  my $tablesAffected = [['GUS::Model::SRes::Taxon', 'A single row is added/updated'],['GUS::Model::SRes::TaxonName', 'A single row is added/updated']];

  my $tablesDependedOn = [['GUS::Model::SRes::Taxon', 'If parent is invoked, parent taxon_id must exist']];

  my $howToRestart = <<PLUGIN_RESTART;
No explicit restart procedure.
PLUGIN_RESTART

  my $failureCases = <<PLUGIN_FAILURE_CASES;
unknown
PLUGIN_FAILURE_CASES

  my $notes = <<PLUGIN_NOTES;
rank argument from the following list:suborder,subspecies,subphylum,species subgroup,class,forma,kingdom,superkingdom,genus,species group,parvorder,family,superfamily,infraclass,superphylum,no rank,phylum,varietas,subfamily,species,subclass,superclass,tribe,subtribe,infraorder,superorder,order,subgenus.
PLUGIN_NOTES

  my $documentation = {purposeBrief => $purposeBrief,
    purpose => $purpose,
    tablesAffected => $tablesAffected,
    tablesDependedOn => $tablesDependedOn,
    howToRestart => $howToRestart,
    failureCases => $failureCases,
    notes => $notes
  };

  return $documentation;
}

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  my $documentation = &getDocumentation();
  my $argsDeclaration = &getArgumentsDeclaration();

  $self->initialize({
    requiredDbVersion => 4,
    cvsRevision       => '$Revision: 15381 $', # cvs fills this in!
    name              => ref($self),
    argsDeclaration   => $argsDeclaration,
    documentation     => $documentation
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

  my $ncbiTaxId = $self->getArg('ncbiTaxId');
  my $mode = $self->getArg('mode');

  my $rank = $self->getArg('rank');
  my $geneticCodeId = $self->getArg('geneticCodeId');
  my $mitochondrialGeneticCodeId = $self->getArg('mitochondrialGeneticCodeId');
  my $parentNcbiTaxId = $self->getArg('parentNcbiTaxId');
  my $name = $self->getArg('name');

  # we only support inserting/updating the scientific name at this time.
  my $nameClass = 'scientific name';

  my $exists;
  my $taxon;

  $taxon = GUS::Model::SRes::Taxon->new ({'ncbi_tax_id'=> $ncbiTaxId});
  $exists = $taxon->retrieveFromDB();

  if ($exists){
    if ($mode eq 'update') {
      $self->updateTaxon($taxon, $rank, $geneticCodeId, $mitochondrialGeneticCodeId, $parentNcbiTaxId, $name, $nameClass);
    } else {
      $self->userError("Plugin is run in insert mode but an existing entry for $ncbiTaxId is found in the database");
    }
  } else {
    if ($mode eq 'insert'){
      $self->insertTaxon($taxon, $rank, $geneticCodeId, $mitochondrialGeneticCodeId, $parentNcbiTaxId, $name, $nameClass);
    } else {
      $self->userError("Plugin is run in update mode but no entry for $ncbiTaxId is found in the database");
    }
  }

  my $rows = $taxon->submit();

  $self->undefPointerCache();

  my $resultDescrip = $taxon->hasChangedAttributes();
  if ($mode eq 'insert') {
    $resultDescrip = "A new record is inserted to sres.Taxon and sres.TaxonName for $name ($ncbiTaxId).";
  } else{
    $resultDescrip = "The existing records for $ncbiTaxId in sres.Taxon and/or sres.TaxonName are updated with the provided values.";
  }

  $self->setResultDescr($resultDescrip);
  $self->logData($resultDescrip);
}

sub insertTaxon {
  my ($self, $taxon, $rank, $geneticCodeId, $mitochondrialGeneticCodeId, $parentNcbiTaxId, $name, $nameClass) = @_;

  # Make sure we have everything to create a new record.
  # if (!($rank && $geneticCodeId && $$mitochondrialGeneticCodeId && $parentNcbiTaxId && $name && $nameClass)){
  $self->userError("name must be provided at the very minimum to insert a new record.") unless $name;

  # CREATE TAXON ENTRY
  if ( defined $rank){
    $taxon->setRank($rank);
  } else {
    $taxon->setRank('no rank');
  }

  $taxon->setGeneticCodeId($geneticCodeId) if $geneticCodeId;
  $taxon->setMitochondrialGeneticCodeId($mitochondrialGeneticCodeId) if $mitochondrialGeneticCodeId;

  # ASSOCIATE WITH PARENT TAXON
  if (defined $parentNcbiTaxId ) {
    my $parentTaxon = GUS::Model::SRes::Taxon->new({'ncbi_tax_id' => $parentNcbiTaxId });
    if ($parentTaxon->retrieveFromDB()) {
      $taxon->setParent($parentTaxon);
    }
    else {
      $self->userError("Parent taxon $parentNcbiTaxId must exist to before inserting the taxon entry.");
    }
  }

  # CREATE TAXONNAME
  my $taxonName = GUS::Model::SRes::TaxonName->new ({'name'=> $name, 'name_class'=> $nameClass});
  $taxon->setChild($taxonName);
}

sub updateTaxon {
  my ($self, $taxon, $rank, $geneticCodeId, $mitochondrialGeneticCodeId, $parentNcbiTaxId, $name, $nameClass) = @_;
  my $noUpdates = 0;

  if (defined $rank) {
    if ($rank eq $taxon->getRank()) {
      $self->userError("Rank provided to the plugin ($rank) for update is identical with the database. Remove the parameter to fix this problem");
    }
    else {
      $taxon->setRank($rank);
      $noUpdates++;
    }
  }

  if (defined $geneticCodeId){
    if ($geneticCodeId eq $taxon->getGeneticCodeId()){
      $self->userError("GeneticCodeId provided to the plugin ($geneticCodeId) for update is identical with the database. Remove the parameter to fix this problem");
    } else {
      $taxon->setGeneticCodeId($geneticCodeId);
      $noUpdates++;
    }
  }

  if (defined $mitochondrialGeneticCodeId){
    if ($mitochondrialGeneticCodeId eq $taxon->getMitochondrialGeneticCodeId()){
      $self->userError("MitoChondrialGeneticCodeId provided to the plugin ($mitochondrialGeneticCodeId) for update is identical with the database. Remove the parameter to fix this problem");
    } else {
      $taxon->setMitochondrialGeneticCodeId($mitochondrialGeneticCodeId);
      $noUpdates++;
    }
  }

  if (defined $parentNcbiTaxId) {
    my $parentTaxon = GUS::Model::SRes::Taxon->new ({'ncbi_tax_id'=> $parentNcbiTaxId});

    if ($parentTaxon->retrieveFromDB()){
      my $currentParentTaxon = $taxon->getParent('SRes::Taxon')->getNcbiTaxId();
      if ($parentNcbiTaxId eq $currentParentTaxon) {
        $self->userError("ParentNcbiTaxId provided to the plugin ($parentNcbiTaxId) for update is identical with the database. Remove the parameter to fix this problem");
      } else{
        $taxon->setParent($parentTaxon);
        $noUpdates++;
      }
    } else {
      $self->userError("Parent taxon must exist to update the parent as $parentNcbiTaxId");
    }
  }

  ## UPDATE TAXON NAME
  if (defined $name) {
    my $taxonName = $taxon->getChild('SRes::TaxonName', 1, 0, {'name_class'=> $nameClass });
    if ($name eq $taxonName->getName()) {
      $self->userError("Name provided to the plugin ($name) for update is identical with the database. Remove the parameter to fix this problem");
    } else {
      $taxonName->setName($name);
      $taxonName->setNameClass($nameClass);
      $noUpdates ++;
    }
  }

  $self->userError("No updates made to the existing taxon entry as all parameters provided are identical to the database.") unless $noUpdates > 0 ;

}

sub undoTables {
  my ($self) = @_;

  return ('SRes.TaxonName','SRes.Taxon');
}

1;


