#######################################################################
##                 InsertCytobandFeatures.pm
##
## $Id: InsertCytobandFeatures allenem $
##
#######################################################################

package GUS::Community::Plugin::InsertCytobandFeatures;

@ISA = qw( GUS::PluginMgr::Plugin);

use strict 'vars';

use GUS::PluginMgr::Plugin;
use lib "$ENV{GUS_HOME}/lib/perl";

use GUS::Model::DoTS::ChromosomeElementFeature; 
use GUS::Model::DoTS::ExternalNASequence;
use GUS::Model::DoTS::NALocation;

use Data::Dumper;
use FileHandle;


my $argsDeclaration =
  [
   fileArg({ name           => 'inFile',
	     descr          => 'input data file; see NOTES for file format',
	     reqd           => 1,
	     mustExist      => 1,
	     format         => 'tab-delimited format',
	     constraintFunc => undef,
	     isList         => 0,
	   }),
 
   stringArg({ name  => 'extDbRlsSpec',
	       descr => "The ExternalDBRelease specifier for the result. Must be in the format 'name|version', where the name must match an name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
	       constraintFunc => undef,
	       reqd           => 1,
	       isList         => 0 }),
 
 
  
  ];


my $purposeBrief = <<PURPOSEBRIEF;
Load ctyobands into DoTS::ChromosomeElemenentFeature.
PURPOSEBRIEF

my $purpose = <<PLUGIN_PURPOSE;
Load ctyobands into DoTS::ChromosomeElemenentFeature, 
with Giemsa stain info loaded into the description field.
PLUGIN_PURPOSE

my $tablesAffected = [
                      ['DoTS::ChromosomeElementFeature', 'Each record stores a cytoband feature'],
                      ['DoTS::NALocation', 'Each record stores the chromosomal location of the feature'],
                     ];

my $tablesDependedOn = [
                     
                        ['SRes::ExternalDatabaseRelease', 'Lookups of external database specifications'],
                        ['DoTS::ExternalNASequence', 'Lookups of sequence ids']
		       ];

my $howToRestart = <<PLUGIN_RESTART;
just restart, plugin will not load duplicate records
PLUGIN_RESTART

my $failureCases = <<PLUGIN_FAILURE_CASES;
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
INPUT FILE FORMAT:
should be tab-delim with the following columns:
chromosome
start
end
band name
gieStain
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
		     cvsRevision => '$Revision: 16475 $', # cvs fills this in!
		     name => ref($self),
		     argsDeclaration => $argsDeclaration,
		     documentation => $documentation
		    });

  return $self;
}


my %naSequenceIds; # hash to store naSequenceId lookups

#######################################################################
# Main Routine
#######################################################################

sub run {
  my ($self) = @_;

  my $xdbrId = $self->getExtDbRlsId($self->getArg('extDbRlsSpec'));
  my $fName = $self->getArg('inFile');

  my $fh = FileHandle->new;
  $fh->open("<$fName") || $self->error("Unable to open input file: $fName.");
  while (<$fh>) {
      chomp;
      my ($sequenceSourceId, $startLoc, $endLoc, $bandName, $gieStain) = split /\t/; # gieStain is the Giemsa stain results. 

      my $naSequenceId = retrieveSequenceId($self, $sequenceSourceId);

      my $ceFeature = GUS::Model::DoTS::ChromosomeElementFeature->new(
	  { name => $bandName,
	    external_database_release_id => $xdbrId,
	    na_sequence_id => $naSequenceId,
	    description => $gieStain
	  });

      my $naLocation = GUS::Model::DoTS::NALocation->new(
	 { start_min => $startLoc,
	   end_max => $endLoc,
	 });

      $naLocation->setParent($ceFeature);
      $ceFeature->submit();
      $self->undefPointerCache();
    }

  $fh->close();
}

sub retrieveSequenceId {

  my ($self, $sequenceSourceId, $extDbRlsId) = @_;

  unless (exists $naSequenceIds{$sequenceSourceId}) {
      my $sequence = GUS::Model::DoTS::ExternalNASequence->new( {
          'source_id' => $sequenceSourceId,
								} );

      unless ( $sequence->retrieveFromDB() ) {
	  $self->error("No record for sequence $sequenceSourceId found in DoTS::ExternalNASequence");
      }

      $naSequenceIds{$sequenceSourceId} = $sequence->getNaSequenceId();
  }
  return $naSequenceIds{$sequenceSourceId};
}


sub undoTables {
  my ($self) = @_;

  return ('DoTS.NALocation',
          'DoTS.ChromosomeElementFeature');

}

1;
