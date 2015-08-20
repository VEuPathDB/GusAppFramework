#######################################################################
##                 InsertSeqVariationResult.pm
##
## Loads results from tab-delimited file into Results.SeqVariation
## also links results to annotations via the Study.ProtocolAppNode
##
## $Id: InsertSeqVariationResult.pm allenem $
##
#######################################################################

package GUS::Community::Plugin::InsertSeqVariationResult;

@ISA = qw( GUS::PluginMgr::Plugin);

use strict 'vars';

use GUS::PluginMgr::Plugin;
use lib "$ENV{GUS_HOME}/lib/perl";

use GUS::Model::Study::ProtocolAppNode;
use GUS::Model::Study::Characteristic;
use GUS::Model::SRes::OntologyTerm;
use GUS::Model::SRes::OntologySynonym;
use GUS::Model::Results::SeqVariation;
use GUS::Model::DoTS::SnpFeature;
use GUS::Model::DoTS::NAFeatureRelationship;

use Data::Dumper;
use FileHandle;
use Carp;
use POSIX qw(log10);

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
   fileArg({ name           => 'characteristicFile',
	     descr          => 'file listing dataset (protocol application) characteristics; see NOTES for file format details',
	     reqd           => 0,
	     mustExist      => 0,
	     format         => 'tab-delimited format',
	     constraintFunc => undef,
	     isList         => 0,
	   }),

   stringArg({ name  => 'extDbRlsSpec',
	       descr => "The ExternalDBRelease specifier for the result. Must be in the format 'name|version', where the name must match an name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
	       constraintFunc => undef,
	       reqd           => 0,
	       isList         => 0 }),

 stringArg({ name  => 'snpExtDbRlsSpec',
	       descr => "The ExternalDBRelease specifier for the referenced SNPs. Must be in the format 'name|version', where the name must match an name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
	       constraintFunc => undef,
	       reqd           => 1,
	       isList         => 0 }),
  stringArg({ name  => 'sourceId',
	       descr => "external database source_id for the result in the specified External Database; or internal identifier",
	       constraintFunc => undef,
	       reqd           => 0,
	       isList         => 0 }),
   stringArg({ name  => 'name',
	       descr => "the name of the result",
	       constraintFunc => undef,
	       reqd           => 0,
	       isList         => 0 }),
   stringArg({ name  => 'description',
	       descr => "description of the result",
	       constraintFunc => undef,
	       reqd           => 0,
	       isList         => 0 }),
    stringArg({ name  => 'type',
	       descr => "The type of dataset specified as 'term;Ontology|Version' where 'Ontology' must match an entry in SRes.ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.  term must match a source_id or name in SRes.OntologyTerm associated with the versioned external database",
	       constraintFunc => undef,
	       reqd           => 0,
	       isList         => 0 }),
   stringArg({ name  => 'subType',
	       descr => "sub-type defined as 'term;Ontology|Version.  See 'type' parameter for more information",
	       constraintFunc => undef,
	       reqd           => 0,
	       isList         => 0 }),
   booleanArg({ name  => 'skipMissingSNPs',
		descr => "skip results mapped to SNPs not found in the database.  If flag is not provided, plugin will fail when a result cannot be mapped to a SNP",
		constraintFunc => undef,
		reqd           => 0,
		isList         => 0 }),
  booleanArg({ name  => 'negLogP',
		descr => "transform pvalues using -log10",
		constraintFunc => undef,
		reqd           => 0,
		isList         => 0 }),
   integerArg({name=>'protocolAppNodeId',
	       descr => 'protocol app node id for resume or linking to exisiting protocol app node',
	       constraintFunc => undef,
	       reqd => 0,
	       isList => 0}),
  
  ];


my $purposeBrief = <<PURPOSEBRIEF;
Loads snp results in Results.SeqVariation
PURPOSEBRIEF

my $purpose = <<PLUGIN_PURPOSE;
Loads snp results in Results.SeqVariation and links to meta-data via a Study.ProtocolAppNode
PLUGIN_PURPOSE

my $tablesAffected = [
                      ['Study::ProtocolAppNode', 'Each dataset is represented by one record.'],
                      ['Study::Characteristic', 'Each record links a dataset to an ontology term.'],
                      ['Results::SeqVariation', 'Each record stores one pvalue/allele frequence for a snp.'],
                     ];

my $tablesDependedOn = [
                        ['DoTS.SnpFeature', 'Lookups of SNP source_ids to match to na_feature_ids'],
                        ['SRes.OntologyTerm', 'Lookups of characteristics'],
                        ['SRes.OntologySynonym', 'Lookups of characteristics'],
                        ['SRes.ExternalDatabase', 'Lookups of external database specifications'],
                        ['SRes.ExternalDatabaseRelease', 'Lookups of external database specifications']
 
];

my $howToRestart = <<PLUGIN_RESTART;
No restart facility available.
PLUGIN_RESTART

my $failureCases = <<PLUGIN_FAILURE_CASES;
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
INPUT FILE must be tab-delimited with first column containing a snp_id (source_id in DoTS.SnpFeature)
remaining columns should be named for fields in the Results.SeqVariation table,

except for 'phenotype_id' and 'sequence_ontology_id', which should be specificed as a two-column pair: 
'phenotype' (or 'sequence_ontology') providing a term or source_id 
and 'phenotype_xdbr' (or 'sequence_ontology_xdbr') specifying the ontology and version (Ontology|Version).  
Alternatively, 'phenotype_id' or 'sequence_ontology_id' may be directly provided, as long as values map 
to an existing 'ontology_term_id' in SRes::OntologyTerm.

CHARACTERISTIC FILE is a two column tab-delimited file
first column contains the term or term_source_id
second column contains the external database release of the term specified as ExternalDatabase|Version


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
		     cvsRevision => '$Revision: 16513 $', # cvs fills this in!
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

  my $protocolAppNode = $self->loadProtocolAppNode();
  $self->loadCharacteristics($protocolAppNode);
  
  $self->loadResults($protocolAppNode);

}

sub fetchSnpNAFeatureId {
  my ($self, $snpId, $mergeFeatureRelationTypeId) = @_;

  my $snpFeature = GUS::Model::DoTS::SnpFeature->new({source_id => $snpId,
						      external_database_release_id => $self->getExtDbRlsId($self->getArg('snpExtDbRlsSpec'))});

  unless ($snpFeature->retrieveFromDB()) {
    if ($self->getArg('skipMissingSNPs')) {
	$self->log("No record found for $snpId in DoTS.SnpFeature") if ($self->getArg('verbose'));
	return undef;
    }
    else {
	$self->error("No record found for $snpId in DoTs.SnpFeature");
    }
  }

  # if SNP has been merged, map to parent
  if ($snpFeature->getName() eq 'merged') {
    return $self->getParentSnpFeature($snpFeature->getNaFeatureId());
  }

  return $snpFeature->getNaFeatureId();
}


sub getParentSnpFeature {
  my ($self, $childNaFeatureId) = @_;
  
  # TODO: this is PostgreSQL specific; needs to be generalized for Oracle (limit --> rownum | recursive with)
  my $query = $self->getQueryHandle()->prepare(<<SQL) or die DBI::errstr;
WITH RECURSIVE parentFeature AS (
(SELECT parent_na_feature_id AS na_feature_id, sf.source_id FROM
DoTS.NAFeatureRelationship r, DoTS.SnpFeature sf
WHERE r.child_na_feature_id = ? AND sf.na_feature_id = r.parent_na_feature_id)
UNION
SELECT parent_na_feature_id AS na_feature_id, sf.source_id FROM 
parentFeature pf, DoTS.NAFeatureRelationship r, DoTS.SnpFeature sf
WHERE r.child_na_feature_id = pf.na_feature_id AND sf.na_feature_id = r.parent_na_feature_id)
SELECT * FROM parentFeature ORDER by source_id DESC LIMIT 1;
SQL

  $query->execute($childNaFeatureId);
  my ($parentNaFeatureId, $parentSourceId) = $query->fetchrow_array();
  $query->finish();

  return $parentNaFeatureId;

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

sub link2table { # create entry in SRes.Characteristic that links the protocol app node to a result table
  my ($self, $protocolAppNodeId) = @_;

  my $tableId = $self->className2TableId('Results::SeqVariation');
  my $characteristic = GUS::Model::Study::Characteristic->new({
							       value => 'SeqVariation',
							       table_id => $tableId,
							       protocol_app_node_id => $protocolAppNodeId
							      });
  $characteristic->submit() unless ($characteristic->retrieveFromDB());

}

sub getTypeId {
  my ($self, $typeStr) = @_;
  my $typeId = undef;
  if ($typeStr) {
    my @type = $self->getArg('type').split(";"); # term;xdbr
    $typeId = $self->fetchOntologyTermId($type[0], $type[1]);
  }
  return $typeId;
}


# take neg log10 of pvalues; use value of exponent when value is >= 300 due to floating point issues
sub negLog10{
  my ($self, $value) = @_;
  my $exponent =  ($value =~ /[E|e]-(\d+)/) ? $1 : undef;

  return $exponent if ($exponent > 300);
  return sprintf("%.2f",-log10($value));
  
}

sub parseFieldValues { # 
  my ($self, $fieldValues) = @_;

  delete $fieldValues->{''}; # seems to be creating an empty key => value pair

  # make empty values undef
  while (my ($key, $value) = each %$fieldValues) {
    $fieldValues->{$key} = undef if $value eq '';
  }
  
  $fieldValues->{p_value} = $self->negLog10($fieldValues->{p_value}) if ($self->getArg('negLogP'));

  # map phenotypes to ontology_term_id; throw error if no External Database specification is provided 
  if (exists $fieldValues->{phenotype}) {
    $self->error("must provide a 'phenotype_xdbr' (Ontology|Version) column if providing 'phenotype' terms or source_ids in data file")
      if (!exists $fieldValues->{phenotype_xdbr});

    $fieldValues->{phenotype_id} = $self->fetchOntologyTermId($fieldValues->{phenotype}, $fieldValues->{phenotype_xdbr});
    delete $fieldValues->{phenotype}; # remove phenotype/phenotype_xdbr b/c they are not fields in SeqVariation 
    delete $fieldValues->{phenotype_xdbr};
  }

  # map sequence ontology terms to ontology_term_id; throw error if no External database specification is provided
  if (exists $fieldValues->{sequence_ontology}) {
      $self->error("must provide a 'sequence_ontology_xdbr' (Ontology|Version) column if providing 'sequence_ontology' terms or source_ids in data file") 
	  if (!exists $fieldValues->{sequence_ontology_xdbr});
      
      if ($fieldValues->{sequence_ontology}) { # if a value is present
	  $fieldValues->{sequence_ontology_id} = $self->fetchOntologyTermId($fieldValues->{sequence_ontology},
									    $fieldValues->{sequence_ontology_xdbr});
      }
      delete $fieldValues->{sequence_ontology};
      delete $fieldValues->{sequence_ontology_xdbr};
  }

  if (exists $fieldValues->{allele}) { # allele field can only have char length 1
      my $allele = $fieldValues->{allele};
      if (length $allele > 1) {
	  $self->log("Allele $allele length > 1; inserting NULL value instead") 
	      if $self->getArg('veryVerbose');
	  $fieldValues->{allele} = undef;
      }
    }

  return %$fieldValues;
}

# creates a ProtocolAppNode and Study.Characteristic entry
# that indicates that the result is stored in SeqVariation
sub loadProtocolAppNode {
    my ($self) = @_;
    
    my $protocolAppNode = undef;

    my $protocolAppNodeId = $self->getArg('protocolAppNodeId');
    if ($protocolAppNodeId) {
      $protocolAppNode = GUS::Model::Study::ProtocolAppNode->new({
        protocol_app_node_id => $protocolAppNodeId});
      $self->error("No record found in Study.ProtocolAppNode where protocol_app_node_id = $protocolAppNodeId") 
	unless ($protocolAppNode->retrieveFromDB());
    }
    else {
      $protocolAppNode = GUS::Model::Study::ProtocolAppNode->new({
	external_database_release_id => $self->getExtDbRlsId($self->getArg('extDbRlsSpec')),
	type_id => $self->getTypeId($self->getArg('type')),
	subtype_id => $self->getTypeId($self->getArg('subType')),
	name => $self->getArg('name'),
	source_id => $self->getArg('sourceId'),
	description => $self->getArg('description')
								  });
      $protocolAppNode->submit();
    }
     
    $self->link2table($protocolAppNode->getProtocolAppNodeId());

    return $protocolAppNode;
}

sub loadCharacteristics {
    my ($self, $protocolAppNode) = @_;

    my $cfName = $self->getArg('characteristicFile');
    if ($cfName) {
      my $fh = FileHandle->new;
      $fh->open("<$cfName") || $self->error("Error opening characteristic file: $cfName");
      while(<$fh>) {
	chomp;
	my ($term, $xdbr) = split /\t/;
	my $ontologyTermId =$self->fetchOntologyTermId($term, $xdbr);
	my $characteristic = GUS::Model::Study::Characteristic->new({ontology_term_id => $ontologyTermId});
	$characteristic->setParent($protocolAppNode);
	$characteristic->submit();
      }
      $fh->close();
    }
}

sub loadResults {
    my ($self, $protocolAppNode) = @_;

    # begin transaction management
    $self->getDb()->manageTransaction(undef, "begin"); # start a transaction

    my $fName = $self->getArg('inFile');
    my $fh = FileHandle->new;
    $fh->open("<$fName") || $self->error("Unable to open data file: $fName\n");

    my $header = <$fh>;
    my @fields = split /\t/, $header;
    shift @fields; # first one is snp source id
    chomp(@fields);

    my $recordCount = 0;
    while(<$fh>) {
	my ($sourceId, @values) = split /\t/;

	$self->log($sourceId) if ($self->getArg('veryVerbose'));

	chomp(@values);

	my %fieldValues = undef;
	@fieldValues{@fields} = @values; # create hash mapping field name => value

	# need to clean up field values (set empty strings to undef)
	# and fetch ontology_term_ids for phenotypes
	%fieldValues = $self->parseFieldValues(\%fieldValues);

	my $naFeatureId = $self->fetchSnpNAFeatureId($sourceId);

	next if (!$naFeatureId);

	$fieldValues{snp_na_feature_id} = $naFeatureId;
	$fieldValues{protocol_app_node_id} = $protocolAppNode->getProtocolAppNodeId();

	if ($self->getArg('veryVerbose')) {
	  $self->log(Dumper(\%fieldValues));
	}

	my $seqVariationResult = GUS::Model::Results::SeqVariation->new(\%fieldValues);
	$seqVariationResult->submit(undef, 1); # noTran = 1 --> do not commit at this point

	unless (++$recordCount % 5000) {
	    if ($self->getArg("commit")) {
		$self->getDb()->manageTransaction(undef, "commit"); # commit
		$self->getDb()->manageTransaction(undef, "begin");
	    }
	    $self->log("$recordCount records loaded.")
		if $self->getArg('verbose');
	}
	$self->undefPointerCache();
    }

    if ($self->getArg("commit")) {
	$self->getDb()->manageTransaction(undef, "commit"); # commit final batch
	$self->log("$recordCount records loaded.") if $self->getArg('verbose');
    }

    $fh->close();
    
}

sub undoTables {
  my ($self) = @_;

  return ('Study.ProtocolAppNode',
          'Study.Characteristic',
          'Results.SeqVariation',
         );
}

1;
