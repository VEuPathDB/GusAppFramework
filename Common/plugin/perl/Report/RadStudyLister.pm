
package GUS::Common::Plugin::Report::RadStudyLister;
@ISA = qw(GUS::PluginMgr::Plugin);

# ----------------------------------------------------------------------

use strict;

use FileHandle;
use V;

use GUS::PluginMgr::Plugin;

use GUS::PluginMgr::PluginUtilities::ConstraintFunction;
use GUS::PluginMgr::PluginUtilities;

use GUS::Model::RAD3::Study;

# ======================================================================

sub new {
   my $Class = shift;

   my $self = bless {}, $Class;

   my $selfPodCommand = 'pod2text '. __FILE__;
   my $selfPod        = `$selfPodCommand`;

   $self->initialize
   ({ requiredDbVersion => {},
      cvsRevision       => ' $Revision$ ',
      name              => ref($self),

      # just expand
      revisionNotes     => '',
      revisionNotes     => 'initial creation and testing',

      # ARGUMENTS
      argsDeclaration   =>
      [
      ],

      # DOCUMENTATION
      documentation     =>
      { purpose          => <<Purpose,

  This plugin lists RAD3.Studies and dependent info

Purpose
        purposeBrief     => 'List RAD3.Studies',
        tablesAffected   =>
        [ ],
        tablesDependedOn =>
        [
        ],
        howToRestart     => 'just restart; this is a reader',
        failureCases     => 'just run again',
        notes            => $selfPod,
      },
    });

   # RETURN
   $self
}

# ======================================================================

sub run {
   my $Self       = shift;

	 $Self->logArgs();

	 my $description_fmt = "%s";

   my $sql = 'select max(length(name)) from SRes.ExternalDatabase';
   my ($w) = @{$Self->sql_get_as_array($sql)};
   my $name_fmt = "%-${w}.${w}s";

   my $sql = 'select max(length(version)) from SRes.ExternalDatabaseRelease';
   my ($w) = @{$Self->sql_get_as_array($sql)};
   my $version_fmt = "%-${w}.${w}s";

   my $sql = 'select study_id from RAD3.Study order by name';
   my @study_ids = @{$Self->sql_get_as_array($sql)};

   for (my $i = 0; $i < @study_ids; $i += 2 ) {
      my $study_id = $study_ids[$i];

      my $_study = GUS::Model::RAD3::Study->new
      ({ study_id => $study_id });

			eval { $_study->retrieveFromDB(); };
			if ($@) {
				 $Self->log('STUDY', $_study->getId(), 'Protected');
			}

			else {

				 #      foreach my $_studyr (sort { $a->getId() <=> $b->getId() }
				 #                         $_study->getChildren('SRes::ExternalDatabaseRelease',1)
				 #                        ) {
				 #
				 $Self->log('STUDY',
										$_study->getId()           || 'study.id?',
										sprintf($name_fmt,    $_study->getName() || 'Study.name?'),
										sprintf($description_fmt,    $_study->getDescription() || 'Study.description?'),
										#
										#                    $_studyr->getId()          || 'Studyr.id?',
										#                    sprintf($version_fmt, $_studyr->getVersion()     || 'Studyr.ver?'),
										#                    sprintf('%-24.24s',   $_studyr->getReleaseDate() || 'Studyr.rd?'),
										#                    $_studyr->getDescription() || 'Studyr.descr?'
                   );
			}
	 }
}

# ----------------------------------------------------------------------

1;
