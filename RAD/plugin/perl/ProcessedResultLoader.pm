# ----------------------------------------------------------
# ProcessedResultLoader.pm
#
# Loads processed data (e.g. after normalization) data into the following tables:
# ProcessInvocation, ProcessInvocationParam, ProcessIO, ProcessResult, 
# ProcessInvQuantification
#
# Mandatory inputs: a configuration file and a data file.
# (a) the data_file, a tab-delimited text file with one header line and
#     lines for the input element results and the corresponding output value 
#     (must make sure that there are no two columns with the same name
#     in the header; see parse_header subroutine below).
# (b) the cfg_file which specifies the values for some attributes in 
#     RAD tables and mapping information for the data file. 
#
# Created: Aug-13-2002
#
# Author: Hongxian He
#
# Modifications:
#    - ProcessImplementation table will be populated beforehand, thus
#    - the plug-in will take implementation_id
#        directly for table insert. --hx, Aug-27-02
#    - check also CompositeElementResultImp for validating input_result_id. --hx, Oct-2-02
#    - to accomondate the following changes made to Process-related tables:
#        a. add an optional "description" field to ProcessInvocation, which can be specified
#		in the cfg_file.	
#        b. create a ProcessResultElementResult linking table. (not implementated yet)
#        c. create a ProcessInvQuantification linking table. --hx, Oct-14-02
#
#    - changed "--desc" option in cfg_file to a command line argument. --hx, Nov-15-2002
#    - fixed a bug that incorrectly resized the input array when the
#    - last output value is NA. --hx, Nov-15-2002
#    - converted to conform to the new CVS, GUS build system. --hx, Jan-16-2003
#        * giving the complete path name and modifying sub new{};
#        * replace log() with logData() or logAlert().
#
#    - remove *ResultImp tables. These objects are no longer used.
#    - conform the plug-in to new usages, e.g. use userError, error(),
#        getArgs(), etc. --hx, Mar-13-2003
#    - somehow has to fix a sql query, change from double quotes to
#        single qoutes. --hx, May-22-2003
#    - could not used ElementResult, CompositeElementResult objects
#        any more => change to ElementResultImp, and
#        CompositeElementResultImp objects respectively. -- hx, May-27-2003
#    - again, romoved the usgae of Imp tables. Use the objects for
#        specific views, which are loaded inline
#      using eval("require $table") statement. --hx, Jun-10-2003
#    - change the plug-in name, in order to move it to cvs at Sanger center. --hx, Jun-10-2003
#    - updated documentation. --hx, Oct-22-2003
#    -- also query databaseInfo when querying table_id for a given table name in InsertedProcessedResult(). --hx, Jan-10-2005
#
# Last modified Jan-10-2005
#
# ----------------------------------------------------------
package GUS::RAD::Plugin::ProcessedResultLoader;
@ISA = qw( GUS::PluginMgr::Plugin );

use strict;
use IO::File;

use GUS::Model::RAD3::ProcessInvocation;
use GUS::Model::RAD3::ProcessInvocationParam;
use GUS::Model::RAD3::ProcessIO;
use GUS::Model::RAD3::ProcessResult;
use GUS::Model::RAD3::ProcessImplementation;
use GUS::Model::RAD3::OntologyEntry;
#use GUS::Model::RAD3::ProcessResultElementResult;
use GUS::Model::RAD3::ProcessInvQuantification;
use GUS::Model::Core::TableInfo;

# ---------------------------
# constructor

sub new {
  my $class = shift;
  my $self = {};
  bless($self,$class);

  my $usage = 'Loads processed array data into ProcessInvocation, ProcessInvocationParam, ProcessIO, ProcessResult tables in RAD3 database.';
  
  my $easycsp =
    [
     {
	 o => 'data_file',
	 t => 'string',
	 r => 1,
	 h => 'mandatory, data filename (absolute path)',
	 
     },    
     {
	 o => 'cfg_file',
	 t => 'string',
	 r => 1,
	 h => 'mandatory, configuration filename',
     },
     {
	 o => 'testnumber',
	 t => 'int',
	 h => 'optional, number of iterations for testing',
     },
     { 
	 o => 'desc',
	 t => 'string',
	 h => 'optional, free text describing the specific process invocation, which will be stored in ProcessInvocation table.',
     },
     ]; 
  

  $self->initialize({requiredDbVersion => {RAD3 => '3', Core => '3'},
		     cvsRevision => '$Revision$', # cvs fills this in!
                     name => ref($self),
                     revisionNotes => 'make consistent with GUS 3.0',
                     easyCspOptions => $easycsp,
                     usage => $usage
                 });
  return $self;
}

# ---------------------------
# global plug-in variables
my $cfg_rv;

# ---------------------------
# run method to do the work

sub run {
  my $M   = shift;

  $M->logRAIID;
  $M->logArgs;


  if ($M->getArgs()->{'commit'}) {
      $M->logAlert("INFO","***COMMIT ON***");
  } else {
      $M->logAlert("INFO","***COMMIT OFF***");
  }
  
  $M->logAlert("INFO",join (" ","***TESTING ON",$M->getArgs()->{'testnumber'},"ITERATIONS***")) if ($M->getArgs()->{'testnumber'});
  
  $M->readCfgFile(); 

  my $num_reads = $M->readDataFile();
  
  $M->insertProcessInv();

  $M->insertProcessInvQuant();
  
  $M->insertProcessedResult($num_reads);
  
}

# ----------------------
# read in the cfg file

sub readCfgFile(){
    my $M = shift;
    my $file = $M->getArgs()->{'cfg_file'};
    my $RV = "";

    ## check the location of the cfg_file
    if ($file !~ m{^/}) {
		$M->userError("The cfg_file has to specified as the absolute pathname.");
    }

    # required parameters
    my @requiredCfgParam = qw(table_id input_column_name implementation_id invocation_date);
    my @optCfgParam = qw(input_role invocation_param_name invocation_param_value);
    
    my $fh = new IO::File;
    unless ($fh->open("<$file")) {
		$RV = join(' ','Cannot open configuration file', $file);
		$M->error($RV);
    }
    
    while (my $line=<$fh>) {
	chomp($line);
	next if ($line =~ /^\s*$/ || $line =~ /^\#.*$/);
	
	my @arr = split(/\t/, $line); #allow only tab delimiter
	if (@arr>1) {
	    $arr[1] =~ s/^\s+|\s+$//g; #remove white space
	    $arr[1] =~ s/\"|\'//g;     #remove quotes

	    if ($arr[1] ne "") {
		$arr[0] =~ tr/A-Z/a-z/; ## change to lower case
		#$arr[1] =~ tr/A-Z/a-z/; ## remove this, keep the original case,--hx, Mar-03-2004	
		
		if ( !(grep {$arr[0] =~ /$_/} @requiredCfgParam) && !(grep {$arr[0] =~ /$_/} @optCfgParam) ){
		    $RV = "$arr[0] is not expected to be in cfg_file. Please check again.";
		    $M->userError($RV);
		}
			
		## map key => value
		$cfg_rv->{$arr[0]} = $arr[1];
		
		## there can be more than 1 name/value parameter pair
		if ($arr[0] =~ /table_id(\d+)$/i) {
		    push @{$cfg_rv->{'table_index'}}, $1;
		} elsif ($arr[0] =~ /input_column_name(\d+)$/i) {
		    push @{$cfg_rv->{'input_col_index'}}, $1;
		} elsif ($arr[0] =~ /^invocation_param_name(\d+)$/i) {
		    push @{$cfg_rv->{'inv_param_index'}}, $1;
		}
	    }
	} #if
    } #while

    # -----------------
    # enforced checking
    
    ## check the required attributes
    foreach my $param (@requiredCfgParam) {
		if ($param eq "table_id" || $param eq "input_column_name") {	
	    	$param = $param."1";	
		}	
		unless ($cfg_rv->{$param}) {
	    	$M->userError("$param is not specified in cfg_file.");
		} 
    }
	
    ## check the date format
    my $date = $cfg_rv->{'invocation_date'};
    if ($date =~ /^(\d\d\d\d)\-(\d+?)\-(\d+)$/) {
		$cfg_rv->{'invocation_date'} = $date.' 00:00:00'; # 'YYYY-MM-DD 00:00:00' default DATE format
    } else {
		$M->userError("Invalid date format for invocation_id. The correct format is YYYY-MM-DD.");
    }
	    
    ## check that the given table_id is valid
    my $dbInfo = GUS::Model::Core::DatabaseInfo->new( { name => 'RAD3' } );
    foreach my $i (@{$cfg_rv->{'table_index'}}) {
	my $tableInfo = GUS::Model::Core::TableInfo->new({ 'table_id' => $cfg_rv->{'table_id'.$i} });
        $tableInfo->setParent($dbInfo);

	if (!$tableInfo->retrieveFromDB) {
	    $RV = "Invalid table_id for table_id$i: $cfg_rv->{'table_id'.$i} in cfg_file.";
	    $M->userError($RV);
	}
        ## store the table name for checking the valie input_result_id later
	$cfg_rv->{'table_name'.$i} = $tableInfo->getName();
	$cfg_rv->{'view_on_table_id'.$i} = $tableInfo->getViewOnTableId();
        my $tableName = "GUS::Model::RAD3::".$cfg_rv->{'table_name'.$i};
        eval("require $tableName");
    }

    ## check that the given implementation_id is valid
    my $processImp = GUS::Model::RAD3::ProcessImplementation->new({'process_implementation_id' => $cfg_rv->{implementation_id}});
    if (!$processImp->retrieveFromDB) {
		$M->userError("Invalid implementation_id: $cfg_rv->{implementation_id} in cfg_file.");
    }
    
    ## check to see if all the input_column_name or table_id are given
    if ( $#{$cfg_rv->{'table_index'}} != $#{$cfg_rv->{'input_col_index'}} ) {
		$M->userError("The number of table_id does not match the number of input_column_name");
    }
    
    $fh->close();
    $M->undefPointerCache();
    
    $M->logAlert('STATUS', "Finished reading cfg_file");
}

# ----------------------
# read in the data file

sub readDataFile(){
    my $M = shift;
    my $file = $M->getArgs()->{'data_file'};
    my $RV;
    
    if ($file !~ m{^/}) {
		$M->error("The data_file has to specified as the absolute pathname.");
    }

    my $fh = new IO::File;
    unless ($fh->open("<$file")) {
		$RV = join(' ','Cannot open data file', $file);
		$M->error($RV);
    }

    $M->_parseHeader($fh);

    my %col_index;
    my $line_num = 0;
    my $input_na = 0;
    my $output_na = 0;

    while (my $line=<$fh>) {
		chomp($line);
		next if ($line =~ /^\s*$/ || $line =~ /^\#.*$/); #remove empty lines

		$line_num++; # do not count empty lines

		## stop reading data after testnumber of lines
		last if (!$M->getArgs()->{'commit'} && defined $M->getArgs()->{'testnumber'} && $line_num > $M->getArgs()->{'testnumber'});
	
		my @fields = split(/\t/,$line);
	
		## $index -> row number
		my $index = $line_num - 1;
	
		## read data in each column $i
		## $cfg_rv->{inputResult}->[index] refers to the array which holds the input_result_id(s) in each row
		foreach my $i (@{$cfg_rv->{input_col_index}}) {
	    	    my $col = $cfg_rv->{'input_column_name'.$i};
		    my $input_value = $fields[$cfg_rv->{pos}->{$col}];
		    if ($input_value eq "") {
			$RV = "Line ${line_num}: column <$col> is empty in the data file";
			$M->error($RV);
		    } else {
			$cfg_rv->{inputResult}->[$index]->{$i} = $input_value;
			## if NA, then do not load this value into ProcessIO table later
			$input_na++ if ($input_value =~ /NA/i);
	    	    } #if/else 	
		} #foreach
	
		## $cfg_rv->{outputResult}: refers to the array which holds the output_value(s)
		my $output_value = $fields[$cfg_rv->{pos}->{output}];
		if ($output_value =~ /-?[\d\.]+/ ) { ## the value has to be a number
	    	    push @{$cfg_rv->{outputResult}}, $output_value;
		} elsif ($output_value =~ /NA/i) {
	    	    $output_na++;
	    	    ## need to remove all the input_values in this line from the above inputResult array!!
	    	    #@{$cfg_rv->{inputResult}->[$index]} =();
	    	    #@{$cfg_rv->{inputResultIndex}->[$index]} = ();
	    
	    	    # the above is not right! needs to resize the array by changing $#ARRAY value --Nov-15-2002
		    $#{$cfg_rv->{inputResult}}--;
		    $#{$cfg_rv->{inputResultIndex}}--;
		    $line_num--;
	    	    next;
		} elsif (!$output_value) {
	    	    $RV = "Line ${line_num}: column <output> is empty in the data file";
	    	    $M->error($RV);
		} #if/elsif
	
    } #while
    
    $fh->close();

    if ($#{$cfg_rv->{inputResult}} != $#{$cfg_rv->{outputResult}}) {
	$M->error("The size of input_result_ids does not match the size of output");
    } 


    $M->logData('INFO',"Removed $input_na NA values from input result") if ($input_na);
    $M->logData('INFO',"Removed $output_na NA values from output result (skipping $output_na lines from data_file)") if ($output_na);
    
    my $num = $#{$cfg_rv->{outputResult}}+1;
    $M->logData('INFO', "Finished reading data file: $num lines are read in");
    
    return $num;
}

# --------------------------------------------------------
# insert into ProcessInvocation and ProcessInvocationParam

sub insertProcessInv (){
    my $M = shift;
    
    ## set ProcessInvocation
    my $inv_arg = { process_implementation_id => $cfg_rv->{'implementation_id'}, 
		    process_invocation_date => $cfg_rv->{'invocation_date'}
		};
  
    ## description field is optional
    $inv_arg->{description} = $M->getArgs()->{desc} if (defined $M->getArgs()->{desc});
     
    my $prcInv = GUS::Model::RAD3::ProcessInvocation->new($inv_arg);
    
    ## set ProcessInvocationParam
    my $inv_param_arg; 
    my $num_param = 0;
    foreach my $i (@{$cfg_rv->{'inv_param_index'}}) {
	$inv_param_arg = { name => $cfg_rv->{'invocation_param_name'.$i},
	 		value => $cfg_rv->{'invocation_param_value'.$i},
	};

	my $prcInvParam = GUS::Model::RAD3::ProcessInvocationParam->new($inv_param_arg);
	
	# set parent
	$prcInvParam->setParent($prcInv);
	$num_param++;
    }
    
    ### everything is ready, now submit ...
    $prcInv->submit();
    
    ### need to retrieve the process_invocation_id, which is the foreign key to process_invocation_id in table ProcessIO
    unless ($cfg_rv->{'process_inv_id'} = $prcInv->getId()) {
	$M->error("Failed to retrieve the process_invocation_id for the ProcessInvocation entry just submitted");
    }

    my $RV = "1 row is inserted into ProcessInvocation table; $num_param rows are inserted into ProcessInvocationParam table";
    $M->logData('RESULT',$RV);
    
    $M->undefPointerCache();
}

# ---------------------------------------------------------------
# load data into ProcessInvQuantification, a linking table

sub insertProcessInvQuant(){
    my $M = shift;
    
    my (%q);
    ## get quantification_id for each column of input_result_id
    foreach my $i (@{$cfg_rv->{input_col_index}}) {
	my $iid;
	my $j = 0;
	while(!$iid) {
	    $iid = $cfg_rv->{inputResult}->[$j]->{$i} if ($cfg_rv->{inputResult}->[$j]->{$i});
	    $j++;
	}
	
        my $qid_ref = $M->_get_quant_id($iid, $i);
	
	foreach my $tp (@{$qid_ref}) {
	    $q{$tp} = 1 unless (defined $q{$tp});
	}
    }

    my @qids = sort {$a<=>$b} (keys (%q));
    foreach my $q (@qids) {
	my $piq = GUS::Model::RAD3::ProcessInvQuantification->new({ quantification_id => $q, process_invocation_id => $cfg_rv->{process_inv_id} });
	$piq->submit;
    }
    
    $M->logData('RESULT',join " ", ($#qids+1), "rows are inserted to ProcessInvQuantification table");
    
    $M->undefPointerCache;
    
}

# ----------------------------
# insert ProcessedResult table

sub insertProcessedResult(){
    my $M = shift;
    my ($num_elements) = @_;
    my $RV;

    my $num_io = 0;
    my ($i,$j);
    
    for ($i=0; $i<$num_elements; $i++) {
	
	## indicate where we are at the moment
	if ( ($i+1)%200 == 0) {
	    $RV = "Finished inserting ".($i+1)." lines of data.";
	    $M->logAlert($RV);
	}
	
	## insert into ProcessResult table
	my $output_result = $cfg_rv->{outputResult}->[$i];

	my $prcResult = GUS::Model::RAD3::ProcessResult->new({value => $output_result });
	
	## insert into ProcessIO table with input_result_id(s)
	foreach $j (@{$cfg_rv->{input_col_index}}) {
	    
	    my $input_result_id = $cfg_rv->{inputResult}->[$i]->{$j};		    
	    next if ($input_result_id =~ /NA/i);
	    
            # check whether the input_result is valid
	    unless ($M->_checkValidInput($input_result_id, $j)) {
            	$RV = "$input_result_id is not a valid input_result_id. The valid id should already exist in table $cfg_rv->{'table_name'.$j}";
            	$M->error($RV);
            }
	    
	    my $io_arg = { table_id => $cfg_rv->{'table_id'.$j}, 
		   input_result_id => $input_result_id,
		   process_invocation_id => $cfg_rv->{'process_inv_id'},
	    };

	    if ($cfg_rv->{'input_role'.$j}) {
		$io_arg->{input_role} = $cfg_rv->{'input_role'.$j};
	    }
		
	    my $procIO = GUS::Model::RAD3::ProcessIO->new($io_arg);
	    $procIO->setParent($prcResult);
            # or $prcResult->addChild($procIO);
	  
	    $num_io++; 
	}
	
	## deep submit
	$prcResult->submit();
	$M->undefPointerCache();	

	#?
	#load ProcessResultElementResult...
    }

    $RV = "$num_elements rows are inserted into ProcessResult table; $num_io rows are inserted into ProcessIO table";
    $M->logData('RESULT', $RV);
}


# ------------------------------------------------------
# quantication_id = $M->_get_quant_id(id, flag)

sub _get_quant_id{
    my $M = shift;
    my ($id, $i) = @_;

    my @qids;
    
    ## table is the view of the ElementResultImp
    my $view_id = $cfg_rv->{'view_on_table_id'.$i};
    my $table = "GUS::Model::RAD3::".$cfg_rv->{'table_name'.$i};

    if ($view_id && $view_id==2953) {

      # currently, there is an error with the object invovling table AgilentElementResult, 
      # we need to avoid to retrieve column p_val_feat_eq_bg. --hongxian, Aug-11-2004
      my @attributesNotToRetrieve;
      if ($cfg_rv->{'table_name'.$i} eq 'AgilentElementResult') {
	@attributesNotToRetrieve = qw(p_val_feat_eq_bg);
      } else {
	@attributesNotToRetrieve = ();
      }
	my $ele_result = $table->new( {element_result_id => $id} );
	unless ($ele_result->retrieveFromDB(\@attributesNotToRetrieve)) {
	    $M->error("Failed to create an instance of $table with element_result_id = $id");
	}
	push @qids, $ele_result->getQuantificationId;
	
    } elsif ($view_id && $view_id == 2965) {

	my $ele_result = $table->new( {composite_element_result_id => $id} );
        unless ($ele_result->retrieveFromDB) {
            $M->error("Failed to create an instance of $table with composite_element_result_id = $id");
        }
        push @qids, $ele_result->getQuantificationId;

    } else {

	my $dbh = $M->getQueryHandle();

        my $sql = "SELECT process_invocation_id from RAD3.ProcessIO WHERE output_result_id = $id";
        my $sth = $dbh->prepare($sql);
        $sth->execute();

        my $inv_id;
        if ($inv_id = $sth->fetchrow_array) {
          $sql = "SELECT quantification_id from RAD3.ProcessInvQuantification WHERE process_invocation_id = ?";
          $sth = $dbh->prepare($sql);
          $sth->execute($inv_id);
	    
	  while (my $row = $sth->fetchrow_array) {
	      push @qids, $row;
	  } #while

        } else {
            $M->error("Failed to retrieve any quantification_id from RAD3.ProcessInvQuantification for process_invocation_id = $inv_id");
        } #if/else

    } #if/elsif/else

    return \@qids;
}

# -----------------------------------------------------------
# check there can not be duplicate column names in the header

sub _parseHeader{
	my  $M=shift;
  	my ($fh) = @_;

  	my $line ="";
	while ($line =~ /^\s*$/) {
    	    $line = <$fh>;
  	}
  
  	my @input_col_names;
  	foreach my $i (@{$cfg_rv->{input_col_index}}) {
      	    my $col = $cfg_rv->{'input_column_name'.$i};
      	    push @input_col_names, $col;
  	}

  	my %headers;
  	my @arr = split (/\t/, $line);
  	for (my $i=0; $i<@arr; $i++) {
      	    my $name = $arr[$i];
      	    $name =~ s/^\s+|\s+$//g;
      	    $name =~ s/\"|\'//g;
      	    #$name =~ tr/A-Z/a-z/; --removed, --hx, Mar-03-2004
  
      	    if ($headers{$name}) {
	    	$fh->close();
	    	$M->error("No two columns can have the same name in the data file header");
      	    } elsif ($name ne "output" && (!grep {$name eq $_} @input_col_names)) {
	    	$M->error("$name is not a correct input_column_name as specified in cfg_file");
      	    } else {
	    	$headers{$name} = 1;
      	    }

      	    $cfg_rv->{pos}->{$name} = $i;
  	} #for
  
  	unless ($headers{output}) {
            $M->error("There is no <output> column in the header");
  	}	  

  	$M->logAlert('STATUS', join (" ","Finished parsing the header in data_file: ", ($#arr+1), "columns are found"));
}

# -------------------------------------------------------------------------
# check if the input_result_id exists in ElementResult, CompositeElementResult, or ProcessResult

sub _checkValidInput() {
    my  $M=shift;
    my ($input_result_id, $i) = @_;
    
    my $table = "GUS::Model::RAD3::".$cfg_rv->{'table_name'.$i};
      
    my $view_id = $cfg_rv->{'view_on_table_id'.$i};
    my $inputResult;

    if ($view_id && $view_id==2953) {
       # view on ElementResultImp

      # currently, there is an error with the object invovling table AgilentElementResult, 
      # we need to avoid to retrieve column p_val_feat_eq_bg. --hongxian, Aug-11-2004
      my @attributesNotToRetrieve;
      if ($cfg_rv->{'table_name'.$i} eq 'AgilentElementResult') {
	@attributesNotToRetrieve = qw(p_val_feat_eq_bg);
      } else {
	@attributesNotToRetrieve = ();
      }
      
      $inputResult = $table->new( {element_result_id => $input_result_id } );
      return 1 if ($inputResult->retrieveFromDB(\@attributesNotToRetrieve));
    } elsif ($view_id && $view_id==2965) {
        # view on CompositeElementImp
	$inputResult = $table->new( {composite_element_result_id => $input_result_id } );
	return 1 if ($inputResult->retrieveFromDB);
    } else {	    
        # ProcessResult Table
	$inputResult = $table->new( {process_result_id => $input_result_id } );
	return 1 if ($inputResult->retrieveFromDB);
    }

    return 0;
}

1;

__END__

=head1 NAME

GUS::RAD::Plugin::ProcessedResultLoader

=head1 SYNOPSIS

ga GUS::RAD::Plugin:ProcessedResultLoader B<[options]> B<--cfg_file> cfg_file B<--data_file> data_file

=head1 DESCRIPTION

This plug-in loads the processed data (e.g. after normalization) resulted from one particular process into the following tables: ProcessInvocation, ProcessInvocationParam, ProcessIO, ProcessResult, and ProcessInvQuantification. 

=head1 ARGUMENTS

B<--cfg_file> F<config_file> [require the absolute pathname]   
    The configuration file contains the mapping information for input results, including table_id, input_column_name (column names appearing in the header of data_file), and input_role (optional). It also contains other information including the implementation_id, invocation_date, etc. See the sample config file F<sample_ProcessedResultLoader.cfg> in the $PROJECT_HOME/RAD/config/ directory.

B<--data_file> F<data_file>  [require the absolute pathname]  
    The file contains the input_result_ids and corresponding output values. There is one header line which specifies what each column represents.

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

B<--desc> I<STRING>
    Free text describing the specific process invocation, which will be stored in ProcessInvocation table.

B<--user> I<STRING>
    The user name, used to set value for row_user_id. The user must already be in Core::UserInfo table. [Default: from $HOME/.gus.properties file]

B<--group> I<STRING>
    The group name, used to set value for row_group_id. The group must already be in Core::GroupInfo table. [Default: from $HOME/.gus.properties file]

B<--project> I<STRING>
    The project name, used to set value for row_project_id. The project must already be in Core::ProjectInfo table. [Default: from $HOME/.gus.properties file]

=head1 NOTES

Before one can run this plug-in, the Perl objects that will be loaded need to be created, if these objects do not exist yet.

The plug-in outputs to STDERR the number of lines that have been loaded from F<data_file> (I<excluding> the header and empty lines). Any warning statement (for example, those regarding data lines that have not been loaded into RAD3) will be output to STDOUT for possible redirection to a log file. 

Make sure that the F<.gus.properties> file of the user contains the correct login name [RAD3rw]. Also, if the group and project differ from the default values in F<.gus.properties>, I<please specify the proper group and project name on the command line using --group and --project options respectively>. 

The process referred to should have been already loaded in the ProcessImplementation table in RAD3. The corresponding process_implementation_id needs to be specified in F<cfg_file>.

=head2 F<cfg_file> 

It should be a tab-delimited text file with 2 column: I<Name> and I<Value>. The order and case of these columns are not important, but it is recommended to follow the template for the sake of consistency.

Comments line start with #.

Each (non-comment) line should contain exactly only one tab.

Do not use special symbols (like "NA" or similar) for empty field, either leave the field empty or delete the entire line.

The required parameters are as follows:

B<I<table_idN>> 
    The table_id (from GUS::Model::Core::TableInfo) for the I<N>th column of input_result_id(s) in data_file. 

B<I<input_column_nameN>> 
    The column name in the header in the data_file for the I<N>th column of input_result_id's in data_file.

B<I<input_roleN>> [Optional]
    The input_role for the I<N>th  column of input_result_id's in data_file. 

B<I<implementation_id>>
    The process_implementation_id for the specific process implementation. It should be taken from ProcessImplementation table. 

B<I<invocation_date>>
    The date when the specific implementation is invoked. The correct format is YYYY-MM-DD.

B<I<invocation_param_nameN>> [Optional]
    The name of the I<N>th parameter in ProcessInvocationParam. 

B<I<invocation_param_valueN>> [Optional]
    The value of the I<N>th parameter in ProcessInvocationParam.

=head2 F<data_file>

The data file should be in tab-delimited text format with one header line and multiple lines for input element_results and corresponding output value. Each line should contain the same number of tab/fields. There can be multiple input_result_ids but only one output value per line. The header specifies the column names for the input_result_ids (specified by I<input_column_nameN> in F<cfg_file>) and the output value (specified by the column name I<output> in F<data_file>).

Please make sure that the input_result_id is valid (must already be in GUS::Model::RAD3::ElementResultImp, GUS::Model::RAD3::CompositeElementResultImp, or GUS::Model::RAD3::ProcessResult table). If input_result_id = "NA", then this entry will be discarded [Note: Only this input entry will be removed. If there are other valid entries in the same line, they will be loaded accordingly.]

The output value can be a number or "NA". In the latter case, the I<entire> line will be automatically removed. An error will occur if the column for output value is empty.

B<Caution>: The data_file should contain only the data involved in one
specific process and not combine more than one process.  For example,
if the user has results from normalization of I<n> different assays, then
this plug-in needs to be run I<n> times (leading to I<n> different process
invocations), once per assay.  Accordingly, I<n> separate data files will need to be
created.  All elements in the same input column of the data file
should correspond to the same quantification_id and the data_file
should contain all input columns corresponding to data which yielded the
results in the output column. For example, if the process corresponds
to computing the average of spot values over I<n> arrays, then there should be
I<n> input columns.  

=head1 AUTHOR

Written by Hongxian He.

=head1 COPYRIGHT

Copyright Hongxian He, Trustees of University of Pennsylvania 2003. 



