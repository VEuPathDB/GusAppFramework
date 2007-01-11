#!/usr/bin/perl

## script that takes in the names of blast file(s) on stdin, parses and outputs either similarityspans
## or summaries or both.

## following are the fields of the output file:
## 
## >query_Identifier (# subjects)
##   Sum: subject_Identifier:score:pvalue:minSubjectStart:maxSubjectEnd:minQueryStart:maxQueryEnd:numberOfMatches:totalMatchLength:numberIdentical:numberPositive:isReversed:readingFrame
##     HSP: subject_Identifier:numberIdentical:numberPositive:matchLength:score:PValue:subjectStart:subjectEnd:queryStart:queryEnd:isReversed:readingFrame

use CBIL::Bio::Blast::BlastAnal;
use strict;
use Getopt::Long;

my $debug = 0;

$| = 1;

my ($regex,$pValCutoff,$lengthCutoff,$percentCutoff,$outputType,$program, $database,$seqFile,$startNumber,$stopNumber,$logFile,$addedParams,$remMaskedRes,$percentLengthCutoff,$rpsblast, $printLengths);

&GetOptions("regex=s" => \$regex, 
            "pValCutoff=f" => \$pValCutoff, 
            "lengthCutoff=i"=> \$lengthCutoff,
            "percentCutoff=i" => \$percentCutoff,
            "percentLengthCutoff=i" => \$percentLengthCutoff,
            "rpsblast!" => \$rpsblast,
            "outputType=s" => \$outputType,
            "outputFile=s" => \$logFile,
            "adjustMatchLength!" => \$remMaskedRes,
            "printLengths!" => \$printLengths,
            );

die "Usage: echo <blast filename> | parseBlastFilesForSimilarity.pl --regex='regular expression following ^\> of defline...ie '(\S+)'' --pValCutoff=[1e-5] --lengthCutoff=[10] --percentCutoff=[20] --percentLengthCutoff=[1] --rpsblast! --outputType=(summary|span|[both]) --adjustMatchLength --outputFile [blastSimilarity.out] --printLengths! (prints query and subject lengths in output)\n" unless ( $regex );

print STDERR "percentlengthcutoff=$percentLengthCutoff\n";
print STDERR "regex=$regex\n";


###set the defaullts...
$pValCutoff = $pValCutoff ? $pValCutoff : 1e-5;
$lengthCutoff = $lengthCutoff ? $lengthCutoff : 10;
$percentCutoff = $percentCutoff ? $percentCutoff : 20;  ##low for blastp
$outputType = $outputType ? $outputType : "both";
$logFile = $logFile ? $logFile : "blastSimilarity.out";

my $printSum = 0;
my $printSpan = 0;
if($outputType =~ /sum/i){
  $printSum = 1;
}elsif($outputType =~ /span/i){
  $printSpan = 1;
}elsif($outputType =~ /both/i){
  $printSum = 1;
  $printSpan = 1;
}else{
  die "usage: generateBlastSimilarity.pl identifier_regex pValueCutoff lengthCutoff percentCutoff output_format(summary|span|both) blast_program database sequenceFile startNumber stopNumber outputFile\n";
}


open(OUT, ">>$logFile");


##printthe cutoff parameters if first time used
print OUT "Cutoff parameters:\n\tP value: $pValCutoff\n\tLength: $lengthCutoff\n\tPercent Identity: $percentCutoff\n\tPercent Length Cutoff: $percentLengthCutoff\n\n";

##take in file names on STDIN
while(<STDIN>){
  print STDERR "Analyzing $_";
  chomp $_;
  open(F,"$_") || die "File $_ not found\n";
  my @blast;
  while(<F>){
    if(/^BLAST/ || /^TBLAST/){
#      print STDERR "new file of length ".scalar(@blast)."\n";
      &analyzeBlast(@blast) if scalar(@blast) > 1;
      undef @blast;
    }
    push(@blast,$_);
  }
  &analyzeBlast(@blast) if scalar(@blast) > 1;
  close F;
}


sub analyzeBlast{
  my(@blastn_out) = @_;
  my $blast = CBIL::Bio::Blast::BlastAnal->new($debug);
  $blast->parseBlast($lengthCutoff,$percentCutoff,$pValCutoff,$regex,\@blastn_out,$remMaskedRes,$rpsblast,$percentLengthCutoff); ##parse with less stringent params
  ##to aid in detection of repeats...

  print STDERR "\>".$blast->getQueryID()." (".$blast->getSubjectCount()." subjects)\n";
  print OUT "\>".$blast->getQueryID()." (".$blast->getSubjectCount()." subjects)".($printLengths ? " qlength=".$blast->getQueryLength() : "")."\n";
  foreach my $s ($blast->getSubjects()){
    print OUT $s->getSimilaritySummary(":").($printLengths ? " slength=".$s->getLength() : "")."\n" if $printSum;
    print OUT $s->getSimilaritySpans(":")."\n" if $printSpan;
  }
}

