#!@perlLocation@

# -----------------------------------------------------------------------
# rebuildIndex.pl
#
# Rebuild unusable indexes for a table.
#
# Created: Fri Nov  2 13:39:30 EST 2001
#
# Jonathan Crabtree
#
# $Revision$ $Date$ $Author$
# -----------------------------------------------------------------------

use strict;

use DBI;
use DBD::Oracle;

use Table;
use Util;

# -----------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------

my $DBI_STR = "dbi:Oracle:host=nemesis;sid=gus";
my $DBI_ATTS = { RaiseError => 0, AutoCommit => 0, LongReadLen => 10000000 };

# -----------------------------------------------------------------------
# Input
# -----------------------------------------------------------------------

my $login = shift || die "First argument must be Oracle login";
my $src = shift || die "Second argument must be the name of the source table.";

my ($srcOwner, $srcTName) = ($src =~ /^([^\.]+)\.([^\.]+)$/);
die "Must specify source table name as owner.table" if (!defined($srcTName));

# -----------------------------------------------------------------------
# Main program
# -----------------------------------------------------------------------

my $dbh = &Util::establishLogin($login, $DBI_STR, $DBI_ATTS);

my $srcTable = new Table({owner => $srcOwner, name => $srcTName});
my $indexes = $srcTable->getUnusableIndexes($dbh);

foreach my $ind (@$indexes) {
    my $owner = $ind->{'owner'};
    my $name = $ind->{'index_name'};
    my $cmd = "alter index $owner.$name rebuild";

    print $cmd, "\n";
    $dbh->do($cmd);
}

$dbh->disconnect();

