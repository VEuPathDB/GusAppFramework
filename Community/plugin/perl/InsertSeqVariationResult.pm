#######################################################################
##                 InsertSeqVariationResult.pm
##
## Loads results from tab-delimited file into Results.SeqVariation
## also links results to annotations via the Study.ProtocolAppNode
## and (optional) the ProtocolAppNode to an existing Study (in 
## Study.Study via Study.StudyLink)
##
## Also includes option to load results associated with markers 
## identified by position (e.g., 1-1239341 or 1:12313) into 
## Results.SegmentResult
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
use GUS::Model::Study::Study;
use GUS::Model::Study::StudyLink;
use GUS::Model::SRes::OntologyTerm;
use GUS::Model::SRes::OntologySynonym;
use GUS::Model::Results::SeqVariation;
use GUS::Model::DoTS::SnpFeature;
use GUS::Model::DoTS::NAFeatureRelationship;
use GUS::Model::Results::SegmentResult;
use GUS::Model::DoTS::ExternalNASequence;

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
   stringArg({name          => 'characteristics',
	      descr         => "comma separated list of ontology terms source ids;external database release specifier pairs that can be provided as an alternative to a text file (using the --characteristicFile option).  For example: EFO_0002692;Experimental Factor Ontology|2.72.  The external database release specifier must be in the format 'name|version', where the name must match a name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
	      reqd          => 0,
	      constraintFunc => undef,
	      isList        => 1}),
   stringArg({ name  => 'extDbRlsSpec',
	       descr => "The ExternalDBRelease specifier for the result. Must be in the format 'name|version', where the name must match an name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
	       constraintFunc => undef,
	       reqd           => 0,
	       isList         => 0 }),
   stringArg({ name  => 'sequenceExtDbRlsSpec',
	       descr => "The ExternalDBRelease specifier for the sequence (for SegmentResults). Must be in the format 'name|version', where the name must match an name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
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
		descr => "transform p-values using -log10?",
		constraintFunc => undef,
		reqd           => 0,
		isList         => 0 }),
  booleanArg({ name  => 'loadSegmentResults',
		descr => "load results associated with missing SNPs or positional ids into segment result?",
		constraintFunc => undef,
		reqd           => 0,
		isList         => 0 }),

   integerArg({name=>'protocolAppNodeId',
	       descr => 'protocol app node id for resume or linking to exisiting protocol app node',
	       constraintFunc => undef,
	       reqd => 0,
	       isList => 0}),

   integerArg({name=>'studyId',
	       descr => 'Study.Study study_id to which the ProtocolAppNode associated with the result shoudl be linked',
	       constraintFunc => undef,
	       reqd => 0,
	       isList => 0}),
  ];


my $purposeBrief = <<PURPOSEBRIEF;
Loads SNP results in Results.SeqVariation
PURPOSEBRIEF

my $purpose = <<PLUGIN_PURPOSE;
Loads SNP results in Results.SeqVariation.

If flag --loadSegmentResults is specified, will load results
that cannot be linked to a SNP identifier (in DoTS.SnpFeature)
into Results.SegmentResult

Can link the results to an existing Study.ProtocolAppnode or create
a new one.  Will also populate the characteristics associated
with the ProtocolAppNode (Study.Characteristics) if a provided.

Will also create a link between the ProtocolAppNode and an 
existing study in Study.Study via Study.StudyLink if the 
--studyId flag is provided.
PLUGIN_PURPOSE

my $tablesAffected = [
                      ['Study::ProtocolAppNode', 'Each dataset is represented by one record.'],
                      ['Study::Characteristic', 'Each record links a dataset to an ontology term.'],
		      ['Study::StudyLink', 'Each record stores a link between a protocol_app_node_id and a study_id.'],
                      ['Results::SeqVariation', 'Each record stores one pvalue/allele frequence for a snp.'],
                      ['Results::SegmentResult', 'Each records stores a pvalue for an unmapped location.']
                     ];

my $tablesDependedOn = [
                        ['DoTS::SnpFeature', 'Lookups of SNP source_ids to match to na_feature_ids'],
                        ['SRes::OntologyTerm', 'Lookups of characteristics'],
                        ['SRes::OntologySynonym', 'Lookups of characteristics'],
                        ['SRes::ExternalDatabase', 'Lookups of external database specifications'],
                        ['SRes::ExternalDatabaseRelease', 'Lookups of external database specifications'],
			['Study::Study', 'Lookups of study_ids for linking.']
 
];

my $howToRestart = <<PLUGIN_RESTART;
Provide a revised input file and a --protocolAppNodeId to resume a load.
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
		     cvsRevision => '$Revision: 18474 $', # cvs fills this in!
		     name => ref($self),
		     argsDeclaration => $argsDeclaration,
		     documentation => $documentation
		    });

  return $self;
}

my %naSequenceMap = undef;
my $snpExternalDbRlsId;
my %ontologyTermMap = undef;

#######################################################################
# Main Routine
#######################################################################


sub run {
  my ($self) = @_;

  $snpExternalDbRlsId = $self->getExtDbRlsId($self->getArg('snpExtDbRlsSpec'));
  my $protocolAppNode = $self->loadProtocolAppNode();
  $self->loadCharacteristics($protocolAppNode);
  $self->linkStudy($protocolAppNode) if ($self->getArg('studyId'));
  $self->loadResults($protocolAppNode);
}

sub linkStudy {
  my ($self, $protocolAppNode) = @_;
  my $studyId = $self->getArg('studyId');
  my $study = GUS::Model::Study::Study->new({study_id => $studyId});
  if ($study->retrieveFromDB()) {
    my $studyLink = GUS::Model::Study::StudyLink->new({study_id => $studyId,
						       protocol_app_node_id => $protocolAppNode->getProtocolAppNodeId()
						      });

    $studyLink->submit() unless ($studyLink->retrieveFromDB());
  }
  else {
    $self->error("No record for study_id $studyId found in Study.Study.");
  }
}


sub fetchSnpNAFeatureId {
  my ($self, $snpId, $mergeFeatureRelationTypeId) = @_;

  my $snpFeature = GUS::Model::DoTS::SnpFeature->new({source_id => $snpId,
						      external_database_release_id => $snpExternalDbRlsId});

  unless ($snpFeature->retrieveFromDB()) {
    if ($self->getArg('skipMissingSNPs')) {
	# $self->log("No record found for $snpId in DoTS.SnpFeature") if ($self->getArg('verbose'));
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

    unless (exists $ontologyTermMap{$term . '_' . $xdbr}) {
      my $xdbrId = $self->getExtDbRlsId($xdbr);
      my $ontologyTerm = GUS::Model::SRes::OntologyTerm->new({
							      name => $term,
							      external_database_release_id => $xdbrId
							     });

      
      if (!$ontologyTerm->retrieveFromDB()) {
	# try source_id
	$ontologyTerm = GUS::Model::SRes::OntologyTerm->new({ 
							     source_id => $term,
							     external_database_release_id => $xdbrId
							});
      }

      if (!$ontologyTerm->retrieveFromDB()) { # if still not found
	# try synonym
	$ontologyTerm = GUS::Model::SRes::OntologySynonym->new({
								      ontology_synonym => $term,
								      external_database_release_id => $xdbrId
								     });
      }

      if (!$ontologyTerm->retrieveFromDB()) { # if still not found
	$self->error("Ontology Term: $term ($xdbr) not found in SRes.OntologyTerm or SRes.OntologySynonym");
      }

      # otherwise ...set map value to reduce future lookups
      $ontologyTermMap{$term . '_' . $xdbr} = $ontologyTerm->getOntologyTermId();
    }
    return $ontologyTermMap{$term . '_' . $xdbr};
}

sub link2table { # create entry in SRes.Characteristic that links the protocol app node to a result table
  my ($self, $protocolAppNodeId, $table) = @_;

  my $tableId = $self->className2TableId($table);
  my $characteristic = GUS::Model::Study::Characteristic->new({
							       value => $table,
							       table_id => $tableId,
							       protocol_app_node_id => $protocolAppNodeId
							      });
  $characteristic->submit() unless ($characteristic->retrieveFromDB());

  return 1;
}

sub getTypeId {
  my ($self, $typeStr) = @_;
  my $typeId = undef;
  if ($typeStr) {
    my @type = split ';',  $typeStr; # term;xdbr
    $self->log(Dumper(\@type));
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

    if ($fieldValues->{phenotype}) { # if a value is present
      $fieldValues->{phenotype_id} = $self->fetchOntologyTermId($fieldValues->{phenotype}, $fieldValues->{phenotype_xdbr});
    }
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

    $self->link2table($protocolAppNode->getProtocolAppNodeId(), 'Results::SeqVariation');

    return $protocolAppNode;
}

sub insertCharacteristic {
  my ($self, $protocolAppNode, $term, $xdbr) = @_;
  my $ontologyTermId = $self->fetchOntologyTermId($term, $xdbr);
  my $characteristic = GUS::Model::Study::Characteristic->new({ontology_term_id => $ontologyTermId});
  $characteristic->setParent($protocolAppNode);
  $characteristic->submit();
}

sub loadCharacteristicsFromFile {
    my ($self, $protocolAppNode) = @_;

    my $cfName = $self->getArg('characteristicFile');
    if ($cfName) {
      my $fh = FileHandle->new;
      $fh->open("<$cfName") || $self->error("Error opening characteristic file: $cfName");
      while(<$fh>) {
	chomp;
	my ($term, $xdbr) = split /\t/;
	$self->insertCharacteristic($protocolAppNode, $term, $xdbr);
      }
      $fh->close();
    }
}

sub loadCharacteristics {
  my ($self, $protocolAppNode) = @_;
  # load from file
  $self->loadCharacteristicsFromFile($protocolAppNode);

  # load from list
  my $characteristics = $self->getArg('characteristics');
  foreach my $characteristic (@{$characteristics}) {
    my ($term, $xdbr) = split ';', $characteristic;
    $self->insertCharacteristic($protocolAppNode, $term, $xdbr);
  }
}

sub fetchNaSequenceId {
  my ($self, $chr) = @_;

  unless (exists $naSequenceMap{$chr}) {
    my $naSequenceXdbrId = $self->getExtDbRlsId($self->getArg('sequenceExtDbRlsSpec'));
    my $naSequence = GUS::Model::DoTS::ExternalNASequence->new({source_id => $chr,
								external_database_release_id => $naSequenceXdbrId});
    if ($naSequence->retrieveFromDB()) {
      $naSequenceMap{$chr} = $naSequence->getNaSequenceId();
      undef $naSequence;
    }
    else {
      $self->error("No sequence for $chr found in the DB");
    }
  }

  return $naSequenceMap{$chr};
}


sub loadSegmentResult {
    my ($self, $sourceId, $fieldValues, $protocolAppNodeId, $hasSegmentResultLink) = @_;
    
    my $chr = undef;
    my $location = undef;
    ($chr, $location) = split(':', $sourceId) if ($sourceId =~ /:/);
    ($chr, $location) = split('-', $sourceId) if ($sourceId =~ /\-/);

    $chr = 'chr' . $chr;

    my $naSequenceId = $self->fetchNaSequenceId($chr);
    
    my $segmentResult = GUS::Model::Results::SegmentResult->new({
         na_sequence_id => $naSequenceId,
         protocol_app_node_id => $protocolAppNodeId,
         segment_start => $location
});

 
    $segmentResult->setPValue($fieldValues->{p_value}) if (exists $fieldValues->{p_value});
    $segmentResult->setCategoricalValue($fieldValues->{allele}) if (exists $fieldValues->{allele});
    $segmentResult->submit();

    # $self->log("Inserted result for $sourceId in Results::SegmentResult") if ($self->getArg('verbose'));
    if (!$hasSegmentResultLink) {
      $self->link2table($protocolAppNodeId, 'Results::SegmentResult');
      $hasSegmentResultLink = 1;
    }
    return $hasSegmentResultLink;
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
    my $hasSegmentResultLink = 0;
    my $currentSnp = undef;
    my $naFeatureId = undef;

    while(<$fh>) {
	my ($sourceId, @values) = split /\t/;

	$self->log($sourceId) if ($self->getArg('veryVerbose'));

	chomp(@values);

	my %fieldValues = undef;
	@fieldValues{@fields} = @values; # create hash mapping field name => value

	# need to clean up field values (set empty strings to undef)
	# and fetch ontology_term_ids for phenotypes
	%fieldValues = $self->parseFieldValues(\%fieldValues);

	# reduce lookups b/c sometimes multiple annotations for single SNP
	$naFeatureId = ($currentSnp ne $sourceId) ? $self->fetchSnpNAFeatureId($sourceId) : $naFeatureId;
	$currentSnp = $sourceId;
	
	if (!$naFeatureId) {
	  if ($self->getArg('loadSegmentResults') and $sourceId !~ 'rs') {
	    $hasSegmentResultLink = $self->loadSegmentResult($sourceId, \%fieldValues, 
							     $protocolAppNode->getProtocolAppNodeId(), 
							     $hasSegmentResultLink);	    
	  }
	 
	}
	else {
	  $fieldValues{snp_na_feature_id} = $naFeatureId;
	  $fieldValues{protocol_app_node_id} = $protocolAppNode->getProtocolAppNodeId();
	  
	  if ($self->getArg('veryVerbose')) {
	    $self->log(Dumper(\%fieldValues));
	  }

	  my $seqVariationResult = GUS::Model::Results::SeqVariation->new(\%fieldValues);
	  $seqVariationResult->submit(undef, 1); # noTran = 1 --> do not commit at this point
	}

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

  return ('Results.SeqVariation',
	  'Study.Characteristic',
	  'Study.StudyLink',
	  'Study.ProtocolAppNode'
      );
}

1;
