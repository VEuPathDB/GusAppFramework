#######################################################################
##                 InsertTrack.pm
##
## Loads track data from tab-delimited file
## $Id: InsertTrack.pm 12488 2013-07-11 15:02:27Z iodice $
##
#######################################################################

package GUS::Community::Plugin::InsertTrack;
@ISA = qw( GUS::PluginMgr::Plugin);

use strict 'vars';


use GUS::PluginMgr::Plugin;
use lib "$ENV{GUS_HOME}/lib/perl";
use FileHandle;
use Carp;
use GUS::Model::Study::ProtocolAppNode;
use GUS::Model::Study::Characteristic;
use GUS::Model::Results::SegmentResult;
use Data::Dumper;

my $argsDeclaration =
  [
   fileArg({ name           => 'file',
	     descr          => 'input data file',
	     reqd           => 1,
	     mustExist      => 1,
	     format         => 'tab-delimited format',
	     constraintFunc => undef,
	     isList         => 0,
	   }),
     stringArg({ name  => 'extDbRlsSpec',
		  descr => "The ExternalDBRelease specifier. Must be in the format 'name|version', where the name must match an name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
		  constraintFunc => undef,
		  reqd           => 1,
		  isList         => 0 }),
     stringArg({ name  => 'label',
		  descr => "The JBrowse internal ID for this track",
		  constraintFunc => undef,
		  reqd           => 1,
		  isList         => 0 }),
     stringArg({ name  => 'name',
		  descr => "The human-readable name for this track",
		  constraintFunc => undef,
		  reqd           => 1,
		  isList         => 0 }),
     stringArg({ name  => 'type',
		  descr => "An ontology/ontology-term pair describing the type of this track. The ontology name and term name are separated by a slash",
		  constraintFunc => undef,
		  reqd           => 1,
		  isList         => 0 }),
     stringArg({ name  => 'terms',
		  descr => "A comma-separated list of ontology terms related to this track. Each item in the list consists of an ontology name and a term name, separated by a slash",
		  constraintFunc => undef,
		  reqd           => 1,
		  isList         => 0 }),
  ];


my $purposeBrief = <<PURPOSEBRIEF;
Loads the genomic spans of a genome-browser track
PURPOSEBRIEF

my $purpose = <<PLUGIN_PURPOSE;
Loads the genomic spans of a genome-browser track
PLUGIN_PURPOSE

my $tablesAffected = [
                      ['Study::ProtocolAppNode', 'Each track is represented by one record.'],
                      ['Study::Characteristic', 'Each record links a track to an ontology term.'],
                      ['Results::SegmentResult', 'Each record stores one genomic span for the track.'],
                     ];

my $tablesDependedOn = [];

my $howToRestart = <<PLUGIN_RESTART;
No restart facility available.
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

sub new {
    my ($class) = @_;
    my $self = {};
    bless($self,$class);


    $self->initialize({requiredDbVersion => 4.0,
		       cvsRevision => '$Revision: 12488 $', # cvs fills this in!
		       name => ref($self),
		       argsDeclaration => $argsDeclaration,
		       documentation => $documentation
		      });

    return $self;
}

#######################################################################
# Main Routine
#######################################################################

sub run {
    my ($self) = @_;

    # each track has one ProtocolAppNode
    my $pan = GUS::Model::Study::ProtocolAppNode->new({
	external_database_release_id => $self->getExtDbRlsId($self->getArg('extDbRlsSpec')),
	type_id => $self->getOntologyTermId(split("/", $self->getArg('type'))),
	name => $self->getArg('name'),
	source_id => $self->getArg('label'),
					  });
    $pan->submit()
	unless ($pan->retrieveFromDB());

    # each ontology term is a Characteristic
    foreach my $ot (split(',', $self->getArg('terms'))){
	my $c = GUS::Model::Study::Characteristic->new({
	    protocol_app_node_id => $pan->getPrimaryKey(),
	    ontology_term_id => $self->getOntologyTermId(split("/", $ot)),
					   });
	$c->submit()
	    unless ($c->retrieveFromDB());
    }

    # put track-file records in Results::SegmentResult
    open (TRACK, $self->getArg('trackFile')) || die "Can't open input file.";
    while (<TRACK>) {
      chomp;
      my ($chromosome, $startloc, $endloc, $score, $strand, $name, $thickstartloc,
          $thickendloc, $itemrgb, $blockcount, $blocksizes, $blockstarts) = split /\t/;

      my $sequenceId = $self->getSequenceId($chromosome);
      my $segment = GUS::Model::Results::SegmentResult->new({
	  protocol_app_node_id => $pan->getPrimaryKey(),
	  na_sequence_id => $sequenceId,
	  segment_start => $startloc,
	  segment_end => $endloc,
	  on_reverse_strand => ($strand eq "-" ? 1 : 0),
	  score1 => $score
							    });
      $segment->submit()
	  unless ($segment->retrieveFromDB());
    }

    my $msg = "Here is my status message.";
    return $msg;
}

sub getSequenceId {
  my ($self, $name) = @_;
}

sub undoTables {
  my ($self) = @_;

  return ('Study.ProtocolAppNode',
          'Study.Characteristic',
          'Results.SegmentResult',
         );
}

1;
