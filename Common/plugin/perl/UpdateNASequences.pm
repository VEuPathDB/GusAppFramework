#!/usr/bin/perl

# -----------------------------------------------------------------------
# setNASeqs.pl
#
# Set the 'sequence' attribute of one or more NASequenceImp entries
# already in the database.  This column is a CLOB, so the script makes
# use of DBMS_LOB and a stored procedure in order to append to the
# CLOB value 4KB at a time (thus reducing the memory footprint of the
# client program.)
#
# This script requires the following PL/SQL procedure (which will
# *only* function correctly if the CLOB in question has already been
# initialized):
#
# CREATE OR REPLACE PROCEDURE append_dots_naseq (seqid NUMBER, seq VARCHAR2) IS
#	clob_loc CLOB;
#   BEGIN
#	SELECT sequence INTO clob_loc
#	FROM DoTS.NASequenceImp where na_sequence_id = seqid
#	FOR UPDATE;
#	DBMS_LOB.WRITEAPPEND(clob_loc, length(seq), seq);
#   END append_dots_naseq;
# /
# Created: Wed Oct 30 13:57:56 EST 2002
#
# Jonathan Crabtree
# 
# $Revision$ $Date$ $Author$
# -----------------------------------------------------------------------

package GUS::Common::Plugin::UpdateNASequences;

@ISA = qw(GUS::PluginMgr::Plugin); 

use strict;

use DBI;
use DBD::Oracle;

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  my $usage = "Update the sequence attribute of a set of NASequenceImp entries from fasta file";

  my $easycsp =
      [{
	  o => 'external_database_release_id',
	  h => 'minimum size percentage of a genomic gap that seems to correspond to a query gap',
	  t => 'int',
	  r => 1,
       },
       {  o => 'fasta_files',
	  h => 'FASTA files containing the sequence to be used for update.',
	  t => 'string',
       },
       {  o => 'file_list',
	  h => 'File containing new line separated list of FASTA files (to be used in place of --fasta_files).',
	  t => 'string',
       },
       { 
	   o => 'source_id_regex',
	   h => 'Regular expression for the parsing of source ids from FASTA headers.',
	   t => 'string',
	   d => '^>(\S+)',
       },
       {  o => 'source_id_lookup_table',
	  h => 'GUS table from which to lookup na_sequence_id for source_id.',
	  t => 'string',
	  d => 'DoTS.VirtualSequence',
       },       
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

sub run {
    my $self = shift;
    
    $| = 1;
    
    my $dbh = $self->getQueryHandle();
    $dbh->{RaiseError} = 1;
    $dbh->{AutoCommit} = 0;

    my $cla = $self->getCla();
    my $fastaFiles = $cla->{'fasta_files'};
    my $fileList = $cla->{'file_list'};
    my @fastaFiles = &getFastaFilesArray($fastaFiles, $fileList);
    my $extDbRelId = $cla->{'external_database_release_id'};
    my $srcid_regex = $cla->{'source_id_regex'};
    my $srcid_lookup_table = $cla->{'source_id_lookup_table'};

    # Maximum amount of sequence to buffer on the client side before writing
    # it into the database.
    #
    my $MAX_BUFFER_SIZE = 1024 * 1024;  # 1Mb

    # SQL statement used to retrieve the sequence to update, based on the
    # source_id parsed out of the FASTA file's defline.
    #
    my $SEQ_SQL = "select na_sequence_id from $srcid_lookup_table "
	. "where external_database_release_id = $extDbRelId and source_id = ? ";

    my $seqLookup = $dbh->prepare($SEQ_SQL);
    my $seqUpdate = $dbh->prepare("update DoTS.NASequenceImp set sequence = ? where na_sequence_id = ?");
    my $seqAppend = $dbh->prepare("BEGIN append_dots_naseq(?, ?); END;");

    my $defline = undef;
    my $srcId = undef;
    my $naSeqId = undef;
    my $seqBuffer = undef;
    my $charsBuffered = undef;
    my $charsWritten = undef;
    my $line = undef;

    &createStoredProcedure($dbh);
    my $tot_files = scalar(@fastaFiles);
    my $tally = 1;
    foreach my $fastaFile (@fastaFiles) {
	print STDERR "process " . $tally++ . " / $tot_files files: $fastaFile...\n";
	open FA, $fastaFile;
	while ($line = <FA>) {
	    chomp($line);
	    # Skip blank lines
	    next if ($line =~ /^\s*$/);
	    
	    # New sequence defline
	    if ($line =~ /^>/) {
		
		if ($charsBuffered > 0) {
		    &appendToNASeq($dbh, $seqUpdate, $seqAppend, $naSeqId, $defline,
				   \$seqBuffer, \$charsBuffered, \$charsWritten);
		    print "$defline: $naSeqId: wrote $charsWritten bp\n";
		}
		
		$defline = $line;
		if ($line =~ /$srcid_regex/) {
		    $srcId = $1;
		    
		    # Look up this sequence using the provided SQL statement
		    #
		    $naSeqId = &lookupNASeq($seqLookup, $srcId);
		    die "Unable to find $srcId" if (!defined($naSeqId));
		    
		    $charsWritten = 0;
		    $charsBuffered = 0;
		    $seqBuffer = '';
		} else {
		    die "failed to parse defline '$line' using regex '$srcid_regex'";
		}
	    } 
	    
	    # Sequence
	    elsif ($line =~ /^(\S+)$/) {
		my $seq = $1;
		my $seqLen = length($seq);
		
		$seqBuffer .= $seq;
		$charsBuffered += $seqLen;
		
		if ($charsBuffered > $MAX_BUFFER_SIZE) {
		    &appendToNASeq($dbh, $seqUpdate, $seqAppend, $naSeqId, $defline,
				   \$seqBuffer, \$charsBuffered, \$charsWritten);
		}
	    }
	    
	    else {
		die "this really shouldn't happen";
	    }
	}
	
	# Write whatever we have left
	#
	if ($charsBuffered > 0) {
	    &appendToNASeq($dbh, $seqUpdate, $seqAppend, $naSeqId, $defline,
			   \$seqBuffer, \$charsBuffered, \$charsWritten);
	    print "$defline: $naSeqId: wrote $charsWritten bp\n";
	}
	close FA;

	$dbh->do("update DoTS.NASequenceImp set length = length(sequence)"
		 . " where na_sequence_id = $naSeqId and length(sequence) > 0");
    }

    # huh? Comment above notes that this script fails on sequences
    # over a Meg without the append_dots_naseq feature
    # so why are we dropping it?
    # $dbh->do("drop procedure append_dots_naseq");

    $dbh->disconnect();
}

# -----------------------------------------------------------------------
# Subroutines
# -----------------------------------------------------------------------

# get an array of fasta files to load sequence from
#
sub getFastaFilesArray {
    my ($fastaFiles, $fileList) = @_;

    die "neither fasta_files nor file_list defined" if ((!defined($fastaFiles)) && (!defined($fileList)));

    my @fastaFiles = split(/,/, $fastaFiles);
    if (defined($fileList)) {
	my $fl = `cat $fileList`;
	@fastaFiles = split(/[\s\n]+/,$fl);
    }

    @fastaFiles;
}

# Retrieve the na_sequence_id of a sequence identified by source_id
#
sub lookupNASeq {
    my($sth, $srcId) = @_;
    my $rows = [];
    $sth->execute($srcId);

    while(my @a = $sth->fetchrow_array()) {
	my @copy = @a;
	push(@$rows, \@copy);
    }
    $sth->finish();

    return undef if (scalar(@$rows) == 0);

    if (scalar(@$rows > 1)) {
	print STDERR "updateNASeqs.pl: WARNING - found multiple sequences with ID '$srcId'\n";
    }
    return $rows->[0]->[0];
}

# Write the complete contents of the current sequence buffer to the CLOB 
# in the database
#
sub appendToNASeq {
    my($dbh, $seqUpdate, $seqAppend, $naSeqId, $defline, $seqBuffer, $charsBuffered, $charsWritten) = @_;

    # For debugging purposes we'll just print out the sequence instead of 
    # actually appending it to the CLOB.

    while ($$charsBuffered > 0) {

	# The first time we write to the CLOB we need to initialize it, and
	# DBI will take care of this for us.
	#
	if ($$charsWritten == 0) {
	    my $nrows = $seqUpdate->execute($$seqBuffer, $naSeqId);

	    # DEBUG
#	    print "na_seq_id = $naSeqId\n";
#	    print "$$seqBuffer\n";

	    $$charsWritten += $$charsBuffered;
	    $$seqBuffer = '';
 	    $$charsBuffered = 0;
        } 

        # But for subsequent writes we'll use the PL/SQL procedure that appends
        # successive 4K chunks to the CLOB.
        #
        else {
	    # How much to append in this write operation
	    #
	    my $writeLen = ($$charsBuffered < 4000) ? $$charsBuffered : 4000;
	    my $substring = substr($$seqBuffer, 0, $writeLen);
	    my $nrows = $seqAppend->execute($naSeqId, $substring);

	    # DEBUG
#	    print "$substring\n";

	    $$charsWritten += $writeLen;
	    $$charsBuffered -= $writeLen;
	    substr($$seqBuffer, 0, $writeLen) = '';
        }
    }
    print STDERR "$naSeqId: $$charsWritten bp\n";
    $dbh->commit();
}

sub createStoredProcedure {
  my $dbh = shift;

  my $sp =<<SP;
CREATE OR REPLACE PROCEDURE append_dots_naseq (seqid NUMBER, seq VARCHAR2) IS
	clob_loc CLOB;
   BEGIN
	SELECT sequence INTO clob_loc
	FROM DoTS.NASequenceImp where na_sequence_id = seqid
	FOR UPDATE;
	DBMS_LOB.WRITEAPPEND(clob_loc, length(seq), seq);
   END append_dots_naseq;
SP
  $dbh->do($sp);
}

sub showNASeq {
    my($dbh, $naSeqId) = @_;
    my $seq = $dbh->selectrow_array("select sequence from DoTS.NASequenceImp where na_sequence_id = $naSeqId ");
    my $sl = length($seq);
    print "$naSeqId: retrieved sequence of length $sl\n";
}

# ----------------------------------------------------------
# toFasta
#
# Create a FASTA-format sequence entry.
#
# $seq         Sequence with NO newlines, whitespace, or FASTA defline.
# $defline     Definition line for the FASTA entry (not including '>')
# $width       Width of the actual sequence in characters.
#
sub toFasta {
    my($seq, $defline, $width) = @_;

    my $rs = ">$defline\n";
    
    my $start = 0;
    my $end = length($seq);

    for (my $i = $start;$i <= $end;$i += $width) {
	if ($width + $i > $end) {
	    $rs .= substr($seq, $i, $end - $i + 1) . "\n";
	} else {
	    $rs .= substr($seq, $i, $width) . "\n";
	}
    }
    chomp($rs);
    return $rs;
}


