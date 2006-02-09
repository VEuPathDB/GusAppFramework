package GUS::PluginMgr::Args::Arg;

# Super class for all Args

use strict 'vars';
use Carp;

sub getName {
  my ($self) = @_;

  return $self->{name};
}

# returns undef if no value (including for list values)
sub getValue {
  my ($self) = @_;
  return $self->{value};
}

sub getEasyCsp {
  my ($self) = @_;
  
  return {h=> $self->{descr}, 
	  o=> $self->getName(), 
	  t=> $self->getPrimativeType(), 
	  l=> $self->{isList},
	  r=> $self->{reqd}
	  };
}

# return true if a problem
sub checkReqd {
  my ($self) = @_;

  my $problem;
  if ($self->{reqd}) {
    if (!defined $self->{value}) {
      $problem = "required argument omitted";
    } elsif ($self->{isList} && !scalar(@{$self->{value}})) {
      $problem = "required argument needs a non-empty list value";
    }
  }
  return $problem;
}

sub formatConciseText {
  my ($self) = @_;

  my $type = $self->getType();
  my $s = "--" . $self->getName() . " " . $type;
  $s .= "-list"  if $self->{isList};
  $s = "[$s]" unless $self->{reqd};
  return $s;
}

sub formatLongPod {
  my ($self) = @_;

  my $type = $self->getType();
  my $s = "\n=item --" . $self->getName() . " I<" . $type;
  $s .= "-list> (comma delimited)" if $self->{isList};
  $s .= ">" unless $self->{isList};
  $s .= " (Required)" if $self->{reqd};
  $s .= "\n\n";
  $s .= "Allowed values: $self->{enum}\n\n" if $self->{enum};
  $s .= "=over 4\n\n";
  $s .= "$self->{descr}\n\n";
  my $extraLine;
  if (defined $self->{default}) {
    $s .= "=over 4\n\n";
    $s .= "=item default: $self->{default}\n\n";
    $s .= "=back\n\n";
    $extraLine = 1;
  }

  my @attrs = $self->getAttrs();
  foreach my $attr (@attrs) {
    my ($name, $checkFunc) = @$attr;
    if ($self->{$name}) {
      $s .= "=over 4\n\n";
      $s .= "=item $name: $self->{$name}\n\n";
      $s .= "=back\n\n";
      $extraLine = 1;
    }
  }

  $s .= "=back\n\n";
  $s .= "=item \n\n" if $extraLine;
  return $s;
}

sub runConstraintFunc {
  my ($self, $plugin, $value) = @_;
  my $problem;
  $problem = $self->{constraintFunc}($plugin, $value) if (defined $self->{constraintFunc});
  return $problem;
}

sub formatValue {
  my ($self) = @_;

  my $s;
  if (defined $self->getValue()) {
    $s = "--" . $self->getName() . " ";
    if ($self->{isList}) {
      $s .= join (", ", @{$self->getValue()});
    } else {
      $s .= $self->getValue();
    }
  }
  return $s;
}

sub _getStandardAttrs {
  my ($self) = @_;

  my @a = (['name', undef],
	   ['descr', undef],
	   ['reqd', \&_checkReqdDecl],
	   ['default', undef]);

  push(@a, (['constraintFunc', undef],
	    ['isList', undef])) unless ref($self) =~ 'Boolean';
  return @a
}

# will be overridden.
sub getAttrs {
  return ();
}

sub initAttrs {
  my ($self, $attrsHashRef, $booleanArg) = @_;

  my @attrs = ($self->getAttrs(), $self->_getStandardAttrs());

  if (defined $attrsHashRef->{default}) {
    $self->{default} = $attrsHashRef->{default};
    $self->{value} = $self->{default};
  }

  foreach my $attr (@attrs) {
    my ($name, $checkFunc) = @$attr;
    next if ($name eq 'default');
    $self->failinit($name) unless exists $attrsHashRef->{$name};
    $self->{$name} = $attrsHashRef->{$name};
    &$checkFunc($self) if $checkFunc;
  }

  $self->_checkReqdDecl();
}

sub failinit {
  my ($self, $argname) = @_;

  my $class = ref $self;
  &confess("Argument declaration error: $class requires '$argname => '\n\n");
}

###########################################################################
#               private methods
###########################################################################

sub _checkReqdDecl {
  my ($self) = @_;

  my $class = ref $self;
  &confess("Argument declaration error for argument $self->{name}: 'reqd => $self->{reqd}' is invalid.  It must be either 0 or 1\n\n")
    unless $self->{reqd} eq '0' || $self->{reqd} eq '1';
  &confess("Argument declaration error for argument $self->{name}: required args must have 'default => undef or omit default =>'\n\n")
    if $self->{reqd} && defined $self->{default};
}

1;
