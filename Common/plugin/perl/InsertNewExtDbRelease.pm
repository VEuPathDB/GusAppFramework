package GUS::Common::Plugin::InsertNewExtDbRelease;
@ISA = qw( GUS::PluginMgr::Plugin);


use lib "$ENV{GUS_HOME}/lib/perl";

use strict 'vars';

use FileHandle;

use GUS::Model::SRes::ExternalDatabaseRelease;

sub new {
    
    # create
    my $class = shift;
    my $self = bless{}, $class;
    # initialize

    my $usage = "Creates new entry in table SRes.ExternalDatabaseRelease for new external database versions"; 
    my $easycsp =
	[
	 {o => 'database_name',
	  h => 'Name in GUS of database for which we are creating a new release',
	  t => 'string',
	  r => 1,
      },
	 {o => 'database_version',
	  h => 'New version of external database for which we are creating a new release',
	  t => 'float',
	  r => 1,
      }
	 ];

     $self->initialize({requiredDbVersion => {},
		       cvsRevision => '$Revision$', # cvs fills this in!
	 		   cvsTag => '$Name$', # cvs fills this in!
 	 	       name => ref($self),
		       revisionNotes => 'initial creation of plugin',
		       easyCspOptions => $easycsp,
		       usage => $usage,
		   });

    return $self;
}

sub run {
    my $self = shift;

    my $dbName = $self->getCla->{database_name};
    my $dbVer = $self->getCla->{database_version}; 

    my $msg;

    my $externalDatabaseId = $self->getExtDbId($dbName);

    if ($self->releaseAlreadyExists($externalDatabaseId)){
	$msg = "Not creating a new release Id for $dbName as there is already one for $dbName version $dbVer";
    }

    else{
	my $extDbRelId = $self->makeNewReleaseId($externalDatabaseId);
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
    });

    $newRelease->submit();
    my $newReleasePk = $newRelease->getId();
    return $newReleasePk;

}

sub getExtDbId{

    my ($self, $name) = @_;

    my $queryHandle = $self->getQueryHandle();

    my $sql = "select external_database_id from SRes.ExternalDatabase where name = '$name'";

    print STDERR "executing $sql\n";

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
