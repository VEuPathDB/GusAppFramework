package GUS::Pipeline::ExternalResources::SftpManager;

_loadSftpModule();
use File::Basename;
use strict;

my $debug = 1;

sub new {
  my ($class, $location) = @_;

  my $self = {};
  bless $self, $class;

  my $user;
  ($user, $self->{host}, $self->{root}) = &parseLocation($location);

  die "invalid sftp location '$location'.  Check to make sure repository location is of format [user\@]hostname:path\n" unless ($self->{host} && $self->{root});

  if ($self->{root} !~ /\/$/) {
    $self->{root} .= "/";
  }

  eval {
    $self->{sftp} = Net::SFTP->new($self->{host}, user => $user);
#    $self->{sftp} = Net::SFTP->new($self->{host}, debug => 1);
  };

  if ($@) {
    die "$@(to use sftp you need to have an ssh agent running)\n"; 
  } 

  if (!$self->{sftp}) {
    die "could not create SFTP object or login to host '$self->{host}'. error: '$@'\n";
  }

  if ($self->{root}) {
    print STDERR "do_stat($self->{root})\n" if ($debug);
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
  my $path_regex = "\\/?(\\S+\\/)*\\S+/\?";
  if ($location =~ /^($user_regex)?($host_regex):($path_regex)$/) {
    return ($2, $3, $5);
  } else {
    return undef;
  }
}

sub fileExists {
  my ($self, $file) = @_;

  print STDERR "fileExists($file)\n" if ($debug);
  my $dirName = dirname("$file");
  my $baseName = basename("$file");

  my @files = $self->listDir($dirName);

  my $found = 0;
  foreach my $f (@files) {
    if ($f eq $baseName) {
      $found = 1;
      last;
    }
  }
  print STDERR "fileExists - x\n\n" if ($debug);
  return $found;
}

sub dirExists {
  my ($self, $dir) = @_;
  print STDERR "dirExists($dir)\n" if ($debug);

  my $dirName = dirname("$dir");
  my $baseName = basename("$dir");

  my $found = 0;

  print STDERR "ls($self->{root}$dirName)\n" if ($debug);

  my @files = $self->{sftp}->ls("$self->{root}$dirName");

  foreach my $f (@files) {
    if ($f->{filename} eq $baseName && $f->{longname} =~ /^d/) {
      $found = 1;
      last;
    }
  }
  print STDERR "dirExists - x\n\n" if ($debug);
  return $found;
}

sub makeDir {
  my ($self, $dir) = @_;

  print STDERR "makeDir($dir)\n" if ($debug);
  my $attrs = Net::SFTP::Attributes->new();

  print STDERR "do_mkdir($self->{root}$dir, $attrs)\n" if ($debug);
  my $retCode = $self->{sftp}->do_mkdir("$self->{root}$dir", $attrs);
  if ($retCode) {
    die "Couldn't make dir '$self->{root}$dir' on host '$self->{host}'. message: " . Net::SFTP::Util::fx2txt($retCode) . "\n";
  }
  print STDERR "makdDir - x\n\n" if ($debug);
  return 1;
}

sub copyOut {
  my ($self, $reposFile, $localFile) = @_;

  my $dirName = dirname($localFile);

  -d dirname($localFile) || die "Local dir '$dirName' does not exist\n";
  -e $localFile && die "Local file '$localFile' already exists...\n";

  print STDERR "copyOut($reposFile, $localFile)\n" if ($debug);
  print STDERR "get($self->{root}$reposFile, $localFile)\n" if ($debug);
  $self->{sftp}->get("$self->{root}$reposFile", $localFile);

  print STDERR "copyOut - x\n\n" if ($debug);
}

sub copyIn {
  my ($self, $localFile, $reposFileOrDir) = @_;

  print STDERR "copyIn($localFile, $reposFileOrDir)\n" if ($debug);
  print STDERR "put($localFile, $self->{root}$reposFileOrDir)\n" if ($debug);
  -e $localFile || die "Local file '$localFile' does not exist\n";
  my $success = $self->{sftp}->put($localFile, "$self->{root}$reposFileOrDir");
  print STDERR "copyIn - x\n\n" if ($debug);
  return $success;
}

sub touchFile {
  my ($self, $file) = @_;

  print STDERR "touchFile($file)\n" if ($debug);

  my $touchFile = "/tmp/touch_" .time();
  &_runCmd("echo lock > $touchFile");
  -e $touchFile || die "Couldn't touch local file $touchFile\n";
  $self->copyIn("$touchFile", $file);
  unlink($touchFile) || die "Can't unlink '$touchFile'\n";
  print STDERR "touchFile - x\n\n" if ($debug);
}

sub deleteFile {
  my ($self, $file) = @_;

  print STDERR "do_remove($self->{root}$file)\n" if ($debug);
  my $retCode = $self->{sftp}->do_remove("$self->{root}$file");
  if ($retCode) {
    die "Couldn't remove '$self->{root}$file' on host '$self->{host}'. message: " . Net::SFTP::Util::fx2txt($retCode) . "\n";
  }
  return 1;
}

sub listDir {
  my ($self, $dir) = @_;

  print STDERR "listDir($dir)\n" if ($debug);

  print STDERR "ls($self->{root}$dir)\n" if ($debug);
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


# supplant default Net::SFTP with faster Net::SFTP::Foreign, if available
sub _loadSftpModule {
  eval { require Net::SFTP::Foreign::Compat };
  if (! $@ ) {
    import Net::SFTP::Foreign::Compat ':supplant';
  } else {
    eval { require Net::SFTP };
    eval { require Net::SFTP::Util };
    eval { require Net::SFTP::Attributes };
  }
}


1;
