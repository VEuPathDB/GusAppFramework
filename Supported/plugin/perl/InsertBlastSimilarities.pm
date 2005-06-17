package GUS::Supported::Plugin::InsertBlastSimilarities;
@ISA = qw(GUS::PluginMgr::Plugin); 
use strict;

use FileHandle;
use CBIL::Util::Disp;

use GUS::Model::DoTS::Protein;
use GUS::Model::DoTS::ExternalAASequence;
use GUS::Model::DoTS::ExternalNASequence;
use GUS::PluginMgr::Plugin;

  my $purposeBrief = 'Load blast results from a condensed file format into the D
oTS.Similarity table.';

  my $purpose = <<PLUGIN_PURPOSE;
Load a set of BLAST similarities from a file in the form generated by the blastS
imilarity command (distributed with GUS in the CBIL/Bio component)into the DoTS.Similarity table.  
PLUGIN_PURPOSE

  my $tablesAffected = 
    [ ['DoTS::Similarity', 'One row per similarity to a subject'],
      ['DoTS::SimilaritySpan', 'One row per similarity span (HSP)'],
    ];

  my $tablesDependedOn =
    [
    ];

  my $howToRestart = <<PLUGIN_RESTART;
Use the restartAlgInvs to provide a list of algorithm_invocation_ids that repres
ent previous runs of loading these similarities.  The algorithm_invocation_id of
 a run of this plugin is logged to stderr.  If you don't have that information f
or a previous run or runs, you will have to poke around in the Core.AlgorithmInv
ocation table and others to find your runs and their algorithm_invocation_ids.
PLUGIN_RESTART

  my $failureCases = <<PLUGIN_FAILURE_CASES;
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
The definition lines of the sequences involved in the BLAST (both query and subj
ect) must begin with the na_sequence_ids of those sequences.  The standard way t
o acheive that is to first load the sequences into GUS, using the InsertNewExter
nalSequences plugin, and then to extract them into a file with the dumpSequences
FromTable.pl command.  That command places the na_sequence_id of the sequence as
 the first thing in the definition line.

The plugin assumes that all subject sequences are stored in the same table, and 
that all query sequences are stored in the same table (but possibly different fr
om the subject sequences).  The subjectTable and queryTable arguments indicate w
hich tables the sequences are in, respectively.  (This is because the Similarity
 table forms similarities between table/rows in GUS; therefore, the plugin must 
specify which tables the sequences are in.)
PLUGIN_NOTES


  my $documentation = { purpose=>$purpose,
                        purposeBrief=>$purposeBrief,
                        tablesAffected=>$tablesAffected,
                        tablesDependedOn=>$tablesDependedOn,
                        howToRestart=>$howToRestart,
                        failureCases=>$failureCases,
                        notes=>$notes
                      };


  my $argsDeclaration =
  [
   fileArg({name => 'file',
            descr => 'Input file containing BLAST results in condensed form',
            constraintFunc=> undef,
            reqd  => 1,
            isList => 0,
            mustExist => 1,
            format => 'The format produced by the blastSimilarities command (one
 line per Subject hit, followed by one for each HSP)',
           }),

   tableNameArg({name  => 'subjectTable',
                 descr => 'Subjects are taken from this table (schema::table for
mat, eg, DoTS::ExternalNaSequence)',
                 reqd  => 1,
                 constraintFunc=> undef,
                 isList=>0,
           }),
   tableNameArg({name  => 'queryTable',
                 descr => 'Queries are taken from this table (schema::table form
at, eg, DoTS::ExternalNaSequence)',
                 reqd  => 1,
                 constraintFunc=> undef,
                 isList=>0,
           }),
   integerArg({name  => 'batchSize',
               descr => 'Number of spans to write in one transaction',
               reqd  => 0,
               constraintFunc=> undef,
               isList=> 0,
               default=> 1000,
              }),
   booleanArg({ name   => 'noHSPs',
                descr  => 'If true, load only subject summaries, not HSPs',
                reqd   => 0,
                isList => 0,
                default=> 0,
                constraintFunc => undef,
              }),
   integerArg({name  => 'testnumber',
               descr => 'Number of query sequences to process for testing',
               reqd  => 0,
               constraintFunc=> undef,
               isList=> 0,
              }),
   stringArg({name  => 'restartAlgInvs',
              descr => 'A comma delimited list of row_alg_invocation_ids.  Queri
es in the input file which have rows in the Similarity table marked with one or 
more of these row_alg_invocation_ids will be ignored',
              reqd  => 0,
              constraintFunc=> undef,
              isList=>1,
             }),
   integerArg({name  => 'subjectsLimit',
               descr => 'Maximum number of subjects to load per query',
               reqd  => 0,
               constraintFunc=> undef,
               isList=> 0,
              }),
   integerArg({name  => 'hspsLimit',
               descr => 'Maximum number of hsps to load per subject',
               reqd  => 0,
               constraintFunc=> undef,
               isList=> 0,
              }),
   integerArg({name  => 'minSubjects',
               descr => 'Reject queries with less than this number of subjects',
               reqd  => 0,
               constraintFunc=> undef,
               isList=> 0,
              }),
   integerArg({name  => 'maxSubjects',
               descr => 'Reject queries with more than this number of subjects',
               reqd  => 0,
               constraintFunc=> undef,
               isList=> 0,
              }),
   floatArg({name  => 'subjectPvalue',
             descr => 'Reject subjects with pvalues greater than this',
             reqd  => 0,
             constraintFunc=> undef,
             isList=> 0,
              }),
   floatArg({name  => 'subjectPctIdent',
             descr => 'Reject subjects with percent identity less than this',
             reqd  => 0,
             constraintFunc=> undef,
             isList=> 0,
              }),
   integerArg({name  => 'subjectMatchLength',
               descr => 'Reject subjects with match length less than this',
               reqd  => 0,
               constraintFunc=> undef,
               isList=> 0,
              }),
   floatArg({name  => 'hspPvalue',
             descr => 'Reject HSPs with pvalues greater than this',
             reqd  => 0,
             constraintFunc=> undef,
             isList=> 0,
              }),
   floatArg({name  => 'hspPctIdent',
             descr => 'Reject HSPs with percent identity greater than this',
             reqd  => 0,
             constraintFunc=> undef,
             isList=> 0,
              }),
   integerArg({name  => 'hspMatchLength',
               descr => 'Reject HSPs wth match length less than this',
               reqd  => 0,
               constraintFunc=> undef,
               isList=> 0,
              }),
  ];

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  $self->initialize({requiredDbVersion => {},
		     cvsRevision => '$Revision$', # cvs fills this in!
		     name => ref($self),
		     argsDeclaration   => $argsDeclaration,
		     documentation     => $documentation,
		    });
  return $self;
}

$| = 1;

sub run {
  my ($self) = @_;

  my $dbh = $self->getDb()->getDbHandle();

  $self->{queryTable}   = $self->getArg('queryTable');
  $self->{subjectTable} = $self->getArg('subjectTable');
  
  my $query_tbl_id = $self->className2TableId($self->{queryTable});
  my $subj_tbl_id = $self->className2TableId($self->{subjectTable});

  $self->log("Testing on " . $self->getArg('testnumber') . " queries") if $self->getArg('testnumber');

  my %ignore = $self->handleRestart($self->getArg('restartAlgInvs'), $dbh);

  my $file = $self->getArg('file');
  my $fh  = $file =~ /\.gz$|\.Z$/ ?
    FileHandle->new("zcat $file|") : FileHandle->new($file);

  die "Can't open file '$file'" unless $fh;

  $self->{queryCount} = 0;
  $self->{subjectCount} = 0;
  $self->{spanCount} = 0;
  $self->{ignoredQueries} = 0;
  $self->{filteredQueries} = 0;
  $self->{filteredSubjects} = 0;
  $self->{filteredHSPs} = 0;

  my $eof;
  while(!$eof) {
    my $subjects;
    ($subjects, $eof) = 
      $self->parseQueries($fh, 
			  $self->getArg('batchSize'), 
			  \%ignore, 
			  $self->getArg('testnumber'));
    $self->insertSubjects($self->getDb(), $subjects, $query_tbl_id, $subj_tbl_id);
  }
}

sub handleRestart {
  my ($self, $restartAlgInvs, $dbh) = @_;

  my %ignore;
  if ($restartAlgInvs) {
    my $query = "select distinct query_id from dots.Similarity where row_alg_invocation_id in ($restartAlgInvs)";
    $self->log("Restarting: Querying for the ids to ignore\n$query");
    my $stmt = $dbh->prepare($query);
    $stmt->execute()|| die $stmt->errstr;
    while ( my($id) = $stmt->fetchrow_array()) {
      $ignore{$id} = 1;
    }
    $self->log("Ignoring ".scalar(keys%ignore)." entries");
  }
  return %ignore;
}

sub parseQueries {
  my ($self, $fh, $batchSize, $ignore, $testnumber) = @_;

  my $batchSpanCount = 0;

  my @subjects;
  my $eof;
  while ($batchSpanCount < $batchSize) {
    if ($testnumber && $self->{queryCount} >= $testnumber) {
      $eof = 1;
      last;
    }
    my ($queryId, $spanCount, $querySubjects);
    ($queryId, $spanCount, $querySubjects, $eof) = 
      $self->parseQuery($fh);
    last if $eof;
    if ($ignore->{$queryId}) {
      $self->{ignoredQueries} += 1;
      next;
    }
    $batchSpanCount += $spanCount;
    push(@subjects, @$querySubjects);
  }
  return (\@subjects, $eof);
}

sub parseQuery {
  my ($self, $fh) = @_;

  my @subjects;
  my $spanCount;
  my $subjectsLimit = $self->getArg('subjectsLimit');
  my $maxSubjects = $self->getArg('maxSubjects');
  my $maxSubjects = $self->getArg('maxSubjects');
  my $pvalueF = $self->getArg('subjectPvalue');
  my $pctIdentF = $self->getArg('subjectPctIdent');
  my $matchLengthF = $self->getArg('subjectMatchLength');

  my $queryLine = <$fh>;
  while ($queryLine && (not $queryLine =~ /^\>/)) {
    $queryLine = <$fh>;
  }

  my $queryPK;
  if ($queryLine) {
    #>99929462 (2 subjects)
    $queryLine =~ /^\>*(\S+)\s\((\d+)/ || die "Invalid query line: '$_'\n";

    $queryPK = $1;
    my $subjCount = $2;

    # filter query
    my $filterQuery = ($self->getArg('maxSubjects') && $subjCount > $self->getArg('maxSubjects'))
      || ($self->getArg('minSubjects') && $subjCount < $self->getArg('minSubjects'));

    if ($filterQuery) {
      $self->{filteredQueries} += 1;
    } else {
      $self->{queryCount} += 1 unless $subjCount == 0;
    }

    my $c = 0;
    while ($c++ < $subjCount) {
      my ($subjSpanCount, $subject) = $self->parseSubject($fh, $queryPK);

      next if ($filterQuery);

      # filter subject
      if (($subjectsLimit && $c > $subjectsLimit)
	  || ($pvalueF && $subject->{pvalue} > $pvalueF)
	  || ($pctIdentF
	      && $subject->{number_identical}/$subject->{total_match_length}*100 <$pctIdentF)
	  || ($matchLengthF && $subject->{total_match_length} < $matchLengthF)) {
	$self->{filteredSubjects} += 1;
	next;
      }

      $spanCount += $subjSpanCount;
      push(@subjects, $subject);
    }
  }
  return ($queryPK, $spanCount, \@subjects, !$queryLine);
}

sub parseSubject {
  my ($self, $fh, $queryPK) = @_;

#  Sum: 13058520:483:4e-49:1:193:175:642:2:290:126:172:0:+1

  my $sumLine = <$fh>;

  my @vals = split(/:/, $sumLine);
  die "invalid Sum line: '$sumLine'\n" unless $vals[0] =~ /Sum/;
  die "invalid Sum line (wrong number of columns):  '$sumLine'\n" unless scalar @vals == 14;

  my %subj;
  $subj{query_id} = $queryPK;
  $subj{subject_id} = $vals[1];
  
  $subj{score} = $vals[2];
  $subj{pvalue} = $vals[3];
  ($subj{pvalue_mant}, $subj{pvalue_exp}) = split(/e/, $subj{pvalue});
  $subj{pvalue_mant} = 1 unless $subj{pvalue_mant} ;
  $subj{pvalue_exp} = 1 unless $subj{pvalue_exp} ;
  $subj{min_subject_start} = $vals[4];
  $subj{max_subject_end} = $vals[5];
  $subj{min_query_start} = $vals[6];
  $subj{max_query_end} = $vals[7];
  $subj{number_of_matches} = $vals[8];
  $subj{total_match_length} = $vals[9];
  $subj{number_identical} = $vals[10];
  $subj{number_positive} = $vals[11];
  $subj{is_reversed} = $vals[12];
  $subj{reading_frame} = $vals[13];
  $subj{reading_frame} =~ s/\D//g;   # get rid of (+-)

  my $hspsLimit = $self->getArg('hspsLimit');
  my $pvalueF = $self->getArg('hspPvalue');
  my $pctIdentF = $self->getArg('hspPctIdent');
  my $matchLengthF = $self->getArg('hspMatchLength');

  my $c = 0;
  my @subjSpans;
  while ($c++ < $subj{number_of_matches}) {
    my $span = $self->parseSpan($fh);

    # filter
    if (($hspsLimit && $c > $hspsLimit) 
	|| ($pvalueF && $span->{pvalue} > $pvalueF)
	|| ($pctIdentF
	    && $span->{number_identical}/$span->{match_length}*100 < $pctIdentF)
	|| ($matchLengthF && $span->{match_length} < $matchLengthF)) {
      $self->{filteredHSPs} += 1;
      next;
    }


    push(@subjSpans, $span);
  }
  $subj{spans} = \@subjSpans;



  return ($subj{number_of_matches}, \%subj);
}

sub parseSpan {
  my ($self, $fh) = @_;

#   HSP1: 13058520:84:108:156:483:4e-49:1:155:175:642:0:+1

  my $pvalueF = $self->getArg('hspPvalue');
  my $pctIdentF = $self->getArg('hspPctIdent');
  my $matchLengthF = $self->getArg('hspMatchLength');
  my $spanLine = <$fh>;

  my @vals = split(/:/, $spanLine);
  die "invalid HSP line: '$spanLine'\n" unless $vals[0] =~ /HSP/;
  my $columnCount = scalar @vals;
  die "invalid HSP line (wrong number of columns, have $columnCount , should be 13):  '$spanLine'\n" unless $columnCount == 13;

  my %span;
  $span{number_identical} = $vals[2];
  $span{number_positive} = $vals[3];
  $span{match_length} = $vals[4];
  $span{score} = $vals[5];
  ($span{pvalue_mant}, $span{pvalue_exp}) = split(/e/, $vals[6]);
  $span{pvalue_mant} = 1 unless $span{pvalue_mant} ;
  $span{pvalue_exp} = 1 unless $span{pvalue_exp} ;
  $span{subject_start} = $vals[7];
  $span{subject_end} = $vals[8];
  $span{query_start} = $vals[9];
  $span{query_end} = $vals[10];
  $span{is_reversed} = $vals[11];
  $span{reading_frame} = $vals[12];
  $span{reading_frame} =~ s/\D//g;   # get rid of (+-)

  return \%span
}

# insert a batch of subjects (with their spans)
sub insertSubjects {
  my ($self, $db, $subjects, $query_table_id, $subj_table_id) = @_;

  my $simStmt = $self->getInsertSubjStmt($db->getDbHandle(), $query_table_id,$subj_table_id);

  my $spanStmt = $self->getInsertSpanStmt($db);

  my $nextvalSql = $db->getDbPlatform()->nextValSelect("dots.similarity");

  my $nextIdStmt = $db->getDbHandle()->prepare($nextvalSql);

  my $verbose = $self->getArg('verbose');
  my $noHSPs = $self->getArg('noHSPs');

  foreach my $s (@$subjects) {

    my $simPK = &getNextId($nextIdStmt);

    next if (scalar @{$s->{spans}} == 0);

    # Get query & subject objects GUS PK if necessary

    my $queryTable   = $self->{queryTable};
    my $subjectTable = $self->{subjectTable};
    
    my $query_id = $s->{query_id};
    
    # Get rid of the spaces
    $query_id =~ s/\s//g;
    
    if (not $query_id =~ /^\d+$/) {
      # must be the sequence entry identifier, get the GUS PK then
      my $queryobj = $queryTable->new ({'name' => $query_id});
      my $is_in = $queryobj->retrieveFromDB;
      
      if (! $is_in) {
	die "can't get the GUS entry for query, $query_id!\n";
      }
      else {
	$s->{query_id} = $queryobj->getId;
      }
	
    }
    
    my $subject_id = $s->{subject_id};
    
    # Get rid of the spaces
    $subject_id =~ s/\s//g;
    
    if (not $subject_id =~ /^\d+$/) {
      # must be the sequence entry identifier, get the GUS PK then
      my $subjectobj = $subjectTable->new ({'name' => $subject_id});
      my $is_in = $subjectobj->retrieveFromDB;
      
      if (! $is_in) {
	die "can't get the GUS entry for subject, $subject_id!\n";
      }
      else {
	$s->{subject_id} = $subjectobj->getId;
      }
    }
    
    my @simVals = ($simPK, $s->{subject_id}, $s->{query_id},
		   $s->{score}, undef,
		   $s->{pvalue_mant}, $s->{pvalue_exp},
		   $s->{min_subject_start}, $s->{max_subject_end},
		   $s->{min_query_start}, $s->{max_query_end},
		   $s->{number_of_matches}, $s->{total_match_length},
		   $s->{number_identical}, $s->{number_positive},
		   $s->{is_reversed}, $s->{reading_frame});

    $simStmt->execute(@simVals) || die $simStmt->errstr;
    $self->log("Inserting Similarity: ", @simVals) if $verbose;

    $self->{subjectCount} += 1;
    if (!$noHSPs) {
      foreach my $span (@{$s->{spans}}) {
	my @spanVals = ($simPK, $span->{match_length},
			$span->{number_identical}, $span->{number_positive},
			$span->{score},  undef,
			$span->{pvalue_mant}, $span->{pvalue_exp},
			$span->{subject_start}, $span->{subject_end},
			$span->{query_start}, $span->{query_end},
			$span->{is_reversed}, $span->{reading_frame});
	$spanStmt->execute(@spanVals) || die $spanStmt->errstr;
	$self->log("Inserting SimilaritySpan: ", @spanVals) if $verbose;
	$self->{spanCount} += 1;
      }
    }

  }

  # Sum it all up in a message for the log and AlgInv.result
  my $summaryMessage = "$self->{queryCount} Queries parsed.  Inserted $self->{subjectCount} subj, $self->{spanCount} hsp.  Filtered $self->{filteredQueries} q, $self->{filteredSubjects} subj, $self->{filteredHSPs} hsp.  Restart past $self->{ignoredQueries} q";

  $self->log($summaryMessage);
  $self->setResultDescr($summaryMessage);

  if ($self->getArg('commit')) {
    $self->log("Committing");
    $db->getDbHandle()->commit();
  } else {
    $db->getDbHandle()->rollback();
    $self->log("Rolling back");
  }
}

sub getInsertSubjStmt {
  my ($self, $dbh, $query_tbl_id, $subj_tbl_id) = @_;

  my $algInvId = $self->getAlgInvocation()->getId();
  my $rowUserId = $self->getAlgInvocation()->getRowUserId();
  my $rowGroupId = $self->getAlgInvocation()->getRowGroupId();
  my $rowProjectId = $self->getAlgInvocation()->getRowProjectId();

  my $sql =
"insert into dots.Similarity Values " .
"(?, $subj_tbl_id, ?, $query_tbl_id, ?, " .
#score, bit_score_summary, pvalue_mant, pvalue_exp, min_subject_start,
"?,     ?,                 ?,           ?,          ?, " .
#min_subject_end, min_query_start, min_query_end, number_of_matches
"?,               ?,               ?,             ?, " .
#total_match_length, number_identical, number_positive, is_reversed, reading_fr
"?,                  ?,                ?,               ?,           ?, ".
" null, SYSDATE, 1, 1, 1, 1, 1, 0, $rowUserId, $rowGroupId, $rowProjectId, $algInvId)";

  return $dbh->prepare($sql);
}

sub getInsertSpanStmt {
  my ($self, $db) = @_;

  my $algInvId = $self->getAlgInvocation()->getId();
  my $rowUserId = $self->getAlgInvocation()->getRowUserId();
  my $rowGroupId = $self->getAlgInvocation()->getRowGroupId();
  my $rowProjectId = $self->getAlgInvocation()->getRowProjectId();


  my $nextVal = $db->getDbPlatform()->nextVal("dots.SimilaritySpan");


  my $sql = 
"insert into dots.SimilaritySpan Values " .
#similarity_span_id, similarity_id, match_length, number_identical,
"($nextVal,                  ?,             ?,            ?, ".
#number_positive, score, bit_score, pvalue_mant, pvalue_exp,
"?,               ?,     ?,         ?,           ?,".
#subject_start, subject_end, query_start, query_end,
"?,             ?,           ?,           ?, " .
#is_reversed, reading_frame
"?,           ?, ".
"SYSDATE, 1, 1, 1, 1, 1, 0, $rowUserId, $rowGroupId, $rowProjectId, $algInvId)";
  return $db->getDbHandle()->prepare($sql);
}

sub getNextId {
  my ($nextIdStmt) = @_;
  $nextIdStmt->execute();
  while ((my $result) = $nextIdStmt->fetchrow_array()) {
    $nextIdStmt->finish();
    return $result;
  }
}

1;

