package GUS::RAD::Plugin::GenePixStudyModuleILoader;

@ISA = qw( GUS::PluginMgr::Plugin);

use strict 'vars';

use CBIL::Util::Disp;
use CBIL::Util::PropertySet;
use GUS::PluginMgr::Plugin;

use GUS::Model::RAD3::Study;
use GUS::Model::RAD3::Assay;
use GUS::Model::RAD3::StudyAssay;
use GUS::Model::RAD3::Acquisition; 
use GUS::Model::RAD3::RelatedAcquisition;
use GUS::Model::RAD3::Quantification;
use GUS::Model::RAD3::QuantificationParam;
use GUS::Model::RAD3::RelatedQuantification;
use GUS::Model::RAD3::Array;
use GUS::Model::RAD3::Protocol;
use GUS::Model::RAD3::ProtocolParam;
use GUS::Model::RAD3::Channel;
use GUS::Model::SRes::Contact;


sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  my $purposeBrief = 'Plugin is BatchLoader, creates assays, acquisitions and quantifications for GenePix assays in RAD3 tables.';
  
  my $purpose = <<PURPOSE; 
The plugin creates assays, acquisitions and quantifications for GenePix assays in RAD3 tables from multiple files in a batch mode, eliminating the need to load these files one by one. 
PURPOSE
 
#  ------- 
 
  my $tablesAffected = [['RAD3::Assay','Enters as many rows as distinct assays found'],['RAD3::AssayParam','For each assay entered, enters here the values of the Fluidics protocol parameters as recorded in the corresponding .EXP file'],['RAD3::Quantification','Enters here two quantifications, cel and chp, for each assay entered'],['RAD3::QuantificationParam','For each assay entered, enters here the values for parameters recorded in the corresponding .RPT file'],['RAD3::Acquisition','Enters here one acquisition for each assay entered'],['RAD3::AcquisitionParam','For each assay entered, enters here the values for parameters recorded in the corresponding .EXP file'],['RAD3::StudyAssay','Row linking the given study to an assay is entered']];

  my $tablesDependedOn = [['RAD3::Study','The particular study to which the assay belongs'],['RAD3::Array', 'Holds array information'], ['RAD3::Protocol', 'The hybridization, image_acquisition, and feature_extraction protocols used'], ['RAD3::ProtocolParam', 'Parameters for the protocol used'], ['RAD3::Contact', 'Information on researchers who performed the hybridization and the image analysis']];

  my $howToRestart = <<RESTART; 
Cannot be restarted. 
RESTART
  
  my $failureCases = <<FAILURE_CASES;
Files not in an appropriate format.
FAILURE_CASES


  my $notes = <<NOTES;

=pod

=head2 F<General Description>

Plugin reads a config file with information about full paths of directories where files of interest (.EXP, .RPT etc. )
are maintained.  Data from these files are then parsed and entered into a database. The plugin can handle multiple files,
hence works in a batch mode.

read config file -> follow file paths -> parse files and gather data -> input data in database

=head2 F<Config File [ Mandatory ]>

Blank lines and comment lines (lines starting with '#') are ignored.
The following keywords and their values are required:

- EXPFilePath  (full path to the dir where the EXP files are kept)

- RPTFilePath  (full path to the dir where the RPT files are kept)

- CELFilePath  (full path to the dir where the CEL files are kept)

- DATFilePath**  (full path to the dir where the DAT files are kept)

- MetricsFilePath  (full path to the dir where the Metrics files are kept)

- Hyb_Protocol_ID  (hybridization protocol id, should pre-exist in the RAD3 database)

- Acq_Protocol_ID  (acquisition protocol id, should pre-exist in the RAD3 database)

- Cel_Protocol_ID  (cel quantification protocol id, should pre-exist in the RAD3 database)

- Chp_Protocol_ID  (chp quantification protocol id, should pre-exist in the RAD3 database)

- Hyb_Operator_ID  (contact_id of the person who carried out the hybridization, should pre-exist in the RAD3 database)

- Cel_Quant_Operator_ID**  (contact_id of the person who carried out the cel quantification, should pre-exist in the RAD3 database)

- Chp_Quant_Operator_ID**  (contact_id of the person who carried out the chp quantification, should pre-exist in the RAD3 database)

- Study_ID  (the study identifier, should pre-exist in the RAD3 database)

** These values are optional, i.e., the keywords should exist, but their the values can be left blank.

Each of these keywords should be on a separate line. The values for these keywords should be seperated by tabs. A sample
file is maintained in \$GUS_HOME/config/sample_MAS5StudyModuleILoader.cfg


=head1 AUTHORS

Shailesh Date, Hongxian He

=head1 COPYRIGHT

Copyright, Trustees of University of Pennsylvania 2003. 

=cut

NOTES


  my $documentation = {purpose=>$purpose, purposeBrief=>$purposeBrief,tablesAffected=>$tablesAffected,tablesDependedOn=>$tablesDependedOn,howToRestart=>$howToRestart,failureCases=>$failureCases,notes=>$notes};
 

  my $argsDeclaration  =
    [
     
     fileArg({name => 'cfg_file',
          descr => 'The full path of the cfg file.',
          constraintFunc=> undef,
          reqd  => 1,
          isList => 0, 
          mustExist => 1,
          format => 'See NOTES'
         }),

     stringArg({name => 'skip',
        descr => 'The list of prefixes of the files in the specified directories that will be skipped for loading.',
        constraintFunc=> undef,
        reqd  => 0,
        isList => 1, 
           }),
     
     integerArg({name => 'testnumber',
         descr => 'Number of assays to be loaded for testing',
         constraintFunc=> undef,
         reqd  => 0,
         isList => 0 
        })
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

my @properties =
(
    [ "GPRFilePath",                 "", "" ],
    [ "Study_ID",                    "", "" ],
    [ "arrayId",                     "", "" ],
    [ "batchId",                     "NOVALUEPROVIDED", "" ],
    [ "allAssayDescriptionsSame",    "NOVALUEPROVIDED", "" ],
    [ "allAssayDescriptions",        "NOVALUEPROVIDED", "" ],
    [ "individualAssayDescriptions", "NOVALUEPROVIDED", "" ],
    [ "Hyb_Protocol_ID",             "", "" ],
    [ "Hyb_Operator_ID",             "", "" ],
    [ "allHybDatesSame",             "", "" ],
    [ "allHybDates",                 "NOVALUEPROVIDED", "" ],
    [ "individualHybDates",          "NOVALUEPROVIDED", "" ],
    [ "Acq_Protocol_ID",             "", "" ],
    [ "tiffFilePath",                "", "" ],
    [ "allScanDatesSame",            "", "" ],
    [ "allScanDates",                "NOVALUEPROVIDED", "" ],
    [ "individualScanDates",         "NOVALUEPROVIDED", "" ],
    [ "Quant_Protocol_ID",           "", "" ],
    [ "Quant_Operator_ID",           "NOVALUEPROVIDED", "" ]
 ); 

###############################

sub run {
  my $self = shift;
    
  $self->logAlgInvocationId();
  $self->logCommit();
  $self->logArgs();

  $self->{propertySet} = CBIL::Util::PropertySet->new($self->getArg('cfg_file'), \@properties);

  my $studyId = $self->{propertySet}->getProp("Study_ID");

  my ($gusAssays, $skippedAssayCnt, $totalAssayCnt) = $self->createGUSAssaysFromFiles();
  my $gusInsertedAssayCnt = $self->submitGusAssays($gusAssays);

  $self->populateRelatedTables($studyId); 

  $self->setResultDescr(
   "Total assays: $totalAssayCnt; Assay/s inserted in DB: $gusInsertedAssayCnt; Skipped assay/s: $skippedAssayCnt"
  );
}

###############################

sub createGUSAssaysFromFiles {
  my ($self) = @_;

  my @gusAssays;
  my $assayCnt = 0;

  my $tiffFilePath  = $self->{propertySet}->getProp("tiffFilePath"); 
  my $gprFilePath   = $self->{propertySet}->getProp("GPRFilePath"); 
  my $studyId       = $self->{propertySet}->getProp("Study_ID");
  my $testNumber    = $self->getArgs->{testnumber};
  my @skipAssayList = @{$self->getArgs->{skip}};

  my $assayNames              = $self->findAssayNames($gprFilePath);
  my $assayDescriptionHashRef = $self->parseMultipleDescriptions("allAssayDescriptionsSame","allAssayDescriptions","individualAssayDescriptions");
  my $hybDateHashRef          = $self->parseMultipleDescriptions("allHybDatesSame","allHybDates","individualHybDates");
  my $scanDateHashRef         = $self->parseMultipleDescriptions("allScanDatesSame","allScanDates","individualScanDates");
  my $imageFilesRef           = $self->getImageFileNames($tiffFilePath); 

  my $skipAssayCnt  = scalar @skipAssayList;
  my $totalAssayCnt = scalar @$assayNames;

  $self->log("STATUS","Found $totalAssayCnt assays");
  $self->log("STATUS","Skipping assay/s @skipAssayList") if (scalar @skipAssayList > 0);

  foreach my $assayName (@$assayNames) {

    next if (($assayCnt > ($testNumber - 1)) && (defined $testNumber));
    next if (grep { $assayName =~ /^$_/ } @skipAssayList);

    my $gusAssay = $self->createSingleGUSAssay($assayName, $hybDateHashRef, $scanDateHashRef, $assayDescriptionHashRef, $imageFilesRef);

    push(@gusAssays, $gusAssay);
    $assayCnt++;
  }

  $self->log("STATUS","-------- End Assay Descriptions --------");
  $self->log("STATUS","OK Created $assayCnt assay/s");

  return (\@gusAssays, $skipAssayCnt, $totalAssayCnt);
}

###############################

sub submitGusAssays {
  my ($self,$gusAssays) = @_;

  my $studyId = $self->{propertySet}->getProp("Study_ID");

  my $gusStudy = GUS::Model::RAD3::Study->new({study_id => $studyId});
  unless ($gusStudy->retrieveFromDB) {
    $self->error("Failed to create an object for study $studyId from RAD3.Study");
  }

  my $gusInsertedAssayCnt = 0;
  foreach my $gusAssay (@$gusAssays) {

    my $studyAssay = GUS::Model::RAD3::StudyAssay->new(); # links RAD3.Study & RAD3.Assay

    $studyAssay->setParent($gusAssay);
    $studyAssay->setParent($gusStudy);

    $gusAssay->submit() if ($self->getArgs->{commit});
    $gusInsertedAssayCnt++;
  }

  return $gusInsertedAssayCnt;
}

###############################

sub populateRelatedTables {
  my ($self, $studyId) = @_; 

  my $dbh = $self->getQueryHandle();
  my $sth = $dbh->prepare("select assay_id from rad3.studyassay where study_id = ?");
  $sth->execute("$studyId");

  my @assayIds = ();
  while (my @row = $sth->fetchrow_array) {
    push (@assayIds, $row[0]);
  }

  $sth->finish;
  $self->error("Id $studyId does not exist in the table rad3.studyassay") if (scalar @assayIds eq 0); 

  my $insertedRelatedCnt = 0;

  foreach my $assayId (@assayIds) {

    my $tempAssayName = GUS::Model::RAD3::Assay->new({assay_id => $assayId});
    $self->error("Create object failed, assay Id $assayId absent in table RAD3::Assay")
      unless ($tempAssayName->retrieveFromDB);
    my $assayName = $tempAssayName->getName();

    my ($acquisitionIdsRef, $acquisitionChannelsRef) = $self->populateRelatedAcquisition($assayName, $assayId);
    $self->populateRelatedQuantification($assayName, $assayId, $acquisitionIdsRef, $acquisitionChannelsRef);

    $insertedRelatedCnt++;
  }

  $self->log("STATUS","Inserted $insertedRelatedCnt x 2 rows in rad3.relatedacquisition and rad3.relatedquantification");
  return $insertedRelatedCnt;
}

###############################

sub populateRelatedAcquisition {
  my ($self, $assayName, $assayId) = @_; 

  my $dbh = $self->getQueryHandle();
  my $sth = $dbh->prepare("select acquisition_id, channel_id from rad3.acquisition where assay_id = ?");
  $sth->execute("$assayId");

  my (@acquisitionIds, @acquisitionChannels) = ();

  while (my @row = $sth->fetchrow_array) {
    push (@acquisitionIds, $row[0]);

    my $tempChannelName = GUS::Model::RAD3::Channel->new({channel_id => $row[1]});
    $self->error("Create object failed, channel Id $row[1] absent in table RAD3::Channel")
      unless ($tempChannelName->retrieveFromDB);
    my $channelName = $tempChannelName->getName();

    push (@acquisitionChannels, $channelName);
  }

  $sth->finish;
  $self->error("Id $assayId does not exist in the table rad3.acquistion") if (scalar @acquisitionIds eq 0); 
  $self->error("More/less than two entries found for assay id $assayId in rad3.acquistion") if (scalar @acquisitionIds ne 2); 
    
  my $acquistionAssociationOne = GUS::Model::RAD3::RelatedAcquisition->new({
    acquisition_id            => $acquisitionIds[0],
    associated_acquisition_id => $acquisitionIds[1],
    name                      => $assayName,
    designation               => "$acquisitionChannels[0] acquisition",
    associated_designation    => "$acquisitionChannels[1] acquisition",
  });

  my $acquistionAssociationTwo = GUS::Model::RAD3::RelatedAcquisition->new({
    acquisition_id            => $acquisitionIds[1],
    associated_acquisition_id => $acquisitionIds[0],
    name                      => $assayName,
    designation               => "$acquisitionChannels[1] acquisition",
    associated_designation    => "$acquisitionChannels[0] acquisition",
  });

  $acquistionAssociationOne->submit() if ($self->getArgs->{commit});
  $acquistionAssociationTwo->submit() if ($self->getArgs->{commit});

  return (\@acquisitionIds, \@acquisitionChannels);
}

###############################

sub populateRelatedQuantification {
  my ($self, $assayName, $assayId, $acquisitionIdsRef, $acquisitionChannelsRef) = @_; 

  my @quantificationIds;
  foreach my $acquisitionId (@$acquisitionIdsRef) {

    my $tempQuantId = GUS::Model::RAD3::Quantification->new({acquisition_id => $acquisitionId});
    $self->error("Create object failed, acquisition Id $acquisitionId absent in table RAD3::Quantification")
      unless ($tempQuantId->retrieveFromDB);
    my $quantificationId = $tempQuantId->getQuantificationId();

    push (@quantificationIds, $quantificationId);
  }

  $self->error("More/less than two entries found for acqusitions @$acquisitionIdsRef in rad3.quantification") 
    if (scalar @quantificationIds ne 2); 
    
  my $quantificationAssociationOne = GUS::Model::RAD3::RelatedQuantification->new({
    quantification_id            => $quantificationIds[0],
    associated_quantification_id => $quantificationIds[1],
    name                         => $assayName,
    designation                  => "@$acquisitionChannelsRef[0] quantification",
    associated_designation       => "@$acquisitionChannelsRef[1] quantification",
  });

  my $quantificationAssociationTwo = GUS::Model::RAD3::RelatedQuantification->new({
    quantification_id            => $quantificationIds[1],
    associated_quantification_id => $quantificationIds[0],
    name                         => $assayName,
    designation                  => "@$acquisitionChannelsRef[1] quantification",
    associated_designation       => "@$acquisitionChannelsRef[0] quantification",
  });
  $quantificationAssociationOne->submit() if ($self->getArgs->{commit});
  $quantificationAssociationTwo->submit() if ($self->getArgs->{commit});
}

###############################

sub findAssayNames {
  my ($self,$assayNameFilesDir) = @_;

  my @assayNames;
  my $requiredExtension = "gpr";  # filenames correspond to assay names

  opendir (DIR,$assayNameFilesDir) || $self->userError("Cannot open dir $assayNameFilesDir");
  my @assayDir = readdir DIR; 
  close (DIR);

  $self->userError("Cannot create assays, directory $assayNameFilesDir is empty!") 
    if (scalar @assayDir eq 0); 

  foreach my $file (@assayDir) { 

    next if ($file eq '.' || $file eq '..'); # skip '.' and '..' files

    $file =~ /(.+)\.(\w+)/;             # split name based on '.'

    next unless ($2);                   # skip files with no extension
    next if ($2 ne $requiredExtension); # skip files with diff extension
    push (@assayNames,$1);
  }
 
  return \@assayNames;
}

###############################

sub parseMultipleDescriptions {
  my ($self, $assayNames, $allValuesFlag, $allValues, $individualValues) = @_;

  my $infoHashRef;
  my $allValuesContent = $self->{propertySet}->getProp($allValuesFlag);

  if ($allValuesContent eq "no") {

    my @individualValuesArray = split /\;/, $self->{propertySet}->getProp($individualValues);
    foreach my $individualValue (@individualValuesArray) {
      my ($key,$value) = split /\|/, $individualValue;
      $infoHashRef->{$key} = $value;
    }
  } else {
    foreach my $assayName (@$assayNames) {
      $infoHashRef->{$assayName} = $self->{propertySet}->getProp($allValues) if ($allValuesContent eq "yes");
      $infoHashRef->{$assayName} = "" if ($allValuesContent eq "NOVALUEPROVIDED");
    }
  }

  return $infoHashRef;
}

###############################

sub getImageFileNames {
  my ($self, $imageFilesDir) = @_;

  my $imageFilesRef;

  opendir (DIR,$imageFilesDir) || $self->userError("Cannot open dir $imageFilesDir");
  my @imageFiles = readdir DIR; 
  close (DIR);

  foreach my $imageFile (@imageFiles) { 

    next if ($imageFile eq '.' || $imageFile eq '..'); # skip '.' and '..' files
    
    my ($fileName, $extention) = $imageFile =~ /(.+)\.(\w+$)/;
    my ($assay, $type) = $fileName =~ /(.+)\_(.+)/;

    if ($type eq "Cy5Cy3" || $type eq "Cy3Cy5") {
      $imageFilesRef->{$assay."_Cy5"} = $imageFilesDir."/".$imageFile;
      $imageFilesRef->{$assay."_Cy3"} = $imageFilesDir."/".$imageFile;

    } else {
      $imageFilesRef->{$assay."_$type"} = $imageFilesDir."/".$imageFile;
    }
  }

  return $imageFilesRef;
}

###############################

sub createSingleGUSAssay {
  my ($self, $assayName, $hybDateHashRef, $scanDateHashRef, $assayDescriptionHashRef, $imageFilesRef) = @_;

  $self->log("STATUS","----- Assay $assayName -----");

  $self->checkRequiredFilesExist($assayName, $imageFilesRef);

  my $GPRinfo = $self->parseTabFile('GPR', $assayName);

  my $gusAssay = $self->createGusAssay($assayName, $GPRinfo, $hybDateHashRef, $assayDescriptionHashRef);

  my ($gusAcquisitionCy5, $gusAcquisitionCy3) = $self->createGusAcquisition($assayName, $imageFilesRef, $scanDateHashRef);

  $gusAcquisitionCy5->setParent($gusAssay);
  $gusAcquisitionCy3->setParent($gusAssay);

  my ($gusQuantificationCy5, $gusQuantificationCy3) = $self->createGusQuantification($assayName);
  my ($gusQuantParamsCy5Ref, $gusQuantParamsCy3Ref) = $self->createGusQuantParams($GPRinfo);

  $gusQuantificationCy5->setParent($gusAcquisitionCy5);
  foreach my $gusQuantParamsCy5 (@$gusQuantParamsCy5Ref) {
    $gusQuantParamsCy5->setParent($gusQuantificationCy5);
  }

  $gusQuantificationCy3->setParent($gusAcquisitionCy3);
  foreach my $gusQuantParamsCy3 (@$gusQuantParamsCy3Ref) {
    $gusQuantParamsCy3->setParent($gusQuantificationCy3);
  }

  return $gusAssay;
}

###############################

sub checkRequiredFilesExist {
  my ($self, $assayName, $imageFilesRef) = @_;

  my $gprFile     = $self->{propertySet}->getProp("GPRFilePath")."/$assayName.gpr";
  my $tiffFileCy5 = $imageFilesRef->{$assayName."_Cy5"};
  my $tiffFileCy3 = $imageFilesRef->{$assayName."_Cy3"};

  $self->userError("Missing file: $gprFile") if (! -e $gprFile); 

  $self->userError("Missing Cy5 tif (image) file for assay: $assayName") if (! -e $tiffFileCy5); 
  $self->userError("Empty Cy5 tif (image) file for assay: $assayName")   if ( -z $tiffFileCy5); 
  $self->userError("Missing Cy3 tif (image) file for assay: $assayName") if (! -e $tiffFileCy3); 
  $self->userError("Empty Cy3 tif (image) file for assay: $assayName")   if ( -z $tiffFileCy3); 
}

###############################

sub parseTabFile {
  my ($self, $prefix, $assayName) = @_;

  my $GPRinfo;
  my $flag = 1;

  my $filePath = $self->{propertySet}->getProp("${prefix}FilePath");

  $prefix = "gpr" if ($prefix eq "GPR"); # quick fix
 
  my $file = "$filePath/$assayName.$prefix";

  open (GPRFILE, $file) || $self->userError("Can't open $file: $!");
  while (<GPRFILE>) {

    chomp $_;
    my ($key, $value);

    $flag = 0 if ($_ =~ /Block/);  # skip all lines after the 'Block' line
    next if ($flag eq 0);          # skip lines not required
    next if (/^\s+$/);             # skip empty lines
    s/\r$//;                       # remove ^M at the end
    s/\"//g;                       # remove '"' in each line

    my ($key, $value) = split /\=/, $_;
    $value = "N/A" if ($value eq ""); 

    my ($modifiedKey, $modifiedValue) = $self->modifyKeyValuePairs($key, $value);
    $GPRinfo->{$modifiedKey} = $modifiedValue;
  }

  close (GPRFILE);

  return $GPRinfo;
}

###############################

sub modifyKeyValuePairs {
  my ($self, $key, $value) = @_;

  my ($modifiedKey, $modifiedValue);

  # can be extended to fill as many values as required, 
  # via 'elsif' statements

  if ($key eq "Creator") {
    my @softwareVersionInfo = split " ",$value;
    my $softwareVersion;
    foreach my $word (@softwareVersionInfo) {
      $softwareVersion = $word if (/[0-9]/);
    }

    $modifiedKey = "software version";
    $modifiedValue = $softwareVersion;

  } elsif ($key eq "RatioFormulations") {

      $modifiedKey = "ratio formulations"; 

      $value =~ s/[\(|\)]/\-/g;
      my @tempValueArray = split /\-/, $value;
      my $tempValue = pop @tempValueArray;
      my ($wavelengthOne, $wavelengthTwo) = split /\//, $tempValue;
      $modifiedValue = $wavelengthOne."nm/".$wavelengthTwo."nm";

  } elsif ($key eq "BackgroundSubtraction") {
      
      $modifiedKey = "background density measure";
      $modifiedValue = $value;
      $modifiedValue = "local" if ($value eq "LocalFeature");

  } elsif ($key eq "StdDev") {

      $modifiedKey = "standard deviation";
      $modifiedValue = $value;
      $modifiedValue = "Normal(SD)" if ($value eq "Type 1");
      $modifiedValue = "Alternate(SD2)" if ($value eq "Type 2");

  } else {
      $modifiedKey = $key;
      $modifiedValue = $value;
  }

  return ($modifiedKey, $modifiedValue);
}

###############################

sub createGusAssay {
  my ($self, $assayName, $GPRinfo, $hybDateHashRef, $assayDescriptionHashRef) = @_;

  my $arrayId       = $self->{propertySet}->getProp("arrayId");
  my $batchId       = $self->{propertySet}->getProp("batchId");
  my $hybProtocolId = $self->{propertySet}->getProp("Hyb_Protocol_ID");
  my $hybOperatorId = $self->{propertySet}->getProp("Hyb_Operator_ID");

  my $hybDate = $hybDateHashRef->{$assayName};
  my $description = $assayDescriptionHashRef->{$assayName};

  my $params = {
    array_id    => $arrayId,
    assay_date  => $hybDate,
    protocol_id => $hybProtocolId,
    operator_id => $hybOperatorId,
    name        => $assayName,
  };

  $params->{"array_batch_identifier"} = $batchId if ($batchId ne "NOVALUEPROVIDED");
  $params->{"description"} = $description if ($description ne "NOVALUEPROVIDED");

  my $assay = GUS::Model::RAD3::Assay->new($params);

  $self->log("STATUS","OK Inserted 1 row in table RAD3.Assay for assay $assayName");

  return $assay;
}

###############################

# gusAssayParams (or hyb params) are to be input via the Study Annotator website

###############################

sub createGusAcquisition {
  my ($self, $assayName, $imageFilesRef, $scanDateHashRef) = @_;

  my $acqProtocolId = $self->{propertySet}->getProp("Acq_Protocol_ID");

  my $acqDate = $scanDateHashRef->{$assayName};

  my $channelDefs = {
    'Cy5' => "",   # HARD-CODED: select channel def from rad3.channel from your own instance
    'Cy3' => ""    # HARD-CODED: select channel def from rad3.channel from your own instance
  };
  my $channelParams = $channelDefs;

  my $protocol = GUS::Model::RAD3::Protocol->new({protocol_id => $acqProtocolId});
  $self->error("Create object failed, protocol ID $acqProtocolId absent in table RAD3::Protocol")
    unless ($protocol->retrieveFromDB);
  my $tempAcqName = $protocol->getName();

  my $acqParametersCommon = {
    acquisition_date => $acqDate,
    protocol_id      => $acqProtocolId
  };

  foreach my $channel (keys %$channelDefs) {
    my $channelName = GUS::Model::RAD3::Channel->new({ name => $channel});
    $self->error("Create object failed, parameter name '$channel' absent in table RAD3::Channel")
      unless ($channelName->retrieveFromDB);
    $channelDefs->{$channel} = $channelName->getChannelId();

    my $acqName = "$channel $assayName".$protocol;
    my $acqParameters = $acqParametersCommon;
    $acqParameters = {
      name       => $acqName,
      channel_id => $channelDefs->{$channel},
      uri        => $imageFilesRef->{$assayName."_$channel"}
    };

    $channelParams->{$channel} = $acqParameters;
  }

  my $acquisitionCy5 = GUS::Model::RAD3::Acquisition->new($channelParams->{"Cy5"});
  my $acquisitionCy3 = GUS::Model::RAD3::Acquisition->new($channelParams->{"Cy3"});

  $self->log("STATUS","OK Inserted 2 rows in table RAD3.Acquisition for assay $assayName channel Cy5 and Cy3");
  return ($acquisitionCy5, $acquisitionCy3);
}

###############################

# acquisitionParams are to be input via the Study Annotator website

###############################

sub createGusQuantification {
  my ($self, $assayName) = @_;

  my (@gusQuantificationsCy5, @gusQuantificationsCy3);

  my $gprURI          = $self->{propertySet}->getProp("GPRFilePath");
  my $acqProtocolId   = $self->{propertySet}->getProp("Acq_Protocol_ID");
  my $quantOperatorId = $self->{propertySet}->getProp("Quant_Operator_ID");
  my $quantProtocolId = $self->{propertySet}->getProp("Quant_Protocol_ID");

  my $protocol = GUS::Model::RAD3::Protocol->new({protocol_id => $acqProtocolId});
  $self->error("Create object failed, $acqProtocolId absent in table RAD3::Protocol")
    unless ($protocol->retrieveFromDB);

  my $tempAcqName = $protocol->getName();

  my $gprQuantParameters = {
    protocol_id => $quantProtocolId,
    uri         => $gprURI
  };

  $gprQuantParameters->{operator_id} = $quantOperatorId if (defined $quantOperatorId);

  my $acqNameCy5                 = "Cy5 $assayName $tempAcqName";
  my $gprQuantParametersCy5      = $gprQuantParameters;
  $gprQuantParametersCy5->{name} = $acqNameCy5;
  my $gprQuantificationCy5       = GUS::Model::RAD3::Quantification->new($gprQuantParametersCy5);

  my $acqNameCy3                 = "Cy3 $assayName $tempAcqName";
  my $gprQuantParametersCy3      = $gprQuantParameters;
  $gprQuantParametersCy3->{name} = $acqNameCy3;
  my $gprQuantificationCy3       = GUS::Model::RAD3::Quantification->new($gprQuantParametersCy3);

  $self->log("STATUS","OK Inserted 2 rows in table RAD3.Quantification for Cy5 & Cy3 quantifications");

  return ($gprQuantificationCy5, $gprQuantificationCy3);
}
###############################

sub createGusQuantParams {
  my ($self, $GPRinfo) = @_;

  my $quantProtocolId = $self->{propertySet}->getProp("Quant_Protocol_ID");

  my (@gusQuantParamsCy5, @gusQuantParamsCy3);
  my $quantParamKeywordCnt = 0;

  my $params = {
    'ratio formulations'         => 1, 
    'standard deviation'         => 1,
    'background density measure' => 1,
    'software version'           => 1
  };

  foreach my $param (keys %$params) {

    my $protocolParam = GUS::Model::RAD3::ProtocolParam->new({
        protocol_id => $quantProtocolId,
        name        => $param
    });

    $self->error("Create object failed, name $param absent in table RAD3::ProtocolParam")
      unless ($protocolParam->retrieveFromDB);

    my $quantParameters = GUS::Model::RAD3::QuantificationParam->new({
     name  => $param,
     value => $GPRinfo->{$param}
     });

    my $quantParametersCy5 = $quantParameters;
    $quantParametersCy5->setParent($protocolParam); # protocolParam in only needed here, so set parent here
    push(@gusQuantParamsCy5, $quantParametersCy5);

    my $quantParametersCy3 = $quantParameters;
    $quantParametersCy3->setParent($protocolParam); # protocolParam in only needed here, so set parent here
    push(@gusQuantParamsCy3, $quantParametersCy3);
    
    $quantParamKeywordCnt++;
  }

  $self->log("STATUS","OK Inserted $quantParamKeywordCnt rows in table RAD3.QuantificationParam for Cy5 and Cy3");
  return (\@gusQuantParamsCy5, \@gusQuantParamsCy3);
}

