package GUS::RAD::Plugin::MAS5StudyModuleILoader;
@ISA = qw( GUS::PluginMgr::Plugin);

use strict 'vars';

use CBIL::Util::Disp;
use CBIL::Util::PropertySet;
use GUS::PluginMgr::Plugin;
use GUS::Model::RAD3::Study;
use GUS::Model::RAD3::Assay;
use GUS::Model::RAD3::AssayParam;
use GUS::Model::RAD3::StudyAssay;
use GUS::Model::RAD3::Acquisition;
use GUS::Model::RAD3::AcquisitionParam;
use GUS::Model::RAD3::Quantification;
use GUS::Model::RAD3::QuantificationParam;
use GUS::Model::RAD3::Array;
use GUS::Model::RAD3::Protocol;
use GUS::Model::RAD3::ProtocolParam;
use GUS::Model::RAD3::Channel;
use GUS::Model::SRes::Contact;


sub new {
  my ($class) = @_;
  my $self = {};
  bless($self, $class);

  my $purposeBrief = 'Plugin is BatchLoader, creates assays, acquisitions and quantifications for Affymetrix assays in RAD3 tables.';
  my $purpose      = "Create assays, acquisitions and quantifications for Affymetrix assays in RAD3 tables from multiple files in batch mode.";
  
  my $tablesAffected = [
    ['RAD3::Assay',               'Enters as many rows as distinct assays found'],
    ['RAD3::AssayParam',          'For each assay entered, enters here the values of the Fluidics protocol parameters as recorded in the corresponding .EXP file'],
    ['RAD3::Quantification',      'Enters here two quantifications, cel and chp, for each assay entered'],
    ['RAD3::QuantificationParam', 'For each assay entered, enters here the values for parameters recorded in the corresponding .RPT file'],
    ['RAD3::Acquisition',         'Enters here one acquisition for each assay entered'],
    ['RAD3::AcquisitionParam',    'For each assay entered, enters here the values for parameters recorded in the corresponding .EXP file'],
    ['RAD3::StudyAssay',          'Row linking the given study to an assay is entered']
   ];

  my $tablesDependedOn = [
    ['RAD3::Study',                'The particular study to which the assay belongs'],
    ['RAD3::Array',                'Holds array information'], 
    ['RAD3::Protocol',             'The hybridization, image_acquisition, and feature_extraction protocols used'], 
    ['RAD3::ProtocolParam',        'Parameters for the protocol used'], 
    ['RAD3::Contact',              'Information on researchers who performed the hybridization and the image analysis']
  ];

  my $howToRestart = "Cannot be restarted."; 
  
  my $failureCases = "Files not in an appropriate format.";

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

 - EXPFilePath = full path to the dir where the EXP files are kept 
 - RPTFilePath = full path to the dir where the RPT files are kept 
 - CELFilePath = full path to the dir where the CEL files are kept 
 - DATFilePath** = full path to the dir where the DAT files are kept
 - MetricsFilePath = full path to the dir where the Metrics files are kept 
 - Hyb_Protocol_ID = hybridization protocol id, should pre-exist in the RAD3 database 
 - Acq_Protocol_ID = acquisition protocol id, should pre-exist in the RAD3 database 
 - Cel_Protocol_ID = cel quantification protocol id, should pre-exist in the RAD3 database 
 - Chp_Protocol_ID = chp quantification protocol id, should pre-exist in the RAD3 database 
 - Hyb_Operator_ID = contact_id of the person who carried out the hybridization, should pre-exist in the RAD3 database 
 - Cel_Quant_Operator_ID** = contact_id of the person who carried out the cel quantification, should pre-exist in the RAD3 database 
 - Chp_Quant_Operator_ID** = contact_id of the person who carried out the chp quantification, should pre-exist in the RAD3 database 
 - Study_ID = the study identifier, should pre-exist in the RAD3 database 
 - Extensions = the extensions for each file type (should be in the form: expFile|EXP;celFile|CEL; and so on)

** These values are optional, i.e., the keywords should exist, but their the values can be input as the word 'null',
(without the single quotes) if no values exist.

Each of these keywords should be on a separate line. The values for these keywords should be seperated by '='. A sample
file is maintained in \$GUS_HOME/config/sample_MAS5StudyModuleILoader.cfg

For the 'Extensions' keyword, multiple values can be input in the following form:
 EXPFile|EXP;RPTFile|RPT;CELFile|CEL;DATFile|DAT;MetricsFile|txt;
This allows the user to specify proper extensions; for instance, if all the Metrics files have an extension 'TXT', and not
'txt', it can be specified here. Please make sure there is no space between the semi-colons after each file type.


=head2 F<Database requirements>

This plugin assumes that the following entries exist in your instance of the database:

 1.  The study in RAD3.Study
 2.  The appropriate Affymetrix array in RAD3.Array
 3.  The hybridization protocol, the acquisition protocol, the quantification protocol in RAD3.Protocol
 4.  For each of the protocol entries in 3, all of its parameters in RAD3.ProtocolParam

If any of the above is missing, the plugin will report an error.

=head2 F<Warning (for non-CBIL instances)>

For local installations of RAD which differ from the CBIL database, some lines of this plugin will need to be modified, to accomodate
hard-coded information. You might need to modify any piece of code labelled as 'HARD-CODED' in the comments below.


=head1 AUTHORS

Shailesh Date, Hongxian He

=head1 COPYRIGHT

Copyright, Trustees of University of Pennsylvania 2003. 

=cut

NOTES


  my $documentation = {
    purpose          =>$purpose, 
    purposeBrief     =>$purposeBrief,
    tablesAffected   =>$tablesAffected,
    tablesDependedOn => $tablesDependedOn,
    howToRestart     =>$howToRestart,
    failureCases     =>$failureCases,
    notes            =>$notes
  };
 

  my $argsDeclaration  = [

    fileArg({
      name           => 'cfg_file',
      descr          => 'The full path of the cfg file.',
      constraintFunc => undef,
      reqd           => 1,
      isList         => 0, 
      mustExist      => 1,
      format         => 'See NOTES'
    }),

    stringArg({
      name           => 'skip',
      descr          => 'The list of prefixes of the files in the specified directories that will be skipped for loading.',
      constraintFunc => undef,
      reqd           => 0,
      isList         => 1, 
    }),
     
    integerArg({
      name           => 'testnumber',
      descr          => 'Number of assays to be loaded for testing',
      constraintFunc => undef,
      reqd           => 0,
      isList         => 0 
    })
  ];

  $self->initialize({
    requiredDbVersion => {RAD3 => '3', Core => '3'},
    cvsRevision       => '$Revision$',
    cvsTag            => '$Name$',
    name              => ref($self),
    revisionNotes     => '',
    argsDeclaration   => $argsDeclaration,
    documentation     => $documentation
  });
  return $self;
}

my @properties =
(
    ["EXPFilePath",           "",""],
    ["RPTFilePath",           "",""],
    ["CELFilePath",           "",""],
    ["DATFilePath",           "",""],  # can be empty
    ["MetricsFilePath",       "",""],
    ["Hyb_Protocol_ID",       "",""],
    ["Acq_Protocol_ID",       "",""],
    ["Cel_Protocol_ID",       "",""],
    ["Chp_Protocol_ID",       "",""],
    ["Hyb_Operator_ID",       "",""],
    ["Cel_Quant_Operator_ID", "",""],
    ["Chp_Quant_Operator_ID", "",""],
    ["Study_ID",              "",""],
    ["Extensions",            "",""]
 ); 

###############################

sub run {
  my $self = shift;
    
  $self->logAlgInvocationId();
  $self->logCommit();
  $self->logArgs();

  $self->{propertySet} = CBIL::Util::PropertySet->new($self->getArg('cfg_file'), \@properties);

  # UNCOMMENT THE FOLLOWING LINE IF THE PLUGIN PRESENTS MEMORY PROBLEMS
  #$self->getDb()->setMaximumNumberOfObjects(30000);

  my ($insertedAssayCnt, $skippedAssayCnt, $totalAssayCnt) = $self->createAndSubmitGUSAssaysFromFiles();
  
  $self->setResultDescr(
   "Total assays: $totalAssayCnt; Assay/s inserted in DB: $insertedAssayCnt; Skipped assay/s: $skippedAssayCnt"
  );
}

###############################

sub createAndSubmitGUSAssaysFromFiles {
  my ($self) = @_;

  my $expFilePath   = $self->{propertySet}->getProp("EXPFilePath");
  my $extensionInfo = $self->{propertySet}->getProp("Extensions");
  my $testNumber    = $self->getArgs->{testnumber};
  my @skipAssayList = @{$self->getArgs->{skip}};

  $expFilePath .= "/" if ($expFilePath !~ m/(.+)\/$/);

  my $extensionHashRef = $self->getFileExtensions($extensionInfo);
  my $assayNames       = $self->findAssayNames($expFilePath, $extensionHashRef);

  my $skipAssayCnt  = scalar @skipAssayList;
  my $totalAssayCnt = scalar @$assayNames;

  my @gusAssays;
  my $assayCnt = 0;
  my $insertedAssayCnt = 0;

  $self->log("STATUS","Found $totalAssayCnt assays");
  $self->log("STATUS","Skipping assay/s @skipAssayList") if (scalar @skipAssayList > 0);

  foreach my $assayName (@$assayNames) {

    next if (($assayCnt > ($testNumber - 1)) && (defined $testNumber));
    next if (grep { $assayName =~ /^$_/ } @skipAssayList);

    my $gusAssay       = $self->createSingleGUSAssay($assayName, $extensionHashRef);
    $insertedAssayCnt += $self->submitSingleGUSAssay($gusAssay);
    $assayCnt++;
	$self->undefPointerCache();  # clean memory
  }

  $self->log("STATUS","-------- End Assay Descriptions --------");
  $self->log("STATUS","OK   Created $assayCnt assay/s");

  return ($insertedAssayCnt, $skipAssayCnt, $totalAssayCnt);
}

###############################

sub submitSingleGUSAssay {
  my ($self, $gusAssay) = @_;

  my $studyId = $self->{propertySet}->getProp("Study_ID");

  my $gusStudy = GUS::Model::RAD3::Study->new({study_id => $studyId});
  unless ($gusStudy->retrieveFromDB) { 
    $self->error("Failed to create an object for study $studyId from RAD3.Study"); 
  }

  my $insertedAssayCnt = 0;

  my $studyAssay = GUS::Model::RAD3::StudyAssay->new(); # links RAD3.Study & RAD3.Assay

  $studyAssay->setParent($gusAssay);
  $studyAssay->setParent($gusStudy);
 
  if ($self->getArgs->{commit}) {
    $gusAssay->submit();
    $insertedAssayCnt = 1;
  }

  return $insertedAssayCnt;
}

###############################

sub getFileExtensions {
  my ($self, $extensions) = @_;
  
  my $extensionHashRef;

  my @extensionArray = split /\;/, $extensions;

  foreach my $extensionType (@extensionArray) {
    my ($fileType, $extension) = split /\|/, $extensionType;
    $extensionHashRef->{$fileType} = $extension;
  }

  return $extensionHashRef;
}

###############################

sub findAssayNames {
  my ($self, $assayNameFilesDir, $extensionHashRef) = @_;

  my (@assayNames, @assayDir);

  my $requiredExtension = $extensionHashRef->{"EXPFile"}; # EXP filenames correspond to assay names

  opendir (DIR, $assayNameFilesDir) || $self->userError("Cannot open dir $assayNameFilesDir");
  @assayDir = readdir DIR; 
  close (DIR);

  $self->userError("Cannot create assays, directory $assayNameFilesDir is empty!") 
    if (scalar @assayDir eq 0); 

  foreach my $file (@assayDir) { 

    next if ($file eq '.' || $file eq '..');              # skip '.' and '..' files

    my ($fileName, $extension) = $file =~ /(.+)\.(\w+)/;
    next unless ($extension);                             # skip files with no extension
    next if ($extension ne $requiredExtension);           # skip files with diff extension

    push (@assayNames, $1);
  }
 
  return \@assayNames;
}

###############################

sub createSingleGUSAssay {
  my ($self, $assayName, $extensionHashRef) = @_;

  $self->log("STATUS","----- Assay $assayName -----");

  $self->checkRequiredFilesExist($assayName, $extensionHashRef);

  my ($EXPinfo, $EXPfluidicsInfo) = $self->parseTabFile($extensionHashRef->{"EXPFile"}, $assayName);
  my ($RPTinfo, $RPTfluidicsInfo) = $self->parseTabFile($extensionHashRef->{"RPTFile"}, $assayName);
  
  my $gusAssay               = $self->createGusAssay($assayName, $EXPinfo);
  my $gusAssayParams         = $self->createGusAssayParams($EXPinfo, $EXPfluidicsInfo);
  my $gusAcquisition         = $self->createGusAcquisition($assayName, $EXPinfo, $extensionHashRef);
  my $gusAcquistionParamsRef = $self->createGusAcquisitionParams($EXPinfo);
  my $gusQuantificationsRef  = $self->createGUSQuantification($assayName, $RPTinfo, $extensionHashRef);

  foreach my $gusAssayParam (@$gusAssayParams) { 
    $gusAssayParam->setParent($gusAssay); 
  }
  
  $gusAcquisition->setParent($gusAssay);

  foreach my $gusAcquisitionParam (@$gusAcquistionParamsRef) { 
    $gusAcquisitionParam->setParent($gusAcquisition); 
  }
  
  foreach my $gusQuantification (@$gusQuantificationsRef) { 

    $gusQuantification->setParent($gusAcquisition); 
    next if ($gusQuantification == $gusQuantificationsRef->[0]); # skip cel quantification (not req.)
    my $gusQuantParamsRef = $self->createGUSQuantParams($RPTinfo);
    foreach my $gusQuantParam (@$gusQuantParamsRef) { 
        $gusQuantParam->setParent($gusQuantification); 
     }
  }

  return $gusAssay;
}

###############################

sub checkRequiredFilesExist {
  my ($self, $assayName, $extensionHashRef) = @_;

  my @fileTypes = ("EXP", "RPT", "CEL", "DAT", "Metrics");  # HARD-CODED for our instance of RAD

  foreach my $fileType (@fileTypes) {

    my $filePath = $self->{propertySet}->getProp($fileType."FilePath");
	$filePath .= "/" if ($filePath !~ m/(.+)\/$/);

	my $file = "$assayName.".$extensionHashRef->{$fileType."File"};

	$file = "$assayName"."_Metrics.".$extensionHashRef->{$fileType."File"} if ($fileType eq "Metrics");

    next if (( $fileType eq "DAT" ) && ($self->{propertySet}->getProp($fileType."FilePath") eq "null"));

    $self->userError("Missing file: $file") if ( ! -e $filePath.$file ); 
    $self->userError("Empty file: $file") if ( -z $filePath.$file ); 
  }

  $self->log("STATUS","OK   All required files exist for assay $assayName, and none are empty");
}

###############################

sub parseTabFile {
  my ($self, $prefix, $assayName) = @_;

  my ($info, $fluidicsInfo, $flag);

  my $filePath = $self->{propertySet}->getProp("${prefix}FilePath");

  my $file = "$filePath/$assayName.$prefix";
  open (FILE, $file) || $self->userError("Can't open $file: $!");
  while (<FILE>) {
    next if ( /Affymetrix GeneChip Experiment Information/ || /Sample Info/ || /^\s+$/ );
    chomp $_;
    s/\r$//; # remove ^M at the end

    my @keyValue = split /\t+/,$_ || $self->userError("Formatting error: line '$_' in $file is not tab-delimited");
    my $key = $keyValue[0];
    my $value = $keyValue[1];

    if ($key =~ /Fluidics/) { 
        $flag = 1;  
        next;  
    }

    $flag = 0 if ($key =~ /Hybridize/);

    $info->{$key} = $value;
    $fluidicsInfo->{$key} = $value if ($flag eq 1);
  }

  close (FILE);
  return ($info, $fluidicsInfo);
}

###############################

sub createGusAssay {
  my ($self, $assayName, $EXPinfo) = @_;

  my $arrayName     = $EXPinfo->{"Chip Type"};
  my $batchId       = $EXPinfo->{"Chip Lot"}; 
  my $description   = $EXPinfo->{"Description"}; 
  my $hybDate       = $EXPinfo->{"Hybridize Date"};
  my $hybProtocolId = $self->{propertySet}->getProp("Hyb_Protocol_ID");
  my $hybOperatorId = $self->{propertySet}->getProp("Hyb_Operator_ID");

  $self->checkDatabaseEntry("GUS::Model::RAD3::Protocol", "protocol_id", $hybProtocolId);
  $self->checkDatabaseEntry("GUS::Model::SRes::Contact", "contact_id", $hybOperatorId);
  
  my $arrayIdParams;

  if ($arrayName =~ /^(\S+)(v\d)$/) {  # eg: MG_U74Av2, where version may/may-not be included
    $arrayIdParams = GUS::Model::RAD3::Array->new({
      name    => "Affymetrix $1",
      version => $2
    });

  } else {
    $arrayIdParams = GUS::Model::RAD3::Array->new({
      name    => "Affymetrix $arrayName",
      version => "null"
    });
  }

  $self->error("Create object failed, array name $arrayName absent in table RAD3::Array") 
    unless ($arrayIdParams->retrieveFromDB);
  my $arrayId = $arrayIdParams->getArrayId();

  my $params = {
    array_id               => $arrayId, 
    protocol_id            => $hybProtocolId, 
    operator_id            => $hybOperatorId, 
    name                   => $assayName,
    array_batch_identifier => $batchId, 
    description            => $description
  };
  
  $params->{assay_date} = $self->modifyDate($hybDate) if ($hybDate);

  my $assay = GUS::Model::RAD3::Assay->new($params);

  $self->log("STATUS","OK   Inserted 1 row in table RAD3.Assay");

  return $assay;
}

###############################

sub checkDatabaseEntry {
  my ($self, $tableName, $paramName, $valueToCheck) = @_;

  my $checkerObject = $tableName->new({"$paramName" => $valueToCheck});

  $self->error("Create object failed: Table $tableName value $valueToCheck")
   unless ($checkerObject->retrieveFromDB);
}

###############################

sub createGusAssayParams {
  my ($self, $EXPinfo, $EXPfluidicsInfo) = @_;

  my @gusAssayParams;
  my $fluidicsKeywordCnt = 0;

  my $hybProtocolId = $self->{propertySet}->getProp("Hyb_Protocol_ID");

  foreach my $keyword (keys %$EXPfluidicsInfo) {

    my $key = "Fluidics_$keyword"; # HARD-CODED. Define '$key' as the corresponding RAD3.ProtocolParam.name in your instance
    my $value = $EXPfluidicsInfo->{$keyword};
      
    next unless ($value =~ /\S+/); # skip if no value 

    my $protocolParam = GUS::Model::RAD3::ProtocolParam->new ({
        protocol_id => $hybProtocolId, 
        name        => $key
    });
 
    $self->error("Create object failed, protocol ID $hybProtocolId or name $key absent in table RAD3::ProtocolParam") 
        unless ($protocolParam->retrieveFromDB);
    my $protocolParamId = $protocolParam->getProtocolParamId();

    my $assayParam = GUS::Model::RAD3::AssayParam->new({
        protocol_param_id => $protocolParamId, 
        value             => $value
    }); 
    $fluidicsKeywordCnt++;
    push (@gusAssayParams, $assayParam);
  }

  $self->log("STATUS","OK   Inserted $fluidicsKeywordCnt rows in table RAD3.AssayParam");

  return \@gusAssayParams;
}

###############################

sub createGusAcquisition {
  my ($self, $assayName, $EXPinfo, $extensionHashRef) = @_;

  my $acqProtocolId = $self->{propertySet}->getProp("Acq_Protocol_ID");
  my $scanDate      = $EXPinfo->{"Scan Date"};
  my $channelDef    = "biotin";  # HARD-CODED: select channel def from rad3.channel from your own instance

  my ($localFilePath, $tempDatURI, $datURI);
  if ($self->{propertySet}->getProp("DATFilePath") eq "null") {
    $datURI = "";

  } else {

    $tempDatURI = $self->{propertySet}->getProp("DATFilePath");
    $tempDatURI .= "/" if ($tempDatURI !~ m/(.+)\/$/);
    $tempDatURI = $assayName.".".$extensionHashRef->{"DATFile"};
    ($localFilePath, $datURI) = split "RAD_images/", $tempDatURI; # HARD-CODED. Based on our convention for naming files
  }

  my $protocolId = GUS::Model::RAD3::Protocol->new({protocol_id => $acqProtocolId});
  $self->error("Create object failed, protocol ID $acqProtocolId absent in table RAD3::Protocol") 
    unless ($protocolId->retrieveFromDB);
  my $protocolName = $protocolId->getName();
  my $acqName = "$assayName-$channelDef-".$protocolName;

  my $channelName = GUS::Model::RAD3::Channel->new({ name => $channelDef});
  $self->error("Create object failed, parameter name 'biotin' absent in table RAD3::Channel") 
    unless ($channelName->retrieveFromDB);
  my $channelId = $channelName->getChannelId();

  my $acqParameters = { 
    name        => $acqName, 
    protocol_id => $acqProtocolId, 
    channel_id  => $channelId,
    uri         => $datURI
  };
    
  $acqParameters->{acquisition_date} = $self->modifyDate($scanDate) if ($scanDate);

  my $acquisition = GUS::Model::RAD3::Acquisition->new($acqParameters);

  $self->log("STATUS","OK   Inserted 1 row in table RAD3.Acquisition");

  return $acquisition;
}

###############################

sub createGusAcquisitionParams {
  my ($self, $EXPinfo) = @_;

  my $acqProtocolId = $self->{propertySet}->getProp("Acq_Protocol_ID");

  my %params = (
    'Pixel Size'      =>1,   # WARNING. The plugin assumes this is your RAD3.ProtocolParam.name for 'Pixel Size'.
    'Filter'          =>1,   # WARNING. The plugin assumes this is your RAD3.ProtocolParam.name for 'Filter'.
    'Number of Scans' =>1,   # WARNING. The plugin assumes this is your RAD3.ProtocolParam.name for 'Number of Scans'.
  );

  my @gusAcquisitionParams;
  my $acqParamKeywordCnt = 0;

  foreach my $param (keys %params) {

    my $protocolParam = GUS::Model::RAD3::ProtocolParam->new({
      protocol_id => $acqProtocolId, 
      name        => "$param"
    });

    $self->error("Create object failed, parameter $param absent in table RAD3::ProtocolParam") 
     unless ($protocolParam->retrieveFromDB);
    my $acquisitionParamId = $protocolParam->getProtocolParamId();

    my $acquisitionParam = GUS::Model::RAD3::AcquisitionParam->new({
      protocol_param_id => $acquisitionParamId, 
      name              => $param, 
      value             => $EXPinfo->{$param} 
    });

    $acqParamKeywordCnt++;
    push (@gusAcquisitionParams, $acquisitionParam);
  }

  $self->log("STATUS","OK   Inserted $acqParamKeywordCnt rows in table RAD3.AcquisitionParam");

  return \@gusAcquisitionParams;
}

###############################

sub createGUSQuantification {
  my ($self, $assayName, $RPTinfo, $extensionHashRef) = @_;

  my $tempCelURI         = $self->{propertySet}->getProp("CELFilePath");
  my $tempChpURI         = $self->{propertySet}->getProp("MetricsFilePath");
  my $acqProtocolId      = $self->{propertySet}->getProp("Acq_Protocol_ID");
  my $celProtocolId      = $self->{propertySet}->getProp("Cel_Protocol_ID");
  my $chpProtocolId      = $self->{propertySet}->getProp("Chp_Protocol_ID");
  my $celQuantOperatorId = $self->{propertySet}->getProp("Cel_Quant_Operator_ID");
  my $chpQuantOperatorId = $self->{propertySet}->getProp("Chp_Quant_Operator_ID");

  $tempCelURI .= "/" if ($tempCelURI !~ m/(.+)\/$/);
  $tempChpURI .= "/" if ($tempChpURI !~ m/(.+)\/$/);
  $tempCelURI = $assayName.".".$extensionHashRef->{"CELFile"};
  $tempChpURI = $assayName."_Metrics.".$extensionHashRef->{"MetricsFile"};

  $self->checkDatabaseEntry("GUS::Model::RAD3::Protocol", "protocol_id", $celProtocolId);
  $self->checkDatabaseEntry("GUS::Model::RAD3::Protocol", "protocol_id", $chpProtocolId);
  $self->checkDatabaseEntry("GUS::Model::SRes::Contact", "contact_id", $celQuantOperatorId);
  $self->checkDatabaseEntry("GUS::Model::SRes::Contact", "contact_id", $chpQuantOperatorId);

  my ($localCelFilePath, $celURI) = split "RAD/", $tempCelURI; # HARD-CODED. Based on our convention for naming files
  my ($localChpFilePath, $chpURI) = split "RAD/", $tempChpURI; # HARD-CODED. Based on our convention for naming files

  # modify quantification date, which is not in regular format
  my ($quantificationDate, $tempQuantificationDate);
  foreach my $key (keys %$RPTinfo) {
    $tempQuantificationDate = $RPTinfo->{$key} if ($key =~ m/Date/);
  }
  my ($tempTime, $tempDate) = split " ", $tempQuantificationDate;
  $quantificationDate = $self->getQuantificationDate($tempTime, $tempDate);


  my $protocol = GUS::Model::RAD3::Protocol->new({protocol_id => $acqProtocolId});
  $self->error("Create object failed, $acqProtocolId absent in table RAD3::Protocol") 
    unless ($protocol->retrieveFromDB);

  my $tempAcqName = $protocol->getName();
  my $acqName = $assayName."-Biotin-".$tempAcqName;

  my $celQuantParameters = {
    protocol_id => $celProtocolId, 
    name        => $acqName."-Affymetrix Probe Cell Analysis", 
    uri         => $celURI
  }; 
  $celQuantParameters->{operator_id} = $celQuantOperatorId if ( defined $celQuantOperatorId );
  my $celQuantification = GUS::Model::RAD3::Quantification->new($celQuantParameters);

  my $chpQuantParameters = {
    protocol_id         => $chpProtocolId,
    name                => $acqName."-Affymetrix MAS5 Absolute Expression Analysis", 
    uri                 => $chpURI,
    quantification_date => $quantificationDate
  };
  $chpQuantParameters->{operator_id} = $chpQuantOperatorId if ( defined $chpQuantOperatorId );
  my $chpQuantification = GUS::Model::RAD3::Quantification->new($chpQuantParameters);

  my @gusQuantifications;
  push (@gusQuantifications, $celQuantification, $chpQuantification);

  $self->log("STATUS","OK   Inserted 2 rows in table RAD3.Quantification for CEL & CHP quantification");

  return \@gusQuantifications;
}

###############################

sub createGUSQuantParams {
  my ($self, $RPTinfo) = @_;

  my $chpProtocolId = $self->{propertySet}->getProp("Chp_Protocol_ID");
  $self->checkDatabaseEntry("GUS::Model::RAD3::Protocol", "protocol_id", $chpProtocolId);

  my $params = {
    'Alpha1' => 1,  # WARNING. The plugin assumes this is your RAD3.ProtocalParam.name for 'Alpha1'.
    'Alpha2' => 1,  # WARNING. The plugin assumes this is your RAD3.ProtocalParam.name for 'Alpha2'.
    'Tau'    => 1,  # WARNING. The plugin assumes this is your RAD3.ProtocalParam.name for 'Tau'.
    'TGT'    => 1,  # HARD-CODED. Replace 'TGT' by your RAD3.ProtocolParam.name for 'TGT Value'.
    'SF'     => 1   # HARD-CODED. Replace 'SF' your RAD3.ProtocolParam.name for 'Scale Factor (SF)'.
  };

  # Note: 'TGT' in RAD is represented as 'TGT Value' and 'SF' in RAD is represented as 'Scale Factor (SF)' in .RPT files. 

  my @gusQuantParams;
  my $quantParamKeywordCnt = 0;

  foreach my $param (keys %$params) {

    my $protocolParam = GUS::Model::RAD3::ProtocolParam->new({
      protocol_id => $chpProtocolId, 
      name        => $param
    });

    $self->error("Create object failed, name $param absent in table RAD3::ProtocolParam")
      unless ($protocolParam->retrieveFromDB);

    my $paramValue;

    if ($param eq "TGT") {   # HARD-CODED. Replace 'TGT' by your RAD3.ProtocolParam.name for 'TGT Value'.
      $paramValue = $RPTinfo->{"TGT Value:"}; 

    } elsif ($param eq "SF") {    # HARD-CODED. Replace 'SF' your RAD3.ProtocolParam.name for 'Scale Factor (SF)'.
      $paramValue = $RPTinfo->{"Scale Factor (SF):"}; 

    } else {
      $paramValue = $RPTinfo->{"$param:"};
    }

    my $quantParameters = GUS::Model::RAD3::QuantificationParam->new({
      name  => $param,
      value => $paramValue
    });
    
    $quantParameters->setParent($protocolParam);  # protocolParam in only needed here, so set parent here

    $quantParamKeywordCnt++;
    push(@gusQuantParams,$quantParameters);
  }

  $self->log("STATUS","OK   Inserted $quantParamKeywordCnt rows in table RAD3.QuantificationParam");

  return \@gusQuantParams;
}

###############################

sub modifyDate {
  my ($self, $inputDate) = @_;

  # eg: Hybridize Date  Apr 23 2004 10:58AM
  my @dateArray = split " ", $inputDate;  

  my $arrayLen = scalar @dateArray;
  $self->error("Missing date, cannot continue") if ($arrayLen eq 0);

  my %monthHash = (
    Jan => '01', Feb => '02', Mar => '03', Apr => '04', May => '05', Jun => '06',
    Jul => '07', Aug => '08', Sep => '09', Oct => '10', Nov => '11', Dec => '12'
  );

  my $tempTime = pop @dateArray;    #get time 
  my $time1 = chop $tempTime;       #get AM/PM
  my $time2 = chop $tempTime;       #get AM/PM

  my @hourMinArray = split /\:/,$tempTime;

  my $finalTime;

  if ($time2.$time1 eq "PM") {
      $finalTime = $hourMinArray[0] + 12 if ($hourMinArray[0] <= 11);
      $finalTime = $hourMinArray[0] if ($hourMinArray[0] eq 12);
      $finalTime .= ":$hourMinArray[1]:00";
  } 
  else {
    $finalTime = "$tempTime:00";
  }

  my $monthNum = $monthHash{$dateArray[0]};
  my $finalDateTime = "$dateArray[2]-$monthNum-$dateArray[1]". " $finalTime";

  return $finalDateTime;
}

###############################

sub getQuantificationDate {
  my ($self, $tempTime, $tempDate) = @_;

  # this sub deals with quantification date only, since quantification date
  # is in a different format than other dates in EXP files
  # eg: 09:57PM 06/21/2004

  my $time1 = chop $tempTime;       #get AM/PM
  my $time2 = chop $tempTime;       #get AM/PM

  my @hourMinArray = split /\:/,$tempTime;

  my $finalTime;

  if ($time2.$time1 eq "PM") {
    $finalTime = $hourMinArray[0] + 12 if ($hourMinArray[0] <= 11);
    $finalTime = $hourMinArray[0] if ($hourMinArray[0] eq 12);
    $finalTime = ":$hourMinArray[1]:00"; 

  } else {
    $finalTime = "$tempTime:00";
  }

  my @dateArray = split /\//, $tempDate;
  my $finalDate = "$dateArray[2]-$dateArray[0]-$dateArray[1]";

  my $finalDateTime = "$finalDate $finalTime";

  return $finalDateTime;
}
