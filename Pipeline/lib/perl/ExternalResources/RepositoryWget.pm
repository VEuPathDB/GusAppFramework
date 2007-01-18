package GUS::Pipeline::ExternalResources::RepositoryWget;

use strict;

#############################################################################
#          Public Methods
#############################################################################


sub new {
  my ($class, $argsHash) = @_;

  my $self = {};
  bless $self, $class;

  $self->{sourceUrl} = $argsHash->{url};
  delete $argsHash->{url};
  $self->{args} = $argsHash;
  return $self;
}

sub getArgs {
  my ($self) = @_;

  return $self->{args};
}

sub getUrl {
  my ($self) = @_;

  return $self->{sourceUrl};
}

# returns a message if mismatch; undef if match
sub argsMatch {
  my ($self, $url, $argsHash) = @_;

  return "Urls differ (previous url was: '$url')" 
    if ($url ne $self->{sourceUrl});

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
  my ($self, $targetDir, $logFile, $cmdFile) = @_;

  my $cmd = "wget --directory-prefix=$targetDir --output-file=$logFile";

  foreach my $argName (keys %{$self->{args}}) {
    ($argName eq "--directory-prefix=" 
     || $argName eq "--output-file=")
      && die "Do not provide the wget arg '$argName'.  It is handled internally.";
    $cmd .= " ${argName}$self->{args}->{$argName}";
  }

  $cmd .= " \"$self->{sourceUrl}\"";

  open(CMD, ">$cmdFile") || die "Cannot open wget command file '$cmdFile' for writing\n";
  print CMD "$cmd\n";
  close(CMD);

  system($cmd);
  my $status = $? >> 8;
  die "Failed running '$cmd'\n.  Error: $!\n" if ($status);

  # check for existance of result
  opendir(DIR, $targetDir) || die "Can't open directory '$targetDir': $!\n";
  my @files = grep !/^\./, readdir DIR;    # lose . and ..
  close(DIR);
  die "wget failed to create any files.  Please see $logFile\n" if (scalar @files == 0);
}

1;
