package GUS::Community::Plugin::Test::TestLoadMageDoc;
use base qw(Test::Unit::TestCase);

use strict;
use Error qw(:try);
use Log::Log4perl qw(get_logger :levels);

use  GUS::ObjRelP::DbiDatabase;
use GUS::Supported::GusConfig;

use GUS::Model::Study::Study;
use GUS::Model::RAD::StudyAssay;
use GUS::Model::RAD::Assay;

use RAD::MR_T::MageImport::Service::Reader::MockReader;
use RAD::MR_T::MageImport::Service::Translator::VoToGusTranslator;
use RAD::MR_T::MageImport::Service::Tester::SqlTester;

use Data::Dumper;

Log::Log4perl->init_once("$ENV{GUS_HOME}/config/log4perl.config");
my $sLogger = get_logger("RAD::MR_T::MageImport::Service");

my ($loadMageDoc, $testCount);

# my $args = {configfile => '/home/jbrestel/projects/RAD/MR_T/lib/perl/MageImport/Test/config.xml',
#             magefile => '',
#             commit => 0,
#            };
#my $ga = GUS::PluginMgr::GusApplication->new();

#--------------------------------------------------------------------------------

sub new {
  my $self = shift()->SUPER::new(@_);

  $testCount = scalar $self->list_tests();

  my @properties;

  my $configFile = "$ENV{GUS_HOME}/config/gus.config";

  unless(-e $configFile) {
    my $error = "Config file $configFile does not exist.";
    die $error;
  }

  my $config = GUS::Supported::GusConfig->new($configFile);
  
  my $login       = $config->getDatabaseLogin();
  my $password    = $config->getDatabasePassword();
  my $core        = $config->getCoreSchemaName();
  my $dbiDsn      = $config->getDbiDsn();
  my $oraDfltRbs  = $config->getOracleDefaultRollbackSegment();

  my $database;
  unless($database = GUS::ObjRelP::DbiDatabase->getDefaultDatabase()) {
    $database = GUS::ObjRelP::DbiDatabase->new($dbiDsn, $login, $password,
                                                  0,0,1,$core, $oraDfltRbs);
  }

  $self->{_dbi_database} = $database;

  return $self;
}

#--------------------------------------------------------------------------------

sub set_up {
  my ($self) = @_;

  #$loadMageDoc = $ga->newFromPluginName('GUS::Community::Plugin::LoadMageDoc');

  #$load->initDb(

  #my $argDecl = [@{$loadMageDoc->getArgsDeclaration()},
  #               @{$ga->getStandardArgsDeclaration()},
  #              ];

  #foreach my $arg (@$argDecl) {
  #  my $name = $arg->getName();

 #   unless(exists $args->{$name}) {
 #     $args->{$name} = $arg->getValue();
 #   }
 # }


  #$loadMageDoc->initArgs($args);

  my $database =   GUS::ObjRelP::DbiDatabase->getDefaultDatabase();
  my $val = 0;  

  $database->setCommitState(0);

  $database->setDefaultProjectId($val);
  $database->setDefaultUserId($val);
  $database->setDefaultGroupId($val);
  $database->setDefaultAlgoInvoId(-99);

  $database->setDefaultUserRead(1);
  $database->setDefaultUserWrite(1);
  $database->setDefaultGroupRead($val);
  $database->setDefaultGroupWrite($val);
  $database->setDefaultOtherRead($val);
  $database->setDefaultOtherWrite($val);
}

#--------------------------------------------------------------------------------

sub tear_down {
  my $self = shift;

  $testCount--;

  my $database = GUS::ObjRelP::DbiDatabase->getDefaultDatabase();
  $database->{'dbh'}->rollback();

  # LOG OUT AFTER ALL TESTS ARE FINISHED
  if($testCount <= 0) {
    $database->logout();
    print STDERR "LOGGING OUT FROM DBI DATABASE\n";
  }
}

#--------------------------------------------------------------------------------

sub test_run {
  my $self = shift;

  my $study = GUS::Model::Study::Study->new({name => 'test_study',
                                            contact_id => 9
                                            }); 

  $study->submit();
  $study->submit();

  my $sql = "select name from Study.study where contact_id = 9";

  my @names = $self->fetchArray($sql, []);

  $self->assert_equals(1, scalar(@names));
  $self->assert_equals('test_study', $names[0]);
}

#--------------------------------------------------------------------------------

sub test_run2 {
  my $self = shift;

  my $study = GUS::Model::Study::Study->new({name => 'test_study2',
                                            contact_id => 9
                                            }); 


  my $assay1 = GUS::Model::RAD::Assay->new({name => 'test_assay1',
                                            array_design_id => 9,
                                            operator_id => 9,
                                            });

  my $assay2 = GUS::Model::RAD::Assay->new({name => 'test_assay2',
                                            array_design_id => 9,
                                            operator_id => 9,
                                            });

  my $sa1 = GUS::Model::RAD::StudyAssay->new();
  my $sa2 = GUS::Model::RAD::StudyAssay->new();

  $sa1->setParent($study);
  $sa1->setParent($assay1);

  $sa2->setParent($study);
  $sa2->setParent($assay2);

  $study->submit();

  my $bindValues = [];

  my $sql = "select name from Study.study where contact_id = 9";

  my @studyNames = $self->fetchArray($sql, $bindValues);

  $self->assert_equals(1, scalar(@studyNames));
  $self->assert_equals('test_study2', $studyNames[0]);

  my $sql2 = "select name from RAD.assay where assay_id in 
                (select assay_id from Rad.StudyAssay where study_id in
                 (Select study_id from Study.study where contact_id = 9))";


  my @assayNames = $self->fetchArray($sql2, $bindValues);

  foreach my $name (@assayNames) {
    $self->assert_matches(qr/test_assay/, $name);
  }
}

#--------------------------------------------------------------------------------

sub test_run3 {
  my $self = shift;

  my $reader = RAD::MR_T::MageImport::Service::Reader::MockReader->new();
  my $docRoot = $reader->parse();

  my $translator =  RAD::MR_T::MageImport::Service::Translator::VoToGusTranslator->new();
  my $study = $translator->mapAll($docRoot);

  $study->submit();

  my $sqls = [
	      join("\t", '1', 'select count(*) from study.study where row_alg_invocation_id = -99', ''),
              join("\t", '\d+', 'select study_id from study.study where row_alg_invocation_id = -99', 'study_id'),
              join("\t", 'study', 'select name from study.study where study_id = $$study_id$$', ''),
              join("\t", '1', 'select count(*)  from study.studydesign where row_alg_invocation_id = -99 and study_id = $$study_id$$', ''),
              join("\t", '\d+', 'select study_design_id from study.studydesign where row_alg_invocation_id = -99', 'study_design_id'),
              join("\t", '2', 'select count(*) from study.studyfactor where row_alg_invocation_id = -99 and study_design_id = $$study_design_id$$', ''),
	      join("\t", '2', 'select count(*) from rad.studyassay where row_alg_invocation_id = -99 and study_id=$$study_id$$', ''),
	      join("\t", '2', 'select count(*) from rad.assay where row_alg_invocation_id = -99', ''),
	      join("\t", '3', 'select count(*) from rad.STUDYBIOMATERIAL where row_alg_invocation_id = -99 and study_id=$$study_id$$', ''),
	      join("\t", '3', 'select count(*) from study.biomaterialimp where row_alg_invocation_id = -99', ''),

	      join("\t", '0', 'select count(*) from rad.acquisition where row_alg_invocation_id = -99', ''),
	      join("\t", '0', 'select count(*) from rad.treatment where row_alg_invocation_id = -99', ''),


             ];

  my $fn = "dummyFile";
  my $handle = GUS::ObjRelP::DbiDatabase->getDefaultDatabase()->getDbHandle();

  my $tester = RAD::MR_T::MageImport::Service::Tester::SqlTester->new($fn, $handle);
  $tester->{_lines_array} = $sqls;
  $sLogger->debug("****Dump the sqlTester return****", sub {Dumper($tester->parseLines())});

}


sub test_run4 {
  my $self = shift;

  my $reader = RAD::MR_T::MageImport::Service::Reader::MockReader->new();
  my $docRoot = $reader->parse();

  my $translator =  RAD::MR_T::MageImport::Service::Translator::VoToGusTranslator->new();
  my $study = $translator->mapAll($docRoot);

  if(my @studyAssay = $study->getChildren("GUS::Model::RAD::StudyAssay")){
    foreach my $studyAssay (@studyAssay){
      my $assay = $studyAssay->getParent("GUS::Model::RAD::Assay");
      $study->addToSubmitList($assay);
    }
  }

  $study->submit();

  my $sqls = [
	      join("\t", '1', 'select count(*) from study.study where row_alg_invocation_id = -99', ''),
              join("\t", '\d+', 'select study_id from study.study where row_alg_invocation_id = -99', 'study_id'),
              join("\t", 'study', 'select name from study.study where study_id = $$study_id$$', ''),
              join("\t", '1', 'select count(*)  from study.studydesign where row_alg_invocation_id = -99 and study_id = $$study_id$$', ''),
              join("\t", '\d+', 'select study_design_id from study.studydesign where row_alg_invocation_id = -99', 'study_design_id'),
              join("\t", '2', 'select count(*) from study.studyfactor where row_alg_invocation_id = -99 and study_design_id = $$study_design_id$$', ''),
	      join("\t", '2', 'select count(*) from rad.studyassay where row_alg_invocation_id = -99 and study_id=$$study_id$$', ''),
	      join("\t", '2', 'select count(*) from rad.assay where row_alg_invocation_id = -99', ''),
	      join("\t", '3', 'select count(*) from rad.STUDYBIOMATERIAL where row_alg_invocation_id = -99 and study_id=$$study_id$$', ''),
	      join("\t", '3', 'select count(*) from study.biomaterialimp where row_alg_invocation_id = -99', ''),

	      join("\t", '\d+', 'select assay_id from rad.assay where row_alg_invocation_id = -99 and rownum<2', 'assay_id'),
	      join("\t", '4', 'select count(*) from rad.acquisition where row_alg_invocation_id = -99', ''),
	      join("\t", '2', 'select count(*) from rad.acquisition where row_alg_invocation_id = -99 and assay_id=$$assay_id$$', ''),
	      join("\t", '\d+', 'select acquisition_id from rad.acquisition where row_alg_invocation_id = -99 and assay_id=$$assay_id$$ and rownum<2', 'acquisition_id'),
	      join("\t", '8', 'select count(*) from rad.quantification where row_alg_invocation_id = -99', ''),
	      join("\t", '2', 'select count(*) from rad.quantification where row_alg_invocation_id = -99 and acquisition_id=$$acquisition_id$$', ''),
	      join("\t", '0', 'select count(*) from rad.treatment where row_alg_invocation_id = -99', ''),


             ];

  my $fn = "dummyFile";
  my $handle = GUS::ObjRelP::DbiDatabase->getDefaultDatabase()->getDbHandle();

  my $tester = RAD::MR_T::MageImport::Service::Tester::SqlTester->new($fn, $handle);
  $tester->{_lines_array} = $sqls;
  $sLogger->debug("****Dump the sqlTester return****", sub {Dumper($tester->parseLines())});

}

sub test_run5 {
  my $self = shift;

  my $reader = RAD::MR_T::MageImport::Service::Reader::MockReader->new();
  my $docRoot = $reader->parse();

  my $translator =  RAD::MR_T::MageImport::Service::Translator::VoToGusTranslator->new();
  my $study = $translator->mapAll($docRoot);

  if(my @studyBioMaterial = $study->getChildren("GUS::Model::RAD::StudyBioMaterial")){
    foreach my $studyBioMaterial (@studyBioMaterial){
      my $biomat = $studyBioMaterial->getParent("GUS::Model::RAD::BioMaterialImp");
      $study->addToSubmitList($biomat);
    }
  }

  $study->submit();

  my $sqls = [
	      join("\t", '1', 'select count(*) from study.study where row_alg_invocation_id = -99', ''),
              join("\t", '\d+', 'select study_id from study.study where row_alg_invocation_id = -99', 'study_id'),
              join("\t", 'study', 'select name from study.study where study_id = $$study_id$$', ''),
              join("\t", '1', 'select count(*)  from study.studydesign where row_alg_invocation_id = -99 and study_id = $$study_id$$', ''),
              join("\t", '\d+', 'select study_design_id from study.studydesign where row_alg_invocation_id = -99', 'study_design_id'),
              join("\t", '2', 'select count(*) from study.studyfactor where row_alg_invocation_id = -99 and study_design_id = $$study_design_id$$', ''),
	      join("\t", '2', 'select count(*) from rad.studyassay where row_alg_invocation_id = -99 and study_id=$$study_id$$', ''),
	      join("\t", '2', 'select count(*) from rad.assay where row_alg_invocation_id = -99', ''),
	      join("\t", '3', 'select count(*) from rad.STUDYBIOMATERIAL where row_alg_invocation_id = -99 and study_id=$$study_id$$', ''),
	      join("\t", '3', 'select count(*) from study.biomaterialimp where row_alg_invocation_id = -99', ''),
	      join("\t", '4', 'select count(*) from rad.treatment where row_alg_invocation_id = -99', ''),
	      join("\t", '5', 'select count(*) from rad.biomaterialmeasurement where row_alg_invocation_id = -99', ''),

	      join("\t", '\d+', 'select bio_material_id from study.biomaterialimp where row_alg_invocation_id = -99 and name=\'bioSource\'', 'bio_source_id'),
	      join("\t", '2', 'select count(*) from study.biomaterialimp where row_alg_invocation_id = -99 and name=\'bioSample\'', ''),
	      join("\t", '\d+', 'select bio_material_id from study.biomaterialimp where row_alg_invocation_id = -99 and name=\'bioSample\'', 'bio_sample_id'),
	      join("\t", '\d+', 'select bio_material_id from study.biomaterialimp where row_alg_invocation_id = -99 and name=\'labeledExtract\'', 'labeled_extract_id'),
	      join("\t", '0', 'select count(*) from rad.acquisition where row_alg_invocation_id = -99', ''),


             ];

  my $fn = "dummyFile";
  my $handle = GUS::ObjRelP::DbiDatabase->getDefaultDatabase()->getDbHandle();

  my $tester = RAD::MR_T::MageImport::Service::Tester::SqlTester->new($fn, $handle);
  $tester->{_lines_array} = $sqls;
  $sLogger->debug("****Dump the sqlTester return****", sub {Dumper($tester->parseLines())});

}


sub fetchArray {
  my ($self, $sql, $bindValues) = @_;

  my @rv;

  my $sh = $self->{_dbi_database}->getDbHandle()->prepare($sql);
  $sh->execute(@$bindValues);

  while(my @vals = $sh->fetchrow_array()) {
    push(@rv, @vals);
  }
  $sh->finish();

  return wantarray ?  @rv : \@rv;
}


#--------------------------------------------------------------------------------

1;
