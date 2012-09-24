# ----------------------------------------------------------
# LoadSimpleArrayResults.pm
#
# Loads data into ElementResultImp table (for cDNA data and 
# provided with element_id mapping info),
# CompositeElementResultImp table (for affymetrix data and 
# provided with composite_element_id mapping info)
#
# Mandatory inputs are quantification_id and the full path to the data file.
#
# Created: Monday Nov 3 2003
#
# junmin liu
#
# last modified on Dec. 8 2003
# Copied from the SimpleArrayResultLoader plugin from sanger cvs at Nov 3 2003
#   --to make it work with BatchArrayResultLoader
#
# $Revision$ $Date$ $ Author: Junmin $
# ----------------------------------------------------------
package GUS::Community::Plugin::LoadSimpleArrayResults;
@ISA = qw( GUS::PluginMgr::Plugin );

use strict;
use IO::File;
use CBIL::Util::Disp;
use GUS::PluginMgr::Plugin;
use GUS::Model::RAD::Quantification;
use GUS::Model::RAD::ArrayDesign;
use GUS::Model::RAD::ElementAnnotation;
use GUS::Model::Core::TableInfo;

sub new {
  my $Class = shift;
  my $self = {};
  bless($self,$Class); # configuration object...

# call required inherited initialization methods

  my $purposeBrief = 'Loads data into ElementResultImp, CompositeElementResultImp tables in RAD database. meanwhile it will set the value of result_table_id in Quantification table';

  my $purpose = <<PURPOSE;
This is a plug-in that loads array  (spotted microarray and oligonucleotide array) result data into ElementResultImp and CompositeElementResultImp table, meanwhile it will set the value of result_table_id in Quantification table.
PURPOSE

  my $tablesAffected = [['RAD::ElementResultImp', 'Enters the results of this ElementResult here'], ['RAD::CompositeElementResultImp', 'Enters the results of this CompositeElementResult here']];

  my $tablesDependedOn = [['RAD::Array', 'The array used in the hybridization whose quantification result file is being loaded'], ['RAD::Quantification', 'The quantifiction whose result file is being loaded' ]]; 

  my $howToRestart = <<RESTART;
Loading can be resumed using the I<--restart n> argument where n is the line number in the data file of the first row to load upon restarting (line 1 is the first line after the header, empty lines are counted).
RESTART

  my $failureCases = <<FAILURE_CASES;
FAILURE_CASES

  my $notes = <<NOTES;

=head1 NOTES

Before you can run this plug-in you need to create the Perl objects for the views you will be loading, should these objects not exist yet. Based on the "build" system, this will involve two steps. First, check out the RAD, CBIL, GUS and Install modules from the cvs repository; secondly, build the GUS_HOME which the Perl objects reside in.

The plug-in outputs a print statement to STDOUT (for possible redirection to a log file) which lists the number of data file lines read (counting empty lines, but not counting the header and the lines preceding it in the data file) and any warning statement(s) regarding data lines which have not been loaded into RAD3.

Make sure that the F<.gus.properties> file of the user contains the correct login name [RADrw]. Also, if the group and project differ from the default values in F<.gus.properties>, I<please specify the proper group and project name on the command line using --group and --project options respectively>. 

B<I<array_id>> [Mandatory]

The array used in the hybridization whose quantification result file is being loaded. Set value of the ElementImp.array_id in order to determine the element_id and composite_element_id. 

B<I<quantification_id>> [Mandatory]

The quantification_id (in RAD.Quantification) of the quantifiction whose result file is being loaded. For Affymetrix platform, this will be the quantification associated with the chp data.

B<I<array_subclass_view>> [Optional]

being used for determining the element_id and composite_element_id

B<I<result_subclass_view>> [Optional]

 being used for updating ElementResultImp/CompositeElementResultImp table, this is one of the subclass_views of ElementResultImp/CompositeElementResultImp table which the result file is being loaded into.

B<I<rel_quantification_id>> [Optional]

must be provided when associated channel data is loaded. set value of  the ElementImp.quantification_id and CompositeElementImp.quantification_id for the associated channel.

B<I<log_path>> [Optional]

the directory where the plugin writes its log files in. default will be the current directory the plugin runs.

B<I<posOption>>  [optional]

to be used when sublass_view is set to "ShortOligoFamily", to specify what the data_file uses as probe-set identifier: set to 1 if "name" is used, set to 2 if the pair (external_database_release_id, and source_id) is used, set to 3 if the triplet (name, external_database_release_id and source_id) is used.

B<I<debug>>
    Debugging output.

B<I<help>>
    Get usage; same as usage.

B<I<verbose>>
    Lots of output.

B<I<commit>>
    Commit the data to database.

B<I<testnumber>>
    Number of iterations for testing (B<in non-commit mode only>).

B<I<restart>>
    data file line number to start loading data from (start counting after the header)

B<I<user>>
    The user name, used to set value for row_user_id. The user must already be in Core::UserInfo table. [Default: from .gus.properties file]

B<I<group>> 
    The group name, used to set value for row_group_id. The group must already be in Core::GroupInfo table. [Default: from .gus.properties file]

B<I<project>> 
    The project name, used to set value for row_project_id. The project must already be in Core::ProjectInfo table. [Default: from .gus.properties file]

=head2 F<data_file>

The data file should be in tab-delimited text format with one header row and a row for each element. All rows should contain the same number of tabs/fields.

* The header contains a list of attributes, which can be divided into two categories. One is position attributes which is used to identify the location of each element in array or compositeElement identifier such as probe set name. The other is view attributes which is defined in the view of ElementResultImp and CompositeElementResultImp.

* All attributes in the header should be small case. View attributes should be the same as defined in the views of interest.

* Every element for which the position attributes are available should have these stored in the database in order to determine the element_id and/or composite_element_id.

* Depending on array platform, the position attributes are different. If  the command line argument "subclass_view" is set to "Spot", then position attributes will be array_row, array_column, grid_row, grid_column, sub_row and sub_column. If the command line argument "subclass_view" is set to "ShortOligoFamily", then position attributes will be dependant on the posOption as described in the following paragraph. You will need to have these columns in the data file for each row.

* If you only load the compositeElementResult for affymetrix data, you have option to use probe set identifier to set the composite_element_id. First, set command line argument "subclass_view" to "ShortOligoFamily", second, use the "posOption" to set the probe set identifier, its default is 1, which uses "name" as the probe set identifier; 2 means using "external_database_release_id"and "source_id" as the probe set identifier; 3 means using "external_database_release_id", "source_id" and "name" as the probe set identifier.

* If the data file contains two-channel array data, then you can use "R.attributeName" and "G.attributeName" to denote each channel data.

* Empty lines in the data files are ignored. All quotes within a data line are removed by the plug-in.

* If any values in data file larger than the maximum value or smaller than minimum value that corresponding field in database allows, then the plugin will reset the value to maximum or minimum value of that field.

Please double-check that your data file has no inconsistencies before loading the data. If a column in your data file contains information which should be separated and stored into different table/view attributes, you will need to re-parse your file and separate this information into different columns before running the plug-in. Similarly, if information from different columns of your data file refers to one table/view attribute, you will need to re-parse your data file and merge this information into one column.

=head1 AUTHOR
Written by Junmin Liu.
=head1 COPYRIGHT
Copyright Trustees of University of Pennsylvania 2003.

NOTES

my $documentation = {purpose=>$purpose, purposeBrief=>$purposeBrief,tablesAffected=>$tablesAffected,tablesDependedOn=>$tablesDependedOn,howToRestart=>$howToRestart,failureCases=>$failureCases,notes=>$notes};

# modify the following line to add a new view for ElementResultImp/CompositeElementResultImp table
  my @rSubclassViewList=[qw (ArrayVisionElementResult GenePixElementResult SpotElementResult ScanAlyzeElementResult AffymetrixCEL GEMToolsElementResult AffymetrixMAS4 AffymetrixMAS5 MOIDResult)];

# modify the following line to add a new view for ElementImp/CompositeElementImp table
  my @aSubclassViewList=[qw (Spot ShortOligoFamily)];

  my @posOption=(1, 2, 3);

  my $argsDeclaration  =
    [
     stringArg({name => 'array_subclass_view',
		descr => 'The name of the view of RAD3.ElementImp/RAD3.CompositeElementImp.',
		constraintFunc=> undef,
		reqd => 1,
		isList => 0
	       }),
     integerArg({name  => 'posOption',
		 descr => 'option choice of positionList of ShortOligoFamily table, default is 1.',
		 constraintFunc=> undef,
		 reqd  => 0,
		 isList => 0,
		 default => 1,
		}),
     stringArg({name => 'result_subclass_view',
		descr => 'The name of the view of RAD3.ElementResultImp/RAD3.CompositeElementResultImp.',
		constraintFunc=> undef,
		reqd => 1,
		isList => 0
	       }),

     stringArg({name => 'log_path',
		descr => 'The directory where the plugin writes log file in. default is current directory the plugin runs',
		constraintFunc=> undef,
		reqd => 0,
		isList => 0
	       }),
     integerArg({name  => 'quantification_id',
		 descr => 'The RAD3 quantification id, the entry in Quantification table.',
		 constraintFunc=> undef,
		 reqd  => 1,
		 isList => 0
		}),
     integerArg({name  => 'rel_quantification_id',
		 descr => 'optional, for associated channel, RAD3 quantification id, the entry in Quantification table.',
		 constraintFunc=> undef,
		 reqd  => 0,
		 isList => 0
		}),

     integerArg({name  => 'array_design_id',
		 descr => 'The RAD array design id, the entry in ArrayDesign table.',
		 constraintFunc=> undef,
		 reqd  => 1,
		 isList => 0
		}),
     integerArg({name  => 'testnumber',
		 descr => 'optional, The number of data lines to read when testing this plugin. Not to be used in commit mode.',
		 constraintFunc=> undef,
		 reqd  => 0,
		 isList => 0
		}),
     integerArg({name  => 'restart',
		 descr => 'optional, Line number in data_file from which loading should be resumed (line 1 is the first line after the header, empty lines are counted).',
		 constraintFunc=> undef,
		 reqd  => 0,
		 isList => 0
		}),
     fileArg({name => 'data_file',
	      descr => 'The name of the data file (give full path).',
	      constraintFunc=> undef,
	      reqd  => 1,
	      isList => 0,
	      mustExist => 1,
	      format => 'See the NOTES for the format of this file'
	     })
    ];

  $self->initialize({requiredDbVersion => 3.5,
		     cvsRevision => '$Revision$',
		     name => ref($self),
		     revisionNotes => '',
		     argsDeclaration => $argsDeclaration,
		     documentation => $documentation
		    });
# return the new object
	return $self;
}

# Global variable
my $cfg_rv;
my @positionList;

sub run {
  my $M   = shift;
  $M->setOk(1);

  my $RV;

# self-defined subroutine, open log file handles
#
  my $filePath=".";
  if(defined $M->getCla->{log_path}){
    $filePath =$M->getCla->{log_path};
  }


  my $prefix=$M->getCla->{quantification_id};
  if(defined $M->getCla->{rel_quantification_id}){
    $prefix .="_";
    $prefix .=$M->getCla->{rel_quantification_id};
  }

  my $errorFileName =$prefix."_AR_errors.log";
  my $error_fh=new IO::File;
  unless ($error_fh->open(">$filePath/$errorFileName")) {
	$M->log('ERROR', "Cannot open data file $filePath/$errorFileName for writing.");
	return -1;
  }

  my $warningFileName =$prefix."_AR_warnings.log";
  my $warning_fh=new IO::File;
  unless ($warning_fh->open(">$filePath/$warningFileName")) {
	$M->log('ERROR', "Cannot open data file $filePath/$warningFileName for writing.");
	return -1;
  }

  my $statusFileName =$prefix."_AR_status.log";
  my $status_fh=new IO::File;
  unless ($status_fh->open(">$filePath/$statusFileName")) {
	$M->log('ERROR', "Cannot open data file $filePath/$statusFileName for writing.");
	return -1;
  }

  my $resultFileName =$prefix."_AR_result.log";
  my $result_fh=new IO::File;
  unless ($result_fh->open(">$filePath/$resultFileName")) {
	$M->log('ERROR', "Cannot open data file $filePath/$resultFileName for writing.");
	return -1;
  }

# require the elementimp and compositeelementimp view objects at running time
  eval "require GUS::Model::RAD::$M->getCla->{'array_subclass_view'}";
  eval "require GUS::Model::RAD::$M->getCla->{'result_subclass_view'}";

# set the global array $positionList and require the view for CompositeElementImp at running time
  if($M->getCla->{array_subclass_view} eq 'ShortOligoFamily'){
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

  if($M->getCla->{array_subclass_view} eq 'Spot'){
    if( $M->getCla->{posOption} == 1){
      @positionList = ('array_row','array_column','grid_row','grid_column','sub_row','sub_column');
    }
    if( $M->getCla->{posOption} == 2){
      @positionList = ('name');
    }
    if( $M->getCla->{posOption} == 3){
      $M->userError("posOption [3] Not Supported For 'Spot' Data");
    }
  }



# self-defined subroutine, open a file handle
#
  my $fh=new IO::File;
  my $fileName=$M->getCla->{'data_file'};
    unless ($fh->open("<$fileName")) {
      print $error_fh "Error\tCannot open data file $fileName for reading.\n";
      return 0;
  }

# self-defined subroutine, get the head and individual field position
#
  $M->parseHeader($fh);
  print $status_fh "STATUS\tfinished parsing the headers of array data file\n";

# self-defined subroutine, check the headers in data file if it provide the 
# required attributes
#
  $M->checkHeader($error_fh);
  return unless $M->getOk();
  print $status_fh "STATUS\tfinish checking the headers of array data file\n";

# self-defined subroutine, update ResultTableId in quantification table
#
#
  $M->updateResultTableId($error_fh);
  return unless $M->getOk();
  print $status_fh "STATUS\tfinish updating Result_Table_Id in quantification table\n";

# self-defined subroutine, load the data
#
#
  $RV = $M->loadData($fh, $error_fh, $warning_fh, $status_fh, $result_fh);

  $fh->close();
  $error_fh->close();
  $warning_fh->close();
  $status_fh->close();
  $result_fh->close();

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

  my @arr = split (/\t/, $line);

  for (my $i=0; $i<@arr; $i++) {
    $arr[$i] =~ s/^\s+|\s+$//g;
    $arr[$i] =~ s/\"|\'//g;
    $cfg_rv->{'position'}->{$arr[$i]} = $i;
  }

  $cfg_rv->{'num_fields'} = scalar(@arr);

}

sub checkHeader{
    my $M=shift;
    my ($error_fh)=@_;
    $M ->setOk(1);
    my $RV;
    foreach my $arr (@positionList){
	if (! defined $cfg_rv->{'position'}->{$arr}){
	    $RV = "ERROR\tMissing header $arr in the data file which is required to define one element/compositeElement.\n";
	    print $error_fh  $RV;
	    $M ->setOk(0);
	    return;
	}
    }
}




sub loadData{
   my $M=shift;
   my ($fh, $error_fh, $warning_fh, $status_fh, $result_fh)=@_;
   $M->setOk(1);
   my $RV;

# holds current number of rows inserted into ElementResultImp/CompositeElementResultImp
   $cfg_rv->{num_inserts} = 0;
# holds the warnings
   $cfg_rv->{warnings} = "";
# the line being read including the emptry lines
   my $line;
# holds the current number of rows being read including the emptry lines
   $cfg_rv->{n} = 0;
# set all parameters
   my $array_id = $M->getCla->{array_design_id};
   my $array_subclass_view = $M->getCla->{array_subclass_view};
   my $result_subclass_view = $M->getCla->{result_subclass_view};

   my $quantification_id = $M->getCla->{quantification_id};

   my $rel_quantification_id;
   if(defined $M->getCla->{rel_quantification_id}){
      $rel_quantification_id = $M->getCla->{rel_quantification_id};
   }
# default
   my $pk_name="element_id";
   if($M->getCla->{array_subclass_view} eq 'ShortOligoFamily'){
     $pk_name="composite_element_id";
    }
    if($M->getCla->{array_subclass_view} eq 'Spot'){
      $pk_name="element_id";
    }

  eval "require GUS::Model::RAD::$array_subclass_view";
  eval "require GUS::Model::RAD::$result_subclass_view";

# the hash mapping position attributes to ids of spot or shortoligoFamily
   my $posListToId;
   my $dbh = $M->getSelfInv->getQueryHandle();
   my $posList="";
   my $count=0;
   foreach my $pos(@positionList){
     if($count==0){
       $posList="$pos";
       $count++;
     }
     else{
       $posList .= ",";
       $posList .="$pos"; }
   }
   my $posSQL="select $posList, $pk_name from RAD.$array_subclass_view where array_design_id=$array_id";
   my $st = $dbh->prepare($posSQL) or die "SQL= $posSQL\n", $dbh->errstr;
   if($st->execute()){
     while (my $row = $st->fetchrow_hashref('NAME_lc')){
       my $counter=0;
       my $posStr;
       foreach my $pos(@positionList){
	 if($counter==0){
	   $posStr=$row->{$pos};
	   $counter++;
	 }
	 else{
	   $posStr .= ",";
	   $posStr .=$row->{$pos}; }
       }
       $posListToId->{$posStr}=$row->{$pk_name};
     }
   }


# for querying ElementImp table to set the element_id or composite_element_id
   my $arrayClass;
   $arrayClass="GUS::Model::RAD::$array_subclass_view";

   while ($line = <$fh>) {
     $cfg_rv->{n}++;
     if (($cfg_rv->{n})%200==0) {
	 $RV="STATUS\tRead $cfg_rv->{n} datalines including empty line\n";
	 print $status_fh $RV;
     }

# skip number of line as defined by user
     if (defined $M->getCla->{'restart'} && $cfg_rv->{n}<$M->getCla->{'restart'}) {
	 next;
     }
# skip empty lines if any
     if ($line =~ /^\s*$/) {
	 next;
     }

# stop reading data lines after testnumber of lines
     if (!$M->getCla->{'commit'} && defined $M->getCla->{'testnumber'} && $cfg_rv->{n}-$M->getCla->{'restart'}==$M->getCla->{'testnumber'}+1) {
	 $cfg_rv->{n}--;
	 my $stopNumber=$M->getCla->{'testnumber'};
	 $RV="RESULT\tstopping reading after testing $stopNumber lines\t";
	 print $result_fh $RV;
	 last;
     }

     my @arr = split(/\t/, $line);

# this will not happen since the parser will make sure of this, but I keep the
# code for now
#     if (scalar(@arr) != $cfg_rv->{'num_fields'}) {
#	 $RV = "WARNING\tThe number of fields for data line $cfg_rv->{n} does not equal the number of fields in the header.\nWARNING\tThis might indicate a problem with the data file.\nWARNING\tData loading is interrupted.\nWARNING\tData from data line $cfg_rv->{n} is not loaded.\nWARNING\tHere $cfg_rv->{n} is the number of lines (including empty ones) after the header.\n";   
#	 print $warning_fh $RV;
#	 next;
#     }

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
     my $posStrQuery;
     my $counter=0;
     foreach my $item(@positionList){
       if(defined $arr[$pos->{$item}]){
	 if($counter==0){
	   $posStrQuery=$arr[$pos->{$item}];
	   $counter++;
	 }
	 else{
	   $posStrQuery .= ",";
	   $posStrQuery .=$arr[$pos->{$item}]; }
       }
       else{

# this will not happen according to discussion
#	 $cfg_rv->{warnings} = "Data file line $cfg_rv->{n} is missing attribute ElementImp.$item, which is mandatory.\nData from this data line were not loaded.\nHere $cfg_rv->{n} is the number of lines (including empty ones) after the header.\n\n";
#	 $M->logData('Warning', $cfg_rv->{warnings});
	 
#	 if($M->getCla->{'commit'}){print STDERR "Warning: $RV\n";}
#	 $cfg_rv->{skip_line} = 1;
       }
     }

   next if ($cfg_rv->{skip_line} == 1); # skip this row

   if (defined $posListToId->{$posStrQuery}) {
     $cfg_rv->{spot_or_sf_id} = $posListToId->{$posStrQuery};
   }
   else{
#     $RV="Couldn't find the corresponding element_id for the data line no. $cfg_rv->{n}\tskip this\tNo insert";
#     print $warning_fh $RV;
#     $cfg_rv->{skip_line} = 1;
#     next; # skip this row
   }

# build a row for MAS5 or MAS4 resultImp
     if($array_subclass_view eq "ShortOligoFamily"){
       $M->updateSpotFamResult($warning_fh, @arr);
     }

# build a row for ElementResultImp
     if($array_subclass_view eq "Spot"){
       if(defined $M->getCla->{rel_quantification_id}){
	 $cfg_rv->{channel}='R';
	 $M->updateSpotResult($warning_fh, @arr);
	 $cfg_rv->{channel}='G';
	 $M->updateSpotResult($warning_fh, @arr);
       } 
       else{
	 $M->updateSpotResult($warning_fh, @arr);
       }
     }

     my $numOfLine=$cfg_rv->{n};

# reach the max 9000 objects, do clean up, but to be safe use 9000 instead
     if( ($numOfLine*5) % 9000 == 0 ) {$M->undefPointerCache();}

 }#end of while loop

#   $dbh->disconnect();
   $RV="RESULT\tTotal datalines read (after header): $cfg_rv->{n}.\n";
   print $result_fh $RV;
   my $total_insert;
   if($cfg_rv->{num_inserts}==0){
       $total_insert=$cfg_rv->{num_spot_family};
   }
   else{
       $total_insert=$cfg_rv->{num_inserts};
   }

   $RV = "Processed $cfg_rv->{n} dataline including empty lines. $total_insert records have been inserted into $result_subclass_view table (after header).";
   print $result_fh "RESULT\t$RV\n";

   return $RV;
}

sub updateResultTableId{
  my $M = shift;
  my ($error_fh)=@_;
  $M ->setOk(1);
  my $result_subclass_view = $M->getCla->{result_subclass_view};
  my $RV;
  my $t_id=$M->getTable_Id($result_subclass_view);
  my $quantification_id = $M->getCla->{quantification_id};
  if(!$M->updateQuantification($t_id, $quantification_id)){
    $RV = "ERROR\tCann't set result_table_id to $t_id for quantification id $quantification_id in quantification table.\n";
    print $error_fh  $RV;
    $M ->setOk(0);
    return;
  }

  my $rel_quantification_id;
  if(defined $M->getCla->{rel_quantification_id}){
    $rel_quantification_id = $M->getCla->{rel_quantification_id};

    if(!$M->updateQuantification($t_id, $rel_quantification_id)){
      $RV = "ERROR\tCann't set result_table_id to $t_id for quantification id $rel_quantification_id in quantification table.\n";
      print $error_fh  $RV;
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
  my $quan=GUS::Model::RAD::Quantification->new($quan_hash);
  $quan->retrieveFromDB();
  if( $quan->setResultTableId($result_table_id)){
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

sub updateSpotFamResult{
    my $M = shift;
    my ($warning_fh, @arr)=@_;
    my $pos=$cfg_rv->{position};
    my $spot_fam_hash;
    my $cr_subclass_view = $M->getCla->{result_subclass_view};
    my $warnings;
    my $RV;
    my @attributesToNotRetrieve = ('modification_date', 'row_alg_invocation_id');     
    $spot_fam_hash->{'subclass_view'} = $cr_subclass_view;
    $spot_fam_hash->{'composite_element_id'} = $cfg_rv->{spot_or_sf_id};
    
    if(defined $cfg_rv->{channel} && $cfg_rv->{channel} eq 'G'){
	$spot_fam_hash->{'quantification_id'} = $M->getCla->{rel_quantification_id};
    }
    else{
	$spot_fam_hash->{'quantification_id'} = $M->getCla->{quantification_id};
    }
 
    my @spot_fam_attr=$M->getAttrArray("GUS::Model::RAD::$cr_subclass_view");
    my $spot_fam_attr_hashref=$M->getAttrHashRef("GUS::Model::RAD::$cr_subclass_view");
    for (my $i=0; $i<@spot_fam_attr; $i++) {
	my $attr;
	$attr=$spot_fam_attr[$i];
	if ( defined $pos->{$attr} && $arr[$pos->{$attr}] ne "") {
	  $spot_fam_hash->{$spot_fam_attr[$i]} = $arr[$pos->{$attr}];
	}
	if ( ($spot_fam_attr_hashref->{$spot_fam_attr[$i]} =~ /^Not Nullable$/)  && !defined $spot_fam_hash->{$spot_fam_attr[$i]}) {
	  $warnings = "Data file line $cfg_rv->{n} is missing attribute CompositeElementResultImp.$spot_fam_attr[$i], which is mandatory.\nData from this data line were not loaded for $cfg_rv->{channel} channel.\nHere $cfg_rv->{n} is the number of lines (including empty ones) after the header.\n\n";
	  print $warning_fh "WARNING\t$warnings\n";
	  return; 
	}
      }
 
     my $SPOT_FAM_VIEW=join('::', 'GUS', 'Model', 'RAD', $cr_subclass_view);
     my $spot_family = $SPOT_FAM_VIEW->new($spot_fam_hash);
# check whether this row is already in the database
# if it is, get its primary key
     if ($spot_family->retrieveFromDB(\@attributesToNotRetrieve)) {
	 $RV="Data line no. $cfg_rv->{n}\tAlready existing an entry in CompositeElementResultImp\tNo insert";
	 print $warning_fh "WARNING\t$RV\n";
	 $cfg_rv->{spot_fam_rs_pk} = $spot_family->getId();
     }
     else{
	 $spot_family->submit();
# need to rewrite this part
#
	 if($spot_family->getId()){
	     $cfg_rv->{num_spot_family}++;
	     $cfg_rv->{spot_fam_rs_pk} = $spot_family->getId();
	 }
	 else{
	     $RV="Data line no. $cfg_rv->{n} cann't be inserted into CompositeElementResultImp\tSkip this one";
	     print $warning_fh "WARNING\t$RV\n";

	 }
     }
}

sub updateSpotResult{
    my $M=shift;    
    my ($warning_fh,@arr)=@_;
    my $pos=$cfg_rv->{position};
    my $spot_hash;
    my $n=$cfg_rv->{n};
    my $warnings;
    my $RV;

    my $er_subclass_view = $M->getCla->{result_subclass_view};
    my @spot_attr=$M->getAttrArray("GUS::Model::RAD::$er_subclass_view");
    my $spot_attr_hashref=$M->getAttrHashRef("GUS::Model::RAD::$er_subclass_view");
    my @attributesToNotRetrieve = ('modification_date', 'row_alg_invocation_id');     
    $spot_hash->{'element_id'} = $cfg_rv->{spot_or_sf_id};
    $spot_hash->{'subclass_view'} = $er_subclass_view;

    if(defined $cfg_rv->{channel} && $cfg_rv->{channel} eq 'G'){
	$spot_hash->{'quantification_id'} = $M->getCla->{rel_quantification_id};
    }
    else{
	$spot_hash->{'quantification_id'} = $M->getCla->{quantification_id};
    }
 
    for (my $i=0; $i<@spot_attr; $i++) {
	my $attr;
	if(defined $cfg_rv->{channel}){
    	    $attr="R.$spot_attr[$i]" if $cfg_rv->{channel} eq 'R';
    	    $attr="G.$spot_attr[$i]" if $cfg_rv->{channel} eq 'G';
	}
	else{
	    $attr=$spot_attr[$i];
	}
	if ( defined $pos->{$attr} &&  $arr[$pos->{$attr}] ne "") {
	    $spot_hash->{$spot_attr[$i]} = $arr[$pos->{$attr}];
	}

	if ($spot_attr_hashref->{$spot_attr[$i]}=~ /^Not Nullable$/ && !defined $spot_hash->{$spot_attr[$i]}) { 
	    $RV = "Data file line $n is missing attribute ElementImp.$spot_attr[$i], which is mandatory\nData from data line $n for $cfg_rv->{channel} were not loaded.\nHere $n is the number of lines (including empty ones) after the header.\n\n";
	    print $warning_fh "WARNING\t$RV\n";
	    return;
	 }
    }

   my $SPOT_VIEW=join('::', 'GUS', 'Model','RAD', $er_subclass_view);
   my $spotResult = $SPOT_VIEW->new($spot_hash);
   my $spot_result_id;
   my $spot_result_pk;

# check whether this row is already in the database
    if ($spotResult->retrieveFromDB(\@attributesToNotRetrieve)) {
	$spot_result_pk=$spotResult->getId();
	$RV="Data line no. $n\tAlready existing an entry in ElementImp\tNo insert";
	print $warning_fh "WARNING\t$RV\n";
    }
    else{
	$spotResult->submit();	  
	if($spotResult->getId()){
	    $cfg_rv->{num_inserts}++;
	}
	else{
	    $RV="Data line no. $cfg_rv->{n}\t cann't be inserted into ElementResultImp\tSkip this one";
	    print $warning_fh "WARNING\t$RV\n";
	}
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


