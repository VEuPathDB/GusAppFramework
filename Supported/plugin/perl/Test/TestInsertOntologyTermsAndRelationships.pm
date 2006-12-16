package GUS::Supported::Plugin::Test::TestInsertOntologyTermsAndRelationships;
use base qw(GUS::PluginMgr::PluginTestCase);

use strict;

use Error qw(:try);

use GUS::Model::SRes::OntologyTerm;

#--------------------------------------------------------------------------------
# Create Global Stuff to be used by the tests... 
# These are will be set in the set_up method.  ie. they will be fresh for EACH test method below.

my $plugin; # Instance of InsertOntologyTermsAndRelationships

my $exampleFileLines;
my $nameToOntologyTermTypeMap;
my $nameToOntologyRelationshipTypeMap;

#--------------------------------------------------------------------------------

sub set_up {
  my ($self) = @_;

  my $pluginArgs = { inFile => "$ENV{GUS_HOME}/lib/perl/GUS/Supported/Plugin/Test/testMgedOntology.owl",
                     extDbName => "MGED Ontology",
                     extDbVersion => "1.2.0",
                     uri => 'http://mged.sourceforge.net/ontologies/MGEDontology.php',
                     parserType => 'MgedRdfRow',
                     debug => 0,
                   };

  # This will make the plugin being tested...
  $self->SUPER::set_up('GUS::Supported::Plugin::InsertOntologyTermsAndRelationships', $pluginArgs);

  $self->setExampleFileLines();
  $self->setNameToOntologyTermTypeMap();
  $self->setNameToOntologyRelationshipTypeMap();

  $plugin = $self->getPlugin();
}

#--------------------------------------------------------------------------------

sub setExampleFileLines {
  my $lines =  ["test_subject_1|test_predicate|test_object_1|test_type",
                "term_subject|term_predicate_def|term_object_def|definition",
                "test_subject_2|test_predicate|test_object_2|test_type",
                "term_subject|term_predicate_type|DataTypeProperty|instanceOf",
                "test_subject_3|test_predicate|test_object_3|test_type",
                "term_subject||irregular_term|test_type",
               ];

  # Replace the bar with tabs...
  foreach(@$lines) {
    $_ =~ s/\|/\t/g;
  }

  $exampleFileLines = $lines;
}

#--------------------------------------------------------------------------------

sub setNameToOntologyRelationshipTypeMap {
  $nameToOntologyRelationshipTypeMap = {hasValue => 1,
                                        someValuesFrom => 2,
                                        hasClass => 3,
                                        oneOf => 4,
                                        instanceOf => 5,
                                        intersectionOf => 6,
                                        subClassOf => 7,
                                        unionOf => 8,
                                        complementOf => 9,
                                        domain => 10,
                                        hasInstance => 11,
                                        hasThing => 12,
                                        hasDatabase => 13,
                                        test_type => 14,
                                       }
}

#--------------------------------------------------------------------------------

sub setNameToOntologyTermTypeMap {
  $nameToOntologyTermTypeMap =  {FunctionalProperty => 1,	
                                Individual => 2,
                                Class => 3,
                                DatatypeProperty => 4,
                                ObjectProperty => 5,
                                Datatype => 6,
                                Root => 7
                               };
}

#--------------------------------------------------------------------------------

sub test_run {
  my ($self) = @_;

  # The following sql is used to test database entries from your test File
  # regular expressions are used to test the returned values...

  # READ:  (Expect 8), (Actual = select count(*) from SRes.OntologyTerm...), optionalParam
  # READ:  (Expect 5), (Actual = select count(*) from SRes.OntologyRelationship...), optionalParam
  my $sqlList = [ ['9', 'select count(*) from SRes.OntologyTerm where row_alg_invocation_id = $$row_alg_invocation_id$$'],
                  ['7', 'Select count(*) from SRes.OntologyRelationship where row_alg_invocation_id = $$row_alg_invocation_id$$'],
                  ['\d+', 'select ontology_term_id from sres.ontologyterm where row_alg_invocation_id  = $$row_alg_invocation_id$$ and name = \'book\'', 'ontology_term_id'],
                  ['^A publication type', 'select definition from sres.ontologyterm where ontology_term_id = $$ontology_term_id$$'],
                ];

  $plugin->run();

  $self->sqlStatementsTest($sqlList);
}

#--------------------------------------------------------------------------------

sub test_parseTerms {
  my ($self) = @_;

  $plugin->setExtDbRls(-99);

  my $terms = $plugin->parseTerms($exampleFileLines, $nameToOntologyTermTypeMap);

  # Test the number of terms made... 
  $self->assert_equals(1, scalar(@$terms));

  # Test the object is the correct type
  foreach(@$terms) {
    $self->assert_equals('GUS::Model::SRes::OntologyTerm', ref($_));
  }

  my $testTerm = $terms->[0];

  $self->assert_equals(-99, $testTerm->getExternalDatabaseReleaseId());
  $self->assert_equals('#term_subject', $testTerm->getSourceId());
  $self->assert_equals('term_subject', $testTerm->getName());
  $self->assert_equals(2, $testTerm->getOntologyTermTypeId());
  $self->assert_equals('term_object_def', $testTerm->getDefinition());
  $self->assert_equals('http://mged.sourceforge.net/ontologies/MGEDontology.php#term_subject', $testTerm->getUri());
}

#--------------------------------------------------------------------------------

sub test_makeStringThing {
  my ($self) = @_;

  my $uri = "testUri";
  my $extDbRlsId = -99;

  my @result = $plugin->makeStringThing($nameToOntologyTermTypeMap, $uri, $extDbRlsId);

  $self->assert_equals(2, scalar(@result));

  my $string = $result[0];
  my $thing = $result[1];

  $self->assert_equals(-99, $string->getExternalDatabaseReleaseId());
  $self->assert_equals('testUri#string', $string->getUri());
  $self->assert_equals('#string', $string->getSourceId());
  $self->assert_equals('string', $string->getName());
  $self->assert_equals(6, $string->getOntologyTermTypeId());
  $self->assert_null($string->getDefinition());

  $self->assert_equals(-99, $thing->getExternalDatabaseReleaseId());
  $self->assert_equals('testUri#Thing', $thing->getUri());
  $self->assert_equals('#Thing', $thing->getSourceId());
  $self->assert_equals('Thing', $thing->getName());
  $self->assert_equals(7, $thing->getOntologyTermTypeId());
  $self->assert_null($thing->getDefinition());


  # Test that the exception is thrown
  my $termTypes = {Indivudual => 1,
                  FunctionalProperty => 2
                  };

  try {
    $plugin->makeStringThing($termTypes, $uri, $extDbRlsId);
    $self->assert(0, "Should have thrown an exception");
  } catch GUS::PluginMgr::PluginError with {};

}

#--------------------------------------------------------------------------------

sub test_parseRelationships {
  my ($self) = @_;

  my $terms = $plugin->parseTerms($exampleFileLines, $nameToOntologyTermTypeMap);

  my $testTerms = [GUS::Model::SRes::OntologyTerm->new({ontology_term_id => -99, name => 'test_subject_1'}),
                   GUS::Model::SRes::OntologyTerm->new({ontology_term_id => -99, name => 'test_subject_2'}),
                   GUS::Model::SRes::OntologyTerm->new({ontology_term_id => -99, name => 'test_subject_3'}),
                   GUS::Model::SRes::OntologyTerm->new({ontology_term_id => -99, name => 'test_object_1'}),
                   GUS::Model::SRes::OntologyTerm->new({ontology_term_id => -99, name => 'test_object_2'}),
                   GUS::Model::SRes::OntologyTerm->new({ontology_term_id => -99, name => 'test_object_3'}),
                 ];

  push(@$terms, @$testTerms);

  foreach my $term (@$terms) {
    $term->setId(-99);
  }

  my $relationships = $plugin->parseRelationships($terms, $exampleFileLines, $nameToOntologyRelationshipTypeMap);

  $self->assert_equals(3, scalar(@$relationships));

  foreach(@$relationships) {
    $self->assert_equals('GUS::Model::SRes::OntologyRelationship', ref($_));
  }

}

#--------------------------------------------------------------------------------

sub test_getTermIdFromName {
  my ($self) = @_;

  my $terms = [GUS::Model::SRes::OntologyTerm->new({name => 'test1', ontology_term_id => 1}),
               GUS::Model::SRes::OntologyTerm->new({name => 'test2', ontology_term_id => 2}),
               GUS::Model::SRes::OntologyTerm->new({name => 'test3', ontology_term_id => 3}),
               GUS::Model::SRes::OntologyTerm->new({name => 'test4', ontology_term_id => 4}),
              ];

  my $termId = $plugin->getTermIdFromName($terms, 'test3');

  $self->assert_equals(3, $termId);

  my $shouldBeNull = $plugin->getTermIdFromName($terms, 'test');

  $self->assert_null($shouldBeNull);
}

#--------------------------------------------------------------------------------

sub test_getObjectStringFromType {
  my ($self) = @_;

  my $subObj = $plugin->getObjectStringFromType($exampleFileLines, 'test_type');

  $self->assert_equals(4, scalar(keys %$subObj));

  $self->assert_equals('test_object_1', $subObj->{test_subject_1});
  $self->assert_equals('test_object_2', $subObj->{test_subject_2});
  $self->assert_equals('test_object_3', $subObj->{test_subject_3});
  $self->assert_equals('irregular_term', $subObj->{term_subject});
}

#--------------------------------------------------------------------------------

sub test_getOntologyTypes {
  my ($self) = @_;

  my $testHash = $plugin->getOntologyTypes("select 'test_key', 'test_value' from dual");

  $self->assert_equals('test_value', $testHash->{test_key});
}



1;
