# ----------------------------------------------------------
# ControlLoader.pm
#
# Loads data into Control,
#  
# Mandatory inputs are array_id, (e_subclass_view || c_subclass_view) and a data file.
# 
# Created: Friday Aug. 15 12:00:00 EST 2003
#
# junmin liu
#
# Last Modified $Date$
# 
# $Revision$ $Date$ $Author$
# ----------------------------------------------------------
package GUS::RAD::Plugin::ControlLoader;
@ISA = qw( GUS::PluginMgr::Plugin );

use strict;
use IO::File;

use GUS::Model::RAD3::Array;
use GUS::Model::RAD3::Control;
use GUS::Model::RAD3::OntologyEntry;

sub new {
  my $Class = shift;
  my $self = {};
  bless($self,$Class); # configuration object...

# call required inherited initialization methods
  my $usage = 'Loads data into Control table in RAD3 database.';

# modify the following line to add a new view for ElementImp table
  my @eSubclassViewList=[qw (ShortOligo Spot SAGETagMapping)];  

# modify the following line to add a new view for CompositeElementImp table
  my @cSubclassViewList=[qw (ShortOligoFamily SpotFamily SAGETag)];

# this is for setting the global array $positionList and require the view for CompositeElementImp.  
  my @posOption=(1, 2, 3);

# command line options  
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

  if($M->getCla->{c_subclass_view} eq 'SpotFamily'){
      eval "require GUS::Model::RAD3::SpotFamily";
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
  

# self-defined subroutine, check the headers of data file
#
  my $fh=new IO::File;
  my $fileName=$M->getCla->{'data_file'};
    unless ($fh->open("<$fileName")) {
	$M->logData('ERROR', "Cannot open data file $fileName for reading.");
	if($M->getCla->{'commit'}){print STDERR "ERROR: Cannot open data file $fileName for reading.\n";}
	return;
  }
  $M->parseHeader($fh);
  return unless $M->getOk();

# self-defined subroutine, check the headers in data file if it provide the 
# required attributes
#  
  $M->checkHeader(); 
  return unless $M->getOk();

# self-defined subroutine, load the data into control table
#
  $RV = $M->loadData($fh);
  $fh->close();

  return $RV;
}

sub checkArgs {
    my $M = shift;
    my $RV="";
    $M->setOk(1);
    my $array_id=$M->getCla->{'array_id'};
    my $query;
    my $dbh = $M->getSelfInv->getQueryHandle();
    my $sth;

# one of the e_subclass_view or c_subclass_view must be provided
    if(!defined $M->getCla->{e_subclass_view} && !defined $M->getCla->{c_subclass_view}){
	$RV = join(' ','a --e_subclass_view <view name for ElementImp>', $M->getCla->{e_subclass_view},'or --c_subclass_view <view name for CompositeElementImp> must be provided at the commandline', $M->getCla->{c_subclass_view});
	$M->setOk(0);
	$M->logData('ERROR', $RV);
	if($M->getCla->{'commit'}){print STDERR "ERROR: $RV\n";}
	return;
    }

# check that the given array_id is a valid one
    $M->checkId('RAD3', 'Array', 'array_id', $M->getCla->{'array_id'}, 'array_id');
    return unless $M->getOk();

#check if given array_id and e_subclass_view matched
    if(defined $M->getCla->{e_subclass_view}){
	my $e_table=$M->getCla->{e_subclass_view};
	$query="select e.array_id from rad3.$e_table e where e.array_id=$array_id";
	$sth = $dbh->prepare($query);
	$sth->execute();
	my ($id) = $sth->fetchrow_array();
	$sth->finish();
	if (!defined $id) {
	    $RV="array_id $array_id is not existing in element table $e_table.";
	    $M->setOk(0);
	    $M->logData('ERROR', $RV);
	    if($M->getCla->{'commit'}){print STDERR "ERROR: $RV\n";}
	    return;
	}
    }

#check if given array_id and ce_subclass_view matched
	if(defined $M->getCla->{ce_subclass_view}){
	    my $ce_table=$M->getCla->{e_subclass_view};
	    $query="select ce.array_id from rad3.$ce_table ce where ce.array_id=$array_id";
	    $sth = $dbh->prepare($query);
	    $sth->execute();
	    my ($id) = $sth->fetchrow_array();
	    $sth->finish();
	    if (!defined $id) {
		$RV="array_id $array_id is not in composite element table $ce_table.";
		$M->setOk(0);
		$M->logData('ERROR', $RV);
		if($M->getCla->{'commit'}){print STDERR "ERROR: $RV\n";}
		return;
	    }
	}

    $M->logData('RESULT', 'finished checking command line arguments');
    if($M->getCla->{'commit'}){print STDERR "RESULT: finished checking command line arguments\n";}
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

    foreach my $att(@$lref){
	my $cname=$att->{'col'};
# don't load the primary key, foreign keys and @common_attr which will set automatically to not nullable
# so we don't put them into attr_hash

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

  for (my $i=0; $i<@arr; $i++) {
  
    $arr[$i] =~ s/^\s+|\s+$//g;
    $arr[$i] =~ s/\"|\'//g;
    if ($headers{$arr[$i]}) {
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
  if($M->getCla->{'commit'}){print STDERR "Result:  finish parsing the headers of array data file\n";}
}

sub checkHeader{
    my $M=shift; 
    $M ->setOk(1);
    my $RV; 
    my $e_table;
    my $c_table;
    if(defined $M->getCla->{e_subclass_view}){
	$e_table=$M->getCla->{e_subclass_view};
    }
    if(defined $M->getCla->{c_subclass_view}){
	$c_table=$M->getCla->{c_subclass_view};
    }
    if($M->getCla->{c_subclass_view} eq 'SpotFamily'){
	$M ->setOk(0);
	my @spotfam_attr=$M->getAttrArray("GUS::Model::RAD3::SpotFamily");
	my @common_attr=('composite_element_id', 'subclass_view', 'parent_id', 'array_id', 'modification_date', 'user_read', 'user_write', 'group_read', 'group_write', 'other_read', 'other_write', 'row_user_id','row_group_id', 'row_project_id', 'row_alg_invocation_id');
	foreach my $att(@spotfam_attr){
	    next if( (grep(/^$att$/, @common_attr)) );
	    if(defined $cfg_rv->{'position'}->{$att}){
		$M ->setOk(1);
		last;
	    }
	}
	if(! $M->getOk){
	    $RV = "Missing header in the data file which is required to define the spotfamily";
	    $M ->logData("ERROR", $RV);
	    if($M->getCla->{'commit'}){print STDERR "ERROR: $RV\n";}
	}
    }
    else{
	foreach my $arr (@positionList){
	    if (! defined $cfg_rv->{'position'}->{$arr}){
		$RV = "Missing header $arr in the data file which is required to define one element or composite element";
		$M ->logData("ERROR", $RV);
		$M ->setOk(0);
		if($M->getCla->{'commit'}){print STDERR "ERROR: $RV\n";}
		return;
	    }
	}
    }
    $M->logData('Result', 'finish checking the headers of array data file');
}

sub loadData{
   my $M=shift;
   my ($fh)=@_;
   $M->setOk(1);
   my $RV;

   $M->setOk(1);
   $cfg_rv->{num_inserts} = 0; # holds current number of rows inserted into control table
   $cfg_rv->{warnings} = "";  
   my $line;
   $cfg_rv->{n} = 0; # holds the current number of rows being read 

# set all parameters
   my $array_id = $M->getCla->{array_id};
   my $subclass_view;

   if(defined $M->getCla->{e_subclass_view}){
       $subclass_view = $M->getCla->{e_subclass_view};
   }
   elsif(defined $M->getCla->{c_subclass_view}){
       $subclass_view = $M->getCla->{c_subclass_view};
   }

   $cfg_rv->{table_id}=getTable_Id($subclass_view);
   return unless $M->getOk();

   while ($line = <$fh>) {
     $cfg_rv->{n}++;
     if (($cfg_rv->{n})%200==0) {
	 $RV="Read $cfg_rv->{n} datalines including empty lines";
	 $M->logData('Result', $RV);
	 if($M->getCla->{'commit'}){
	     $RV = "Processed $cfg_rv->{n} dataline including empty line, Inserted $cfg_rv->{num_inserts} rows into control table "; 
	     print STDERR "RESULT: $RV\n";
	 }
     }
# skip number of line as defined by user
     if (defined $M->getCla->{'restart'} && $cfg_rv->{n}<$M->getCla->{'restart'}) {
	 next;
     }
# skip empty lines if any
     if ($line =~ /^\s*$/) {
	 next;
     }
# for debug purpose     
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
	 $M->logData('Error', $cfg_rv->{warnings});
	 $M->setOk(0);
	 if($M->getCla->{'commit'}){print STDERR "Error: $RV\n";}
	 last; #exit the while loop
     }

# get rid of preceding and trailing spaces and of quotes
     for (my $i=0; $i<@arr; $i++) {
	 $arr[$i] =~ s/^\s+|\s+$//g;
	 $arr[$i] =~ s/\"|\'//g;
     }

     $cfg_rv->{skip_line} = 0; # when set to 1 the current data line is skipped

     my $pos=$cfg_rv->{'position'};
     
     my ($spot_id, $spot_family_id);

# get the element_id for the row
     $cfg_rv->{row_id}=getRow_Id($subclass_view, @arr);
     if($cfg_rv->{skip_line}){
	 next; # skip this row
     }
# insert a row into control table
     my $row_id=$cfg_rv->{row_id};
     my $table_id=$cfg_rv->{table_id};
     $M->updateControl($tabe_id, $row_id, @arr);
 
     my $numOfLine=$cfg_rv->{n};

# reach the max 9000 objects, do clean up, but to be safe use 9000 instead
     if( ($numOfLine*5) % 9000 == 0 ) {$M->undefPointerCache();}

 }#end of while loop

#   $dbh->disconnect();
   $RV="Total datalines read (after header) including empty lines: $cfg_rv->{n}.";
   if($M->getCla->{'commit'}){print STDERR "RESULT: $RV\n";}
   
   $M->logData('Result', $RV);
   my $total_insert;
  
   $total_insert=$cfg_rv->{num_inserts};
  
   $RV="Number of lines which have been inserted into control table in database (after header): $total_insert.";
   $M->logData('Result', $RV);
   if($M->getCla->{'commit'}){print STDERR "RESULT: $RV\n";}
     
   $RV = "Processed $cfg_rv->{n} dataline, Inserted $cfg_rv->{num_inserts} entries in control table."; 
   return $RV;
   
}

sub getTable_Id{
    my $M = shift;
    my ($table_name)=@_;
    $M->setOk(1);
    $query="select t.table_id from core.tableinfo t where t.name='$table_name'";
    $sth = $dbh->prepare($query);
    $sth->execute();
    my ($id) = $sth->fetchrow_array();
    $sth->finish();
    if (defined $id) {
	return $id;
    }
    else{
	$cfg_rv->{warnings} = "Cann't retrieve table_id for subclass view $table_name";
	$M->logData('Error', $cfg_rv->{warnings});
	if($M->getCla->{'commit'}){print STDERR "Error: $RV\n";}
	$M->setOk(0);
    }
}

sub getRow_Id{
 my $M = shift;
 my ($subclass_view, @arr)=@_;

 my @attributesToNotRetrieve = ('modification_date', 'row_alg_invocation_id');     
  
# for querying ElementImp or CompositeElementImp table to set the element_id or composite_element_id
   my ($subClass);

   if(defined $subclass_view){
       if($subclass_view=~ /^ShortOligo$/){
	   $subClass="GUS::Model::RAD3::ShortOligo";
       }
       elsif($subclass_view=~ /^Spot$/){
	   $subClass="GUS::Model::RAD3::Spot"; 
       }
       else{
	   $subClass="GUS::Model::RAD3::SAGETagMapping"; 
       }
       if($subclass_view=~ /^ShortOligoFamily$/){
	   $subClass="GUS::Model::RAD3::ShortOligoFamily";
       }
       elsif($subclass_view=~ /^SpotFamily$/){
	   $subClass="GUS::Model::RAD3::SpotFamily"; 
       }
       else{
	   $subClass="GUS::Model::RAD3::SAGETag"; 
       }
   }

 if(defined $subclass_view){
     my $sub_hash;
     my $sub_class;
     $sub_hash->{'array_id'} = $M->getCla->{array_id};
     if($subclass_view=~ /^SpotFamily$/){
	 my @spotfam_attr=$M->getAttrArray("GUS::Model::RAD3::SpotFamily");
	 my @common_attr=('composite_element_id', 'subclass_view', 'parent_id', 'array_id', 'modification_date', 'user_read', 'user_write', 'group_read', 'group_write', 'other_read', 'other_write', 'row_user_id','row_group_id', 'row_project_id', 'row_alg_invocation_id');
	 foreach my $att(@spotfam_attr){
	     next if( (grep(/^$att$/, @common_attr)) );
	     if(defined $arr[$pos->{$att}] ){
		 $sub_hash->{$att} = $arr[$pos->{$att}]; 
	     }
	 }
     }
     else{
	 foreach my $item(@positionList){
	     if(defined $arr[$pos->{$item}]){
		 $sub_hash->{$item} = $arr[$pos->{$item}]; 
	     }
	     else{
		 $cfg_rv->{warnings} = "Data file line $cfg_rv->{n} is missing attribute ElementImp.$item, which is mandatory.\nData from this data line were not loaded.\nHere $cfg_rv->{n} is the number of lines (including empty ones) after the header.\n\n";
		 $M->logData('Warning', $cfg_rv->{warnings});
		 if($M->getCla->{'commit'}){print STDERR "Warning: $RV\n";}
		 $cfg_rv->{skip_line} = 1;
		 last; # exit the foreach loop
	     }
	 }
     }

     $sub_class = $subClass->new($sub_hash);
     if ($sub_class->retrieveFromDB(\@attributesToNotRetrieve)) {
	 $cfg_rv->{row_id} = $sub_class->getId();
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
     }
 }
}
sub updateControl{
    my $M = shift;
    my ($table_id, $row_id, @arr)=@_;

    my $pos=$cfg_rv->{position};
    my $control_hash;
    my $warnings;
    my $RV;
    my @attributesToNotRetrieve = ('modification_date', 'row_alg_invocation_id');     
    $control_hash->{'table_id'} = $table_id;
    $control_hash->{'row_id'} = $row_id;
  
    my @control_attr=$M->getAttrArray("GUS::Model::RAD3::Control");
    my $control_attr_hashref=$M->getAttrHashRef("GUS::Model::RAD3::Control");
    for (my $i=0; $i<@control_attr; $i++) {
	my $attr;
	
	$attr="control.$control_attr[$i]";
	
	if ( defined $pos->{$attr} && $arr[$pos->{$attr}] ne "") {
	    $control_hash->{$control_attr[$i]} = $arr[$pos->{$attr}];
	}
	 if ( ($control_hashref->{$control_attr[$i]} =~ /^Not Nullable$/)  && !defined $control_hash->{$control_attr[$i]}) {
	     $warnings = "Data file line $cfg_rv->{n} is missing attribute Control.$control_attr[$i], which is mandatory.\nData from this data line were not loaded.\nHere $cfg_rv->{n} is the number of lines (including empty ones) after the header.\n\n";
	     $M->logData('Error', $warnings);
	     if($M->getCla->{'commit'}){print STDERR "Error: $RV\n";}
	     return; 
	 }
     }

     my $CONTROL_VIEW=join('::', 'GUS', 'Model', 'RAD3', 'Control');
     my $control = $CONTROL_VIEW->new($control_hash);
# check whether this row is already in the database
# if it is, get its primary key
     if ($control->retrieveFromDB(\@attributesToNotRetrieve)) {
	 $RV="Data line no. $cfg_rv->{n}\tAlready existing an entry in Control\tNo insert";
	 if(! $M->getCla->{noWarning}){
	     $M->logData('Warning', $RV);
	 }
	 if($M->getCla->{'commit'} && !$M->getCla->{noWarning} ){
	     print STDERR "Warning: $RV\n";
	 }
     }
     else{
	 $control->submit();
# need to rewrite this part
#
	 if(!$control->getId()){
	     $RV="Data line no. $cfg_rv->{n}\t cann't be inserted into Control table\tSkip this one";
	     $M->logData('Warning', $RV);
	     if($M->getCla->{'commit'}){print STDERR "Warning: $RV\n";}
	 }
	 else{
	     $cfg_rv->{num_inserts}++;
	 }
     }
}

1;


__END__

=head1 NAME

GUS::RAD::Plugin::ControlLoader

=head1 SYNOPSIS

*For help

ga GUS::RAD::Plugin::ControlLoader B<[options]> B<--help>

*For loading data into Control table

ga GUS::RAD::Plugin::ControlLoader B<[options]> B<--data_file> data_file B<--array_id> array_id B<--e_subclass_view> e_subclass_view B<--debug> > logfile

*For loading data into Control table

ga GUS::RAD::Plugin::ControlLoader B<[options]> B<--data_file> data_file B<--array_id> array_id B<--c_subclass_view> c_subclass_view B<--commit> > logfile 

=head1 DESCRIPTION

This is a plug-in that loads control information (spotted microarray and oligonucleotide array) data into control table. 

=head1 ARGUMENTS

B<--data_file> F<data_file>  [require the absolute pathname]

    The file contains the values for attributes in Control.

B<--array_id> I<array_id>  [require must be one of array_id in RAD3::Array table]

    set value of the ElementImp.array_id in order to determine the element_id and composite_element_id


=head1 OPTIONS

B<--e_subclass_view> I<e_subclass_view>  [optional, must be one of view name for  RAD3::ElementImp table]
    being used for determining the element_id and composite_element_id

B<--c_subclass_view> I<c_subclass_view>  [optional, must be one of view name for  RAD3::CompositeElementImp table]
    being used for determining the composite_element_id if e_subclass_view not set

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

=head2 I<restart>

If you need to restart loading from your data file from a specific line (e.g. due to previous interruptions in data loading), give the line number of this line in the --restart option. You should start your line count from the line after the header line and include any empty lines. 

=head2 I<testnumber>

If you are testing the plug-in and want only to test n lines from your data file, use the --testnumber option. If you set this to n, it will test the plug-in on the first n data lines (counting empty lines) after the header or after --restart, if this is set. 

=head1 AUTHOR

Written by Junmin Liu.

=head1 COPYRIGHT

Copyright Trustees of University of Pennsylvania 2003.
