package GUS::Community::Plugin::LoadHspsOnly;
@ISA = qw(GUS::PluginMgr::Plugin); 
use strict;

use FileHandle;
use CBIL::Util::Disp;

use GUS::Model::DoTS::Protein;
use GUS::Model::DoTS::ExternalAASequence;
use GUS::Model::DoTS::ExternalNASequence;

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  my $usage = 'Possible one-time use plugin; given a BLAST file where subject and query info has been loaded (but no HSPS), load HSPS for sequences in a particular ortholog group';

  my $easycsp =
      [{o => 'file',
	t => 'string',
	h => 'read condensed results from this file',
	r => 1,
    },
       {o => 'subjectTable',
	t => 'string',
	h => 'subjects are taken from this table (schema::table format).',
	r => 1,
    },
       {o => 'queryTable',
	t => 'string',
	h => 'queries are taken from this table (schema::table format). ',
	r => 1,
    },
       {o => 'batchSize',
	t => 'int',
	h => 'Number of spans to write in one transaction',
	d => 1000,
    },
       {o => 'noHSPs',
	t => 'boolean',
	h => 'if true, load only subject summaries, not HSPs',
	d => 0,
    },
       {o => 'testnumber',
	t => 'int',
	h => 'number of queries to process for testing',
    },
       {o => 'altSchemaName',
	t => 'string',
      h => 'if set, plugin will insert into Similarity and SimilaritySpan tables in the specified schema.  If not set, will insert into dots',
    },
       
       {o => 'restartAlgInvs',
	t => 'string',
      h => 'a comma delimited list of row_alg_invocation_ids.  Queries in the input file which have rows in the Similarity table marked with one or more of these row_alg_invocation_ids will be ignored',
  },
     {o => 'subjectsLimit',
      t => 'int',
      h => 'maximum number of subjects to load per query'
      },
     {o => 'hspsLimit',
      t => 'int',
      h => 'maximum number of hsps to load per subject'
      },
     {o => 'minSubjects',
      t => 'int',
      h => 'reject queries with less than this number of subjects'
      },
     {o => 'maxSubjects',
      t => 'int',
      h => 'reject queries with more than this number of subjects'
      },
     {o => 'subjectPvalue',
      t => 'float',
      h => 'reject subjects with pvalues greater than this'
      },
     {o => 'subjectPctIdent',
      t => 'float',
      h => 'reject subjects with percent identity less than this'
      },
     {o => 'subjectMatchLength',
      t => 'int',
      h => 'reject subjects with match length less than this'
      },
     {o => 'hspPvalue',
      t => 'float',
      h => 'reject HSPs with pvalues greater than this'
      },
     {o => 'hspPctIdent',
      t => 'float',
      h => 'reject HSPs with percent identity greater than this'
      },
     {o => 'hspMatchLength',
      t => 'int',
      h => 'reject HSPs wth match length less than this'
      },
     ];

  $self->initialize({requiredDbVersion => {},
		     cvsRevision => '$Revision$', # cvs fills this in!
		     cvsTag => '$Name$', # cvs fills this in!
		     name => ref($self),
		     revisionNotes => 'initial writing',
		     easyCspOptions => $easycsp,
		     usage => $usage,
		     queryTable   => undef,
		     subjectTable => undef,
		    });
  return $self;
}

$| = 1;

sub run {
  my ($self) = @_;


  #open ortho file
  #open mapping file, map orthoSeqs->gus seqs
  #for each group,
  #  if group contains a plasmo seq, 
  #     put all of its sequences on the list
  #Go through similarity file
  #For each query
  #  if query is on the list
  #     for each subject
  #       if subject is on the list
  #         get similarity from table representing query and subject
  #         load HSPs
  

  my $args = $self->getArgs();

  my $algInv = $self->getAlgInvocation();
  my $dbh = $self->getDb()->getDbHandle();

  $self->{queryTable}   = $args->{queryTable};
  $self->{subjectTable} = $args->{subjectTable};
  
  my $query_tbl_id = $algInv->getTableIdFromTableName($args->{queryTable});
  my $subj_tbl_id = $algInv->getTableIdFromTableName($args->{subjectTable});
  
  my $simSchemaName = $args->{altSchemaName};
  if (!$simSchemaName){
      $simSchemaName = 'dots';
  }
  $self->{simSchemaName} = $simSchemaName;

  $self->logArgs();
  $self->logCommit();
  my $testNumber = $args->{testnumber};
  print "Testing on $args->{testnumber} queries\n" if $args->{testnumber};

  my %ignore = $self->handleRestart($args->{restartAlgInvs}, $dbh);


  $self->{queryCount} = 0;
  $self->{subjectCount} = 0;
  $self->{spanCount} = 0;
  $self->{ignoredQueries} = 0;
  $self->{filteredQueries} = 0;
  $self->{filteredSubjects} = 0;
  $self->{filteredHSPs} = 0;

  $self->loadHspsInPlasmoGroups($args->{batchSize}, $testNumber);
  my $spanCount = $self->{spanCount};
  return "Loaded $spanCount HSPS for existing similarities";
}


sub handleRestart {
  my ($self, $restartAlgInvs, $dbh) = @_;

  my %ignore;
  if ($restartAlgInvs) {
      
    my $query = "select distinct query_id from " . $self->{simSchemaName} . ".Similarity where row_alg_invocation_id in ($restartAlgInvs)";
    print "Restarting: Querying for the ids to ignore\n$query\n";
    my $stmt = $dbh->prepare($query);
    $stmt->execute()|| die $stmt->errstr;
    while ( my($id) = $stmt->fetchrow_array()) {
      $ignore{$id} = 1;
    }
    print "Ignoring ".scalar(keys%ignore)." entries\n";
  }
  return %ignore;
}

sub loadHspsInPlasmoGroups{
    my ($self, $batchSize, $testNumber) = @_;
    $self->log("loading hsps in batches of $batchSize");
    $self->log("loading matrix map");
    my $matrixMap = $self->loadMatrixMap();
    $self->log("loading species map");
    my ($indexToPlasmoMap, $plasmoToIndexMap) = $self->loadSpeciesMap();
    $self->log("loading index map");
    my ($indexToGusMap, $gusToIndexMap) = $self->loadIndexMap();
    $self->log("loading plasmo gus map");
    my $plasmoGusMap = $self->loadPlasmoGusMap();
    $self->log("loading plasmo group map");
    my $plasmoGroupMap = $self->getPlasmoGroupMap($indexToPlasmoMap, $matrixMap);
    
    
    my $blastFile = "/files/cbil/data/cbil/orthoPipeline/release2/blastSimilarity.out";
    my $blastFh = FileHandle->new("<" . $blastFile) || die ("could not open $blastFile!");
    my $groupKeys;
    my $finalSimCount = 0;
    my $checkSubjects = 0;
    my $queryIndexId;
    my $counter = 0;
    my $globalCounter = 0;
    my $queryCounter = 0;
    my $queryGusId;
    my @spansToSubmit;
    $self->log("parsing file");
    while (<$blastFh>){
	my $line = $_;
	if ($line =~ /^\>(\d+)\s/){
	    $counter++;
	    $queryCounter++;
	    $queryGusId = $1;
#	    $self->log("checking $queryGusId; counter is $counter and batch is $batchSize\n");
	    if ($counter == $batchSize){
	
		$self->submitAndCommit(@spansToSubmit);
		$counter = 0;
		@spansToSubmit = ();
	    }
	    if ($testNumber && $globalCounter >= $testNumber){
		$self->log ("done testing; test number is $testNumber");
		
		$self->submitAndCommit(@spansToSubmit);
		last;
	    }
	    $self->log("processed $queryCounter queries") if ($queryCounter % 1000 == 0);
	    $checkSubjects = 0;
	    $queryIndexId = $gusToIndexMap->{$queryGusId};
	    #die ("no query index id for gus id $queryGusId") unless $queryIndexId;
	    if ($queryIndexId){
		$groupKeys = $plasmoGroupMap->{$queryIndexId};
		if ($groupKeys){  #query is in group that contains plasmo
		    $checkSubjects = 1;
		    #print STDERR "sequence $queryIndexId (gus $queryGusId) is in a group that contains plasmo\n";
		}
	    }
	}
	else {
	    if ($checkSubjects){
		if ($line =~ /HSP\d:\s(\d+):/){
		    $globalCounter++;
		    $self->log("loading HSP number $globalCounter") if ($globalCounter % 1000 == 0);

		    my $subjectGusId = $1;
		 
		    my $subjectIndexId = $gusToIndexMap->{$subjectGusId};
		    #print STDERR "checking subject $subjectGusId for query $queryGusId\n";
		    #    die ("no subject index id for gus id $subjectGusId") unless $subjectIndexId;
		    if ($subjectIndexId){
			foreach my $key (keys %$groupKeys){  #foreach key for a group that has query
			    
			    if ($plasmoGroupMap->{$subjectIndexId}->{$key}){
				print STDERR "\tand the subject $subjectIndexId (gus $subjectGusId) is in the same group as query $queryIndexId \n";
				my $span = $self->parseSpan($line);
				$span->{subjectGusId} = $subjectGusId;
				$span->{queryGusId} = $queryGusId;
			
				push (@spansToSubmit, $span);
				$finalSimCount++;  #note if more than one group has same subject/query Id, will be counted twice, so number will be high
			    }
			}
		    }
		}
	    }
	}
    }
    $self->submitAndCommit(@spansToSubmit);
 
}

sub submitAndCommit{
    my ($self, @spansToSubmit) = @_;
    my $db = $self->getDb();
    $self->submitSpans(@spansToSubmit);
    if ($self->getArgs()->{commit}) {
	print STDERR "Committing\n";
	$db->getDbHandle()->commit();
    } else {
	$db->getDbHandle()->rollback();
	print STDERR "Rolling back\n";
    }
}

sub submitSpans{
    my ($self, @spansToSubmit) = @_;
    my $simQueryStmt = $self->getSimQueryStmt($self->getDb());
    my $spanStmt = $self->getInsertSpanStmt($self->getDb());
    
    foreach my $span (@spansToSubmit){

	my $subjectGusId = $span->{subjectGusId};
	my $queryGusId = $span->{queryGusId};
	my $simPk = $self->queryForSimId($subjectGusId, $queryGusId, $simQueryStmt);

	$self->insertSpan($simPk, $span, $spanStmt);
    }
    $self->log("submitted " . scalar (@spansToSubmit) . " spans; total spans submitted: " . $self->{spanCount});
}

sub getSimQueryStmt{

    my ($self, $db) = @_;
    
    my $sql = "select similarity_id from dots.similarity where query_table_id = 83 and subject_table_id = 83 and query_id = ? and subject_id = ?";
    return $db->getDbHandle()->prepare($sql);
}

sub queryForSimId{
    my ($self, $subjectGusId, $queryGusId, $simQueryStmt) = @_;
    $simQueryStmt->execute($queryGusId, $subjectGusId) || die $simQueryStmt->errstr;
    my ($simPk) = $simQueryStmt->fetchrow_array();
    return $simPk;
}

sub parseSpan {
  my ($self, $spanLine, $filter) = @_;

#   HSP1: 13058520:84:108:156:483:4e-49:1:155:175:642:0:+1


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


sub getInsertSpanStmt {
  my ($self, $db) = @_;

  my $algInvId = $self->getAlgInvocation()->getId();
  my $rowUserId = $self->getAlgInvocation()->getRowUserId();
  my $rowGroupId = $self->getAlgInvocation()->getRowGroupId();
  my $rowProjectId = $self->getAlgInvocation()->getRowProjectId();


  my $nextVal = $db->getDbPlatform()->nextVal($self->{simSchemaName} . ".SimilaritySpan");


  my $sql = 
"insert into  " . $self->{simSchemaName} . ".SimilaritySpan Values " .
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

sub insertSpan{

    my ($self, $simPk, $span, $spanStmt) = @_;

    my @spanVals = ($simPk, $span->{match_length},
		    $span->{number_identical}, $span->{number_positive},
		    $span->{score},  undef,
		    $span->{pvalue_mant}, $span->{pvalue_exp},
		    $span->{subject_start}, $span->{subject_end},
		    $span->{query_start}, $span->{query_end},
		    $span->{is_reversed}, $span->{reading_frame});

    $spanStmt->execute(@spanVals) || die $spanStmt->errstr;
    $self->logVerbose("Inserting SimilaritySpan: ", @spanVals);
    $self->{spanCount} += 1;


}

#map of form map->{plasmoGusId} = plasmoSourceId
sub loadPlasmoGusMap{
    my ($self) = @_;
    my $gusconfig = GUS::Community::GusConfig->new();
    
    my $db = GUS::ObjRelP::DbiDatabase->new($gusconfig->getDbiDsn(),
					    $gusconfig->getReadOnlyDatabaseLogin(),
					    $gusconfig->getReadOnlyDatabasePassword,
					    1,0,1,
					    $gusconfig->getCoreSchemaName);
    my $sql = "select aa_sequence_id, source_id from dots.externalaasequence where external_database_release_id in (10438,10437)";
    
    my $gusMap;
    
    my $sth = $db->getQueryHandle()->prepareAndExecute($sql);
    

    while (my ($gusId, $sourceId) = $sth->fetchrow_array()){
	$gusMap->{$gusId} = $sourceId;
    }
    
    return $gusMap;
}

#map of form map->{ortho_index_number} = sequence_gus_id and vice versa
sub loadIndexMap{
    my ($self) = @_;
    my $indexFile = "/home/dbarkan/ortho/fengResults/all_ortho_gus.idx";
    
    my $indexFh = FileHandle->new("<" . $indexFile) || die "could not open feng file\n";
    
    my $indexToGusMap;
    my $gusToIndexMap;
    while (<$indexFh>){
	my $line = $_;
	if ($line =~ /^(\d+)\s+(\d+)$/){
	    my $index = $1;
	    my $gusSeq = $2;

	    $indexToGusMap->{$index} = $gusSeq;
	    $gusToIndexMap->{$gusSeq} = $index;

	}
    }

    return ($indexToGusMap, $gusToIndexMap);
}

#map of form map->{ortho_index_number}->{plasmo_source_id}
sub loadSpeciesMap{
    my ($self) = @_;
    my $indexFile = "/home/dbarkan/ortho/fengResults/all_ortho.idx";
    
    my $indexFh = FileHandle->new("<" . $indexFile) || die "could not open feng file\n";

    my $indexToPlasmoMap;
    my $plasmoToIndexMap;
    while (<$indexFh>){
	my $line = $_;
	if ($line =~ /^(\d+)\s+(\d+)$/){
	    my $index = $1;
	    my $plasmoSeq = $2;
#	    print STDERR "info: $index is being added\n";
	    $indexToPlasmoMap->{$index} = $plasmoSeq;
	    $plasmoToIndexMap->{$plasmoSeq} = $index;
	}
    }
    return ($indexToPlasmoMap, $plasmoToIndexMap);   
}

#map of form map->{mcl matrix key} = mcl matrix seq string
sub loadMatrixMap{
       my ($self) = @_;
    my $orthoFile = "/home/dbarkan/ortho/fengResults/all_ortho.mcl";
    my $orthoFh = FileHandle->new("<" . $orthoFile) || die "could not open mcl file\n";
    
    my $matrixMap;
    
    my $key;    
    while(<$orthoFh>) {
	chomp;
	next unless ($_ =~ /^[\d\s]/);

	if($_ =~/^(\d+)\s+(.+)/) {

	    $key = $1;
#	    print STDERR "loading matrix map for key $key\n";
	    $matrixMap->{$key} = $2;
	}
 	else{
	#    print STDERR "appending matrix map for key $key\n";
	    $matrixMap->{$key} .= $_;
	    
	}
    }
    return $matrixMap;
}

#map of form map->{sequence in group with plasmo seq}->{key of that group} = 1

sub getPlasmoGroupMap{
    
    my ($self, $indexToPlasmoMap, $matrixMap) = @_;
    my $plasmoGroupMap;
    my $plasmoCount = 0;
    my $otherCount = 0; 
    my $totalCount = 0;
    foreach my $key (keys %$matrixMap) {

	$matrixMap->{$key} =~s/\$//;
	my @seqsInGroup = split(/\s+/, $matrixMap->{$key});
	my $containsPlasmo = 0;
	foreach my $seq (@seqsInGroup){
	    
	    if ($indexToPlasmoMap->{$seq}){
		$containsPlasmo = 1;
	    }
	}
	if ($containsPlasmo){
	    #print STDERR "adding seqs to plasmo group for key $key: ";
	    foreach my $seq (@seqsInGroup){
		$plasmoGroupMap->{$seq}->{$key} = 1;
		#print STDERR " $seq ";
	    }
	    #print STDERR "\n";
	}
	else {
	    $otherCount++;
	}

    }
    $plasmoGroupMap->{otherCount} = $otherCount;

    return $plasmoGroupMap;
}


1;

