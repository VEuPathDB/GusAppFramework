
package GUS::Community::Plugin::MakeDtd;
@ISA = qw(GUS::PluginMgr::Plugin);

# ----------------------------------------------------------------------

=pod

=head1 Purpose


=cut

# ---------------------------------------------------------------------

use strict;

use FileHandle;

use CBIL::Util::Disp;
use CBIL::Util::V;

use GUS::PluginMgr::Plugin;

use GUS::PluginMgr::PluginUtilities::ConstraintFunction;

# ----------------------------------------------------------------------

# ======================================================================

sub new {
   my $Class = shift;

   my $self = bless {}, $Class;

   my $selfPodCommand = 'pod2text '. __FILE__;
   my $selfPod        = `$selfPodCommand`;

   $self->initialize
   ({ requiredDbVersion => {},
      cvsRevision       => ' $Revision$ ',
      cvsTag            => ' $Name$ ',
      name              => ref($self),

      # just expand
      revisionNotes     => '',
      revisionNotes     => 'initial creation and testing',

      # ARGUMENTS
      argsDeclaration   =>
      [ stringArg ({ name           => 'RootTableName',
                     descr          => 'make a DTD for this table',
                     reqd           => 1,
                     isList         => 0,
                     constraintFunc => sub { CfIsAnything() },
                   }),

        booleanArg({ name           => 'Attributes',
                     descr          => 'when true DTD will include columns as attributes',
                     reqd           => 0,
                     isList         => 0,
                     constraintFunc => sub { CfIsAnything(@_) },
                     default        => 1,
                   }),

        booleanArg({ name           => 'Overhead',
                     descr          => 'when true DTD will include overhead columns',
                     reqd           => 0,
                     isList         => 0,
                     constraintFunc => sub { CfIsAnything(@_) },
                     default        => 1,
                   }),

        integerArg({ name           => 'Depth',
                     descr          => 'follow child tables to this depth',
                     reqd           => 0,
                     isList         => 0,
                     constraintFunc => sub { CfIsPositive(@_) },
                     default        => 1,
                   }),

        integerArg({ name           => 'LongStrings',
                     descr          => 'columns with type string that longer than are elements',
                     reqd           => 0,
                     isList         => 0,
                     constraintFunc => sub { CfIsPositive(@_) },
                     default        => 64,
                   }),

      ],

      # DOCUMENTATION
      documentation     =>
      { purpose          => <<Purpose,

  This plugin creates a DTD for a table.

Purpose
        purposeBrief     => 'make DTD for a GUS table',
        tablesAffected   =>
        [ ],
        tablesDependedOn =>
        [ ],
        howToRestart     => 'just restart; this is a reader',
        failureCases     => 'just run again',
        notes            => $selfPod,
      },
    });

   # RETURN
   $self
}

# ----------------------------------------------------------------------

sub run {
   my $Self       = shift;

	 $Self->logArgs() if $Self->getArgs()->{debug};

   $Self->_doTable($Self->getArgs()->{RootTableName}, {}, 0);

}

# ----------------------------------------------------------------------

sub _doTable {
   my $Self  = shift;
   my $Table = shift;
   my $Seen  = shift;
   my $Depth = shift;

   return if $Seen->{$Table};
   return if $Depth > $Self->getArgs()->{Depth};

   $Seen->{$Table} = 1;

   my $_db = $Self->getDb();

   my $table = $Table; $table =~ s/GUS::Model:://;
   my $file  = $table; $file =~ s/::/_/;

   my $perl = "use GUS::Model::${table}_Table; GUS::Model::${table}_Table->new('$table',\$_db)";

   $Self->log('INFO', 'Perl', $perl) if $Self->getArgs()->{debug};
   my $_obj = eval $perl;
   if ($@) {
      $Self->log('FATAL', 'CantMakeObject', "could not use or make $table", $@);
      die $@;
   }

   my $attList = $_obj->{attInfo};
   CBIL::Util::Disp::Display($attList) if $Self->getArgs()->{debug};
   my $w = CBIL::Util::V::max(map { length $_->{col} } @$attList);

   my @children = map { s/GUS::Model::// ; $_} $_obj->getChildList();

   my @attDeclarations;
   my @eleDeclarations;

   my $overhead_b = 0;

   for (my $att_i = 0; $att_i < @$attList; $att_i++) {
      my $att = $attList->[$att_i];

      my $isAtt_b = $Self->getArgs()->{Attributes};

      $overhead_b = 1 if $att->{col} eq 'modification_date';

      last if ($overhead_b && !$Self->getArgs()->{Overhead});

      $isAtt_b = 0 if ($att->{type} eq 'CLOB');
      $isAtt_b = 0 if ($att->{type} eq 'VARCHAR2' && $att->{length} >= $Self->getArgs()->{LongStrings});

      if ($isAtt_b) {
         my $value = $att->{Nulls} || $att_i == 0 || $overhead_b ? '#IMPLIED' : '#REQUIRED';

         push(@attDeclarations, 
              sprintf("%-${w}.${w}s CDATA %s",
                      $att->{col},
                      $value
                     )
             );
      }

      # prepare as an element
      else {
         my $declaration;

         my $name = $att->{col};

         my $repeats = $att->{Nulls} || $att_i == 0 || $overhead_b ? '?' : '';

         $declaration = { name => $name, repeats => $repeats };

         push(@eleDeclarations, $declaration);
      }
   }

   if ($Depth < $Self->getArgs()->{Depth}) {
      foreach my $child (@children) {
         push(@eleDeclarations, { name    => $child,
                                  repeats => '*',
                                  table   => 1,
                                }
             );
      }
   }

   my $eleDeclarations = @eleDeclarations
   ? '('. join(',', map { "$_->{name}$_->{repeats}" } @eleDeclarations). ')'
   : '';

   print "\n\n";
   print "<!-- ...................................................................... -->\n";
   print "<!ELEMENT $table $eleDeclarations>\n";

   foreach my $decl (@attDeclarations) {
      printf "  <!ATTLIST $table %s>\n", $decl;
   }

   foreach my $decl (grep { $_->{table} == 0 } @eleDeclarations) {
      printf "  <!ELEMENT %-${w}.${w}s (#CDATA)>\n", $decl->{name};
   }

   foreach my $child (@children) {
      $Self->_doTable($child, $Seen, $Depth+1);
   }
}

# ----------------------------------------------------------------------

1;
