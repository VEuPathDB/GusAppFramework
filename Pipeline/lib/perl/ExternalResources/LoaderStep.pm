package GUS::Pipeline::ExternalResources::LoaderStep;

use strict;
use GUS::Pipeline::ExternalResources::RepositoryEntry;

my $DBNAME_MACRO = "\%DATABASE_NAME\%";
my $DBVERSION_MACRO = "\%REPOSITORY_VERSION\%";

sub new {
  my ($class, $repositoryDir, $resource, $version, $targetDir, $unpackers,
      $url, $plugin, $pluginArgs, $dbName, $releaseDescription, $commit, 
      $dbCommit, $wgetArgs, $repositoryLogFile) = @_;

  my $self = {};
  $self->{repositoryEntry} = 
      GUS::Pipeline::ExternalResources::RepositoryEntry->new($repositoryDir,
							     $resource,
							     $version,
							     $url,
							     $wgetArgs,
							     $repositoryLogFile);
  
  $self->{dbName} = $dbName;
  $self->{description} = $releaseDescription;
  $self->{targetDir} = $targetDir;
  $self->{unpackers} = $unpackers;
  $self->{plugin} = $plugin;
  $self->{commit} = $commit;
  $self->{dbCommit} = $dbCommit;
  $self->{pluginArgs} = $pluginArgs;
  bless $self, $class;

  return $self;
}

sub setRepositoryEntry {
  my ($self, $repositoryEntry) = @_;

  $self->{repositoryEntry} = $repositoryEntry;
}

sub run {
    my ($self, $mgr) = @_;

    my $resource = $self->{repositoryEntry}->getResource();
    my $version = $self->{repositoryEntry}->getVersion();
    my $signalBase = "${resource}_${version}";

    $self->_handleDatabaseInfo($mgr, $signalBase, $resource, $version);
    $self->_acquire($mgr, $signalBase, $resource, $version);
    $self->_loadData($mgr, $signalBase, $resource, $version);
}

sub _handleDatabaseInfo {
  my ($self, $mgr, $signalBase, $resource, $version) = @_;

    my $dbPluginArgs = "--name \'$self->{dbName}\' $self->{dbCommit}";

    $mgr->runPluginNoCommit("createDb_${signalBase}", 
			    "GUS::Common::Plugin::InsertNewExternalDatabase",
			    $dbPluginArgs, 
			    "Creating database entry for $resource");

    my $releasePluginArgs = "--database_name \'$self->{dbName}\' --database_version \'$version\' --description \'$self->{description}\' $self->{dbCommit}";

    $mgr->runPluginNoCommit("createRelease_${signalBase}",
			    "GUS::Common::Plugin::InsertNewExtDbRelease",
			    $releasePluginArgs,
			    "Creating database release for $resource $version");
}


sub _acquire {
  my ($self, $mgr, $signalBase, $resource, $version) = @_;
    if (!$mgr->startStep("Acquiring $resource $version",
			 "acquire_${signalBase}")) {

      die "Target dir '$self->{targetDir}' already exists.  Please remove it\n"
	if -e $self->{targetDir};

      mkdir($self->{targetDir}) 
	|| die "Cannot make target dir '$self->{targetDir}'\n";

      $self->{repositoryEntry}->fetch($self->{targetDir});

      foreach my $unpacker (@{$self->{unpackers}}) {
	GUS::Pipeline::ExternalResources::RepositoryEntry::runCmd($unpacker);
      }

      $mgr->endStep("acquire_${signalBase}");
    }
}

sub _loadData {
  my ($self, $mgr, $signalBase, $resource, $version) = @_;

    $self->_validatePluginDbArgs();

    $self->{pluginArgs} =~ s/$DBNAME_MACRO/$self->{dbName}/;
    $self->{pluginArgs} =~ s/$DBVERSION_MACRO/$version/;

    my $pluginDbArgs = " --external_database_name \'$self->{dbName}\' --version \'$version\'";

    ## handle commit ourselves
    $mgr->runPluginNoCommit("load_${signalBase}", $self->{plugin}, 
			    "$self->{pluginArgs} $pluginDbArgs $self->{commit}",
			    "Loading $resource $version");
}

# make sure that plugin args contain necessary macros for 
# handling ExternalDatabase info
sub _validatePluginDbArgs {
    my ($self) = @_;
    my $pluginArgs = $self->{pluginArgs};
    my $resource = $self->{repositoryEntry}->getResource();
    if (!($pluginArgs =~ /$DBNAME_MACRO/ && 
	  $pluginArgs =~ /$DBVERSION_MACRO/)){
      die ("error in resource $resource: attribute dbName specified, but database name and version macros not found in plugin args");
    }
}

1;



