package GUS::Pipeline::ExternalResources::FileSysManager;

use strict;

# THIS IS NOT FUNCTIONAL
# IT IS JUST A COPY OF FileSysManager
# BUT, THE DIRECTORIES HERE DEMONSTRATE WHAT IS NEEDED


sub new {
  my ($class, $ftpSite) = @_;

  my $self = {};

  # HERE it would be a good idea to validate the ftp site.  i don't know
  # how yet.

  $self->{ftpSite} = $ftpSite;
  bless $self, $class;
  return $self;

}

sub dirExists {
  my ($self, $dir) = @_;

  return -d "$self->{root}/$dir";
}

sub makeDir {
  my ($self, $dir) = @_;

  return mkdir("$self->{root}/$dir");
}

sub fileExists {
  my ($self, $file) = @_;

  return -e "$self->{root}/$file";
}

sub copyOut {
  my ($self, $reposFile, $localFile) = @_;

  my $cmd = "cp $self->{root}/$reposFile $localFile";
  &_runCmd($cmd);
}

sub copyIn {
  my ($self, $localFile, $reposFileOrDir) = @_;

  my $cmd = "cp $localFile $self->{root}/$reposFileOrDir";
  &_runCmd($cmd);
}

sub touchFile {
  my ($self, $file) = @_;

  &_runCmd("touch $self->{root}/$file");
}

sub deleteFile {
  my ($self, $file) = @_;

  return unlink("$self->{root}/$file");
}

sub listDir {
  my ($self, $dir) = @_;

  opendir(DIR, "$self->{root}/$dir") || die "Couldn't open directory '$self->{root}/$dir'\n";

  my @files = grep !/^\./, readdir DIR;    # lose . and ..

  closedir(DIR) || die "Couldn't close directory '$self->{root}/$dir'\n";

  return @files;
}

sub _runCmd {
  my ($cmd) = @_;

  system($cmd);
  my $status = $? >> 8;
  die("Failed with status $status running '$cmd': $!\n") if ($status);
}

1;
