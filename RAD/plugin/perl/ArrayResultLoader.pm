# ----------------------------------------------------------
# ArrayResultLoader.pm
#
# Loads data into ElementResultImp,CompositeElementResultImp,
#  
# Mandatory inputs are quantification_id and a data file.
# 
# Created: Monday July 8 12:00:00 EST 2002
#
# junmin liu
#
# Modified April 15 2003
#   --to make it load affy data appropriately
#
# Last Modified Tuesday Jan 28 2003
#   --to make it consitant with new Build system
# 
# $Revision$ $Date$ $Author$
# ----------------------------------------------------------
package GUS::RAD::Plugin::ArrayResultLoader;
@ISA = qw( GUS::PluginMgr::Plugin );

use strict;
use IO::File;

use GUS::Model::RAD3::Quantification;
use GUS::Model::RAD3::Array;
use GUS::Model::RAD3::ElementAnnotation;

sub new {
  my $Class = shift;
  my $self = {};
  bless($self,$Class); # configuration object...

# call required inherited initialization methods
  my $usage = 'Loads data into ElementResultImp, CompositeElementResultImp tables in RAD3 database.';

# modify the following line to add a new view for ElementResultImp table

#  my $arrayRef=$m->sql_get_as_array_refs("select name from CORE.TABLEINFO where view_on_table_id = 2953");
#  my @erSubclassViewList=@$arrayRef;
#  print "@erSubclassViewList\n";

  my @erSubclassViewList=[qw (ArrayVisionElementResult GenePixElementResult SpotElementResult ScanAlyzeElementResult AffymetrixCEL GEMToolsElementResult AgilentElementResult)];
# modify the following line to add a new view for CompositeElementResultImp table
  my @crSubclassViewList=[qw (AffymetrixMAS4 AffymetrixMAS5 SAGETagResult MOIDResult RMAExpress GNFAffymetrixResult)];
# modify the following line to add a new view for ElementImp table
  my @eSubclassViewList=[qw (ShortOligo Spot SAGETagMapping)];  
  my @cSubclassViewList=[qw (ShortOligoFamily SpotFamily SAGETag)];  
  my @posOption=(1, 2, 3);
#  my $sh=$m->getQueryHandle->prepareAndExecute('select array_id from RAD3.Array');
#  my @arrayIdList;
#  while (my @row = $sh->fetchrow_array) {
#		push(@arrayIdList,@row);
#	} 
#  $sh->finish;
  
  my $easycsp = [
    {
      o => 'data_file',
      t => 'string',
      r => 1,
      h => 'mandatory, name of the data file (give full path)',
    }, 
    {
      o => 'e_subclass_view',
      t => 'string',
      r => 0,
      e => @eSubclassViewList,
      h => 'view name of ElementImp table',
    }, 
    {
      o => 'c_subclass_view',
      t => 'string',
      r => 0,
      e => @cSubclassViewList,
      h => 'view name of CompositeElementImp table',
    },
   {
      o => 'posOption',
      t => 'int',
      r => 0,
      e => @posOption,
      h => 'option choice of positionList of ShortOligoFamily table, default is 1',
      d => 1,
    },

   {
      o => 'noWarning',
      t => 'boolean',
      h => 'if specified, generate no warning messages',
    },
    {
      o => 'er_subclass_view',
      t => 'string',
      r => 0,
      e => @erSubclassViewList,
      h => 'view name of ElementResultImp table',
    }, 
   {
      o => 'cr_subclass_view',
      t => 'string',
      r => 0,
      e => @crSubclassViewList,
      h => 'view name of CompositeElementResultImp table',
    },  
    {
      o => 'quantification_id',
      t => 'int',
      r => 1,
      h => 'mandatory, RAD3 quantification id, the entry in Quantification table',
    },
#    {
#      o => 'is_related',
#      t => 'boolean',
#      h => 'if set, will load the associated date also',
#      d => 0,
#    },
    {
      o => 'rel_quantification_id',
      t => 'int',
      h => 'optional, for associated channel, RAD3 quantification id, the entry in Quantification table',
    },
   {
      o => 'cel_quantification_id',
      t => 'int',
      h => 'optional, if load affymetrix .chp file, then relate the associated quantification_id for affymetrix cel file in the RelatedQuantification table',
    },

    {
      o => 'array_id',
      t => 'int',
      r => 1,
      h => 'mandatory, RAD3 array id, the entry in Array table',
    },
    {
      o => 'testnumber',
      t => 'int',
      h => 'optional, number of iterations for testing',	 
    },
    {
      o => 'restart',
      t => 'int',
      h => 'optional,data file line number to start loading data from(start counting after the header)',
    }
	];

  $self->initialize({requiredDbVersion => {RAD3 => '3', Core => '3'},
		     cvsRevision => '$Revision$', # cvs fills this in!
                     cvsTag => '$Name$', # cvs fills this in!
                     name => ref($self),
                     revisionNotes => 'make consistent with GUS 3.0',
                     easyCspOptions => $easycsp,
                     usage => $usage
                 });

# return the new object
	return $self;
}

# Global variable
my $cfg_rv;
my @positionList;

sub run {
  my $M   = shift;
  $M->logRAIID;
  $M->logArgs;
  $M->logCommit;
  $M->setOk(1);

  my $RV;
 
# self-defined subroutine, check the command line arguments
#  
  $M->checkArgs(); 
  return unless $M->getOk();

# self-defined subroutine
# stores in a hash the mapping of table/view attributes to data file columns 
#  $M->readCfg();
#  return unless $M->getOk();

# require the elementimp and compositeelementimp view objects at running time  
  eval "require GUS::Model::RAD3::$M->getCla->{'er_subclass_view'}";
  eval "require GUS::Model::RAD3::$M->getCla->{'cr_subclass_view'}";

# set the global array $positionList and require the view for CompositeElementImp at running time
 
  if($M->getCla->{c_subclass_view} eq 'ShortOligoFamily'){
      
      eval "require GUS::Model::RAD3::ShortOligoFamily";    
      if( $M->getCla->{posOption} == 1){
	  @positionList = ('name');
      }
      if( $M->getCla->{posOption} == 2){
	  @positionList = ('external_database_release_id', 'source_id');
      }
      if( $M->getCla->{posOption} == 3){
	  @positionList = ('name', 'external_database_release_id', 'source_id');
      }
	
  }

 if($M->getCla->{c_subclass_view} eq 'SAGETag' ){
	@positionList = ('tag');
	eval "require GUS::Model::RAD3::SAGETag";
  }
# set the global array $positionList and require the view for ElementImp at running time
  if($M->getCla->{e_subclass_view} eq 'ShortOligo' ){
	@positionList = ('x_position', 'y_position');
	eval "require GUS::Model::RAD3::ShortOligo";
  }
  
  if($M->getCla->{e_subclass_view} eq 'Spot'){
	@positionList = ('array_row','array_column','grid_row','grid_column','sub_row','sub_column');
#      @positionList = ('grid_row','grid_column','sub_row','sub_column');
	eval "require GUS::Model::RAD3::Spot";
  }
  
  if($M->getCla->{e_subclass_view} eq 'SAGETagMapping' ){
	@positionList = ('external_database_release_id', 'source_id');
	eval "require GUS::Model::RAD3::SAGETagMapping";
  }
  

# self-defined subroutine, check the headers of data file if it provide the 
# header matching with them provide in configuration file
#
  my $fh=new IO::File;
  my $fileName=$M->getCla->{'data_file'};
    unless ($fh->open("<$fileName")) {
	$M->logData('Result', "Cannot open data file $fileName for reading.");
	return;
  }
  $M->parseHeader($fh);
  return unless $M->getOk();

# self-defined subroutine, check the headers in data file if it provide the 
# required attributes
#  
  $M->checkHeader(); 
  return unless $M->getOk();

# self-defined subroutine, update ResultTableId in quantification table
#
#
  $M->updateResultTableId();
  return unless $M->getOk();
  $M->logData('Result', "Finish updating Result_Table_Id in quantification table.");
  


# self-defined subroutine, related the .cel file and .chp file's quantification_id 
# 
  if($M->getCla->{cel_quantification_id}){
      eval "require GUS::Model::RAD3::RelatedQuantification";
      $M->relateQuantifications(); 
      return unless $M->getOk();
  }

# self-defined subroutine, read the headers of data file if it provide the 
# header matching with them provide in configuration file
#
  $RV = $M->loadData($fh);
  $fh->close();

  return $RV;
}

sub checkArgs {
    my $M = shift;
    my $RV="";
    $M->setOk(1);
    my $quan_id=$M->getCla->{'quantification_id'};
    my $array_id=$M->getCla->{'array_id'};
    my $query;
    my $dbh = $M->getSelfInv->getQueryHandle();
    my $sth;

# one of the e_subclass_view or c_subclass_view must be provided
    if(!defined $M->getCla->{e_subclass_view} && !defined $M->getCla->{c_subclass_view}){
	$RV = join(' ','a --e_subclass_view <view name for ElementImp>', $M->getCla->{e_subclass_view},'or --c_subclass_view <view name for CompositeElementImp> must be on the commandline', $M->getCla->{c_subclass_view});
	$M->setOk(0);
	$M->logData('ERROR', $RV);
	if($M->getCla->{'commit'}){print STDERR "ERROR: $RV\n";}
	return;
    }


# one of the er_subclass_view or cr_subclass_view must be provided
    if(!defined $M->getCla->{er_subclass_view} && !defined $M->getCla->{cr_subclass_view}){
	$RV = join(' ','a --er_subclass_view <view name for ElementResultImp>', $M->getCla->{er_subclass_view},'or --cr_subclass_view <view name for CompositeElementResultImp> must be on the commandline', $M->getCla->{cr_subclass_view});
	$M->setOk(0);
	$M->logData('RESULT', $RV);
	if($M->getCla->{'commit'}){print STDERR "ERROR: $RV\n";}
	return;
    }

# check that the given quantification_id is a valid one
# skip this check for now
    if($M->getCla->{debug}){
	$M->checkId('RAD3', 'Quantification', 'quantification_id', $M->getCla->{'quantification_id'}, 'quantification_id');
	return unless $M->getOk();
    }

# check that the given quantification_id is a valid one
    if(defined $M->getCla->{cel_quantification_id}){
	$M->checkId('RAD3', 'Quantification', 'quantification_id', $M->getCla->{'cel_quantification_id'}, 'cel_quantification_id');
	return unless $M->getOk();
    }
# check that the given array_id is a valid one
    $M->checkId('RAD3', 'Array', 'array_id', $M->getCla->{'array_id'}, 'array_id');
    return unless $M->getOk();

#check if given array_id and quantification_id matched
    $query="select a.assay_id from RAD3.acquisition aq, rad3.quantification qa, rad3.assay a where quantification_id=$quan_id and qa.acquisition_id=aq.acquisition_id and aq.assay_id=a.assay_id and a.array_id=$array_id";
    $sth = $dbh->prepare($query);
    $sth->execute();
    my ($assay_id) = $sth->fetchrow_array();
    $sth->finish();
    if (!defined $assay_id) {
	$RV="quantification_id $quan_id and array_id $array_id are not related ids.";
	$M->setOk(0);
	$M->logData('ERROR', $RV);
	if($M->getCla->{'commit'}){print STDERR "ERROR: $RV\n";}
	return;
    }

# check rel_quantification_id 
    if(defined $M->getCla->{rel_quantification_id}){
# check that the given rel_quantification_id is a valid one
# skip this check for now
	if($M->getCla->{debug}){
	    $M->checkId('RAD3','Quantification','quantification_id',$M->getCla->{'rel_quantification_id'},'rel_quantification_id');
	    return unless $M->getOk();
	}
	my $rel_quan_id=$M->getCla->{'rel_quantification_id'};    
	$query="select related_quantification_id from rad3.relatedquantification where quantification_id=$quan_id and associated_quantification_id=$rel_quan_id";

	$sth = $dbh->prepare($query);
	$sth->execute();
	my ($qid) = $sth->fetchrow_array();
	$sth->finish();
	if (!defined $qid) {
	    $RV="$quan_id and $rel_quan_id are not related quantification ids.";
	    $M->setOk(0);
	    $M->logData('ERROR', $RV);
	    if($M->getCla->{'commit'}){print STDERR "ERROR: $RV\n";}
	    return;
	}
#check if given array_id and rel_quantification_id matched
	$query="select a.assay_id from rad3.acquisition aq, rad3.quantification qa, rad3.assay a where quantification_id=$rel_quan_id and qa.acquisition_id=aq.acquisition_id and aq.assay_id=a.assay_id and a.array_id=$array_id";
	$sth = $dbh->prepare($query);
	$sth->execute();
	my ($assay_id) = $sth->fetchrow_array();
	$sth->finish();
	if (!defined $assay_id) {
	    $RV="rel_quantification_id $quan_id and array_id $array_id are not related ids.";
	    $M->setOk(0);
	    $M->logData('ERROR', $RV);
	    if($M->getCla->{'commit'}){print STDERR "ERROR: $RV\n";}
	    return;
	}
    
    }


    $M->logData('RESULT', 'finished checking command line arguments');
}

sub checkId{
    my $M = shift;
    my $RV;
    $M->setOk(1);
    my ($database, $tablename, $pkname, $id, $claname)=@_;

    my $object=lc($tablename);
    my $Object=join('::', 'GUS', 'Model', $database, $tablename);

    my $object = $Object->new({$pkname=>$id});
    if (!$object->retrieveFromDB()) {
	$RV = join(' ','a VALID --', $claname, 'must be on the commandline', $claname, '=',$M->getCla->{$claname});
	$M->logData('ERROR', $RV);
	if($M->getCla->{'commit'}){print STDERR "ERROR: $RV\n";}
	$M->setOk(0);
    }
    return $RV;
}

# get the attribute list for a given table
sub getAttrArray(){
    my $M = shift;
    my ($table_name)=@_;
    my @attr_array;
    
    $M->setOk(1);
    my $RV="";
# get the database handle
  my $extent=$M->getDb->getTable($table_name);
    if (not defined($extent)){
	$M->setOk(0);
	$RV = join(' ','Cannot get the database handle', $table_name);
	$M->logData('ERROR', $RV);
	if($M->getCla->{'commit'}){print STDERR "ERROR: $RV\n";}
	return;
    }

# retrive attribute infor for the table
    my $lref=$extent->getAttributeInfo();
     foreach my $att(@$lref){
	my $cname=$att->{'col'};
	push (@attr_array, $cname);
    }
    return @attr_array;
}

# put nullability of attributes into a hash for a given table
sub getAttrHashRef(){
    my $M = shift;
    my ($table_name)=@_;
    my $attr_hash;

    $M->setOk(1);
    my $RV="";
# get the database handle
    my $extent=$M->getDb->getTable($table_name);
    if (not defined($extent)){
	$M->setOk(0);
	$RV = join(' ','Cannot get the database handle', $table_name);
	$M->logData('ERROR', $RV);
	if($M->getCla->{'commit'}){print STDERR "ERROR: $RV\n";}
	return;
    }
# retrive attribute infor for the table
    my $lref=$extent->getAttributeInfo();
    my $primarykey=$extent->getPrimaryKeyAttributes();

    my $parents=$extent->getParentRelations();
    my @fkArray;
    foreach my $item(@$parents){
	    push (@fkArray, $item->[1]);
    }

    my @common_attr=('modification_date', 'user_read', 'user_write', 'group_read', 'group_write', 'other_read', 'other_write', 'row_user_id','row_group_id', 'row_project_id', 'row_alg_invocation_id');

# Process parent relations into a hash indexed by
# column name.
#
#    my %pHash;
#    foreach my $p (keys @$parents) {
#	my $rel = $parents->{$p};
#	foreach my $mykey (keys %$rel) {
#	    my $val = $rel->{$mykey};
#	    $pHash{$mykey} = {'table' => $p, 'columns' => $val};
#	}
#    }

    foreach my $att(@$lref){
	my $cname=$att->{'col'};
# don't load the primary key, foreign keys and @common_attr which will set automatically to not nullable
# so we don't put them into attr_hash

#	next if( (grep(/^$cname$/, @$primarykey))|| defined $pHash{$cname} ||(grep(/^$cname$/, @common_attr)) );
	next if( (grep(/^$cname$/, @$primarykey))|| (grep(/^$cname$/, @common_attr)) || (grep(/^$cname$/, @fkArray)) );
	if($att->{'Nulls'}==1){ 
	  $attr_hash->{$cname}='Nullable';
        }
	else{
	   $attr_hash->{$cname}='Not Nullable'; 
	}
    }
    return $attr_hash;
}

# given a table name, check the nullability of the attrbutes and if their values are provided in configuration file
sub checkMandatory(){
    my $M = shift;
    my ($database, $table_name, $view_name)=@_;

    if(!defined $view_name){
	$view_name=join('::', $database, $table_name);
    }
    else{
	$view_name=join('::', $database, $view_name);
    }

    $M->setOk(1);
    my $RV="";
# get the nullability of each attribute except primary key, foreign keys and those common attributes
    my $attr_hash=$M->getAttrHashRef($view_name);
    if(! $M->getOk){
	$RV = join(' ','Cannot retrive the attribute info of', $view_name);
	$M->logData('ERROR', $RV);
	if($M->getCla->{'commit'}){print STDERR "ERROR: $RV\n";}
	return;
    }
    foreach my $key (keys %$attr_hash){
	my $cfg_key=join('.', $table_name, $key);

	if( $attr_hash->{$key} =~ /^Not Nullable$/) {

	    if(!defined ($cfg_rv->{'mapping'}->{$cfg_key}) )
	    {
		$M->setOk(0); 
		$RV .="$cfg_key, ";
	    }
	}
    }
    if (! $M->getOk){
	$RV .=" missing in configuration file";
	$M->logData('ERROR', $RV);
	if($M->getCla->{'commit'}){print STDERR "ERROR: $RV\n";}
    }
}

sub parseHeader{
  my  $M=shift;
  my ($fh) = @_;
  my %headers;

  my $line = "";
  while ($line =~ /^\s*$/) {
    last unless $line = <$fh>;
  }
  
  if($M->getCla->{debug}){
      print "Headers $line\n";
  }

  my @arr = split (/\t/, $line);
#    print "hello@arr\n$line\n";
  for (my $i=0; $i<@arr; $i++) {
  
    $arr[$i] =~ s/^\s+|\s+$//g;
    $arr[$i] =~ s/\"|\'//g;
    if ($headers{$arr[$i]}) {
#	print "$arr[$i]\n";
	$fh->close();
      
      die "No two columns can have the same name in the data file header.\n";
    }
    else {
      $headers{$arr[$i]} = 1;
    }
    $cfg_rv->{'position'}->{$arr[$i]} = $i;
  }

  $cfg_rv->{'num_fields'} = scalar(@arr);
  $M->logData('Result', 'finish parsing the headers of array data file');
}

sub checkHeader{
    my $M=shift; 
    $M ->setOk(1);
    my $RV;
    foreach my $arr (@positionList){
	if (! defined $cfg_rv->{'position'}->{$arr}){
	    $RV = "Missing header $arr in the data file which is required to define one element";
	    $M ->logData("ERROR", $RV);
	    $M ->setOk(0);
	    if($M->getCla->{'commit'}){print STDERR "ERROR: $RV\n";}
	    return;
	}
    }
    $M->logData('Result', 'finish checking the headers of array data file');
}

sub relateQuantifications{
    my $M=shift; 
    my $RV;
    $M->setOk(1);
    my $relQuan_hash;
    $relQuan_hash->{'quantification_id'} = $M->getCla->{quantification_id};
    $relQuan_hash->{'associated_quantification_id'} = $M->getCla->{cel_quantification_id};
    my $c_subclass_view=$M->getCla->{'cr_subclass_view'};
  #  $relQuan_hash->{'ASSOCIATED_DESIGNATION'}="cel quantification";
  #  $relQuan_hash->{'DESIGNATION'}="chp quantification";
    my @attributesToNotRetrieve = ('modification_date', 'row_alg_invocation_id');     
    my $rel_quantification = GUS::Model::RAD3::RelatedQuantification->new($relQuan_hash);
    my $id;
    my $relId;
# check whether this row is already in the database
# if it is, get its primary key
     if ($rel_quantification->retrieveFromDB(\@attributesToNotRetrieve)) {
	 $id=$relQuan_hash->{'quantification_id'};
	 $relId=$relQuan_hash->{'associated_quantification_id'};
	 $RV="The chp quantification_id $id and cel quantification_id $relId have already been linked in relatedQuantification table as quantification_id and associated_quantification_id\tNo insert";
	 $M->logData('Result', $RV);
	 if($M->getCla->{'commit'}){print STDERR "RESULT: $RV\n";}
     }
     else{
	 if($c_subclass_view == "RMAExpress"){
	     $rel_quantification->setDesignation("RMA quantification");
	     $rel_quantification->setAssociatedDesignation("cel quantification");
	 }
	 elsif($c_subclass_view == "MOIDResult"){
	     $rel_quantification->setDesignation("MOID quantification");
	     $rel_quantification->setAssociatedDesignation("cel quantification");	 
	 }
	 else{
	     $rel_quantification->setDesignation("chp quantification");
	     $rel_quantification->setAssociatedDesignation("cel quantification");
	 }
	 $rel_quantification->submit();
# need to rewrite this part
#
	 if($rel_quantification->getId()){
	     $RV="Linked the chp quantification_id $id and cel quantification_id $relId in relatedQuantification table as quantification_id and associated_quantification_id";
	     $M->logData('Result', $RV);
	     if($M->getCla->{'commit'}){print STDERR "Result: $RV\n";}
	 }
	 else{
	     $RV="The chp quantification_id $id and cel quantification_id $relId cann't be linked in relatedQuantification table as quantification_id and associated_quantification_id\tNo insert";
	     $M->logData('Error', $RV);
	     if($M->getCla->{'commit'}){print STDERR "Error: $RV\n";}
	 }
     }
# related in another way
    $relQuan_hash->{'associated_quantification_id'} = $M->getCla->{quantification_id};
    $relQuan_hash->{'quantification_id'} = $M->getCla->{cel_quantification_id};
  #  $relQuan_hash->{'ASSOCIATED_DESIGNATION'}="cel quantification";
  #  $relQuan_hash->{'DESIGNATION'}="chp quantification";

   $rel_quantification = GUS::Model::RAD3::RelatedQuantification->new($relQuan_hash);
# check whether this row is already in the database
# if it is, get its primary key
     if ($rel_quantification->retrieveFromDB(\@attributesToNotRetrieve)) {
	 my $id=$relQuan_hash->{'quantification_id'};
	 my $relId=$relQuan_hash->{'associated_quantification_id'};
	 $RV="The chp quantification_id $id and cel quantification_id $relId have already been linked in relatedQuantification table as associated_quantification_id and quantification_id\tNo insert";
	 $M->logData('Result', $RV);
	 if($M->getCla->{'commit'}){print STDERR "RESULT: $RV\n";}
     }
     else{
	 if($c_subclass_view == "RMAExpress"){
	     $rel_quantification->setDesignation("cel quantification");
	     $rel_quantification->setAssociatedDesignation("RMA quantification");
	 }
	 elsif($c_subclass_view == "MOIDResult"){
	     $rel_quantification->setDesignation("cel quantification");
	     $rel_quantification->setAssociatedDesignation("MOID quantification");	 
	 }
	 else{
	     $rel_quantification->setDesignation("cel quantification");
	     $rel_quantification->setAssociatedDesignation("chp quantification");
	 }
	 $rel_quantification->submit();
# need to rewrite this part
#
	 if($rel_quantification->getId()){
	     $RV="Linked the chp quantification_id $id and cel quantification_id $relId in relatedQuantification table as associated_quantification_id and quantification_id";
	     $M->logData('Result', $RV);
	     if($M->getCla->{'commit'}){print STDERR "Result: $RV\n";}
	 }
	 else{
	     $RV="The chp quantification_id $id and cel quantification_id $relId cann't be linked in relatedQuantification table as associated_quantification_id and quantification_id\tNo insert";
	     $M->logData('Error', $RV);
	     if($M->getCla->{'commit'}){print STDERR "Error: $RV\n";}
	 }
     }
}

sub loadData{
   my $M=shift;
   my ($fh)=@_;
   $M->setOk(1);
   my $RV;
#   my @common_attr=('modification_date', 'user_read', 'user_write', 'group_read', 'group_write', 'other_read', 'other_write', 'row_user_id','row_group_id', 'row_project_id', 'row_alg_invocation_id');
   $M->setOk(1);
   $cfg_rv->{num_inserts} = 0; # holds current number of rows inserted into ElementResultImp
   $cfg_rv->{num_spot_family} = 0; # holds current number of rows inserted into CompositeElementResultImp
   $cfg_rv->{warnings} = "";  
   my $line;
   $cfg_rv->{n} = 0; # holds the current number of rows being read 
# set all parameters
   my $array_id = $M->getCla->{array_id};
   my ($e_subclass_view, $c_subclass_view, $er_subclass_view, $cr_subclass_view);
   if(defined $M->getCla->{e_subclass_view}){
       $e_subclass_view = $M->getCla->{e_subclass_view};
   }
   if(defined $M->getCla->{c_subclass_view}){
       $c_subclass_view = $M->getCla->{c_subclass_view};
   }
   if(defined $M->getCla->{er_subclass_view}){
       $er_subclass_view = $M->getCla->{er_subclass_view};
       eval "require GUS::Model::RAD3::$er_subclass_view";
   } 
   if(defined $M->getCla->{cr_subclass_view}){
       $cr_subclass_view = $M->getCla->{cr_subclass_view};
       eval "require GUS::Model::RAD3::$cr_subclass_view";
   }
   my $quantification_id = $M->getCla->{quantification_id};
   my $rel_quantification_id;
   if(defined $M->getCla->{rel_quantification_id}){
      $rel_quantification_id = $M->getCla->{rel_quantification_id}; 
   }
# for querying ElementImp table to set the element_id or composite_element_id
   my ($spotClass, $spotFamilyClass);

   if(defined $e_subclass_view){
       if($e_subclass_view=~ /^ShortOligo$/){
	   $spotClass="GUS::Model::RAD3::ShortOligo";
       }
       elsif($e_subclass_view=~ /^Spot$/){
	   $spotClass="GUS::Model::RAD3::Spot"; 
       }
       else{
	   $spotClass="GUS::Model::RAD3::SAGETagMapping"; 
       }
   }
# if $e_subclass_view not set, querying CompositeElementImp table to set the  composite_element_id
   if(defined $c_subclass_view){
       if($c_subclass_view=~ /^ShortOligoFamily$/){
	   $spotFamilyClass="GUS::Model::RAD3::ShortOligoFamily";
       }
       elsif($c_subclass_view=~ /^SpotFamily$/){
	   $spotFamilyClass="GUS::Model::RAD3::SpotFamily"; 
       }
       else{
	   $spotFamilyClass="GUS::Model::RAD3::SAGETag"; 
       }

   }

   while ($line = <$fh>) {
     
     $cfg_rv->{n}++;
     if (($cfg_rv->{n})%200==0) {
	 $RV="Read $cfg_rv->{n} datalines including empty line";
	 $M->logData('Result', $RV);
	 if($M->getCla->{'commit'}){
	     $RV = "Processed $cfg_rv->{n} dataline including empty line, Inserted $cfg_rv->{num_inserts} ElementResults and $cfg_rv->{num_spot_family} CompositeElementResults."; 
	     print STDERR "RESULT: $RV\n";
	 }
#	 print STDERR "Read $n datalines including empty line\n";
     }
# skip number of line as defined by user
     if (defined $M->getCla->{'restart'} && $cfg_rv->{n}<$M->getCla->{'restart'}) {
	 next;
     }
# skip empty lines if any
     if ($line =~ /^\s*$/) {
	 next;
     }
     
     if($M->getCla->{debug}){
	 print "Debug\t$line\n";
     }

# stop reading data lines after testnumber of lines
     if (!$M->getCla->{'commit'} && defined $M->getCla->{'testnumber'} && $cfg_rv->{n}-$M->getCla->{'restart'}==$M->getCla->{'testnumber'}+1) {
	 $cfg_rv->{n}--;
	 my $stopNumber=$M->getCla->{'testnumber'};
	 $RV="stopping reading after testing $stopNumber lines";
	 $M->logData('Result', $RV);
	 last;
     }

     my @arr = split(/\t/, $line);
     if (scalar(@arr) != $cfg_rv->{'num_fields'}) {
	 $cfg_rv->{warnings} = "The number of fields for data line $cfg_rv->{n} does not equal the number of fields in the header.\nThis might indicate a problem with the data file.\nData loading is interrupted.\nData from data line $cfg_rv->{n} and following lines were not loaded.\nHere $cfg_rv->{n} is the number of lines (including empty ones) after the header.\n";   
	 $M->logData('Warning', $cfg_rv->{warnings});
	 $M->setOk(0);
	if($M->getCla->{'commit'}){print STDERR "Warning: $RV\n";}
	 last; #exit the while loop
     }

# get rid of preceding and trailing spaces and of quotes
     for (my $i=0; $i<@arr; $i++) {
	 $arr[$i] =~ s/^\s+|\s+$//g;
	 $arr[$i] =~ s/\"|\'//g;
     }

     $cfg_rv->{skip_line} = 0; # when set to 1 the current data line is skipped

     my $pos=$cfg_rv->{'position'};
     my @attributesToNotRetrieve = ('modification_date', 'row_alg_invocation_id');     
     my ($spot_id, $spot_family_id);
# get the element_id for the row
if(defined $e_subclass_view){
     my $spot_hash;
     my $spot;
     $spot_hash->{'array_id'} = $array_id;
     foreach my $item(@positionList){
	 if(defined $arr[$pos->{$item}]){
	     $spot_hash->{$item} = $arr[$pos->{$item}]; 
	 }
	 else{
	     $cfg_rv->{warnings} = "Data file line $cfg_rv->{n} is missing attribute ElementImp.$item, which is mandatory.\nData from this data line were not loaded.\nHere $cfg_rv->{n} is the number of lines (including empty ones) after the header.\n\n";
	     $M->logData('Warning', $cfg_rv->{warnings});
#	     print STDERR $warnings; 
	     if($M->getCla->{'commit'}){print STDERR "Warning: $RV\n";}
	     $cfg_rv->{skip_line} = 1;
	     last; # exit the foreach loop
	 }
     }

     next if ($cfg_rv->{skip_line} == 1); # skip this row


     my $elementAnnotation_hash;
     my $elementAnnotation;
 #    $elementAnnotation_hash->{'name'}=$arr[$pos->{'name'}];
 #    $elementAnnotation_hash->{'name'}=$arr[$pos->{'value'}];
 #    $elementAnnotation=GUS::Model::RAD3::ElementAnnotation->new($elementAnnotation_hash);

     $spot = $spotClass->new($spot_hash);
 #   $spot->setChild($elementAnnotation);

     if ($spot->retrieveFromDB(\@attributesToNotRetrieve)) {
	 $cfg_rv->{spot_id} = $spot->getId();
#	 print "$spot_id\n";
	 $cfg_rv->{spot_family_id} = $spot->getCompositeElementId();
     }
     else{
	 $RV="Couldn't find the corresponding element_id for the data line no. $cfg_rv->{n}\tskip this\tNo insert";
	 if(! $M->getCla->{noWarning} ){
	     $M->logData('Warning', $RV);
	 }

	 if($M->getCla->{'commit'} && ! $M->getCla->{noWarning} ){
	     print STDERR "Warning: $RV\n";
	 }

	 $cfg_rv->{skip_line} = 1;
	 next; # skip this row
     }
}

# or get the composite_element_id for the row
if(defined $c_subclass_view){
     my $spot_fam_hash;
     my $spotFam;
     $spot_fam_hash->{'array_id'} = $array_id;
     foreach my $item(@positionList){
	 if(defined $arr[$pos->{$item}]){
	     $spot_fam_hash->{$item} = $arr[$pos->{$item}]; 
	 }
	 else{
	     $cfg_rv->{warnings} = "Data file line $cfg_rv->{n} is missing attribute CompositeElementImp.$item, which is mandatory.\nData from this data line were not loaded.\nHere $cfg_rv->{n} is the number of lines (including empty ones) after the header.\n\n";
	     $M->logData('Warning', $cfg_rv->{warnings});
#	     print STDERR $warnings;
	     if($M->getCla->{'commit'}){print STDERR "Warning: $RV\n";} 
	     $cfg_rv->{skip_line} = 1;
	     last; # exit the foreach loop
	 }
     }

     next if ($cfg_rv->{skip_line} == 1); # skip this row


     my $elementAnnotation_hash;
     my $elementAnnotation;
 #    $elementAnnotation_hash->{'name'}=$arr[$pos->{'name'}];
 #    $elementAnnotation_hash->{'name'}=$arr[$pos->{'value'}];
 #    $elementAnnotation=GUS::Model::RAD3::ElementAnnotation->new($elementAnnotation_hash);

     $spotFam = $spotFamilyClass->new($spot_fam_hash);
 #   $spot->setChild($elementAnnotation);


     if ($spotFam->retrieveFromDB(\@attributesToNotRetrieve)) {
	 $cfg_rv->{spot_family_id} = $spotFam->getCompositeElementId();
     }
     else{
	 $RV="Couldn't find the corresponding composite_element_id for the data line no. $cfg_rv->{n}\tskip this\tNo insert";
	 if(! $M->getCla->{noWarning}){
	     $M->logData('Warning', $RV);
	 }
	 if($M->getCla->{'commit'} && !$M->getCla->{noWarning} ){
	     print STDERR "Warning: $RV\n";
	 }
	 $cfg_rv->{skip_line} = 1;
	 next; # skip this row
     }
}

     
# build a row for spotfamilyresultImp

     if(defined $cr_subclass_view && defined $cfg_rv->{spot_family_id} && $cfg_rv->{spot_family_id} ne 'null'){
	 if(defined $M->getCla->{rel_quantification_id}){
	     $cfg_rv->{channel}='channel1';
	     $M->updateSpotFamResult(@arr);
	     $cfg_rv->{channel}='channel2';
 	     $M->updateSpotFamResult(@arr);
	 } 
	 else{
	     $M->updateSpotFamResult(@arr);
	 }
     }
     if(defined $cr_subclass_view && (!defined $cfg_rv->{spot_family_id} || $cfg_rv->{spot_family_id} eq 'null')){
	 $RV="Couldn't find the corresponding composite_element_id for the data line no. $cfg_rv->{n}\tskip this\tNo insert into CompositeElementResultImp";
	 $M->logData('Warning', $RV);
	 if($M->getCla->{'commit'}){print STDERR "Warning: $RV\n";}
     }

# build a row for ElementResultImp
     if(defined $er_subclass_view){
	  if(defined $M->getCla->{rel_quantification_id}){
#	      print "$spot_id\n";
	      $cfg_rv->{channel}='channel1';
	      $M->updateSpotResult(@arr);
	      $cfg_rv->{channel}='channel2';
	      $M->updateSpotResult(@arr);
	 } 
	 else{

	     $M->updateSpotResult(@arr);
	 }
     }
     my $numOfLine=$cfg_rv->{n};

# reach the max 9000 objects, do clean up, but to be safe use 9000 instead
     if( ($numOfLine*5) % 9000 == 0 ) {$M->undefPointerCache();}

 }#end of while loop

#   $dbh->disconnect();
   $RV="Total datalines read (after header): $cfg_rv->{n}.";
   if($M->getCla->{'commit'}){print STDERR "RESULT: $RV\n";}
   
   $M->logData('Result', $RV);
   my $total_insert;
   if($cfg_rv->{num_inserts}==0){
       $total_insert=$cfg_rv->{num_spot_family};
   }
   else{
       $total_insert=$cfg_rv->{num_inserts};
   }

   $RV="Number of lines which have been inserted into database (after header): $total_insert.";
   $M->logData('Result', $RV);
   if($M->getCla->{'commit'}){print STDERR "RESULT: $RV\n";}
   
   $RV="Number of records which have been inserted into CompositeElementImp table (after header): $cfg_rv->{num_spot_family}.";
   $M->logData('Result', $RV);
   if($M->getCla->{'commit'}){print STDERR "RESULT: $RV\n";}
   
   $RV = "Processed $cfg_rv->{n} dataline, Inserted $cfg_rv->{num_inserts} ElementResults and $cfg_rv->{num_spot_family} CompositeElementResults."; 
   return $RV;
   
}


sub updateResultTableId{
  my $M = shift;
  $M ->setOk(1);
  my $t_id;
  my $RV;
  my $er_subclass_view;
  if(defined $M->getCla->{er_subclass_view}){
    $er_subclass_view = $M->getCla->{er_subclass_view};
    $t_id=$M->getTable_Id($er_subclass_view);  
  } 
  
  my $cr_subclass_view;
  if(defined $M->getCla->{cr_subclass_view}){
    $cr_subclass_view = $M->getCla->{cr_subclass_view};
    $t_id=$M->getTable_Id($cr_subclass_view);
  }
  
  my $quantification_id = $M->getCla->{quantification_id};
  if(!$M->updateQuantification($t_id, $quantification_id)){
    $RV = "ERROR\tCann't set result_table_id to $t_id for quantification id $quantification_id in quantification table.\n";
    print STDERR  $RV;
    $M ->setOk(0);
    return;
  }

   my $rel_quantification_id;
   if(defined $M->getCla->{rel_quantification_id}){
      $rel_quantification_id = $M->getCla->{rel_quantification_id}; 
      if(!$M->updateQuantification($t_id, $rel_quantification_id)){
	$RV = "ERROR\tCann't set result_table_id to $t_id for quantification id $rel_quantification_id in quantification table.\n";
	print STDERR  $RV;
	$M ->setOk(0);
	return;
    }
   }
}

sub updateQuantification{
  my $M = shift;
  my ($result_table_id, $q_id )=@_;
  my $quan_hash;
  $quan_hash->{'quantification_id'}=$q_id;
  my $quan=GUS::Model::RAD3::Quantification->new($quan_hash);
  $quan->retrieveFromDB();
  
  if(  $quan->setResultTableId($result_table_id)){
      if($quan->submit()){
	  return 1;
      }
      else{
	  return 0;
      }
  }
  else{
      return 0;
  }
}

sub getTable_Id{
    my $M = shift;
    my ($table_name)=@_;
 #eval "require GUS::Model::RAD3::$cfg_rv->{'mapping'}->{'CompositeElementImp.subclass_view'}";
  #eval "require GUS::Model::RAD3::$cfg_rv->{'mapping'}->{'ElementImp.subclass_view'}";
    $M->setOk(1);
    my $query="select t.table_id from core.tableinfo t where t.name='$table_name'";
    my $dbh = $M->getSelfInv->getQueryHandle();
    my $sth = $dbh->prepare($query);
    $sth->execute();
    my ($id) = $sth->fetchrow_array();
    $sth->finish();
    if (defined $id) {
	return $id;
    }
    else{
	$cfg_rv->{warnings} = "Cann't retrieve table_id for subclass view $table_name";
	$M->logData('Error', $cfg_rv->{warnings});
	if($M->getCla->{'commit'}){print STDERR "Error: Cann't retrieve table_id for subclass view $table_name\n";}
	$M->setOk(0);
    }
}

sub updateSpotFamResult{
    my $M = shift;
    my (@arr)=@_;
    my $pos=$cfg_rv->{position};
    my $spot_fam_hash;
    my $cr_subclass_view = $M->getCla->{cr_subclass_view};
    my $warnings;
    my $RV;
    my @attributesToNotRetrieve = ('modification_date', 'row_alg_invocation_id');     
    $spot_fam_hash->{'subclass_view'} = $cr_subclass_view;
    if(defined $cfg_rv->{channel} && $cfg_rv->{channel} eq 'channel2'){
	$spot_fam_hash->{'quantification_id'} = $M->getCla->{rel_quantification_id};
    }
    else{
	$spot_fam_hash->{'quantification_id'} = $M->getCla->{quantification_id};
    }
#   if(defined $spot_family_id && $spot_family_id ne "null"){
    $spot_fam_hash->{'composite_element_id'} = $cfg_rv->{spot_family_id};
	     
    my @spot_fam_attr=$M->getAttrArray("GUS::Model::RAD3::$cr_subclass_view");
    my $spot_fam_attr_hashref=$M->getAttrHashRef("GUS::Model::RAD3::$cr_subclass_view");
    for (my $i=0; $i<@spot_fam_attr; $i++) {
	my $attr;
	if(defined $cfg_rv->{channel}){
    	    $attr="channel1.$spot_fam_attr[$i]" if $cfg_rv->{channel} eq 'channel1';
    	    $attr="channel2.$spot_fam_attr[$i]" if $cfg_rv->{channel} eq 'channel2';
	}
	else{
	    $attr=$spot_fam_attr[$i];
	}
	 if ( defined $pos->{$attr} && $arr[$pos->{$attr}] ne "") {
	     $spot_fam_hash->{$spot_fam_attr[$i]} = $arr[$pos->{$attr}];
	 }
	 if ( ($spot_fam_attr_hashref->{$spot_fam_attr[$i]} =~ /^Not Nullable$/)  && !defined $spot_fam_hash->{$spot_fam_attr[$i]}) {
	     $warnings = "Data file line $cfg_rv->{n} is missing attribute CompositeElementResultImp.$spot_fam_attr[$i], which is mandatory.\nData from this data line were not loaded for $cfg_rv->{channel}.\nHere $cfg_rv->{n} is the number of lines (including empty ones) after the header.\n\n";
	     $M->logData('WARNING', $warnings);
	     if($M->getCla->{'commit'}){print STDERR "WARNING: $RV\n";}
	     return; 
	 }
     }

     my $SPOT_FAM_VIEW=join('::', 'GUS', 'Model', 'RAD3', $cr_subclass_view);
     my $spot_family = $SPOT_FAM_VIEW->new($spot_fam_hash);
# check whether this row is already in the database
# if it is, get its primary key
     if ($spot_family->retrieveFromDB(\@attributesToNotRetrieve)) {
	 $RV="Data line no. $cfg_rv->{n}\tAlready existing an entry in CompositeElementResultImp\tNo insert";
	 if(! $M->getCla->{noWarning}){
	     $M->logData('Result', $RV);
	 }
	 if($M->getCla->{'commit'} && !$M->getCla->{noWarning} ){print STDERR "RESULT: $RV\n";}
	 
	 if(defined $cfg_rv->{channel} && $cfg_rv->{channel} eq 'channel2'){
	     $cfg_rv->{spot_fam_rs_pk2} = $spot_family->getId();
	 }
	 else{
	     $cfg_rv->{spot_fam_rs_pk} = $spot_family->getId();
	 }

     }
     else{
	 $spot_family->submit();
# need to rewrite this part
#
	 if($spot_family->getId()){
	     $cfg_rv->{num_spot_family}++;
	     if(defined $cfg_rv->{channel} && $cfg_rv->{channel} eq 'channel2'){
		 $cfg_rv->{spot_fam_rs_pk2} = $spot_family->getId();
	     }
	     else{
		 $cfg_rv->{spot_fam_rs_pk} = $spot_family->getId();
	     }
	 }
	 else{
	     $RV="Data line no. $cfg_rv->{n}\t cann't be inserted into CompositeElementResultImp\tSkip this one";
	     $M->logData('Result', $RV);
	     if($M->getCla->{'commit'}){print STDERR "RESULT: $RV\n";}
	 }
     }
}

sub updateSpotResult{
    my $M=shift;    
    my (@arr)=@_;
    my $pos=$cfg_rv->{position};
    my $spot_hash;
    my $n=$cfg_rv->{n};
    my $warnings;
    my $RV;
    my $er_subclass_view = $M->getCla->{er_subclass_view};
    my @spot_attr=$M->getAttrArray("GUS::Model::RAD3::$er_subclass_view");
    my $spot_attr_hashref=$M->getAttrHashRef("GUS::Model::RAD3::$er_subclass_view");
    my @attributesToNotRetrieve = ('modification_date', 'row_alg_invocation_id');     
    $spot_hash->{'element_id'} = $cfg_rv->{spot_id};
    $spot_hash->{'subclass_view'} = $er_subclass_view;

    if(defined $cfg_rv->{channel} && $cfg_rv->{channel} eq 'channel2'){
	$spot_hash->{'quantification_id'} = $M->getCla->{rel_quantification_id};
	if(defined $cfg_rv->{spot_fam_rs_pk2}){
	    $spot_hash->{'composite_element_result_id'} = $cfg_rv->{spot_fam_rs_pk2} ;
	}
    }
    else{
	$spot_hash->{'quantification_id'} = $M->getCla->{quantification_id};
	if(defined $cfg_rv->{spot_fam_rs_pk}){
	    $spot_hash->{'composite_element_result_id'} = $cfg_rv->{spot_fam_rs_pk} ;
	}
    }
 
    for (my $i=0; $i<@spot_attr; $i++) {
	my $attr;
	if(defined $cfg_rv->{channel}){
    	    $attr="channel1.$spot_attr[$i]" if $cfg_rv->{channel} eq 'channel1';
    	    $attr="channel2.$spot_attr[$i]" if $cfg_rv->{channel} eq 'channel2';
	}
	else{
	    $attr=$spot_attr[$i];
	}
	if ( defined $pos->{$attr} &&  $arr[$pos->{$attr}] ne "") {
	    $spot_hash->{$spot_attr[$i]} = $arr[$pos->{$attr}];
	}

	if ($spot_attr_hashref->{$spot_attr[$i]}=~ /^Not Nullable$/ && !defined $spot_hash->{$spot_attr[$i]}) {
	    $cfg_rv->{warnings} = "Data file line $n is missing attribute ElementImp.$spot_attr[$i], which is mandatory\nData from data line $n for $cfg_rv->{channel} were not loaded.\nHere $n is the number of lines (including empty ones) after the header.\n\n";
	    $M->logData('Warning', $cfg_rv->{warnings});
	    if($M->getCla->{'commit'}){print STDERR "Warning: $RV\n";}
	    return;
	 }
    }

   my $SPOT_VIEW=join('::', 'GUS', 'Model','RAD3', $er_subclass_view);
   my $spotResult = $SPOT_VIEW->new($spot_hash);
   my $spot_result_id;
   my $spot_result_pk;

#   if (defined($spot_fam_pk)) {
#       $spotResult->setCompositeElementResultId($spot_fam_pk);
#   }
# check whether this row is already in the database
    if ($spotResult->retrieveFromDB(\@attributesToNotRetrieve)) {
	$spot_result_pk=$spotResult->getId();
	$RV="Data line no. $n\tAlready existing an entry in ElementImp\tNo insert";
	$M->logData('Result', $RV);
	if($M->getCla->{'commit'}){print STDERR "RESULT: $RV\n";}
    }
    else{
	$spotResult->submit();	  
	if($spotResult->getId()){
	    $cfg_rv->{num_inserts}++;
	}
	else{
	    $RV="Data line no. $cfg_rv->{n}\t cann't be inserted into ElementResultImp\tSkip this one";
	    $M->logData('Result', $RV);
	    if($M->getCla->{'commit'}){print STDERR "RESULT: $RV\n";}

	}
    } 
}

# Run a query and return the results as an arrayref
# of hashrefs.
#
sub doSelect {
    my $M=shift;
    my($query) = @_;
    my $result = [];
                               
#    print STDERR "SpottedArrayLoader.pm: $query\n";
                             
    my $dbh = $M->getCla->getQueryHandle();
    my $sth = $dbh->prepare($query);
    $sth->execute();
        
    while (my $row = $sth->fetchrow_hashref('NAME_lc')) {
        my %copy = %$row;
        push(@$result, \%copy);
    }
    $sth->finish();

    return $result;
}

1;


__END__

=head1 NAME

GUS::RAD::Plugin::ArrayResultLoader

=head1 SYNOPSIS

*For help

ga GUS::RAD::Plugin::ArrayResultLoader B<[options]> B<--help>

*For loading data into ElementResultImp table

ga GUS::RAD::Plugin::ArrayResultLoader B<[options]> B<--data_file> data_file B<--array_id> array_id B<--e_subclass_view> e_subclass_view B<--quantification_id> quantification_id B<--er_subclass_view> er_subclass_view B<--debug> > logfile

*For loading data into CompositeElementResultImp table

ga GUS::RAD::Plugin::ArrayResultLoader B<[options]> B<--data_file> data_file B<--array_id> array_id B<--e_subclass_view> e_subclass_view B<--quantification_id> quantification_id B<--cr_subclass_view> cr_subclass_view B<--commit> > logfile 

*For loading data into CompositeElementResultImp table such as loading Affymetrix Chp data

ga  GUS::RAD::Plugin::ArrayResultLoader B<[options]> B<--data_file> data_file B<--array_id> array_id B<--c_subclass_view> c_subclass_view  B<--quantification_id> quantification_id B<--cr_subclass_view> cr_subclass_view B<--debug> > logfile


*For loading data into ElementResultImp and CompositeElementResultImp table

ga  GUS::RAD::Plugin::ArrayResultLoader B<[options]> B<--data_file> data_file B<--array_id> array_id B<--e_subclass_view> e_subclass_view  B<--quantification_id> quantification_id B<--er_subclass_view> er_subclass_view B<--cr_subclass_view> cr_subclass_view B<--rel_quantification_id> rel_quantification_id B<--debug> > logfile

*For loading two-channel data into ElementResultImp and CompositeElementResultImp table

ga  GUS::RAD::Plugin::ArrayResultLoader B<[options]> B<--data_file> data_file B<--array_id> array_id B<--e_subclass_view> e_subclass_view  B<--quantification_id> quantification_id B<--er_subclass_view> er_subclass_view B<--cr_subclass_view> cr_subclass_view B<--rel_quantification_id> rel_quantification_id B<--commit> > logfile

=head1 DESCRIPTION

This is a plug-in that loads array  (spotted microarray and oligonucleotide array) result data into CompositeElementResultImp, ElementResultImp, set the value of result_table_id in Quantification table and if applicable, link the chp quantification_id with cel quantification_id in relatedQuantification table. 

=head1 ARGUMENTS

B<--data_file> F<data_file>  [require the absolute pathname]

    The file contains the values for attributes in ElementResultImp, CompositeResultElementImp.

B<--array_id> I<array_id>  [require must be one of array_id in RAD3::Array table]

    set value of the ElementImp.array_id in order to determine the element_id and composite_element_id

B<--quantification_id> I<quantification_id>  [require must must be one of quantification_id in RAD3::Quantification table]

    set value for the ElementImp.quantification_id and CompositeElementImp.quantification_id




=head1 OPTIONS

B<--e_subclass_view> I<e_subclass_view>  [optional, must be one of view name for  RAD3::ElementImp table]
    being used for determining the element_id and composite_element_id

B<--c_subclass_view> I<c_subclass_view>  [optional, must be one of view name for  RAD3::CompositeElementImp table]
    being used for determining the composite_element_id if e_subclass_view not set

B<--er_subclass_view> I<er_subclass_view>  [optional, must be one of view name for  RAD3::ElementResultImp table]
    being used for updating ElementResultImp table, if set, will update ElementResultImp table

B<--cr_subclass_view> I<cr_subclass_view>  [optional, must be one of view name for  RAD3::CompositeElementResultImp table]
    being used for updating CompositeElementResultImp table, if set, will update CompositeElementResultImp table

B<--rel_quantification_id> I<rel_quantification_id>  [optional, must be one of quantification_id in RAD3::Quantification table]
    must be provided when associated channel data is loaded. set value of  the ElementImp.quantification_id and CompositeElementImp.quantification_id for the associated channel

B<--cel_quantification_id> I<cel_quantification_id>  [optional, must be one of quantification_id in RAD3::Quantification table]
    can be provided when associated chp data is loaded. set value of  the cel quantification_id and chp quantification_id in relatedQuantification table

B<--posOption> I<posOption>  [optional, default is 1, can be 1, 2 or 3]
    if 1, then using "name" as probe set identifier; if 2, then using "external_database_release_id" and "source_id" as probe set identifier; if 3, then using "name", "external_database_release_id" and "source_id" as probe set identifier.

B<--debug>
    Debugging output.

B<--help>
    Get usage; same as usage.

B<--verbose>
    Lots of output.

B<--commit>   
    Commit the data to database.

B<--testnumber> I<NUM>   
    Number of iterations for testing (B<in non-commit mode only>).  

B<--restart> I<NUM>   
    data file line number to start loading data from (start counting after the header)

B<--user> I<STRING>
    The user name, used to set value for row_user_id. The user must already be in Core::UserInfo table. [Default: from $HOME/.gus.properties file]

B<--group> I<STRING>
    The group name, used to set value for row_group_id. The group must already be in Core::GroupInfo table. [Default: from $HOME/.gus.properties file]

B<--project> I<STRING>
    The project name, used to set value for row_project_id. The project must already be in Core::ProjectInfo table. [Default: from $HOME/.gus.properties file]

=head1 NOTES

Before you can run this plug-in you need to create the Perl objects for the views you will be loading, should these objects not exist yet. Based on the "build" system, this will involve two steps. First, check out the RAD, CBIL, GUS and Install modules from the cvs repository; secondly, build the GUS_HOME which the Perl objects reside in.

The plug-in outputs a print statement to STDOUT (for possible redirection to a log file) which lists the number of data file lines read (counting empty lines, but not counting the header and the lines preceding it in the data file) and any warning statement(s) regarding data lines which have not been loaded into RAD3.

Make sure that the F<.gus.properties> file of the user contains the correct login name [RAD3rw]. Also, if the group and project differ from the default values in F<.gus.properties>, I<please specify the proper group and project name on the command line using --group and --project options respectively>. 

=head2 F<data_file>

The data file should be in tab-delimited text format with one header row and a row for each element. All rows should contain the same number of tabs/fields.

* The header contains a list of attributes, which can be divided into two categories. One is position attributes which is used to identify the location of each element in array or compositeElement identifier such as probe set name. The other is view attributes which is defined in the view of ElementResultImp and CompositeElementResultImp.

* All attributes in the header should be small case. View attributes should be the same as defined in the views of interest.

* Every element for which the position attributes are available should have these stored in the database in order to determine the element_id and/or composite_element_id.

* Depending on array platform, the position attributes are different. If  the command line argument "e_subclass_view" is set to "Spot", then position attributes will be array_row, array_column, grid_row, grid_column, sub_row and sub_column. If  the command line argument "e_subclass_view" is set to "ShortOligo", then position attributes will be x_position and y_position. You will need to have these columns in the data file for each row.

* If you only load the compositeElementResult for affymetrix data, you have option to use probe set identifier to set the composite_element_id without using the position attributes of x_position and y_position. First, set command line argument "c_subclass_view" to "ShortOligoFamily", second, use the "posOption" to set the probe set identifier, its default is 1, which uses "name" as the probe set identifier; 2 means using "external_database_release_id"and "source_id" as the probe set identifier; 3 means using "external_database_release_id", "source_id" and "name" as the probe set identifier.

* If the data file contains two-channel array data, then you can use "channel1.attributeName" and "channel2.attributeName" to denote each channel data.

* Empty lines in the data files are ignored. All quotes within a data line are removed by the plug-in.

* If any values in data file larger than the maximum value or smaller than minimum value that corresponding field in database allows, then the plugin will reset the value to maximum or minimum value of that field.

Please double-check that your data file has no inconsistencies before loading the data. If a column in your data file contains information which should be separated and stored into different table/view attributes, you will need to re-parse your file and separate this information into different columns before running the plug-in. Similarly, if information from different columns of your data file refers to one table/view attribute, you will need to re-parse your data file and merge this information into one column.

=head2 F<e_subclass_view>

Legal values for this argument must be either "Spot" or "ShortOligo" or "SAGETagMapping".

=head2 F<c_subclass_view>

Legal values for this argument must be either "SpotFamily" or "ShortOligoFamily" or "SAGETag". 

=head2 F<er_subclass_view>

Legal values for "er_subclass_view" must be "ArrayVisionElementResult", "GenePixElementResult", "SpotElementResult", "ScanalyzeElementResult", "AgilentElementResult", "AffymetrixCEL". 

=head2 F<cr_subclass_view>

Legal values for "cr_subclass_view" must be "AffymetrixMAS4", "AffymetrixMAS5", "SAGETagResult", "MOIDResult".

=head2 I<restart>

If you need to restart loading from your data file from a specific line (e.g. due to previous interruptions in data loading), give the line number of this line in the --restart option. You should start your line count from the line after the header line and include any empty lines. 

=head2 I<testnumber>
 
If you are testing the plug-in and want only to test n lines from your data file, use the --testnumber option. If you set this to n, it will test the plug-in on the first n data lines (counting empty lines) after the header or after --restart, if this is set. 

=head1 AUTHOR

Written by Junmin Liu.

=head1 COPYRIGHT

Copyright Trustees of University of Pennsylvania 2003.


