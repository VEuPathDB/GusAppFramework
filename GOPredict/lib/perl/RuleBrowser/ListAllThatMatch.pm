
use strict 'vars';

package ListAllThatMatch;

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

	$I->{'n'} = 50 unless $I->{'n'};
	$I->{'i'} = 1  unless $I->{'i'};

	my @items;

	# prepare the name of the group.
	my $group_name = join('/',
												'AMGFRS',
												'2001',
												$I->{ddb},
												($I->{iea} =~ /^y/i ? '+' : '-'). 'IEA',
											 );
	push(@items,
			 [ 'three', 'Rule Group' ],
			 [ 'four',  $H->e_pre(new A { viz => $group_name }) ],
			);

	# query GUS for members of this set.
	my $rvw_sql = {
								 Yes => ' AND r.review_status_id = 1 ',
								 No  => ' AND r.review_status_id = 0 ',
								}->{$I->{rvw}};
	my $cnf_sql = $I->{cnf} ne 'Any' ?
								 sprintf( " AND r.confidence = '%s' ", lc $I->{cnf}) :
								 '';
	my $sql = <<SQL;

    SELECT /*+ RULE */
           s.aa_motif_go_term_rule_set_id
         , s.p_value_threshold_mant
         , s.p_value_threshold_exp
         , s.rule_type
         , s.number_of_annotated_proteins
         , m.name
         , m.source_id
         , f.go_id
         , f.name       as go_name
         , r.review_status_id
         , r.confidence
         , r.defining  /* was "node_is_leaf" */
      FROM /* Core.ProjectInfo          p
         , DoTS.ProjectLink          l
         , */ DoTS.AaMotifGoTermRuleSet s
         , DoTS.MotifAaSequence      m
         , DoTS.AaMotifGoTermRule    r
         , SRES.GoTerm               f
    WHERE /* p.name              = '$group_name'
      AND p.project_id        = l.project_id
      AND l.id                = s.aa_motif_go_term_rule_set_id
      AND */ m.aa_sequence_id    = s.aa_sequence_id_1
      AND r.aa_motif_go_term_rule_set_id = s.aa_motif_go_term_rule_set_id
      AND r.go_term_id    = f.go_term_id
      AND (
          m.name like '%$I->{pat}%'
       OR m.source_id like '%$I->{pat}%'
       OR f.name      like '%$I->{pat}%'
      )
      AND f.external_database_release_id = 6918
      $rvw_sql
      $cnf_sql
     ORDER BY s.number_of_annotated_proteins DESC
         , m.source_id
         , r.defining
         , f.minimum_level
SQL
	print STDERR $sql;
	# headers
	my $headers = [
								 { -g => ' ',
									 -s => [ { -t => '#',      -a => '#' },
												 ],
								 },

								 { -g => 'Protein Domain Model',
									 -s => [ { -t => 'ID',     -a => 'SOURCE_ID' },
													 { -t => 'Name',   -a => 'NAME' },
													 ],
								 },

								 { -g =>  'Association',
									 -s => [ { -t => "Rvw'd",  -a => 'REVIEW_STATUS_ID', },
													 { -t => 'Conf.',  -a => 'CONFIDENCE', },
													 { -t => 'Pv',     -a => 'PVALUE', },
													 { -t => 'Type',   -a => 'NICE_RULE' },
													 { -t => 'GOAPS',  -a => 'NUMBER_OF_ANNOTATED_PROTEINS', },
													 { -t => 'Detail', -a => 'DETAIL', },
												 ],
								 },

								 { -g => 'GO Function',
									 -s => [ { -t => 'ID',     -a => 'GO_ID' },
													 { -t => 'Leaf',   -a => 'DEFINING' },
													 { -t => 'Name',   -a => 'GO_NAME' },
												 ],
								 },

								];

	my $sh = $Q->prepareAndExecute($sql);

	# redundancy supresion
	# ........................................
	my $last_id;
	my $att_id      = 'AA_MOTIF_GO_TERM_RULE_SET_ID';
	my @atts_to_hid = ( SOURCE_ID, NAME,
											REVIEW_STATUS_ID, CONFIDENCE, PVALUE, NICE_RULE,
											NUMBER_OF_ANNOTATED_PROTEINS,
										);
	my $row_cb = sub {
		my $row = shift;

#		$row->{GO_ID}     = $M->makeGoLink(sprintf('GO%06d', $row->{GO_ID}));
		$row->{GO_ID}     = $M->makeGoLink($row->{GO_ID});
		$row->{SOURCE_ID} = $M->makeOutDbLink($row->{SOURCE_ID});
		$row->{REVIEW_STATUS_ID} = $M->makeYesNo($row->{REVIEW_STATUS_ID});
		$row->{DEFINING}      = $M->makeYesNo($row->{DEFINING});
		$row->{PVALUE} = $M->pValue($row->{P_VALUE_THRESHOLD_MANT},
																$row->{P_VALUE_THRESHOLD_EXP});
		$row->{NICE_RULE} = $M->getRuleMap()->{$row->{RULE_TYPE}} || "'$row->{RULE_TYPE}'";

		$row->{DETAIL}
		= $M->makeDetailLink($I,
												 'rsid',
												 $row->{AA_MOTIF_GO_FUNC_RULE_SET_ID}
												);

		if ($row->{$att_id} == $last_id) {
			$last_id = $row->{$att_id};
			foreach (@atts_to_hid) { $row->{$_} = ' '; }
		}

		$row
	};

	require Lister;
	my $lister = Lister->new($M);
	my $nav_html   = $lister->makeNavButtons($M,$I,$H);
	my $table_html = $lister->makeTable($I,
																			$H,
																			$headers,
																			$sh,
																			$row_cb
																		 );
	push(@items,
			 [ 'three', 'Matching Rule Summaries' ],
			 [ 'four',   $nav_html. $table_html ],
			);

	# how long did this take?
	my $stop_t = time;
	push(@items,
			 [ 'three', 'Performance' ],
			 [ 'four',
				 sprintf('Elapsed time: %0.2f seconds.', $stop_t - $start_t)
			 ],
			);

	$M->saySomething(\@items);
}

