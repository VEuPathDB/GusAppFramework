#######################################################################
##                 InsertEnsemblGenes.pm
## $Id: InsertEnsemblGenes.pm  manduchi $
##
#######################################################################
 
package GUS::Community::Plugin::InsertEnsemblGenes;
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
     fileArg({name => 'geneFile',
	      descr => 'The full path to a tab-delimited file as generated from Ensembl Biomart with the following fields in the header: Ensembl Gene ID, Ensembl Transcript ID, Chromosome Name, Gene Start (bp), Gene End (bp), Strand, Transcript Start (bp), Transcript End (bp), <some symbol header, e.g. HGNC symbol> (order is irrelevant and extra header fields will be ignored).',
	      constraintFunc=> undef,
	      reqd  => 1,
	      isList => 0,
	      mustExist => 1,
	      format => ''
	     }),
     fileArg({name => 'exonFile',
	      descr => 'The full path to a tab-delimited file as generated from Ensambl Biomart with the following fields in the header: Ensembl Transcript ID, Exon Chr Start (bp), Exon Chr End (bp), CDS Start, CDS End, Chromosome Name, Exon Rank in Transcript (order is irrelevant and extra header fields will be ignored).',
	      constraintFunc=> undef,
	      reqd  => 1,
	      isList => 0,
	      mustExist => 1,
	      format => ''
	     }),
     stringArg({ name  => 'extDbRlsSpecGenome',
		 descr => "The ExternalDBRelease specifier for the genome the gene coordinates refer to. Must be in the format 'name|version', where the name must match a name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
		 constraintFunc => undef,
		 reqd           => 1,
		 isList         => 0 
	     }),
     stringArg({ name  => 'extDbRlsSpecGenes',
		 descr => "The ExternalDBRelease specifier for these Ensembl genes. Must be in the format 'name|version', where the name must match a name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
		 constraintFunc => undef,
		 reqd           => 1,
		 isList         => 0 
	     }),
     stringArg({ name  => 'symbolHeader',
		 descr => 'The name of the header in the gene file corresponding to gene symbols',
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
  my $purposeBrief = 'Loads data from two Ensembl Biomart gene and exon files into DoTS.';

  my $purpose = "This plugin reads files downloaded from Ensembl Biomart and populates DoTS Gene tables.";

  my $tablesAffected = [['DoTS::Gene', 'Enters a row for each gene symbol in the file and for each Ensembl Gene without a symbol'], ['DoTS::GeneFeature', 'Enters a row for each Ensembl gene in the gene file'], ['DoTS::GeneInstance', 'Enters rows linking each new GeneFeature to its Gene'], ['DoTS::RNAFeature', 'Enters a row for each Ensembl transcript in the gene file'], ['DoTS::ExonFeature', 'Enters a row for each distinct exon in the exon file'], ['DoTS::NALocation', 'Enters a row for each gene, a row for each transcript and a row for each exon location'], ['DoTS:RNAFeatureExon', 'Enters a row linking each exon to each transcript it belongs to']];

  my $tablesDependedOn = [['SRes::ExternalDatabaseRelease', 'The releases of the external database identifying the Ensembl genome and the Ensembl genes being loaded']];

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
		     cvsRevision => '$Revision: 11600 $',
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
  $self->logDebug("Ext Db Rls Ids: $extDbRlsGenome, $extDbRlsGenes");

  my $chrIds = $self->getChromosomeIds($extDbRlsGenome);
  $self->logData('Inserting the exons');
  
  my ($exons, $exonFeatureCount) = $self->insertExons($extDbRlsGenes, $chrIds);

  $self->logData('Inserting the genes');
  my ($geneFeatureCount, $rnaFeatureCount) = $self->insertGenes($extDbRlsGenes, $chrIds, $exons);

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

sub insertExons {
  my ($self, $extDbRlsGenes, $chrIds) = @_;
  my $exons;
  my $file = $self->getArg('exonFile');
  open(my $fh ,'<', $file);
  my $count = 0;
  my %done;

  my %pos;
  my $line = <$fh>;
  chomp($line);
  my @arr = split(/\t/, $line);
  for (my $i=0; $i<@arr; $i++) {
    $pos{$arr[$i]} = $i;
  }
  my %exonIds;
  while (my $line=<$fh>) {
    chomp($line);
    my @arr = split(/\t/, $line);
    my $rnaId = $arr[$pos{'Ensembl Transcript ID'}];
    if (!defined($chrIds->{$arr[$pos{'Chromosome Name'}]})) {
      next;
    }
    my $chrId = $chrIds->{$arr[$pos{'Chromosome Name'}]};
    my $exonStart = $arr[$pos{'Exon Chr Start (bp)'}];
    my $exonEnd = $arr[$pos{'Exon Chr End (bp)'}];
    my $cdsStart = $arr[$pos{'CDS Start'}];
    my $cdsEnd = $arr[$pos{'CDS End'}];
    my $orderNum = $arr[$pos{'Exon Rank in Transcript'}];
    
    if (!defined($exonIds{"$chrId|$exonStart|$exonEnd|$cdsStart|$cdsEnd"})) {
      my $exonFeature= GUS::Model::DoTS::ExonFeature->new({na_sequence_id => $chrId, name => 'Ensembl exon', coding_start => $cdsStart, coding_end => $cdsEnd, external_database_release_id => $extDbRlsGenes});
      my $exonNaLocation = GUS::Model::DoTS::NALocation->new({start_min => $exonStart, start_max => $exonStart, end_min => $exonEnd, end_max => $exonEnd});
      $exonNaLocation->setParent($exonFeature); 
    
      $exonFeature->submit();
      $exonIds{"$chrId|$exonStart|$exonEnd|$cdsStart|$cdsEnd"} = $exonFeature->getId();
      $count++;
    }
    push(@{$exons->{$rnaId}}, $exonIds{"$chrId|$exonStart|$exonEnd|$cdsStart|$cdsEnd"} . "|" .$orderNum);
    $self->undefPointerCache();
  }
  close($fh);
  return($exons, $count);
}

sub insertGenes {
  my ($self, $extDbRlsGenes, $chrIds, $exons) = @_;
  my $file = $self->getArg('geneFile');
  my ($geneFeatureCount, $rnaFeatureCount) = (0,0,0);

  open(my $fh ,'<', $file);
  my %pos;
  my $symbolHeader = $self->getArg('symbolHeader');

  my $line = <$fh>;
  chomp($line);
  my @arr = split(/\t/, $line);
  for (my $i=0; $i<@arr; $i++) {
    $pos{$arr[$i]} = $i;
  }
  
  while (my $line=<$fh>) {
    chomp($line);
    my @arr = split(/\t/, $line);
    my $geneId = $arr[$pos{'Ensembl Gene ID'}]; 
    my $rnaId = $arr[$pos{'Ensembl Transcript ID'}]; 
    if (!defined($chrIds->{$arr[$pos{'Chromosome Name'}]})) {
      next;
    }
    my $chrId = $chrIds->{$arr[$pos{'Chromosome Name'}]};
    my $geneStart = $arr[$pos{'Gene Start (bp)'}]; 
    my $geneEnd = $arr[$pos{'Gene End (bp)'}]; 
    my $rnaStart = $arr[$pos{'Transcript Start (bp)'}]; 
    my $rnaEnd = $arr[$pos{'Transcript End (bp)'}]; 
    my $symbol = $arr[$pos{$symbolHeader}];
    if (!defined($symbol) || $symbol =~ /^\s*$/) {
      $symbol = $geneId;
    }
    my $isReversed = $arr[$pos{'Strand'}]==1 ? 0 : 1;

    my $gene = GUS::Model::DoTS::Gene->new({gene_symbol => $symbol, external_database_release_id => $extDbRlsGenes});
    $gene->retrieveFromDB();
    my $geneFeature = GUS::Model::DoTS::GeneFeature->new({name => $geneId, na_sequence_id => $chrId, external_database_release_id => $extDbRlsGenes, source_id => $geneId});
    my $geneInstance = GUS::Model::DoTS::GeneInstance->new(); 
    $geneInstance->setParent($gene);
    $geneInstance->setParent($geneFeature);
    my $geneNaLocation = GUS::Model::DoTS::NALocation->new({start_min => $geneStart, start_max => $geneStart, end_min => $geneEnd, end_max => $geneEnd, is_reversed => $isReversed}); 
    $geneNaLocation->setParent($geneFeature);
    $geneFeature->addToSubmitList($geneNaLocation);
    my $rnaFeature = GUS::Model::DoTS::RNAFeature->new({name => $rnaId, na_sequence_id => $chrId, external_database_release_id => $extDbRlsGenes, source_id => $rnaId});
    $rnaFeature->setParent($geneFeature);
    $geneFeature->addToSubmitList($rnaFeature);

    my $rnaNaLocation = GUS::Model::DoTS::NALocation->new({start_min => $rnaStart, start_max => $rnaStart, end_min => $rnaEnd, end_max => $rnaEnd, is_reversed => $isReversed}); 
    $rnaNaLocation->setParent($rnaFeature);
    my $exonId;
    my $orderNum;

    for (my $i=0; $i<@{$exons->{$rnaId}}; $i++) {
      ($exonId, $orderNum) = split(/\|/, $exons->{$rnaId}->[$i]);
      
      my $rnaFeatureExon = GUS::Model::DoTS::RNAFeatureExon->new({exon_feature_id => $exonId, order_number => $orderNum});
      $rnaFeatureExon->setParent($rnaFeature);
    }
    $gene->submit();
    $geneFeatureCount++;
    $rnaFeatureCount++;
    $self->undefPointerCache();
  } 
  close($fh);
 
  return($geneFeatureCount, $rnaFeatureCount);
}

# ----------------------------------------------------------------------
# Undo
# ----------------------------------------------------------------------

sub undoTables {
  my ($self) = @_;
  return ('DoTS.NALocation', 'DoTS.RNAFeatureExon', 'DoTS.ExonFeature', 'DoTS.RNAFeature', 'DoTS.GeneInstance', 'DoTS.GeneFeature', 'DoTS.Gene');
}


1;
