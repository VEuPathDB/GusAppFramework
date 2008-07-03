#############################################################################
##                    InsertHomoloGeneDeprecated.pm
##
## Plug_in to insert the homologene file from HomoloGene into
## DoTS.OrthologExperiment, DoTS.OrthologGroup, DoTS.AASequenceDbRef, and
## DoTS.SequenceSequenceGroup tables
## $Id$
##
## created August 18, 2005  by Jennifer Dommer
#############################################################################

package GUS::Supported::Plugin::InsertHomoloGeneDeprecated;
@ISA = qw(GUS::PluginMgr::Plugin);


use strict;

use GUS::PluginMgr::Plugin;
use GUS::Model::SRes::DbRef;
use GUS::Model::DoTS::OrthologExperiment;
use GUS::Model::DoTS::OrthologGroup;
use GUS::Model::DoTS::AASequenceDbRef;
use GUS::Model::DoTS::AASequence;
use GUS::Model::DoTS::SequenceSequenceGroup;
use GUS::Model::DoTS::NRDBEntry;


my $purposeBrief = <<PURPOSEBRIEF;
Plug_in to insert the homologene file from ncbi.
PURPOSEBRIEF

my $purpose = <<PLUGIN_PURPOSE;
plug_in to load the data from the homologene file downloaded from HomoloGene into the DoTS.OrthologExperiment, DoTS.OrthologGroup, DoTS.AASequenceDbRef, and DoTS.SequenceSequenceGroup tables.
PLUGIN_PURPOSE

my $tablesAffected = [['GUS::Model::DoTS::OrthologExperiment', 'The descriptin attribute of this table will hold the homologene file release date which will be used to map the new homologene entries to the proper external database release ids for the gene2accession and gene2go files they are associated with'],['GUS::Model::DoTS::OrthologGroup', 'The new homologene group entries will be added here'],['GUS::Model::DoTS::AASequenceDbRef', 'Mappings from the gene IDs in the homologene file to the AA sequence corresponding to the protein accession will be done here'],['GUS::Model::DoTS::SequenceSequenceGroup','we will map the protein sequences to the homologene groups in this table']];

my $tablesDependedOn = [['GUS::Model::SRes::DbRef','we will link all entries for the genes in the homologene file that are found in DbRef to a AASequence using DoTS::AASequenceDbRef'],['GUS::Model::SRes::ExternalDatabaseRelease', 'The new database release for the latest gene2accession file must have been loaded into SRes::ExternalDatabaseRelease prior to loading the file into the database.']];

my $howToRestart = <<PLUGIN_RESTART;
set the restart flag to 1
PLUGIN_RESTART

my $failureCases = <<PLUGIN_FAILURE_CASES;
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

 stringArg({name => 'releaseDate',
            descr => 'release date on the homolgene file',
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

 stringArg({name => 'nrdbExternalDatabaseName',
            descr => 'sres.externaldatabase.name for NRDB entries for the HomoloGene load',
            constraintFunc => undef,
            reqd => 1,
            isList => 0
            }),

 stringArg({name => 'nrdbExternalDatabaseVersion',
            descr => 'sres.externaldatabaserelease.version for the most recent load of NRDB for HomoloGene',
            constraintFunc => undef,
            reqd => 1,
            isList => 0
            }),

 fileArg({name => 'homoloGene',
	  descr => 'pathname for the homologene file',
	  constraintFunc => undef,
	  reqd => 1,
	  isList => 0,
	  mustExist => 1,
	  format => 'Tab delimited file of the form HomoloGene Group ID, taxonomy ID, Gene ID, Gene Symbol, Protein gi, Protein Accession - available from the ncbi homoloGene ftp site.'
        }),

 booleanArg({name => 'restart',
             descr => 'set this flag to 1 if you want to Restart the plugin; set the entrez database name and version, and the release date to be the same as the ones for the run that failed',
             reqd => 0,
             default => 0
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

    my $orthologExp = $self->makeOrthologExperiment();

    my $homoloHash = $self->makeHomoloHash($orthologExp);

    $msg = $self->loadData($orthologExp, $homoloHash);

    return $msg;
}

# --------------------------------------------------------------------
# Subroutines:
#
# makeHomoloHash
# takes the data from the homologene file and makes a hash of the form
# homoloHash{HID}->{tax_id}->{gene_id} = [proteins]
# returns the hash
# --------------------------------------------------------------------

sub makeHomoloHash{
    my ($self, $orthologExp) = @_;
    my %homoloHash;
    my $file = $self->getArg('homoloGene');
    my %restartHash;

    if($self->getArg('restart')){
	print "restarting...\n";
	$self->makeRestartHash(\%restartHash, $orthologExp);
    }

    open (HOMOLO, $file) || die "Can't open $file.  Reason: $!\n";

    while(<HOMOLO>){
	chomp;

	my @homoloArray = split(/\t/, $_);
	my $hid = $homoloArray[0];
	my $tax_id = $homoloArray[1];
	my $gene_id = $homoloArray[2];
	my $protein_accession = $homoloArray[5];
	unless ($restartHash{$hid} == 1){
	    push(@{$homoloHash{$hid}->{$tax_id}->{$gene_id}}, $protein_accession);
	}
    }
    close(HOMOLO);

    return (\%homoloHash);

}

# --------------------------------------------------------------------
# makeRestartHash
# retrieves OrthologGroups from that database that have the current
# OrthologExperiment id and makes a hash of the HIDs
# returns the hash
# --------------------------------------------------------------------

sub makeRestartHash{
    my ($self, $restartHash, $orthologExp) = @_;
    my $orthologExpId = $$orthologExp->getId();

    my $sql = "select name from DoTS.OrthologGroup where sequence_group_experiment_id = $orthologExpId";

 my $queryHandle = $self->getQueryHandle();
    my $sth = $queryHandle->prepareAndExecute($sql);

    while(my ($hid) = $sth ->fetchrow_array()){
	$restartHash->{$hid}=1;
    }
    $sth->finish();
    return $self;

}

# --------------------------------------------------------------------
# makeOrthologExperiment
# will load the release date provided into the description field of
# DoTS::OrthologExperiment
# --------------------------------------------------------------------

sub makeOrthologExperiment{
    my ($self) = @_;
    my $releaseDate = $self->getArg('releaseDate');
    my $restart = $self->getArg('restart');

    my $newExperiment = GUS::Model::DoTS::OrthologExperiment->new({
	'description' => $releaseDate
	});

    if ($restart){
	$newExperiment->retrieveFromDB();
    }
    else{
	$newExperiment->submit();
    }

    return (\$newExperiment);
}

# --------------------------------------------------------------------
# loadData
# takes in the parent for an ortholog group entry; will need to use
#  the $$ notation to dereference
# Creates an Ortholog group entry, 
# --------------------------------------------------------------------

sub loadData{
    my ($self, $orthologExp, $homoloHash) = @_;
    my $sourceTableId = $self->getSourceTableId();
    my $AASequenceId;
    my $skippedCount = 0;
    my $enteredCount = 0;
    my $nrdbExtDbRlsId = $self->getExtDbRlsId($self->getArg('nrdbExternalDatabaseName'), $self->getArg('nrdbExternalDatabaseVersion'));

    my $sql = "select x.aa_sequence_id from DoTS.NRDBEntry n, DoTS.ExternalAASequence x where n.source_id = ? and n.aa_sequence_id = x.aa_sequence_id and x.external_database_release_id = $nrdbExtDbRlsId";

    my $queryHandle = $self->getQueryHandle();
    my $sth = $queryHandle->prepare($sql);

    foreach  my $hid (keys %$homoloHash){
	print "Making entries for Ortholog Group $hid\n";
	my $newOrthologGroup = $self->makeOrthologGroup($hid, $homoloHash);
	$$newOrthologGroup->setParent($$orthologExp);

	foreach my $tax_id (keys %{$homoloHash->{$hid}}){
	    foreach my $gene_id (keys %{$homoloHash->{$hid}->{$tax_id}}){
		foreach my $protein (@{$homoloHash->{$hid}->{$tax_id}->{$gene_id}}){

		    unless($AASequenceId = $self->getAASequenceId($protein, \$sth)){
			$skippedCount ++;
			next;
		    }

		    my $newSeqSeqEntry = $self->makeSequenceSequenceGroup($sourceTableId, $hid, $AASequenceId);

			$$newOrthologGroup->addChild($$newSeqSeqEntry);


		    my $newAASeqDbRef = $self->makeAASeqDbRef($AASequenceId, $gene_id);

		    if(defined $$newAASeqDbRef) {
			unless($$newAASeqDbRef->retrieveFromDB()){
			    $$newOrthologGroup->addToSubmitList($$newAASeqDbRef );
			}
		    }
		}
	    }
	}


	$$newOrthologGroup->submit();
	$enteredCount ++;

	$self->undefPointerCache();
    }

    my $msg = "Created $enteredCount new entries in the database.  Skipped $skippedCount proteins because they were not in the database.\n";

    return $msg;

}

# --------------------------------------------------------------------
# makeOrthologGroup
# make an entry for the ortholog group table
# counts how many genes are in the group
# returns a reference to the new entry
# --------------------------------------------------------------------

sub makeOrthologGroup{
    my ($self, $hid, $homoloHash) = @_;
    my $membersCount = 0;

    foreach my $tax_id (keys %{$homoloHash->{$hid}}){
	 $membersCount += scalar(keys %{$homoloHash->{$hid}->{$tax_id}});
    }

     my $newOrthologGroup = GUS::Model::DoTS::OrthologGroup->new({
		'name'=> $hid,
		'number_of_members' => $membersCount
		});

    return (\$newOrthologGroup);
}

# --------------------------------------------------------------------
# makeSequenceSequenceGroup
# takes in the source table ID, homologene ID, and aa sequence ID
# makes a new SequenceSequence entry
# returns a reference to the entry
# --------------------------------------------------------------------

sub makeSequenceSequenceGroup{
    my ($self, $sourceTableId, $hid, $AASequenceId) = @_;

      my $newSeqSeqEntry = GUS::Model::DoTS::SequenceSequenceGroup->new({
	'sequence_id' => $AASequenceId,
	'source_table_id' => $sourceTableId,
	'sequence_group_id' => $hid
	});

    return (\$newSeqSeqEntry);

}

# --------------------------------------------------------------------
# makeAASeqDbRef
# fetches the DbRefId corresponding to the gene_id and then
# makes a new linking entry in AASequenceDbRef to link the entries in
# DbRef for the version of Entrez provided to the entries in AASequence
# returns the new entry
# --------------------------------------------------------------------

sub makeAASeqDbRef{
    my ($self, $AASeqId, $gene_id) = @_;
    my $extDbRlsId = $self->getExtDbRlsId($self->getArg('entrezGeneExternalDatabaseName'), $self->getArg('entrezGeneExternalDatabaseVersion'));
    my $newAASeqDbRef;

    my $DbRef = GUS::Model::SRes::DbRef->new({
	'primary_identifier' => $gene_id,
	'external_database_release_id' => $extDbRlsId
	});

    $DbRef->retrieveFromDB();
    my $dbRefId = $DbRef->getId();

    my $AASequence = GUS::Model::DoTS::AASequence->new({
	'aa_sequence_id' => $AASeqId
	});

    $AASequence->retrieveFromDB();
    my $aaSeqId = $AASequence->getId();

    if ($dbRefId && $aaSeqId){
      $newAASeqDbRef = GUS::Model::DoTS::AASequenceDbRef->new({
				    'aa_sequence_id' => $aaSeqId,
				    'db_ref_id' => $dbRefId
				   });
    }
    else {
      $self->log("Missing either aa_sequence_id: $aaSeqId or db_ref_id: $dbRefId for gene ID $gene_id and sequence ID $AASeqId");
    }
    return (\$newAASeqDbRef);
    
}

# --------------------------------------------------------------------
# getSourceTableId
# gets the id for DoTS.OrthologGroup from Core.TableInfo
# returns the id
# --------------------------------------------------------------------

sub getSourceTableId{
    my ($self) = @_;

     my $sourceTable = GUS::Model::Core::TableInfo->new({
	'name' => 'OrthologGroup'
	});

    $sourceTable->retrieveFromDB();
    my $sourceTableId = $sourceTable->getId();

    return $sourceTableId;

}

# --------------------------------------------------------------------
# getAASequenceId
# get the id for the protein sequence of interest
# returns the id or 0 if the protein isn't in the database
# --------------------------------------------------------------------

sub getAASequenceId{
    my ($self, $protein, $sth) = @_;

    my @proteinAccessArray = split(/\./, $protein);
	   my $accession = $proteinAccessArray[0];
	   my $version = $proteinAccessArray[1];

    $$sth->execute($accession);

    my $AASequenceId = $$sth->fetchrow_array();
    $$sth->finish();

    return $AASequenceId;

}


1;
