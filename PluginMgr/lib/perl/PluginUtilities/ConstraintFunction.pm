
package GUS::PluginMgr::PluginUtilities::ConstraintFunction;

@ISA = qw( Exporter );

@EXPORT = qw( &CfIsAnything &CfIsDirectory &CfIsXdbSpec
              &CfIsPositive &CfIsHashKey &CfIsOneOfThese
              &CfIsAlphaNumeric
            );

# ======================================================================

use strict;

# ----------------------------------------------------------------------

sub evaluate {
   my $Message = shift;
   my $Test    = shift;
   my $Values  = shift;

   my $Rv;

   my %errors;

   my @Values = ref $_[0] ? @$_[0] : @_;
   foreach my $value (@Values) {
      $errors{$value} = 1 if $Test->($value);
   }

   if (%errors) {
      my $Rv = sprintf($Message,
                       sort keys %errors
                      );
   }

   return $Rv;
}

=pod

=head1 CfIsAnything

This constraint is no constraint at all.

=cut

sub CfIsAnything {
	 return undef;
}


=pod

=head1 CfIsDirectory

This constraint makes sure the value is a directory.

=cut

sub CfIsDirectory {
   evaluate('%s are not directories',
            sub { return ! -d $_[0] },
            @_
           );
}

=pod

=head1 CfIsXdbSpec

Ensres

=cut

sub CfIsXdbSpec {
   evaluate('%s are not in _database_name_::_version_ format, e.g., "DoTS::V6"',
            sub { return $_[0] !~ /^.+::.+$/; },
            @_
           );
}

sub CfMatchesRx {
	 my $UserRx = shift;
	 my $RealRx = shift;

	 evaluate("'%s' does not match regular expression, $UserRx",
						sub { return $_[0] !~ /$RealRx/; },
						@_
					 );
}

sub CfIsAlphaNumeric {
   evaluate('%s is not alphanumeric word; must contain only a-z, A-Z, 0-9, _, or -',
            sub { return $_[0] !~ /^[a-zA-z0-9-_]+$/; },
            @_
           );
}

sub CfIsPositive {
   evaluate('%s not strictly positive, i.e., > 0',
            sub { return $_[0] <= 0 },
            @_
           );
}

sub CfIsHashKey {
   my $Hash   = shift;

   evaluate(sprintf('%%s are not in legal list: %s',
                    join(',', sort keys %$Hash)
                   ),
            sub { return not defined $Hash->{$_[0]} },
            @_
           );
}

=pod

=head2 CfIsOneOfThese

Makes sure the values are in a list ref or hash ref of possible
values.

=cut

sub CfIsOneOfThese {
   my $These   = shift;

	 $These = { map {($_ => 1)} @$These } if ref $These eq 'ARRAY';

   evaluate(sprintf('%%s are not in legal list: %s',
                    join(',', sort keys %$These)
                   ),
            sub { return not defined $These->{$_[0]} },
            @_
           );
}

# ----------------------------------------------------------------------

1;

