package GUS::Community::Plugin::Test::TestLoadOntologyEntryFromMO;
use base qw(GUS::PluginMgr::PluginTestCase);

use strict;

use Error qw(:try);

use GUS::Model::SRes::OntologyTerm;

use GUS::PluginMgr::PluginError;

#--------------------------------------------------------------------------------
my $plugin;
#--------------------------------------------------------------------------------

sub set_up {
  my ($self) = @_;

  my $pluginArgs = { nameChangesFile => "$ENV{GUS_HOME}/config/sample_loadOntologyEntryFromMO.cfg",
                     externalDatabase => "MGED Ontology",
                     externalDatabaseRls => "1.3.1",
                     debug => 0,
                   };

  $self->SUPER::set_up('GUS::Community::Plugin::LoadOntologyEntryFromMO', $pluginArgs);

  $plugin = $self->getPlugin();
}

#--------------------------------------------------------------------------------

sub prepareForRun {
  my ($self) = @_;

  $plugin->setRootNode('ExperimentalProtocolType');

  my $category = GUS::Model::Study::OntologyEntry->new({value => 'ProtocolType'});
  $plugin->setRootParent($category);

  my $nameChanges = $plugin->getArg('nameChangesFile');
  $plugin->setNamesHashFromConfigFile($nameChanges);

  my $dbRlsId = $plugin->getExtDbRlsId($plugin->getArg('externalDatabase'),
                                       $plugin->getArg('externalDatabaseRls'));

  $plugin->setExternalDatabaseReleaseId($dbRlsId);
  $plugin->setOntologyTermTableId();
  $plugin->setSoExternalDatabaseRelease();

  my $dbh = $plugin->getQueryHandle();
  my $sh = $dbh->prepare($plugin->getOntologyTermChildrenSql);

  $plugin->setRelationshipQueryHandle($sh);
}

#--------------------------------------------------------------------------------

sub test_hasSeenOntologyEntry {
  my $self = shift;

  my $seen = $plugin->hasSeenOntologyEntry("testValue", "testCategory");
  $self->assert(!$seen, "Could not have been seen");
  $self->assert_equals(1, scalar(@{$plugin->getSeenOntologyEntry()->{testValue}}));

  my $seenAgain = $plugin->hasSeenOntologyEntry("testValue", "testCategory");
  $self->assert($seenAgain, "Should have been seen");
  $self->assert_equals(2, scalar(@{$plugin->getSeenOntologyEntry()->{testValue}}));

  my $anotherTestValue = $plugin->hasSeenOntologyEntry("testValue", "testCategory2");
  $self->assert(!$anotherTestValue, "Should not have been seen");
  $self->assert_equals(3, scalar(@{$plugin->getSeenOntologyEntry()->{testValue}}));

  my $different = $plugin->hasSeenOntologyEntry("differentValue", "testCategory");
  $self->assert(!$different, "Could not have been seen");
  $self->assert_equals(1, scalar(@{$plugin->getSeenOntologyEntry()->{differentValue}}));

}

#--------------------------------------------------------------------------------

sub test_run {
  my $self = shift;

  $self->prepareForRun();

  my $dbh = $plugin->getQueryHandle();
  my $sh = $dbh->prepare("select ontology_entry_id from Study.ONTOLOGYENTRY where value in ('infect', 'inoculate') and category = 'ExperimentalProtocolType'");
  $sh->execute();

  my ($infectOe) = $sh->fetchrow_array();
  $sh->finish();

  $plugin->run();

   #$self->getDbiDatabase()->{dbh}->rollback();

  # Should Skip any which don't have the ext_db_rls_id
  $plugin->setRootNode('exon');
  my $category = GUS::Model::Study::OntologyEntry->new({value => 'TheoreticalBioSequenceType'});
  $plugin->setRootParent($category);

  $plugin->run();

 my $sqlList = [ [$infectOe, 'select ontology_entry_id from Study.ONTOLOGYENTRY where value = \'inoculate\' and category = \'ExperimentalProtocolType\''],
                 ['^37$', 'select count(*) from Study.ontologyEntry where row_alg_invocation_id = $$row_alg_invocation_id$$'],
                 ['^0$', 'select count(*) from Study.ontologyEntry where row_alg_invocation_id = $$row_alg_invocation_id$$ and value = \'exon\''],
                ];

  $self->sqlStatementsTest($sqlList);
}

#--------------------------------------------------------------------------------

sub test_setNamesHashFromConfigFile {
  my $self = shift;

  $self->assert_null(keys(%{$plugin->getNamesHash}));

  my $file = $plugin->getArg('nameChangesFile');
  my $namesHash = $plugin->setNamesHashFromConfigFile($file);

  $self->assert_equals('array_manufacturing_protocol', $namesHash->{array_manufacturing});
  $self->assert_equals('element_design_protocol', $namesHash->{element_design});

  $self->assert_null($namesHash->{testNull});
}

#--------------------------------------------------------------------------------

sub test_processOntologyRelationships {
  my $self = shift;

  # The Run above is essentially testing this...(except for the error being thrown)

  try {
    $plugin->processOntologyRelationships("shouldFail", "");
    $self->assert(0, "SHOULD HAVE FAILED");
  } catch GUS::PluginMgr::PluginError with {};

}

#--------------------------------------------------------------------------------

sub test_loadOntologyEntry {
  my $self = shift;

  my $soArray = $plugin->setSoExternalDatabaseRelease();
  if(scalar @$soArray == 0) {
    print STDERR "WARN: Unable to test loadOntologyEntry\n";
    return;
  }

  my $extDbRls = $soArray->[0];

  my $soOe = GUS::Model::Study::OntologyEntry->new({value => 'testValue',
                                                    category => 'testCategory',
                                                    external_database_release_id => $extDbRls,
                                                   });

  my $parent = GUS::Model::Study::OntologyEntry->new({value => 'parentValue'});

  my $term = GUS::Model::SRes::OntologyTerm->new({name => 'testTerm',
                                                  definition => 'defTerm',
                                                  uri => 'uriTerm',
                                                  source_id => 'sourceTerm',
                                                 });

  my $oe = GUS::Model::Study::OntologyEntry->new({value => 'testValue',
                                                  category => 'testCategory',
                                                  name => 'user_defined',
                                                 });

  my $soRes = $plugin->loadOntologyEntry($soOe, $term, $parent);
  $self->assert_equals(0, $soRes);


  my $realRes = $plugin->loadOntologyEntry($oe, $term, $parent);
  $self->assert_equals(1, $realRes);

  $self->assert_equals('testTerm', $oe->getValue());
  $self->assert_equals('parentValue', $oe->getCategory());

  my $tryAgain = $plugin->loadOntologyEntry($oe, $term, $parent);
  $self->assert_equals(0, $tryAgain);

  $parent->setValue('DeprecatedTerms');

  my $deprecated = $plugin->loadOntologyEntry($oe, $term, $parent);
  $self->assert_equals('DeprecatedTerms_parentValue', $oe->getCategory());

  $oe->setId('');
  my $depNoId = $plugin->loadOntologyEntry($oe, $term, $parent);
  $self->assert_equals(0, $depNoId);
}

#--------------------------------------------------------------------------------

sub test_getParentInfo {
  my $self = shift;

  my $parent = GUS::Model::Study::OntologyEntry->new({value => 'testValue',
                                                      category => 'testCategory',
                                                      ontology_entry_id => 1,
                                                     });

  my $depParent =  GUS::Model::Study::OntologyEntry->new({value => 'DeprecatedTerms',
                                                          category => 'testCategory',
                                                          ontology_entry_id => 2,
                                                         });

  my $oe = GUS::Model::Study::OntologyEntry->new({value => 'testOe',
                                                  category => 'testOeCategory',
                                                  parent_id => 3,
                                                 });

  my ($id, $category) = $plugin->getParentInfo('test', $parent, $oe);
  $self->assert_equals(1, $id);
  $self->assert_equals('testValue', $category);

  my ($idDep, $categoryDep) = $plugin->getParentInfo('test', $depParent, $oe);
  $self->assert_equals(3, $idDep);
  $self->assert_equals('DeprecatedTerms_testOeCategory', $categoryDep);
}

#--------------------------------------------------------------------------------

1;
