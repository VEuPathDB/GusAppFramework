#######################################################################
##                 InsertMgiGenes.pm
## $Id: InsertMgiGenes.pm  manduchi $
##
#######################################################################
 
package GUS::Community::Plugin::InsertMgiGenes;
@ISA = qw( GUS::PluginMgr::Plugin );

use strict;
use GUS::PluginMgr::Plugin;
use GUS::Model::DoTS::Gene;
use GUS::Model::DoTS::GeneSynonym;
use GUS::Model::DoTS::GeneInstance;
use GUS::Model::DoTS::GeneFeature;
use GUS::Model::DoTS::NALocation;
use GUS::Model::SRes::TaxonName;

# ----------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------

sub getArgumentsDeclaration {
  my $argumentDeclaration =
    [
     fileArg({name => 'geneFile',
	      descr => 'The full path to a marker list report file from MGI with the header containing the following fields: MGI Accession ID, Chr, genome coordinate start, genome coordinate end, strand, Symbol, Marker Type, Marker Synonyms (pipe-separated). Order is irrelevant and extra header fields will be ignored.',
	      constraintFunc=> undef,
	      reqd  => 1,
	      isList => 0,
	      mustExist => 1,
	      format => ''
	     }),
     stringArg({ name  => 'extDbRlsSpec',
		 descr => "The ExternalDBRelease specifier for the MGI release to which --geneFile corresponds. Must be in the format 'name|version', where the name must match a name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
		 constraintFunc => undef,
		 reqd           => 1,
		 isList         => 0 
	     }),
     stringArg({ name  => 'extDbRlsSpecGenome',
		 descr => "The ExternalDBRelease specifier for the genome the gene coordinates refer to. Must be in the format 'name|version', where the name must match a name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
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
  my $purposeBrief = 'Loads MGI genes into DoTS.';

  my $purpose = "This plugin reads a marker list report file downloaded from MGI and populates the DoTS Gene, GeneSynonym, GeneInstance, GeneFeature, and NALocation tables.";

  my $tablesAffected = [['DoTS::Gene', 'Enters a row for each MGI gene symbol, not already in the database for mouse'], ['DoTS::GeneFeature', 'Enters a row for each MGI gene in the file'], ['DoTS::NALocation', 'Enters a row for each MGI gene in the file for which coordinates are available'], ['DoTS::GeneInstance', 'Enters rows linking each new GeneFeature to its Gene'], ['DoTS::GeneSynonym', 'Enters a row for each MGI gene synonym, not already in the database for mouse']];

  my $tablesDependedOn = [['SRes::ExternalDatabaseRelease', 'The releases of the external database identifying the MGI genes being loaded and the one for the genome build the coordinates refer to'], ['SRes::TaxonName', 'The Mus musculus entry']];

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
		     cvsRevision => '$Revision: 12648 $',
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

  my $chrIds = $self->getChromosomeIds();
  my ($geneCount, $geneSynonymCount, $geneInstanceCount, $geneFeatureCount, $naLocationCount) = $self->insertGenes($chrIds);

  my $resultDescrip = "Inserted $geneCount entries in DoTS.Gene, $geneSynonymCount in DoTS.GeneSynonym, $geneInstanceCount entries in DoTS.GeneInstance, $geneFeatureCount entries in DoTS.GeneFeature, and $naLocationCount entries in DoTS.NALocation.";
  return $resultDescrip;
}

# ----------------------------------------------------------------------
# methods
# ----------------------------------------------------------------------
sub getChromosomeIds {
  my ($self) = @_;
  my $extDbRlsGenome = $self->getExtDbRlsId($self->getArg('extDbRlsSpecGenome'));
  my $chrIds;
  
  my $dbh = $self->getQueryHandle();  
  my $sth = $dbh->prepare("select na_sequence_id, source_id from DoTS.ExternalNASequence where external_database_release_id=$extDbRlsGenome");
  $sth->execute();
  while (my ($naSeqId, $sourceId) = $sth->fetchrow_array()) {
    $chrIds->{$sourceId} = $naSeqId;
  }
  
  return($chrIds);
}

sub insertGenes {
  my ($self, $chrIds) = @_;
  my $file = $self->getArg('geneFile');
  my $extDbRlsId = $self->getExtDbRlsId($self->getArg('extDbRlsSpec'));
  
  my $taxonName = GUS::Model::SRes::TaxonName->new({name => 'Mus musculus'});
  if (!$taxonName->retrieveFromDB()) {
    $self->userError("Your database instance must contain a 'Mus musculus' entry in SRes.TaxonName");
  }
  my $taxonId = $taxonName->getTaxonId();  
  
  my ($geneCount, $geneSynonymCount, $geneInstanceCount, $geneFeatureCount, $naLocationCount) = (0, 0, 0, 0, 0);
  my $lineCount = 0;
  open(my $fh ,'<', $file);
  my %pos;
  my $line = <$fh>;
  chomp($line);
  my @arr = split(/\t/, $line);
  for (my $i=0; $i<@arr; $i++) {
    $pos{$arr[$i]} = $i;
  }
  
  while (my $line=<$fh>) {
    $lineCount++;
    if ($lineCount % 1000 ==0) {
      $self->logData("Read $lineCount lines from $file");
    }
    chomp($line);
    my @arr = split(/\t/, $line);
    if ($arr[$pos{'Marker Type'}] ne 'Gene' && $arr[$pos{'Marker Type'}] ne 'Pseudogene' && $arr[$pos{'Marker Type'}] ne 'Complex/Cluster/Region') {
      next;
    }
    
    my $mgiId = $arr[$pos{'MGI Accession  ID'}]; 
    my $symbol = $arr[$pos{'Marker Symbol'}];
    my $name = $arr[$pos{'Marker Name'}];
    my $chrId = $chrIds->{$arr[$pos{'Chr'}]};
    my $start = $arr[$pos{'genome coordinate start'}];
    my $end = $arr[$pos{'genome coordinate end'}];
    my $isReversed = $arr[$pos{'strand'}] eq '+' ? 0 : 1;;
    if (!defined($symbol) || $symbol =~ /^\s*$/) {
      $symbol = $mgiId;
    }
    my @synonyms = split(/\|/, $arr[$pos{'Marker Synonyms (pipe-separated)'}]);
    
    my $gene = GUS::Model::DoTS::Gene->new({gene_symbol => $symbol, taxon_id => $taxonId});
    if (!$gene->retrieveFromDB()) {
      $geneCount++;
    }
    $gene->set('external_database_release_id', $extDbRlsId);
    for (my $i=0; $i<@synonyms; $i++) {
      if ($synonyms[$i] eq 'now' || $synonyms[$i] eq 'NOW') {
	next;
      }
      my $geneSynonym = GUS::Model::DoTS::GeneSynonym->new({synonym_name => $synonyms[$i]});
      $geneSynonym->setParent($gene);
      if (!$geneSynonym->retrieveFromDB()) {
	$geneSynonymCount++;
      }
    }
    my $geneFeature = GUS::Model::DoTS::GeneFeature->new({name => $name,  na_sequence_id => $chrId, external_database_release_id => $extDbRlsId, source_id => $mgiId});
    my $naLocation = GUS::Model::DoTS::NALocation->new({start_min => $start, start_max => $start, end_min => $end, end_max => $end, is_reversed => $isReversed}); 
    $naLocation->setParent($geneFeature);
    $geneFeature->addToSubmitList($naLocation);
    my $geneInstance = GUS::Model::DoTS::GeneInstance->new(); 
    $geneInstance->setParent($gene);
    $geneInstance->setParent($geneFeature);
    $gene->submit();
    $geneInstanceCount++;
    $geneFeatureCount++;
    $naLocationCount++;
    $self->undefPointerCache();
  } 
  close($fh);
  
  return($geneCount, $geneSynonymCount, $geneInstanceCount, $geneFeatureCount);
}

# ----------------------------------------------------------------------
# Undo
# ----------------------------------------------------------------------
# Won't delete from DoTS.Gene

sub undoTables {
  my ($self) = @_;
  return ('DoTS.GeneInstance', 'DoTS.NALocation', 'DoTS.GeneFeature', 'DoTS.GeneSynonym');
}

1;
