package GUS::Pipeline::ExternalResources::FileSysManager;

use Net::FTP;
use strict;

sub new {
  my ($class, $ftpSite, $root, $login, $password, $localTmpDir) = @_;

  my $self = {};
  bless $self, $class;

  $self->{root} = $root;
  $self->{localTmpDir} = $localTmpDir;
  $self->{ftpSite} = $ftpSite;
  $self->{ftp} = Net::FTP->new($ftpSite, Debug => 0);

  if (!$self->{ftp}) {
    die "could not create FTP object. error: '$@'\n";
  }

  $self->{ftp}->login($login, $password) ||
    die "cannot login to ftp site '$ftpSite'\n";

  $self->{ftp}->cwd($root) ||
    die "cannot cd to dir '$root' on ftp site '$ftpSite'\n";

  return $self;
}

sub dirExists {
  my ($self, $dir) = @_;

  return $self->{ftp}->cwd($dir);
}

sub makeDir {
  my ($self, $dir) = @_;

  return $self->{ftp}->mkdir("$self->{root}/$dir")
    || die "couldn't make dir '$self->{root}/$dir' on ftp site '$self->{ftpSite}'";
}

sub fileExists {
  my ($self, $file) = @_;

 return $self->{ftp}->mdtm("$self->{root}/$file");
}

sub copyOut {
  my ($self, $reposFile, $localFile) = @_;

 return $self->{ftp}->get($self->{root}/$reposFile, $localFile)
   || die "couldn't get '$reposFile' from ftp site '$self->{ftpSite}' to '$localFile'\n";
}

sub copyIn {
  my ($self, $localFile, $reposFileOrDir) = @_;

 return $self->{ftp}->put($localFile, $self->{root}/$reposFile)
   || die "couldn't put '$localFile' to '$self->{root}/$reposFile' on ftp site '$self->{ftpSite}'\n";
}

sub touchFile {
  my ($self, $file) = @_;

  &_runCmd("touch $localTmpDir/$file");
  $self->copyIn("$localTmpDir/$file", "$self->{root}/$file");
  unlink("$localTmpDir/$file") || die "Can't unlink '$self->{root}/$file'\n";
}

sub deleteFile {
  my ($self, $file) = @_;

  return $self->{ftp}->delete("$self->{root}/$file")
    || die "Can't delete '$self->{root}/$file' from ftp site '$self->{ftpSite}'\n";
}

sub listDir {
  my ($self, $dir) = @_;

  my @files = $self->{ftp}->ls("$self->{root}/$dir");

  @files || die "couldn't open directory '$self->{root}/$dir' on ftp site '$self->{ftpSite}'\n";

  my @files2;
  foreach my $file (@files) { push(@files2, chomp($file))};

  return @files2;
}

sub _runCmd {
  my ($cmd) = @_;

  system($cmd);
  my $status = $? >> 8;
  die("Failed with status $status running '$cmd': $!\n") if ($status);
}

1;
