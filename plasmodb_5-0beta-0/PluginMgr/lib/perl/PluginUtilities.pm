
package GUS::PluginMgr::PluginUtilities;

# ----------------------------------------------------------------------

use strict;

use GUS::PluginMgr::PluginUtilities::ConstraintFunction;

# ======================================================================

sub logEnter {
   my $Plugin = shift;

   my ($package,$filename,$line,$subroutine) = caller(1);

   $Plugin->logVerbose(ref $Plugin, 'CALL', '>>>>', $subroutine, @_);
}

sub logExit {
   my $Plugin = shift;

   my ($package,$filename,$line,$subroutine) = caller(1);

   $Plugin->logVerbose(ref $Plugin, 'CALL', '<<<<', $subroutine, @_);
}

# ======================================================================

=pod

=head1 Constraint Checking Functions

These are class methods that typically take a single value to be
checked against a constraint.

=cut

my $MSG_KeyValuePairFormat = q{Key-Value pair format is _key_=_value_, e.g., 'name=Fred', not '%s'.};
my $MSG_NotHashKey         = q{The value '%s' must be one of these values: %.};

# ----------------------------------------------------------------------

sub PuConstraintAnything {
	 return undef;
}

sub PuConstraintXdbSpec {
	 my $XdbSpec = shift;

	 return ( $XdbSpec =~ /^.+::.+$/
						? undef
						: q{must match format _database_name_::_version_, e.g., DoTS::V6}
					);
}

sub PuConstraintIsPositive {
	 my $Distance = shift;

	 return ( $Distance >= 0
						? undef
						: 'Must be >= 0'
					);
}

sub PuConstraintKeyValuePair
{	 my $KeyValuePair = shift;

	 eval {
			$@ = undef;
			PuParseKeyValuePair($KeyValuePair)
	 };

	 return $@;
}

sub PuParseKeyValuePair {
	 my $Args = shift;

   my $RV   = {};

   my @kvps = ref $Args ? @$Args : ($Args);

   foreach (@kvps) {
      my @parts = $_ =~ /^(.+?)=(.+)$/;
      if (scalar @parts == 2) {
         $RV->{$parts[0]} = $parts[1];
      }
      else {
         die sprintf($MSG_KeyValuePairFormat, $_);
      }
   }

   return $RV;
}

sub PuConstraintIsHashKey {
   my $Hash   = shift;
   my @Values = ref $_[0] ? @$_[0] : @_;

   foreach my $value (@Values) {
      if (not exists $Hash->{$value}) {
         return sprintf($MSG_NotHashKey, $value,
                        join(', ', map {"'$_'"} sort keys %$Hash)
                       );
      }
   }

   return undef;
}

# ======================================================================

my $MSG_TooManyXdbs = q{Found too many SRes.ExternalDatabases for '%s'.};
my $MSG_NoXdbs      = q{Found no SRes.ExternalDatabases for '%s', parsed as '%s' and '%s'.};

#======================================================================
=pod

=head1 C<puGetXdbrId>

Parses a database and version specification then executes SQL to get
the C<SRes.ExternalDatabaseRelease.external_database_release_id>.

Specification is '/' delimited I<database>/I<version>.

=cut

sub getXdbrIdFromSpec {
   my $Plugin = shift;
   my $Spec = shift;

   my @RV;

   my $spec = GUS::PluginMgr::PluginUtilities::ConstraintFunction::ParseXdbSpec($Spec);

   # name/version
   if (ref $spec eq 'ARRAY') {
      my ($name, $version) = @$spec;

      my $_sql =
      qq{
     SELECT sedr.external_database_release_id
     FROM   SRes.ExternalDatabase        sed
     ,      SRes.ExternalDatabaseRelease sedr
     WHERE  sed.name                 = '$name'
     AND    sedr.version             = '$version'
     AND    sed.external_database_id = sedr.external_database_id
     };

      eval {
         my $_sh = $Plugin->getQueryHandle()->prepareAndExecute($_sql);
         while (my ($xdb_id) = $_sh->fetchrow_array()) {
            push(@RV, $xdb_id);
         }
         $_sh->finish();
      };

      if ($@) {
         $Plugin->log($_sql);
         die $@;
      }
   }

   # direct specification
   else {
      @RV = ($spec);
   }

   if (@RV == 1) {
      return $RV[0];
   }

   elsif (@RV == 0) {
      die sprintf($MSG_NoXdbs, $Spec);
   }

   else {
      die sprintf($MSG_TooManyXdbs, $Spec);
   }
}

# ----------------------------------------------------------------------

1;
