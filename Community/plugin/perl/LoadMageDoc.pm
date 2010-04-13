package GUS::Community::Plugin::LoadMageDoc;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
use Error qw(:try);
use Log::Log4perl qw(get_logger :levels);
use XML::Simple;

use GUS::PluginMgr::Plugin;

use RAD::MR_T::MageImport::ServiceFactory;
use RAD::MR_T::MageImport::Service::Translator::VoToGusTranslator;
 
my $notes = <<PLUGIN_NOTES;
=pod

=head1 DISCLAIMER

This plugin will handle the one channel microarray data for now.

=over

=head1  Config XML file

This is plugin only takes one configuration xml file. The example will be:

<plugin>
  <property name="sqltesting" value="1"/>
  <property name="reporting" value="1"/>
  <property name="processing" value="1"/>
  <property name="validating" value="1"/>

<service id="reader" class="RAD::MR_T::MageImport::Service::Reader::MagemlReader">
  <property name="magemlfile" value="test.xml"/>
  <property name="two-dye" value="0"/>
</service>

<service id="translator" class="RAD::MR_T::MageImport::Service::Translator::VoToGusTranslator">
  <property name="retrieveOEFromDB" value="1"/>
  <property name="retrieveExtDBFromDB" value="1"/>
  <property name="retrieveProtocolFromDB" value="0"/>
  <property name="retrievePersonFromDB" value="0"/>
</service>

<service id="validator" baseClass="RAD::MR_T::MageImport::Service::Validator">
  <decorProperties name="rules" value="BlankRule"/>
</service>

<service id="sqlTester" baseClass="RAD::MR_T::MageImport::Service::SqlTester">
  <property name="sqlTestingFile" value="sqlTest.txt"/>
</service>

</plugin>

=head1 Argurments

=cut

=item --configfile

 only take one command line arguement

=cut

=cut

PLUGIN_NOTES


sub getArgumentsDeclaration { 
  return [ fileArg({name           => 'configfile',
                    format         => '',
                    descr          => '', 
                    reqd           => 1,
                    mustExist      => 1,
                    constraintFunc => undef,
                    isList => '',
                   }),
           stringArg({ name           => 'extDbRlsSpec',
                       descr          => 'external database name for the Study',
                       reqd           => 0,
                       constraintFunc => undef,
                       isList         => 0,
                     }),
           stringArg({ name           => 'sourceId',
                       descr          => 'source identifier for this Study',
                       reqd           => 0,
                       constraintFunc => undef,
                       isList         => 0,
                     }),
         ];
}


sub getDocumentation {
  # TODO:  Fill all this in
  my $purposeBrief = "Load MAGE documents into RAD";

  my $purpose = "";

  my $tablesAffected = ['Many tables in RAD, STUDY AND SRES SCHEMA'];

  my $tablesDependedOn = [
			  ['SRes::Contact', 'Used for BioSource Provider'],
			  ['Study::OntologyEntry', 'Used multiple times'],
			  ['RAD::Protocol', 'Protocol ids taken from config file']
			 ];

  my $howToRestart = "This plugin has no restart facility.";

  my $failureCases = "";

  my $documentation = {purpose=>$purpose, purposeBrief=>$purposeBrief, tablesAffected=>$tablesAffected, tablesDependedOn=>$tablesDependedOn, howToRestart=>$howToRestart, failureCases=>$failureCases,notes=>$notes};

  return $documentation;
}

=head1 Class methods

=over

=item new 

 create and initalize new plugin instance.

=cut

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  my $documentation = &getDocumentation();
  my $argumentDeclaration = &getArgumentsDeclaration();


  $self->initialize({requiredDbVersion => 3.5,
		     cvsRevision => '$Revision$', # cvs fills this in!
		     cvsTag => '$Name: $', # cvs fills this in!
                     name => ref($self),
                     revisionNotes => '',
                     argsDeclaration => $argumentDeclaration,
                     documentation => $documentation});

  return $self;
}



=item run method

this is the main method

the idea here is to have serviceFactory to read the config file and automagically create service classes

=cut

sub run {
  my ($self) = @_;

  my $coreInserts = $self->getTotalInserts();

  $self->setPointerCacheSize(40000);

  my $dbh = $self->getDbHandle();
  $dbh->{AutoCommit}=0;

  Log::Log4perl->init_once("$ENV{GUS_HOME}/config/log4perl.config");
  my $mLogger = get_logger("RAD::MR_T::MageImport");

  $self->setLogger($mLogger);

  my $config = $self->parseAndCheckConfig();

  my $serviceFactory = RAD::MR_T::MageImport::ServiceFactory->new($config);

  my $study = $self->createStudy($config, $serviceFactory);

  $self->submit($study);

  $self->testAndReport($serviceFactory, $dbh);

  if ($self->getArg('commit')) {
    $mLogger->fatal("Committing");
    $dbh->commit() or $self->error("Commit failed: " . $self->{'dbh'}->errstr());
  }
  else {
    $mLogger->fatal("Rolling Back DB");
    $dbh->rollback() or $self->error("Rollback failed: " . $self->{'dbh'}->errstr());
  }

  my $insertCount = $self->getTotalInserts() - $coreInserts;
  my $updateCount = $self->getTotalUpdates() || 0;

  my $msg = "Inserted $insertCount and Updated $updateCount";

  return($msg);
}

#--------------------------------------------------------------------------------

sub testAndReport {
  my ($self, $serviceFactory, $dbh) = @_;

  my $mLogger = $self->getLogger;

  if(my $tester = $serviceFactory->getServiceByName('tester')) {
    my $passedTest = $tester->test();
    $mLogger->info("Please see log file for test report");
    unless($passedTest) {
      $mLogger->fatal("Rolling Back DB");
      $dbh->rollback() or $self->error("Rollback failed: " . $self->{'dbh'}->errstr());

      $self->error("SQL TEST FAILURE!!");
    }
  }

  if(my $reporter = $serviceFactory->getServiceByName('reporter')) {
    $reporter->report();
    $mLogger->info("Please see log file for sql report");
  }

}


#--------------------------------------------------------------------------------

sub createStudy {
  my ($self, $config, $serviceFactory) = @_;

  my $mLogger = $self->getLogger;

  my $reader =  $serviceFactory->getServiceByName('reader');

  $mLogger->info("parse the mage file", $config->{service}->{reader}->{property}->{value});
  my $docRoot = $reader->parse();

  if (my $processor = $serviceFactory->getServiceByName('processor')){
    $mLogger->info("process the value objects using ", ref($processor));
    $processor->process($docRoot);
  }

  my $validator = $serviceFactory->getServiceByName('validator');

  $mLogger->info("validate the value objects using ", ref($validator));
  $validator->check($docRoot);

  my $translator = $serviceFactory->getServiceByName('translator');

  $mLogger->info("translate the value objects to GUS objects using ", ref($translator));
  my $study = $translator->mapAll($docRoot);

  if(my $extDbRlsSpec = $self->getArg('extDbRlsSpec')) {
    my $extDbRlsId = $self->getExtDbRlsId($extDbRlsSpec);
    $study->setExternalDatabaseReleaseId($extDbRlsId);
  }

  if(my $sourceId = $self->getArg('sourceId')) {
    $study->setSourceId($sourceId);
  }

  return $study;
}

#--------------------------------------------------------------------------------

sub parseAndCheckConfig {
  my ($self) = @_;

  my $mLogger = $self->getLogger;

  $mLogger->info("parse the config xml file", $self->getArg('configfile'));
  my $config = XMLin($self->getArg('configfile'),  'ForceArray' => 1);

  $mLogger->info("check the config xml file");
  $self->checkConfig($config);

  return $config;
}

#--------------------------------------------------------------------------------

=item checkConfig(\%config)

this is a very simple check config xml method, we should blow it up into a ConfigManager class,Note: for the case there is only one service, the config hash will be totally different

=cut

sub checkConfig{
  my ($self, $config) = @_;

  my $mLogger = $self->getLogger;

  my $services = $config->{service};

  my $reader = 0;
  my $translator = 0;

  foreach my $service ( keys %$services){
       $reader = 1 if $service eq 'reader';
       $translator = 1 if $service eq 'translator';
  }

  $reader = 1 if $services->{id} && $services->{id} eq 'reader';

  $mLogger->fatal("You must provide a reader in the configuration xml") unless $reader;
  $mLogger->fatal("You must provide a translator in the configuration xml") unless $translator;
#  $mLogger->fatal("You must provide a mage doc inside the reader block in the configuration xml") unless $config->{service}->{reader}->{property};

}

=item submit(Study)

Because "Children only submit parents if parent does not have a primary key (is new object that has not been submitted).  Then parent is submitted but does not submit any children.", we have submit those parent manually 

=cut

sub submit{
  my ($self, $study) = @_;

  my $mLogger = $self->getLogger;
  $mLogger->info("submit GUS objects");

#this will submit study, studydesign, studyfactor and assays if studyAssays are set
  if(my @studyAssay = $study->getChildren("GUS::Model::RAD::StudyAssay")){

    foreach my $studyAssay (@studyAssay){
      my $assay = $studyAssay->getParent("GUS::Model::RAD::Assay");
      $study->addToSubmitList($assay);
    }
  }

  if(my @studyBioMaterial = $study->getChildren("GUS::Model::RAD::StudyBioMaterial")){
    foreach my $studyBioMaterial (@studyBioMaterial){
      my $biomat = $studyBioMaterial->getParent("GUS::Model::Study::BioMaterialImp");
      $study->addToSubmitList($biomat);
    }
  }

  $study->submit;
}

=item setLogger(logger)

=cut

sub setLogger {$_[0]->{_logger} = $_[1]}

=item getLogger():logger

=cut

sub getLogger {$_[0]->{_logger}}



sub undoTables {
  return ('RAD.BioMaterialMeasurement',
          'RAD.Treatment',
          'RAD.StudyBioMaterial',
          'RAD.AssayBioMaterial',
          'RAD.AssayLabeledExtract',
          'Study.BioMaterialCharacteristic',
          'Study.LabeledExtract',
          'Study.BioSample',
          'Study.BioSource',
          'RAD.RelatedQuantification',
          'RAD.QuantificationParam',
          'RAD.Quantification',
          'RAD.RelatedAcquisition',
          'RAD.AcquisitionParam',
          'RAD.Acquisition',
          'RAD.StudyAssay',
          'RAD.AssayParam',
          'RAD.StudyDesignAssay',
          'RAD.StudyFactorValue',
          'RAD.Assay',
          'Study.StudyFactor',
          'Study.StudyDesignType',
          'Study.StudyDesignDescription',
          'Study.StudyDesign',
          'Study.Study',
          'RAD.LabelMethod',
          'RAD.ProtocolParam',
          'RAD.Protocol',
          'SRes.Abstract',
          'SRes.BibliographicReference',
          'SRes.Contact',
          'SRes.ExternalDatabaseRelease',
          'SRes.ExternalDatabase',
          'TESS.Protocol',
          'TESS.ProtocolParam',
          'TESS.Assay',
          'TESS.AssayParam',
          'TESS.Acquisition',
          'TESS.AcquisitionParam',
          'TESS.Quantification',
          'TESS.QuantificationParam',
          'TESS.StudyAssay',
          'TESS.StudyDesignAssay',
          'TESS.StudyFactorValue',
          'TESS.AssayBioMaterial',
         );
}
1;
