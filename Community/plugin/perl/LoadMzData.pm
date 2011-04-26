package GUS::Community::Plugin::LoadMzData;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
use FileHandle;
use XML::Parser::PerlSAX;

use GUS::PluginMgr::Plugin;

use GUS::Model::PROT::Protocol;
use GUS::Model::PROT::ProtocolInstance;
use GUS::Model::Study::OntologyEntry;

my $assayHash={};

my $argsDeclaration =
  [
   fileArg({name           => 'filename',
	    descr          => 'Name of XML file to insert',
	    constraintFunc => undef,
	    reqd           => 1,
	    isList         => 0,
	    format         => 'Simple GUS XML Format.  See the notes.',
	    mustExist      => 1 })

  ];



my $purpose = <<PURPOSE;
Insert data in from a simple GUS XML format into GUS.
PURPOSE

my $purposeBrief = <<PURPOSE_BRIEF;
Insert data in from a simple GUS XML format into GUS
PURPOSE_BRIEF

my $notes = <<EOF;
The XML format is:
<Schema::table>
  <column>value</column>
  ...
</Schema::table>
  ...
Each major tag represents a table and nested within it are elements for column values. The file introduces a special non-xml syntax to delimit a submit (and a transaction).  A line beginning with "//" indicates that the objects created since the last submit (and commit) should be submitted and committed.
EOF

my $tablesAffected = <<EOF;
EOF

my $tablesDependedOn = <<EOF;
EOF

my $howToRestart = <<EOF;
There are no restart facilities for this plugin
EOF

my $failureCases = <<EOF;
EOF

my $documentation = { purpose          => $purpose,
		      purposeBrief     => $purposeBrief,
		      notes            => $notes,
		      tablesAffected   => $tablesAffected,
		      tablesDependedOn => $tablesDependedOn,
		      howToRestart     => $howToRestart,
		      failureCases     => $failureCases };
sub new {
  my ($class) = @_;
  my $self    = {};
  bless($self, $class);

  $self->initialize({
      requiredDbVersion => 3.6,
      cvsRevision       => '$Revision: 3032 $',            # Completed by CVS
      name              => ref($self),
      argsDeclaration   => $argsDeclaration,
      documentation     => $documentation
      });

  return $self;
}
 

sub run {
  my $self = shift;
  my $handler = MzDataHandler->new();
  my $parser = XML::Parser::PerlSAX->new(Handler => $handler);

  my $file = $self->getArg('filename');
  MzDataHandler->setFile($file);

  my $oe=GUS::Model::Study::OntologyEntry->new({category=>"ExperimentalProtocolType", value=>"mzRun"});
  $oe->submit unless ($oe->retrieveFromDB);

  $self->log("submit oe", $oe->getId);

  my $protocol=GUS::Model::PROT::Protocol->new({name=>"$file mzRun protocol", type_id=>$oe->getId});
  my $protocolIns=GUS::Model::PROT::ProtocolInstance->new({deviation=>"$file mzRun protocol instance"});
  $protocolIns->setParent($protocol);
  $protocol->submit unless $protocol->retrieveFromDB;

  $self->log("submit protocol", $protocol->getId);
  $self->log("submit protocol instance", $protocolIns->getId);

  MzDataHandler->setProtocolId($protocol->getId);
  MzDataHandler->setProtInstance($protocolIns->getId);

  $oe=GUS::Model::Study::OntologyEntry->new({category=>"ExperimentalProtocolType", value=>"mzScan"});
  $oe->submit unless ($oe->retrieveFromDB);

  $self->log("submit oe", $oe->getId);

  my $scanProtocol=GUS::Model::PROT::Protocol->new({name=>"$file mzScan protocol", type_id=>$oe->getId});
  $scanProtocol->submit unless $scanProtocol->retrieveFromDB;

  $self->log("submit scan protocol", $scanProtocol->getId);

  MzDataHandler->setScanProtocolId($scanProtocol->getId);

  my %parser_args = (Source => {SystemId => $file});
  $parser->parse(%parser_args);

  return "finish loading mzData $file";
}



package MzDataHandler;

use GUS::Model::SRes::Contact;
use GUS::Model::PROT::MZRun;
use GUS::Model::PROT::MZScan;
use GUS::Model::PROT::Hardware;
use GUS::Model::PROT::Software;
use GUS::Model::PROT::ProtocolHardware;
use GUS::Model::PROT::ProtocolSoftware;
use GUS::Model::PROT::Parameter;
use GUS::Model::PROT::ParameterInstance;
use GUS::Model::Study::OntologyEntry;
use GUS::Model::PROT::ProtocolInstance;


my @element_stack;
my $in_intset;
my $person;
my $personHash;
my $hardwareHash;
my $hardware;
my $softwareHash;
my $software;
my $mzRunHash;
my $storage;
my $mzScanHash;
my $mzScan;

sub new {
  my $type = shift;
  return bless {}, $type;
}


sub start_element{
  my ($self, $element) = @_;

  $assayHash->{"id"}=1;

  if($element->{Name} eq 'mzData'){push @element_stack, 'mzData' ;}

  if($element_stack[$#element_stack] eq 'mzData'){
    if($element->{Name} eq 'description'){push  @element_stack, 'mzData.description';}
  }

  if($element->{Name} eq 'Contact'){push @element_stack, 'Contact' ;}

  if($element_stack[$#element_stack] eq 'Contact'){
    if($element->{Name} eq 'name'){push  @element_stack, 'Contact.name';}
  }

  if($element->{Name} eq 'instrument'){
    push @element_stack, 'instrument' ;
  }

  
  if($element_stack[$#element_stack] eq 'instrument'){
    if($element->{Name} eq 'instrumentName'){push  @element_stack, 'instrumentName';}
    if($element->{Name} eq 'source'){push  @element_stack, 'instrumentSource';}
    if($element->{Name} eq 'analyzerList'){push  @element_stack, 'instrumentAnalyzerList';}
    if($element->{Name} eq 'detector'){push  @element_stack, 'instrumentDetector';}

  }

  if($element_stack[$#element_stack] eq 'instrumentAnalyzerList'){
    if($element->{Name} eq 'analyzer'){push  @element_stack, 'instrumentAnalyzerList.analyzer';}
  }


  if($element_stack[$#element_stack] eq 'instrumentSource'){
    if($element->{Name} eq 'cvParam'){$hardwareHash->{type_id}=$self->getCVId($element->{Attributes})}
  }

  if($element_stack[$#element_stack] eq 'instrumentAnalyzerList.analyzer'){
    if($element->{Name} eq 'cvParam'){$self->insertHardwareCVParam($element->{Attributes}, "analyzer")}
  }

  if($element_stack[$#element_stack] eq 'instrumentDetector'){
    if($element->{Name} eq 'cvParam'){$self->insertHardwareCVParam($element->{Attributes}, "detector")}
  }

  if($element->{Name} eq 'dataProcessing'){
    push @element_stack, 'dataProcessing' ;
  }

  if($element_stack[$#element_stack] eq 'dataProcessing'){
    if($element->{Name} eq 'software'){ push @element_stack, 'dataProcessing.software' ;}
    if($element->{Name} eq 'processingMethod'){ push @element_stack, 'dataProcessing.processingMethod' ;}
  }
  if($element_stack[$#element_stack] eq 'dataProcessing.software'){
    if($element->{Name} eq 'name'){ push @element_stack, 'dataProcessing.software.name' ;}
    if($element->{Name} eq 'version'){ push @element_stack, 'dataProcessing.software.version' ;}
  }
  if($element_stack[$#element_stack] eq 'dataProcessing.processingMethod'){
    if($element->{Name} eq 'cvParam'){$self->insertSoftwareCVParam($element->{Attributes})}
  }

  if($element->{Name} eq 'spectrumList'){push @element_stack, 'spectrumList' ;}
  if($element_stack[$#element_stack] eq 'spectrumList'){
    if($element->{Name} eq 'spectrum'){ 
      my $file =  $self->getFile;
      my $scanprotocolIns=GUS::Model::PROT::ProtocolInstance->new({deviation=>"$file mzScan protocol instance".$element->{Attributes}->{id}, parameterizable_id=>$storage->{scan_protocol_id}});
      $scanprotocolIns->submit unless $scanprotocolIns->retrieveFromDB;
      $storage->{scan_protocol_instance_id}=$scanprotocolIns->getId;
      push @element_stack, 'spectrumList.spectrum' ;
    }
  }
  if($element_stack[$#element_stack] eq 'spectrumList.spectrum'){
    if($element->{Name} eq 'spectrumSettings'){ push @element_stack, 'spectrumList.spectrum.spectrumSettings' ;}
  }

  if($element_stack[$#element_stack] eq 'spectrumList.spectrum.spectrumSettings'){
    if($element->{Name} eq 'acqSpecification'){ push @element_stack, 'spectrumList.spectrum.spectrumSettings.acqSpecification' ;}

    if($element->{Name} eq 'spectrumInstrument'){ push @element_stack, 'spectrumList.spectrum.spectrumSettings.spectrumInstrument' ;}

  }

  if($element_stack[$#element_stack] eq 'spectrumList.spectrum.spectrumSettings.spectrumInstrument'){
    if($element->{Name} eq 'cvParam'){  $self->insertCVParam($element->{Attributes});}
  }

  if($element_stack[$#element_stack] eq 'spectrumList.spectrum.spectrumSettings.acqSpecification'){
    if($element->{Name} eq 'acquisition'){
      my $file =  $self->getFile;
      my $mzScanHash->{assay_id}=$storage->{assay_id};
      $mzScanHash->{protocol_instance_id}=$storage->{scan_protocol_instance_id};
      $mzScanHash->{Name}="$file mzScan ".$element->{Attributes}->{acqNumber};
      $mzScanHash->{scan_num}=$element->{Attributes}->{acqNumber};
      my $mzScan=GUS::Model::PROT::MZScan->new($mzScanHash);
      $mzScan->submit unless $mzScan->retrieveFromDB;
    }
  }
  print STDOUT $#element_stack, $element_stack[$#element_stack];
}
 

sub characters{
  my ($self, $element) = @_;
  $assayHash->{"id"}=1;

  if($element_stack[$#element_stack] eq 'Contact.name'){
    $personHash->{Name}=$element->{Data};
    print STDOUT $element->{Data}, $personHash->{Name}, "\n";
  }
  
  if($element_stack[$#element_stack] eq 'instrumentName'){
    $hardwareHash->{Name}=$element->{Data};
  }

  if($element_stack[$#element_stack] eq 'instrumentAnalyzerList'){
    $storage->{num_of_analyzer}=$element->{Data};
  }

  if($element_stack[$#element_stack] eq 'dataProcessing.software.name'){
    $softwareHash->{Name}=$element->{Data};
  }
  if($element_stack[$#element_stack] eq 'dataProcessing.software.version'){
    $softwareHash->{version}=$element->{Data};
  }
}
 

sub end_element{
  my ($self, $element) = @_;
  if($element_stack[$#element_stack] eq 'Contact.name' && $element->{Name} eq 'Contact'){
    my $person=GUS::Model::SRes::Contact->new($personHash);
    $person->submit unless $person->retrieveFromDB;

    print STDOUT "submit contact: ", $person->getId, "\n";

    $mzRunHash->{operator_id} = $person->getId;
    pop @element_stack;
  }
  
  if($element_stack[$#element_stack] eq 'instrumentSource'){
    if($element->{Name} eq 'source'){
      $hardware=GUS::Model::PROT::Hardware->new($hardwareHash);
      $hardware->submit unless $hardware->retrieveFromDB;
      $storage->{hardware_id}=$hardware->getId;

      my $ph=GUS::Model::PROT::ProtocolHardware->new({protocol_id=>$storage->{protocol_id}, hardware_id=>$storage->{hardware_id}, parent_prmz_id=>$storage->{protocol_id}, child_prmz_id=>$storage->{software_id}});
      $ph->submit unless $ph->retrieveFromDB;

      pop @element_stack;
    }
  }

  if($element_stack[$#element_stack] eq 'instrumentAnalyzerList.analyzer'){
    if($element->{Name} eq 'analyzer'){pop  @element_stack;}
  }

  if($element_stack[$#element_stack] eq 'instrumentAnalyzerList'){
    if($element->{Name} eq 'analyzerList'){pop  @element_stack;}
  }

  if($element_stack[$#element_stack] eq 'instrumentDetector'){
    if($element->{Name} eq 'detector'){pop  @element_stack;}
  }  

  if($element_stack[$#element_stack] eq 'instrument'){
    if($element->{Name} eq 'instrument'){pop  @element_stack;}
  }


 if($element_stack[$#element_stack] eq 'dataProcessing.software.name'){
   if($element->{Name} eq 'name'){pop  @element_stack;}
  }
  if($element_stack[$#element_stack] eq 'dataProcessing.software.version'){
    if($element->{Name} eq 'version'){pop  @element_stack;}
  }

if($element_stack[$#element_stack] eq 'dataProcessing.software'){
   if($element->{Name} eq 'software'){
     my  $oe=GUS::Model::Study::OntologyEntry->new({category=>"Software Type", value=>"ms data processing software", name=>"user defined"});
     $oe->submit unless ($oe->retrieveFromDB);

     $softwareHash->{type_id}=$oe->getId;
     $software=GUS::Model::PROT::Software->new($softwareHash);
     $software->submit unless $software->retrieveFromDB;

     $storage->{software_id}=$software->getId;

     my $ps=GUS::Model::PROT::ProtocolSoftware->new({protocol_id=>$storage->{protocol_id}, software_id=>$storage->{software_id}, parent_prmz_id=>$storage->{protocol_id}, child_prmz_id=>$storage->{software_id}});
     $ps->submit unless $ps->retrieveFromDB;
     pop  @element_stack;

   }
  }
  if($element_stack[$#element_stack] eq 'dataProcessing.processingMethod'){
    if($element->{Name} eq 'processingMethod'){pop  @element_stack;}
  }

  if($element_stack[$#element_stack] eq 'dataProcessing'){
    if($element->{Name} eq 'dataProcessing'){pop  @element_stack;}
  }

  if($element_stack[$#element_stack] eq 'mzData.description' && $element->{Name} eq 'description'){
    my $mzRun=GUS::Model::PROT::MZRun->new($mzRunHash);
    $mzRun->submit unless $mzRun->retrieveFromDB;
    $storage->{assay_id}=$mzRun->getId;
    pop @element_stack;
  }


  if($element_stack[$#element_stack] eq 'spectrumList.spectrum.spectrumSettings.acqSpecification'){
    if($element->{Name} eq 'acqSpecification'){pop  @element_stack;}
  }
  if($element_stack[$#element_stack] eq 'spectrumList.spectrum.spectrumSettings.spectrumInstrument'){
    if($element->{Name} eq 'spectrumInstrument'){pop  @element_stack;}
  }

  if($element_stack[$#element_stack] eq 'spectrumList.spectrum.spectrumSettings'){
    if($element->{Name} eq 'spectrumSettings'){pop  @element_stack;}
  }

  if($element_stack[$#element_stack] eq 'spectrumList.spectrum'){
    if($element->{Name} eq 'spectrum'){pop  @element_stack;}
  }

  if($element_stack[$#element_stack] eq 'spectrumList'){
    if($element->{Name} eq 'spectrumList'){pop  @element_stack;}
  }

  if($element_stack[$#element_stack] eq 'mzData' && $element->{Name} eq 'mzData'){
    pop @element_stack;
  }
}

sub setProtInstance{
  my ($self, $id) = @_;
  $mzRunHash->{protocol_instance_id}=$id;
}

sub setProtocolId{
  my ($self, $id) = @_;
  $storage->{protocol_id}=$id;
}

sub setScanProtocolId{
  my ($self, $id) = @_;
  $storage->{scan_protocol_id}=$id;
}

sub setFile{
  my ($self, $file) = @_;
  $storage->{file}=$file;
}

sub getFile{
  my ($self) = @_;
  return $storage->{file};
}

sub getCVId{
  my ($self, $cvHash) = @_;
  my $oe1=GUS::Model::Study::OntologyEntry->new({source_id=>$cvHash->{accession}});
  
  if($oe1->retrieveFromDB){
    my $oe2=GUS::Model::Study::OntologyEntry->new({value=>$cvHash->{value}, parent_id=>$oe1->getId});
    if($oe2->retrieveFromDB){
      return $oe2->getId;
    }
  }
}

sub insertHardwareCVParam{
  my ($self, $cvHash, $prefix) = @_;
  my $paramHash;
  my $paramInstanceHash;

  $paramHash->{parameterizable_id}=$storage->{hardware_id};
  $paramInstanceHash->{parameterizable_instance_id}=$storage->{protocol_instance_id};

  $paramHash->{Name}=$prefix.$cvHash->{Name};
  my $oe1=GUS::Model::Study::OntologyEntry->new({source_id=>$cvHash->{accession}});

  if($oe1->retrieveFromDB){
    $paramHash->{value_class_oe_id}=$oe1->getId;
    my $oe2=GUS::Model::Study::OntologyEntry->new({value=>$cvHash->{value}, parent_id=>$oe1->getId});
    if($oe2->retrieveFromDB){
       $paramInstanceHash->{value_ontology_entry_id}=$oe2->getId;
    }
    else{
      $paramInstanceHash->{value}=value=>$cvHash->{value};
    }
  }
  else{
    $paramInstanceHash->{value}=value=>$cvHash->{value};
  }

  my $param=GUS::Model::PROT::Parameter->new($paramHash);
  my $paramIns=GUS::Model::PROT::ParameterInstance->new($paramInstanceHash);

  $paramIns->setParent($param);
  $param->submit unless $param->retrieveFromDB;

}

sub insertSoftwareCVParam{
  my ($self, $cvHash, $prefix) = @_;
  my $paramHash;
  my $paramInstanceHash;

  $paramHash->{parameterizable_id}=$storage->{software_id};
  $paramInstanceHash->{parameterizable_instance_id}=$storage->{protocol_instance_id};

  $paramHash->{Name}=$prefix.$cvHash->{Name};
  my $oe1=GUS::Model::Study::OntologyEntry->new({source_id=>$cvHash->{accession}});

  if($oe1->retrieveFromDB){
    $paramHash->{value_class_oe_id}=$oe1->getId;
    my $oe2=GUS::Model::Study::OntologyEntry->new({value=>$cvHash->{value}, parent_id=>$oe1->getId});
    if($oe2->retrieveFromDB){
       $paramInstanceHash->{value_ontology_entry_id}=$oe2->getId;
    }
    else{
      $paramInstanceHash->{value}=value=>$cvHash->{value};
    }
  }
  else{
    $paramInstanceHash->{value}=value=>$cvHash->{value};
  }

  my $param=GUS::Model::PROT::Parameter->new($paramHash);
  my $paramIns=GUS::Model::PROT::ParameterInstance->new($paramInstanceHash);

  $paramIns->setParent($param);
  $param->submit unless $param->retrieveFromDB;

}

sub insertCVParam{
  my ($self, $cvHash, $prefix) = @_;
  my $paramHash;
  my  $paramInstanceHash;

  $paramHash->{parameterizable_id}=$storage->{scan_protocol_id};
  $paramInstanceHash->{parameterizable_instance_id}=$storage->{scan_protocol_instance_id};

  $paramHash->{Name}=$prefix.$cvHash->{Name};
  my $oe1=GUS::Model::Study::OntologyEntry->new({source_id=>$cvHash->{accession}});

  if($oe1->retrieveFromDB){
    $paramHash->{value_class_oe_id}=$oe1->getId;
    my $oe2=GUS::Model::Study::OntologyEntry->new({value=>$cvHash->{value}, parent_id=>$oe1->getId});
    if($oe2->retrieveFromDB){
       $paramInstanceHash->{value_ontology_entry_id}=$oe2->getId;
    }
    else{
      $paramInstanceHash->{value}=value=>$cvHash->{value};
    }
  }
  else{
    $paramInstanceHash->{value}=value=>$cvHash->{value};
  }

  my $param=GUS::Model::PROT::Parameter->new($paramHash);
  my $paramIns=GUS::Model::PROT::ParameterInstance->new($paramInstanceHash);

  $paramIns->setParent($param);
  $param->submit unless $param->retrieveFromDB;

}

1;
