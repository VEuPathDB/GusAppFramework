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
use GUS::Model::SRes::TaxonName;

# ----------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------

sub getArgumentsDeclaration {
  my $argumentDeclaration =
    [
     fileArg({name => 'geneFile',
	      descr => 'The full path to a marker list report file from MGI with the header containing the following fields: MGI Accession ID, Symbol, Marker Type, Marker Synonyms (pipe-separated). Order is irrelevant and extra header fields will be ignored.',
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
	     })
    ];
  return $argumentDeclaration;
}

# ----------------------------------------------------------------------
# Documentation
# ----------------------------------------------------------------------


sub getDocumentation {
  my $purposeBrief = 'Loads MGI genes into DoTS.';

  my $purpose = "This plugin reads a marker list report file downloaded from MGI and populates the DoTS Gene, GeneSynonym, GeneInstance, and GeneFeature tables.";

  my $tablesAffected = [['DoTS::Gene', 'Enters a row for each MGI gene symbol, not already in the database'], ['DoTS::GeneFeature', 'Enters a row for each MGI gene in the file'], ['DoTS::GeneInstance', 'Enters rows linking each new GeneFeature to its Gene'], ['DoTS::GeneSynonym', 'Enters a row for each MGI gene synonym, not already in the database']];

  my $tablesDependedOn = [['SRes::ExternalDatabaseRelease', 'The releases of the external database identifying the MGI genes being loaded'], ['SRes::TaxonName', 'The Mus musculus entry']];

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
		     cvsRevision => '$Revision: 12639 $',
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

  my $taxonName = GUS::Model::SRes::TaxonName->new({name => 'Mus musculus'});
  if (!$taxonName->retrieveFromDB()) {
    $self->userError("Your database instance must contain a 'Mus musculus' entry in SRes.TaxonName");
  }
  my $taxonId = $taxonName->getTaxonId();  

  my ($geneCount, $geneSynonymCount, $geneInstanceCount, $geneFeatureCount) = (0, 0, 0, 0);
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
    if ($arr[$pos{'Marker Type'}] ne 'Gene') {
      next;
    }

    my $mgiId = $arr[$pos{'MGI Accession  ID'}]; 
    my $symbol = $arr[$pos{'Marker Symbol'}];
    my $name = $arr[$pos{'Marker Name'}];
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
    my $geneFeature = GUS::Model::DoTS::GeneFeature->new({name => $name, external_database_release_id => $extDbRlsId, source_id => $mgiId});
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
# Won't delete from DoTS.Gene

sub undoTables {
  my ($self) = @_;
  return ('DoTS.GeneInstance', 'DoTS.GeneFeature', 'DoTS.GeneSynonym');
}

1;
