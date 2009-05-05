package GUS::Supported::BioperlFeatMapper;

use strict 'vars';
use CBIL::Util::Disp;
######CPAN Perl Libraries

sub new{
  my ($class, $bioperlFeatureName, $featureMapHashFromXmlSimple, $mapXmlFile) = @_;
  my $self = $featureMapHashFromXmlSimple;
  $self->{'bioperlFeatureName'} = $bioperlFeatureName;
  $self->{'mapXmlFile'} = $mapXmlFile;
  foreach my $qualifier (@{$self->{qualifier}}) {
    $self->{qualifiers}->{$qualifier->{name}} = $qualifier;
    push(@{$self->{qualifierNamesList}}, $qualifier->{name});
  }

  foreach my $validator (@{$self->{validator}}) {
    $self->{validators}->{$validator->{name}} = $validator;
    push(@{$self->{validatorNamesList}}, $validator->{name});
  }
  bless($self, $class);
  return $self;
}

sub getBioperlFeatureName {
  my ($self) = @_;
  return $self->{'bioperlFeatureName'};
}

sub sortTags {
  my ($self, @tags) = @_;
  my %tags;
  my @sortedTags;
  foreach my $t (@tags) {
    $self->_checkTagExists($t);
    $tags{$t} = 1;
  }
  foreach my $q (@{$self->{qualifierNamesList}}) {
    push(@sortedTags, $q) if $tags{$q};
  }
  return @sortedTags;
}


sub sortValidationTags {
  my ($self, @tags) = @_;
  my %tags;
  my @sortedTags;

  foreach my $q (@{$self->{validatorNamesList}}) {
    push(@sortedTags, $q) if $tags{$q};
  }
  return @sortedTags;
}

sub getGusColumn{
  my ($self, $tag) = @_;
  
  $self->_checkTagExists($tag);
  my $gusColumnName = $self->{'qualifiers'}->{$tag}->{'column'};
  if ($gusColumnName eq '') {return $tag;}
  else {return $gusColumnName;}
}

sub getGusTable {
  my ($self) = @_;

  return $self->{'table'}; 
}

sub getGusObjectName {
  my ($self) = @_;

  my $objectName = $self->{'table'};

#  $objectName =~ s/\./::/;

  return "GUS::Model::$objectName";
}

sub getSoTerm {
  my ($self) = @_;

  return $self->{'so'};
}

sub isSpecialCase {
  my ($self, $tag) = @_;

  $self->_checkTagExists($tag);
  return $self->{qualifiers}->{$tag}->{'handler'}; 
}

sub getHandlerName {
  my ($self, $tag) = @_;

  return $self->{qualifiers}->{$tag}->{'handler'}
}

sub getHandlerMethod {
  my ($self, $tag) = @_;

  return $self->{qualifiers}->{$tag}->{'method'}
}

sub getValidatorHandlerName {
  my ($self, $tag) = @_;

  return $self->{validators}->{$tag}->{'handler'}
}

sub getValidatorHandlerMethod {
  my ($self, $tag) = @_;

  return $self->{validators}->{$tag}->{'method'}
}

sub ignoreFeature {
  my ($self) = @_;

  return $self->{'ignore'};
}

sub ignoreTag {
  my ($self, $tag) = @_;

  $self->_checkTagExists($tag);
  return $self->{qualifiers}->{$tag}->{'ignore'}; 
}

sub _checkTagExists {
  my ($self, $tag) = @_;
  
  if (!$self->{qualifiers}->{$tag}) {
    die "In feature map XML file '$self->{mapXmlFile}' <feature name=\"$self->{bioperlFeatureName}\"> does not have a <qualifier> for '$tag', which is found in the input.

Please edit file '$self->{mapXmlFile}', adding a <qualifer> tag under <feature name=\"$self->{bioperlFeatureName}\">.

If you want to ignore the input data add <qualifier name=\"$tag\" ignore=\"true\"/>.

If you want to handle the data, you will need to add a special case handler (please see the plugin documentation).
";
  }
}


1;

