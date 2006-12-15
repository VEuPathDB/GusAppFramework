package GUS::Supported::Plugin::InsertOntologyTermsAndRelationships;

@ISA = qw(GUS::PluginMgr::Plugin);

# ----------------------------------------------------------------------

use strict;

use GUS::PluginMgr::Plugin;
use GUS::PluginMgr::PluginUtilities;

use UNIVERSAL qw(isa);

use FileHandle;

use GUS::Model::SRes::OntologyTerm;
use GUS::Model::SRes::OntologyRelationship;

use Data::Dumper;

my $argsDeclaration =
[

 fileArg({name           => 'inFile',
	  descr          => 'A file of Representing Ontology Terms and Relationships.  Currently owl format is Supported.',
	  reqd           => 1,
	  mustExist      => 1,
	  format         => 'rdf statements',
	  constraintFunc => undef,
	  isList         => 0, 
	 }),


 stringArg({ descr => 'Name of the External Database',
	     name  => 'extDbName',
	     isList    => 0,
	     reqd  => 1,
	     constraintFunc => undef,
	   }),

 stringArg({ descr => 'Version of the External Database Release',
	     name  => 'extDbVersion',
	     isList    => 0,
	     reqd  => 1,
	     constraintFunc => undef,
	   }),

 stringArg({ descr => 'uri for the OntlogyTerm',
	     name  => 'uri',
	     isList    => 0,
	     reqd  => 1,
	     constraintFunc => undef,
	   }),

 enumArg({  name => 'parserType',
	    descr => 'Which java parser should be used??...Currently only MGED Parser is Supported',
	    constraintFunc => undef,
	    reqd => 1,
	    isList => 0,
	    enum => "MgedRdfRow",
	   }),


];

my $purpose = <<PURPOSE;
The purpose of this plugin is to parse a an rdf file (list of ontology statements) and load as Ontology Terms and Relationships.  
PURPOSE

my $purposeBrief = <<PURPOSE_BRIEF;
The purpose of this plugin is to load Ontology Terms and Relationships.
PURPOSE_BRIEF

my $notes = <<NOTES;
This plugin calls a java parser which reads the input file using the java package Jena.  Jena is used to read the rdf file and convert
each statemnt into strings (subject, predicate, object).  


You must set your CLASSPATH variable to the following jar files:

 GUS-Supported.jar
 antlr-2.7.5.jar
 arq.jar
 commons-logging.jar
 concurrent.jar
 icu4j_3_4.jar
 iri.jar
 jena.jar
 jenatest.jar
 json.jar
 junit.jar
 log4j-1.2.12.jar
 stax-api-1.0.jar
 wstx-asl-2.8.jar
 xercesImpl.jar
 xml-apis.jar



The strings are then manipulated and printed to a file.  This manipulation of the strings is project specific (currently MGED.owl is supported).  

This plugin could be used for ANY file which can be read by Jena 
You would need to create a java class which implements org.gusdb.gus.supported.GusRdfRow
NOTES

my $tablesAffected = <<TABLES_AFFECTED;
SRes::OntologyTerm, SRes::OntologyRelationship
TABLES_AFFECTED

my $tablesDependedOn = <<TABLES_DEPENDED_ON;
SRes.OntologyTermType, SRes::OntologyRelationShipType
TABLES_DEPENDED_ON

my $howToRestart = <<RESTART;
No Restart utilities for this plugin.
RESTART

my $failureCases = <<FAIL_CASES;
FAIL_CASES

my $documentation = { purpose          => $purpose,
		      purposeBrief     => $purposeBrief,
		      notes            => $notes,
		      tablesAffected   => $tablesAffected,
		      tablesDependedOn => $tablesDependedOn,
		      howToRestart     => $howToRestart,
		      failureCases     => $failureCases };

my $numRelationships = 0;

# ----------------------------------------------------------------------

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  $self->initialize({ requiredDbVersion => 3.5,
		      cvsRevision       => '$Revision$',
		      name              => ref($self),
		      argsDeclaration   => $argsDeclaration,
		      documentation     => $documentation});

  return $self;
}

# ----------------------------------------------------------------------

sub getExtDbRls {$_[0]->{ext_db_rls_id}}
sub setExtDbRls {$_[0]->{ext_db_rls_id} = $_[1]}

# ----------------------------------------------------------------------

sub run {
  my ($self) = @_;

  my $file = $self->getArg('inFile');
  my $parserType = $self->getArg('parserType');

  my $extDbRlsId = $self->getExtDbRlsId($self->getArg('extDbName'),
                                        $self->getArg('extDbVersion'));

  $self->setExtDbRls($extDbRlsId);

  # This will create a file appending ".out" to the inFile 
  my $systemResult = system("java org.gusdb.gus.supported.OwlParser $file $parserType");

  unless($systemResult / 256 == 0) {
    $self->error("Could not Parse RDF file $file");
  }

  my $gusInFile = $file . ".out";

  my $lines = $self->readFile($gusInFile);

  my $termTypes = $self->getOntologyTypes("select name, ontology_term_type_id from SRes.ONTOLOGYTERMTYPE");
  my $relationshipTypes = $self->getOntologyTypes("select name, ontology_relationship_type_id from SRes.ONTOLOGYRELATIONSHIPTYPE");

  my $terms = $self->parseTerms($lines, $termTypes);
  $self->submitObjectList($terms);

  my $relationships = $self->parseRelationships($terms, $lines, $relationshipTypes);
  $self->submitObjectList($relationships);

  my $termCount = scalar(@$terms);
  my $relationshipCount = scalar(@$relationships);

  return "Inserted $termCount SRes::OntologyTerms and $relationshipCount SRes::OntologyRelationships";

}

#--------------------------------------------------------------------------------

sub readFile {
  my ($self, $fn) = @_;

  open(FILE, "< $fn") or $self->error("Could Not open file $fn for reading: $!");

  my @lines;

  while(<FILE>) {
    chomp;

    push(@lines, $_);
  }
  close(FILE);

  return \@lines;
}

#--------------------------------------------------------------------------------

sub parseTerms {
  my ($self, $lines, $termTypes) = @_;

  my $uri = $self->getArg('uri');

  my $extDbRlsId = $self->getExtDbRls();

  my @ontologyTerms = $self->makeStringThing($termTypes, $uri, $extDbRlsId);

  my $definitions = $self->getObjectStringFromType($lines, 'definition');
  my $types = $self->getObjectStringFromType($lines, 'instanceOf');

  foreach my $termName (keys %$definitions) {
    my $source = "#$termName";
    $uri = $uri . $source;

    my $def = $definitions->{$termName};
    my $type = $types->{$termName};

    my $typeId;
    if(!$type) {
      $self->log("WARN Skipping:  No type found for subject $termName");
    }
    else {
      $typeId = $termTypes->{$type};
      $typeId = $termTypes->{Individual} unless($typeId);

      my $ontologyTerm = GUS::Model::SRes::OntologyTerm->
        new({name => $termName,
             source_id => $source,
             ontology_term_type_id => $typeId,
             external_database_release_id => $extDbRlsId,
             uri => $uri,
             definition => $def,
            });

      push(@ontologyTerms, $ontologyTerm);
    }
  }

  return \@ontologyTerms;
}

#--------------------------------------------------------------------------------

sub makeStringThing {
  my ($self, $termTypes, $uri, $extDbRlsId) = @_;

  my $stringTypeId = $termTypes->{Datatype};
  my $thingTypeId = $termTypes->{Root};

  my $string = 'string';
  my $thing = 'Thing';

  my $stringSource = "#$string";
  my $thingSource = "#$thing";

  my $stringUri = $uri . $stringSource;
  my $thingUri = $uri . $thingSource;

  unless($stringTypeId && $thingTypeId) {
    $self->error("OntologyTermTypeId required for string [$stringTypeId] and thing [$thingTypeId]");
  }

  my $string = GUS::Model::SRes::OntologyTerm->
    new({ ontology_term_type_id => $stringTypeId,
          external_database_release_id => $extDbRlsId,
          source_id => $stringSource,
          uri => $stringUri,
          name => $string,
        });

  my $thing = GUS::Model::SRes::OntologyTerm->
    new({ ontology_term_type_id => $thingTypeId,
          external_database_release_id => $extDbRlsId,
          source_id => $thingSource,
          uri => $thingUri,
          name => $thing,
        });

  return($string, $thing);

}

#--------------------------------------------------------------------------------

sub parseRelationships {
  my ($self, $terms, $lines, $relationshipTypes) = @_;

  my @relationships;
  my $skipCount = 0;

  foreach my $line (@$lines) {
    my ($subject, $predicate, $object, $type) = split(/\t/, $line);

    next if($type eq 'definition');

    my $subjectTermId = $self->getTermIdFromName($terms, $subject);
    my $predicateTermId = $self->getTermIdFromName($terms, $predicate);
    my $objectTermId = $self->getTermIdFromName($terms, $object);

    my $relationshipTypeId = $relationshipTypes->{$type};
    unless($relationshipTypeId) {
      $self->error("OntologyRelationshipType is Required at line: $line");
    }

    my $relationship = GUS::Model::SRes::OntologyRelationship->
      new({subject_term_id => $subjectTermId,
           predicate_term_id => $predicateTermId,
           object_term_id => $objectTermId,
           ontology_relationship_type_id => $relationshipTypeId,
          });

    if($subjectTermId && $objectTermId && $relationshipTypeId) {
      push(@relationships, $relationship);
    }
    else {
      print STDERR "Skipping Relationship on line: $subject|$predicate|$object|$type\n" if($self->getArg('debug'));
      $skipCount++;
    }
  }

  $self->log("WARN:  Skipped $skipCount Lines");

  return \@relationships;
}

#--------------------------------------------------------------------------------

sub getTermIdFromName {
  my ($self, $terms, $wantedName) = @_;

  my $termId;

  foreach my $term (@$terms) {
    my $termName = $term->getName();

    if($termName eq $wantedName) {
      $termId = $term->getId();
    }
  }

  return $termId;
}


#--------------------------------------------------------------------------------

sub getObjectStringFromType {
  my ($self, $lines, $wantType) = @_;

  my %rv;

  foreach my $line (@$lines) {
    my ($subject, $predicate, $object, $type) = split(/\t/, $line);

    if($type eq $wantType) {
      $rv{$subject} = $object;
    }
  }
  return \%rv;
}


#--------------------------------------------------------------------------------

sub getOntologyTypes {
  my ($self, $sql) = @_;

  my %rv;

  my $sh = $self->getQueryHandle()->prepare($sql);
  $sh->execute();

  while(my ($name, $id) = $sh->fetchrow_array()) {
    $rv{$name} = $id;
  }
  $sh->finish();

  return \%rv;
}

#--------------------------------------------------------------------------------

sub submitObjectList {
  my ($self, $list) = @_;

  foreach my $gusObj (@$list) {
    $gusObj->submit();
  }
}

#--------------------------------------------------------------------------------


1;
