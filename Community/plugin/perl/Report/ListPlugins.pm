
package GUS::Community::Plugin::Report::ListPlugins;
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
       booleanArg ({ name       => 'Info',
                     descr      => 'show usage information about the plugins',
                     reqd       => 0,
                     isList     => 0,
                     constraintFunc => sub { CfIsAnything(@_) },
                   }),

       stringArg  ({ name       => 'MatchRx',
                     descr      => 'show plugins that match this regular expression',
                     reqd       => 0,
                     isList     => 0,
                     constraintFunc => sub { CfIsAnything(@_) },
                     default    => '.',
                   }),
      ],

      # DOCUMENTATION
      documentation     =>
      { purpose          => <<Purpose,

  Lists Core.Algorithm entries that appear to be plugins.

Purpose
        purposeBrief     => 'List plugins',
        tablesAffected   =>
        [ ],
        tablesDependedOn =>
        [
         [ 'Core.Algorithm',               'duh!' ],
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

   my $sql = "select name from Core.Algorithm where name like '%::Plugin::%'";
   my @plugins = @{$Self->sql_get_as_array($sql)};

   my $match_rx = $Self->getArg('MatchRx');

   map {

      if ($Self->getArg('Info')) {
         $Self->log('-'x7, '-'x80);
      }

      $Self->log('Plugin', $_);

      if ($Self->getArg('Info')) {
         eval qq{
                 use $_;
                 my \$_pu = $_->new();
                 \$_pu->printDocumentationText();
                };
         if ($@) {
            $Self->log('WARN', 'NoUse', $_, $@);
         }
      }

   } grep { $_ =~ /$match_rx/ }
   sort { uc $a cmp uc $b } @plugins;

}

# ----------------------------------------------------------------------

1;
