#!@perlLocation@

# -----------------------------------------------------------------------
# fixRADViews.pl
#
# Fix the broken views in RAD.
#
# Created: Mon Jul  2 13:24:37 EST 2001
#
# Jonathan Crabtree
#
# $Revision$ $Date$ $Author$
# -----------------------------------------------------------------------

use strict;
use Database;
use Schema;
use Table;

use Getopt::Long;

use FileHandle;

# -----------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------

my $DB_SID = "gusdev";
my $DB_HOST = "localhost";
my $DBI_ATTS = { RaiseError => 0, AutoCommit => 0, LongReadLen => 10000000 };


# -----------------------------------------------------------------------
# Input
# -----------------------------------------------------------------------

my(
   $login,
   $schema,
   $listonly
   );

&GetOptions("login=s" => \$login,
	    "schema=s" => \$schema,
	    "listonly!" => \$listonly
	    );

if (!$login || !$schema) {
    print <<USAGE;
Usage: fixRADViews.pl options
  --login=login          # Oracle login
  --schema=owner         # schema whose views are suspect
  --listonly=true/false  # list broken views but do not fix them
USAGE
    die "Invalid arguments";
}

# -----------------------------------------------------------------------
# Main program
# -----------------------------------------------------------------------

$| = 1;

my $db = Database->new({sid => $DB_SID, host => $DB_HOST});
my $dbh = &Util::establishLogin($login, $db->getDbiStr(), $DBI_ATTS);
my $s = Schema->new({name => $schema});

# Search through views for bad ones
#
my $nBadViews = 0;
my $views = $s->getViews($dbh);
foreach my $vname (@$views) {
    my $tbl = Table->new({owner => $schema, name => $vname});
    my $sql = $tbl->getViewSQL($dbh);

    my($svValue) = ($sql =~ /subclass_view\s+=\s+'([^']+)'/im);
    my($impTable) = ($sql =~ /from\s+(\S+)\s+(where|with)/im);

    # "Houston, we have a problem."
    #
    if ($svValue =~ /Ver$/) {
        if ($listonly) {
	    print "$vname selects from $impTable where subclass_view = '$svValue'\n";
	} else {
	    # Sanity check
	    #
	    if (!($vname =~ /^${svValue}$/i)) {
		print "Names do not match: $vname and $svValue\n";
                next;
	    }
		
	    # Drop the view
	    #
	    $dbh->do("drop view $vname");

	    # Recreate the view with the new subclass_view clause
	    #
	    my $newValue = $svValue;
	    $newValue =~ s/Ver$//;

	    my $newSql = $sql;
	    $newSql =~ s/(subclass_view\s+=\s+')([^']+)'/${1}${newValue}'/;
	    $newSql =~ s/;\s*$//m;

	    $dbh->do($newSql);

	    # Grant select on the new view
	    #
            $dbh->do("grant select on $vname to RAD_READ_ROLE");	

	    # Update the implementation table accordingly
	    # (probably not necessary but can't hurt)
	    #
            $dbh->do("update $impTable set subclass_view = '$newValue' where subclass_view = '$svValue'");
	    $dbh->commit();

            print "recreated $vname\n";
        }
        ++$nBadViews;
    }
}

print "Identified/recreated $nBadViews erroneous views\n";

$dbh->disconnect();
