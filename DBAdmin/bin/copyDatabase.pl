#!@perl@

# -----------------------------------------------------------------------
# copyDatabase.pl
#
# Copy the contents of one Oracle database into another using SQL
# commands and remote database links.
#
# Created: Mon Oct 28 09:17:27 EST 2002
#
# Jonathan Crabtree
#
# $Revision$ $Date$ $Author$
# -----------------------------------------------------------------------

use strict;

use DBI;
use DBD::Oracle;
use Getopt::Long;
use FileHandle;

use Table;
use Util;

# -----------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------

my $DBI_STR = "dbi:Oracle:host=nemesis.pcbi.upenn.edu;sid=gus";
my $DBI_ATTS = { RaiseError => 0, AutoCommit => 0, LongReadLen => 10000000 };

# Rollback segment to use for insert statements
#
my $RBS_SEG = "BIGRBS0";

# -----------------------------------------------------------------------
# Input
# -----------------------------------------------------------------------

# Other parameters:
#  -destination tablespaces for tables and indexes
#  -tables to omit from the copy

my(
   $tgtLogin,
   $tgtPassword,
   $tgtHost,
   $tgtSID,
   $tgtSchema,
   $srcLogin,
   $srcPassword,
   $srcHost,
   $srcSID,
   $srcSchema,
   $srcLink,
   $tgtTS,
   $tgtIndTS,
   $filePrefix,
   $verbose,
   $checkCounts,
   );

&GetOptions("tgtLogin=s" => \$tgtLogin,
	    "tgtPassword=s" => \$tgtPassword,
	    "tgtHost=s" => \$tgtHost,
	    "tgtSid=s" => \$tgtSID,
	    "tgtSchema=s" => \$tgtSchema,
	    "srcLogin=s" => \$srcLogin,
	    "srcPassword=s" => \$srcPassword,
	    "srcHost=s" => \$srcHost,
	    "srcSid=s" => \$srcSID,
	    "srcSchema=s" => \$srcSchema,
	    "srcLink=s" => \$srcLink,
	    "targetTS=s" => \$tgtTS,
	    "targetIndTS=s" => \$tgtIndTS,
	    "filePrefix=s" => \$filePrefix,
	    "verbose!" => \$verbose,
	    "checkCounts!" => \$checkCounts,
	    );

if ((!$tgtLogin) || (!$tgtPassword) || (!$tgtHost) || (!$tgtSID) || (!$tgtSchema) ||
    (!$srcLogin) || (!$srcPassword) || (!$srcHost) || (!$srcSID) || (!$srcSchema) || 
    (!$srcLink) || (!$tgtTS) || (!$tgtIndTS) || (!$filePrefix))
{
    print <<USAGE;
copyDatabase.pl 
    --tgtLogin=login         # Oracle login for the *target* database/schema
    --tgtPassword=password   # Password for the *target* database/schema
    --tgtHost=host           # Host machine for *target* database
    --tgtSid=SID             # Oracle SID for *target* database
    --tgtSchema=schema       # Name of *target* database schema
    --srcLogin=login         # Oracle login for the *source* database/schema
    --srcPassword=password   # Password for the *source* database/schema
    --srcHost=host           # Host machine for *source* database
    --srcSid=SID             # Oracle SID for *source* database
    --srcSchema=schema       # Name of *source* database schema
    --srcLink=dblink         # Remote database link to *source* database on the *target* system
    --targetTS=tablespace    # Target tablespace for tables
    --targetIndTS=tablespace # Target tablespace for indexes
    --filePrefix=prefix      # Path/prefix for files used to record indexes and constraints
    --verbose
    --checkCounts            # Don't do anything except compare numbers of rows in source and target
USAGE
    die "Invalid arguments";
}

# -----------------------------------------------------------------------
# Main program
# -----------------------------------------------------------------------

$| = 1;

my $date = `date`;
chomp($date);
print "Database copy started at $date\n";

# Login to the source database
my $srcDbiStr = "dbi:Oracle:host=$srcHost;sid=$srcSID";
my $srcDbh = &Util::establishLogin($srcLogin, $srcDbiStr, $DBI_ATTS, $srcPassword);

# Login to the target database
my $tgtDbiStr = "dbi:Oracle:host=$tgtHost;sid=$tgtSID";
my $tgtDbh = &Util::establishLogin($tgtLogin, $tgtDbiStr, $DBI_ATTS, $tgtPassword);

print "***SCHEMA $srcSchema\n";
my $ss = $srcSchema;
$ss =~ tr/a-z/A-Z/;


# Saved SQL for indexes and constraints (primary and non-primary)
#
my $primKeyConstraintTxt = "";
my $constraintTxt = "";
my $indexTxt = '';
my $nindexes = 0;
my $nconstraints = 0;

# -----------------------------------------------------------------------
# TABLES
#
my $tsql = "select table_name from all_tables where owner = '$ss' order by table_name";
my $tables = &Util::execQuery($srcDbh, $tsql, 'scalar');
my $nTables = scalar(@$tables);
my $tnum = 1;

foreach my $table (@$tables) {

    # --checkCounts option
    #
    if ($checkCounts) {
	my $c1sql = "select count(*) from ${srcSchema}.$table";
	my $c2sql = "select count(*) from ${tgtSchema}.$table";

	my $c1 = $srcDbh->selectrow_array($c1sql);
	my $c2 = $tgtDbh->selectrow_array($c2sql);

	print "TABLE $table source=$c1 row(s) target=$c2 row(s)";
	print " <COUNTS DIFFER>" if ($c1 != $c2);
	print "\n";
	next;
    }

    # Read schema information from source database
    #
    my $srcTable = new Table({owner => $srcSchema, name => $table});
    my $createSql = $srcTable->getSQL($srcDbh, $tgtSchema, $tgtTS);
    $createSql =~ s/;\s*$//;

    my($dropCons, $createCons) = $srcTable->getSelfConstraintsSql($srcDbh, $tgtSchema, 1);
    my($dropInds, $createInds) = $srcTable->getIndexesSql($srcDbh, "$tgtSchema.$table", 1, $tgtSchema, $tgtIndTS, 0);

    $nconstraints += scalar(@$createCons);
    $nindexes += scalar(@$createInds);

    # Indexes
    $indexTxt .= "/* $table */\n";
    $indexTxt .= join("\n", @$createInds) . "\n\n";

    # Constraints
    $constraintTxt .= "/* $table */\n";
    foreach my $con (@$createCons) {
	if ($con =~ /primary key/i) {
	    $primKeyConstraintTxt .= "$con\n";
	} else {
	    $constraintTxt .= "$con\n";
	}
    }
    $constraintTxt .= "\n";

    # Default is to skip table if it already exists:
    #
    if (&tableExists($tgtDbh, $tgtSchema, $table)) {
	print "****TABLE $table ($tnum/$nTables): already exists\n";
    } 
    else {
	# Create table in target database
	my $nRows = $tgtDbh->do($createSql);
	print "****TABLE $table ($tnum/$nTables): dbi returned $nRows\n";
	$tgtDbh->commit();

	my $copySql = "insert into ${tgtSchema}.$table select * from ${srcSchema}.$table\@${srcLink}";

	if ($RBS_SEG =~ /\S+/) {
	    $tgtDbh->do("set transaction use rollback segment $RBS_SEG");
	}

	my $startTime = time;
	$nRows = $tgtDbh->do($copySql);
	my $endTime = time;
	$tgtDbh->commit();
    
	my $elapsed = $endTime - $startTime;
	print "****TABLE $table ($tnum/$nTables): $nRows row(s) copied in $elapsed second(s)\n";
    }
    ++$tnum;
}

$date = `date`;
chomp($date);
print "Transfer of row data finished at $date\n";

# -----------------------------------------------------------------------
# VIEWS
#
my $vsql = "select view_name from all_views where owner = '$ss' order by view_name";
my $views = &Util::execQuery($srcDbh, $vsql, 'scalar');
my $nViews = scalar(@$views);
my $vnum = 1;

foreach my $table (@$views) {

    # --checkCounts option
    #
    if ($checkCounts) {
	my $c1sql = "select count(*) from ${srcSchema}.$table";
	my $c2sql = "select count(*) from ${tgtSchema}.$table";

	my $c1 = $srcDbh->selectrow_array($c1sql);
	my $c2 = $tgtDbh->selectrow_array($c2sql);

	print "TABLE $table source=$c1 row(s) target=$c2 row(s)";
	print " <COUNTS DIFFER>" if ($c1 != $c2);
	print "\n";
	next;
    }

    # Read schema information from source database
    #
    my $srcTable = new Table({owner => $srcSchema, name => $table});
    my $createSql = $srcTable->getSQL($srcDbh, $tgtSchema, $tgtTS);
    $createSql =~ s/;\s*$//;

    # Create view in target database
    my $nRows = $tgtDbh->do($createSql);
    print "****VIEW $table ($vnum/$nViews): dbi returned $nRows\n";

    ++$vnum;
}

$tgtDbh->commit() if (!$checkCounts);

# -----------------------------------------------------------------------
# INDEXES AND CONSTRAINTS - dump SQL to files

if (!$checkCounts) {

    # Indexes
    #
    my $indexFile = $filePrefix . "-indexes.sql";
    my $indexFh = new FileHandle();
    $indexFh->open("> $indexFile");
    &printSqlFileHeader($indexFh, $indexFile);
    print $indexFh $indexTxt, "\n";
    print $indexFh "\n";
    print $indexFh "/* $nindexes index(es) */\n\n";
    &printSqlFileFooter($indexFh, $indexFile);
    $indexFh->close();

    # Constraints
    #
    my $constraintFile = $filePrefix . "-constraints.sql";
    my $constraintFh = new FileHandle();
    $constraintFh->open("> $constraintFile");
    &printSqlFileHeader($constraintFh, $constraintFile);
    print $constraintFh "/* PRIMARY KEY CONSTRAINTS */\n\n";
    print $constraintFh $primKeyConstraintTxt, "\n";
    print $constraintFh "\n";
    print $constraintFh "/* NON-PRIMARY KEY CONSTRAINTS */\n\n";
    print $constraintFh $constraintTxt, "\n";
    print $constraintFh "\n";
    print $constraintFh "/* $nconstraints constraint(s) */\n\n";
    &printSqlFileFooter($constraintFh, $constraintFile);
    $constraintFh->close();
}

# -----------------------------------------------------------------------
# Clean up 

$tgtDbh->disconnect();
$srcDbh->disconnect();

$date = `date`;
chomp($date);
print "Database copy finished at $date\n";

# -----------------------------------------------------------------------
# Subroutines
# -----------------------------------------------------------------------

# Determine whether a table already exists in the specified schema
#
sub tableExists {
    my($dbh, $schema, $table) = @_;
    my $us = $schema;
    $us =~ tr/a-z/A-Z/;
    my $ut = $table;
    $ut =~ tr/a-z/A-Z/;

    my $csql = "select count(*) from all_tables where owner = '$us' and table_name = '$ut'";
    my $count = $dbh->selectrow_array($csql);

    return ($count > 0);
}

# Print standard header for each of the SQL files/scripts that we generate
#
sub printSqlFileHeader {
    my($fh, $filename) = @_;

    my $date = `date`;
    chomp($date);

    print $fh "\n";
    print $fh sprintf("/* %-90s */\n", '');
    print $fh sprintf("/* %-90s */\n", $filename);
    print $fh sprintf("/* %-90s */\n", '');
    print $fh sprintf("/* %-90s */\n", "This file was generated automatically by copyDatabase.pl on $date");
    print $fh sprintf("/* %-90s */\n", '');
    print $fh "\n";
    
    my $logFile = $filename;
    $logFile =~ s#\.[^\.]+#.log#;

    print $fh "SET ECHO ON\n";
    print $fh "SPOOL $logFile\n";
    print $fh "\n";
}

# Print standard footer for each of the SQL files/scripts that we generate
#
sub printSqlFileFooter {
    my($fh, $filename) = @_;
    print $fh "SPOOL OFF\n";
    print $fh "SET ECHO OFF\n";
    print $fh "DISCONNECT\n";
    print $fh "EXIT\n";
}
