package GUS::Pipeline::ExternalResources::ReleaseIdGetter;

use strict;

use Getopt::Long;
use GUS::ObjRelP::DbiDatabase;
use GUS::Common::GusConfig;
use GUS::Pipeline::ExternalResources::Loader;
use GUS::Pipeline::ExternalResources::LoaderStep;
use XML::Simple;


sub new {

    my ($class, $xmlFile) = @_;

    my $self = {};
    bless $self, $class;
    $self->{resources} = [];
    $self->{xmlFile} = $xmlFile;
    $self->connectToDatabase();
    $self->_initDbInfo();

    return $self;
}

sub connectToDatabase{
 
    my ($self) = @_;
    my $gusconfig = GUS::Common::GusConfig->new();
    
    my $db = GUS::ObjRelP::DbiDatabase->new($gusconfig->getDbiDsn(),
					    $gusconfig->getReadOnlyDatabaseLogin(),
					    $gusconfig->getReadOnlyDatabasePassword,
					    1,0,1,
					    $gusconfig->getCoreSchemaName);
    $self->setDatabase($db);
}


sub setDatabase{
    my ($self, $db) = @_;
    $self->{database} = $db;

}


sub getDatabase{
    my ($self) = @_;
    my $db = $self->{database};
    return $db;

}


sub getIdList{

    my ($self) = @_;
    my @resources = $self->getResources();
    my @ids;
    foreach my $resource (@resources){
	print STDERR "resolving $resource\n";
	my $id = $self->getId($resource);
	push (@ids, $id);
    }
    my $idString = join (",", @ids);
    print STDERR "got id string $idString\n";
    return $idString;


}


sub getId{
    my ($self, $resource) = @_;
    my $dbName = $resource->{extDbName};
    my $lcName = lc($dbName);
    my $version = $resource->{version};

    my $sql = "select external_database_release_id from sres.externaldatabaserelease edr, sres.externaldatabase e
               where lower(e.name) = '$lcName' and edr.version = '$version' and e.external_database_id = edr.external_database_id";
    print STDERR "executing $sql\n";
    
    my $sth = $self->getDatabase()->getQueryHandle()->prepareAndExecute($sql);
    my ($releaseId) = $sth->fetchrow_array();
    print STDERR "retrieved $releaseId for db $dbName version $version\n";
    die ("no release id exists for database name $dbName version $version\n") unless $releaseId;
    return $releaseId;
}


sub getResources{
    my ($self) = @_;
    return @{$self->{resources}};
}


sub _initDbInfo{

    my ($self) = @_;

    my $xml = new XML::Simple;
    
   
    my $xmlString = "";
    open(FILE, $self->{xmlFile}) || die "could not open " . $self->{xmlFile} . "\n";
    while (<FILE>) {
	my $line = $_;
	$xmlString .= $line;
    }
    my $data = $xml->XMLin($xmlString);
    
    foreach my $resource (@{$data->{resource}}) {
	
	$self->_addResource($resource);
    }
}


sub _addResource{

    my ($self, $resource) = @_;
    
    push (@{$self->{resources}}, $resource);
}



1;
