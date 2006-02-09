#!/usr/bin/perl
=head1 NAME

C<Configuration> - a configuration object.

=head1 DESCRIPTION

C<Config> controls the location of various resources that TESS needs.  
Basically, it is a hash which can be loaded from a user-editable file which 
can be documented.

=head1 METHODS

=over 4

=cut

package Configuration;

@ISA = qw( A );

use strict 'vars';
use FileHandle;
use Carp;

use CBIL::Util::A;

# ----------------------------------------------------------------------

=item new

Creates a new configuration object.  Configuration is loaded from a file 
via a list of key/value pairs.  No filtering is performed at the moment and 
no defaults are provided.

Arguments:

C<CONFIG_FILE> (opt) name of a file to read for configuration.

=cut

sub new {
  my $class = shift;
  my $args  = shift;
		
  my $self = {};
  bless $self, $class;

  if ($args->check('CONFIG_FILE')) {
    $self->load($args);
  }
  
  return $self;
}

# ----------------------------------------------------------------------

=item add

Adds definitions from an object to the configuration.

Arguments:

All keys in input C<A> are copied.

=cut

sub add {
  my $self = shift;
  my $args = shift;
  
  $self->copy($args, @{$args->attributes()});
}

# ----------------------------------------------------------------------

=item load

loads parameters from a file.  Current configuration is not erase prior to 
loading.

Arguments:

C<CONFIG_FILE> (req) name of a file to read for configuration.

=cut

sub load {
  my $self = shift;
  my $args = shift;
  
  return undef unless $args->ensure('CONFIG_FILE');

  my $fh_config = new FileHandle "<$args->{CONFIG_FILE}";
	
	if ($fh_config) {
	  while (<$fh_config>) {

		# comments
		if (/^\#/) {
		  ;
		}
			
		# key-value pairs
		elsif (/^(\S+)\s+(.+)$/) {
		  $self->{$1} = $2;
		}
	  }
	  $fh_config->close();
	}
	else {
	  carp(sprintf("Unable to open '%s' to read the configuration; '%s'\n",
	  $args->{CONFIG_FILE}, $English::ERRNO));
	  return undef;
  }
	
  return $self;
}

# ----------------------------------------------------------------------

=item save

C<save> writes the object to a file in a format suitable for reloading.

Arguments:

C<CONFIG_FILE> writes to this file.

=cut

sub save {
  my $self = shift;
  my $args = shift;
  
  return undef unless $args->ensure('CONFIG_FILE');
  
  my $rv;
  
  my $fh_config = new FileHandle ">$args->{CONFIG_FILE}";
	
  if ($fh_config) {
    $self->dump(new CBIL::Util::A {FH => $fh_config});
    $fh_config->close();
    $rv = 1;
  }

  return $rv;	
}

=pod
=item lookup

Looks up the value of a tag in the configuration.  Caller must provide
a default and a list of possible tag names, usually abberviations.

First argument is the default value, the rest are tag strings.

=cut

sub lookup {
  my $Me      = shift;
  my $Default = shift;
  my @Tags    = @_;

  my $rv = $Default;
  my $tag;
  foreach $tag (@Tags) {
    if (exists $Me->{$tag}) {
      $rv = $Me->{$tag};
      last;
    }
  }
  
  return $rv;
}

# ----------------------------------------------------------------------

=back

=cut

1;


