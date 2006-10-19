package GUS::Community::Plugin::LoadMageDoc;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
use GUS::PluginMgr::Plugin;

use RAD::MR_T::MageImport::Service::MockReader;

my $documentation = {};

my $argsDeclaration 
  =[
    fileArg({name           => 'magefile',
	     reqd           => 1,
	     mustExist      => 1,
	    })
   ];


sub new {
  my ($class) = @_;
  my $self    = {};
  bless($self,$class);

  $self->initialize({requiredDbVersion => 3.5,
                     cvsRevision       => '$Revision: $',
                     name              => ref($self),
                     argsDeclaration   => $argsDeclaration,
		     documentation     => $documentation
                    });

  return $self;
}

sub run {
  my ($self) = @_;

  my $reader = RAD::MR_T::MageImport::Service::MockReader->new();

  my $docRoot = $reader->parse();

  my $study = $self->map2GUSObjTree($docRoot);

  $study->submit;
}

sub map2GUSObjTree {
 my ($self, $docRoot) = @_;

 my $study = GUS::Model::Study::Study->new();

#.......
#.......

 return $study;
}
