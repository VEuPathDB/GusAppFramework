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
    die "Map XML file '$self->{mapXmlFile}' does not contain a <feature name=\"${featureName}\">, which is found in the input\n";
  }

  return $self->{mappersByName}->{$featureName};
}

sub getHandler {
  my ($self, $name) = @_;

  return $self->{qualifierHandlers}->{$name};
}

sub getAllHandlers{
my ($self) = @_;

  return @{$self->{qualifierHandlerObjectsList}};
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

sub preprocessBioperlSeq {
  my ($self, $bioperlSeq) = @_;
  return unless $self->{bioperlSeqPreprocessor};
  my $class = $self->{bioperlSeqPreprocessor}->{class};

  eval {
    no strict "refs";
    eval "require $class";
    my $method = "${class}::preprocess";
    &$method($bioperlSeq);
  };

  my $err = $@;
  if ($err) { die "Can't run bioperlSeq preprocessor method '${class}::preprocess'.  Error:\n $err\n"; }
}

sub getGusSkeletonMakerClassName {
  my ($self) = @_;
  return $self->{gusSkeletonMaker}->{class};
}

# Static method
# return the BioperlFeatMapper set in a hash keyed on feature name
sub _parseMapFile {
  my ($self, $mapXml, $plugin) = @_;

  my $simple = XML::Simple->new();

  # use forcearray so elements with one child are still arrays
  # and, use keyattr so that handlers are given as an ordered list
  # rather than a hash with name as key.  the ordering is needed
  # so that undo operations are ordered.  also, the qualifiers retain
  # the ordering found in the xml file.
  my $data = $simple->XMLin($mapXml,
			    forcearray => 1,
			    KeyAttr => {});
  my $mapperSet = $data->{feature};
  $self->{qualifierHandlersList} = $data->{specialCaseQualifierHandler};

  if($data->{bioperlSeqPreprocessor}){
    ($self->{bioperlSeqPreprocessor}) = @{$data->{bioperlSeqPreprocessor}};
  }

  if($data->{gusSkeletonMaker}){
    ($self->{gusSkeletonMaker}) = @{$data->{gusSkeletonMaker}};
  }

  foreach my $feature (@{$mapperSet}) {
    my $name = $feature->{name};
    $self->{mappersByName}->{$name} = 
      GUS::Supported::BioperlFeatMapper->new($name, $feature, $mapXml);
  }

  foreach my $handler (@{$self->{qualifierHandlersList}}) {
    my $handlerClass = $handler->{class};
    my $name = $handler->{name};
    $self->{qualifierHandlers}->{$name} =
      eval "{require $handlerClass; $handlerClass->new()}";
    if ($@) { die "Cannot import or construct new object for qualifier handler class '$handlerClass'\n $@\n"; }
    push(@{$self->{qualifierHandlerObjectsList}},
	 $self->{qualifierHandlers}->{$name});
    $self->{qualifierHandlers}->{$name}->setPlugin($plugin);
  }
}


1;
