package GUS::Pipeline::ExternalResources::LoaderStep;

use strict;
use GUS::Pipeline::ExternalResources::RepositoryEntry;

sub new {
  my ($class, $repositoryDir, $resource, $version, $targetDir, $url, $plugin,
     $pluginArgs, $commit, $wgetArgs, $repositoryLogFile) = @_;

  my $self = {};
  $self->{repositoryEntry} = 
    GUS::Pipeline::ExternalResources::RepositoryEntry->new($repositoryDir,
							   $resource,
							   $version,
							   $url,
							   $wgetArgs,
							   $repositoryLogFile);

  $self->{targetDir} = $targetDir;
  $self->{plugin} = $plugin;
  $self->{commit} = $commit;
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

  if (!$mgr->startStep("Acquiring $resource $version",
		       "acquire_${signalBase}")) {

    die "Target dir '$self->{targetDir}' already exists.  Please remove it\n"
      if -e $self->{targetDir};

    mkdir($self->{targetDir}) 
      || die "Cannot make target dir '$self->{targetDir}'\n";

    $self->{repositoryEntry}->fetch($self->{targetDir});
    $mgr->endStep("acquire_${signalBase}");
  }

  ## handle commit ourselves
  $mgr->runPluginNoCommit("load_${signalBase}", $self->{plugin}, 
			  "$self->{pluginArgs} $self->{commit}",
			  "Loading $resource $version");
}

1;



