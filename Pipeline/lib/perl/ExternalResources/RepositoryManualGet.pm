package GUS::Pipeline::ExternalResources::RepositoryManualGet;

use strict;

#############################################################################
#          Public Methods
#############################################################################


sub new {
  my ($class, $argsHash) = @_;

  my $self = {};
  bless $self, $class;

  $self->{args} = &_cleanArgs($argsHash);

  return $self;
}

sub getArgs {
  my ($self) = @_;

  return $self->{args};
}

sub argsMatch {
  my ($self, $argsHash) = @_;

  return "number of args differ"
    if (scalar keys %$argsHash) != (scalar keys %{$self->{args}});

  foreach my $argName (keys %$argsHash) {
    return "keys for arg '$argName' differ"
      if !defined $self->{args}->{$argName};
    return "values for arg '$argName' differ"
      if $argsHash->{$argName} ne $self->{args}->{$argName};
  }

  return undef;
}

sub execute {
  my ($self, $targetDir) = @_;

  my $source = $self->{args}->{fileOrDir};
  my $cmd;
  if ($source =~ s|^rsync://||) {
    my ($host, $path) = split ':', $source;
    system("rsync -e 'ssh $host' :$path &>/dev/null"); # test file's existence 
    my $status = $? >> 8;
    die "File or directory '$path' does not exist\n" if ($status);
    $cmd = "rsync -ae 'ssh $host' :$path $targetDir";
  } else {
  (-f $source || -d $source) || die "File or directory '$source' does not exist";
    $cmd = "cp -r $source $targetDir";
  }
  system($cmd);
  my $status = $? >> 8;
  die "Failed running '$cmd'\n.  Error: $!\n" if ($status);

  # check for existance of result
  opendir(DIR, $targetDir) || die "Can't open directory '$targetDir': $!\n";
  my @files = grep !/^\./, readdir DIR;    # lose . and ..
  close(DIR);
  die "manual get failed to create any files from '$source'\n" if (scalar @files == 0);
}

# if args are in wget format, convert to our format
sub _cleanArgs {
  my ($argsHash) = @_;

  my %newHash;
  foreach my $key (keys(%{$argsHash})) {
    if ($key =~ /--(.*)=/) {
      $newHash{$1} = $argsHash->{$key};
    } else {
      $newHash{$key} = $argsHash->{$key};
    }
  }
  return \%newHash;
}

1;
