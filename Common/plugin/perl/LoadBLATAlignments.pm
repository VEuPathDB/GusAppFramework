# ----------------------------------------------------------------------
# LoadBLATAlignments.pm
#
# Load a set of BLAT alignments into GUS.  Assumes that the 
# query sequences are identified with GUS na_sequence_ids.  The
# subject (genomic) sequences may use either na_sequence_ids
# or source_ids (if the corresponding external_db_id is given).
#
# Created: Sun Apr 28 22:48:04 EDT 2002
#
# Jonathan Crabtree
#
# $Revision$ $Date$ $Author$
# ----------------------------------------------------------------------

package GUS::Common::Plugin::LoadBLATAlignments;

@ISA = qw(GUS::PluginMgr::Plugin); 
use strict;
use CBIL::Bio::BLAT::PSL;
use CBIL::Bio::BLAT::PSLDir;
use CBIL::Bio::BLAT::Alignment;
use CBIL::Bio::FastaIndex;
use CBIL::Util::TO;
use CBIL::Util::Disp;

my $VERSION = '$Revision$'; $VERSION =~ s/Revision://; $VERSION =~ s/\$//g; $VERSION =~ s/ //g; #'

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  my $usage = "Load a set of BLAT alignments into GUS.  Assumes that the query sequences are identified with GUS na_sequence_ids.  The subject (genomic) sequences may use either na_sequence_ids or source_ids (if the corresponding external_db_id is given)";

  my $easycsp =
      [{  o => 'action',
	  h => 'one of: strip, get rid of extra psl headers; load, get alignments into db; setbest: set best alignment status, maybe delete unwanted alignments. Do all above if not set',
	  t => 'string',
       },
       {  o => 'blat_dir',
	  h => 'dir with files containing BLAT results in .psl format',
	  t => 'string', 
       },
       {  o => 'blat_files',
	  h => 'Files containing BLAT results in .psl format',
	  t => 'string',
       },
       {  o => 'reg_ex',
	  h => 'Regular expression for finding source ID in defline',
	  t => 'string',
       },
       {
	  o => 'file_list',
	  h => 'File that contains a list of newline-separated BLAT files (used instead of --blat_files).',
	  t => 'string',
      },
       {
	   o => 'query_file',
	   h => 'FASTA file that contains all of the BLAT query sequences.',
	   t => 'string',
	   r => 1,
       },
       {
	   o => 'keep_best',
	   h => 'keep how many alignments per query? (1: 1, 2: top 1%, o.w. all)',
	   t => 'int',
       },
       {
	   o => 'gap_table_space',
	   h => 'table space where genomic gap info is stored',
	   t => 'string',
       },
       {
	   o => 'previous_runs',
	   h => 'Comma-separated list of algorithm_invocation_ids of previous runs; any duplicate results from these runs are ignored.',
	   t => 'string',
       },
       {
	   o => 'report_interval',
	   h => 'Print a progress message every report_interval entries processed',
	   t => 'int',
	   d => 5000,
       },
       {
	   o => 'commit_interval',
	   h => 'Commit after this number of entries have been inserted.',
	   t => 'int',
	   d => 5000,
       },
       #####################################
       # BLAT run identification parameters
       #####################################
       {
	   o => 'query_table_id',
	   h => 'GUS table_id for the NASequence view that contains the BLAT query sequences.',
	   t => 'int',
	   d => 56,
       },
       {
	   o => 'query_taxon_id',
	   h => 'GUS taxon_id for the BLAT query sequences.',
	   t => 'int',
	   r => 1,
       },
       {
	   o => 'query_db_rel_id',
	   h => 'GUS external_db_release_id for the BLAT query sequence',
	   t => 'int',
       },
       {
	   o => 'target_table_id',
	   h => 'GUS table_id for the NASequence view that contains the BLAT target sequences.',
	   t => 'int',
	   d => 245, # VirtualSequence
       },
       {
	   o => 'target_taxon_id',
	   h => 'GUS taxon_id for the BLAT target sequences.',
	   t => 'int',
	},
       # 4792 = UCSC/NCBI 12/22/2001 release (human)
       # 5093 = UCSC Mm virtual chromosomes (February 2002 release)
       #
       {
	   o => 'target_db_rel_id',
	   t => 'int',
	   h => 'GUS external_db_release_id for the BLAT target sequences (only required if using source_ids for target.)',
       },
       ######################################################
       # gate-keeping parameter to prevent loading everything
       ######################################################
       {
	   o => 'min_query_pct',
	   h => 'Minimum percentage of the query sequence that must align in order for an alignment to be loaded.',
	   t => 'int',
	   d => 10,
       },
       ##################################################
       # parameters for blat alignment quality assessment
       ##################################################
       {
	   o => 'max_end_mismatch',
	   h => 'Maximum mismatch, excluding polyA, at either end of the query sequence for a consistent alignment.',
	   t => 'int',
	   d => 10,
       },
       {
	   o => 'min_pct_id',
	   h => 'Minimum percent identity for a consistent alignment.',
	   t => 'int',
	   d => 95,
       },
       {
	   o => 'max_query_gap',
	   h => 'Maximum size gap (unaligned segment) in the query sequence for a consistent alignment.',
	   t => 'int',
	   d => 5,
       },
       {
	   o => 'ok_internal_gap',
	   h => 'Tolerated size of internal gap (unaligned segment) in the query sequence for a alignment quality assessment.',
	   t => 'int',
	   d => 15,
       },
       {
	   o => 'ok_end_gap',
	   h => 'Tolerated size of end gap (unaligned segment) in the query sequence for a alignment quality assessment.',
	   t => 'int',
	   d => 50,
       },
       {
	   o => 'end_gap_factor',
	   h => 'multiplication factor to be applied to the size of query end mismatch for the search of genomic gaps',
	   t => 'int',
	   d => 10,
       },
       {
	   o => 'min_gap_pct',
	   h => 'minimum size percentage of a genomic gap that seems to correspond to a query gap',
	   t => 'int',
	   d => 90,
       }
       ];

  $self->initialize({requiredDbVersion => {},
		     cvsRevision => '$Revision$', # cvs fills this in!
		     cvsTag => '$Name$', # cvs fills this in!
		     name => ref($self),
		     revisionNotes => 'make consistent with GUS 3.0',
		     easyCspOptions => $easycsp,
		     usage => $usage
		     });
  return $self;
}

my $TPREF = 'DoTS';

sub run {
    my $self = shift;
    $| = 1;

    my $cla = $self->getCla();
    my $blatDir = $cla->{'blat_dir'};
    my $blatFiles = $cla->{'blat_files'};
    my $fileList =  $cla->{'file_list'};
    my $queryFile = $cla->{'query_file'};
    my $queryTableId = $cla->{'query_table_id'};
    my $targetTableId = $cla->{'target_table_id'};
    my $action = $cla->{'action'};
    my $regEx = $cla->{'reg_ex'};

    die "LoadBLATAlignments: query_file not defined" unless $queryFile;
    die "LoadBLATAlignments: unrecognized query_table_id" if (!($queryTableId =~ /^56|57|89|245|339$/));
    die "LoadBLATAlignments: unrecognized target_table_id" if (!($targetTableId =~ /^56|57|89|245|339$/));

    my $summary;

    my @blatFiles;
    my @allBlatFiles = &getBlatFiles($blatDir, $blatFiles, $fileList) unless $action eq 'setbest';

    if (!$action || $action eq 'strip') {
	foreach my $file (@allBlatFiles) {
	    $self->log("stripping extra headers in $file");
	    &CBIL::Bio::BLAT::PSLDir::strip($file);
	    if (&CBIL::Bio::BLAT::PSLDir::isFileEmpty($file)) {
	      &system("/bin/rm $file");
	    } else {
	      push @blatFiles, $file;
	    }
	}
    } else {
      @blatFiles = @allBlatFiles;
    }

    if (!$action || $action eq 'load') {
	my $blatFiles = join(',', @blatFiles);
	$self->log("Load alignments from raw BLAT output files $blatFiles ...");
	my $qIndex = &maybeIndexQueryFile($queryFile, $regEx);
print "DEBUGG made query index on file \"$queryFile\", using regEx \"$regEx\"\n";
	$summary = $self->loadAlignments($blatFiles, $qIndex);
    }

    if (!$action || $action eq 'setbest') {
	$self->log("setting best alignment status, maybe remove unwanted entries...");
	$summary .= $self->keepBestAlignments;
    }

    return $summary;
}

sub loadAlignments {
    my ($self, $blatFiles, $qIndex) = @_;
    
    my $dbh = $self->getQueryHandle();
    my $cla = $self->getCla();

    my $reportInterval = $cla->{'report_interval'};
    my $commitInterval = $cla->{'commit_interval'};
    my $prevRuns = $cla->{'previous_runs'};

    my $queryTableId = $cla->{'query_table_id'};
    my $queryTaxonId = $cla->{'query_taxon_id'};
    my $queryExtDbRelId = $cla->{'query_db_rel_id'};
    my $targetTableId = $cla->{'target_table_id'};
    my $targetTaxonId = $cla->{'target_taxon_id'};
    my $targetExtDbRelId = $cla->{'target_db_rel_id'};
    my $gapTabSpace = $cla->{'gap_table_space'};
    my $gapTabPref = '';
    if ($gapTabSpace) {
      my $ext_genome_ver = &getUcscGenomeVersion($dbh, $targetExtDbRelId);
      $gapTabPref = "${gapTabSpace}.${ext_genome_ver}_";
    }

    my $minQueryPct = $cla->{'min_query_pct'};

    # Parameters used to assess alignments qualities
    #
    my $qualityParams = {
	'maxEndMismatch' => $cla->{'max_end_mismatch'},
	'minPctId' => $cla->{'min_pct_id'},
	'maxQueryGap' => $cla->{'max_query_gap'},
	'okInternalGap' => $cla->{'ok_internal_gap'},
	'okEndGap' => $cla->{'ok_end_gap'},
	'endGapFactor' => $cla->{'end_gap_factor'},
	'minGapPct' => $cla->{'min_gap_pct'},
    };

    my @prevAlgInvIds = defined($prevRuns) ? split(/,|\s+/, $prevRuns): ();

    # 1. Read target source ids if requested
    #
    my $targetTable = &getTableNameFromTableId($dbh, $targetTableId);
    my $targetIdHash = ($targetExtDbRelId =~ /\d+/) ?
	&makeSourceIdHash($dbh, "$TPREF.$targetTable", $targetExtDbRelId) : undef;
    # 2. Build hash of alignments that have already been loaded; we assume
    #    that an alignment can be uniquely identified by its coordinates.
    #
    my $alreadyLoaded = &makeAlignmentHash($dbh, \@prevAlgInvIds, $queryTableId, $targetTableId);

    # 3. Load BLAT alignments into BLATAlignment
    #
    my @files = split(/,|\s+/, $blatFiles);
    my $nFiles = scalar(@files);

    my $userId = $self->getDb()->getDefaultUserId();  # used to be $cla->{'user_id'};
    my $groupId = $self->getDb()->getDefaultGroupId(); 
    my $projectId = $self->getDb()->getDefaultProjectId();
    my $algInvId = $self->getAlgInvocation()->getId();

    my $nextvalVar = $self->getDb()->getDbPlatform()->nextVal("$TPREF.BLATAlignment");

    my $insertSql = ("INSERT INTO $TPREF.BLATAlignment VALUES (" .
		     "$nextvalVar, " .
		     "?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, " .
		     "?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, " .
		     "SYSDATE, 1, 1, 1, 1, 1, 0, " .
		     "$userId, $groupId, $projectId, $algInvId)");

    #print STDERR "LoadBLATAlignments: insert sql = '$insertSql'\n";

    my $sth = $dbh->prepare($insertSql);

    my $nTotalAligns = 0;
    my $nTotalAlignsLoaded = 0;

    foreach my $blatFile (@files) {
	print "LoadBLATAlignments: reading from $blatFile\n";
	my $nAligns = 0;
	my $nAlignsLoaded = 0;

	my $psl = CBIL::Bio::BLAT::PSL->new($blatFile);
	my $alignments = $psl->getAlignments();

	print "LoadBLATAlignments: read ", $psl->getNumAlignments, " BLAT alignments from $blatFile\n";

	foreach my $align (@$alignments) {
	    ++$nAligns;
	    ++$nTotalAligns;

	    my $gapTab = ($gapTabPref ? "${gapTabPref}" . $align->get('t_name') . "_gap" : "");
	    my $nl = &loadAlignment($dbh, $gapTab, $insertSql, $sth, $queryTableId, $queryTaxonId,
				    $queryExtDbRelId, $targetTableId, $targetTaxonId, $targetExtDbRelId,
				    $qIndex, $qualityParams, $alreadyLoaded, $targetIdHash, $align,
				    $minQueryPct);

	    $nAlignsLoaded += $nl;
	    $nTotalAlignsLoaded += $nl;

	    &progressMessage($reportInterval, $nTotalAligns, 'BLAT alignments processed.');
	    &progressMessage($reportInterval, $nTotalAlignsLoaded, 'BLAT alignments loaded.') if ($nl > 0);

	    $dbh->commit() if (($nTotalAlignsLoaded % $commitInterval) == 0);
	}

	$dbh->commit();

	my $srcId = $1 if $blatFile =~ /([^\/])\.(fa|fasta)$/;
	my $target_id = $targetIdHash->{$srcId};
	print "LoadBLATAlignments: loaded $nAlignsLoaded/$nAligns BLAT alignments for $srcId ($target_id) from $blatFile.\n";
    }

    my $summary = "Loaded $nTotalAlignsLoaded/$nTotalAligns BLAT alignments from $nFiles file(s).\n";
    print "LoadBLATAlignments: ", $summary, "\n";
    return $summary;
}


sub getAlignmentGroups {
    my ($self) = @_;

    my $dbh = $self->getQueryHandle();
    my $cla = $self->getCla();

    my $keepBest = $cla->{'keep_best'};
    my $queryTableId = $cla->{'query_table_id'};
    my $queryTaxonId = $cla->{'query_taxon_id'};
    my $queryExtDbRelId = $cla->{'query_db_rel_id'};
    my $targetTableId = $cla->{'target_table_id'};
    my $targetTaxonId = $cla->{'target_taxon_id'};
    my $targetExtDbRelId = $cla->{'target_db_rel_id'};

    my $sql = "select query_na_sequence_id, blat_alignment_id, score, percent_identity "
	. "from DoTS.BlatAlignment "
        . "where query_table_id = $queryTableId "
	. "and query_taxon_id = $queryTaxonId "
	. ($queryExtDbRelId ? "and query_external_db_release_id = $queryExtDbRelId " : "")
	. "and target_table_id = $targetTableId "
        . "and target_taxon_id = $targetTaxonId "
        . "and target_external_db_release_id = $targetExtDbRelId";
    my $sth = $dbh->prepare($sql) or die "bad sql $sql:!\n";
    print "# running $sql...\n";
    $sth->execute or die "could not run $sql: $!";

    my %alnGrps;
    while (my ($sid, $bid, $score, $pct_id) = $sth->fetchrow_array) {
	$alnGrps{$sid} = [] unless $alnGrps{$sid};
	push @{ $alnGrps{$sid} }, [$bid, $score, $pct_id];
    }
    $sth->finish;

    \%alnGrps;
}

sub keepBestAlignments {
    my ($self) = @_;

    my $dbh = $self->getQueryHandle();
    my $cla = $self->getCla();

    my $keepBest = $cla->{'keep_best'};
    my $queryTableId = $cla->{'query_table_id'};
    my $queryTaxonId = $cla->{'query_taxon_id'};
    my $queryExtDbRelId = $cla->{'query_db_rel_id'};
    my $targetTableId = $cla->{'target_table_id'};
    my $targetTaxonId = $cla->{'target_taxon_id'};
    my $targetExtDbRelId = $cla->{'target_db_rel_id'};
    my $commitInterval = $cla->{'commit_interval'};

    # get alignment groups by query
    #
    print "# grouping alignments by query (DT)...\n";
    my $alnGrps = $self->getAlignmentGroups();

    # process result
    #
    print "# setting is_best_alignment status for each group...\n";
    my $tot_sq = scalar(keys %$alnGrps);
    my ($tot_al, $tot_bs) = (0,0);
    foreach my $sid (keys %$alnGrps) {
	my @oneGrp = @{ $alnGrps->{$sid} };
	my $grpSize = scalar(@oneGrp);

	my $best_score = 0;
	foreach (@oneGrp) {
	    my ($bid, $score, $pct_id) = @$_;
	    $best_score = $score if $score > $best_score;
	    $tot_al++;
	}
	foreach (@oneGrp) {
	    my ($bid, $score, $pct_id) = @$_;

	    my $is_best = ($grpSize == 1 || $score >= 0.99 * $best_score);
	    if ($is_best) {
		$tot_bs++;
		$dbh->do("update DoTS.BlatAlignment set is_best_alignment = 1 "
			 . "where blat_alignment_id = $bid" );
		if (($tot_bs % $commitInterval) == 0) {
		    $dbh->commit();
		    print "# $tot_bs alignments marked is_best_alignment = 1\n";
		}
	    }
	}
    }
    $dbh->commit();
    $alnGrps = undef;

    my $summary = "$tot_sq DoTS with $tot_al ($tot_bs) alignments (that are bests)\n";
    print $summary;

    if ($keepBest == 1) {
	print "# TODO: keep only one alignment per query\n";
    } elsif ($keepBest == 2) {
	print "deleting non-top alignments ...\n";
	my $sql = "delete DoTS.BlatAlignment "
	    . "where query_table_id = $queryTableId "
	    . "and query_taxon_id = $queryTaxonId "
	    . "and target_table_id = $targetTableId "
            . "and target_taxon_id = $targetTaxonId "
            . "and target_external_db_release_id = $targetExtDbRelId "
            . "and (is_best_alignment is null or is_best_alignment = 0)";
	$dbh->do($sql) or die "could not run $sql:!\n";
	$dbh->commit();
	$summary .= "(non-best alignments deleted from db)\n";
    }

    return $summary;
}

#-------------------------------------------------
# Subroutines
#-------------------------------------------------

# maybe index query sequence file
#
sub maybeIndexQueryFile {
    my ($queryFile) = @_;
    # Make sure that query_file is indexed
    #
    my $qIndex = new CBIL::Bio::FastaIndex(CBIL::Util::TO->new({seq_file => $queryFile, open => 1}));

    my $idSub = sub {
	my($defline) = @_;

	if ($defline =~ /^>(DT\.\d+|THC\d+)/) {
	    return $1;
	} elsif ($defline =~ /^>(\d+)/) {
	    return $1;
	} elsif ($defline =~ /^>Pfa3D7\|(\d+)\|/) {
	    return $1;
	}
        # TODO: make this id regex a config item (below is for mchr5p celera genes)
        elsif ($defline =~ /^>(\S+)/) { return $1; }

	print "Unable to parse $defline\n";	print "returning $1\n";
    };

    if (!$qIndex->open()) {
	$qIndex->createIndex(CBIL::Util::TO->new({get_key => $idSub}));
	$qIndex = undef;
	$qIndex = new CBIL::Bio::FastaIndex(CBIL::Util::TO->new({seq_file => $queryFile, open => 1}));
    }
    $qIndex;
}

sub getBlatFiles {
    my ($blatDir, $blatFiles, $fileList) = @_;
    die "LoadBLATAlignments: blat files not defined" unless $blatDir || $blatFiles || $fileList;

    return split(/,/, $blatFiles) if $blatFiles;

    # Read list of files if need be
    #
    my @files;
    if ($fileList && !$blatFiles) {
	my $fl = `cat $fileList`;
	@files = split(/[\s\n]+/,$fl);
    }

    if ($blatDir && !$blatFiles) {
	my $bd = CBIL::Bio::BLAT::PSLDir->new($blatDir);
	@files = $bd->getPSLFiles;
    }

    @files;
}

# Print a progress message if appropriate
#
sub progressMessage {
    my($interval, $num, $what) = @_;

    return if (not defined($interval));
    return if ($num == 0);

    if (($interval < 0) || ($num % $interval == 0)) {
	my $date = `date`;
	chomp($date);
	print "LoadBLATAlignments: $date $num $what\n";
    }
}

# Return the name of a table given its GUS table_id.
#
sub getTableNameFromTableId {
    my($dbh, $tid) = @_;

    my $sth = $dbh->prepareAndExecute("select distinct name from core.TableInfo where table_id = $tid");
    my($name) =  $sth->fetchrow_array();
    $sth->finish();

    return $name;
}

# Create a hash mapping source_id to na_sequence_id, if the
# user has supplied an external_db_id for the target sequences.
#
sub makeSourceIdHash {
    my($dbh, $targetTable, $targetDbId) = @_;
    my $hash = {};

    my $sql = ("select source_id, na_sequence_id " .
	       "from $targetTable " .
	       "where external_database_release_id = $targetDbId");
    print "DEBUG: query in makeSourceIdHash: \"$sql\"\n";
    my $sth = $dbh->prepare($sql);

    $sth->execute();
    while (my @a = $sth->fetchrow_array()) {
print "DEBUG:in mSIH: a0 = $a[0], a1 = $a[1]\n";
	my $v = $hash->{$a[0]};
	if (defined($v)) {
	    print STDERR "LoadBLATAlignments: WARNING - duplicate source_id $a[0] in $targetTable\n";
	} else {
	    $hash->{$a[0]} = $a[1];
	}
    }
    $sth->finish();

    print STDERR "LoadBLATAlignments: read ", scalar(keys %$hash), " source_ids for ";
    print STDERR "external_db_release_id $targetDbId from $targetTable.\n";

    return $hash;
}

# Create a hash containing all the BLAT alignments already in the 
# database for a given set of row_alg_invocation_id's.  Assumes
# that the two sequence ids + the alignment coordinates are a unique
# identifier.
#
sub makeAlignmentHash {
    my($dbh, $algInvIds, $queryTableId, $targetTableId) = @_;

    print STDERR "LoadBLATAlignments: Building hash using alg_inv_ids: [", join(", ", @$algInvIds), "]\n";

    my $hash = {};
    return $hash if (scalar(@$algInvIds) == 0);

    my $sql = (
	       "select query_na_sequence_id, target_na_sequence_id, " .
	       "       query_start, query_end, target_start, target_end " .
	       "from $TPREF.BLATAlignment " .
	       "where row_alg_invocation_id in ( " . join(",", @$algInvIds) . " )"
	       );

    print STDERR "LoadBLATAlignments: running '$sql'\n";

    my $sth = $dbh->prepare($sql);
    $sth->execute();

    my $nRows = 0;

    while (my @a = $sth->fetchrow_array()) {
	my $key = join(":", @a);
	my $entry = $hash->{$key};

	if (defined($entry)) {
	    print STDERR "LoadBLATAlignments: WARNING - already seen an alignment for $key\n";
	} else {
	    $hash->{$key} = 1;
	}
	++$nRows;
    }

    $sth->finish();

    print STDERR "LoadBLATAlignments.makeAlignmentHash: Entered $nRows rows into hash\n";
    return $hash;
}

# Load a single BLAT alignment into the GUS BLATAlignment table,
# if it is not already present in $alreadyLoaded and it meets 
# the minimum query percent alignment cutoff.  Returns the number 
# of alignments (0 or 1) actually loaded.
#
sub loadAlignment {
    my($dbh, $gapTable, $sql, $sth, $queryTableId, $queryTaxonId, $queryExtDbRelId,
       $targetTableId, $targetTaxonId, $targetExtDbRelId,$qIndex, $qualityParams,
       $alreadyLoaded, $targetIdHash, $align, $minQueryPct) = @_;

    my $query_id = $align->get('q_name');
    my $target_id = $align->get('t_name');

    # Map target query name -> na_sequence_id if required
    #
    if (defined($targetIdHash)) {
	my $srcId = $target_id;
	$target_id = $targetIdHash->{$srcId};

	if (!($target_id =~ /\d+/)) {
	    print STDERR "LoadBLATALignments: ERROR - unable to resolve target source_id '$srcId'\n";
	    return 0;
	}
    }

    # Convert external na seq source id to seq id, convert 'DT.blah' to 'blah' 
    #
    my $origQueryId = $query_id;
    # HACK
    $query_id = &getQueryNaSeqId($dbh, $query_id, $queryTableId);
    $query_id =~ s/[^0-9]//g;

    # Check to see whether this alignment has already been loaded
    #
    my $qs = $align->get('q_start'); my $qe = $align->get('q_end');
    my $ts = $align->get('t_start'); my $te = $align->get('t_end');

    my $key = join(":", ($query_id, $target_id, $qs, $qe, $ts, $te));
    my $loaded = $alreadyLoaded->{$key};

    if ($loaded == 1) {
	print STDERR "LoadBLATAlignments: Already loaded alignment of $query_id vs $target_id\n";
	return 0;
    }

    # Check to see whether this alignment meets the $minQueryPct cutoff
    #
    my $qSize = $align->get('q_size');
    my $matches = $align->get('matches');
    my $mismatches = $align->get('mismatches');
    my $repmatches = $align->get('rep_matches');
    my $ns = $align->get('num_ns');
    my $alignedBases = ($matches + $mismatches + $repmatches + $ns);
    my $alignPct = ($alignedBases / $qSize) * 100.0;
    return 0 if ($alignPct < $minQueryPct);

    # TO DO - only retrieve sequence if needed?

    # Retrieve sequence and compute quality
    #
    my $querySeq = $qIndex->getSequence(CBIL::Util::TO->new({accno => $origQueryId, strip => 1}));

print "DEBUGG: length(querySeq) = " . length($querySeq->{seq}) . " for accesion no. $origQueryId\n";
print "DEBUGG: index_file = \"$qIndex->{index_file}\", seq_file = \"$qIndex->{seq_file}\"\n";

    # Disp::Display($querySeq);

    my @a = $align->checkQuality($querySeq->{'seq'}, $qualityParams, $gapTable, $dbh);

    # determine BLAT alignment quality id (as specified in BlatAlignmentQuality table)
    my($qualityId,$has3p,$is3p,$has5p,$is5p,$qn,$tn,$pctId,$alignedBases,
       $maxQGap,$maxTGap,$numSpans, $minQs, $maxQe, $ts, $te, $strand, $end3, $end5) = @a;
    my $isConsist = ($qualityId == 1 ? 1 : 0);

    my @values = ($query_id,
		  $target_id,
		  $queryTableId,
		  $queryTaxonId,
		  $queryExtDbRelId,
		  $targetTableId,
		  $targetTaxonId,
		  $targetExtDbRelId,
		  $isConsist,
		  0,
		  $end3, $end5,
		  $has3p, $has5p,
		  $is3p, $is5p,
		  $pctId,
		  $maxQGap,
		  $maxTGap,
		  $numSpans,
		  $qs, $qe,
		  $ts, $te,
		  ($strand eq '-') ? 1 : 0,
		  $alignedBases,
		  $align->get('rep_matches'),
		  $align->get('num_ns'),
		  sprintf("%3.3f", sqrt($pctId * $alignPct)),
		  0,
		  $qualityId,
		  $align->getRaw('block_sizes'),
		  $align->getRaw('q_starts'),
		  $align->getRaw('t_starts')
		  );

    $sth->execute(@values) 
	or die "$sql failed with values: \n" . join(", ", @values)  . "\n";
    return 1;
}

# Return the na_sequence_id for of a TIGR TC.
#
sub getQueryNaSeqId {
    my ($dbh, $qid, $queryTableId) = @_;

    return $qid if $queryTableId =~ /^56|339$/;
    return $qid if $queryTableId == 89 && $qid =~ /^\d+$/;

    my $sql;
    if ($queryTableId == 89) {
	$sql = "select na_sequence_id from $TPREF.externalnasequence where source_id = '$qid'";
    } elsif ($queryTableId == 57) {
	$sql = "select na_sequence_id from $TPREF.assemblysequence where assembly_sequence_id = $qid";
    }
    
    my $sth = $dbh->prepareAndExecute($sql);
    my($sid) =  $sth->fetchrow_array();
    $sth->finish();
    return $sid;
}

# Return the (UCSC) genome version for given external databaser release id
#
sub getUcscGenomeVersion {
    my ($dbh, $ext_db_rel_id) = @_;

    my $sql = "select version from SRES.ExternalDatabaseRelease " .
	      "where external_database_release_id = $ext_db_rel_id";
    my $sth = $dbh->prepare($sql) or die "bad sql $sql: $!";
    $sth->execute or die "could not run $sql: $!";
    my @vers;
    while (my ($v) = $sth->fetchrow_array) { push @vers, $v; }
    my $c = $#vers+1;
    die "expected 1 entry but got $c\n" unless $c == 1;

    my $v = $vers[0];
    if ($v =~ /^((hg|mm)\d+)/i) {
	$v = $1;
    } else {
	die "can not parse UCSC genome version from \"$v\"\n";
    }

    $v;
}

1;
