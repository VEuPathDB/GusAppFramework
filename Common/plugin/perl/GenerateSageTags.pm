package GUS::Common::Plugin::GenerateSageTags;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
use GUS::PluginMgr::Plugin;
use GUS::Model::DoTS::SAGETagFeature;
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

  my $purposeBrief = "Predict SAGE tags in nucleic acid sequences.";

  my $purpose = <<PLUGIN_PURPOSE;
This plugin scans nucleic acid sequences for SAGE tags.  A SAGETagFeature is 
created to map each SAGE tag occurrence to the sequence in which it is found.  
Three NALocations are created to store the location of the tag, trailer and 
binding site within the sequence.  The sequence of the tag oligomer is
in a RAD3.SageTag (which is found if it exists, and created otherwise).  The 
SageTag is mapped to the SAGETagFeature with a new SAGETagMapping.

PLUGIN_PURPOSE

  my $tablesAffected =
    [ ['DoTS::SAGETagFeature', 'Insert a record for each predicted SAGE tag feature'],
      ['DoTS::NALocation', 'Insert three records for each predicted tag'],
      ['RAD3::SAGETag', 'Insert a record for any novel tag sequence'],
      ['RAD3::SAGETagMapping',
       'Map DoTS sourceId-ExtDbRelId to RAD CompositeElementId'],
    ];

  my $tablesDependedOn =
    [ ['DoTS::ProjectLink', 'Identify sequences to scan for tags'],
      ['DoTS::ExternalNASequence', 'Get sequences to scan for SAGE tag features'],
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
     integerArg({name  => 'array_id',
		 descr => 'array_id',
		 reqd  => 1,
		 constraintFunc=> undef,
		 isList=>0,
		}),
     integerArg({name  => 'project_id',
		 descr => 'project_id',
		 reqd  => 1,
		 constraintFunc=> undef,
		 isList=>0,
		}), 
     integerArg({name  => 'taxon_id',
		 descr => 'taxon_id',
		 reqd  => 1,
		 constraintFunc=> undef,
		 isList=>0,
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
# to scan for SageTagFeatures

sub scanSequencesByProjectId {
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

  my $dbh = $self->getQueryHandle();
  my $stmt = $dbh->prepareAndExecute($sql);

  while (my ($na_sequence_id) = $stmt->fetchrow_array()) {
    $self->logVerbose("Processing NaSequenceId " . $na_sequence_id);
    $self->scanSequenceById($na_sequence_id);
    $self->undefPointerCache();
  }
}

# Given an na_sequence_id, scan that sequence for SageTagFeatures

sub scanSequenceById {
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
    $self->_createEntries( { id => $sourceId,
			     re => $rightEnd,
			     le => $leftEnd,
			     rv => 0,
			     ez => $enzymeName,
			     sq => $externalNaSequence,
			     ss => \$sequence,
			   } );
    $self->_createEntries( { id => $sourceId,
			     re => $rightEnd,
			     le => $leftEnd,
			     rv => 1,
			     ez => $enzymeName,
			     sq => $externalNaSequence,
			     ss => \$sequence,
			   } );

    if ( 20 * $siteCount++ >= 10000 ) {
      $self->undefPointerCache();
      $siteCount = 0;
    }
  }				# eof matches to sequence.
}

# ----------------------------------------------------------------------

# Create SageTagFeature and NaLocation objects, and call updateRad()
# to create RAD schema objects.

sub _createEntries {
  my ($self, $argHash) = @_;

  my $bind_start = $argHash->{le};
  my $bind_end   = $argHash->{re};

  my $tag_start  = $argHash->{rv} ? $bind_start - 10 : $bind_end + 1 ;
  my $tag_end    = $argHash->{rv} ? $bind_start - 1  : $bind_end + 10;

  my $trailer_start = $argHash->{rv} ? $bind_start - 16 : $bind_end+ 11 ;
  my $trailer_end   = $argHash->{rv} ? $bind_start - 11 : $bind_end + 16 ;

  my $sense_g_s     = $argHash->{rv} ? 'g' : 'G';

  my $externalNaSequence = $argHash->{sq};

  # Make source_id unique, even if the same NaSequence.SourceId occurs
  # in two different ExternalDatabaseReleases
  my $sourceId = sprintf('%s-%d-%d-%d-%s',
			 $argHash->{id},
			 $externalNaSequence->getExternalDatabaseReleaseId(),
			 $tag_start,
			 $tag_end,
			 $sense_g_s,
			);

  # Name should be in the same familiar format, but needn't be unique
  my $name = sprintf('%s-%d-%d-%s',
		     $argHash->{id},
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
	   restriction_enzyme => $argHash->{ez},
	  } );
  $sageTagFeature->setParent($argHash->{sq});

  my $tag_nalg =
    GUS::Model::DoTS::NALocation->new
	( {
	   na_feature_id  => $argHash->{id},
	   start_min      => $tag_start,
	   start_max      => $tag_start,
	   end_min        => $tag_end,
	   end_max        => $tag_end,
	   is_reversed    => $argHash->{rv},
	  } );
  $tag_nalg->setParent( $sageTagFeature );

  my $trl_nalg =
    GUS::Model::DoTS::NALocation->new
	( {
	   na_feature_id  => $argHash->{id},
	   start_min      => $trailer_start,
	   start_max      => $trailer_start,
	   end_min        => $trailer_end,
	   end_max        => $trailer_end,
	   is_reversed    => $argHash->{rv},
	  } );
  $trl_nalg->setParent( $sageTagFeature );

  my $bnd_nalg =
    GUS::Model::DoTS::NALocation->new
	( {
	   na_feature_id  => $argHash->{id},
	   start_min      => $bind_start,
	   start_max      => $bind_start,
	   end_min        => $bind_end,
	   end_max        => $bind_end,
	   is_reversed    => $argHash->{rv},
	  } );
  $bnd_nalg->setParent( $sageTagFeature );

  $sageTagFeature->submit();

  $sageTagFeature->setTagLocationId($tag_nalg->getId());
  $sageTagFeature->setTrailerLocationId($trl_nalg->getId());
  $sageTagFeature->setBindingLocationId($bnd_nalg->getId());

  $sageTagFeature->submit();

  my $tag = substr(${$argHash->{ss}}, $tag_start - 1, 10 );
  $tag = reverseComplement($tag) if $argHash->{rv};
  $tag = uc($tag);
  $self->updateRad($tag, $sageTagFeature);
}

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

# ======================================================================
# ----------------------------------------------------------------------
# ======================================================================

# returns the reverse complement of a nucleic acid sequence
sub reverseComplement {
  my $s = $_[0];
  $s =~ tr/ACGT/TGCA/;
  my $rs = reverse $s;

  return $rs;
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
