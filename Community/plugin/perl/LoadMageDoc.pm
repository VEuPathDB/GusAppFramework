package GUS::Community::Plugin::LoadMageDoc;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
use Error qw(:try);

use GUS::PluginMgr::Plugin;

use RAD::MR_T::MageImport::ServiceFactory;
use RAD::MR_T::MageImport::Service::Translator::VoToGusTranslator;

my $documentation = {};

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
  my $purposeBrief = "";

  my $purpose = "";

  my $tablesAffected;

  my $tablesDependedOn;

  my $howToRestart = "";

  my $failureCases = "";

  my $notes = "";

  my $documentation = {purpose=>$purpose, purposeBrief=>$purposeBrief, tablesAffected=>$tablesAffected, tablesDependedOn=>$tablesDependedOn, howToRestart=>$howToRestart, failureCases=>$failureCases,notes=>$notes};

  return $documentation;
}

# ----------------------------------------------------------------------
# create and initalize new plugin instance.
# ----------------------------------------------------------------------

sub new {
  my ($class) = @_;
  my $self = {na_sequences => []
             };
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



=head plugin classes

=cut

=item run method

this is the main method

config file example:
         service=reader,validator,processor
         service.docType = Mageml
         validator.rules = BlankRule,BlankRule
         processor.modules = BlankModule

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
