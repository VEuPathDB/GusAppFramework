

use strict 'vars';

package ProgrammerError;

use vars qw(@ISA);
use Module;

@ISA = qw( Module );

# ----------------------------------------------------------------------

sub makePage {
	my $M = shift;

	my $H = $M->getHify;

	# items to be stuck in page.
	my @items;

	# explain what the error is
	# ........................................

	my $request = $M->getInput->{R};

	my $error = <<ERROR;

    The GO Rule Browser has received a request, 'R=$request', that it
    does not recognize.<BR>

    Please inform the staff at CBIL using <a
    href='mailto:GoMaster\@pcbi.upenn.edu'>GoMaster\@pcbi.upenn.edu</a>.

ERROR

	push(@items,$M->formatError($error));


	# generate the page.
	# ........................................
	$M->saySomething(join("\n", @items));

	# RETURN
	1
}

# ----------------------------------------------------------------------

1;

