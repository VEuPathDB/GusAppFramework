package GUS::Pipeline::ExternalResources::SftpManager;

use Net::SFTP;
use Net::SFTP::Util;
use Net::SFTP::Attributes;
use File::Basename;
use strict;

sub new {
  my ($class, $location) = @_;

  my $self = {};
  bless $self, $class;

  my $user;
  ($user, $self->{host}, $self->{root}) = &parseLocation($location);

  die "invalid sftp location '$location'\n" unless ($user && $self->{host} && $self->{root});

  if ($self->{root} !~ /\/$/) {
    $self->{root} .= "/";
  }

  eval {
    $self->{sftp} = Net::SFTP->new($self->{host}, user => $user);
  };

  if ($@) {
    die "$@(to use sftp you need to have an ssh agent running)\n"; 
  } 

  if (!$self->{sftp}) {
    die "could not create SFTP object or login to host '$self->{host}'. error: '$@'\n";
  }

  if ($self->{root}) {
    $self->{sftp}->do_stat($self->{root}) ||
      die "root dir '$self->{root}' does not exist on host '$self->{host}'\n";
  }

  return $self;
}

# return ($user, $host, $path) or undef if not valid
sub parseLocation {
  my ($location) = @_;

  my $user_regex = "(\\w+)@";
  my $host_regex = "(\\w+\\.)+\\w+";
  my $path_regex = "\\/?(\\w+\\/)*\\w+/\?";
  if ($location =~ /^($user_regex)?($host_regex):($path_regex)$/) {
    return ($2, $3, $5);
  } else {
    return undef;
  }
}

sub fileExists {
  my ($self, $file) = @_;

  my $dirName = dirname("$file");

  my @files = $self->listDir($dirName);

  foreach my $f (@files) {
    return 1 if ($f eq $file);
  }
  return 0;
}

sub dirExists {
  my ($self, $dir) = @_;

  my $dirName = dirname("$dir");

  my @files = $self->{sftp}->ls("$self->{root}$dirName");
  foreach my $f (@files) {
    return 1 if ($f->{filename} eq $dir && $f->{longname} =~ /^d/);
  }
}

sub makeDir {
  my ($self, $dir) = @_;

  my $attrs = Net::SFTP::Attributes->new();

  my $retCode = $self->{sftp}->do_mkdir("$self->{root}$dir", $attrs);
  if ($retCode) {
    die "Couldn't make dir '$self->{root}$dir' on host '$self->{host}'. message: " . Net::SFTP::Util::fx2txt($retCode) . "\n";
  }
}

sub copyOut {
  my ($self, $reposFile, $localFile) = @_;

  # catch exception
  return $self->{sftp}->get("$self->{root}$reposFile", $localFile);
}

sub copyIn {
  my ($self, $localFile, $reposFileOrDir) = @_;

  # catch exception
  return $self->{sftp}->put($localFile, "$self->{root}$reposFileOrDir");
}

sub touchFile {
  my ($self, $file) = @_;


  my $touchFile = "/tmp/touch_" .time();
  &_runCmd("touch $touchFile");
  -e $touchFile || die "Couldn't touch local file $touchFile\n";
  $self->copyIn("$touchFile", $file);
  unlink($touchFile) || die "Can't unlink '$touchFile'\n";
}

sub deleteFile {
  my ($self, $file) = @_;

  my $retCode = $self->{sftp}->do_remove("$self->{root}$file");
  if ($retCode) {
    die "Couldn't remove '$self->{root}$file' on host '$self->{host}'. message: " . Net::SFTP::Util::fx2txt($retCode) . "\n";
  }
}

sub listDir {
  my ($self, $dir) = @_;

  my @files = $self->{sftp}->ls("$self->{root}$dir");

  @files || die "couldn't open directory '$self->{root}$dir' on host '$self->{host}'\n";

  my @files2;
  foreach my $file (@files) { push(@files2, $file->{filename})};

  return @files2;
}

sub _runCmd {
  my ($cmd) = @_;

  system($cmd);
  my $status = $? >> 8;
  die("Failed with status $status running '$cmd': $!\n") if ($status);
}

1;
