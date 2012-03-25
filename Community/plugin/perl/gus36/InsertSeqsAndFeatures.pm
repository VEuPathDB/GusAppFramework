package GUS::Community::Plugin::LoadAnnotatedSeqs;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict 'vars';

use XML::Simple;
use DBI;
use CBIL::Util::Disp;

use Bio::SeqIO;
use Bio::SeqFeature::Tools::Unflattener;
use Bio::Tools::SeqStats;
use Bio::SeqFeature::Generic;
use Bio::LocationI;

use GUS::PluginMgr::Plugin;
use GUS::Model::DoTS::NASequence; ## View -> NASequenceImp
use GUS::Model::DoTS::ExternalNASequence; ## View -> NASequenceImp
use GUS::Model::DoTS::NAEntry;
use GUS::Model::DoTS::SecondaryAccs;
use GUS::Model::DoTS::NALocation; #NEED TO IMPLEMENT THIS FOR EACH FEATURE!!!!!!!!!!!!!!!!!!!!!

use GUS::Model::DoTS::NAGene;
use GUS::Model::DoTS::NAProtein;
use GUS::Model::DoTS::NAPrimaryTranscript;
use GUS::Model::SRes::DbRef;
use GUS::Model::DoTS::Organelle;
use GUS::Model::DoTS::NAFeatureComment;

use GUS::Model::DoTS::NASequenceRef;
use GUS::Model::DoTS::NASequenceOrganelle;
use GUS::Model::DoTS::NASequenceKeyword;
use GUS::Model::DoTS::NAFeatureNAGene;
use GUS::Model::DoTS::NAFeatureNAPT;
use GUS::Model::DoTS::NAFeatureNAProtein;
use GUS::Model::DoTS::DbRefNAFeature;
use GUS::Model::DoTS::DbRefNASequence;
use GUS::Model::SRes::ExternalDatabaseKeyword;

use GUS::Model::DoTS::NAFeatureImp;
use GUS::Model::DoTS::NAFeature;
use GUS::Model::DoTS::DNARegulatory;
use GUS::Model::DoTS::DNAStructure;
use GUS::Model::DoTS::STS;
use GUS::Model::DoTS::GeneFeature;
use GUS::Model::DoTS::RNAType;
use GUS::Model::DoTS::Repeats;
use GUS::Model::DoTS::Miscellaneous;
use GUS::Model::DoTS::Immunoglobulin;
use GUS::Model::DoTS::ProteinFeature;
use GUS::Model::DoTS::SeqVariation;
use GUS::Model::DoTS::RNAStructure;
use GUS::Model::DoTS::Source;
use GUS::Model::DoTS::Transcript;
use GUS::Model::DoTS::ExonFeature;

############################################################ 
# Application Context
############################################################

sub new {
  my $class = shift;
  my $self = {};
  bless($self, $class);

  my $documentation = &getDocumentation();

  my $args = &getArgsDeclaration();

  $self->initialize({requiredDbVersion => {RAD3 => '3', Core => '3'},
		     cvsRevision => '$Revision$',
		     cvsTag => '$Name$',
		     name => ref($self),
		     revisionNotes => '',
		     argsDeclaration => $args,
		     documentation => $documentation
		    });
  return $self;
}


###############################################################
#Main Routine
##############################################################

sub run{
  my $self = shift;

  my $args = $self->getArgs();
  my $dbh = $self->getQueryHandle();
  my $dbRlsId = $self->getArg('db_rls_id');
  my $mapXml = $self->getArg('map_xml');
  my $dataFile = $self->getArg('data_file');
  print "*** testing: db_rls_id = $dbRlsId, map_xml = $mapXml, data_file = $dataFile ***\n";
  return "short summary";
}

# ----------------------------------------------------------
# Load Arguments
# ----------------------------------------------------------

sub getArgsDeclaration {
  my $argsDeclaration  =
    [
     fileArg({name => 'map_xml',
	      descr => 'XML file with Mapping of Sequence Feature from BioPerl to GUS',
	      constraintFunc=> undef,
	      reqd  => 1,
	      isList => 0,
	      mustExist => 1,
	      format => 'XML',
	     }),

     fileArg({name => 'data_file',
	      descr => 'text file with GenBank records of sequence annotation data',
	      constraintFunc=> undef,
	      reqd  => 1,
	      isList => 0,
	      mustExist => 1,
	      format => 'genbank',
	     }),

     integerArg({name => 'db_rls_id',
		 descr => 'external database release id for the data',
		 constraintFunc=> undef,
		 reqd  => 1,
		 isList => 0
		}),

     integerArg({name => 'test_number',
		 descr => 'number of entries to do test on',
		 constraintFunc=> undef,
		 reqd  => 0,
		 isList => 0
		}),

     booleanArg({name => 'is_update_mode',
		 descr => 'whether this is an update mode',
		 constraintFunc=> undef,
		 reqd  => 0,
		 isList => 0,
		 default => 0,
		}),
    ];

  return $argsDeclaration;
}


# ----------------------------------------------------------
# Documentation
# ----------------------------------------------------------

sub getDocumentation {

my $description = <<NOTES;
 Watch more star trek re-runs.  You can learn everything you need
 to know about computer engineering from Spock and Scotty.
NOTES

my $purpose = <<PURPOSE;
 Plate of shrimp.
PURPOSE

my $purposeBrief = <<PURPOSEBRIEF;
 Plate of shrimp.
PURPOSEBRIEF

my $syntax = <<SYNTAX;
 Why booze is so expensive in GA.
SYNTAX

my $notes = <<NOTES;
 Homer Simpson
NOTES

my $tablesAffected = <<AFFECT;
 Tables deficated
AFFECT

my $tablesDependedOn = <<TABD;
 Tables dumped
TABD

my $howToRestart = <<RESTART;
 Flick the power switch
RESTART

my $failureCases = <<FAIL;
 Delta Delta Delta can we help ya help ya help ya
FAIL

  my $documentation = {purpose=>$purpose, purposeBrief=>$purposeBrief,tablesAffected=>$tablesAffected,tablesDependedOn=>$tablesDependedOn,howToRestart=>$howToRestart,failureCases=>$failureCases,notes=>$notes};

return ($documentation);

}
