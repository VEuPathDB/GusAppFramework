package GUS::Pipeline::ExternalResources::RepositoryEntry;

use strict;
use GUS::Pipeline::ExternalResources::RepositoryWget;
use GUS::Pipeline::ExternalResources::FileSysManager;
#use GUS::Pipeline::ExternalResources::FtpManager;


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
  my ($class, $repositoryLocation, $resource, $version, $sourceUrl, $wgetArgs,
      $logFile) = @_;

  my $self = {};
  bless $self, $class;

  $self->{storageManager} = _makeStorageManager($repositoryLocation);
  $self->{resource} = $resource;
  $self->{resourceDir} = $self->{resource};
  $self->{version} = $self->_findVersion($version, $self->{resourceDir});
  $self->{versionDir} = "$self->{resourceDir}/$self->{version}";
  $self->{logFile} = $logFile;

  $self->{wget} = GUS::Pipeline::ExternalResources::RepositoryWget->new($sourceUrl, $wgetArgs);

  return $self;
}

sub fetch {
  my ($self, $targetDir) = @_;


  -d $targetDir || die "Target dir '$targetDir' does not exist\n";

  if (!$self->{storageManager}->dirExists($self->{resourceDir})) {
    $self->{storageManager}->makeDir($self->{resourceDir})
      || die "Can't 'mkdir $self->{resourceDir}'\n";
  }

  my $answerFile = $self->_getAnswerFile();

  $self->_log("");

  # if versionDir exists, then we have previously acquired this version.
  # make sure it is ok
  if ($self->{storageManager}->dirExists($self->{versionDir})) {
    $self->_checkPrev($answerFile, $targetDir);
  }

  # otherwise, acquire it
  else {
    $self->{storageManager}->makeDir($self->{versionDir})
      || die "Can't 'mkdir $self->{versionDir}'\n";

    $self->_acquire($targetDir);
  }

  # in either case, copy it to the requested target
  $self->_copyTo($targetDir);
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

sub _getAnswerFile {
  my ($self) = @_;

  return $self->_fileBaseName() . ".tar.gz";
}

# static method
sub _makeStorageManager {
  my ($storageLocation) = @_;

  if ($storageLocation =~ /^ftp:/) {
  } elsif ($storageLocation =~ /^\//) {
    return GUS::Pipeline::ExternalResources::FileSysManager->new($storageLocation);
  } else {
    die "Illegal repository location '$storageLocation'";
  }

}

sub _waitForUnlock {
  my ($self) = @_;

  my $count = 0;
  while ($self->{storageManager}->fileExists($self->_fileBaseName() . "lock")) {
    if ($count++ % 120) { $self->_log("Waiting for unlock"); }
    sleep(1);
  }
}

sub _fileBaseName {
  my ($self) = @_;
  return "$self->{versionDir}/$self->{resource}-$self->{version}";
}

sub _checkPrev {
  my ($self, $answerFile, $targetDir) = @_;
    $self->_log("Found existing $self->{resource} $self->{version}");

    $self->_waitForUnlock();

    $self->{storageManager}->fileExists($answerFile)
      || die "Previously attempted fetch did not produce expected file '$answerFile'\n";

    my ($prevSourceUrl, $prevWgetArgs) = $self->_parseWgetArgs($targetDir);
    my $errMsg = $self->{wget}->argsMatch($prevSourceUrl, $prevWgetArgs);
    die("wget args disagree with those from previous fetch request:\n  $errMsg\n") if $errMsg;

}

sub _parseWgetArgs {
  my ($self, $targetDir) = @_;

  # get file into local tmp file
  my $time = time;
  my $wgetFile = "$targetDir/tmp-$time-wget.args";
  $self->{storageManager}->copyOut("$self->{versionDir}/wget.args", $wgetFile);

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
  unlink($wgetFile) || die "Couldn't remove temp file '$wgetFile'\n";
  return ($url, \%args);
}

sub _acquire {
  my ($self, $targetDir) = @_;

  $self->_lock();

  eval {
    my $tmpDir = "$targetDir/tmp-" . time();
    -e $tmpDir && die "Temp dir '$tmpDir' already exists.  Please remove it.\n";
    mkdir $tmpDir || die "Could not make temp dir '$tmpDir'\n";

    my $wgetDir = "$tmpDir/wget";

    mkdir $wgetDir || die "Could not make temp dir '$wgetDir'\n";
    chdir $wgetDir || die "Could not cd to temp dir '$wgetDir/'\n";

    $self->_writeWgetArgs($targetDir);

    $self->_log("Calling wget");
    $self->{wget}->execute($wgetDir,
			   "$tmpDir/wget.log",
			   "$tmpDir/wget.cmd");

    $self->_log("Calling tar");
    my $baseName = "$self->{resource}-$self->{version}";
    my $tarCmd = "tar -cf $tmpDir/$baseName.tar .";
    $self->_runCmd($tarCmd);

    $self->_log("Calling gzip");
    my $gzipCmd = "gzip $tmpDir/$baseName.tar";
    $self->_runCmd($gzipCmd);

    $self->{storageManager}->copyIn("$tmpDir/wget.log", $self->{versionDir});
    $self->{storageManager}->copyIn("$tmpDir/wget.cmd", $self->{versionDir});
    $self->{storageManager}->copyIn("$tmpDir/$baseName.tar.gz", $self->{versionDir});

    chdir $targetDir || die "Could not cd to '$targetDir/'\n";
    $self->_runCmd("rm -rf $tmpDir");
  };

  my $err = $@;

  # clean up.
  $self->_unlock();

  die "$err\n" if $err;

}

sub _lock {
  my ($self) = @_;

  my $lockFile = "$self->{versionDir}/lock";
  $self->{storageManager}->touchFile($lockFile);
}

sub _unlock {
  my ($self) = @_;

  my $lockFile = "$self->{versionDir}/lock";
  $self->{storageManager}->deleteFile($lockFile)
    || die("Couldn't delete '$lockFile'\n");
}

sub _writeWgetArgs {
  my ($self, $targetDir) = @_;

  my $time = time;
  my $wgetArgsFile = "$targetDir/tmp-$time-wget.args";
  open(WGET, ">$wgetArgsFile") || die("Can't open $wgetArgsFile for writing\n");
  print WGET $self->{wget}->getUrl() . "\n";
  my $wgetArgs = $self->{wget}->getArgs();
  foreach my $arg (keys %{$wgetArgs}) {
    print WGET "${arg}$wgetArgs->{$arg}\n";
  }
  close(WGET);
  $self->{storageManager}->copyIn($wgetArgsFile, "$self->{versionDir}/wget.args");
  unlink($wgetArgsFile) || die "Couldn't remove temp file '$wgetArgsFile'\n";
}

sub _copyTo {
  my ($self, $targetDir) = @_;

  my $fileNm = $self->_getAnswerFile();

  $self->_log("Copying $self->{resource}-$self->{version}.tar.gz to $targetDir");
  $self->{storageManager}->copyOut($fileNm, $targetDir);

  $self->_log("Unzipping and untarring $self->{resource}-$self->{version}.tar.gz");

  my $cmd = "tar -C $targetDir/ -zxf $targetDir/$self->{resource}-$self->{version}.tar.gz";
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

  if ($self->{logFile}) { 
    open(LOG, ">>$self->{logFile}") 
      || die "Couldn't open repository log file '$self->{logFile}'\n";
    print LOG "$msg\n";
    close(LOG);
  } else {
    print "$msg\n";
  }
}

sub _findVersion {
  my ($self, $requestedVersion, $resourceDir) = @_;

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

    my @files = $self->{storageManager}->listDir($resourceDir);
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
