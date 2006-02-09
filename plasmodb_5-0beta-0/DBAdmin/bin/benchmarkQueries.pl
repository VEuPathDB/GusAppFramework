#!@perl@

# -----------------------------------------------------------------------
# benchmarkQueries.pl
#
# Benchmark one or more SQL queries against an Oracle database.
# Logs all timing output to STDOUT.
#
# Created: Thu Apr 12 11:13:08 EST 2001
#
# Jonathan Crabtree
#
# $Revision$ $Date$ $Author$
# -----------------------------------------------------------------------

use strict;

use FileHandle;
use Getopt::Long;

use DBI;
use DBD::Oracle;

use Database;
use Util;

# -----------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------

my $DB_SID = "gusdev";
my $DB_HOST = "erebus";
my $DBI_ATTS = { RaiseError => 0, AutoCommit => 0, LongReadLen => 10000000 };

# -----------------------------------------------------------------------
# Input
# -----------------------------------------------------------------------

my(
   $login,
   $password,
   $queryFile,
   $explainPlans
   );

&GetOptions("login=s" => \$login,
	    "queryFile=s" => \$queryFile,
	    "explainPlans!" => \$explainPlans,
	    "password:s" => \$password,
	    );

if (!$login || !-e $queryFile) {
    print <<USAGE;
Usage: benchmarkQueries.pl options
  --login=login          # Oracle login with appropriate query privileges
  --queryFile=file       # File containing SQL query and parameter information
  --explainPlans         # Whether to record EXPLAIN PLAN output for each query
USAGE
    die "Invalid arguments";
}

# -----------------------------------------------------------------------
# Main program
# -----------------------------------------------------------------------

my $db = Database->new({sid => $DB_SID, host => $DB_HOST});
my $dbh = &Util::establishLogin($login, $db->getDbiStr(), $DBI_ATTS, $password);

# Read info in query file by eval'ing it
#
my $queries;
my $qfile = `cat $queryFile`;
eval($qfile) || die "Error trying to eval contents of $queryFile";

# Iterate over all queries, run 1 random for each
#
foreach my $q (@$queries) {
    my $args = $q->{'args'};
    my $query = $q->{'query'};
    my $name = $q->{'name'};

    # Choose a random argument vector
    #
    my $argvec = &randomArgVector($args);
    my $times = &timeQuery($dbh, $query, $argvec, $name);
    &displayTimingResults($times);
}

$dbh->disconnect();

# -----------------------------------------------------------------------
# Subroutines
# -----------------------------------------------------------------------

# Return a single argument vector with arguments chosen from
# the input argument lists.
#
sub randomArgVector {
    my($args) = @_;
    my $nArgs = scalar(@$args);
    my $vector = [];

    for (my $i = 0;$i < $nArgs;++$i) {
	my $args_i = $args->[$i];
	my $args_i_size = scalar(@$args_i);
	my $j = rand($args_i_size);
	push(@$vector, $args_i->[$j]);
    }
    return $vector;
}

# Replace the argument placeholders in $sql with the actual arguments
# in $argVec;
#
sub instantiateQuery {
    my($sql, $argVec) = @_;
    my $result = $sql;
    my $na = scalar(@$argVec);

    for (my $i = 0;$i < $na;++$i) {
	$result =~ s/\$\$$i\$\$/$argVec->[$i]/g;
    }

    return $result;
}

# Run a query using DBI, recording the time it takes.
#
sub timeQuery {
    my($dbh, $sql, $args, $descr, $numReps) = @_;
    my($startTime, $firstRowTime, $lastRowTime);
    my $numRows = 0;

    my $qsql = instantiateQuery($sql, $args);
    my $sth = $dbh->prepare($qsql);

    # Start time doesn't include preparation
    #
    $startTime = time;
    $sth->execute();

    # First row returned (should this go here or after the first fetchrow?)
    #
    $firstRowTime = time;
    while (my @a = $sth->fetchrow_array()) {
	++$numRows;
    }

    # All rows returned
    #
    $lastRowTime = time;
    $sth->finish();

    return {
	firstRowElapsed => $firstRowTime - $startTime,
	lastRowElapsed => $lastRowTime - $startTime,
	descr => $descr,
	numRows => $numRows,
	args => $args
    };
}

sub displayTimingResults {
    my($times) = @_;

    print "Arguments: ", join(',', @{$times->{args}}), "\n";
    print "Time to retrieve first row: ", $times->{firstRowElapsed}, " second(s)\n";
    print "Time to retrieve all rows: ", $times->{lastRowElapsed}, " second(s)\n";
    print "Number of rows: ", $times->{numRows}, "\n";
    print "Description: ", $times->{descr}, "\n";
    print "Number of repetitions: ", $times->{reps}, "\n";
}
