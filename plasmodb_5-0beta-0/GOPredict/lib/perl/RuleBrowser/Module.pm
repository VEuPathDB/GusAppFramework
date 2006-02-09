

use strict 'vars';

package Module;

sub new {
	my $C = shift;
	my $H = shift;
	my $I = shift;

	my $m = bless {}, $C;

	$m->setHify($H);
	$m->setInput($I);

	$m->setRuleMap({ leaf   => 'Leaf',
									 ncle   => 'Near-consensus Leaf',
									 npar   => 'Recent Ancestor',
									 onep   => 'One Protein',
									 pval   => 'Best P-value',
									 sing   => 'Single Function',
								 });

	$m->loadStyleSheet;

	$m
}

# ----------------------------------------------------------------------

sub setHify { $_[0]->{HIFY} = $_[1]; $_[0] }
sub getHify { $_[0]->{HIFY} }

sub setInput { $_[0]->{INPUT} = $_[1]; $_[0] }
sub getInput { $_[0]->{INPUT} }

sub setRuleMap { $_[0]->{RULEMAP} = $_[1];
								 foreach (keys %{$_[1]}) {
									 $_[0]->{REVRULEMAP}->{$_[1]->{$_}} = substr($_,0,4)
								 }
								 $_[0] }
sub getRuleMap { $_[0]->{RULEMAP} }

sub getReverseRuleMap { $_[0]->{REVRULEMAP} }

# ----------------------------------------------------------------------
# Division
# ----------------------------------------------------------------------

sub makeHeader {
	my $M = shift;
	my $I = shift;
	my $T = shift;

	my $H = $M->getHify;

	my @levels = qw( zero one two three four );
	my $level_class = $levels[$I] || ' ';

	$H->e_tr(new A {
		class => $level_class,
		style => $M->getStyle($level_class),
		viz   => $H->e_td(new A {
			viz => $T,
		}),
	})
}

# ----------------------------------------------------------------------
# Form-building Stuff
# ----------------------------------------------------------------------
sub getSelfUrl {
	my $M = shift;

	my @parts = split('/',$0);
	pop @parts
}

# ----------------------------------------------------------------------

sub formatError {
	my $M = shift;
	my $E = shift;

	my $H = $M->getHify;

	$H->e_p(new A {
		class => 'error',
		style => $M->getStyle('error'),
		viz   => $E,
	})
}

# ----------------------------------------------------------------------

sub formSummary {
	my $M = shift;
	my $S = shift;

	my $H = $M->getHify;

	$H->e_p( new A {
		viz => $H->e_font(new A {
			class => 'formSummary',
			style => $M->getStyle('formSummary'),
			viz   => $S,
		}),
	})
}

# ----------------------------------------------------------------------

sub formAbstract {
	my $M = shift;
	my $A = shift;

	my $H = $M->getHify;

	$H->e_p( new A {
		viz => $H->e_font(new A {
			class => 'formAbstract',
			style => $M->getStyle('formAbstract'),
			viz   => $A,
		}),
	})
}

# ----------------------------------------------------------------------

sub form {
	my $M = shift;
	my $I = shift;

	my $H = $M->getHify;

	$H->e_table(new A {
		class => 'form',
		style => $M->getStyle('form'),
		viz   => join("\n", @$I),
	})
}

# ----------------------------------------------------------------------

sub makePrompt {
	my $M = shift;
	my $P = shift;

	my $H = $M->getHify;

	$H->e_td(new A {
		class => 'formPrompt',
		style => $M->getStyle('formPrompt'),
		viz   => $P,
	})
}

sub makeGuidePost {
	my $M = shift;
	my $G = shift;

	my $H = $M->getHify;

	$H->e_tr(new A {
		viz => $H->e_td(new A {
			class   => 'formGuide',
			style   => $M->getStyle('formGuide'),
			colspan => 2,
			viz     => '<br>'.$G
		}),
	})
}

# ----------------------------------------------------------------------

sub makeTextBox {
	my $M = shift;
	my $P = shift;
	my $N = shift;
	my $V = shift;

	my $H = $M->getHify;

	$H->e_tr(new A {
		viz => join("\n",
								$M->makePrompt($P),
								$H->e_td(new A {
									viz => $H->e_input(new A {
										type  => 'text',
										name  => $N,
										value => $V,
										viz   => $V,
									}),
								 }),
							 ),
						 })
}

# ----------------------------------------------------------------------

sub makeSubmit {
	my $M = shift;
	my $N = shift;
	my $P = shift || ' ';

	my $H = $M->getHify;

	$H->e_tr(new A {
		viz => join("\n",

								$M->makePrompt($P),

								# button in a TD
								$H->e_td(new A {
									viz => $H->e_input(new A {
										type   => 'submit',
										name   => 'R',
										value  => $N,
									}),
								}),
							 ),
	})
}

# ----------------------------------------------------------------------

sub makeSelect {
	my $M = shift;
	my $P = shift; # prompt
	my $N = shift; # name of option
	my $V = shift; # current value
	my $O = shift; # list of possible values.

	my $H = $M->getHify;

	# get html for prompt.
	my $p_html = $M->makePrompt($P);

	# get html for options.
	my $o_html = join("\n", map {
		$H->e_option(new A {
			viz      => $_,
			selected => $_ eq $V ? 1 : 0,
		})
	} @$O);

	$H->e_tr(new A {
		viz => join("\n",
								$p_html,
								$H->e_td(new A {
									viz => $H->e_select(new A {
										name  => $N,
										viz   => $o_html,
									}),
								}),
							 ),
						 })
}

# ----------------------------------------------------------------------

sub saySomething {
	my $M = shift;
	my $T = shift;

	my $H = $M->getHify;

	my $class = ref $M;

	print $H->contentType();

	print $H->e_html(new A {
		viz => join("\n",
								$H->e_head(new A {
									viz => join("\n",
															"<link REL=StyleSheet HREF='/GO/style.css' TYPE='text/css' MEDIA='screen'>\n",
															$H->e_title(new A {
																viz => "GO Rule Browser: $class",
															}),
														 ),
													 }),

								$H->e_body(new A {
									viz => $H->e_table(new A {
										width => '100%',
										viz   =>
										join("\n",
												 $H->e_tr(new A {
													 viz => $H->e_td(new A {
														 class => 'one',
														 style => $M->getStyle('one'),
														 viz   =>
														 join('',
																	$H->e_br(A::e).
																	$H->e_a(new A {
																		class => 'one',
																		style => $M->getStyle('one'),
																		href  => '/GO',
																		viz   => 'Predicting GO Functions'
																	}),
																	' : ',
																	$H->e_a(new A {
																		class => 'one',
																		style => $M->getStyle('one'),
																		href  => $M->getSelfUrl,
																		viz   => 'GO Rule Browser',
																	}),
																 ),
															 }),
														 }),
												 $H->e_tr(new A {
													 viz => $H->e_td(new A {
														 class => 'two',
														 style => $M->getStyle('two'),
														 viz   => "Class: $class",
													 }),
												 }),

												 # contents 
												 ( map {
													 my $level = $_->[0] || 'four';
													 my $viz   = $_->[1] || '?';
													 $viz = ($level eq 'three' ? '<br>' : '' ). $viz;
													 $H->e_tr(new A {
														 viz => $H->e_td(new A {
															 class => $level,
															 style => $M->getStyle($level),
															 viz   => $viz,
														 }),
													 }),
												 } ref $T eq 'ARRAY' ? @$T : ([ 'four', $T ]) ),

												 # debugging information
												 $H->e_tr(new A {
													 viz => $H->e_td(new A {
														 class => 'three',
														 style => $M->getStyle('three'),
														 viz   => '<br>Debug Information',
													 }),
												 }),

												 $H->e_tr(new A {
													 viz => $H->e_td(new A {
														 class => 'debug',
														 style => $M->getStyle('td.debug'),
														 viz   => join($H->e_br(A::e),
																					 map {
																						 $_. '='. $M->getInput->{$_}
																					 } sort keys %{$M->getInput}
																					),
																				}),
																			}),
												),
											}),
										}),
							 ),
						 });
}

# ----------------------------------------------------------------------

sub makeGoLink {
	my $M = shift;
	my $T = shift; # text to locate in GO browser.

	my $H = $M->getHify;

	my $url_fmt = 'http://godatabase.org/cgi-bin/go.cgi?view=query&query=%s';
#	my $url_fmt = 'http://godatabase.org/cgi-bin/go.cgi?action=replace_tree&query=%s';

	$H->e_a(new A {
		class  => 'outlink',
		style  => $M->getStyle('outlink'),
		href   => sprintf($url_fmt,$T),
		target => 'go_external_browser',
		viz    => $T,
	})
}

sub makeOutDbLink {
	my $M = shift;
	my $T = shift;

	my $RV;

	my $H = $M->getHify;

	# we'll figure out what DB/URL from the lead initials
	my ($abbr) = $T =~ /^([a-z]+)/i;

	my $dispatch = {
									pfam  => 'http://www.ncbi.nlm.nih.gov/Structure/cdd/cddsrv.cgi?uid=%s',
									LOAD  => 'http://www.ncbi.nlm.nih.gov/Structure/cdd/cddsrv.cgi?uid=%s',
									smart => 'http://www.ncbi.nlm.nih.gov/Structure/cdd/cddsrv.cgi?uid=%s',
#									PD    => 'http://protein.toulouse.inra.fr/prodom/cgi-bin/ReqProdomII.pl?prodom_release=p2001.1&id_dom1=%s',
									PD    => 'http://protein.toulouse.inra.fr/prodom/2001.3/cgi-bin/request.pl?question=DBEN&query=%s',
								 };

	my $url_fmt = $dispatch->{$abbr};
	if (defined $url_fmt) {
		$RV = $H->e_a( new A {
			class  => 'outlink',
			style => $M->getStyle('outlink'),
			target => 'domain_external_browser',
			href   => sprintf($url_fmt,$T),
			viz    => $T,
		});
	}
	else {
		$RV = $T;
	}

	# return
	$RV
}

sub makeDetailLink {
	my $M = shift;
	my $I = shift;
	my $A = shift;
	my $V = shift;

	my $H = $M->getHify;

	my %i = ( %$I,
						R => 'DetailRuleSet',
						$A => $V,
					);
	my $url = $M->getSelfUrl. '?'. join('&', map {  "$_=$i{$_}" } keys %i );
	$H->e_a(new A {
		href   => $url,
		viz    => $M->makeDetailLinkImage,
		target => 'go_details',
	})
}

sub makeDetailLinkImage {
	my $M = shift;

	my $H = $M->getHify;

	$H->e_img(new A {
		src    => '/images/magnify-blue-12.gif',
		height => 12,
		width  => 12,
	})
}

sub makeYesNo {
	my $M = shift;
	my $V = shift;

	$V ? 'Yes' : 'No'
}

# ----------------------------------------------------------------------
# Database Querying Stuff
# ----------------------------------------------------------------------

sub setDatabase { $_[0]->{DATABASE} = $_[1]; $_[0] }
sub getDatabase { $_[0]->{DATABASE} }

sub setQueryHandle { $_[0]->{QUERYHANDLE} = $_[1]; $_[0] }
sub getQueryHandle { $_[0]->{QUERYHANDLE} }

sub connectToDatabase {
	my $M = shift;

	# setup environment
	{
		$ENV{ORACLE_HOME}      = '/usr/local/oracle/u01/app';
		$ENV{LD_LIBRARY_PATH} .= ':'. $ENV{ORACLE_HOME}. '/lib';

		require dbiperl_utils::DbiDatabase;
	}

	# connect to database
	{
#		my $db = DbiDatabase->new('dbi:Oracle:host=nemesis.pcbi.upenn.edu;sid=gus',
#															'readonly','s7fp4erv',
#															0,0,1,
#															'gus',
#														 );
		my $db = DbiDatabase->new('dbi:Oracle:host=cbilbld.pcbi.upenn.edu;sid=cbilbld',
															'gofuncb','48zoo18n',
															0,0,1,
															'cbilbld',
														 );
#		my $db = DbiDatabase->new('dbi:Oracle:host=themis.pcbi.upenn.edu;sid=cbilrw',
#															'gusdevreadonly','s7fp4erv',
#															0,0,1,
#															'cbilrw',
#														 );
		$M->setDatabase($db);
	}

	# get a query handle
	{
		$M->setQueryHandle($M->getDatabase->getQueryHandle);
	}
}

# ----------------------------------------------------------------------
# GO hierachy : works on GUS id links
# ----------------------------------------------------------------------

sub setGoFuHi { $_[0]->{GFH} = $_[1]; $_[0] }
sub getGoFuHi { $_[0]->{GFH} || $_[0]->loadGoFunctionHierarchy }

sub loadGoFunctionHierarchy {
	my $M = shift;

	my $I = $M->getInput;

	my $sql = "
		select gt.go_term_id
				 , gr.parent_term_id
				 , gt.go_id
				 , gt.name
				 , gt.minimum_level
		from sres.goTerm gt
			 , sres.GoRelationship gr
/*		 , sres.externalDatabaseRelease edr
			 , sres.externalDatabase ed */
		where gt.go_term_id = gr.child_term_id
			and gt.external_database_release_id = 6918
/*		and gt.external_database_release_id = edr.external_database_release_id
			and edr.version = '$I->{cvs}'
			and edr.external_database_id = ed.external_database_id
			and ed.name='GO Function' */
  ";

	#print STDERR 'lGFH', $sql, "\n";
	my $sth = $M->getQueryHandle->prepareAndExecute($sql);

	my $gfh;

	while (my ($gid_c,$gid_p,$id,$name,$mlevel) = $sth->fetchrow_array() ) {
		$gfh->{ par }->{ $gid_c }->{ $gid_p } = 1;
		$gfh->{ chi }->{ $gid_p }->{ $gid_c } = 1;
		$gfh->{ id  }->{ $gid_c }             = $id;
		$gfh->{ nam }->{ $gid_c }             = $name;
		#$gfh->{ roo } = $gid_p  if $mlevel == 1;
	}

	$sth->finish();

	# get root
	my $sql = qq{
    select gt.go_term_id
         , gt.go_id
         , gt.name
    from sres.ExternalDatabase ed
       , sres.ExternalDatabaseRelease edr
       , sres.GoTerm gt
    where ed.external_database_id = edr.external_database_id
      and edr.external_database_release_id = gt.external_database_release_id
      and edr.version = '$I->{cvs}'
      and gt.minimum_level = 0
};
	my $sh = $M->getQueryHandle->prepareAndExecute($sql);
	my ($fid,$id,$name) = $sh->fetchrow_array;
	$sh->finish;
	$gfh->{roo} = $fid;
	$gfh->{id}->{$fid} = $id;
	$gfh->{nam}->{$fid} = 'molecular function';

	# store for later
	$M->setGoFuHi($gfh);

	# return value
	$gfh
}

# ----------------------------------------------------------------------
# Math stuff
# ----------------------------------------------------------------------

sub pValue {
	shift;
	my $M = shift;
	my $E = shift;

	$M * 10 ** $E
}

# ----------------------------------------------------------------------
# Style Sheet workaround
# ----------------------------------------------------------------------

sub loadStyleSheet {
	my $M = shift;

	require FileHandle;

	my $styles;
	my $class;
	my $fh = FileHandle->new("<../htdocs/style.css");
	while (<$fh>) {
		chomp;
		s/^\s+//;
		if (/^}/) {
			;
		}
		elsif (/:/) {
			$styles->{$class} .= $_;
		}
		elsif (/(\S+)\s+\{/) {
			$class = lc $1;
			$class =~ s/^\.//;
			$styles->{$class} = '';
		}
	}
	$fh->close;

	#Disp::Display($styles, '', STDERR);
	$M->{STYLES} = $styles;

	$M
}

sub getStyle {
	my $M = shift;
	my $C = shift;

	$M->{STYLES}->{$C}
}
1;

