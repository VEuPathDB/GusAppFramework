##
## InsertMAS5Assay2Quantification Plugin
## $Id$
##

package GUS::Community::Plugin::InsertMAS5Assay2Quantification;
@ISA = qw( GUS::PluginMgr::Plugin);

use strict 'vars';

# GUS utilities
use GUS::PluginMgr::Plugin;
use GUS::Model::Study::Study;
use GUS::Model::RAD::Assay;
use GUS::Model::RAD::AssayParam;
use GUS::Model::RAD::StudyAssay;
use GUS::Model::RAD::Acquisition;
use GUS::Model::RAD::AcquisitionParam;
use GUS::Model::RAD::Quantification;
use GUS::Model::RAD::QuantificationParam;
use GUS::Model::RAD::ArrayDesign;
use GUS::Model::RAD::Protocol;
use GUS::Model::RAD::ProtocolParam;
use GUS::Model::Study::OntologyEntry;
use GUS::Model::SRes::Contact;

###############################

sub getDocumentation {

  my $purposeBrief = 'Plugin is BatchLoader, creates assays, acquisitions and quantifications for Affymetrix assays in RAD tables.';
  my $purpose      = "Create assays, acquisitions and quantifications for Affymetrix assays in RAD tables from multiple files in batch mode.";
  
  my $tablesAffected = [
    ['RAD::Assay',               'Enters as many rows as distinct assays found'],
    ['RAD::AssayParam',          'For each assay entered, enters here the values of the Fluidics protocol parameters as recorded in the corresponding .EXP file'],
    ['RAD::Quantification',      'Enters here two quantifications, cel and chp, for each assay entered'],
    ['RAD::QuantificationParam', 'For each assay entered, enters here the values for parameters recorded in the corresponding .RPT file'],
    ['RAD::Acquisition',         'Enters here one acquisition for each assay entered'],
    ['RAD::AcquisitionParam',    'For each assay entered, enters here the values for parameters recorded in the corresponding .EXP file'],
    ['RAD::StudyAssay',          'Row linking the given study to an assay is entered']
   ];

  my $tablesDependedOn = [
    ['Study::Study',                'The particular study to which the assay belongs'],
    ['RAD::ArrayDesign',                'Holds array information'], 
    ['RAD::Protocol',             'The hybridization, image_acquisition, and feature_extraction protocols used'], 
    ['RAD::ProtocolParam',        'Parameters for the protocol used'], 
    ['RAD::Contact',              'Information on researchers who performed the hybridization and the image analysis']
  ];

  my $howToRestart = "Cannot be restarted."; 
  
  my $failureCases = "Files not in an appropriate format.";

  my $notes = <<NOTES;

=pod

=head2 F<General Description>

Plugin reads a config file with information about full paths of directories where files of 
interest (.EXP, .RPT etc. ) are maintained.  Data from these files are then parsed and 
entered into a database. The plugin can parse and load information from one or more data 
files into the database at once, and therefore works in 'batch mode'.

This plugin requires two utilities, 'Disp' and 'PropertySet', which are are available with
RAD, and also from the CBIL cvs at:
 http://cvs.cbil.upenn.edu/cgi-bin/cvsweb.cgi/CBIL/Util/lib/perl/ 

=head2 F<Config File (is mandatory)>

Blank lines and comment lines (lines starting with '#') are ignored.
The following keywords and their values are required:

 - SpecificEXPFilePath = full path to the dir where the EXP files are kept 

 - SpecificRPTFilePath = full path to the dir where the RPT files are kept 

 - SpecificCELFilePath = full path to the dir where the CEL files are kept 

 - SpecificDATFilePath** = full path to the dir where the DAT files are kept

 - SpecificMetricsFilePath = full path to the dir where the Metrics files are kept 

 - HybProtocolID = hybridization protocol id, should pre-exist in the 
   RAD database 

 - AcqProtocolID = acquisition protocol id, should pre-exist in the RAD 
   database 

 - CelProtocolID = cel quantification protocol id, should pre-exist in 
   the RAD database 

 - ChpProtocolID = chp quantification protocol id, should pre-exist in 
   the RAD database 

 - HybOperatorID = contact_id of the person who carried out the 
   hybridization, should pre-exist in the RAD database 

 - CelQuantOperatorID** = contact_id of the person who carried out the 
   cel quantification, should pre-exist in the RAD database 

 - ChpQuantOperatorID** = contact_id of the person who carried out the 
   chp quantification, should pre-exist in the RAD database 

 - StudyID = the study identifier, should pre-exist in the RAD database

 - Extensions = the extensions for each file type (should be in the form: 
   expFile|EXP;celFile|CEL; and so on)

** These values are optional, i.e., the keywords should exist, but their the values can be 
input as the word 'null', (without the single quotes) if no values exist.

All keywords are required, and each should be on a separate line with the 
keywords and values seperated by '='. A sample config file is maintained in 
 \$PROJECT_HOME/GUS/RAD/config/sample_MAS5StudyModuleILoader.cfg

The 'Extensions' keyword can support multiple values, provided they are in the following
form:
 EXPFile|EXP;RPTFile|RPT;CELFile|CEL;DATFile|DAT;MetricsFile|txt;

This facilitates file extension specification for individual file types (the plugin
will not tolerate spaces between the semi-colons after each file type).


=head2 F<Database requirements>

This plugin assumes that the following entries exist in your instance of the database:

 1.  The study in RAD.Study
 2.  The appropriate Affymetrix array in RAD.Array
 3.  The hybridization protocol, the acquisition protocol, the 
     quantification protocol in RAD.Protocol
 4.  For each of the protocol entries in 3, all of its parameters 
     in RAD.ProtocolParam

If any of the above is missing, the plugin will report an error.

=head2 F<Warning (for non-CBIL instances)>

For local installations of RAD which differ from the CBIL database, some lines of this 
plugin will need to be modified, to accomodate hard-coded information. Modify lines
labelled 'HARD-CODED' based on information contained in your instance of RAD.


=head1 EXAMPLES

ga GUS::RAD::Plugin::MAS5StudyModuleILoader --cfg_file /somePath/configFile.cfg --testnumber 1 --group myPI --project myProject

ga GUS::RAD::Plugin::MAS5StudyModuleILoader --cfg_file /somePath/configFile.cfg --testnumber 1 --group myPI --project myProject --skip assay123456

ga GUS::RAD::Plugin::MAS5StudyModuleILoader --cfg_file /somePath/configFile.cfg --group myPI --project myProject --skip assay123456,assay123457 --commit


=head1 REPORT BUGS TO

 svdate (AT) pcbi (dot) upenn (dot) edu
 OR
 rad3 (AT) pcbi (dot) upenn (dot) edu

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

  return $documentation;
}

###############################

sub getArgumentsDeclaration {

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

  return $argsDeclaration;
}

###############################

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self, $class);

  my $documentation       = &getDocumentation();
  my $argsDeclaration = &getArgumentsDeclaration();

  $self->initialize({
    requiredDbVersion => 3.5,
    cvsRevision       => '$Revision$',
    name              => ref($self),
    revisionNotes     => '',
    argsDeclaration   => $argsDeclaration,
    documentation     => $documentation
  });

  return $self;
}

###############################

# properties with '0' values can be declared as 'null'
# in the config file. properties with value '1' require
# a description other than 'null' in the config file.

my $requiredProperties = {
  "MaxObjectNumber"              => 0,
  "DataRepositoryPath"           => 1,
  "ImageRepositoryPath"          => 1,
  "EXPFilePath"                  => 1,
  "RPTFilePath"                  => 1,
  "CELFilePath"                  => 1,
  "DATFilePath"                  => 0,
  "MetricsFilePath"              => 1,
  "HybProtocolID"                => 1,
  "AcqProtocolID"                => 1,
  "CelProtocolID"                => 1,
  "ChpProtocolID"                => 1,
  "HybOperatorID"                => 1,
  "CelQuantOperatorID"           => 1,
  "ChpQuantOperatorID"           => 1,
  "StudyID"                      => 1,
  "ChannelDef"                   => 1,
  "Extensions"                   => 1,
  "FileTypes"                    => 1,
  "PrependToFluidicsKeyword"     => 0,
  "AppendToFluidicsKeyword"      => 0,
  "JoinFluidicsKeywordsWithSign" => 0,
  "PixelSizeRepresentation"      => 1,
  "FilterRepresentation"         => 1,
  "NumberOfScansRepresentation"  => 1,
  "TGTValueRepresentation"       => 1,
  "SFValueRepresentation"        => 1,
  "Alpha1Representation"         => 1,
  "Alpha2Representation"         => 1,
  "TauRepresentation"            => 1
}; 

###############################

sub run {
  my $self = shift;
    
  $self->logAlgInvocationId();
  $self->logCommit();
  $self->logArgs();

  my @properties = $self->createPropertiesArray($requiredProperties);
  $self->{propertySet} = CBIL::Util::PropertySet->new($self->getArg('cfg_file'), \@properties);
  $self->checkPropertiesInConfigFile($requiredProperties);

  $self->getDb()->setMaximumNumberOfObjects($self->{propertySet}->getProp("MaxObjectNumber")) 
   if ($self->{propertySet}->getProp("MaxObjectNumber") ne "null");

  my ($insertedAssayCnt, $skippedAssayCnt, $totalAssayCnt) = $self->createAndSubmitGUSAssaysFromFiles();
  
  $self->setResultDescr(
   "Total assays: $totalAssayCnt; Assay/s inserted in DB: $insertedAssayCnt; Skipped assay/s: $skippedAssayCnt"
  );
}

###############################

sub createPropertiesArray {
  my ($self, $propertiesRef) = @_;

  my @properties;

  foreach my $property (keys %$propertiesRef) {
    push(@properties, ["$property", "", ""]);
  }

 return (@properties);
}

###############################

sub checkPropertiesInConfigFile {
  my ($self, $propertiesRef) = @_;

  $self->log("STATUS","CHECKING   Properties in config file");
  foreach my $property (keys %$propertiesRef) {
    my $status = $propertiesRef->{$property};
    my $valueInFile = $self->{propertySet}->getProp("$property");

    $self->error("Value not defined for keyword $property. Use 'null' if no value is to be defined!") 
     if (! defined $valueInFile);

    $self->error("Value for keyword $property cannot be 'null'. Please specify an appropriate value!") 
     if ($status eq 1 && $valueInFile eq "null");
  }

  $self->log("STATUS","OK   All properties defined appropriately");
}

###############################

sub createAndSubmitGUSAssaysFromFiles {
  my ($self) = @_;

  $self->log("STATUS","DETECTED NON-COMMIT MODE: Nothing will be inserted in the database (although the log messages might say so)!") unless ($self->getArg('commit'));
  $self->log("STATUS","DETECTED NON-COMMIT MODE: Will skip checking related tables") unless ($self->getArg('commit'));

  my $dataRepositoryPath  = $self->{propertySet}->getProp("DataRepositoryPath");
  my $imageRepositoryPath = $self->{propertySet}->getProp("ImageRepositoryPath");
  my $expFilePath         = $self->{propertySet}->getProp("EXPFilePath");
  my $extensionInfo       = $self->{propertySet}->getProp("Extensions");
  my $testNumber          = $self->getArg('testnumber');
  my @skipAssayList       = @{$self->getArg('skip')};

  $expFilePath           .= "/" if ($expFilePath !~ m/(.+)\/$/);
  $dataRepositoryPath    .= "/" if ($dataRepositoryPath !~ m/(.+)\/$/);
  $imageRepositoryPath   .= "/" if ($imageRepositoryPath !~ m/(.+)\/$/);

  my $extensionHashRef    = $self->getFileExtensions($extensionInfo);
  my $assayNames          = $self->findAssayNames($dataRepositoryPath, $expFilePath, $extensionHashRef);

  my $skipAssayCnt        = scalar @skipAssayList;
  my $totalAssayCnt       = scalar @$assayNames;
  my $assayCnt            = 0;
  my $insertedAssayCnt    = 0;

  my @gusAssays;

  $self->log("STATUS","Found $totalAssayCnt assays");
  $self->log("STATUS","Skipping assay/s as defined: @skipAssayList") if (scalar @skipAssayList > 0);

  foreach my $assayName (@$assayNames) {

    next if (($assayCnt > ($testNumber - 1)) && (defined $testNumber));
    next if (grep { $assayName =~ /^$_/ } @skipAssayList);

    my $gusAssay       = $self->createSingleGUSAssay(
                          $dataRepositoryPath, $imageRepositoryPath, $assayName, $extensionHashRef);

    $insertedAssayCnt += $self->submitSingleGUSAssay($gusAssay);
    $assayCnt++;
	$self->undefPointerCache();  # clean memory
  }

  $self->log("STATUS","-------- End Assay Descriptions --------");
  $self->log("STATUS","Created $assayCnt assay/s");

  return ($insertedAssayCnt, $skipAssayCnt, $totalAssayCnt);
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
  my ($self, $dataRepositoryPath, $expFilePath, $extensionHashRef) = @_;

  my (@assayNames, @assayDir);
  my $requiredExtension = $extensionHashRef->{"EXPFile"}; # EXP filenames correspond to assay names
  my $assayNameFilesDir = $dataRepositoryPath.$expFilePath;

  opendir (DIR, $assayNameFilesDir) || $self->userError("Cannot open dir $assayNameFilesDir");
  @assayDir = readdir DIR; 
  close (DIR);

  $self->userError("Cannot create assays, directory  is empty!") 
    if (scalar @assayDir eq 0); 

  foreach my $file (@assayDir) { 

    next if ($file eq '.' || $file eq '..');              # skip '.' and '..' files

    my ($fileName, $extension) = $file =~ /(.+)\.(\w+)/;
    next unless ($extension);                             # skip files with no extension
    next if ($extension ne $requiredExtension);           # skip files with a different extension

    push (@assayNames, $1);
  }
 
  return \@assayNames;
}

###############################

sub createSingleGUSAssay {
  my ($self, $dataRepositoryPath, $imageRepositoryPath, $assayName, $extensionHashRef) = @_;
  
  $self->log("STATUS","----- Assay $assayName -----");

  $self->checkRequiredFilesExist($dataRepositoryPath, $imageRepositoryPath, $assayName, $extensionHashRef);

  my ($EXPinfo, $EXPfluidicsInfo) = $self->parseTabFile($dataRepositoryPath, $extensionHashRef->{"EXPFile"}, $assayName);
  my ($RPTinfo, $RPTfluidicsInfo) = $self->parseTabFile($dataRepositoryPath, $extensionHashRef->{"RPTFile"}, $assayName);
  
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
  my ($self, $dataRepositoryPath, $imageRepositoryPath, $assayName, $extensionHashRef) = @_;


  $self->log("STATUS","CHECKING   For non-exsistant and empty files: assay $assayName");

  my @fileTypes = split /\;/, $self->{propertySet}->getProp("FileTypes");

  foreach my $fileType (@fileTypes) {

    next if (( $fileType eq "DAT" ) && ($self->{propertySet}->getProp($fileType."FilePath") eq "null"));

    my $filePath;
    $filePath = $dataRepositoryPath.$self->{propertySet}->getProp($fileType."FilePath") if $fileType ne "DAT";
    $filePath = $imageRepositoryPath.$self->{propertySet}->getProp($fileType."FilePath") if $fileType eq "DAT";
	$filePath .= "/" if ($filePath !~ m/(.+)\/$/);

	my $file = "$assayName.".$extensionHashRef->{$fileType."File"};

    # check this for hard coding
	$file = "$assayName"."_Metrics.".$extensionHashRef->{$fileType."File"} if ($fileType eq "Metrics");

    $self->userError("Missing file: $file") if ( ! -e $filePath.$file ); 
    $self->userError("Empty file: $file") if ( -z $filePath.$file ); 
  }

  $self->log("STATUS","OK   All required files exist for assay $assayName, and none are empty");
}

###############################

sub parseTabFile {
  my ($self, $dataRepositoryPath, $prefix, $assayName) = @_;

  my ($info, $fluidicsInfo, $flag);

  my $filePath = $self->{propertySet}->getProp("${prefix}FilePath");
  $filePath .= "/" if ($filePath !~ m/(.+)\/$/);

  my $file = $dataRepositoryPath.$filePath.$assayName.".$prefix";
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
  my $hybProtocolId = $self->{propertySet}->getProp("HybProtocolID");
  my $hybOperatorId = $self->{propertySet}->getProp("HybOperatorID");

  $self->checkDatabaseEntry("GUS::Model::RAD::Protocol", "protocol_id", $hybProtocolId);
  $self->checkDatabaseEntry("GUS::Model::SRes::Contact", "contact_id", $hybOperatorId);
  
  my $arrayIdParams;

  if ($arrayName =~ /^(\S+)(v\d)$/) {  # eg: MG_U74Av2, where version may/may-not be included
    $arrayIdParams = GUS::Model::RAD::ArrayDesign->new({
      name    => "Affymetrix $1",
      version => $2
    });

  } else {
    $arrayIdParams = GUS::Model::RAD::ArrayDesign->new({
      name    => "Affymetrix $arrayName",
      version => "null"
    });
  }

  $self->error("Create object failed, array name $arrayName absent in table RAD::ArrayDesign") 
    unless ($arrayIdParams->retrieveFromDB);
  my $arrayDesignId = $arrayIdParams->getArrayDesignId();

  my $params = {
    array_design_id        => $arrayDesignId, 
    protocol_id            => $hybProtocolId, 
    operator_id            => $hybOperatorId, 
    name                   => $assayName,
    array_batch_identifier => $batchId, 
    description            => $description
  };
  
  $params->{assay_date} = $self->modifyDate($hybDate) if ($hybDate);

  my $assay = GUS::Model::RAD::Assay->new($params);

  $self->log("STATUS","Inserted 1 row in table RAD.Assay");

  return $assay;
}

###############################

sub checkDatabaseEntry {
  my ($self, $tableName, $paramName, $valueToCheck) = @_;

  my $checkerObject = $tableName->new({"$paramName" => $valueToCheck});

  $self->error("Create object failed :(\n Table: $tableName\n parameter: $paramName\n value: $valueToCheck\n
Check if the parameter and its value exist in the table")
   unless ($checkerObject->retrieveFromDB);
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

    $finalTime = ($hourMinArray[0] + 12).":$hourMinArray[1]:00" if ($hourMinArray[0] <= 11);
    $finalTime = $hourMinArray[0].":$hourMinArray[1]:00" if ($hourMinArray[0] > 11);
  }

  $finalTime = "$tempTime:00" if ($time2.$time1 eq "AM");

  my $monthNum = $monthHash{$dateArray[0]};
  my $finalDateTime = "$dateArray[2]-$monthNum-$dateArray[1]". " $finalTime";

  return $finalDateTime;
}

###############################

sub createGusAssayParams {
  my ($self, $EXPinfo, $EXPfluidicsInfo) = @_;

  my @gusAssayParams;
  my $fluidicsKeywordCnt = 0;

  my $hybProtocolId = $self->{propertySet}->getProp("HybProtocolID");

  foreach my $keyword (keys %$EXPfluidicsInfo) {

    my $key;

    my $prependFluidicsKeyword = $self->{propertySet}->getProp("PrependToFluidicsKeyword");
    my $appendFluidicsKeyword  = $self->{propertySet}->getProp("AppendToFluidicsKeyword");
    my $joinFluidicsKeyword    = $self->{propertySet}->getProp("JoinFluidicsKeywordsWithSign");

    $key = $prependFluidicsKeyword.$joinFluidicsKeyword.$keyword 
	 if $prependFluidicsKeyword ne "null" && $joinFluidicsKeyword ne "null";
    $key = $keyword.$joinFluidicsKeyword.$appendFluidicsKeyword 
	 if $appendFluidicsKeyword ne "null" && $joinFluidicsKeyword ne "null";

    my $value = $EXPfluidicsInfo->{$keyword};
      
    next unless ($value =~ /\S+/); # skip if no value 

    my $protocolParam = GUS::Model::RAD::ProtocolParam->new ({
        protocol_id => $hybProtocolId, 
        name        => $key
    });
 
    $self->error("Create object failed, protocol ID $hybProtocolId or name $key absent in table RAD::ProtocolParam") 
        unless ($protocolParam->retrieveFromDB);
    my $protocolParamId = $protocolParam->getProtocolParamId();

    my $assayParam = GUS::Model::RAD::AssayParam->new({
        protocol_param_id => $protocolParamId, 
        value             => $value
    }); 
    $fluidicsKeywordCnt++;
    push (@gusAssayParams, $assayParam);
  }

  $self->log("STATUS","Inserted $fluidicsKeywordCnt rows in table RAD.AssayParam");

  return \@gusAssayParams;
}

###############################

sub createGusAcquisition {
  my ($self, $assayName, $EXPinfo, $extensionHashRef) = @_;

  my $acqProtocolId = $self->{propertySet}->getProp("AcqProtocolID");
  my $scanDate      = $EXPinfo->{"Scan Date"};
  my $channelDef    = $self->{propertySet}->getProp("ChannelDef");

  my $datURI;
  if ($self->{propertySet}->getProp("DATFilePath") eq "null") {
    $datURI = "";

  } else {

    $datURI = $self->{propertySet}->getProp("DATFilePath");
    $datURI .= "/" if ($datURI !~ m/(.+)\/$/);
    $datURI .= $assayName.".".$extensionHashRef->{"DATFile"};
  }

  my $protocolId = GUS::Model::RAD::Protocol->new({protocol_id => $acqProtocolId});
  $self->error("Create object failed, protocol ID $acqProtocolId absent in table RAD::Protocol") 
    unless ($protocolId->retrieveFromDB);
  my $protocolName = $protocolId->getName();
  my $acqName = "$assayName-$channelDef-".$protocolName;

 ## note to myself
  my $ontologyEntryIdObject = GUS::Model::Study::OntologyEntry->new({ value => $channelDef, category => 'LabelCompound'});
  $self->error("Create object failed, parameter name $channelDef absent in table Study.OntologyEntry") 
    unless ($ontologyEntryIdObject->retrieveFromDB);
  my $ontologyEntryId = $ontologyEntryIdObject->getOntologyEntryId();

  my $acqParameters = { 
    name        => $acqName, 
    protocol_id => $acqProtocolId, 
    channel_id  => $ontologyEntryId,
    uri         => $datURI
  };
    
  $acqParameters->{acquisition_date} = $self->modifyDate($scanDate) if ($scanDate);

  my $acquisition = GUS::Model::RAD::Acquisition->new($acqParameters);

  $self->log("STATUS","Inserted 1 row in table RAD.Acquisition");

  return $acquisition;
}

###############################

sub createGusAcquisitionParams {
  my ($self, $EXPinfo) = @_;

  my $acqProtocolId               = $self->{propertySet}->getProp("AcqProtocolID");
  my $pixelSizeRepresentation     = $self->{propertySet}->getProp("PixelSizeRepresentation");
  my $filterRepresentation        = $self->{propertySet}->getProp("FilterRepresentation");
  my $numberOfScansRepresentation = $self->{propertySet}->getProp("NumberOfScansRepresentation");

  my %params = (
    $pixelSizeRepresentation     =>1,
    $filterRepresentation        =>1,
    $numberOfScansRepresentation =>1
  );

  my @gusAcquisitionParams;
  my $acqParamKeywordCnt = 0;

  foreach my $param (keys %params) {

    my $protocolParam = GUS::Model::RAD::ProtocolParam->new({
      protocol_id => $acqProtocolId, 
      name        => "$param"
    });

    $self->error("Create object failed, parameter $param absent in table RAD::ProtocolParam") 
     unless ($protocolParam->retrieveFromDB);
    my $acquisitionParamId = $protocolParam->getProtocolParamId();

    my $acquisitionParam = GUS::Model::RAD::AcquisitionParam->new({
      protocol_param_id => $acquisitionParamId, 
      name              => $param, 
      value             => $EXPinfo->{$param} 
    });

    $acqParamKeywordCnt++;
    push (@gusAcquisitionParams, $acquisitionParam);
  }

  $self->log("STATUS","Inserted $acqParamKeywordCnt rows in table RAD.AcquisitionParam");

  return \@gusAcquisitionParams;
}

###############################

sub createGUSQuantification {
  my ($self, $assayName, $RPTinfo, $extensionHashRef) = @_;

  my $celURI         = $self->{propertySet}->getProp("CELFilePath");
  my $chpURI         = $self->{propertySet}->getProp("MetricsFilePath");
  my $acqProtocolId      = $self->{propertySet}->getProp("AcqProtocolID");
  my $celProtocolId      = $self->{propertySet}->getProp("CelProtocolID");
  my $chpProtocolId      = $self->{propertySet}->getProp("ChpProtocolID");
  my $celQuantOperatorId = $self->{propertySet}->getProp("CelQuantOperatorID");
  my $chpQuantOperatorId = $self->{propertySet}->getProp("ChpQuantOperatorID");


  $self->checkDatabaseEntry("GUS::Model::RAD::Protocol", "protocol_id", $celProtocolId);
  $self->checkDatabaseEntry("GUS::Model::RAD::Protocol", "protocol_id", $chpProtocolId);
  $self->checkDatabaseEntry("GUS::Model::SRes::Contact", "contact_id", $celQuantOperatorId);
  $self->checkDatabaseEntry("GUS::Model::SRes::Contact", "contact_id", $chpQuantOperatorId);

  $celURI .= "/" if ($celURI !~ m/(.+)\/$/);
  $chpURI .= "/" if ($chpURI !~ m/(.+)\/$/);

  $celURI .= $assayName.".".$extensionHashRef->{"CELFile"};
  $chpURI .= $assayName."_Metrics.".$extensionHashRef->{"MetricsFile"};

  # modify quantification date, which is not in regular format
  my ($quantificationDate, $tempQuantificationDate);
  foreach my $key (keys %$RPTinfo) {
    $tempQuantificationDate = $RPTinfo->{$key} if ($key =~ m/Date/);
  }
  my ($tempTime, $tempDate) = split " ", $tempQuantificationDate;
  $quantificationDate = $self->getQuantificationDate($tempTime, $tempDate);

  my $protocol = GUS::Model::RAD::Protocol->new({protocol_id => $acqProtocolId});
  $self->error("Create object failed, $acqProtocolId absent in table RAD::Protocol") 
    unless ($protocol->retrieveFromDB);

  my $tempAcqName = $protocol->getName();
  my $acqName = $assayName."-Biotin-".$tempAcqName;

  my $celQuantParameters = {
    protocol_id => $celProtocolId, 
    name        => $acqName."-Affymetrix Probe Cell Analysis", 
    uri         => $celURI
  }; 
  $celQuantParameters->{operator_id} = $celQuantOperatorId if ( defined $celQuantOperatorId );
  my $celQuantification = GUS::Model::RAD::Quantification->new($celQuantParameters);

  my $chpQuantParameters = {
    protocol_id         => $chpProtocolId,
    name                => $acqName."-Affymetrix MAS5 Absolute Expression Analysis", 
    uri                 => $chpURI,
    quantification_date => $quantificationDate
  };
  $chpQuantParameters->{operator_id} = $chpQuantOperatorId if ( defined $chpQuantOperatorId );
  my $chpQuantification = GUS::Model::RAD::Quantification->new($chpQuantParameters);

  my @gusQuantifications;
  push (@gusQuantifications, $celQuantification, $chpQuantification);

  $self->log("STATUS","Inserted 2 rows in table RAD.Quantification for CEL & CHP quantification");

  return \@gusQuantifications;
}
###############################

sub getQuantificationDate {
  my ($self, $tempTime, $tempDate) = @_;

  # this sub deals with quantification date only, since the quantification 
  # date is in a different format than other dates in EXP files
  # eg: 09:57PM 06/21/2004

  my $time1 = chop $tempTime;       #get AM/PM
  my $time2 = chop $tempTime;       #get AM/PM

  my @hourMinArray = split /\:/,$tempTime;

  my $finalTime;

  if ($time2.$time1 eq "PM") {

    $finalTime = ($hourMinArray[0] + 12).":$hourMinArray[1]:00" if ($hourMinArray[0] <= 11);
    $finalTime = $hourMinArray[0].":$hourMinArray[1]:00" if ($hourMinArray[0] > 11);
  } 

  $finalTime = "$tempTime:00" if ($time2.$time1 eq "AM");

  my @dateArray = split /\//, $tempDate;
  my $finalDate = "$dateArray[2]-$dateArray[0]-$dateArray[1]";

  my $finalDateTime = "$finalDate $finalTime";

  return $finalDateTime;
}


###############################

sub createGUSQuantParams {
  my ($self, $RPTinfo) = @_;

  my $chpProtocolId = $self->{propertySet}->getProp("ChpProtocolID");
  $self->checkDatabaseEntry("GUS::Model::RAD::Protocol", "protocol_id", $chpProtocolId);

  my $params = {
    $self->{propertySet}->getProp("Alpha1Representation")   => 1,
    $self->{propertySet}->getProp("Alpha2Representation")   => 1,
    $self->{propertySet}->getProp("TauRepresentation")      => 1,
    $self->{propertySet}->getProp("TGTValueRepresentation") => 1,
    $self->{propertySet}->getProp("SFValueRepresentation")  => 1
  };

  my @gusQuantParams;
  my $quantParamKeywordCnt = 0;

  foreach my $param (keys %$params) {

    my $protocolParam = GUS::Model::RAD::ProtocolParam->new({
      protocol_id => $chpProtocolId, 
      name        => $param
    });

    $self->error("Create object failed, name $param absent in table RAD::ProtocolParam")
      unless ($protocolParam->retrieveFromDB);

    my $paramValue;

    # standard keywords as seen in .RPT files can be modified and stored in RAD
	# HARD-CODED based on observed keywords in files
    $paramValue = $RPTinfo->{"Alpha1:"}            if ($param eq $self->{propertySet}->getProp("Alpha1Representation"));
    $paramValue = $RPTinfo->{"Alpha2:"}            if ($param eq $self->{propertySet}->getProp("Alpha2Representation"));
    $paramValue = $RPTinfo->{"Tau:"}               if ($param eq $self->{propertySet}->getProp("TauRepresentation"));
    $paramValue = $RPTinfo->{"TGT Value:"}         if ($param eq $self->{propertySet}->getProp("TGTValueRepresentation"));
    $paramValue = $RPTinfo->{"Scale Factor (SF):"} if ($param eq $self->{propertySet}->getProp("SFValueRepresentation"));

    my $quantParameters = GUS::Model::RAD::QuantificationParam->new({
      name  => $param,
      value => $paramValue
    });
    
    $quantParameters->setParent($protocolParam);  # protocolParam in only needed here, so set parent here

    $quantParamKeywordCnt++;
    push(@gusQuantParams,$quantParameters);
  }

  $self->log("STATUS","Inserted $quantParamKeywordCnt rows in table RAD.QuantificationParam");

  return \@gusQuantParams;
}

###############################

sub submitSingleGUSAssay {
  my ($self, $gusAssay) = @_;

  my $studyId = $self->{propertySet}->getProp("StudyID");

  my $gusStudy = GUS::Model::Study::Study->new({study_id => $studyId});
  unless ($gusStudy->retrieveFromDB) { 
    $self->error("Failed to create an object for study $studyId from RAD.Study"); 
  }

  my $insertedAssayCnt = 0;

  my $studyAssay = GUS::Model::RAD::StudyAssay->new(); # links RAD.Study & RAD.Assay

  $studyAssay->setParent($gusAssay);
  $studyAssay->setParent($gusStudy);
 
  if ($self->getArg('commit')) {
    $gusAssay->submit();
    $insertedAssayCnt = 1;
  }

  return $insertedAssayCnt;
}

############################### END
