#######################################################################
##                 LoadNcbiGeneInfo
##
## updates records in DoTS.Gene from the NCBI gene info file,
## overwriting stored information
##
## $Id: LoadNcbiGeneInfo.pm 16594 2015-08-29 11:51:34Z allenem $
##
#######################################################################

package GUS::Community::Plugin::LoadNcbiGeneInfo;

@ISA = qw( GUS::PluginMgr::Plugin);

use strict 'vars';

use GUS::PluginMgr::Plugin;
use lib "$ENV{GUS_HOME}/lib/perl";

use GUS::Model::DoTS::Gene;
use GUS::Model::DoTS::GeneCategory;
use GUS::Model::DoTS::GeneSynonym;
use GUS::Model::DoTS::GeneChromosomalLocation;
use GUS::Model::DoTS::GeneInstance;
use GUS::Model::DoTS::GeneFeature;
use GUS::Model::SRes::DbRef;
use GUS::Model::DoTS::DbRefNAFeature;
use GUS::Model::SRes::OntologyTerm;
use GUS::Model::SRes::OntologySynonym;

use Data::Dumper;
use FileHandle;
use Carp;

my $argsDeclaration =
  [
   fileArg({ name           => 'inFile',
	     descr          => 'input data file; see NOTES for file format details',
	     reqd           => 1,
	     mustExist      => 1,
	     format         => 'tab-delimited format',
	     constraintFunc => undef,
	     isList         => 0,
	   }),
 
   stringArg({ name  => 'extDbRlsSpec',
	       descr => "The ExternalDBRelease specifier for the gene info file. Must be in the format 'name|version', where the name must match an name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
	       constraintFunc => undef,
	       reqd           => 1,
	       isList         => 0 }),

  stringArg({ name  => 'geneExtDbRlsSpec',
	       descr => "The ExternalDBRelease specifier for the records in DoTS.Gene that are being annotated. Must be in the format 'name|version', where the name must match an name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
	       constraintFunc => undef,
	       reqd           => 1,
	       isList         => 0 }),

  fileArg({ name           => 'sequenceOntologyMap',
	     descr          => 'file mapping NCBI gene types to sequence ontology source ids',
	     reqd           => 0,
	    mustExist      => 1,
	     format         => 'tab-delimited format',
	     constraintFunc => undef,
	     isList         => 0,
	   }),

 stringArg({ name  => 'soExtDbRlsSpec',
	       descr => "The ExternalDBRelease specifier for the sequence ontology. Must be in the format 'name|version', where the name must match an name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.  Must be specified if sequenceOntologyMap option is specified",
	       constraintFunc => undef,
	       reqd           => 0,
	       isList         => 0 }),
 
  
  ];


my $purposeBrief = <<PURPOSEBRIEF;
Loads NCBI Gene Info
PURPOSEBRIEF

my $purpose = <<PLUGIN_PURPOSE;
Loads NCBI Gene Info, over-writing anything previous in place in DoTS.Gene, 
inserting new rows otherwise (and in all other affected tables (unless fail duplicate entry checks))
PLUGIN_PURPOSE

my $tablesAffected = [
                      ['DoTS::Gene','update/inset description, name, symbol, gene_category_id , and sequence_ontology_id for each gene'],
                      ['DoTS::GeneCategory', 'Each record stores one NCBI gene category' ],
                      ['DoTS::GeneSynonym', 'Each record stores a gene synonym'],
                      ['DoTS::GeneChromosomalLocation', 'Each record stores the map location of a gene'],
                      ['DoTS::DbRef', 'Each record stores a DB reference from the gene info file; external database release will reference the NCBI Gene info, remark will describe the referenced DB'],
                     ['DoTS::DbRefNaFeature', 'Each record will link a gene to a DbRef'],
                     ];

my $tablesDependedOn = [
                        ['DoTS::GeneInstance', 'Required to link a gene to a gene feature'],
                        ['DoTS::GeneFeature', 'Required to populate DoTS::DbRefNAFeature'],
                        ['SRes.OntologyTerm', 'Lookups of sequence ontology terms'],
                        ['SRes.ExternalDatabase', 'Lookups of external database specifications'],
                        ['SRes.ExternalDatabaseRelease', 'Lookups of external database specifications']
 
];

my $howToRestart = <<PLUGIN_RESTART;
No restart facility available.
PLUGIN_RESTART

my $failureCases = <<PLUGIN_FAILURE_CASES;
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
PLUGIN_NOTES

my $documentation = { purpose=>$purpose,
		      purposeBrief=>$purposeBrief,
		      tablesAffected=>$tablesAffected,
		      tablesDependedOn=>$tablesDependedOn,
		      howToRestart=>$howToRestart,
		      failureCases=>$failureCases,
		      notes=>$notes
		    };

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);


  $self->initialize({requiredDbVersion => 4.0,
		     cvsRevision => '$Revision: 16594 $', # cvs fills this in!
		     name => ref($self),
		     argsDeclaration => $argsDeclaration,
		     documentation => $documentation
		    });

  return $self;
}

#######################################################################
# Main Routine
#######################################################################


sub run {
  my ($self) = @_;

  $self->loadGeneInfo();

}


sub fetchOntologyTermId {
    my ($self, $term, $xdbr) = @_;

    my $xdbrId = $self->getExtDbRlsId($xdbr);
    my $ontologyTerm = GUS::Model::SRes::OntologyTerm->new({
							    name => $term,
							    external_database_release_id => $xdbrId
							   });

    return $ontologyTerm->getOntologyTermId() if ($ontologyTerm->retrieveFromDB());

    # otherwise try source_id
    $ontologyTerm = GUS::Model::SRes::OntologyTerm->new({ 
							 source_id => $term,
							 external_database_release_id => $xdbrId
							});

    return $ontologyTerm->getOntologyTermId() if ($ontologyTerm->retrieveFromDB());


    # otherwise try synonym
    my $ontologySynonym = GUS::Model::SRes::OntologySynonym->new({
								  ontology_synonym => $term,
								  external_database_release_id => $xdbrId
								   });

    return $ontologySynonym->getOntologyTermId() if $ontologySynonym->retrieveFromDB();

    # otherwise ... not found
    $self->error("Ontology Term: $term ($xdbr) not found in SRes.OntologyTerm or SRes.OntologySynonym");
}

sub getSequenceOntologyMapping {
  my ($self) = @_;
  if ($self->getArg('sequenceOntologyMap')) {
    my $soMap = undef;

#    $self->error("Must provide external database specification for sequence ontology if mapping gene types.") if (!$soExtDbRlsId);
    my $fh = FileHandle->new;
    $fh->open("<" . $self->getArg('sequenceOntologyMap')) 
      || $self->error("Unable to open sequence ontology map: ". $self->getArg('sequenceOntologyMap'));
    
    while (<$fh>) {
      chomp;
      my ($geneType, $soSourceId) = split /\t/;
      $self->log("$geneType : $soSourceId");
      $soMap->{$geneType} = $self->fetchOntologyTermId($soSourceId, $self->getArg('soExtDbRlsSpec'));
    }
    $fh->close();
    return $soMap;
  }
  else {
    return undef;
  }
}

sub loadGeneInfo {
    my ($self) = @_;

# Format: tax_id GeneID Symbol LocusTag Synonyms dbXrefs chromosome map_location description type_of_gene Symbol_from_nomenclature_authority Full_name_from_nomenclature_authority Nomenclature_status Other_designations Modification_date (tab is used as a separator, pound sign - start of a comment)

    my $geneInfoExtDbRlsId = $self->getExtDbRlsId($self->getArg('extDbRlsSpec'));
    my $geneExtDbRlsId = $self->getExtDbRlsId($self->getArg('geneExtDbRlsSpec'));
    my $soMap = $self->getSequenceOntologyMapping();

    my $fName = $self->getArg('inFile');
    my $fh = FileHandle->new;
    $fh->open("<$fName") || $self->error("Unable to open data file: $fName\n");

    my $header = <$fh>;
    while(<$fh>) {
	chomp;
	my ($taxId, $entrezGeneId, $symbol, $locusTag, $synonyms, $dbXrefs, $chr, $mapLocation, $description, $type, $officialSymbol, $officialName, @etc) = split /\t/;

	$self->log("Entrez $entrezGeneId; OS: $officialSymbol, NAME: $officialName, Map: $mapLocation, Type: $type") if ($self->getArg('veryVerbose'));

	my $gene = GUS::Model::DoTS::Gene->new({source_id => $entrezGeneId,
						external_database_release_id => $geneExtDbRlsId});

	my $geneExists = $gene->retrieveFromDB();

	$self->log("$entrezGeneId does not exist") if (!$geneExists);

	$gene->setGeneSymbol($officialSymbol) if $officialSymbol ne '-';
	$gene->setDescription($description) if $description ne '-';
	$gene->setName($officialName) if $officialName ne '-';
	$gene->setSequenceOntologyId($soMap->{$type}) if ($soMap);

	if ($synonyms ne '-') {
	  my @synonyms = split /\|/, $synonyms;
	  foreach my $s (@synonyms) {
	    my $geneSynonym = GUS::Model::DoTS::GeneSynonym->new({synonym_name => $s});
	    $geneSynonym->setParent($gene);
	  }
	}
	if ($mapLocation ne '-') {
	  $chr = 23 if ($chr eq 'X');
	  $chr = 24 if ($chr eq 'Y');
	  $chr = 25 if ($chr eq 'M' or $chr eq 'MT');
	  $chr = 99 if ($chr =~ /\|/);

	  my $geneChromosomalLocation = GUS::Model::DoTS::GeneChromosomalLocation->new({cytogenetic => $mapLocation
											  , chromosome=> $chr});
	  $geneChromosomalLocation->setParent($gene);
	}

	if ($type ne '-') {
	  my $geneCategory = GUS::Model::DoTS::GeneCategory->new({term => $type});
	  $geneCategory->submit() unless ($geneCategory->retriveFromDB());
	  $gene->setGeneCategoryId($geneCategory->getGeneCategoryId());
	}

	$gene->submit();

	if ($geneExists) { # no gene instance/nafeature associated with newly entered genes
	    my $geneInstance = GUS::Model::DoTS::GeneInstance->new({gene_id => $gene->getGeneId()});
	    $geneInstance->retrieveFromDB();
	    my $naFeatureId = $geneInstance->getNaFeatureId();
	    
	    my @dbRefs = split /\|/, $dbXrefs;
	    foreach my $d (@dbRefs) {
	      my @dbr = split /:/, $d;
	      my $db = $dbr[0];
	      my $id = $dbr[1];

	      $id = $dbr[2] if ($db eq 'HGNC');
	      $self->log("$db - $id") if ($self->getArg('veryVerbose'));
	      my $dbRef = GUS::Model::SRes::DbRef->new({external_database_release_id => $geneInfoExtDbRlsId,
							primary_identifier => $gene->getGeneId(),
							secondary_identifier => $id,
							gene_symbol => $gene->getGeneSymbol(),
							remark => $db});
	      $dbRef->submit();
	    }
	}
	$self->undefPointerCache();
    }

  
    $fh->close();
    
}

# sub undoTables {
#   my ($self) = @_;

#   return undef;
# }

1;
