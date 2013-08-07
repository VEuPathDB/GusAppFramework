#######################################################################
##                 InsertEntrezGenes.pm
## $Id: InsertEntrezGenes.pm  manduchi $
##
#######################################################################
 
package GUS::Community::Plugin::InsertEntrezGenes;
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
     stringArg({ name  => 'species',
		 descr => 'The scientific name name of the species the genes refer to',
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

  my $tablesAffected = [['DoTS::Gene', 'Enters a row for each Entrez gene symbol, not already in the database for --species'], ['DoTS::GeneFeature', 'Enters a row for each Entrez gene in the file'], ['DoTS::GeneInstance', 'Enters rows linking each new GeneFeature to its Gene'], ['DoTS::GeneSynonym', 'Enters a row for each Entrez gene synonym, not already in the database for --species']];

  my $tablesDependedOn = [['SRes::ExternalDatabaseRelease', 'The releases of the external database identifying the Entrez genes being loaded'], ['SRes::TaxonName', 'The species the genes refer to']];

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
		     cvsRevision => '$Revision:  $',
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
  my $species = $self->getArg('species');

  my $taxonName = GUS::Model::SRes::TaxonName->new({name => $species});
  if (!$taxonName->retrieveFromDB()) {
    $self->userError("Your database instance must contain a '$species' entry in SRes.TaxonName");
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

    my $gene = GUS::Model::DoTS::Gene->new({gene_symbol => $symbol, taxon_id => $taxonId});
    if (!$gene->retrieveFromDB()) {
      $geneCount++;
      $gene->set('external_database_release_id', $extDbRlsId);
    }
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
    my $geneFeature = GUS::Model::DoTS::GeneFeature->new({external_database_release_id => $extDbRlsId, source_id => $entrezId});
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
