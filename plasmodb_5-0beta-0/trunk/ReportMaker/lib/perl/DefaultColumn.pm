package GUS::ReportMaker::DefaultColumn;

use strict;

# $formatFn  An optional formatting function to apply to the column value 
#            before displaying it.  Accepts a string and returns a string.  
#
sub new {
  my ($class, $name, $description, $formatFn) = @_;

  my $self = {};
  bless($self, $class);

  $self->{name} = $name;
  $self->{description} = $description;
  $self->{formatFn} = $formatFn;

  return $self;
}

sub getValue {
  my ($self, $rowHashLowerCase) = @_;

  my $nm = lc($self->{name});
  return $rowHashLowerCase->{$nm};
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
  my $value = '';

  if ($answerRow->{$self->{name}}) {
    $value = join(",", @{$answerRow->{$self->{name}}});
    $value =~ s/\t/ /g;    # just in case
  }

  if ($value =~ /\S/) {

      # Apply formatting function if we have one
      my $formatFn = $self->{formatFn};
      if (defined($formatFn)) {
	  $value = &$formatFn($value);
      }
  } else {
      $value = '--';
  }

  print "$value\t";
}

sub formatGoId {
    my ($id) = @_;

    return substr("GO:0000000", 0, 10 - length($id)) . $id;
}

1;
