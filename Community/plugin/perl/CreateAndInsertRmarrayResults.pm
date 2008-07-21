##
## CreateAndInsertRmarrayResults Plugin
## $Id: $
##

# ----------------------------------------------------------
# CreateAndInsertRmarrayResults.pm
#
# This plugin queries from the db the raw data (from quantification)
# from 2 channel cDNA assays and performs a loess normalization using
# the R marray package from www.bioconductor.org.
# If the data were originally quantified with GenePix, the option of
# removing elements with specified flags prior to this normalization can
# also be exercised.
#
# The results are output into a data file which can then be used by
# GUS::Supported::Plugin::InsertRadAnalysis. The plugin will also insert a
# RAD.LogicalGroup and RAD.LogicalGroupLinks into the database and it will
# create a configuration file to be used by 
# GUS::Supported::Plugin::InsertRadAnalysis.
#
# Reference:
# Nucleic Acid Research, 2002, 30:e15
# Normalization for cDNA microarray data: a robust composite method addressing
# single and multiple slide systematic variation.
# Yee Hwa Yang,...,Terence P. Speed
#
# Created: Jan-24-2005
#
# Modifications:
# $Revision: 1622 $ $Date: 2005-06-23 12:32:30 -0400 (Thu, 23 Jun 2005) $ $Author: manduchi $
# ----------------------------------------------------------
package GUS::Community::Plugin::CreateAndInsertRmarrayResults;
@ISA = qw( GUS::PluginMgr::Plugin );

use strict;
use IO::File;
use CBIL::Util::Disp;
use GUS::PluginMgr::Plugin;

use GUS::Model::RAD::Spot;
use GUS::Model::RAD::Acquisition;
use GUS::Model::RAD::Quantification;
use GUS::Model::Study::OntologyEntry;
use GUS::Model::RAD::Assay;
use GUS::Model::RAD::ArrayDesign;
use GUS::Model::RAD::Protocol;
use GUS::Model::RAD::ProtocolParam;
use GUS::Model::RAD::LogicalGroup;
use GUS::Model::RAD::LogicalGroupLink;
use GUS::Model::RAD::GenePixElementResult;

# ----------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------

sub getArgumentsDeclaration {

  my $argumentDeclaration  =
    [
     fileArg({name => 'cfg_file',
	      descr => 'The full path of the cfg_file.',
	      constraintFunc=> undef,
	      reqd  => 1,
	      isList => 0,
	      mustExist => 1,
	      format => 'See the NOTES for the format of this file'
	     }),
     integerArg({name  => 'qid1',
		 descr => 'quantification_id 1 for the channel to be used as the numerator in loess normalization.',
		 constraintFunc=> undef,
		 reqd  => 1,
		 isList => 0
		}),
     integerArg({name  => 'qid2',
		 descr => 'quantification_id 2 for the channel to be used as the denominator in loess normalization.',
		 constraintFunc=> undef,
		 reqd  => 1,
		 isList => 0
		}),
     stringArg({name => 'fg',
		descr => 'The name of the field to be used as foreground measurement; should be one of the foreground fields of the view of RAD.ElementResultImp into which the quantifications were loaded.',
		constraintFunc => undef,
		reqd  => 1,
		isList => 0
	       }),
     stringArg({name => 'bg',
		descr => 'The name of the field to be used as background measurement. If specified, background subtraction will be performed. In this case, this argument should be one of the background fields of the view of RAD.ElementResultImp into which the quantifications were loaded.',
		constraintFunc => undef,
		reqd  => 0,
		isList => 0
	       }),
     booleanArg({name => 'print_tip',
		 descr => 'If specified, print-tip loess will be used instead of global loess.',
		 constraintFunc=> undef,
		 reqd  => 0,
		 isList => 0
		}),
     floatArg({ name => 'smoothing_param',
		descr => 'The smoother span.',
		constraintFunc=> undef,
		default => 0.4,
		reqd  => 0,
		isList => 0
	      }),
    ];

return $argumentDeclaration;
}


# ----------------------------------------------------------------------
# Documentation
# ----------------------------------------------------------------------

sub getDocumentation {
  my $purposeBrief = 'Loess normalize two-channel cDNA array data using the R marray package from BioConductor (possibly after removing flagged spots).'; 

  
my $purpose = <<PURPOSE;
This plugin takes in 2 related quantification_id's of a cDNA assay and performs loess normalization on the raw data using the  R marray package. If the data were originally quantified with GenePix, the option of removing elements with specified flags prior to this normalization can also be exercised. The plugin creates an entry in RAD.LogicalGroup and 2 entries in RAD.LogicalGroupLink and outputs a data and config file which can be used with GUS::RAD::Plugin::InsertRadAnalysis to load the normalized data into table RAD.DataTransformationResult. 
PURPOSE

  my $tablesAffected = 
    [['RAD::LogicalGroup', 'Enters a row which will be used as analysis input for this normalization process'],
     ['RAD::LogicalGroupLink', 'Enters 2 rows which correspond to the 2 input quantifications']];
  
    my $tablesDependedOn = 
      [['RAD::Protocol', 'The analysis protocol used'],
       ['RAD::ProtocolParam', 'The parameters for the protocol or its components'],
       ['Core::TableInfo', 'The table from which the table_id for RAD.Quantification is retrieved'], 
       ['Core::DatabaseInfo', 'The table from which the database_id for RAD is retrieved'],
       ['StudyOntologyEntry', 'The channels corresponding to the relevant Acquisitions']];

  my $howToRestart = <<RESTART;
RESTART

  my $failureCases = <<FAILURE_CASES;
FAILURE_CASES

  my $notes = <<NOTES;

=head2 F<cfg_file>

In this file the field element_result_table should always be provided. The flag fields should only be provided if one wants to remove flagged elements before loess normalization (currently this option is available only if the input data were quantified with GenePix).

This should be a tab-delimited text file with 2 columns: I<name> and I<value>.

Comment lines should start with #.

Each (non-comment) line should contain exactly one tab.

The required names are as follows:

B<I<element_result_table>>
    The specific view of RAD.ElementResultImp to which the element result data after quantification are loaded. FOR NOW THIS IS LIMITED TO GenePixElementResult.

The following parameters are optional:

B<I<flag_nameN>>
    The name of the I<N>th flag in the specified element_result_table which will be used to exclude elements whose flag value equals I<flag_valueN>. FOR NOW THIS IS LIMITED TO flag (from RAD.GenePixElementResult)

B<I<flag_valueN>>
    The value specified for the I<flagN>.

See the sample config file F<sample_RmarrayNormalizer.cfg> in the \$PROJECT_HOME/RAD/DataLoad/config directory.

=head1 AUTHOR

Written by Hongxian He.

=head1 COPYRIGHT

Copyright Hongxian He, Trustees of University of Pennsylvania 2005.

NOTES

  my $documentation = 
    {purpose => $purpose, 
     purposeBrief => $purposeBrief, 
     tablesAffected => $tablesAffected, 
     tablesDependedOn => $tablesDependedOn, 
     howToRestart => $howToRestart, 
     failureCases => $failureCases, 
     notes => $notes};

return $documentation;
}


# ----------------------------------------------------------------------
# create and initalize new plugin instance.
# ----------------------------------------------------------------------

sub new {
  my $class = shift;
  my $self = {};
  bless($self,$class);
  
  my $documentation = &getDocumentation();
  my $argumentDeclaration    = &getArgumentsDeclaration();
  
  $self->initialize({requiredDbVersion => 3.5,
		     cvsRevision => '$Revision: 6073 $',
		     name => ref($self),
		     revisionNotes => '',
		     argsDeclaration => $argumentDeclaration,
		     documentation => $documentation
		    });
  
  return $self;
}

# global varible
my $cfg_rv;

sub run{
  my $self = shift;

  my $dbh = $self->getQueryHandle();

  $self->logAlgInvocationId();
  $self->logCommit();
  $self->logArgs();	
 
  $self->checkArgs();

  $self->readCfgFile();

  $self->readArrayInfo();
  
  $self->retrieveElementResult($dbh);

  $self->runLoessFromR($dbh);

  $self->createLogicalGroup($dbh);

  $self->writeAnalysisCfgFile();

  $self->setResultDescr("Finished loess normalization. inserted 1 row in RAD.logicalGroup and 2 rows in RAD.logicalGroupLink");

}

#---------------
sub checkArgs{
#--------------
  my $self = shift;
  
  $self->checkFg($self->getArg('fg'));
  if ($self->getArg('bg')) {
    $self->checkBg($self->getArg('bg'));
  }
}

#---------------
sub readCfgFile{
#--------------
  my $self = shift;

  my $file = $self->getArg('cfg_file');
   
  if ($file !~ m{^/}) {
    $self->userError("The cfg_file is not specified as the absolute pathname");
  }
       
  my $fh = IO::File->new("<$file");
  unless ($fh) {
    $self->userError("Cannot not open cfg_file $file");
  }
    
  ## read in name/value pair, flags
  while(my $line = <$fh>) {
    chomp($line);
    my @attr = split(/\t/,$line);
    $cfg_rv->{$attr[0]} = $attr[1] if ($attr[0] =~ /element_result_table/);
	
    # record flags (e.g. "flag1    PCR_FAILURE")
    if ($attr[0] =~ /flag_name(\d+)/i) {
      $cfg_rv->{flag}->{$1} = $attr[1];
      push @{$cfg_rv->{flag_index}}, $1;
    } elsif ($attr[0] =~ /flag_value(\d+)/i) {
      ## a scalar value - those elements which have flagged with this value will be filtered out
      $cfg_rv->{flag_value}->{$1} = $attr[1];
      $self->logData("INFO","Excluding elements with $cfg_rv->{flag}->{$1} = $attr[1]");
    }
  }
  
  # element_result_table shoulg be given
  $cfg_rv->{fg} = $self->getArg('fg');
  if ($self->getArg('bg')) {
    $cfg_rv->{bg} = $self->getArg('bg');
  }
 
  if (!$cfg_rv->{element_result_table}) {
    $self->userError("element_result_table is not specified in the cfg_file!");
  } 

  # note currently the plugin only accepts GenePixElementResult as element_result_table, but it can be expanded to accept other elementResult tables. 
  if ($cfg_rv->{element_result_table} ne "GenePixElementResult") {
    $self->userError("The only element_result_table the plugin currently handles is GenePixElementResult.");
  } 

  $self->logData("INFO","ElementResult table: $cfg_rv->{element_result_table}");
  $self->logData("INFO","Foreground intensity measure: $cfg_rv->{fg}");

  if ($self->getArg('bg')) {
    $self->logData("INFO","Background intensity measure: $cfg_rv->{bg}");	
  }
}

# -----------------------------------
# retrieve channel name, assayId info

sub readArrayInfo{
  my $self = shift;

  my @assay_id;
  
  ### check if the quantification ids are valid
  foreach my $ch_id (1..2) {
    my $k = $ch_id-1;
    $cfg_rv->{quantification_id}->[$k] = $self->getArg("qid$ch_id");
    my $qt = GUS::Model::RAD::Quantification->new({ quantification_id => $cfg_rv->{quantification_id}->[$k] });
    if (!$qt->retrieveFromDB){
      $self->error("$cfg_rv->{quantification_id}->[$k] is not a valid quantification_id.");
    } 

    my $acq_id = $qt->getAcquisitionId;
  
    my $acq = GUS::Model::RAD::Acquisition->new({ acquisition_id => $acq_id });
    
    if (!$acq->retrieveFromDB){
      $self->error("acquisition_id $acq_id does not exist in RAD.");
    } 

    $assay_id[$k] = $acq->getAssayId;
 
    my $channel_id = $acq->getChannelId;

    my $channel = GUS::Model::Study::OntologyEntry->new({ontology_entry_id => $channel_id});

    if ($channel->retrieveFromDB){
      $cfg_rv->{channel}->[$k] = $channel->getValue();
    } 
  }

  ## the two quantifications should have the same assay_id
  if ($assay_id[0] != $assay_id[1]) {
    $self->error("The two quantifications are NOT from the same assay.");
  }
    
  ## retrieve array_design_id, in order to get array layout information
  my $assay = GUS::Model::RAD::Assay->new({ assay_id => $assay_id[1] });
  if (!$assay->retrieveFromDB){
    $self->error("Failed to retrieve from RAD::Assay for assay_id = $assay_id[1]");
  }

  $cfg_rv->{array_design_id} = $assay->getArrayDesignId;

  my $array = GUS::Model::RAD::ArrayDesign->new({ array_design_id => $cfg_rv->{array_design_id} });		
  if (!$array->retrieveFromDB){
    $self->error("Failed to retrieve from RAD::ArrayDesign for array_design_id = $cfg_rv->{array_design_id}");
  }

  ## treat each print-tip in a different subarray as a distinct print-tip 
  $cfg_rv->{ngc} = $array->getNumArrayColumns * $array->getNumGridColumns;
  $cfg_rv->{ngr} = $array->getNumArrayRows * $array->getNumGridRows;
  $cfg_rv->{nsc} = $array->getNumSubColumns;
  $cfg_rv->{nsr} = $array->getNumSubRows;
}

# -------------------------------------------------------------------------------------
# retrieve element_id, foreground, and background intensity values from ElementResult table, and store in
# $cfg_rv->{elementId}, $cfg_rv->{R}, $cfg_rv->{Rbg}, $cfg_rv->{G}, $cfg_rv->{Gbg}
# flag values in $cfg_rv->{flagValue$n}
# store grid information from Spot in $cfg_rv->{grid}

sub retrieveElementResult{
  my ($self, $dbh)  = @_;
    
  my $num_flags = defined(@{$cfg_rv->{flag_index}}) ? scalar @{$cfg_rv->{flag_index}} : 0;
    
  my $sql;
  if ($cfg_rv->{bg}) {
    $sql = "SELECT element_id, $cfg_rv->{fg}, $cfg_rv->{bg} FROM RAD.$cfg_rv->{element_result_table} WHERE quantification_id = ?";
  } else {
    $sql = "SELECT element_id, $cfg_rv->{fg} FROM RAD.$cfg_rv->{element_result_table} WHERE quantification_id = ?";
  }

  if ($num_flags > 0) {
    for my $j (@{$cfg_rv->{flag_index}}) {
      $sql .= " AND $cfg_rv->{flag}->{$j} != $cfg_rv->{flag_value}->{$j}";
    }
  }
   
  $sql .= " order by element_id";
    
  ## For my own convenience, R -> qid1 (numerator), G -> qid2 (denominator) 
  ### retrieve data from numerator channel
  my $sth = $dbh->prepare($sql);
  $sth->execute($cfg_rv->{quantification_id}->[0]);
    
  while (my $row = $sth->fetchrow_arrayref) {
    $cfg_rv->{R}->{$row->[0]} = $row->[1];
    $cfg_rv->{Rbg}->{$row->[0]} = $row->[2] if ($cfg_rv->{bg});
  }
  
  my $num_red_elements = scalar( keys %{$cfg_rv->{R}} );
    
  ### retrieve data from denominator channel
  $sth->execute($cfg_rv->{quantification_id}->[1]);
    
  while (my $row = $sth->fetchrow_arrayref) {
    $cfg_rv->{G}->{$row->[0]} = $row->[1];
    $cfg_rv->{Gbg}->{$row->[0]} = $row->[2] if ($cfg_rv->{bg});
  }

  my $num_green_elements = scalar( keys %{$cfg_rv->{G}} );

  if ($num_red_elements != $num_green_elements) {
    $self->error("The number of elements from the two channels are different.");
  }

  $cfg_rv->{num_elements} = $num_red_elements;
 
  $self->logData("RESULT", "Retrieved $num_red_elements unflagged elements from both channels from $cfg_rv->{element_result_table}.");

  $sth->finish;
}

sub runLoessFromR{
  my ($self, $dbh) = @_;
    
  my ($i, @layout, @keys);
  #sort elements by their coordinates (guess it should be ok to order by element_id, but just to be cautious)
  # modified => order by the row then column, so that we are sure the elements will be arranged as what marray expects.--Mar-18-05

  my $sql = "select element_id from rad.spot where array_design_id = ? order by to_number(array_row), to_number(array_column), 
             to_number(grid_row), to_number(grid_column), to_number(sub_row), to_number(sub_column)";
    
  my $sth = $dbh->prepare($sql);
  $sth->execute($cfg_rv->{array_design_id});
  
  my @elements;
  while (my @row = $sth->fetchrow_array) {
    push @elements, $row[0];
  }

  my $n = scalar(@elements);

  # write R,G values into a file which will be fed to R
  my $inFile = "./loess.Rinput";
  unlink ($inFile) if (-e $inFile);
    
  my $out_fh = IO::File->new("$inFile", "w");

  print $out_fh join "\t","element_id","Rf","Rb","Gf","Gb"; 
  print $out_fh "\n";

  if ($cfg_rv->{bg}) {
    $self->logData('INFO',"Background intensity will be subtracted.");
 
    foreach $i (0..($n-1)) {
      my $eid = $elements[$i];
      if (!exists $cfg_rv->{R}->{$eid}) {
	print $out_fh join "\t",$eid,"NA","NA","NA","NA";
      } else {
	print $out_fh join "\t",$eid,$cfg_rv->{R}->{$eid},$cfg_rv->{Rbg}->{$eid},$cfg_rv->{G}->{$eid},$cfg_rv->{Gbg}->{$eid}; 
      } #if/else
      print $out_fh "\n";
    } #foreach
  }
  else {
    $self->logData('INFO',"Background intensity will NOT be subtracted");
    foreach $i (0..($n-1)) {
      my $eid = $elements[$i];
      if (!exists $cfg_rv->{R}->{$eid}) {
	print $out_fh join "\t",$eid,"NA","NA","NA","NA";
      } else {
	print $out_fh join "\t",$eid,$cfg_rv->{R}->{$eid},0,$cfg_rv->{G}->{$eid},0; 
      }
      print $out_fh "\n";
    } #foreach
  }
  $out_fh->close;

  my $Rcmd = `which R`;
  chomp($Rcmd);
  if ($Rcmd =~ /Not Found/) {
    $self->error("R is needed to run this plug-in. You can run this plug-in on hera.");
  }

  $self->log('STATUS', "Calling R ...");
    
  my $sm_param = $self->getArg('smoothing_param');

  my $outFile = "./norm_".$cfg_rv->{quantification_id}->[0]."_".$cfg_rv->{quantification_id}->[1].".forRAD.txt";
  $self->logData('STATUS',"writing normalization output to $outFile");

  unlink ($outFile) if (-e $outFile);

  my $Rscript = "$ENV{GUS_HOME}/bin/marrayNormalization.R";
  unless (-e $Rscript) {
   $self->error("$Rscript does not exist!");
  }

  my $cmd;
  if ($self->getArg('print_tip')) {	
    $cmd = "echo 'inputFile=\"$inFile\";outputFile=\"$outFile\";smoothingParam=$sm_param;ngr=$cfg_rv->{ngr};ngc=$cfg_rv->{ngc};nsr=$cfg_rv->{nsr};nsc=$cfg_rv->{nsc};printTip=T' | cat - $Rscript | $Rcmd --slave --no-save";  
  } 
  else {
    $cmd = "echo 'inputFile=\"$inFile\";outputFile=\"$outFile\";smoothingParam=$sm_param;ngr=$cfg_rv->{ngr};ngc=$cfg_rv->{ngc};nsr=$cfg_rv->{nsr};nsc=$cfg_rv->{nsc};printTip=F' | cat - $Rscript | $Rcmd --slave --no-save"; 
  }
   
  $self->logData('INFO',"loess normalizing data...");
  $self->log("STATUS",$cmd);
  system("$cmd");

  $self->logData('RESULT',"Finished loess normalizing $cfg_rv->{num_elements} elements. Output is $outFile.");
  
  if (!-e $outFile || `grep "Error" $outFile`) {
    $self->error("Failed to normalize data in R.");
  }

  $sth->finish;
}

sub createLogicalGroup{
  my ($self, $dbh) = @_;      

  # retrieve study name
  my $sql = "SELECT s.name, a.name FROM study.study s, rad.studyassay sa, rad.acquisition acq, rad.quantification q, rad.assay a
            WHERE q.quantification_id = ? and q.acquisition_id=acq.acquisition_id and acq.assay_id=sa.assay_id and sa.study_id=s.study_id and acq.assay_id=a.assay_id";

  my $sth = $dbh->prepare($sql);
  $sth->execute($cfg_rv->{quantification_id}->[0]);

  my ($study_name, $assay_name);
  if (my $rowref = $sth->fetchrow_arrayref) {
    $study_name = $rowref->[0];
    $assay_name = $rowref->[1];
  }

  $study_name =~ s/\.$//;
  my $name = "Quantifications for assay $assay_name";

  my $logicalGroup = GUS::Model::RAD::LogicalGroup->new
    ( { name => "$name",
	category => 'quantification' } 
    );
  $sth = $dbh->prepare("select table_id from Core.TableInfo t, Core.DatabaseInfo d where t.database_id=d.database_id and d.name='RAD' and t.name='Quantification'");
  $sth->execute();
  my ($table_id) = $sth->fetchrow_array;

  foreach my $k (0..1) {
    my $logicalGroupLink = GUS::Model::RAD::LogicalGroupLink->new
      ( { table_id => $table_id,
	  row_id => $cfg_rv->{quantification_id}->[$k]
	});
    $logicalGroupLink->setParent($logicalGroup);
  }
  
  if ($self->getArg('commit')) {
    $logicalGroup->submit();

    $cfg_rv->{logical_group_id} = $logicalGroup->getLogicalGroupId;
  }

  $self->logData('RESULT', "1 row inserted into table RAD.LogicalGroup: name='$name'");
  $self->logData('RESULT',"2 rows inserted into RAD.LogicalGroupLink");

  $sth->finish;
}    

# --------------------------------------------------------
# insert into ProcessInvocation and ProcessInvocationParam

sub writeAnalysisCfgFile {
  my $self = shift;

  my $fname = "./marrayNorm_".$cfg_rv->{quantification_id}->[0]."-".$cfg_rv->{quantification_id}->[1].".cfg";

  my $fh = IO::File->new($fname, "w");

  print $fh "table\tRAD.Spot\n";
  print $fh "analysis_date\t",$self->getDate(),"\n";

  my $num_flags = scalar @{$cfg_rv->{flag_index}};

  my ($norm_protocol_name, $series_protocol_name);
  if ($self->getArg('print_tip')) {
    $norm_protocol_name = 'Print-tip Loess Normalization of M values with the R marray package';
  } else {
    $norm_protocol_name = 'Global Loess Normalization of M values with the R marray package';
  }
  
  my $normProtocol = GUS::Model::RAD::Protocol->new( {name => $norm_protocol_name});

  unless ($normProtocol->retrieveFromDB) {
    $self->error("failed to retrieve from rad.Protocol for name = '$norm_protocol_name'");
  }
  
  my $norm_protocol_id = $normProtocol->getProtocolId();

  my $flagProtocol = GUS::Model::RAD::Protocol->new( {name => 'Filter spots using GenePix flags'});

  unless ($flagProtocol->retrieveFromDB) {
    $self->error("failed to retrieve from rad.Protocol for name = 'Filter spots using GenePix flags'");
  }
  
  my $flag_protocol_id = $flagProtocol->getProtocolId();

  my $series_protocol_id;
  if ($num_flags) {
    if ($self->getArg('print_tip')) {
      $series_protocol_name = 'Print-tip loess normalization series with GenePix flag filtering';
    } else {
      $series_protocol_name = 'Global loess normalization series with GenePix flag filtering';
    }

    my $seriesProtocol = GUS::Model::RAD::Protocol->new( {name => $series_protocol_name});

    unless ($seriesProtocol->retrieveFromDB) {
      $self->error("failed to retrieve from rad.Protocol for name = '$series_protocol_name'");
    }

    $series_protocol_id = $seriesProtocol->getProtocolId();
  } else {
    $series_protocol_id = $norm_protocol_id;
  }

  print $fh "protocol_id\t$series_protocol_id\n";

  my $param_id = $self->getProtocolParamId($norm_protocol_id, 'R version');
  my $qry = `R --version | head -1`;
  my $r_version = (split(/\s+/,$qry))[1];

  my @params;
  push @params, [$param_id, $r_version];

  $param_id = $self->getProtocolParamId($norm_protocol_id, 'marray version');  
  my $qry = `grep Version /files/software/lib/R/library/marray/DESCRIPTION`;
  my $marray_version = (split(/\s+/,$qry))[1];

  push @params, [$param_id, $marray_version];

  $param_id =  $self->getProtocolParamId($norm_protocol_id, 'foreground_measurement');
  push @params, [$param_id,$cfg_rv->{fg}];

  $param_id =  $self->getProtocolParamId($norm_protocol_id, 'background_measurement');
  if ($self->getArg('bg')) {
    push @params, [$param_id, $cfg_rv->{bg}];
  } else {
    push @params, [$param_id, 'none'];
  } 

  if ($self->getArg('smoothing_param')) {
    $param_id =  $self->getProtocolParamId($norm_protocol_id, 'smoothing_param');
    push @params, [$param_id, $self->getArg('smoothing_param')];
  }
  
  $param_id =  $self->getProtocolParamId($norm_protocol_id, 'numerator_channel');
  push @params, [$param_id, $cfg_rv->{channel}->[0]];

  $param_id =  $self->getProtocolParamId($norm_protocol_id, 'denominator_channel');
  push @params, [$param_id, $cfg_rv->{channel}->[1]];

  $param_id =  $self->getProtocolParamId($norm_protocol_id, 'spots used for loess curve');
  if (!$num_flags) {
    push @params, [$param_id, 'all spots'];
  } else {
    push @params, [$param_id, 'all non-flagged spots'];
  }

  if ($num_flags) {
    $param_id =  $self->getProtocolParamId($flag_protocol_id, 'flag_value');
    foreach my $j (@{$cfg_rv->{flag_index}}) {
      push @params, [$param_id, $cfg_rv->{flag_value}->{$j}];
    }
  }

  foreach my $i (0..$#params) {
    my $ref = $params[$i];
    $self->logData('RESULT',"AnalysisParam [Id] $ref->[0] : [Value] $ref->[1]");
    print $fh "protocol_param_id",($i+1),"\t",$ref->[0],"\n";
    print $fh "protocol_param_value",($i+1),"\t",$ref->[1],"\n";
  }

  print $fh "logical_group_id1\t$cfg_rv->{logical_group_id}\n";
  $fh->close();

  $self->logData('RESULT',"The config file $fname used for InsertRadAnalysis plug-in has been written");
}

#-----------------------
sub getProtocolParamId{
#-----------------------
  my ($self, $protocol_id, $name) = @_;

  my $protocolParam = GUS::Model::RAD::ProtocolParam->new
	       ({ protocol_id => $protocol_id, 
		  name => $name
		 });
  
  unless ($protocolParam->retrieveFromDB) {
    $self->error("failed to retrieve from rad.ProtocolParam for protocol_id=$protocol_id and name=$name");
  }

  my $id = $protocolParam->getProtocolParamId;
  return($id);
}

#-----------
sub getDate{
#-----------
    my $self = shift;

    my ($junk,$junk,$junk,$day,$month,$year) = localtime(time);
    $year += 1900;
    $month += 1;
    $month = '0'.$month if ($month<10);
    $day = '0'.$day if ($day<10);	
    my $date = sprintf("%s-%s-%s",$year,$month,$day);
    
    return $date;
}

#-----------
sub checkFg{
#-----------
  my ($self, $fg) = @_;

  my $resultTable = GUS::Model::RAD::GenePixElementResult->new();
 
  if (!$resultTable->isValidAttribute($fg)) {
    $self->userError('Invalid --fg option: $fg.');
  }
}

#-----------
sub checkBg{
#-----------
  my ($self, $bg) = @_;

  my $resultTable = GUS::Model::RAD::GenePixElementResult->new();
 
  if (!$resultTable->isValidAttribute($bg)) {
    $self->userError('Invalid --bg option: $bg.');
  }
}

1;

