##
## InsertGcRMAAssay2Quantification Plugin
## $Id: InsertGcRMAAssay2Quantification.pm 3208 2005-08-03 15:15:19Z svdate $
##

package GUS::Community::Plugin::InsertGcRMAAssay2Quantification;
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
  my $purpose      = "Create assays, acquisitions and quantifications for Affymetrix assays in RAD tables from multiple files in batch mode.  Data has been quantified with gcRMA (Bioconductor)";
  
  my $tablesAffected = [
    ['RAD::Assay',               'Enters as many rows as distinct assays found'],
    ['RAD::AssayParam',          'For each assay entered, enters here the values of the Fluidics protocol parameters as recorded in the corresponding .EXP file'],
    ['RAD::Quantification',      'Enters here two quantifications, cel and gcRMA, for each assay entered'],
    ['RAD::QuantificationParam', 'For each assay entered, enters here the values for parameters recorded in the corresponding .RPT file'],
    ['RAD::Acquisition',         'Enters here one acquisition for each assay entered'],
    ['RAD::AcquisitionParam',    'For each assay entered, enters here the values for parameters recorded in the corresponding .EXP file'],
    ['RAD::StudyAssay',          'Row linking the given study to an assay is entered']
   ];

  my $tablesDependedOn = [
    ['Study::Study',              'The particular study to which the assay belongs'],
    ['RAD::ArrayDesign',          'Holds array information'], 
    ['RAD::Protocol',             'The hybridization, image_acquisition, and feature_extraction protocols used'], 
    ['RAD::ProtocolParam',        'Parameters for the protocol used'], 
    ['RAD::Contact',              'Information on researchers who performed the hybridization and the image analysis']
  ];

  my $howToRestart = "Cannot be restarted."; 
  
  my $failureCases = "Files not in an appropriate format.";

  my $notes = <<NOTES;

=pod

=head1 DESCRIPTION

This plugin loads information about multiple assays into the database, in a batch mode.
A config file containing information such as location of the EXP files is required by
the plugin.

The plugin does contain some 'hard-coded' information, which is based on policies adopted
by CBIL, and will be entered as such into RAD tables. This is mostly done to avoid handling
the exponential number of combinations possible if differences are allowed. If you want to 
change such hard-coded information, you will have to edit some of the plugin code. 

Hierarchy of subroutines is as follows (should give you some idea of what the plugin does
without looking into the code):

 #+ getDocumentation {
 #+ getArgumentsDeclaration {
 #+ new {
 #+ run {
 #++ createPropertiesArray {
 #++ checkPropertiesInConfigFile {
 #++ createAndSubmitGUSAssaysFromFiles {
 #++++ getFileExtensions {
 #++++ findAssayNames {
 #++++ createSingleGUSAssay {
 #++++++ checkRequiredFilesExist {
 #++++++ parseTabFile {
 #++++++ createGusAssay {
 #++++++++ checkDatabaseEntry {
 #++++++++ modifyDate {
 #++++++ createGusAssayParams {
 #++++++ createGusAcquisition {
 #++++++ createGusAcquisitionParams {
 #++++++ createGUSQuantification {
 #++++++ getQuantificationDate {
 #++++++ createGUSQuantParams {
 #++++ submitSingleGUSAssay {



=head2 F<Config File (is mandatory)>

A config file is need for the plugin to run. Blank lines and comments (lines starting with
'#') are ignored. The sample config file contains instructions and information about the
keywords and their required values, and is maintained in:
 \$PROJECT_HOME/GUS/Community/config/sample_InsertGcRMAAssay2Quantification.cfg

All keywords are required. If no value is to be entered, please use the word 'null'
(without the quotes) instead. The following keywords are used by the plugin (a value
of 1 indicates that the keyword can never have a null value):


MaxObjectNumber               => 0, 
DataRepositoryPath            => 1,
ImageRepositoryPath           => 0,
EXPFilePath                   => 1,
RPTFilePath                   => 0,
CELFilePath                   => 0,
DATFilePath                   => 0,
gcRMAFilePath                 => 1,
HybProtocolID                 => 1,
AcqProtocolID                 => 1,
CelProtocolID                 => 1,
gcRMAProtocolID               => 1,
gcRMAQuantDate                => 1,
HybOperatorID                 => 1,
CelQuantOperatorID            => 1,
gcRMAQuantOperatorID          => 1,
StudyID                       => 1,
ChannelDef                    => 1,
Extensions                    => 1,
FileTypes                     => 1,
PrependToFluidicsKeyword      => 0,
AppendToFluidicsKeyword       => 0,
JoinFluidicsKeywordsWithSign  => 0,
PixelSizeRepresentation       => 1,
FilterRepresentation          => 1,
NumberOfScansRepresentation   => 1,
BGVersionRepresentation       => 1,
NormalizeRepresentation       => 1,
FastRepresentation            => 1,
gcRMAVersionRepresentation    => 1,
KRepresentation               => 0,
RVersionRepresentation        => 1,
OpticalCorrectRepresentation  => 1,
RhoRepresentation             => 1,
TypeRepresentation            => 1



=head2 F<Database requirements>

This plugin assumes that the following entries exist in your instance of the database:

 1.  The study in Study.Study
 2.  The appropriate Affymetrix array in RAD.Array
 3.  The hybridization protocol, the acquisition protocol, the 
     quantification protocol in RAD.Protocol
 4.  For each of the protocol entries in 3, all of its parameters 
     in RAD.ProtocolParam

If any of the above is missing, the plugin will report an error.


=head1 EXAMPLES

ga GUS::Community::Plugin::InsertGcRMAAssay2Quantification 
 --cfg_file ~/test/testStudy/InsertGcRMAAssay2Quantification.cfg 
 --testnumber 1 
 --group myPI_InRAD
 --project 'myProjectInRAD'


ga GUS::Community::Plugin::InsertGcRMAAssay2Quantification 
 --cfg_file ~/test/testStudy/InsertGcRMAAssay2Quantification.cfg 
 --skip assay12345, assay45678
 --testnumber 5 
 --group myPI_InRAD
 --project 'myProjectInRAD'
 --commit

ga GUS::Community::Plugin::InsertGcRMAAssay2Quantification 
 --cfg_file ~/test/testStudy/InsertGcRMAAssay2Quantification.cfg 
 --skip assay12345, assay45678
 --group myPI_InRAD
 --project 'myProjectInRAD'
 --commit


=head1 REPORT BUGS TO

https://www.cbil.upenn.edu/tracker/enter_bug.cgi?product=GUS%20Application%20Framework

(you will need an account to log in to the bug tracker)


=head1 AUTHORS

Shailesh Date, Hongxian He, Regina Gorski


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
    requiredDbVersion => 3.6,
    cvsRevision       => '$Revision: 4386 $',
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
  "ImageRepositoryPath"          => 0,
  "EXPFilePath"                  => 1,
  "RPTFilePath"                  => 0,
  "CELFilePath"                  => 0,
  "DATFilePath"                  => 0,
  "gcRMAFilePath"                => 1,
  "HybProtocolID"                => 1,
  "AcqProtocolID"                => 1,
  "CelProtocolID"                => 1,
  "gcRMAProtocolID"              => 1,
  "HybOperatorID"                => 1,
  "CelQuantOperatorID"           => 1,
  "gcRMAQuantOperatorID"         => 1,
  "gcRMAQuantDate"               => 1,
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
  "BGVersionRepresentation"      => 1,
  "NormalizeRepresentation"      => 1,
  "FastRepresentation"           => 1,
  "gcRMAVersionRepresentation"   => 1,
  "KRepresentation"              => 0,
  "RVersionRepresentation"       => 1,
  "OpticalCorrectRepresentation" => 1,
  "RhoRepresentation"            => 1,
  "TypeRepresentation"           => 1
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
  $self->log("STATUS","Found assays: @$assayNames");
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
  
  my $gusAssay               = $self->createGusAssay($assayName, $EXPinfo);
  my $gusAssayParams         = $self->createGusAssayParams($EXPinfo, $EXPfluidicsInfo);
  my $gusAcquisition         = $self->createGusAcquisition($assayName, $EXPinfo, $extensionHashRef);
  my $gusAcquistionParamsRef = $self->createGusAcquisitionParams($EXPinfo);
  my $gusQuantificationsRef  = $self->createGUSQuantification($assayName, $extensionHashRef);

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
    #my $gusQuantParamsRef = $self->createGUSQuantParams($RPTinfo);
    my $gusQuantParamsRef = $self->createGUSQuantParams();
    foreach my $gusQuantParam (@$gusQuantParamsRef) { 
        $gusQuantParam->setParent($gusQuantification); 
     }
  }


  return $gusAssay;
}

###############################

sub checkRequiredFilesExist {
  my ($self, $dataRepositoryPath, $imageRepositoryPath, $assayName, $extensionHashRef) = @_;


  $self->log("STATUS","CHECKING   For non-existent and empty files: assay $assayName");

  my @fileTypes = split /\;/, $self->{propertySet}->getProp("FileTypes");

  foreach my $fileType (@fileTypes) {

    next if (( $fileType eq "DAT" ) && ($self->{propertySet}->getProp($fileType."FilePath") eq "null"));
    next if (( $fileType eq "RPT" ) && ($self->{propertySet}->getProp($fileType."FilePath") eq "null"));

    my $filePath;
    $filePath = $dataRepositoryPath.$self->{propertySet}->getProp($fileType."FilePath") if $fileType ne "DAT";
    $filePath = $imageRepositoryPath.$self->{propertySet}->getProp($fileType."FilePath") if $fileType eq "DAT";
	$filePath .= "/" if ($filePath !~ m/(.+)\/$/);

	my $file = "$assayName.".$extensionHashRef->{$fileType."File"};

    # check this for hard coding
	#$file = "$assayName"."_Metrics.".$extensionHashRef->{$fileType."File"} if ($fileType eq "Metrics");
	$file = "$assayName.".$extensionHashRef->{$fileType."File"} if ($fileType eq "gcRMA");

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
      version => ""
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
  # or Hybridize Date  02/05/02  19:18
  my @dateArray = split " ", $inputDate;  

  my $arrayLen = scalar @dateArray;
  $self->error("Missing date, cannot continue") if ($arrayLen eq 0);

  my %monthHash = (
    Jan => '01', Feb => '02', Mar => '03', Apr => '04', May => '05', Jun => '06',
    Jul => '07', Aug => '08', Sep => '09', Oct => '10', Nov => '11', Dec => '12'
  );

  my $finalTime;
  my $tempTime = pop @dateArray;    #get time 

  if (($tempTime =~/am/i)||($tempTime=~/pm/i)){
    my $time1 = chop $tempTime;       #get AM/PM
    my $time2 = chop $tempTime;       #get AM/PM

    my @hourMinArray = split /\:/,$tempTime;


    if ($time2.$time1 eq "PM") {

      $finalTime = ($hourMinArray[0] + 12).":$hourMinArray[1]:00" if ($hourMinArray[0] <= 11);
      $finalTime = $hourMinArray[0].":$hourMinArray[1]:00" if ($hourMinArray[0] > 11);
    }

    $finalTime = "$tempTime:00" if ($time2.$time1 eq "AM");
  }else{
    $finalTime = "$tempTime:00";
  }


  #Date may be in number format or text
  my $finalDateTime;
  if ($dateArray[0] =~ /(\d+)\W+(\d+)\W+(\d+)/){
    my $year = $3;
    $year = "20".$3 if (length($3) < 4);
    $year = "200".$3  if(length($3) < 2);
    $finalDateTime = "$year-$1-$2". " $finalTime";
  }else{
    my $monthNum = $monthHash{$dateArray[0]};
    $finalDateTime = "$dateArray[2]-$monthNum-$dateArray[1]". " $finalTime";
  }
  $self->error("Cannot parse date, cannot continue") if ($finalDateTime=~/--/);

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
  my ($self, $assayName, $extensionHashRef) = @_;

  my $celURI         = $self->{propertySet}->getProp("CELFilePath");
  my $gcRMAURI         = $self->{propertySet}->getProp("gcRMAFilePath");
  my $acqProtocolId      = $self->{propertySet}->getProp("AcqProtocolID");
  my $celProtocolId      = $self->{propertySet}->getProp("CelProtocolID");
  my $gcRMAProtocolId      = $self->{propertySet}->getProp("gcRMAProtocolID");
  my $celQuantOperatorId = $self->{propertySet}->getProp("CelQuantOperatorID");
  my $gcRMAQuantOperatorId = $self->{propertySet}->getProp("gcRMAQuantOperatorID");
  my $quantificationDate = $self->{propertySet}->getProp("gcRMAQuantDate");

  $self->checkDatabaseEntry("GUS::Model::RAD::Protocol", "protocol_id", $celProtocolId);
  $self->checkDatabaseEntry("GUS::Model::RAD::Protocol", "protocol_id", $gcRMAProtocolId);
  $self->checkDatabaseEntry("GUS::Model::SRes::Contact", "contact_id", $celQuantOperatorId);
  $self->checkDatabaseEntry("GUS::Model::SRes::Contact", "contact_id", $gcRMAQuantOperatorId);

  $celURI .= "/" if ($celURI !~ m/(.+)\/$/);
  $gcRMAURI .= "/" if ($gcRMAURI !~ m/(.+)\/$/);

  $celURI .= $assayName.".".$extensionHashRef->{"CELFile"};
  $gcRMAURI .= $assayName.".".$extensionHashRef->{"gcRMAFile"};

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

  my $gcRMAQuantParameters = {
    protocol_id         => $gcRMAProtocolId,
    name                => $acqName."-Affymetrix GcRMA Absolute Expression Analysis", 
    uri                 => $gcRMAURI,
    quantification_date => $quantificationDate
  };
  $gcRMAQuantParameters->{operator_id} = $gcRMAQuantOperatorId if ( defined $gcRMAQuantOperatorId );
  my $gcRMAQuantification = GUS::Model::RAD::Quantification->new($gcRMAQuantParameters);

  my @gusQuantifications;
  push (@gusQuantifications, $celQuantification, $gcRMAQuantification);

  $self->log("STATUS","Inserted 2 rows in table RAD.Quantification for CEL & gcRMA quantification");

  return \@gusQuantifications;
}
###############################

sub createGUSQuantParams {
  my ($self) = @_;

  my $gcRMAProtocolId = $self->{propertySet}->getProp("gcRMAProtocolID");
  $self->checkDatabaseEntry("GUS::Model::RAD::Protocol", "protocol_id", $gcRMAProtocolId);

  my $params = {
    'normalize'       => $self->{propertySet}->getProp("NormalizeRepresentation"),
    'bgversion'       => $self->{propertySet}->getProp("BGVersionRepresentation"),
    'fast'            => $self->{propertySet}->getProp("FastRepresentation") ,
    'gcrma version'   => $self->{propertySet}->getProp("gcRMAVersionRepresentation") ,
    'R version'       => $self->{propertySet}->getProp("RVersionRepresentation"),
    'optical.correct' => $self->{propertySet}->getProp("OpticalCorrectRepresentation"),
    'rho'             => $self->{propertySet}->getProp("RhoRepresentation") ,
    'type'            => $self->{propertySet}->getProp("TypeRepresentation")
  };

  $params->{k} = $self->{propertySet}->getProp("KRepresentation") if ($self->{propertySet}->getProp("KRepresentation") ne "null");

  my @gusQuantParams;
  my $quantParamKeywordCnt = 0;

  foreach my $param (keys %$params) {

    my $protocolParam = GUS::Model::RAD::ProtocolParam->new({
      protocol_id => $gcRMAProtocolId, 
      name        => $param
    });

    $self->error("Create object failed, name $param absent in table RAD::ProtocolParam")
      unless ($protocolParam->retrieveFromDB);

    my $paramValue = $params->{$param};


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

###############################

sub undoTables {
  my ($self) = @_;

return ('RAD.QuantificationParam','RAD.Quantification','RAD.AcquisitionParam','RAD.Acquisition','RAD.StudyAssay','RAD.AssayParam','RAD.Assay');

}

############################### END
