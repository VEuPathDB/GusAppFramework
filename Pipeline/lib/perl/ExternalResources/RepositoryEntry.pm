package GUS::Pipeline::ExternalResources::RepositoryEntry;

use strict;
use GUS::Pipeline::ExternalResources::RepositoryWget;


# This class represents an entry in an External Data Files Repository.
#
# Each entry has:
#   - a resource name (eg, NRDB, PFAM)
#   - a version (eg, 1.1.2)
#   - a set of wget args used to acquire it
#   - the data.  the data is stored exactly as received from the source but
#     tarred and gzipped
#
# The only public function supported by a RepositoryEntry is fetch, ie, retrieve
# the .tar.gz file from the repository.  If the file is not already in the 
# repository, the RepositoryEntry executes wget to acquire the file.
#
# Error conditions on a fetch:
#   - if the resource has been previously acquired, but, the wget args differ
#   - if wget fails

#############################################################################
#          Public Methods
#############################################################################


# wgetArgs is a hash of wget args.  
#  - If the arg is a flag, the key is of the form "--name" and the value is "".
#  - If the arg is value, the key is of the form "--name=" and the value is the value.
sub new {
  my ($class, $repositoryDir, $resource, $version, $sourceUrl, $wgetArgs) = @_;

  my $self = {};
  bless $self, $class;

  $self->{repositoryDir} = $repositoryDir;
  $self->{resource} = $resource;
  $self->{resourceDir} = "$self->{repositoryDir}/$self->{resource}";
  $self->{version} = _findVersion($version, $self->{resourceDir});
  $self->{versionDir} = "$self->{resourceDir}/$self->{version}";

  -d $repositoryDir || die "Repository directory '$repositoryDir' does not exist\n";

  $self->{wget} = GUS::Pipeline::ExternalResources::RepositoryWget->new($sourceUrl, $wgetArgs);

  return $self;
}

sub getAnswerFile {
  my ($self) = @_;

  return $self->_fileBaseName() . ".tar.gz";
}

sub fetch {
  my ($self, $targetDir) = @_;

  die "Target dir '$targetDir' does not exist\n" unless -d $targetDir;

  if (!-d $self->{resourceDir}) {
    mkdir($self->{resourceDir}) || die "Can't 'mkdir $self->{resourceDir}'\n";
  }

  my $answerFile = $self->getAnswerFile();

  # if versionDir exists, then we have previously acquired this version.
  # make sure it is ok
  if (-d $self->{versionDir}) {
    $self->_log("Found existing $self->{resource} $self->{version}");

    $self->_waitForUnlock();

    -e $answerFile || die "Previously attempted fetch did not produce expected file '$answerFile'\n";

    my ($prevSourceUrl, $prevWgetArgs) = $self->_parseWgetArgs();
    my $errMsg = $self->{wget}->argsMatch($prevSourceUrl, $prevWgetArgs);
    die("wget args disagree with those from previous fetch request:\n  $errMsg\n") if $errMsg;
  }

  # otherwise, acquire it
  else {

    mkdir($self->{versionDir}) || die "Can't 'mkdir $self->{versionDir}'\n";

    $self->_acquire();

  }

  # in either case, copy it to the requested target
  $self->_copyTo($targetDir);
  return $answerFile;
}

sub getResource {
  my ($self) = @_;

  return $self->{resource};
}

sub getVersion {
  my ($self) = @_;

  return $self->{version};
}

sub parseWgetArg {
  my ($arg) = @_;

  my @arg;
  if ($arg =~ /^(--[\w-]+)=(.*)$/) {
    @arg = ("$1=", $2);
  } elsif ($arg =~ /^(--[\w-]+)$/) {
    @arg = ($1, "");
  } else {
    die "invalid wget argument name '$arg' (only long form of args is allowed)\n";
  }
  return @arg;
}

########################################################################
#          Private Methods
########################################################################

sub _waitForUnlock {
  my ($self) = @_;

  my $count = 0;
  while (-e $self->_fileBaseName() . "lock") {
    if ($count++ % 120) { $self->_log("Waiting for unlock"); }
    sleep(1);
  }
}

sub _fileBaseName {
  my ($self) = @_;
  return "$self->{versionDir}/$self->{resource}-$self->{version}";
}

sub _parseWgetArgs {
  my ($self) = @_;

  my $wgetFile = "$self->{versionDir}/wget.args";
  open(WGET, $wgetFile) || die("Can't open $wgetFile\n");

  my $url;
  my %args;
  while (<WGET>) {
    chomp;
    if (!$url) {
      $url = $_;           # first line has url
    } else {
      my ($k, $v) = parseWgetArg($_);
      $args{$k} = $v;
    }
  }

  close(WGET);
  return ($url, \%args);
}

sub _acquire {
  my ($self) = @_;

  my $tmpDir = "$self->{versionDir}/tmp";
  my $baseName = $self->_fileBaseName();
  my $tarCmd = "tar -cf ${baseName}.tar .";
  my $gzipCmd = "gzip $baseName.tar";

  $self->_lock();

  eval {
    -e $tmpDir && die "Temp dir '$tmpDir' already exists.  Please remove it.\n";
    mkdir $tmpDir || die "Could not make temp dir '$tmpDir'\n";
    chdir $tmpDir || die "Could not cd to temp dir '$tmpDir'\n";

    $self->_writeWgetArgs();

    $self->_log("Calling wget");
    $self->{wget}->execute($tmpDir,
			   "$self->{versionDir}/wget.log",
			   "$self->{versionDir}/wget.cmd");

    $self->_log("Calling tar");
    $self->_runCmd($tarCmd);
    $self->_runCmd("rm -rf $tmpDir");

    $self->_log("Calling gzip");
    $self->_runCmd($gzipCmd);

  };

  my $err = $@;

  # clean up.
  $self->_unlock();

  die "$err\n" if $err;

}

sub _lock {
  my ($self) = @_;

  my $lockFile = "$self->{versionDir}/lock";
  $self->_runCmd("touch $lockFile");
}

sub _unlock {
  my ($self) = @_;

  my $lockFile = "$self->{versionDir}/lock";
  unlink($lockFile);
}

sub _writeWgetArgs {
  my ($self) = @_;

  my $wgetArgsFile = "$self->{versionDir}/wget.args";
  open(WGET, ">$wgetArgsFile") || die("Can't open $wgetArgsFile for writing\n");
  print WGET $self->{wget}->getUrl() . "\n";
  my $wgetArgs = $self->{wget}->getArgs();
  foreach my $arg (keys %{$wgetArgs}) {
    print WGET "${arg}$wgetArgs->{$arg}\n";
  }
  close(WGET);
}

sub _copyTo {
  my ($self, $targetDir) = @_;

  my $fileNm = $self->getAnswerFile();

  $self->_log("Copying $self->{resource}-$self->{version}.tar.gz to $targetDir");
  my $cmd = "cp $fileNm $targetDir";
  $self->_runCmd($cmd);

  $self->_log("Unzipping and untarring $self->{resource}-$self->{version}.tar.gz");
  my $cmd = "tar -C $targetDir -zxf $targetDir/$self->{resource}-$self->{version}.tar.gz";
  $self->_runCmd($cmd);

  $self->_log("Deleting $self->{resource}-$self->{version}.tar.gz");
  my $cmd = "rm $targetDir/$self->{resource}-$self->{version}.tar.gz";
  $self->_runCmd($cmd);
}

sub _runCmd {
  my ($self, $cmd) = @_;

  system($cmd);
  my $status = $? >> 8;
  die("Failed with status $status running '$cmd': $!\n") if ($status);
}

sub _log {
  my($self, $msg) = @_;

  print "$msg\n";
}

sub _findVersion {
  my ($requestedVersion, $resourceDir) = @_;

  my $version = $requestedVersion;

  if ($requestedVersion =~ /(\d\d\d\d)-(\d\d)-(\d\d)/){
    my $requestedY = $1;
    my $requestedM = $2;
    my $requestedD = $3;

    my @today = localtime(time);
    my $todayYear = $today[5] + 1900;
    my $todayMonth = $today[4] + 1;
    my $todayDay = $today[3] + 1;
    my $today = "${todayYear}-${todayMonth}-$todayDay";

    opendir(RDIR, $resourceDir) || die "Couldn't open repository directory '$resourceDir'\n";
    my @files = grep !/^\./, readdir RDIR;    # lose . and ..
    close(RDIR);
    my $found;
    foreach my $file (sort @files) {
      if ($file =~ /(\d\d\d\d)-(\d\d)-(\d\d)/){
	my $y = $1;
	my $m = $2;
	my $d = $3;
	if ($y > $requestedY
	    || ($y == $requestedY && $m > $requestedM)
	    || ($y == $requestedY && $m == $requestedM && $d >= $requestedD)) {
	  $version = $file;
	  $found = 1;
	  last;
	}
      }
    }
    $version = $today unless $found;

  } elsif ($requestedVersion !~ /\d+/
      && $requestedVersion !~ /\d+\.\d+/
      && $requestedVersion !~ /\d+\.\d+\.\d+/
      && $requestedVersion !~ /\d+\.\d+\.\d+\.\d+/) {

    die "Invalid version number '$requestedVersion'\n";
  }
  return $version;
}
1;
