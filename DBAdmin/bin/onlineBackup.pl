#!@perl@

# -----------------------------------------------------------------------
# onlineBackup.pl
#
# Make an online ("hot") backup of an Oracle database.  The database
# must be running in ARCHIVELOG mode for such a backup to be useful.
#
# Force a log switch: ALTER SYSTEM SWITCH LOGFILE
# (this begins a checkpoint but returns control immediately)
#
# Created: Sat Feb 24 11:31:31 EST 2001
#
# Jonathan Crabtree
#
# $Revision$ $Date$ $Author$
# -----------------------------------------------------------------------

use strict;
use Database;

use FileHandle;
use Getopt::Long;

# -----------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------

my $DB_SID = "gusdev";
my $DB_HOST = "erebus";
my $DBI_ATTS = { 
    RaiseError => 0, 
    LongReadLen => 10000000,
    ora_session_mode => 2     # connect as SYSDBA
    };

# -----------------------------------------------------------------------
# Input
# -----------------------------------------------------------------------

my(
   $login,
   $tarFile,
   $logDir,
   $tablespaces,
   $datafilesOnly,
   $archivedLogsOnly,
   $maxFiles,
   $forceSwitch,
   $testOnly,
   $password,
   $gzip
   );

&GetOptions("login=s" => \$login,
	    "tarFile=s" => \$tarFile,
	    "logDir=s" => \$logDir,
	    "tablespaces:s" => \$tablespaces,
	    "datafilesOnly!" => \$datafilesOnly,
	    "archivedLogsOnly!" => \$archivedLogsOnly,
	    "maxFiles=s" => \$maxFiles,
	    "forceSwitch!" => \$forceSwitch,
	    "testOnly!" => \$testOnly,
	    "password:s" => \$password,
	    "gzip!" => \$gzip,
	    );

if (!$login || !$tarFile || !$logDir) {
    print <<USAGE;
Usage: onlineBackup.pl options
  --login=login          # Oracle login with system privileges
  --password=password    # Password: will prompt for this if not provided
  --tarFile=file/device  # tar file or device
  --logDir=directory     # Directory for log & control files
  --tablespaces=list     # (optional) List of tablespaces to back up; default is all
  --datafilesOnly        # Do not back up archived redo logs
  --archivedLogsOnly     # Only back up archived redo logs
  --maxFiles             # Maximum number of archived logs to back up
  --forceSwitch          # Force a log switch in order to ensure that the current log is archived
  --testOnly             # Do not write anything to tape
  --gzip                 # Use gzip compression with tar
USAGE
    die "Invalid arguments";
}

# -----------------------------------------------------------------------
# Main program
# -----------------------------------------------------------------------

# Uses the start time to tag files created
#
my $dt = `date`; chomp($dt);
my $date = $dt;
$date =~ s/ /-/g;

my $shortDate = $date;
$shortDate =~ s/^\S+\s//;

# Write all activity to a log file
#
my $logFile = "${logDir}/${DB_SID}-${shortDate}.log";
my $log = FileHandle->new();

$log->open("> $logFile");
die "Unable to open log file $logFile" if (!defined($log));
$log->autoflush(1);

# Where to place the backup of the control file
#
my $ctlFile = "${logDir}/${DB_SID}-${shortDate}.ctl";

# Function that backs up a single datafile/log file to tape.
#
my $backupFn = sub {
    my($files) = @_;
    my $nfiles = [];

    foreach my $file (@$files) {
	die "Unable to read file '$file'" if (!-r $file);

	# Remove leading '/'; cd to / before running tar command
	#
	$file =~ s/^\///;
	push(@$nfiles, $file);
    }

    # Note: cannot use both compression and --multi-volume
    #
    my $cmd = 'cd /; tar --create';

    $cmd .= " --label 'Online backup of Oracle db ${DB_SID}\@${DB_HOST}: $date' ";
    $cmd .= " --file $tarFile ";
    $cmd .= ' --verbose ';
    $cmd .= ' --gzip ' if ($gzip);
#    $cmd .= ' --multi-volume ';
    $cmd .= ' --preserve-permissions ';
    $cmd .= ' --sparse ';

    $cmd .= " " . join(' ', @$nfiles);

    $log->print(" [$cmd]\n");
    system($cmd) if (!$testOnly);
};

my $db = Database->new({sid => $DB_SID, host => $DB_HOST});
my $dbh = &Util::establishLogin($login, $db->getDbiStr(), $DBI_ATTS, $password);

my $tspaces;
my $msg = '';

if (defined($tablespaces)) {
    my @tspacenames = split(',', $tablespaces);
    $tspaces = [];
    foreach my $name (@tspacenames) {
	push(@$tspaces, Tablespace->new({db => $db, name => $name}));
    }
} else {
    $tspaces = $db->getTablespaces($dbh);
    $msg = '(all tablespaces)';
}

my $nTSs = scalar(@$tspaces);

$log->print("$dt: backing up $DB_SID\n");
$log->print("TABLESPACES=", join(" ", map {$_->toString()} @$tspaces), " $msg\n");

# 1. Back up the control file
#    (does it make a difference if this comes before/after tablespace backup?)
#
$log->print("Backing up control file to $ctlFile..");
$dbh->do("alter database backup controlfile to '$ctlFile'");
$log->print("..done\n");

# 2. Checkpoint the database
#    (writes all committed transactions to the datafiles)
#
$log->print("Checkpointing database..");
$dbh->do("alter system checkpoint");
$log->print("..done\n");

# 3. Back up each tablespace in turn
#
if (!$archivedLogsOnly) {
    foreach my $ts (@$tspaces) {
	my $args = {backupFn => $backupFn, log => $log};
	$ts->onlineBackup($dbh, $args);
    }
}

# 4. Back up the archived redo logs
#
if (!$datafilesOnly) {
    my $args = {backupFn => $backupFn, log => $log};
    $args->{maxFiles} = $maxFiles if (defined($maxFiles));
    $args->{forceSwitch} = $forceSwitch if (defined($forceSwitch));
    $args->{testOnly} = $testOnly if (defined($testOnly));
    $db->backupArchivedRedoLogs($dbh, $args);
}

$dbh->commit();
$dbh->disconnect();

# Close log file.
#
$dt = `date`; chomp($dt);
$log->print("$dt: completed online backup of $DB_SID\n");
$log->close();

# Add backed up control file and log file to the tar file.
#
&$backupFn([$logFile, $ctlFile]);


