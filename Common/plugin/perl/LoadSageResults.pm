package GUS::Common::Plugin::LoadSageResults;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
use GUS::PluginMgr::Plugin;
# use GUS::Model::DoTS::SAGETagFeature;
# use GUS::Model::DoTS::GeneFeature;
# use GUS::Model::DoTS::GeneFeatureSAGETagLink;
# use GUS::Model::DoTS::NALocation;
# use GUS::Model::DoTS::ExternalNASequence;
use GUS::Model::RAD3::SAGETag;
use GUS::Model::RAD3::SAGETagResult;
use GUS::Model::RAD3::Quantification;
# use GUS::Model::RAD3::SAGETagMapping;
use GUS::Model::Core::DatabaseInfo;
use GUS::Model::Core::TableInfo;
use FileHandle;

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  my $purposeBrief = "Load SAGE tag-count pairs from a file.";

  my $purpose = <<PLUGIN_PURPOSE;
This plugin loads SAGE tag-count pairs from a file into the database.
The tag sequence is added to RAD3.SageTag, if it isn't already there.  The count
is inserted into RAD3.SageTagResult.  A quantification_id and an array_id must
be supplied on the command line, these are used to link to RAD3.Quantification
and RAD3.Array.
PLUGIN_PURPOSE

  my $tablesAffected =
    [ ['RAD3::SAGETag', 'Insert a record for any novel tag sequence'],
      ['RAD3::SAGETagResult', 'Insert a record for each tag count'],
    ];

  my $tablesDependedOn =
    [ ['Core::DatabaseInfo', 'Look up table IDs by database/table names'],
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
		 isList=> 0,
		}),
     integerArg({name  => 'quantification_id',
		 descr => 'quantification_id',
		 reqd  => 1,
		 constraintFunc=> undef,
		 isList=> 0,
		}),
     stringArg({name  => 'datafile',
		 descr => 'datafile',
		 reqd  => 1,
		 constraintFunc=> undef,
		 isList=> 0,
		}),
    ];


  $self->initialize({requiredDbVersion => {},
                     cvsRevision => '$Revision$', # cvs fills this in!
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

  $self->{resultsAdded} = 0;
  $self->{tagsAdded} = 0;

  $self->loadSageFile($self->getArg('datafile'),
		      $self->getArg('array_id'),
		      $self->getArg('quantification_id'));

  $self->logVerbose("Finished LoadSageResults " .
		    $self->{resultsAdded} . " results added. " .
		    $self->{tagsAdded} . " tags added.");
}

# ----------------------------------------------------------------------
# Given the name of a data file, read tag-count pairs from it
# and add them to RAD

sub loadSageFile {
  my ($self, $datafile, $array_id, $quantification_id) = @_;

  my $fh = FileHandle->new('<'.$datafile);
  if (! $fh) {
    die ("Can't open datafile $datafile");
  }

  while (<$fh>) {
    chomp;
    my ( $tag, $count ) = split(/\s+/,$_);
    $self->logVerbose("Processing tag $tag, with count $count");

    # $tag is the oligo; $sageTag is the RAD3 object
    # getSageTag finds the RAD3.SageTag if it's there, adds it otherwise
    my $sageTag = $self->getSageTag($tag, $array_id);

    my $sageTagResult = 
      $self->addSageTagResult($sageTag, $quantification_id, $count);
    $sageTagResult->submit();
    $self->{resultsAdded} += 1;

    $self->undefPointerCache();
  }
  $fh->close();
}

# ----------------------------------------------------------------------
# Find SageTag object (inserting into DB if it's novel)

sub getSageTag {
  my ($self, $tag, $array_id) = @_;

  $self->logVerbose("Looking for RAD3.SageTag, " .
		    "tag sequence $tag, array_id $array_id");
  my $sageTag = GUS::Model::RAD3::SAGETag->new
    ( {
       tag => $tag,
       array_id => $array_id
       } );

  if (! $sageTag->retrieveFromDB()) {
    $self->logVerbose("Tag not found; inserting");
    $self->{tagsAdded} += 1;
    $sageTag->submit();
  }

  $self->logVerbose("returning compositeElementId " .
		    $sageTag->getCompositeElementId());
  return $sageTag;
}

# ----------------------------------------------------------------------
# make and populate SageTagResult object

sub addSageTagResult {
  my ($self, $sageTag, $quantification_id, $count) = @_;
  my $sageTagResult = GUS::Model::RAD3::SAGETagResult->new
    ( {
       composite_element_id => $sageTag->getCompositeElementId(),
       quantification_id => $quantification_id
      } );

  if ($sageTagResult->retrieveFromDB()) {
    die("SageTagResult already exists for composite_element_id " .
	$sageTag->getCompositeElementId(). ", quantification_id " .
	$quantification_id);
  }
  $sageTagResult->setTagCount($count);

  return $sageTagResult;
}

1;
