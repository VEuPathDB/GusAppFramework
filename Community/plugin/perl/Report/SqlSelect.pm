
package GUS::Community::Plugin::Report::SqlSelect;
@ISA = qw(GUS::PluginMgr::Plugin);

# ----------------------------------------------------------------------

use strict;

use FileHandle;

use GUS::PluginMgr::Plugin;

use GUS::PluginMgr::PluginUtilities::ConstraintFunction;
use GUS::PluginMgr::PluginUtilities;


# ======================================================================

sub new {
   my $Class = shift;

   my $self = bless {}, $Class;

   $self->initialize
   ({ requiredDbVersion => '3.6',
      cvsRevision       => ' $Revision: 2892 $ ',
      name              => ref($self),

      # just expand
      revisionNotes     => '',
      revisionNotes     => 'initial creation and testing',

      # ARGUMENTS
      argsDeclaration   =>
      [ globArg  ({ name           => 'SqlGlob',
                    descr          => 'read single SQL command from each file that matches these descriptions',
                    reqd           => 1,
                    isList         => 1,
                    constraintFunc => sub { CfIsAnything(@_) },
                    mustExist      => 1,
                    format         => [ '.sql' ],
                  }),
      ],

      # DOCUMENTATION
      documentation     =>
      { purpose          => <<Purpose,

  Execute a series of SQL queries.

Purpose
        purposeBrief     => 'Execute SQL queries',
        tablesAffected   =>
        [ ],
        tablesDependedOn =>
        [
        ],
        howToRestart     => 'just restart; this is a reader',
        failureCases     => 'just run again',
        notes            => join("\n",
                                 GUS::PluginMgr::Plugin::Pod2Text(__FILE__),
                                ),
      },
    });

   # RETURN
   $self
}

# ======================================================================

sub run {
   my $Self       = shift;

   my @sql_f = map { glob($_) } @{$Self->getArg('SqlGlob')};

   foreach my $sql_f (@sql_f) {
      $Self->log('INFO', 'SqlFile', $sql_f);

      if (my $sql_fh = FileHandle->new("<$sql_f")) {
         my $sql = join('', map { chomp; $_ } <$sql_fh>);
         $sql_fh->close();

         $Self->logWrap('SQL', $sql);

         my $tab_f = $sql_f. '.tab';
         if (my $tab_fh = FileHandle->new(">$tab_f")) {

            my $rows_n = 0;

            my $_sh = $Self->getQueryHandle()->prepareAndExecute($sql);
            while (my @row = $_sh->fetchrow_array()) {
               print $tab_fh join("\t", @row), "\n";
               $rows_n++;
            }
            $_sh->finish();

            $Self->log('INFO', 'RowsN', $rows_n);

         }

         else {
            $Self->log('ERROR', 'NoTabOpen', $tab_f, $!);
         }
      }

      else {
         $Self->log('ERROR', 'NoSqlOpen', $sql_f, $!);
      }
   }

}

# ----------------------------------------------------------------------

1;
