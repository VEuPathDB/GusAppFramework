##
## LoadBatchArrayResults Plugin
## $Id$
##

package GUS::Community::Plugin::LoadBatchArrayResults;
@ISA = qw( GUS::PluginMgr::Plugin );

use strict;
use IO::File;
use CBIL::Util::Disp;
use CBIL::Util::PropertySet;
use GUS::PluginMgr::Plugin;
use GUS::Community::FileTranslator;
use GUS::Community::Utils::InformationQueries;
use GUS::Model::RAD::RelatedQuantification;

# ----------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------

sub getArgumentsDeclaration {
  my $argumentDeclaration  =
    [
     integerArg({name  => 'studyId',
		 descr => 'The study whose quantification results (obtained with the specified protocol) should be loaded, if one desires to load results for all such quantifications in a study.',
		 constraintFunc => undef,
		 reqd  => 0,
		 isList => 0
		}),
     fileArg({name => 'assayIdFile',
	      descr => 'The (full path of the) file containing the list of assay_ids for all the assays whose quantification results (obtained with the specified protocol) should be loaded.',
	      constraintFunc => undef,
	      reqd  => 0,
	      isList => 0,
	      mustExist => 0,
	      format => 'See the NOTES for the format of this file'
	     }),
     fileArg({name => 'cfgFile',
	      descr => 'The full path of the cfgFile.',
	      constraintFunc => undef,
	      reqd  => 1,
	      isList => 0,
	      mustExist => 1,
	      format => 'See the NOTES for the format of this file'
	     }),
     fileArg({name => 'xmlFile',
	      descr => 'The full path of the xmlFile.',
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
     stringArg({name  => 'logPath',
		 descr => 'The absolute path of the directory where the log files and the data files will be created. The user should have write permission to that directory. This is also where the parsed data files go.',
		 constraintFunc => undef,
		 reqd  => 1,
		 isList => 0
		}),
     integerArg({name  => 'posOption',
		 descr => 'option choice of positionList of ShortOligoFamily table, default is 1.',
		 constraintFunc=> undef,
		 reqd  => 0,
		 isList => 0,
		 default => 1,
		}),
     integerArg({name  => 'testNumLine',
		 descr => 'The number of lines in the data file for the first retrieved assay to be tested for loading.',
		 constraintFunc => undef,
		 reqd  => 0,
		 isList => 0
		}),
     integerArg({name  => 'testNumAssay',
		 descr => 'The number of assays to be tested for loading.',
		 constraintFunc => undef,
		 reqd  => 0,
		 isList => 0
		}),
     stringArg({name  => 'skip',
		 descr => 'The list of assay_ids within the specified study which will be skipped for loading.',
		 constraintFunc => undef,
		 reqd  => 0,
		 isList => 1
		}),
    ];
  return $argumentDeclaration;
}

# ----------------------------------------------------------------------
# Documentation
# ----------------------------------------------------------------------

sub getDocumentation {
  my $purposeBrief = 'Loads into the appropriate view of RAD::(Composite)ElementResultImp quantification data from a collection of files all having the same format.';

  my $purpose = <<PURPOSE;
This plugin takes as input: (i) a study_id or a file with a list of assay_ids, (ii) a property file, (iii) an xml configuration file, and (iv) a quantification protocol or software (one of: I<MAS4.0, MAS5.0, GenePix, ArrayVision, RMAExpress, and MOID>). The plugin then uploads into the appropriate view of RAD::(Composite)ElementResult the data contained in the uri files corresponding to all those quantifications from these assays, which have the specified quantification protocol. I<If any such file has a format that does not correspond to that specified by the configuration file (e.g. different header names, etc.), it will not be uploaded>.
PURPOSE

  my $tablesAffected = [['RAD::ElementResultImp', 'Enters the quantification results here, if the protocol is GenePix or ArrayVision'], ['RAD::CompositeElementResultImp', 'Enters the quantification results here, if the protocol is MAS4.0, MAS5.0, RMAExpress, or MOID'], ['RAD::RelatedQuantification', 'Inserts entries in this table for the quantifications at stake, if missing']];

  my $tablesDependedOn = [['Study::Study', 'The study, if studyId is passed in'], ['RAD::StudyAssay', 'The table linking the assays to the study, if studyId is passed in'], ['RAD::Assay', 'The assays passed in'], ['SRes::ExternalDatabaseRelease', 'The external database relase for the assays passed in'], ['RAD::ArrayDesign', 'The array design(s) used in the assays passed in' ], ['Study::OntologyEntry', 'The technology and substrate information for the arrays involved; also the channels for the acquisitions relative to the assays passed in'], ['RAD::Acquisition', 'The acquisitions for the assays passed in'], ['RAD::Quantification', 'The quantifications for the assays passed in'], ['RAD::RelatedAcquisition', 'The associations between the acquisitions for the assays passed in'], ['RAD::RelatedQuantification', 'The associations between the quantifications for the assays passed in'], ['RAD::Protocol', 'The quantification protocol of interest']];

  my $howToRestart = <<RESTART;
RESTART

  my $failureCases = <<FAILURE_CASES;
FAILURE_CASES

  my $notes = <<NOTES;
B<Only one of studyId or assayIdFile should be specified in the argument line.>

=head2 F<assayIdFile>

To be used when either not all assays in a study should be considered or when assays from different studies should be considered. Their assay_ids should be provided through this text file. One assay_id per line, empty lines are ignored.

=head2 F<cfgFile>

This file is where instance-specific information is specified. It should be in the format name=value required by CBIL::Util::PropertySet.
This file should be as follows:

mas4=<RAD::Protocol::protocol_id for the Affymetrix MAS 4.0 Probe Set quantification protocol in your instance>

mas5=<RAD::Protocol::protocol_id for the Affymetrix MAS 5.0 Probe Set quantification protocol in your instance>

cel4=<RAD::Protocol::protocol_id for the Affymetrix MAS 4.0 Probe Cell quantification protocol in your instance>

cel5=<RAD::Protocol::protocol_id for the Affymetrix MAS 5.0 Probe Cell quantification protocol in your instance>

rmaexpress=<RAD::Protocol::protocol_id for the RMAExpress quantification protocol in your instance>

moid=<RAD::Protocol::protocol_id for the MOID quantification protocol in your instance>

genepix=<RAD::Protocol::protocol_id for the GenePix quantification protocol in your instance>

arrayvision=<RAD::Protocol::protocol_id for the ArrayVision quantification protocol in your instance>

filePath=<The path to the directory on your server where the data files are stored (possibly organized in subdirectories)>, e.g. at CBIL the filePath should be set to "/files/cbil/data/cbil/RAD/". For each quantification, this plugin concatenates this filePath with the uri specified in RAD.Quantification.uri, to retrieve the corresponding quantification file.

=head2 F<xmlFile>

This should be an xml file whose format should be that specified in GUS/Community/config/FileTranslatorCfg.dtd.
This is used to map headers in the software output files to attributes of the appropriate RAD view of (Composite)ElementResultImp as well as to RAD coordinates.

=head1 AUTHORS

The following individuals have collaborated in the design and coding of this plugin and the file mapping utilities it calls: Hongxian He, Junmin Liu, Elisabetta Manduchi, Angel Pizarro, Trish Whetzel.

=head1 COPYRIGHT

Copyright CBIL, Trustees of University of Pennsylvania 2003.
NOTES

  my $documentation = {purpose=>$purpose, purposeBrief=>$purposeBrief,tablesAffected=>$tablesAffected,tablesDependedOn=>$tablesDependedOn,howToRestart=>$howToRestart,failureCases=>$failureCases,notes=>$notes};
  
  return $documentation;
}

# ----------------------------------------------------------------------
# create and initalize new plugin instance.
# ----------------------------------------------------------------------

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);
  
  my $documentation = &getDocumentation();
  my $argumentDeclaration    = &getArgumentsDeclaration();
  
  $self->initialize({requiredDbVersion => 3.5,
		     cvsRevision => '$Revision$',
		     name => ref($self),
		     revisionNotes => '',
		     argsDeclaration => $argumentDeclaration,
		     documentation => $documentation
		    });
  return $self;
}

# global hash reference
my $globalRef;
my @singleChannelSoftware = qw(mas4 mas5 rmaexpress moid);

sub run {
  
  my ($self) = @_;
  
  $self->logAlgInvocationId();
  $self->logCommit();
  $self->logArgs();
  
  my $dbh = $self->getQueryHandle();
  $self->checkArgs($dbh);
  $self->initializeGlobalRef();

  my $infoQ = GUS::Community::Utils::InformationQueries->new($dbh);

  my $xmlFile = $self->getArg('xmlFile');
  
  my $logPath = $self->getArg('logPath'); 
  $logPath = $logPath."/" unless ($logPath =~ m{.*/$});
  unless (-e "$logPath") {
    $self->userError("directory $logPath does not exist.");
  }
  
  my @assayIds = @{$self->getAssayIds($dbh)};
  
  # skip certain assays if specified
  if ($self->getArg('skip')) {
    my @skipLists = @{$self->getArg('skip')};
    my $str = join ",", @skipLists;
    $self->log("STATUS","The following assays will be skipped for data loading: $str");
    $self->logData("STATUS","The following assays will be skipped for data loading: $str");
    
    my @toBeLoaded;
    foreach my $i (@assayIds) {
      push @toBeLoaded, $i if (scalar(grep {$_ == $i} @skipLists)==0);
    }
    @assayIds = @toBeLoaded;
  }
  
  my $numAssays = scalar(@assayIds);
  $self->log("STATUS", "There are $numAssays assays whose results will be loaded.");
  $self->logData("RESULT", "There are $numAssays assays whose results will be loaded.");
  
  my $assayCount = 0;
  foreach my $assayId (@assayIds) {
    $self->log("STATUS", "Working on assay $assayId.");
    
    my $fileTranslator;
    my $ftLogFile = $logPath.".".$assayId.".filetranslator.log";
    eval {
      $fileTranslator = GUS::Community::FileTranslator->new($xmlFile, $ftLogFile, $self->getArg('debug'));
    };
    
    if ($@) {
      # failed in validating cfg file
      $self->userError("The mapping configuration file '$xmlFile' failed the validation. Please see the log file $ftLogFile.");
    };
    
    $self->retrieveQuantifications($dbh, $assayId);
    
    # If 2-channel data, the entries in the quantifications array alternate b/w
    # red qid, associated green qid, ...
    my @quantifications = @{$globalRef->{$assayId}->{'quantifications'}};

    if ($globalRef->{'is2channel'}==0) { # 1-channel data
      foreach my $qid (@quantifications) {
	$self->log("STATUS", "Working on quantification $qid.");
	
	if ($self->checkExistingResults($dbh, $qid) == 0) { 
	  my $quantInfo = $infoQ->getQuantificationInfo($qid);
	  my $dataFile = $self->createDataFile($dbh, $assayId, $quantInfo, $fileTranslator);
	  
	  if (defined $dataFile) {
	    $self->runArrayResultLoader($dbh, $logPath, $dataFile, $globalRef->{$assayId}->{'arrayInfo'}, $qid);

	    $self->parseARlogs($logPath, $qid);
	  } 
	  else {
	    # The input file failed to validate against the config file
	    $self->log("ERROR", "The input file for quantification $qid failed validation. The results for this quantification cannot be loaded. Please see the log file $ftLogFile.");
	  }
	} 
	else {
	  $self->logData("WARNING", "The results for quantification_id $qid already exist in the database, thus will not be loaded");
	}
      }
    }
    else { # 2-channel data
      for my $i (0..(scalar(@quantifications)/2-1)) {
	my $Rqid = $quantifications[2*$i];
	my $Gqid = $quantifications[2*$i+1];
	$self->log("STATUS", "Working on quantifications $Rqid, $Gqid.");
	if ($self->checkExistingResults($dbh, $Rqid) == 0 && $self->checkExistingResults($dbh, $Gqid) == 0) { 
	  my $quantInfo = $infoQ->getQuantificationInfo($Rqid);
	  my $dataFile = $self->createDataFile($dbh, $assayId, $quantInfo, $fileTranslator);
	  if (defined $dataFile) {
	    $self->runArrayResultLoader($dbh, $logPath, $dataFile, $globalRef->{$assayId}->{'arrayInfo'}, $Rqid, $Gqid);
	    $self->parseARlogs($logPath, $Rqid, $Gqid);
	  } 
	  else {
	    $self->log("ERROR", "The input file for quantification ($Rqid,$Gqid) failed validation. The results for this quantification cannot be loaded. Please see the log file $ftLogFile.");
	  }
	}
	else { # results already exist
	  $self->logData("WARNING", "The results for at least one of the quantification_ids $Rqid, $Gqid already exist in the database, thus neither will be loaded");
	}
      }
    }

    $assayCount++;
    # test only 1 assay
    if ($self->getArg('testNumLine')) {
      last;
    }

    if ($self->getArg('testNumAssay') && $assayCount >=$self->getArg('testNumAssay')) {
      last;
    }
    
  }
  $self->setResultDescr("Processed $assayCount assays");
}

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
# -- checks that exactly one of studyId or assayIdFile is given
#    as an argument
# -- checks that the studyId (if given) is a valid one
###################################################################
#--------------
sub checkArgs {
#--------------
  my ($self, $dbh) = @_;

  if (!defined($self->getArg('studyId')) && !defined ($self->getArg('assayIdFile'))) {
    $self->userError('Must provide one of --studyId or --assayIdFile.');
  }
  if (defined($self->getArg('studyId')) && defined ($self->getArg('assayIdFile'))) {
    $self->userError('Can pass in only one of --studyId or --assayIdFile.');
  }
 if (defined($self->getArg('studyId'))) {
   my $studyId = $self->getArg('studyId');
   my $sth = $dbh->prepare("select count(*) from Study.Study where study_id=$studyId");
   $sth->execute();
   my ($count) = $sth->fetchrow_array();
   $sth->finish();
   if ($count != 1) {
     $self->userError('Invalid studyId');
   }
 }
}

sub initializeGlobalRef {
  my ($self) = @_;
  
  my @properties =
    (
     ["mas4", "", ""],
     ["mas5", "", ""],
     ["genepix", "", ""],
     ["arrayvision", "", ""],
     ["rmaexpress", "", ""],
     ["cel4", "", ""],
     ["cel5", "", ""],
     ["moid", "", ""],
     ["filePath", "", ""]
    ); 
  my $propertySet = CBIL::Util::PropertySet->new($self->getArg('cfgFile'), \@properties);
  
  $globalRef->{'filePath'} = $propertySet->getProp("filePath");
  
  $globalRef->{'softwareName2Id'} =
  {
   'mas4'=>$propertySet->getProp("mas4"),
   'mas5'=>$propertySet->getProp("mas5"),
   'genepix'=>$propertySet->getProp("genepix"),
   'arrayvision'=>$propertySet->getProp("arrayvision"),
   'rmaexpress'=>$propertySet->getProp("rmaexpress"),
   'cel4'=>$propertySet->getProp("cel4"),
   'cel5'=>$propertySet->getProp("cel5"),
   'moid' =>$propertySet->getProp("moid")
  };
  
  $globalRef->{'protocolId'} = $globalRef->{'softwareName2Id'}->{$self->getArg('software')};
  
  $globalRef->{'arraySubclassView'} =
    {
     'mas4'=>'ShortOligoFamily',
     'mas5'=>'ShortOligoFamily',
     'genepix'=>'Spot',
     'arrayvision'=>'Spot',
     'rmaexpress'=>'ShortOligoFamily',
     'moid' => 'ShortOligoFamily',
    };
  
  $globalRef->{'resultSubclassView'} =
    {
     'mas4'=>'AffymetrixMAS4',
     'mas5'=>'AffymetrixMAS5',
     'genepix'=>'GenePixElementResult',
     'arrayvision'=>'ArrayVisionElementResult',
     'rmaexpress'=>'RMAExpress',
     'moid' => 'MOIDResult',
    };
}

###################################################################
# getAssayIds ($dbh)
# Function:
# -- checks that the assay_ids in the assayIdFile (if given)
#    are valid ones
# -- returns a reference to an array of assay_ids
###################################################################
#----------------
sub getAssayIds {
#----------------
  my ($self, $dbh) = @_;

  if (defined($self->getArg('studyId'))) {
    my $infoQ = GUS::Community::Utils::InformationQueries->new($dbh);
    my $study = $infoQ->getStudyInfo($self->getArg('studyId'));
    return $study->{'assays'};
  }
  else {
    my @r;
    my $sth = $dbh->prepare("select count(*) from RAD.Assay where assay_id=?");
    my $file = $self->getArg('assayIdFile');
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
# retrieveQuantifications ($dbh, $assayId)
# Function:
# -- retrieves array information for the given assay and stores it in
#    $globalRef->{$assayId}->{'arrayInfo'}
# -- retrieves quantification_id's for the given assay and stores them
#    in $globalRef->{$assayId}->{'quantifications'}
#    alternating red and green quantifications when 2-channel
# -- calls to check related quantifications and to insert if needed
#######################################################################
#-----------------------
sub retrieveQuantifications{
#-----------------------
  my ($self, $dbh, $assayId) = @_;

  my $infoQ = GUS::Community::Utils::InformationQueries->new($dbh);
  my $assayInfo = $infoQ->getAssayInfo($assayId);

  # get arrayInfo
  $globalRef->{$assayId}->{'arrayInfo'} = $infoQ->getArrayInfo($assayInfo->{'array_design_id'});

  # get acquisitions
  my @acqs = @{$assayInfo->{'acquisitions'}};

  # get quantifications
  if (scalar(grep {$self->getArg('software') eq $_} @singleChannelSoftware) ==1) {
    # if the quantification is from MAS4, MAS5, RMAExpress or MOID
    $globalRef->{'is2channel'} = 0;

    foreach my $acqId (@acqs) {
      my $celQuantId;
      my @setQuantIds;
      my $celCount = 0;
      my $acqInfo =  $infoQ->getAcquisitionInfo($acqId);

      foreach my $quantId (@{$acqInfo->{quantifications}}) {
	my $quantInfo = $infoQ->getQuantificationInfo($quantId);

	if($quantInfo->{'protocol_id'} == $globalRef->{'softwareName2Id'}->{'cel4'} || $quantInfo->{'protocol_id'} == $globalRef->{'softwareName2Id'}->{'cel5'}) {
	  $celQuantId = $quantInfo->{'quantification_id'};
	  $celCount++;
	  next;
	}
	if($quantInfo->{'protocol_id'} == $globalRef->{'protocolId'}) {
	  push(@setQuantIds, $quantInfo->{'quantification_id'});
	  push (@{$globalRef->{$assayId}->{'quantifications'}}, $quantInfo->{'quantification_id'});
	}
      }
      # relate CEL and other quantifications if one CEL exists
      foreach my $quantId (@setQuantIds) {
	$self->relateQuantifications($celQuantId, $quantId) if ($celCount==1);
	$self->relateQuantifications($quantId, $celQuantId) if ($celCount==1);
      }
    }
  }
  else {
    # if the quantification is from GenePix or ArrayVision, note that the data
    # can be one-channel or 2-channel data

    my @quantInfoArray;

    foreach my $acqId (@acqs) {
      my $acqInfo = $infoQ->getAcquisitionInfo($acqId);
      my $channel = $acqInfo->{'channel'};

      foreach my $qid (@{$acqInfo->{'quantifications'}}) {
	my $quantInfo = $infoQ->getQuantificationInfo($qid);
	if($quantInfo->{'protocol_id'} == $globalRef->{'protocolId'}) {
	  push @quantInfoArray, [$channel, $quantInfo];
	}
      }
    }

    my $quantRef = $self->checkRelatedQuantifications($dbh, \@quantInfoArray);
    push @{$globalRef->{$assayId}->{'quantifications'}}, @{$quantRef};
  }
}

#####################################################################################
# checkRelatedQuantifications($dbh, $quantInfoArray)
# Function:
# -- returns quantification_ids for the quantifications in @{$quantInfoArray}
# -- determines whether 1 or 2 channel
# -- relates two quantifications if they are 2-channel and have the same uri
# -- checks for errors in RAD.RelatedQuantification
#####################################################################################
#-------------------------------
sub checkRelatedQuantifications{
#-------------------------------
  my ($self, $dbh, $quantInfoArrayRef) = @_;

  my (@quantifications, %quantUris, %uriCount, @redChannels, @relatedRedChannels, @greenChannels, @relatedGreenChannels);

  my $acqId = undef;

  foreach my $row (@{$quantInfoArrayRef}) {
    my ($channel, $quantInfo) = @{$row};
    my $qid = $quantInfo->{'quantification_id'};
    $quantUris{$qid} = $quantInfo->{'uri'};
    $uriCount{$quantInfo->{'uri'}}++;
  }

  foreach my $uri (keys %uriCount) {
    if ($uriCount{$uri}==2 && (!defined($globalRef->{'is2channel'})||$globalRef->{'is2channel'}==1)) {
      $globalRef->{'is2channel'} = 1;
    }
    elsif ($uriCount{$uri}==1 && (!defined($globalRef->{'is2channel'})||$globalRef->{'is2channel'}==0)) {
      $globalRef->{'is2channel'} = 0;
    }
    else {
      $self->userError("For the selected software, some of the quantifications from the assay list provided appear to be 2-channel, others 1-channel, judging from  the pairing of uris.");
    }
  }

  foreach my $row (@{$quantInfoArrayRef}) {
    my ($channel, $quantInfo) = @{$row};
    my $qid = $quantInfo->{'quantification_id'};
    $acqId = $quantInfo->{'acquisition_id'} unless (defined $acqId);

    if ($globalRef->{'is2channel'}==0) {
      # if it is 1-channel data, simply store the qid
      push (@quantifications, $qid);
    }
    else {
      # 2-channel data, store both Rqid and Gqid
      my $relQid = $quantInfo->{'assoc_quantification_id}'};
      my $relChannel = undef;
      if (defined $relQid) {
	my $infoQ = GUS::Community::Utils::InformationQueries->new($dbh);
	my $relQ = $infoQ->getQuantificationInfo($relQid);
	my $acq = $infoQ->getAcquisitionInfo($relQ->{'acquisition_id'});
	$relChannel = $acq->{'channel'};
      }
    
      if ($channel eq "Cy5") {
	push (@redChannels, $qid);
	if (defined($relChannel) && $relChannel ne 'Cy3') {
	  $self->error("DATABASE: quantifications (Cy5) $qid and $relQid are related but the latter is not for channel Cy3.");
	}
	push (@relatedRedChannels, $relQid);
      } 
      elsif ($channel eq "Cy3") {
	push (@greenChannels, $qid);
	if (defined($relChannel) && $relChannel ne 'Cy5') {
	  $self->error("DATABASE: quantifications (Cy3) $qid and $relQid are related but the latter is not for channel Cy5.");
	}
	push (@relatedGreenChannels, $relQid);
      }
      elsif ($channel eq "alexa_532") {
	push (@greenChannels, $qid);
	if (defined($relChannel) && $relChannel ne 'alexa_633') {
	  $self->error("DATABASE: quantifications (alexa_532) $qid and $relQid are related but the latter is not for channel alexa_633.");
	}
	push (@relatedGreenChannels, $relQid);
      }
      elsif ($channel eq "alexa_633") {
	push (@redChannels, $qid);
	if (defined($relChannel) && $relChannel ne 'alexa_532') {
	  $self->error("DATABASE: quantifications (alexa_633) $qid and $relQid are related but the latter is not for channel alexa_532.");
	}
	push (@relatedRedChannels, $relQid);
      }
    }
  }

  if ($globalRef->{'is2channel'}==0) {
    return \@quantifications;
  }

  # if it is 2-channel data, need to check related quantification relationships
  if ($#redChannels != $#greenChannels) {
    $self->error("For acquisition $acqId, the number of Cy5 quantifications, with the specified protocol, differs from that of Cy3 quantifications.");
  }
  
  foreach my $i (0..$#redChannels) {
    my $qid = $redChannels[$i];
    my $relQid = $relatedRedChannels[$i];
    
    # if the related_quantification exists, check to see if they have the same uri
    if (defined $relQid) {
      if ($quantUris{$qid} ne $quantUris{$relQid}) {
	$self->error("DATABASE: Quantifications $qid and $relQid are related in RAD, but they have different quantification uri's.\nquantification_id:${qid}\turi:$quantUris{$qid}\nrelated_quantification_id:${relQid}\turi:$quantUris{$relQid}");
      }
    } 
    else {
      # needs to relate the two quantifications with the same uri
      if ( grep {$quantUris{$qid} eq $_} @quantUris{@greenChannels}) {
	my $targetRelQid = undef;
	foreach my $greenQid (@greenChannels) {
	  $targetRelQid = $greenQid if ($quantUris{$greenQid} eq $quantUris{$qid});
	}
	
	if (defined $targetRelQid) {
	  $self->relateQuantifications($qid, $targetRelQid);
	  $relatedRedChannels[$i] = $targetRelQid;
	}
      } 
      else {
	$self->error("DATABASE: Cannot retrieve related quantification for quantification_id $qid.");
      }
    }
  }
  
  # repeat the same procedure for green channels
  foreach my $i (0..$#greenChannels) {
    my $qid = $greenChannels[$i];
    my $relQid = $relatedGreenChannels[$i];
    
    # if the related_quantification exists, check to see if they have the same uri
    if (defined $relQid) {      
      if ($quantUris{$qid} ne $quantUris{$relQid}) {
	$self->error("Quantification $qid and $relQid are related in RAD, but they have different quantification uri's.\nquantification_id:${qid}\turi:$quantUris{$qid}\nrelated_quantification_id:${relQid}\turi:$quantUris{$relQid}");
      }
    }
    else {
      # needs to relate the two quantifications with the same uri
      if ( grep {$quantUris{$qid} eq $_} @quantUris{@redChannels}) {
	my $targetRelQid = undef;
	foreach my $redQid (@redChannels) {
	  $targetRelQid = $redQid if ($quantUris{$redQid} eq $quantUris{$qid});
	}
	
	if (defined $targetRelQid) {
	  $self->relateQuantifications($qid, $targetRelQid);
	  $relatedGreenChannels[$i] = $targetRelQid;
	}
      }
      else {
	$self->error("DATABASE: Cannot retrieve related quantification for quantification_id $qid.");
      }
    }
  }
  
  foreach my $i (0..$#redChannels) { 
    push @quantifications, $redChannels[$i], $relatedRedChannels[$i];
  }
  
  return \@quantifications;
}

##################################################################################
# RelateQuantifications($dbh, $qid1, $qid2)
# Function:
# -- relate $qid11 and $qid12 (insert one entry in RAD::RelatedQuantification)
##################################################################################
#-------------------------
sub relateQuantifications{
#-------------------------
  my ($self, $qid1, $qid2) = @_;

  my $relQuant = GUS::Model::RAD::RelatedQuantification->new({ 'quantification_id' => $qid1, 'associated_quantification_id' => $qid2});

  if (!$relQuant->retrieveFromDB()) {
    $relQuant->submit();
    $self->logData("RESULT","$qid1 and $qid2 are related. Inserted 1 entry in RAD::RelatedQuantification.");
  }
}

#-------------------------
sub runArrayResultLoader {
#-------------------------
  my ($self, $dbh, $logPath, $dataFile, $arrayInfo, $Rqid, $Gqid) = @_;

  my $infoQ = GUS::Community::Utils::InformationQueries->new($dbh);
  my $q = $infoQ->getQuantificationInfo($Rqid);
  my $projectName = $self->getArg('project') ? $self->getArg('project'): $q->{'project_name'};
  my $groupName =  $self->getArg('group') ?  $self->getArg('group') : $q->{'group_name'};
  my $arrayDesignId = $arrayInfo->{'array_design_id'};
  my $software = $self->getArg('software');
  my $arraySubclassView = $globalRef->{'arraySubclassView'}->{$software};
  my $resultSubclassView = $globalRef->{'resultSubclassView'}->{$software};

  my $commitString = "";
  if ($self->getArg('commit')) {
    $commitString = "--commit";
  }

  my $testnumberString = "";
  if (my $num = $self->getArg('testNumLine')) {
    $testnumberString = "--testnumber $num";
  }

  my $posOption =  $self->getArg('posOption') ? "--posOption " . $self->getArg('posOption') : undef;

  if (!$globalRef->{'is2channel'}) {
    system("ga GUS::Community::Plugin::LoadSimpleArrayResults --data_file $dataFile --array_design_id $arrayDesignId --quantification_id $Rqid --array_subclass_view $arraySubclassView --result_subclass_view $resultSubclassView --project '$projectName' --group '$groupName' --log_path $logPath $testnumberString $commitString $posOption");
   }
  else {
    system("ga GUS::Community::Plugin::LoadSimpleArrayResults --data_file $dataFile --array_design_id $arrayDesignId --quantification_id $Rqid --rel_quantification_id $Gqid --array_subclass_view $arraySubclassView --result_subclass_view $resultSubclassView --project '$projectName' --group '$groupName' --log_path $logPath $testnumberString $commitString $posOption");
  }
}

##########################
#
##########################
#------------------------
sub checkExistingResults{
#------------------------
  my ($self, $dbh, $qid) = @_;

  my $sth = $dbh->prepare("select count(*) from RAD.ElementResultImp where quantification_id=$qid");
  $sth->execute();
  my ($count) = $sth->fetchrow_array();
  $sth->finish();
  return $count;
}

#############################
# parseARlogs ($Rqid, $Gqid)
# Function:
#  -- parse the log file from running LoadSimpleArrayResults
#############################
#------------------------
sub parseARlogs{
#------------------------
  my ($self, $logPath, $Rqid, $Gqid) = @_;

  my $fh = new IO::File;
  my $prefix = $logPath.$Rqid;
  if (defined $Gqid) {
    $prefix .= "_".$Gqid;
  }
  my $errorFile = $prefix."_AR_errors.log";
  my $warningFile = $prefix."_AR_warnings.log";
  my $resultFile = $prefix."_AR_result.log";
  my $countErrors = 0;
  my $countWarnings = 0;
  unless ($fh->open("<$errorFile")) {
    $self->error("Could not open file $errorFile.");
  }
  while (my $line=<$fh>) { 
    if ($line =~ /ERROR/i) {
      $countErrors++;
    }
  }
  $fh->close();
  if ($countErrors) {
    $self->log("ERROR", "There are $countErrors reported in file $errorFile. MAKE SURE TO CHECK THIS FILE!!!");
    $self->logData("ERROR", "There are $countErrors reported in file $errorFile. MAKE SURE TO CHECK THIS FILE!!!");
  }

  unless ($fh->open("<$warningFile")) {
    $self->error("Could not open file $warningFile.");
  }
  while (my $line=<$fh>) {
    if ($line =~ /WARNING/i) {
      $countWarnings++;
    }
  }
  $fh->close();
  if ($countWarnings) {
    $self->log("WARNING", "There are $countWarnings reported in file $warningFile.");
    $self->logData("WARNING", "There are $countWarnings reported in file $warningFile.");
  }

  unless ($fh->open("<$resultFile")) {
    $self->error("Could not open file $resultFile.");
  }
  while (my $line=<$fh>) {
    if ($line =~ /RESULT\s+(\w+.*)$/i) {
      my $msg = $1;
      if ($Gqid) {
	$self->log("RESULT", "For quantifications $Rqid, $Gqid: $msg");
	$self->logData("RESULT", "For quantifications $Rqid, $Gqid: $msg");
      } 
      else {
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
  my ($self, $dbh, $assayId, $quantInfo, $fileTranslator) = @_;
  my $filePath = $globalRef->{'filePath'};
  $filePath .= "/" if ($filePath !~ m/(.+)\/$/);
  
  # translate input file to output according to the mapping xmlFile
  my $uri = $filePath.$quantInfo->{'uri'};
  my $fname = $1 if ($quantInfo->{uri} =~ m{.*/(\S+)$});
  
  my $dataFile = $self->getArg('logPath') . "/$fname.data";
  
  my $result = $fileTranslator->translate($globalRef->{$assayId}->{'arrayInfo'}, $uri, $dataFile);
  
  # invalid input file
  if ($result == -1) {
    return undef;
  } 
  else {
    return $dataFile;
  }
}

1;



