
package GUS::Community::Plugin::LoadEPCR;

=pod

=head1 Purpose Brief

Insert new EPCR results in to GUS from a file.

=head1 Purpose

This plugin reads through a file in the output format of me-PCR. It
parses each line and inserts a row for an EPCR result.  See Notes for
the format of the file.  Sequence identifiers are assumed to be
C<source_ids> and are loooked up on the fly as the file is processed.

=head1 How to Restart

Use the C<--startLine> option to indicate how many lines of the input
file to skip.

=head1 Failure Cases

A row will not be inserted if a matching sequence can not be found for
either the target or primer pair source ids (in the proper table with
the proper external_database_release_id(s)).

=head1 Notes

The data file should be in tab-delimited format.  The columns should
be in the following order:

=over 4

=item seq_id

  source id of the target sequences, e.g., the chromosome name for
  genomic sequence.

=item location

  Location on the target in FROM..TO format.

=item primer pair source_id

  This will be used to find the na_sequence_id for the primer pair
  which will then be used as the map_id in the C<DoTS.EPCR> table.

=item orientation

  Orientation of primer pair on the target sequence.  Either '(-)' or
  '(+)' format.

=back

=cut

# ========================================================================
# ----------------------------- Declarations -----------------------------
# ========================================================================

use strict;
use vars qw( @ISA );
@ISA = qw(GUS::PluginMgr::Plugin);

use FileHandle;
use DirHandle;

use GUS::Model::DoTS::EPCR;
use GUS::PluginMgr::Plugin;
use GUS::PluginMgr::PluginUtilities;

# ========================================================================
# --------------------------- Required Methods ---------------------------
# ========================================================================

# --------------------------------- new ----------------------------------

sub new {
   my ($Class) = @_;

   my $self = bless {}, $Class;

   $self->initialize
   ({ requiredDbVersion    => '3.6',
      cvsRevision          => "\$ Revision: 4885 \$",
      cvsTag               => "\$ Name: \$",
      name                 => ref($self),

      revisionNotes        => '',
      revisionNotes        => 'code cleanup',

      documentation        => 
      { $self->extractDocumentationFromMyPod(),
        tablesAffected   => [ [ 'DoTS::EPCR','One row for a primer pair EPCR result' ]
                            ],
        tablesDependedOn => [ [ 'DoTS::NaSequence', 'look for source ids in (views on) this table' ],
                            ],
      },

      argsDeclaration    =>
      [ fileArg
        ({name           => 'epcrFile',
          reqd           => 1,
          descr          => 'File name to load data from',
          constraintFunc => undef,
          mustExist      => 1,
          isList         => 0,
          format         => 'see NOTES for requirements',
         }),

        fileArg
        ({name           => 'logFile',
          reqd           => 0,
          descr          => 'log progress to this file',
          constraintFunc => undef,
          mustExist      => 0,
          isList         => 0,
          format         => 'inserted info?'
         }),

        integerArg
        ({name           => 'genomeXdbrId',
          reqd           => 1,
          descr          => 'external_database_release_id for genome and genome version used for epcr target',
          constraintFunc => undef,
          isList         => 0
         }),

        tableNameArg
        ({name           => 'genomeSubclassView',
          descr          => 'subclass view for (genome) target sequences',
          reqd           => 0,
          default        => 'DoTS::VirtualSequence',
          constraintFunc => undef,
          isList         => 0
         }),

        stringArg
        ({ name           => 'primerPairXdbrIds',
           reqd           => 1,
           descr          => 'list of external_database_release_ids for primer pairs',
           constraintFunc => undef,
           isList         => 1,
         }),

        tableNameArg
        ({name           => 'primerPairSubclassView',
          descr          => 'Subclass view for primer pairs',
          reqd           => 0,
          default        => 'DoTS::VirtualSequence',
          constraintFunc => undef,
          isList         => 0
         }),

        integerArg
        ({name           => 'testNumber',
          reqd           => 0,
          descr          => 'number of lines to process when testing',
          constraintFunc => undef,
          isList         => 0
         }),

        integerArg
        ({name           => 'startLine',
          reqd           => 0,
          descr          => 'Line number to start entering from',
          constraintFunc => undef,
          isList          => 0,
          default         => 0,
         }),
      ]
    });

   return $self;
}

# --------------------------------- run ----------------------------------

sub run {
   my $Self     = shift;

   # ------------- open files and get easy access to variables --------------

   my $epcr_f       = $Self->getArg('epcrFile');
   my $epcr_fh      = FileHandle->new("<$epcr_f") || die "File $epcr_f not opened: $!";

   my $log_f        = $Self->getArg('logFile');
   my $log_fh       = FileHandle->new(">$log_f") || die "File '$log_f' not opened: $!";

   my $genomeSv     = $Self->getArg('genomeSubclassView');  $genomeSv =~ s/::/./;
   my $genomeXdbrId = $Self->getArg('genomeXdbrId');

   my $ppSv         = $Self->getArg('primerPairSubclassView');
   my $ppXdbrIds    = join(',', @{$Self->getArg('primerPairXdbrIds')});
   my $mapTableId   = $Self->className2tableId($ppSv);
   $ppSv =~ s/::/./;

   # line counter
   my $lines_n      = 0;

   # --------- SQL statement handles for looking stuff up as we go ----------

   # na_sequence_id for target sequence
   my $naid_sql = "SELECT distinct sv.na_sequence_id FROM $genomeSv sv WHERE sv.source_id = ? AND sv.external_database_release_id = $genomeXdbrId";
   $Self->log('SQL', 'TargetLookup', $naid_sql);
   my $naid_sh = $Self->getQueryHandle()->prepare($naid_sql);

   # na_sequence_id for primer pair
   my $map_sql = "SELECT na_sequence_id FROM $ppSv sv WHERE sv.source_id = ? AND sv.external_database_release_id in ($ppXdbrIds)";
   $Self->log('SQL', 'PrimerLookup', $map_sql);
   my $map_sh  = $Self->getQueryHandle()->prepare($map_sql);

   # -------------------------- file reading loop ---------------------------

   while (<$epcr_fh>) {

      # skip lines until we reach the part we want to process.
      $lines_n++;
      next if $lines_n < $Self->getArg('startLine');

      # assume we'll be ok.
      my $error_b = 0;

      # parse line
      my @cols = split /\s+/;

      my ( $seq_id, $loc, $source_id, $orientation ) = @cols;
      my $is_reversed_b    = $orientation eq '(-)' ? 1 : 0;
      my @locs             = split /\.\./, $loc;

      # get the map id for the primer pair.
      my ($map_id)         = $Self->sqlAsArray( Handle => $map_sh,  Bind => [ $source_id ]);

      # check for DTs, but otherwise look this up.
      my $na_sequence_id;
      if ($seq_id =~ /^DT\.(\d+)$/) {
         $na_sequence_id = $1;
      }

      else {
         ($na_sequence_id) = $Self->sqlAsArray( Handle => $naid_sh, Bind => [ $seq_id ]);
      }

      # error checking
      if (!defined $na_sequence_id) {
         $Self->log('ERROR', $lines_n, 'bad sequence source_id', $seq_id);
         $error_b = 1;
      }

      if (!defined $map_id) {
         $Self->log('ERROR', $lines_n, 'bad tile source_id', $source_id);
         $error_b = 1;
      }

      # proceed if no errors.
      if (!$error_b) {
         my %_epcr = ( map_table_id      => $mapTableId,
                       map_id            => $map_id,
                       na_sequence_id    => $na_sequence_id,
                       seq_subclass_view => $ppSv,
                       start_pos         => $locs[0],
                       stop_pos          => $locs[1],
                       is_reversed       => $is_reversed_b,
                     );
         print $log_fh join("\t", 'SUBMITTED', $lines_n,
                            map { $_epcr{$_} } sort keys %_epcr
                           ), "\n";

         my $_epcr = GUS::Model::DoTS::EPCR->new(\%_epcr);
         $_epcr->submit();

         $Self->undefPointerCache();
      }

      last if (defined $Self->getArg('testNumber') && $lines_n >= $Self->getArg('testNumber'));

      $Self->log('ENTERED', $lines_n) if ($lines_n % 1000 == 0);
   } #end while()

   $Self->log('ENTERED', $lines_n);

   return "Entered $lines_n.";
}

# ========================================================================
# ---------------------------- End of Package ----------------------------
# ========================================================================

1;

__END__

=pod

=head1 Obsoleted Arguments

        stringArg({name => 'dir',
                   reqd => 1,	
                   descr => 'Working directory',
                   constraintFunc => undef,
                   isList => 0
                  }),

=cut
