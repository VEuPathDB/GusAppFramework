package GUS::Common::Plugin::LoadGenomicSageData;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
use GUS::PluginMgr::Plugin;
use GUS::Model::DoTS::SAGETagFeature;
use GUS::Model::DoTS::GeneFeature;
use GUS::Model::DoTS::GeneFeatureSAGETagLink;
use GUS::Model::DoTS::NALocation;
use GUS::Model::DoTS::ExternalNASequence;
use GUS::Model::RAD3::SAGETag;
use GUS::Model::RAD3::SAGETagMapping;
use GUS::Model::Core::DatabaseInfo;
use GUS::Model::Core::TableInfo;

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  my $purposeBrief = "Generate SAGE data from sequences and genes.";

  my $purpose = <<PLUGIN_PURPOSE;
This plugin generates SAGE data from genomic data.  Specifically, it finds SAGE
tags in ExternalNaSequences, and creates GeneFeatureSageTagLinks to associate
SAGE tags with genes.  These associations are made by the findLinks method.
This method, written by Jonathan Crabtree for an earlier version of this
plugin, links each SAGE tag to any genes found within a given distance (by
default, 1000 bp).
PLUGIN_PURPOSE

  my $tablesAffected =
    [ ['DoTS::GeneFeatureSAGETagLink',
       'Insert a record for each predicted link'],
      ['DoTS::SAGETagFeature',
       'Insert a record for each predicted SAGE tag feature'],
      ['DoTS::NALocation', 'Insert three records for each predicted tag'],
      ['RAD3::SAGETag', 'Insert a record for any novel tag sequence'],
      ['RAD3::SAGETagMapping',
       'Map DoTS sourceId-ExtDbRelId to RAD CompositeElementId'],
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
     integerArg({name  => 'array_id',
		 descr => 'array_id',
		 reqd  => 0,
		 constraintFunc=> undef,
		 isList=>0,
		}),
     integerArg({name  => 'max_distance',
		 descr => 'max_distance',
		 reqd  => 0,
		 default  => 1000,
		 constraintFunc=> undef,
		 isList=> 0,
		}),
     booleanArg({name  => 'find_tags',
		 descr => 'find_tags',
		 reqd  => 0,
		 constraintFunc=> undef,
		 isList=> 0,
		}),
     booleanArg({name  => 'find_links',
		 descr => 'find_links',
		 reqd  => 0,
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

  # validate command-line arguments
  if (!($self->getArg('find_tags') || $self->getArg('find_links'))) {
    $self->userError('--find_tags or --find_links must be specified');
  }

  if ($self->getArg('find_tags')) {
    if (!$self->getArg('array_id')) {
      $self->userError('an array_id must be specified to find tags');
    }
    $self->{tagsFound} = 0;
  }

  if ($self->getArg('find_links')) {
    $self->{linksFound} = 0;
  }

  # if we're finding tag-gene links, prepare the query that runs
  # against each sequence
  if ($self->getArg('find_links')) {
    $self->prepareQuery($self->getArg('max_distance'));
  }

  $self->processSequencesByProjectId($self->getArg('project_id'),
				     $self->getArg('taxon_id'));

  my $logString = "LoadGenomicSageData finished.";
  if ($self->getArg('find_tags')) {
    $logString = $logString . " " . $self->{tagsFound} . " tags found.";
  }
  if ($self->getArg('find_links')) {
    $logString = $logString . " " . $self->{linksFound} . " links found.";
  }
  $self->log($logString);
}

# ----------------------------------------------------------------------

# Given a projectId, use ProjectLink to find and process
# the correspoding ExternalNaSequences

sub processSequencesByProjectId {
  my ($self, $project_id, $taxon_id) = @_;

  my $table_id = getTableId('DoTS', 'ExternalNASequence');

  my $sql = <<SQL;
    select pl.id
    from DoTS.ProjectLink pl, DoTS.ExternalNaSequence ens
    where pl.project_id = $project_id
      and pl.table_id = $table_id
      and pl.id = ens.na_sequence_id
      and ens.taxon_id = $taxon_id
SQL

  $self->logVerbose($sql);

  my $dbh = $self->getQueryHandle();
  $self->logVerbose("preparingAndExecuting sequenceId query");
  my $stmt = $dbh->prepareAndExecute($sql);
  $self->logVerbose("finished prepareAndExecute()");

  while (my ($na_sequence_id) = $stmt->fetchrow_array()) {
    $self->processSequence($na_sequence_id);
  }
}

# ----------------------------------------------------------------------

# given a sequence (by its naSequenceId), process it
# (i.e. find its SageTagFeatures or link them to Gene features)

sub processSequence {
  my ($self, $na_sequence_id) = @_;
  $self->logVerbose("processing NaSequenceId $na_sequence_id");

  if ($self->getArg('find_tags')) {
    $self->findTags($na_sequence_id);
  }

  if ($self->getArg('find_links')) {
    $self->findLinks($na_sequence_id);
  }

  $self->undefPointerCache();
}
# ----------------------------------------------------------------------

sub findTags {
  my ($self, $na_sequence_id) = @_;

  my $externalNaSequence =
    GUS::Model::DoTS::ExternalNASequence->new
	( {
	   na_sequence_id => $na_sequence_id
	  } );
  $externalNaSequence->retrieveFromDB();

  my $sequence = $externalNaSequence->getSequence();
  my $sourceId = $externalNaSequence->getSourceId();

  my $rightEnd;
  my $leftEnd;

  # hardwired for the restriction enzyme NlaIII, which recognizes CATG
  my $recogSeq = 'CATG';
  my $recogLength = 4;
  my $enzymeName = 'NlaIII';

  my $siteCount = 0;

  while ($sequence =~ m/(CATG)/ig) {

    # these are coordinates of binding site in 1-based system
    $rightEnd = pos ($sequence);
    $leftEnd  = $rightEnd - $recogLength + 1;

    # since the enzyme recognition sequence is its own reverse complement
    # (which it is, at least, for NlaIII) each site makes two tags.
    $self->createSageObjects( { sequenceSourceId => $sourceId,
			     rightEnd => $rightEnd,
			     leftEnd => $leftEnd,
			     isReversed => 0,
			     enzymeName => $enzymeName,
			     sequenceObject => $externalNaSequence,
			     sequenceString => \$sequence,
			   } );
    $self->createSageObjects( { sequenceSourceId => $sourceId,
			     rightEnd => $rightEnd,
			     leftEnd => $leftEnd,
			     isReversed => 1,
			     enzymeName => $enzymeName,
			     sequenceObject => $externalNaSequence,
			     sequenceString => \$sequence,
			   } );

    if ( 20 * $siteCount++ >= 10000 ) {
      $self->undefPointerCache();
      $siteCount = 0;
    }
  }
}

# ----------------------------------------------------------------------

# Create SageTagFeature and NaLocation objects, and call updateRad()
# to create RAD schema objects.

sub createSageObjects {
  my ($self, $argHash) = @_;

  my $bind_start = $argHash->{leftEnd};
  my $bind_end   = $argHash->{rightEnd};

  my $tag_start  = $argHash->{isReversed} ? $bind_start - 10 : $bind_end + 1 ;
  my $tag_end    = $argHash->{isReversed} ? $bind_start - 1  : $bind_end + 10;

  my $trailer_start = $argHash->{isReversed} ? $bind_start - 16 : $bind_end+ 11 ;
  my $trailer_end   = $argHash->{isReversed} ? $bind_start - 11 : $bind_end + 16 ;

  my $sense_g_s     = $argHash->{isReversed} ? 'g' : 'G';

  my $externalNaSequence = $argHash->{sequenceObject};

  # Make source_id unique, even if the same NaSequence.SourceId occurs
  # in two different ExternalDatabaseReleases
  my $sourceId = sprintf('%s-%d-%d-%d-%s',
			 $argHash->{sequenceSourceId},
			 $externalNaSequence->getExternalDatabaseReleaseId(),
			 $tag_start,
			 $tag_end,
			 $sense_g_s,
			);

  # Name should be in the same familiar format, but needn't be unique
  my $name = sprintf('%s-%d-%d-%s',
		     $argHash->{sequenceSourceId},
		     $tag_start,
		     $tag_end,
		     $sense_g_s,
		    );
  $name = substr($name, 0, 30);

  # make the database entries.
  my $sageTagFeature =
    GUS::Model::DoTS::SAGETagFeature->new
	( {
	   name => substr($sourceId,0,30),
	   source_id          => $sourceId,
	   is_predicted       => 1,
	   restriction_enzyme => $argHash->{enzymeName},
	  } );
  $sageTagFeature->setParent($argHash->{sequenceObject});

  my $tag_nalg =
    GUS::Model::DoTS::NALocation->new
	( {
	   na_feature_id  => $argHash->{sequenceSourceId},
	   start_min      => $tag_start,
	   start_max      => $tag_start,
	   end_min        => $tag_end,
	   end_max        => $tag_end,
	   is_reversed    => $argHash->{isReversed},
	  } );
  $tag_nalg->setParent( $sageTagFeature );

  my $trl_nalg =
    GUS::Model::DoTS::NALocation->new
	( {
	   na_feature_id  => $argHash->{sequenceSourceId},
	   start_min      => $trailer_start,
	   start_max      => $trailer_start,
	   end_min        => $trailer_end,
	   end_max        => $trailer_end,
	   is_reversed    => $argHash->{isReversed},
	  } );
  $trl_nalg->setParent( $sageTagFeature );

  my $bnd_nalg =
    GUS::Model::DoTS::NALocation->new
	( {
	   na_feature_id  => $argHash->{sequenceSourceId},
	   start_min      => $bind_start,
	   start_max      => $bind_start,
	   end_min        => $bind_end,
	   end_max        => $bind_end,
	   is_reversed    => $argHash->{isReversed},
	  } );
  $bnd_nalg->setParent( $sageTagFeature );

  $sageTagFeature->submit();

  $self->{tagsFound} += 1;

  $sageTagFeature->setTagLocationId($tag_nalg->getId());
  $sageTagFeature->setTrailerLocationId($trl_nalg->getId());
  $sageTagFeature->setBindingLocationId($bnd_nalg->getId());

  $sageTagFeature->submit();

  my $tag = substr(${$argHash->{sequenceString}}, $tag_start - 1, 10 );
  $tag = reverseComplement($tag) if $argHash->{isReversed};
  $tag = uc($tag);
  $self->updateRad($tag, $sageTagFeature);
}

# ----------------------------------------------------------------------

# Given a SageTagFeature and tag sequence, find or create
# a SageTag object for the tag, and link them with a
# new SageTagMapping object

sub updateRad {
  my ($self, $tag, $sageTagFeature) = @_;

  my $sageTag =
    GUS::Model::RAD3::SAGETag->new
	( {
	   tag => $tag,
	   array_id => $self->getArg('array_id')
	  } );

  if (!$sageTag->retrieveFromDB()) {
    $sageTag->submit();
  }

  my $sageTagMapping =
    GUS::Model::RAD3::SAGETagMapping->new
	( {
	   composite_element_id =>
	   $sageTag->getCompositeElementId(),
	   array_id => $sageTag->getArrayId(),
	   source_id =>
	   $sageTagFeature->getSourceId()
	  } );
  $sageTagMapping->submit();
}

# ----------------------------------------------------------------------

# returns the reverse complement of a nucleic acid sequence
sub reverseComplement {
  my $s = $_[0];
  $s =~ tr/ACGT/TGCA/;
  my $rs = reverse $s;

  return $rs;
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

  $self->logVerbose($sql);

  my $dbh = $self->getQueryHandle();
  $self->{geneTagLinksQuery} = $dbh->prepare($sql);
}

# ----------------------------------------------------------------------
# Given an na_sequence_id, use SQL to find linked gene/SAGE tag pairs.
# This is just a copy of the _storeLinks method from the old version
# of this plugin, modified to work with GUS v. 3 objects.

sub findLinks {
  my ($self, $na_sequence_id) = @_;

  $self->logVerbose("finding links for NaSequenceId $na_sequence_id");

  my $queryHandle = $self->{geneTagLinksQuery};
  $queryHandle->execute($na_sequence_id);

  while (my($tagId, $geneId, $tagStart, $tagEnd, $tagIsReversed, $geneStart,
	    $geneEnd, $geneIsReversed, $sameStrand)
	 = $queryHandle->fetchrow_array()) {

    $self->logVerbose("linking GeneFeatureId " . $geneId
		      . " to SageTagFeatureId " . $tagId);
    my($tt5p, $tt3p);

    if (!$geneIsReversed) {
      if (($tagStart <= $geneStart) && ($tagEnd >= $geneStart)) {
	$tt5p = 0;
      } else {
	$tt5p = ($tagEnd <= $geneStart)
	  ? $geneStart - $tagEnd
	    : $geneStart - $tagStart;
      }
      if (($tagStart <= $geneStart) && ($tagEnd >= $geneStart)) {
	$tt3p = 0;
      } else {
	$tt3p = ($tagStart >= $geneEnd)
	  ? $tagStart - $geneEnd
	    : $tagEnd - $geneEnd;
      }
    } else {
      if (($tagStart <= $geneEnd) && ($tagEnd >= $geneEnd)) {
	$tt5p = 0;
      } else {
	$tt5p = ($tagStart >= $geneEnd)
	  ? $tagStart - $geneEnd
	    : $tagEnd - $geneEnd;
      }
      if (($tagStart <= $geneEnd) && ($tagEnd >= $geneEnd)) {
	$tt3p = 0;
      } else {
	$tt3p = ($tagEnd <= $geneStart)
	  ? $geneStart - $tagEnd
	    : $geneStart - $tagStart;
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
	     same_strand => $sameStrand,
	     experimentally_verified => 0
	    } );

    if ($geneFeatureSageTagLink->retrieveFromDB()) {
      die("SageTagLink already exists between geneFeature " . $geneId .
	  " and sageTagFeature " . $tagId);
    }
    $geneFeatureSageTagLink->submit();
    $self->undefPointerCache();

    $self->{linksFound} += 1;
  }
  $queryHandle->finish();
}

# ----------------------------------------------------------------------

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
