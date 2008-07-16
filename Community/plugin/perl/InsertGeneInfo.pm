##
## InsertGeneInfo Plugin
## $Id: $
##

package GUS::Community::Plugin::InsertGeneInfo;
@ISA = qw( GUS::PluginMgr::Plugin );

use strict;
use IO::File;
use Data::Dumper;
use GUS::PluginMgr::Plugin;

use GUS::Model::DoTS::Gene;
use GUS::Model::DoTS::GeneSynonym;
use GUS::Model::DoTS::GeneCategory;

# ----------------------------------------------------------------------
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
     stringArg({ name  => 'extDbRlsSpec',
		  descr => "The ExternalDBRelease specifier for this Taxon.gene_info file. Must be in the format 'name|version', where the name must match an name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
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
     integerArg({name  => 'restart',
		 descr => 'Line number in Taxon.gene_info file from which loading should be resumed (line 1 is the first line after the header, empty lines are counted).',
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
  my $purposeBrief = 'Loads data from an NCBI taxon gene_info file into DoTS.';

  my $purpose = "This plugin reads a Taxon.gene_info file from NCBI Entrez Gene and populates DoTS Gene tables.";

  my $tablesAffected = [['DoTS::Gene', 'Enters a row for each gene in the file'], ['DoTS::GeneSynomym', 'Enters rows linking each entered Gene to its Synonyms'], ['DoTS::GeneCategory', 'Enters values from type_of_gene, if not already present in this table']];

  my $tablesDependedOn = [['SRes::ExternalDatabaseRelease', 'The release of the Taxon Entrez Gene external database identifying the input file'], ['SRes::SequenceOntology', 'The terms corresponding to types of gene'], ['SRes::TaxonName', 'The taxon for the gene_info being loaded']];

  my $howToRestart = "Loading can be resumed using the I<--restart n> argument where n is the line number in the Taxon.gene_info file of the first row to load upon restarting (line 1 is the first line after the header, empty lines are counted). Alternatively, one can use the plugin GUS::Community::Plugin::Undo to delete all entries inserted by a specific call to this plugin. Then this plugin can be re-run from fresh.";

  my $failureCases = "";

  my $notes = <<NOTES;

=head1 AUTHOR

Written by Elisabetta Manduchi.

=head1 COPYRIGHT

Copyright Elisabetta Manduchi, Trustees of University of Pennsylvania 2008. 
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
		     cvsRevision => '$Revision$',
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
  my $extDbRls = $self->getExtDbRlsId($self->getArg('extDbRlsSpec'));
  
  $resultDescrip .= $self->insertGene($taxonId, $extDbRls, $geneCategoryIds, \%soMapping, $self->getArg('geneInfoFile'));

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
  $resultDescrip .= "Entered $count rows in DoTS.GeneCategory";
  return ($resultDescrip, $geneCategoryIds);
}

sub insertGene {
  my ($self, $taxonId, $extDbRls, $geneCategoryIds, $soMapping, $file) = @_;
  my $resultDescrip = '';
  my $countGenes = 0;
  my $countGeneSynonyms = 0;
  my $lineNum = 0;
  my $startLine = defined $self->getArg('restart') ? $self->getArg('restart') : 1;
  my $endLine;
  if (defined $self->getArg('testnum')) {
    $endLine = $startLine-1+$self->getArg('testnum');
  }

  my $fh = IO::File->new("<$file")  || $self->userError("Cannot open file $file.");
  my $line = <$fh>;
  chomp($line);
  my @arr = split(/\s+/, $line);
  my %headerPos;
  for (my $i=0; $i<@arr; $i++) {
    if ($arr[$i] eq 'GeneID') {
      $headerPos{'sourceId'} = $i-1;
    }
    if ($arr[$i] eq 'Symbol') {
      $headerPos{'symbol'} = $i-1;
    }
    if ($arr[$i] eq 'Synonyms') {
      $headerPos{'synonyms'} = $i-1;
    }
    if ($arr[$i] eq 'description') {
      $headerPos{'description'} = $i-1;
    }
    if ($arr[$i] eq 'type_of_gene') {
      $headerPos{'geneCategory'} = $i-1;
    }  
    if ($arr[$i] eq 'Full_name_from_nomenclature_authority'){
      $headerPos{'name'} = $i-1;
    }  
  }
  $self->logDebug(Dumper(%headerPos) . "\n");
  while ($line=<$fh>) {
    $lineNum++;
    if ($lineNum<$startLine) {
      next;
    }
    if (defined $endLine && $lineNum>$endLine) {
      last;
    }
    if ($lineNum % 200 == 0) {
      $self->log("Inserting data from the $lineNum-th line.");
    }
    chomp($line);
    my @arr = split(/\t/, $line);
    my $gene= GUS::Model::DoTS::Gene->new({gene_symbol => $arr[$headerPos{'symbol'}], external_database_release_id => $extDbRls, source_id => $arr[$headerPos{'sourceId'}], taxon_id => $taxonId});
    if (defined $soMapping->{$arr[$headerPos{'geneCategory'}]} && $soMapping->{$arr[$headerPos{'geneCategory'}]} ne 'NA') {
      $gene->set('sequence_ontology_id', $soMapping->{$arr[$headerPos{'geneCategory'}]});
    }
    if ($arr[$headerPos{'name'}] ne '-'){
	$gene->set('name', $arr[$headerPos{'name'}]);
      }
    if ($arr[$headerPos{'description'}] ne '-'){
	$gene->set('description', $arr[$headerPos{'description'}]);
      }
    if ($arr[$headerPos{'geneCategory'}] ne '-'){
	$gene->set('gene_category_id', $geneCategoryIds->{$arr[$headerPos{'geneCategory'}]},);
      }
    my @synonyms = split(/\|/, $arr[ $headerPos{'synonyms'}]);
    for (my $i=0; $i<@synonyms; $i++) {
      if ($synonyms[$i] ne '-'){
	my $geneSynonym= GUS::Model::DoTS::GeneSynonym->new({synonym_name => $synonyms[$i]});
	$geneSynonym->setParent($gene);
	$countGeneSynonyms++;
	$self->logDebug($geneSynonym->toString() . "\n");
      }
    }
    
    $gene->submit();
    $countGenes++;
    $self->logDebug($gene->toString() . "\n");
    $self->undefPointerCache();
  }
  $fh->close();
  $resultDescrip .= "Inserted $countGenes entries in DoTS.Gene and $countGeneSynonyms entries in DoTS.GeneSynonym.";
  return ($resultDescrip);
}

# ----------------------------------------------------------------------
# Undo
# ----------------------------------------------------------------------

sub undoTables {
  my ($self) = @_;

  return ('DoTS.GeneSynonym', 'DoTS.Gene');
}

1;
