#!/usr/bin/perl

# -----------------------------------------------------------------------
# addColumns.pl
#
# Add a set of columns (in an arbitrary position) to an extant Oracle 
# table.
#
# raddev.ExperimentImageImp 
# raddev.ExperimentImageImpVer
# raddev.ExperimentResultImp
# raddev.ExperimentResultImpVer
#
# Created: Tue Feb 20 14:29:21 EST 2001
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

my $DBI_STR = "dbi:Oracle:host=erebus;sid=gusdev";
my $DBI_ATTS = { 
    RaiseError => 0, 
    AutoCommit => 0, 
    LongReadLen => 10000000,
    ora_session_mode => 2     # connect as SYSDBA
};
my $TEST_ONLY = 0;
my $OLD_SUFFIX = "_dm";

# -----------------------------------------------------------------------
# Input
# -----------------------------------------------------------------------

my $login = shift || die "First argument must be Oracle login";
my $passwd = shift || die "Second argument must be Oracle password";
my $src = shift || die "Third argument must be the name of the source table.";
my $tgt = shift || die "Fourth argument must be the name of the target table.";

my ($srcOwner, $srcTName) = ($src =~ /^([^\.]+)\.([^\.]+)$/);
die "Must specify source table name as owner.table" if (!defined($srcTName));

my ($tgtOwner, $tgtTName) = ($tgt =~ /^([^\.]+)\.([^\.]+)$/);
die "Must specify target table name as owner.table" if (!defined($tgtTName));

# -----------------------------------------------------------------------
# Main program
# -----------------------------------------------------------------------

my $dbh = &Util::establishLogin($login, $DBI_STR, $DBI_ATTS, $passwd);

my $srcTable = new Table({owner => $srcOwner, name => $srcTName});
my $tgtTable = new Table({owner => $tgtOwner, name => $tgtTName});

# 1. Obtain exclusive locks on both tables.  Don't need to lock the
#    tables that reference them.
#
die "Unable to lock $src" if (!$srcTable->lock($dbh, 'EXCLUSIVE'));
die "Unable to lock $tgt" if (!$tgtTable->lock($dbh, 'EXCLUSIVE'));

# 2. Copy all the data from source table -> target table
#
my $numRows = $srcTable->copyTo($dbh, $tgtTable, $TEST_ONLY);

# 3. Drop all constraints referring to the source table
#
my ($dropCons, $createCons) = $srcTable->getConstraintsSql($dbh);

foreach my $drop (@$dropCons) {
    print $drop, "\n";
    $drop =~ s/;\s*$//;
    $dbh->do($drop) if (!$TEST_ONLY);
}

# 4. Drop indexes on the source table
#
my($dropInds, $createInds) = $srcTable->getIndexesSql($dbh);

foreach my $drop (@$dropInds) {
    print $drop, "\n";
    $drop =~ s/;\s*$//;
    $dbh->do($drop) if (!$TEST_ONLY);
}

# 5. Rename the tables (RENAME old TO new)
#
my $oldSrcTName = $srcTName . $OLD_SUFFIX;

print "RENAME $srcTName TO $oldSrcTName\n";
$dbh->do("RENAME $srcTName TO $oldSrcTName") if (!$TEST_ONLY);

print "RENAME $tgtTName TO $srcTName\n";
$dbh->do("RENAME $tgtTName TO $srcTName") if (!$TEST_ONLY);

# 6. Recreate source table indexes
#
foreach my $create (@$createInds) {
    print $create, "\n";
    $create =~ s/;\s*$//;
    $dbh->do($create) if (!$TEST_ONLY);
}

# 7. Recreate source table constraints
#
foreach my $create (@$createCons) {
    print $create, "\n";
    $create =~ s/;\s*$//;
    $dbh->do($create) if (!$TEST_ONLY);
}

# 8. Commit: releases locks
#
$dbh->commit();

# 9. Regenerate statistics for the table
#
print "analyze table $src compute statistics\n";
$dbh->do("analyze table $src compute statistics") if (!$TEST_ONLY);
print "done\n";

$dbh->disconnect();

# Don't need to regenerate views and synonyms.
# DO need to regenerate permissions

