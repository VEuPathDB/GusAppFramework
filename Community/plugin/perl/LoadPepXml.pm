package GUS::Community::Plugin::LoadPepXml;
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
	    descr          => 'Name of pep XML file to insert',
	    constraintFunc => undef,
	    reqd           => 1,
	    isList         => 0,
	    format         => 'XML Format.  See the notes.',
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
  my $handler = PepXmlHandler->new();
  my $parser = XML::Parser::PerlSAX->new(Handler => $handler);

  my $file = $self->getArg('filename');
  PepXmlHandler->setFile($file);

 

  my %parser_args = (Source => {SystemId => $file});
  $parser->parse(%parser_args);

  return "finish loading mzData $file";
}



package PepXmlHandler;

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
use GUS::Model::PROT::MascotElementResult;
use GUS::Model::PROT::SequestElementResult;
use GUS::Model::PROT::Quantification;

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
my $elementResultHash;

sub new {
  my $type = shift;
  return bless {}, $type;
}


sub start_element{
  my ($self, $element) = @_;

  if($element->{Name} eq 'search_summary'){
    push @element_stack, 'search_summary' ;

    my $engine=$element->{Attributes}->{search_engine};
    $self->setEngine($engine);
$self->insertPROTocol($element->{Attributes});
    $self->insertQuantification($element->{Attributes});
  }

  if($element->{Name} eq 'search_database'){
    push @element_stack, 'search_database' ;
    $self->insertParamIns($element->{Attributes}, "search_database");
  }

  if($element->{Name} eq 'enzymatic_search_constraint'){
    push @element_stack, 'enzymatic_search_constraint' ;
    $self->insertParamIns($element->{Attributes}, "enzymatic_search_constraint");
  }

  if($element_stack[$#element_stack] eq "search_summary" && $element->{Name} eq 'parameter'){
    push @element_stack, 'search_summary.parameter' ;
    $self->loadParam($element->{Attributes});
  }

  if($element->{Name} eq 'spectrum_query'){
    push @element_stack, 'spectrum_query';
    $self->loadSpecQuery($element->{Attributes});
  }

  if($element->{Name} eq 'search_hit'){
    push @element_stack, 'search_hit';
    $self->loadSearchHit($element->{Attributes});
  }

  if($element_stack[$#element_stack] eq 'search_hit'){
    if($element->{Name} eq 'search_score'){
      push @element_stack, 'search_hit.search_score';
      $self->loadSearchScore($element->{Attributes});
    }
    if($element->{Name} eq 'peptideprophet_result'){
      push @element_stack, 'search_hit.peptideprophet_result';
      $self->loadPeptideProphetResult($element->{Attributes});
    }
  }

  if($element_stack[$#element_stack] eq 'search_hit.peptideprophet_result' && $element->{Name} eq 'parameter'){
    push @element_stack, 'search_hit.peptideprophet_result.parameter';
    $self->loadSearchScore($element->{Attributes});
  }

}

sub characters{
  my ($self, $element) = @_;
}

sub end_element{
  my ($self, $element) = @_;

  if($element_stack[$#element_stack] eq 'search_database'){
    pop @element_stack;
  }

  if($element_stack[$#element_stack] eq 'enzymatic_search_constraint'){
    pop @element_stack;
  }

  if($element_stack[$#element_stack] eq 'search_summary.parameter'){
    pop @element_stack;
  }

  if($element_stack[$#element_stack] eq 'search_summary'){
    pop @element_stack;
  }

  if($element_stack[$#element_stack] eq 'spectrum_query'){
    pop @element_stack;
  }

  if($element_stack[$#element_stack] eq 'search_hit.search_score' && $element->{Name} eq 'search_score'){
    pop @element_stack;
  }

  if($element_stack[$#element_stack] eq 'search_hit.peptideprophet_result.parameter' && $element->{Name} eq 'parameter'){
    pop @element_stack;
  }

  if($element_stack[$#element_stack] eq 'search_hit.peptideprophet_result' && $element->{Name} eq 'peptideprophet_result'){
    pop @element_stack;
  }

}

sub setCurrentPROTInstance{
  my ($self, $id) = @_;
  $storage->{protocol_instance_id}=$id;
}

sub getCurrentPROTInstance{
  my ($self, $id) = @_;
  return $storage->{protocol_instance_id};
}

sub setCurrentQuan{
  my ($self, $id) = @_;
  $storage->{quantification_id}=$id;
}

sub getCurrentQuan{
  my ($self, $id) = @_;
  return $storage->{quantification_id};
}


sub setPROTocolId{
  my ($self, $id) = @_;
  $storage->{protocol_id}=$id;
}

sub getPROTocolId{
  my ($self, $id) = @_;
  return $storage->{protocol_id};
}

sub setScanPROTocolId{
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

sub setEngine{
  my ($self, $file) = @_;
  $storage->{engine}=$file;
}

sub getEngine{
  my ($self) = @_;
  return $storage->{file};
}


sub insertPROTocol{
  my ($self, $searchSumHash) = @_;

  my $engine=$self->getEngine;

  my $oe=GUS::Model::Study::OntologyEntry->new({category=>"ExperimentalPROTocolType", value=>$engine});
  $oe->submit unless ($oe->retrieveFromDB);

  my $file=$self->getFile;
  my $protocol=GUS::Model::PROT::Protocol->new({name=>"$engine search protocol used in $file", type_id=>$oe->getId});
  $protocol->submit unless $protocol->retrieveFromDB;
  $self->setPROTocolId($protocol->getId);
  print STDOUT $self->getPROTocolId;

}

sub insertQuantification{
  my ($self, $searchSumHash) = @_;
  my $quanHash;
  $quanHash->{URI}=$searchSumHash->{base_name};
  $quanHash->{name}=$self->getFile()." Search Id ".$searchSumHash->{search_id};
  my $quan=GUS::Model::PROT::Quantification->new($quanHash);

  my $protocolIns=GUS::Model::PROT::ProtocolInstance->new({deviation=>$self->getFile." protocol instance Id ".$searchSumHash->{search_id}, Parameterizable_ID=>$self->getPROTocolId});

  $quan->setParent($protocolIns);

  $protocolIns->submit unless $protocolIns->retrieveFromDB;

  $self->setCurrentPROTInstance($protocolIns->getId);
  $self->setCurrentQuan($quan->getId);

  foreach my $key(keys %$searchSumHash){
    my $paramHash;
    my $paramInstanceHash;
    $paramHash->{parameterizable_id}=$self->getPROTocolId;
    $paramInstanceHash->{parameterizable_instance_id}=$protocolIns->getId;
    $paramHash->{Name}=$key;
    #value_class_oe_id not nullable???    
    $paramHash->{value_class_oe_id}=1964;
    $paramInstanceHash->{value_ontology_entry_id}=1964;
    $paramInstanceHash->{value}=$searchSumHash->{$key};
    my $param=GUS::Model::PROT::Parameter->new($paramHash);
    $param->submit unless $param->retrieveFromDB;

    $paramInstanceHash->{"parameter_id"}=$param->getId;
    my $paramIns=GUS::Model::PROT::ParameterInstance->new($paramInstanceHash);
    $paramIns->submit unless $paramIns->retrieveFromDB;
  }
}


sub insertParamIns{
  my ($self, $searchDbHash, $prefix) = @_;
  my $quanHash;

  my $protInsId=$self->setCurrentPROTInstance();

  foreach my $key(keys %$searchDbHash){
    my $paramHash;
    my $paramInstanceHash;
    $paramHash->{parameterizable_id}=$self->getPROTocolId;
    $paramInstanceHash->{parameterizable_instance_id}=$protInsId;
    if(defined $prefix){
      $paramHash->{Name}=$prefix."_".$key;
    }
    else{
      $paramHash->{Name}=$key;
    }

    $paramInstanceHash->{value}=$searchDbHash->{$key};
    #value_class_oe_id not nullable???    
    $paramHash->{value_class_oe_id}=1964;
    $paramInstanceHash->{value_ontology_entry_id}=1964;
   
   my $param=GUS::Model::PROT::Parameter->new($paramHash);
    $param->submit unless $param->retrieveFromDB;

    $paramInstanceHash->{"parameter_id"}=$param->getId;
    my $paramIns=GUS::Model::PROT::ParameterInstance->new($paramInstanceHash);
    $paramIns->submit unless $paramIns->retrieveFromDB;
  }
}

sub loadParam{
  my ($self, $phash, $prefix) = @_;

  my $protInsId=$self->setCurrentPROTInstance();

  my $paramHash;
  my $paramInstanceHash;
  $paramHash->{parameterizable_id}=$self->getPROTocolId;
  $paramInstanceHash->{parameterizable_instance_id}=$protInsId;
  if(isset($prefix)){
    $paramHash->{Name}=$prefix."_".$phash->{name};
  }
  else{
    $paramHash->{Name}=$phash->{name};
  }

  $paramInstanceHash->{value}=$phash->{value};
  my $param=GUS::Model::PROT::Parameter->new($paramHash);
  $param->submit unless $param->retrieveFromDB;

  $paramInstanceHash->{"parameter_id"}=$param->getId;
  my $paramIns=GUS::Model::PROT::ParameterInstance->new($paramInstanceHash);
  if(isset($paramInstanceHash->{value}) && $paramInstanceHash->{value}!=""){
    $paramIns->submit unless $paramIns->retrieveFromDB;
  }
}

sub loadSpecQuery{
  my ($self, $specQueryHash) = @_;
# need to clean hash here
  $elementResultHash->{"quantification_id"}=$self->getCurrentQuan();
  $elementResultHash->{"spectrum"}=$specQueryHash->{spectrum};
  $elementResultHash->{"search_index"}=$specQueryHash->{index};
}

sub loadSearchHit{
  my ($self, $searchHitHash) = @_;
  $elementResultHash->{"peptide"}=$searchHitHash->{peptide};
  $elementResultHash->{"protein_gi_id"}=$searchHitHash->{protein};

}

sub loadSearchScore{
  my ($self, $searchScoreHash) = @_;
  my %name2field=();
  if($self->getEngine eq "MASCOT"){
    %name2field=(ionscore=>'ionscore', identityscore=>'id_score', homologyscore=>'homology_score', ntt=>'ntt', fval=>'fval');
  }

  if($self->getEngine eq "SEQUEST"){
    %name2field=(XCORR=>'xcorr', deltacn=>'deltacn', sprank=>'sprank', sp=>'sp', fval=>'fval');
  }
  my $name = $searchScoreHash->{name};
  if( $name2field{$name}){  
    $elementResultHash->{$searchScoreHash->{name}}=$searchScoreHash->{value};
  }
}

sub loadPeptideProphetResult{
  my ($self, $peptideProphetResultHash) = @_;
  $elementResultHash->{"probability"}=$peptideProphetResultHash->{probability};
}


1;
