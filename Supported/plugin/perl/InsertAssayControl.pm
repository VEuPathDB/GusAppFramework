# ----------------------------------------------------------
# AssayControlLoader.pm
#
# Loads data into AssayControl table in RAD,
#  
# Mandatory inputs are assay_id and a data file containing at least one header named control_id.
# 
# Created: Friday Sep. 15 12:00:00 EST 2003
#
# junmin liu
#
# Last Modified $Date$
# 
# $Revision$ $Date$ $Author$
# ----------------------------------------------------------
package GUS::Supported::Plugin::InsertAssayControl;
@ISA = qw( GUS::PluginMgr::Plugin );

use strict;
use IO::File;
use CBIL::Util::Disp;
use GUS::PluginMgr::Plugin;

use GUS::Model::RAD::Control;
use GUS::Model::RAD::AssayControl;
use GUS::Model::RAD::Assay;
use GUS::Model::Study::OntologyEntry;

sub new {
  my $Class = shift;
  my $self = {};
  bless($self,$Class); # configuration object...

# call required inherited initialization methods
  my $usage = 'Loads data into AssayControl table in RAD database.';
  my $purposeBrief = 'Loads data into AssayControl table in RAD database.';
  my $purpose = <<PURPOSE;
This is a plug-in that loads AssayControl information (spotted microarray and oligonucleotide array) data into control table. 
PURPOSE

  my $tablesAffected = [
			['RAD::AssayControl',          'Enters here multiple rows']
		       ];
  my $tablesDependedOn = [
			  ['Study::OntologyEntry',                'Holds the ontolgies for technology_type, substrate_type and control_type'],
			  ['RAD::Assay',                'Holds assay information'], 
			 ];

  my $howToRestart = <<RESTART;
Loading can be resumed using the I<--restart n> argument where n is the line number in the data file of the first row to load upon restarting (line 1 is the first line after the header, empty lines are counted).
RESTART

  my $failureCases = <<FAILURE_CASES;
Files not in an appropriate format.
FAILURE_CASES

my $notes = <<NOTES;
=head2 Example
*For help
ga GUS::Supported::Plugin::InsertAssayControl B<[options]> B<--help>
*For loading data into AssayControl table
ga GUS::Supported::Plugin::InsertAssayControl B<[options]> B<--data_file> data_file B<--assay_id> assay_id B<--debug> > logfile
*For loading data into AssayControl table
ga GUS::Supported::Plugin::InsertAssayControl B<[options]> B<--data_file> data_file B<--assay_id> assay_id B<--commit> > logfile 
=head2 F<data_file>

The data file should be in tab-delimited text format with one header row and a row for each element. All rows should contain the same number of tabs/fields.

* The header contains a list of attributes which are defined in the assaycontrol table including control__id, value, unit_type_id. 

* All attributes in the header should be small case. View attributes should be the same as defined in the views of interest.

* Empty lines in the data files are ignored. All quotes within a data line are removed by the plug-in.

Please double-check that your data file has no inconsistencies before loading the data. If a column in your data file contains information which should be separated and stored into different table/view attributes, you will need to re-parse your file and separate this information into different columns before running the plug-in. Similarly, if information from different columns of your data file refers to one table/view attribute, you will need to re-parse your data file and merge this information into one column.
=head2 SPECIAL NOTES
Before you can run this plug-in you need to create the Perl objects for the views you will be loading, should these objects not exist yet. Based on the "build" system, this will involve two steps. First, check out the RAD, CBIL, GUS and Install modules from the cvs repository; secondly, build the GUS_HOME which the Perl objects reside in.
The plug-in outputs a print statement to STDOUT (for possible redirection to a log file) which lists the number of data file lines read (counting empty lines, but not counting the header and the lines preceding it in the data file) and any warning statement(s) regarding data lines which have not been loaded into RAD.
Make sure that the F<.gus.properties> file of the user contains the correct login name [RADrw]. Also, if the group and project differ from the default values in F<.gus.properties>, I<please specify the proper group and project name on the command line using --group and --project options respectively>. 
=head1 AUTHOR
Written by Junmin Liu.
=head1 COPYRIGHT
Copyright Trustees of University of Pennsylvania 2005.

NOTES
my $documentation = {purpose=>$purpose, purposeBrief=>$purposeBrief, tablesAffected=>$tablesAffected, tablesDependedOn=>$tablesDependedOn, howToRestart=>$howToRestart, failureCases=>$failureCases, notes=>$notes};
my $argsDeclaration  =
  [
   fileArg({name => 'data_file',
	    descr => 'The full path of the data_file.',
	    constraintFunc=> undef,
	    reqd  => 1,
	    isList => 0,
	    mustExist => 1,
	    format => 'See the NOTES for the format of this file'
	   }),
   
integerArg({name  => 'assay_id',
	       descr => 'RAD assay id, the entry in Assay table whose controls are being loaded.',
	       constraintFunc=> undef,
	       reqd  => 1,
	       isList => 0,
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

$self->initialize({requiredDbVersion => '3.6',
		     cvsRevision => '$Revision$',
#		     cvsTag => '$Name:  $',
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
    my $assay_id=$M->getCla->{'assay_id'};
    my $query;
    my $dbh = $M->getSelfInv->getQueryHandle();
    my $sth;


# check that the given array_id is a valid one
    $M->checkId('RAD', 'Assay', 'assay_id', $M->getCla->{'assay_id'}, 'assay_id');
    return unless $M->getOk();

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
  $M->logData('Result', 'finish parsing the headers of AssayControl data file');
  if($M->getCla->{'commit'}){print STDERR "Result:  finish parsing the headers of AssayControl data file\n";}
}

sub checkHeader{
    my $M=shift; 
    $M ->setOk(1);
    my $RV; 
    
    if(!defined $cfg_rv->{'position'}->{'control_id'}){
	$M ->setOk(0);
	$RV = "Missing header control_id in the data file which is not null in AssayControl table";
	$M ->logData("ERROR", $RV);
	if($M->getCla->{'commit'}){print STDERR "ERROR: $RV\n";}
	return;
    }
    $M->logData('Result', 'finish checking the headers of assay control data file');
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
   my $assay_id = $M->getCla->{assay_id};
   my $subclass_view;

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

# insert a row into control table
     $M->updateAssayControl($assay_id, @arr);
 
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
  
   $RV="Number of lines which have been inserted into AssayControl table in database (after header): $total_insert.";
   $M->logData('Result', $RV);
   if($M->getCla->{'commit'}){print STDERR "RESULT: $RV\n";}
     
   $RV = "Processed $cfg_rv->{n} dataline, Inserted $cfg_rv->{num_inserts} entries in AssayControl table."; 
   return $RV;
   
}

sub updateAssayControl{
    my $M = shift;
    my ($assay_id, @arr)=@_;

    my $pos=$cfg_rv->{position};
    my $control_hash;
    my $warnings;
    my $RV;
    my @attributesToNotRetrieve = ('modification_date', 'row_alg_invocation_id');     
    $control_hash->{'assay_id'} = $assay_id;
 
    my @control_attr=$M->getAttrArray("GUS::Model::RAD::AssayControl");
    my $control_hashref=$M->getAttrHashRef("GUS::Model::RAD::AssayControl");
    for (my $i=0; $i<@control_attr; $i++) {
	my $attr;
	
	$attr="$control_attr[$i]";
	
	if ( defined $pos->{$attr} && $arr[$pos->{$attr}] ne "") {
	    $control_hash->{$control_attr[$i]} = $arr[$pos->{$attr}];
	}
	 if ( ($control_hashref->{$control_attr[$i]} =~ /^Not Nullable$/)  && !defined $control_hash->{$control_attr[$i]}) {
	     $warnings = "Data file line $cfg_rv->{n} is missing attribute $control_attr[$i], which is mandatory.\nData from this data line were not loaded.\nHere $cfg_rv->{n} is the number of lines (including empty ones) after the header.\n\n";
	     $M->logData('Error', $warnings);
	     if($M->getCla->{'commit'}){print STDERR "Error: $RV\n";}
	     return; 
	 }
     }

     my $CONTROL_VIEW=join('::', 'GUS', 'Model', 'RAD', 'AssayControl');
     my $control = $CONTROL_VIEW->new($control_hash);
# check whether this row is already in the database
# if it is, get its primary key
     if ($control->retrieveFromDB(\@attributesToNotRetrieve)) {
	 $RV="Data line no. $cfg_rv->{n}\tAlready existing an entry in AssayControl\tNo insert";
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
	     $RV="Data line no. $cfg_rv->{n}\t cann't be inserted into AssayControl table\tSkip this one";
	     $M->logData('Warning', $RV);
	     if($M->getCla->{'commit'}){print STDERR "Warning: $RV\n";}
	 }
	 else{
	     $cfg_rv->{num_inserts}++;
	 }
     }
}

1;

