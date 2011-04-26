package GUS::Community::Plugin::LoadMutualInformationScores;
@ISA = qw(GUS::PluginMgr::Plugin);

#$Id$

use strict;
use GUS::PluginMgr::Plugin;
use GUS::Model::DoTS::PhylogeneticProfile;
use GUS::Model::DoTS::PhylogeneticProfileSet;
use GUS::Model::DoTS::PhylogeneticProfileMember;
use GUS::Model::DoTS::MutualInformationScore;
use GUS::Model::Core::DatabaseInfo;
use GUS::Model::Core::TableInfo;
use FileHandle;
use ApiCommonData::Load::Util;

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
     stringArg({ descr => 'Desciption of the PhylogeneticProfileSet',
                 name  => 'ProfileSetDescription',
                 isList    => 0,
                 reqd  => 1,
                 constraintFunc => undef,
               }),

     floatArg({name  => 'threshold',
		 descr => 'skip pairs with score below this threshold',  # talk about what SQL does
		 reqd  => 1,
		 constraintFunc=> undef,
		 isList=> 0,
		}),

     fileArg({name           => 'dataFile',
              descr          => 'File containing SourceIds and mutual information scores',
              reqd           => 1,
              mustExist      => 1,
              format         => 'One line for each record separated by | ',
              constraintFunc => undef,
              isList         => 0, 
	 }),

     booleanArg ({name => 'tolerateMissingIds',
                  descr => 'Set this to tolerate (and log) source ids in the input that do not find an oligo or gene in the database.  
                          If not set, will fail on that condition',
                  reqd => 0,
                  default =>0
                 }),
    ];

  $self->initialize({requiredDbVersion => 3.6,
                     cvsRevision => '$Revision$', 
                     cvsTag => '$Name$', 
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

  $self->loadMutualInformationFile($self->getArg('dataFile'),
				   $self->getArg('ProfileSetDescription'));

  my $msg = "Finished LoadMutualInformationScores.\n";
  return $msg;
}

# ----------------------------------------------------------------------
# Given the name of a data file, read and load mutual information score data

sub loadMutualInformationFile {
  my ($self, $datafile) = @_;

  my $fileName;

  if ($datafile =~ /(.*)\.gz$/){
    system("gunzip $datafile");
    $fileName = $1;
  }
  else {
    $fileName = $datafile;
  }

  open(FILE, "< $fileName") || die ("Can't open datafile $datafile");

  my %profileIdHash = $self->getProfileIdHash();
  my $submitCount = 0;
  my $skipCount = 0;
  my $missingCount = 0;
  my $threshold = $self->getArg('threshold');

  while(<FILE>) {
    chomp;

    my ($primarySourceId, $secondarySourceId, $score) = (split(/\|/, $_));
    if ($score < $threshold) {
      $skipCount++;
      next;
    }

    my $primaryNaFeatureId =
      ApiCommonData::Load::Util::getGeneFeatureId($self, $primarySourceId);

    my $secondaryNaFeatureId = 
      ApiCommonData::Load::Util::getGeneFeatureId($self, $secondarySourceId);
    my $primaryProfileId = $profileIdHash{$primaryNaFeatureId};

    my $secondaryProfileId = $profileIdHash{$secondaryNaFeatureId};

    if (!$primaryProfileId || !$secondaryProfileId) {
      my $msg = "Can't find either na_feature_id or profile_id for one or both of '$primarySourceId' and '$secondarySourceId'";
      if ($self->getArgs()->{tolerateMissingIds}) {
	$missingCount++;
 	$self->log($msg);
	next;
      } else {
 	$self->userError($msg);
      }
    }

    my $mi = GUS::Model::DoTS::MutualInformationScore->
      new( {primary_profile_id => $primaryProfileId,
	    secondary_profile_id => $secondaryProfileId,
	    mutual_information_score => $score * 10000
	   } );
    
    $mi->submit();
    if ($submitCount++ % 1000 == 0) {
      $self->log("submitted $submitCount.  skipped $skipCount (below threshold).  skipped $missingCount (profile not found)");
      $self->undefPointerCache();
    }
  }

  close(FILE);
  system("gzip $fileName");

  my $rv = "submitted $submitCount.  skipped $skipCount (below threshold).  skipped $missingCount (profile not found)";
  return($rv);
}

=pod

=head2 Subroutines

=over 4

=item C<getProfileIdHash>

Retrieve all Dots::phylogeneticprofile's where the Dots.PhylogeneticProfileSet matches
the description argument.  

B<Return type:> C<hashref>

key of hash is the dots.na_feature_id and value is the profile id

=cut

sub getProfileIdHash {
  my ($self) = @_;

  my %profileIdHash;

  my $profileSet = GUS::Model::DoTS::PhylogeneticProfileSet->
    new({description => $self->getArgs()->{ProfileSetDescription}});

  if($profileSet->retrieveFromDB()) {
    my $phylogeneticProfileSetId = $profileSet->getId();

    my $sql = "SELECT phylogenetic_profile_id, NA_FEATURE_ID
                FROM DoTS.PhylogeneticProfile
                 WHERE phylogenetic_profile_set_id = $phylogeneticProfileSetId";

    my $sth = $self->getQueryHandle()->prepareAndExecute($sql);

    while (my ($profileId, $naFeatureId) = $sth->fetchrow_array()) {
      $profileIdHash{$naFeatureId} = $profileId;
    }
  }
  else {
    die "The ProfileSetDescription provided does not match any in the db";
  }
  return %profileIdHash;
}

sub undoTables {
  my ($self) = @_;

  return ('DoTS.MutualInformationScore'
	 );
}


1;
