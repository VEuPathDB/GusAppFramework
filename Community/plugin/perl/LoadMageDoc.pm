package GUS::Community::Plugin::LoadMageDoc;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
use GUS::PluginMgr::Plugin;

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
  my $docType;
  my $reader = $self->createReader($docType);

  my $docRoot = $reader->parse();

  my $study = $self->map2GUSObjTree($docRoot);

  $study->submit;
}



sub createReader {
  my ($self, $docType) = @_;

  unless ($docType){
    return RAD::MR_T::MageImport::Service::MockReader->new();
  }

  my $readerClass = "RAD::MR_T::MageImport::Service::".$docType."Reader";
  my $require_p = "{require $readerClass; $readerClass->new }";
  my $reader = eval $require_p;

  RAD::MR_T::MageImport::MageImportReaderNotCreatedError->new($self."->createReader: ".$require_p)->throw() if $@;

  return $reader;
  
}

sub map2GUSObjTree {
 my ($self, $docRoot) = @_;

 my $radStudy;
 my @radAffiliations;
 my @radContacts;
 my @radExternalDbs;
 my @radAssays;
 my @radProtocols;
 my @radBioMaterials;


 $self->createRadAffiliations($docRoot->affiliationVOs(), \@radAffiliations);

 $self->createRadContacts($docRoot->personVOs(), \@radContacts, \@radAffiliations);

 $self->createRadExternalDatabases($docRoot->externalDatabaseVOs(), \@radExternalDbs);

 $radStudy = $self->getRadStudy($docRoot->getStudyVO());

 if(my $name = $docRoot->getStudyVO()->getContact()->getName()){
   $self->setRadStudyContact($name, $radStudy, \@radContacts);
 }

 $self->createRadStudyDesignAndFactors($docRoot->getStudyVO()->getDesigns, $radStudy);

 $self->createRadProtocols($docRoot->getProtcolVOs, \@radProtocols);

 $self->createRadAssays($docRoot->getAssayVOs, \@radAssays);




#.......

 return $radStudy;
}


sub createRadAffiliations{
  my ($self, $mageAffs, $radAffiliations) = @_;
  foreach my $mageAff (@ $mageAffs){
    my %h;
    $h{name} = $mageAff->getName if $mageAff->getName;
    my $radAff = GUS::Model::SRes::Contact->new(%h);
    push @$radAffiliations, $radAff;
  }
}


sub createRadContacts{
 my ($self, $magePersons, $radContacts, $radAffiliations) = @_;
 foreach my $mageContact (@ $magePersons ){
   my %h;
   $h{name} = $mageContact->getName if $mageContact->getName;
   $h{last} = $mageContact->getLast if $mageContact->getLast;
   $h{first} = $mageContact->getFirst if $mageContact->getFirst;

   my $radContact = GUS::Model::SRes::Contact->new(%h);

   if(my $name = $mageContact->getAffiliation->getName){
     $radContact->setParent($self->searchObjArrayByObjName($radAffiliations, $name)) ;
   }

   push @$radContacts, $radContact;
 }

}

# we have to assume edb  is already in RAD
sub createRadExternalDatabases{
  my ($self, $mageExtDbs, $radExtDbs) = @_;
  foreach my $mageExtDb (@ $mageExtDbs){
    my %h;
    $h{name} = $mageExtDb->getName if $mageExtDb->getName;
    my $radDb = GUS::Model::SRes::ExternalDatabase->new(%h);
    my $radDbRel;

    if ($mageExtDb->getVersion){
      my %hh;
      $hh{version} = $mageExtDb->getName; 
      $radDbRel = GUS::Model::SRes::ExternalDatabaseRelease->new(%hh);
    }
    else{
      $radDbRel = GUS::Model::SRes::ExternalDatabaseRelease->new();
    }

    $radDbRel->setParent($radDb);
    RAD::MR_T::MageImport::MageImportExtDbNotFoundError->new($self."->createRadExternalDatabases")->throw() unless $radDbRel->retrieveFromDB;
    push @$radExtDbs, $radDbRel;
  }
}

sub getRadStudy{
  my ($self, $mageStudy) = @_;
  my %h;
  $h{name} = $mageStudy->getName() if $mageStudy->getName();
  $h{description} = $mageStudy->getDescription() if $mageStudy->getDescription();

  my $radStudy = GUS::Model::Study::Study->new(%h);

  return $radStudy;
}

sub setRadStudyContact{
  my ($self, $name, $radStudy, $radContacts) = @_;
  $radStudy->setParent($self->searchObjArrayByObjName($radContacts, $name) );
}

sub createRadStudyDesignAndFactors{
 my ($self, $mageSDs, $radStudy) = @_;
 foreach my $mageSD (@ $mageSDs){
   my %h;
   $h{name} = $mageSD->getName() if $mageSD->getName();
   my $radSD = GUS::Model::Study::StudyDesign->new(%h);
   $radSD->setParent($radStudy);

   my $radSDType = GUS::Model::Study::StudyDesignType->new();
   $radSDType->setParent($radSD);
   $radSDType->setParent($self->createRadOE($mageSD->getType, "studyDesign"));

   $self->createRadStudyFactors($mageSD->getFactors, $radSD);

 }

}

sub createRadStudyFactors{
  my ($self, $mageSFs, $radSD) = @_;
   foreach my $mageSF (@ $mageSFs){
     my %h;
     $h{name} = $mageSF->getName() if $mageSF->getName();
     my $radSF = GUS::Model::Study::StudyFactor->new(%h);
     $radSF->setParent($radSD);
     $radSF->setParent($self->createRadOE($mageSF->getType, "studyFactor"));
   }
}


sub createRadProtocols{
 my ($self, $mageProtocols, $radProtocols) = @_;
 foreach my $mageProtocol(@ $mageProtocols){
   my %h;
   $h{name} = $mageProtocol->getName if $mageProtocol->getName;
   $h{uri} = $mageProtocol->getUri if $mageProtocol->getUri;
   $h{protocolDescription} = $mageProtocol->getProtocolDescription if $mageProtocol->getProtocolDescription;
   $h{softwareDescription} = $mageProtocol->getSoftwareDescription if $mageProtocol->getSoftwareDescription;
   $h{hardwareDescription} = $mageProtocol->getHardwareDescription if $mageProtocol->getHardwareDescription;

   my $radProtocol = GUS::Model::RAD::Protocol->new(%h);
   $radProtocol->setParent($self->createRadOE($mageProtocol->getProtocolType, "protocol")) if $mageProtocol->getProtocolType;

   $self->createRadProtocolParams($mageProtocol->getParams, $radProtocol);
 }
}


sub createRadProtocolParams{
  my ($self, $mageProtocolParams, $radProtocol) = @_;
  foreach my $magePP(@ $mageProtocolParams){
    my %h;
    $h{name} = $magePP->getName if $magePP->getName;
    $h{value} = $magePP->getValue if $magePP->getValue;
    my $radProtocolParam = GUS::Model::RAD::ProtocolParam->new(%h);
    $radProtocolParam->setParent($radProtocol);

    $radProtocolParam->setParent($self->createRadOE($magePP->getUnitType, "unit")) if $magePP->getUnitType;
    $radProtocolParam->setParent($self->createRadOE($magePP->getDataType, "data")) if $magePP->getDataType;
  }
}

sub createRadAssays{
 my ($self, $mageAssays, $radAssays) = @_;
 foreach my $mageAssay(@ $mageAssays){
   my %h;
   $h{name} = $mageAssay->getName if $mageAssay->getName;
   my $radAssay = GUS::Model::RAD::Assay->new(%h);

   push @$radAssays, $radAssay;

   $self->createRADAcquisitions($mageAssay->getAcquisitions, $radAssay);
 }
}


sub createRadAcquisitions{
  my ($self, $mageAcquisitions, $radAssay) = @_;
  foreach my $mageAcquisition(@ $mageAcquisitions){
    my %h;
    $h{name} = $mageAcquisition->getName if $mageAcquisition->getName;
    my $radAcquisition = GUS::Model::RAD::Acquisition->new(%h);
    $radAcquisition->setParent($radAssay);
    $self->createRADQuantifications($mageAcquisition->getQuantifications, $radAcquisition);
  }
}

sub createRadQuantifications{
  my ($self, $mageQuantifications, $radAcquisition) = @_;
  foreach my $mageQuantification(@ $mageQuantifications){
    my %h;
    $h{name} = $mageQuantification->getName if $mageQuantification->getName;
    my $radQuantification = GUS::Model::RAD::Quantification->new(%h);
    $radQuantification->setParent($radAcquisition);
  }
}

sub createRadBioMaterials{
  my ($self, $mageBioMaterials, $radBioMaterials) = @_;
  foreach my $mageBM(@ $mageBioMaterials){
    my %h;
    $h{name} = $mageBM->getName if $mageBM->getName;
    $h{description} = $mageBM->getDescription if $mageBM->getDescription;
    $h{subclass_view} = $mageBM->getSubclassView if $mageBM->getSubclassView;

    my $radBM = GUS::Model::Study::BioMaterial->new(%h);

    $radBM->setParent($self->createRadOE($mageBM->getBioMaterialType, "biomaterial")) if $magePP->getBioMaterialType;

    $radBM->setParent($self->searchObjArrayByObjName(\@radProtocols), $magePP->getLabelMethod->getName) if $magePP->getLabelMethod;
  }
}



# we have to assume OE is already in RAD
sub createRadOE{
  my ($self, $mageOE, $type) = @_;

  my @modes    = qw( studyDesign studyFactor treatment protocol unit data biomaterial);
  my $modes_rx = '^('. join('|',@modes). ')$';

  if ($type =~ /$modes_rx/) {
    my $radOE = GUS::Model::Study::OntologyEntry->new({value=>$mageOE->getValue, category=>$mageOE->getCategory});
    RAD::MR_T::MageImport::MageImportOENotFoundError->new(
							  $self."->createRadOE: OntologyEntry value: ".$mageOE->getValue."category: ".$mageOE->getCategory
							 )->throw() unless $radOE->retrieveFromDB;
    return $radOE;
  }
  else {

  }
}


#Util methods
sub searchObjArrayByObjName{
 my ($self, $objArray, $name) = @_;
 foreach my $obj(@$objArray){
   return $obj if $obj->getName eq $name;
 }
}

1;
