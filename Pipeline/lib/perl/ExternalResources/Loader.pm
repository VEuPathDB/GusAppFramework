package GUS::Pipeline::ExternalResources::Loader;

use strict;

use GUS::Pipeline::ExternalResources::LoaderStep;
use XML::Simple;
use Data::Dumper;

sub new {
  my ($class, $manager, $xmlFile) = @_;

  my $self = {};
  $self->{manager} = $manager;
  $self->{xmlFile} = $xmlFile;
  bless $self, $class;
  $self->_parseXmlFile();
  return $self;
}

sub run {
  my ($self) = @_;

  $self->_makeUserProjectGroup();

  my $hadErr;
  foreach my $step (@{$self->{steps}}) {
    eval {
      $step->run($self->{manager});
    };

    my $err = $@;
    if ($err) {
      my $date = `date`;
      chomp $date;
      $self->{manager}->log("[$date]  FAILED\n\n");
      print STDERR $err if $err;
      $hadErr = 1;
    }
  }

  # run cleanup commands, if any
  foreach my $cleanup (@{$self->{cleanups}}) {
    next if ($cleanup =~ m/^\s*$/);
    $self->{manager}->log("Running cleanup command: '$cleanup'\n");
    system ($cleanup);
    if ($? >> 8){
      print STDERR "Failed running: \n$cleanup\n\n";
      $self->{manager}->log("FAILED\n\n");
      $hadErr = 1;
    } else { 
      $self->{manager}->log("\n");
    }
  }

  if ($hadErr) {
    $self->{manager}->goodbye("Pipeline had failures.  NOT complete!\n");
  } else {
    $self->{manager}->goodbye("Pipeline complete!\n");
  }
}

##########################################################################
#    private methods
##########################################################################

sub _makeUserProjectGroup {
  my ($self) = @_;

  my $firstName = $self->{manager}->{propertySet}->getProp('firstName');

  my $lastName = $self->{manager}->{propertySet}->getProp('lastName');

  my $projectRelease = $self->{manager}->{propertySet}->getProp('projectRelease');

  my $commit = $self->{manager}->{propertySet}->getProp('commit');

  my $signal = "${lastName}UserProjectGroup";

  return if $self->{manager}->startStep("Inserting userinfo,groupinfo,projectinfo for $lastName gus config file", $signal);

  $self->{manager}->runCmd ("insertUserProjectGroup --firstName $firstName --lastName $lastName --projectRelease $projectRelease $commit");

  $self->{manager}->endStep($signal);
}

sub _parseXmlFile {
  my ($self) = @_;

  my $commit = $self->{manager}->{propertySet}->getProp('commit');
  my $dbCommit = $self->{manager}->{propertySet}->getProp('dbcommit');
  my $xmlString = $self->_substituteMacros();
  my $xml = new XML::Simple(SuppressEmpty => undef);
  my $data = eval{ $xml->XMLin($xmlString) };
  die "$@\n$xmlString\n" if($@);
  print STDERR Dumper($data);
  my $repositoryLogFile = "$self->{manager}->{pipelineDir}/logs/repository.log";
  # handle resources
  if (ref($data->{resource}) eq 'ARRAY') {
    foreach my $resource (@{$data->{resource}}) {
      $self->_processResource($resource, $data, $commit, $dbCommit,
			      $repositoryLogFile);
    }
  } else {
      $self->_processResource($data->{resource}, $data, $commit, $dbCommit,
			      $repositoryLogFile);
  }

  # handle cleanUps
  $self->{cleanups} = ref($data->{cleanups}->{cleanup}) eq 'ARRAY'?
    $data->{cleanups}->{cleanup} : [$data->{cleanups}->{cleanup}];
}

sub _processResource {
  my ($self, $resource, $data, $commit, $dbCommit, $repositoryLogFile) = @_;

  # this perverse code is a workaround for a mysterious XML::Simple/Net::SFTP
  # bug that was detecting incorrect character encodings in strings
  # derived from the values parsed from the xml file
  my $repositoryDir = 
    substr($data->{repository},0,length($data->{repository}));
  my $resourceNm = 
    substr($resource->{resource},0,length($resource->{resource}));
  my $version = 
    substr($resource->{version},0,length($resource->{version}));
  my $downloadDir = 
    substr($data->{downloadDir},0,length($data->{downloadDir}));
  my $args;

  my $usingWget = $resource->{wgetArgs} || $resource->{url};
  if (($usingWget && $resource->{manualGet})
      || (!$usingWget && !$resource->{manualGet})) {
    die "Resource $resourceNm $version must provide either an url and <wgetArgs> or <manualGet> but not both\n";
  }

  if ($usingWget) {
    $args = &_parseWgetArgs(substr($resource->{wgetArgs},0,
				   length($resource->{wgetArgs})));
	
    my $moreWgetArgs;
    if (ref($resource->{wgetArg}) eq 'ARRAY') {
        $moreWgetArgs = $resource->{wgetArg};
    } else {
        $moreWgetArgs = [$resource->{wgetArg}];
    }

    if ($resource->{wgetArg} && (scalar (@{$moreWgetArgs}) > 0)) {
      foreach my $arg (@{$moreWgetArgs}) {
	  	  my ($argName, $argValue) = split (/=/, $arg, 2);
		  $args->{$argName . '='} = $argValue;
      }
    }

    my $targetDir = "$downloadDir/$resourceNm";
    $args->{url} = $resource->{url};
  } else {
    $args = $resource->{manualGet};
  }

  my $unpackers;
  if (ref($resource->{unpack}) eq 'ARRAY') {
    $unpackers = $resource->{unpack};
  } else {
    $unpackers = [$resource->{unpack}];
  }
  
  map { _formatForCLI($_) } @$unpackers;
  _formatForCLI($resource->{pluginArgs});
  
  my $targetDir = "$downloadDir/$resourceNm";
  my $loaderStep =
    GUS::Pipeline::ExternalResources::LoaderStep->new($repositoryDir,
						      $resourceNm,
						      $version,
						      $targetDir,
						      $unpackers,
						      $resource->{plugin},
						      $resource->{pluginArgs},
						      $resource->{extDbName},
						      $resource->{extDbRlsVer},
						      $resource->{extDbRlsDescrip},
						      $commit,
						      $dbCommit,
						      $args,
						      $repositoryLogFile
						     );

  push(@{$self->{steps}}, $loaderStep);
}

sub _parseWgetArgs {
  my ($wgetArgsString) = @_;

  return undef if (!$wgetArgsString);

  _formatForCLI($wgetArgsString);

  my @wgetArgs = split(/\s+/, $wgetArgsString);
  my %wgetArgs;
  foreach my $arg (@wgetArgs) {
    next if $arg =~ /^\s*$/;
    my ($k, $v) = 
      &GUS::Pipeline::ExternalResources::RepositoryEntry::parseWgetArg($arg);
    $wgetArgs{$k} = $v;
  }
  return \%wgetArgs;
}

sub _substituteMacros {
  my ($self) = @_;

  my $propertySet = $self->{manager}->{propertySet};

  my $xmlString;
  open(FILE, $self->{xmlFile});
  while (<FILE>) {
    my $line = $_;
    my @macroKeys = /\@([\w.]+)\@/g;   # allow keys of the form nrdb.release
    foreach my $macroKey (@macroKeys) {
      my $val = $propertySet->getProp($macroKey);
      die "Invalid macro '\@$macroKey\@' in xml file $self->{xmlFile}" unless defined $val;
      $line =~ s/\@$macroKey\@/$val/g;
    }
    $xmlString .= $line;
  }
  return $xmlString;
}

# remove line wrappings for command line processing
sub _formatForCLI {
    $_[0] =~ s/\\$//gm;
    $_[0] =~ s/[\n\r]+/ /gm;
}


1;



