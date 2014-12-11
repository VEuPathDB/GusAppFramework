#! /usr/bin/perl
#vvvvvvvvvvvvvvvvvvvvvvvvv GUS4_STATUS vvvvvvvvvvvvvvvvvvvvvvvvv
  # GUS4_STATUS | SRes.OntologyTerm              | auto   | absent
  # GUS4_STATUS | SRes.SequenceOntology          | auto   | absent
  # GUS4_STATUS | Study.OntologyEntry            | auto   | absent
  # GUS4_STATUS | SRes.GOTerm                    | auto   | absent
  # GUS4_STATUS | Dots.RNAFeatureExon            | auto   | absent
  # GUS4_STATUS | RAD.SageTag                    | auto   | absent
  # GUS4_STATUS | RAD.Analysis                   | auto   | absent
  # GUS4_STATUS | ApiDB.Profile                  | auto   | absent
  # GUS4_STATUS | Study.Study                    | auto   | absent
  # GUS4_STATUS | Dots.Isolate                   | auto   | absent
  # GUS4_STATUS | DeprecatedTables               | auto   | absent
  # GUS4_STATUS | Pathway                        | auto   | absent
  # GUS4_STATUS | DoTS.SequenceVariation         | auto   | absent
  # GUS4_STATUS | RNASeq Junctions               | auto   | absent
  # GUS4_STATUS | Simple Rename                  | auto   | absent
  # GUS4_STATUS | ApiDB Tuning Gene              | auto   | absent
  # GUS4_STATUS | Rethink                        | auto   | absent
  # GUS4_STATUS | dots.gene                      | manual | unreviewed
die 'This file has broken or unreviewed GUS4_STATUS rules.  Please remove this line when all are fixed or absent';
#^^^^^^^^^^^^^^^^^^^^^^^^^ End GUS4_STATUS ^^^^^^^^^^^^^^^^^^^^

package GUS::Community::BulkSimilarity;

use strict;
use vars qw( @ISA );
@ISA = qw( CBIL::Util::A );

use FileHandle;

use CBIL::Util::A;
use CBIL::Util::Disp;

use GUS::Model::DoTS::Similarity;
use GUS::Model::DoTS::SimilaritySpan;

sub new {
	my $C = shift;
	my $A = shift;

	return undef unless $A->ensure( qw( file query subject types ) );

	my $m = bless CBIL::Util::A::e, $C;

	$m->safeCopy( $A, qw( file query subject span summary types ) );

	$m->{ span }    = '(HSP)(\d+)' unless defined $m->{ span };
	$m->{ summary } = 'Sum'        unless defined $m->{ summary };
	$m->openFile();

	return $m;
}

sub newFile {
	my $M = shift;
	my $F = shift;

	$M->{ file } = $F;

	$M->openFile();
}

sub openFile {
	my $M = shift;

	undef $M->{ line };

	$M->{ fh } = new FileHandle $M->{ file };

	my $fh = $M->{ fh };

	while ( $M->{ line } = <$fh> ) {
		chomp $M->{ line };
		last if $M->{ line } =~ /^>/;
		next if $M->{ line } =~ /^\s*$/;
		$M->{ line } =~ s/^\s+//;
		$M->{ line } =~ s/\s+$//;
		my ( $name, $value ) = split( /:\s*/, $M->{ line }, 2 );
		$M->{ parameters }->{ $name } = $value;
	}

	return $fh;
}

sub getSectionLines {
	my $M = shift;

	#print join( "\t", 'getSectionLines-in', localtime ), "\n";

	# we'll return data in here
	my $rv;

	# access to file handle that doesn't confuse Perl
	my $fh = $M->{ fh };

	# check for end of file.
	return undef if $fh->eof;

	# lines for this section.
	my @lines;

	if ( defined $M->{ line } ) {
		$rv->{ header } = $M->{ line };
	}
	else {
		$rv->{ header } = <$fh>;
	}

	while ( $M->{ line } = <$fh> ) {
		chomp $M->{ line };
		last if $M->{ line } =~ /^>/;
		push( @lines, $M->{ line } );
	}

	my $subject;
	my $b_seenSummary;
	my $b_seenSpan;
	foreach ( @lines ) {

		# is a summary for a subject
		if ( $_ =~ $M->{ summary } ) {
			push( @{ $rv->{ subjects }  }, $subject ) if defined $subject;
			$subject = new CBIL::Util::A { summary => $_ };
			$b_seenSummary = 1;
		}

		# a span line
		elsif ( $_ =~ $M->{ span } ) {
			my $type = $1;
			my $i    = $2;

			# this is a new subject and we don't have summaries
			if ( ! $b_seenSummary && defined $subject && $i == 1 ) {
				push( @{ $rv->{ subjects } }, $subject );
				$subject = new CBIL::Util::A {  };
			}

			# save the span
			push( @{ $subject->{ spans } }, $_ );

			$b_seenSpan = 1;
		}

		# unknown line type
		else {
			print join( "\t", 'ERR', 'line-type?', "$_\n" );
		}
	} # eo line scan.

	# save the last one.
	push( @{ $rv->{ subjects }  }, $subject ) if defined $subject;

	#print join( "\t", 'getSectionLines-out', localtime ), "\n";

	return $rv;
}

sub getSectionObjects {
	my $M   = shift;
	my $NsF = shift; # number of subjects filter
	my $SuF = shift; # summary filters; pValue, percentIdentitiy, length
	my $SpF = shift; # span filters;    pValue, percentIdentitiy, length
	my $limitF = shift; # filter that limits the number of subjects and/or hsps
	
	#print join( "\t", 'getSectionObjects-in', localtime ), "\n";

	# the structure we'll return.
	my $rv;

	# delimiter in lines
	my $delim = '\s*:\s*';

	# holds pointers to existing similarity objects
	my %updateSim;  ##hash of existing similarities

 SECTION_SCAN_LOOP:
	while ( my $section = $M->getSectionLines() ) {

		# check for the number of subjects
		if ( defined $NsF ) {
			$section->{ header } =~ /\((\d+) subjects\)/;
			my $n_sub = $1;
			if ( defined $NsF &&
					 (
						$n_sub < $NsF->{ min } ||
						$n_sub >= $NsF->{ max }
					 )
				 ) {
				print join( "\t", 'NSUB', $n_sub, $section->{ header } ), "\n";
				next SECTION_SCAN_LOOP;
			}
		}

		# here's the object we'll return

		$rv = &{ $M->{ query } }( $section->{ header } );
		next SECTION_SCAN_LOOP unless $rv;

		##implement updating...$rv will have similarity facts if updating...
		foreach my $s ($rv->getSimilarityFacts()){
			$updateSim{$s->getSubjectId()} = $s;
		}

		# iterate over the subjects in the section.
		##need to implement the number of subjects....
		my $numSubjects = 0;
	SUBJECT_SCAN_LOOP:
		foreach my $subject ( @{ $section->{ subjects } }  ) {
			
			##BB: limit on number of subjects...
			$numSubjects++;
			last SUBJECT_SCAN_LOOP if (defined $limitF->{subjects} && $numSubjects > $limitF->{subjects});

			# get a line to represent the subject, and get a table and id.
			# bailout if we can't get this one.
			my $s_rep = $subject->{ summary } || $subject->{ spans }->[ 0 ];
			my @s_rep = split( /$delim/, $s_rep );
			my ( $table_id, $id ) = &{ $M->{ subject } }( $s_rep[ 1 ] );
			#print "+";

			next SUBJECT_SCAN_LOOP unless defined $table_id && defined $id;

			

			# parse the summary line
			my @parts = split( /$delim/, $subject->{ summary } );
			
			# see if it passes the filter.
			if ( defined $SuF ) {
				next SUBJECT_SCAN_LOOP
					if ( defined $SuF->{ pValue } && $parts[ 3 ] > $SuF->{ pValue } );
				next SUBJECT_SCAN_LOOP
					if ( defined $SuF->{ length } && $parts[ 9 ] < $SuF->{ length } );
				next SUBJECT_SCAN_LOOP
					if ( defined $SuF->{ percentIdentity } &&
							 ($parts[ 10 ] / $parts[ 9 ]) * 100 < $SuF->{ percentIdentity }
						 );
			}
			
			##get rid of (+-) in reading frame
			$parts[ 13 ] =~ s/\D//g;

			my $gus_sim;
			if(exists $updateSim{$id}){
				$gus_sim = $updateSim{$id};
				delete $updateSim{$id}; ##so know have dealt with this one..
				##delete existing SimilaritySpan children 
				foreach my $c ($gus_sim->getChildren('DoTS::SimilaritySpan',1)){
					$c->markDeleted();
				}
			      }else{
				$gus_sim =
				  new GUS::Model::DoTS::Similarity( {
								     subject_table_id => $table_id,
								     subject_id       => $id,
								     query_table_id   => $rv->getTableIdFromTableName( $rv->getClassName() ),
								     query_id         => $rv->getId(),
								    } );
				
				# add similarity to parent object
				$rv->addSimilarityFact( $gus_sim );
				
			      }	
			##now set values
			$gus_sim->set('score',$parts[  2 ]);
			$gus_sim->setPValue($parts[  3 ]);
			$gus_sim->set('min_subject_start',$parts[  4 ]);
			$gus_sim->set('max_subject_end',$parts[  5 ]);
			$gus_sim->set('min_query_start',$parts[  6 ]);
			$gus_sim->set('max_query_end',$parts[  7 ]);
			$gus_sim->set('number_of_matches',$parts[  8 ]);
			$gus_sim->set('total_match_length',$parts[  9 ]);
			$gus_sim->set('number_identical',$parts[ 10 ]);
			$gus_sim->set('number_positive',$parts[ 11 ]);
			$gus_sim->set('is_reversed',$parts[ 12 ]);
			$gus_sim->set('reading_frame',$parts[ 13 ] eq '' ? 'NULL' : $parts[ 13 ]);

			# add spans if requested
			if ( $M->{ types } eq 'spans' || $M->{ types } eq 'both' ) {

				# scan the span lines
			SPAN_SCAN_LOOP:
				for ( my $i = 0; $i < scalar @{ $subject->{ spans } }; $i++ ) {

					##BB-limit the number of spans....
					last SPAN_SCAN_LOOP if ( defined $limitF->{hsps} && $i >= $limitF->{hsps});

					#print ".";

					# parse the line
					my @parts = split( /$delim/, $subject->{ spans }->[ $i ] );

					# see if it passes the filter.
					if ( defined $SpF ) {
						next SPAN_SCAN_LOOP
						if ( defined $SpF->{ pValue } && $parts[ 6 ] > $SpF->{ pValue } );
						next SPAN_SCAN_LOOP
						if ( defined $SpF->{ length } && $parts[ 4 ] < $SpF->{ length } );
						next SPAN_SCAN_LOOP
						if ( defined $SpF->{ percentIdentity } &&
								 ($parts[ 2 ] / $parts[ 4 ]) * 100 < $SpF->{ percentIdentity }
							 );
					}

					$parts[ 12 ] =~ s/\D//g;

					# create the span object
					my $gus_span =
					new GUS::Model::DoTS::SimilaritySpan( {
															 number_identical => $parts[  2 ],
															 number_positive  => $parts[  3 ],
															 match_length     => $parts[  4 ],
															 score            => $parts[  5 ],
															 subject_start    => $parts[  7 ],
															 subject_end      => $parts[  8 ],
															 query_start      => $parts[  9 ],
															 query_end        => $parts[ 10 ],
															 is_reversed      => $parts[ 11 ],
															 reading_frame    => $parts[ 12 ] eq '' ? 'NULL' : $parts[ 12 ],
															} );
          $gus_span->setPValue($parts[ 6 ]);

					$gus_span->setParent( $gus_sim );

				} # eo span iter
			} # eo adding spans

			#print "\n";

		} # eo subject scan

		last SECTION_SCAN_LOOP if defined $rv;
	} # eo section scan

	##need to mark deleted any old Similarity objects that didn't get updated...do this better
	#3in the future??
	foreach my $s (keys%updateSim){
		$updateSim{$s}->retrieveAllChildrenFromDB(1);
		$updateSim{$s}->markDeleted(1);
	}

	return $rv;
}

# ----------------------------------------------------------------------

sub GetDotsRnaId {
	my $Line = shift;

	$Line =~ /(DT.\d+)/;
	my $id_dots = $1;

}

=pod

my $bs = new BulkSimilarities( new CBIL::Util::A { 
	file    => 'gunzip -c /usr/local/db/cbil/SimilarityBulkLoading/humDOTS-blast/all/fb6.310000.gz|',
	query   => sub { },
	subject => sub { },
	types   => 'both',
} );

CBIL::Util::Disp::Display( $bs->{ parameters } );
while ( my $o = $bs->getSectionObjects() ) {
	CBIL::Util::Disp::Display( $o );
}

=cut


# ----------------------------------------------------------------------
1;


__END__

=pod

=head1 Methods
=head2 new

Arguments:

=over 1
=item file

the file to read

=item query

call back function which converts a query line to an object from which
we will hang the similarities.

=item subject

call-back function which converts a subject ID to a GUS ID and
tablename for the subject

=item span

pattern extractor for span lines.  Defaults to '(HSP)(\d+)'.

=item summary

pattern extractor for summary lines.  Defaults to 'Sum'.

=item types

which types of elements to add; summaries, spans, or both

=back
=cut
