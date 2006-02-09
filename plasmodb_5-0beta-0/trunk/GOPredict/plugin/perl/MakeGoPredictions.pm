#! /usr/bin/perl

package MakeGoPredictions;

use strict 'vars';

$| = 1;

# ---------------------------------------------------------------------- #
#                                new                                     #
# ---------------------------------------------------------------------- #

sub new {
  my $C = shift;
  my $A = shift;

  my $m = bless {}, $C;

  # mode handlers
  $m->{modes} = {
                   add    => 'addMode',
                   list   => 'listMode',
                   delete => 'deleteMode',
                  };

  # initialize counters
  $m->{n_predictions} = 0;
  $m->{n_rnas}        = 0;
  $m->{error_message} = undef;

	# template
	my $template =
	{ table    => 'AASequenceGOFunction',
		qs_table => 'TranslatedAASequence',
  	qs_xdb   => 0,
		qs_prj   => 0,
		qs_oid   => 'aa_sequence_id',
    ss_table => 'MotifAASequence',
    ss_oid   => 'aa_sequence_id',
		oid      => 'aa_sequence_id',
		aid      => 'aa_sequence_go_function_id',
		gepc     => 1,
		s2oid    => sub { $_[1] },
		new      => sub {
			my $oid = shift;
			my $fid = shift;
			my $evi = shift;

			AASequenceGOFunction->new( { aa_sequence_id    => $oid,
																	 go_function_id    => $fid,
																	 go_evidence       => $evi,
																 } );
		},
	};


  # initialize translations
  $m->{ xlt }->{ as_table } =
	{
	 old_dots =>
	 { table => 'ProteinGOFunction',
		 oid   => 'protein_id',
		 aid   => 'protein_go_function_id',
		 gepc  => 0,
		 s2oid => sub {
			 my $M   = shift;
			 my $Sid = shift;

			 # make sure we've got a translation table
			 unless ( $M->{ xlt }->{ dots }->{ rs2p } ) {
				 $M->{ xlt }->{ dots }->{ rs2p } = $M->__loadDotsRnaToProtein();
			 }

			 # translate
			 $M->{ xlt }->{ dots }->{ rs2p }->{ $Sid }
		 },
		 new   => sub {
			 my $oid = shift;
			 my $fid = shift;
			 my $evi = shift;

			 ProteinGOFunction->new( { protein_id        => $oid,
																 go_function_id    => $fid,
																 manually_reviewed => 0,
															 } );
		 }
	 },

	 # DOTS  
	 dots =>
	 { table    => 'AASequenceGOFunction',
		 qs_table => 'Assembly',
		 qs_xdb   => '0',
		 qs_oid   => 'na_sequence_id',	
     ss_table => 'MotifAASequence',
     ss_oid   => 'aa_sequence_id',
	   oid      => 'aa_sequence_id',
		 aid      => 'aa_sequence_go_function_id',
		 gepc     => 1,
		 s2oid    => sub {
			 my $M   = shift;
			 my $Sid = shift;

			 # make sure we've got a translation table
			 unless ( $M->{ xlt }->{ dots }->{ asm2tra } ) {
				 GusApplication::Log( 'DOTS', 'begin', 'loading xlt cache' );

				 $M->{ xlt }->{ dots }->{ asm2tra } =
				 $M->doSql( $M->{C},
										{q_translation => 1,
										 select => 'am.na_sequence_id, ta.aa_sequence_id',
										 from   => join( ', ',
																		 'Assembly             am',
																		 'RNAFeature           rf',
																		 'TranslatedAAFeature  af',
																		 'TranslatedAASequence ta',
																	 ),
										 where  => [
																'rf.na_sequence_id = am.na_sequence_id',
																'af.na_feature_id  = rf.na_feature_id',
																'af.aa_sequence_id = ta.aa_sequence_id',
															 ],
										}
									);
				 GusApplication::Log( 'DOTS', 'end', 'loading xlt cache' );
			 }

			 $M->{xlt}->{dots}->{asm2tra}->{ $Sid };
		 },
		 new      => sub {
			 my $oid = shift;
			 my $fid = shift;
			 my $evi = shift;

			 AASequenceGOFunction->new( { aa_sequence_id => $oid,
																		go_function_id => $fid,
																		go_evidence    => $evi,
																	} );
		 },
	 },

	 # musDOTS  
	 musdots =>
	 { table    => 'AASequenceGOFunction',
		 qs_table => 'Assembly',
		 qs_xdb   => '0',
		 qs_oid   => 'na_sequence_id',	
     qs_taxon => 14,
     ss_table => 'MotifAASequence',
     ss_oid   => 'aa_sequence_id',
	   oid      => 'aa_sequence_id',
		 aid      => 'aa_sequence_go_function_id',
		 gepc     => 1,
		 s2oid    => sub {
			 my $M   = shift;
			 my $Sid = shift;

			 # make sure we've got a translation table
			 unless ( $M->{ xlt }->{ musdots }->{ asm2tra } ) {
				 GusApplication::Log( 'musDOTS', 'begin', 'loading xlt cache' );

				 $M->{ xlt }->{ musdots }->{ asm2tra } =
				 $M->doSql( $M->{C},
										{q_translation => 1,
										 select => 'am.na_sequence_id, ta.aa_sequence_id',
										 from   => join( ', ',
																		 'Assembly             am',
																		 'RNAFeature           rf',
																		 'TranslatedAAFeature  af',
																		 'TranslatedAASequence ta',
																	 ),
										 where  => [
                                'am.taxon_id       = 14',
   															'rf.na_sequence_id = am.na_sequence_id',
																'af.na_feature_id  = rf.na_feature_id',
																'af.aa_sequence_id = ta.aa_sequence_id',
															 ],
										}
									);
				 GusApplication::Log( 'musDOTS', 'end', 'loading xlt cache' );
			 }

			 $M->{xlt}->{musdots}->{asm2tra}->{ $Sid };
		 },
		 new      => sub {
			 my $oid = shift;
			 my $fid = shift;
			 my $evi = shift;

			 AASequenceGOFunction->new( { aa_sequence_id => $oid,
																		go_function_id => $fid,
																		go_evidence    => $evi,
																	} );
		 },
	 },

	 # humDOTS  
	 humdots =>
	 { table    => 'AASequenceGOFunction',
		 qs_table => 'Assembly',
		 qs_xdb   => '0',
		 qs_oid   => 'na_sequence_id',	
     qs_taxon => 8,
     ss_table => 'MotifAASequence',
     ss_oid   => 'aa_sequence_id',
	   oid      => 'aa_sequence_id',
		 aid      => 'aa_sequence_go_function_id',
		 gepc     => 1,
		 s2oid    => sub {
			 my $M   = shift;
			 my $Sid = shift;

			 # make sure we've got a translation table
			 unless ( $M->{ xlt }->{ humdots }->{ asm2tra } ) {
				 GusApplication::Log( 'humDOTS', 'begin', 'loading xlt cache' );

				 $M->{ xlt }->{ humdots }->{ asm2tra } =
				 $M->doSql( $M->{C},
										{q_translation => 1,
										 select => 'am.na_sequence_id, ta.aa_sequence_id',
										 from   => join( ', ',
																		 'Assembly             am',
																		 'RNAFeature           rf',
																		 'TranslatedAAFeature  af',
																		 'TranslatedAASequence ta',
																	 ),
										 where  => [
                                'am.taxon_id       = 8',
   															'rf.na_sequence_id = am.na_sequence_id',
																'af.na_feature_id  = rf.na_feature_id',
																'af.aa_sequence_id = ta.aa_sequence_id',
															 ],
										}
									);
				 GusApplication::Log( 'humDOTS', 'end', 'loading xlt cache' );
			 }

			 $M->{xlt}->{humdots}->{asm2tra}->{ $Sid };
		 },
		 new      => sub {
			 my $oid = shift;
			 my $fid = shift;
			 my $evi = shift;

			 AASequenceGOFunction->new( { aa_sequence_id => $oid,
																		go_function_id => $fid,
																		go_evidence    => $evi,
																	} );
		 },
	 },

  #Eimeria guide to predictions   
	 eimeria =>
	 { table    => 'AASequenceGOFunction',
		 qs_table => 'Assembly',
		 qs_xdb   => '0',
		 qs_oid   => 'na_sequence_id',	
     qs_taxon => 1124,
     ss_table => 'MotifAASequence',
     ss_oid   => 'aa_sequence_id',
	   oid      => 'aa_sequence_id',
		 aid      => 'aa_sequence_go_function_id',
		 gepc     => 1,
		 s2oid    => sub {
			 my $M   = shift;
			 my $Sid = shift;

			 # make sure we've got a translation table
			 unless ( $M->{ xlt }->{ eimeria }->{ asm2tra } ) {
				 GusApplication::Log( 'eimeria', 'begin', 'loading xlt cache' );

				 $M->{ xlt }->{ eimeria }->{ asm2tra } =
				 $M->doSql( $M->{C},
										{q_translation => 1,
										 select => 'am.na_sequence_id, ta.aa_sequence_id',
										 from   => join( ', ',
																		 'Assembly             am',
																		 'RNAFeature           rf',
																		 'TranslatedAAFeature  af',
																		 'TranslatedAASequence ta',
																	 ),
										 where  => [
                                'am.taxon_id       = 1124',
   															'rf.na_sequence_id = am.na_sequence_id',
																'af.na_feature_id  = rf.na_feature_id',
																'af.aa_sequence_id = ta.aa_sequence_id',
															 ],
										}
									);
				 GusApplication::Log( 'eimeria', 'end', 'loading xlt cache' );
			 }

			 $M->{xlt}->{eimeria}->{asm2tra}->{ $Sid };
		 },
		 new      => sub {
			 my $oid = shift;
			 my $fid = shift;
			 my $evi = shift;

			 AASequenceGOFunction->new( { aa_sequence_id => $oid,
																		go_function_id => $fid,
																		go_evidence    => $evi,
																	} );
		 },
	 },

   # SwissProt guide to making predictions.
	 swissprot =>
	 { table    => 'AASequenceGOFunction',
		 qs_table => 'ExternalAASequence',
		 qs_xdb   => 2893,  # previously 37, 2893 is SP 39.22
		 qs_prj   => 0,
		 qs_oid   => 'aa_sequence_id',
     ss_table => 'MotifAASequence',
     ss_oid   => 'aa_sequence_id',
   	 oid      => 'aa_sequence_id',
		 aid      => 'aa_sequence_go_function_id',
		 gepc     => 1,
		 s2oid    => sub { $_[1] },
		 new      => sub {
			 my $oid = shift;
			 my $fid = shift;
			 my $evi = shift;

			 AASequenceGOFunction->new( { aa_sequence_id    => $oid,
				 													  go_function_id    => $fid,
																	  go_evidence       => $evi,
																  } );
		 },
	
	 },

   # A. Thaliana guide to making predictions.
	 arabidopsis =>
	 { table    => 'AASequenceGOFunction',
		 qs_table => 'ExternalAASequence',
		 qs_xdb   => 2693,
		 qs_prj   => 0,
		 qs_oid   => 'aa_sequence_id',
     ss_table => 'MotifAASequence',
     ss_oid   => 'aa_sequence_id',
   	 oid      => 'aa_sequence_id',
		 aid      => 'aa_sequence_go_function_id',
		 gepc     => 1,
		 s2oid    => sub { $_[1] },
		 new      => sub {
			 my $oid = shift;
			 my $fid = shift;
			 my $evi = shift;

			 AASequenceGOFunction->new( { aa_sequence_id    => $oid,
				 													  go_function_id    => $fid,
																	  go_evidence       => $evi,
																  } );
		 },
	
	 },

   # C. Elegans guide to making predictions.
	 wormpep =>
	 { table    => 'AASequenceGOFunction',
		 qs_table => 'ExternalAASequence',
		 qs_xdb   => 2993, #Wormpep54
		 qs_prj   => 0,
		 qs_oid   => 'aa_sequence_id',
     ss_table => 'MotifAASequence',
     ss_oid   => 'aa_sequence_id',
   	 oid      => 'aa_sequence_id',
		 aid      => 'aa_sequence_go_function_id',
		 gepc     => 1,
		 s2oid    => sub { $_[1] },
		 new      => sub {
			 my $oid = shift;
			 my $fid = shift;
			 my $evi = shift;

			 AASequenceGOFunction->new( { aa_sequence_id    => $oid,
				 													  go_function_id    => $fid,
																	  go_evidence       => $evi,
																  } );
		 },
	
	 },

   # S. cerevisiae guide to making predictions.
	 s_cerevisiae =>
	 { table    => 'AASequenceGOFunction',
		 qs_table => 'ExternalAASequence',
		 qs_xdb   => 2794,
		 qs_prj   => 0,
		 qs_oid   => 'aa_sequence_id',
     ss_table => 'MotifAASequence',
     ss_oid   => 'aa_sequence_id',
   	 oid      => 'aa_sequence_id',
		 aid      => 'aa_sequence_go_function_id',
		 gepc     => 1,
		 s2oid    => sub { $_[1] },
		 new      => sub {
			 my $oid = shift;
			 my $fid = shift;
			 my $evi = shift;

			 AASequenceGOFunction->new( { aa_sequence_id    => $oid,
				 													  go_function_id    => $fid,
																	  go_evidence       => $evi,
																  } );
		 },
	
	 },

  #  flybase guide to making predictions.
	 fly =>
	 { table    => 'AASequenceGOFunction',
		 qs_table => 'ExternalAASequence',
		 qs_xdb   => 2193,
		 qs_prj   => 0,
		 qs_oid   => 'aa_sequence_id',
     ss_table => 'MotifAASequence',
     ss_oid   => 'aa_sequence_id',
   	 oid      => 'aa_sequence_id',
		 aid      => 'aa_sequence_go_function_id',
		 gepc     => 1,
		 s2oid    => sub { $_[1] },
		 new      => sub {
			 my $oid = shift;
			 my $fid = shift;
			 my $evi = shift;

			 AASequenceGOFunction->new( { aa_sequence_id    => $oid,
				 													  go_function_id    => $fid,
																	  go_evidence       => $evi,
																  } );
		 },
	
	 },

   # guide for PlasmoDB predictions. NOTE:  you should also provide 
   # appropriate --sql-from and --sql-filter options on the command 
   # line.  For example:
   #     --sql-from "TranslatedAAFeature tf,
   #                 RNAFeature rf,
   #                 ProjectLink pl
   #     --sql-filter "sim.p_value_exp <= -5                  and 
   #                   q.aa_sequence_id = tf.aa_sequence_id and 
   #                   tf.na_feature_id = rf.na_feature_id  and 
   #                   pl.id = rf.parent_id                 and
   #                   pl.table_id = 108                    and 
   #                   pl.project_id = 113
   # Will allow you to generate predictions for PlasmoDB 3.1.
   plasmo => { %{ $template },
               qs_prj=>8,
             },

   # OLD PlasmoDB guides.  See the --plasmo guide for up to date information.
   # ...................................................................
	 # guide to making predictions for Plasmodium falciparum predictions.
	 #plasmo_finished => {
	 #										 %{ $template },
	 #										 qs_xdb => 22,
	 #										},
	 #plasmo_draft => {
	 #									%{ $template },
	 #									qs_xdb=> 151,
   #                  qs_prj=>8,
	 #								 },
	 # guide for GENSCAN predictions from ORNL
	 ornl_genscan => { %{ $template }, qs_xdb => 183, },


	 # guide for GRAIL predictions from ORNL
	 ornl_grail =>  { %{ $template }, qs_xdb => 184, },


	 # guide for RIKEN full-length mRNAs
	 # ......................................................................
	 # These are entered as ExternalNASequences.  Similarities are
	 # between ExternalNASequence and ProDom.  The GO annotation will be
	 # put in AASequenceGFunction.  The link between ExternalNASequence
	 # and TranslatedAASequence is:
	 #
	 # ExtNASeq <- RNAFeature <- TranslatedAAFeature -> TranslatedAASequence
	 #
	 # The the mapping from ExternalNASequence to TranslatedAASequence
	 # must be loaded.

	 riken => { %{ $template },
							qs_xdb => 185,
#	 { table    => 'AASequenceGOFunction',
#		 qs_table => 'ExternalNASequence',
#		 qs_xdb   => 185,
#		 qs_oid   => 'na_sequence_id',
#		 oid      => 'aa_sequence_id',
#		 aid      => 'aa_sequence_go_function_id',
#		 gepc     => 1,
		 s2oid    => sub {
			 my $M   = shift;
			 my $Sid = shift;

			 # make sure we've got a translation table
			 unless ( $M->{ xlt }->{ riken }->{ rs2aa } ) {

				 GusApplication::Log( 'RIKEN', 'begin', 'loading xlt cache' );

				 $M->{ xlt }->{ riken }->{ rs2aa } =
				 $M->doSql( $M->{C},
										{
										 q_translation => 1,
										 select        => 'e.na_sequence_id, t.aa_sequence_id',
										 from          => join( ', ',
																						'ExternalNASequence    e',
																						'RNAFeature           rf',
																						'TranslatedAAFeature  tf',
																						'TranslatedAASequence  t',
																					),
										 where         => [ 'e.external_db_id  = 185',
																				'e.na_sequence_id  = rf.na_sequence_id',
																				'rf.na_feature_id  = tf.na_feature_id',
																				'tf.aa_sequence_id = t.aa_sequence_id'
																			]
										}
									);

				 GusApplication::Log( 'RIKEN', 'end', 'loading xlt cache' );
			 }

			 # translate
			 $M->{ xlt }->{ riken }->{ rs2aa }->{ $Sid }
		 },
#		 new      => sub {
#			 my $oid = shift;
#			 my $fid = shift;
#			 my $evi = shift;
#
#			 AASequenceGOFunction->new( { aa_sequence_id    => $oid,
#																		go_function_id    => $fid,
#																		go_evidence       => $evi,
#																	} );
#		 },
	 },

	};

	# return the new plugin
	$m
}

# ---------------------------------------------------------------------- #
#                             isReadOnly                                 #
# ---------------------------------------------------------------------- #

sub isReadOnly { 0 }

# ---------------------------------------------------------------------- #
#                               usage                                    #
# ---------------------------------------------------------------------- #

sub Usage {
  my $M = shift;

  'Makes GO function predictions for RNA/proteins using ProDom Similarities'
}

# ---------------------------------------------------------------------- #
#                           EasyCspOptions                               #
# ---------------------------------------------------------------------- #

sub EasyCspOptions {
  my $M = shift;

  +{

		# local enable
		LE          => { o => 'le',
										 t => 'boolean',
										 h => 'locally enable ga_submit',
										 d => 1,
									 },

    # mode selection
    mode        => { o => 'mode',
										 t => 'string',
                     h => 'operate in this mode',
                     e => [ keys %{ $M->{ modes } } ],
                   },

    # invocation id when we're listing or deleting.  When add mode, used to select rules.
    raid        => { o => 'raid=s',
                     h => 'row_alg_invocation_id for list/delete modes or for selecting rules',
                     l => 1,
                   },

    # extra filter for SQL rule selection
		rule_sql_filter =>  { o => 'rule-sql-filter=s',
                          t => 'string',
                          h => 'extra where clause terms used for rule selection, OVERRIDES the raid parameter; remember ruleset table is called "rs"',
									 },


    # external db id of subject/motif database; used in selection of similarities when in add mode.
	  ss_xdb       => { o => 'ss-xdb=s',
			                h => 'external db id of motif database(s)',
    	                l => 1,
                      d => '2293', # prodom 2001.1, was previously 148.
		               },

    # testing
    t_show        => { o => 't-show!',
                     h => 'show messages in testing phase',
                     },

		show_go_rules => { o => 'show-go-rules',
											 t => 'boolean',
											 h => 'show GO rule cache',
										 },

    # ignore existing predictions for sequence, gofunc that were not predicted by this 
    # run of the plugin.  This is required in order to test different rule sets
    ignore_expred  => { o => 'ignore-expred!',
                        h => 'ignore existing predictions, note may cause duplicate predictions! ',
                     },

    # jobs
    job_file    => { o => 'job-file=s',
                     h => 'read job rows from this file',                   },
    job_log     => { o => 'job-log=s',
                     h => 'log jobs',
                   },

    # selecting the query sequences.
		qs_old_date     => { o => 'qs-old-date',
												 t => 'string',
												 h => 'date of oldest sequence allowable',
												 d => '01/01/1900',
											 },

    qs_type     => { o => 'qs-type=s',
                     h => 'query sequence type',
                     e => [ qw( aa na rna ) ],
										 d => 'aa',
                   },

    qs_table    => { o => 'qs-table=s',
                     h => 'select query sequences from this table',
                   },

    qs_project  => { o => 'qs-project=s',
                     h => 'select sequences with this project',
                   },

    qs_count    => { o => 'qs-count=i',
                     h => 'process this many query sequences',
                     d => 1,
                   },

    # selecting the similarities
    sm_pvalues   => { o => 'sm-pvalues=s',
                      h => 'pvalues for similarities and predictions',
                      l => 1,
                    },

    sm_nom       => { o => 'sm-nom=i',
                      h => 'maximum number of matches allowed',
                      d => 5,
                    },

    # selecting the GO ontology version
    go_ver       => { o => 'go-ver=s',
                      h => 'SQL-like term to select GO ontology version',
											d => '%2.61%',
                    },

		# pv-ratio and/or threshold 
		pv_ratio     => { o => 'pv-ratio',
											t => 'float',
											h => 'p-value ratio threshold for sim/rule',
											d => 1.0
										},

		pv_threshold => { o => 'pv-threshold',
											t => 'float',
											h => 'p-value threshold for sim/rule',
										},

    # selecting association table
    as_table =>    { o => 'guide=s',
										 h => 'guide-name for table to hold associations',
										 e => [ keys %{ $M->{ xlt }->{ as_table } } ],
										 d => 'dots',
									 },

		# extra filter for SQL similarity selection
		sql_filter =>  { o => 'sql-filter=s',
										 t => 'string',
										 h => 'extra where clause terms used for similarity selection; remember query sequence table is called "q"',
									 },
	  # extra FROM for similarity selection
		sql_from   =>  { o => 'sql-from=s',
										 t => 'string',
										 h => 'extra FROM clause terms used for similarity selection.',
                   },

   } # eo easy csp options
}

# ---------------------------------------------------------------------- #
#                                Run                                     #
# ---------------------------------------------------------------------- #

sub Run {
  my $M = shift;
  my $C = shift;  # context

  # tuck the context in to self
  $M->{C} = $C;
	$M->{dbq} = $C->{self_inv}->getQueryHandle();

	#Disp::Display( $M, '', STDERR, 3 );

  # get method name
  my $method = $M->{ modes }->{ $M->{C}->{cla}->{ mode } };
  if ( defined $method ) {
    $M->$method( $M );
  }
  else {
    GusApplication::Log( 'MODE', $M->{C}->{cla}->{ mode }, 'not supported' );
  }
}

# ...................................................................... #
#                              listMode                                  #
# ...................................................................... #

sub listMode {
  my $M = shift;

  # list the rows related to a prior run of this plug-in

  # these are possible tables which depend on the sequence source.
  my %tables = ( Evidence  => 1 );
	foreach ( keys %{ $M->{ xlt }->{ as_table } } ) {
    $tables{ $M->{ xlt }->{ as_table }->{ $_ }->{ table } } = 1;
	}

  # count and display rows in each possible table
  foreach my $table ( keys %tables ) {
    my $rows = $M->doSql( $M->{C},
                          {
                           q_complex_list => 1,
                           select         => '*',
                           from           => $table,
                           where          => [ 'row_alg_invocation_id in ('. 
																							 join( ', ', @{ $M->{C}->{cla}->{ raid } } ).
																							 ')' ],
                          }
                        );
    GusApplication::Log( 'ROWS', $table, scalar @{ $rows } );
    if ( $M->{C}->{cla}->{ t_show } ) {
      foreach my $row ( @{ $rows } ) {
        GusApplication::Log( 'ROW', $table, @{ $row } );
      }
    }
  }

	"listed rows for RAID ok";
}

sub deleteMode {
  my $M = shift;

	# handle to the database
  my $dbh = $M->{C}->{ db }->getExtentHandle();

  # these are possible tables which depend on the sequence source.
  my %tables = ( Evidence  => 1 );
	foreach ( keys %{ $M->{ xlt }->{ as_table } } ) {
    $tables{ $M->{ xlt }->{ as_table }->{ $_ }->{ table } } = 1;
	}

	my $rv_msg = 'just testing';

  # count and display rows in each possible table
  foreach my $table ( keys %tables ) {

		my $delete__sql = join( ' ',
														'delete from',
														$table,
														'where row_alg_invocation_id in (',
														join( ', ', @{ $M->{C}->{cla}->{ raid } } ),
														')'
													);

		GusApplication::Log( 'SQL', $delete__sql );

		if ( $M->{C}->{cla}->{ commit } ) {
			my $stmt_h = $M->{dbq}->prepareAndExecute($delete__sql);
			my ($row)  = $stmt_h->fetchrow_array();
			my $rv     = $stmt_h->finish();
			GusApplication::Log( 'DELETED', $row, $rv );
			$rv_msg = sprintf( 'deleted (%d,%d) rows from RAID(s) %d',
												 $row, $rv,
												 join( ',', @{ $M->{C}->{cla}->{ raid } } )
											 );
		}

  } # eo table name scan

}

# ====================================================================== #
# ====================================================================== #

sub addMode {
  my $M = shift;

  my $C = $M->{C};

  require Objects::GUSdev::AAMotifGoFunctionRule;
  require Objects::GUSdev::AAMotifGoFunctionRuleSet;
  require Objects::GUSdev::Evidence;
  require Objects::GUSdev::GOFunction;
  require Objects::GUSdev::GOFunctionHierarchy;
  require Objects::GUSdev::RNASequence;
  require Objects::GUSdev::Similarity;

  # ........................................

  # plasmo mode
  require Objects::GUSdev::AASequenceGOFunction;

  # ornl mode
  require Objects::GUSdev::AASequenceGOFunction;

  # dots mode
  require Objects::GUSdev::ProteinGOFunction;

  # ........................................

  GusApplication::Log( 'RAID', $C->{ self_inv }->getId() );

  # initialize
  $M->{ error_message } = undef;

  if ( 0 ) {

    # get a list of sequence that have similarities to ProDom
    my $id_seqs = $M->getSequenceIds( $C );
    GusApplication::Log( 'NSQ', scalar @{ $id_seqs } ); #if $C->{cla}->{ t_show };

    # process each one.
    for ( my $i = 0; $i < $C->{cla}->{ qs_count }; $i++ ) {
      my $id_seq = $id_seqs->[ $i ];
      last unless defined $id_seq;
      $M->predictGoFunctions( $C, $id_seq )
    }
  }

  # simple version where all the work is done by SQL.
  elsif ( 0 ) {

		# get all the compatible similarities and rules
    my $jobs = $M->getJobs( $C );
    GusApplication::Log( 'NJB', scalar @{ $jobs } ) if $C->{cla}->{ t_show };

		# print them out if requested
    if ( $C->{cla}->{ job_log } ) {
      foreach my $job ( @{ $jobs } ) {
        GusApplication::Log( 'JOB', @{ $job } );
      }
    }

		# track predictions that we've made for counting
    my %rnas;
    my %sets;

		# process the jobs
    foreach my $job ( @{ $jobs } ) {
      my ( $id_sim, $id_q, $id_s, $id_rs, $id_r, $id_f ) = @{ $job };
      my $gus_rule = $M->makeObjects( $C, 'AAMotifGoFunctionRule', 
																			'aa_motif_go_func_rule_id', $id_r );
      my $gus_sim  = $M->makeObjects( $C, 'Similarity',
																			'similarity_id',            $id_sim );
      if ( $M->processRule( $C, $id_q, $gus_rule, $gus_sim, $id_f ) ) {
        $rnas{ $id_q  } = 1;
        $sets{ $id_rs } = 1;
      }
      $M->{C}->{ self_inv }->undefPointerCache();
    }

    # count up what we did.
    $M->{ n_rnas        } = scalar keys %rnas;
    $M->{ n_predictions } = scalar keys %sets;

  }

	# another version which preloads GO rules and processes similarities
	# serially.
	else {

		# load GO rules cache
		$M->getGoRules( $C );

		# track predictions that we've made for counting
		# ........................................

		# best p-value for a rule successfully applied to a sequence.
    my %rnas;

    my %sets;

		# build query for getting similarities;
    my $ast = $M->{ xlt }->{ as_table }->{ $C->{cla}->{ as_table } };
		my $sql = join( ' ',
										'select', 
										join( ",\n  ",
													'sim.similarity_id',
													'sim.query_id',
													'sim.subject_id',
													'sim.pvalue_mant',
													'sim.pvalue_exp',
												),
										"\n  from ",
										join( ",\n  ",
													'Similarity sim',
													$ast->{ qs_table }. ' q',
                          $ast->{ ss_table }. ' s',
                          defined $C->{cla}->{sql_from} ? $C->{cla}->{sql_from} : ()
											),
										"\n where",
										join( "\n  and ",
													'sim.subject_table_id   = 277',
													'sim.query_table_id     = '. $C->{ tbl2id }->{ $ast->{ qs_table } },
													'sim.number_of_matches  < 5',
													'sim.query_id           = q.'. $ast->{ qs_oid },
                          'sim.subject_id         = s.'. $ast->{ ss_oid },
                          's.external_db_id       in ( '.join( ', ', @{ $C->{cla}->{ ss_xdb } } ).') ',
													$ast->{qs_xdb} ? 'q.external_db_id       = '. $ast->{ qs_xdb } : (),
													$ast->{qs_taxon} ? 'q.taxon_id              = '. $ast->{ qs_taxon } : (),
													defined $C->{cla}->{sql_filter} ? $C->{cla}->{sql_filter} : ()
												),
										"\n order by",
										'sim.pvalue_exp, sim.pvalue_mant',
									);
		GusApplication::Log( 'GETSIMS', 'sql', $sql ) if $C->{cla}->{ t_show };

		my $stmt_h = $M->{dbq}->prepareAndExecute($sql);

		#Disp::Display( $M->{ GoRuleCache } );

		# process each row
		while ( my @row = $stmt_h->fetchrow_array() ) {

			GusApplication::Log( 'row', @row );

			# see if we have a GO rule (set) for this domain
			if ( my $rules = $M->{GoRuleCache}->{$row[2]} ) {

			# see if similarity p-value is acceptable for rule

				my $score            = pv($row[3],$row[4]);
				my $log_score        = $score       ? -log10($score)       : 1000;

				# compare to p-value thershold for rule
				my $log_thresh       = $rules->{pv} ? -log10($rules->{pv}) : 1000;
				my $p_value_ratio    = $log_score / $log_thresh;
				my $p_value_ratio_ok = $p_value_ratio >= $C->{cla}->{pv_ratio};

				# compare to CLA p-value and best so far for protein.
				my $bestPvalue       = $rnas{$row[1]};
				my $logBestPvalue    = (defined $bestPvalue ?
																($bestPvalue>0 ? -log10($bestPvalue) : 1000) :
																undef
															 );
				my $p_value_ok       = ( defined $C->{cla}->{pv_threshold} &&
																 $score <= $C->{cla}->{pv_threshold} &&
																 ( ! defined $rnas{$row[1]} ||
																	 $log_score/$logBestPvalue >= 0.5
																 )
				,											 );

				# ok to apply rule
				if ( $p_value_ratio_ok || $p_value_ok ) {

					# record for posterity.
					GusApplication::Log( 'good-pv', @row, $rules->{pv},
															 defined $rnas{$row[1]} ? $rnas{$row[1]} : 'undef',
															 $p_value_ratio_ok||0, $p_value_ok||0);

					# make the call.
					my $gus_sim  = $M->makeObjects( $C, 'Similarity',
																					'similarity_id',
																					$row[0] );
					foreach my $rule ( @{ $rules->{ rules } } ) {
						my $gus_rule = $M->makeObjects( $C, 'AAMotifGoFunctionRule',
																						'aa_motif_go_func_rule_id',
																						$rule->{ rid } );
						if ( $M->processRule( $C, $row[1], $gus_rule,
																	$gus_sim, $rule->{ gid },
																	$p_value_ratio
																)
							 ) {

							# record best p-value for this sequence
							$rnas{$row[1]} = $score unless defined $rnas{$row[1]};

							# record application of this rule set
							$sets{$rules->{ rsid }}++;

						} # eo made a new call.
					} # eo rules for this rule set
				} # eo p-value is good enough
				else {
					GusApplication::Log( 'bad-pv', @row, $rules->{pv},
															 defined $rnas{$row[1]} ? $rnas{$row[1]} : 'undef',
															 $p_value_ratio_ok||0, $p_value_ok||0 );
				}
			} # eo rule for this domain
			else {
				GusApplication::Log( 'norule', @row );
			}
			$M->{C}->{ self_inv }->undefPointerCache();
		}

		$stmt_h->finish();

    # count up what we did.
    $M->{ n_rnas        } = scalar keys %rnas;
    $M->{ n_predictions } = scalar keys %sets;
	}

	my $msg = sprintf( 'Made %d predictions for %d %s sequences.%s',
										 $M->{ n_predictions },
										 $C->{cla}->{ qs_type },
										 $M->{ n_rnas },
										 $C->{cla}->{LE} ? ' Commited' : 'Testing'
									 );
	GusApplication::Log( 'DONE', $msg );

  # return results string, either error or progress
  $M->{ error_message } || $msg
}

# ......................................................................
# build a list

sub mL {
  my $M = shift;
  my $D = shift; # delimiter
  my $L = shift; # list ref or value

  my $s_list;

  # either join with delimiter
  if ( ref $L eq 'ARRAY' ) {
    $s_list = join( $D, @{ $L } )
  }

  # or simply return
  else {
    $s_list = $L
  }

  # return the string
  $s_list
}

# ......................................................................
# execute sql
#
# Takes a hash describing the query and the form of the results.
# Builds and executes the SQL and returns structured results.
#
sub doSql {
  my $M = shift;
  my $C = shift;
  my $S = shift;

  my $sql_select = 'select '. $M->mL( ', ', $S->{ select } );
  my $sql_from   = 'from '.   $M->mL( ', ', $S->{ from } );
  my $sql_where  = $S->{ where }
    ? 'where '.  $M->mL( ' and ', $S->{ where } )
    : '';

  my $sql = join( ' ', $sql_select, $sql_from, $sql_where );

  GusApplication::Log( 'SQL', $sql ) if $C->{cla}->{ t_show };

	my $statement_h = $M->{dbq}->prepareAndExecute($sql);

	my $rows_n = 0;
  my $results;

  if ( $S->{ q_simple_list } ) {
    while ( my ( $id ) = $statement_h->fetchrow_array() ) {
      push( @{ $results }, $id )
    }
  }

  elsif ( $S->{ q_simple_set } ) {
    my $set;
    while ( my ( $id ) = $statement_h->fetchrow_array() ) {
      $set->{ $id } = 1;
    }
    $results = [ keys %{ $set } ];
  }

  elsif ( $S->{ q_complex_list } ) {
    while ( my ( $id, @stuff ) = $statement_h->fetchrow_array() ) {
			#if ( $rows_n++ % 50 == 0 ) {
			#	my $time = localtime;
			#	print "$rows_n\t$time\n"
			#}
			#	print '.'; 
      push( @{ $results }, [ $id, @stuff ] )
    }
  }

  elsif ( $S->{ q_complex_hash } ) {
    while ( my ( $id, @stuff ) = $statement_h->fetchrow_array() ) {
      $results->{ $id } = [ $id, @stuff ]
    }
  }

  elsif( $S->{ q_translation } ) {
    while ( my ( $id_from, $id_to ) = $statement_h->fetchrow_array() ) {
      $results->{ $id_from } = $id_to;
    }
  }

	$statement_h->finish();

  # return a reference to the hash
  $results;
}

# ......................................................................
# make objects
#
# Takes an object name and a list of ids, then instantiates objects
# for each id.  Returns a list ref of the objects.
#
sub makeObjects {
  my $M = shift;
  my $C = shift; # context
  my $O = shift; # object
  my $I = shift; # id attribute name
  my $L = shift; # ( ref to list of ) id.

  eval "require Objects::GUSdev::$O";

  if ( ref $L ) {
    [
     map
     {
       my $o = $O->new( { $I => $_ } );
       $o->retrieveFromDB();
       $o
     }
     @{ $L }
    ]
  }

  else {
    $O->new( { $I => $L } );
  }
}

# ......................................................................
# getJobs
#
# Do the big join to get only the productive tuples
#
# [ similarity_id, rna_sequence_id, motif_id, rule_set_id ]
#

sub getJobs {
  my $M = shift;
  my $C = shift;

  # we've already gotten a list of jobs which we can simply read.
  # we take 6 columns starting with the 3rd to get the job information

  if ( defined $C->{cla}->{ job_file } ) {

    my @jobs;

    require FileHandle;

    my $fh_job = FileHandle->new( '<'. $C->{cla}->{ job_file } );
    if ( $fh_job ) {
      while ( <$fh_job> ) {
        next unless /^JOB\t/;
        chomp;
        my ( $linetype, $date, @parts ) = split /\t/;
        push( @jobs, \@parts );
      }
      $fh_job->close;
    }
    else {
      GusApplication::Log( 'jf-err', $! );
    }

    \@jobs;
  }

  else {
    my $ast = $M->{ xlt }->{ as_table }->{ $C->{cla}->{ as_table } };

    my $sql_raid = $C->{cla}->{ raid } && scalar @{ $C->{cla}->{ raid } } 
    ? 'rs.row_alg_invocation_id in ( '. join( ', ', @{ $C->{cla}->{ raid } } ). ' )'
    : '/* no raid selection */ 1 = 1';

    my $infos =
		$M->doSql( $C,
							 {
								q_complex_list => 1,
								select =>
								join( ', ',
											'sim.similarity_id',
											'sim.query_id',
											'sim.subject_id',
											'rs.aa_motif_go_func_rule_set_id',
											'r.aa_motif_go_func_rule_id',
											'r.go_function_id',
											'f.name',
											'f.go_version',
										),
								from   =>
								join( ', ',
											'Similarity sim',
											'AAMotifGoFunctionRuleSet rs (index PK_AA_MTF_GO_FNC_RULE_SET)',
											'AAMotifGoFunctionRule r (index PK_AA_MTF_GO_FNC_RULE)',
											'GOFunction f',
											$ast->{ qs_table }. ' q',
										),
								where          =>
								[ 'sim.subject_table_id   = 277',
									'sim.query_table_id     = '. $C->{ tbl2id }->{ $ast->{ qs_table } },
									'sim.number_of_matches  < 5',
									'sim.subject_id         = rs.aa_sequence_id_1',
									'sim.pvalue_exp        <= rs.p_value_threshold_exp',
									'sim.pvalue_mant       <= rs.p_value_threshold_mant',
									'r.aa_motif_go_func_rule_set_id = rs.aa_motif_go_func_rule_set_id',
									'r.go_function_id       = f.go_function_id',
									#'f.name                <> "root"',
									'sim.query_id           = q.'. $ast->{ oid },
									'q.external_db_id       = '. $ast->{ qs_xdb },
									$sql_raid,
								],
							 } );

		return [ grep { $_->[ 6] ne 'root' && $_->[ 7 ] =~ $C->{cla}->{ go_ver } } @{ $infos } ];
  }
}

# ......................................................................
# getSequenceIds
#
# Look through appropriate table for sequences in the requested
# project.  Returns a list ref of the ids.
#
sub getSequenceIds {
  my $M = shift;
  my $C = shift;

  $M->doSql( $C,
           {
            q_simple_list => 1,
            select => $C->{cla}->{ qs_type }. '_sequence_id',
            from   => $C->{cla}->{ qs_table },
            where  => 'row_project_id = '. $C->{ prj2id }->{ $C->{cla}->{ qs_project } },
           } )
}

# ......................................................................
# getGoRules
#
# Extract a hash of ProDom GUS id -> { pv    => double,
#                                      rsid  => gus_id
#                                      rules => [ { rid => gus id for rule
#                                                   gid => gus if for function
#                                               } ],
#                                     };

sub getGoRules {
	my $M = shift;
	my $C = shift;

	GusApplication::Log( 'GORULES', 'begin', 'loading GO cache' );
  my $raid_sql;

	# get the information
  if (defined $C->{cla}->{rule_sql_filter}){ # override the alginv ids...just use the rule_sql_filter
    $raid_sql =  $C->{cla}->{rule_sql_filter};
  } else {
	  $raid_sql = $C->{cla}->{ raid } && scalar @{ $C->{cla}->{ raid } } 
    ? 'rs.row_alg_invocation_id in ( '. join( ', ', @{ $C->{cla}->{ raid } } ). ' )'
    : '/* no raid selection */ 1 = 1';
	}
  my $list = $M->doSql( $C,
												{
												 q_complex_list => 1,
												 'select'
												 => join( ",\n  ",
																	'rs.aa_sequence_id_1',
																	'rs.p_value_threshold_mant',
																	'rs.p_value_threshold_exp',
																	'rs.aa_motif_go_func_rule_set_id',
																	'r.aa_motif_go_func_rule_id',
																	'r.go_function_id',
																),
						 						 from
												 => join( ",\n  ",
																	'AAMotifGoFunctionRuleSet rs',
																	'AAMotifGoFunctionRule    r',
																	'GOFunction               f',
																),

												 where
												 => join( "\n  and ",
																	'r.aa_motif_go_func_rule_set_id  = rs.aa_motif_go_func_rule_set_id',
																	'r.go_function_id                = f.go_function_id',
																	q{f.name                         <> 'root'},
																	"f.go_version                 like '$C->{cla}->{ go_ver }'",
																	$raid_sql,
																),
												} );

	GusApplication::Log( 'GORULES', 'end', 'loading GO cache' );
	#Disp::Display( $list, 'LIST', STDOUT );

	# convert list to cache format
	foreach ( @{ $list } ) {
		GusApplication::Log( 'GORULE', @{ $_ } ) if $C->{cla}->{show_go_rules};
		$M->{ GoRuleCache }->{ $_->[0] }->{ pv   } = pv($_->[1],$_->[2]);
		$M->{ GoRuleCache }->{ $_->[0] }->{ rsid } = $_->[3];
		push( @{ $M->{ GoRuleCache }->{ $_->[0] }->{ rules } },
					{ rid => $_->[4],
						gid => $_->[5],
					},
				);
	}

}

# ......................................................................
# iterateOverSimilarities
#
# Iterates over similarities between query db and ProDom and applies GO
# rules to those that have applicable rules.
#

sub iterateOverSimilarities {
	my $M = shift;
	my $C = shift;
}

# ......................................................................
### predict GO functions
#
# Processes a single sequence id.  Retrieves all of the Similarity
# entries between the sequence and ProDom entries.  It then processes
# each entry to make any function calls that are possible at all
# requested p-values.
#
sub predictGoFunctions {
  my $M  = shift;
  my $C  = shift; # context
  my $Id = shift; # id

  # keep the context for easy access.
  $M->{C} = $C;

  GusApplication::Log( 'pGF', $Id ) if $C->{cla}->{ t_show };

  # table id for query sequences.
  my $qs_table_id = $C->{ tbl2id }->{ $C->{cla}->{ qs_table } };

  # get the Similarity IDs and and create objects.
  my $sim_infos =
  $M->doSql( $C,
             {
              q_simple_list => 1,
              select => 'similarity_id',
              from   => 'Similarity',
              where  => [ 'subject_table_id = 277',
                          'query_table_id   = '. $qs_table_id,
                          'query_id         = '. $Id,
                        ],
             } );
  my $gus_sims = $M->makeObjects( $C, 'Similarity', 'similarity_id', $sim_infos );

  # count how many rules we used.
  my $n_rules = 0;

  # process the similarities
  foreach my $gus_sim ( @{ $gus_sims } ) {

    # skip fragmented similarities.
    next if $gus_sim->getNumberOfMatches() > $C->{cla}->{ sm_nom };

    # specific p-value rule sets

    if ( defined $C->{cla}->{ sm_pvalues } &&
         scalar @{ $C->{cla}->{ sm_pvalues } } > 0 ) {

      # at each p-value threshold
      foreach my $pvalue ( @{ $C->{cla}->{ sm_pvalues } } ) {

        GusApplication::Log( 'SIM',
                             $gus_sim->getId(),
                             $pvalue, $gus_sim->getPValue(),
                             $C->{cla}->{ sm_nom }, $gus_sim->getNumberOfMatches(),
                           );

        # skip bad ones with either too high p-values or too many
        # matches (HSPs)
        next if $gus_sim->getPValue() > $pvalue;

        # process the good ones.
        $n_rules += $M->processSimilarity( $C, $Id, $gus_sim, $pvalue );
      }
    } # eo specific p-value rule sets

    # sliding p-value rule sets.
    else {
      $n_rules += $M->processSimilarity( $C, $Id, $gus_sim )
    } # eo sliding rule sets
  } # eo similarity loop

  # undef pointer cache
  $gus_sims->[0]->undefPointerCache() if @{ $gus_sims };

  # return value
  $n_rules
}

# ......................................................................
### process a similarity
#
# find the relevant rule set for this domain and pvalue
# instantiate an object for it
# process all the rules it contains.
#
sub processSimilarity {
  my $M  = shift;
  my $C  = shift; # context
  my $Id = shift; # sequence id
  my $Sm = shift; # similarity
  my $Pv = shift; # pvalue          optional

  # get rules for this domain, give up if there are none.

  # we either want a specific p-value rule or any that would apply
  # this similarity.
  my @sql_where_pv;
	if ( defined $Pv ) {
		my ($m,$e) = pv_decomp($Pv);
		@sql_where_pv = (
										 'rs.p_value_threshold_mant = '.$m,
										 'rs.p_value_threshold_exp  = '.$e
										);
	}
	else {
		my ($m,$e) = pv_decomp($Sm->getPValue());
		@sql_where_pv = (
										 'rs.p_value_threshold_mant >= '.$m,
										 'rs.p_value_threshold_exp  >= '.$e
										);
	}

  # here's the SQL to select the rule sets
  my $id_rule_sets =
  $M->doSql( $C,
             {
              q_simple_set => 1,
              select => 'rs.aa_motif_go_func_rule_set_id',
              from   => 'AAMotifGoFunctionRuleSet rs, AAMotifGoFunctionRule ru, GOFunction gf',
              where  => [ 'rs.aa_sequence_id_1  = '. $Sm->getSubjectId(),
                          @sql_where_pv,
                          'rs.aa_motif_go_func_rule_set_id = ru.aa_motif_go_func_rule_set_id',
                          'ru.go_function_id = gf.go_function_id',
                          "gf.go_version like '$C->{cla}->{ go_ver }'",
                        ],
             }
           );

  # make sure we have a p-value to report
  $Pv = $Sm->getPValue() unless defined $Pv;

  # and report
  GusApplication::Log( 'pS', $Pv, @{ $id_rule_sets } ) if $C->{cla}->{ t_show };

  # make sure we've got at least one rule set
  return undef unless scalar @{ $id_rule_sets } == 1;

  # create objects of the RuleSets IDs.
  my $gus_rule_sets = $M->makeObjects( $C,
                                       'AAMotifGoFunctionRuleSet',
                                       'aa_motif_go_func_rule_set_id',
                                       $id_rule_sets,
                                      );

  # process each rule set and make a protein GO function.
  my $n_rules = 0;
  foreach my $gus_rule_set ( @{ $gus_rule_sets } ) {
    $n_rules += $M->processRuleSet( $C, $Id, $gus_rule_set, $Sm )
  }

  # return the number of rules
  $n_rules
}

# ......................................................................
### process a rule set
#
# get and process all of its children.
#
sub processRuleSet {
  my $M  = shift;
  my $C  = shift; # context
  my $Id = shift; # query id
  my $St = shift; # rule set
  my $Sm = shift; # similarity

  GusApplication::Log( 'RS', $St->getId() ); #if $C->{cla}->{ t_show };

  my $n_rules = 0;

  # process rules in the set.
  my @gus_rules = $St->getChildren( 'AAMotifGoFunctionRule', 1 );
  foreach my $gus_rule ( @gus_rules ) {
    $n_rules++ if $M->processRule( $C, $Id, $gus_rule, $Sm )
  }

  # return the number of rules processed
  $n_rules

}

# ......................................................................
### process a rule
#
#
#
sub processRule {
  my $M  = shift;
  my $C  = shift; # context
  my $Id = shift; # query id
  my $Rl = shift; # rule
  my $Sm = shift; # similarity
  my $Gf = shift || $Rl->getGoFunctionId(); # GO function ( optional )
	my $Pr = shift; # pv-value ratio

	# function log
	GusApplication::Log( 'hack', $Id, $Gf );

  # tailored as_table info.
  my $ast = $M->{ xlt }->{ as_table }->{ $C->{cla}->{ as_table } };

  # get oid for the thing we're going to associate with the term
  my $oid = $ast->{ s2oid }->( $M, $Id );
  unless ( $oid ) {
    GusApplication::Log( 'xlt', $Id );
    return undef
  }

  # check to see if there already is a prediction exactly like this.
  # .................................................................
  # In this case 'exactly' means same go_function_id (i.e. GUS's id
  # for the function and like go_version.

  my @sql_where = ( sprintf( 'agf.%s = %s', $ast->{ oid }, $oid ),
                    sprintf( 'agf.go_function_id = %s', $Gf ),
                    sprintf( 'agf.go_function_id = gf.go_function_id', ),
                    sprintf( 'gf.go_version like \'%s\'', $C->{cla}->{ go_ver } ),
                  );

  push( @sql_where, 'agf.go_evidence = \'PRED\'' ) if $ast->{ gepc };

  # here 'exactly' also means has been predicted by this run of plugin  
  push( @sql_where, 'agf.row_alg_invocation_id = '. $C->{self_inv}->getId() ) if $C->{cla}->{ignore_expred};

  my $id_obj_go_funcs =
  $M->doSql( $C,
             {
              q_simple_set  => 1,
              select        => sprintf( 'agf.%s', $ast->{ aid } ),
              from          => sprintf( '%s agf, GOFunction gf', $ast->{ table } ),
              where         => \@sql_where,
             } );
  GusApplication::Log( 'GO', scalar @{ $id_obj_go_funcs }, @{ $id_obj_go_funcs } );
	#if $C->{cla}->{ t_show };

  # here's the function call we actually want
  my $protein_go_func__gus;

  # there's already one in the database, get it (well, the first one anyway );
  if ( $id_obj_go_funcs->[0] ) {
    my $perl = sprintf( '%s->new( { %s => $id_obj_go_funcs->[0] } )',
                        $ast->{ table },
                        $ast->{ aid }
                      );
    $protein_go_func__gus = eval $perl;
    $protein_go_func__gus->retrieveFromDB();

    GusApplication::Log( 'oldrule', $Gf, scalar @{ $id_obj_go_funcs } );
  }

  # otherwise we need to make a new one.
  else {
    $protein_go_func__gus = $ast->{ new }->( $oid, $Gf, 'PRED' );
    GusApplication::Log( 'newrule', $Id, $oid, $Gf, $Pr ); #if $C->{cla}->{ t_show };
  }

	# no versioning.
	$protein_go_func__gus->setVersionable(0);

	# set pv-ratio to maximum of existing and new
	my $old_pv_ratio = $protein_go_func__gus->getPValueRatio();
	if ( defined $Pr && $Pr > $old_pv_ratio ) {
		$protein_go_func__gus->setPValueRatio( $Pr );
	}

#
# Need to add check here to avoid evidence duplication.
#
#
#	

  # create some (new) evidence to back up the prediction
  # one for the rule and one for the similarity.
  $protein_go_func__gus->addEvidence( $Sm, 1, undef, 0);
  $protein_go_func__gus->addEvidence( $Rl, 1, undef, 0);

  # submit the updated/new go function prediction.
  $protein_go_func__gus->submit() unless ( isReadOnly() || ! $C->{cla}->{ LE } );

  # return the prediction
  $protein_go_func__gus
}

# ---------------------------------------------------------------------- #
#                       __loadDotsRnaToProtein                           #
# ---------------------------------------------------------------------- #

# loads a mapping table, RNASequence -> Protein, which is used to
# identify which Protein row will have the GO association attached.

sub __loadDotsRnaToProtein {
  my $M = shift;

  $M->doSql( $M->{C},
             {
              q_translation => 1,
              select        => 'rs.rna_sequence_id, p.protein_id',
              from          => 'RNASequence rs, Protein p',
              where         => [ 'rs.rna_id = p.rna_id' ],
             } )
}

# ---------------------------------------------------------------------- #
# ---------------------------------------------------------------------- #

sub log10 { log($_[0]) / log(10) }

require POSIX;
sub pv        { $_[0]*10**$_[1] }
sub pv_exp    { POSIX::floor(log10($_[0])) }
sub pv_mant   { $_[0]/(10**pv_exp($_[0]))  }
sub pv_decomp { (pv_mant($@),pv_exp(@_)) }


# ---------------------------------------------------------------------- #
#                             True value                                 #
# ---------------------------------------------------------------------- #

1;

__END__

For Plasmodium predictions:

ga \
  --qs-project PlasmodiumDB \
  --qs-table   TranslatedAASequence \
  --qs-type    aa \
  --sm-pvalues 1e-50,1e-40,1e-30,1e-20,1e-10 \
  --go-ver     '1' \
  MakeGoPredictions

For DOTS predictions:

ga \
  MakeGoPrediction

=head1 PrivateMethods

=head2 addMode
=head2 listMode

Lists rows in tables that where added by a previous run of the plugin.

User must supply a raid which is used to select the relevant rows.

=head2 deleteMode
