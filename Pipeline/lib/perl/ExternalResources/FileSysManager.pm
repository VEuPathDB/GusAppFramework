package GUS::Pipeline::ExternalResources::FileSysManager;

use strict;

sub new {
  my ($class, $root) = @_;

  my $self = {};

  -d $root || die "Repository location '$root' does not exist\n";

  $self->{root} = $root;
  bless $self, $class;
  return $self;

}

sub fileExists {
  my ($self, $file) = @_;

  return -e "$self->{root}/$file";
}

sub dirExists {
  my ($self, $dir) = @_;

  return -d "$self->{root}/$dir";
}

sub makeDir {
  my ($self, $dir) = @_;

  return mkdir("$self->{root}/$dir") || die "Can't mkdir '$self->{root}/$dir'\n";
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

  return unlink("$self->{root}/$file") || die "Can't unlink '$self->{root}/$file'\n";
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
