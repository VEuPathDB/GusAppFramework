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
  if ($hadErr) {
    $self->{manager}->goodbye("Pipeline had failures.  NOT complete!\n");
  } else {
    $self->{manager}->goodbye("Pipeline complete!\n");
  }
}

##########################################################################
#    private methods
##########################################################################

sub _parseXmlFile {
  my ($self) = @_;

  my $commit = $self->{manager}->{propertySet}->getProp('commit');
  my $xmlString = $self->_substituteMacros();
  my $xml = new XML::Simple;
  my $data = $xml->XMLin($xmlString);
  my $repositoryLogFile = "$self->{manager}->{pipelineDir}/logs/repository.log";
  foreach my $resource (@{$data->{resource}}) {
    my $targetDir = "$data->{downloadDir}/$resource->{resource}";
    my $wgetArgs = &_parseWgetArgs($resource->{wgetArgs});
    my $loaderStep =
      GUS::Pipeline::ExternalResources::LoaderStep->new($data->{repository},
							$resource->{resource},
							$resource->{version},
							$targetDir,
							$resource->{url},
							$resource->{plugin},
							$resource->{pluginArgs},
							$resource->{dbName},
							$resource->{releaseDescription},
							$commit,
							$wgetArgs,
							$repositoryLogFile
						       );
    print STDERR "Loader: release description : " . $resource->{releaseDescription} . "\n";

    push(@{$self->{steps}}, $loaderStep);
  }
}

sub _parseWgetArgs {
  my ($wgetArgsString) = @_;

  my @wgetArgs = split(/\s+/, $wgetArgsString);
  my %wgetArgs;
  foreach my $arg (@wgetArgs) {
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
    my @macroKeys = /\@(\w+)\@/g;
    foreach my $macroKey (@macroKeys) {
      my $val = $propertySet->getProp($macroKey);
      die "Invalid macro '\@$macroKey\@' in xml file $self->{xmlFile}" unless defined $val;
      $line =~ s/\@$macroKey\@/$val/g;
    }
    $xmlString .= $line;
  }
  return $xmlString;
}

1;



