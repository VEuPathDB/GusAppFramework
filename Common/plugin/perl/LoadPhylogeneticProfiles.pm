package GUS::Common::Plugin::LoadPhylogeneticProfiles;
@ISA = qw(GUS::PluginMgr::Plugin);

# $Id$

use strict;
use GUS::PluginMgr::Plugin;
use GUS::Model::DoTS::PhylogeneticProfile;
use GUS::Model::DoTS::PhylogeneticProfileMember;
use GUS::Model::Core::DatabaseInfo;
use GUS::Model::Core::TableInfo;
use FileHandle;

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  my $purposeBrief = "Load phylogenetic profiles from a file.";

  my $purpose = <<PLUGIN_PURPOSE;
This plugin loads phylogenetic profiles.  Each of these profiles describes
a gene in terms of which organisms' genomes contain orthologs of it.
PLUGIN_PURPOSE

  my $tablesAffected =
    [ ['DoTS::PhylogeneticProfile', 'Insert one record per gene'],
      ['DoTS::PhylogeneticProfileMember',
       'For each profile, insert one record per genome'],
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
     integerArg({name  => 'phylogenetic_profile_set_id',
		 descr => 'phylogenetic_profile_set_id',
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

  $self->loadPhyloProfileFile($self->getArg('datafile'),
		           $self->getArg('phylogenetic_profile_set_id'),
			   $self->getArg('pred_alg_invocation_id'));

  $self->logVerbose("Finished Load2aryStruct.");
}

# ----------------------------------------------------------------------
# Given the name of a data file, read and load phylogenetic profile data

sub loadPhyloProfileFile {
  my ($self, $datafile, $phylogenetic_profile_set_id, $pred_alg_invocation_id) = @_;

  my $fh = FileHandle->new('<'.$datafile);
  if (! $fh) {
    die ("Can't open datafile $datafile");
  }

  my $taxonIdList = parseTaxa(<$fh>);
  exit;

  my ($cCalls, $hCalls, $eCalls, $aa_sequence_id);
  while (<$fh>) {
    chomp;


    $cCalls .= substr($_, 13,1);
    $hCalls .= substr($_, 20,1);
    $eCalls .= substr($_, 27,1);
  }
  $fh->close();


}

sub parseTaxa {
  my ($taxonList) = @_;

  print "taxonList = $taxonList\n";
}
