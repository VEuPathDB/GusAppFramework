
use strict 'vars';

package Lister;

use V;

# ----------------------------------------------------------------------

sub new {
	my $C = shift;
	my $A = shift;

	my $m = bless {}, $C;

	$m->{M} = $A;

	$m
}

# ----------------------------------------------------------------------

sub makeNavButtons {
	my $M = shift;
	my $O = shift; # mOdule
	my $I = shift; # input
	my $H = shift; # hify

	# navigation buttons
	my $next = do {
		my %i = ( %$I,
							i => $I->{i} + $I->{n},
						);
		my $url = $O->getSelfUrl. '?'. join('&', map {  "$_=$i{$_}" } keys %i );
		$H->e_a(new A {
			class => 'navigation',
			style => $M->{M}->getStyle('navigation'),
			href => $url,
			viz  => 'Next &gt;',
		})
	};

	my $prev = do {
		my %i = ( %$I,
							i => V::max(1,$I->{i} - $I->{n}),
						);
		my $url = $O->getSelfUrl. '?'. join('&', map {  "$_=$i{$_}" } keys %i );
		$H->e_a(new A {
			class =>  'navigation',
			style => $M->{M}->getStyle('navigation'),
			href => $url,
			viz  => '&lt; Prev',
		})
	};

	$H->e_table(new A {
		class => 'navigation',
		style => $M->{M}->getStyle('navigation'),
		viz   => $H->e_tr(new A {
			viz => join("\n",
									$H->e_td(new A {
										align => 'left',
										viz => $prev,
									}),
									$H->e_td(new A {
										align => 'center',
										style => $M->{M}->getStyle('hint'),
										viz   => sprintf('Click on %s icons below to see details of rules.',
																		 $M->{M}->makeDetailLinkImage,
																		),
									}),
									$H->e_td(new A {
										align => 'right',
										viz => $next
									}),
								 ),
							 }),
						 })
}

sub makeTable {
	my $M = shift;
	my $I = shift; # input
	my $H = shift; # hify
	my $G = shift; # guide
	my $S = shift; # statement handle
	my $C = shift; # row-modification code

	my $rows_n = 0;
	my @rows   = ();

	# header lines
	my $groups_tr;
	my $cols_tr;
	{
		my @groups; # top line
		my @cols;   # bottom line

		for (my $i = 0; $i < scalar @$G; $i++) {
			my $class = $i % 2 ? 'odd' : 'even';
			push(@groups,
					 $H->e_th(new A {
						 class   => $class,
						 style   => $M->{M}->getStyle("th.$class"),
						 colspan => scalar @{$G->[$i]->{-s}},
						 viz     => $G->[$i]->{-g},
					 }),
					);

			foreach (@{$G->[$i]->{-s}}) {
				push(@cols,
						 $H->e_th(new A {
							 class => $class,
							 style => $M->{M}->getStyle("th.$class"),
							 viz   => $_->{-t},
						 }),
						);
			}
		}

		$groups_tr = $H->e_tr(new A {
			class => 'even',
			style => $M->{M}->getStyle('even'),
			viz   => join("\n", @groups),
		});
		$cols_tr = $H->e_tr(new A {
			class => 'odd',
			style => $M->{M}->getStyle('odd'),
			viz   => join("\n", @cols),
		});;
	}
	push(@rows, $groups_tr, $cols_tr);

	# Rows of results.
  while (my $row = $S->fetchrow_hashref) {

		$rows_n++;
		next if $rows_n <  $I->{'i'};
		last if $rows_n >= $I->{'i'} + $I->{'n'};
		$row->{'##'} = ($row->{'#'}   = $rows_n);
		$C->($row);

		my @cols;
		for (my $i = 0; $i < scalar @$G; $i++) {
			my $class = $i % 2 ? 'odd' : 'even';
			foreach (@{$G->[$i]->{-s}}) {
				push(@cols,
						 $H->e_td(new A {
							 class => $class,
							 style => $M->{M}->getStyle("td.$class"),
							 viz   => $row->{$_->{-a}} || '?',
						 }),
						);
			}
		}

		push(@rows,
				 $H->e_tr(new A {
					 class => $row->{'##'} % 2 ? 'odd' : 'even',
					 style => $M->{M}->getStyle($row->{'##'} % 2 ? 'tr.odd' : 'tr.even'),
					 viz => join("\n", @cols),
					})
				);
	}
	$S->finish;

	push(@rows, $cols_tr, $groups_tr) if scalar @rows > 12;

	$H->e_table(new A {
		class       => 'results',
		style       => $M->{M}->getStyle('table.results'),
		cellpadding => 4,
		cellspacing => 1,
		viz         => join("\n", @rows ),
	})
}

# ----------------------------------------------------------------------

1;


