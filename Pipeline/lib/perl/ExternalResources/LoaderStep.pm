package GUS::Pipeline::ExternalResources::LoaderStep;

use strict;
use GUS::Pipeline::ExternalResources::RepositoryEntry;

sub new {
  my ($class, $repositoryDir, $resource, $version, $targetDir, $url, $plugin,
     $pluginArgs, $wgetArgs) = @_;

  my $self = {};
  $self->{repositoryEntry} = 
    GUS::Pipeline::ExternalResources::RepositoryEntry->new($repositoryDir,
							   $resource,
							   $version,
							   $url,
							   $wgetArgs);

  die "Target dir '$targetDir' already exists.  Please remove it\n"
    if -e $targetDir;

  mkdir($targetDir) || die "Cannot make target dir '$targetDir'\n";

  $self->{targetDir} = $targetDir;
  $self->{plugin} = $plugin;
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
		       "${signalBase}_acquire")) {

    $self->{repositoryEntry}->fetch($self->{targetDir});
    $mgr->endStep("${signalBase}_acquire");
  }

#  $mgr->runPlugin("${signalBase}_load", $self->{plugin}, $self->{pluginArgs},
#		  "Loading $resource $version");
}

1;



