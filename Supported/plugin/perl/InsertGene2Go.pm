#############################################################################
##                    InsertGene2Go.pm
##
## Plug_in to insert the gene2go file from Entrez Gene into
## DoTS.GOAssociation, DoTS.GOAssociationInstance, and
## DoTS.GOAssocInstEvidCode tables
## $Id$
##
## created August 10, 2005  by Jennifer Dommer
#############################################################################

package GUS::Supported::Plugin::InsertGene2Go;
@ISA = qw(GUS::PluginMgr::Plugin);


use strict;

use GUS::PluginMgr::Plugin;
use GUS::Model::SRes::GOTerm;
use GUS::Model::SRes::DbRef;
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

my $tablesAffected = [['GUS::Model::DoTS::GOAssociation', 'This will be used to map entries in SRes::DbRef to GO Terms in SRes::GOTerm'],['GUS::Model::DoTS::GOAssociationInstance', 'The new GOAssociation entries will be mapped to an loe and the current external database release ID'],['GUS::Model::DoTS::GOAssocInstEvidCode', 'Mappings from the SRes::GOEvidenceCode table to the new entries in the DoTS::GOAssociationInstance table will be done here'],['GUS::Model::SRes::GOEvidenceCode','if any of the evidence codes in gene2go are not in this table, they will be inserted']];

my $tablesDependedOn = [['GUS::Model::SRes::DbRef','we will link all entries for a given external database release id in DbRef to a GO term using DoTS::GOAssociation'],['GUS::Model::SRes::ExternalDatabaseRelease', 'The new database release for the current gene2go file must have been loaded into SRes::ExternalDatabaseRelease prior to loading the file into the database.'],['GUS::Model::SRes::GOTerm','All of the GO terms in the gene2go file must exist in this table prior to inserting the file'],['GUS::Model::SRes::GOEvidenceCode','All evidence codes in gene2go must exist in this table or they will be inserted']];

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

 stringArg({name => 'goAssociationExternalDatabaseName',
            descr => 'sres.externaldatabase.name for gene2go',
            constraintFunc => undef,
            reqd => 1,
            isList => 0
            }),

 stringArg({name => 'goAssociationExternalDatabaseVersion',
            descr => 'sres.externaldatabaserelease.version for this instance of
gene2go',
            constraintFunc => undef,
            reqd => 1,
            isList => 0
            }),

 stringArg({name => 'entrezGeneExternalDatabaseName',
            descr => 'sres.externaldatabase.name for Entrez Gene entries for gene2accession',
            constraintFunc => undef,
            reqd => 1,
            isList => 0
            }),

 stringArg({name => 'entrezGeneExternalDatabaseVersion',
            descr => 'sres.externaldatabaserelease.version for the most recent instance of gene2accession',
            constraintFunc => undef,
            reqd => 1,
            isList => 0
            }),

 integerArg({name => 'taxId',
            descr => 'ncbi tax id, used if mapping is restricted to a single taxon',
            constraintFunc => undef,
            reqd => 0,
            isList => 0
            }),

 fileArg({name => 'gene2go',
	  descr => 'pathname for the gene2accession file',
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

  $self->initialize({requiredDbVersion => 3.5,
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

    if($self->checkExistGOTerms($goHash)){
	$msg = $self->loadData($goHash);
    }

    return $msg;
}

# --------------------------------------------------------------------
# Subroutines:
#
# makeGoHash
# puts the needed contents of the gene2go file into a hash of the form
# goHash{go_term}=[gene_ids], skipping the first (commented) line
# returns a reference to the hash
# --------------------------------------------------------------------

sub makeGoHash{
    my ($self) = @_;
    my %goHash;
    my %evidHash;
    my $file = $self->getArg('gene2go');
    my $taxId = $self->getArg('taxId') if  $self->getArg('taxId');

    open (GO, $file) || die "Can't open $file.  Reason: $!\n";

    while(<GO>){
	chomp;
	if($_ =~ /^#\w/){
	   next;
        }
	my @goArray = split(/\t/, $_);

	next() if ($taxId && $goArray[0] != $taxId);
	my $gene_id = $goArray[1];
	my $go_id = $goArray[2];
	my $evidence = $goArray[3];

	push(@{$goHash{$go_id}->{$gene_id}}, $evidence);
	$evidHash{$evidence};
    }
    close(GO);

    $self->checkExistEvidCodes(\%evidHash);

    return (\%goHash);

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

	die "Not all of the GO Terms are in the database.  Please load GO Terms and then rerun this plugin.\n" unless ($count > 0);
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

    my $entrezGene = $self->getArg('entrezGeneExternalDatabaseName') . '|' . $self->getArg('entrezGeneExternalDatabaseVersion');

    my $entrezExtDbRelId = $self->getExtDbRlsId($entrezGene);

    my $g2g = $self->getArg('goAssociationExternalDatabaseName') . '|' . $self->getArg('goAssociationExternalDatabaseVersion');

    my $goExtDbRelId = $self->getExtDbRlsId($g2g);
    
    foreach my $go_id (keys %$goHash){
	$self->log("Loading entries for GO ID $go_id into the database.");
	foreach my $gene_id (keys %{$goHash->{$go_id}}){
	
	    my $newGOAssoc = $self->makeGOAssocEntry($go_id, $gene_id, $entrezExtDbRelId, $tableId);
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
	    foreach my $evidCode (@{$goHash->{$go_id}->{$gene_id}}){
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
	}#eo inner foreach
	   
    }#eo outer foreach

    my $msg = "$entriesCount entries added to the database, $skippedCount skipped because they were not in DbRef, $presentCount skipped because they were already in the database for this release.\n";

    return $msg;
}

# --------------------------------------------------------------------
# makeGOAssocEntry
# fetches the primary key of the row in DbRef housing
# the given gene for the specified database release of
# InsertGene2Accession, and the GOTerm ID from SRes.GOTerm of the
# term associated with the gene id in the gene2go file.
# It then creates a new GOAssociation entry and returns it.
# It will return a 0 if an entry for the gene does not already exist in
# SRes.DbRef.
# --------------------------------------------------------------------

sub makeGOAssocEntry{
    my ($self, $go_id, $gene_id, $entrezExtDbRelId, $table_id) = @_;

    my $sql = "select max(go_term_id) from SRes.GOTerm where go_id = '$go_id'";
    my $dbh = $self->getDb()->getDbHandle();
    my $st = $dbh->prepareAndExecute($sql);
    my $go_term_id = $st->fetchrow_array();

    my $DbRef = GUS::Model::SRes::DbRef->new({
	'primary_identifier' => $gene_id,
	'external_database_release_id' => $entrezExtDbRelId
	});
    $DbRef->retrieveFromDB();
    my $DbRef_id;
    unless($DbRef_id = $DbRef->getId()){
	return 0;
    }

    my $newGOAssoc = GUS::Model::DoTS::GOAssociation->new({
		'table_id'=> $table_id,
		'row_id' => $DbRef_id,
		'go_term_id' => $go_term_id,
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
    my ($self, $loe_id, $goExtDbRelId) = @_;

    my $newGOAssocInst = GUS::Model::DoTS::GOAssociationInstance->new({
		'go_assoc_inst_loe_id'=> $loe_id,
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
# gets the table id for DbRef from Core.TableInfo and returns it
# --------------------------------------------------------------------

sub getTableId{
    my ($self) = @_;

    my $table = GUS::Model::Core::TableInfo->new({'name'=> 'DbRef'});
    $table->retrieveFromDB();
    my $table_id = $table->getId();

    return $table_id;
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

    my $newAssocEvidCode = GUS::Model::DoTS::GOAssocInstEvidCode->new({
	'go_evidence_code_id'=> $evidCodeId,
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
