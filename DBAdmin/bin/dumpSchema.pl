#!/usr/bin/perl

# -----------------------------------------------------------------------
# dumpSchema.pl
#
# Generate the Oracle DDL required to recreate the objects owned by a 
# given schema (or schemas, in the case of GUS 3.0-compliant databases.)
#
#
# TO DO 
#  -accept a list of owner mappings, so that cross-schema 
#   constraints can be converted correctly; will require
#   changing --target-schema to --target-schema-list and similarly
#   for --schema.
#
# Created: Mon Feb 26 20:25:15 EST 2001
#
# Jonathan Crabtree
#
# $Revision$ $Date$ $Author$
# -----------------------------------------------------------------------

use strict;
use Database;
use Schema;
use Table;
use Sequence;

use Getopt::Long;

use FileHandle;

# -----------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------

my $DB_SID = "gusdev";
my $DB_HOST = "erebus.pcbi.upenn.edu";
my $DBI_ATTS = { RaiseError => 0, AutoCommit => 0, LongReadLen => 10000000 };

# -----------------------------------------------------------------------
# Input
# -----------------------------------------------------------------------

my(
   $login,
   $schema,
   $targetSchema,
   $targetTablespace,
   $targetIndexTablespace,
   $file,
   $tableinfo,
   $tables,
   $rename_sys_ids,
   $usersOnly,
   $tiTablesOnly,
   $tablesOnly,
   $viewsOnly,
   $indexesOnly,
   $constraintsOnly
   );

&GetOptions("login=s" => \$login,
	    "schema=s" => \$schema,
	    "target-schema=s" => \$targetSchema,
	    "target-tablespace=s" => \$targetTablespace,
	    "target-index-tablespace=s" => \$targetIndexTablespace,
	    "file=s" => \$file,
	    "tableinfo=s" => \$tableinfo,
	    "tables=s" => \$tables,
	    "rename-system-ids!" => \$rename_sys_ids,
	    "users-only!" => \$usersOnly,
	    "tableinfo-tables-only!" => \$tiTablesOnly,
	    "tables-only!" => \$tablesOnly,
	    "views-only!" => \$viewsOnly,
	    "indexes-only!" => \$indexesOnly,
	    "constraints-only!" => \$constraintsOnly,
	    );

if (!$login || !$schema) {
    print <<USAGE;
Usage: dumpSchema.pl options
  --login=login                  # Oracle login
  --schema=owner                 # schema whose objects should be dumped
  --target-schema=newowner       # schema name to use in the output files (default = '&&schema' to prompt the user)
  --target-tablespace=ts         # tablespace on which to create the new objects (default = '&&tablespace' to prompt the user)
  --target-index-tablespace=ts   # tablespace on which to create the new indexes (default = '&&index_tablespace' to prompt the user)
  --file=prefix                  # prefix for the files to create
  --tableinfo=owner              # tableinfo owner such as core
  --tables=t1,t2,t3              # explicit list of tables to dump (overrides --tableinfo)
  --rename-sys-ids               # whether to rename all system-generated identifiers (e.g. constraint names)
  --users-only                   # only generate CREATE USER statements
  --tableinfo-tables-only        # only generate CREATE TABLE and VIEW statements for tables and views listed in TableInfo
  --tables-only                  # only generate CREATE TABLE statements
  --views-only                   # only generate CREATE VIEW statements
  --indexes-only                 # only generate CREATE INDEX statements
  --constraints-only             # only generate ALTER TABLE...ADD CONSTRAINT statements
USAGE
    die "Invalid arguments";
}

# -----------------------------------------------------------------------
# Main program
# -----------------------------------------------------------------------

$| = 1;

my $doAll = (!$tablesOnly && !$viewsOnly && !$indexesOnly && !$constraintsOnly);

$targetSchema = '&&schema' if (!defined($targetSchema));
$targetTablespace = '&&tablespace' if (!defined($targetTablespace));
$targetIndexTablespace = '&&index_tablespace' if (!defined($targetIndexTablespace));

my $tableList = undef;

if ($tables =~ /\S/) {
    my @tl = split(/\s*,\s*/, $tables);
    $tableList = \@tl;
}

my $db = Database->new({sid => $DB_SID, host => $DB_HOST});
if ($login =~ /^sys$/i) { $DBI_ATTS->{ora_session_mode} = 2; }
my $dbh = &Util::establishLogin($login, $db->getDbiStr(), $DBI_ATTS);
my $s = Schema->new({name => $schema});

my $primKeyConstraintTxt = "";
my $constraintTxt = "";
my $indexTxt = "";
my $fh = new FileHandle();

# Users/schemas
#
if ($doAll || $usersOnly) {
    my $userFile = "$file-users.sql";
    print "writing $userFile...";
    $fh->open("> $userFile");
    &printSqlFileHeader($fh, $userFile);

    # foreach schema do:

    print $fh "/* Drop user if it already exists */\n";
    print $fh "DROP USER $targetSchema CASCADE;\n";
    print $fh "\n";

    print $fh "CREATE USER $targetSchema IDENTIFIED BY &&password \n";
    print $fh "  TEMPORARY TABLESPACE &&tempTablespace\n";
    print $fh "  DEFAULT TABLESPACE $targetTablespace\n";
    print $fh "  QUOTA &&tempQuota ON &&tempTablespace\n";
    print $fh "  QUOTA &&defaultQuota ON $targetTablespace;\n";
    print $fh "\n";
    print $fh "GRANT CONNECT TO $targetSchema;\n";
    print $fh "GRANT RESOURCE TO $targetSchema;\n";
    print $fh "GRANT CREATE SESSION TO $targetSchema;\n";
    print $fh "GRANT CREATE TABLE TO $targetSchema;\n";
    print $fh "GRANT CREATE VIEW TO $targetSchema;\n";
    print $fh "GRANT CREATE SEQUENCE TO $targetSchema;\n";
    print $fh "/* The following is required in order to create functional indexes: */\n";
    print $fh "GRANT QUERY REWRITE TO $targetSchema;\n";
    print $fh "\n";

    &printSqlFileFooter($fh, $userFile);
    $fh->close();
    print "done.\n";
}

# Contents of TableInfo
#
my $ti = undef;

if (!defined($tableList)) {
    $ti = Table->new({owner => $tableinfo, name => 'TableInfo'});    ### was owner => $schema
}

if ($doAll && !defined($tableList)) {
    my $tiFile = "$file-tableinfo.sql";
    print "writing $tiFile...";
    $fh->open("> $tiFile");
    &printSqlFileHeader($fh, $tiFile);

    my $sql = $ti->getContentsSQL($dbh, "order by table_id", $targetSchema, 'table_id', 1), "\n";

    # Override what's in the table for user, project, group & algorithm_invocation (last 4 cols)
    # so that it will match the contents of the "-initial-rows.sql" file.
    #
    $sql =~ s#\d+,\s*\d+,\s*\d+\s*,\d+\);$#1, 1, 1, 1);#mg;

    print $fh $sql;

    print $fh "COMMIT;\n";
    &printSqlFileFooter($fh, $tiFile);
    $fh->close();
    print "done.\n";
}

# Contents of Taxon tables
#
if ($doAll && !defined($tableList)) {
    my $ttables = [
		   ['Taxon', 'taxon_id'],
		   ['Taxon3', 'taxon_id'],
		   ['TaxonName', 'taxon_name_id'],
		   ['GeneticCode', 'genetic_code_id']
		   ];

    foreach my $ta (@$ttables) {
	my($tt, $keyCol) = @$ta;
	my $table = Table->new({owner => $schema, name => $tt});
	my $tFile = "$file-$tt.sql";
	print "writing $tFile...";
	$fh->open("> $tFile");
	&printSqlFileHeader($fh, $tFile);
	my $sql = $table->getContentsSQL($dbh, "order by $keyCol", $targetSchema, $keyCol, 1), "\n";
	$sql =~ s#\d+,\s*\d+,\s*\d+\s*,\d+\);$#1, 1, 1, 1);#mg;

	print $fh $sql;

	print $fh "COMMIT;\n";
	&printSqlFileFooter($fh, $tFile);
	$fh->close();
	print "done.\n";
    }
}

# TO DO - contents of this file will vary depending on the GUS schema version

# Some initial rows needed to get a GUS-compliant database rolling
#
if ($doAll && !defined($tableList)) {
    my $rowsFile = "$file-initial-rows.sql";
    print "writing $rowsFile...";
    $fh->open("> $rowsFile");
    &printSqlFileHeader($fh, $rowsFile);

    print $fh "/* NOTE - at least one row MUST be inserted into each of the following tables before */\n";
    print $fh "/* enabling the foreign key constraints.  Add additional rows below as desired!      */\n";
    print $fh "\n";

    my $ts = $targetSchema;
    $ts .= "." if ($ts =~ /^&&/);

    print $fh "INSERT INTO $ts.UserInfo VALUES(UserInfo_sq.nextval, 'dba', 'dba', 'Database', 'Administrator', 'unknown', SYSDATE, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1);\n\n";
    print $fh "INSERT INTO $ts.Project VALUES(Project_sq.nextval, 'Database administration', NULL, SYSDATE, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1);\n\n";
    print $fh "INSERT INTO $ts.GroupInfo VALUES(GroupInfo_sq.nextval, 'dba', NULL, SYSDATE, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1);\n\n";
    print $fh "INSERT INTO $ts.Algorithm VALUES(Algorithm_sq.nextval, 'SQL*PLUS', NULL, SYSDATE, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1);\n\n";
    print $fh "INSERT INTO $ts.AlgorithmImplementation VALUES(AlgorithmImplementation_sq.nextval, 1, 'unknown', NULL, NULL, NULL, SYSDATE, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1);\n\n";
    print $fh "INSERT INTO $ts.AlgorithmInvocation VALUES(AlgorithmInvocation_sq.nextval, 1, SYSDATE, SYSDATE, NULL, NULL, NULL, 'Row(s) inserted', NULL, SYSDATE, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1);\n\n";

    print $fh "COMMIT;\n";
    print $fh "\n";
    print $fh "/* 6 rows */\n";
    print $fh "\n";

    &printSqlFileFooter($fh, $rowsFile);
    $fh->close();
    print "done.\n";
}

# Remember which tables and views are listed in TableInfo so we can flag
# or ignore those that aren't.
#
my $tiRows = $tables ? [] : $ti->getContents($dbh, "order by table_id", 'hash');
my $tiTablesHash = {};
my $tiViewsHash = {};

foreach my $tir (@$tiRows) {
    my $tname = $tir->{'table_name'};
    my $isView = $tir->{'is_view'};
    $tname =~ tr/a-z/A-Z/;

    if ($isView) {
	$tiViewsHash->{$tname} = 1;
    } else {
	$tiTablesHash->{$tname} = 1;
    }
}

# Sequences
#
if ($doAll) {
    my $sFile = "$file-sequences.sql";
    print "writing sequences to $sFile...";
    $fh->open("> $sFile");
    &printSqlFileHeader($fh, $sFile);
    my $sequences = $s->getSequences($dbh);
    my $nseqs = 0;
    foreach my $seqname (@$sequences) {
	my $seq = Sequence->new({owner => $targetSchema, name => $seqname});
	print $fh $seq->getSQL($dbh, 1), "\n";
	print ".";
	++$nseqs;
    }
    print $fh "\n";
    print $fh "/* $nseqs sequences(s) */\n\n";

    &printSqlFileFooter($fh, $sFile);
    $fh->close();
    print "done.\n";
    if ($nseqs == 0) {
	print "$sFile contains no entries - deleting file.\n";
	unlink $sFile;

    }
}

# Tables
#
my $ntables = 0;
my $nconstraints = 0;
my $nindexes = 0;
my $tFile = "$file-tables.sql";

if ($doAll || $tablesOnly) {
    print "writing tables to $tFile...";
    $fh->open("> $tFile");      
    &printSqlFileHeader($fh, $tFile);
} 
elsif ($indexesOnly || $constraintsOnly) {      # constraints and indexes are actually generated here
    print "processing table information...";
}

if ($doAll || $tablesOnly || $indexesOnly || $constraintsOnly) {
    my $tl = $tables ? $tableList : $s->getTables($dbh);
    
    foreach my $tname (@$tl) {
	my $inTableInfo = defined($tiTablesHash->{$tname});
	next if (!$inTableInfo && $tiTablesOnly && !defined($tableList));

	my $tbl = Table->new({owner => $schema, name => $tname});
	my($dropCons, $createCons) = $tbl->getSelfConstraintsSql($dbh, $targetSchema, $rename_sys_ids);
	my($dropInds, $createInds) = $tbl->getIndexesSql($dbh, "$targetSchema.$tname", $rename_sys_ids, $targetSchema, $targetIndexTablespace, 0);
	
	$nconstraints += scalar(@$createCons);
	$nindexes += scalar(@$createInds);
	
	$indexTxt .= "/* $tname */\n";
	$indexTxt .= join("\n", @$createInds) . "\n\n";

	$constraintTxt .= "/* $tname */\n";

	# Separate out primary key constraints because they have to be created before
	# the foreign key constraints that make reference to them.
	#
	foreach my $con (@$createCons) {
	    if ($con =~ /primary key/i) {
		$primKeyConstraintTxt .= "$con\n";
	    } else {
		$constraintTxt .= "$con\n";
	    }
	}
	$constraintTxt .= "\n";
	
	if ($doAll || $tablesOnly) {
	    if (!defined($tableList) && !$inTableInfo) {
		print $fh "/* WARNING - $tname does not appear in ${tableinfo}.TableInfo */\n\n";
	    }
	    print $fh $tbl->getSQL($dbh, $targetSchema, $targetTablespace), "\n";
	}
	
	print ".";
	++$ntables;
    }
}

if ($doAll || $tablesOnly) {
    print $fh "\n";
    print $fh "/* $ntables table(s) */\n\n";
    &printSqlFileFooter($fh, $tFile);
    $fh->close();
    print "done.\n";
    if ($ntables == 0) {
	print "$tFile contains no entries - deleting file.\n";
	unlink $tFile;
    }
} elsif ($indexesOnly || $constraintsOnly) {
    print "done.\n";
}

# Views
#
if ($doAll || $viewsOnly) {
    my $vFile = "$file-views.sql";
    print "writing views to $vFile...";
    $fh->open("> $vFile");
    &printSqlFileHeader($fh, $vFile);
    my $views = $s->getViews($dbh);
    my $nviews = 0;
    foreach my $vname (@$views) {
	my $inTableInfo = $tiViewsHash->{$vname};
	next if (!$inTableInfo && $tiTablesOnly);
	my $tbl = Table->new({owner => $schema, name => $vname});
	if (!$inTableInfo && !defined($tableList)) {
	    print $fh "/* WARNING - $vname does not appear in ${tableinfo}.TableInfo */\n\n";
	}
	print $fh $tbl->getSQL($dbh, $targetSchema), "\n";
	print ".";
	++$nviews;
    }
    print $fh "\n";
    print $fh "/* $nviews view(s) */\n\n";
    &printSqlFileFooter($fh, $vFile);
    $fh->close();
    print "done.\n";
    if ($nviews == 0) {
	print "$vFile contains no entries - deleting file.\n";
	unlink $vFile;
    }
}

# Constraints  
#
if ($doAll || $constraintsOnly) {
    my $cFile = "$file-constraints.sql";
    print "writing constraints to $cFile...";
    $fh->open("> $cFile");
    &printSqlFileHeader($fh, $cFile);
    print $fh "/* PRIMARY KEY CONSTRAINTS */\n\n";
    print $fh $primKeyConstraintTxt, "\n";
    print $fh "\n";
    print $fh "/* NON-PRIMARY KEY CONSTRAINTS */\n\n";
    print $fh $constraintTxt, "\n";
    print $fh "\n";
    print $fh "/* $nconstraints constraint(s) */\n\n";
    &printSqlFileFooter($fh, $cFile);
    $fh->close();
    print "done.\n";
    if ($nconstraints == 0) {
	print "$cFile contains no entries - deleting file.\n";
	unlink $cFile;
    }
}

# Indexes
#
if ($doAll || $indexesOnly) {
    my $iFile = "$file-indexes.sql";
    print "writing indexes to $iFile...";
    $fh->open("> $iFile");
    &printSqlFileHeader($fh, $iFile);
    print $fh $indexTxt, "\n";
    print $fh "\n";
    print $fh "/* $nindexes index(es) */\n\n";
    &printSqlFileFooter($fh, $iFile);
    $fh->close();
    print "done.\n";
    if ($nindexes == 0) {
	print "$iFile contains no entries - deleting file.\n";
	unlink $iFile;
    }
}

# OTHER STUFF TO INCLUDE
#
# Bootstrap rows in Algorithm, AlgorithmImplementation, UserInfo, Project, GroupInfo?
# Dumps of controlled vocabulary tables?
# How to handle grants?

$dbh->disconnect();

# -----------------------------------------------------------------------
# Subroutines
# -----------------------------------------------------------------------

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
    print $fh sprintf("/* %-90s */\n", "This file was generated automatically by dumpSchema.pl on $date");
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
