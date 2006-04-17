

use strict 'vars';

package SelectGroup;

use vars qw(@ISA);
use Module;
use V;

@ISA = qw( Module );

# ----------------------------------------------------------------------

sub makePage {
	my $M = shift;

	my $H = $M->getHify;

	# items to be stuck in page.
	my @items;

	# explain what the form is for.
	# ........................................

	my $summary  = <<FORM_SUMMARY;

    Use this form to select which set of domain-to-GO-function rules
    you want to examine.

FORM_SUMMARY

	my $abstract = <<FORM_ABSTRACT;

    We generated rules for ProDom and CDD with and without the use of
    IEA annotation.  You need to choose a database and the inclusion
    (or not) of IEA annotation.

FORM_ABSTRACT

#	push(@items,$M->formSummary($summary), $M->formAbstract($abstract));

	# make the form.
	# ........................................
	my @inputs;
	push(@inputs,
# commented out -- rule groups are no longer broken out into different projectInfo records
#			 $M->makeGuidePost('Choose the data used to build rules.'),
#			 $M->makeSelect   ('Domain Database', 'ddb', $M->getInput->{ddb},
#												 [ 'ProDom', 'CDD' ]),
#			 $M->makeSelect   ('IEA Annotation',  'iea', $M->getInput->{iea},
#												 [ 'Yes', 'No' ]),

			 $M->makeGuidePost('Use this section to filter the quality of the associations.'),
			 $M->makeSelect   ('Manually Reviewed', 'rvw', $M->getInput->{rvw},
												 [ 'Yes', 'No', 'Any' ]),
			 $M->makeSelect   ('Confidence', 'cnf', $M->getInput->{cnf},
												 [ 'Low', 'Medium', 'High', 'Any' ]),
			 $M->makeSelect   ('Rule Type',         'rty', $M->getInput->{rty},
												 [ sort { $a cmp $b } V::set('Any', values %{$M->getRuleMap})  ]),
			 $M->makeTextBox  ('With at least this many GOAPs', 'lgo',
												 $M->getInput->{lgo}),
			 $M->makeTextBox  ('With at most this many GOAPs', 'hgo',
												 $M->getInput->{hgo}),

			 $M->makeGuidePost('Use this section to see all domains with rules.'),
			 $M->makeSubmit   ('List all', ' '),

			 $M->makeGuidePost('Find domains with a name, ID, or associated GO function that matches this pattern.'),
			 $M->makeTextBox  ('Text to match', 'pat', $M->getInput->{pat}),
			 $M->makeSubmit   ('List all that match', ' '),
			);
	push(@items,
			 $H->e_form(new A {
				 action => $M->getSelfUrl,
				 viz    => $M->form(\@inputs),
			 }),
			);

	# generate the page.
	# ........................................
	$M->saySomething(join("\n", @items));

	# RETURN
	1
}

# ----------------------------------------------------------------------

1;

