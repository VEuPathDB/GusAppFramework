#!@perl@

# -----------------------------------------------------------------------
# dumpSchema.pl
#
# Generates the Oracle DDL required to recreate the objects owned by a 
# given schema (or schemas, in the case of GUS 3.0-compliant databases.)
#
# TO DO:
#  -Dumps of controlled vocabulary tables?
#   (everything in SReS for GUS 3.0?)
#  -Handle GRANTing of permissions, at the very least so
#   that the cross-schema constraints can be enabled without
#   errors.
#
# Created: Mon Feb 26 20:25:15 EST 2001
#
# Jonathan Crabtree
#
# $Revision$ $Date$ $Author$
# -----------------------------------------------------------------------

use strict;

use GUS::DBAdmin::Database;
use GUS::DBAdmin::Schema;
use GUS::DBAdmin::Table;
use GUS::DBAdmin::Sequence;
use GUS::DBAdmin::Util;

use Getopt::Long;

use FileHandle;

# -----------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------

my $DBI_ATTS = { RaiseError => 0, AutoCommit => 0, LongReadLen => 10000000 };

# -----------------------------------------------------------------------
# Input
# -----------------------------------------------------------------------

my(
   $gusVersion,
   $dbSid,
   $dbHost,
   $login,
   $schemaList,
   $targetSchemaList,
   $targetTablespaceList,
   $targetIndexTablespaceList,
   $file,
   $tableinfoSchema,
   $tables,
   $rename_sys_ids,
   $usersOnly,
   $tiTablesOnly,
   $tablesOnly,
   $viewsOnly,
   $indexesOnly,
   $constraintsOnly,
   $masterOnly,
   );

&GetOptions("gus-version=s" => \$gusVersion,
	    "db-sid=s" => \$dbSid,
	    "db-host=s" => \$dbHost,
	    "login=s" => \$login,
	    "tableinfo-schema=s" => \$tableinfoSchema,
	    "schema-list=s" => \$schemaList,
	    "target-schema-list=s" => \$targetSchemaList,
	    "target-tablespace-list=s" => \$targetTablespaceList,
	    "target-index-tablespace-list=s" => \$targetIndexTablespaceList,
	    "file=s" => \$file,
	    "tables=s" => \$tables,
	    "rename-system-ids!" => \$rename_sys_ids,
	    "users-only!" => \$usersOnly,
	    "tableinfo-tables-only!" => \$tiTablesOnly,
	    "tables-only!" => \$tablesOnly,
	    "views-only!" => \$viewsOnly,
	    "indexes-only!" => \$indexesOnly,
	    "constraints-only!" => \$constraintsOnly,
	    "master-only!" => \$masterOnly,
	    );

if (!$login || !$schemaList || !$dbSid || !$dbHost) {
    print <<USAGE;
Usage: dumpSchema.pl options
  --gus-version=ver                            # GUS schema version
  --db-sid=SID                                 # SID of the Oracle server
  --db-host=hostname                           # Hostname of the Oracle server
  --login=login                                # Oracle login (required)
  --tableinfo-schema=owner                     # schema that contains the TableInfo table (required if --tables not given)
  --schema-list=s1,s2,...                      # comma-delimited list of schemas to dump (required)
  --target-schema-list=t1,t2,...               # comma-delimited list of target schema names to use in the output files
  --target-tablespace-list=ts1,ts2,...         # tablespaces on which to create the new objects
  --target-index-tablespace-list=ts1,ts2,...   # tablespaces on which to create the new indexes
  --file=prefix                                # prefix for the files to create (required)
  --tables=t1,t2,t3                            # explicit list of tables to dump (required if --tableinfo-schema not given)
  --rename-system-ids                          # whether to rename all system-generated identifiers (e.g., constraint names)
  --users-only                                 # only generate CREATE USER statements
  --tableinfo-tables-only                      # only generate CREATE TABLE and VIEW statements for tables and views listed in TableInfo
  --tables-only                                # only generate CREATE TABLE statements
  --views-only                                 # only generate CREATE VIEW statements
  --indexes-only                               # only generate CREATE INDEX statements
  --constraints-only                           # only generate ALTER TABLE...ADD CONSTRAINT statements
  --master-only                                # only generate master control file
USAGE
    die "Invalid arguments";
}

# -----------------------------------------------------------------------
# Main program
# -----------------------------------------------------------------------

$| = 1;

# -----------------------------------------------------------------------
# Input verification

# Whether to dump all tables, modulo the --tableinfo-tables-only option
#
my $doAll = (!$usersOnly && !$tablesOnly && !$viewsOnly && !$indexesOnly && !$constraintsOnly && !$masterOnly);

my @schemas = split(/\s*,\s*/, $schemaList);
my @targetSchemas;

# Get target schema and tablespace names
#
my @targetSchemas = &getTargetObjectNames('oracle_', '', $targetSchemaList, \@schemas);
my @targetTablespaces = &getTargetObjectNames('oracle_', 'Tablespace', $targetTablespaceList, \@schemas);
my @targetIndexTablespaces = &getTargetObjectNames('oracle_', 'IndexTablespace', $targetTablespaceList, \@schemas);

my $numSchemas = scalar(@schemas);
if ($numSchemas != scalar(@targetSchemas)) {
    print STDERR "ERROR - number of schemas in --schema-list and --target-schema-list differ\n";
    exit(1);
}

my $schemaMapping = {};
for (my $i = 0;$i < $numSchemas;++$i) {
    $schemaMapping->{lc($schemas[$i])} = $targetSchemas[$i];
}

# Explicit list of tables to dump.  If multiple schemas are specified in 
# --schema-list then these must be fully-qualified table names.
#
my $tableList = undef;

if ($tables =~ /\S/) {
    my @tl = split(/\s*,\s*/, $tables);
    $tableList = \@tl;

    if ($numSchemas > 1) {
	foreach my $table (@$tableList) {
	    if (!($table =~ /^(\S+)\.\S+/)) {
		print STDERR "ERROR - multiple schemas given in --schema-list, but '$table' is not a fully-qualified table name\n";
		exit(1);
	    }
	}
    }
} elsif (!defined($tableinfoSchema)) {
    print STDERR "ERROR - either --tableinfo-schema or --tables must be specified\n";
    exit(1);
}

# -----------------------------------------------------------------------
# Establish database login

my $db = GUS::DBAdmin::Database->new({sid => $dbSid, host => $dbHost});
if ($login =~ /^sys$/i) { $DBI_ATTS->{ora_session_mode} = 2; }
my $dbh = &GUS::DBAdmin::Util::establishLogin($login, $db->getDbiStr(), $DBI_ATTS);

# -----------------------------------------------------------------------
# Read metadata if available

# Contents of DatabaseInfo (GUS 3.0 and later)
#
my $di = undef;
my $diRows = [];     # contents of DatabaseInfo
my $dbHash = {};     # hash from database_id to database name

# Contents of TableInfo
#
my $ti = undef;
my $tiRows = [];
my $tiTablesHash = {};
my $tiViewsHash = {};

# Read from DatabaseInfo and TableInfo if --tableinfo-schema given
#
if (!defined($tableList)) {

    # DatabaseInfo
    #
    if ($gusVersion >= 3) {
	$di = GUS::DBAdmin::Table->new({owner => $tableinfoSchema, name => 'DatabaseInfo'});
	$diRows = $di->getContents($dbh, "order by database_id", 'hash');
	foreach my $dir (@$diRows) {
	    my $did = $dir->{'database_id'};
	    my $dname = $dir->{'name'};
	    $dname =~ tr/a-z/A-Z/;
	    $dbHash->{$did} = $dname;
	}
    }

    # TableInfo
    #
    $ti = GUS::DBAdmin::Table->new({owner => $tableinfoSchema, name => 'TableInfo'});
    $tiRows = $tables ? [] : $ti->getContents($dbh, "order by table_id", 'hash');

    foreach my $tir (@$tiRows) {
	my $tname = ($gusVersion < 3) ? $tir->{'table_name'} : $tir->{name};
	my $isView = $tir->{'is_view'};
	$tname =~ tr/a-z/A-Z/;
	
	if ($gusVersion >= 3.0) {
	    my $dbid = $tir->{'database_id'};
	    my $dbname = $dbHash->{$dbid};
	    $tname = $dbname . "." . $tname;
	}
	
#	print STDERR "--$tname\n";
	
	if ($isView) {
	    $tiViewsHash->{$tname} = 1;
	} else {
	    $tiTablesHash->{$tname} = 1;
	}
    }
}

# -----------------------------------------------------------------------
# Perform schema-independent tasks

my $fh = new FileHandle();

# CREATE USER statements: ${file}users.sql
#
if ($doAll || $usersOnly) {
    my $userFile = "${file}users.sql";
    print "writing $userFile...";
    $fh->open("> $userFile");
    &printSqlFileHeader($fh, $userFile, 'CREATE USER statments for the Oracle users/schemas that will hold the tables in GUS.');

    for (my $i = 0;$i < $numSchemas;++$i) {
	my $schema= $schemas[$i];
	my $targetSchema = $targetSchemas[$i];
	my $targetTablespace = $targetTablespaces[$i];
	my $targetIndexTablespace = $targetIndexTablespaces[$i];

	print $fh "/* ----------------------------------------------------------------------- */\n";
	print $fh "/* New schema = $targetSchema (original name = $schema) */\n";
	print $fh "/* ----------------------------------------------------------------------- */\n";
	print $fh "DROP USER $targetSchema CASCADE;\n";
	print $fh "\n";

	
	my $targetPassword = &getTargetPassword($targetSchema);

	print $fh "CREATE USER $targetSchema IDENTIFIED BY $targetPassword \n";
	print $fh "  TEMPORARY TABLESPACE \@oracle_tempTablespace\@\n";
	print $fh "  DEFAULT TABLESPACE $targetTablespace\n";
	print $fh "  QUOTA \@oracle_tempQuota\@ ON \@oracle_tempTablespace\@\n";
	print $fh "  QUOTA \@oracle_defaultQuota\@ ON $targetTablespace;\n";
	print $fh "\n";
	print $fh "GRANT CONNECT TO $targetSchema;\n";
	print $fh "GRANT RESOURCE TO $targetSchema;\n";
	print $fh "GRANT CREATE SESSION TO $targetSchema;\n";
	print $fh "GRANT CREATE TABLE TO $targetSchema;\n";
	print $fh "GRANT CREATE VIEW TO $targetSchema;\n";
	print $fh "GRANT CREATE SEQUENCE TO $targetSchema;\n";
#	print $fh "/* The following is required if you wish to be able to create functional indexes: */\n";
#	print $fh "GRANT QUERY REWRITE TO $targetSchema;\n";
	print $fh "\n";
    }

    &printSqlFileFooter($fh, $userFile);
    $fh->close();
    print "done.\n";
}

# Tables whose contents should be included in a complete dump
#
my $tablesToDump = ($gusVersion >= 3.0) ? 
    [
     ['core', 'DatabaseInfo', 'database_id', 'Populate Core.DatabaseInfo, which lists each of the GUS namespaces (i.e. schemas/users).'],
     ['core', 'TableInfo', 'table_id', 'Populate Core.TableInfo, which lists each of the GUS tables.'],
     ['sres', 'BibRefType', 'bib_ref_type_id', 'Populate sres.BibRefType, a controlled vocabulary of bibliographic reference types.'],
     ] 
    : 
    [
     [undef, 'TableInfo', 'table_id', ''],
     [undef, 'Taxon', 'taxon_id', ''],
     [undef, 'Taxon3', 'taxon_id', ''],
     [undef, 'TaxonName', 'taxon_name_id', ''],
     [undef, 'GeneticCode', 'genetic_code_id', ''],
     ];

# Data
#
if ($doAll && !defined($tableList)) {

    # Bootstrap rows for crucial infrastructure tables
    #
    my $bfile = "${file}bootstrap-rows.sql";
    print "writing bootstrap rows to $bfile...";
    $fh->open("> $bfile");
    &printSqlFileHeader($fh, $bfile, 'Inserts a row into each of the central tracking/data provenance tables.');

    if ($gusVersion >= 3.0) {
	my $coreTs = &getTargetSchema('Core', \@schemas, \@targetSchemas);

	if ($coreTs) {
	    print $fh "INSERT INTO $coreTs.UserInfo VALUES(UserInfo_sq.nextval, 'dba', 'dba', 'Database', ";
	    print $fh "'Administrator', 'unknown', NULL, SYSDATE, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1);\n\n";
	    print $fh "INSERT INTO $coreTs.ProjectInfo VALUES(ProjectInfo_sq.nextval, 'Database administration', ";
	    print $fh "NULL, SYSDATE, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1);\n\n";
	    print $fh "INSERT INTO $coreTs.GroupInfo VALUES(GroupInfo_sq.nextval, 'dba', NULL, ";
	    print $fh "SYSDATE, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1);\n\n";
	    print $fh "INSERT INTO $coreTs.Algorithm VALUES(Algorithm_sq.nextval, 'SQL*PLUS', NULL, ";
	    print $fh "SYSDATE, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1);\n\n";
	    print $fh "INSERT INTO $coreTs.AlgorithmImplementation VALUES(AlgorithmImplementation_sq.nextval, ";
	    print $fh "1, 'unknown', NULL, NULL, NULL, NULL, NULL, SYSDATE, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1);\n\n";
	    print $fh "INSERT INTO $coreTs.AlgorithmInvocation VALUES(AlgorithmInvocation_sq.nextval, ";
	    print $fh "1, SYSDATE, SYSDATE, NULL, NULL, NULL, 'Row(s) inserted', NULL, SYSDATE, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1);\n\n";
	    print $fh "COMMIT;\n";
	    print $fh "\n";
	    print $fh "/* 6 rows */\n";
	    print $fh "\n";
	}
    } 
    else {
	my $ts = $targetSchemas[0];
	print $fh "INSERT INTO $ts.UserInfo VALUES(UserInfo_sq.nextval, 'dba', 'dba', 'Database', ";
	print $fh "'Administrator', 'unknown', SYSDATE, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1);\n\n";
	print $fh "INSERT INTO $ts.Project VALUES(Project_sq.nextval, 'Database administration', ";
	print $fh "NULL, SYSDATE, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1);\n\n";
	print $fh "INSERT INTO $ts.GroupInfo VALUES(GroupInfo_sq.nextval, 'dba', NULL, ";
	print $fh "SYSDATE, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1);\n\n";
	print $fh "INSERT INTO $ts.Algorithm VALUES(Algorithm_sq.nextval, 'SQL*PLUS', NULL, ";
	print $fh "SYSDATE, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1);\n\n";
	print $fh "INSERT INTO $ts.AlgorithmImplementation VALUES(AlgorithmImplementation_sq.nextval, ";
	print $fh "1, 'unknown', NULL, NULL, NULL, SYSDATE, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1);\n\n";
	print $fh "INSERT INTO $ts.AlgorithmInvocation VALUES(AlgorithmInvocation_sq.nextval, ";
	print $fh "1, SYSDATE, SYSDATE, NULL, NULL, NULL, 'Row(s) inserted', NULL, SYSDATE, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1);\n\n";
	print $fh "COMMIT;\n";
	print $fh "\n";
	print $fh "/* 6 rows */\n";
	print $fh "\n";
    }

    &printSqlFileFooter($fh, $bfile);
    $fh->close();
    print "done.\n";

    # Dumps of table contents for selected tables 
    # 
    foreach my $td (@$tablesToDump) {
	my($srcSchema, $tname, $primKeyCol, $fileDescr) = @$td;
	my $dfile = ($srcSchema) ? "${file}$srcSchema-$tname-rows.sql" : "${file}$tname-rows.sql";
	my $fullTName = ($srcSchema) ? "${srcSchema}.$tname" : $tname;
	print "writing contents of $fullTName to $dfile...";
	$fh->open("> $dfile");
	&printSqlFileHeader($fh, $dfile, $fileDescr);

	$srcSchema = $tableinfoSchema if (!defined($srcSchema));
	my $targetSchema = &getTargetSchema($srcSchema, \@schemas, \@targetSchemas);

	my $table = GUS::DBAdmin::Table->new({owner => $srcSchema, name => $tname});
	my $sql = $table->getContentsSQL($dbh, "order by $primKeyCol", $targetSchema, $primKeyCol, 1), "\n";

	# Override what's in the table for user, project, group & algorithm_invocation (last 4 cols)
	# so that it will match the contents of the "-initial-rows.sql" file.
	#
	$sql =~ s#\d+,\s*\d+,\s*\d+\s*,\d+\);$#1, 1, 1, 1);#mg;

	# Core.DatabaseInfo is a special case; the names of the schemas must be made to match
	# the @targetSchemas
	#
	if ($tname =~ /databaseinfo/i) {
	    $sql =~ s#(VALUES\(\s*\d+,'[\d\.]+',)'([^']+)'#$1'$schemaMapping->{lc($2)}'#g;
	}

	print $fh $sql;
	print $fh "COMMIT;\n";
	&printSqlFileFooter($fh, $dfile);
	$fh->close();
	print "done.\n";
    }
}

# -----------------------------------------------------------------------
# Loop over schemas

if ($doAll || $tablesOnly || $viewsOnly || $indexesOnly || $constraintsOnly) {
    for (my $i = 0;$i < $numSchemas;++$i) {
	my $schema = $schemas[$i];
	my $targetSchema = $targetSchemas[$i];
	my $targetTablespace = $targetTablespaces[$i];
	my $targetIndexTablespace = $targetIndexTablespaces[$i];
	my $s = GUS::DBAdmin::Schema->new({name => $schema});

	# Save text for constraints and indexes to dump later
	#
	my $primKeyConstraintTxt = "";
	my $constraintTxt = "";
	my $indexTxt = "";

  	# 1. Sequences (only for non-version databases)
	# 
	if (($doAll) && !($schema =~ /ver$/i)) {
	    my $sFile = "${file}$schema-sequences.sql";
	    print "writing sequences to $sFile...";
	    $fh->open("> $sFile");
	    &printSqlFileHeader($fh, $sFile);
	    my $sequences = $s->getSequences($dbh);
	    my $nseqs = 0;
	    foreach my $seqname (@$sequences) {
		my $seq = GUS::DBAdmin::Sequence->new({owner => $targetSchema, name => $seqname});
		print $fh $seq->getSQL($dbh, 1), "\n";
		print ".";
		++$nseqs;
	    }
	    print $fh "\n";
	    print $fh "/* $nseqs sequences(s) */\n\n";
	    
	    &printSqlFileFooter($fh, $sFile);
	    $fh->close();
	    print "done.\n";
	}

	# 2. Tables
	#
	my $ntables = 0;
	my $nconstraints = 0;
	my $nPrimKeyConstraints = 0;
	my $nOtherConstraints = 0;
	my $nIndexes = 0;
	my $tFile = "${file}$schema-tables.sql";

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
		next if ($tname =~ /plan_table/i);
		my $fullName = ($gusVersion >= 3) ? ($schema . "." . $tname) : $tname;
		$fullName =~ tr/a-z/A-Z/;
		my $inTableInfo = defined($tiTablesHash->{$fullName});
		next if (!$inTableInfo && $tiTablesOnly && !defined($tableList));

		my $tbl = GUS::DBAdmin::Table->new({owner => $schema, name => $tname});
		my($dropCons, $createCons) = $tbl->getSelfConstraintsSql($dbh, $targetSchema, $rename_sys_ids);
		my($dropInds, $createInds) = $tbl->getIndexesSql($dbh, "$targetSchema.$tname", $rename_sys_ids, $targetSchema, $targetIndexTablespace, 0);
	
		$nconstraints += scalar(@$createCons);
		$nIndexes += scalar(@$createInds);
		
		$indexTxt .= "/* $tname */\n";
		$indexTxt .= join("\n", @$createInds) . "\n\n";
		
		$constraintTxt .= "/* $tname */\n";
		
		# Separate out primary key constraints because they have to be created before
		# the foreign key constraints that reference to them.
		#
		foreach my $con (@$createCons) {
		    if ($con =~ /primary key/i) {
			$primKeyConstraintTxt .= "$con\n";
			++$nPrimKeyConstraints;
		    } else {

			# HACK - need to make sure that the schema of the table being 
			# referenced is one of the new targetSchemas
			#
			$con =~ s/(references)\s+([^\.]+)\.(\S+)/$1 $schemaMapping->{lc($2)}.$3/i;

			$constraintTxt .= "$con\n";
			++$nOtherConstraints;
		    }
		}
		$constraintTxt .= "\n";
		
		if ($doAll || $tablesOnly) {
		    if (!defined($tableList) && !$inTableInfo) {
			print $fh "/* WARNING - $tname does not appear in ${tableinfoSchema}.TableInfo */\n\n";
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
	} elsif ($indexesOnly || $constraintsOnly) {
	    print "done.\n";
	}
	
	# 3. Views
	#
	if ($doAll || $viewsOnly) {
	    my $vFile = "${file}$schema-views.sql";
	    print "writing views to $vFile...";
	    $fh->open("> $vFile");
	    &printSqlFileHeader($fh, $vFile);
	    my $views = $s->getViews($dbh);
	    my $nviews = 0;
	    foreach my $vname (@$views) {
		my $fullName = ($gusVersion >= 3) ? ($schema . "." . $vname) : $vname;
		$fullName =~ tr/a-z/A-Z/;
		my $inTableInfo = $tiViewsHash->{$fullName};
		next if (!$inTableInfo && $tiTablesOnly);
		my $tbl = GUS::DBAdmin::Table->new({owner => $schema, name => $vname});
		if (!$inTableInfo && !defined($tableList)) {
		    print $fh "/* WARNING - $vname does not appear in ${tableinfoSchema}.TableInfo */\n\n";
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
	}

	# 4. Constraints: one file for primary keys, one file for the rest
	#
	if ($doAll || $constraintsOnly) {
	    my $cFile1 = "${file}$schema-pkey-constraints.sql";
	    print "writing primary key constraints to $cFile1...";
	    $fh->open("> $cFile1");
	    &printSqlFileHeader($fh, $cFile1);
	    print $fh "/* PRIMARY KEY CONSTRAINTS */\n\n";
	    print $fh $primKeyConstraintTxt, "\n";
	    print $fh "\n";
	    print $fh "/* $nPrimKeyConstraints primary key constraint(s) */\n\n";
	    &printSqlFileFooter($fh, $cFile1);
	    $fh->close();
	    print "done.\n";

	    my $cFile2 = "${file}$schema-constraints.sql";
	    print "writing remaining constraints to $cFile2...";
	    $fh->open("> $cFile2");
	    &printSqlFileHeader($fh, $cFile2);
	    print $fh "/* NON-PRIMARY KEY CONSTRAINTS */\n\n";
	    print $fh $constraintTxt, "\n";
	    print $fh "\n";
	    print $fh "/* $nOtherConstraints non-primary key constraint(s) */\n\n";
	    &printSqlFileFooter($fh, $cFile2);
	    $fh->close();
	    print "done.\n";
	}

	# 5. Indexes
	#
	if ($doAll || $indexesOnly) {
	    my $iFile = "${file}$schema-indexes.sql";
	    print "writing indexes to $iFile...";
	    $fh->open("> $iFile");
	    &printSqlFileHeader($fh, $iFile);
	    print $fh $indexTxt, "\n";
	    print $fh "\n";
	    print $fh "/* $nIndexes index(es) */\n\n";
	    &printSqlFileFooter($fh, $iFile);
	    $fh->close();
	    print "done.\n";
	}
    }
}

$dbh->disconnect();

# -----------------------------------------------------------------------
# Create master file; 
# this script runs all of the others in the correct order
#

# TO DO: grant appropriate permissions?

if ($doAll || $masterOnly) {
    my $nf = 0;
    my $masterFile = "${file}create-db.sh";
    print "writing $masterFile...";
    $fh->open("> $masterFile");
    
    print $fh "#!/bin/sh\n\n";

    print $fh "# Running this file will create a new GUS instance \n";
    print $fh "\n";

    # create new users
    print $fh "# create new users (as sys/sysdba) \n";
    print $fh "sqlplus 'sys/\@oracle_systemPassword\@\@\@oracle_SID\@ as sysdba' \@${file}users.sql\n";
    print $fh "\n";
    ++$nf;

    # schema-dependent tasks

    my $sequenceTxt = '';
    my $tableTxt = '';
    my $viewTxt = '';
    my $primKeyTxt = '';
    my $nonPrimKeyTxt = '';
    my $indexTxt = '';

    for (my $i = 0;$i < $numSchemas;++$i) {
	my $schema = $schemas[$i];
	my $targetSchema = $targetSchemas[$i];
	my $targetPassword = &getTargetPassword($targetSchema);

	if (!($schema =~ /ver$/i)) {
	    $sequenceTxt .= "sqlplus ${targetSchema}/${targetPassword}\@\@oracle_SID\@ \@${file}${schema}-sequences.sql\n";
	}

	$tableTxt .= "sqlplus ${targetSchema}/${targetPassword}\@\@oracle_SID\@ \@${file}${schema}-tables.sql\n";
	$viewTxt .= "sqlplus ${targetSchema}/${targetPassword}\@\@oracle_SID\@ \@${file}${schema}-views.sql\n";
	$primKeyTxt .= "sqlplus ${targetSchema}/${targetPassword}\@\@oracle_SID\@ \@${file}${schema}-pkey-constraints.sql\n";
	$nonPrimKeyTxt .= "sqlplus ${targetSchema}/${targetPassword}\@\@oracle_SID\@ \@${file}${schema}-constraints.sql\n";
	$indexTxt .= "sqlplus ${targetSchema}/${targetPassword}\@\@oracle_SID\@ \@${file}${schema}-indexes.sql\n";
    }

    if ($doAll || $masterOnly) {
	print $fh "# create all sequences\n";
	print $fh "$sequenceTxt\n";
	$nf += $numSchemas;
    }

    if ($doAll || $tablesOnly || $masterOnly) {
	print $fh "# create all tables\n";
	print $fh "$tableTxt\n";
	$nf += $numSchemas;
    }

    if ($doAll || $viewsOnly || $masterOnly) {
	print $fh "# create all views\n";
	print $fh "$viewTxt\n";
	$nf += $numSchemas;
    }

    if ($doAll || $constraintsOnly || $masterOnly) {
	print $fh "# create all primary key constraints\n";
	print $fh "$primKeyTxt\n";
	$nf += $numSchemas;

	print $fh "# create all non-primary key constraints\n";
	print $fh "$nonPrimKeyTxt\n";
	$nf += $numSchemas;
    }

    if (($doAll && !defined($tableList)) || ($masterOnly)) {
	print $fh "# insert bootstrap rows, reset relevant sequences\n";
	my $targetSchema = ($gusVersion >= 3.0) ?  &getTargetSchema('Core', \@schemas, \@targetSchemas) : $targetSchemas[0];
	my $targetPassword = &getTargetPassword($targetSchema);

	print $fh "sqlplus ${targetSchema}/${targetPassword}\@\@oracle_SID\@ \@${file}bootstrap-rows.sql\n";
	print $fh "\n";
	++$nf;

	print $fh "# insert any other shared data/controlled vocabularies\n";

	foreach my $td (@$tablesToDump) {
	    my($srcSchema, $tname, $primKeyCol) = @$td;
	    my $dfile = ($srcSchema) ? "${file}$srcSchema-$tname-rows.sql" : "${file}$tname-rows.sql";
	    my $fullTName = ($srcSchema) ? "${srcSchema}.$tname" : $tname;
	    $srcSchema = $tableinfoSchema if (!defined($srcSchema));
	    my $targetSchema = &getTargetSchema($srcSchema, \@schemas, \@targetSchemas);
	    my $targetPassword = &getTargetPassword($targetSchema);
	    print $fh "sqlplus ${targetSchema}/${targetPassword}\@\@oracle_SID\@ \@$dfile\n";
	    ++$nf;
	}

	print $fh "\n";
    }

    if ($doAll || $indexesOnly || $masterOnly) {
	print $fh "# create all indexes\n";
	print $fh "$indexTxt\n";
	$nf += $numSchemas;
    }

    print $fh "# Issued sqlplus commands for $nf SQL files\n\n";

    $fh->close();
    print "done.\n";
}

# -----------------------------------------------------------------------
# Subroutines
# -----------------------------------------------------------------------

# Get a default password for the specified schema.  Returns a '@style@' 
# parameter so we can use Ant to replace it with the actual value when
# the files are installed.
#
sub getTargetPassword {
    my($targetSchema) = @_;

    my $tp;

    if ($targetSchema =~ /^\@(.*)\@$/) {
	$tp = '@' . $1 . "Password" . '@';
    } else {
	$tp = '@' . $targetSchema . "Password" . '@';
    }
    return $tp;
}

# Get target names for a set of objects, either by parsing user input
# or by generating names from the target schema names.  In the latter
# case the names will be of the form (@like_so@) that Ant recognizes.
#
sub getTargetObjectNames {
    my($objPrefix, $objSuffix, $userInput, $names) = @_;
    my @result;

    if ($userInput =~ /\S/) {
	@result = split(/\s*,\s*/, $userInput);
    } 
    else {
	foreach my $n (@$names) {
	    push(@result, '@' . $objPrefix . $n . $objSuffix . '@');
	}
    }

    return @result;
}

# Get the target schema for a given source schema
#
sub getTargetSchema {
    my($ss, $srcList, $tgtList) = @_;
    
    # normalize to lowercase
    my $lss = $ss;
    $lss =~ tr/A-Z/a-z/;
    
    my $ns = scalar(@$srcList);
    for (my $i = 0;$i < $ns;++$i) {
	my $lsl = $srcList->[$i];
	$lsl =~ tr/A-Z/a-z/;
	if ($lss eq $lsl) {
	    return $tgtList->[$i];
	}
    }
    return undef;
}

# Print standard header for each of the SQL files/scripts that we generate
#
sub printSqlFileHeader {
    my($fh, $filename, $descr) = @_;

    my $date = `date`;
    chomp($date);

    print $fh "\n";
    print $fh sprintf("/* %-90s */\n", '');
    print $fh sprintf("/* %-90s */\n", $filename);
    print $fh sprintf("/* %-90s */\n", '');
    if ($descr =~ /\S/) {
	print $fh sprintf("/* %-90s */\n", $descr);
	print $fh sprintf("/* %-90s */\n", '');
    }
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
