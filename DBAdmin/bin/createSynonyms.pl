#!@perlLocation@

# -----------------------------------------------------------------------
# createSynonyms.pl
#
# Created: Sun Feb 25 19:24:19 EST 2001
#
# Jonathan Crabtree
#
# $Revision$ $Date$ $Author$
# -----------------------------------------------------------------------

use strict;

use Database;
use Schema;

use Getopt::Long;

# -----------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------

my $DB_SID = "gus";
my $DB_HOST = "localhost";
my $DBI_ATTS = { RaiseError => 0, AutoCommit => 0, LongReadLen => 10000000 };

# -----------------------------------------------------------------------
# Input
# -----------------------------------------------------------------------

my(
   $login,        # Oracle login with create synonym privileges
   $targets,      # list of users who will own the new synonyms
   $owner,        # create synonyms for every object owned by this schema
   $verbose
   ) = @_;

&GetOptions("login=s" => \$login,
	    "targets=s" => \$targets,
	    "owner=s" => \$owner,
	    "verbose!" => \$verbose
	    );

if (!$login || !$targets || !$owner) {
    print <<USAGE;
Usage: grantPermissions.pl options
   --login=login       # Oracle login with CREATE SYNONYM privilege
   --targets=list      # list of users who wil own the new synonyms
   --owner=owner       # create synonyms for every object owned by this schema
   --verbose
USAGE
    die "Invalid arguments";
}

# -----------------------------------------------------------------------
# Main program
# -----------------------------------------------------------------------

$| = 1;

my $db = Database->new({sid => $DB_SID, host => $DB_HOST});
my $dbh = &Util::establishLogin($login, $db->getDbiStr(), $DBI_ATTS);

my @targets = split(',', $targets);

# If no object specified, create synonyms for all owned by $owner
#
my $s = Schema->new({name => $owner});

my $tables = $s->getTables($dbh);
my $ntables = scalar(@$tables);
my $views = $s->getViews($dbh);
my $nviews = scalar(@$views);
my $seqs = $s->getSequences($dbh);
my $nseqs = scalar(@$seqs);

my @objects = (@$tables, @$views, @$seqs);

foreach my $obj (@objects) {
    foreach my $target (@targets) {
	my $cmd = "create synonym ${target}.${obj} for ${owner}.${obj}";
	print "[$cmd]\n" if ($verbose);
	$dbh->do($cmd);
    }
}

print "Synonyms created for $ntables tables, $nviews views and $nseqs sequences\n";

$dbh->commit();
$dbh->disconnect();
