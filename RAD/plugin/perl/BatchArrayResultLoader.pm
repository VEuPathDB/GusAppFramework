# ----------------------------------------------------------
# BatchArrayResultLoader.pm
#
# A wrapper for loading data into ElementResultImp and CompositeElementResultImp,
# from outputs from standard feature extraction softwares.
# 
# Created: Nov-21-2003
# Elisabetta Manduchi and Hongxian He
#
# $Revision$Date: $ Author: Elisabetta, Hongxian
# ----------------------------------------------------------
package GUS::RAD::Plugin::BatchArrayResultLoader;
@ISA = qw( GUS::PluginMgr::Plugin );

use strict;
use IO::File;
use CBIL::Util::Disp;
use GUS::PluginMgr::Plugin;

use GUS::RAD::FileTranslator;
use GUS::RAD::Utils::InformationQueries;

use GUS::Model::RAD3::RelatedQuantification;


#--------
sub new {
#--------
  my ($class) = @_;
  my $self = {};
  bless($self,$class);
  my $purposeBrief = 'Loads into the appropriate view of RAD3.(Composite)ElementResultImp quantification data from a collection of files all having the same format.';
  
  my $purpose = <<PURPOSE;
This plugin takes as input: (i) a study_id or a file with a list of assay_ids, (ii) an xml configuration file, and (iii) a quantification protocol or software (one of: I<MAS4.0, MAS5.0, GenePix, ArrayVision, RMAExpress, and MOID>). The plugin then uploads into the appropriate view of RAD3.(Composite)ElementResult the data contained in the uri files corresponding to all those quantifications from these assays, which have the specified quantification protocol. <BIf any such file has a format that does not correspond to that specified by the configuration file (e.g. different header names, etc.), it will not be uploaded>.
PURPOSE
  
  my $tablesAffected = [['RAD3::ElementResultImp', 'Enters the quantification results here, if the protocol is GenePix or ArrayVision'], ['RAD3::CompositeElementResultImp', 'Enters the quantification results here, if the protocol is MAS4.0, MAS5.0, RMAExpress, or MOID'], ['RAD3::RelatedQuantification', 'Inserts entries in this table for the quantifications at stake, if missing']];
  
  my $tablesDependedOn = [['RAD3::Study', 'The study, if study_id is passed in'], ['RAD3::StudyAssay', 'The table linking the assays to the study, if study_id is passed in'], ['RAD3::Assay', 'The assays passed in'], ['SRes::ExternalDatabaseRelease', 'The external database relase for the assays passed in'], ['RAD3::Array', 'The array(s) used in the assays passed in' ], ['RAD3::OntologyEntry', 'The platform and substrate information for the arrays involved'], ['RAD3::Acquisition', 'The acquisitions for the assays passed in'], ['RAD3::Quantification', 'The quantifications for the assays passed in'], ['RAD3::RelatedAcquisition', 'The associations between the acquisitions for the assays passed in'], ['RAD3::RelatedQuantification', 'The associations between the quantifications for the assays passed in'], ['RAD3::Channel', 'The channels for the acquisitions relative to the assays passed in'], ['RAD3::Protocol', 'The quantification protocol of interest']];
  
  my $howToRestart = <<RESTART;
RESTART
  
  my $failureCases = <<FAILURE_CASES;
FAILURE_CASES
  
  my $notes = <<NOTES;
B<Only one of study_id or assay_id_file should be specified in the argument line.> 

=head2 F<assay_id_file>

To be used when either not all assays in a study should be considered or when assays from different studies should be considered. Their assay_ids should be provided through this text file. One assay_id per line, empty lines are ignored.

=head2 F<cfg_file>

This should be an xml file whose format should be that specified in GUS/RAD/config/ResultFileParserCfg.dtd.
This is used to map headers in the software output files to attributes of the appropriate RAD view of (Composite)ElementResultImp as well as to RAD coordinates.

=head2 F<Warning (for non-CBIL Instances)>

For local installations of RAD which differ from the CBIL database,
some lines of this plugin will need to be modified, to accomodate
hard-coded information. You might need to modify any piece of code
labelled as 'HARD-CODED' in the comments below.

=head1 AUTHOR

The following individuals have collaborated in the design and coding of this plugin and the Utils called by it: Hongxian He, Junmin Liu, Elisabetta Manduchi, Angel Pizarro, Trish Whetzel.

=head1 COPYRIGHT

Copyright CBIL, Trustees of University of Pennsylvania 2003. 
NOTES

  my $documentation = {purpose=>$purpose, purposeBrief=>$purposeBrief,tablesAffected=>$tablesAffected,tablesDependedOn=>$tablesDependedOn,howToRestart=>$howToRestart,failureCases=>$failureCases,notes=>$notes};
  
  my $argsDeclaration  =
    [
     integerArg({name  => 'study_id',
		 descr => 'The study whose quantification results (obtained with the specified protocol) should be loaded, if one desires to load results for all such quantifications in a study.',
		 constraintFunc => undef,
		 reqd  => 0,
		 isList => 0
		}),
     fileArg({name => 'assay_id_file',
	      descr => 'The (full path of the) file containing the list of assay_ids for all the assays whose quantification results (obtained with the specified protocol) should be loaded. ',
	      constraintFunc => undef,
	      reqd  => 0,
	      isList => 0,
	      mustExist => 0,
	      format => 'See the NOTES for the format of this file'
	     }),
     fileArg({name => 'cfg_file',
	      descr => 'The full path of the cfg_file.',
	      constraintFunc => undef,
	      reqd  => 1,
	      isList => 0,
	      mustExist => 1,
	      format => 'See the NOTES for the format of this file'
	     }),

     stringArg({name  => 'software',
		 descr => "The quantification protocol for the quantifications that should be loaded. Should be one of 'mas4', 'mas5', 'genepix', 'arrayvision', 'rmaexpress', 'moid'.",
		 constraintFunc => \&isValidSoftware,
		 reqd  => 1,
		 isList => 0
		}),
     stringArg({name  => 'log_path',
		 descr => "The absolute path of the directory where the log files and the data files will be created. The user should have write permission to that directory. This is also where the parsed data files go.",
		 constraintFunc => undef,
		 reqd  => 1,
		 isList => 0
		}),
     integerArg({name  => 'test_num_line',
		 descr => "The number of lines in the data file for the first retrieved assay to be tested for loading.",
		 constraintFunc => undef,
		 reqd  => 0,
		 isList => 0
		}),
     integerArg({name  => 'test_num_assay',
		 descr => "The number of assays to be tested for loading.",
		 constraintFunc => undef,
		 reqd  => 0,
		 isList => 0
		}),
     stringArg({name  => 'skip',
		 descr => "The list of assay_ids within the specified study which will be skipped for loading.",
		 constraintFunc => undef,
		 reqd  => 0,
		 isList => 1
		}),
    ];

  $self->initialize({requiredDbVersion => {RAD3 => '3', Core => '3'},
		     cvsRevision => '$Revision$',
		     cvsTag => '$Name$',
		     name => ref($self),
		     revisionNotes => '',
		     argsDeclaration => $argsDeclaration,
		     documentation => $documentation
		    });
  return $self;
}

# global hash reference
my $global_ref;

# _BEGIN HARD-CODED: The hash values should be replaced with the corresponding RAD3.Protocol.protocol_id in your RAD instance
$global_ref->{'software_name2id'} = 
  {
   'mas4'=>303, 
   'mas5'=>284, 
   'genepix'=>15, 
   'arrayvision'=>3, 
   'rmaexpress'=>904, 
   'cel4'=>926, 
   'cel5'=>283,
   'moid' => 563,
  };
# _END HARD-CODED

$global_ref->{'array_subclass_view'} = 
  {
   'mas4'=>'ShortOligoFamily', 
   'mas5'=>'ShortOligoFamily', 
   'genepix'=>'Spot', 
   'arrayvision'=>'Spot', 
   'rmaexpress'=>'ShortOligoFamily',
   'moid' => 'ShortOligoFamily',
  };

$global_ref->{'result_subclass_view'} = 
  {
   'mas4'=>'AffymetrixMAS4', 
   'mas5'=>'AffymetrixMAS5', 
   'genepix'=>'GenePixElementResult', 
   'arrayvision'=>'ArrayVisionElementResult', 
   'rmaexpress'=>'RMAExpress',
   'moid' => 'MOIDResult',
  };

my @SINGLE_CHANNEL = qw(mas4 mas5 rmaexpress moid);

#--------
sub run {
#--------
  my ($self) = @_;
  
  $self->logAlgInvocationId();
  $self->logCommit();
  $self->logArgs();

  my $dbh = $self->getQueryHandle();
  $self->checkArgs($dbh);

  $global_ref->{'protocol_id'} = $global_ref->{'software_name2id'}->{$self->getArgs->{'software'}};

  my $infoQ = GUS::RAD::Utils::InformationQueries->new($dbh);

  my $cfg_file = $self->getArgs->{'cfg_file'};

  my $log_path = $self->getArgs->{'log_path'}; 
  $log_path = $log_path."/" unless ($log_path =~ m{.*/$});
  unless (-e "$log_path") {
    $self->userError("directory $log_path does not exist.");
  }

  my @assayIds = @{$self->getAssayIds($dbh)};

  # skip certain assays if specified
  if ($self->getArgs->{skip}) {
    my @skip_lists = @{$self->getArgs->{skip}};
    my $str = join ",", @skip_lists;
    $self->log("STATUS","The following assays will be skipped for data loading: $str");
    $self->logData("STATUS","The following assays will be skipped for data loading: $str");

    my @to_be_loaded;
    foreach my $i (@assayIds) {
      push @to_be_loaded, $i if (scalar(grep {$_ == $i} @skip_lists)==0);
    }
    @assayIds = @to_be_loaded;
  }
  
  my $num_assays = scalar(@assayIds);
  $self->log("STATUS", "There are $num_assays assays whose results will be loaded.");
  $self->logData("RESULT", "There are $num_assays assays whose results will be loaded.");

  my $assay_count = 0;
  foreach my $assay_id (@assayIds) {
    $self->log("STATUS", "Working on assay $assay_id.");

    # angel: create FileTranslator class to handle generation of the input file for ARL
    my $fileTranslator;
    my $ft_log_file = $log_path.".".$assay_id.".filetranslator.log";
    eval {
      $fileTranslator = GUS::RAD::FileTranslator->new($cfg_file, $ft_log_file, $self->getArgs->{'debug'});
    };

    if ($@) {
      # failed in validating cfg file
      $self->userError("The mapping configuration file '$cfg_file' failed the validation. Please see the log file $ft_log_file.");
    };
    
    $self->retrieveQuantifications($dbh, $assay_id);
    
    # If 2-channel data, the entries in the quantifications array alternate b/w
    # red qid, associated green qid, ...
    my @quantifications = @{$global_ref->{$assay_id}->{'quantifications'}};
    
    # 2-channel data
    if ($global_ref->{'is_2channel'}==0) {
      foreach my $qid (@quantifications) {
	$self->log("STATUS", "Working on quantification $qid.");
	
	if ($self->checkExistingResults($dbh, $qid) == 0) { 
	  my $quantInfo = $infoQ->getQuantificationInfo($qid);
	  my $data_file = $self->createDataFile($dbh, $assay_id, $quantInfo, $fileTranslator);
	  
	  if (defined $data_file) {
	    $self->runArrayResultLoader($dbh, $log_path, $data_file, $global_ref->{$assay_id}->{'arrayInfo'}, $qid);

	    $self->parseARlogs($log_path, $qid);
	  } else {
	    # The input file failed to validate against the config file
	    $self->log("ERROR", "The input file for quantification $qid failed validation. The results for this quantification cannot be loaded. Please see the log file $ft_log_file.");
	  }
	} else {
	  $self->logData("WARNING", "The results for quantification_id $qid already exist in the database, thus will not be loaded");
	}
      } #foreach 
    }
    else { # 1 channel data
      for my $i (0..(scalar(@quantifications)/2-1)) {
	my $Rqid = $quantifications[2*$i];
	my $Gqid = $quantifications[2*$i+1];
	$self->log("STATUS", "Working on quantifications $Rqid, $Gqid.");
	if ($self->checkExistingResults($dbh, $Rqid) == 0 && $self->checkExistingResults($dbh, $Gqid) == 0) { 
	  my $quantInfo = $infoQ->getQuantificationInfo($Rqid);
	  my $data_file = $self->createDataFile($dbh, $assay_id, $quantInfo, $fileTranslator);
	  if (defined $data_file) {
	    $self->runArrayResultLoader($dbh, $log_path, $data_file, $global_ref->{$assay_id}->{'arrayInfo'}, $Rqid, $Gqid);
	    $self->parseARlogs($log_path, $Rqid, $Gqid);
	  } else {
	    $self->log("ERROR", "The input file for quantification ($Rqid,$Gqid) failed validation. The results for this quantification cannot be loaded. Please see the log file $ft_log_file.");
	  }
	} else { # results already exist
	  $self->logData("WARNING", "The results for at least one of the quantification_ids $Rqid, $Gqid already exist in the database, thus neither will be loaded");
	} #if/else
	
      } #for ($i)
    } #if/else

    $assay_count++;
    # test only 1 assay
    if ($self->getArgs->{test_num_line}) {
      last;
    }
    
    if ($self->getArgs->{test_num_assay} && $assay_count >=$self->getArgs->{test_num_assay} ) {
      last;
    } 

  } #foreach
  $self->setResultDescr("Processed $assay_count assays");
} #sub

###################################################################
# isValidSoftware ($software)
# Function: 
# -- checks that the $software string is one of those specified in
#    the usage
###################################################################
#--------------------
sub isValidSoftware {
#--------------------
  my ($self, $software) = @_;
  my @validSoftwares = qw(mas4 mas5 genepix arrayvision rmaexpress moid);
  #if ($software ne 'mas4' && $software ne 'mas5' && $software ne 'genepix' && $software ne 'arrayvision' && $software ne 'rmaexpress') {
  my @matching = grep {$software eq $_} @validSoftwares;

  if (scalar(@matching)==0) {
    my $errorString = "--software should be one of ";
    $errorString .= join ",", map{"\'$_\'"} @validSoftwares;
    $self->userError($errorString.".");
  }
}

###################################################################
# ckechArgs ($dbh)
# Function: 
# -- checks that exactly one of study_id or assay_id_file is given
#    as an argument
# -- checks that the study_id (if given) is a valid one
###################################################################
#--------------
sub checkArgs {
#--------------
  my ($self, $dbh) = @_;

  if (!defined($self->getArgs->{'study_id'}) && !defined ($self->getArgs->{'assay_id_file'})) {
    $self->userError('Must provide one of --study_id or --assay_id_file.');
  }  
  if (defined($self->getArgs->{'study_id'}) && defined ($self->getArgs->{'assay_id_file'})) {
    $self->userError('Can pass in only one of --study_id or --assay_id_file.');
  }
 if (defined($self->getArgs->{'study_id'})) {
   my $study_id = $self->getArgs->{'study_id'};
   my $sth = $dbh->prepare("select count(*) from RAD3.Study where study_id=$study_id");
   $sth->execute();
   my ($count) = $sth->fetchrow_array();
   $sth->finish();
   if ($count != 1) {
     $self->userError('Invalid study_id');
   }
 }
}

###################################################################
# getAssayIds ($dbh)
# Function: 
# -- checks that the assay_ids in the assay_id_file (if given)
#    are valid ones
# -- returns a reference to an array of assay_ids
###################################################################
#----------------
sub getAssayIds {
#----------------
  my ($self, $dbh) = @_;

  if (defined($self->getArgs->{'study_id'})) {
    my $infoQ = GUS::RAD::Utils::InformationQueries->new($dbh);
    my $study = $infoQ->getStudyInfo($self->getArgs->{'study_id'});
    return $study->{'assays'};
  }
  else {
    my @r;
    my $sth = $dbh->prepare("select count(*) from RAD3.Assay where assay_id=?");
    my $file = $self->getArgs->{'assay_id_file'};
    my $fh = new IO::File;
    unless ($fh->open("<$file")) {
      $self->error("Could not open file $file.");
    }
    while (my $line=<$fh>) {
      $line =~ s/^\s+|\s+$//g;
      if ($line eq "") {
	next;
      }
      $sth->execute($line);
      my ($count) = $sth->fetchrow_array();
      $sth->finish();
      if ($count != 1) {
	$self->userError('$line is an invalid assay_id');
      }
      push (@r, $line);
    }
    return \@r;
  }
}

#######################################################################
# retrieveQuantifications ($dbh, $assay_id)
# Function: 
# -- retrieves array information for the given assay and stores it in
#    $global_ref->{$assay_id}->{'arrayInfo'}
# -- retrieves quantification_id's for the given assay and stores them
#    in $global_ref->{$assay_id}->{'quantifications'}
#    alternating red and green quantifications when 2-channel
# -- calls to check related quantifications and to insert if needed
#######################################################################
#-----------------------
sub retrieveQuantifications{
#-----------------------
  my ($self, $dbh, $assay_id) = @_;
  
  my $infoQ = GUS::RAD::Utils::InformationQueries->new($dbh);
  my $assayInfo = $infoQ->getAssayInfo($assay_id);
  
  # get arrayInfo
  $global_ref->{$assay_id}->{'arrayInfo'} = $infoQ->getArrayInfo($assayInfo->{'array_id'});
  
  # get acquisitions
  my @acqs = @{$assayInfo->{'acquisitions'}};
  
  # get quantifications
  if (scalar(grep {$self->getArgs->{'software'} eq $_} @SINGLE_CHANNEL) ==1) {
    # if the quantification is from MAS4, MAS5, RMAExpress or MOID
    $global_ref->{'is_2channel'} = 0;
    
    foreach my $acq_id (@acqs) {
      my $cel_quant_id = undef;
      my $acqInfo =  $infoQ->getAcquisitionInfo($acq_id);
      
      foreach my $quant_id (@{$acqInfo->{quantifications}}) {
	my $quantInfo = $infoQ->getQuantificationInfo($quant_id);

	if(!defined $cel_quant_id && ($quantInfo->{'protocol_id'} == $global_ref->{'software_name2id'}->{'cel4'} || $quantInfo->{'protocol_id'} == $global_ref->{'software_name2id'}->{'cel5'})) {
	  $cel_quant_id = $quantInfo->{'quantification_id'};
	  next;
	} #if
	
	if($quantInfo->{'protocol_id'} == $global_ref->{'protocol_id'}) {
	  my $quant_id =  $quantInfo->{'quantification_id'};
	  push (@{$global_ref->{$assay_id}->{'quantifications'}}, $quant_id);
	  # relate CEL and other quantifications if CEL exists
	  $self->relateQuantifications($cel_quant_id, $quant_id) if (defined $cel_quant_id);
	  $self->relateQuantifications($quant_id, $cel_quant_id) if (defined $cel_quant_id);
	} #if
      } #foreach ($quant_id)
    } #foreach ($acq_id)
  }
  else { 
    # if the quantification is from GenePix or ArrayVision, note that the data
    # can be one-channel or 2-channel data
    
    my @quantInfoArray;
    
    foreach my $acq_id (@acqs) {
      my $acqInfo = $infoQ->getAcquisitionInfo($acq_id);
      my $channel = $acqInfo->{'channel'};
      
      foreach my $qid (@{$acqInfo->{'quantifications'}}) {
	my $quantInfo = $infoQ->getQuantificationInfo($qid);
	if($quantInfo->{'protocol_id'} == $global_ref->{'protocol_id'}) {
	  push @quantInfoArray, [$channel, $quantInfo];
	} #if
      } #foreach
    } #foreach
    
    my $quant_ref = $self->checkRelatedQuantifications($dbh, \@quantInfoArray);
    push @{$global_ref->{$assay_id}->{'quantifications'}}, @{$quant_ref};
  } #if/elsif/else
} #sub

#####################################################################################
# checkRelatedQuantifications($dbh, $quantInfoArray)
# Function:
# -- returns quantification_ids for the quantifications in @{$quantInfoArray}
# -- determines whether 1 or 2 channel
# -- relates two quantifications if they are 2-channel and have the same uri
# -- checks for errors in RAD3.RelatedQuantification
#####################################################################################
#-------------------------------
sub checkRelatedQuantifications{
#-------------------------------
  my ($self, $dbh, $quantInfoArrayRef) = @_;

  my (@quantifications, %quant_uris, %uri_count, @red_channels, @related_red_channels, @green_channels, @related_green_channels);

  my $acq_id = undef;

  foreach my $row (@{$quantInfoArrayRef}) {
    my ($channel, $quantInfo) = @{$row};
    my $qid = $quantInfo->{'quantification_id'};
    $quant_uris{$qid} = $quantInfo->{'uri'};
    $uri_count{$quantInfo->{'uri'}}++;
  }

  foreach my $uri (keys %uri_count) {
    if ($uri_count{$uri}==2 && (!defined($global_ref->{'is_2channel'})||$global_ref->{'is_2channel'}==1)) {
      $global_ref->{'is_2channel'} = 1;
    }
    elsif ($uri_count{$uri}==1 && (!defined($global_ref->{'is_2channel'})||$global_ref->{'is_2channel'}==0)) {
      $global_ref->{'is_2channel'} = 0;
    }
    else {
      $self->userError("For the selected software, some of the quantifications from the assay list provided appear to be 2_channel, others one-channel, judging from  the pairing of uris.");
    }
  } #foreach

  foreach my $row (@{$quantInfoArrayRef}) {
    my ($channel, $quantInfo) = @{$row};
    my $qid = $quantInfo->{'quantification_id'};
    $acq_id = $quantInfo->{'acquisition_id'} unless (defined $acq_id);

    if ($global_ref->{'is_2channel'}==0) {
      # if it is one-channel data, simply store the qid
      push (@quantifications, $qid);
    }
    else {
      # 2-channel data, store both Rqid and Gqid
      my $rel_qid = $quantInfo->{'assoc_quantification_id}'};
      my $rel_channel = undef;
      if (defined $rel_qid) {
	my $infoQ = GUS::RAD::Utils::InformationQueries->new($dbh);
	my $relQ = $infoQ->getQuantificationInfo($rel_qid);
	my $acq = $infoQ->getAcquisitionInfo($relQ->{'acquisition_id'});
	$rel_channel = $acq->{'channel'};
      }
    
      if ($channel eq "Cy5") {
	push (@red_channels, $qid);
	if (defined($rel_channel) && $rel_channel ne 'Cy3') {
	  $self->error("DATABASE: quantifications (Cy5) $qid and $rel_qid are related but the latter is not for channel Cy3.");
	}
	push (@related_red_channels, $rel_qid);
      } 
      elsif ($channel eq "Cy3") {
	push (@green_channels, $qid);
	if (defined($rel_channel) && $rel_channel ne 'Cy5') {
	  $self->error("DATABASE: quantifications (Cy3) $qid and $rel_qid are related but the latter is not for channel Cy5.");
	}
	push (@related_green_channels, $rel_qid);
      } #if/elsif
    } #If/else
  } #foreach

  if ($global_ref->{'is_2channel'}==0) {
    return \@quantifications;
  }

  # if it is 2-channel data, need to check related quantification relationships
  if ($#red_channels != $#green_channels) {
    $self->error("For acquisition $acq_id, the number of Cy5 quantifications, with the specified protocol, differs from that of Cy3 quantifications.");
  }
  
  foreach my $i (0..$#red_channels) {
    my $qid = $red_channels[$i];
    my $rel_qid = $related_red_channels[$i];
    
    # if the related_quantification exists, check to see if they have the same uri
    if (defined $rel_qid) {
      if ($quant_uris{$qid} ne $quant_uris{$rel_qid}) {
	$self->error("DATABASE: Quantifications $qid and $rel_qid are related in RAD, but they have different quantification uri's.\nquantification_id:${qid}\turi:$quant_uris{$qid}\nrelated_quantification_id:${rel_qid}\turi:$quant_uris{$rel_qid}");
      } #if 
    } else {
      # needs to relate the two quantifications with the same uri
      if ( grep {$quant_uris{$qid} eq $_} @quant_uris{@green_channels}) {
	my $target_rel_qid = undef;
	foreach my $green_qid (@green_channels) {
	  $target_rel_qid = $green_qid if ($quant_uris{$green_qid} eq $quant_uris{$qid});
	} #foreach
	
	if (defined $target_rel_qid) {
	  $self->relateQuantifications($qid, $target_rel_qid);
	  $related_red_channels[$i] = $target_rel_qid;
	}
      } else {
	$self->error("DATABASE: Cannot retrieve related quantification for quantification_id $qid.");
      } #if/else
    } #if/else
  } #foreach
  
  # repeat the same procedure for green channels
  foreach my $i (0..$#green_channels) {
    my $qid = $green_channels[$i];
    my $rel_qid = $related_green_channels[$i];
    
    # if the related_quantification exists, check to see if they have the same uri
    if (defined $rel_qid) {      
      if ($quant_uris{$qid} ne $quant_uris{$rel_qid}) {
	$self->error("Quantification $qid and $rel_qid are related in RAD, but they have different quantification uri's.\nquantification_id:${qid}\turi:$quant_uris{$qid}\nrelated_quantification_id:${rel_qid}\turi:$quant_uris{$rel_qid}");
      } #if
    } 
    else {
      # needs to relate the two quantifications with the same uri
      if ( grep {$quant_uris{$qid} eq $_} @quant_uris{@red_channels}) {
	my $target_rel_qid = undef;
	foreach my $red_qid (@red_channels) {
	  $target_rel_qid = $red_qid if ($quant_uris{$red_qid} eq $quant_uris{$qid});
	} #foreach
	
	if (defined $target_rel_qid) {
	  $self->relateQuantifications($qid, $target_rel_qid);
	  $related_green_channels[$i] = $target_rel_qid;
	}
      }
      else {
	$self->error("DATABASE: Cannot retrieve related quantification for quantification_id $qid.");
      }
    } #if/else
    
  } #foreach
  
  foreach my $i (0..$#red_channels) { 
    push @quantifications, $red_channels[$i], $related_red_channels[$i];
  }
  
  return \@quantifications;
} #sub

##################################################################################
# RelateQuantifications($dbh, $qid1, $qid2)
# Function:
# -- relate $qid_1 and $qid_2 (insert one entry in RAD3::RelatedQuantification)
##################################################################################
#-------------------------
sub relateQuantifications{
#-------------------------
  my ($self, $qid_1, $qid_2) = @_;

  my $rel_quant = GUS::Model::RAD3::RelatedQuantification->new({ 'quantification_id' => $qid_1, 'associated_quantification_id' => $qid_2});

  if (!$rel_quant->retrieveFromDB()) {
    $rel_quant->submit();
    $self->logData("RESULT","$qid_1 and $qid_2 are related. Inserted 1 entry in RAD3::RelatedQuantification.");
  }
} #sub

#-------------------------
sub runArrayResultLoader {
#-------------------------
  my ($self, $dbh, $log_path, $data_file, $arrayInfo, $Rqid, $Gqid) = @_;

  my $infoQ = GUS::RAD::Utils::InformationQueries->new($dbh);
  my $q = $infoQ->getQuantificationInfo($Rqid);
  my $project_name = $self->getArgs->{'project'} ? $self->getArgs->{project}: $q->{'project_name'};
  my $group_name =  $self->getArgs->{'group'} ?  $self->getArgs->{group} : $q->{'group_name'};
  my $array_id = $arrayInfo->{'array_id'};
  my $software = $self->getArgs->{'software'};
  my $array_subclass_view = $global_ref->{'array_subclass_view'}->{$software};
  my $result_subclass_view = $global_ref->{'result_subclass_view'}->{$software};

  my $commit_string = "";
  if ($self->getArgs->{'commit'}) {
    $commit_string = "--commit";
  }

  my $testnumber_string = "";
  if (my $num = $self->getArgs->{'test_num_line'}) {
    $testnumber_string = "--testnumber $num";
  }

  if (!$global_ref->{'is_2channel'}) {
     system("ga GUS::RAD::Plugin::SimpleArrayResultLoader --data_file $data_file --array_id $array_id --quantification_id $Rqid --array_subclass_view $array_subclass_view --result_subclass_view $result_subclass_view --project '$project_name' --group '$group_name' --log_path $log_path $testnumber_string $commit_string");
   }
  else {
    system("ga GUS::RAD::Plugin::SimpleArrayResultLoader --data_file $data_file --array_id $array_id --quantification_id $Rqid --rel_quantification_id $Gqid --array_subclass_view $array_subclass_view --result_subclass_view $result_subclass_view --project '$project_name' --group '$group_name' --log_path $log_path $testnumber_string $commit_string");
  }
}

##########################
#
##########################
#------------------------
sub checkExistingResults{
#------------------------
  my ($self, $dbh, $qid) = @_;

  my $sth = $dbh->prepare("select count(*) from RAD3.ElementResultImp where quantification_id=$qid");
  $sth->execute();
  my ($count) = $sth->fetchrow_array();
  $sth->finish();
  return $count;
}


#############################
# parseARlogs ($Rqid, $Gqid)
# Function:
#  -- parse the log file from running impleArrayResultLoader
#############################
#------------------------
sub parseARlogs{
#------------------------
  my ($self, $log_path, $Rqid, $Gqid) = @_;

  my $fh = new IO::File;
  my $prefix = $log_path.$Rqid;
  if (defined $Gqid) {
    $prefix .= "_".$Gqid;
  }
  my $error_file = $prefix."_AR_errors.log";
  my $warning_file = $prefix."_AR_warnings.log";
  my $result_file = $prefix."_AR_result.log";
  my $count_errors = 0;
  my $count_warnings = 0;
  unless ($fh->open("<$error_file")) {
    $self->error("Could not open file $error_file.");
  }
  while (my $line=<$fh>) { 
    if ($line =~ /ERROR/i) {
      $count_errors++;
    }
  }
  $fh->close();
  if ($count_errors) {
    $self->log("ERROR", "There are $count_errors reported in file $error_file. MAKE SURE TO CHECK THIS FILE!!!");
    $self->logData("ERROR", "There are $count_errors reported in file $error_file. MAKE SURE TO CHECK THIS FILE!!!");
  }

  unless ($fh->open("<$warning_file")) {
    $self->error("Could not open file $warning_file.");
  }
  while (my $line=<$fh>) { 
    if ($line =~ /WARNING/i) {
      $count_warnings++;
    }
  }
  $fh->close();
  if ($count_warnings) {
    $self->log("WARNING", "There are $count_warnings reported in file $warning_file.");
    $self->logData("WARNING", "There are $count_warnings reported in file $warning_file.");
  }

  unless ($fh->open("<$result_file")) {
    $self->error("Could not open file $result_file.");
  }
  while (my $line=<$fh>) {
    if ($line =~ /RESULT\s+(\w+.*)$/i) {
      my $msg = $1;
      if ($Gqid) {
	$self->log("RESULT", "For quantifications $Rqid, $Gqid: $msg");
	$self->logData("RESULT", "For quantifications $Rqid, $Gqid: $msg");
      } else {
	$self->log("RESULT", "For quantification $Rqid: $msg");
	$self->logData("RESULT", "For quantification $Rqid: $msg");
      }
    }
  }
  $fh->close();
}

#------------------
sub createDataFile{
#------------------
  my ($self, $dbh, $assay_id, $quantInfo, $fileTranslator) = @_;

  my $rad_dir = "/files/cbil/data/cbil/RAD/"; # HARD-CODED: Replace this path with that on your server where the data files are stored. 

  # translate input file to output according to the mapping cfg_file
  my $uri = $rad_dir.$quantInfo->{'uri'};
  my $fname = $1 if ($quantInfo->{uri} =~ m{.*/(\S+)$});

  my $data_file = $self->getArgs->{'log_path'} . "/$fname.data";
  
  my $result = $fileTranslator->translate($global_ref->{$assay_id}->{'arrayInfo'}, $uri, $data_file);
  
  # invalid input file
  if ($result == -1) {
    return undef;
  } else {
    return $data_file;
  }
}

1;



