#!@perl@

# -----------------------------------------------------------------------
# checkTableInfo.pl
#
# Perform some checks on the TableInfo table (in a GUS-compliant db.)
#
# Created: 
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
   );

&GetOptions("login=s" => \$login,
	    "schema=s" => \$schema,
	    );

if (!$login || !$schema) {
    print <<USAGE;
Usage: checkTableInfo.pl options
  --login=login          # Oracle login
  --schema=owner         # schema in which TableInfo table resides
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

# Get list of all tables and views
#
my $tables = $s->getTables($dbh);
my $views = $s->getViews($dbh);
my $tablesAndViews = {};

foreach my $n (@$tables, @$views) {
    $tablesAndViews->{$n} = 1;
}

# Check correspondence with those listed in TableInfo
#
my $sql = "select table_id, table_name from TableInfo";
my $rows = &Util::execQuery($dbh, $sql, 'array');

# Tables in TableInfo but not in the database
#
my $tiTables = {};
foreach my $row (@$rows) {
    my $un = $row->[1];
    $un =~ tr/a-z/A-Z/;

    $tiTables->{$un} = $row->[0];
    if (!defined($tablesAndViews->{$un})) {
	print "$row->[1] in TableInfo (id=", $row->[0], "), but no such table or view exists.\n";
    }
}

# Tables in the database but not in TableInfo
#
foreach my $n (@$tables, @$views) {
    if (!defined($tiTables->{$n})) {
	print "Table/view $n not listed in TableInfo\n";
    }
}

# All done
#
$dbh->disconnect();
