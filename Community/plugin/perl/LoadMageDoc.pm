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

 my $radStudy;
 my @radAffiliations;
 my @radContacts;
 my @radAssays;


 foreach my $mageAff (@ $docRoot->affiliationVOs()){
   my %h;
   $h{name} = $mageAff->getName if $mageAff->getName;

   my $radAff = GUS::Model::SRes::Contact->new(%h);
   push @radAffiliations, $radAff;
 }

 foreach my $mageContact (@ $docRoot->personVOs()){
   my %h;
   $h{name} = $mageContact->getName if $mageContact->getName;
   $h{last} = $mageContact->getLast if $mageContact->getLast;
   $h{first} = $mageContact->getFirst if $mageContact->getFirst;

   my $radContact = GUS::Model::SRes::Contact->new(%h);

   $radContact->setParent($self->searchObjArrayByObjName(\@radAffiliations, $mageContact->getAffiliation->getName)) if $mageContact->getAffiliation;

   push @radContacts, $radContact;
 }


 my $mageStudy = $docRoot->getStudyVO();
 my %h;
 $h{name} = $mageStudy->getName() if $mageStudy->getName();
 # $h{description} = $mageStudy->getDescription() if $mageStudy->getDescription();

 $radStudy = GUS::Model::Study::Study->new(%h);
 # $radStudy->setParent($self->searchObjArrayByObjName(\@radContacts, $mageStudy->getContact()->getName()) ) if $mageStudy->getContact()->getName();


 foreach my $mageSD (@ $mageStudy->getDesigns){
   my %h;
   $h{name} = $mageSD->getName() if $mageSD->getName();
   my $radSD = GUS::Model::Study::StudyDesign->new(%h);
   $radSD->setParent($radStudy);

   my $radSDType = GUS::Model::Study::StudyDesignType->new();
   $radSDType->setParent($radSD);
   $radSDType->setParent($self->createRadOE($mageSD->getType, "studyDesign"));

   foreach my $mageSF (@ $mageSD->getFactors){
     my %h;
     $h{name} = $mageSF->getName() if $mageSF->getName();
     my $radSF = GUS::Model::Study::StudyFactor->new(%h);
     $radSF->setParent($radSD);
     $radSF->setParent($self->createRadOE($mageSF->getType, "studyFactor"));
   }

 }


#.......
#.......

 return $radStudy;
}



sub searchObjArrayByObjName{
 my ($self, $objArray, $name) = @_;
 foreach my $obj(@$objArray){
   return $obj if $obj->getName eq $name;
 }
}

sub createRadOE{
  my ($self, $mageOE, $type) = @_;

  my @modes    = qw( studyDesign studyFactor treatment protocol);
  my $modes_rx = '^('. join('|',@modes). ')$';

  if ($type =~ /$modes_rx/) {
    my $radOE = GUS::Model::Study::OntologyEntry->new({value=>$mageOE->getValue, category=>$mageOE->getCategory});
    RAD::MR_T::MageImport::MageImportOENotFoundError->new(
							  "OntologyEntry value: ".$mageOE->getValue."category: ".$mageOE->getCategory
							 )->throw() unless $radOE->retrieveFromDB;
    return $radOE;
  }
  else {

  }

}

1;
