#! /usr/bin/perl

unshift(@INC, '.');

use strict 'vars';

use vars qw(*Input);

use A;
use CSP::Hify;
use Disp;

print STDERR " dollar-pipe = $| \n";
$|=1;
print STDERR " dollar-pipe = $| \n";

my $H = CSP::Hify->new();

my $input = getInput($H);

my $perl_code = <<USE_MODULE;

  require $input->{R_module};
  my \$module = new $input->{R_module} \$H,\$input;
	\$module->makePage();

USE_MODULE

print STDERR $perl_code;
eval $perl_code;
if ($@) {
	print STDERR join("\t", $0, 'eval', $@), "\n";
}

# ----------------------------------------------------------------------

sub Intro {
	my $H = shift;

	SaySomthing($H,'Check back soon');
}

# ----------------------------------------------------------------------

sub getInput {
	my $H = shift;

	my $RV;

	require "./cgi-lib.perl";
	&ReadParse( *Input );

	my $defaults = {
									R    => 'SelectGroup',
									did  => 'PF000002',
									iea  => 'No',
									ddb  => 'ProDom',
									i    => 1,
									n    => 50,
#									pat  => '%',
									pat  => '',
									rsid => 0,
									rvw  => 'Any',
									cnf  => 'Any',
#									cvs  => '2.61',
									cvs  => '2.654',
									rty  => 'Any',
									lgo  => '1',
									hgo  => '200',
								 };

	foreach ( keys %{ $defaults } ) {
		$RV->{$_} = exists $Input{$_} ? $Input{$_} : $defaults->{$_};
	}
	
	# simplification from human readable text

	$RV->{R_module} =  $RV->{R};
	$RV->{R_module} =~ s/\s+(.)/uc $1/ge;
	$RV->{R_module} =  'ProgrammerError' unless -f "$RV->{R_module}.pm";

	Disp::Display($RV,'RV',STDERR);
	
	# RETURN
	$RV
}
