package GUS::Common::Plugin::CalculateGeneFeatureSAGETagLinks;
@ISA = qw(GUS::PluginMgr::Plugin);

#
# This plugin, developed to link GeneFeatures and
# SageTagFeatures, has been replaced by LoadGenomicSageData.pm,
# which is in this same directory.  Go look at that one.
#

use strict;
use GUS::PluginMgr::Plugin;
use GUS::Model::DoTS::SAGETagFeature;
use GUS::Model::DoTS::GeneFeature;
use GUS::Model::DoTS::GeneFeatureSAGETagLink;
use GUS::Model::DoTS::NALocation;
use GUS::Model::DoTS::ExternalNASequence;
use GUS::Model::Core::DatabaseInfo;
use GUS::Model::Core::TableInfo;

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  my $purposeBrief = "Find SageTagFeatures corresponding to each GeneFeature.";

  my $purpose = <<PLUGIN_PURPOSE;
This plugin compares the GeneFeatures and SageTagFeatures of given
ExternalNaSequences to find links (i.e. the gene whose expression can be
inferred from the occurrence of particular tag in a SAGE experiment).  It is
based on the findLinks method.  This method, written by Jonathan Crabtree for
an earlier version of this plugin, links each SAGE tag to any genes found
within a given distance (by default, 1000 bp).
PLUGIN_PURPOSE

  my $tablesAffected =
    [ ['DoTS::GeneFeatureSAGETagLink',
       'Insert a record for each predicted link'],
    ];

  my $tablesDependedOn =
    [ ['DoTS::ProjectLink', 'Identify sequences to scan for tags'],
      ['DoTS::ExternalNASequence',
       'Get sequences to scan for SAGE tag features'],
      ['DoTS::SAGETagFeature', 'Get SAGE tag features to link'],
      ['DoTS::GeneFeature', 'Get gene features to link'],
      ['DoTS::NALocation',
       'Get locations within ExternalNaSequence of SAGE tags and genes'],
      ['Core::DatabaseInfo', 'Look up table IDs by database/table names'],
      ['Core::TableInfo', 'Look up table IDs by database/table names'],
    ];

  my $howToRestart = <<PLUGIN_RESTART;
This plugin has no restart facility.
PLUGIN_RESTART

  my $failureCases = <<PLUGIN_FAILURE_CASES;
PLUGIN_FAILURE_CASES

  my $notes = <<PLUGIN_NOTES;
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
     integerArg({name  => 'project_id',
		 descr => 'project_id',
		 reqd  => 1,
		 constraintFunc=> undef,
		 isList=> 0,
		}),
     integerArg({name  => 'taxon_id',
		 descr => 'taxon_id',
		 reqd  => 1,
		 constraintFunc=> undef,
		 isList=> 0,
		}),
     integerArg({name  => 'max_distance',
		 descr => 'max_distance',
		 reqd  => 0,
		 default  => 1000,
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

  $self->scanSequencesByProjectId($self->getArg('project_id'),
				  $self->getArg('taxon_id'));
}

# Given a projectId, use ProjectLink to find ExternalNaSequences
# to scan for SageTagFeatures and GeneFeatures, creating links
# where appropriate

sub scanSequencesByProjectId {
  my ($self, $project_id, $taxon_id) = @_;

  # outside loop, prepare query to run against every na_sequence_id
  my $queryHandle = $self->prepareQuery($self->getArg('max_distance'));

  my $table_id = getTableId('DoTS', 'ExternalNASequence');

  my $sql = <<SQL;
    select pl.id
    from DoTS.ProjectLink pl, DoTS.ExternalNaSequence ens
    where pl.project_id = $project_id
      and pl.table_id = $table_id
      and pl.id = ens.na_sequence_id
      and ens.taxon_id = $taxon_id
SQL

  my $dbh = $self->getQueryHandle();
  my $stmt = $dbh->prepareAndExecute($sql);

  my $linksFound = 0;
  while (my ($na_sequence_id) = $stmt->fetchrow_array()) {

    $self->logVerbose("processing NaSequenceId $na_sequence_id");
    $linksFound += $self->findLinks($na_sequence_id, $queryHandle);
    $self->undefPointerCache();
  }
}
# ----------------------------------------------------------------------
sub prepareQuery {
  my ($self, $maxDistance) = @_;

  # This join gets ids and locations for close pairs of features.
  # The ugly expression that gets selected as "same_strand" should be
  # 1 if both records have the same value in "is_reversed", 0 otherwise.

  my $sql = <<SQL;
        select tf.na_feature_id as tag_id,
               gf.na_feature_id as gene_id,
               tfl.start_min,
               tfl.end_max,
               tfl.is_reversed,
	       gfl.start_min,
               gfl.end_max,
               gfl.is_reversed,
               (nvl(tfl.is_reversed, 0) * nvl(gfl.is_reversed, 0)
                + (1 - nvl(tfl.is_reversed, 0) )
                   * (1 - nvl(gfl.is_reversed, 0)))
                 as same_strand
	from DoTS.SAGETagFeature tf,
             DoTS.NALocation tfl,
	     DoTS.GeneFeature gf,
             DoTS.NALocation gfl
	where gf.na_sequence_id = ?
	and tf.na_sequence_id = gf.na_sequence_id
	and tf.na_feature_id = tfl.na_feature_id
	and gf.na_feature_id = gfl.na_feature_id
	and (abs(gfl.end_min - tfl.start_max) <= $maxDistance
	     or abs(gfl.start_max - tfl.end_min) <= $maxDistance
	     or (gfl.start_max <= tfl.end_min and gfl.end_min >= tfl.start_max))
SQL

print STDERR "$sql\n";

  my $dbh = $self->getQueryHandle();
  my $stmt = $dbh->prepare($sql);

  return $stmt;
}

# ----------------------------------------------------------------------
# Given an na_sequence_id, use SQL to find linked gene/SAGE tag pairs.
# This is just a copy of the _storeLinks method from the old version
# of this plugin, modified to work with GUS v. 3 objects.

sub findLinks {
  my ($self, $na_sequence_id, $queryHandle) = @_;

  $queryHandle->execute($na_sequence_id);

  my $nLinks = 0;

  while (my($tagId,$geneId,$ts,$te,$trev,$gs,$ge,$grev,$ss)
	 = $queryHandle->fetchrow_array()) {
    my($tt5p, $tt3p);

    if (!$grev) {
      if (($ts <= $gs) && ($te >= $gs)) {
	$tt5p = 0;
      } else {
	$tt5p = ($te <= $gs) ? $gs - $te : $gs - $ts;
      }
      if (($ts <= $gs) && ($te >= $gs)) {
	$tt3p = 0;
      } else {
	$tt3p = ($ts >= $ge) ? $ts - $ge : $te - $ge;
      }
    } else {
      if (($ts <= $ge) && ($te >= $ge)) {
	$tt5p = 0;
      } else {
	$tt5p = ($ts >= $ge) ? $ts - $ge : $te - $ge;
      }
      if (($ts <= $ge) && ($te >= $ge)) {
	$tt3p = 0;
      } else {
	$tt3p = ($te <= $gs) ? $gs - $te : $gs - $ts;
      }
    }

    my $geneFeatureSageTagLink =
      GUS::Model::DoTS::GeneFeatureSAGETagLink->new
	  ( {
	     genomic_na_sequence_id => $na_sequence_id,
	     gene_na_feature_id => $geneId,
	     tag_na_feature_id => $tagId,
	     five_prime_tag_offset => $tt5p,
	     three_prime_tag_offset => $tt3p,
	     same_strand => $ss,
	     experimentally_verified => 0
	    } );

    if ($geneFeatureSageTagLink->retrieveFromDB()) {
      die("SageTagLink already exists between geneFeature " . $geneId .
	  " and sageTagFeature " . $tagId);
    }
    $geneFeatureSageTagLink->submit();
    $self->undefPointerCache();

    ++$nLinks;
  }
  $queryHandle->finish();
  return $nLinks;
}

# ======================================================================
# ----------------------------------------------------------------------
# ======================================================================

# look up tableId by database/table name
sub getTableId {
  my ($dbName, $tableName) = @_;

  my $db =
    GUS::Model::Core::DatabaseInfo->new( { name => $dbName } );
  $db->retrieveFromDB();

  my $table =
    GUS::Model::Core::TableInfo->new
	( {
	   name => $tableName,
	   database_id => $db->getDatabaseId()
	  } );

  $table->retrieveFromDB();

  my $id = $table->getTableId();

  if (! $id ) {
    die("can't get tableId for '$dbName\.$tableName'");
  }

  return $id;

}

1;
