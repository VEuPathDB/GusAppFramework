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
package GUS::Supported::Plugin::LoadArrayResults;
@ISA = qw( GUS::PluginMgr::Plugin );

use strict;
use IO::File;
use CBIL::Util::Disp;
use GUS::PluginMgr::Plugin;

use GUS::Model::RAD::Quantification;
use GUS::Model::RAD::ArrayDesign;
use GUS::Model::RAD::ElementAnnotation;

sub getArgumentsDeclaration {
  my $eSubclassViewList="Spot, RTPCRElement"; 
  my $cSubclassViewList="ShortOligoFamily, SAGETag, MPSSTag";
  my $posOption="1, 2, 3";

  my $argumentDeclaration =
  [
   fileArg({name => 'data_file',
	    descr => 'The full path of the data_file.',
	    constraintFunc=> undef,
	    reqd => 1,
	    isList => 0,
	    mustExist => 1,
	    format => 'See the NOTES for the format of this file'
	   }),
   enumArg({
	    name => 'e_subclass_view',
	    descr => 'The view of RAD.ElementImp to which the results refer. If this is provided, c_subclass_view and cr_subclass view should not be provided.',
	    constraintFunc => undef,
	    reqd => 0,
	    isList => 0,
	    enum => $eSubclassViewList,
	   }),
   enumArg({
	    name => 'c_subclass_view',
	    descr => 'The view of RAD.CompositeElementImp to which the results refer. If this is provided, e_subclass_view and er_subclass_view should not be provided',
	    constraintFunc => undef, 
	    reqd => 0,
	    isList => 0, 
	    enum => $cSubclassViewList
	   }),
   enumArg({
	    name  => 'posOption',
	    descr => 'Choice of identifier attributes for RAD.ShortOligoFamily data, default is 1.',
	    constraintFunc=> undef,
	    reqd  => 0,
	    isList => 0,
	    default => 1,
	    enum => $posOption
	   }),
   integerArg({
	       name => 'quantification_id',
	       descr => 'RAD.Quantification.quantification_id to which the results refer (for 2-channel data, the quantification corresponding to channel1)',
	       constraintFunc=> undef,
	       reqd  => 1,
	       isList => 0
	      }),
   integerArg({
	       name  => 'rel_quantification_id',
	       descr => 'RAD.Quantification.quantification_id for channel2, if the results refer to 2-channel data.',
	       constraintFunc=> undef,
	       reqd  => 0,
	       isList => 0
	      }),
   integerArg({
	       name  => 'cel_quantification_id',
	       descr => 'If loading short-oligo probeset data, the RAD.Quantification.quantification_id of the corresponding probecell data. This is DIFFERENT FROM THE quantification_id of the results being loaded.',
	       constraintFunc=> undef,
	       reqd  => 0,
	       isList => 0
	      }),
   integerArg({
	       name  => 'array_design_id',
	       descr => 'RAD.ArrayDesign.array_design_id for the array used.',
	       constraintFunc => undef,
	       reqd  => 1,
	       isList => 0
	      }),
   booleanArg({
	       name  => 'noWarning',
	       descr => 'If provided, no warning messages will be generated.',
	       constraintFunc=> undef,
	       reqd  => 0,
	       isList => 0
	      }),
   stringArg({
	      name => 'cr_subclass_view',
	      descr => 'The view of RAD.CompositeElementResultImp into which to load the results, if they refer to short-oligo (e.g. Affymetrix), SAGE, or MPSS technologies. If this is provided, e_subclass_view and er_subclass_view should not be provided',
	      constraintFunc => undef,
	      reqd => 0,
	      isList => 0
	     }),
   stringArg({
	      name => 'er_subclass_view',
	      descr => 'The view of RAD.ElementResultImp into which to load the results, if they refer to spotted arrays, long-oligo arrays, or RT-PCR. If this is provided, c_subclass_view and cr_subclass_view should not be provided',
	      constraintFunc => undef,
	      reqd => 0,
	      isList => 0
	     }),
   integerArg({
	       name => 'testnumber',
	       descr => 'Optional, number of iterations for testing',
	       constraintFunc => undef,
	       reqd  => 0,
	       isList => 0
	      }),
   integerArg({
	       name => 'restart',
	       descr => 'Optional, data file line number to start loading data from (start counting after the header and include empty lines.)',
	       constraintFunc=> undef,
	       reqd => 0,
	       isList => 0
	      })
  ];

  return $argumentDeclaration;
}

sub getDocumentation {
  my $purposeBrief = 'Loads data into views of RAD.ElementResultImp or RAD.CompositeElementResultImp.';

  my $purpose = <<PURPOSE;
Each run of this plug-in can load one of the following: (i) quantification results for spotted, or long-oligo microarray data, or RT-PCR data into an appropriate view of RAD.ElementResultImp, (ii) quantification results (probe set level only) for short-oligo (e.g. Affymetrix), or SAGE, or MPSS data into an appropriate view of RAD.CompositeElementResultImp. Moreover, this plugin will also set the value of RAD.Quantification.result_table_id and, if applicable, link the probecell (e.g. cel) quantification_id with the probeset quantification_id in RAD.RelatedQuantification.
PURPOSE

  my $tablesAffected = [
    ['RAD::Quantification', 'Updates the result_table_id for the correponding quantification(s)'],
    ['RAD::RelatedQuantification', 'Inserts two rows to link the probecell and the probeset quantifications, if applicable'],
    ['RAD::ElementResultImp', 'Enters here the quantification results, for spotted, long-oligo and RT-PCR data'],
    ['RAD::CompositeResultElementImp', 'Enters here the quantification results, for short-oligo, SAGE, and MPSS data']
   ];

  my $tablesDependedOn = [
    ['RAD::Quantification', 'The quantification(s) whose results need to be loaded'],
    ['RAD::ArrayDesign', 'The array used'], 
  ];

  my $howToRestart = <<RESTART;
Run the plugin with the I<--restart n> argument, where n is the line number in the data file of the first row to load upon restarting (line 1 is the first line after the header, empty lines ARE counted).
RESTART

  my $failureCases = <<FAILURE_CASES;
Input file not in the appropriate format.
FAILURE_CASES

  my $notes=<<NOTES;
The plug-in outputs to STDOUT (for possible redirection to a log file): the number of data file lines read (counting empty lines, but not counting the header and the lines preceding it in the data file), any warning statement regarding data lines which have not been loaded into RAD.

=head2 F<data_file>

* The data file should be in tab-delimited text format with one header row and one row for each element or composite_element. All rows should contain the same number of tabs/fields.

* The header for this file should contain "identifier attributes" to identify the (composite)element to which the result refer and "view attributes" corresponding to the fields in the view of RAD.(Composite)ElementResultImp to be filled in. These should be in lower case. See below for more details.

* If the data file refers to 2-channel array data, a prefix like "channel1" or "channel2" should precede each view attribute: "channel1.attributeName" and "channel2.attributeName" will distinguish the values for the same field corresponding to the two different channels.

------------------------------------------------------

* The "identifier attributes" to be used depend on the technology. (The posOption argument is an additonal argument which allows for different identifier attributes to be used when dealing with short-oligo, e.g. Affymetrix, data.)

 if c_subclass_view eq 'ShortOligoFamily' and posOption == 1 
   then the identifier attribute provided in the data file is 'name' (as in RAD.ShortOligoFamily)

 if c_subclass_view eq 'ShortOligoFamily' and posOption == 2
   then the identifier attributes provided in the data file are 'external_database_release_id' and 'source_id' (as in RAD.ShortOligoFamily)

 if c_subclass_view eq 'ShortOligoFamily' and posOption == 3
   then the identifier attributes provided in the data file are 'name', 'external_database_release_id', and 'source_id' (as in RAD.ShorgOligoFamily)

 if c_subclass_view eq 'SAGETag'
    then the identifier attribute provided in the data file must be 'tag' (as in RAD.SAGETag)

 if c_subclass_view eq 'MPSSTag'
     then the identifier attribute provided in the data file must be 'tag' (as in RAD.MPSSTag)

 if e_subclass_view eq 'Spot'
     then the identifier attributes provided in the data file must be 'array_row', 'array_column','grid_row', 'grid_column', 'sub_row', and 'sub_column' (as in RAD.Spot)

 if e_subclass_view eq 'RTPCRElement'
       then the identifier attributes provided in the data file are 'external_database_release_id' and 'source_id' (as in RAD.RTPCRElement)

------------------------------------------------------

* The "view attributes" must match attributes from the view which the plugin will populate and be written in lower case.

* Empty lines in the data files are ignored. All quotes within a data line are removed by the plug-in.

* If any value in the data file is larger than the maximum value or smaller than minimum value allowed in the database for the corresponding field, then the plugin will reset the value to the maximum or minimum value for that field.

* Please double-check that your data file has no inconsistencies before loading the data. If a column in your data file contains information which should be separated and stored into multiple view attributes, you will need to re-parse your file and separate this information into different columns before running the plug-in. Similarly, if information from different columns of your data file refers to one view attribute, you will need to re-parse your data file and merge this information into one column.

=head1 AUTHOR

Written by Junmin Liu.

=head1 COPYRIGHT

Copyright Trustees of University of Pennsylvania 2003.

NOTES

  my $documentation = {purpose=>$purpose, purposeBrief=>$purposeBrief, tablesAffected=>$tablesAffected, tablesDependedOn=>$tablesDependedOn, howToRestart=>$howToRestart, failureCases=>$failureCases, notes=>$notes};
  return $documentation;
}

sub new {
  my $Class = shift;
  my $self = {};
  bless($self,$Class); # configuration object...
  my $documentation = &getDocumentation();
  my $argsDeclaration  = &getArgumentsDeclaration();

  $self->initialize({requiredDbVersion => '3.6',
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
  eval "require GUS::Model::RAD::$M->getArgs->{'er_subclass_view'}";
  eval "require GUS::Model::RAD::$M->getArgs->{'cr_subclass_view'}";

# set the global array $positionList and require the view for CompositeElementImp at running time
 
  if($M->getArgs->{c_subclass_view} eq 'ShortOligoFamily'){
      
      eval "require GUS::Model::RAD::ShortOligoFamily";    
      if( $M->getArgs->{posOption} == 1){
	  @positionList = ('name');
      }
      if( $M->getArgs->{posOption} == 2){
	  @positionList = ('external_database_release_id', 'source_id');
      }
      if( $M->getArgs->{posOption} == 3){
	  @positionList = ('name', 'external_database_release_id', 'source_id');
      }
	
  }

 if($M->getArgs->{c_subclass_view} eq 'SAGETag' ){
	@positionList = ('tag');
	eval "require GUS::Model::RAD::SAGETag";
  }
 if($M->getArgs->{c_subclass_view} eq 'MPSSTag' ){
	@positionList = ('tag');
	eval "require GUS::Model::RAD::MPSSTag";
  }
# set the global array $positionList and require the view for ElementImp at running time
#  if($M->getArgs->{e_subclass_view} eq 'ShortOligo' ){
#	@positionList = ('x_position', 'y_position');
#	eval "require GUS::Model::RAD::ShortOligo";
#  }
  
  if($M->getArgs->{e_subclass_view} eq 'Spot'){
	@positionList = ('array_row','array_column','grid_row','grid_column','sub_row','sub_column');
#      @positionList = ('grid_row','grid_column','sub_row','sub_column');
	eval "require GUS::Model::RAD::Spot";
  }
  
  if($M->getArgs->{e_subclass_view} eq 'SAGETagMapping' ){
	@positionList = ('external_database_release_id', 'source_id');
	eval "require GUS::Model::RAD::SAGETagMapping";
  }
  
  if($M->getArgs->{e_subclass_view} eq 'RTPCRElement' ){
	@positionList = ('external_database_release_id', 'source_id');
	eval "require GUS::Model::RAD::RTPCRElement";
  }

# self-defined subroutine, check the headers of data file if it provide the 
# header matching with them provide in configuration file
#
  my $fh=new IO::File;
  my $fileName=$M->getArgs->{'data_file'};
    unless ($fh->open("<$fileName")) {
	$M->error("Cannot open data file $fileName for reading.");
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
  $M->log('Result', "OK Finish updating Result_Table_Id in quantification table.");
  


# self-defined subroutine, related the .cel file and .chp file's quantification_id 
# 
  if($M->getArgs->{cel_quantification_id}){
      eval "require GUS::Model::RAD::RelatedQuantification";
      $M->relateQuantifications(); 
      return unless $M->getOk();
  }

# self-defined subroutine, read the headers of data file if it provide the 
# header matching with them provide in configuration file
#
  $RV = $M->loadData($fh);
  $fh->close();

  $M->getQueryHandle()->commit(); # ga no longer doing this by default
  return $RV;
}

sub checkArgs {
    my $M = shift;
    my $RV="";
    $M->setOk(1);
    my $quan_id=$M->getArgs->{'quantification_id'};
    my $array_id=$M->getArgs->{'array_design_id'};
    my $query;
    my $dbh = $M->getQueryHandle();
    my $sth;

# one of the e_subclass_view or c_subclass_view must be provided
    if(!defined $M->getArgs->{e_subclass_view} && !defined $M->getArgs->{c_subclass_view}){
	$RV = join(' ','a --e_subclass_view <view name for ElementImp>', $M->getArgs->{e_subclass_view},'or --c_subclass_view <view name for CompositeElementImp> must be on the commandline', $M->getArgs->{c_subclass_view});
	$M->userError($RV);
    }


# one of the er_subclass_view or cr_subclass_view must be provided
    if(!defined $M->getArgs->{er_subclass_view} && !defined $M->getArgs->{cr_subclass_view}){
	$RV = join(' ','a --er_subclass_view <view name for ElementResultImp>', $M->getArgs->{er_subclass_view},'or --cr_subclass_view <view name for CompositeElementResultImp> must be on the commandline', $M->getArgs->{cr_subclass_view});
       	$M->userError($RV);
      }

    if(defined $M->getArgs->{er_subclass_view}){
	my $erSubView=$M->getArgs->{er_subclass_view};
	$M->checkViewName($erSubView);
	return unless $M->getOk();
    }

    if(defined $M->getArgs->{cr_subclass_view}){
	my $crSubView=$M->getArgs->{cr_subclass_view};
	$M->checkViewName($crSubView);
	return unless $M->getOk();
    }


# check that the given quantification_id is a valid one
# skip this check for now
    if($M->getArgs->{debug}){
	$M->checkId('RAD', 'Quantification', 'quantification_id', $M->getArgs->{'quantification_id'}, 'quantification_id');
	return unless $M->getOk();
    }

# check that the given quantification_id is a valid one
    if(defined $M->getArgs->{cel_quantification_id}){
	$M->checkId('RAD', 'Quantification', 'quantification_id', $M->getArgs->{'cel_quantification_id'}, 'cel_quantification_id');
	return unless $M->getOk();
    }
# check that the given array_id is a valid one
    $M->checkId('RAD', 'ArrayDesign', 'array_design_id', $M->getArgs->{'array_design_id'}, 'array_design_id');
    return unless $M->getOk();

#check if given array_design_id and quantification_id matched
    $query="select a.assay_id from RAD.acquisition aq, rad.quantification qa, rad.assay a where quantification_id=$quan_id and qa.acquisition_id=aq.acquisition_id and aq.assay_id=a.assay_id and a.array_design_id=$array_id";
    $sth = $dbh->prepare($query);
    $sth->execute();
    my ($assay_id) = $sth->fetchrow_array();
    $sth->finish();
    if (!defined $assay_id) {
	$RV="quantification_id $quan_id and array_design_id $array_id are not related ids.";
	$M->userError($RV);
    }

# check rel_quantification_id 
    if(defined $M->getArgs->{rel_quantification_id}){
# check that the given rel_quantification_id is a valid one
# skip this check for now
	if($M->getArgs->{debug}){
	    $M->checkId('RAD','Quantification','quantification_id',$M->getArgs->{'rel_quantification_id'},'rel_quantification_id');
	    return unless $M->getOk();
	}
	my $rel_quan_id=$M->getArgs->{'rel_quantification_id'};    
	$query="select related_quantification_id from rad.relatedquantification where quantification_id=$quan_id and associated_quantification_id=$rel_quan_id";

	$sth = $dbh->prepare($query);
	$sth->execute();
	my ($qid) = $sth->fetchrow_array();
	$sth->finish();
	if (!defined $qid) {
	    $RV="$quan_id and $rel_quan_id are not related quantification ids.";
	    $M->userError($RV);
	  }
#check if given array_design_id and rel_quantification_id matched
	$query="select a.assay_id from rad.acquisition aq, rad.quantification qa, rad.assay a where quantification_id=$rel_quan_id and qa.acquisition_id=aq.acquisition_id and aq.assay_id=a.assay_id and a.array_design_id=$array_id";
	$sth = $dbh->prepare($query);
	$sth->execute();
	my ($assay_id) = $sth->fetchrow_array();
	$sth->finish();
	if (!defined $assay_id) {
	    $RV="rel_quantification_id $quan_id and array_design_id $array_id are not related ids.";
	    $M->userError($RV);
	}
    
    }


    $M->log('STATUS', 'OK finished checking command line arguments');
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
	$RV = join(' ','a VALID --', $claname, 'must be on the commandline', $claname, '=',$M->getArgs->{$claname});
	$M->userError($RV);
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
	$RV = join(' ','Cannot get the database handle', $table_name);
	$M->error($RV);
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
	$RV = join(' ','Cannot get the database handle', $table_name);
	$M->error($RV);
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

sub parseHeader{
  my  $M=shift;
  my ($fh) = @_;
  my %headers;

  my $line = "";
  while ($line =~ /^\s*$/) {
    last unless $line = <$fh>;
  }
  
  if($M->getArgs->{debug}){
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
	$M->userError("No two columns can have the same name in the data file header.");
    }
    else {
      $headers{$arr[$i]} = 1;
    }
    $cfg_rv->{'position'}->{$arr[$i]} = $i;
  }

  $cfg_rv->{'num_fields'} = scalar(@arr);
  $M->log('Status', 'OK Finish parsing the headers of array data file');
}

sub checkHeader{
    my $M=shift; 
    my $RV;
    foreach my $arr (@positionList){
       	if (! defined $cfg_rv->{'position'}->{$arr}){
	    $RV = "Missing header $arr in the data file which is required to define one element";
	    $M ->userError($RV);
	}
    }
    $M->log('Status', 'OK Finish checking the headers of array data file');
}

sub relateQuantifications{
    my $M=shift; 
    my $RV;
    $M->setOk(1);
    my $relQuan_hash;
    $relQuan_hash->{'quantification_id'} = $M->getArgs->{quantification_id};
    $relQuan_hash->{'associated_quantification_id'} = $M->getArgs->{cel_quantification_id};
    my $c_subclass_view=$M->getArgs->{'cr_subclass_view'};
  #  $relQuan_hash->{'ASSOCIATED_DESIGNATION'}="cel quantification";
  #  $relQuan_hash->{'DESIGNATION'}="chp quantification";
    my @attributesToNotRetrieve = ('modification_date', 'row_alg_invocation_id');     
    my $rel_quantification = GUS::Model::RAD::RelatedQuantification->new($relQuan_hash);
    my $id;
    my $relId;
# check whether this row is already in the database
# if it is, get its primary key
     if ($rel_quantification->retrieveFromDB(\@attributesToNotRetrieve)) {
	 $id=$relQuan_hash->{'quantification_id'};
	 $relId=$relQuan_hash->{'associated_quantification_id'};
	 $RV="The chp quantification_id $id and cel quantification_id $relId have already been linked in relatedQuantification table as quantification_id and associated_quantification_id\tNo insert";
	 $M->log('Result', $RV);
     }
     else{
	 if($c_subclass_view eq "RMAExpress"){
	     $rel_quantification->setDesignation("RMA quantification");
	     $rel_quantification->setAssociatedDesignation("cel quantification");
	 }
	 elsif($c_subclass_view eq "MOIDResult"){
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
	     $M->log('Result', $RV);
	 }
	 else{
	     $RV="The chp quantification_id $id and cel quantification_id $relId cann't be linked in relatedQuantification table as quantification_id and associated_quantification_id\tNo insert";
	     $M->error($RV);
	 }
     }
# related in another way
    $relQuan_hash->{'associated_quantification_id'} = $M->getArgs->{quantification_id};
    $relQuan_hash->{'quantification_id'} = $M->getArgs->{cel_quantification_id};
  #  $relQuan_hash->{'ASSOCIATED_DESIGNATION'}="cel quantification";
  #  $relQuan_hash->{'DESIGNATION'}="chp quantification";

   $rel_quantification = GUS::Model::RAD::RelatedQuantification->new($relQuan_hash);
# check whether this row is already in the database
# if it is, get its primary key
     if ($rel_quantification->retrieveFromDB(\@attributesToNotRetrieve)) {
	 my $id=$relQuan_hash->{'quantification_id'};
	 my $relId=$relQuan_hash->{'associated_quantification_id'};
	 $RV="The chp quantification_id $id and cel quantification_id $relId have already been linked in relatedQuantification table as associated_quantification_id and quantification_id\tNo insert";
	 $M->log('Result', $RV);
     }
     else{
	 if($c_subclass_view eq "RMAExpress"){
	     $rel_quantification->setDesignation("cel quantification");
	     $rel_quantification->setAssociatedDesignation("RMA quantification");
	 }
	 elsif($c_subclass_view eq "MOIDResult"){
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
	     $M->log('Result', $RV);
	 }
	 else{
	     $RV="The chp quantification_id $id and cel quantification_id $relId cann't be linked in relatedQuantification table as associated_quantification_id and quantification_id\tNo insert";
	     $M->error($RV);
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
   my $array_design_id = $M->getArgs->{array_design_id};
   my ($e_subclass_view, $c_subclass_view, $er_subclass_view, $cr_subclass_view);
   if(defined $M->getArgs->{e_subclass_view}){
       $e_subclass_view = $M->getArgs->{e_subclass_view};
   }
   if(defined $M->getArgs->{c_subclass_view}){
       $c_subclass_view = $M->getArgs->{c_subclass_view};
   }
   if(defined $M->getArgs->{er_subclass_view}){
       $er_subclass_view = $M->getArgs->{er_subclass_view};
       eval "require GUS::Model::RAD::$er_subclass_view";
   } 
   if(defined $M->getArgs->{cr_subclass_view}){
       $cr_subclass_view = $M->getArgs->{cr_subclass_view};
       eval "require GUS::Model::RAD::$cr_subclass_view";
   }
   my $quantification_id = $M->getArgs->{quantification_id};
   my $rel_quantification_id;
   if(defined $M->getArgs->{rel_quantification_id}){
      $rel_quantification_id = $M->getArgs->{rel_quantification_id}; 
   }
# for querying ElementImp table to set the element_id or composite_element_id
   my ($spotClass, $spotFamilyClass);

   if(defined $e_subclass_view){
	   $spotClass="GUS::Model::RAD::$e_subclass_view"; 
   }

# if $e_subclass_view not set, querying CompositeElementImp table to set the  composite_element_id
   if(defined $c_subclass_view){
       $spotFamilyClass = "GUS::Model::RAD::$c_subclass_view";
     }

   while ($line = <$fh>) {
     
     $cfg_rv->{n}++;
     if (($cfg_rv->{n})%200==0) {
	 $RV="Read $cfg_rv->{n} datalines including empty line";
	 $M->log('Status', $RV);
	 if($M->getArgs->{'commit'}){
	     $RV = "Processed $cfg_rv->{n} dataline including empty line, Inserted $cfg_rv->{num_inserts} ElementResults and $cfg_rv->{num_spot_family} CompositeElementResults."; 
	     print STDERR "RESULT: $RV\n";
	 }
#	 print STDERR "Read $n datalines including empty line\n";
     }
# skip number of line as defined by user
     if (defined $M->getArgs->{'restart'} && $cfg_rv->{n}<$M->getArgs->{'restart'}) {
	 next;
     }
# skip empty lines if any
     if ($line =~ /^\s*$/) {
	 next;
     }
     
     if($M->getArgs->{debug}){
	 print "Debug\t$line\n";
     }

# stop reading data lines after testnumber of lines
     if (!$M->getArgs->{'commit'} && defined $M->getArgs->{'testnumber'} && $cfg_rv->{n}-$M->getArgs->{'restart'}==$M->getArgs->{'testnumber'}+1) {
	 $cfg_rv->{n}--;
	 my $stopNumber=$M->getArgs->{'testnumber'};
	 $RV="stopping reading after testing $stopNumber lines";
	 $M->log('Result', $RV);
	 last;
     }

     my @arr = split(/\t/, $line);
     if (scalar(@arr) != $cfg_rv->{'num_fields'}) {
	 $cfg_rv->{warnings} = "The number of fields for data line $cfg_rv->{n} does not equal the number of fields in the header.\nThis might indicate a problem with the data file.\nData loading is interrupted.\nData from data line $cfg_rv->{n} and following lines were not loaded.\nHere $cfg_rv->{n} is the number of lines (including empty ones) after the header.\n";   
	 $M->userError($cfg_rv->{warnings});
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
     $spot_hash->{'array_design_id'} = $array_design_id;
     foreach my $item(@positionList){
	 if(defined $arr[$pos->{$item}]){
	     $spot_hash->{$item} = $arr[$pos->{$item}]; 
	 }
	 else{
	     $cfg_rv->{warnings} = "Data file line $cfg_rv->{n} is missing attribute ElementImp.$item, which is mandatory.\nData from this data line were not loaded.\nHere $cfg_rv->{n} is the number of lines (including empty ones) after the header.\n\n";
	     $M->log('Warning', $cfg_rv->{warnings});
#	     print STDERR $warnings; 

	     $cfg_rv->{skip_line} = 1;
	     last; # exit the foreach loop
	 }
     }

     next if ($cfg_rv->{skip_line} == 1); # skip this row


     my $elementAnnotation_hash;
     my $elementAnnotation;
 #    $elementAnnotation_hash->{'name'}=$arr[$pos->{'name'}];
 #    $elementAnnotation_hash->{'name'}=$arr[$pos->{'value'}];
 #    $elementAnnotation=GUS::Model::RAD::ElementAnnotation->new($elementAnnotation_hash);

     $spot = $spotClass->new($spot_hash);
 #   $spot->setChild($elementAnnotation);

     if ($spot->retrieveFromDB(\@attributesToNotRetrieve)) {
	 $cfg_rv->{spot_id} = $spot->getId();
#	 print "$spot_id\n";
	 $cfg_rv->{spot_family_id} = $spot->getCompositeElementId();
     }
     else{
	 $RV="Couldn't find the corresponding element_id for the data line no. $cfg_rv->{n}\tskip this\tNo insert";
	 if(! $M->getArgs->{noWarning} ){
	     $M->logData('Warning', $RV);
	 }

	 if($M->getArgs->{'commit'} && ! $M->getArgs->{noWarning} ){
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
     $spot_fam_hash->{'array_design_id'} = $array_design_id;
     foreach my $item(@positionList){
	 if(defined $arr[$pos->{$item}]){
	     $spot_fam_hash->{$item} = $arr[$pos->{$item}]; 
	 }
	 else{
	     $cfg_rv->{warnings} = "Data file line $cfg_rv->{n} is missing attribute CompositeElementImp.$item, which is mandatory.\nData from this data line were not loaded.\nHere $cfg_rv->{n} is the number of lines (including empty ones) after the header.\n\n";
	     $M->logData('Warning', $cfg_rv->{warnings});
#	     print STDERR $warnings;
	     if($M->getArgs->{'commit'}){print STDERR "Warning: $RV\n";} 
	     $cfg_rv->{skip_line} = 1;
	     last; # exit the foreach loop
	 }
     }

     next if ($cfg_rv->{skip_line} == 1); # skip this row


     my $elementAnnotation_hash;
     my $elementAnnotation;
 #    $elementAnnotation_hash->{'name'}=$arr[$pos->{'name'}];
 #    $elementAnnotation_hash->{'name'}=$arr[$pos->{'value'}];
 #    $elementAnnotation=GUS::Model::RAD::ElementAnnotation->new($elementAnnotation_hash);

     $spotFam = $spotFamilyClass->new($spot_fam_hash);
 #   $spot->setChild($elementAnnotation);


     if ($spotFam->retrieveFromDB(\@attributesToNotRetrieve)) {
	 $cfg_rv->{spot_family_id} = $spotFam->getCompositeElementId();
     }
     else{
	 $RV="Couldn't find the corresponding composite_element_id for the data line no. $cfg_rv->{n}\tskip this\tNo insert";
	 if(! $M->getArgs->{noWarning}){
	     $M->logData('Warning', $RV);
	 }
	 if($M->getArgs->{'commit'} && !$M->getArgs->{noWarning} ){
	     print STDERR "Warning: $RV\n";
	 }
	 $cfg_rv->{skip_line} = 1;
	 next; # skip this row
     }
}

     
# build a row for spotfamilyresultImp

     if(defined $cr_subclass_view && defined $cfg_rv->{spot_family_id} && $cfg_rv->{spot_family_id} ne 'null'){
	 if(defined $M->getArgs->{rel_quantification_id}){
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
	 if($M->getArgs->{'commit'}){print STDERR "Warning: $RV\n";}
     }

# build a row for ElementResultImp
     if(defined $er_subclass_view){
	  if(defined $M->getArgs->{rel_quantification_id}){
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
   if($M->getArgs->{'commit'}){print STDERR "RESULT: $RV\n";}
   
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
   if($M->getArgs->{'commit'}){print STDERR "RESULT: $RV\n";}
   
   $RV="Number of records which have been inserted into CompositeElementImp table (after header): $cfg_rv->{num_spot_family}.";
   $M->logData('Result', $RV);
   if($M->getArgs->{'commit'}){print STDERR "RESULT: $RV\n";}
   
   $RV = "Processed $cfg_rv->{n} dataline, Inserted $cfg_rv->{num_inserts} ElementResults and $cfg_rv->{num_spot_family} CompositeElementResults."; 
   return $RV;
   
}


sub updateResultTableId{
  my $M = shift;

  my $t_id;
  my $RV;
  my $er_subclass_view;
  if(defined $M->getArgs->{er_subclass_view}){
    $er_subclass_view = $M->getArgs->{er_subclass_view};
    $t_id=$M->getTable_Id($er_subclass_view);  
  } 
  
  my $cr_subclass_view;
  if(defined $M->getArgs->{cr_subclass_view}){
    $cr_subclass_view = $M->getArgs->{cr_subclass_view};
    $t_id=$M->getTable_Id($cr_subclass_view);
  }
  
  my $quantification_id = $M->getArgs->{quantification_id};
  if(!$M->updateQuantification($t_id, $quantification_id)){
    $RV = "ERROR\tCann't set result_table_id to $t_id for quantification id $quantification_id in quantification table.\n";
    $M->error($RV);
  }

   my $rel_quantification_id;
   if(defined $M->getArgs->{rel_quantification_id}){
      $rel_quantification_id = $M->getArgs->{rel_quantification_id}; 
      if(!$M->updateQuantification($t_id, $rel_quantification_id)){
	$RV = "ERROR\tCann't set result_table_id to $t_id for quantification id $rel_quantification_id in quantification table.\n";
	$M->error($RV);
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


sub checkViewName{
    my $M = shift;
    my ($table_name)=@_;
    my $query="select t.table_id from core.tableinfo t where t.name='$table_name' and is_view=1";
    my $dbh = $M->getQueryHandle();
    my $sth = $dbh->prepare($query);
    $sth->execute();
    my ($id) = $sth->fetchrow_array();
    $sth->finish();
    if (defined $id) {
	return 1;
    }
    else{
	$cfg_rv->{warnings} = "The subclass view $table_name doesn't exist!";
	$M->userError($cfg_rv->{warnings});
    }
}

sub getTable_Id{
    my $M = shift;
    my ($table_name)=@_;
 #eval "require GUS::Model::RAD::$cfg_rv->{'mapping'}->{'CompositeElementImp.subclass_view'}";
  #eval "require GUS::Model::RAD::$cfg_rv->{'mapping'}->{'ElementImp.subclass_view'}";
    my $query="select t.table_id from core.tableinfo t where t.name='$table_name'";
    my $dbh = $M->getQueryHandle();
    my $sth = $dbh->prepare($query);
    $sth->execute();
    my ($id) = $sth->fetchrow_array();
    $sth->finish();
    if (defined $id) {
	return $id;
    }
    else{
	$cfg_rv->{warnings} = "Cann't retrieve table_id for subclass view $table_name";
	$M->error($cfg_rv->{warnings});
    }
}

sub updateSpotFamResult{
    my $M = shift;
    my (@arr)=@_;
    my $pos=$cfg_rv->{position};
    my $spot_fam_hash;
    my $cr_subclass_view = $M->getArgs->{cr_subclass_view};
    my $warnings;
    my $RV;
    my @attributesToNotRetrieve = ('modification_date', 'row_alg_invocation_id');     
    $spot_fam_hash->{'subclass_view'} = $cr_subclass_view;
    if(defined $cfg_rv->{channel} && $cfg_rv->{channel} eq 'channel2'){
	$spot_fam_hash->{'quantification_id'} = $M->getArgs->{rel_quantification_id};
    }
    else{
	$spot_fam_hash->{'quantification_id'} = $M->getArgs->{quantification_id};
    }
#   if(defined $spot_family_id && $spot_family_id ne "null"){
     $spot_fam_hash->{'composite_element_id'} = $cfg_rv->{spot_family_id};
	     
    my @spot_fam_attr=$M->getAttrArray("GUS::Model::RAD::$cr_subclass_view");
    my $spot_fam_attr_hashref=$M->getAttrHashRef("GUS::Model::RAD::$cr_subclass_view");
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
	     $M->userError($warnings);
	 }
     }

     my $SPOT_FAM_VIEW=join('::', 'GUS', 'Model', 'RAD', $cr_subclass_view);
     my $spot_family = $SPOT_FAM_VIEW->new($spot_fam_hash);
# check whether this row is already in the database
# if it is, get its primary key
     if ($spot_family->retrieveFromDB(\@attributesToNotRetrieve)) {
	 $RV="Data line no. $cfg_rv->{n}\tAlready existing an entry in CompositeElementResultImp\tNo insert";
	 if(! $M->getArgs->{noWarning}){
	     $M->logData('Result', $RV);
	 }
	 if($M->getArgs->{'commit'} && !$M->getArgs->{noWarning} ){print STDERR "RESULT: $RV\n";}
	 
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
	     if($M->getArgs->{'commit'}){print STDERR "RESULT: $RV\n";}
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
    my $er_subclass_view = $M->getArgs->{er_subclass_view};
    my @spot_attr=$M->getAttrArray("GUS::Model::RAD::$er_subclass_view");
    my $spot_attr_hashref=$M->getAttrHashRef("GUS::Model::RAD::$er_subclass_view");
    my @attributesToNotRetrieve = ('modification_date', 'row_alg_invocation_id');     
    $spot_hash->{'element_id'} = $cfg_rv->{spot_id};
    $spot_hash->{'subclass_view'} = $er_subclass_view;

    if(defined $cfg_rv->{channel} && $cfg_rv->{channel} eq 'channel2'){
	$spot_hash->{'quantification_id'} = $M->getArgs->{rel_quantification_id};
	if(defined $cfg_rv->{spot_fam_rs_pk2}){
	    $spot_hash->{'composite_element_result_id'} = $cfg_rv->{spot_fam_rs_pk2} ;
	}
    }
    else{
	$spot_hash->{'quantification_id'} = $M->getArgs->{quantification_id};
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
	    $M->userError($cfg_rv->{warnings});
	 }
    }

   my $SPOT_VIEW=join('::', 'GUS', 'Model','RAD', $er_subclass_view);
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
	if($M->getArgs->{'commit'}){print STDERR "RESULT: $RV\n";}
    }
    else{
	$spotResult->submit();	  
	if($spotResult->getId()){
	    $cfg_rv->{num_inserts}++;
	}
	else{
	    $RV="Data line no. $cfg_rv->{n}\t cann't be inserted into ElementResultImp\tSkip this one";
	    $M->logData('Result', $RV);
	    if($M->getArgs->{'commit'}){print STDERR "RESULT: $RV\n";}

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
                             
    my $dbh = $M->getArgs->getQueryHandle();
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


