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

use GUS::DBAdmin::Database;
use GUS::DBAdmin::Schema;

use Getopt::Long;

# -----------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------

my $DBI_ATTS = { RaiseError => 0, AutoCommit => 0, LongReadLen => 10000000 };

# -----------------------------------------------------------------------
# Input
# -----------------------------------------------------------------------

my(
   $dbSid,
   $dbHost,
   $dbPort,
   $login,        # Oracle login with grant/revoke permissions
   $permissions,  # list of permissions to grant/revoke
   $grantees,     # list of users & roles to grant permissions to
   $revoke,       # revoke instead of grant
   $owner,        # grant/revoke $permissions to objects owned by this schema
   $verbose
   );

&GetOptions("db-sid=s" => \$dbSid,
	    "db-host=s" => \$dbHost,
	    "db-port=s" => \$dbPort,
	    "login=s" => \$login,
	    "permissions=s" => \$permissions,
	    "grantees=s" => \$grantees,
	    "revoke!" => \$revoke,
	    "owner=s" => \$owner,
	    "verbose!" => \$verbose
	    );

if (!$dbSid || !$dbHost || !$login || !$permissions || !$grantees || !$owner) {
    print <<USAGE;
Usage: grantPermissions.pl options
   --db-sid=SID                # SID of the Oracle server
   --db-host=hostname          # Hostname of the Oracle server
   --db-port=portnum           # Port on which the Oracle server will accept connections
   --login=login               # Oracle login with grant/revoke permissions on the objects owned by --owner
   --permissions=p1,p2,..      # list of permissions to grant/revoke
   --grantees=u1,u2,...        # List of users or roles to grant permissions to
   --revoke                    # Revoke listed permissions instead of granting them
   --owner=owner               # Grant/revoke --permissions to all objects owned by this schema
   --verbose
USAGE
    die "Invalid arguments";
}

# -----------------------------------------------------------------------
# Main program
# -----------------------------------------------------------------------

$| = 1;

my $db = GUS::DBAdmin::Database->new({sid => $dbSid, host => $dbHost, port => $dbPort});
my $dbh = &GUS::DBAdmin::Util::establishLogin($login, $db->getDbiStr(), $DBI_ATTS);

my @perms = split(',',  $permissions);
my @grantees = split(',', $grantees);

# If no object specified, list all owned by $owner
#
my $s = GUS::DBAdmin::Schema->new({name => $owner});

my $tables = $s->getTables($dbh);
my $ntables = scalar(@$tables);
my $views = $s->getViews($dbh);
my $nviews = scalar(@$views);
my $seqs = $s->getSequences($dbh);
my $nseqs = scalar(@$seqs);

my @objects = (@$tables, @$views, @$seqs);

# Run the grants/revokes
#
my $ntg = &runGrants($dbh, $tables, \@grantees, \@perms, {'select' => 1,
							  'update' => 1,
							  'insert' => 1,
							  'delete' => 1,
							  'references' => 1,
						      });

my $nvg = &runGrants($dbh, $views, \@grantees, \@perms, {'select' => 1,
							 'update' => 1,
							 'insert' => 1,
							 'delete' =>1,
						     });

my $nsg = &runGrants($dbh, $seqs, \@grantees, \@perms, {'select' => 1, 
							'alter' => 1,
						    });


print "Permissions set on ${ntg}/${ntables} table(s), ${nvg}/${nviews} view(s) and ${nsg}/${nseqs} sequence(s)\n";

$dbh->commit();
$dbh->disconnect();

# -----------------------------------------------------------------------
# Subroutines
# -----------------------------------------------------------------------

# Run the specified GRANT statements on a set of objects, allowing
# only those operations listed in $validPerms.
#
sub runGrants {
    my($dbh, $objects, $grantees, $perms, $validPerms) = @_;
    my $numAffected = 0;

    foreach my $obj (@$objects) {
	my $grantsRun = 0;

	foreach my $grantee (@$grantees) {
	    foreach my $perm (@$perms) {
		$perm =~ tr/A-Z/a-z/;

		if (not defined($validPerms->{$perm})) {
		    print "[$perm not valid for $obj: ignoring]\n" if ($verbose);
		    next;
		}

		my $cmd = $revoke ? 'revoke' : 'grant';
		$cmd .= " $perm on ${owner}.${obj} ";
		$cmd .= $revoke ? 'from' : 'to';
		$cmd .= " $grantee";
		
		print "[$cmd]\n" if ($verbose);
		$dbh->do($cmd);
		$grantsRun = 1;
	    }
	}
	++$numAffected if ($grantsRun);
    }
    return $numAffected;
}
