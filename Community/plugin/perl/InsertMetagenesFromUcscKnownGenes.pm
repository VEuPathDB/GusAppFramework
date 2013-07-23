#######################################################################
##                 InsertEnsemblGenes.pm
## $Id: InsertMetaGenesFromUcscKnownGenes.pm  manduchi $
##
#######################################################################
 
package GUS::Community::Plugin::InsertMetagenesFromUcscKnownGenes;
@ISA = qw( GUS::PluginMgr::Plugin );

use strict;
use GUS::PluginMgr::Plugin;
use GUS::Model::DoTS::Gene;
use GUS::Model::DoTS::GeneInstance;
use GUS::Model::DoTS::ExternalNASequence;
use GUS::Model::DoTS::GeneFeature;
use GUS::Model::DoTS::RNAFeature;
use GUS::Model::DoTS::ExonFeature;
use GUS::Model::DoTS::RNAFeatureExon;
use GUS::Model::DoTS::NALocation;

# ----------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------

sub getArgumentsDeclaration {
  my $argumentDeclaration =
    [
     fileArg({name => 'metageneFile',
	      descr => 'The full path to a tab-delimited headerless metagene file with the following fields: chromosome, strand, metagene start (bp), metagene end (bp), metaexon count, metaexon starts, metaexon ends, metagene identifier (order is relevant).',
	      constraintFunc=> undef,
	      reqd  => 1,
	      isList => 0,
	      mustExist => 1,
	      format => ''
	     }),
     fileArg({name => 'knownGeneFile',
	      descr => 'The full path to a tab-delimited file from UCSC with the following header: sa.knownGene.name, sa.knownGene.chrom, sa.knownGene.strand, sa.knownGene.txStart, sa.knownGene.txEnd, sa.knownGene.cdsStart, sa.knownGene.cdsEnd, sa.knownGene.exonCount, sa.knownGene.exonStarts, sa.knownGene.exonEnds, sa.kgXref.kgID, sa.kgXref.geneSymbol, sa.knownToLocusLink.value (order is irrelevant and extra header fields will be ignored). Here sa is specified by --speciesAbbr.',
	      constraintFunc=> undef,
	      reqd  => 1,
	      isList => 0,
	      mustExist => 1,
	      format => ''
	     }),
     stringArg({ name  => 'speciesAbbr',
		 descr => "The species abbreviation in the header of the knownGeneFile, e.g. 'mm9'",
		 constraintFunc => undef,
		 reqd           => 1,
		 isList         => 0 
	     }),
     stringArg({ name  => 'extDbRlsSpecGenome',
		 descr => "The ExternalDBRelease specifier for the genome the gene coordinates refer to. Must be in the format 'name|version', where the name must match a name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
		 constraintFunc => undef,
		 reqd           => 1,
		 isList         => 0 
	     }),
     stringArg({ name  => 'extDbRlsSpecGenes',
		 descr => "The ExternalDBRelease specifier for these metagenes. Must be in the format 'name|version', where the name must match a name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
		 constraintFunc => undef,
		 reqd           => 1,
		 isList         => 0 
	     }),
     stringArg({ name  => 'extDbRlsSpecSymbols',
		 descr => "The ExternalDBRelease specifier for the reference gene symbols. Must be in the format 'name|version', where the name must match a name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
		 constraintFunc => undef,
		 reqd           => 1,
		 isList         => 0 
	     })
    ];
  return $argumentDeclaration;
}

# ----------------------------------------------------------------------
# Documentation
# ----------------------------------------------------------------------


sub getDocumentation {
  my $purposeBrief = 'Loads metagenes and associated transcripts/exons into DoTS.';

  my $purpose = "This plugin reads a Known Genes file downloaded from UCSC and a metagene file based on that, and populates DoTS Gene tables.";

  my $tablesAffected = [['DoTS::Gene', 'Enters a row for each (non-already existing) gene symbol in the file and for each metagene without a symbol'], ['DoTS::GeneFeature', 'Enters a row for each metagene in the gene file'], ['DoTS::GeneInstance', 'Enters rows linking each new GeneFeature to its Gene'], ['DoTS::RNAFeature', 'Enters a row for each known gene'], ['DoTS::ExonFeature', 'Enters a row for each distinct exon in the known genes'], ['DoTS::NALocation', 'Enters a row for each metaexon, a row for each transcript and a row for each exon location'], ['DoTS:RNAFeatureExon', 'Enters a row linking each exon to each transcript it belongs to']];

  my $tablesDependedOn = [['SRes::ExternalDatabaseRelease', 'The releases of the external database identifying the UCSC known genes and the metagenes being loaded']];

  my $howToRestart = "";

  my $failureCases = "";

  my $notes = <<NOTES;

=head1 AUTHOR

Written by Elisabetta Manduchi.

=head1 COPYRIGHT

Copyright Elisabetta Manduchi, Trustees of University of Pennsylvania 2013. 
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

  $self->initialize({requiredDbVersion => 4.0,
		     cvsRevision => '$Revision: 12549 $',
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

  my $extDbRlsGenome = $self->getExtDbRlsId($self->getArg('extDbRlsSpecGenome'));
  my $extDbRlsGenes = $self->getExtDbRlsId($self->getArg('extDbRlsSpecGenes'));
  my $extDbRlsSymbols = $self->getExtDbRlsId($self->getArg('extDbRlsSpecSymbols'));
  $self->logDebug("Ext Db Rls Ids: $extDbRlsGenome, $extDbRlsGenes,$extDbRlsSymbols");
  my $chrIds = $self->getChromosomeIds($extDbRlsGenome);

  $self->logData('Inserting rnas and exons');
  my ($rnaFeatures, $exonFeatureCount, $rnaFeatureCount) = $self->insertKnownGenes($extDbRlsGenes, $chrIds);

  $self->logData('Inserting metagenes');
  my ($geneFeatureCount) = $self->insertMetagenes($extDbRlsGenes, $extDbRlsSymbols, $chrIds, $rnaFeatures);

  my $resultDescrip = "Inserted $geneFeatureCount gene features, $rnaFeatureCount rna features, $exonFeatureCount exon feature with their corresponding locations. Entries in DoTS.Gene, DoTS.GeneInstance, and DoTS.RnaFeatureExon were inserted as needed.";
  return $resultDescrip;
}

# ----------------------------------------------------------------------
# methods
# ----------------------------------------------------------------------
sub getChromosomeIds {
  my ($self, $extDbRlsGenome) = @_;
  my $chrIds;
  
  my $dbh = $self->getQueryHandle();  
  my $sth = $dbh->prepare("select na_sequence_id, source_id from DoTS.ExternalNASequence where external_database_release_id=$extDbRlsGenome");
  $sth->execute();
  while (my ($naSeqId, $sourceId) = $sth->fetchrow_array()) {
    $chrIds->{$sourceId} = $naSeqId;
  }
  
  return($chrIds);
}

sub insertKnownGenes {
  my ($self, $extDbRlsGenes, $chrIds) = @_;
  my $exons;
  my $rnas;
  my %rnaFeatures;

  my $file = $self->getArg('knownGeneFile');
  my $sa = $self->getArg('speciesAbbr');
  open(my $fh ,'<', $file);
  my $exonFeatureCount = 0;
  my $rnaFeatureCount = 0;

  my %pos;
  my $line = <$fh>;
  chomp($line);
  $line =~ s/^\#//;
  my @arr = split(/\t/, $line);
  for (my $i=0; $i<@arr; $i++) {
    $pos{$arr[$i]} = $i;
  }
  my %exonIds;
  my %done;
  while (my $line=<$fh>) {
    chomp($line);
    my @arr = split(/\t/, $line);
    my $rnaId = $arr[$pos{$sa . '.knownGene.name'}];
    if (!defined($chrIds->{$arr[$pos{$sa . '.knownGene.chrom'}]})) {
      next;
    }
    my $chrId = $chrIds->{$arr[$pos{$sa . '.knownGene.chrom'}]};
    my $isReversed = $arr[$pos{$sa . '.knownGene.strand'}] eq '+' ? 0 : 1;
    my $rnaStart = $arr[$pos{$sa . '.knownGene.txStart'}];
    my $rnaEnd = $arr[$pos{$sa . '.knownGene.txEnd'}];
    my $rnaCdsStart = $arr[$pos{$sa . '.knownGene.cdsStart'}];
    my $rnaCdsEnd = $arr[$pos{$sa . '.knownGene.cdsEnd'}];
    my $rnaFeature = GUS::Model::DoTS::RNAFeature->new({name => $rnaId, na_sequence_id => $chrId, external_database_release_id => $extDbRlsGenes, source_id => $rnaId});

    my $rnaNaLocation = GUS::Model::DoTS::NALocation->new({start_min => $rnaStart, start_max => $rnaStart, end_min => $rnaEnd, end_max => $rnaEnd, is_reversed => $isReversed}); 
    $rnaNaLocation->setParent($rnaFeature);
    
    $arr[$pos{$sa . '.knownGene.exonStarts'}] =~ s/\,$//;
    my @exonStarts = split(/,/, $arr[$pos{$sa . '.knownGene.exonStarts'}]);
    $arr[$pos{$sa . '.knownGene.exonEnds'}] =~ s/\,$//;
    my @exonEnds = split(/,/, $arr[$pos{$sa . '.knownGene.exonEnds'}]);
    for (my $i=0; $i<@exonStarts; $i++) {
      my $rnaFeatureExon;
      my $cdsStart;
      my $cdsEnd;
      if ($exonEnds[$i]>=$rnas->{$rnaId}->{'cdsStart'}) {
	$cdsStart = $exonStarts[$i]>=$rnaCdsStart ? $exonStarts[$i] : $rnaCdsStart;
      }
      if ($exonStarts[$i]<=$rnaCdsEnd) {
	$cdsEnd = $exonEnds[$i]<=$rnaCdsEnd ? $exonEnds[$i] : $rnaCdsEnd;
      }
      if (!defined($exonIds{"$chrId|$exonStarts[$i]|$exonEnds[$i]|$cdsStart|$cdsEnd"})) {
	my $exonFeature= GUS::Model::DoTS::ExonFeature->new({na_sequence_id => $chrId, name => 'UCSC known gene exon', coding_start => $cdsStart, coding_end => $cdsEnd, external_database_release_id => $extDbRlsGenes});
	my $exonNaLocation = GUS::Model::DoTS::NALocation->new({start_min => $exonStarts[$i], start_max => $exonStarts[$i], end_min => $exonEnds[$i], end_max => $exonEnds[$i]});
	$exonNaLocation->setParent($exonFeature); 	
	$exonFeature->submit();
	$exonIds{"$chrId|$exonStarts[$i]|$exonEnds[$i]|$cdsStart|$cdsEnd"} = $exonFeature->getId();
	$exonFeatureCount++;
      }
      my $orderNum = $i+1;
      $rnaFeatureExon = GUS::Model::DoTS::RNAFeatureExon->new({exon_feature_id => $exonIds{"$chrId|$exonStarts[$i]|$exonEnds[$i]|$cdsStart|$cdsEnd"}, order_number => $orderNum});
      $rnaFeatureExon->setParent($rnaFeature);
    }

    $rnaFeature->submit;
    $rnaFeatures{$rnaId} = $rnaFeature->getId();
    $rnaFeatureCount++;
    $self->undefPointerCache();
  }
  close($fh);
  return (\%rnaFeatures, $exonFeatureCount, $rnaFeatureCount);
}

sub insertMetagenes {
  my ($self, $extDbRlsGenes, $extDbRlsSymbols, $chrIds, $rnaFeatures) = @_;
  my $file = $self->getArg('metageneFile');
  my $geneFeatureCount = 0;

  open(my $fh ,'<', $file);
  
  while (my $line=<$fh>) {
    chomp($line);
    my @arr = split(/\t/, $line);
    my $geneId = $arr[7]; 
    $geneId  =~ /^([^\(]+) \((.+); (.+); /;
    my ($entrez, $symbols, $ucsc) = ($1, $2, $3);
    
    my $symbol = $symbols;

    if (!defined($symbol) || $symbol =~ /^\s*$/) {
      $symbol = $ucsc;
    }
    
    my @rnaIds = split(/,/, $ucsc);
    
    my $chrId = $chrIds->{$arr[0]};
    
    $arr[5] =~ s/\,$//;
    my @geneStarts = split(/,/, $arr[5]);
    $arr[6] =~ s/\,$//;
    my @geneEnds = split(/,/, $arr[6]); 
    
    my $isReversed;
    if ($arr[1] eq '+') {
      $isReversed = 0;
    }
    elsif ($arr[1] eq '-') {
      $isReversed = 1;
    }
    
    my $gene1 = GUS::Model::DoTS::Gene->new({gene_symbol => $symbol, external_database_release_id => $extDbRlsSymbols});
    my $gene2 = GUS::Model::DoTS::Gene->new({gene_symbol => $symbol, external_database_release_id => $extDbRlsGenes});
    my $gene;
    if ($gene1->retrieveFromDB()) {
      $gene = $gene1;
    }
    elsif ($gene2->retrieveFromDB()) {
      $gene = $gene2;
    }
    else {
      $gene = GUS::Model::DoTS::Gene->new({gene_symbol => $symbol, external_database_release_id => $extDbRlsGenes})
    }
    my $geneFeature = GUS::Model::DoTS::GeneFeature->new({name => $geneId, na_sequence_id => $chrId, external_database_release_id => $extDbRlsGenes, source_id => $geneId});
    my $geneInstance = GUS::Model::DoTS::GeneInstance->new(); 
    $geneInstance->setParent($gene);
    $geneInstance->setParent($geneFeature);
    for (my $i=0; $i<@geneStarts; $i++) {
      my $geneNaLocation = GUS::Model::DoTS::NALocation->new({start_min => $geneStarts[$i], start_max => $geneStarts[$i], end_min => $geneEnds[$i], end_max => $geneEnds[$i], is_reversed => $isReversed}); 
      $geneNaLocation->setParent($geneFeature);
      $geneFeature->addToSubmitList($geneNaLocation);
    }
    for (my $i=0; $i<@rnaIds; $i++) {
      if (defined $rnaFeatures->{$rnaIds[$i]}) {
	my $rnaFeature = GUS::Model::DoTS::RNAFeature->new({na_feature_id => $rnaFeatures->{$rnaIds[$i]}});
	$rnaFeature->retrieveFromDB();
	$rnaFeature->setParent($geneFeature);
	$geneFeature->addToSubmitList($rnaFeature);
      }
    }
    
    $gene->submit();
    $geneFeatureCount++;
    $self->undefPointerCache();
  }
  close($fh);
  return($geneFeatureCount);
}

# ----------------------------------------------------------------------
# Undo
# ----------------------------------------------------------------------

sub undoTables {
  my ($self) = @_;
  return ('DoTS.NALocation', 'DoTS.RNAFeatureExon', 'DoTS.ExonFeature', 'DoTS.RNAFeature', 'DoTS.GeneInstance', 'DoTS.GeneFeature', 'DoTS.Gene');
}


1;
