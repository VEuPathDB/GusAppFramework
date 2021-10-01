package GUS::Supported::Plugin::LoadTaxon;

@ISA = qw(GUS::PluginMgr::Plugin);
use strict;


use GUS::PluginMgr::Plugin;
use GUS::Model::SRes::Taxon;
use GUS::Model::SRes::TaxonName;
use GUS::Model::SRes::GeneticCode;
use GUS::PluginMgr::Plugin;
use GUS::Model::SRes::Taxon_Table;
use Data::Dumper;

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


  $self->initialize({requiredDbVersion => 4.0,
		     cvsRevision => '$Revision$', # cvs fills this in!
		     name => ref($self),
		     argsDeclaration   => $argsDeclaration,
		     documentation     => $documentation});

  return $self;
}

sub run {

    my $self   = shift;

    my $count = 0;

    $self->cacheTaxonIdMapping();
    
    $self->mergeTaxons();

    my $genCodes = $self->makeGeneticCode();
    
    my $nodesHash = $self->makeNodesHash($genCodes);
    
    my $rootAttArray = $self->getRootAttArray($genCodes);

    $self->log("Inserting and updating taxon entries");
    $self->makeTaxonEntry($rootAttArray, \$count);
    
    if ($self->getArg('restart') > 1) {
	$self->getTaxonAtt($self->getArg('restart'),$nodesHash,\$count);
    }
    else {
	$self->getTaxonAtt($rootAttArray->[0],$nodesHash,\$count); 
    }
    $self->getDb()->manageTransaction(0,'commit'); ##commit remaining uncommitted ones
    $self->log("Finished inserting taxon entries: total processed = $count");

    my ($TaxonNameIdHash,$TaxonIdHash) = $self->makeTaxonName($self->getNames());

    $self->deleteTaxonName($TaxonNameIdHash,$TaxonIdHash);

}

sub mergeTaxons {
  my $self   = shift;
  $self->log("Merging taxons");

  my $taxonTable = GUS::Model::SRes::Taxon_Table->new();

  my @childrenTables;
  foreach my $childArray (@{$taxonTable->{children}}) {
    my $childTable = $childArray->[0];
    my $childField = $childArray->[2];

    $childTable =~ s/GUS::Model:://;
    $childTable =~ s/::/./;

    push @childrenTables, [$childTable, $childField];
  }

  $self->getDb()->manageTransaction(0, 'begin');

  my $dbh = $self->getDbHandle();
  my $updateTaxonRow = $dbh->prepare("update sres.taxon set ncbi_tax_id = ? where taxon_id = ?");

  my $merged = $self->getArg('merged');
  open (MERGED,$merged) || die "Can't open merged file '$merged': $!\n";

  my $rowCount;
  while(<MERGED>) {
    chomp;

    my ($oldNcbiTaxId, $newNcbiTaxId) = split(/\s*\|\s*/, $_);

    my $oldTaxonId = $self->getTaxon($oldNcbiTaxId);
    if (! $oldTaxonId) {
#      $self->log("Doing merge and NCBI tax id '$oldNcbiTaxId' not in database, skipping");
      next;
    }
    my $newTaxonId = $self->getTaxon($newNcbiTaxId);

    # replace ncbi_tax_id for old row where merged row prev didn't exist in db
    if (! $newTaxonId) {
      $rowCount++ if($self->updateTaxonRow($updateTaxonRow, $oldTaxonId, $oldNcbiTaxId, $newNcbiTaxId));
    }

    # if there is old and new, set children old->new and delete old row
    $self->updateTaxonAndChildRows ($dbh, $oldTaxonId, $oldNcbiTaxId, $newTaxonId, $newNcbiTaxId, \@childrenTables) if ($newTaxonId);

    if($rowCount++ % 2000 == 0) {
      $self->getDb()->manageTransaction(0, 'commit');
      $self->getDb()->manageTransaction(0, 'begin');
    }
  }

  $self->getDb()->manageTransaction(0, 'commit');
}

sub updateTaxonRow {
  my ($self, $update, $oldTaxonId, $oldNcbiTaxId, $newNcbiTaxId) = @_;

  if($oldNcbiTaxId != $newNcbiTaxId) {
    ##deal with idcache
    $self->{taxonIdMapping}->{$newNcbiTaxId} = $oldTaxonId;
    delete $self->{taxonIdMapping}->{$oldNcbiTaxId};

    $self->log("update sres.taxon set ncbi_tax_id = $newNcbiTaxId where taxon_id = $oldTaxonId");
    $update->execute($newNcbiTaxId, $oldTaxonId) or $self->error("Can't execute SQL statement: $DBI::errstr"); 

    return 1;
  }
  return 0;
}

sub updateTaxonAndChildRows {
  my ($self,$dbh, $oldTaxonId,$oldNcbiTaxId, $newTaxonId, $newNcbiTaxId, $childrenTables)= @_;

  foreach my $tableArray (@$childrenTables) {
    my $table = $tableArray->[0];
    my $field = $tableArray->[1];

    $self->log("update $table set $field = $newTaxonId where $field = $oldTaxonId");
    my $update = $dbh->prepare("update $table set $field = ? where $field = ?");
    $update->execute($newTaxonId, $oldTaxonId) or $self->error("Can't execute SQL statement: $DBI::errstr");
    $self->getDb()->manageTransaction(0, 'commit');
    $self->getDb()->manageTransaction(0, 'begin');
  }

  ##deal with idcache
  $self->{taxonIdMapping}->{$newNcbiTaxId} = $newTaxonId;
  delete $self->{taxonIdMapping}->{$oldNcbiTaxId};

  $self->log("delete sres.taxon where taxon_id = $oldTaxonId");
  $dbh->do("delete sres.taxon where taxon_id = $oldTaxonId") or $self->error("Can't execute SQL statement: $DBI::errstr");

  return 1;
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
    $newTaxon->retrieveFromDB() if $self->{taxonIdMapping}->{$tax_id};
    
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
    

    $self->getDb()->manageTransaction(0,'begin') if $$count % 100 == 0;
    
    my $submit = $newTaxon->submit(0,1);

    $self->{taxonIdMapping}->{$newTaxon->getNcbiTaxId()} = $newTaxon->getId();
    $$count++;

    if ($$count % 100 == 0) {
      $self->getDb()->manageTransaction(0,'commit');
      $self->log("  Processed $$count taxon rows") if $$count % 10000 == 0;
    }

    $self->undefPointerCache();
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

sub cacheTaxonIdMapping {
  my $self = shift;
  my $st = $self->prepareAndExecute("select taxon_id, ncbi_tax_id from sres.taxon");
  while(my($taxon_id,$n_tax_id) = $st->fetchrow_array()){
    $self->{taxonIdMapping}->{$n_tax_id} = $taxon_id;
  }
}


sub getTaxon{
    my ($self,$tax_id) = @_;
    return $self->{taxonIdMapping}->{$tax_id};
}

sub makeTaxonName {

  my $self   = shift;
  my $namesDmp = shift;
  $self->log("Inserting and updating TaxonName");
  my %TaxonNameIdHash;
  my %TaxonIdHash;
  my $num = 0;
  my $nameCache = {};

  ##want to cache the taxonNames in the db so don't have to call retreiveFromDB unless already in the db
  my $st = $self->prepareAndExecute("select taxon_name_id, taxon_id, name, unique_name_variant, name_class from sres.taxonname");
  while(my($taxonNameId,$taxonId,$name,$nameClass,$variant) = $st->fetchrow_array()){
    $nameCache->{$taxonId}->{$name}->{$nameClass}->{$variant} = $taxonNameId;
  }
  
  foreach my $tax_id (keys %$namesDmp) {
    my $taxon_id = $self->getTaxon($tax_id);
    foreach my $name (keys %{$namesDmp->{$tax_id}}) {
      foreach my $name_class (keys %{$namesDmp->{$tax_id}->{$name}}) {
	foreach my $unique_name_variant (keys %{$namesDmp->{$tax_id}->{$name}->{$name_class}}) {
	  my %attHash = ('taxon_id'=>$taxon_id,'name'=>$name, 'unique_name_variant'=> $unique_name_variant, 'name_class'=>$name_class);

          my $taxon_name_id;
          if($nameCache->{$taxon_id}->{$name}->{$name_class}->{$unique_name_variant}){
            $taxon_name_id = $nameCache->{$taxon_id}->{$name}->{$name_class}->{$unique_name_variant};
          }else{
            my $newTaxonName = GUS::Model::SRes::TaxonName->new(\%attHash);
            $self->getDb()->manageTransaction(0,'begin') if $num % 100 == 0;
	    $num += $newTaxonName->submit(0,1);
            if($num % 100 == 0){
              $self->getDb()->manageTransaction(0,'commit');
              $self->log("  Processed $num taxonName rows") if $num % 10000 == 0;
            }
            $taxon_name_id = $newTaxonName->getTaxonNameId();
            $nameCache->{$taxon_id}->{$name}->{$name_class}->{$unique_name_variant} = $taxon_name_id;
	  }

	  $TaxonNameIdHash{$taxon_name_id}=1;
	  $TaxonIdHash{$taxon_id}->{$name_class}=1;
	  
	  
	  $self->undefPointerCache();
	}
      }
    }
  }
  $self->getDb()->manageTransaction(0,'commit');
  $self->log("$num taxon names inserted\n");
  return (\%TaxonNameIdHash,\%TaxonIdHash);
}

sub deleteTaxonName {
  my $self   = shift;
  my ($TaxonNameIdHash,$TaxonIdHash) = @_;
  $self->log("Deleting TaxonNames when redundant");
  my $num = 0;
  my $dbh = $self->getDbHandle();
  $self->getDb()->manageTransaction(0,'begin');
  my $st = $self->prepareAndExecute("select taxon_name_id, taxon_id, name_class from sres.taxonname");
  while (my ($taxon_name_id,$taxon_id,$name_class) = $st->fetchrow_array()) {
    if ($TaxonNameIdHash->{$taxon_name_id}==1) {
      next();
    }
    elsif ($TaxonIdHash->{$taxon_id}->{$name_class}==1) {

      $num += $dbh->do("delete sres.taxonname where taxon_name_id = $taxon_name_id") or $self->error("Can't execute SQL statement: $DBI::errstr");
      if($num % 1000 == 0) {
        $self->getDb()->manageTransaction(0,'commit');
        $self->getDb()->manageTransaction(0,'begin');
      }
     }
  }
  $self->getDb()->manageTransaction(0,'commit');
  $self->log("$num TaxonName entries deleted\n");
}

sub undoTables {
  my ($self) = @_;

   return('SRes.TaxonName', 'SRes.Taxon', 'SRes.GeneticCode');
}


1;

__END__

=pod
=head1 Description
B<LoadTaxon> - a plug-in that creates Taxon, TaxonName,and GeneticCode entries from ncbi files.

=head1 Purpose
B<LoadTaxon> is a  GUS application that creates Taxon, TaxonName,and GeneticCode entries from ncbi files-original GUS taxon_ids have been retained.

      
