# ----------------------------------------------------------
# ArrayLoader.pm#
# Loads data into Array, ArrayAnnotation, 
# ElementImp, CompositeElementImp, 
# ElementAnnotation, CompositeAnnotation 
# 
# Mandatory inputs are platform_type_id, a configuration file and a data file.
# 
# Optional inputs are substrate_type_id, manufacturer_id,
#
# Created: Tuesday June 11 12:00:00 EST 2002
#
# junmin liu
#
# Modified
#   Monday Sept. 13 2002
#
#   Thursday Jan. 23 2003
#     made changes for new build system
# 
# ----------------------------------------------------------
package GUS::RAD::Plugin::ArrayLoader;
@ISA = qw( GUS::PluginMgr::Plugin );



use strict;
use IO::File;


use GUS::Model::RAD3::Array;
use GUS::Model::SRes::Contact;
use GUS::Model::RAD3::OntologyEntry;
use GUS::Model::RAD3::ArrayAnnotation;
use GUS::Model::RAD3::ElementAnnotation;
use GUS::Model::RAD3::CompositeElementAnnotation;


sub new {
  my $class = shift;
  my $self = {};
  bless ($self, $class);
#  my $m = bless {}, $Class; # configuration object...

#call required inherited initialization methods
#  $m->setUsage('Loads Array Information Data into RAD3 database.');
#  $m->setVersion('1.2');
#  $m->setRequiredDbVersion({SRes => '3',RAD3 => '3'} );
#  $m->setDescription('Loads data into Array, ArrayAnnotation, ElementImp, CompositeElementImp, ElementAnnotation, CompositeAnnotation tables in RAD3 database.');
  my $usage = 'Loads data into Array, ArrayAnnotation, ElementImp, CompositeElementImp, ElementAnnotation, CompositeAnnotation tables in RAD3 database.';



  my $easycsp = [
    {
      o => 'data_file',
      t => 'string',
      r => 1,
      h => 'mandatory, name of the data file (give full path)',
    },    
    {
      o => 'cfg_file',
      t => 'string',
      r => 1,
      h => 'mandatory, name of the configuration file',
    },
    {
      o => 'platform_type_id',
      t => 'int',
      r => 1,
      h => 'mandatory, RAD3 platform type id, the entry in ontologyentry table',
    },
    {
      o => 'substrate_type_id',
      t => 'int',
      h => 'optional, RAD3 array substrate type id, the entry in ontologyentry table ',
    },
    {
      o => 'manufacturer_id',
      t => 'int',
      r => 1,
      h => 'mandatory, RAD3 array manufacturer id, the entry in GUS::Model::SRes::Contact table ',
    },		
    {
      o => 'protocol_id',
      t => 'int',
      h => 'optional, RAD3 array protocol id, the entry in protocol table ',
    }, 
   {
      o => 'noWarning',
      t => 'boolean',
      h => 'if specified, generate no warning messages',
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

  $self->initialize({requiredDbVersion => {RAD3 => '3', SRes => '3'},
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
  $M->readCfg();
  return unless $M->getOk();

# require the elementimp and compositeelementimp view objects at running time  
  eval "require GUS::Model::RAD3::$cfg_rv->{'mapping'}->{'CompositeElementImp.subclass_view'}";
  eval "require GUS::Model::RAD3::$cfg_rv->{'mapping'}->{'ElementImp.subclass_view'}";

# self-defined subroutine, check the configuration file if it provide the 
# value or header for non-nullable attributes
#  
  $M->checkCfg(); 
  return unless $M->getOk();

# self-defined subroutine, update the Array table, assuming Array.name is provided in configuration file
#
  $M->workOnArray();
  return unless $M->getOk();

# self-defined subroutine, update the ArrayAnnotation table
#
  if(defined $cfg_rv->{'arrayannotation_index'}){
      $M->workOnArrayAnnotation();
      return unless $M->getOk();
  }

# self-defined subroutine, check the headers of data file if it provide the 
# header matching with them provide in configuration file
#
  my $fh=new IO::File;
  my $fileName=$M->getCla->{'data_file'};
    unless ($fh->open("<$fileName")) {
	$M->logData('ERROR', "Cannot open file $fileName for reading.");
	if($M->getCla->{'commit'}){print STDERR "ERROR: $RV\n";}
	return;
  }
   $M->parseHeader($fh);
   return unless $M->getOk();
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
  if (!defined $M->getCla->{'data_file'}) {
    $RV = join(' ','a --data_file <datafilename> must be on the commandline', $M->getCla->{'data_file'}); 
    $M->setOk(0);
    $M->logData('ERROR', $RV);
    if($M->getCla->{'commit'}){print STDERR "ERROR: $RV\n";}
    return;
  }

  if (!defined $M->getCla->{'cfg_file'}) {
    $RV = join(' ','a --cfg_file <cfgfilename> must be on the commandline', $M->getCla->{'data_file'});
    $M->setOk(0);
    $M->logData('ERROR', $RV);
    if($M->getCla->{'commit'}){print STDERR "ERROR: $RV\n";}
    return;
  }

  if (!defined $M->getCla->{'platform_type_id'}) {
      $RV = join(' ','a --platform_type_id <platform type id> must be on the commandline', $M->getCla->{'platform_type_id'});
      $M->setOk(0);
      $M->logData('ERROR', $RV);
      if($M->getCla->{'commit'}){print STDERR "ERROR: $RV\n";}
      return;
  }
  else{
# check that the given platform_type_id is a valid one
      $M->checkId('RAD3', 'OntologyEntry', 'ontology_entry_id', $M->getCla->{'platform_type_id'}, 'platform_type_id');
      return unless $M->getOk();
  }

  if (defined $M->getCla->{'substrate_type_id'}){
      $M->checkId('RAD3', 'OntologyEntry', 'ontology_entry_id', $M->getCla->{'substrate_type_id'}, 'substrate_type_id');
      return unless $M->getOk(); 	  
  }

  if (!defined $M->getCla->{'manufacturer_id'}) {
      $RV = join(' ','a --manufacturer_id <manufacturer id> must be on the commandline', $M->getCla->{'manufacturer_id'});
      $M->setOk(0);
      $M->logData('ERROR', $RV);
      if($M->getCla->{'commit'}){print STDERR "ERROR: $RV\n";}
      return;
  }
  else{
      $M->checkId('SRes', 'Contact', 'contact_id', $M->getCla->{'manufacturer_id'}, 'manufacturer_id');
      return unless $M->getOk();
  }

  if (defined $M->getCla->{'protocol_id'}){
      $M->checkId('RAD3', 'Protocol', 'protocol_id', $M->getCla->{'protocol_id'}, 'protocol_id');
      return unless $M->getOk();
  }

    $M->logData('RESULT', 'finished checking command line arguments');
}

sub checkId{
    my $M = shift;
    my $RV;
    $M->setOk(1);
    my ($database, $tablename, $pkname, $id, $claname)=@_;

    my $object=lc($tablename);
    my $Object=join('::', "GUS", "Model", $database, $tablename);

    my $object = $Object->new({$pkname=>$id});
  if (!$object->retrieveFromDB()) {
      
    $RV = join(' ','a VALID --', $claname, 'must be on the commandline', $claname, '=',$M->getCla->{$claname});
  
    $M->logData('ERROR', $RV);
    if($M->getCla->{'commit'}){print STDERR "ERROR: $RV\n";}
    $M->setOk(0);
  }
    return $RV;
}

sub readCfg{
  my $M = shift;
  my $file = $M->getCla->{'cfg_file'};
  my $RV="";

  $M->setOk(1);
  my $fh = new IO::File;
  unless ($fh->open("<$file")) {
      $M->setOk(0);
      $RV = join(' ','Cannot open configuration file', $M->getCla->{'cfg_file'});
      $M->logData('ERROR', $RV);
      if($M->getCla->{'commit'}){print STDERR "ERROR: $RV\n";}
      return;
  }
  while (my $line=<$fh>) {
    if ($line =~ /^\s*$/ || $line =~ /^\s*\#/ || $line =~ /^\#.*$/) {
      next;
    }
    chomp($line);
    my @arr = split(/\t/, $line);
    if (@arr>1) {
      $arr[1] =~ s/^\s+|\s+$//g;
      $arr[1] =~ s/\"|\'//g;
      if ($arr[1] ne "") {
# $cfg_rv is a global hash varaibale
	$cfg_rv->{'mapping'}->{$arr[0]} = $arr[1];
	if ($arr[0] =~ /^ElementAnnotation(\d+)\.value$/) {
	  $cfg_rv->{'elementannotation_index'}->{$1} = 1;
	}
	if ($arr[0] =~ /^CompositeElementAnnotation(\d+)\.value$/) {
	  $cfg_rv->{'compositeelementannotation_index'}->{$1} = 1;
	}
	if ($arr[0] =~ /^ArrayAnnotation(\d+)\.value$/) {
	  $cfg_rv->{'arrayannotation_index'}->{$1} = 1;
	}
      }
    }
  }
  $fh->close();
  $RV = join(' ','Finish reading configuration file', $M->getCla->{'cfg_file'});
  $M->logData('Result', $RV);

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


sub checkCfg(){
    my $M = shift;
    $M->setOk(1);
    my $RV="";
# for Array table
    $M->checkMandatory('RAD3', 'Array');
    return unless $M->getOk;
# for ArrayAnnotation table
    if(defined $cfg_rv->{'arrayannotation_index'}){
	foreach my $m (keys (%{$cfg_rv->{'arrayannotation_index'}})) {
	    if (!defined($cfg_rv->{'mapping'}->{'ArrayAnnotation'.$m.'.name'}) || !defined($cfg_rv->{'mapping'}->{'ArrayAnnotation'.$m.'.value'})) {
		$M->setOk(0);
		$RV="You must provide ArrayAnnotation$m.name and ArrayAnnotation$m.value in your configuration file.\n";
		$M->logData('ERROR', $RV);	
		if($M->getCla->{'commit'}){print STDERR "ERROR: $RV\n";}
		return;
            }
	}
    }    
# for ElementImp table
    if(defined $cfg_rv->{'mapping'}->{'ElementImp.subclass_view'}){
      my $subclass_view=$cfg_rv->{'mapping'}->{'ElementImp.subclass_view'};
      $M->checkMandatory('RAD3', 'ElementImp', $subclass_view );
      return unless $M->getOk;
    }
# ElementImp may not be updated
#    else{
#	$M->setOk(0);
#	$RV="You must provide ElementImp.subclass_view in your CfgFile.\n";
#	$M->logData('Result', $RV);	
#	return;
#    }

# for CompositeElementImp table
    if(defined $cfg_rv->{'mapping'}->{'CompositeElementImp.subclass_view'}){
      my $subclass_view=$cfg_rv->{'mapping'}->{'CompositeElementImp.subclass_view'};
      $M->checkMandatory('RAD3', 'CompositeElementImp', $subclass_view );
      return unless $M->getOk;
    }
# for ElementAnnotation table
    if(defined $cfg_rv->{'elementannotation_index'}){
	foreach my $m (keys (%{$cfg_rv->{'elementannotation_index'}})) {
	    if (!defined($cfg_rv->{'mapping'}->{'ElementAnnotation'.$m.'.name'}) || !defined($cfg_rv->{'mapping'}->{'ElementAnnotation'.$m.'.value'})) {
		$M->setOk(0);
		$RV="You must provide ElementAnnotation$m.name and ElementAnnotation$m.value in your configuration file.\n";
		$M->logData('ERROR', $RV);	
		if($M->getCla->{'commit'}){print STDERR "ERROR: $RV\n";}
		return;
            }
	}
    }    

# for CompositeElementAnnotation table
    if(defined $cfg_rv->{'compositeelementannotation_index'}){
	foreach my $m (keys (%{$cfg_rv->{'compositeelementannootation_index'}})) {
	    if (!defined($cfg_rv->{'mapping'}->{'CompositeElementAnnotation'.$m.'.name'}) || !defined($cfg_rv->{'mapping'}->{'CompositeElementAnnotation'.$m.'.value'})) {
		$M->setOk(0);
		$RV="You must provide CompositeElementAnnotation$m.name and CompositeElementAnnotation$m.value in your configuration file.\n";
		$M->logData('ERROR', $RV);	
		if($M->getCla->{'commit'}){print STDERR "ERROR: $RV\n";}
		return;
            }
	}
    }    
  $RV = join(' ','Finish checking configuration file', $M->getCla->{'cfg_file'});
  $M->logData('Result', $RV);
}

sub workOnArray {
  my $M = shift;

  $M->setOk(1);
  my $RV="";
  $cfg_rv->{'mapping'}->{'Array.platform_type_id'} = $M->getCla->{'platform_type_id'};
  if(defined $M->getCla->{'substrate_type_id'} ){
      $cfg_rv->{'mapping'}->{'Array.substrate_type_id'} = $M->getCla->{'substrate_type_id'};
  }
  if(defined $M->getCla->{'manufacturer_id'} ){
      $cfg_rv->{'mapping'}->{'Array.manufacturer_id'} = $M->getCla->{'manufacturer_id'};
  }
  
  if(defined $M->getCla->{'protocol_id'}) {
      $cfg_rv->{'mapping'}->{'Array.protocol_id'} = $M->getCla->{'protocol_id'};
  }

  my $array_hash;
  my @array_attr=$M->getAttrArray('GUS::Model::RAD3::Array');

# the following will be module dependable or schema dependable
  my @array_key_attr=('name', 'version', 'platform_type_id', 'manufacturer_id');

  for (my $i=0; $i<@array_key_attr; $i++) {
   if(defined $cfg_rv->{'mapping'}->{'Array.'.$array_key_attr[$i] }){
    $array_hash->{$array_key_attr[$i]} = $cfg_rv->{'mapping'}->{'Array.'.$array_key_attr[$i]};
   }
  }
 my $array = GUS::Model::RAD3::Array->new($array_hash);
 my $new_entry = 1; 
 my @attributesToNotRetrieve = ('modification_date', 'row_alg_invocation_id');
 
  if ($array->retrieveFromDB(\@attributesToNotRetrieve)) {
#      print "retrieveFromDb1\n";
      my $string = $array->toString();
      print STDERR "There is already an entry in the Array table with same name, version and platform_type_id:\n$string\nEnter \"OK\", if you want to use this entry as it is.\nEnter \"u\", if you want to update this entry with the information in your CfgFile.\nEnter \"n\", if you want to create a new entry.\n(In this case, read/write permissions will be as by default, unless you have set them in your CfgFile.)\nEnter \"q\" to exit now.\n"; 
      my $input=<STDIN>;
      chomp($input);
      until ($input =~ /^OK$/ || $input =~ /^u$/ || $input =~/^n$/ || $input=~ /^q$/) {
	print STDERR "You must enter one of \"OK\", \"u\", \"n\", or \"q\". Re-enter.\n";
	$input=<STDIN>;
	chomp($input);
      }
      
      if ($input=~ /^q$/) {
	print STDERR "You entered \"q\". Exiting the plug-in.\n";
	$M->setOk(0);
	$M->logData('Result', 'User exit program. No table was affected.');
	return;
      }
      elsif ($input =~ /^OK$/) {
	$new_entry = 0;
	print STDERR "You entered \"OK\". The entry already in the database, without any updating, will be used.\n";
	$cfg_rv->{'Array_Id'} = $array->getId();
	return;
      }
      elsif ($input =~ /^u$/) {
	$new_entry = 0;
	print STDERR "You entered \"u\". The entry currently in the database will be updated with the information in your CfgFile.\n";
	for (my $i=0; $i<@array_attr; $i++) {
	    my $index=join('', 'Array', '.', $array_attr[$i]);
	  if (defined($cfg_rv->{'mapping'}->{$index})) {
	    $array->set($array_attr[$i], $cfg_rv->{'mapping'}->{$index});
	  }
	}
	$M->logData('Result', 'One update in Array tables.');
	$cfg_rv->{'Array_Id'} = $array->getId();
	return;
      }
      else {
	print STDERR "You entered \"n\". A new entry will be created.\n";
      }
  }
 
  my $prod = 1;
  my $counter=0;
  if (defined($cfg_rv->{'mapping'}->{'Array.num_array_rows'})) {
    $prod *= $cfg_rv->{'mapping'}->{'Array.num_array_rows'};
    $counter++;
  }
  if (defined($cfg_rv->{'mapping'}->{'Array.num_array_columns'})) {
    $prod *= $cfg_rv->{'mapping'}->{'Array.num_array_columns'};
    $counter++;
  }
  if (defined($cfg_rv->{'mapping'}->{'Array.num_grid_rows'})) {
    $prod *= $cfg_rv->{'mapping'}->{'Array.num_grid_rows'};
    $counter++;
  }	
  if (defined($cfg_rv->{'mapping'}->{'Array.num_grid_columns'})) {
    $prod *= $cfg_rv->{'mapping'}->{'Array.num_grid_columns'};
    $counter++;
  }
  if (defined($cfg_rv->{'mapping'}->{'Array.num_sub_rows'})) {
    $prod *= $cfg_rv->{'mapping'}->{'Array.num_sub_rows'};
    $counter++;
  }
  if (defined($cfg_rv->{'mapping'}->{'Array.num_sub_columns'})) {
    $prod *= $cfg_rv->{'mapping'}->{'Array.num_sub_columns'};
    $counter++;
  }
  if ($counter==6) {
    if ( defined($cfg_rv->{'mapping'}->{'Array.number_of_elements'}) &&  $prod!=$cfg_rv->{'mapping'}->{'Array.number_of_elements'}) {
      $M->setOk(0);
      $M->logData('ERROR', 'No table was touched because The number of elements you entered in your CfgFile does not match the array layout you entered.\nExiting the plug-in.\n');
      if($M->getCla->{'commit'}){print STDERR "ERROR: $RV\n";}
      return;
    }
  }

  if($new_entry==1){
      for (my $i=0; $i<@array_attr; $i++) {
	  next if( (grep(/^$array_attr[$i]$/, @array_key_attr)) ); 
	  if (defined($cfg_rv->{'mapping'}->{'Array.'.$array_attr[$i]})) {
	      $array_hash->{$array_attr[$i]} = $cfg_rv->{'mapping'}->{'Array.'.$array_attr[$i]};
	  }
      }
      
      $array = GUS::Model::RAD3::Array->new($array_hash);
      if($M->getCla->{'debug'}){
	  foreach my $key(keys %$array_hash){
	      print "$key\t$array_hash->{$key}\n";
	  }
      }
      $array->submit(undef, 1);
  }
# for debug
  if($M->getCla->{'debug'}){
      $cfg_rv->{'Array_Id'} = $array->getId();
      $RV="Finish update/insert Array table.\tArray_Id:\t$cfg_rv->{'Array_Id'}";
      $M->logData('Debug', $RV);
  }
  elsif ( $array->getId() ) {
    $cfg_rv->{'Array_Id'} = $array->getId();
    $M->setOk(1);
    $RV ="Finish update/insert Array table.\tArray_Id:\t$cfg_rv->{'Array_Id'}";
    $M->logData('Result', $RV);
  }
  else {
    $M->setOk(0);
    $M->logData('ERROR', 'No table was touched, as Array entry could not be inserted/updated.');
   if($M->getCla->{'commit'}){print STDERR "ERROR: $RV\n";}
  }
  return;
}


sub workOnArrayAnnotation{
    my $M = shift;
    $M->setOk(1);
    my $RV="";
    my @arrayannotation_attr=$M->getAttrArray('GUS::Model::RAD3::ArrayAnnotation');
    my @arrayannotation_key_attr=('name', 'value');

  foreach my $m (keys (%{$cfg_rv->{'arrayannotation_index'}})) {
    my $arrayannotation_hash;
    $arrayannotation_hash->{'array_id'}= $cfg_rv->{'Array_Id'};

    for (my $i=0; $i<@arrayannotation_key_attr; $i++) {

      my $index=join('', 'ArrayAnnotation', $m, '.', $arrayannotation_key_attr[$i]);

      if (defined $cfg_rv->{'mapping'}->{$index}) {
	  print "$index\n";
	$arrayannotation_hash->{$arrayannotation_key_attr[$i]} = $cfg_rv->{'mapping'}->{$index};
      }
    }
    my $arrayannotation = GUS::Model::RAD3::ArrayAnnotation->new($arrayannotation_hash);
    my $new_entry = 1;
    my @attributesToNotRetrieve = ('modification_date', 'row_alg_invocation_id');
    if ($arrayannotation->retrieveFromDB(\@attributesToNotRetrieve)) {
      my $string = $arrayannotation->toString();
      print STDERR "There is already an entry in the ArrayAnnotation table with same name, value and array_id:\n$string\nEnter \"OK\", if you want to use this entry as it is.\nEnter \"u\", if you want to update this entry with the information in your CfgFile.\nEnter \"n\", if you want to create a new entry.\n(In this case, read/write permissions will be as by default, unless you have set them in your CfgFile.)\nEnter \"q\" to exit now.\n"; 
      my $input=<STDIN>;
      chomp($input);
      until ($input =~ /^OK$/ || $input =~ /^u$/ || $input =~/^n$/ || $input=~ /^q$/) {
	print STDERR "You must enter one of \"OK\", \"u\", \"n\", or \"q\". Re-enter.\n";
	$input=<STDIN>;
	chomp($input);
      }
      
      if ($input=~ /^q$/) {
	print STDERR "You entered \"q\". Exiting the plug-in.\n";
	$M->setOk(0);
	$M->logData('Result', 'Possible updates/inserts in Array and ArrayAnnotation tables. No other table was affected.');
	return;
      }
      elsif ($input =~ /^OK$/) {
	$new_entry = 0;
	print STDERR "You entered \"OK\". The entry already in the database, without any updating, will be used.\n";
      }
      elsif ($input =~ /^u$/) {
	$new_entry = 0;
	print STDERR "You entered \"u\". The entry currently in the database will be updated with the information in your CfgFile.\n";
	for (my $i=0; $i<@arrayannotation_attr; $i++) {
	    my $index=join('', 'ArrayAnnotation', $m, '.', $arrayannotation_attr[$i]);
	  if (defined($cfg_rv->{'mapping'}->{$index})) {
	    $arrayannotation->set($arrayannotation_attr[$i], $cfg_rv->{'mapping'}->{$index});
	  }
	}
	$M->logData('Result', 'One update in ArrayAnnotation tables.');
	next;
      }
      else {
	print STDERR "You entered \"n\". A new entry will be created.\n";
      }
    }
    if ($new_entry==1) {
      for (my $i=0; $i<@arrayannotation_attr; $i++) {
	   next if( (grep(/^$arrayannotation_attr[$i]$/, @arrayannotation_key_attr)) ); 
	my $index=join('', 'ArrayAnnotation', $m, '.', $arrayannotation_attr[$i]);
	if (defined($cfg_rv->{'mapping'}->{$index})) {
	  $arrayannotation_hash->{$arrayannotation_attr[$i]} = $cfg_rv->{'mapping'}->{$index};
	}
      }
      $arrayannotation = GUS::Model::RAD3::ArrayAnnotation->new($arrayannotation_hash);
      $arrayannotation->submit();

    }

# for debug
    if($M->getCla->{debug}){
      $cfg_rv->{'arrayannotation_id'}->{$m} = $arrayannotation->getId();
      $RV="One insert into ArrayAnnotation.\tarayannotation_id\t$cfg_rv->{'arrayannotation_id'}->{$m}\n";
      $M->logData('Debug', $RV);
    }
    elsif ($arrayannotation->getId()) {
      $cfg_rv->{'arrayannotation_id'}->{$m} = $arrayannotation->getId();
      $RV="One insert into ArrayAnnotation.\tarayannotation_id\t$cfg_rv->{'arrayannotation_id'}->{$m}\n";
      $M->logData('Result', $RV);
    }
    else {
      $M->setOk(0);
      $M->logData('ERROR', 'Possible updates/inserts in Array and ArrayAnnotation tables. No other table was affected, as some of the ArrayAnnotation entries could note be inserted/updated.');
      if($M->getCla->{'commit'}){print STDERR "ERROR: $RV\n";}
      last;#exit of foreach loop
    }  

  } #end of foreach loop 
  return;
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
  $M->logData('Result', 'finish parse the headers of array data file');
}

sub loadData{
   my $M=shift;
   my ($fh)=@_;

   my $RV="";
   my @common_attr=('modification_date', 'user_read', 'user_write', 'group_read', 'group_write', 'other_read', 'other_write', 'row_user_id','row_group_id', 'row_project_id', 'row_alg_invocation_id');
   $M->setOk(1);
   my $num_inserts = 0; # holds current number of rows inserted into ElementImp
   my $num_spot_family = 0; # holds current number of rows inserted into CompositeElementImp
   my $line = "";
  
# the following hash is used for caching
   my %ext_db_cache; 
   my $warnings;
   my $dbh = $M->getQueryHandle();
# for query the compositeElementImp and/or compositeElementAnnotation tables to check the CompositeElement
   my $sql;

# for checking the externaldatabaserelease id
   my $statement = 'select external_database_id from SRes.ExternalDatabaseRelease where external_database_release_id=?';
   my $sth = $dbh->prepare($statement);
#
#  my $statement2 = 'select ontology_entry_id from RAD3.OnotologyEntry where category like %element type% and value like %?%';
#  my $sth2 = $dbh->prepare($statement2);

   my $n=0;  

   while ($line = <$fh>) {
    
     $n++;
     if ($n%200==0) {
	 $RV="Read $n datalines including empty line";
	 $M->logData('Result', $RV);
	 if($M->getCla->{'commit'}){
	     $RV = "Processed $n dataline, Inserted $num_inserts Elements and $num_spot_family CompositeElements."; 
	     print STDERR "Result: $RV\n";
	 }
     }
#skip number of line as defined by user
     if (defined $M->getCla->{'restart'} && $n<$M->getCla->{'restart'}) {
	 next;
     }
#skip empty lines if any
     if ($line =~ /^\s*$/) {
	 next;
     }
#print out the data line
     if($M->getCla->{debug}){
	 print "Debug\t$line\n";
     }
#stop reading data lines after testnumber of lines
     if (!$M->getCla->{'commit'} && defined $M->getCla->{'testnumber'} && $n-$M->getCla->{'restart'}==$M->getCla->{'testnumber'}+1) {
	 $n--;
	 $RV="stopping reading after testing $M->getCla->{'testnumber'} lines";
	 $M->logData('Result', $RV);
	 last;
     }

     my @arr = split(/\t/, $line);
    
     if (scalar(@arr) != $cfg_rv->{'num_fields'}) {
	 $warnings = "The number of fields for data line $n does not equal the number of fields in the header.\nThis might indicate a problem with the data file.\nData loading is interrupted.\nData from data line $n and following lines were not loaded.\nHere $n is the number of lines (including empty ones) after the header.\n";   
	 $M->logData('ERROR', $warnings);
	 $M->setOk(0);
	 if($M->getCla->{'commit'}){print STDERR "ERROR: $RV\n";}
	 last; #exit the while loop
     }

# get rid of preceding and trailing spaces and of quotes
     for (my $i=0; $i<@arr; $i++) {
	 $arr[$i] =~ s/^\s+|\s+$//g;
	 $arr[$i] =~ s/\"|\'//g;
     }

     my $skip_line = 0; # when set to 1 the current data line is skipped

# build a row for spotFamilyImp

     my $pos=$cfg_rv->{'position'};
     my $mapping=$cfg_rv->{'mapping'};
     my $spot_fam_pk;
     my $spot_family;
     my $subview;
     my $subclassview;
     my @attributesToNotRetrieve = ('modification_date', 'row_alg_invocation_id');
     if(defined $cfg_rv->{'mapping'}->{'CompositeElementImp.subclass_view'}){
	 my $spot_fam_hash;
	 $spot_fam_hash->{'array_id'} = $cfg_rv->{'Array_Id'};
	 $subview=$mapping->{'CompositeElementImp.subclass_view'};
	 $spot_fam_hash->{'subclass_view'} = $subview;
	 $subclassview=join('::', 'RAD3', $subview); 
	 my @spot_fam_attr=$M->getAttrArray($subclassview);
	 my $spot_fam_attr_hashref=$M->getAttrHashRef($subclassview);

# build up the query for checking compisteElement id
	 if(defined $cfg_rv->{'compositeelementannotation_index'}){
	     my $avName;
	     $sql="select ce.composite_element_id from RAD3.$subview ce, RAD3.compositeElementAnnotation cea where ce.array_id=$cfg_rv->{'Array_Id'} and ce.subclass_view=\'$subview\' and ce.composite_element_id=cea.composite_element_id";
 
	     if(defined $cfg_rv->{'mapping'}->{'CompositeElementAnnotation1.name'} ){
		 $avName=$cfg_rv->{'mapping'}->{'CompositeElementAnnotation1.name'};
		 $sql .=" and cea.name=\'$avName\' ";
	     }
# only check the first compositeElementAnnotation
	     my $avIndex="CompositeElementAnnotation1.value";
	     if ($arr[$pos->{$cfg_rv->{'mapping'}->{$avIndex}}] ne ""){
		 my $value=$arr[$pos->{$cfg_rv->{'mapping'}->{$avIndex}}];
		 $sql .=" and cea.value=\'$value\' ";
	     }
	 }
	 else{
	     $sql="select ce.composite_element_id from RAD3.$subview ce where ce.array_id=$cfg_rv->{'Array_Id'} and ce.subclass_view=\'$subview\'  ";
	 }


	 my $attrValue;
	 for (my $i=0; $i<@spot_fam_attr; $i++) {
#	next if ($spot_fam_attr[$i]=~ /^subclass_view$/);
	     if (defined $mapping->{'CompositeElementImp.'.$spot_fam_attr[$i]}&& defined $pos->{$mapping->{'CompositeElementImp.'.$spot_fam_attr[$i]}} && $arr[$pos->{$mapping->{'CompositeElementImp.'.$spot_fam_attr[$i]}}] ne "") {
		 $spot_fam_hash->{$spot_fam_attr[$i]} = $arr[$pos->{$mapping->{'CompositeElementImp.'.$spot_fam_attr[$i]}}];
		 $attrValue=$arr[$pos->{$mapping->{'CompositeElementImp.'.$spot_fam_attr[$i]}}];

# to biuld up the $sql
		 $sql .= " and ce.$spot_fam_attr[$i] =\'$attrValue\' "; 

	     }
	     if ( ($spot_fam_attr_hashref->{$spot_fam_attr[$i]} =~ /^Not Nullable$/)  && !defined $spot_fam_hash->{$spot_fam_attr[$i]}) {
		 $warnings = "Data file line $n is missing attribute CompositeElementImp.$spot_fam_attr[$i], which is mandatory.\nData from this data line were not loaded.\nHere $n is the number of lines (including empty ones) after the header.\n\n";
		 $M->logData('Warning', $warnings);
		 $skip_line = 1;
		 if($M->getCla->{'commit'}){print STDERR "Warning: $RV\n";}
		 last; # exit the for loop
	     }
          
	     if ($spot_fam_attr[$i] eq 'external_database_release_id' && defined $spot_fam_hash->{'external_database_release_id'} && !$ext_db_cache{$spot_fam_hash->{'external_database_release_id'}}) {
		 $sth->execute($spot_fam_hash->{'external_database_release_id'});
		 my ($lowercase_name) = $sth->fetchrow_array();
		 $sth->finish();
		 if (!defined $lowercase_name || $lowercase_name eq "") {
		     $warnings = "Invalid external_realase_id at line $n of data file.\nData from data line $n were not loaded.\nHere $n is the number of lines (including empty ones) after the header.\n\n";
		     $M->logData('Warning', $warnings);
		     $skip_line = 1;
		     if($M->getCla->{'commit'}){print STDERR "Warning: $RV\n";}
		     last; # exit the for loop 	  
		 }
		 else {
		     $ext_db_cache{$spot_fam_hash->{'external_database_release_id'}} = 1;
		 }
	     }
 
	 }

	 if ($skip_line) {
	     next; # skip this line
	 }

	 if (defined $spot_fam_hash->{'source_id'} && !defined $spot_fam_hash->{'external_database_release_id'}) {
	     $warnings = "Line $n of data file has a source_id but not an ext_db_id.\nThe latter must be given if source_id is given.\nData from data line $n were not loaded.\nHere $n is the number of lines (including empty ones) after the header.\n\n";
	     $M->logData('Warning', $warnings);
	     if($M->getCla->{'commit'}){print STDERR "Warning: $RV\n";}
	     next; # skip this line
	 }   

	 my $spot_fam_view = $mapping->{'CompositeElementImp.subclass_view'};
	 my $SPOT_FAM_VIEW=join('::', "GUS", "Model", 'RAD3', $spot_fam_view);
	 $spot_family = $SPOT_FAM_VIEW->new($spot_fam_hash);
# check whether this row is already in the database
# if it is, get its primary key



	 if ($spot_family->retrieveFromDB(\@attributesToNotRetrieve)) {

#	 $sth = $dbh->prepare($sql);	
#	 $sth->execute();
# fetch the first returned composite_element_id
#	 my ($composite_element_id) = $sth->fetchrow_array();
#	 $sth->finish();

#	 if ( defined $composite_element_id ) {
#	     $spot_fam_pk = $composite_element_id;
	     $spot_fam_pk = $spot_family->getId();
	     $RV="Data line no. $n\tAlready existing an entry in CompositeElementImp\tNo insert";
	     if(! $M->getCla->{noWarning} ){
		 $M->logData('Warning', $RV) ;
	     }
	     if($M->getCla->{'commit'} && ! $M->getCla->{noWarning} ){
		 print STDERR "Warning: $RV\n";
	     }
	 }
	     else{
		 $spot_family->submit();
		 $num_spot_family++;
		 if($spot_family->getId()){
		     $spot_fam_pk = $spot_family->getId();
		 }
	     }
     }

# build a row for SpotImp
     my $spot_hash;
     $subclassview=join('::', 'RAD3',$mapping->{'ElementImp.subclass_view'}); 
     my @spot_attr=$M->getAttrArray($subclassview);
     my $spot_attr_hashref=$M->getAttrHashRef($subclassview);
#    my $idhash=$M->getCVNameToIdHash('element type');

     $spot_hash->{'array_id'} = $cfg_rv->{'Array_Id'};

     $subview=$mapping->{'ElementImp.subclass_view'};
     $spot_hash->{'subclass_view'} = $subview;

# mapping element type to ontology entry id temporarily commented out
#     if (defined $mapping->{'ElementImp.element_type'}&& defined $pos->{$mapping->{'ElementImp.element_type'}} &&  $arr[$pos->{$mapping->{'ElementImp.element_type'}}] ne "") {
#	$spot_hash->{element_type_id} = $idhash->{$arr[$pos->{$mapping->{'ElementImp.element_type'}}]};
#      }

     for (my $i=0; $i<@spot_attr; $i++) {
	 if (defined $mapping->{'ElementImp.'.$spot_attr[$i]}&& defined $pos->{$mapping->{'ElementImp.'.$spot_attr[$i]}} &&  $arr[$pos->{$mapping->{'ElementImp.'.$spot_attr[$i]}}] ne "") {
	     $spot_hash->{$spot_attr[$i]} = $arr[$pos->{$mapping->{'ElementImp.'.$spot_attr[$i]}}];
	 }

#      if($spot_attr[$i] =~ /^element_type_id$/ )
#     $spot_hash->{'element_tye_id'}

	 if ($spot_attr_hashref->{$spot_attr[$i]}=~ /^"Not Nullable"$/ && !defined $spot_hash->{$spot_attr[$i]}) {
	     $warnings = "Data file line $n is missing attribute ElementImp.$spot_attr[$i], which is mandatory\nData from data line $n were not loaded.\nHere $n is the number of lines (including empty ones) after the header.\n\n";
	     $M->logData('Warning', $warnings);
	     $skip_line = 1;
	     if($M->getCla->{'commit'}){print STDERR "Warning: $RV\n";}
	     last;
	 }
     }

     if ($skip_line) {
	 next;
     }

     my $spot_view = $mapping->{'ElementImp.subclass_view'};
     my $SPOT_VIEW=join('::', 'GUS', 'Model', 'RAD3', $spot_view);

     my $spot = $SPOT_VIEW->new($spot_hash);
     my $spot_id;
     my $spot_pk;
#  $spot->setParent($spot_family);  
     if (defined($spot_fam_pk)) {
	 $spot->setCompositeElementId($spot_fam_pk);
# check whether this row is already in the database
	 if ($spot->retrieveFromDB(\@attributesToNotRetrieve)) {
	     $spot_pk=$spot->getId();
	     $RV="Data line no. $n\tAlready existing an entry in ElementImp\tNo insert";
	     if(! $M->getCla->{noWarning} ){
		 $M->logData('Warning', $RV);
	     }
	     if($M->getCla->{'commit'} && ! $M->getCla->{noWarning}){
		 print STDERR "Warning: $RV\n";
	     }
	 }
	 else{
	     $spot->submit();	  
	 }
     }
     else{
	 if ($spot->retrieveFromDB(\@attributesToNotRetrieve)) {
	     $spot_pk=$spot->getId();
	     $RV="Data line no. $n\tAlready existing an entry in ElementImp\tNo insert";
	     if(! $M->getCla->{noWarning}){
		 $M->logData('Warning', $RV);
	     }
	     if($M->getCla->{'commit'} && ! $M->getCla->{noWarning} ){
		 print STDERR "Warning: $RV\n";
	     }
	 }
	 else{
	     $spot->submit();	  
	 } 
     }
# need to rewrite this part
     if($spot->getId()){
	 $spot_pk = $spot->getId();
     }
     if(defined($spot_fam_pk)){
	 $cfg_rv->{'CompositeElement_Id'}= $spot_fam_pk;
     }
     else{
	 if(defined $spot_family){
	     $cfg_rv->{'CompositeElement_Id'}= $spot_family->getId();
	 }
     }

     if(defined($spot_pk)){
	 $cfg_rv->{'Element_Id'}= $spot_pk;
     }
     else{
	 $cfg_rv->{'Element_Id'}= $spot->getId();
     }

     if(defined $cfg_rv->{'compositeelementannotation_index'}){
	
	 foreach my $m (keys (%{$cfg_rv->{'compositeelementannotation_index'}})) {
	     my $composite_element_annotation_hash;
	     my $composite_element_annotation;
	     $composite_element_annotation_hash->{'composite_element_id'}=$cfg_rv->{'CompositeElement_Id'};
	     my $nIndex=join('', 'CompositeElementAnnotation', $m, '.', 'name');
	     my $vIndex=join('', 'CompositeElementAnnotation', $m, '.', 'value');

	     $composite_element_annotation_hash->{'name'}=$cfg_rv->{'mapping'}->{$nIndex};

	     if ($arr[$pos->{$cfg_rv->{'mapping'}->{$vIndex}}] ne ""){
		 $composite_element_annotation_hash->{'value'}=$arr[$pos->{$cfg_rv->{'mapping'}->{$vIndex}}];
	     }

	     if ( !defined $composite_element_annotation_hash->{'value'} ) {
		 next; #skip this indexed compositeannotation
	     } 
	     else{
		 $composite_element_annotation=GUS::Model::RAD3::CompositeElementAnnotation->new($composite_element_annotation_hash);
		 my @attributesToNotRetrieve = ('modification_date', 'row_alg_invocation_id');

		 if($composite_element_annotation->retrieveFromDB(\@attributesToNotRetrieve)){
		     $RV="Data line no. $n\tAlready existing an entry in CompositeElementAnnotation\tNo insert";
		     if(! $M->getCla->{noWarning}){
			 $M->logData('Warning', $RV);
		     }
		     if($M->getCla->{'commit'} && ! $M->getCla->{noWarning}){
			 print STDERR "Warning: $RV\n";
		     }
		     next;
		 }
		 else{
		     $composite_element_annotation->submit();
		 }
# check if submit success or the row is already in database
	     }#end else
	 }#end foreach
      } #end if

# work on elementannation
     if(defined $cfg_rv->{'elementannotation_index'}){
	
	
# for debug
#   $element_annotation_hash->{'element_id'}=1;
	 foreach my $m (keys (%{$cfg_rv->{'elementannotation_index'}})) {
	     my $element_annotation_hash;
	     my $element_annotation;
	     $element_annotation_hash->{'element_id'}=$cfg_rv->{'Element_Id'};	
	     my $nIndex=join('', 'ElementAnnotation', $m, '.', 'name');
	     my $vIndex=join('', 'ElementAnnotation', $m, '.', 'value');
	     $element_annotation_hash->{'name'}=$cfg_rv->{'mapping'}->{$nIndex};
       
	     if ($arr[$pos->{$cfg_rv->{'mapping'}->{$vIndex}}] ne ""){
		 $element_annotation_hash->{'value'}=$arr[$pos->{$cfg_rv->{'mapping'}->{$vIndex}}];
	     }
       
	     if ( !defined $element_annotation_hash->{'value'} ) {
		 next;
	     } 
	     else{
		 $element_annotation=GUS::Model::RAD3::ElementAnnotation->new($element_annotation_hash);
		 if($element_annotation->retrieveFromDB(\@attributesToNotRetrieve)){
		     $RV="Data line no. $n\tAlready existing an entry in ElementAnnotation\tNo insert";
		     if(! $M->getCla->{noWarning}){
			 $M->logData('Warning', $RV);
		     }
		     if($M->getCla->{'commit'} && ! $M->getCla->{noWarning}){
			 print STDERR "Warning: $RV\n";
		     }
		     next;
		 }
		 else{
		     $element_annotation->submit();
		 }
# check if submit success or the row is already in database
	     }
	 }
     }

     $num_inserts++;
#     $spot_family->undefPointerCache();

       $M->undefPointerCache();
 }#end of while loop


   $dbh->disconnect();
   $RV="Total datalines read (after header): $n.";
   $M->logData('Result', $RV);
   if($M->getCla->{'commit'}){print STDERR "Result: $RV\n";}
   $RV="Number of lines which have been inserted into database (after header): $num_inserts.";
   $M->logData('Result', $RV);
   if($M->getCla->{'commit'}){print STDERR "Result: $RV\n";}
   $RV="Number of records which have been inserted into CompositeElementImp table (after header): $num_spot_family.";
   $M->logData('Result', $RV);
   if($M->getCla->{'commit'}){print STDERR "Result: $RV\n";}   
   $RV = "Processed $n dataline, Inserted $num_inserts Elements and $num_spot_family CompositeElements."; 
   return $RV;
}

sub mapCVNameToId{
    my $M=shift;
    my ($category, $cvName)=@_;
    my $cvId;
    my $hash=$M-> getCVNameToIdHash($category);
    foreach my $key (keys %$hash){
	if($key=~ /$cvName/ ){
	    $cvId=$hash->{$key};
	}
    }
    return $cvId;
}

sub getCVNameToIdHash{
    my $M->shift;
    my ($category)=@_;
    my $dbh = $M->getQueryHandle();

    my $q = $M->doSelect('select ontology_entry_id, name from RAD3.OntologyEntry');

    my $idHash;
    foreach my $row (@$q) {
        $idHash->{$row->{'name'}} = $row->{'ontology_entry_id'};
    }

    $dbh->disconnsct();
    return $idHash;
}

# Run a query and return the results as an arrayref
# of hashrefs.
#
sub doSelect {
    my $M=shift;
    my($query) = @_;
    my $result = [];
                               
#    print STDERR "SpottedArrayLoader.pm: $query\n";
                         
    my $dbh = $M->getQueryHandle();
    my $sth = $dbh->prepare($query);
    print "$query\n";
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

GUS::RAD::Plugin::ArrayLoader

=head1 SYNOPSIS

ga GUS::RAD::Plugin:ArrayLoader B<[options]> B<--cfg_file> cfg_file B<--data_file> data_file

ga GUS::RAD::Plugin::ArrayLoader B<[options]> B<--help>

ga GUS::RAD::Plugin::ArrayLoader B<[options]> B<--cfg_file> cfg_file B<--data_file> data_file B<--manufacturer_id> manufacturer_id B<--platform_type_id> platform_type_id B<--substrate_type_id> substrate_type_id B<--debug> > logfile

ga GUS::RAD::Plugin::ArrayLoader B<[options]> B<--cfg_file> cfg_file B<--data_file> data_file B<--manufacturer_id> manufacturer_id B<--platform_type_id>  platform_type_id B<--substrate_type_id> substrate_type_id B<--commit> > logfile 

=head1 DESCRIPTION

    This is a plug-in that loads array data (spotted microarray and oligonucleotide array) into Array, ArrayAnnotation, CompositeElementAnnotaion, ElementAnnotation tables and views of CompositeElementImp, ElementImp.  

=head1 ARGUMENTS

B<--cfg_file> F<config_file> [require the absolute pathname]
   
    This file tells the plug-in how to map table/view attributes to columns in the data file and gives the values for attributes in Array, ArrayAnnotation.

B<--data_file> F<data_file>  [require the absolute pathname]

    The file contains the values for attributes in ElementImp, CompositeElementImp, ElementAnnotation and CompositeElementAnnotation.

B<--manufacturer_id> I<manufacturer_id>  [require must be one of contact_id in SRes:Contact table]

    set value for the Array.manufacturer_id

B<--platform_type_id> I<platform_type_id>  [require must be one of ontology_entry_id in RAD3::OntologyEntry table]

    set value for the Array.platform_type_id

B<--substrate_type_id> I<substrate_type_id>  [require must be one of ontology_entry_id in RAD3::OntologyEntry table]

    set value for the Array.substrate_type_id

=head1 OPTIONS

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

=head2 F<cfg_file> 

This configuration file tells the plug-in how to map table/view attributes to columns in the data file. Here is a detailed description of the format:

You should save this file in the CVS repository, in the directory $PROJECT_HOME/RAD/DataLoad/config (the name of this file, stripped of its path, is stored by the ga as an algorithm parameter).

* This should be a tab-delimited text file, with 2 columns, named: "Table.attribute", "value or header" The order and case of these columns is important, and it is recommended to follow the template for the sake of consistency.

* Lines which start with "#" are ignored (use this for comments).

* Each (non-comment) line should contain exactly only one tab.

* The first column should be in the same format as "Table.attribute", Even if it is view, give the ImpTable name and the names in for "attribute" should be the attribute names as named in the view of interest.

* For empty fields do not use special symbols (like NA or similar), just leave that field empty or delete this line.

* If a line of the Template does not apply to your situation,  you do not have to enter it in your configuration file.

* In case the Template does not include the attribute required by your array design and is in RAD3 schema,  you can add it in your configuration file.

* You can have mutiple entries for annotation tables such as ArrayAnnotation, ElementAnnotation and CompositeAnnotation table. The number after annotation table name denotes each entry. For example, ArrayAnnotation1.name and ArrayAnnotation1.value. And the name attribute for annotation table should be provided as value and value attribute for annotation table as header.

*  For each row, only one of VALUE and HEADER can be given. If the value of a particular table attribute is constant for all data lines, enter that in the second column. Else, if the value has to be taken from the data file, put in the second column the name of the data file column containing that value (the names under second column should be identical, case and all, to how they appear in the data file). But for external_database_release_id and element_type_id, always provide them as HEADER even if they are constant for all elements.

* Please make sure that the column in your data file to which external_database_release_id is mapped, if present (which in most cases should be), contains valid SRes.ExternalDatabaseRelease.ext_db_ids. If this is not the case, you will need to re-parse your data file, as the plug-in will not insert any row with an invalid external_database_release_id, when this is present.

* It is crucial that the attributes of CompositeElememtImp that you are listing are such that each CompositeElement in your data file is uniquely identified by those attributes. For spotted array case, if one of the attributes listed should be present in each spot family and uniquely identifies a spot family (e.g. a well id might do this), make that attribute mandatory in your configuration file.

* It is also very important for shortOligo array, the name attribute for each shortOligoFamily should be unique, since the plugin will cache the name attribute of each shortOligoFamily and all shortOligoFamily with same name will be loaded into database once.

=head2 F<data_file>

The data file should be in tab-delimited text format with one header row and a row for each element. All rows should contain the same number of tabs/fields.

* Every element for which an external_database_release_id and source_id are available should have these stored in the database. You will need to have two columns in the data file one for each of these two fields.

* Empty lines in the data files are ignored. All quotes within a data line are removed by the plug-in.

Please double-check that your data file has no inconsistencies before loading the data. If a column in your data file contains information which should be separated and stored into different table/view attributes, you will need to re-parse your file and separate this information into different columns before running the plug-in. Similarly, if information from different columns of your data file refers to one table/view attribute, you will need to re-parse your data file and merge this information into one column.

=head2 I<restart>

If you need to restart loading from your data file from a specific line (e.g. due to previous interruptions in data loading), give the line number of this line in the --restart option. You should start your line count from the line after the header line and include any empty lines. 

=head2 I<testnumber>

If you are testing the plug-in and want only to test n lines from your data file, use the --testnumber option. If you set this to n, it will test the plug-in on the first n data lines (counting empty lines) after the header or after --restart, if this is set. 

=head1 AUTHOR

Written by Junmin Liu.

=head1 COPYRIGHT

Copyright Trustees of University of Pennsylvania 2003. 
