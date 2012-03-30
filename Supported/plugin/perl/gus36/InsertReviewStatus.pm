#######################################################################
##                 InsertReviewStatus.pm
##
## Creates a new entry in table SRes.ReviewStatus to represent
## a new review code in GUS
## $Id: InsertGOEvidenceCode.pm 2822 2005-06-13 22:57:43Z sfischer $
##
#######################################################################
 
# this plugin is incompatible with version 4.0 of GUS because it references tables
# which have been dropped, such as sres.ReviewStatus

package GUS::Supported::Plugin::InsertReviewStatus;
@ISA = qw( GUS::PluginMgr::Plugin);

use strict 'vars';

use GUS::PluginMgr::Plugin;
use lib "$ENV{GUS_HOME}/lib/perl";
use FileHandle;
use Carp;
use GUS::Model::SRes::ReviewStatus;

my $argsDeclaration = 
  [
   stringArg({name => 'name',
	      descr => 'the new review code to be inserted. i.e. reviewed, unreviewed, etc.',
	      reqd => 1,
	      constraintFunc => undef,
	      isList => 0,
	     }),

   stringArg({name=> 'description',
	      descr => 'description of the review code',
	      reqd => 1,
	      constraintFunc => undef,
	      isList => 0,
	     })
  ];

my $purposeBrief = <<PURPOSEBRIEF;
Creates a new entry in table SRes.ReviewStatus to represent a new review status code in GUS.
PURPOSEBRIEF
    
my $purpose = <<PLUGIN_PURPOSE;
Simple plugin that is the easiest way to create a row representing a new review status code in GUS.  Protects against making multiple entries in GUS for a review status code that already exists there (see notes below).
PLUGIN_PURPOSE
   
my $tablesAffected = 
	[['SRes.ReviewStatus', 'The entry representing the new review status code is created here']];

my $tablesDependedOn = [];

my $howToRestart = <<PLUGIN_RESTART;
Only one row is created, so if the plugin fails, restart by running it again with the same parameters (accounting for any errors that may have caused the failure).
PLUGIN_RESTART

my $failureCases = <<PLUGIN_FAILURE_CASES;
If the entry already exists, based on the --name flag and a corresponding name in the table, then the plugin does not submit a new row.  This is not a failure case per se, but will result in no change to the database where one might have been expected.
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
The way the plugin checks to make sure there is not already an entry representing this evidence code is by case-insensitive matching against the name.  There is a chance, however, that the user could load a duplicate entry, representing the same evidence code, but with different names, because of a misspelling or alternate naming or capitalization convention.  This cannot be guarded against, so it is up to the user to avoid duplicate entries when possible.
PLUGIN_NOTES

my $documentation = { purpose=>$purpose,
		      purposeBrief=>$purposeBrief,
		      tablesAffected=>$tablesAffected,
		      tablesDependedOn=>$tablesDependedOn,
		      howToRestart=>$howToRestart,
		      failureCases=>$failureCases,
		      notes=>$notes
		    };

sub new {
    my ($class) = @_;
    my $self = {};
    bless($self,$class);

    $self->initialize({requiredDbVersion => 3.6,
		       cvsRevision => '$Revision: 2822 $', # cvs fills this in!
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
    my $self = shift;
    my $dbName = $self->getArg('name');
    my $dbDescription = $self->getArg('description');
    my $msg;

    my $sql = "select name from sres.reviewstatus where lower(name) like '" . lc($dbName) ."'";
    my $sth = $self->prepareAndExecute($sql);
    my ($dbId) = $sth->fetchrow_array();

    if ($dbId){
	$msg = "Not creating a new entry for $dbName as one already exists in the database (id $dbId)";
    }

    else {
	my $newDatabase = GUS::Model::SRes::ReviewStatus->new({
	    name => $dbName,
	    description => $dbDescription
	   });
	$newDatabase->submit();
	my $newDatabasePk = $newDatabase->getId();
	$msg = "created new entry for database $dbName with primary key $newDatabasePk";
    }

    return $msg;
}

1;
