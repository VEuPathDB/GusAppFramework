
package GUS::Common::PluginParasite;

=pod

=head1 Purpose

A superclass used to make other packages appears as though they are a
plugin.  This package has a Plugin attribute and and AUTOLOAD method
that passes all unhandled method calls to the plugin.

Subclasses of C<GUS::Common::PluginParasite> should not have a C<new>
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
   my $Args  = shift || {};

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
                        "Request for an unsupported method '$method' ($AUTOLOAD)"
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
