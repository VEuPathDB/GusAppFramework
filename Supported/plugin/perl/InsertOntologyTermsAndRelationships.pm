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

=head2 Subroutines

=over 4

=item C<run>

Reads in the Rdf File... Parses using the Java Ap depending on the parserType.
Converts to SRes::OntologyTerm and SRes::OntologyRelationships

B<Return type:> 

 C<string> Descriptive statement of how many rows were entered

=cut

sub run {
  my ($self) = @_;

  my $file = $self->getArg('inFile');
  my $parserType = $self->getArg('parserType');
  my $uri = $self->getArg('uri');

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

  my @terms = $self->makeStringThing($termTypes, $uri, $extDbRlsId);

  my $standardTerms = $self->parseTerms($lines, $termTypes);
  push(@terms, @$standardTerms);

  my $linesForIrregularTerms = $self->parseNoDefTerms($lines, $termTypes, \@terms);
  my $irregularTerms = $self->parseTerms($linesForIrregularTerms, $termTypes);
  push(@terms, @$irregularTerms);

  $self->submitObjectList(\@terms);
  $self->log("Inserted ", scalar(@terms), " SRes::OntologyTerms");

  my $relationships = $self->parseRelationships(\@terms, $lines, $relationshipTypes);
  $self->submitObjectList($relationships);

  my $termCount = scalar(@terms);
  my $relationshipCount = scalar(@$relationships);

  return "Inserted $termCount SRes::OntologyTerms and $relationshipCount SRes::OntologyRelationships";

}

#--------------------------------------------------------------------------------

=item C<readFile>

Opens the out file and reads ALL lines into an arrayref. (Chomps off the newline chars)

B<Parameters:>

 $fn(string): full path to the .out file

B<Return Type:> 

 C<ARRAYREF> Each element is a file line

=cut

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

=item C<parseTerms>

Loops through an array ref.  Each element of the array is split into 4 elements
subject, predicate, object, type

A a term has a type of "definition".  The subject will be the term name and the object will be the term Definition

For each Term, the OntologyTermType is found by looping through the lines again.  This time the type will be 
"instanceOf", the subject will be the same and the ontology_term_type_name will be the object.

Terms which cannot be mapped to an ontologytermtype are assigned "Individual";

B<Parameters:>

 $lines(ARRAYREF): list of the file lines
 $termTypes(HASHREF): hash linking the ontology term types to their ids

B<Return Type:> 

 C<[GUS::Model::SRes::OntologyTerm]> ArrayRef of SRes.OntologyTerms

=cut

sub parseTerms {
  my ($self, $lines, $termTypes) = @_;

  my @ontologyTerms;

  my $uri = $self->getArg('uri');
  my $extDbRlsId = $self->getExtDbRls();

  my $definitions = $self->getObjectStringFromType($lines, 'definition');
  my $types = $self->getObjectStringFromType($lines, 'instanceOf');

  foreach my $termName (keys %$definitions) {
    my $source = "#$termName";
    my $termUri =  $uri . $source;

    my $def = $definitions->{$termName};
    my $type = $types->{$termName};

    my $typeId = $termTypes->{$type};
    $typeId = $termTypes->{Individual} unless($typeId);

    my $ontologyTerm = GUS::Model::SRes::OntologyTerm->
      new({name => $termName,
           source_id => $source,
           ontology_term_type_id => $typeId,
           external_database_release_id => $extDbRlsId,
           uri => $termUri,
           definition => $def,
          });

    push(@ontologyTerms, $ontologyTerm);
  }

  return \@ontologyTerms;
}

#--------------------------------------------------------------------------------

=item C<makeStringThing>

String and Thing are created automatically.  Thing is the Root object

B<Parameters:>

 $termTypes(HASHREF): hash linking the ontology term types to their ids
 $uri(scalar): uri from the Arg
 $extDbRlsId(scalar): ExternalDatabaseReleaseId which was retrieved

B<Return Type:> 

 C<[GUS::Model::SRes::OntologyTerm]> SRes::OntologyTerms for string and Thing

=cut

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

=item C<parseNoDefTerms>

In an Rdf file... the object isn't needed to have a definition.  To populuate
SRes::OntologyRelationship, we need to create a SRes::OntologyTerm for these
anyway.

Loop through the relationships and find a distinct list of terms without declaired definitions.  
Make an arrayRef of string which can be made into ontology terms

B<Parameters:>

 $lines(ARRAYREF): list of the file lines
 $termTypes(HASHREF): hash linking the ontology term types to their ids
 $terms([GUS::Model::SRes::OntologyTerm]) ArrayRef of Official Terms with definitions

B<Return Type:> 

 C<ARRAYREF> List of Strings representing the new terms

=cut

sub parseNoDefTerms {
  my ($self, $lines, $termTypes, $terms) = @_;

  my %irregularTerms;
  my @additionalLines;

  foreach my $term (@$terms) {
    my $name = $term->getName();
    $irregularTerms{$name} = 0;
  }

  foreach my $line (@$lines) {
    my ($subject, $predicate, $object, $type) = split(/\t/, $line);

    next if(exists $irregularTerms{$object} || $type eq 'definition');
    $irregularTerms{$object} = 1;
  }

  foreach my $irregular (keys %irregularTerms) {
    next unless($irregularTerms{$irregular});
    next if($termTypes->{$irregular});
    next unless($irregular);

    push(@additionalLines , "$irregular\t\t\tdefinition");
    push(@additionalLines , "$irregular\t\t\tinstanceOf");
  }

  return \@additionalLines;
}

#--------------------------------------------------------------------------------

=item C<parseRelationships>

Loop through all the file lines and create the relationships.  Skip any row
with a type of "definition".  Skip any row which doesn't have a SRes::OntologyTerm
for both subject and object (these are required by the database schema)

Log to a file any lines which are skipped

B<Parameters:>

 $lines(ARRAYREF): list of the file lines
 $terms([GUS::Model::SRes::OntologyTerm]) ArrayRef of Official Terms with definitions
 $relationshipTypes(HASHREF): hash linking the ontology relationship types to their ids

B<Return Type:> 

 C<[GUS::Model::SRes::OntologyRelationship]>  ArrayRef of OntologyRelationships

=cut

sub parseRelationships {
  my ($self, $terms, $lines, $relationshipTypes) = @_;

  my $file = $self->getArg('inFile');
  my $log = $file . ".log";

  open(LOG, "> $log") or $self->error("Could Not open file $log for reading: $!");

  my @relationships;
  my $skipCount = 0;

  my $count = 0;

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

      $count++;
      if($count % 250 == 0) {
        $self->log("Inserted $count SRes::OntologyRelationships");
      }

    }
    else {
      print LOG "SKIPPED: $subject|$predicate|$object|$type\n";
      $skipCount++;
    }
  }

  close(LOG);
  $self->log("WARN:  Skipped $skipCount Lines");

  return \@relationships;
}

#--------------------------------------------------------------------------------

=item C<getTermIdFromName>

Helper method which loops through an array of SRes::OntologyTerms and returns its id (undef if not found)

B<Parameters:>

 $terms([GUS::Model::SRes::OntologyTerm]) ArrayRef of Official Terms with definitions
 $wantedName(scalar): Term that you want

B<Return Type:> 

 C<scalar>  SRes::ontologyTerm ID

=cut

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

=item C<getObjectStringFromType>

Loop through the file lines... get the statment object based on the type

B<Parameters:>

 $lines(ARRAYREF): list of the file lines
 $wantedType(scalar): Type of Term that you want

B<Return Type:> 

 C<HASHREF>  key is the subject, value is the object

=cut

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

=item C<getOntologyTypes>

Prepare and Execute an sql statment.  The key is the first value in the 
result, the value is the second value in the result;

B<Parameters:>

 $sql(scalar): Any sql statment can be used... Here used to map ontology[term|relationship] types to their ids

B<Return Type:> 

 C<HASHREF> 

=cut

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

sub undoTables {
  my ($self) = @_;

  return ('SRes.OntologyRelationship','SRes.OntologyTerm');
}

1;
