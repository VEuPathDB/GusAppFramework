package GUS::Community::Plugin::LoadMutualInformationScores;
@ISA = qw(GUS::PluginMgr::Plugin);

#$Id$

use strict;
use GUS::PluginMgr::Plugin;
use GUS::Model::DoTS::PhylogeneticProfile;
use GUS::Model::DoTS::PhylogeneticProfileMember;
use GUS::Model::DoTS::MutualInformationScore;
use GUS::Model::Core::DatabaseInfo;
use GUS::Model::Core::TableInfo;
use FileHandle;
#use Dump::Dumper;

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  my $purposeBrief = "Load mutual information scores from a file.";

  my $purpose = <<PLUGIN_PURPOSE;
This plugin loads mutual information scores from a file.
PLUGIN_PURPOSE

  my $tablesAffected =
    [ ['DoTS::MutualInformationScore', 'Insert data'],
    ];

  my $tablesDependedOn =
    [
      ['phylo profile', 'Look up table IDs by database/table names'],
      ['Core::DatabaseInfo', 'Look up table IDs by database/table names'],
      ['Core::TableInfo', 'Look up table IDs by database/table names'],
    ];

  my $howToRestart = <<PLUGIN_RESTART;
This plugin has no restart facility.
PLUGIN_RESTART

  my $failureCases = <<PLUGIN_FAILURE_CASES;
PLUGIN_FAILURE_CASES

  my $notes = <<PLUGIN_NOTES;
fill in
PLUGIN_NOTES

  my $documentation = { purpose=>$purpose,
                        purposeBrief=>$purposeBrief,
                        tablesAffected=>$tablesAffected,
                        tablesDependedOn=>$tablesDependedOn,
                        howToRestart=>$howToRestart,
                        failureCases=>$failureCases,
                        notes=>$notes
                      };

  my $argsDeclaration =
    [
# should be SQL
     integerArg({name  => 'phylogenetic_profile_set_id',
		 descr => 'phylogenetic_profile_set_id',  # talk about what SQL does
		 reqd  => 1,
		 constraintFunc=> undef,
		 isList=> 0,
		}),
# should be fileArg -- use the "format" field to descript file format
     stringArg({name  => 'datafile',
		 descr => 'datafile',    # <- more descriptive
		 reqd  => 1,
		 constraintFunc=> undef,
		 isList=> 0,
		}),
    ];


  $self->initialize({requiredDbVersion => {},
                     cvsRevision => '$Revision$', # cvs fills this in!
                     cvsTag => '$Name$', # cvs fills this in!
                     name => ref($self),
                     revisionNotes => 'make consistent with GUS 3.0',
                     argsDeclaration => $argsDeclaration,
                     documentation => $documentation
                    });
  return $self;
}

sub run {
  my ($self) = @_;
  $self->logAlgInvocationId;
  $self->logCommit;

  $self->loadMutualInformationFile($self->getArg('datafile'),
				   $self->getArg('phylogenetic_profile_set_id'));

  $self->logVerbose("Finished LoadMutualInformationScores.");
}

# ----------------------------------------------------------------------
# Given the name of a data file, read and load mutual information score data

sub loadMutualInformationFile {
  my ($self, $datafile, $phylogeneticProfileSetId) = @_;

  my $fh = FileHandle->new('<'.$datafile);
  if (! $fh) {
    die ("Can't open datafile $datafile");
  }

  my %profileIdHash = $self->getProfileIdHash($phylogeneticProfileSetId);
  my $i;

# loop in run(); subroutine to make object
  while (<$fh>) {
    chomp;

    my ($primarySourceId, $secondarySourceId, $score) = (split(/\|/, $_));

    my $primaryProfileId = $profileIdHash{$primarySourceId};
    die("Can't find profile_id for source_id $primarySourceId")
      if (!$primaryProfileId);

    my $secondaryProfileId = $profileIdHash{$secondarySourceId};
    die("Can't find profile_id for source_id $secondarySourceId")
      if (!$secondaryProfileId);

    my $mi = GUS::Model::DoTS::MutualInformationScore->new
      ( {
	 primary_profile_id => $primaryProfileId,
	 secondary_profile_id => $secondaryProfileId,
	} );

#    $mi->retrieveFromDB();
    $mi->setMutualInformationScore($score * 10000);
    $mi->submit();

    if ($i++ % 1000 == 0) {
      $self->undefPointerCache();
    }
  }

  $fh->close();
}

sub getProfileIdHash {
  my ($self, $phylogeneticProfileSetId) = @_;

  my %profileIdHash;

  my $sql = <<SQL;
    SELECT phylogenetic_profile_id, source_id
    FROM plasmodb_42.plasmodb_genes gf, DoTS.PhylogeneticProfile pp
    WHERE gf.na_feature_id = pp.na_feature_id
      AND pp.phylogenetic_profile_set_id=$phylogeneticProfileSetId
SQL

  my $sth = $self->getQueryHandle()->prepareAndExecute($sql);

  while (my ($profileId, $sourceId) = $sth->fetchrow_array()) {
    $profileIdHash{$sourceId} = $profileId;
  }

  return %profileIdHash;
}
