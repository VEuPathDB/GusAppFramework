#!@perl@

# -----------------------------------------------------------------------
# Util.pm
#
# A set of subroutines useful in manipulating an Oracle db.
#
# Created: Tue Feb 20 14:29:32 EST 2001
#
# Jonathan Crabtree
#
# $Revision$ $Date$ $Author$
# -----------------------------------------------------------------------

package GUS::DBAdmin::Util;

use DBI;
use DBD::Oracle;

# -----------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------

my $DEBUG = 0;

# -----------------------------------------------------------------------
# Informative messages
# -----------------------------------------------------------------------

sub printDate {
    my $date = `date`;
    chomp($date);
    print $date, "\n";
}

# -----------------------------------------------------------------------
# DBI utility routines
# -----------------------------------------------------------------------

# Prompt user for a password and create a DBI connection.
#
sub establishLogin {
    my($user, $dbiStr, $dbAtts, $password) = @_;

    # ora_session_mode must be set for sys logins
    if ($user =~ /^sys$/i) {
	$dbAtts->{ora_session_mode} = 2;
    }

    while($password =~ /^\s*$/) {
	print "Enter password for $user: ";
	$password = <STDIN>;
	chomp($password);
    }

    my $dbh = DBI->connect($dbiStr, $user, $password, $dbAtts);
    return $dbh;
}

# $returnMode  'array' - arrayref of arrayrefs
#              'hash' - arrayref of hashrefs
#              'scalar' - arrayref of scalar values, only if 1 column
#
sub execQuery {
    my($dbh, $sql, $returnMode) = @_;
    my $rows = [];

    print "execQuery: sql = '$sql'\n" if ($DEBUG);
    
    my $sth = $dbh->prepare($sql);
    $sth->execute();

    if ($returnMode =~ /array/i) {
	while(my $a = $sth->fetchrow_arrayref) {
	    my @copy = @$a;
	    push(@$rows, \@copy);
	}
    } elsif ($returnMode =~ /hash/i) {
	while(my $a = $sth->fetchrow_hashref('NAME_lc')) {
	    my %copy = %$a;
	    push(@$rows, \%copy);
	}
    } elsif ($returnMode =~ /scalar/i) {
	while(my @a = $sth->fetchrow_array) {
	    push(@$rows, $a[0]);
	}
    } else {
	die "Illegal return mode '$returnMode' in execQuery";
    }

    $sth->finish();
    return $rows;
}

1;
