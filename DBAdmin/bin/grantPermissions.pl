#!@perl@

# -----------------------------------------------------------------------
# grantPermissions.pl
#
# Created: Sun Feb 25 11:24:59 EST 2001
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
   $login,        # Oracle login with grant/revoke permissions
   $permissions,  # list of permissions to grant/revoke
   $grantees,     # list of users & roles to grant permissions to
   $revoke,       # revoke instead of grant
   $owner,        # grant/revoke $permissions to objects owned by this schema
   $verbose
   );

&GetOptions("login=s" => \$login,
	    "permissions=s" => \$permissions,
	    "grantees=s" => \$grantees,
	    "revoke!" => \$revoke,
	    "owner=s" => \$owner,
	    "verbose!" => \$verbose
	    );

if (!$login || !$permissions || !$grantees || !$owner) {
    print <<USAGE;
Usage: grantPermissions.pl options
   --login=login       # Oracle login with grant/revoke permissions
   --permissions=list  # list of permissions to grant/revoke
   --grantees=list     # list of users & roles to grant permissions to
   --revoke            # revoke instead of grant
   --owner=owner       # grant/revoke $permissions to objects owned by this schema
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

my @perms = split(',',  $permissions);
my @grantees = split(',', $grantees);

# If no object specified, list all owned by $owner
#
my $s = Schema->new({name => $owner});

my $tables = $s->getTables($dbh);
my $ntables = scalar(@$tables);
my $views = $s->getViews($dbh);
my $nviews = scalar(@$views);
my $seqs = $s->getSequences($dbh);
my $nseqs = scalar(@$seqs);

my @objects = (@$tables, @$views, @$seqs);

# Run the grants/revokes
#
&runGrants($dbh, $tables, \@grantees, \@perms, {'select' => 1,
					       'update' => 1,
					       'insert' => 1,
					       'delete' =>1});

&runGrants($dbh, $views, \@grantees, \@perms, {'select' => 1,
					       'update' => 1,
					       'insert' => 1,
					       'delete' =>1});

&runGrants($dbh, $seqs, \@grantees, \@perms, {'select' => 1, 
					      'alter' => 1});


print "Permissions set on $ntables tables, $nviews views and $nseqs sequences\n";

$dbh->commit();
$dbh->disconnect();

# -----------------------------------------------------------------------
# Subroutines
# -----------------------------------------------------------------------

sub runGrants {
    my($dbh, $objects, $grantees, $perms, $validPerms) = @_;

    foreach my $obj (@$objects) {
	foreach my $grantee (@$grantees) {
	    foreach my $perm (@$perms) {

		$perm =~ tr/A-Z/a-z/;
		if (not defined($validPerms->{$perm})) {
		    print "$perm not valid for $obj: ignoring\n";
		    next;
		}

		my $cmd = $revoke ? 'revoke' : 'grant';
		$cmd .= " $perm on ${owner}.${obj} ";
		$cmd .= $revoke ? 'from' : 'to';
		$cmd .= " $grantee";
		
		print "[$cmd]\n" if ($verbose);
		$dbh->do($cmd);
	    }
	}
    }
}
