#!/usr/bin/perl

# -----------------------------------------------------------------------
# exportSchema.pl
#
# Export the schema of an Oracle database using the EXPORT utility.
# Also capable of comparing the exported schema to a previous version
# to determine whether any changes have been made.
#
# Created: Tue Feb 27 10:37:05 EST 2001
# 
# Jonathan Crabtree
#
# $Revision$ $Date$ $Author$
# -----------------------------------------------------------------------

use strict;

use Database;

use Getopt::Long;

# -----------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------

my $DB_SID = "gusdev";
my $DB_HOST = "localhost";
my $DBI_ATTS = { RaiseError => 0, AutoCommit => 0, LongReadLen => 10000000 };
my $EXP = 'exp';

# -----------------------------------------------------------------------
# Input
# -----------------------------------------------------------------------

my(
   $login,
   $sid,
   $host,
   $schema,
   $password,
   $file,
   $filePrefix,
   );

&GetOptions("login=s" => \$login,
	    "sid=s" => \$sid,
	    "host=s" => \$host,
	    "schema:s" => \$schema,
	    "password=s" => \$password,
	    "file=s" => \$file,
	    "filePrefix=s" => \$filePrefix,
	    );

if (!$login || !$password || !$sid || !$host || (!$file && !$filePrefix)) {
    print <<USAGE;
Usage: dumpSchema.pl options
  --login=login             # Oracle login
  --sid=sid                 # Oracle SID
  --host=host               # Oracle host
  --schema=schema           # Optional schema name
  --password=password       # Oracle password
  --file=file               # Where to place the exported schema  
  --filePrefix=prefix       # Generate a filename using this prefix (overrides --file)
USAGE
    die "Invalid arguments";
}

# -----------------------------------------------------------------------
# Main program
# -----------------------------------------------------------------------

# Generate filename; default is to use the day of the month so that
# files are overwritten every month or so.
#
if ($filePrefix) {
    my $date = `date`;
    my($day) = ($date =~ /^\S+\s+\S+\s+(\S+)\s+/);

    $file = $filePrefix;
    $file .= "${sid}-";
    $file .= "${schema}-" if ($schema);
    $file .= sprintf("%02d", $day);
}

# Use EXPORT to dump the schema
# 
my $cmd = "exp ${login}/${password}\@${sid} ";

$cmd .= $schema ? "owner=$schema " : "full=Y ";
$cmd .= "compress=N ";
$cmd .= "consistent=Y ";
$cmd .= "constraints=Y ";
$cmd .= "grants=Y ";
$cmd .= "indexes=Y ";
$cmd .= "triggers=Y ";
$cmd .= "direct=N ";
$cmd .= "rows=N ";
$cmd .= "file=$file ";
$cmd .= "log=${file}.log ";

print "[$cmd]\n";
system($cmd);


