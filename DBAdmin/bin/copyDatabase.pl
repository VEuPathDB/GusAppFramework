#!@perl@

# -----------------------------------------------------------------------
# copyDatabase.pl
#
# Copy all the tables owned by a user in one Oracle database to a user 
# in a second Oracle database.  The script uses SQL statements and a 
# remote Oracle database link to accomplish this.
# 
# Here's an example of how the script might be used.  This command copies
# all the tables owned by the user "gusdev" on the Oracle server "gusdev" 
# (running on erebus.pcbi.upenn.edu) to the user "gus" on the Oracle 
# server "gus" (running on the machine called nemesis.)  It will place
# the copies of these tables on the "RAID1" tablespace (on the "gus" 
# server), assuming that such a tablespace exists and the user "gus" 
# is allowed to create tables there.  It will also generate two files
# in the current directory, gus-indexes.sql and gus-constraints.sql, 
# which contain the CREATE INDEX and ALTER TABLE commands, respectively,
# needed to complete the database copy.  The following command also
# relies on the existence of a database link named "gusdev.pcbi.upenn.edu"
# in the source database (see below for details):
#
# copyDatabase.pl \
#  --tgtLogin=gus --tgtPassword=guspassword \
#  --tgtHost=nemesis --tgtSID=gus --tgtSchema=gus \
#  --srcLogin=gusdev --srcPassword=gusdevpassword \
#  --srcHost=erebus --srcSID=gusdev --srcSchema=gusdev \
#  --srcLink=gusdev.pcbi.upenn.edu \
#  --targetTS=RAID1 --targetIndTS=INDX --targetRbsSeg=BIGRBS0 \
#  --filePrefix=gus |& cat > gus-copy.log &
#
# Here's the command again, with each option explained in detail:
#
# copyDatabase.pl \
#  --tgtLogin=gus --tgtPassword=guspassword \
#
# --tgtLogin and --tgtPassword give the Oracle login and password needed 
# to log in to the *target* (i.e. destination) database.  --tgtLogin must 
# be an Oracle user/login that has the ability to create tables in the 
# schema specified by the --tgtSchema option (see below.)  For this 
# reason the simplest thing to do is make --tgtLogin and --tgtSchema the
# same ("gus", in this example); this tells the script to log in as the 
# same user that will own the newly-created tables in the target database.
#
#  --tgtHost=nemesis --tgtSID=gus --tgtSchema=gus \
#
# --tgtHost is the name of the machine where the target Oracle database 
# is installed; depending on where you're running the script from, this
# may need to be a fully-qualified hostname (i.e., "gus.pcbi.upenn.edu"
# instead of "gus", in this example.)  --tgtSID is the Oracle SID for 
# the target Oracle database, and --tgtSchema, as mentioned above, is the 
# Oracle schema/login that will own the new tables being copied from the 
# source database.
#
#  --srcLogin=gusdev --srcPassword=gusdevpassword \
#
# --srcLogin and --srcPassword give the Oracle login and password needed
# to log in to the *source* database (i.e., the one that has the tables 
# being copied.)  --srcLogin must be an Oracle user/login that has the 
# ability to read (i.e. SELECT from) the tables owned by --srcSchema.  
# For this reason, as with --tgtLogin and --tgtSchema, the easiest thing
# to do is to make --srcLogin and --srcSchema the same ("gusdev" in this
# example.)
#
#  --srcHost=erebus --srcSID=gusdev --srcSchema=gusdev \
#
# --srcHost is the name of the machine where the source Oracle database
# is running.  --srcSID is the Oracle SID that identifies the source
# Oracle database, and --srcSchema is the Oracle schema/login that owns
# the tables being copied.
#
#  --srcLink=gusdev.pcbi.upenn.edu \
#
# --srcLink must be the name of an Oracle database link that gives the 
# user named by --tgtLogin the ability to SELECT FROM tables in --srcSchema
# on the source database.  Note that although this link allows access to 
# tables in the source database, it is something that must be created in 
# the target database.  See the Oracle documentation for more information
# on database links, in particular the documentation for the CREATE DATABASE 
# LINK command, which is used to create new database links.
#
# To create the database link used in this example, we would first log in 
# to the *target* database using --tgtLogin ("gus") and --tgtPassword
# ("guspassword").  We would then run the following SQL command to create
# the link to the target database:
#
# CREATE DATABASE LINK gusdev.pcbi.upenn.edu CONNECT TO gusdev 
#  IDENTIFIED BY gusdevpassword USING 'gusdev.pcbi.upenn.edu';
#
# (If this command fails with an "insufficient privileges" error then the
# --tgtLogin login first needs to be granted the CREATE DATABASE LINK 
# privilege.)
#
# In this command "gusdev.pcbi.upenn.edu" is the name of the database link 
# (in the target database.)  "gusdev" is the name of the login to be used
# to connect to the *source* database, and "gusdevpassword" is the 
# corresponding password.  Finally, the clause "USING 'gusdev.pcbi.upenn.edu'" 
# gives the SID of the database to which the link is being made (or can
# be any valid Oracle connection string.)  This command creates a database 
# link that can be used by the "gus" login on the target database to query
# against the source database (without logging in to it directly).  For 
# example, the above database link allows the "gus" user to run a command
# like the following, while logged on to the gus database:
#
# describe gusdev.nafeatureimp@gusdev.pcbi.upenn.edu;
#
# The "@gusdev.pcbi.upenn.edu" tells the server to use the remote database
# link named gusdev.pcbi.upenn.edu to find the specified table on the
# remote database gusdev.  The script uses this database link in order
# to transfer the data from each table in the source database to the target
# database.
#
#  --targetTS=RAID1 --targetIndTS=INDX --targetRbsSeg=BIGRBS0 \
#
# --targetTS is the name of the tablespace in the *target* database where
# the new tables will be created.  It must be a tablespace that --tgtLogin
# has the ability to create tables in, and it must be large enough to 
# accomodate all the tables being copied from --srcSchema.  --targetIndTS
# is the name of the tablespace in the target database where the indexes
# for the new tables will be created.  Similarly to --targetTS, --tgtLogin
# needs the ability to create indexes there, and --targetIndTS must be large
# enough to hold all of the indexes.  Note, however, that the script does
# not create the indexes directly; instead, it generates a separate file
# containing all of the CREATE INDEX statements, to be run at your leisure.
#
# --targetRbsSeg is an optional parameter that specifies the name of a 
# rollback segment in the target database that should be used when 
# transferring the data from each table (using a SELECT INTO statement.)
# Large tables can generate a substantial amount of redo information, which
# may require the use of a rollback segment that is larger than the default
# rollback segment.  Note that this parameter should *not* be set if your
# target database is an Oracle9i or later database using automatic undo
# management.  If you set this option in a database using automatic undo
# management an error will be triggered when the script attempts to use 
# the specified rollback segment.
#
#  --filePrefix=gus |& cat > gus-copy.log &
# 
# --filePrefix specifies a prefix for the files that the script will create
# in the current working directory.  For example, specifying a prefix of
# "gus" will cause the script to create files named gus-indexes.sql and
# gus-constraints.sql in the current working directory.  Finally, the last
# part of the shell command, "|& cat > gus-copy.log &", causes the entire
# command to be run in the background, with stdout and stderr redirected to 
# a log file named "gus-copy.log".  (Note that this shell syntax works with
# tcsh and may need modifying for bash and other shells.)  We recommend
# running the command in the background because it can take 1-2 days to
# migrate a moderately-sized database (~100 gigabytes).
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

use GUS::DBAdmin::Table;
use GUS::DBAdmin::Util;

# -----------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------

# Attributes that control the properties of the DBI connections; the
# setting of LongReadLen should not be crucial here, because the data
# from the source database is being transferred directly from database
# to database, without going through the DBI interface.
#
my $DBI_ATTS = { RaiseError => 0, AutoCommit => 0, LongReadLen => 10000000 };

# -----------------------------------------------------------------------
# Input
# -----------------------------------------------------------------------

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
   $tgtRbsSeg,
   $filePrefix,
   $checkCounts,
   $sqlOnly,
   $excludePerlExp
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
	    "targetRbsSeg=s" => \$tgtRbsSeg,
	    "filePrefix=s" => \$filePrefix,
	    "checkCounts!" => \$checkCounts,
	    "sqlOnly!" => \$sqlOnly,
	    "excludePerlExp=s" => \$excludePerlExp,
	    );

if ((!$tgtLogin) || (!$tgtPassword) || (!$tgtHost) || (!$tgtSID) || (!$tgtSchema) ||
    (!$srcLogin) || (!$srcPassword) || (!$srcHost) || (!$srcSID) || (!$srcSchema) || 
    (!$srcLink) || (!$tgtTS) || (!$tgtIndTS) || (!$filePrefix))
{
    print <<USAGE;
copyDatabase.pl 
    --tgtLogin=login         # Oracle login for the target database/schema
    --tgtPassword=password   # Password for the target database/schema
    --tgtHost=host           # Host machine for target database
    --tgtSid=SID             # Oracle SID for target database
    --tgtSchema=schema       # Name of target database schema
    --srcLogin=login         # Oracle login for the source database/schema
    --srcPassword=password   # Password for the source database/schema
    --srcHost=host           # Host machine for source database
    --srcSid=SID             # Oracle SID for source database
    --srcSchema=schema       # Name of source database schema
    --srcLink=dblink         # Remote database link to source database on the target system
    --targetTS=tablespace    # Target tablespace for tables
    --targetIndTS=tablespace # Target tablespace for indexes
    --targetRbsSeg=seg       # Target rollback segment (optional); should NOT be specified if the target
                               database is using automatic undo management.
    --filePrefix=prefix      # Path/prefix for files used to record indexes and constraints
    --checkCounts            # Don't do anything except compare numbers of rows in source and target
    --sqlOnly                # Don't do anything except generate SQL for indexes and constraints
    --excludePerlExp=perlexp # Perl expression for tables/views to exclude from the copy
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

# Login to the source database; this login is used primarily to query the source
# database to determine the CREATE TABLE (and CREATE VIEW) statements required
# to create each table and view in the target database.
#
my $srcDbiStr = "dbi:Oracle:host=$srcHost;sid=$srcSID";
my $srcDbh = &GUS::DBAdmin::Util::establishLogin($srcLogin, $srcDbiStr, $DBI_ATTS, $srcPassword);

# Login to the target database; this login is used to create the new tables and
# transfer the data.  A commit is done after transferring the contents of each
# table.
#
my $tgtDbiStr = "dbi:Oracle:host=$tgtHost;sid=$tgtSID";
my $tgtDbh = &GUS::DBAdmin::Util::establishLogin($tgtLogin, $tgtDbiStr, $DBI_ATTS, $tgtPassword);

print "***SCHEMA $srcSchema\n";
my $ss = $srcSchema;
$ss =~ tr/a-z/A-Z/;

# Save the SQL for indexes and constraints (primary and non-primary) in these
# variables, and then print their contents to files after all the data has been
# transferred.
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
my $tables = &GUS::DBAdmin::Util::execQuery($srcDbh, $tsql, 'scalar');
my $nTables = scalar(@$tables);
my $tnum = 1;

foreach my $table (@$tables) {

    if ($excludePerlExp) {
	$_ = $table;
	if (eval($excludePerlExp)) {
	    print "****skipping table $table\n";
	    next;
	}
    }

    # --checkCounts option: compares the sizes of the two tables without moving any data
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
    my $srcTable = new GUS::DBAdmin::Table({owner => $srcSchema, name => $table});
    my $createSql = $srcTable->getSQL($srcDbh, $tgtSchema, $tgtTS);
    $createSql =~ s/;\s*$//;

    # Get and save the SQL used to create the table's indexes and constraints
    #
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

    # If running in --sqlOnly mode save the SQL but don't transfer any data
    #
    if ($sqlOnly) {
	print "****TABLE $table ($tnum/$nTables): generating SQL\n";
    }
    
    # If the table already exists don't attempt to transfer any data
    #
    elsif (&tableExists($tgtDbh, $tgtSchema, $table)) {
	print "****TABLE $table ($tnum/$nTables): already exists\n";
    } 
    
    # Otherwise run the SQL commands to create the target table and to copy 
    # the contents of the source table into it.
    #
    else {
	# Create table in target database
	my $nRows = $tgtDbh->do($createSql);
	print "****TABLE $table ($tnum/$nTables): dbi returned $nRows\n";
	$tgtDbh->commit();

	my $copySql = "insert into ${tgtSchema}.$table select * from ${srcSchema}.$table\@${srcLink}";

	if ($tgtRbsSeg =~ /\S+/) {
	    $tgtDbh->do("set transaction use rollback segment $tgtRbsSeg");
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
my $views = &GUS::DBAdmin::Util::execQuery($srcDbh, $vsql, 'scalar');
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
    elsif ($sqlOnly) {
	print "****VIEW $table ($vnum/$nViews): generating SQL\n";
	next;
    }

    # Read schema information from source database
    #
    my $srcTable = new GUS::DBAdmin::Table({owner => $srcSchema, name => $table});
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
# Disconnect and clean up 

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

    # Queries the "all_tables" system table to find out whether the table exists.
    my $csql = "select count(*) from all_tables where owner = '$us' and table_name = '$ut'";
    my $count = $dbh->selectrow_array($csql);

    return ($count > 0);
}

# Print standard header for each of the SQL files/scripts
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
