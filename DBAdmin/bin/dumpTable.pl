#!@perl@

# -----------------------------------------------------------------------
# dumpTable.pl
#
# Generate the Oracle DDL required to recreate the objects owned by a  
# given schema.table.
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
my $DB_HOST = "localhost";
my $DBI_ATTS = { RaiseError => 0, AutoCommit => 0, LongReadLen => 10000000 };

# -----------------------------------------------------------------------
# Input
# -----------------------------------------------------------------------

my(
   $login,
   $schema,
   $table,
   $file
   );

&GetOptions("login=s" => \$login,
	    "schema=s" => \$schema,
	    "table=s" => \$table,
	    "file=s" => \$file
	    );

if (!$login || !$schema) {
    print <<USAGE;
Usage: dumpSchema.pl options
  --login=login          # Oracle login
  --schema=owner         # schema whose objects should be dumped
  --table=table          # the table to dump
  --file=prefix          # prefix for the files to create
USAGE
    die "Invalid arguments";
}

# -----------------------------------------------------------------------
# Main program
# -----------------------------------------------------------------------

my $db = Database->new({sid => $DB_SID, host => $DB_HOST});
my $dbh = &Util::establishLogin($login, $db->getDbiStr(), $DBI_ATTS);
my $s = Schema->new({name => $schema});

my $constraintTxt = "";
my $indexTxt = "";
my $fh = new FileHandle();

# Contents of Table
#
#$fh->open("> $table-rows.sql");
#my $ti = Table->new({owner => $schema, name => $table});
#print $fh $ti->getContentsSQL($dbh), "\n";
#$fh->close();

$fh->open("> $table.sql");

# Tables
#
my $tbl = Table->new({owner => $schema, name => $table});
my($dropCons, $createCons) = $tbl->getSelfConstraintsSql($dbh);
my($dropInds, $createInds) = $tbl->getIndexesSql($dbh);
$indexTxt .= join("\n", @$createInds) . "\n\n";
$constraintTxt .= join("\n", @$createCons) . "\n\n";
print $fh $tbl->getSQL($dbh), "\n";

# Sequences
#
my $sequences = $s->getSequences($dbh);
foreach my $seqname (@$sequences) {
    if ($seqname =~ /^${table}_sq$/i) {
			my $seq = Sequence->new({owner => $schema, name => $seqname});
			print $fh $seq->getSQL($dbh, 1), "\n";
    }
}
print $fh "\n";

# Constraints
#
print $fh $constraintTxt, "\n";

# Indexes
#
print $fh $indexTxt, "\n";

# Grants?

$fh->close();
$dbh->disconnect();
