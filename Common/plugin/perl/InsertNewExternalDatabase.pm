package GUS::Common::Plugin::InsertNewExternalDatabase;
@ISA = qw( GUS::PluginMgr::Plugin);

use GUS::PluginMgr::Plugin;

use lib "$ENV{GUS_HOME}/lib/perl";

use strict 'vars';

use FileHandle;
use Carp;


use GUS::Model::SRes::ExternalDatabase;

sub new {

    #create
    my $class = shift;
    my $self = bless{}, $class;
    
    #init
    my $purposeBrief = "Creates a new entry in table SRes.ExternalDatabase to represent a new source of data imported into GUS.";
    
    my $purpose = "Simple plugin that is the easiest way to create a row representing a new database that exists in the outside world that will be imported into GUS.  This entry serves as a stable identifier across multiple releases of the database (which are stored in SRes.ExternalDatabaseRelease and point back to the entry created by this plugin).  Protects against making multiple entries in GUS for an external database that already exists there (see notes below).";
    
    my $tablesAffected = 
	[['SRes.ExternalDatabase', 'The entry representing the new external database is created here']];

    my $tablesDependedOn = [];

    my $howToRestart = "Only one row is created, so if the plugin fails, restart by running it again with the same parameters (accounting for any errors that may have caused the failure.";

    my $notes = "The way the plugin checks to make sure there is not already an entry representing this database is by case-insensitive matching against the name.  There is a chance, however, that the user could load a duplicate entry, representing the same database, but with different names, because of a misspelling or alternate naming convention.  This cannot be guarded against, so it is up to the user to avoid duplicate entries when possible.";

    my $failureCases = "If the entry already exists, based on the --name flag and a corresponding name in the table, then the plugin does not submit a new row.  This is not a failure case per se, but will result in no change to the database where one might have been expected";

    my $documentation = { purpose=>$purpose,
			  purposeBrief=>$purposeBrief,
			  tablesAffected=>$tablesAffected,
			  tablesDependedOn=>$tablesDependedOn,
			  howToRestart=>$howToRestart,
			  failureCases=>$failureCases,
			  notes=>$notes
			  };
    
    my $argsDeclaration = 
	[
	 stringArg({name => 'name',
		    descr => 'name of the external database to be inserted',
		    reqd => 1,
		    constraintFunc => undef,
		    isList => 0,
		}),
	 ];
    
    $self->initialize({requiredDbVersion => {},
		       cvsRevision => '$Revision$', # cvs fills this in!
		       cvsTag => '$Name$', # cvs fills this in!
		       name => ref($self),
		       revisionNotes => 'added attributes and changed to new-style plugin usage',
		       argsDeclaration => $argsDeclaration,
		       documentation => $documentation
		       });
    
	 
    return $self;
}

sub run {
    my $self = shift;

    my $dbName = $self->getCla->{name};

    my $msg;

    my $sql = "select external_database_id from sres.externaldatabase where lower(name) like '" . lc($dbName) ."'";
    my $sth = $self->getQueryHandle()->prepareAndExecute($sql);
    
    my ($dbId) = $sth->fetchrow_array();

    if ($dbId){
	$msg = "Not creating a new entry for $dbName as one already exists in the database (id $dbId)";
    }

    else {
	my $newDatabase = GUS::Model::SRes::ExternalDatabase->new({
	    name => $dbName,
	    lowercase_name => lc($dbName),
	});
	$newDatabase->submit();
	my $newDatabasePk = $newDatabase->getId();
	$msg = "created new entry for database $dbName with primary key $newDatabasePk";
    }

    return $msg;
}
    


							      
