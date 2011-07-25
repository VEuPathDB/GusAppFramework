#############################################################################
##                    InsertTaxonAndTaxonName.pm
##
## Plug_in to a row into sres.taxon and sres.taxonname
##
##
#############################################################################

package GUS::Supported::Plugin::InsertTaxonAndTaxonName;
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

     integerArg({name => 'parentNcbiTaxId',
		 descr => 'ncbi_tax_id of the parent of the organism to be inserted in the taxonomic hierarchy ',
		 constraintFunc => undef,
		 reqd => 0,
		 isList => 0
		}),

     stringArg({name => 'parentRank',
		descr => 'reqd if parentNcbiTaxId-taxonomic level such as order,family,species - should conform to ranks used by the NCBI taxonomy db - \see PLUGIN_NOTES',
		constraintFunc => undef,
		reqd => 0,
		isList => 0
	       }),

     integerArg({name => 'ncbiTaxId',
		 descr => 'ncbi_tax_id of the organism to be inserted',
		 constraintFunc => undef,
		 reqd => 0,
		 isList => 0
		}),

     stringArg({name => 'rank',
		descr => 'taxonomic level such as order,family,species - should conform to ranks used by the NCBI taxonomy db - see PLUGIN_NOTES',
		constraintFunc => undef,
		reqd => 1,
		isList => 0
	       }),

     stringArg({name => 'name',
		descr => 'name for organism such as scientific name',
		constraintFunc => undef,
		reqd => 1,
		isList => 0
	       }),

     stringArg({name => 'nameClass',
		descr => 'type of name such as scientific name, should conform to name_class used by the NCBI taxonomy db - see PLUGIN_NOTES',
		constraintFunc => undef,
		reqd => 1,
		isList => 0,
	       })
    ];

  return $argsDeclaration;
}

sub getDocumentation {

  my $purposeBrief = <<PURPOSEBRIEF;
Plug_in to add a row into sres.Taxon and into sres.TaxonName.
PURPOSEBRIEF

  my $purpose = <<PLUGIN_PURPOSE;
Plug_in that inserts a row into sres.Taxon and sres.TaxonName - adds rows not added by LoadTaxon plugin.
PLUGIN_PURPOSE

  #check the documentation for this
  my $tablesAffected = [['GUS::Model::SRes::Taxon', 'A single row is added'],['GUS::Model::SRes::TaxonName', 'A single row is added']];

  my $tablesDependedOn = [['GUS::Model::SRes::Taxon', 'If parent is invoked, parent taxon_id must exist']];

  my $howToRestart = <<PLUGIN_RESTART;
No explicit restart procedure.
PLUGIN_RESTART

  my $failureCases = <<PLUGIN_FAILURE_CASES;
unknown
PLUGIN_FAILURE_CASES

  my $notes = <<PLUGIN_NOTES;
rank argument from the following list:suborder,subspecies,subphylum,species subgroup,class,forma,kingdom,superkingdom,genus,species group,parvorder,family,superfamily,infraclass,superphylum,no rank,phylum,varietas,subfamily,species,subclass,superclass,tribe,subtribe,infraorder,superorder,order,subgenus.
nameClass argument from the following list:misnomer,misspelling,equivalent name,genbank synonym,anamorph,includes,teleomorph,genbank common name,synonym,scientific name,common name,blast name,in-part,genbank anamorph,genbank acronym,acronym.
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

  $self->initialize({requiredDbVersion => 3.6,
		     cvsRevision => '$Revision: 9470 $', # cvs fills this in!
		     name => ref($self),
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

  $self->checkForExistingRows();

  my $taxon = $self->getTaxon();

  my $taxonName = $self->getTaxonName();

  $taxon->setChild($taxonName);

  my $rows = $taxon->submit();

  $self->undefPointerCache();

  my $name = $self->getArg('name');

  my $resultDescrip = "$rows row(s) inserted into sres.Taxon and sres.TaxonName for $name";

  $self->setResultDescr($resultDescrip);
  $self->logData($resultDescrip);
}

#######################################################################
# Sub-routines
#######################################################################

sub checkForExistingRows {
  my ($self) = @_;

  my $name = $self->getArg('name');

  my $nameClass = $self->getArg('nameClass');

  my $taxonName = GUS::Model::SRes::TaxonName->new({'name'=>$name,'name_class'=>$nameClass});

  my $existing = $taxonName->retrieveFromDB();

  if ($existing) {

    my $taxonId = $taxonName->getTaxonId();

    $self->userError("There is already an entry in Taxon and in TaxonName for $name with name_class = $nameClass. The taxon_id = $taxonId");
  }

}

sub getTaxon {
    my ($self) = @_;

    my $ncbiTaxId = $self->getArg('ncbiTaxId') if $self->getArg('ncbiTaxId');

    my $rank = $self->getArg('rank');

    my $taxon;

    if ($self->getArg('ncbiTaxId')) {
      $taxon = GUS::Model::SRes::Taxon->new ({'ncbi_tax_id'=>$ncbiTaxId});
      $taxon->retrieveFromDB();
    }
    else {
      $taxon = GUS::Model::SRes::Taxon->new();
    }

    $taxon->setRank($rank) unless $taxon->getRank();

    if ($self->getArg('parentNcbiTaxId')) {

      my $parentTaxon = $self->getParentTaxon();

      $taxon->setParent($parentTaxon);
    }

    return $taxon;
}

sub getParentTaxon {
  my ($self) = @_;

  my $parentNcbiTaxId = $self->getArg('parentNcbiTaxId');

  my $parentRank = $self->getArg('parentRank') || $self->userError("Parent rank required if parent ncbi_tax_id argument given");

  my $parentTaxon = GUS::Model::SRes::Taxon->new ({'ncbi_tax_id'=>$parentNcbiTaxId});

  $parentTaxon->retrieveFromDB();

  $parentTaxon->setRank($parentRank) unless $parentTaxon->getRank();

  return $parentTaxon;

}

sub getTaxonName {
  my ($self) = @_;

  my $name = $self->getArg('name');

  my $name_class = $self->getArg('nameClass');

  my $taxonName = GUS::Model::SRes::TaxonName->new ({'name'=>$name,'name_class'=>$name_class});

  return $taxonName;

}

1;


