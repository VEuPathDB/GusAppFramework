# ----------------------------------------------------------
# ArrayLoader.pm#
# Loads data into Array, ArrayAnnotation, 
# ElementImp, CompositeElementImp, 
# ElementAnnotation, CompositeAnnotation 
# 
# Mandatory inputs are technology_type_id, a configuration file and a data file.
# 
# Optional inputs are substrate_type_id, manufacturer_id,
#
# Created: Tuesday June 11 12:00:00 EST 2002
#
# junmin liu
#
# Modified
#   Thursday October 16, 2003  
#     made final changes for loading control infor.
#   Monday Sept. 13 2002
#
#   Thursday Jan. 23 2003
#     made changes for new build system
#
# $Revision$ $Date$ $Author$ 
# ----------------------------------------------------------
package GUS::Supported::Plugin::LoadArrayDesign;
@ISA = qw( GUS::PluginMgr::Plugin );


use strict;
use IO::File;
use CBIL::Util::Disp;
use GUS::PluginMgr::Plugin;

# GUS utilities
use GUS::Model::RAD::ArrayDesign;
use GUS::Model::RAD::Protocol;
use GUS::Model::SRes::Contact;
use GUS::Model::Study::OntologyEntry;
use GUS::Model::RAD::ArrayDesignAnnotation;
use GUS::Model::RAD::ElementAnnotation;
use GUS::Model::RAD::CompositeElementAnnotation;
use GUS::Model::RAD::Control;

sub new {
  my $class = shift;
  my $self = {};
  bless ($self, $class);

  my $purposeBrief = 'Loads array information data into RAD database.';

  my $purpose = <<PURPOSE;
This plugin reads a configuration file and data file and loads data into ArrayDesign, ArrayDesignAnnotation, ElementImp, CompositeElementImp, ElementAnnotation, CompositeElementAnnotation, Control tables in RAD database.
PURPOSE


  my $tablesAffected = [
    ['RAD::ArrayDesign',               'Enters one row for the array loaded'],
    ['RAD::ArrayDesignAnnotation',          'For the array entered, enters here the name/value pairs of the ArrayDesignAnnotation as recorded in the corresponding cfg file'],
    ['RAD::ElementImp',      'Enters here many rows for each array entered'],
    ['RAD::CompositeElementImp', 'Enters here many rows for each array entered'],
    ['RAD::ElemenetAnnotation',         'For the array entered, enters here the name/value pairs of the ElementAnnotation as recorded in the corresponding cfg file.'],
    ['RAD::CompositeElementAnnotation',    'For the array entered, enters here the name/value pairs of the CompositeElementAnnotation as recorded in the corresponding cfg file.'],
    ['RAD::Control',          'Enters here one row for each element or compositeElement designated as control']
   ];

  my $tablesDependedOn = [
    ['Study::OntologyEntry',                'Holds the ontolgies for technology_type, substrate_type and control_type'],
    ['RAD::Array',                'Holds array information'], 
    ['RAD::Protocol',             'The array manufacturing protocol used'], 
    ['SRes::Contact',              'Information on researchers who produces the array']
  ];

  my $howToRestart = <<RESTART;
Loading can be resumed using the I<--restart n> argument where n is the line number in the data file of the first row to load upon restarting (line 1 is the first line after the header, empty lines are counted).
RESTART

  my $failureCases = <<FAILURE_CASES;
Files not in an appropriate format.
FAILURE_CASES

  my $notes = <<NOTES;

=head2 EXAMPLES

ga GUS::Supported::Plugin::LoadArrayDesign B<[options]> B<--cfg_file> cfg_file B<--data_file> data_file

ga GUS::Supported::Plugin::LoadArrayDesign B<[options]> B<--help>

ga GUS::Supported::Plugin::LoadArrayDesign B<[options]> B<--cfg_file> cfg_file B<--data_file> data_file B<--manufacturer_id> manufacturer_id B<--technology_type_id> technology_type_id B<--substrate_type_id> substrate_type_id B<--debug> > logfile

ga GUS::Supported::Plugin::LoadArrayDesign B<[options]> B<--cfg_file> cfg_file B<--data_file> data_file B<--manufacturer_id> manufacturer_id B<--technology_type_id>  technology_type_id B<--substrate_type_id> substrate_type_id B<--commit> > logfile


=head2 F<cfg_file>

This file tells the plug-in how to map table/view attributes to columns in the data file and gives the values for attributes in ArrayDesign, ArrayDesignAnnotation.

See the sample config file F<sample_LoadArrayDesign.cfg> in the GUS/RAD/config directory.

Empty lines are ignored.

Each (non-empty) line should contain B<exactly one> tab.

Do not use special symbols (like NA or similar) for empty fields: either leave the field empty or delete the entire line.

The names of each field and instructions for their values are as follows: 

This configuration file tells the plug-in how to map table/view attributes to columns in the data file. Here is a detailed description of the format:

* This should be a tab-delimited text file, with 2 columns, named: "Table.attribute", "value or header" The order and case of these columns is important, and it is recommended to follow the template for the sake of consistency.

* Lines which start with "#" are ignored (use this for comments).

* Each (non-comment) line should contain exactly only one tab.

* The first column should be in the same format as "Table.attribute", Even if it is view, give the ImpTable name and the names in for "attribute" should be the attribute names as named in the view of interest.

* For empty fields do not use special symbols (like NA or similar), just leave that field empty or delete this line.

* If a line of the Template does not apply to your situation,  you do not have to enter it in your configuration file.

* In case the Template does not include the attribute required by your array design and is in RAD schema,  you can add it in your configuration file.

* You can have mutiple entries for annotation tables such as ArrayDesignAnnotation, ElementAnnotation and CompositeAnnotation table. The number after annotation table name denotes each entry. For example, ArrayDesignAnnotation1.name and ArrayDesignAnnotation1.value. And the name attribute for annotation table should be provided as value and value attribute for annotation table as header.

*  For each row, only one of VALUE and HEADER can be given. If the value of a particular table attribute is constant for all data lines, enter that in the second column. Else, if the value has to be taken from the data file, put in the second column the name of the data file column containing that value (the names under second column should be identical, case and all, to how they appear in the data file). But for external_database_release_id and element_type_id, always provide them as HEADER even if they are constant for all elements.

* Please make sure that the column in your data file to which external_database_release_id is mapped, if present (which in most cases should be), contains valid SRes.ExternalDatabaseRelease.ext_db_ids. If this is not the case, you will need to re-parse your data file, as the plug-in will not insert any row with an invalid external_database_release_id, when this is present.

* It is crucial that the attributes of CompositeElememtImp that you are listing are such that each CompositeElement in your data file is uniquely identified by those attributes. For spotted array case, if one of the attributes listed should be present in each spot family and uniquely identifies a spot family (e.g. a well id might do this), make that attribute mandatory in your configuration file.

* It is also very important for shortOligo array, the name attribute for each shortOligoFamily should be unique, since the plugin will cache the name attribute of each shortOligoFamily and all shortOligoFamily with same name will be loaded into database once.

* The control.subclass_view is the name of the view of either RAD.ElementImp or RAD.CompositeElementImp to which Control.table_id should point for every control loaded in this run. If the controls refer to elements on the array, the subclass_view should be the name of view of RAD.ElementImp. If the controls refer to CompositeElements on the array, the subclass_view should be the name of view of RAD.CompositeElementImp.

=head2 F<data_file>

The file contains the values for attributes in ElementImp, CompositeElementImp, ElementAnnotation and CompositeElementAnnotation. The data file should be in tab-delimited text format with one header row and a row for each element. All rows should contain the same number of tabs/fields.

* Every element for which an external_database_release_id and source_id are available should have these stored in the database. You will need to have two columns in the data file one for each of these two fields.

* Empty lines in the data files are ignored. All quotes within a data line are removed by the plug-in.
Please double-check that your data file has no inconsistencies before loading the data. If a column in your data file contains information which should be separated and stored into different table/view attributes, you will need to re-parse your file and separate this information into different columns before running the plug-in. Similarly, if information from different columns of your data file refers to one table/view attribute, you will need to re-parse your data file and merge this information into one column.

=head1 AUTHOR

Written by Junmin Liu.

=head1 COPYRIGHT

Copyright Junmin Liu, Trustees of University of Pennsylvania 2005. 
NOTES

my $documentation = {purpose=>$purpose, purposeBrief=>$purposeBrief, tablesAffected=>$tablesAffected, tablesDependedOn=>$tablesDependedOn, howToRestart=>$howToRestart, failureCases=>$failureCases, notes=>$notes};

my $argsDeclaration  =
  [
   fileArg({name => 'cfg_file',
	    descr => 'The full path of the cfg_file.',
	    constraintFunc=> undef,
	    reqd  => 1,
	    isList => 0,
	    mustExist => 1,
	    format => 'See the NOTES for the format of this file'
	   }),
   fileArg({name => 'data_file',
	    descr => 'The full path of the data_file.',
	    constraintFunc=> undef,
	    reqd  => 1,
	    isList => 0,
	    mustExist => 1,
	    format => 'See the NOTES for the format of this file'
	   }),
   stringArg({name  => 'technology_type',
	       descr => 'Array technology type, the value attribute of the entry in ontologyentry table.',
	       constraintFunc=> undef,
	       reqd  => 1,
	       isList => 0
	      }),
   integerArg({name  => 'manufacturer_id',
	       descr => 'RAD array manufacturer id, the entry in GUS::Model::SRes::Contact table.',
	       constraintFunc=> undef,
	       reqd  => 0,
	       isList => 0
	      }),
   stringArg({name  => 'manufacturer',
	       descr => 'The name,first name and last name of the manufacturer as they appear in the entry in GUS::Model::SRes::Contact table.',
	       constraintFunc=> undef,
	       reqd  => 0,
	       isList => 1
	      }),
   stringArg({name  => 'substrate_type',
	       descr => 'Array substrate type, the value attribute of the entry in ontologyentry table.',
	       constraintFunc=> undef,
	       reqd  => 0,
	       isList => 0
	      }),
   integerArg({name  => 'protocol_id',
	       descr => 'RAD array protocol id, the entry in protocol table.',
	       constraintFunc=> undef,
	       reqd  => 0,
	       isList => 0
	      }),
   integerArg({name  => 'testnumber',
	       descr => 'optional, number of iterations for testing',
	       constraintFunc=> undef,
	       reqd  => 0,
	       isList => 0
	      }),
   integerArg({name  => 'restart',
	       descr => 'optional,data file line number to start loading data from(start counting after the header)',
	       constraintFunc=> undef,
	       reqd  => 0,
	       isList => 0
	      }),
   booleanArg({name  => 'noWarning',
	       descr => 'if specified, generate no warning messages',
	       constraintFunc=> undef,
	       reqd  => 0,
	       isList => 0,
	       default => 0
	      })
  ];

  $self->initialize({requiredDbVersion => '3.5',
		     cvsRevision => '$Revision$',
#		     cvsTag => '$Name$',
		     name => ref($self),
		     revisionNotes => 'make consistent with GUS 3.5',
		     argsDeclaration => $argsDeclaration,
		     documentation => $documentation
		    });
# return the new object
  return $self;
}

# Global variable
my $cfg_rv;
my $cfg_rv_rev;

sub run {
  my $M   = shift;
  $M->logAlgInvocationId();
  $M->logArgs;
  $M->logCommit;
  $M->setOk(1);

  my $RV;

# self-defined subroutine, check the command line arguments
#  
  $M->checkArgs(); 

# self-defined subroutine
# stores in a hash the mapping of table/view attributes to data file columns 
  $M->readCfg();

# require the elementimp and compositeelementimp view objects at running time  
  eval "require GUS::Model::RAD::$cfg_rv->{'mapping'}->{'CompositeElementImp.subclass_view'}";
  eval "require GUS::Model::RAD::$cfg_rv->{'mapping'}->{'ElementImp.subclass_view'}";

# self-defined subroutine, check the configuration file if it provide the 
# value or header for non-nullable attributes
#  
  $M->checkCfg(); 

# self-defined subroutine, update the ArrayDesign table, assuming ArrayDesign.name is provided in configuration file
#
  $M->workOnArrayDesign();

# self-defined subroutine, update the ArrayDesignAnnotation table
#
  if(defined $cfg_rv->{'arrayannotation_index'}){
      $M->workOnArrayDesignAnnotation();
  }

# self-defined subroutine, check the headers of data file if it provide the 
# header matching with them provide in configuration file
#
  my $fh=new IO::File;
  my $fileName=$M->getCla->{'data_file'};
    unless ($fh->open("<$fileName")) {
	$M->error("Cannot open file $fileName for reading.");
  }
   $M->parseHeader($fh);
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
    my @attributesToNotRetrieve = ('modification_date', 'row_alg_invocation_id');
  if (!defined $M->getArgs->{'data_file'}) {
    $RV = join(' ','a --data_file <datafilename> must be on the commandline', $M->getArgs->{'data_file'}); 
    $M->userError($RV);
  }

  if (!defined $M->getArgs->{'cfg_file'}) {
    $RV = join(' ','a --cfg_file <cfgfilename> must be on the commandline', $M->getArgs->{'data_file'});
    $M->userError($RV);
  }

  if (!defined $M->getArgs->{'technology_type'}) {
      $RV = join(' ','a --technology_type <technology type> must be on the commandline', $M->getArgs->{'technology_type_id'});
      $M->userError($RV);
  }
  else{
# check that the given technology_type_id is a valid one
    eval "use GUS::Model::Study::OntologyEntry;";
    my $oeHash;
    $oeHash->{category}="TechnologyType";
    $oeHash->{value}=$M->getArgs->{'technology_type'};
    my $oe = GUS::Model::Study::OntologyEntry->new($oeHash);
    if ($oe->retrieveFromDB(\@attributesToNotRetrieve)) {
      $cfg_rv->{'mapping'}->{'ArrayDesign.technology_type_id'}=$oe->getId();
      $M->log("Status find the array technology_type_id ", $cfg_rv->{'mapping'}->{'ArrayDesign.technology_type_id'});
    }
    else{
      $RV = join(' ','could not find unique technology_type_id for', $M->getArgs->{'technology_type'});
      $M->userError($RV);
    }
#      $M->checkId('Study', 'OntologyEntry', 'ontology_entry_id', $M->getArgs->{'technology_type_id'}, 'technology_type_id');
  }

  if (defined $M->getArgs->{'substrate_type'}){
#      $M->checkId('Study', 'OntologyEntry', 'ontology_entry_id', $M->getArgs->{'substrate_type_id'}, 'substrate_type_id');
    eval "use GUS::Model::Study::OntologyEntry;";
    my $oeHash;
    $oeHash->{category}="SubstrateType";
    $oeHash->{value}=$M->getArgs->{'substrate_type'};
    my $oe = GUS::Model::Study::OntologyEntry->new($oeHash);
    if ($oe->retrieveFromDB(\@attributesToNotRetrieve)) {
      $cfg_rv->{'mapping'}->{'ArrayDesign.substrate_type_id'}=$oe->getId();
      $M->log("Status find the array substrate_type_id ", $cfg_rv->{'mapping'}->{'ArrayDesign.substrate_type_id'});
    }
    else{
      $RV = join(' ','could not find unique substrate_type_id for', $M->getArgs->{'substrate_type'});
      $M->userError($RV);
    }
  }

    if (!defined $M->getArgs->{'manufacturer_id'} && !defined $M->getArgs->{'manufacturer'}) {
      $RV = join(' ','a --manufacturer_id <manufacturer id> or --manufacturer <name,first,last> must be on the commandline', $M->getArgs->{'manufacturer_id'});
      $M->userError($RV);
    }
    elsif(defined $M->getArgs->{'manufacturer_id'}){
      $M->checkId('SRes', 'Contact', 'contact_id', $M->getArgs->{'manufacturer_id'}, 'manufacturer_id');
    }
    else{
      eval "use GUS::Model::SRes::Contact;";
      my $contactHash;
      if(defined $M->getArgs->{'manufacturer'}->[0])  {  $contactHash->{name}=$M->getArgs->{'manufacturer'}->[0];}
      if(defined $M->getArgs->{'manufacturer'}->[1])  {  $contactHash->{first}=$M->getArgs->{'manufacturer'}->[1];}
      if(defined $M->getArgs->{'manufacturer'}->[2])  {  $contactHash->{last}=$M->getArgs->{'manufacturer'}->[2];}
      my $manufacturer = GUS::Model::SRes::Contact->new($contactHash);
      if ($manufacturer->retrieveFromDB(\@attributesToNotRetrieve)) {
	$cfg_rv->{'mapping'}->{'ArrayDesign.manufacturer_id'}=$manufacturer->getId();
	$M->log("Status find the array manufacturer_id ", $cfg_rv->{'mapping'}->{'ArrayDesign.manufacturer_id'});
      }
      else{
	$RV = join(' ','could not find unique manufacturer_id ');
	$M->userError($RV);
      }
    }

  if (defined $M->getArgs->{'protocol_id'}){
    $M->checkId('RAD', 'Protocol', 'protocol_id', $M->getArgs->{'protocol_id'}, 'protocol_id');
  }

    $M->log('STATUS', 'OK   Finished checking command line arguments');
}

sub checkId{
    my $M = shift;
    my $RV;
    my ($database, $tablename, $pkname, $id, $claname)=@_;

    my $object=lc($tablename);
    my $Object=join('::', "GUS", "Model", $database, $tablename);
    my $object = $Object->new({$pkname=>$id});
    if (!$object->retrieveFromDB()) {
      $RV = join(' ','a VALID --', $claname, 'must be on the commandline', $claname, '=',$M->getArgs->{$claname});
      $M->userError($RV);
    }
}

sub readCfg{
  my $M = shift;
  my $file = $M->getArgs->{'cfg_file'};
  my $RV="";

  my $fh = new IO::File;
  unless ($fh->open("<$file")) {
      $RV = join(' ','Cannot open configuration file', $M->getArgs->{'cfg_file'});
      $M->userError('ERROR', $RV);
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
	$cfg_rv_rev->{$arr[1]} = $arr[0];
	if ($arr[0] =~ /^ElementAnnotation(\d+)\.value$/) {
	  $cfg_rv->{'elementannotation_index'}->{$1} = 1;
	}
	if ($arr[0] =~ /^CompositeElementAnnotation(\d+)\.value$/) {
	  $cfg_rv->{'compositeelementannotation_index'}->{$1} = 1;
	}
	if ($arr[0] =~ /^ArrayDesignAnnotation(\d+)\.value$/) {
	  $cfg_rv->{'arrayannotation_index'}->{$1} = 1;
	}
      }
    }
  }
  $fh->close();
  $RV = join('OK ','Finish reading configuration file', $M->getArgs->{'cfg_file'});
  $M->log('Status', $RV);

}


# get the attribute list for a given table
sub getAttrArray(){
  my $M = shift;
  my ($table_name)=@_;
  my @attr_array;
  my $RV="";
  # get the DbiDb and then the DbiTable 
  my $extent=$M->getDb->getTable($table_name);
  if (not defined($extent)){
    $RV = join(' ','Cannot get the Dbidatabase or DbiTable', $table_name);
    $M->userError($RV);
  }
  

  return @{$extent->getAttributeList()};

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
    my $RV="";
# get the DbiDb and then the DbiTable
    my $extent=$M->getDb->getTable($table_name);
    if (not defined($extent)){
	$RV = join(' ','Cannot get the DbiDatabase or DbiTable', $table_name);
	$M->userError($RV);
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

    my $RV="";
    my $missed=0;
# get the nullability of each attribute except primary key, foreign keys and those common attributes
    my $attr_hash=$M->getAttrHashRef($view_name);
    if(!defined $attr_hash){
	$RV = join(' ','Cannot retrive the attribute info of', $view_name);
	$M->userError($RV);
    }

    foreach my $key (keys %$attr_hash){
      my $cfg_key=join('.', $table_name, $key);
      if( $attr_hash->{$key} =~ /^Not Nullable$/) {
	if(!defined ($cfg_rv->{'mapping'}->{$cfg_key}) )
	  {
	    $missed=1;
	    $RV .="$cfg_key, ";
	  }
      }
    }
    if ($missed){
      $RV .=" missing in configuration file";
      $M->userError($RV);
    }
}


sub checkCfg(){
    my $M = shift;
    my $RV="";
# for ArrayDesign table
    $M->checkMandatory('RAD', 'ArrayDesign');

# for ArrayDesignAnnotation table
    if(defined $cfg_rv->{'arrayannotation_index'}){
	foreach my $m (keys (%{$cfg_rv->{'arrayannotation_index'}})) {
	    if (!defined($cfg_rv->{'mapping'}->{'ArrayDesignAnnotation'.$m.'.name'}) || !defined($cfg_rv->{'mapping'}->{'ArrayDesignAnnotation'.$m.'.value'})) {
		$RV="You must provide ArrayDesignAnnotation$m.name and ArrayDesignAnnotation$m.value in your configuration file.\n";
		$M->userError($RV);	
            }
	}
    }    
# for ElementImp table
    if(defined $cfg_rv->{'mapping'}->{'ElementImp.subclass_view'}){
      my $subclass_view=$cfg_rv->{'mapping'}->{'ElementImp.subclass_view'};
      $M->checkMandatory('RAD', 'ElementImp', $subclass_view );
    }

# for CompositeElementImp table
    if(defined $cfg_rv->{'mapping'}->{'CompositeElementImp.subclass_view'}){
      my $subclass_view=$cfg_rv->{'mapping'}->{'CompositeElementImp.subclass_view'};
      $M->checkMandatory('RAD', 'CompositeElementImp', $subclass_view );
    }
# for ElementAnnotation table
    if(defined $cfg_rv->{'elementannotation_index'}){
	foreach my $m (keys (%{$cfg_rv->{'elementannotation_index'}})) {
	    if (!defined($cfg_rv->{'mapping'}->{'ElementAnnotation'.$m.'.name'}) || !defined($cfg_rv->{'mapping'}->{'ElementAnnotation'.$m.'.value'})) {

		$RV="You must provide ElementAnnotation$m.name and ElementAnnotation$m.value in your configuration file.\n";
		$M->userError($RV);
            }
	}
    }

# for CompositeElementAnnotation table
    if(defined $cfg_rv->{'compositeelementannotation_index'}){
	foreach my $m (keys (%{$cfg_rv->{'compositeelementannootation_index'}})) {
	    if (!defined($cfg_rv->{'mapping'}->{'CompositeElementAnnotation'.$m.'.name'}) || !defined($cfg_rv->{'mapping'}->{'CompositeElementAnnotation'.$m.'.value'})) {
	      $RV="You must provide CompositeElementAnnotation$m.name and CompositeElementAnnotation$m.value in your configuration file.\n";
	      $M->userError($RV);
            }
	}
    }

# for Control table
    if(defined $cfg_rv->{'mapping'}->{'Control.subclass_view'}){
	if(!defined $cfg_rv->{'mapping'}->{'Control.control_type_id'}){
	 $RV="You must provide Control.control_type_id in your configuration file.\n";
	 $M->userError($RV);
	}
    }

    $RV = join('OK ','Finish checking configuration file', $M->getArgs->{'cfg_file'});
    $M->log('Status', $RV);
}

sub workOnArrayDesign {
  my $M = shift;
  my @attributesToNotRetrieve = ('modification_date', 'row_alg_invocation_id');
  my $RV="";
#  $cfg_rv->{'mapping'}->{'ArrayDesign.technology_type_id'} = $M->getArgs->{'technology_type_id'};
#  if(defined $M->getArgs->{'substrate_type_id'} ){
#      $cfg_rv->{'mapping'}->{'ArrayDesign.substrate_type_id'} = $M->getArgs->{'substrate_type_id'};
#  }
  if(defined $M->getArgs->{'manufacturer_id'} ){
      $cfg_rv->{'mapping'}->{'ArrayDesign.manufacturer_id'} = $M->getArgs->{'manufacturer_id'};
  }

  if(defined $M->getArgs->{'protocol_id'}) {
      $cfg_rv->{'mapping'}->{'ArrayDesign.protocol_id'} = $M->getArgs->{'protocol_id'};
  }

  my $array_hash;
  my @array_attr=$M->getAttrArray('GUS::Model::RAD::ArrayDesign');

# the following will be module dependable or schema dependable
  my @array_key_attr=('name', 'version', 'technology_type_id', 'manufacturer_id');

  for (my $i=0; $i<@array_key_attr; $i++) {
   if(defined $cfg_rv->{'mapping'}->{'ArrayDesign.'.$array_key_attr[$i] }){
    $array_hash->{$array_key_attr[$i]} = $cfg_rv->{'mapping'}->{'ArrayDesign.'.$array_key_attr[$i]};
   }
  }
 my $array = GUS::Model::RAD::ArrayDesign->new($array_hash);
 my $new_entry = 1; 

 
  if ($array->retrieveFromDB(\@attributesToNotRetrieve)) {
#      print "retrieveFromDb1\n";
      my $string = $array->toString();
      print STDERR "There is already an entry in the ArrayDesign table with same name, version and technology_type_id:\n$string\nEnter \"OK\", if you want to use this entry as it is.\nEnter \"u\", if you want to update this entry with the information in your CfgFile.\nEnter \"n\", if you want to create a new entry.\n(In this case, read/write permissions will be as by default, unless you have set them in your CfgFile.)\nEnter \"q\" to exit now.\n"; 
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
	die "Result   User exit program. No table was affected.";
	return;
      }
      elsif ($input =~ /^OK$/) {
	$new_entry = 0;
	print STDERR "You entered \"OK\". The entry already in the database, without any updating, will be used.\n";
	$cfg_rv->{'ArrayDesign_Id'} = $array->getId();
	return;
      }
      elsif ($input =~ /^u$/) {
	$new_entry = 0;
	print STDERR "You entered \"u\". The entry currently in the database will be updated with the information in your CfgFile.\n";
	for (my $i=0; $i<@array_attr; $i++) {
	    my $index=join('', 'ArrayDesign', '.', $array_attr[$i]);
	  if (defined($cfg_rv->{'mapping'}->{$index})) {
	    $array->set($array_attr[$i], $cfg_rv->{'mapping'}->{$index});
	  }
	}
	$M->log('Result', 'One update in ArrayDesign tables.');
	$cfg_rv->{'ArrayDesign_Id'} = $array->getId();
	return;
      }
      else {
	print STDERR "You entered \"n\". A new entry will be created.\n";
      }
  }
 
  my $prod = 1;
  my $counter=0;
  if (defined($cfg_rv->{'mapping'}->{'ArrayDesign.num_array_rows'})) {
    $prod *= $cfg_rv->{'mapping'}->{'ArrayDesign.num_array_rows'};
    $counter++;
  }
  if (defined($cfg_rv->{'mapping'}->{'ArrayDesign.num_array_columns'})) {
    $prod *= $cfg_rv->{'mapping'}->{'ArrayDesign.num_array_columns'};
    $counter++;
  }
  if (defined($cfg_rv->{'mapping'}->{'ArrayDesign.num_grid_rows'})) {
    $prod *= $cfg_rv->{'mapping'}->{'ArrayDesign.num_grid_rows'};
    $counter++;
  }	
  if (defined($cfg_rv->{'mapping'}->{'ArrayDesign.num_grid_columns'})) {
    $prod *= $cfg_rv->{'mapping'}->{'ArrayDesign.num_grid_columns'};
    $counter++;
  }
  if (defined($cfg_rv->{'mapping'}->{'ArrayDesign.num_sub_rows'})) {
    $prod *= $cfg_rv->{'mapping'}->{'ArrayDesign.num_sub_rows'};
    $counter++;
  }
  if (defined($cfg_rv->{'mapping'}->{'ArrayDesign.num_sub_columns'})) {
    $prod *= $cfg_rv->{'mapping'}->{'ArrayDesign.num_sub_columns'};
    $counter++;
  }
  if ($counter==6) {
    if ( defined($cfg_rv->{'mapping'}->{'ArrayDesign.number_of_elements'}) &&  $prod!=$cfg_rv->{'mapping'}->{'ArrayDesign.number_of_elements'}) {
      $M->userError('No table was touched because the number of elements you entered in your CfgFile does not match the array layout you entered.\nExiting the plug-in.\n');
    }
  }

  if($new_entry==1){
      for (my $i=0; $i<@array_attr; $i++) {
	  next if( (grep(/^$array_attr[$i]$/, @array_key_attr)) ); 
	  if (defined($cfg_rv->{'mapping'}->{'ArrayDesign.'.$array_attr[$i]})) {
	      $array_hash->{$array_attr[$i]} = $cfg_rv->{'mapping'}->{'ArrayDesign.'.$array_attr[$i]};
	  }
      }
      
      $array = GUS::Model::RAD::ArrayDesign->new($array_hash);
      if($M->getArgs->{'debug'}){
	  foreach my $key(keys %$array_hash){
	      print "$key\t$array_hash->{$key}\n";
	  }
      }
      $array->submit(undef, 1);
  }
# for debug
  if($M->getArgs->{'debug'}){
      $cfg_rv->{'ArrayDesign_Id'} = $array->getId();
      $RV="Finish update/insert ArrayDesign table.\tArrayDesign_Id:\t$cfg_rv->{'ArrayDesign_Id'}";
      $M->log('Debug', $RV);
  }
  elsif ( $array->getId() ) {
    $cfg_rv->{'ArrayDesign_Id'} = $array->getId();
    $RV ="OK Finish update/insert ArrayDesign table.\tArrayDesign_Id:\t$cfg_rv->{'ArrayDesign_Id'}";
    $M->log('Result', $RV);
  }
  else {
    $M->userError('No table was touched, as ArrayDesign entry could not be inserted/updated.');
  }
  return;
}


sub workOnArrayDesignAnnotation{
    my $M = shift;
    $M->setOk(1);
    my $RV="";
    my @arrayannotation_attr=$M->getAttrArray('GUS::Model::RAD::ArrayDesignAnnotation');
    my @arrayannotation_key_attr=('name', 'value');

  foreach my $m (keys (%{$cfg_rv->{'arrayannotation_index'}})) {
    my $arrayannotation_hash;
    $arrayannotation_hash->{'array_design_id'}= $cfg_rv->{'ArrayDesign_Id'};

    for (my $i=0; $i<@arrayannotation_key_attr; $i++) {

      my $index=join('', 'ArrayDesignAnnotation', $m, '.', $arrayannotation_key_attr[$i]);

      if (defined $cfg_rv->{'mapping'}->{$index}) {
	  print "$index\n";
	$arrayannotation_hash->{$arrayannotation_key_attr[$i]} = $cfg_rv->{'mapping'}->{$index};
      }
    }
    my $arrayannotation = GUS::Model::RAD::ArrayDesignAnnotation->new($arrayannotation_hash);
    my $new_entry = 1;
    my @attributesToNotRetrieve = ('modification_date', 'row_alg_invocation_id');
    if ($arrayannotation->retrieveFromDB(\@attributesToNotRetrieve)) {
      my $string = $arrayannotation->toString();
      print STDERR "There is already an entry in the ArrayDesignAnnotation table with same name, value and array_id:\n$string\nEnter \"OK\", if you want to use this entry as it is.\nEnter \"u\", if you want to update this entry with the information in your CfgFile.\nEnter \"n\", if you want to create a new entry.\n(In this case, read/write permissions will be as by default, unless you have set them in your CfgFile.)\nEnter \"q\" to exit now.\n"; 
      my $input=<STDIN>;
      chomp($input);
      until ($input =~ /^OK$/ || $input =~ /^u$/ || $input =~/^n$/ || $input=~ /^q$/) {
	print STDERR "You must enter one of \"OK\", \"u\", \"n\", or \"q\". Re-enter.\n";
	$input=<STDIN>;
	chomp($input);
      }
      
      if ($input=~ /^q$/) {
	print STDERR "You entered \"q\". Exiting the plug-in.\n";
	die "Result  Possible updates/inserts in ArrayDesign and ArrayDesignAnnotation tables. No other table was affected.";
      }
      elsif ($input =~ /^OK$/) {
	$new_entry = 0;
	print STDERR "You entered \"OK\". The entry already in the database, without any updating, will be used.\n";
      }
      elsif ($input =~ /^u$/) {
	$new_entry = 0;
	print STDERR "You entered \"u\". The entry currently in the database will be updated with the information in your CfgFile.\n";
	for (my $i=0; $i<@arrayannotation_attr; $i++) {
	    my $index=join('', 'ArrayDesignAnnotation', $m, '.', $arrayannotation_attr[$i]);
	  if (defined($cfg_rv->{'mapping'}->{$index})) {
	    $arrayannotation->set($arrayannotation_attr[$i], $cfg_rv->{'mapping'}->{$index});
	  }
	}
	$M->log('Result', 'OK One update in ArrayDesignAnnotation tables.');
	next;
      }
      else {
	print STDERR "You entered \"n\". A new entry will be created.\n";
      }
    }
    if ($new_entry==1) {
      for (my $i=0; $i<@arrayannotation_attr; $i++) {
	   next if( (grep(/^$arrayannotation_attr[$i]$/, @arrayannotation_key_attr)) ); 
	my $index=join('', 'ArrayDesignAnnotation', $m, '.', $arrayannotation_attr[$i]);
	if (defined($cfg_rv->{'mapping'}->{$index})) {
	  $arrayannotation_hash->{$arrayannotation_attr[$i]} = $cfg_rv->{'mapping'}->{$index};
	}
      }
      $arrayannotation = GUS::Model::RAD::ArrayDesignAnnotation->new($arrayannotation_hash);
      $arrayannotation->submit();
    }

# for debug
    if($M->getArgs->{debug}){
      $cfg_rv->{'arrayannotation_id'}->{$m} = $arrayannotation->getId();
      $RV="One insert into ArrayDesignAnnotation.\tarayannotation_id\t$cfg_rv->{'arrayannotation_id'}->{$m}\n";
      $M->logData('Debug', $RV);
    }
    elsif ($arrayannotation->getId()) {
      $cfg_rv->{'arrayannotation_id'}->{$m} = $arrayannotation->getId();
      $RV="OK One insert into ArrayDesignAnnotation.\tarayannotation_id\t$cfg_rv->{'arrayannotation_id'}->{$m}\n";
      $M->log('Result', $RV);
    }
    else {
      $M->userError('Possible updates/inserts in ArrayDesign and ArrayDesignAnnotation tables. No other table was affected, as some of the ArrayDesignAnnotation entries could note be inserted/updated.');
    }  

  } #end of foreach loop 
  return;
}

sub parseHeader{
  my  $M=shift;
  my ($fh) = @_;
  my %headers;
  my $is_header=0;
  my $line = "";
  while ($line =~ /^\s*$/) {
      last unless $line = <$fh>;
  }
  
  if($M->getArgs->{debug}){
      print "Headers $line\n";
  }
  my @arr = split (/\t/, $line);
  for (my $i=0; $i<@arr; $i++) {
      $arr[$i] =~ s/^\s+|\s+$//g;
      $arr[$i] =~ s/\"|\'//g;
      if ($headers{$arr[$i]}) {
	  $fh->close();
	  $M->userError("No two columns can have the same name in the data file header.");
      }
      else {
	  $headers{$arr[$i]} = 1;
      }

      if($is_header==0 && defined $cfg_rv_rev->{$arr[$i]}){
	  $is_header=1;
      }

      $cfg_rv->{'position'}->{$arr[$i]} = $i;

  }

  if($is_header==0){
      $M->userError("No header information in data file header.");
  }
  $cfg_rv->{'num_fields'} = scalar(@arr);
  $M->log('Status', 'OK Finish parse the headers of array data file');
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
   $cfg_rv->{num_control_inserts}=0;
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
#  my $statement2 = 'select ontology_entry_id from RAD.OnotologyEntry where category like %element type% and value like %?%';
#  my $sth2 = $dbh->prepare($statement2);

   my $n=0;  

   while ($line = <$fh>) {
    
     $n++;
     if ($n%200==0) {
	 $RV="OK Read $n datalines including empty line";
	 $M->log('Status', $RV);
	 if($M->getArgs->{'commit'}){
	     $RV = "Processed $n dataline, Inserted $num_inserts Elements and $num_spot_family CompositeElements."; 
	     $M->log("Status: OK $RV");
	 }
     }
#skip number of line as defined by user
     if (defined $M->getArgs->{'restart'} && $n<$M->getArgs->{'restart'}) {
	 next;
     }
#skip empty lines if any
     if ($line =~ /^\s*$/) {
	 next;
     }
#print out the data line
     if($M->getArgs->{debug}){
	 print "Debug\t$line\n";
     }
#stop reading data lines after testnumber of lines
     if (!$M->getArgs->{'commit'} && defined $M->getArgs->{'testnumber'} && $n-$M->getArgs->{'restart'}==$M->getArgs->{'testnumber'}+1) {
	 $n--;
	 $RV="stopping reading after testing $M->getArgs->{'testnumber'} lines";
	 $M->log('Result', "stopping reading after testing", $M->getArgs->{'testnumber'}, "lines");
	 last;
     }

     my @arr = split(/\t/, $line);
    
     if (scalar(@arr) != $cfg_rv->{'num_fields'}) {
	 $warnings = "The number of fields for data line $n does not equal the number of fields in the header.\nThis might indicate a problem with the data file.\nData loading is interrupted.\nData from data line $n and following lines were not loaded.\nHere $n is the number of lines (including empty ones) after the header.\n";   
	 $M->userError($warnings);
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
	 $spot_fam_hash->{'array_design_id'} = $cfg_rv->{'ArrayDesign_Id'};
	 $subview=$mapping->{'CompositeElementImp.subclass_view'};
	 $spot_fam_hash->{'subclass_view'} = $subview;
	 $subclassview=join('::', 'RAD', $subview); 
	 my @spot_fam_attr=$M->getAttrArray($subclassview);
	 my $spot_fam_attr_hashref=$M->getAttrHashRef($subclassview);

# build up the query for checking compisteElement id
	 if(defined $cfg_rv->{'compositeelementannotation_index'}){
	     my $avName;
	     $sql="select ce.composite_element_id from RAD.$subview ce, RAD.compositeElementAnnotation cea where ce.array_design_id=$cfg_rv->{'ArrayDesign_Id'} and ce.subclass_view=\'$subview\' and ce.composite_element_id=cea.composite_element_id";
 
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
	     $sql="select ce.composite_element_id from RAD.$subview ce where ce.array_design_id=$cfg_rv->{'ArrayDesign_Id'} and ce.subclass_view=\'$subview\'  ";
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
		 if($M->getArgs->{'commit'}){print STDERR "Warning: $RV\n";}
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
		     if($M->getArgs->{'commit'}){print STDERR "Warning: $RV\n";}
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
	     if($M->getArgs->{'commit'}){print STDERR "Warning: $RV\n";}
	     next; # skip this line
	 }   

	 my $spot_fam_view = $mapping->{'CompositeElementImp.subclass_view'};
	 my $SPOT_FAM_VIEW=join('::', "GUS", "Model", 'RAD', $spot_fam_view);
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
	     if(! $M->getArgs->{noWarning} ){
		 $M->logData('Warning', $RV) ;
	     }
	     if($M->getArgs->{'commit'} && ! $M->getArgs->{noWarning} ){
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
if(defined $cfg_rv->{'mapping'}->{'ElementImp.subclass_view'}){
     my $spot_hash;
     $subclassview=join('::', 'RAD',$mapping->{'ElementImp.subclass_view'}); 
     my @spot_attr=$M->getAttrArray($subclassview);
     my $spot_attr_hashref=$M->getAttrHashRef($subclassview);
#    my $idhash=$M->getCVNameToIdHash('element type');

     $spot_hash->{'array_design_id'} = $cfg_rv->{'ArrayDesign_Id'};

     $subview=$mapping->{'ElementImp.subclass_view'};
     $spot_hash->{'subclass_view'} = $subview;

# mapping element type to ontology entry id temporarily commented out
#     if (defined $mapping->{'ElementImp.element_type'}&& defined $pos->{$mapping->{'ElementImp.element_type'}} &&  $arr[$pos->{$mapping->{'ElementImp.element_type'}}] ne "") {
#	$spot_hash->{element_type_id} = $idhash->{$arr[$pos->{$mapping->{'ElementImp.element_type'}}]};
#      }

     for (my $i=0; $i<@spot_attr; $i++) {
       if(defined $mapping->{'ElementImp.'.$spot_attr[$i]}){
	 if (defined $pos->{$mapping->{'ElementImp.'.$spot_attr[$i]}} &&  $arr[$pos->{$mapping->{'ElementImp.'.$spot_attr[$i]}}] ne "") {
	     $spot_hash->{$spot_attr[$i]} = $arr[$pos->{$mapping->{'ElementImp.'.$spot_attr[$i]}}];
	   }
	 elsif(!defined $pos->{$mapping->{'ElementImp.'.$spot_attr[$i]}}){
	   $spot_hash->{$spot_attr[$i]}=$mapping->{'ElementImp.'.$spot_attr[$i]};
#	   print $spot_attr[$i],$spot_hash->{$spot_attr[$i]},"\n";
	 }
       }
#      if($spot_attr[$i] =~ /^element_type_id$/ )
#     $spot_hash->{'element_tye_id'}


	 if ($spot_attr_hashref->{$spot_attr[$i]}=~ /^"Not Nullable"$/ && !defined $spot_hash->{$spot_attr[$i]}) {
	     $warnings = "Data file line $n is missing attribute ElementImp.$spot_attr[$i], which is mandatory\nData from data line $n were not loaded.\nHere $n is the number of lines (including empty ones) after the header.\n\n";
	     $M->logData('Warning', $warnings);
	     $skip_line = 1;
	     if($M->getArgs->{'commit'}){print STDERR "Warning: $RV\n";}
	     last;
	 }
     }

     if ($skip_line) {
	 next;
     }

     my $spot_view = $mapping->{'ElementImp.subclass_view'};
     my $SPOT_VIEW=join('::', 'GUS', 'Model', 'RAD', $spot_view);

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
	     if(! $M->getArgs->{noWarning} ){
		 $M->logData('Warning', $RV);
	     }
	     if($M->getArgs->{'commit'} && ! $M->getArgs->{noWarning}){
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
	     if(! $M->getArgs->{noWarning}){
		 $M->logData('Warning', $RV);
	     }
	     if($M->getArgs->{'commit'} && ! $M->getArgs->{noWarning} ){
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
		 $composite_element_annotation=GUS::Model::RAD::CompositeElementAnnotation->new($composite_element_annotation_hash);
		 my @attributesToNotRetrieve = ('modification_date', 'row_alg_invocation_id');

		 if($composite_element_annotation->retrieveFromDB(\@attributesToNotRetrieve)){
		     $RV="Data line no. $n\tAlready existing an entry in CompositeElementAnnotation\tNo insert";
		     if(! $M->getArgs->{noWarning}){
			 $M->logData('Warning', $RV);
		     }
		     if($M->getArgs->{'commit'} && ! $M->getArgs->{noWarning}){
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
		 $element_annotation=GUS::Model::RAD::ElementAnnotation->new($element_annotation_hash);
		 if($element_annotation->retrieveFromDB(\@attributesToNotRetrieve)){
		     $RV="Data line no. $n\tAlready existing an entry in ElementAnnotation\tNo insert";
		     if(! $M->getArgs->{noWarning}){
			 $M->logData('Warning', $RV);
		     }
		     if($M->getArgs->{'commit'} && ! $M->getArgs->{noWarning}){
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

# work on control table
     if(defined $cfg_rv->{'mapping'}->{'Control.subclass_view'}){
	 my $view=$cfg_rv->{'mapping'}->{'Control.subclass_view'};
	 my $table_id=$M->getTable_Id($view);
	 my $row_id;
	 
	 if($view eq 'ShortOligo' || $view eq 'Spot'){
	     $row_id=$cfg_rv->{'Element_Id'};

	 }
	 if($view eq 'ShortOligoFamily' || $view eq 'SpotFamily'){
	     $row_id=$cfg_rv->{'CompositeElement_Id'};
	 }

	 if ( defined $pos->{$mapping->{'Control.control_type_id'}} && $arr[$pos->{$mapping->{'Control.control_type_id'}}] ne ""){
	     $M->updateControl($table_id, $row_id, @arr);
	 }
     }




     $num_inserts++;
#     $spot_family->undefPointerCache();

       $M->undefPointerCache();
 }#end of while loop


#   $dbh->disconnect();
   $RV="Total datalines read (after header): $n.";
   $M->logData('Result', $RV);
   if($M->getArgs->{'commit'}){print STDERR "Result: $RV\n";}
   $RV="Number of lines which have been inserted into database (after header): $num_inserts.";
   $M->logData('Result', $RV);
   if($M->getArgs->{'commit'}){print STDERR "Result: $RV\n";}
   $RV="Number of records which have been inserted into CompositeElementImp table (after header): $num_spot_family.";
   $M->logData('Result', $RV);
   if($M->getArgs->{'commit'}){print STDERR "Result: $RV\n";}   
   my $num_control=$cfg_rv->{num_control_inserts};
   $RV = "Processed $n dataline, Inserted $num_inserts Elements and $num_spot_family CompositeElements and $num_control Controls ."; 
   return $RV;
}

sub getTable_Id{
    my $M = shift;
    my ($table_name)=@_;
 #eval "require GUS::Model::RAD::$cfg_rv->{'mapping'}->{'CompositeElementImp.subclass_view'}";
  #eval "require GUS::Model::RAD::$cfg_rv->{'mapping'}->{'ElementImp.subclass_view'}";
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
	if($M->getArgs->{'commit'}){print STDERR "Error: Cann't retrieve table_id for subclass view $table_name\n";}
	$M->setOk(0);
    }
}

sub updateControl{
    my $M = shift;
    my ($table_id, $row_id, @arr)=@_;

    my $control_hash;
    my $pos=$cfg_rv->{'position'};
    my $mapping=$cfg_rv->{'mapping'};
    my $warnings;
    my $RV;
    my @attributesToNotRetrieve = ('modification_date', 'row_alg_invocation_id');     
    $control_hash->{'table_id'} = $table_id;
    $control_hash->{'row_id'} = $row_id;
  
    my @control_attr=$M->getAttrArray("GUS::Model::RAD::Control");
    my $control_hashref=$M->getAttrHashRef("GUS::Model::RAD::Control");
    for (my $i=0; $i<@control_attr; $i++) {
	my $attr;
	
	$attr="Control.$control_attr[$i]";
	
	if ( defined $pos->{$mapping->{$attr}} && $arr[$pos->{$mapping->{$attr}}] ne "") {
	    $control_hash->{$control_attr[$i]} = $arr[$pos->{$mapping->{$attr}}];
	}
	 if ( ($control_hashref->{$control_attr[$i]} =~ /^Not Nullable$/)  && !defined $control_hash->{$control_attr[$i]}) {
	     $warnings = "Data file line $cfg_rv->{n} is missing attribute Control.$control_attr[$i], which is mandatory.\nData from this data line were not loaded.\nHere $cfg_rv->{n} is the number of lines (including empty ones) after the header.\n\n";
	     $M->logData('Error', $warnings);
	     if($M->getArgs->{'commit'}){print STDERR "Error: $RV\n";}
	     return; 
	 }
     }

     my $CONTROL_VIEW=join('::', 'GUS', 'Model', 'RAD', 'Control');
     my $control = $CONTROL_VIEW->new($control_hash);
# check whether this row is already in the database
# if it is, get its primary key
     if ($control->retrieveFromDB(\@attributesToNotRetrieve)) {
	 $RV="Data line no. $cfg_rv->{n}\tAlready existing an entry in Control\tNo insert";
	 if(! $M->getArgs->{noWarning}){
	     $M->logData('Warning', $RV);
	 }
	 if($M->getArgs->{'commit'} && !$M->getArgs->{noWarning} ){
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
	     if($M->getArgs->{'commit'}){print STDERR "Warning: $RV\n";}
	 }
	 else{
	     $cfg_rv->{num_control_inserts}++;
	 }
     }
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

    my $q = $M->doSelect('select ontology_entry_id, name from RAD.OntologyEntry');

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

sub undoTables {
  my $M   = shift;

  return ('RAD.Control', 'RAD.ElementAnnotation', 'RAD.CompositeElementAnnotation', 'RAD.ElementImp', 'RAD.CompositeElementImp', 'RAD.ArrayDesignAnnotation', 'RAD.ArrayDesign');
}
1;

