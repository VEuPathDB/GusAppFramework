package GUS::PluginMgr::Args::ArgList;

use strict;
use Carp;
use Getopt::Long;
use CBIL::Util::Disp;
use GUS::PluginMgr::Args::BooleanArg;

sub new {
  my ($class, $argsList, $usagePrefixText, $plugin) = @_;

  my $self = {};

  bless($self, $class);

  my $helpArg =
    GUS::PluginMgr::Args::BooleanArg->new({name  => 'help',
					   descr => 'Request long help',
					   reqd  => 0,
					   default=> undef,
					  });
  my $helpHTMLArg =
    GUS::PluginMgr::Args::BooleanArg->new({name  => 'helpHTML',
					   descr => 'Request help in HTML',
					   reqd  => 0,
					   default=> undef,
					  });

  $self->{argsList} = $argsList;
  push(@{$self->{argsList}}, $helpArg);
  push(@{$self->{argsList}}, $helpHTMLArg);
  $self->{usagePrefixText} = $usagePrefixText;

  $self->parseArgs();

  $self->{argsHash} = {};
  $self->{easyCsp} = [];
  foreach my $arg (@{$self->{argsList}}) {
    $self->{argsHash}->{$arg->getName()} = $arg;
    $self->{argsValueHash}->{$arg->getName()} = $arg->getValue();
  }

  return ($self, 'text') if $self->getValue('help');
  return ($self, 'html') if $self->getValue('helpHTML');

  $self->checkArgs($plugin);

  return ($self, 0);
}

# name->value
sub getArgsValueHash {
  my ($self) = @_;
  
  return $self->{argsValueHash};
}

sub getValue {
  my ($self, $name) = @_;

  my $arg = $self->{argsHash}->{$name};
  &confess("Invalid argument name '$name'\n") unless $arg;

  return $arg->getValue();
}

sub parseArgs {
  my ($self) = @_;

  my %getOptionsHash = $self->getGetOptionsHash();
  $self->usage() unless &GetOptions(%getOptionsHash);
  
  # parse lists
  foreach my $arg (@{$self->{argsList}}) {
    if ($arg->{isList} && defined($arg->{value})) {
      my @l = split(/\s*,\s*/, $arg->{value});
      $arg->{value} = \@l;
    }
  }
}

sub getGetOptionsHash {
  my ($self) = @_;

  my %getOptionsHash;
  foreach my $arg (@{$self->{argsList}}) {
    my $key = $arg->getName() . $arg->getGetOptionsSuffix();
    $getOptionsHash{$key} = \$arg->{value};
  }

  return %getOptionsHash;
}

sub checkArgs {
  my ($self, $plugin) = @_;

  foreach my $arg (@{$self->{argsList}}) {
    my $problem = $arg->checkReqd();

    if (!$problem && defined($arg->{value})) {
      # little tricky here: handle both list and non-list as a list
      my @valueList = $arg->{isList}? @{$arg->{value}} : ($arg->{value});

      foreach my $value (@valueList) {
	$problem = $arg->checkValue($value);
	$problem = $arg->runConstraintFunc($plugin, $arg->getValue()) unless $problem;
	last if $problem;
      }
    }

    if ($problem) {
      print STDERR "\nUser Error. Argument --$arg->{name}: $problem\n\n";
      $self->usage();
    }
  }
}

sub usage {
  my ($self) = @_;

  print STDERR "Usage: " . $self->formatConciseText(). "\n\n";
  exit(1);
}

sub longHelp {
  my ($self) = @_;

  print STDERR $self->formatConciseText();
  print STDERR "\n";
  print STDERR "Arguments:\n";
  print STDERR $self->formatLongText();
  exit(1);
}

sub formatConciseText {
  my ($self) = @_;

  my $usage = "\n   $self->{usagePrefixText} --help\n\n   $self->{usagePrefixText} --helpHTML\n\n   $self->{usagePrefixText}";
  foreach my $arg (@{$self->{argsList}}) {
    next if ($arg->getName() eq "help");
    next if ($arg->getName() eq "helpHTML");
    $usage .= " " . $arg->formatConciseText();
  }
  return $usage;
}

sub formatConcisePod {
  my ($self) = @_;

  my $usage = "\n$self->{usagePrefixText} --help\n\n";
  $usage .= "$self->{usagePrefixText} --helpHTML\n\n";
  $usage .= "$self->{usagePrefixText}";
  foreach my $arg (@{$self->{argsList}}) {
    next if ($arg->getName() eq "help");
    next if ($arg->getName() eq "helpHTML");
    $usage .= " " . $arg->formatConciseText();
  }
  return "$usage\n";
}

sub formatLongPod {
  my ($self) = @_;

  my $longText;
  foreach my $arg (@{$self->{argsList}}) {
    $longText .= $arg->formatLongPod();
  }
  return "$longText\n\n";
}

sub showValues {
  my ($self, $concise) = @_;

  my $s;
  my $n = $concise? " " : "\n  ";
  foreach my $arg (@{$self->{argsList}}) {
    next if ($arg->getName() eq "help");
    next if ($arg->getName() eq "helpHTML");
    $s .= $n . $arg->formatValue();
  }
  return "$s\n";

}
1;
