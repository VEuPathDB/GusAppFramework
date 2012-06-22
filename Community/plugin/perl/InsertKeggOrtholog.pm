##
## InsertKeggOrtholog Plugin
## $Id: $
##

package GUS::Community::Plugin::InsertKeggOrtholog;
@ISA = qw( GUS::PluginMgr::Plugin );

use Data::Dumper;

use strict;
use FileHandle;
use GUS::PluginMgr::Plugin;

use GUS::Model::DoTS::Gene;
use GUS::Model::DoTS::Family;
use GUS::Model::DoTS::FamilyGene;

# ----------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------

sub getArgumentsDeclaration {
  my $argumentDeclaration  =
    [
     fileArg({name => 'keggOrthologFile', 
	      descr => 'The full path of the ko file downloaded from KEGG',
	      constraintFunc=> undef,
	      reqd  => 1,
	      isList => 0,
	      mustExist => 1,
	      format => ''
	     }),
     fileArg({name => 'keggTaxonFile',
	      descr => 'The full path of the file mapping KEGG taxon codes to taxon names',
	      constraintFunc=> undef,
	      reqd  => 1,
	      isList => 0,
	      mustExist => 1,
	      format => ''
	     }),
     stringArg({ name  => 'keggExtDbRlsSpec',
		  descr => "The ExternalDBRelease specifier for --keggOrthologFile. Must be in the format 'name|version', where the name must match an name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
		  constraintFunc => undef,
		  reqd           => 1,
		  isList         => 0 }),

     stringArg({ name  => 'taxaGeneInfoExtDbRlsSpecs',
		  descr => "The ExternalDBRelease specifiers for the Taxon.gene_info files to consider. Must be a comma-separated list with each entry in the format 'name|version', where the name must match an name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
		  constraintFunc => undef,
		  reqd           => 1,
		  isList         => 0 }),
     integerArg({name  => 'restart',
		 descr => 'Line number in --keggOrthologFile from which loading should be resumed (line 1 is the first line, empty lines are counted).',
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
  my $purposeBrief = 'Loads data from an KEGG Ortholog file into DoTS.';

  my $purpose = "This plugin reads a ko file from KEGG and populates the DoTS Family and FamilyGene tables for the specified taxa.";

  my $tablesAffected = [['DoTS::Family', 'Enters a row for each ortholog in the file for the taxa of interest'], ['DoTS::FamilyGene', 'Enters rows linking each entered ortholog to its genes']];

  my $tablesDependedOn = [['SRes::ExternalDatabaseRelease', 'The release of the KEGG database for --keggOrthologFile and the releases of the Taxon Entrez Gene external databases identifying the Entrez Genes for the taxa of interest'], ['SRes::Taxon', 'The taxa of interest']];

  my $howToRestart = "Loading can be resumed using the I<--restart n> argument where n is the line number in the ko file of the first row to load upon restarting (line 1 is the first line, empty lines are counted). Alternatively, one can use the plugin GUS::Community::Plugin::Undo to delete all entries inserted by a specific call to this plugin. Then this plugin can be re-run from fresh.";

  my $failureCases = "";

  my $notes = <<NOTES;

=head1 AUTHOR

Written by Emily Greenfest-Allen

=head1 COPYRIGHT

Copyright Emily Greenfest-Allen, Trustees of University of Pennsylvania 2012. 
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
		     cvsRevision => '$Revision: 9246 $',
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

  if (defined($self->getArg('testnum')) && $self->getArg('commit')) {
    $self->userError("The --testnum argument can only be provided if COMMIT is OFF.");
  }
  my $dbh = $self->getQueryHandle();
  my $taxonCodes = $self->getKeggTaxonCodes($dbh);

  my $resultDescrip = $self->insertKeggOrtholog($taxonCodes);

  $self->setResultDescr($resultDescrip);
  $self->logData($resultDescrip);
}

# ----------------------------------------------------------------------
# methods called by run
# ----------------------------------------------------------------------

sub getKeggTaxonCodes {
  my ($self, $dbh) = @_;
  my $fileName = $self->getArg('keggTaxonFile');

  my $fh = FileHandle->new;
  $fh->open("<" . $fileName) || die "Unable to open taxon code file: " . $fileName . "\n";
  my $keggTaxonCodes = undef;
  while (<$fh>) {
    chomp;
    my ($code, $scientificName) = split /\t/;
    $keggTaxonCodes->{$scientificName} = $code;
  }
  $fh->close();

  my @taxaSpecs = split /,/, $self->getArg('taxaGeneInfoExtDbRlsSpecs');
  my $taxa = undef;
  my $sth = $dbh->prepare(qq(select distinct tn.name from SRes.TaxonName tn, Dots.Gene g where tn.taxon_id=g.taxon_id and g.external_database_release_id=? and tn.name_class = 'scientific name')) || die $dbh->errstr;

  foreach my $taxonSpec (@taxaSpecs) {
    my $extDbRls = $self->getExtDbRlsId($taxonSpec);

    $sth->execute($extDbRls)  || die $dbh->errstr;
    my $scientificName = $sth->fetchrow_array();
    my $code = $keggTaxonCodes->{$scientificName};
    $code =~ s/ //g; # remove trailing spaces

    $taxa->{$code} = $extDbRls;
    $self->logData("KEGG taxon $code ($scientificName) will be considered (extdbRls: $extDbRls).");
  }
  
  $sth->finish();
  return($taxa);
}

sub parseKeggOrthologs {
  my ($self, $keggOrthologFile, @taxonCodes) = @_;
  
  my $fh = FileHandle->new;
  $fh->open("<" . $keggOrthologFile) || die "Unable to open ko file: " . $keggOrthologFile . "\n";
  
  my $ko2geneMap = undef;
  my $entryCount = 0;
  my $entry = undef;
  
  $self->log("Parsing $keggOrthologFile\n");
  while(<$fh>) {
    chomp;
    s/\s{2,}/\t/g; # substitute one or more white spaces with tabs
    my @row = split /\t/;
    
    if ($row[0] =~ /ENTRY/) {
      $entry = $row[1]; 
      $entryCount++;
    }
    
    foreach my $taxon (@taxonCodes) {
      $ko2geneMap->{$entry}->{$taxon} = parseGeneList($row[1]) if ($row[1] =~ /$taxon/);
    }
    
  } # end iterate over file

  $self->log("Done Parsing $keggOrthologFile\n");
  $self->undefPointerCache();
  
  $fh->close();

  return $ko2geneMap;
} # end parseKOFile

sub parseGeneList {
  # genes are list in format EntrezGene(Symbol) EntrezGene(Symbol) ... etc
  my ($string) = @_;

  my @entrezGeneList = ();
  my @geneList = split /\s/, $string;
  shift @geneList; # get rid of the first element which is the taxon abbreviation

  foreach my $gene (@geneList) {   
    my @geneIds = split '\(', $gene;
    push(@entrezGeneList, $geneIds[0]);

  }

  return \@entrezGeneList;
} # end parseGeneList


sub insertKeggOrtholog {
  my ($self, $taxonCodes) = @_;
  my $resultDescrip = '';
  my $extDbRls = $self->getExtDbRlsId($self->getArg('keggExtDbRlsSpec'));

  my $familyCount = 0;
  my $familyGeneCount = 0;

  my $ortholog2entrezGeneMap = $self->parseKeggOrthologs($self->getArg('keggOrthologFile'), keys %$taxonCodes);
  
  foreach my $koid (keys %$ortholog2entrezGeneMap) {

    my $family = GUS::Model::DoTS::Family->new({external_database_release_id => $extDbRls, source_id => $koid});
    if (!$family->retrieveFromDB()) {
      $familyCount++;
    }

    my $orthologs = $ortholog2entrezGeneMap->{$koid};

    my @taxa = keys %{$orthologs};
    
    foreach my $taxon (@taxa) {
      my @entrezGenes = @{$orthologs->{$taxon}};

      foreach my $geneId (@entrezGenes) {
	if ($familyGeneCount % 1000 == 0) {
	  $self->log("Inserted $familyGeneCount-th KEGG ortholog.");
	  $self->undefPointerCache();
	}

	my $gene = GUS::Model::DoTS::Gene->new({external_database_release_id => $taxonCodes->{$taxon}, source_id => $geneId});
	if ($gene->retrieveFromDB()) {
	  my $familyGene = GUS::Model::DoTS::FamilyGene->new({});
	  $familyGeneCount++;
	  $familyGene->setParent($family);
	  $familyGene->setParent($gene);
	  $family->submit();
	}
      }
    }
  }

  $resultDescrip .= "Entered $familyCount rows in DoTS.Family and $familyGeneCount rows in DoTS.FamilyGene";
  return ($resultDescrip);
}


# ----------------------------------------------------------------------
# Undo
# ----------------------------------------------------------------------

sub undoTables {
  my ($self) = @_;

  return ('DoTS.FamilyGene', 'DoTS.Family');
}

1;
