package GUS::Community::Plugin::InsertFromCsv;

=pod

=head1 Purpose

Inserts data from CSV (comma-separated value) files into a selected GUS table.

=head1 Purpose Brief

=head1 How To Restart

=head1 Failure Cases

=head1 Notes

The input file is assumed to contain data for all columns of the table.

=cut

# ========================================================================
# ----------------------------- Declarations -----------------------------
# ========================================================================

use strict;
use vars qw( @ISA );

use lib "$ENV{GUS_HOME}/lib/perl";

@ISA = qw( GUS::PluginMgr::Plugin);

use FileHandle;
use Carp;

use CBIL::Util::Files;

use GUS::PluginMgr::Plugin;
use GUS::PluginMgr::PluginUtilities::ConstraintFunction;

# ========================================================================
# --------------------------- Required Methods ---------------------------
# ========================================================================

# --------------------------------- new ----------------------------------

sub new {
   my $Class = shift;
   my $Args  = shift;

   my $Self = bless {}, $Class;

   $Self->initialize
   ({ requiredDbVersion => '3.6',
      cvsRevision       => '$Revision: presvn-5 $',
      name              => ref($Self),
      releaseNotes      => 'added --inDelimRx',
      releaseNotes      => 'added --addGusOverhead',
      releaseNotes      => 'added support for --commit; or rather for --nocommit - does not work',
      argsDeclaration   =>
      [ fileArg  ({ descr     => 'read CSV data from these files',
                    name      => 'CsvFiles',
                    isList    => 1,
                    reqd      => 1,
                    format    => '.csv',
                    mustExist => 1,
                    constraintFunc => sub { CfIsAnything(@_) },
                  }),

        stringArg({ descr     => 'write data into this table',
                    name      => 'TableName',
                    isList    => 0,
                    reqd      => 1,
                    constraintFunc => sub { CfMatchesRx('schema(::|.)table',
                                                        '([a-zA-Z0-9_]+)(?::|\.)([a-zA-Z0-9_]+)',
                                                        @_) },
                  }),

        stringArg({ descr      => 'data is delimited with this regular expression; defaults to tab for .tab or comma',
                    name       => 'inDelimRx',
                    isList     => 0,
                    reqd       => 0,
                    constraintFunc => undef
                  }),

        integerArg({ descr     => 'write at most this many lines',
                     name      => 'MaxLinesN',
                     isList    => 0,
                     reqd      => 0,
                     constraintFunc => sub { CfIsAnything(@_) },
                   }),

        booleanArg({ descr     => 'add overhead columns',
                     name      => 'addGusOverhead',
                     isList    => 0,
                     reqd      => 0,
                     constraintFunc => undef
                   }),
      ],
      documentation     =>
      { $Self->extractDocumentationFromMyPod(),
        tablesAffected   => [
                            ],
        tablesDependedOn => [
                            ],
      }
    });

   return $Self;
}

# --------------------------------- run ----------------------------------

sub run {
    my $Self = shift;

    my $fullTableName    = $Self->getArg('TableName');
    my ($schema, $table) = split(/::|\./, $fullTableName);
    my $safeTableName    = "$schema.$table";

    my $_alg             = $Self->getAlgInvocation();
    my $alg_id           = $_alg->getId();

    my $maxRows_n        = defined $Self->getArg('MaxLinesN') ? $Self->getArg('MaxLinesN') : 1e15;
    my $rows_n           = 0;
    my $files_n          = 0;

    my $addGusOverhead_b = $Self->getArg('addGusOverhead');

    my @overhead         = ( 'SYSDATE',
                             $_alg->getUserRead(),  $_alg->getUserWrite(),
                             $_alg->getGroupRead(), $_alg->getGroupWrite(),
                             $_alg->getOtherRead(), $_alg->getOtherWrite(),
                             $_alg->getRowUserId(),
                             $_alg->getRowGroupId(),
                             $_alg->getRowProjectId(),
                             $alg_id
                           );

    my $insert_sh;

    $Self->getDb()->manageTransaction(0,'begin');

    foreach my $file (@{$Self->getArg('CsvFiles')}) {

       $files_n++;
       my $fileRow_n = 0;

       my $delim_rx  = $Self->getArg('inDelimRx');
       if (not defined $delim_rx) {
          $delim_rx = $file =~ /\.tab$/ ? "\t" : ',';
       }

       my $in_fh     = CBIL::Util::Files::SmartOpenForRead($file);
       while (<$in_fh>) {

          $fileRow_n++;
          $rows_n++;

          chomp;
          my @cols = split /$delim_rx/;

          # prepare a handle if we don't have one already.
          if (!$insert_sh) {
             my $cols_n    = scalar @cols;

             if ($addGusOverhead_b) {
                $cols_n += 11;
             }

             my $variables = join(',', ('?') x $cols_n);

             $insert_sh = $Self
             ->getQueryHandle(0)
             ->prepare("INSERT INTO $safeTableName VALUES ( $variables )");
          }

          push(@cols, @overhead) if $addGusOverhead_b;

          $insert_sh->execute( @cols );

          last if $rows_n >= $maxRows_n;

       }
       $in_fh->close();
    }

    if ($Self->getArg('commit')) {
       $Self->getDb()->manageTransaction(0,'commit');
    }

    # NOTE: this plugin should probably use $Self->getDbHandle() so as to 
    # obey the --commit arg
    $Self->getQueryHandle()->commit(); # ga no longer doing this by default
    return "Inserted $rows_n rows from $files_n files.";
}

# ========================================================================
# ---------------------------- End of Package ----------------------------
# ========================================================================

1;
