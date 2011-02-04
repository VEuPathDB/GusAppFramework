##
## UpdateGeneInfo Plugin
## $Id: $
##

package GUS::Community::Plugin::UpdateGeneInfo;
@ISA = qw( GUS::PluginMgr::Plugin );

use strict;
use IO::File;
use Data::Dumper;
use GUS::PluginMgr::Plugin;

use GUS::Model::DoTS::Gene;
use GUS::Model::DoTS::GeneSynonym;
use GUS::Model::DoTS::GeneCategory;

# -----------------------------_---------------------------------------
# Arguments
# ---------------------------------------------------------------------

sub getArgumentsDeclaration {
  my $argumentDeclaration  =
    [
     fileArg({name => 'geneInfoFile',
	      descr => 'The full path of the Taxon.gene_info file downloaded from NCBI.',
	      constraintFunc=> undef,
	      reqd  => 1,
	      isList => 0,
	      mustExist => 1,
	      format => ''
	     }),
     stringArg({name  => 'taxon',
		 descr => 'The scientific name of the taxon in the Taxon.gene_info file.',
		 constraintFunc=> undef,
		 reqd  => 1,
		 isList => 0
		}),
     stringArg({ name  => 'oldExtDbRlsSpec',
		  descr => "The ExternalDBRelease specifier for the PREVIOUS release of the Taxon.gene_info file. Must be in the format 'name|version', where the name must match a name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
		  constraintFunc => undef,
		  reqd           => 1,
		  isList         => 0 }),
     stringArg({ name  => 'newExtDbRlsVer',
		  descr => "The ExternalDBRelease version for this Taxon.gene_info file.",
		  constraintFunc => undef,
		  reqd           => 1,
		  isList         => 0 }),
     stringArg({ name  => 'soVersion',
		  descr => "The version of SO to be used.",
		  constraintFunc => undef,
		  reqd           => 1,
	       	  isList         => 0 }),
     fileArg({name => 'soMappingFile',
	      descr => "The full path to a property file mapping Entrez Genes types of genes in the Taxon.gene_info file to SRes.SequenceOntology.term_name for the SO version specified by --soVersion. Use 'NA' if no mapping.",
	      constraintFunc=> undef,
	      reqd  => 1,
	      isList => 0,
	      mustExist => 1,
	      format => ''
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
  my $purposeBrief = 'Updates data in DoTS Gene, DoTS.GeneSynonym, and DoTS.GeneCategory according to a new release of an NCBI taxon gene_info file.';

  my $purpose = "This plugin reads a Taxon.gene_info file from NCBI Entrez Gene and updates DoTS Gene, DoTS.GeneSynonym, and DoTS.GeneCategory. More precisely, existing entries are updated or deprecated and new entries are added.";

  my $tablesAffected = [['DoTS::Gene', 'Updates or enters a row for each gene in the file'], ['DoTS::GeneSynomym', 'Updates or enters rows linking each entered Gene to its Synonyms'], ['DoTS::GeneCategory', 'Enters values from type_of_gene, if not already present in this table']];

  my $tablesDependedOn = [['SRes::ExternalDatabaseRelease', 'The release of the Taxon Entrez Gene external database for the previous version of the taxon gene_info file'], ['SRes::SequenceOntology', 'The terms corresponding to types of gene'], ['SRes::TaxonName', 'The taxon for the gene_info being updated']];

  my $howToRestart = "";

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
		     cvsRevision => '$Revision: 9067 $',
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
  my $dbh = $self->getQueryHandle();
  my %soMapping = %{$self->getSoMapping($dbh, $self->getArg('soVersion'), $self->getArg('soMappingFile'))};

  my $geneCategoryIds;
  ($resultDescrip, $geneCategoryIds) = $self->insertGeneCategory(\%soMapping);

  my $taxonId = $self->getTaxonId($dbh, $self->getArg('taxon'));
  my $extDbRls = $self->getExtDbRlsId($self->getArg('oldExtDbRlsSpec'));
  my $newExtDbRlsVer = $self->getArg('newExtDbRlsVer');

  $resultDescrip .= $self->processGene($dbh, $taxonId, $extDbRls, $geneCategoryIds, \%soMapping, $self->getArg('geneInfoFile'));

  my $sth = $dbh->prepare("Update Sres.ExternalDatabaseRelease set version='$newExtDbRlsVer' where external_database_release_id=$extDbRls");
  $sth->execute();
  if ($self->getArg('commit')) {
    $dbh->commit();
  }
  $resultDescrip .= "Updated the version of the external database release.";
#  $resultDescrip .= $self->cleanRedundancies($dbh, $extDbRls);
  $self->setResultDescr($resultDescrip);
  $self->logData($resultDescrip);
}

# ----------------------------------------------------------------------
# methods called by run
# ----------------------------------------------------------------------

sub getSoMapping {
  my ($self, $dbh, $soVersion, $file) = @_;
  my %soMapping;
  
  my $sth = $dbh->prepare("select sequence_ontology_id from SRes.SequenceOntology where so_version='$soVersion' and term_name=?") || die $dbh->errstr;
  my $fh = IO::File->new("<$file") || $self->userError("Cannot open file $file.");
  while (my $line=<$fh>) {
    chomp($line);
    if ($line =~ /^\s*$/) {
      next;
    }
    else {
      my ($type, $so) = split(/=/, $line);
      if ($so eq 'NA') {
	$soMapping{$type} = $so;
      }
      else {
	$sth->execute($so)  || die $dbh->errstr;
	my ($soId) = $sth->fetchrow_array();
	$sth->finish();
	$soMapping{$type} = $soId;
      }
    }
  }
  $fh->close();
  
  return(\%soMapping);
}

sub getTaxonId {
  my ($self, $dbh, $taxonName) = @_;
  my $taxonId;
  
  $taxonName =~ tr/A-Z/a-z/;
  my $sth =$dbh->prepare("select taxon_id from SRes.TaxonName where name_class='scientific name' and lower(name)='$taxonName'")  || die $dbh->errstr;
  $sth->execute() || die $dbh->errstr ;
  my ($taxonId) = $sth->fetchrow_array();
  if (!$taxonId) {
    $self->userError("Scientific name provided doesn't exist in SRes.TaxonName");
  }
  else {
    return($taxonId);
  }
}

sub insertGeneCategory {
  my ($self, $soMapping) = @_;
  my $resultDescrip = '';
  my $geneCategoryIds;
  my $count = 0;
  
  foreach my $term (keys %{$soMapping}) {
    my $geneCategory = GUS::Model::DoTS::GeneCategory->new({term => $term});
    if (!$geneCategory->retrieveFromDB()) {
      $geneCategory->submit();
      $count++;
    }
    $geneCategoryIds->{$term} = $geneCategory->getId();
  }
  $resultDescrip .= "Entered $count rows in DoTS.GeneCategory. ";
  return ($resultDescrip, $geneCategoryIds);
}

sub processGene {
  my ($self, $dbh, $taxonId, $extDbRls, $geneCategoryIds, $soMapping, $file) = @_;
  my $resultDescrip = '';
  my $countUpdatedGenes = 0;
  my $countInsertedGenes = 0;
  my $countInsertedGeneSynonyms = 0;
  my $countDeprecatedGenes = 0;
  my $countDeprecatedGeneSynonyms = 0;
  my $countReinstatedGeneSynonyms = 0;
  my $lineNum = 0;
  my $endLine;
  if (defined $self->getArg('testnum')) {
    $endLine = $self->getArg('testnum');
  }
  my %isProcessedGene;
  
  my $fh = IO::File->new("<$file")  || $self->userError("Cannot open file $file.");
  
  my %headerPos;
  $headerPos{'sourceId'} = 1;
  $headerPos{'symbol'} = 2;
  $headerPos{'synonyms'} = 4;
  $headerPos{'description'} = 8;
  $headerPos{'geneCategory'} = 9;
  $headerPos{'name'} = 11;
  
  while (my $line=<$fh>) {
    $lineNum++;
    if (defined $endLine && $lineNum>$endLine) {
      last;
    }
    if ($lineNum % 500 == 0) {
      $self->log("Processing data from the $lineNum-th line.");
    }
    chomp($line);
    my @arr = split(/\t/, $line);
    $isProcessedGene{$arr[$headerPos{'sourceId'}]} = 1;
    my $gene= GUS::Model::DoTS::Gene->new({external_database_release_id => $extDbRls, source_id => $arr[$headerPos{'sourceId'}], taxon_id => $taxonId});
    my $isOldGene = $gene->retrieveFromDB();
    my @oldSynonyms;
    if ($isOldGene) {
      @oldSynonyms = $gene->getChildren("DoTS::GeneSynonym", 1);
    }
    
    my %isProcessedSynonym;
    my @synonyms = split(/\|/, $arr[ $headerPos{'synonyms'}]);
    for (my $i=0; $i<@synonyms; $i++) {
      $isProcessedSynonym{$synonyms[$i]} = 1;
      my $isOldSynonym = 0;
      if ($synonyms[$i] ne '-' && $synonyms[$i] ne 'null'){
	for (my $j=0; $j<@oldSynonyms; $j++) {
	  if ($synonyms[$i] eq $oldSynonyms[$j]->get('synonym_name')) {
	    $isOldSynonym = 1;
	    last;
	  }
	}
	if (!$isOldSynonym) {
	  $countInsertedGeneSynonyms++;
	  my $geneSynonym= GUS::Model::DoTS::GeneSynonym->new({synonym_name => $synonyms[$i]});
	  $gene->addChild($geneSynonym); 
	}
      }
    }
    $gene->set('gene_symbol', $arr[$headerPos{'symbol'}]);
    if ($soMapping->{$arr[$headerPos{'geneCategory'}]} ne 'NA') {
      $gene->set('sequence_ontology_id', $soMapping->{$arr[$headerPos{'geneCategory'}]});
    }
#    if ($arr[$headerPos{'name'}] ne '-'){
      $gene->set('name', $arr[$headerPos{'name'}]);
#    }
#    if ($arr[$headerPos{'description'}] ne '-'){
      $gene->set('description', $arr[$headerPos{'description'}]);
#    }
    if ($arr[$headerPos{'geneCategory'}] ne '-'){
      $gene->set('gene_category_id', $geneCategoryIds->{$arr[$headerPos{'geneCategory'}]},);
    }
    
    for (my $i=0; $i<@oldSynonyms; $i++) {
      my $synonym = $oldSynonyms[$i]->get('synonym_name');
      if (!$isProcessedSynonym{$synonym}) {
	$oldSynonyms[$i]->set('is_obsolete', 1);
	$self->logDebug($oldSynonyms[$i]->toString() . "\n");
	$countDeprecatedGeneSynonyms++;
      }
      elsif($oldSynonyms[$i]->get('is_obsolete')==1) {
	$oldSynonyms[$i]->set('is_obsolete', 0);
	$countReinstatedGeneSynonyms++;
      }
      else {}
    }
    $gene->setGlobalNoVersion(1);
    $gene->submit();
    if ($isOldGene) {
      $countUpdatedGenes++;
    }
    else {
      $countInsertedGenes++;
    }
    $self->logDebug($gene->toString() . "\n");
    $self->undefPointerCache();
  }
  $fh->close();
  my $sth = $dbh->prepare("select distinct source_id from DoTS.Gene where external_database_release_id=$extDbRls");
  $sth->execute();
  while (my ($sourceId)=$sth->fetchrow_array()) {
    if (!$isProcessedGene{$sourceId} && !$self->getArg('testnum')) {
      my $gene= GUS::Model::DoTS::Gene->new({external_database_release_id => $extDbRls, source_id => $sourceId, taxon_id => $taxonId}); 
      $gene->retrieveFromDB();
      my $descr = $gene->get('description');
      if ($descr !~ /DEPRECATED/) {
	$gene->set('description', $descr . " (DEPRECATED)");
      }
      $gene->submit();
      $countDeprecatedGenes++;
      $self->undefPointerCache();
    }
  }

  $resultDescrip .= "Updated $countUpdatedGenes genes. Inserted $countInsertedGenes genes and $countInsertedGeneSynonyms synonyms. Deprecated $countDeprecatedGenes genes and $countDeprecatedGeneSynonyms synonyms. Reinstated $countReinstatedGeneSynonyms synonyms. ";
  return ($resultDescrip);
}

1;
