##
## InsertGeneCoordinates Plugin
## $Id: $
##

package GUS::Community::Plugin::InsertGeneCoordinates;
@ISA = qw( GUS::PluginMgr::Plugin );

use strict;
use IO::File;
use Data::Dumper;
use GUS::PluginMgr::Plugin;

use GUS::Model::DoTS::Gene;
use GUS::Model::DoTS::GeneInstance;
use GUS::Model::DoTS::GeneInstanceCategory;
use GUS::Model::DoTS::VirtualSequence;
use GUS::Model::DoTS::GeneFeature;
use GUS::Model::DoTS::ExonFeature;
use GUS::Model::DoTS::NALocation;

# ----------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------

sub getArgumentsDeclaration {
  my $argumentDeclaration  =
    [
     fileArg({name => 'geneCoordFile',
	      descr => 'The full path of the file downloaded from UCSC.',
	      constraintFunc=> undef,
	      reqd  => 1,
	      isList => 0,
	      mustExist => 1,
	      format => ''
	     }),
     fileArg({name => 'entrezChrFile',
	      descr => 'The full path of an NCBI file mapping Entrez Genes to chromosomes with the first 2 columns having values chromosome number and gene_symbol (no header).',
	      constraintFunc=> undef,
	      reqd  => 1,
	      isList => 0,
	      mustExist => 1,
	      format => ''
	     }),
     stringArg({ name  => 'extDbRlsSpecGenome',
		  descr => "The ExternalDBRelease specifier for the genome release which the coordinates refer to. Must be in the format 'name|version', where the name must match a name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
		  constraintFunc => undef,
		  reqd           => 1,
		  isList         => 0 }),
     stringArg({ name  => 'extDbRlsSpecEntrez',
		  descr => "The ExternalDBRelease specifier for the Entrez Genes whose coordinates one wants to load. Must be in the format 'name|version', where the name must match a name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
		  constraintFunc => undef,
		  reqd           => 1,
		  isList         => 0 }),
     integerArg({name  => 'restart',
		 descr => 'Line number in --geneCoordFile from which loading should be resumed (line 1 is the first line after the header, empty lines are counted).',
		 constraintFunc=> undef,
		 reqd  => 0,
		 isList => 0
		}),
     integerArg({name  => 'testnum',
		 descr => 'The number of data lines to read when testing this plugin. Not to be used in commit mode.',
		 constraintFunc=> undef,
		 reqd  => 0,
		 isList => 0
		})
    ];
  return $argumentDeclaration;
}

# ----------------------------------------------------------------------
# Documentation
# ----------------------------------------------------------------------


sub getDocumentation {
  my $purposeBrief = 'Loads gene coordinates from a UCSC file into DoTS.';

  my $purpose = "This plugin reads a file obtained from UCSC by joining knownGene and knownXref, with the following header suffixes (order is not relevant): name, chrom, strand, txStart, txEnd, cdsStart, cdsEnd, exonCount, extonStarts, exonEnds, geneSymbol. The file is assumed to have 0-base for starts and 1-base for ends. The plugin enters all this info into the relevant DoTS tables. An Entrez Gene mapping file from genes to chromosomes is used to filter out UCSC entries mapping to more than one chromosome. When a gene maps both to chrX and to chrY, only the first of these two mappings is retained.";

  my $tablesAffected = [['DoTS::GeneFeature', 'Enters a row for each gene in the file'], ['DoTS::GeneInstance', 'Enters rows linking each new GeneFeature to its Gene and VirtualSequence'], ['DoTS::ExonFeature', 'Enters a row for each exon'], ['DoTS::NALocation', 'Enters a row for each gene and a row for each exon']];

  my $tablesDependedOn = [['SRes::ExternalDatabaseRelease', 'The genome release to which coordinates refer and the Entrez Gene release whose coordinates are being entered'],['DoTS::GeneInstanceCategory', 'The term corresponding to Entrez Genes'], ['DoTS::Gene', 'The genes to which coordinates refer'], ['DoTS::VirtualSequence', 'The chromosomes for the genome release of interest']];

  my $howToRestart = "Loading can be resumed using the I<--restart n> argument where n is the line number in the Taxon.gene_info file of the first row to load upon restarting (line 1 is the first line after the header, empty lines are counted). Alternatively, one can use the plugin GUS::Community::Plugin::Undo to delete all entries inserted by a specific call to this plugin. Then this plugin can be re-run from fresh.";

  my $failureCases = "";

  my $notes = <<NOTES;

=head1 AUTHOR

Written by Elisabetta Manduchi.

=head1 COPYRIGHT

Copyright Elisabetta Manduchi, Trustees of University of Pennsylvania 2009. 
NOTES

  my $documentation = {purpose=>$purpose, purposeBrief=>$purposeBrief, tablesAffected=>$tablesAffected, tablesDependedOn=>$tablesDependedOn, howToRestart=>$howToRestart, failureCases=>$failureCases, notes=>$notes};

  return $documentation;
}

# ----------------------------------------------------------------------
# create and initalize new plugin instance.
# ----------------------------------------------------------------------

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  my $documentation = &getDocumentation();
  my $argumentDeclaration    = &getArgumentsDeclaration();

  $self->initialize({requiredDbVersion => 3.5,
		     cvsRevision => '$Revision: 7463 $',
		     name => ref($self),
		     revisionNotes => '',
		     argsDeclaration => $argumentDeclaration,
		     documentation => $documentation
		    });
  return $self;
}

# ----------------------------------------------------------------------
# run method to do the work
# ----------------------------------------------------------------------

sub run {
  my ($self) = @_;
  my $resultDescrip;

  if (defined($self->getArg('testnum')) && $self->getArg('commit')) {
    $self->userError("The --testnum argument can only be provided if COMMIT is OFF.");
  }
  my $extDbRlsGenome = $self->getExtDbRlsId($self->getArg('extDbRlsSpecGenome'));
  my $extDbRlsEntrez = $self->getExtDbRlsId($self->getArg('extDbRlsSpecEntrez'));
  $self->logDebug("Ext Db Rls Ids: $extDbRlsGenome, $extDbRlsEntrez");
  my $chrs = $self->getGene2Chr($self->getArg('entrezChrFile'));
  $resultDescrip .= $self->insertCoordinates($extDbRlsGenome, $extDbRlsEntrez, $self->getArg('geneCoordFile') , $chrs);
  
  $self->setResultDescr($resultDescrip);
  $self->logData($resultDescrip);
}

# ----------------------------------------------------------------------
# methods
# ----------------------------------------------------------------------

sub getGene2Chr {
  my ($self, $file) = @_;
  my $chrs;
  my $fh = IO::File->new("<$file") || $self->userError("Cannot open $file");
  while (my $line=<$fh>) {
    chomp($line);
    my ($chr, $geneSymbol, @rest) = split(/\t/, $line);
    if (!defined($chrs->{$geneSymbol})) {
      $chrs->{$geneSymbol} = 'chr' . $chr;
    }    
    elsif ($chr eq 'X' && $chrs->{$geneSymbol} eq 'chrY') {
      $chrs->{$geneSymbol} = 'chrX';
    }
    elsif ($chr eq 'Y' && $chrs->{$geneSymbol} eq 'chrX') {
      $chrs->{$geneSymbol} = 'chrX';
    }
    elsif ($chrs->{$geneSymbol} ne 'chr'.$chr) {
      $self->userError("$geneSymbol has multiple mappings in --entezChrFile"); 
    }
  }
  return($chrs);
}

sub insertCoordinates {
  my ($self, $extDbRlsGenome, $extDbRlsEntrez, $file, $chrs) = @_;
  my $resultDescrip = '';
  my $countGeneFeatures = 0;
  my $countExonFeatures = 0;
  my $lineNum = 0;

  my $fh = IO::File->new("<$file") || $self->userError("Cannot open $file");
  my $line = <$fh>;
  my $pos = $self->parseHeader($line);

  my $startLine = defined $self->getArg('restart') ? $self->getArg('restart') : 1;
  my $endLine;
  if (defined $self->getArg('testnum')) {
    $endLine = $startLine-1+$self->getArg('testnum');
  }
  my $geneInstanceCategory= GUS::Model::DoTS::GeneInstanceCategory->new({name => 'Entrez Genes'});
  if (!$geneInstanceCategory->retrieveFromDB()) {
    $self->userError("Missing required 'Entrez Genes' Gene Instance Category");
  }
  $self->logDebug($geneInstanceCategory->toString() . "\n");
  while ($line=<$fh>) {
    $lineNum++;
    if ($lineNum<$startLine) {
      next;
    }
    if (defined $endLine && $lineNum>$endLine) {
      last;
    }
    if ($lineNum % 1000 == 0) {
      $self->log("Inserting data from the $lineNum-th line.");
    }
    chomp($line);
    my @arr = split(/\t/, $line);
    my $ucId = $arr[$pos->{'ucId'}];
    my $chr = $arr[$pos->{'chr'}];
    my $isReversed = $arr[$pos->{'strand'}] eq "+" ? 0 : 1;
    my $geneStart = $arr[$pos->{'txStart'}] + 1;
    my $geneEnd = $arr[$pos->{'txEnd'}]; 
    my $cdsStart = $arr[$pos->{'cdsStart'}] + 1;
    my $cdsEnd = $arr[$pos->{'cdsEnd'}]; 
    $/ = ",";
    chomp($arr[$pos->{'exonStarts'}]);
    chomp($arr[$pos->{'exonEnds'}]);
    $/ = "\n";
    my @exonStarts = map ($_+1, split(/,/,$arr[$pos->{'exonStarts'}]));
    my @exonEnds = split(/,/,$arr[$pos->{'exonEnds'}]);
    my $exonCount = $arr[$pos->{'exonCount'}];
    my $geneSymbol = $arr[$pos->{'geneSymbol'}]; 
    if ($chrs->{$geneSymbol} ne $chr) {
      next;
    }
    if (scalar(@exonStarts) != $exonCount || scalar(@exonEnds) != $exonCount) {
      $self->userError("Inconsistent exon counts at line $lineNum");
    }
    
    if ($chr eq 'chrM' || $chr =~ /chrU/ || $chr =~ /_/) {
      next;
    }
    my $gene= GUS::Model::DoTS::Gene->new({gene_symbol => $geneSymbol, external_database_release_id => $extDbRlsEntrez});
    if (!$gene->retrieveFromDB()) {
      next;
    }
    $self->logDebug($gene->toString() . "\n");
    my $virtualSequence= GUS::Model::DoTS::VirtualSequence->new({external_database_release_id => $extDbRlsGenome, source_id => $chr});

    my @doNotRetrieve = ('sequence');
    if (!$virtualSequence->retrieveFromDB(\@doNotRetrieve)) {
      $self->userError("Missing required DoTS.VirtualSequence for $chr");
    } 
    $self->logDebug($virtualSequence->toString() . "\n");

    my $geneFeature= GUS::Model::DoTS::GeneFeature->new({name => $ucId, number_of_exons => $exonCount});
    $geneFeature->setParent($virtualSequence);

    my $geneInstance= GUS::Model::DoTS::GeneInstance->new({is_reference => 0});    
    $geneInstance->setParent($geneInstanceCategory);   
    $geneInstance->setParent($gene);
    $geneInstance->setParent($geneFeature);
    my $naLocation = GUS::Model::DoTS::NALocation->new({start_min => $geneStart, start_max => $geneStart, end_min => $geneEnd, end_max => $geneEnd, is_reversed => $isReversed});
    $naLocation->setParent($geneFeature);

    $self->logDebug($geneFeature->toString() . "\n");
    $self->logDebug($naLocation->toString() . "\n");
    $self->logDebug($geneInstance->toString() . "\n");

    for (my $i=0; $i<$exonCount; $i++) {
      my $exonNum = $i+1;
      my ($start, $end);
      if ($cdsEnd>$cdsStart && $exonStarts[$i]<=$cdsEnd) {
	if ($exonStarts[$i]>=$cdsStart) {
	  $start = $exonStarts[$i];
	}
	elsif ($cdsStart<=$exonEnds[$i]) {
	  $start = $cdsStart;
	}
      }
      if ($cdsEnd>$cdsStart && $exonEnds[$i]>=$cdsStart) {
	if ($exonEnds[$i]<=$cdsEnd) {
	  $end = $exonEnds[$i];
	}
	elsif ($exonStarts[$i]<=$cdsEnd) {
	  $end = $cdsEnd;
	}
      }

      my $exonFeature= GUS::Model::DoTS::ExonFeature->new({name => 'exon '. $exonNum, coding_start => $start, coding_end => $end});
      $exonFeature->setParent($geneFeature); 
      my $exonNaLocation = GUS::Model::DoTS::NALocation->new({start_min => $exonStarts[$i], start_max => $exonStarts[$i], end_min => $exonEnds[$i], end_max => $exonEnds[$i], is_reversed => $isReversed});
      $exonNaLocation->setParent($exonFeature);    
      $self->logDebug($exonFeature->toString() . "\n");
      $self->logDebug($exonNaLocation->toString() . "\n");
    }
    $geneFeature->submit();
    $countGeneFeatures++;
    $countExonFeatures += $exonCount;
    $self->undefPointerCache();
  }
  $fh->close();

  my $countTotal = $countGeneFeatures + $countExonFeatures;
  $resultDescrip .= "Inserted $countGeneFeatures entries in DoTS.GeneInstance and DoTS.GeneFeature, $countExonFeatures entries in DoTS.ExonFeature, and $countTotal entries in DoTS.NALocation.";
  return ($resultDescrip);
}

sub parseHeader{
  my ($self, $line) = @_;
  my $pos;
  
  chomp($line);
  my @arr = split(/\t/, $line);
  for (my $i=0; $i<@arr; $i++) {
    if ($arr[$i] =~ /name$/) {
      $pos->{'ucId'} = $i;
    }
    if ($arr[$i] =~ /chrom$/) {
      $pos->{'chr'} = $i;
    }
    if ($arr[$i] =~ /strand$/) {
      $pos->{'strand'} = $i;
    }
    if ($arr[$i] =~ /txStart$/) {
      $pos->{'txStart'} = $i;
    }
    if ($arr[$i] =~ /txEnd$/) {
      $pos->{'txEnd'} = $i;
    }
    if ($arr[$i] =~ /cdsStart$/) {
      $pos->{'cdsStart'} = $i;
    }
    if ($arr[$i] =~ /cdsEnd$/) {
      $pos->{'cdsEnd'} = $i;
    }
    if ($arr[$i] =~ /exonCount$/) {
      $pos->{'exonCount'} = $i;
    }
    if ($arr[$i] =~ /exonStarts$/) {
      $pos->{'exonStarts'} = $i;
    }
    if ($arr[$i] =~ /exonEnds$/) {
      $pos->{'exonEnds'} = $i;
    }
    if ($arr[$i] =~ /geneSymbol$/) {
      $pos->{'geneSymbol'} = $i;
    }
  }
  $self->logDebug(Dumper($pos) . "\n");
  if (!defined $pos->{'ucId'} || 
      !defined $pos->{'chr'} || !defined $pos->{'strand'} ||
      !defined $pos->{'txStart'} || !defined $pos->{'txEnd'} ||
      !defined $pos->{'cdsStart'} || !defined $pos->{'cdsEnd'} ||
      !defined $pos->{'exonStarts'} || !defined $pos->{'exonEnds'} ||
      !defined $pos->{'exonCount'} || !defined $pos->{'geneSymbol'}) {
    $self->userError("Missing fields in gene coordinates file");
  }
  return($pos);
}

# ----------------------------------------------------------------------
# Undo
# ----------------------------------------------------------------------

sub undoTables {
  my ($self) = @_;

  return ('DoTS.NALocation', 'DoTS.ExonFeature', 'DoTS.GeneInstance', 'DoTS.GeneFeature');
}

1;
