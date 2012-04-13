#######################################################################
##                 InsertECMapping.pm
##
## Creates new entries in the table DoTS.AASequenceEnzymeClass to represent
## the EC mappings found in a tab delimited file of the form EC number, alias
## $Id$
##
#######################################################################

package GUS::Community::Plugin::InsertECMapping;
@ISA = qw( GUS::PluginMgr::Plugin);

use strict 'vars';

use GUS::PluginMgr::Plugin;
use lib "$ENV{GUS_HOME}/lib/perl";
use FileHandle;
use Carp;
use GUS::Model::DoTS::AASequenceEnzymeClass;
use GUS::Model::SRes::EnzymeClass;
use GUS::Model::DoTS::TranslatedAAFeature;
use GUS::Model::DoTS::GeneFeature;
#use GUS::Model::DoTS::NAFeatureNaGene;
use GUS::Model::DoTS::NAGene;
use GUS::Supported::Util;

my $purposeBrief = <<PURPOSEBRIEF;
Creates new entries in table DoTS.AASequenceEnzymeClass to represent new aa sequence/enzyme class associations.
PURPOSEBRIEF

my $purpose = <<PLUGIN_PURPOSE;
Takes in a tab delimited file of the order EC number, identifier, and creates new entries in table DoTS.AASequenceEnzymeClass to represent new aa sequence/enzyme class associations.  If the identifier is not the primary identifier, we will map the EC number to the primary identifier via the NAGene table, which houses gene aliases.  The mapping then will be NAGene to NAFeatureNAGene to Transcript.
PLUGIN_PURPOSE

my $tablesAffected =
	[['DoTS.AASequenceEnzymeClass', 'The entries representing the new aa_sequence/enzyme class mappings are created here']];

my $tablesDependedOn = [['SRes::EnzymeClass','The EC Numbers from the EC mapping file must have entries in this table to be considered legitimate'],['DoTS::TranslatedAAFeature','The sequences mapped to EC Numbers by the EC mapping file must have entries in this table'],['DoTS::GeneFeature','This table may contain the source ID that will be used to map from the Pfid provided by the mapping file to the entry in DoTS::TranslatedAAFeature'],['DoTS::NAFeatureNaGene','If DoTS::GeneFeature does not contain the Pfid from the mapping file as a source ID, we will need to use this table to check synonyms so that we can map the Pfid to the entry in DoTS::TranslatedAAFeature'],['DoTS::NAGene','If DoTS::GeneFeature does not contain the Pfid from the mapping file as a source ID, we will need to check this table for synonyms so that we can map the Pfid to the entry in DoTS::TranslatedAAFeature']];

my $howToRestart = <<PLUGIN_RESTART;
There is currently no restart method
PLUGIN_RESTART

my $failureCases = <<PLUGIN_FAILURE_CASES;
There are no known failure cases
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
   fileArg({name => 'ECMappingFile',
	  descr => 'pathname for the file containing the EC mapping data',
	  constraintFunc => undef,
	  reqd => 1,
	  isList => 0,
	  mustExist => 1,
	  format => 'Two column tab delimited file in the order EC number, identifier'
        }),
   stringArg({name => 'evidenceCode',
	      descr => 'the evidence code with which data should be entered into the AASequenceEnzymeClass table',
	      reqd => 1,
	      constraintFunc => undef,
	      isList => 0,
	     }), 
   stringArg({name => 'aaSeqLocusTagMappingSql',
	      descr => 'sql which returns the aa_sequence_id for a given locus tag.  use LOCUS_TAG as a macro for where the locus tag should be interpolated into the sql string',
	      reqd => 1,
	      constraintFunc => undef,
	      isList => 0,
	     })

  ];


sub new {
    my ($class) = @_;
    my $self = {};
    bless($self,$class);


    $self->initialize({requiredDbVersion => 3.6,
		       cvsRevision => '$Revision: 9997 $', # cvs fills this in!
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
  my $mappingFile = $self->getArg('ECMappingFile');

  my $msg = $self->getMapping($mappingFile);

  return $msg;
}

sub getMapping {
  my ($self, $mappingFile) = @_;
  my %ecNumbers = ();
  my %ids = ();
  my $enzymeClass;
  my $aaSeqId;
  my $evidCode = $self->getArg('evidenceCode');

  open (ECMAP, "$mappingFile") ||
                    die ("Can't open the file $mappingFile.  Reason: $!\n");

    while (<ECMAP>) {
	chomp;

	my ($locusTag, $ecNumber) = split('\t', $_);

	if (!$ecNumber || !$locusTag){
	  next;
	}

	$locusTag =~ s/\s//g;
	$ecNumber =~ s/\s//g;

	$self->log("Processing Pfid: $locusTag, ECNumber: $ecNumber\n");

	if ($ecNumbers{$ecNumber}){
	  $enzymeClass = $ecNumbers{$ecNumber};
	}
	else {
	  $enzymeClass = $self->getEnzymeClass($ecNumber, \%ecNumbers);
	}

	if ($ids{$locusTag}){
	  $aaSeqId = $ids{$locusTag};
	}
	else {
	  $aaSeqId = $self->getAASeqId($locusTag, \%ids);
	}

	my $newAASeqEnzClass =  GUS::Model::DoTS::AASequenceEnzymeClass->new({
					    'aa_sequence_id' => $aaSeqId,
					    'enzyme_class_id' => $enzymeClass,
					    'evidence_code' => $evidCode
	});

	unless (!$enzymeClass || !$aaSeqId){
	  if(!$newAASeqEnzClass->retrieveFromDB()){
	    $self->log("submitted enzyme $enzymeClass, seq $aaSeqId\n");
	    $newAASeqEnzClass->submit();
	  }
	}
      }

  my $msg = "Finished processing EC Mapping file\n";

  return $msg;
}

###### FETCH THE EC ID FOR A GIVEN EC NUMBER ######

sub getEnzymeClass {
  my ($self, $ecNumber, $ecHash) = @_;

  my $newEnzymeClass =  GUS::Model::SRes::EnzymeClass->new({
	'ec_number' => $ecNumber
	});

  $newEnzymeClass->retrieveFromDB();
  my $enzymeClass = $newEnzymeClass->getId();

$$ecHash{$ecNumber} = $enzymeClass;

print "EC NUMBER: $enzymeClass\n";

return $enzymeClass;
}

###### FETCH THE AA SEQUNCE ID FOR A GIVEN ALIAS ######

sub getAASeqId {
  my ($self, $locusTag, $aaIdHash) = @_;

  my $sql = $self->getArg('aaSeqLocusTagMappingSql');
print "SQL: $sql\n";

  my $queryHandle = $self->getQueryHandle();

  my $sth = $queryHandle->prepare($sql);
  my $naFeatureId =  GUS::Supported::Util::getGeneFeatureId($self, $locusTag) ;
  $sth->execute($naFeatureId);
  my $aaSequenceId = $sth->fetchrow_array();
  $sth->finish();

  $$aaIdHash{$locusTag} = $aaSequenceId;

print "AA SEQ ID: $aaSequenceId\n";

  return $aaSequenceId;
}

sub undoTables {
  my ($self) = @_;

  return ('DoTS.AASequenceEnzymeClass');
}

1;
