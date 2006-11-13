package GUS::Community::Plugin::Test::TestLoadMageDoc;
use base qw(Test::Unit::TestCase);

use strict;

use GUS::PluginMgr::GusApplication;

use Error qw(:try);
use GUS::PluginMgr::Args::ArgList;
use GUS::Community::Plugin::LoadMageDoc;

use  GUS::ObjRelP::DbiDatabase;

use GUS::Supported::GusConfig;

use GUS::Model::Study::Study;

use Data::Dumper;

use GUS::PluginMgr::PluginError;

my $args = {configfile => '/home/jbrestel/projects/RAD/MR_T/lib/perl/MageImport/Test/config.xml',
            magefile => '',
            commit => 0,
           };

my ($loadMageDoc, $testCount);

#my $ga = GUS::PluginMgr::GusApplication->new();

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
  $database->setDefaultAlgoInvoId($val);

  $database->setDefaultUserRead($val);
  $database->setDefaultUserWrite($val);
  $database->setDefaultGroupRead($val);
  $database->setDefaultGroupWrite($val);
  $database->setDefaultOtherRead($val);
  $database->setDefaultOtherWrite($val);

}

sub tear_down {
  my $self = shift;

  $testCount--;

  # LOG OUT AFTER ALL TESTS ARE FINISHED
  if($testCount <= 0) {
    GUS::ObjRelP::DbiDatabase->getDefaultDatabase()->logout();
    print STDERR "LOGGING OUT FROM DBI DATABASE\n";
  }  

}

sub test_run {
  my $self = shift;

  my $study = GUS::Model::Study::Study->new({name => 'test_study',
                                            contact_id => 9
                                            }); 

  $study->submit();

  my $sql = "select name from Study.study where contact_id = 9";

  my $sh = $self->{_dbi_database}->getDbHandle()->prepare($sql);
  $sh->execute();

  while(my ($name) = $sh->fetchrow_array()) {
    print "NAME=$name\n";
  }
  $sh->finish();

}
