#######################################################################
##                 InsertMouseEntrezGenes.pm
## $Id: InsertEntrezGenes.pm  manduchi $
##
#######################################################################
 
package GUS::Community::Plugin::InsertMouseEntrezGenes;
@ISA = qw( GUS::PluginMgr::Plugin );

use strict;
use GUS::PluginMgr::Plugin;
use GUS::Model::DoTS::Gene;
use GUS::Model::DoTS::GeneSynonym;
use GUS::Model::DoTS::GeneInstance;
use GUS::Model::DoTS::GeneFeature;
use GUS::Model::SRes::TaxonName;

# ----------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------

sub getArgumentsDeclaration {
  my $argumentDeclaration =
    [
     fileArg({name => 'geneFile',
	      descr => 'The full path to a gene_info file from NCBI.',
	      constraintFunc=> undef,
	      reqd  => 1,
	      isList => 0,
	      mustExist => 1,
	      format => ''
	     }),
     stringArg({ name  => 'extDbRlsSpec',
		 descr => "The ExternalDBRelease specifier for the Entrez Gene release to which --geneFile corresponds. Must be in the format 'name|version', where the name must match a name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
		 constraintFunc => undef,
		 reqd           => 1,
		 isList         => 0 
	     }),
     stringArg({ name  => 'extDbRlsMgiSpec',
		 descr => "The ExternalDBRelease specifier for the MGI release these entries should be linked to. Must be in the format 'name|version', where the name must match a name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
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
  my $purposeBrief = 'Loads Entrez genes into DoTS.';

  my $purpose = "This plugin reads a gene_info file downloaded from NCBI and populates the DoTS Gene, GeneSynonym, GeneInstance, and GeneFeature tables.";

  my $tablesAffected = [['DoTS::Gene', 'Enters a row for each Entrez gene symbol, not already in the database from MGI'], ['DoTS::GeneFeature', 'Enters a row for each Entrez gene in the file'], ['DoTS::GeneInstance', 'Enters rows linking each new GeneFeature to its Gene'], ['DoTS::GeneSynonym', 'Enters a row for each Entrez gene synonym, not already in the database from MGI']];

  my $tablesDependedOn = [['SRes::ExternalDatabaseRelease', 'The releases of the external database identifying the Entrez genes being loaded'], ['SRes::TaxonName', 'The species the genes refer to'], ['DoTS::GeneFeature', 'To check for additional DB presence']];

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
		     cvsRevision => '$Revision: 12660 $',
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

  my ($geneCount, $geneSynonymCount, $geneInstanceCount, $geneFeatureCount) = $self->insertGenes();

  my $resultDescrip = "Inserted $geneCount entries in DoTS.Gene, $geneSynonymCount in DoTS.GeneSynonym, $geneInstanceCount entries in DoTS.GeneInstance, and $geneFeatureCount entries in DoTS.GeneFeature.";
  return $resultDescrip;
}

# ----------------------------------------------------------------------
# methods
# ----------------------------------------------------------------------

sub insertGenes {
  my ($self) = @_;
  my $file = $self->getArg('geneFile');
  my $extDbRlsId = $self->getExtDbRlsId($self->getArg('extDbRlsSpec'));
  my $extDbRlsIdMgi = $self->getExtDbRlsId($self->getArg('extDbRlsMgiSpec'));

  my $taxonName = GUS::Model::SRes::TaxonName->new({name => 'Mus musculus'});
  if (!$taxonName->retrieveFromDB()) {
    $self->userError("Your database instance must contain a Mus musculus entry in SRes.TaxonName");
  }
  my $taxonId = $taxonName->getTaxonId();  

  my ($geneCount, $geneSynonymCount, $geneInstanceCount, $geneFeatureCount) = (0, 0, 0, 0);
  my $lineCount = 0;

  open(my $fh ,'<', $file);
  my $line = <$fh>;  
  while (my $line=<$fh>) {
    $lineCount++;
    if ($lineCount % 1000 ==0) {
      $self->logData("Read $lineCount lines from $file");
    }
    chomp($line);
    my @arr = split(/\t/, $line);
    
    my $entrezId = $arr[1]; 
    my $symbol = $arr[2];
    if (!defined($symbol) || $symbol =~ /^\s*$/) {
      $symbol = 'Entrez Gene: $entrezId';
    }
    my @synonyms = split(/\|/, $arr[4]);
    my $mgiId = split(/\|/, $arr[5]);
    $mgiId =~ /(MGI\:\d+)\|/;
    $mgiId = $1;
    my $mgiFeature;
    my $gene = GUS::Model::DoTS::Gene->new({gene_symbol => $symbol, taxon_id => $taxonId});
    if (defined $mgiId && $mgiId !~ /^\s*$/) {
      $mgiFeature = GUS::Model::DoTS::NAFeature->new({external_database_release_id => $extDbRlsIdMgi, source_id => $mgiId});
    }
    my $geneId;
    if (!$gene->retrieveFromDB() && !$mgiFeature->retrieveFromDB()) {
      $geneCount++;
      $gene->set('external_database_release_id', $extDbRlsId);
    }
    elsif ($mgiFeature->retrieveFromDB()) {
      my $oldGeneInstance = GUS::Model::DoTS::GeneInstance->new({na_feature_id => $mgiFeature->getId()});
      $oldGeneInstance->retrieveFromDB();
      my $mgiGene = GUS::Model::DoTS::Gene->new({gene_id => $oldGeneInstance->getGeneId()});     
      if ($mgiGene->retrieveFromDB()) {
	$gene = $mgiGene;
      }
      else {
	$geneCount++;
	$gene->set('external_database_release_id', $extDbRlsId);
      }
    }
    else {
      $geneId = $gene->getId();
    }
    
    my %visited;
    for (my $i=0; $i<@synonyms; $i++) {
      if ($synonyms[$i] eq 'now' || $synonyms[$i] eq 'NOW' || $visited{$synonyms[$i]}) {
	next;
      }
      $visited{$synonyms[$i]} = 1;
      my $geneSynonym = GUS::Model::DoTS::GeneSynonym->new({synonym_name => $synonyms[$i]});
      $geneSynonym->setParent($gene);
      if (defined $geneId) {
	$geneSynonym->setGeneId($geneId);
      }
      if (!$geneSynonym->retrieveFromDB()) {
	$geneSynonymCount++;
      }
    }
    my $geneFeature = GUS::Model::DoTS::GeneFeature->new({name => "Entrez Gene: $entrezId", external_database_release_id => $extDbRlsId, source_id => $entrezId});
    my $geneInstance = GUS::Model::DoTS::GeneInstance->new(); 
    $geneInstance->setParent($gene);
    $geneInstance->setParent($geneFeature);
    $gene->submit();
    $geneInstanceCount++;
    $geneFeatureCount++;
    $self->undefPointerCache();
  } 
  close($fh);
  
  return($geneCount, $geneSynonymCount, $geneInstanceCount, $geneFeatureCount);
}

# ----------------------------------------------------------------------
# Undo
# ----------------------------------------------------------------------
sub undoTables {
  my ($self) = @_;
  return ('DoTS.GeneInstance', 'DoTS.GeneFeature', 'DoTS.GeneSynonym', 'DoTS.Gene');
}

1;
