#!@perl@

# -----------------------------------------------------------------------
# updateStatistics.pl
#
# Used to recompute statistics on database tables on a regular basis.
#
# Created: Mon Apr  9 10:15:54 EST 2001
#
# Jonathan Crabtree
#
# $Revision$ $Date$ $Author$
# -----------------------------------------------------------------------

use strict;

use GUS::DBAdmin::Database;
use GUS::DBAdmin::Schema;

use Getopt::Long;

# -----------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------

my $DBI_ATTS = { RaiseError => 0, AutoCommit => 0 };

# -----------------------------------------------------------------------
# Input
# -----------------------------------------------------------------------

my(
   $login,        # Oracle login with ANALYZE TABLE permissions
   $password,
   $dbSid,        # SID of Oracle database
   $dbHost,       # Hostname  of machine running Oracle database
   $owners,       # Only analyze tables belonging to these schemas
   $allTables,    # Update all tables
   $maxDaysOld,   # Update tables last analyzed more than this number of days ago
   $verbose
   );

&GetOptions("login=s" => \$login,
	    "owners=s" => \$owners,
	    "password=s" => \$password,
	    "sid=s" => \$dbSid,
	    "host=s" => \$dbHost,
	    "allTables!" => \$allTables,
	    "maxDaysOld=i" => \$maxDaysOld,
	    "verbose!" => \$verbose
	    );

if (!$login) {
    print <<USAGE;
Usage: updateStatistics.pl options
   --host=host         # Hostname of machine running Oracle
   --sid=SID           # SID of target Oracle instance
   --login=login       # Oracle login with ANALYZE TABLE permissions
   --password=password # (optional) password for login
   --owners=o1,o2...   # Update statistics for tables owned by these schemas only
   --allTables         # Whether to update statistics for all tables
   --maxDaysOld        # Only update tables last analyzed more than this number of days ago
   --verbose
USAGE
    die "Invalid arguments";
}

# -----------------------------------------------------------------------
# Main program
# -----------------------------------------------------------------------

$| = 1;

my $db = GUS::DBAdmin::Database->new({sid => $dbSid, host => $dbHost});
my $dbh = &GUS::DBAdmin::Util::establishLogin($login, $db->getDbiStr(), $DBI_ATTS, $password);

&GUS::DBAdmin::Util::printDate() if ($verbose);

my $tables = &tableList($dbh, $allTables, $owners);

foreach my $t (@$tables) {
    &updateStats($dbh, $t->{'owner'}, $t->{'table_name'});
}

&GUS::DBAdmin::Util::printDate() if ($verbose);
print "Computed statistics for ", scalar(@$tables), " tables\n" if ($verbose);

$dbh->disconnect();

# -----------------------------------------------------------------------
# Subroutines
# -----------------------------------------------------------------------

sub tableList {
    my($dbh, $allTables, $schemas) = @_;
    my $tables;
    my $where = '';

    if (defined($schemas)) {
	my @sc = split(/\s*,\s*/, $schemas);

	if (scalar(@sc) > 0) {
	    $where = "WHERE owner in (";
	    $where .= join(", ", map {"UPPER('$_')"} @sc);
	    $where .= ")";
	}
    }
	
    # All tables
    #
    if ($allTables) {
	my $sql = ("select owner, table_name FROM all_tables " . $where);
	$tables = &GUS::DBAdmin::Util::execQuery($dbh, $sql, 'hash');
    } 

    # Analyze those older than $maxDaysOld (includes those that have never been analyzed)
    #
    elsif ($maxDaysOld =~ /\d/) {
    }

    # Default - analyze only those that have not yet been analzyed
    #
    else {
	if ($where =~ /^\s*$/) {
	    $where = " where last_analyzed is null";
	} else {
	    $where .= " and last_analyzed is null";
	}

	my $sql = ("select owner, table_name from all_tables " . $where);
	$tables = &GUS::DBAdmin::Util::execQuery($dbh, $sql, 'hash');
    }

    return $tables;
}

sub updateStats {
    my($dbh, $schema, $table) = @_;
    my $sql = "analyze table ${schema}.${table} compute statistics";
    print "[$sql]\n" if ($verbose);
    $dbh->do($sql);
}
