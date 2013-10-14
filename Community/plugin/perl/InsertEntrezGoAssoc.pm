#############################################################################
##                    InsertEntrezGoAssoc.pm
##
## created October 10, 2013  by Elisabetta Manduchi, modifying an older
## plugin by Jennifer Dommer
#############################################################################

package GUS::Community::Plugin::InsertEntrezGoAssoc;
@ISA = qw(GUS::PluginMgr::Plugin);


use strict;

use GUS::PluginMgr::Plugin;
use GUS::Model::SRes::OntologyTerm;
use GUS::Model::SRes::OntologyTermType;
use GUS::Model::DoTS::Gene;
use GUS::Model::DoTS::GeneInstance;
use GUS::Model::DoTS::GeneFeature;
use GUS::Model::DoTS::GOAssociation;
use GUS::Model::DoTS::GOAssociationInstance;
use GUS::Model::DoTS::GOAssociationInstanceLOE;
use GUS::Model::DoTS::GOAssocInstEvidCode;


my $purposeBrief = <<PURPOSEBRIEF;
Plug_in to insert the Entrez GO associations.
PURPOSEBRIEF

my $purpose = <<PLUGIN_PURPOSE;
plug_in to load the data from the gene2go file downloaded from NCBI into the DoTS.GOAssociation, DoTS.GOAssociationInstance, and DoTS.GOAssocInstEvidCode tables.
PLUGIN_PURPOSE

my $tablesAffected = [['GUS::Model::DoTS::GOAssociation', 'This will be used to map entries in DoTS::Gene to GO Terms in SRes::OntologyTerm'],['GUS::Model::DoTS::GOAssociationInstance', 'The new GOAssociation entries will be mapped to a loe and the current external database release ID'],['GUS::Model::DoTS::GOAssocInstEvidCode', 'Mappings from GO evidence codes in the SRes::OntologyTerm table to the new entries in the DoTS::GOAssociationInstance table will be done here']];

my $tablesDependedOn = [['GUS::Model::DoTS::Gene','We will link all entries for a given external database release id in Gene to GO terms using DoTS::GOAssociation'],['GUS::Model::SRes::ExternalDatabaseRelease', 'The external database releases for Entrez genes, GO terms, Entrez GO Annotations and Evidence Code Ontology'],['GUS::Model::SRes::OntologyTerm','GO terms and Evidence Codes in the gene2go file must be present in this table']];

my $howToRestart = <<PLUGIN_RESTART;
There is no restart method for this plugin.  All entries are checked before they are loaded into the database to prevent duplicate entries.
PLUGIN_RESTART

my $failureCases = <<PLUGIN_FAILURE_CASES;
If there are GO terms in the file that are not in SRes.OntologyTerm the plugin will skip them with a warning. Similarly if a gene in the file is not in our db.
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
PLUGIN_NOTES

my $documentation = {purposeBrief => $purposeBrief,
		     purpose => $purpose,
		     tablesAffected => $tablesAffected,
		     tablesDependedOn => $tablesDependedOn,
		     howToRestart => $howToRestart,
		     failureCases => $failureCases,
		     notes => $notes
		    };

my $argsDeclaration =
[
 stringArg({name => 'assocExtDbRlsSpec',
            descr => "The ExternalDBRelease specifier for the Entrez GO associations. Must be in the format 'name|version', where the name must match a name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
            constraintFunc => undef,
            reqd => 1,
            isList => 0
            }),
 stringArg({name => 'entrezExtDbRlsSpec',
            descr => "The ExternalDbRelease specifier for the Entrez genes. Must be in the format 'name|version', where the name must match a name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
            constraintFunc => undef,
            reqd => 1,
            isList => 0
            }),
 stringArg({name => 'goExtDbRlsSpec',
            descr => "The ExternalDbRelease specifier for the Gene Ontology. Must be in the format 'name|version', where the name must match a name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
            constraintFunc => undef,
            reqd => 1,
            isList => 0
            }),
 stringArg({name => 'ecoExtDbRlsSpec',
	    descr => "The ExternalDbRelease specifier for the Evidence Code Ontology. Must be in the format 'name|version', where the name must match a name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
	    constraintFunc => undef,
	    reqd => 1,
	    isList => 0
	   }),
 stringArg({name => 'species',
	    descr => "Optional scientific name of the species to which the loading should be restricted",
	    constraintFunc => undef,
	    reqd => 0,
	    isList => 0
	   }),
 fileArg({name => 'file',
	  descr => 'path to the gene2go file',
	  constraintFunc => undef,
	  reqd => 1,
	  isList => 0,
	  mustExist => 1,
	  format => ''
        })
 ];

my $goQuery;
my $entrezQuery;
my $ecoQuery;

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  $self->initialize({requiredDbVersion => 4.0,
		     cvsRevision => '$Revision: 12937 $',
		     name => ref($self),
		     argsDeclaration   => $argsDeclaration,
		     documentation     => $documentation
		    });

  return $self;
}

# --------------------------------------------------------------------
# Main
# --------------------------------------------------------------------

sub run{
  my ($self) = @_;
  
  my $msg;
  my $goHash = $self->makeGoHash();
  $msg = $self->loadData($goHash);
  return $msg;
}

sub makeGoHash{
  my ($self) = @_;
  my $goHash;
  my $file = $self->getArg('file');
  my $ncbiTaxonId;
  if ($self->getArg('species')) {
    $ncbiTaxonId = getTaxon($self->getArg('species'));
  }
  open (GO, $file) || die "Can't open $file.  Reason: $!\n";
  
  while(<GO>){
    chomp;
    if($_ =~ /^\#/){
      next;
    }
    my @goArray = split(/\t/, $_);
    
    my $taxId = $goArray[0];
    my $entrezId = $goArray[1];
    my $goId = $goArray[2];
    my $evidence = $goArray[3];
    if (defined $ncbiTaxonId && $taxId!=$ncbiTaxonId) {
      next;
    }
    push(@{$goHash->{$goId}->{$entrezId}}, $evidence);
  }
  close(GO);
  
  return ($goHash); 
}

sub getTaxon {
  my ($self, $species) = @_;
  my $taxonQuery = $self->getQueryHandle()->prepare("select t.ncbi_taxon_id from sres.taxon t, sres.taxonname n where t.taxon_id=n.taxon_id and n.name=$species") or die DBI::errstr;

  $taxonQuery->execute() or die DBI::errstr;
  my ($ncbiTaxonId) = $taxonQuery->fetchrow_array();
  $taxonQuery->finish() or die DBI::errstr;
  unless($ncbiTaxonId) {
    $self->userError("No species $species in the database");
  }
  return($ncbiTaxonId);
}

sub loadData{
  my ($self, $goHash) = @_;
  my $loeId = $self->getLoeId();

  my $entriesCount = 0;
  my $skippedCount = 0;

  my $assocExtDbRlsId = $self->getExtDbRlsId($self->getArg('assocExtDbRlsSpec'));  
  my $entrezExtDbRlsId = $self->getExtDbRlsId($self->getArg('entrezExtDbRlsSpec'));  
  my $goExtDbRlsId = $self->getExtDbRlsId($self->getArg('goExtDbRlsSpec'));  
  my $ecoExtDbRlsId = $self->getExtDbRlsId($self->getArg('ecoExtDbRlsSpec'));
  
  foreach my $goId (keys %{$goHash}){
    $self->log("Loading entries for $goId into the database.");
    foreach my $entrezId (keys %{$goHash->{$goId}}){
      my $goAssoc = $self->makeGoAssoc($goId, $entrezId, $goExtDbRlsId, $entrezExtDbRlsId);
      unless($goAssoc){
	$skippedCount++;
	$self->undefPointerCache();
	next;
      }
      
      my $goAssocInst = $self->makeGoAssocInst($loeId, $assocExtDbRlsId);
      my %seen;
      foreach my $evidence (@{$goHash->{$goId}->{$entrezId}}){
	unless ($seen{$evidence}) {
	  $seen{$evidence} = 1;
	  my $evidCodeId = $self->getEvidCodeId($evidence, $ecoExtDbRlsId);
	  my $goAssocInstEvidCode = GUS::Model::DoTS::GOAssocInstEvidCode->new({go_evidence_code_id => $evidCodeId});
	  $goAssocInstEvidCode->setParent($goAssocInst);
	}
      }
      $goAssocInst->setParent($goAssoc);
      $goAssoc->submit();
      $self->undefPointerCache();
      $entriesCount++;
      
      if($entriesCount % 1000 == 0) {
	$self->log("Processed $entriesCount entries. Skipped $skippedCount");
      }
    }
  }
  
  my $msg = "$entriesCount entries added to the database, $skippedCount skipped.\n";
  return $msg;
}

sub makeGoAssoc{
  my ($self, $goId, $entrezId, $goExtDbRlsId, $entrezExtDbRlsId) = @_;
  my $tableId = $self->getTableId();
  
  unless ($goQuery) {  
    $goQuery = $self->getQueryHandle()->prepare("select ontology_term_id from sres.OntologyTerm where source_id=? and external_database_release_id = $goExtDbRlsId") or die DBI::errstr;
  }
  $goQuery->execute($goId) or die DBI::errstr;
  my ($goTermId) = $goQuery->fetchrow_array();
  $goQuery->finish() or die DBI::errstr;
  unless($goTermId) {
    $self->log("Skipping GO ID $goId ... not in DB");
    return 0 ;
  }

  unless ($entrezQuery) {
    $entrezQuery = $self->getQueryHandle()->prepare("select g.gene_id from dots.GeneFeature gf, dots.GeneInstance gi, dots.Gene g where g.external_database_release_id=$entrezExtDbRlsId and g.gene_id = gi.gene_id and gi.na_feature_id = gf.na_feature_id and gf.source_id=? and gf.external_database_release_id=$entrezExtDbRlsId") or die DBI::errstr;
  }
  $entrezQuery->execute($entrezId) or die DBI::errstr;
  my ($geneId) = $entrezQuery->fetchrow_array();
  $entrezQuery->finish() or die DBI::errstr;
  unless($geneId) {
    $self->log("Skipping Gene ID \"$entrezId\" ... not in DB");
    return 0 ;
  }
  
  my $goAssoc = GUS::Model::DoTS::GOAssociation->new({'table_id'=> $tableId, 'row_id' => $geneId, 'go_term_id' => $goTermId, 'is_not' => 0, 'is_deprecated' => 0, 'defining' => 0});
  return ($goAssoc);
}

sub makeGoAssocInst{
  my ($self, $loeId, $assocExtDbRelId) = @_;

  my $goAssocInst = GUS::Model::DoTS::GOAssociationInstance->new({'go_assoc_inst_loe_id'=> $loeId, 'external_database_release_id' => $assocExtDbRelId, 'is_primary' => 0, 'is_deprecated' => 0});
  return ($goAssocInst);
}

sub getLoeId{
  my ($self) = @_;
  my $loe = GUS::Model::DoTS::GOAssociationInstanceLOE->new({'name' => 'Entrez GO Association'});
  unless($loe->retrieveFromDB()){
    $self->log("Entry for 'Entrez GO Association' automatically created in DoTS::GOAssociationInstanceLOE");
    $loe->submit();
  }
  my $loeId = $loe->getId();
  
  return $loeId;
}

sub getTableId{
    my ($self) = @_;

    my $table = GUS::Model::Core::TableInfo->new({'name'=> 'Gene'});
    $table->retrieveFromDB();
    my $tableId = $table->getId();

    return $tableId;
}

sub getEvidCodeId{
  my ($self, $evidence, $ecoExtDbRlsId) = @_;
  
  unless ($ecoQuery) {  
    $ecoQuery = $self->getQueryHandle()->prepare("select t.ontology_term_id from sres.ontologyterm t, sres.ontologysynonym s where s.ontology_synonym=? and s.ontology_term_id=t.ontology_term_id and t.external_database_release_id = $ecoExtDbRlsId") or die DBI::errstr;
  }
  $ecoQuery->execute($evidence) or die DBI::errstr;
  my ($evidCodeId) = $ecoQuery->fetchrow_array();
  $ecoQuery->finish() or die DBI::errstr;
  unless($evidCodeId) {
    $self->userError("Evidence code $evidence is not in the database for the specified ECO release");
  }
  return ($evidCodeId);
}

# --------------------------------------------------------------------
# undoTables
# return the list of tables to be used by the undo plugin
# for data deleting
# --------------------------------------------------------------------

sub undoTables {
    my ($self) = @_;

    return ('DoTS.GOAssocInstEvidCode', 'DoTS.GOAssociationInstanceLOE', 'DoTS.GOAssociationInstance', 'DoTS.GOAssociation');
}

1;
