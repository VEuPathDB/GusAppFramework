#!@perl@

# -----------------------------------------------------------------------
# Sequence.pm
#
# Perl object that represents an Oracle sequence.
#
# Created: Mon Jul  2 15:09:52 EST 2001
# 
# Jonathan Crabtree
#
# $Revision$ $Date$ $Author
# -----------------------------------------------------------------------

package Sequence;

use strict;
use Util;

# -----------------------------------------------------------------------
# Constructor
# -----------------------------------------------------------------------

sub new {
    my($class, $args) = @_;

    my $self = {
	owner => $args->{owner},
	name => $args->{name},
	db => $args->{db},
    };

    bless $self, $class;
    return $self;
}

# -----------------------------------------------------------------------
# Sequence
# -----------------------------------------------------------------------

# Generate the SQL required to recreate this object.
#
# startWith  reset the sequence to this value if defined
#
sub getSQL {
    my($self, $dbh, $startWith) = @_;

    my $owner = $self->{owner};
    my $name = $self->{name};

    my $sql = ("select * from all_sequences " .
	       "where sequence_owner = UPPER('$owner') " . 
	       "and sequence_name = UPPER('$name') ");

    my $rows = &Util::execQuery($dbh, $sql, 'hash');
    my $row = $rows->[0];

    my $minVal = $row->{min_value};
    my $maxVal = $row->{max_value};
    my $inc = $row->{increment_by};
    my $last = $row->{last_number};
    my $cacheSize = $row->{cache_size};

    my $start = $last;
    $start = $startWith if (defined($startWith));
    $maxVal = undef if ($maxVal >= 1e+27);

    my $createSql = '';

    if ($owner =~ /^&&/) {
	$createSql .= "CREATE SEQUENCE $owner..$name";
    } else {
	$createSql .= "CREATE SEQUENCE $owner.$name";
    }

    $createSql .= " START WITH $start" if (defined($start));
    $createSql .= " INCREMENT BY $inc" if (defined($inc));
    $createSql .= " CACHE $cacheSize" if (defined($cacheSize));
    $createSql .= " MAXVALUE $maxVal" if (defined($maxVal));
    $createSql .= " MINVALUE $minVal" if (defined($minVal));
    $createSql .= ";";

    return $createSql;
}

1;

