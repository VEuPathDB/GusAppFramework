package GUS::Supported::Plugin::LoadTaxon;

@ISA = qw(GUS::PluginMgr::Plugin);
use strict;


use GUS::PluginMgr::Plugin;
use GUS::Model::SRes::Taxon;
use GUS::Model::SRes::TaxonName;
use GUS::Model::SRes::GeneticCode;
use GUS::PluginMgr::Plugin;

sub new {
  my ($class) = @_;

  my $self = {};
  bless($self,$class);

my $purpose = <<PURPOSE;
Populate the SRes::Taxon, SRes::GeneticCode, and SRes::TaxonName tables using the names.dmp, gencode.dmp and merged.dmp files downloaded from NCBI
PURPOSE

my $purposeBrief = <<PURPOSE_BRIEF;
Load the NCBI Taxon into GUS, updating where there have been changes.
PURPOSE_BRIEF

my $notes = <<NOTES;
NOTES

my $tablesAffected = <<TABLES_AFFECTED;
    [ ['SRes::Taxon', ''],
      ['SRes::GeneticCode', ''],
      ['SRes::TaxonName', ''],
    ];
TABLES_AFFECTED

my $tablesDependedOn = <<TABLES_DEPENDED_ON;
TABLES_DEPENDED_ON

my $howToRestart = <<RESTART;
RESTART

my $failureCases = <<FAIL_CASES;
FAIL_CASES

my $documentation = { purpose          => $purpose,
		      purposeBrief     => $purposeBrief,
		      notes            => $notes,
		      tablesAffected   => $tablesAffected,
		      tablesDependedOn => $tablesDependedOn,
		      howToRestart     => $howToRestart,
		      failureCases     => $failureCases };


my $argsDeclaration = 
[
   fileArg({name => 'nodes',
            descr => 'file from ncbi with tax_id,parent_id,rank,etc e.g. /usr/local/db/local/taxonomy/nodes.dmp',
            constraintFunc=> undef,
            reqd  => 1,
            isList => 0,
            mustExist => 1,
            format => '',}),
    fileArg({name => 'names',
            descr => 'file from ncbi with tax_id,name,name_class,etc
            e.g. /usr/local/db/local/taxonomy/names.dmp',
            constraintFunc=> undef,
            reqd  => 1,
            isList => 0,
            mustExist => 1,
            format => '',}),
   fileArg({name => 'gencode',
            descr => 'file from ncbi with genetic_code_id,abbreviation,ame,code,starts
            e.g./usr/local/db/local/taxonomy/gencode.dmp',
            constraintFunc=> undef,
            reqd  => 1,
            isList => 0,
            mustExist => 1,
            format => '',}),
  fileArg({name => 'merged',
            descr => 'file from ncbi with old_tax_id\tnew_tax_id
            e.g./usr/local/db/local/taxonomy/merged.dmp',
            constraintFunc=> undef,
            reqd  => 1,
            isList => 0,
            mustExist => 1,
            format => '',}),
   integerArg({name  => 'restart',
               descr => 'taxon_id of parent for restart, 0 if no restart',
               reqd  => 0,
               constraintFunc=> undef,
               isList=> 0,
               default=> 0,
              }),
];


  $self->initialize({requiredDbVersion => 3.5,
		     cvsRevision => '$Revision: 2943 $', # cvs fills this in!
		     name => ref($self),
		     argsDeclaration   => $argsDeclaration,
		     documentation     => $documentation});

  return $self;
}

sub run {

    my $self   = shift;

    my $count = 0;

    
    $self->mergeTaxons();

    my $genCodes = $self->makeGeneticCode();
    
    my $namesDmp = $self->getNames(); 
    
    my $nodesHash = $self->makeNodesHash($genCodes);
    
    my $rootAttArray = $self->getRootAttArray($genCodes);

    $self->makeTaxonEntry($rootAttArray, \$count);
    
    if ($self->getArg('restart') > 1) {
	$self->getTaxonAtt($self->getArg('restart'),$nodesHash,\$count);
    }
    else {
	$self->getTaxonAtt($rootAttArray->[0],$nodesHash,\$count); 
    }
    my ($TaxonNameIdHash,$TaxonIdHash) = $self->makeTaxonName($namesDmp);
    $self->deleteTaxonName($TaxonNameIdHash,$TaxonIdHash);
    
}

sub mergeTaxons {
  my $self   = shift;
  $self->log("Merging taxons");
  my $merged = $self->getArg('merged');
  open (MERGED,$merged) || die "Can't open merged file '$merged': $!\n";
  while(<MERGED>) {
    chomp;
    my @merged = split(/\s*\|\s*/, $_);
    my $oldTax = $merged[0];
    my $newTax = $merged[1];
    my $oldTaxon = $self->getTaxon($oldTax);
    if (! $oldTaxon) {
      $self->log("Doing merge and NCBI tax id '$oldTax' not in database, skipping");
      next;
    }
    my $newTaxon = $self->getTaxon($newTax);
    $self->updateTaxonRow($oldTaxon,$newTax) if (! $newTaxon);
    $self->updateTaxonAndChildRows ($oldTaxon,$newTaxon) if ($newTaxon);
  }
}

sub updateTaxonRow {
  my ($self,$oldTaxon,$newTax) = @_;
  my $taxonRow  = GUS::Model::SRes::Taxon->new({'taxon_id'=>$oldTaxon});
  $taxonRow ->retrieveFromDB();
  if ($taxonRow->get('ncbi_tax_id') != $newTax) {
    $taxonRow->set('ncbi_tax_id',$newTax);
  }
  my $submit = $taxonRow->submit();
  if ($submit == 1) {
    $self->log("Taxon_id = $oldTaxon updated to ncbi_tax_id = $newTax");
  }
  else {
    $self->log("Taxon_id = $oldTaxon FAILED to update to ncbi_tax_id = $newTax");
  }
  $self->undefPointerCache();
}

sub updateTaxonAndChildRows {
  my ($self,$oldTaxon,$newTaxon)= @_;
  my $newTaxon = GUS::Model::SRes::Taxon->new({'taxon_id'=>$newTaxon});
  $newTaxon ->retrieveFromDB();
  my $oldTaxon  = GUS::Model::SRes::Taxon->new({'taxon_id'=>$oldTaxon});
  $oldTaxon ->retrieveFromDB();
  my @children = $oldTaxon->getAllChildren(1);
  foreach my $child (@children) {
    $child->removeParent($oldTaxon);
    $child->setParent($newTaxon);
  }
  my $submit = $newTaxon->submit();
  if ($submit == 1) {
    $self->log("Taxon_id = $oldTaxon merged with Taxon_id = $newTaxon");
  }
  else {
    $self->log("Taxon_id = $oldTaxon FAILED to merge with Taxon_id = $newTaxon");
  }
  $oldTaxon->markDeleted(); 
  my $delete = $oldTaxon->submit();
  if ($delete == 1) {
    $self->log("Taxon_id = $oldTaxon deleted");
  }
  else {
    $self->log("Taxon_id = $oldTaxon FAILED to delete");
  }
  $self->undefPointerCache();
}

sub makeGeneticCode {

    my $self   = shift;
    $self->log("Updating and inserting SRes.GeneticCode");
    my %genCodes;  ##$genCodes{ncbi_gencode_id}=GUS genetic_code_id
    open (GENCODE,$self->getArg('gencode')) || die "Can't open gencode file: !\n";
    while (<GENCODE>) {
	chomp;
	my @nodeArray = split(/\s*\|\s*/, $_);
	my $abbreviation = $nodeArray[1];
	my $ncbi_gencode_id = $nodeArray[0];
	my $name = $nodeArray[2];
	my $code = $nodeArray[3];
	if (!$code) {
	    $code = 'Unspecified';
	}
	my $starts = $nodeArray[4];
	if (!$starts) {
	    $starts = 'Unspecified';
	}
	my $newGeneticCode = GUS::Model::SRes::GeneticCode->new({'ncbi_genetic_code_id'=> $ncbi_gencode_id});
	$newGeneticCode->retrieveFromDB();
	if ($newGeneticCode->get('abbreviation') ne $abbreviation) {
	    $newGeneticCode->set('abbreviation',$abbreviation);
	}
	if ($newGeneticCode->get('name') ne $name) {
	    $newGeneticCode->set('name',$name);
	}
	if ($newGeneticCode->get('code') ne $code) {
	    $newGeneticCode->set('code',$code);
	}
	if ($newGeneticCode->get('starts') ne $starts) {
	    $newGeneticCode->set('starts',$starts);
	}
	$newGeneticCode->submit();
	$genCodes{$ncbi_gencode_id} = $newGeneticCode->get('genetic_code_id');
	$self->undefPointerCache();
    }
    return \%genCodes;
}

sub getNames {

    my $self   = shift;
    my %namesDmp;
    open (NAMES,$self->getArg('names')) || die "Can't open names file: ! \n";                   
    while (<NAMES>) {
	chomp;
	my @nameArray = split(/\s*\|\s*/, $_);
	$namesDmp{$nameArray[0]}->{$nameArray[1]}->{$nameArray[3]}->{$nameArray[2]}++; #namesDmp{tax_id}->{name}->{name class}->{unique name **mostly null}
    }
    return (\%namesDmp);
}

sub makeNodesHash {

    my $self   = shift;
    my $genCodes = shift;
    my %nodesHash; #nodesHash{parent ncbi tax_id}->{child ncbi tax_id}=(rank,genetic_code_id,mitochondrial_genetic_code_id) 
    open (NODES,$self->getArg('nodes')) || die "Can't open nodes file: !\n";
    while (<NODES>) {
	chomp;
	my @nodeArray = split(/\s*\|\s*/, $_);
	my $tax_id = $nodeArray[0];
	my $parent_tax_id = $nodeArray[1];
	my $rank = $nodeArray[2]; 
	my $gen_code = $nodeArray[6]; 
	my $mit_code = $nodeArray[8]; 
	if (!$mit_code) {  #some mit_gen_code_id are null, set to unspecified here
	    $mit_code=0;
	}
	if ($tax_id == $parent_tax_id) {   #the root has tax_id and parent_id equal to 1, causes problems with the recursive sub getTaxonAtt
	    $tax_id = 0;
	}
	$nodesHash{$parent_tax_id}->{$tax_id} = [$rank,$genCodes->{$gen_code},$genCodes->{$mit_code}];
    }
    return (\%nodesHash);
}

sub getRootAttArray {

    my $self   = shift;
    my $genCodes = shift;
    my $tax_id=1;
    my $rank='no rank';
    my $gen_code = 0;
    my $mit_code = 0;
    my $parent_tax_id = -1;
    my @rootArray = ($tax_id,$rank,$parent_tax_id,$genCodes->{$gen_code},$genCodes->{$mit_code});
    return \@rootArray;
}

sub makeTaxonEntry {

    my $self   = shift;
    my $attArray = shift; 
    my $count = shift;
    my $tax_id = $attArray->[0];
    my $rank = $attArray->[1];
    my $parent_id = $attArray->[2];
    my $gen_code = $attArray->[3];
    my $mit_code = $attArray->[4];
    
    my $newTaxon  = GUS::Model::SRes::Taxon->new({'ncbi_tax_id'=>$tax_id});
    $newTaxon ->retrieveFromDB();
    
    if ($newTaxon->get('rank') ne $rank) {
	$newTaxon->set('rank',$rank);
    }
    if ($parent_id != -1 && $newTaxon->get('parent_id') != $parent_id ) {
	$newTaxon->set('parent_id',$parent_id);
    }
    if ($newTaxon->get('genetic_code_id') != $gen_code) {
	$newTaxon->set('genetic_code_id',$gen_code);
    }
    if ($newTaxon->get('mitochondrial_genetic_code_id') != $mit_code) { 
	$newTaxon->set('mitochondrial_genetic_code_id',$mit_code);
    }  
    

    
    $newTaxon->submit();
    my $submit = $self->undefPointerCache();
    $self->log("Processed ncbi_tax_id : $tax_id\n") if ($submit ==1);
    $$count++;
    if ($$count % 1000 == 0) {
	$self->log("Number processed: $$count\n");
    }
}


sub getTaxonAtt {
    
    my $self   = shift;
    my $parent_tax_id = shift;
    my $nodesHash = shift;
    my $count = shift;
    foreach my $tax_id (keys %{$nodesHash->{$parent_tax_id}}) {
	my $parent_taxon_id = $self->getTaxon($parent_tax_id);
	my $rank = $nodesHash->{$parent_tax_id}->{$tax_id}[0];
	my $gen_code = $nodesHash->{$parent_tax_id}->{$tax_id}[1];
	my $mit_code = $nodesHash->{$parent_tax_id}->{$tax_id}[2];
	my @attArr=($tax_id,$rank,$parent_taxon_id,$gen_code,$mit_code);
	$self->makeTaxonEntry(\@attArr,$count);
	$self->getTaxonAtt($tax_id,$nodesHash,$count);
    }
}

sub getTaxon{
    
    my $self   = shift;
    my ($tax_id) = @_;
    my $st = $self->prepareAndExecute("select t.taxon_id from sres.taxon t where t.ncbi_tax_id = $tax_id");
    my $taxon_id = $st->fetchrow_array();
    $st->finish();
    return $taxon_id;
}

sub makeTaxonName {

  my $self   = shift;
  my $namesDmp = shift;
  $self->log("Inserting and updating TaxonName");
  my %TaxonNameIdHash;
  my %TaxonIdHash;
  my $num = 0;
  foreach my $tax_id (keys %$namesDmp) {
    my $taxon_id = $self->getTaxon($tax_id);;
    foreach my $name (keys %{$namesDmp->{$tax_id}}) {
      foreach my $name_class (keys %{$namesDmp->{$tax_id}->{$name}}) {
	foreach my $unique_name_variant (keys %{$namesDmp->{$tax_id}->{$name}->{$name_class}}) {
	  my %attHash = ('taxon_id'=>$taxon_id,'name'=>$name, 'unique_name_variant'=> $unique_name_variant, 'name_class'=>$name_class);
	  my $newTaxonName = GUS::Model::SRes::TaxonName->new(\%attHash);

	  if (!$newTaxonName->retrieveFromDB()) {
	    $num += $newTaxonName->submit();
	  }

	  my $taxon_name_id = $newTaxonName->getTaxonNameId();
	  $TaxonNameIdHash{$taxon_name_id}=1;
	  $TaxonIdHash{$taxon_id}->{$name_class}=1;
	  
	  
	  $self->undefPointerCache();
	}
      }
    }
  }
  $self->log("$num taxon names inserted\n");
  return (\%TaxonNameIdHash,\%TaxonIdHash);
}

sub deleteTaxonName {
  my $self   = shift;
  my ($TaxonNameIdHash,$TaxonIdHash) = @_;
  $self->log("Deleting TaxonNames when redundant");
  my $num = 0;
  my $st = $self->prepareAndExecute("select taxon_name_id, taxon_id, name_class from sres.taxonname");
  while (my ($taxon_name_id,$taxon_id,$name_class) = $st->fetchrow_array()) {
    if ($TaxonNameIdHash->{$taxon_name_id}==1) {
      next();
    }
    elsif ($TaxonIdHash->{$taxon_id}->{$name_class}==1) {
      my $newTaxonName = GUS::Model::SRes::TaxonName->new({'taxon_name_id'=>$taxon_name_id});
      $newTaxonName->retrieveFromDB();
      $newTaxonName->markDeleted();
      $num += $newTaxonName->submit();
      $newTaxonName->undefPointerCache();
     }
  }
  $self->log("$num TaxonName entries deleted\n");
}
1;

__END__

=pod
=head1 Description
B<LoadTaxon> - a plug-in that creates Taxon, TaxonName,and GeneticCode entries from ncbi files.

=head1 Purpose
B<LoadTaxon> is a  GUS application that creates Taxon, TaxonName,and GeneticCode entries from ncbi files-original GUS taxon_ids have been retained.

      
