
use strict 'vars';

package GUS::GOPredict::RuleBrowser::ListAll;

use vars qw(@ISA);
use GUS::GOPredict::RuleBrowser::Module;
@ISA = qw( GUS::GOPredict::RuleBrowser::Module );

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
# commented out -- rule groups are no longer broken out into projectInfo records
#	push(@items,
#			 [ 'three', 'Rule Group'],
#			 [ 'four', $H->e_pre(new CBIL::Util::A { viz => $group_name })],
#			);

	# query GUS for members of this set.

	my $rvw_sql = {
								 Yes => "AND r.review_status_id = 1\n",
								 No  => "AND r.review_status_id = 0\n",
								}->{$I->{rvw}};
	my $cnf_sql = $I->{cnf} ne 'Any' ?
								 sprintf( "AND r.confidence = '%s'\n", lc $I->{cnf}) :
								 '';
	my $rty_sql = $I->{rty} ne 'Any' ?
	sprintf("AND s.rule_type like '%s\%'\n",
					$M->getReverseRuleMap->{$I->{rty}},
				 ) : '';
	my $lgo_sql = sprintf("AND s.number_of_annotated_proteins >= %d\n",
												$I->{lgo});

	my $minp_sql = $I->{minp}
								 ? sprintf("AND s.p_value_threshold_exp >= -%d\n", abs($I->{minp}))
								 : '';

	my $maxp_sql = $I->{maxp}
								 ? sprintf("AND s.p_value_threshold_exp < -%d\n", abs($I->{maxp}))
								 : '';

	my $hgo_sql = sprintf("AND s.number_of_annotated_proteins <= %d\n",
												$I->{hgo} || 2000);

	my $name_sql = $I->{pat}
								 ? 'AND (m.name like \'' . $I->{pat} . '\' OR m.source_id like \''
										. $I->{pat} . '\' OR f.name like \'' . $I->{pat} . "\')\n"
								 : '';

	my $sql = <<SQL;
    SELECT s.aa_motif_go_term_rule_set_id
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
         , nvl(ra.rule_applications, 0) rule_applications
      FROM gofuncb.rule_applications ra
         , DoTS.AaMotifGotermRuleSet s
         , DoTS.MotifAaSequence      m
         , DoTS.AaMotifGoTermRule    r
         , SRES.GoTerm               f
    WHERE /* p.name              = '$group_name'
      AND p.project_id        = l.project_id
      AND l.id                = s.aa_motif_go_term_rule_set_id
      AND */ f.external_database_release_id =6918
      AND m.aa_sequence_id    = s.aa_sequence_id_1
      AND r.aa_motif_go_term_rule_set_id = s.aa_motif_go_term_rule_set_id
      AND r.defining      = 1  /* ?? was node_is_leaf */
      AND r.go_term_id    = f.go_term_id
      AND m.source_id not in
        (select source_id from DoTS.RejectedMotif rm, SRes.ExternalDatabaseRelease edr
         where rm.external_database_id = edr.external_database_id
           and edr.external_database_release_id = m.external_database_release_id)
      $rvw_sql $cnf_sql $rty_sql $lgo_sql $hgo_sql $minp_sql $maxp_sql $name_sql
    AND s.aa_motif_go_term_rule_set_id = ra.aa_motif_go_term_rule_set_id(+)
    ORDER BY rule_applications DESC
SQL
	print STDERR $sql;
	my $sh = $Q->prepareAndExecute($sql);
	# headers
	my $headers = [
								 { -g => ' ',
									 -s => [ { -t => '#',     -a => '#' },
												 ],
								 },

								 { -g => 'Protein Domain Model',
									 -s => [ { -t => 'ID',    -a => 'SOURCE_ID' },
													 { -t => 'Name',  -a => 'NAME' },
													 ],
								 },

								 { -g =>  'Association',
									 -s => [ { -t => "Rvw'd",  -a => 'REVIEW_STATUS_ID', },
													 { -t => 'Conf',   -a => 'CONFIDENCE', },
													 { -t => 'Pvalue', -a => 'PVALUE', },
													 { -t => 'Type',   -a => 'NICE_RULE' },
													 { -t => 'GOAPS',  -a => 'NUMBER_OF_ANNOTATED_PROTEINS', },
													 { -t => ' ',     -a => 'DETAIL', },
												 ],
								 },

								 { -g => 'GO Function',
									 -s => [ { -t => 'ID',    -a => 'GO_ID' },
													 { -t => 'Name',  -a => 'GO_NAME' },
												 ],
								 },

								 { -g => 'Rule',
									 -s => [ { -t => 'Applications',    -a => 'RULE_APPLICATIONS' },
												 ],
								 },

								];

	my $row_cb = sub {
		my $row = shift;

		my $GoIdNum = $row->{GO_ID};
	  $GoIdNum =~ s/GO://;
		$row->{GO_ID}     = $M->makeGoLink(sprintf('GO%06d', $GoIdNum));
#		$row->{GO_ID}             = $M->makeGoLink(sprintf('GO%06d',
#																											 $row->{GO_ID}));
		$row->{GO_NAME}           =~ s/\s/&nbsp;/g;
		$row->{SOURCE_ID}         = $M->makeOutDbLink($row->{SOURCE_ID});
		$row->{REVIEW_STATUS_ID} = $row->{REVIEW_STATUS_ID} ? 'Yes' : 'No';
		$row->{PVALUE} = $M->pValue($row->{P_VALUE_THRESHOLD_MANT},
																$row->{P_VALUE_THRESHOLD_EXP});
		$row->{NICE_RULE} = $M->getRuleMap()->{$row->{RULE_TYPE}} || "'$row->{RULE_TYPE}'";

		# bug workaround: coerce RULE_APPLICATIONS to string so zeroes don't become question-marks
		$row->{RULE_APPLICATIONS} = $row->{RULE_APPLICATIONS} . ' ';

		$row->{DETAIL}
		= $M->makeDetailLink($I,
												 'rsid',
												 $row->{AA_MOTIF_GO_TERM_RULE_SET_ID}
												);

		$row
	};

	require GUS::GOPredict::RuleBrowser::Lister;
	my $lister = GUS::GOPredict::RuleBrowser::Lister->new($M);
	my $nav_html   = $lister->makeNavButtons($M,$I,$H);
	#push(@items, [ 'three', $nav_html] );
	my $table_html = $lister->makeTable($I,
																			$H,
																			$headers,
																			$sh,
																			$row_cb
																		 );
	push(@items,
			 [ 'three', 'Rule Summaries' ],
			 [ 'four',   $nav_html. $table_html],
			);

	# how long did this take?
	my $stop_t = time;
	push(@items,
			 [ 'three', 'Performance' ],
			 [ 'four',   sprintf('Elapsed time: %0.2f seconds.', $stop_t - $start_t) ],
			);

	$M->saySomething(\@items);
}

