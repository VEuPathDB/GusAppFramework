
#vvvvvvvvvvvvvvvvvvvvvvvvv GUS4_STATUS vvvvvvvvvvvvvvvvvvvvvvvvv
  # GUS4_STATUS | SRes.OntologyTerm              | auto   | absent
  # GUS4_STATUS | SRes.SequenceOntology          | auto   | absent
  # GUS4_STATUS | Study.OntologyEntry            | auto   | absent
  # GUS4_STATUS | SRes.GOTerm                    | auto   | absent
  # GUS4_STATUS | Dots.RNAFeatureExon            | auto   | absent
  # GUS4_STATUS | RAD.SageTag                    | auto   | absent
  # GUS4_STATUS | RAD.Analysis                   | auto   | absent
  # GUS4_STATUS | ApiDB.Profile                  | auto   | absent
  # GUS4_STATUS | Study.Study                    | auto   | absent
  # GUS4_STATUS | Dots.Isolate                   | auto   | absent
  # GUS4_STATUS | DeprecatedTables               | auto   | absent
  # GUS4_STATUS | Pathway                        | auto   | absent
  # GUS4_STATUS | DoTS.SequenceVariation         | auto   | absent
  # GUS4_STATUS | RNASeq Junctions               | auto   | absent
  # GUS4_STATUS | Simple Rename                  | auto   | absent
  # GUS4_STATUS | ApiDB Tuning Gene              | auto   | absent
  # GUS4_STATUS | Rethink                        | auto   | absent
  # GUS4_STATUS | dots.gene                      | manual | unreviewed
die 'This file has broken or unreviewed GUS4_STATUS rules.  Please remove this line when all are fixed or absent';
#^^^^^^^^^^^^^^^^^^^^^^^^^ End GUS4_STATUS ^^^^^^^^^^^^^^^^^^^^
package GUS::Community::PluginParasite;

=pod

=head1 Purpose

A superclass used to make other packages appears as though they are a
plugin.  This package has a Plugin attribute and and AUTOLOAD method
that passes all unhandled method calls to the plugin.

Subclasses of C<GUS::Community::PluginParasite> should not have a C<new>
method.  They should have an C<init> method, though this is only
necessary if they have additional attributes besides the C<Plugin>
they get from this class.

=cut

# ----------------------------------------------------------------------

use strict;

use vars qw( $AUTOLOAD );

# ======================================================================
# ------------------------- CLASS METHODS ------------------------------
# ======================================================================

sub Pod2Text { GUS::PluginMgr::Plugin::Pod2Text(@_) }

# ======================================================================
# ------------------------- OBJECT METHODS -----------------------------
# ======================================================================

sub new {
   my $Class = shift;
   my $Args  = ref $_[0] ? shift : {@_} ;

   my $self = bless {}, $Class;

   $self->setPlugin               ( $Args->{Plugin              } );

   $self->init($Args);

   return $self;
}

# ----------------------------------------------------------------------

sub init {
   my $Self = shift;
   my $Args = shift;

   return $Self;
}

# ----------------------------------------------------------------------

sub getPlugin               { $_[0]->{'Plugin'                      } }
sub setPlugin               { $_[0]->{'Plugin'                      } = $_[1]; $_[0] }

# ----------------------------------------------------------------------

# -------------------------------- Notes -------------------------------

# The default note method returns the source code of the method which
# should contain pod text.

sub Notes {
   my $Self = shift;

   my $Rv;

   if (my $_f = $INC{ref($Self). '.pm'}) {
      $Rv = `cat $_f`;
   }

   return $Rv
}

# ----------------------------------------------------------------------

sub AUTOLOAD {
   my $Self = shift;

   my @parts = split('::', $AUTOLOAD);
   my $method = pop @parts;

   if ($Self) {
      my $selfType = ref $Self;
      if ($selfType =~ /::/) {
         if (my $plugin = $Self->getPlugin()) {
            if ($plugin->can($method)) {
               return $plugin->$method(@_);
            }

            else {
               die join("\t",
                        ref $Self,
                        "Request for a method '$method' ($AUTOLOAD) that a plugin can not do."
                       );
            }
         }
         else {
            die join("\t",
                     ref $Self,
                     "Tried to AUTOLOAD method '$method' to my plugin, but no plugin was set."
                    );
         }
      }
      else {
         die join("\t",
                  __PACKAGE__,
                  "Tried to AUTOLOAD method '$method' on non-object argument, $Self.",
                 );
      }
   }
   else {
      die join("\t",
               __PACKAGE__,
               "Tried to AUTOLAOD method '$method' ($AUTOLOAD) without a Self."
              );
   }
}

# ======================================================================
# ------------------ ARGUMENT CONVERSION ROUTINES ----------------------
# ======================================================================

=pod

=head2 getFlexId

Helps methods be somewhat polymorphic by easing the conversion from
objects to ids, i.e., using this method, methods can easily take
either a GUS object or an id.

=cut

sub getFlexId {
	 my $Self    = shift;
	 my $ObjOrId = shift;

	 my $Rv = ref $ObjOrId ? $ObjOrId->getId() : $ObjOrId;

	 return $Rv;
}

=pod

=head2 getFlexIdList

Like C<getFlexId> but allows a list and returns values in ( , , ... )
form.

=cut

sub getFlexIdList {
	 my $Self    = shift;
	 my $ObjOrId = shift;

	 my $ooiList = ref $ObjOrId eq 'ARRAY' ? $ObjOrId : [ $ObjOrId ];

	 my $Rv = [ map { $Self->getFlexId($_) } @$ooiList ];

	 return $Rv;
}

# ----------------------------------------------------------------------

=pod

=head2 cvtAnatomyNameToId

Converts an anatomy name to anatomy_id.

=cut

sub cvtTissueNameToId {
	 my $Self   = shift;
	 my $Tissue = shift;

	 my $Rv;

	 if ($Tissue =~ /^\d+$/) {
			$Rv = $Tissue;
	 }

	 else {
			my $sql = "select anatomy_id from SRes.Anatomy where name = '$Tissue'";
			($Rv) = @{$Self->sql_get_as_array($sql)};
	 }

	 return $Rv;
}

# ----------------------------------------------------------------------

1;
