package GUS::ReportMaker::DefaultColumn;

use strict;

sub new {
  my ($class, $name, $description) = @_;

  my $self = {};
  bless($self, $class);

  $self->{name} = $name;
  $self->{description} = $description;

  return $self;
}

sub getValue {
  my ($self, $rowHash) = @_;

  return $rowHash->{$self->{name}};
}

sub getName {
  my ($self) = @_;
  return $self->{name};
}

sub getDescription {
  my ($self) = @_;
  return $self->{description};
}

sub print {
  my ($self, $answerRow) = @_;

  my $value = '--';
  if ($answerRow->{$self->{name}}) {
    $value = join(",", @{$answerRow->{$self->{name}}});
    $value =~ s/\t/ /g;    # just in case
  }
  $value = '--' unless $value =~ /\S+/;
  print "$value\t";
}

sub formatGoId {
    my ($id) = @_;

    return substr("GO:0000000", 0, 10 - length($id)) . $id;
}

1;
