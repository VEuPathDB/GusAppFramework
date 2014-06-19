
package GUS::Community::Plugin::Report::ListRadStudies;
@ISA = qw(GUS::PluginMgr::Plugin);

# ----------------------------------------------------------------------

use strict;

use FileHandle;
use V;

use GUS::PluginMgr::Plugin;

use GUS::PluginMgr::PluginUtilities::ConstraintFunction;
use GUS::PluginMgr::PluginUtilities;

use GUS::Model::Study::Study;

# ======================================================================

sub new {
   my $Class = shift;

   my $self = bless {}, $Class;

   my $selfPodCommand = 'pod2text '. __FILE__;
   my $selfPod        = `$selfPodCommand`;

   $self->initialize
   ({ requiredDbVersion => '3.6',
      cvsRevision       => ' $Revision: 2892 $ ',
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

  This plugin lists RAD.Studies and dependent info

Purpose
        purposeBrief     => 'List RAD.Studies',
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

   my $name_fmt        = '%s';
	 my $description_fmt = '%s';

   my $sql = 'select study_id from Study.Study where user_read = 1 and group_read = 1 and other_read = 1 order by name';
   my @study_ids = @{$Self->sql_get_as_array($sql)};

   for (my $i = 0; $i < @study_ids; $i += 2 ) {
      my $study_id = $study_ids[$i];

      my $_study = GUS::Model::Study::Study->new
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
										sprintf($name_fmt,           $_study->getName() || 'Study.name?'),
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
