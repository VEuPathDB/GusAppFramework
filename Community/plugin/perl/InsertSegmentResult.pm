#######################################################################
##                 InsertSegmentResult.pm
##
## Loads results from tab-delimited file into Results.SegmentResult
## also links results to annotations via the Study.ProtocolAppNode
##
## 
## $Id: InsertSegmentResult.pm allenem $
##
#######################################################################

package GUS::Community::Plugin::InsertSegmentResult;

@ISA = qw( GUS::PluginMgr::Plugin);

use strict 'vars';

use GUS::PluginMgr::Plugin;
use lib "$ENV{GUS_HOME}/lib/perl";

use GUS::Model::Study::ProtocolAppNode;
use GUS::Model::Study::Characteristic;
use GUS::Model::SRes::OntologyTerm;
use GUS::Model::SRes::OntologySynonym;
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
	       descr => "The type of dataset specified as an ontology term source_ref",
	       constraintFunc => undef,
	       reqd           => 0,
	       isList         => 0 }),
   stringArg({ name  => 'subType',
	       descr => "sub-type defined as an ontology term source ref",
	       constraintFunc => undef,
	       reqd           => 0,
	       isList         => 0 }),
 
  booleanArg({ name  => 'negLogP',
		descr => "transform pvalues using -log10",
		constraintFunc => undef,
		reqd           => 0,
		isList         => 0 }),

 booleanArg({ name  => 'isZeroBased',
		descr => "coordinate system is zero-based; when specified adds 1 to start",
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
If flag --loadSegmentResults is specified, will load data that cannot be linked to a dbSNP rs Id 
into Results.SegmentResult
PLUGIN_PURPOSE

my $tablesAffected = [
                      ['Study::ProtocolAppNode', 'Each dataset is represented by one record.'],
                      ['Study::Characteristic', 'Each record links a dataset to an ontology term.'],
                      ['Results::SegmentResult', 'Each records stores a pvalue for an unmapped location.']
                     ];

my $tablesDependedOn = [
                        ['DoTS.ExternalNASequence', 'Lookups of sequence source_ids'],
                        ['SRes.OntologyTerm', 'Lookups of characteristics'],
                        ['SRes.OntologySynonym', 'Lookups of characteristics'],
                        ['SRes.ExternalDatabase', 'Lookups of external database specifications'],
                        ['SRes.ExternalDatabaseRelease', 'Lookups of external database specifications']
 
];

my $howToRestart = <<PLUGIN_RESTART;
Provide a revised input file and a --protocolAppNodeId to resume a load.
PLUGIN_RESTART

my $failureCases = <<PLUGIN_FAILURE_CASES;
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
INPUT FILE must be tab-delimited with columns should be named for fields in the Results.SegmentResult table,
except for 'sequence_source_id' (e.g., chromosome), which should match a source_id in DoTS.ExternalNASequence associated with the sequenceExtDbRlsSpec

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
		     cvsRevision => '$Revision: 19979 $', # cvs fills this in!
		     name => ref($self),
		     argsDeclaration => $argsDeclaration,
		     documentation => $documentation
		    });

  return $self;
}

my %naSequenceMap = undef;

#######################################################################
# Main Routine
#######################################################################


sub run {
  my ($self) = @_;

  my $protocolAppNode = $self->loadProtocolAppNode();
  $self->loadCharacteristics($protocolAppNode);
  $self->loadResults($protocolAppNode);

}

sub fetchOntologyTermId {
    my ($self, $term, $xdbr) = @_;

    # my $xdbrId = $self->getExtDbRlsId($xdbr);
    my $ontologyTerm = GUS::Model::SRes::OntologyTerm->new({
							    name => $term,
							   });

    return $ontologyTerm->getOntologyTermId() if ($ontologyTerm->retrieveFromDB());



    # otherwise try source_id
    $ontologyTerm = GUS::Model::SRes::OntologyTerm->new({
							 source_id => $term,
							});
    return $ontologyTerm->getOntologyTermId() if ($ontologyTerm->retrieveFromDB());

    (my $sourceRef = $term) =~ s/:/_/;
    $ontologyTerm = GUS::Model::SRes::OntologyTerm->new({
							 source_id => $sourceRef,
							});

    return $ontologyTerm->getOntologyTermId() if ($ontologyTerm->retrieveFromDB();)


    # otherwise try synonym
    my $ontologySynonym = GUS::Model::SRes::OntologySynonym->new({
								  ontology_synonym => $term,
								   });

    return $ontologySynonym->getOntologyTermId() if $ontologySynonym->retrieveFromDB();

    # otherwise ... not found
    $self->error("Ontology Term: $term ($xdbr) not found in SRes.OntologyTerm or SRes.OntologySynonym");
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

  if (exists $fieldValues->{p_value}) {
    $fieldValues->{p_value} = $self->negLog10($fieldValues->{p_value}) if ($self->getArg('negLogP'));
  }

  if (exists $fieldValues->{segment_start}) {
    $fieldValues->{segment_start} = $fieldValues->{segment_start} + 1 if ($self->getArg('isZeroBased'));
  }

  # map sequence source id to na sequence
  $self->error("Must specify a sequence_source_id for each row in the input file")
    if (!exists $fieldValues->{sequence_source_id});
  $fieldValues->{na_sequence_id} = $self->fetchNaSequenceId($fieldValues->{sequence_source_id});
  delete $fieldValues->{sequence_source_id};

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
      $protocolAppNode->submit() unless $protocolAppNode->retrieveFromDB();
    }
     
    $self->link2table($protocolAppNode->getProtocolAppNodeId(), 'Results::SegmentResult');

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

sub loadResults {
    my ($self, $protocolAppNode) = @_;

    # begin transaction management
    $self->getDb()->manageTransaction(undef, "begin"); # start a transaction

    my $fName = $self->getArg('inFile');
    my $fh = FileHandle->new;
    $fh->open("<$fName") || $self->error("Unable to open data file: $fName\n");

    my $header = <$fh>;
    my @fields = split /\t/, $header;
    chomp(@fields);

    my $recordCount = 0;
    while(<$fh>) {
	my @values = split /\t/;
	chomp(@values);

	my %fieldValues = undef;
	@fieldValues{@fields} = @values; # create hash mapping field name => value

	# need to clean up field values (set empty strings to undef)
	# and map sequence_source_id
	%fieldValues = $self->parseFieldValues(\%fieldValues);
	$fieldValues{protocol_app_node_id} = $protocolAppNode->getProtocolAppNodeId();

	$self->log(Dumper(\%fieldValues)) if ($self->getArg('veryVerbose'));
	
	my $segmentResult = GUS::Model::Results::SegmentResult->new(\%fieldValues);
	$segmentResult->submit(undef, 1); # noTran = 1 --> do not commit at this point

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

  return ('Results.SegmentResult',
	  'Study.Characteristic',
	  'Study.ProtocolAppNode'
         );
}

1;
