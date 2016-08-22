#!/usr/bin/perl
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

# ----------------------------------------------------------
# Similarity.pm
#
# A package to ease the entering of data into Similarity
# and SimilaritySpan by automatically computing summary
# fields.
#
# Created: Mon Apr 24 09:15:33 EDT 2000
#
# Jonathan Crabtree
# ----------------------------------------------------------

package GUS::Community::Similarity;

use strict;

use GUS30::GUSdev::RNASequence;
use GUS30::GUSdev::NASequence;
use GUS30::GUSdev::Similarity;
use GUS30::GUSdev::SimilaritySpan;

# ----------------------------------------------------------
# Enter a Similarity object and optionally a corresponding set 
# of SimilaritySpans.  Returns the Similarity object that was
# created.
#
# $subject    The subject object.
# $subject    The query object.
# $simData    Reference to an array of objects with the same  
#             fields as SimilaritySpan
# $saveSpans  Whether to write the individual SimilaritySpans.
# $noSubmit   Whether to omit submitting the Similarity & 
#             SimilaritySpans.
#
sub enterSimData {
    my($subject, $query, $simData, $saveSpans, $noSubmit) = @_;
    my $sim = Similarity->new();

    # Set subject and query pointers
    #
    $sim->set('subject_table_id', &tableId($subject));
    $sim->set('subject_id', &rowId($subject));
    $sim->set('query_table_id', &tableId($query));
    $sim->set('query_id', &rowId($query));

    # Similarity summary data
    #
    my $bestScore;
    my $bestPval;
    my $bestIsReversed;
    my $bestReadingFrame;
    my $totalIdentical = 0;
    my $totalPositive = 0;
    my $totalLength = 0;
    my $minQStart;
    my $maxQEnd;
    my $minSStart;
    my $maxSEnd;
    my $numSpans = 0;

    # Loop over spans
    #
    foreach my $span (@$simData) {
	my $matchLen = $span->{'match_length'};
	my $numId = $span->{'number_identical'};
	my $numPos = $span->{'number_positive'};
	my $score = $span->{'score'};
	my $pval_mant = $span->{'pvalue_mant'};
	my $pval_exp = $span->{'pvalue_exp'};
	my $pval = $pval_mant;
	$pval .= (" e" . $pval_exp) if (($pval_exp != 0) && ($pval_exp != 999999));
	my $sstart = $span->{'subject_start'};
	my $send = $span->{'subject_end'};
	my $qstart = $span->{'query_start'};
	my $qend = $span->{'query_end'};
	my $isRev = $span->{'is_reversed'};
	my $frame = $span->{'reading_frame'};

	my $length = $qend - $qstart + 1;
	$totalIdentical += $numId;
	$totalPositive += $numPos;
	$totalLength += $length;

	if (not defined($bestScore)) {
	    $bestScore = $score;
	    $bestPval = $pval;
	    $bestIsReversed = $isRev;
	    $bestReadingFrame = $frame if (defined($frame));
	} elsif ($score > $bestScore) {
	    $bestPval = $pval;
	    $bestIsReversed = $isRev;
	    $bestReadingFrame = $frame if (defined($frame));
	}

	if (not defined($minQStart)) {
	    $minSStart = $sstart; $maxSEnd = $send;
	    $minQStart = $qstart; $maxQEnd = $qend;
	} else {
	    $minQStart = $qstart if ($qstart < $minQStart);
	    $minSStart = $sstart if ($sstart < $minSStart);
	    $maxQEnd = $qend if ($qend > $maxQEnd);
	    $maxSEnd = $send if ($send > $maxSEnd);
	}

	if ($saveSpans) {
	    my $ss = SimilaritySpan->new();
	    $ss->set('pvalue_mant', $pval_mant);
	    $ss->set('pvalue_exp', $pval_exp);
	    $ss->set('score', $score);
	    $ss->set('match_length', $matchLen);
	    $ss->set('number_identical', $numId);
	    $ss->set('number_positive', $numPos);
	    $ss->set('subject_start', $sstart);
	    $ss->set('subject_end', $send);
	    $ss->set('query_start', $qstart);
	    $ss->set('query_end', $qend);
	    $ss->set('is_reversed', $isRev);
	    $ss->set('reading_frame', $frame) if (defined($frame));
	    $ss->setParent($sim);
	}
	++$numSpans;
    }

    # Record summary data
    #
    $sim->setPValue($bestPval);
    $sim->set('score', $bestScore);
    $sim->set('min_subject_start', $minSStart);
    $sim->set('max_subject_end', $maxSEnd);
    $sim->set('min_query_start', $minQStart);
    $sim->set('max_query_end', $maxQEnd);
    $sim->set('number_of_matches', $numSpans);
    $sim->set('total_match_length', $totalLength);
    $sim->set('number_identical', $totalIdentical);
    $sim->set('number_positive', $totalPositive);
    $sim->set('is_reversed', $bestIsReversed);
    $sim->set('reading_frame', $bestReadingFrame) if (defined($bestReadingFrame));

    # Submit to the database
    #
    $sim->submit() if (!$noSubmit);
    return $sim;
}

# Return the table_id for a GUS object.
#
sub tableId {
    my($obj) = @_;
    my $class = $obj->get('subclass_view');
    $class = $obj->getClassName() if (not defined($class));
    return $obj->getTableIdFromTableName($class);
}

# Return the ID for a GUS object of type RNASequence or NASequence.
#
sub rowId {
    my($obj) = @_;

    if ($obj->getClassName() eq 'RNASequence') {
	return $obj->getRnaSequenceId();
    }
    return $obj->getNaSequenceId();
}

1;
