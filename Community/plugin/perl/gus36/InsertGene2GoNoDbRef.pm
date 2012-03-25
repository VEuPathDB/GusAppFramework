#############################################################################
##                    InsertGene2GoNoDbRef.pm
##
## Plug_in to insert the gene2go file from Entrez Gene into
## DoTS.GOAssociation, DoTS.GOAssociationInstance, and
## DoTS.GOAssocInstEvidCode tables
## $Id: InsertGene2GoNoDbRef.pm  $
##
## created July 25, 2008  by Elisabetta Manduchi, modifying an older
## plugin by Jennifer Dommer
#############################################################################

package GUS::Community::Plugin::InsertGene2GoNoDbRef;
@ISA = qw(GUS::PluginMgr::Plugin);


use strict;

use GUS::PluginMgr::Plugin;
use GUS::Model::SRes::GOTerm;
use GUS::Model::DoTS::Gene;
use GUS::Model::DoTS::GOAssociation;
use GUS::Model::DoTS::GOAssociationInstance;
use GUS::Model::DoTS::GOAssociationInstanceLOE;
use GUS::Model::DoTS::GOAssocInstEvidCode;
use GUS::Model::SRes::GOEvidenceCode;


my $purposeBrief = <<PURPOSEBRIEF;
Plug_in to insert the gene2go file from ncbi.
PURPOSEBRIEF

my $purpose = <<PLUGIN_PURPOSE;
plug_in to load the data from the gene2go file downloaded from Entrez Gene into the DoTS.GOAssociation, DoTS.GOAssociationInstance, and DoTS.GOAssocInstEvidCode tables.
PLUGIN_PURPOSE

my $tablesAffected = [['GUS::Model::DoTS::GOAssociation', 'This will be used to map entries in DoTS::Gene to GO Terms in SRes::GOTerm'],['GUS::Model::DoTS::GOAssociationInstance', 'The new GOAssociation entries will be mapped to an loe and the current external database release ID'],['GUS::Model::DoTS::GOAssocInstEvidCode', 'Mappings from the SRes::GOEvidenceCode table to the new entries in the DoTS::GOAssociationInstance table will be done here'],['GUS::Model::SRes::GOEvidenceCode','if any of the evidence codes in gene2go are not in this table, they will be inserted']];

my $tablesDependedOn = [['GUS::Model::DoTS::Gene','We will link all entries for a given external database release id in Gene to a GO term using DoTS::GOAssociation'],['GUS::Model::SRes::ExternalDatabaseRelease', 'The new database release for the current gene2go file must have been loaded into SRes::ExternalDatabaseRelease prior to loading the file into the database.'],['GUS::Model::SRes::GOTerm','All of the GO terms in the gene2go file must exist in this table prior to inserting the file'],['GUS::Model::SRes::GOEvidenceCode','All evidence codes in gene2go must exist in this table or they will be inserted']];

my $howToRestart = <<PLUGIN_RESTART;
There is no restart method for this plugin.  All entries are checked before they are loaded into the database to prevent duplicate entries.
PLUGIN_RESTART

my $failureCases = <<PLUGIN_FAILURE_CASES;
If there are GO terms in the gene2go file that are not in SRes.GOTerm the plugin will fail and request that you load the GO terms into SRes.GOTerm.  This is a deliberate failure of the plugin and not bug.
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
 stringArg({name => 'goAssociationExtDbRlsSpec',
            descr => "The ExternalDBRelease specifier for the gene2go file. Must be in the format 'name|version', where the name must match a name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
            constraintFunc => undef,
            reqd => 1,
            isList => 0
            }),
 stringArg({name => 'entrezGeneExtDbRlsSpec',
            descr => "The ExternalDBRelease specifier for the Taxon.gene_info file to which GO mapping should be linkd. Must be in the format 'name|version', where the name must match a name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.res.externaldatabase.",
            constraintFunc => undef,
            reqd => 1,
            isList => 0
            }),
 integerArg({name => 'taxId',
	     descr => 'NCBI tax id, used if mapping is restricted to a single taxon',
	     constraintFunc => undef,
	     reqd => 0,
	     isList => 0
            }),
 stringArg({name => 'taxonName',
            descr => "SRes.TaxonName.name",
            constraintFunc => undef,
            reqd => 0,
            isList => 0
            }),
 fileArg({name => 'gene2go',
	  descr => 'pathname for the gene2go file',
	  constraintFunc => undef,
	  reqd => 1,
	  isList => 0,
	  mustExist => 1,
	  format => 'Tab delimited file of the form tax_id, GeneID, GO ID, evidence, Qualifier, GO term, PubMed - available from the ncbi gene ftp site.'
        })
 ];


sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  $self->initialize({requiredDbVersion => 3.6,
		     cvsRevision => '$Revision$',
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

#    if($self->checkExistGOTerms($goHash)){
	$msg = $self->loadData($goHash);
#    }

    return $msg;
}

# --------------------------------------------------------------------
# Subroutines:
#
# makeGoHash
# puts the needed contents of the gene2go file into a hash of the form
# goHash{goTerm}=[entrezGeneIds], skipping the first (commented) line
# returns a reference to the hash
# --------------------------------------------------------------------

sub makeGoHash{
    my ($self) = @_;
    my %goHash;
#    my %evidHash;
    my $file = $self->getArg('gene2go');
    my $taxId = $self->getTaxonId();

    open (GO, $file) || die "Can't open $file.  Reason: $!\n";

    while(<GO>){
	chomp;
	if($_ =~ /^#\w/){
	   next;
        }
	my @goArray = split(/\t/, $_);

	next() if ($taxId && $goArray[0] != $taxId);
	my $entrezGeneId = $goArray[1];
	my $goId = $goArray[2];
	my $evidence = $goArray[3];

	push(@{$goHash{$goId}->{$entrezGeneId}}, $evidence);
#	$evidHash{$evidence};
    }
    close(GO);

#    $self->checkExistEvidCodes(\%evidHash);

    return (\%goHash);

}

sub getTaxonId {
  my ($self) = @_;

  if(my $taxId = $self->getArg('taxId')) {
    return $taxId;
  }

  if(my $taxonName = $self->getArg('taxonName')) {
    my $sql = "select distinct taxon_id from sres.taxonname where name = ?";

    my $dbh = $self->getQueryHandle();
    my $sh = $dbh->prepare($sql);
    $sh->execute($taxonName);

    my ($taxId, $count);
    while(($taxId) = $sh->fetchrow_array()) {
      $count++;
    }
    $sh->finish();

    if($count != 1) {
      $self->userError("Could not find a distinct taxon_id for taxon name $taxonName");
    }

    return $taxId;
  }

  $self->userError("Either taxId OR taxonName must be specified");
}


# --------------------------------------------------------------------
# checkExistEvidCodes
# checks to see if all evidence codes in gene2go are in the table
# SRes.GOEvidenceCode
# returns true if they are or dies with an error message if they aren't
# --------------------------------------------------------------------

sub checkExistEvidCodes{
    my ($self, $evidHash) = @_;

    foreach my $evidCode (keys %$evidHash){

	my $sql = "select count(*) from SRes.GOEvidenceCode where name = '$evidCode'";
	my $dbh = $self->getDb()->getDbHandle();
	my $st = $dbh->prepareAndExecute($sql);
	my $count = $st->fetchrow_array();

	die "The evidence code $evidCode is not in the database.  Please load it and then rerun this plugin.\n" unless ($count > 0);
    }

    return 1;
}

# --------------------------------------------------------------------
# checkExistGOTerms
# checks to see if all GO IDs in gene2go are in the table
# SRes.GOTerm
# returns true if they are or dies with an error message if they aren't
# --------------------------------------------------------------------

sub checkExistGOTerms{
    my ($self, $goHash) = @_;

    foreach my $go_id (keys %$goHash){

	my $sql = "select count(*) from SRes.GOTerm where go_id = '$go_id'";
	my $dbh = $self->getDb()->getDbHandle();
	my $st = $dbh->prepareAndExecute($sql);
	my $count = $st->fetchrow_array();

	$self->log("Skipping GO ID $go_id ... not in DB") unless ($count > 0);
    }

    return 1;
}

# --------------------------------------------------------------------
# loadData
# loads the data from the gene2go file into the appropriate tables in
# the database
# --------------------------------------------------------------------

sub loadData{
    my ($self, $goHash) = @_;
    my $loeId = $self->getLOEid();
    my $tableId = $self->getTableId();
    my $entriesCount = 0;
    my $skippedCount = 0;
    my $presentCount = 0;

    my $entrezExtDbRelId = $self->getExtDbRlsId($self->getArg('entrezGeneExtDbRlsSpec'));
    my $goExtDbRelId = $self->getExtDbRlsId($self->getArg('goAssociationExtDbRlsSpec'));
    
    foreach my $goId (keys %$goHash){
	$self->log("Loading entries for GO ID $goId into the database.");
	foreach my $entrezGeneId (keys %{$goHash->{$goId}}){
	
	    my $newGOAssoc = $self->makeGOAssocEntry($goId, $entrezGeneId, $entrezExtDbRelId, $tableId);
	    unless($newGOAssoc){
		$skippedCount ++;
		$self->undefPointerCache();
		next;
	    }#eo unless

	    if($$newGOAssoc->retrieveFromDB()){
#		$self->log("Gene $gene_id GO term $go_id pair already in database for this release");
	#	$presentCount ++;
		#$self->undefPointerCache();
		#next;
	    }

	    my $newGOAssocInst = $self->makeGOAssocInstEntry($loeId, $goExtDbRelId);
	    my %seen = ();
	    foreach my $evidCode (@{$goHash->{$goId}->{$entrezGeneId}}){
		if($evidCode) {
		    unless($seen{$evidCode}){
			$seen{$evidCode} = 1;
						
			my $newAssocEvidCode = $self->makeAssocInstEvidCode($evidCode);
			$$newGOAssocInst->addChild($$newAssocEvidCode);
			
#			$self->undefPointerCache();
		    }
		}
	    }
	    
	    $$newGOAssoc->addChild($$newGOAssocInst);
	    $$newGOAssoc->submit();
	    $self->undefPointerCache();
	    $entriesCount ++;

            if($entriesCount % 1000 == 0) {
              $self->log("Processed $entriesCount entries.  Skipped $skippedCount");
            }
	}#eo inner foreach
	   
    }#eo outer foreach

    my $msg = "$entriesCount entries added to the database, $skippedCount skipped because they were not in DoTS.Gene, $presentCount skipped because they were already in the database for this release.\n";

    return $msg;
}

# --------------------------------------------------------------------
# makeGOAssocEntry
# fetches the primary key of the row in DoTS.Gene housing
# the given gene for the specified database release of
# Taxon.gene_info, and the GOTerm ID from SRes.GOTerm of the
# term associated with the gene id in the gene2go file.
# It then creates a new GOAssociation entry and returns it.
# It will return a 0 if an entry for the gene does not already exist in
# DoTS.Gene.
# --------------------------------------------------------------------

sub makeGOAssocEntry{
    my ($self, $goId, $entrezGeneId, $entrezExtDbRelId, $tableId) = @_;

    my $sql = "select max(go_term_id) from SRes.GOTerm where go_id = '$goId'";
    my $dbh = $self->getDb()->getDbHandle();
    my $st = $dbh->prepareAndExecute($sql);
    my $goTermId = $st->fetchrow_array();

    unless($goTermId) {
      $self->log("Skipping GO ID $goId ... not in DB");
      return 0 ;
    }

    my $gene = GUS::Model::DoTS::Gene->new({
	'source_id' => $entrezGeneId,
	'external_database_release_id' => $entrezExtDbRelId
	});
    $gene->retrieveFromDB();
    my $geneId;
    unless($geneId = $gene->getId()){
	return 0;
    }

    my $newGOAssoc = GUS::Model::DoTS::GOAssociation->new({
		'table_id'=> $tableId,
		'row_id' => $geneId,
		'go_term_id' => $goTermId,
		'is_not' => 0,
		'is_deprecated' => 0,
		'defining' => 0,
		'review_status_id' => 0
		});

    return (\$newGOAssoc);

}

# --------------------------------------------------------------------
# makeGOAssocInstEntry
# creates a new GOAssociationInstance entry and returns it.
# --------------------------------------------------------------------

sub makeGOAssocInstEntry{
    my ($self, $loeId, $goExtDbRelId) = @_;

    my $newGOAssocInst = GUS::Model::DoTS::GOAssociationInstance->new({
		'go_assoc_inst_loe_id'=> $loeId,
		'external_database_release_id' => $goExtDbRelId,
		'is_primary' => 0,
		'is_deprecated' => 0,
		'review_status_id' => 0
		});

    return (\$newGOAssocInst);
}

# --------------------------------------------------------------------
# getLOEid
# retrieves the LOE ID corresponding to 'mRNA' from
# DoTS.GOAssociationInstanceLOE and returns it
# the LOE entry will be created if it doesn't exist
# --------------------------------------------------------------------

sub getLOEid{
    my ($self) = @_;
    my $loe = GUS::Model::DoTS::GOAssociationInstanceLOE->new({
	             'name' => 'GOAssociation'
		     });

    unless($loe->retrieveFromDB()){
	$self->log("Entry for GOAssociation automatically created in DoTS::GOAssociationInstanceLOE");
	$loe->submit();
    }
    my $loeId = $loe->getId();

    return $loeId;
}

# --------------------------------------------------------------------
# getTableId
# gets the table id for Gene from Core.TableInfo and returns it
# --------------------------------------------------------------------

sub getTableId{
    my ($self) = @_;

    my $table = GUS::Model::Core::TableInfo->new({'name'=> 'Gene'});
    $table->retrieveFromDB();
    my $tableId = $table->getId();

    return $tableId;
}

# --------------------------------------------------------------------
# makeAssocInstEvidCode
# gets the go_evidence_code_id from SRes.GOEvidenceCode and creates
# and returns a new DoTS.GOAssocInstEvidCode object
# --------------------------------------------------------------------

sub makeAssocInstEvidCode{
    my ($self, $evidence) = @_;

    my $evidCode = GUS::Model::SRes::GOEvidenceCode->new({'name'=> $evidence});
    $evidCode->retrieveFromDB();
    my $evidCodeId = $evidCode->getId();

    unless($evidCodeId) {
      $evidCode->submit();
    }

    my $newAssocEvidCode = GUS::Model::DoTS::GOAssocInstEvidCode->new({
	'go_evidence_code_id'=> $evidCode->getId(),
	'review_status_id' => 0
	});

    return (\$newAssocEvidCode);
}



# --------------------------------------------------------------------
# undoTables
# return the list of tables to be used by the undo plugin
# for data deleting
# --------------------------------------------------------------------

sub undoTables {
    my ($self) = @_;
    
    return ('SRes.GOEvidenceCode', 'DoTS.GOAssocInstEvidCode', 'DoTS.GOAssociationInstanceLOE', 'DoTS.GOAssociationInstance', 'DoTS.GOAssociation');
}



1;
