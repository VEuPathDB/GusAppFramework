##
## InsertGenePixAssay2Quantification Plugin
## $Id$
##

package GUS::Community::Plugin::InsertGenePixAssay2Quantification;
@ISA = qw( GUS::PluginMgr::Plugin);

use strict 'vars';

# CBIL specific packages
use CBIL::Util::Disp;
use CBIL::Util::PropertySet;

# GUS specific packages
use GUS::PluginMgr::Plugin;
use GUS::Model::Study::Study;
use GUS::Model::RAD::Assay;
use GUS::Model::RAD::StudyAssay;
use GUS::Model::RAD::Acquisition; 
use GUS::Model::RAD::RelatedAcquisition;
use GUS::Model::RAD::Quantification;
use GUS::Model::RAD::QuantificationParam;
use GUS::Model::RAD::RelatedQuantification;
use GUS::Model::RAD::ArrayDesign;
use GUS::Model::RAD::Protocol;
use GUS::Model::RAD::ProtocolParam;
use GUS::Model::Study::OntologyEntry;
use GUS::Model::SRes::Contact;

###############################

sub getDocumentation {

  my $purposeBrief = "Creates assays, acquisitions and quantifications for GenePix assays en-batch.";

  my $purpose      = "Create assays, acquisitions and quantifications for GenePix assays in RAD tables from multiple files in batch mode.";
 
  my $tablesAffected = [
    ['Study::Study',               'One row for the given study is entered'],
    ['RAD::Assay',                 'One row for each distinct assay is entered'],
    ['RAD::StudyAssay',            'One row linking the given study to each assay is entered'],
    ['RAD::Acquisition',           'For each assay, two rows (2 acquisitions) are entered, one for each channel'],
    ['RAD::Quantification',        'For each assay, two rows (2 quantifications) are entered, one for each channel'],
    ['RAD::QuantificationParam',   'Eight rows, four for each channel (Cy5 and Cy3), corresponding to four parameters per quantification, are entered'],
    ['RAD::RelatedAcquisition',    'Two rows are entered for each assay, relating the two corresponding acquisitions'],
    ['RAD::RelatedQuantification', 'Two rows are entered for each assay, relating the two corresponding quantifications']
  ];

  my $tablesDependedOn = [
    ['Study::Study',               'Holds study information'],
    ['RAD::ArrayDesign',           'Holds array information'], 
    ['Study::OntologyEntry',         'Holds channel (Cy5 or Cy3 in this case) information'], 
    ['RAD::Protocol',              'Holds hybridization, image acquisition and feature extraction protocol information'], 
    ['RAD::ProtocolParam',         'Holds protocol parameter information'], 
    ['SRes::Contact',              'Holds personnel contact information']
  ];

  my $howToRestart = "Cannot be restarted."; 

  my $failureCases = "Files not in an appropriate format.";

  my $notes = <<NOTES;

=pod

=head1 DESCRIPTION

This plugin loads information about multiple assays into the database, in a batch mode.  
A config file containing information such as location of the GPR files is required by the 
plugin.

The plugin does contain some ’hard-coded’ information, which is basedased on policies 
adopted by CBIL, and will be entered as such into RAD tables. This is mostly done to avoid 
handling the exponential number of combinations possible if differences are allowed. If you 
want to change such hard-coded information, you will have to edit some of the plugin code.

Since assay, acquisition and most quantification parameters are not readily available through the '.gpr' files,
they cannot be added to the database through this plugin. They have to be added to the tables separately, 
either directly or through the following forms in the RAD StudyAnnotator: Hybridization Parameters, Acquisition
Parameters and Quantification Parameters.

The plugin also assumes the following parameters to be the same for all assays: Array ID, Batch ID, 
Hybridization Protocol ID, Hybridization Operator ID, Acquisition Protocol ID, Quantification Protocol 
ID and Quantification Operator ID.

Hierarchy of subroutines is as follows (should give you some idea of what the plugin does without 
looking into the code):

 #+ getDocumentation {
 #+ getArgumentsDeclaration {
 #+ new {
 #+ run {
 #++ createPropertiesArray {
 #++ checkPropertiesInConfigFile {
 #++ createAndSubmitGUSAssaysFromFiles {
 #++++ findAssayNames {
 #++++ getImageFileNames {
 #++++ parseMultipleDescriptions {
 #++++ createSingleGUSAssay {
 #++++++ checkRequiredFilesExist {
 #++++++ parseTabFile {
 #++++++ modifyKeyValuePairs {
 #++++++ createGusAssay {
 #++++++++ checkDatabaseEntry {
 #++++++ createGusAcquisition {
 #++++++ createGusQuantification {
 #++++++ createGusQuantParams {
 #++++ submitSingleGusAssay {
 #++ populateRelatedTables {
 #++++ populateRelatedAcquisition {
 #++++ populateRelatedQuantification {




=head2 F<Config File (is mandatory)>

A config file is need for the plugin to run. Blank lines and comments (lines starting with '#') are ignored. 
The sample config file contains instructions and information about the keywords and their required values, 
and is maintained in:
\$PROJECT_HOME/GUS/Community/config/sample_InsertGenePixAssay2Quantification.cfg

All keywords are required. If no value is to be entered, please use the word 'null' (without the quotes) 
instead. The following keywords are used by the plugin (a value of 1 indicates that the keyword can never
have a null value):

StudyID                      => 1,
ArrayID                      => 1,
BatchID                      => 0,
GPRFileExtension             => 1,
DataRepositoryPath           => 1,
ImageRepositoryPath          => 1,
GPRFilePath                  => 1,
TiffFilePath                 => 1,
CY5ChannelDef                => 1,
CY3ChannelDef                => 1,
Cy5Cy3FilesCombined          => 1,
CombinedFileExtension        => 1,
CY5FileExtension             => 1,
CY3FileExtension             => 1,
RatioFormulations            => 1,
StandardDeviation            => 1,
BackgroundDensityMeasure     => 1,
SoftwareVersion              => 1,
GenePixQuantification        => 1,
HybProtocolID                => 1,
AcqProtocolID                => 1,
HybOperatorID                => 1,
QuantOperatorID              => 0,
AllAssayDescriptionsSame     => 0,
AllAssayDescriptions         => 0,
IndividualAssayDescriptions  => 0,
AllHybDatesSame              => 1,
AllHybDates                  => 1,
IndividualHybDates           => 0,
AllScanDatesSame             => 1,
AllScanDates                 => 1,
IndividualScanDates          => 0


=head2 F<Database requirements>

This plugin assumes that the following entries exist in your instance of the database:

 1.  The study in RAD.Study
 2.  The appropriate GenePix array in RAD.Array
 3.  The hybridization protocol, the acquisition protocol, the quantification protocol in RAD.Protocol
 4.  Quantification parameters for quantification in RAD.ProtocolParam
 5.  Image files adhere to the following naming convention: name_label.ext (ex.test_Cy3.tif)

If any of the above is missing, the plugin will report an error.



=head1 EXAMPLES

ga GUS::Community::Plugin::InsertGenePixAssay2Quantification
 --cfg_file /somePath/InsertGenePixAssay2Quantification.cfg
 --testnumber 1 
 --group myPI 
 --project myProject

ga GUS::Community::Plugin::InsertGenePixAssay2Quantification
 --cfg_file /somePath/InsertGenePixAssay2Quantification.cfg
 --skip assay12345 assay45678
 --group myPI 
 --project myProject
 --commit

ga GUS::Community::Plugin::InsertGenePixAssay2Quantification
 --cfg_file /somePath/InsertGenePixAssay2Quantification.cfg
 --skip assay12345 assay45678
 --testnumber 5
 --group myPI 
 --project myProject
 --commit


=head1 REPORT BUGS TO

https://www.cbil.upenn.edu/tracker/enter_bug.cgi?product=GUS%20Application%20Framework

(you will need an account to log in to the bug tracker)



=head1 AUTHOR

Shailesh Date, Hongxian He

=head1 COPYRIGHT

Copyright, Trustees of University of Pennsylvania 2003. 

=cut
NOTES

  my $documentation = {
    purpose          => $purpose, 
    purposeBrief     => $purposeBrief,
    tablesAffected   => $tablesAffected,
    tablesDependedOn => $tablesDependedOn,
    howToRestart     => $howToRestart,
    failureCases     => $failureCases,
    notes            => $notes
  };

  return $documentation;
}

###############################

sub getArgumentsDeclaration {

  my $argsDeclaration = [
     
    fileArg({
       name           => 'cfg_file',
       descr          => 'Full path of the cfg file.',
       constraintFunc => undef,
       reqd           => 1,
       isList         => 0, 
       mustExist      => 1,
       format         => 'See NOTES'
    }),

     stringArg({
       name           => 'skip',
       descr          => 'List of files in specified directories that will be skipped for loading.',
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
  bless($self,$class);

  my $documentation       = &getDocumentation();
  my $argsDeclaration = &getArgumentsDeclaration();

  $self->initialize({
    requiredDbVersion => 3.6,
    cvsRevision       => '$Revision$',
    name              => ref($self),
    revisionNotes     => '',
    argsDeclaration   => $argsDeclaration,
    documentation     => $documentation
  });

  return $self;
}

###############################

my $requiredProperties = {
  "StudyID"                     => 1,
  "ArrayID"                     => 1,
  "BatchID"                     => 0,
  "GPRFileExtension"            => 1,
  "DataRepositoryPath"          => 1,
  "ImageRepositoryPath"         => 1,
  "GPRFilePath"                 => 1,
  "TiffFilePath"                => 1,
  "CY5ChannelDef"               => 1,
  "CY3ChannelDef"               => 1,
  "Cy5Cy3FilesCombined"         => 1,
  "CombinedFileExtension"       => 1,
  "CY5FileExtension"            => 1,
  "CY3FileExtension"            => 1,
  "RatioFormulations"           => 1,
  "StandardDeviation"           => 1,
  "BackgroundDensityMeasure"    => 1,
  "SoftwareVersion"             => 1,
  "GenePixQuantification"       => 1,
  "HybProtocolID"               => 1,
  "AcqProtocolID"               => 1,
  "HybOperatorID"               => 1,
  "QuantOperatorID"             => 0,
  "AllAssayDescriptionsSame"    => 0,
  "AllAssayDescriptions"        => 0,
  "IndividualAssayDescriptions" => 0,
  "AllHybDatesSame"             => 1,
  "AllHybDates"                 => 1,
  "IndividualHybDates"          => 0,
  "AllScanDatesSame"            => 1,
  "AllScanDates"                => 1,
  "IndividualScanDates"         => 0
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

  my $insertedRelatedCnt = 0;
  my $studyId = $self->{propertySet}->getProp("StudyID");

  my ($insertedAssayCnt, $skippedAssayCnt, $totalAssayCnt) = $self->createAndSubmitGUSAssaysFromFiles($studyId);
  $insertedRelatedCnt = $self->populateRelatedTables($studyId) if ($self->getArg('commit'));

  $self->log("STATUS","Inserted $insertedRelatedCnt rows in RAD.RelatedAcquisition and RAD.RelatedQuantification");
  $self->setResultDescr(
   "Total assay/s: $totalAssayCnt; Assay/s inserted: $insertedAssayCnt; Assay/s skipped: $skippedAssayCnt"
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

  foreach my $property (keys %$propertiesRef) {
    my $status = $propertiesRef->{$property};
    my $valueInFile = $self->{propertySet}->getProp("$property");

    $self->error("Value for keyword $property cannot be 'null'. Please specify an appropriate value!") 
     if ($status eq 1 && $valueInFile eq "null");
  }
}

###############################

sub createAndSubmitGUSAssaysFromFiles {
  my ($self, $studyId) = @_;

  $self->log("STATUS","DETECTED NON-COMMIT MODE: Nothing will be inserted in the database (although the log messages might say so)!") unless ($self->getArg('commit'));
  $self->log("STATUS","DETECTED NON-COMMIT MODE: Will skip checking related tables") unless ($self->getArg('commit'));

  my $dataRepositoryPath  = $self->{propertySet}->getProp("DataRepositoryPath"); 
  my $imageRepositoryPath = $self->{propertySet}->getProp("ImageRepositoryPath"); 
  my $tiffFilesPath       = $self->{propertySet}->getProp("TiffFilePath"); 
  my $gprFilesPath        = $self->{propertySet}->getProp("GPRFilePath"); 
  my $testNumber          = $self->getArg('testnumber');
  my @skipAssayList       = @{$self->getArg('skip')};

  $dataRepositoryPath    .= "/" if ($dataRepositoryPath !~ m/(.+)\/$/);
  $imageRepositoryPath   .= "/" if ($imageRepositoryPath !~ m/(.+)\/$/);
  $tiffFilesPath         .= "/" if ($tiffFilesPath !~ m/(.+)\/$/);
  $gprFilesPath          .= "/" if ($gprFilesPath !~ m/(.+)\/$/);

  my $assayCnt = 0;
  my ($assayNames, $modifiedAssayFileURIRef) = $self->findAssayNames($dataRepositoryPath, $gprFilesPath);
  my ($imageFilesLocationRef, $modifiedImageFileURIRef) = $self->getImageFileNames($imageRepositoryPath, $tiffFilesPath); 

  my $assayDescriptionHashRef = $self->parseMultipleDescriptions( $assayNames,"AllAssayDescriptionsSame","AllAssayDescriptions","IndividualAssayDescriptions");
  my $hybDateHashRef          = $self->parseMultipleDescriptions( $assayNames,"AllHybDatesSame","AllHybDates","IndividualHybDates");
  my $scanDateHashRef         = $self->parseMultipleDescriptions( $assayNames,"AllScanDatesSame","AllScanDates","IndividualScanDates");

  my $skipAssayCnt  = scalar @skipAssayList;
  my $totalAssayCnt = scalar @$assayNames;

  $self->log("STATUS","Found $totalAssayCnt assays");
  $self->log("STATUS","Skipping assay/s @skipAssayList") if (scalar @skipAssayList > 0);

  my $insertedAssayCnt = 0;
  foreach my $assayName (@$assayNames) {

    next if (($assayCnt > ($testNumber - 1)) && (defined $testNumber));
    next if (grep { $assayName =~ /^$_/ } @skipAssayList);

    my $gusAssay = $self->createSingleGUSAssay(
                    $assayName, $modifiedAssayFileURIRef, $hybDateHashRef, $scanDateHashRef, 
                    $assayDescriptionHashRef, $imageFilesLocationRef, $modifiedImageFileURIRef,
					$tiffFilesPath, $gprFilesPath, $dataRepositoryPath, $imageRepositoryPath);
    $assayCnt++;
    $insertedAssayCnt += $self->submitSingleGusAssay($gusAssay, $studyId);

    $self->undefPointerCache();  # clean memory
  }

  $self->log("STATUS","-------- End Assay Descriptions --------");
  $self->log("STATUS","OK Created $assayCnt assay/s");

  return ($insertedAssayCnt, $skipAssayCnt, $totalAssayCnt);
}

###############################

sub findAssayNames {
  my ($self, $dataRepositoryPath, $gprFilesPath) = @_;

  my $requiredExtension = $self->{propertySet}->getProp("GPRFileExtension"); 

  my @assayNames;
  my $modifiedAssayFileURIs;

  opendir (DIR, $dataRepositoryPath.$gprFilesPath) || $self->userError("Cannot open dir $dataRepositoryPath $gprFilesPath");
  my @assayDir = readdir DIR; 
  close (DIR);

  $self->userError("Cannot create assays, directory $dataRepositoryPath $gprFilesPath is empty!") 
    if (scalar @assayDir eq 0); 

  foreach my $file (@assayDir) { 

    next if ($file eq '.' || $file eq '..'); # skip '.' and '..' files

    $file =~ /(.+)\.(\w+)/;             # split name based on '.'
    next unless ($2);                   # skip files with no extension
    next if ($2 ne $requiredExtension); # skip files with diff extension
    push (@assayNames, $1);

    $modifiedAssayFileURIs->{$1} = $gprFilesPath.$1.".$2";
  }
 
  return (\@assayNames, $modifiedAssayFileURIs);
}

###############################

sub getImageFileNames {
  my ($self, $imageRepositoryPath, $tiffFilesPath) = @_; 

  my $combinedFilesStatus = $self->{propertySet}->getProp("Cy5Cy3FilesCombined"); 
  my $combinedFilesExtension = $self->{propertySet}->getProp("CombinedFileExtension"); 
  my $cy5FilesExtension = $self->{propertySet}->getProp("CY5FileExtension"); 
  my $cy3FilesExtension = $self->{propertySet}->getProp("CY3FileExtension"); 

  my $cy5ChannelDef = $self->{propertySet}->getProp("CY5ChannelDef"); 
  my $cy3ChannelDef = $self->{propertySet}->getProp("CY3ChannelDef"); 

  my ($imageFilesLocationRef, $modifiedImageFileURI);

  opendir (DIR, $imageRepositoryPath.$tiffFilesPath) || $self->userError("Cannot open dir $tiffFilesPath");
  my @imageFiles = readdir DIR; 
  close (DIR);

  foreach my $imageFile (@imageFiles) { 

    next if ($imageFile eq '.' || $imageFile eq '..'); # skip '.' and '..' files

    my ($fileName, $extension) = $imageFile =~ /(.+)\.(\w+$)/;
    my ($assay, $type) = $fileName =~ /(.+)\_(.+)/;

    if ($combinedFilesStatus eq "yes" && $extension eq $combinedFilesExtension) {

      $imageFilesLocationRef->{$assay."_$cy5ChannelDef"} = $imageRepositoryPath.$tiffFilesPath.$imageFile;
      $imageFilesLocationRef->{$assay."_$cy3ChannelDef"} = $imageRepositoryPath.$tiffFilesPath.$imageFile;

      $modifiedImageFileURI->{$assay."_$cy5ChannelDef"}  = $tiffFilesPath.$imageFile;
      $modifiedImageFileURI->{$assay."_$cy3ChannelDef"}  = $tiffFilesPath.$imageFile;
    }

    if ($type eq $cy5ChannelDef && $extension eq $cy5FilesExtension) {
      $imageFilesLocationRef->{$assay."_$cy5ChannelDef"} = $imageRepositoryPath.$tiffFilesPath.$imageFile;
      $modifiedImageFileURI->{$assay."_$cy5ChannelDef"}  = $tiffFilesPath.$imageFile;
	}

    if ($type eq $cy3ChannelDef && $extension eq $cy3FilesExtension) {
      $imageFilesLocationRef->{$assay."_$cy3ChannelDef"} = $imageRepositoryPath.$tiffFilesPath.$imageFile;
      $modifiedImageFileURI->{$assay."_$cy3ChannelDef"}  = $tiffFilesPath.$imageFile;
	}
  }

  return ($imageFilesLocationRef, $modifiedImageFileURI);
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
      $infoHashRef->{$assayName} = "" if ($allValuesContent eq "null");
    }
  }

  return $infoHashRef;
}

###############################

sub createSingleGUSAssay {
  my ($self, $assayName, $modifiedAssayFileURIRef, $hybDateHashRef, 
      $scanDateHashRef, $assayDescriptionHashRef, $imageFilesLocationRef, 
      $modifiedImageFileURIRef, $tiffFilesPath, $gprFilesPath, 
      $dataRepositoryPath, $imageRepositoryPath) = @_;

  $self->log("STATUS","----- Assay $assayName -----");

  $self->checkRequiredFilesExist($gprFilesPath, $dataRepositoryPath, $assayName, $imageFilesLocationRef);

  my $GPRinfo = $self->parseTabFile($gprFilesPath, $dataRepositoryPath, $assayName);

  my $gusAssay = $self->createGusAssay($assayName, $hybDateHashRef, $assayDescriptionHashRef);

  my ($gusAcquisitionCy5, $gusAcquisitionCy3) = $self->createGusAcquisition($assayName, $modifiedImageFileURIRef, $scanDateHashRef);
  my ($gusQuantificationCy5, $gusQuantificationCy3, $quantProtocolId) 
   = $self->createGusQuantification($assayName, $modifiedAssayFileURIRef, $GPRinfo);
  my ($gusQuantParamsCy5Ref, $gusQuantParamsCy3Ref) = $self->createGusQuantParams($GPRinfo, $quantProtocolId);

  $gusAcquisitionCy5->setParent($gusAssay);
  $gusAcquisitionCy3->setParent($gusAssay);

  $gusQuantificationCy5->setParent($gusAcquisitionCy5);
  $gusQuantificationCy3->setParent($gusAcquisitionCy3);

  foreach my $gusQuantParamsCy5 (@$gusQuantParamsCy5Ref) {
    $gusQuantParamsCy5->setParent($gusQuantificationCy5);
  }

  foreach my $gusQuantParamsCy3 (@$gusQuantParamsCy3Ref) {
    $gusQuantParamsCy3->setParent($gusQuantificationCy3);
  }

  return $gusAssay;
}

###############################

sub checkRequiredFilesExist {
  my ($self, $gprFilesPath, $dataRepositoryPath, $assayName, $imageFilesLocationRef) = @_;

  # image repository path is not required here since it is available via imageFilesRef

  my $cy5ChannelDef = $self->{propertySet}->getProp("CY5ChannelDef"); 
  my $cy3ChannelDef = $self->{propertySet}->getProp("CY3ChannelDef"); 
  my $extension   = $self->{propertySet}->getProp("GPRFileExtension");
  my $tiffFileCy5 = $imageFilesLocationRef->{$assayName."_$cy5ChannelDef"};
  my $tiffFileCy3 = $imageFilesLocationRef->{$assayName."_$cy5ChannelDef"};

  my $gprFile = $dataRepositoryPath.$gprFilesPath.$assayName.".$extension";

  $self->userError("Missing file: $gprFile") if (! -e $gprFile); 

  $self->userError("Missing Cy5 tif (image) file for assay: $assayName") if (! -e $tiffFileCy5); 
  $self->userError("Empty Cy5 tif (image) file for assay: $assayName")   if ( -z $tiffFileCy5); 
  $self->userError("Missing Cy3 tif (image) file for assay: $assayName") if (! -e $tiffFileCy3); 
  $self->userError("Empty Cy3 tif (image) file for assay: $assayName")   if ( -z $tiffFileCy3); 
}

###############################

sub parseTabFile {
  my ($self, $gprFilesPath, $dataRepositoryPath, $assayName) = @_;

  my $GPRinfo;
  my $flag = 1;

  my $extension = $self->{propertySet}->getProp("GPRFileExtension");

  my $file = $dataRepositoryPath.$gprFilesPath.$assayName.".$extension";

  open (GPRFILE, $file) || $self->userError("Can't open $file for parsing: $!");
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

  # HARD-CODED. 
  # All names and values are modified in this subroutine to suit CBIL
  # instance of RAD. 
  # THIS MAKES THIS PLUGIN COMPATIBLE WITH THE RAD STUDY ANNOTATOR
  # Please modify names and their values based on your instance, if necessary.

  # The following statement can be extended to fill as many values 
  # as required, via 'elsif' statements

  if ($key eq "Creator") {
    my @softwareVersionInfo = split " ",$value;
    my $softwareVersion;
    foreach my $word (@softwareVersionInfo) {
      $softwareVersion = $word if (/[0-9]/);
    }

    $modifiedKey = "software version";
    $modifiedValue = $softwareVersion;

  } elsif ($key =~ /^RatioFormulation/) {

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

  } elsif ($key eq "DateTime") {

      $modifiedKey = $key;
      $value =~ s/\//\-/g;
      $modifiedValue = $value;

  } else {
      $modifiedKey = $key;
      $modifiedValue = $value;
  }

  return ($modifiedKey, $modifiedValue);
}

###############################

sub createGusAssay {
  my ($self, $assayName, $hybDateHashRef, $assayDescriptionHashRef) = @_;

  my $arrayId       = $self->{propertySet}->getProp("ArrayID");
  my $batchId       = $self->{propertySet}->getProp("BatchID");
  my $hybProtocolId = $self->{propertySet}->getProp("HybProtocolID");
  my $hybOperatorId = $self->{propertySet}->getProp("HybOperatorID");
  
  $self->checkDatabaseEntry("GUS::Model::RAD::ArrayDesign", "array_design_id", $arrayId);
  $self->checkDatabaseEntry("GUS::Model::RAD::Protocol", "protocol_id", $hybProtocolId);
  $self->checkDatabaseEntry("GUS::Model::SRes::Contact", "contact_id", $hybOperatorId);

  my $getOntologyProtocolTypeIdObject = GUS::Model::Study::OntologyEntry->new({
    category => "ExperimentalProtocolType",
    value    => "hybridization"
  });
  $self->error("Create object failed: Table RAD.OntologyEntry, category ExperimentalProtocolType, value hybridization") 
   unless ($getOntologyProtocolTypeIdObject->retrieveFromDB);
  my $ontologyProtocolTypeIdFromDb = $getOntologyProtocolTypeIdObject->getOntologyEntryId();

  my $protocolTypeIdObject = GUS::Model::RAD::Protocol->new({ protocol_id => $hybProtocolId });
  $self->error("Create object failed: Table RAD.Protocol, category ExperimentalProtocolType, value hybridization") 
   unless ($protocolTypeIdObject->retrieveFromDB);
  my $protocolTypeIdFromDb = $protocolTypeIdObject->getProtocolTypeId();

  $self->error("Hybridization protocol ID specified does not correspond to any hybridization protocol in table RAD.Ontology")
   if ($ontologyProtocolTypeIdFromDb ne $protocolTypeIdFromDb);

  my $hybDate = $hybDateHashRef->{$assayName};
  my $description = $assayDescriptionHashRef->{$assayName};

  my $params = {
    name            => $assayName,
    array_design_id => $arrayId,
    assay_date      => $hybDate,
    protocol_id     => $hybProtocolId,
    operator_id     => $hybOperatorId,
  };

  $params->{"array_batch_identifier"} = $batchId if ($batchId ne "null");
  $params->{"description"} = $description if ($description ne "");

  my $assay = GUS::Model::RAD::Assay->new($params);

  $self->log("STATUS","OK Inserted 1 row in table RAD.Assay for assay $assayName");

  return $assay;
}

###############################

sub checkDatabaseEntry {
  my ($self, $tableName, $paramName, $valueToCheck) = @_;

  my $checkerObject = $tableName->new({"$paramName" => $valueToCheck});

  $self->error("Create object failed :(\n Table name: $tableName\n parameter: $paramName\n value: $valueToCheck\n
Check if the parameter and its value exist in the table")
   unless ($checkerObject->retrieveFromDB);
}

###############################

# gusAssayParams (or hyb params) are to be input via the Study Annotator website

###############################

sub createGusAcquisition {
  my ($self, $assayName, $modifiedImageFileURIRef, $scanDateHashRef) = @_;

  my $acqProtocolId = $self->{propertySet}->getProp("AcqProtocolID");

  my $acqDate = $scanDateHashRef->{$assayName};
  my $cy5ChannelDef = $self->{propertySet}->getProp("CY5ChannelDef");
  my $cy3ChannelDef = $self->{propertySet}->getProp("CY3ChannelDef");

  my $acquisitionCnt = 0;

  my $channelDefs = {
   $cy5ChannelDef => "",
   $cy3ChannelDef => ""
  };

  my $protocolObject = GUS::Model::RAD::Protocol->new({protocol_id => $acqProtocolId});
  $self->error("Create object failed: Table RAD.Protocol, ID $acqProtocolId") 
   unless ($protocolObject->retrieveFromDB);
  my $protocolName = $protocolObject->getName();

  foreach my $channel (keys %$channelDefs) {

    my $ontologyEntryIdObject = GUS::Model::Study::OntologyEntry->new({value => $channel, category => 'LabelCompound'});
    $self->error("Create object failed: Table Study.OntologyEntry, value $channel & category 'LabelCompound'") 
     unless ($ontologyEntryIdObject->retrieveFromDB);
    my $ontologyEntryId = $ontologyEntryIdObject->getOntologyEntryId();

    my $acqName = "$assayName-$channel-".$protocolName;
    my $acqParameters = {
      name             => $acqName,
      channel_id       => $ontologyEntryId,
      protocol_id      => $acqProtocolId,
      acquisition_date => $acqDate,
      uri              => $modifiedImageFileURIRef->{$assayName."_$channel"}
    };

    $channelDefs->{$channel} = $acqParameters;
    $acquisitionCnt++;
  }

  my $acquisitionCy5 = GUS::Model::RAD::Acquisition->new($channelDefs->{$cy5ChannelDef});
  my $acquisitionCy3 = GUS::Model::RAD::Acquisition->new($channelDefs->{$cy3ChannelDef}); 

  $self->log("STATUS","OK Inserted $acquisitionCnt rows in table RAD.Acquisition for Cy5 and Cy3 acquisitions");
 
 return ($acquisitionCy5, $acquisitionCy3);
}

###############################

# acquisitionParams are to be input via the Study Annotator website

###############################

sub createGusQuantification {
  my ($self, $assayName, $modifiedAssayFileURIRef, $GPRinfo) = @_;

  my (@gusQuantificationsCy5, @gusQuantificationsCy3);

  my $acqProtocolId         = $self->{propertySet}->getProp("AcqProtocolID");
  my $quantOperatorId       = $self->{propertySet}->getProp("QuantOperatorID");
  my $genepixQuantification = $self->{propertySet}->getProp("GenePixQuantification");

  my $quantDate = $GPRinfo->{"DateTime"};
  my $gprURI = $modifiedAssayFileURIRef->{$assayName};

  my $protocolNameObject = GUS::Model::RAD::Protocol->new({protocol_id => $acqProtocolId});
  $self->error("Create object failed: Table RAD.Protocol, protocol_id $acqProtocolId") 
   unless ($protocolNameObject->retrieveFromDB);
  my $tempAcqName = $protocolNameObject->getName();

  my $protocolIdObject = GUS::Model::RAD::Protocol->new({name => $genepixQuantification});
  $self->error("Create object failed: Table RAD.Protocol, name for GenePix quantification $genepixQuantification") 
   unless ($protocolIdObject->retrieveFromDB);
  my $quantProtocolId = $protocolIdObject->getId();

  my $gprQuantParameters = {
    protocol_id         => $quantProtocolId,
    uri                 => $gprURI
  };

  $gprQuantParameters->{'quantification_date'} = $quantDate if ( defined $GPRinfo->{"DateTime"} && $GPRinfo->{"DateTime"} ne "");
  $gprQuantParameters->{'operator_id'} = $quantOperatorId if (defined $quantOperatorId);
# check this for hard coding
  my $acqNameCy5                 = "$assayName-Cy5-$tempAcqName-Genepix quantification"; # CBIL-specific policy on Acq. Name
  my $gprQuantParametersCy5      = $gprQuantParameters;
  $gprQuantParametersCy5->{name} = $acqNameCy5;
  my $gprQuantificationCy5       = GUS::Model::RAD::Quantification->new($gprQuantParametersCy5);

# check this for hard coding
  my $acqNameCy3                 = "$assayName-Cy3-$tempAcqName-Genepix quantification"; # CBIL-specific policy on Acq. Name
  my $gprQuantParametersCy3      = $gprQuantParameters;
  $gprQuantParametersCy3->{name} = $acqNameCy3;
  my $gprQuantificationCy3       = GUS::Model::RAD::Quantification->new($gprQuantParametersCy3);

  $self->log("STATUS","OK Inserted 2 rows in table RAD.Quantification for Cy5 & Cy3 quantifications");

  return ($gprQuantificationCy5, $gprQuantificationCy3, $quantProtocolId);
}
###############################

sub createGusQuantParams {
  my ($self, $GPRinfo, $quantProtocolId) = @_;

  $self->checkDatabaseEntry("GUS::Model::RAD::Protocol", "protocol_id", $quantProtocolId);

  my $ratioFormulations        = $self->{propertySet}->getProp("RatioFormulations");
  my $standardDeviation        = $self->{propertySet}->getProp("StandardDeviation");
  my $backgroundDensityMeasure = $self->{propertySet}->getProp("BackgroundDensityMeasure");
  my $softwareVersion          = $self->{propertySet}->getProp("SoftwareVersion");

  my (@gusQuantParamsCy5, @gusQuantParamsCy3);
  my $quantParamKeywordCnt = 0;

  my $params = {
    $ratioFormulations        => 1,
    $standardDeviation        => 1,
    $backgroundDensityMeasure => 1,
    $softwareVersion          => 1
  };

  foreach my $param (keys %$params) {

    next if ( ! defined $GPRinfo->{$param} || $GPRinfo->{$param} eq ""); # skip undefined params

    my $protocolParamObject = GUS::Model::RAD::ProtocolParam->new({
        protocol_id => $quantProtocolId,
        name        => $param
    });

    $self->error("Create object failed: Table RAD.ProtocolParam, name $param")
      unless ($protocolParamObject->retrieveFromDB);

    my $quantParametersCy5 = GUS::Model::RAD::QuantificationParam->new({
     name  => $param,
     value => $GPRinfo->{$param}
     });
    $quantParametersCy5->setParent($protocolParamObject); # protocolParam in only needed here, so set parent here
    push(@gusQuantParamsCy5, $quantParametersCy5);
    $quantParamKeywordCnt++;

    my $quantParametersCy3 = GUS::Model::RAD::QuantificationParam->new({
     name  => $param,
     value => $GPRinfo->{$param}
     });
    $quantParametersCy3->setParent($protocolParamObject); # protocolParam in only needed here, so set parent here
    push(@gusQuantParamsCy3, $quantParametersCy3);
    $quantParamKeywordCnt++;
  }

  $self->log("STATUS","OK Inserted $quantParamKeywordCnt rows in table RAD.QuantificationParam for Cy5 and Cy3 quantification parameters");

  return (\@gusQuantParamsCy5, \@gusQuantParamsCy3);
}


###############################

sub submitSingleGusAssay {
  my ($self, $gusAssay, $studyId) = @_;

  my $gusStudy = GUS::Model::Study::Study->new({study_id => $studyId});
  $self->error("Create object failed: Table RAD.Study, study_id $studyId")
   unless ($gusStudy->retrieveFromDB);

  my $gusInsertedAssayCnt = 0;

  my $studyAssay = GUS::Model::RAD::StudyAssay->new(); # links RAD.Study & RAD.Assay

  $studyAssay->setParent($gusAssay);
  $studyAssay->setParent($gusStudy);

  if ($self->getArg('commit')) {
    $gusAssay->submit();
    $gusInsertedAssayCnt = 1;
  }

  return $gusInsertedAssayCnt;
}

###############################

sub populateRelatedTables {
  my ($self, $studyId) = @_; 

  # query db directly, since objects only return one value, 
  # and we need a list of assay IDs

  my $dbh = $self->getQueryHandle();
  my $sth = $dbh->prepare("select assay_id from rad.studyassay where study_id = ?");
  $sth->execute("$studyId");

  my @assayIds = ();
  while (my @row = $sth->fetchrow_array) {
    push (@assayIds, $row[0]);
  }

  $sth->finish;
  $self->error("Id $studyId does not exist in the table RAD.StudyAssay") if (scalar @assayIds eq 0); 

  my $insertedRelatedCnt = 0;

  foreach my $assayId (@assayIds) {

    my $assayObject = GUS::Model::RAD::Assay->new({assay_id => $assayId});
    $self->error("Create object failed: Table RAD.Assay, assay_id $assayId") 
     unless ($assayObject->retrieveFromDB);
    my $assayName = $assayObject->getName();

    my ($acquisitionIdsRef, $acquisitionChannelsRef, $relatedAcquisitionCnt) = $self->populateRelatedAcquisition($assayName, $assayId);
    my $relatedQuantificationCnt = $self->populateRelatedQuantification($assayName, $assayId, $acquisitionIdsRef, $acquisitionChannelsRef);

    $insertedRelatedCnt += $relatedAcquisitionCnt + $relatedQuantificationCnt;
    $self->undefPointerCache();  # clean memory
  }

  return $insertedRelatedCnt;
}

###############################

sub populateRelatedAcquisition {
  my ($self, $assayName, $assayId) = @_; 

  my $dbh = $self->getQueryHandle();
  my $sth = $dbh->prepare("select acquisition_id, channel_id from rad.acquisition where assay_id = ?");
  $sth->execute("$assayId");

  my (@acquisitionIds, @acquisitionChannels) = ();

  while (my @row = $sth->fetchrow_array) {
    push (@acquisitionIds, $row[0]);

    my $ontologyEntryIdObject = GUS::Model::Study::OntologyEntry->new({ontology_entry_id => $row[1]});
    $self->error("Create object failed: Table Study.OntologyEntry, ontology_entry_id $row[1]") 
     unless ($ontologyEntryIdObject->retrieveFromDB);
    my $channelName = $ontologyEntryIdObject->getValue();

    push (@acquisitionChannels, $channelName);
  }

  $sth->finish;
  $self->error("Assay Id $assayId does not exist in the table RAD.Acquisition") if (scalar @acquisitionIds eq 0); 
  $self->error("More/less than two entries found for assay id $assayId in RAD.Acquisition") if (scalar @acquisitionIds ne 2); 

  my $relatedAcquisitionCnt = 0;
    
  my $acquistionAssociationOne = GUS::Model::RAD::RelatedAcquisition->new({
    acquisition_id            => $acquisitionIds[0],
    associated_acquisition_id => $acquisitionIds[1],
    name                      => $assayName,
    designation               => $acquisitionChannels[0],
    associated_designation    => $acquisitionChannels[1]
  });
  $relatedAcquisitionCnt++;

  my $acquistionAssociationTwo = GUS::Model::RAD::RelatedAcquisition->new({
    acquisition_id            => $acquisitionIds[1],
    associated_acquisition_id => $acquisitionIds[0],
    name                      => $assayName,
    designation               => $acquisitionChannels[1],
    associated_designation    => $acquisitionChannels[0]
  });
  $relatedAcquisitionCnt++;

  $acquistionAssociationOne->submit() if ($self->getArg('commit') && ! $acquistionAssociationOne->retrieveFromDB);
  $acquistionAssociationTwo->submit() if ($self->getArg('commit') && ! $acquistionAssociationTwo->retrieveFromDB);

  return (\@acquisitionIds, \@acquisitionChannels, $relatedAcquisitionCnt);
}

###############################

sub populateRelatedQuantification {
  my ($self, $assayName, $assayId, $acquisitionIdsRef, $acquisitionChannelsRef) = @_; 

  my @quantificationIds;
  foreach my $acquisitionId (@$acquisitionIdsRef) {

    my $quantificationObject = GUS::Model::RAD::Quantification->new({acquisition_id => $acquisitionId});
    $self->error("Create object failed: Table RAD.Quantification, acquisition_id $acquisitionId") 
     unless ($quantificationObject->retrieveFromDB);
    my $quantificationId = $quantificationObject->getQuantificationId();

    push (@quantificationIds, $quantificationId);
  }

  $self->error("More/less than two entries found for acqusitions @$acquisitionIdsRef in RAD.Quantification") 
    if (scalar @quantificationIds ne 2); 
    
  my $relatedQuantificationCnt = 0;

  my $quantificationAssociationOne = GUS::Model::RAD::RelatedQuantification->new({
    quantification_id            => $quantificationIds[0],
    associated_quantification_id => $quantificationIds[1],
    name                         => $assayName,
    designation                  => @$acquisitionChannelsRef[0],
    associated_designation       => @$acquisitionChannelsRef[1]
  });
  $relatedQuantificationCnt++;

  my $quantificationAssociationTwo = GUS::Model::RAD::RelatedQuantification->new({
    quantification_id            => $quantificationIds[1],
    associated_quantification_id => $quantificationIds[0],
    name                         => $assayName,
    designation                  => @$acquisitionChannelsRef[1],
    associated_designation       => @$acquisitionChannelsRef[0]
  });
  $relatedQuantificationCnt++;

  $quantificationAssociationOne->submit() if ($self->getArg('commit') && ! $quantificationAssociationOne->retrieveFromDB);
  $quantificationAssociationTwo->submit() if ($self->getArg('commit') && ! $quantificationAssociationTwo->retrieveFromDB);

  return $relatedQuantificationCnt;
}

#################### END
