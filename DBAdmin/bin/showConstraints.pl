#!@perl@

# -----------------------------------------------------------------------
# showConstraints.pl
#
# Display constraints on a table.
#
# Created: Thu Apr 12 10:41:04 EST 2001
#
# Jonathan Crabtree
#
# $Revision$ $Date$ $Author$
# -----------------------------------------------------------------------

use strict;

use DBI;
use DBD::Oracle;

use GUS::DBAdmin::Table;
use GUS::DBAdmin::Util;

# -----------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------

my $DBI_STR = "dbi:Oracle:host=erebus;sid=gusdev";
my $DBI_ATTS = { 
    RaiseError => 0, 
    AutoCommit => 0, 
    LongReadLen => 10000000
    };

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

if ($login =~ /^sys$/i) { $DBI_ATTS->{ora_session_mode} = 2; }

my $dbh = &GUS::DBAdmin::Util::establishLogin($login, $DBI_STR, $DBI_ATTS);

my $srcTable = new GUS::DBAdmin::Table({owner => $srcOwner, name => $srcTName});

my($dropCons, $createCons) = $srcTable->getConstraintsSql($dbh);
my($dropInds, $createInds) = $srcTable->getIndexesSql($dbh);

print "Constraints (drop):\n";
map { print $_, "\n"; } @$dropCons;

print "\n";
print "Constraints (create):\n";
map { print $_, "\n"; } @$createCons;

print "\n";
print "Indexes (drop):\n";
map { print $_, "\n"; } @$dropInds;

print "\n";
print "Indexes (create):\n";
map { print $_, "\n"; } @$createInds;

$dbh->disconnect();

