
use strict 'vars';

package DetailRuleSet;

use vars qw(@ISA);
use Module;
@ISA = qw( Module );

# ----------------------------------------------------------------------

sub makePage {
	my $M = shift;

	my $start_t = time;

	my $H = $M->getHify;
	my $I = $M->getInput;
	$M->connectToDatabase;
	my $Q = $M->getQueryHandle;
	require Lister;
	my $lister = Lister->new($M);

	my @items;

	# prepare the name of the group.
	my $group_name = join('/',
												'AMGFRS',
												'2001',
												$I->{ddb},
												($I->{iea} =~ /^y/i ? '+' : '-'). 'IEA',
											 );
#	push(@items,
#			 [ 'three', 'Rule Set' ],
#			 [ 'four',  $group_name ],
#			 );


	push(@items, $M->_make_rule_set_table($Q,$lister));
	push(@items, $M->_make_sequence_listing($Q,$lister));
	push(@items, $M->_make_go_func_table($Q,$lister));
	push(@items, $M->_make_similarity_table($Q,$lister));

	# how long did this take?
	my $stop_t = time;
	push(@items,
			 [ three, 'Performance' ],
			 [ four,  sprintf('Elapsed time: %0.2f seconds.', $stop_t - $start_t) ],
			);

	$M->saySomething(\@items);
}


# ----------------------------------------------------------------------

sub _make_rule_set_table {
	my $M = shift;
	my $Q = shift;
	my $L = shift;

	my $H = $M->getHify;
	my $I = $M->getInput;

	my $hint_html = $H->e_p(new A {
		class => 'hint',
		style => $M->getStyle('hint'),
		viz   => <<HINT,
  This is a summary of a rule associating a protein domain model with
  a GO function.
HINT
	});

	# query GUS for members of this set.
	my $oldsql = <<SQL;
    SELECT /*+ RULE */
           s.aa_motif_go_term_rule_set_id
         , s.p_value_threshold_mant
         , s.p_value_threshold_exp
         , s.rule_type
         , s.review_status_id
         , s.confidence
         , s.number_of_annotated_proteins
         , m.name
         , m.description
         , m.source_id
      FROM DoTS.AaMotifGoTermRuleSet s
         , DoTS.MotifAaSequence      m
    WHERE $I->{rsid}          = s.aa_motif_go_term_rule_set_id
      AND m.aa_sequence_id    = s.aa_sequence_id_1
SQL
	my $newsql = <<NEWSQL;
    SELECT 
				   s.aa_motif_go_term_rule_set_id
				 , s.p_value_threshold_mant
				 , s.p_value_threshold_exp
				 , s.rule_type
				 , s.review_status_id
				 , s.confidence
				 , s.number_of_annotated_proteins
				 , m.name
				 , m.description
				 , m.source_id
				 , nvl(ra.rule_applications, 0) rule_applications
			FROM (select count(*) rule_applications,
									 r.aa_motif_go_term_rule_set_id
						from dots.aamotifgotermrule r,
								 dots.evidence e,
								 dots.goAssociationInstance g
						where r.aa_motif_go_term_rule_id = e.fact_id
							and e.fact_table_id = 330 /* AaMotifGoTermRule */
							and e.fact_id = r.aa_motif_go_term_rule_id
							and e.target_table_id = 3177
							and e.target_id = g.go_association_instance_id
							and g.is_deprecated = 0
							and g.review_status_id = 0
						group by r.aa_motif_go_term_rule_set_id) ra
				 , DoTS.MotifAaSequence m
				 , DoTS.AaMotifGoTermRuleSet s
		WHERE $I->{rsid} = s.aa_motif_go_term_rule_set_id
			AND s.aa_motif_go_term_rule_set_id = ra.aa_motif_go_term_rule_set_id(+)
			AND m.aa_sequence_id = s.aa_sequence_id_1
NEWSQL
  my $sql = $newsql;
	print STDERR "\n", $sql, "\n";
	my $sh = $Q->prepareAndExecute($sql);

	my $row_cb = sub {
		my $row = shift;

		$row->{SOURCE_ID} = $M->makeOutDbLink($row->{SOURCE_ID});
		$row->{PVALUE} = $M->pValue($row->{P_VALUE_THRESHOLD_MANT},
																$row->{P_VALUE_THRESHOLD_EXP});
		$row->{NICE_RULE} = $M->getRuleMap()->{$row->{RULE_TYPE}} || "'$row->{RULE_TYPE}'";
		$row->{REVIEW_STATUS_ID} = $M->makeYesNo($row->{REVIEW_STATUS_ID});

print STDERR "\ngetting data for rule set ", $row->{AA_MOTIF_GO_TERM_RULE_SET_ID}, "\n",
						 "rule_applications = ", $row->{RULE_APPLICATIONS}, "\n";
		$row
	};

	# headers
	my $headers = [
								 { -g => ' ',
									 -s => [ { -t => '#',          -a => '#' },
													 { -t => 'AMGTRS',     -a => 'AA_MOTIF_GO_TERM_RULE_SET_ID' },
												 ],
								 },

								 { -g => 'Protein Domain Model',
									 -s => [ { -t => 'ID',         -a => 'SOURCE_ID' },
													 { -t => 'Name',       -a => 'NAME' },
													 { -t => 'Description',       -a => 'DESCRIPTION' },
													 ],
								 },

								 { -g =>  'Association',
									 -s => [ { -t => "Rvw'd",      -a => 'REVIEW_STATUS_ID', },
													 { -t => 'Conf',       -a => 'CONFIDENCE', },
													 { -t => 'Pv',         -a => 'PVALUE', },
													 { -t => 'Type',       -a => 'NICE_RULE' },
													 { -t => 'GOAPs',      -a => 'NUMBER_OF_ANNOTATED_PROTEINS' },
												 ],
								 },

								 { -g =>  'Rule',
									 -s => [ { -t => 'Applications',      -a => 'RULE_APPLICATIONS' },
												 ],
								 },

								];

	([ three, 'Rule Summary'],
	 [ four,  $hint_html   ],
	 [ four, $L->makeTable($I,
												 $H,
												 $headers,
												 $sh,
												 $row_cb
												) ],
	)
}

# ----------------------------------------------------------------------

sub _make_sequence_listing {
	my $M = shift;
	my $Q = shift;
	my $L = shift;

	my $H = $M->getHify;
	my $I = $M->getInput;

	my $hint_html = $H->e_p(new A {
		class => 'hint',
		style => $M->getStyle('hint'),
		viz   => <<HINT,
  This is the sequence of the domain associated with this rule.
HINT
	});

	# query GUS for members of this set.
	my $sql = <<SQL;
    SELECT /*+ RULE */
           m.sequence
      FROM DoTS.AaMotifGoTermRuleSet s
         , DoTS.MotifAaSequence      m
    WHERE $I->{rsid}          = s.aa_motif_go_term_rule_set_id
      AND m.aa_sequence_id    = s.aa_sequence_id_1
SQL
	print STDERR $sql;
	my $sh = $Q->prepareAndExecute($sql);
	my $row = $sh->fetchrow_hashref;

	([ three, 'Sequence'],
	 [ four,  $hint_html   ],
	 [ four, $row->{SEQUENCE} ],
	)
}

# ----------------------------------------------------------------------

sub _make_go_func_table {
	my $M = shift;
	my $Q = shift;
	my $L = shift;

	my $H = $M->getHify;
	my $I = $M->getInput;

	my $hint_html = $H->e_p(new A {
		class => 'hint',
		style => $M->getStyle('hint'),
		viz   => <<HINT,

		These are the details of the GO functions associated with the
		domain.  The leaf term is highlighted.  All paths to the term are
		shown.

HINT
	});

	# query GUS for members of this set.
	my $sql = <<SQL;
    SELECT /*+ RULE */
           f.go_id
         , f.go_term_id
         , f.name
         , f.minimum_level
      FROM DoTS.AaMotifGoTermRuleSet s
         , DoTS.MotifAaSequence      m
         , DoTS.AaMotifGoTermRule    r
         , SRES.GoTerm               f
    WHERE $I->{rsid}          = s.aa_motif_go_term_rule_set_id
      AND m.aa_sequence_id    = s.aa_sequence_id_1
      AND r.aa_motif_go_term_rule_set_id = s.aa_motif_go_term_rule_set_id
      AND r.go_term_id    = f.go_term_id
SQL
	print STDERR $sql;
	my $sh = $Q->prepareAndExecute($sql);
	my $funcs;
	my $root;
	while (my $row = $sh->fetchrow_hashref) {
		$funcs->{$row->{GO_TERM_ID}} = $row;
#		if ($row->{GO_ID} < 0) {
		if ($row->{GO_ID} eq 'GO:0003674') {
			$root = $row;
#			$root->{GO_ID} = 3674;
#			$root->{GO_ID} = 'GO:0003674';
			$root->{NAME} = 'molecular function';
		}
	}
	$sh->finish;

	my @go_rows;
	my $G     = $M->getGoFuHi;
	my @queue = ( { %$root, depth => 0 });
	while (@queue) {
		my $node = pop @queue;
		my @kids = grep { $funcs->{$_} } keys %{$G->{chi}->{$node->{GO_TERM_ID}}};
		my $f = join(' ',
								 $H->e_font(new A {
									 class => 'fixed',
									 style => $M->getStyle('fixed'),
									 viz   => _indent_string($node->{depth}+1),
								 }),
								 $H->e_font(new A {
									 class => 'fixed',
									 style => $M->getStyle('fixed'),
#									 viz => $M->makeGoLink(sprintf('GO%06d', $node->{GO_ID})),
									 viz => $M->makeGoLink($node->{GO_ID}),
								 }),
								 $H->e_font(new A {
									 lass => 'proportional',
									 style => $M->getStyle('proportional'),
									 viz => $node->{NAME} ne 'root' ? $node->{NAME} : 'molecular function',
								 }),
								);
		push(@go_rows, $H->e_tr(new A {
			viz => $H->e_td(new A {
				class => scalar @kids ? 'golist' : 'goleaf',
				style => $M->getStyle(scalar @kids ? 'golist' : 'goleaf'),
				viz => $f,
			}),
		}));

		# mark the called GO-ID.
		unless (scalar @kids) {
			$M->{'--call--'}->{$node->{GO_ID}} = 1;
		}

		foreach my $kid (@kids) {
			push(@queue,
					 { %{$funcs->{$kid}},
						 depth => $node->{depth}+1
					 } ) if $funcs->{$kid};
		}
	}

	# return the stuff to display
	([ three, 'Associated GO Functions'],
	 [ four,  $hint_html ],
	 [ four,  $H->e_table(new A {
		 viz => join("\n", @go_rows),
	 })]
	)
}

# ----------------------------------------------------------------------

sub _make_similarity_table {
	my $M = shift;
	my $Q = shift;
	my $L = shift;

	my $H = $M->getHify;
	my $I = $M->getInput;

	my $hint_sim_html = $H->e_p(new A {
		class => 'hint',
		style => $M->getStyle('hint'),
		viz   => <<HINT,

  This section shows the similarities between the protein domain and
  the GOAPs (score, p-value, and length), the GOAPs (ID, name, and
  source database), the GO associations for the GOAPs (ID, function,
  and evidence code), and whether any association for a GOAP
  supported, dissented, or is below the p-value threshold for the
  derived rule.

HINT
	});

  my $iea_sql = $I->{iea} =~ /^n/i ? "AND gec.name not like '%IEA%'" : '';
	my $sql = <<SQL;

    SELECT /*+ RULE */
           e.evidence_group_id
         , s.score
         , s.pvalue_mant
         , s.pvalue_exp
         , s.total_match_length
         , s.number_positive
         , a.source_id
         , a.name               as a_name
         , a.aa_sequence_id
         , x.lowercase_name
         , gec.name             as go_evidence
         , f.go_association_id
         , g.go_id
         , g.go_term_id
         , g.name               as g_name
      FROM DoTS.Evidence                e
         , DoTS.Similarity              s
         , DoTS.ExternalAASequence      a
         , DoTS.GoAssociation           f
         , SRES.GoTerm                  g
         , SRES.ExternalDatabaseRelease go_xdr
         , SRES.ExternalDatabase        x
         , SRES.ExternalDatabaseRelease xr
         , SRES.GoEvidenceCode          gec
         , DoTS.GoAssocInstEvidCode     gaiec
         , DoTS.GoAssociationInstance   gai 
     WHERE e.target_table_id = 329 /* DoTS.AaMotifGoTermRuleSet */
       AND e.target_id       = '$I->{rsid}'
       AND e.fact_table_id   = 219 /* DoTS.Similarity */
       AND e.fact_id         = s.similarity_id
       AND s.query_id        = a.aa_sequence_id
       AND s.query_id        = f.row_id
       AND f.table_id        = 83 /* DoTS.ExternalAaSequence */
/*     AND f.go_evidence    != 'PRED' ??? */
        $iea_sql 
       AND f.go_term_id  = g.go_term_id
       AND go_xdr.version  = '$I->{cvs}'
       AND g.external_database_release_id = go_xdr.external_database_release_id
       AND a.external_database_release_id  = xr.external_database_release_id
       AND xr.external_database_id  = x.external_database_id
       AND f.go_association_id = gai.go_association_id
       AND gai.go_association_instance_id = gaiec.go_association_instance_id
       AND gaiec.go_evidence_code_id = gec.go_evidence_code_id
     ORDER BY s.pvalue_exp
         , s.pvalue_mant
         , a.source_id
         , g.go_id
SQL
#exit;
	#print STDERR $sql;
#exit;
	my $headers = [ { -g => ' ',
										-s => [ { -t => '#', -a => '#' },
													],
									},
									{ -g => 'Similarity',
										-s => [ { -t => 'Score',   -a => 'SCORE' },
														{ -t => 'Pvalue',   -a => 'PVALUE' },
														{ -t => 'Len',   -a => 'TOTAL_MATCH_LENGTH' },
													],
									},
									{ -g => 'Protein',
										-s => [ { -t => 'ID',      -a => 'SOURCE_ID', },
														{ -t => 'Name',    -a => 'A_NAME', },
														{ -t => 'DB',      -a => 'LOWERCASE_NAME' },
													],
									},

									{ -g => 'Agreement',
										-s => [ { -t => 'Group',   -a => 'EVGID' },
													],
									},

									{ -g => 'GO Annotation',
										-s => [ { -t => 'ID',       -a => 'GO_ID' },
														{ -t => 'Function', -a => 'G_NAME' },
														{ -t => 'Evidence', -a => 'GO_EVIDENCE' },
													],
									},

								];

	my @evgids = qw( error supporting dissenting unused );
	my @colors = qw( red   green      red        black );
  my $sh = $Q->prepareAndExecute($sql);

	# {go_function_id}->{aa_sequence_id} = 1
	my $leaf_count = {};

	my $last_source_id;
	my $row_count = 0;
	my @atts = qw( EVGID SCORE PVALUE TOTAL_MATCH_LENGTH SOURCE_ID A_NAME LOWERCASE_NAME # );

	my $blank = '&nbsp;';
	my $row_cb = sub {
		my $row = shift;

		$row->{PVALUE}         = $M->pValue($row->{PVALUE_MANT},
																				$row->{PVALUE_EXP});
		$row->{LOWERCASE_NAME} =~ s/_/ /g;
#		$row->{GO_ID} = $M->makeGoLink(sprintf('GO%06d', $row->{GO_ID}));
		$row->{GO_ID} = $M->makeGoLink($row->{GO_ID});

		$leaf_count->{$row->{GO_TERM_ID}}->{$row->{AA_SEQUENCE_ID}} = 1;

		if ($row->{SOURCE_ID} eq $last_source_id) {
			$last_source_id = $row->{SOURCE_ID};
			foreach (@atts) {
				$row->{$_} = $blank;
			}
			$row->{'##'} = $row_count;
		}
		else {
			$row_count++;
			$row->{'##'} = ($row->{'#'} = $row_count);
			$last_source_id = $row->{SOURCE_ID};
			$row->{EVGID} = $H->e_font(new A {
				color => $colors[$row->{EVIDENCE_GROUP_ID}],
				viz => $evgids[$row->{EVIDENCE_GROUP_ID}],
			});
		}
	};

	my $sim_table = $L->makeTable({%$I, i=>0, n=>999999},
																$H,$headers,$sh,$row_cb);

	# create weight tree.
	my $weight_tree = $M->_make_weight_tree($leaf_count);
	my $hint_tree_html = $H->e_p(new A {
		class => 'hint',
		style => $M->getStyle('hint'),
		viz   => <<HINT,

  This section shows the portion of the GO molecular function
  hierarchy that is relevent to the set of GOAPs similar to the
  protein domain.  The number to the left of each GO term is the
  number of GOAPs marked with that term.  A GOAP may be associated
  with multiple terms.  Terms marked in orange are the ones selected
  in the rule.

HINT
	});

	(

	 [ three, 'Annotation Tree' ],
	 [ four, $hint_tree_html ],
	 [ four,   $weight_tree ],

	 [ three, 'Protein Similarities and Annotation' ],
	 [ four, $hint_sim_html ],
	 [ four,  $sim_table],

	)
}

# ----------------------------------------------------------------------

sub _make_weight_tree {
	my $M = shift;
	my $C = shift;
	#Disp::Display($C,'LC',STDERR);

	my $H = $M->getHify;
	my $G = $M->getGoFuHi;
	#Disp::Display($G,'$G',STDERR);

	my @rows;
	push(@rows,
			 $H->e_tr(new A {
				 viz => join("\n",
										 map {
											 $H->e_th(new A{
												 class => 'header',
												 style => $M->getStyle('header'),
												 viz => $_,
											 })
										 } ('# GOAPs', 'GO Function' )
										),
			 }),
			);

	# get all nodes on all paths back to root.
	my $nodes = {};
	my @nodes = keys %$C;
	while (my $node = shift @nodes) {
		next if $nodes->{$node};
		$nodes->{$node} = 1;
		push(@nodes, keys %{$G->{par}->{$node}});
	}
	#Disp::Display($nodes, '$nodes', STDERR);

	# expand from root.
	@nodes = ([ $G->{roo}, 0 ]);
	while (my $rec = pop @nodes) {
		my $node = $rec->[0];
		my $lvl  = $rec->[1];

		if ($lvl > 0) {
			my $goaps_n = scalar(keys %{$C->{$node}});
			my $is_call = $M->{'--call--'}->{$G->{id}->{$node}};
			my $style   = $is_call ? 'gopick' : $goaps_n > 0 ? 'goleaf' : 'golist';
			push(@rows,
					 $H->e_tr(new A {
						 viz => join("\n",
												 $H->e_td(new A {
													 viz => $goaps_n,
													 style => 'text-align: center;',
												 }),
												 $H->e_td(new A {
													 class => $style,
													 style => $M->getStyle($style),
													 viz => join(' ',
																			 $H->e_font(new A {
																				 class => 'fixed',
																				 style => $M->getStyle('fixed'),
																				 viz   => join(' ',
																											 _indent_string($lvl),
#																											 $M->makeGoLink(sprintf('GO%06d',
#																																							$G->{id}->{$node})
#																																		 ),
																											 $M->makeGoLink($G->{id}->{$node}),
																											),
																										}),
																			 $G->{nam}->{$node},
																			),
																		}),
												),
											}),
					);
		}

		push(@nodes,
				 map { [ $_, $lvl+1 ] }
				 grep { $nodes->{$_} }
				 keys %{$G->{chi}->{$node}}
				);
	}

	$H->e_table(new A {
		viz => join("\n", @rows),
	})
}

sub _indent_string {
	my $N = shift;

	my $half = int($N/2);

	my $RV = '|' x ($N-1) . '-';

	#$RV .= '-' if $N % 2 == 1;

	$RV
}
