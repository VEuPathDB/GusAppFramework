#!/usr/bin/perl

# -----------------------------------------------------------------------
# Tablespace.pm
#
# An Oracle tablespace.
#
# Created: Sat Feb 24 11:31:31 EST 2001
#
# Jonathan Crabtree
#
# $Revision$ $Date$ $Author$
# -----------------------------------------------------------------------

package Tablespace;

use Util;

# -----------------------------------------------------------------------
# Constructor
# -----------------------------------------------------------------------

sub new {
    my($class, $args) = @_;

    my $self = {
	db => $args->{db},
	name => $args->{name},
    };

    bless $self, $class;
    return $self;
}

# -----------------------------------------------------------------------
# Tablespace
# -----------------------------------------------------------------------

sub toString() {
    my($self) = @_;
    return $self->{name};
}

sub getDatafiles {
    my($self, $dbh) = @_;
    my $name = $self->{name};

    my $sql = ("select ddf.file_name " .
	       "from dba_data_files ddf " .
	       "where ddf.tablespace_name = upper('$name')");

    return &Util::execQuery($dbh, $sql, 'scalar');
}

# Perform an on-line ("hot") backup of all the datafiles in this tablespace.
#
# backupFn  A function that will back up a single file.
#
sub onlineBackup {
    my($self, $dbh, $args) = @_;

    my $backupFn = $args->{backupFn};
    my $log = $args->{log};

    my $name = $self->{name};
    my $files = $self->getDatafiles($dbh);
    my $nfiles = scalar(@$files);

    $log->print("Performing online backup of tablespace $name") if ($log);
    $log->print(" ($nfiles datafile(s))\n") if ($log);

    # Ensure tablespace isn't already in backup mode due to
    # an earlier failed backup attempt.
    #
    $dbh->do("alter tablespace $name end backup" );

    # 1. Place tablespace into online backup mode
    #
    $log->print("Placing tablespace $name into backup mode..") if ($log);
    $dbh->do("alter tablespace $name begin backup" );
    $log->print("..done\n") if ($log);

    # 2. Back up each datafile in turn
    #
    $log->print("Backing up $name..");
    &$backupFn($files);
    $log->print("..done\n");

    # 3. Restore backup status of the tablespace
    #
    $log->print("Taking tablespace $name out of backup mode..") if ($log);
    $dbh->do("alter tablespace $name end backup" );
    $log->print("..done\n") if ($log);
}

1;
