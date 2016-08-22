#############################################################################
##                    InsertGene2Accession.pm
##
## Plug_in to load the gene2accession file from Entrez Gene into
## SRes.DbRef, DoTS.ExternalNASequence, and DoTS.DbRefNASequence tables
## $Id$
##
## created August 1, 2005  by Jennifer Dommer
#############################################################################

package GUS::Supported::Plugin::InsertGene2Accession;
@ISA = qw(GUS::PluginMgr::Plugin);


use strict;

use GUS::PluginMgr::Plugin;
use GUS::Model::SRes::Taxon;
use GUS::Model::DoTS::SequenceType;
use GUS::Model::SRes::DbRef;
use GUS::Model::DoTS::ExternalNASequence;
use GUS::Model::DoTS::DbRefNASequence;


my $purposeBrief = <<PURPOSEBRIEF;
Plug_in to load the gene2accession file from ncbi.
PURPOSEBRIEF

my $purpose = <<PLUGIN_PURPOSE;
plug_in to load the data from the gene2accession file downloaded from Entrez Gene into the SRes.DbRef, DoTS.ExternalNASequence, and DoTS.DbRefNASequence tables.
PLUGIN_PURPOSE

my $tablesAffected = [['GUS::Model::DoTS::ExternalNASequence', 'New RefSeqs are added to this table'],['GUS::Model::SRes::DbRef', 'New Entrez Genes from gene2accession are added to this table'],['GUS::Model::DoTS::DbRefNASequence', 'new mappings from DbRefs to the RefSeqs are loaded here, the parents of the entries are the new RefSeqs in DoTS::ExternalNASequences and the new Entrez Genes in SRes::DbRef']];

my $tablesDependedOn = [['GUS::Model::SRes::ExternalDatabaseRelease', 'The new database release for the current gene2accession file must have been loaded into SRes::ExternalDatabaseRelease prior to loading the file into the database.'],['DoTS::SequenceType','The sequence type id for RefSeqs will be pulled from this table'],['GUS::Model::SRes::Taxon','All taxa from gene2accession must exist in this table prior to loading the file']];

my $howToRestart = <<PLUGIN_RESTART;
Set the restart flag to 1.
PLUGIN_RESTART

my $failureCases = <<PLUGIN_FAILURE_CASES;
If there are taxa in the gene2accession file that are not in SRes.Taxon the plugin will fail and request that you load the taxa into SRes.Taxon.  This is a deliberate failure of the plugin and not bug.
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
If the fails and requests that you load the taxa into SRes.Taxon, LoadTaxon.pm is the recommended plugin to use for loading Taxon.  You will want to load the most recent taxonomy files from NCBI and then re-run the InsertGene2Accession plugin.  Note that if a RefSeq RNA nucleotide accession does not have a .version associated with it, the version will be set to 0 to indicate this lack.
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

 stringArg({name => 'entrezExternalDatabaseName',
            descr => 'sres.externaldatabase.name for gene2accession',
            constraintFunc => undef,
            reqd => 1,
            isList => 0
            }),

 stringArg({name => 'entrezExternalDatabaseVersion',
            descr => 'sres.externaldatabaserelease.version for this instance of
gene2accession',
            constraintFunc => undef,
            reqd => 1,
            isList => 0
            }),

 stringArg({name => 'refSeqExternalDatabaseName',
            descr => 'sres.externaldatabase.name for gene2accession',
            constraintFunc => undef,
            reqd => 1,
            isList => 0
            }),

 stringArg({name => 'refSeqExternalDatabaseVersion',
            descr => 'sres.externaldatabaserelease.version for this instance of
gene2accession',
            constraintFunc => undef,
            reqd => 1,
            isList => 0
            }),

 fileArg({name => 'gene2accession',
	  descr => 'pathname for the gene2accession file',
	  constraintFunc => undef,
	  reqd => 1,
	  isList => 0,
	  mustExist => 1,
	  format => 'Tab delimited file of the form tax_id, GeneID, status, RNA nucleotide accession.version, RNA nucleotide gi, protein accession.version, protein gi, genomic nucleotide accession.version, genomic nucleotide gi, start posistion on the genomic accession, end position on the genomic accession, orientation'
        }),

 fileArg({name => 'mergedTaxa',
	  descr => 'pathname for the merged.dmp file',
	  constraintFunc => undef,
	  reqd => 1,
	  isList => 0,
	  mustExist => 1,
	  format => 'Tab delimited file of the form old_tax_id | new_tax_id | from ncbi taxonomy.  This will allow mapping of old tax ids to new tax ids if the taxonomy files are not in sync with the gene2accession files.'
        }),

 booleanArg({name => 'restart',
             descr => 'set this flag to 1 if you want to Restart the plugin; set the externalDatabaseReleaseIDs to be the same as the one for the run that failed',
             reqd => 0,
             default => 0
            })
 ];


sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  $self->initialize({requiredDbVersion => 4.0,
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

sub run {
    my ($self) = @_;
    my $msg;

    my $genesHash = $self->makeGenesHash();
    
    if($self->checkTaxaExist($genesHash)){
	$msg = $self->loadData($genesHash);
    }
    return $msg;
}

# --------------------------------------------------------------------
# Subroutines:
#
# makeGenesHash
# puts the contents of the gene2accession file into a
# hash of the form {tax_id}->{gene_id}=[accession number, version]
# to allow for multiple arrays of [accession, version] per gene_id
# it is necessary to add each array to the array pointed to by the
# gene_id key
# by pushing the array, we end up with an array of arrays in our hash
# --------------------------------------------------------------------

sub makeGenesHash{
    my ($self) = @_;
    my %genesHash;
    my $file = $self->getArg('gene2accession');
    my %restartHash;

    if($self->getArg('restart')){
	print "restarting...\n";
	$self->makeRestartHash(\%restartHash);
    }

    open (GENES, $file) || die "Can't open $file.  Reason: $!\n";

    while(<GENES>){
	chomp;
	my @geneArray = split(/\t/, $_);
	my $tax_id = $geneArray[0];
	my $gene_id = $geneArray[1];
	my $accession = "";
	my $version = "";
	unless($geneArray[3] eq "-"){
	    my @RNA_accessVer = split(/\./, $geneArray[3]);
	    $accession = $RNA_accessVer[0];
	    $version = $RNA_accessVer[1];
	}

	unless ($restartHash{$tax_id}->{$gene_id} == 1){
	    push(@{$genesHash{$tax_id}->{$gene_id}}, [$accession, $version]);
	}
    }
    close(GENES);

    return (\%genesHash);
}

# --------------------------------------------------------------------
# makeMergedHash
# takes the contents of the merged.dmp file and places them into a
# hash of the form %mergedHash{$old_tax_id} = $new_tax_id
# --------------------------------------------------------------------

sub makeMergedHash{
    my ($self) = @_;
    my %mergedHash;
    my $file = $self->getArg('mergedTaxa');
   
    open (MERGED, $file) || die "Can't open $file.  Reason: $!\n";

    while(<MERGED>){
	chomp;
	my @mergedArray = split(/\t/, $_);
	my $old_tax_id = $mergedArray[0];
	my $new_tax_id = $mergedArray[2];

	$mergedHash{$old_tax_id} = $new_tax_id; 
    }

    close(MERGED);

    return (\%mergedHash);
}

# --------------------------------------------------------------------
# makeRestartHash
# creates a hash of entries already in the database for this
# entrez external database release ID
# returns the hash
# --------------------------------------------------------------------

sub makeRestartHash{
    my ($self, $restartHash) = @_;
    my $extDbRlsId = $self->getExtDbRlsId($self->getArg('entrezExternalDatabaseName'), $self->getArg('entrezExternalDatabaseVersion'));

    my $sql = "select t.ncbi_tax_id, r.primary_identifier from SRes.DbRef r, SRes.Taxon t where r.external_database_release_id = $extDbRlsId and r.taxon_id = t.taxon_id";

    my $queryHandle = $self->getQueryHandle();
    my $sth = $queryHandle->prepareAndExecute($sql);

    while(my ($taxon_id, $gene_id) = $sth ->fetchrow_array()){
	$restartHash->{$taxon_id}->{$gene_id}=1;
    }

    return $self;
}

# --------------------------------------------------------------------
# checkTaxaExist
# checks to see if all of the taxa in the gene2accession file are in
# SRes.Taxon.
# --------------------------------------------------------------------

sub checkTaxaExist{
    my ($self, $genesHash) = @_;
    my @keys = keys %$genesHash;
    my $mergedHash;

    foreach my $tax_id (@keys){
	my $taxon = GUS::Model::SRes::Taxon->new({'ncbi_tax_id'=> $tax_id});
	$taxon->retrieveFromDB();
	my $taxon_id = $taxon->getId();

	if(!$taxon_id){
	    if(!$mergedHash){
		$mergedHash = $self->makeMergedHash();
	    }
	    $self->checkMergedTaxon($tax_id, $genesHash, $mergedHash);
	}
    }

    return 1;
}

# --------------------------------------------------------------------
# loadData
# --------------------------------------------------------------------

sub loadData{
    my ($self, $genesHash) = @_;
    my $sequenceTypeId = getSequenceTypeID();
    my $EntrezGeneCount = 0;
    my $RefSeqCount = 0;

    foreach my $tax_id (keys %$genesHash){
	my $taxon = GUS::Model::SRes::Taxon->new({'ncbi_tax_id'=> $tax_id});
	$taxon->retrieveFromDB();
	my $taxon_id = $taxon->getId();
	print "Loading entries for taxon $tax_id into the database\n";

	foreach my $gene_id (keys %{$genesHash->{$tax_id}}){
	    my $newDbRef = $self->makeDbRefEntry($gene_id, $taxon_id);
	    if($$newDbRef->retrieveFromDB()){
		print "Gene $gene_id already in database for this release\n";
		next;
	    }

	    $EntrezGeneCount ++;
	    
	    my %seen = ();
	    foreach my $array (@{$genesHash->{$tax_id}->{$gene_id}}){
		if($$array[0] =~ /^NM\w/){
		    unless($seen{$$array[0].$$array[1]}){
			$seen{$$array[0].$$array[1]} = 1;
			
			my $newExtNASeq = $self->makeNewNASeq($$array[1], $sequenceTypeId, $taxon_id, $$array[0]);
			$RefSeqCount ++;

			my $newDbRefNASeq =  GUS::Model::DoTS::DbRefNASequence->new();
			$$newExtNASeq->addChild($newDbRefNASeq);
			$newDbRefNASeq->setParent($$newDbRef);
			$$newDbRef->addToSubmitList($$newExtNASeq);
		    }#eo unless
		}#eoif
	    }#array foreach

            $$newDbRef->submit();

	    $self->undefPointerCache();

	}#inner foreach
    }#outer foreach

    my $msg = "$EntrezGeneCount Entrez Genes and $RefSeqCount RefSeqs inserted into database";

    return $msg;
}

# --------------------------------------------------------------------
# makeDbRefEntry
# creates a new DbRef entry and submits it to the database
# returns the primary key
# --------------------------------------------------------------------

sub makeDbRefEntry{
    my ($self, $gene_id, $taxon_id) = @_;
    my $externalDatabaseRlsId = $self->getExtDbRlsId($self->getArg('entrezExternalDatabaseName'), $self->getArg('entrezExternalDatabaseVersion'));

    my $newDbRef = GUS::Model::SRes::DbRef->new({
		'external_database_release_id'=> $externalDatabaseRlsId,
		'primary_identifier' => $gene_id,
		'lowercase_primary_identifier' => $gene_id,
		'taxon_id' => $taxon_id
		});

    return (\$newDbRef);
}

# --------------------------------------------------------------------
# makeNewNASeq
# creates a new ExternalNASequence entry and submits it to the database
# returns the primary key
# NOTE: If there is no version for a give accession number (sourceId)
# the version will be set to 0 to indicate that it wasn't present.
# --------------------------------------------------------------------

sub makeNewNASeq{
    my ($self, $seqVer, $sequenceTypeId, $taxon_id, $sourceId) = @_;
    my $externalDatabaseRlsId = $self->getExtDbRlsId($self->getArg('refSeqExternalDatabaseName'), $self->getArg('refSeqExternalDatabaseVersion'));
    
    if(!$seqVer){
	$seqVer = 0;
    }

    my $newRefSeq = GUS::Model::DoTS::ExternalNASequence->new({
	'sequence_version' => $seqVer,
	'sequence_type_id' => $sequenceTypeId,
	'taxon_id' => $taxon_id,
	'external_database_release_id'=> $externalDatabaseRlsId,
	'source_id' => $sourceId
	});

    return (\$newRefSeq);

}

# --------------------------------------------------------------------
# getSequenceTypeID
# gets the sequence_type_id from DoTS::SequenceType corresponding to
# --------------------------------------------------------------------

sub getSequenceTypeID{
    my ($self) = @_;

    my $sequenceType = GUS::Model::DoTS::SequenceType->new({
	'name' => 'mRNA'
	});

    $sequenceType->retrieveFromDB();
    my $sequenceTypeId = $sequenceType->getId();

    return $sequenceTypeId;

}

# --------------------------------------------------------------------
# checkMergedTaxon
# checks the merged.dmp file to see if there is a new tax id for
# the tax id that we didn't find in the database
# if there is, the hash key in genesHash will be updated to the new
# tax id, if there isn't, the program will die with a message
# returns self
# --------------------------------------------------------------------

sub checkMergedTaxon{
    my ($self, $tax_id, $genesHash, $mergedHash) = @_;
    my $taxon_id = '';

    while(!$taxon_id){
	my $old_tax_id = $tax_id;
	$tax_id = $mergedHash->{$old_tax_id};
	die "Not all of the tax_ids are found in the database\n" unless ($tax_id);

	$genesHash->{$tax_id} = delete $genesHash->{$old_tax_id};

	my $taxon = GUS::Model::SRes::Taxon->new({'ncbi_tax_id'=> $tax_id});
	$taxon->retrieveFromDB();
	$taxon_id = $taxon->getId();

    }

    return $self;
}

1;
