#!@perlLocation@

# -----------------------------------------------------------------------
# checkForeignKeysIndexed.pl
#
# Check that every column that references another table is indexed.  This
# is so that when rows in the referenced table are deleted or updated the
# database can use the index to check whether any foreign key constraints
# have been violated.
#
# Created: Fri Oct  5 09:44:57 EST 2001
#
# Jonathan Crabtree
# $Revision$ $Date$ $Author$
# -----------------------------------------------------------------------

use strict;

use Database;
use Schema;
use Table;

use Getopt::Long;


# -----------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------

my $DB_SID = "gusdev";
my $DB_HOST = "localhost";
my $DBI_ATTS = { RaiseError => 0, AutoCommit => 0, LongReadLen => 10000000 };
my $EXP = 'exp';

my $VERBOSE = 1;

my @SHARED_COLS = ('ROW_ALG_INVOCATION_ID', 'ROW_USER_ID', 'ROW_PROJECT_ID', 'ROW_GROUP_ID');
my $INDX_TSPACE = 'indx';

# -----------------------------------------------------------------------
# Input
# -----------------------------------------------------------------------

my(
   $login,
   $sid,
   $host,
   $schema,
   $password,
   );

&GetOptions("login=s" => \$login,
	    "sid=s" => \$sid,
	    "host=s" => \$host,
	    "schema:s" => \$schema,
	    "password=s" => \$password,
	    );

if (!$login || !$schema) {
    print <<USAGE;
Usage: dumpSchema.pl options
  --login=login             # Oracle login
  --sid=sid                 # Oracle SID
  --host=host               # Oracle host
  --schema=schema           # Optional schema name
  --password=password       # Oracle password
USAGE
    die "Invalid arguments";
}

# -----------------------------------------------------------------------
# Main program
# -----------------------------------------------------------------------

my $db = Database->new({
    sid => defined($sid) ? $sid : $DB_SID, 
    host => defined($host) ? $host : $DB_HOST
    });

my $dbh = &Util::establishLogin($login, $db->getDbiStr(), $DBI_ATTS, $password);
my $s = Schema->new({name => $schema});

# Retrieve all table names for the specified schema
#
my $tables = $s->getTables($dbh);

# Check each table in turn
#
foreach my $tname (@$tables) {
    print "checking $tname:\n";

    my $tbl = Table->new({owner => $schema, name => $tname});
    my $fks = $tbl->getSelfConstraints($dbh);
    my $inds = $tbl->getIndexes($dbh);

    my $indexes = {};

    my $indPrefix = $tname;
    my $maxINum = 0;

    # Build a hash on the available indexes
    #
    foreach my $ind (@$inds) {
	my $owner = $ind->{owner};
	my $name = $ind->{index_name};
	my $cols = $tbl->getIndexColumns($dbh, $owner, $name);

	my $key = join(',', map { $_->{column_name} } @$cols);
	$indexes->{$key} = $name;

	print " index $name on $key\n" if ($VERBOSE);

	if ($name =~ /^(\S+)_IND(\d+)/) { 
	    $indPrefix = $1;
	    $maxINum = $2; 
	}
    }

    foreach my $row (@$fks) {
	my $cname = $row->{constraint_name};
	my $type = $row->{constraint_type};
	next if ($type ne 'R');               # referential integrity constraints only

	my $cowner = $row->{owner};
	my $rOwner = $row->{r_owner};
	my $rConstraint = $row->{r_constraint_name};
	my $dRule = $row->{delete_rule};
	my $srcCols = $tbl->getConstraintCols($dbh, $cowner, $cname);

	my @cnames = map { $_->{'column_name'} } @$srcCols;

	print " foreign key on (", join(', ', @cnames), ") ";

	# First look for exact match
	#
	my $key = join(',', @cnames);

	if ($indexes->{$key}) {
	    print "matched exactly by ", $indexes->{$key};
	} elsif (my @k = grep(/^${key},\S+$/, keys %$indexes)) {
	    print "a prefix of ", $indexes->{$k[0]};
	} else {
	    print " NO INDEX FOUND!!";

	    # Ignore shared columns; make this an option
	    #
	    if (!grep(/^${key}$/, @SHARED_COLS)) {
   	        my $iName = $indPrefix . sprintf("_IND%02d", ++$maxINum);
		print "\nCREATE INDEX $iName ON $schema.$tname ($key) TABLESPACE $INDX_TSPACE";
	    }
	}

	print "\n";
    }
}

$dbh->disconnect();
