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
  $self->parseXmlFile();
  return $self;
}

sub parseXmlFile {
  my ($self) = @_;

  my $xmlString = $self->substituteMacros();
  my $xml = new XML::Simple;
  my $data = $xml->XMLin($xmlString);

  foreach my $resource (@{$data->{resource}}) {
    my $targetDir = "$data->{downloadDir}/$resource->{resource}";
    my $wgetArgs = &parseWgetArgs($resource->{wgetArgs});
    my $loaderStep =
      GUS::Pipeline::ExternalResources::LoaderStep->new($data->{repository},
							$resource->{resource},
							$resource->{version},
							$targetDir,
							$resource->{url},
							$resource->{plugin},
							$resource->{pluginArgs},
							$wgetArgs,
						       );

    push(@{$self->{steps}}, $loaderStep);
  }
}

sub parseWgetArgs {
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

sub substituteMacros {
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

sub run {
  my ($self) = @_;

  foreach my $step (@{$self->{steps}}) {
    eval {
      $step->run($self->{manager});
    };

    my $err = $@;
    print STDERR $err if $err;
  }
}

1;



