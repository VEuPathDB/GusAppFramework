#!@perl@

# -----------------------------------------------------------------------
# Database.pm
#
# Perl object that represents an Oracle database (instance).
#
# Created: Sat Feb 24 11:27:39 EST 2001
#
# Jonathan Crabtree
#
# $Revision$ $Date$ $Author$
# -----------------------------------------------------------------------

package GUS::DBAdmin::Database;

use GUS::DBAdmin::Tablespace;
use GUS::DBAdmin::Util;

# -----------------------------------------------------------------------
# Constructor
# -----------------------------------------------------------------------

sub new {
    my($class, $args) = @_;

    my $self = {
	host => $args->{host},
	port => $args->{port},
	sid => $args->{sid},
    };

    bless $self, $class;
    return $self;
}

# -----------------------------------------------------------------------
# Database
# -----------------------------------------------------------------------

sub toString {
    my($self) = @_;

    my $host = $self->{host};
    my $port = $self->{port};
    my $sid = $self->{sid};

    return "${sid}@${host}:${port}";
}

# Returns the string used to identify the DB in DBI/DBD::Oracle
#
sub getDbiStr {
    my($self) = @_;

    my $host = $self->{host};
    my $port = $self->{port};
    my $sid = $self->{sid};

    return ("dbi:Oracle:host=${host}" . 
	    (defined($port) ? ":${port}" : "") .
	    ";sid=${sid}");
}

# Returns an arrayref of all the tablespaces in the database.
#
sub getTablespaces {
    my($self, $dbh) = @_;
    my $sql = "select tablespace_name from dba_tablespaces";
    my $tsNames = &GUS::DBAdmin::Util::execQuery($dbh, $sql, 'scalar');
    my $list = [];

    foreach my $ts (@$tsNames) {
	push(@$list, GUS::DBAdmin::Tablespace->new({db => $self, name => $ts}));
    }

    return $list;
}

# Back up all current archived redo logs
#
sub backupArchivedRedoLogs {
    my($self, $dbh, $args) = @_;

    my $backupFn = $args->{backupFn};
    my $log = $args->{log};
    my $forceSwitch = $args->{forceSwitch};
    my $testOnly = $args->{testOnly};

    # A hack to prevent trying to put too many files on one
    # tape; allows a maximum to be specified.
    #
    my $maxFiles = $args->{maxFiles};

    # Force a log switch, if requested.
    #
    if ($forceSwitch) {
	$log->print(" Forcing switch of logfiles..") if ($log);
	$dbh->do("alter system switch logfile") if (!$testOnly);
	$log->print("done..\n") if ($log);

	# Give the ARC process enough time to begin archiving
	#
	sleep(30);
    }

    # Temporarily halt the archiving process
    #
    $log->print(" Halting archive log writer\n") if ($log);
    &svrmgrCommand("archive log stop");

    # Query v$archive_processes to ensure that there are no archive
    # processes running.  Must do this because 'archive log stop' 
    # returns immediately and any archiving operations in progress
    # at the time of the command will still finish.
    # 
    while (1) {
	my $sql = "select count(*) from v\$archive_processes where state = 'BUSY'";
	my $rows = &GUS::DBAdmin::Util::execQuery($dbh, $sql, 'scalar');

	# Should return exactly one row
	#
	if (scalar(@$rows) != 1) {
	    $log->print("ERROR running statement '$sql'") if ($log);
	    $log->print(" Restarting archive log writer\n") if ($log);
	    &svrmgrCommand("archive log start");
	    return;
	}

	my $val = $rows->[0];

	$log->print(" Number of busy ARC processes = $val\n") if ($log);
	last if ($val == 0);
	sleep(30);
    }

    # Query database to determine archived log destination 
    # directories.
    #
    my $sql = ("select destination " .
	       "from v\$archive_dest " .
	       "where status = 'VALID' ");

    my $logDirs = &GUS::DBAdmin::Util::execQuery($dbh, $sql, 'scalar');

    # List the contents of each directory
    #
    my $listings = {};
    my $nds = scalar(@$logDirs);

    $log->print(" Listing archived log files in $nds directories..") if ($log);

    foreach my $ld (@$logDirs) {
	opendir(LD, $ld);
	my @logFiles = grep(/\.arc$/, readdir(LD));
	closedir(LD);
	$listings->{$ld} = \@logFiles;
    }

    $log->print("..done\n") if ($log);

    # Resume archiving
    #
    $log->print(" Restarting archive log writer\n") if ($log);
    &svrmgrCommand("archive log start");

    # Back up and compress each listed file.  Assumes that files
    # with the same name are identical and only backs these up once.
    # All files are compressed, however.
    # 
    my $backedUp = {};

    # TO DO - have a way to specify a preferred directory from which
    #         to make the backups, if more than one.

    my $numFiles = 0;

    foreach my $logDir (keys %$listings) {
	my $filesToTar = [];
	my $filesToZip = [];
	my @sorted = sort @{$listings->{$logDir}};

	foreach my $logFile (@sorted) {
	    my $lf = "${logDir}/${logFile}";

	    if (not defined($backedUp->{$logFile})) {

		# Only add a file to the current job if we have < $maxFiles already
		#
		if (!$maxFiles || ($numFiles < $maxFiles)) {
		    push(@$filesToTar, $lf);
		    push(@$filesToZip, $lf);
		    $backedUp->{$logFile} = 1;
		    ++$numFiles;
		}
	    } else {
		push(@$filesToZip, $lf);
	    }
	}

	# Rename files once they've been backed up
	#
	&$backupFn($filesToTar) if (scalar(@$filesToTar) > 0);
	foreach my $lf (@$filesToZip) {
#	    my $cmd = "gzip $lf";
	    my $cmd = "mv $lf $lf.tape";
	    $log->print(" [$cmd]\n") if ($log);
	    system($cmd) if (!$testOnly);
	}
    }
}

sub svrmgrCommand {
    my($cmd) = @_;
    my $str = "echo 'connect / as sysdba;\n${cmd}\nexit;\n' | sqlplus /nolog";

#    print STDERR "Running '$str'\n";
    system($str);
}

1;
