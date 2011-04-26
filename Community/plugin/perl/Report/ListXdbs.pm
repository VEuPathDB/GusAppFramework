
package GUS::Community::Plugin::Report::ListXdbs;
@ISA = qw(GUS::PluginMgr::Plugin);

# ----------------------------------------------------------------------

use strict;

use FileHandle;

use GUS::PluginMgr::Plugin;

use GUS::PluginMgr::PluginUtilities::ConstraintFunction;
use GUS::PluginMgr::PluginUtilities;

use GUS::Model::SRes::ExternalDatabase;

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
      [ booleanArg ({ name       => 'pad',
                      descr      => 'show usage information about the plugins',
                      reqd       => 0,
                      isList     => 0,
                      constraintFunc => sub { CfIsAnything(@_) },
                    }),
      ],

      # DOCUMENTATION
      documentation     =>
      { purpose          => <<Purpose,

  This plugin lists SRes.ExternalDatabases and their releases.

Purpose
        purposeBrief     => 'List SRes.ExternalDatabase',
        tablesAffected   =>
        [ ],
        tablesDependedOn =>
        [
         [ 'SRes.ExternalDatabase',        'duh!' ],
         [ 'SRes.ExternalDatabaseRelease', 'duh!' ],
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

	 #$Self->logArgs();

   my $name_fmt    = '%s';
   my $version_fmt = '%s';

   if ($Self->getArg('pad')) {
      my $sql = 'select max(length(name)) from SRes.ExternalDatabase';
      my ($w) = @{$Self->sql_get_as_array($sql)};
      $name_fmt = "%-${w}.${w}s";

      my $sql = 'select max(length(version)) from SRes.ExternalDatabaseRelease';
      my ($w) = @{$Self->sql_get_as_array($sql)};
      $version_fmt = "%-${w}.${w}s";
   }

   my $sql = 'select external_database_id,name from SRes.ExternalDatabase order by name';
   my @xdb_ids = @{$Self->sql_get_as_array($sql)};

   for (my $i = 0; $i < @xdb_ids; $i += 2 ) {
      my $xdb_id = $xdb_ids[$i];

      my $_xdb = GUS::Model::SRes::ExternalDatabase->new
      ({ external_database_id => $xdb_id });
      $_xdb->retrieveFromDB();

      foreach my $_xdbr (sort { $a->getId() <=> $b->getId() }
                         $_xdb->getChildren('SRes::ExternalDatabaseRelease',1)
                        ) {

         $Self->log('XDBR',
                    $_xdb->getId()           || 'xdb.id?',
                    sprintf($name_fmt,    $_xdb->getName() || 'Xdb.name?'),

                    $_xdbr->getId()          || 'Xdbr.id?',
                    sprintf($version_fmt, $_xdbr->getVersion()     || 'Xdbr.ver?'),
                    sprintf('%-24.24s',   $_xdbr->getReleaseDate() || 'Xdbr.rd?'),
                    $_xdbr->getDescription() || 'Xdbr.descr?'
                   );
      }
   }
}

# ----------------------------------------------------------------------

1;
