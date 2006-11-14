package GUS::Community::Plugin::LoadMageDoc;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
use Error qw(:try);

use GUS::PluginMgr::Plugin;

use RAD::MR_T::MageImport::ServiceFactory;
use RAD::MR_T::MageImport::Service::Translator::VoToGusTranslator;

my $notes = <<PLUGIN_NOTES;
=pod

=head1 DISCLAIMER

This plugin will handle the one channel microarray data for now.

=over

=head1 Config XML file

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
                  })
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

# ----------------------------------------------------------------------
# create and initalize new plugin instance.
# ----------------------------------------------------------------------

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  my $documentation = &getDocumentation();
  my $argumentDeclaration = &getArgumentsDeclaration();


  $self->initialize({requiredDbVersion => 3.5,
		     cvsRevision => '$Revision:  1 $',
                     name => ref($self),
                     revisionNotes => '',
                     argsDeclaration => $argumentDeclaration,
                     documentation => $documentation});

  return $self;
}



=item run method

this is the main method

the idea here is to have serviceFactory to read this config file and automatically not statically create service classes

=cut

sub _run {
  my ($self) = @_;

  my %config = ParseConfig((-ConfigFile => $self->getArgs('configfile'), -AutoTrue => 1));

  my $serviceFactory = RAD::MR_T::MageImport::ServiceFactory->new(\%config);

  my $reader =  $serviceFactory->getServiceByName('reader');
  my $docRoot = $reader->parse($self->getArgs('magefile'));

  if($config{modules}){
    my @pModules = split(/,/, $config{modules});

    my $processor = $serviceFactory->getServiceByName('processor');;
    $processor->process($docRoot);
  }

  if($config{rules}){
    my @rules = split(/,/, $config{rules});

    my $validator = $serviceFactory->getServiceByName('validator');;
    $validator->check($docRoot);
  }

  my $translator = $serviceFactory->getServiceByName('translator');
  my $study = $translator->mapAll($docRoot);

  $study->submit;

  # Sql Tester
}





1;
