package GUS::Pipeline::ExternalResources::LoaderStep;

use strict;
use GUS::Pipeline::ExternalResources::RepositoryEntry;

my $DBNAME_MACRO = "\%EXT_DB_NAME\%";
my $DBVERSION_MACRO = "\%EXT_DB_RLS_VER\%";

sub new {
  my ($class, $repositoryDir, $resource, $version, $targetDir, $unpackers,
      $url, $plugin, $pluginArgs, $extDbName, $extDbRlsVer, $extDbRlsDescrip, $commit, 
      $dbCommit, $wgetArgs, $repositoryLogFile) = @_;

  my $self = {};
  $self->{repositoryEntry} = 
      GUS::Pipeline::ExternalResources::RepositoryEntry->new($repositoryDir,
							     $resource,
							     $version,
							     $url,
							     $wgetArgs,
							     $repositoryLogFile);
  
  $self->{extDbName} = $extDbName;
  $self->{extDbRlsDescrip} = $extDbRlsDescrip;
  $self->{extDbRlsVer} = $extDbRlsVer;
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

  return unless $self->{extDbName};

  my $dbPluginArgs = "--name \'$self->{extDbName}\' $self->{dbCommit}";

  $mgr->runPluginNoCommit("createDb_${signalBase}", 
			  "GUS::Common::Plugin::InsertNewExternalDatabase",
			  $dbPluginArgs, 
			  "Inserting/checking external database info for $self->{extDbName}");
  
  my $releasePluginArgs = "--database_name \'$self->{extDbName}\' --database_version \'$self->{extDbRlsVer}\' --description \'$self->{extDbRlsDescrip}\' $self->{dbCommit}";
  
  $mgr->runPluginNoCommit("createRelease_${signalBase}",
			  "GUS::Common::Plugin::InsertNewExtDbRelease",
			  $releasePluginArgs,
			  "Inserting/checking external database release for $self->{extDbName} $self->{extDbRlsVer}");
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
	if ($unpacker){  #might be necessary to protect against weird Perl array stuff
	  GUS::Pipeline::ExternalResources::RepositoryEntry::runCmd($unpacker);
	}
      }

      $mgr->endStep("acquire_${signalBase}");
    }
}

sub _loadData {
  my ($self, $mgr, $signalBase, $resource, $version) = @_;

    $self->_validatePluginDbArgs();

    $self->{pluginArgs} =~ s/$DBNAME_MACRO/\"$self->{extDbName}\"/;
    $self->{pluginArgs} =~ s/$DBVERSION_MACRO/\"$self->{extDbRlsVer}\"/;

    ## handle commit ourselves
    $mgr->runPluginNoCommit("load_${signalBase}", $self->{plugin}, 
			    "$self->{pluginArgs} $self->{commit}",
			    "Loading $resource $version");
}

# make sure that plugin args contain necessary macros for 
# handling ExternalDatabase info
sub _validatePluginDbArgs {
    my ($self) = @_;
    my $pluginArgs = $self->{pluginArgs};
    my $resource = $self->{repositoryEntry}->getResource();
    if ($self->{extDbName}
	&& ($pluginArgs !~ /$DBNAME_MACRO/ || $pluginArgs !~ /$DBVERSION_MACRO/)){
	die ("error in resource $resource: attribute extDbName specified, but database name and version macros not found in plugin args");
    }
}

1;



