#######################################################################
##                 InsertFile.pm
##
## Load data from a tab-delimited file. Input file should have newlines between records and tabs between fields within a record. First record should contain a tab-delimited set of column names
## $Id$
##
#######################################################################

package GUS::Community::Plugin::InsertFile;
@ISA = qw( GUS::PluginMgr::Plugin);

use strict 'vars';


use GUS::PluginMgr::Plugin;
use lib "$ENV{GUS_HOME}/lib/perl";
# use FileHandle;
# use Carp;

my $argsDeclaration =
  [
   fileArg({ name => 'file',
             descr => 'input file',
             reqd => 1,
             mustExist => 1,
             format => 'tab-delimited',
             constraintFunc => undef,
             isList => 0,
           }),
   stringArg({ name  => 'table',
               descr => "the database table in which to load records. Must have a column named FILE, as well as one for each column named in the input file",
               constraintFunc => undef,
               reqd => 1,
               isList => 0 }),
 integerArg({ name => 'commitInterval',
              descr => 'number of inserts to perform between committing transactions',
              constraintFunc => undef,
              reqd => 0,
              isList => 0
            }),
  ];


my $purposeBrief = <<PURPOSEBRIEF;
Loads data from the given tab-delimited file into the given databaes table
PURPOSEBRIEF

my $purpose = <<PLUGIN_PURPOSE;
Loads data from the given tab-delimited file into the given databaes table. The first record should be a tab-seprated list of column names. The named table must have all those columns, as well as one named FILE.
PLUGIN_PURPOSE

my $tablesAffected =
        [];

my $tablesDependedOn = [];

my $howToRestart = <<PLUGIN_RESTART;
No restart facility available.
PLUGIN_RESTART

my $failureCases = <<PLUGIN_FAILURE_CASES;
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
PLUGIN_NOTES

my $documentation = { purpose=>$purpose,
                      purposeBrief=>$purposeBrief,
                      tablesAffected=>$tablesAffected,
                      tablesDependedOn=>$tablesDependedOn,
                      howToRestart=>$howToRestart,
                      failureCases=>$failureCases,
                      notes=>$notes
                    };

my $inputFile;
my $table = "not initialized";
my $insertStmt;

sub new {
    my ($class) = @_;
    my $self = {};
    bless($self,$class);

    $self->initialize({requiredDbVersion => 4.0,
                       cvsRevision => '$Revision$', # cvs fills this in!
                       name => ref($self),
                       argsDeclaration => $argsDeclaration,
                       documentation => $documentation
                      });

    return $self;
}

#######################################################################
# Main Routine
#######################################################################

sub run {
    my ($self) = @_;

    $inputFile = $self->getArg('file');
    $table = $self->getArg('table');
    my $commitInterval = $self->getArg('commitInterval') || 10000;

    open (FILE, $inputFile) || die "Can't open input file \"$inputFile\".";
    if ($inputFile =~ m!\/([^/]*)$! ) {
      $inputFile = $1;
    }

    my $insertCount;

    while (<FILE>) {
      chomp;

      my @inputRecord = split /\t/;

      if (!$insertStmt) {
        # first trip: input record names columns; insert statement must be prepared
        my $sql = "insert into $table ("
                  . "filename, "
                  . join(", ", map({my $s = $_; $s =~ s/\.//g; $s} @inputRecord)) # remove periods from field names
                  . ") values ("
                  . "?, "  # placeholder for file column
                  . join(', ', (map {"?"} @inputRecord))
                  . ")";
	print "\$sql = \"$sql\"\n";
	$insertStmt = $self->getQueryHandle()->prepare($sql) or die DBI::errstr;
      } else {
        # subsequent trip: input record contains data to insert

	unshift(@inputRecord, $inputFile);
	my @inputRecord =  map({my $s = $_; $s =~ s/^NA$/NULL/g; $s} @inputRecord); # change "NA" to null string
	$insertStmt->execute(@inputRecord) or die DBI::errstr;
	$insertStmt->finish();

        # at intervals, log and commit
        unless (++$insertCount % $commitInterval) {
          $self->undefPointerCache();
          print STDERR "inserted $insertCount records\n";
        }
      }
    }

    if ($self->getArg('commit')) {
      $self->getQueryHandle()->commit();
    }

    $self->undefPointerCache();

    my $msg = "$insertCount records inserted";
    return $msg;
}

1;
