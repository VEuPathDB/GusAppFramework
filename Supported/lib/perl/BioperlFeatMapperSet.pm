package GUS::Supported::BioperlFeatMapperSet;

use strict;
use GUS::Supported::BioperlFeatMapper;
use Data::Dumper;

use XML::Simple;

sub new {
  my ($class, $mapXmlFile, $plugin) = @_;
  $class = ref($class) || $class;

  my $self = {};
  bless($self, $class);

  $self->{mapXmlFile} = $mapXmlFile;
  $self->_parseMapFile($mapXmlFile, $plugin);

  return $self;
}

sub getMapperByFeatureName {
  my ($self, $featureName) = @_;

  if (!$self->{mappersByName}->{$featureName}) {
    die "Map XML file '$self->{mapXmlFile}' does not contain a <feature name=\"${featureName}\">, which is found in the input";
  }

  return $self->{mappersByName}->{$featureName};
}

sub getHandler {
  my ($self, $name) = @_;

  return $self->{qualifierHandlers}->{$name};
}

sub getAllHandlers{
my ($self) = @_;

  return values(%{$self->{qualifierHandlers}});
}

# return a list of all SO terms used in feature maps
sub getAllSoTerms {
  my ($self) = @_;
  my @terms;
  foreach my $mapper (values %{$self->{mappersByName}}) {
    push(@terms, $mapper->getSoTerm()) if ($mapper->getSoTerm());
  }
  return @terms
}

# Static method
# return the BioperlFeatMapper set in a hash keyed on feature name
sub _parseMapFile {
  my ($self, $mapXml, $plugin) = @_;

  my $simple = XML::Simple->new();
  my $data = $simple->XMLin($mapXml, forcearray => 1);
  my $mapperSet = $data->{feature};
  my $qualifierHandlers = $data->{specialCaseQualifierHandler};

  while (my ($name, $feature) = each %{$mapperSet}) {
    $self->{mappersByName}->{$name} = 
      GUS::Supported::BioperlFeatMapper->new($name, $feature, $mapXml);
  }

  while (my ($name, $handler) = each %{$qualifierHandlers}) {
    my $handlerClass = $handler->{class};
    $self->{qualifierHandlers}->{$name} = 
      eval "{require $handlerClass; $handlerClass->new()}";
    if ($@) { die "Cannot import or construct new object for qualifier handler class '$handlerClass'\n $@"; }
    $self->{qualifierHandlers}->{$name}->setPlugin($plugin);
  }
}


1;
