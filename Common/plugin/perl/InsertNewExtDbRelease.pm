package GUS::Common::Plugin::InsertNewExtDbRelease;
@ISA = qw( GUS::PluginMgr::Plugin);

use GUS::PluginMgr::Plugin;

use lib "$ENV{GUS_HOME}/lib/perl";

use strict 'vars';

use FileHandle;
use Carp;
use GUS::Model::SRes::ExternalDatabaseRelease;

sub new {
    
    # create
    my $class = shift;
    my $self = bless{}, $class;
    # initialize

    my $purposeBrief = "Creates new entry in table SRes.ExternalDatabaseRelease for new external database versions"; 
    
    my $purpose = "Simple plugin that is the easiest way to create a row representing a new release of a database from an external source.  Protects against making an entry for a version that already exists for a particular database.";

    my $tablesAffected = 
	[['SRes.ExternalDatabaseRelease', 'The entry representing the new release is created here']];

    my $tablesDependedOn = 
	[['SRes.ExternalDatabase', 'There must be an entry in this table representing the database itself; the release to be created will point to it'],
	 ['SRes.ExternalDatabaseRelease', 'If there is already an entry in this table with the same version as the release to be created, then no action is taken']];
	 
    my $howToRestart = "Only one row is created, so if the plugin fails, restart by running it again with the same parameters (accounting for any errors that may have caused the failure.";
    
    my $notes = "Although currently SRes.ExternalDatabaseRelease contains attributes named blast_file and blast_file_md5, they are unpopulated in CBIL's instance and it is unclear what they are used for, so the ability to load data into them is not provided here.";

    my $failureCases = "Neither the name of the database nor the database ID is required as input; however, if neither is provided, the plugin will fail.  Also, If there is already an entry in SRes.ExternalDatabaseRelease that has the same version number as the entry to be created, then no new row is submitted.  This is not a failure case per se, but will result in no change to the database where one might have been expected.  Finally, if including --release_date in the command line, the format of the date must be the same as that expected by the DATE datatype in your database instance";

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
	 stringArg({name => 'database_name',
		    descr => 'Name in GUS of database for which we are creating a new release',
		    reqd => 0,
		    constraintFunc => undef,
		    isList => 0,
		}),

	 integerArg ({name => 'database_id',
		      descr => 'ID (in SRes.ExternalDatabase) of external database for which we are creating a new release',
		      reqd => 0,
		      constraintFunc => undef,
		      isList => 0,
		  }),
	 
	 stringArg ({name=> 'release_date',
		     descr => 'release date; format must conform to DATE format in your database instance',
		     reqd => 0,
		     constraintFunc => undef,
		     isList =>0,
		 }),
	 
	 stringArg ({name => 'database_version',
		    descr => 'New version of external database for which we are creating a new release',
		    reqd => 1,
		    constraintFunc => undef,
		    isList => 0,
		}),
	 
	 stringArg({name => 'download_url',
		    descr => 'full url of external site from where new release can be downloaded',
		    reqd => 0,
		    constraintFunc => undef,
		    isList => 0,
		}),

	 stringArg({name => 'id_type',
		    descr => 'brief description of the format of the primary identifier of entries in the release',
		    reqd => 0,
		    constraintFunc => undef,
		    isList => 0,
		}),
	 stringArg({name => 'id_url',
		    descr => 'url to look up entries for a particular id.  If possible, replace a specific id with <ID> to provide a generalized url',
		    reqd => 0,
		    constraintFunc => undef,
		    isList => 0,
		}),

	 stringArg({name => 'secondary_id_type',
		    descr => 'brief description of the format of the secondary identifier of entries in the release',
		    reqd => 0,
		    constraintFunc => undef,
		    isList => 0,
		}),
	 stringArg({name => 'secondary_id_url',
		    descr => 'url to look up entries for a particular id, by their secondary identifier.  If possible, replace a specific id with <ID> to provide a generalized url',
		    reqd => 0,
		    constraintFunc => undef,
		    isList => 0,
		}),
	 stringArg({name => 'description',
		    descr => 'description of the new release.  If possible, make the description specific to the release rather than a general description of the database itself',
		    reqd => 0,
		    constraintFunc => undef,
		    isList => 0,
		}),
	 
	 #not using fileArg for this since file is not actually opened in this plugin
	 stringArg({name => 'file_name',
		    descr => 'name of file representing this release, and if it exists, link to local location where file can be found',
		    reqd => 0,
		    constraintFunc => undef,
		    isList => 0,
		}),

	 stringArg({name => 'file_md5',
		    descr => 'md5 checksum for verifying the file was downloaded successfully, and if it exists, link to local location where file can be found',
		    reqd => 0,
		    constraintFunc => undef,
		    isList => 0,
		}),
	 ];

     $self->initialize({requiredDbVersion => {},
			cvsRevision => '$Revision$', # cvs fills this in!
			name => ref($self),
			revisionNotes => 'added attributes and changed to new-style plugin usage',
			argsDeclaration => $argsDeclaration,
			documentation => $documentation
			});

    return $self;
}

sub run {
    my $self = shift;

    my $dbName = $self->getCla->{database_name};
    my $dbVer = $self->getCla->{database_version}; 
    my $dbId = $self->getCla->{database_id};

    if (!$dbName && !$dbId){
	$self->userError("Please provide one of either --database_name (as it appears in SRes.ExternalDatabase) or --database_id as an argument to this plugin");
    }

    my $msg;
    if (!$dbId){
	$dbId = $self->getExtDbId($dbName, $dbId);
    }

    if ($self->releaseAlreadyExists($dbId)){
	$msg = "Not creating a new release Id for $dbName as there is already one for $dbName version $dbVer";
    }

    else{
	my $extDbRelId = $self->makeNewReleaseId($dbId);
	$msg = "Created new release id for $dbName with version $dbVer and release id $extDbRelId";
    }
    return $msg;
}

sub releaseAlreadyExists{
    my ($self, $id) = @_;

    my $queryHandle = $self->getQueryHandle();


    my $dbVer = $self->getCla->{database_version}; 

    my $sql = "select external_database_release_id 
               from SRes.ExternalDatabaseRelease
               where external_database_id = $id
               and version = '$dbVer'";

    my $sth = $queryHandle->prepareAndExecute($sql);

    my ($relId) = $sth->fetchrow_array();
    return $relId; #if exists, entry has already been made for this version

}

sub makeNewReleaseId{
    
    my ($self, $id) = @_;

    my $dbVer = $self->getCla->{database_version}; 

    my $newRelease = GUS::Model::SRes::ExternalDatabaseRelease->new({
	external_database_id => $id,
	version => $dbVer,
	download_url => $self->getCla()->{download_url},
	id_type => $self->getCla()->{id_type},
	id_url => $self->getCla()->{id_url},
	secondary_id_type => $self->getCla()->{secondary_id_type},
	secondary_id_url => $self->getCla()->{secondary_id_url},
	description => $self->getCla()->{description},
	file_name => $self->getCla()->{file_name},
	file_md5 => $self->getCla()->{file_md5},
	
    });

    $newRelease->submit();
    my $newReleasePk = $newRelease->getId();
    return $newReleasePk;

}

sub getExtDbId{

    my ($self, $name, ) = @_;

    my $queryHandle = $self->getQueryHandle();
	my $lcName = lc($name);
    my $sql = "select external_database_id from SRes.ExternalDatabase where lower(name) = '$lcName'";

    my $sth = $queryHandle->prepareAndExecute($sql);
   
    my ($id) = $sth->fetchrow_array();
    if (!($id)){
	$self->userError("no entry in SRes.ExternalDatabase for database $name");
    }
    else{
	return $id;
    }
}


1;
