package GUS::RAD::Plugin::GenePixStudyModuleILoader;

@ISA = qw( GUS::PluginMgr::Plugin);

use strict 'vars';

# CBIL specific packages
use CBIL::Util::Disp;
use CBIL::Util::PropertySet;

# GUS specific packages
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

  my $purposeBrief = "Creates assays, acquisitions and quantifications for GenePix assays en-batch.";

  my $purpose      = "Create assays, acquisitions and quantifications for GenePix assays in RAD3 tables from multiple files in batch mode.";
 
  my $tablesAffected = [
    ['RAD3::Study',                 'One row for the given study is entered'],
    ['RAD3::Assay',                 'One row for each distinct assay is entered'],
    ['RAD3::StudyAssay',            'One row linking the given study to each assay is entered'],
    ['RAD3::Acquisition',           'For each assay, two rows (2 acquisitions) are entered, one for each channel'],
    ['RAD3::Quantification',        'For each assay, two rows (2 quantifications) are entered, one for each channel'],
    ['RAD3::QuantificationParam',   'Eight rows, four for each channel (Cy5 and Cy3), corresponding to four parameters per quantification, are entered'],
    ['RAD3::RelatedAcquisition',    'Two rows are entered for each assay, relating the two corresponding acquisitions'],
    ['RAD3::RelatedQuantification', 'Two rows are entered for each assay, relating the two corresponding quantifications']
  ];

  my $tablesDependedOn = [
    ['RAD3::Study',                  'Holds study information'],
    ['RAD3::Array',                  'Holds array information'], 
    ['RAD3::Channel',                'Holds channel (Cy5 or Cy3 in this case) information'], 
    ['RAD3::Protocol',               'Holds hybridization, image acquisition and feature extraction protocol information'], 
    ['RAD3::ProtocolParam',          'Holds protocol parameter information'], 
    ['SRes::Contact',                'Holds personnel contact information']
  ];

  my $howToRestart = "Cannot be restarted."; 

  my $failureCases = "Files not in an appropriate format.";

  my $notes = <<NOTES;

=pod

=head2 F<General Description>

Plugin reads a config file with information about full paths of directories where files of interest (.gpr & .tif)
are maintained.  Information is extracted from the '.gpr' files and entered into a database. 

Since assay, acquisition and most quantification parameters are not readily available through the '.gpr' files,
they cannot be added to the database through this plugin. They have to be added to the tables separately, 
either directly or through the following forms in the RAD StudyAnnotator: Hybridization Parameters, Acquisition
Parameters and Quantification Parameters.

Certain portions in the PERL code are hard-coded for use by RAD at CBIL. These are indicated with the comment 'HARD-CODED', 
and should be changed based on data maintained in the local instance of RAD.

The plugin also assumes the following parameters to be the same for all assays: Array ID, Batch ID, Hybridization
Protocol ID, Hybridization Operator ID, Acquisition Protocol ID, Quantification Protocol ID and Quantification Operator ID.

=head2 F<Config File [ required ]>

Blank lines and comment lines (lines starting with '#') are ignored.
The following keywords and their values are required (in cases where no value is to be specified, please
use the words 'null' as the value):

  - gpr_File_Path= full path to the dir where the gpR files are kept
  - Study_ID^ = the study identifier
  - Array_ID^ = array type ID
 
 ASSAY SECTION

  - Batch_ID** = the study identifier
  - All_Assay_Descriptions_Same** = requires a yes/no answer; if yes, then allAssayDescriptions 
    will be read, else individualAssayDescriptions will be read
  - All_Assay_Descriptions** = description of the assay
  - Individual_Assay_Descriptions** = assayName|description;assayName|description;assayName|description;

 HYBRIDIZATION SECTION

  - Hyb_Protocol_ID^ = hybridization protocol id
  - Hyb_Operator_ID^ = hybridization operator id
  - All_Hyb_Dates_Same = requires a yes/no answer; if yes, then allHybDates will be read, 
    else individual_HybDates will be read
  - All_Hyb_Dates = yyyy-mm-dd
  - Individual_Hyb_Dates = assayName|yyyy-mm-dd;assayName|yyyy-mm-dd;assayName|yyyy-mm-dd;

 ACQUISITION SECTION

  - Acq_Protocol_ID^ = acquisition protocol id
  - Tiff_File_Path = full path to the dir where the .tif files are kept
  - All_Scan_Dates_Same = requires a yes/no answer; if yes, then allScanDates will be read, 
    else individual_Scan_Dates will be read
  - All_Scan_Dates = yyyy-mm-dd
  - Individual_Scan_Dates = assayName|yyyy-mm-dd;assayName|yyyy-mm-dd;assayName|yyyy-mm-dd;

 QUANTIFICATION SECTION

  - Quant_Protocol_ID^ = quantification protocol id
  - Quant_Operator_ID^** = quantification operator id

  ^ These values should pre-exist in various tables in the database
 ** These values are optional, i.e., the keywords should exist, but their 
    the values can be left blank.

Each of these keywords should be on a separate line. The values for these keywords should be separated by an '=' sign. A sample
file is maintained in \$PROJECT_HOME/GUS/RAD/config/sample_GenePixStudyModuleILoader.cfg (the sample config file also contains instructions).


=head2 F<Database requirements>

This plugin assumes that the following entries exist in your instance of the database:

 1.  The study in RAD3.Study
 2.  The appropriate GenePix array in RAD3.Array
 3.  The hybridization protocol, the acquisition protocol, the quantification protocol in RAD3.Protocol
 4.  Quantification parameters for quantification in RAD3.ProtocolParam

If any of the above is missing, the plugin will report an error.

=head2 F<Warning (for non-CBIL instances)>

For local installations of RAD which differ from the CBIL database, some lines of this plugin will need to be modified, to accomodate
hard-coded information. You might need to modify any piece of code labelled as 'HARD-CODED' in the comments below.

=head1 EXAMPLES

ga GUS::RAD::Plugin::GenePixStudyModuleILoader --cfg_file /somePath/configFile.cfg --testnumber 1 --group myPI --project myProject

ga GUS::RAD::Plugin::GenePixStudyModuleILoader --cfg_file /somePath/configFile.cfg --testnumber 1 --group myPI --project myProject --skip assay123456

ga GUS::RAD::Plugin::GenePixStudyModuleILoader --cfg_file /somePath/configFile.cfg --group myPI --project myProject --skip assay123456,assay123457 --commit

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
 

  my $argsDeclaration  = [
     
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

my @properties = (
    [ "gpr_File_Path",                 "", "" ],
    [ "Study_ID",                      "", "" ],
    [ "Array_ID",                      "", "" ],
    [ "Batch_ID",                      "", "" ],  # can be null
    [ "All_Assay_Descriptions_Same",   "", "" ],  # can be null
    [ "All_Assay_Descriptions",        "", "" ],  # can be null
    [ "Individual_Assay_Descriptions", "", "" ],  # can be null
    [ "Hyb_Protocol_ID",               "", "" ],
    [ "Hyb_Operator_ID",               "", "" ],
    [ "All_Hyb_Dates_Same",            "", "" ],
    [ "All_Hyb_Dates",                 "", "" ],
    [ "Individual_Hyb_Dates",          "", "" ],
    [ "Acq_Protocol_ID",               "", "" ],
    [ "Tiff_File_Path",                "", "" ],
    [ "All_Scan_Dates_Same",           "", "" ],
    [ "All_Scan_Dates",                "", "" ],
    [ "Individual_Scan_Dates",         "", "" ],
    [ "Quant_Protocol_ID",             "", "" ],
    [ "Quant_Operator_ID",             "", "" ]   # can be null
 ); 

###############################

sub run {
  my $self = shift;
    
  $self->logAlgInvocationId();
  $self->logCommit();
  $self->logArgs();

  $self->{propertySet} = CBIL::Util::PropertySet->new($self->getArg('cfg_file'), \@properties);

  my $studyId = $self->{propertySet}->getProp("Study_ID");

  my ($gusAssays, $skippedAssayCnt, $totalAssayCnt) = $self->createGUSAssaysFromFiles($studyId);
  my $insertedAssayCnt                              = $self->submitGusAssays($gusAssays, $studyId);
  my $insertedRelatedCnt                            = $self->populateRelatedTables($studyId); 

  $self->log("STATUS","Inserted $insertedRelatedCnt rows in RAD3.RelatedAcquisition and RAD3.RelatedQuantification");
  $self->setResultDescr(
   "Total assay/s: $totalAssayCnt; Assay/s inserted: $insertedAssayCnt; Assay/s skipped: $skippedAssayCnt"
  );
}

###############################

sub createGUSAssaysFromFiles {
  my ($self, $studyId) = @_;

  my @gusAssays;
  my $assayCnt = 0;

  my $tiffFilePath  = $self->{propertySet}->getProp("Tiff_File_Path"); 
  my $gprFilePath   = $self->{propertySet}->getProp("gpr_File_Path"); 
  my $testNumber    = $self->getArgs->{testnumber};
  my @skipAssayList = @{$self->getArgs->{skip}};

  my ($assayNames, $modifiedAssayFileURIRef)    = $self->findAssayNames($gprFilePath);
  my ($imageFilesRef, $modifiedImageFileURIRef) = $self->getImageFileNames($tiffFilePath); 
  my $assayDescriptionHashRef                   = $self->parseMultipleDescriptions($assayNames,"All_Assay_Descriptions_Same","All_Assay_Descriptions","Individual_Assay_Descriptions");
  my $hybDateHashRef                            = $self->parseMultipleDescriptions($assayNames,"All_Hyb_Dates_Same","All_Hyb_Dates","Individual_Hyb_Dates");
  my $scanDateHashRef                           = $self->parseMultipleDescriptions($assayNames,"All_Scan_Dates_Same","All_Scan_Dates","Individual_Scan_Dates");

  my $skipAssayCnt  = scalar @skipAssayList;
  my $totalAssayCnt = scalar @$assayNames;

  $self->log("STATUS","Found $totalAssayCnt assays");
  $self->log("STATUS","Skipping assay/s @skipAssayList") if (scalar @skipAssayList > 0);

  foreach my $assayName (@$assayNames) {

    next if (($assayCnt > ($testNumber - 1)) && (defined $testNumber));
    next if (grep { $assayName =~ /^$_/ } @skipAssayList);

    my $gusAssay = $self->createSingleGUSAssay($assayName, $modifiedAssayFileURIRef, $hybDateHashRef, $scanDateHashRef, $assayDescriptionHashRef, $imageFilesRef, $modifiedImageFileURIRef);

    push(@gusAssays, $gusAssay);
    $assayCnt++;
  }

  $self->log("STATUS","-------- End Assay Descriptions --------");
  $self->log("STATUS","OK Created $assayCnt assay/s");

  return (\@gusAssays, $skipAssayCnt, $totalAssayCnt);
}

###############################

sub submitGusAssays {
  my ($self, $gusAssays, $studyId) = @_;

  my $gusStudy = GUS::Model::RAD3::Study->new({study_id => $studyId});
  $self->error("Create object failed: Table RAD3.Study, study_id $studyId")
   unless ($gusStudy->retrieveFromDB);

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
  $self->error("Id $studyId does not exist in the table RAD3.StudyAssay") if (scalar @assayIds eq 0); 

  my $insertedRelatedCnt = 0;

  foreach my $assayId (@assayIds) {

    my $assayObject = GUS::Model::RAD3::Assay->new({assay_id => $assayId});
    $self->error("Create object failed: Table RAD3.Assay, assay_id $assayId") 
     unless ($assayObject->retrieveFromDB);
    my $assayName = $assayObject->getName();

    my ($acquisitionIdsRef, $acquisitionChannelsRef, $relatedAcquisitionCnt) = $self->populateRelatedAcquisition($assayName, $assayId);
    my $relatedQuantificationCnt = $self->populateRelatedQuantification($assayName, $assayId, $acquisitionIdsRef, $acquisitionChannelsRef);

    $insertedRelatedCnt += $relatedAcquisitionCnt + $relatedQuantificationCnt;
  }

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

    my $channelObject = GUS::Model::RAD3::Channel->new({channel_id => $row[1]});
    $self->error("Create object failed: Table RAD3.Channel, channel_id $row[1]") 
     unless ($channelObject->retrieveFromDB);
    my $channelName = $channelObject->getName();

    push (@acquisitionChannels, $channelName);
  }

  $sth->finish;
  $self->error("Assay Id $assayId does not exist in the table RAD3.Acquisition") if (scalar @acquisitionIds eq 0); 
  $self->error("More/less than two entries found for assay id $assayId in RAD3.Acquisition") if (scalar @acquisitionIds ne 2); 

  my $relatedAcquisitionCnt = 0;
    
  my $acquistionAssociationOne = GUS::Model::RAD3::RelatedAcquisition->new({
    acquisition_id            => $acquisitionIds[0],
    associated_acquisition_id => $acquisitionIds[1],
    name                      => $assayName,
    designation               => $acquisitionChannels[0],
    associated_designation    => $acquisitionChannels[1]
  });
  $relatedAcquisitionCnt++;

  my $acquistionAssociationTwo = GUS::Model::RAD3::RelatedAcquisition->new({
    acquisition_id            => $acquisitionIds[1],
    associated_acquisition_id => $acquisitionIds[0],
    name                      => $assayName,
    designation               => $acquisitionChannels[1],
    associated_designation    => $acquisitionChannels[0]
  });
  $relatedAcquisitionCnt++;

  $acquistionAssociationOne->submit() if ($self->getArgs->{commit});
  $acquistionAssociationTwo->submit() if ($self->getArgs->{commit});

  return (\@acquisitionIds, \@acquisitionChannels, $relatedAcquisitionCnt);
}

###############################

sub populateRelatedQuantification {
  my ($self, $assayName, $assayId, $acquisitionIdsRef, $acquisitionChannelsRef) = @_; 

  my @quantificationIds;
  foreach my $acquisitionId (@$acquisitionIdsRef) {

    my $quantificationObject = GUS::Model::RAD3::Quantification->new({acquisition_id => $acquisitionId});
    $self->error("Create object failed: Table RAD3.Quantification, acquisition_id $acquisitionId") 
     unless ($quantificationObject->retrieveFromDB);
    my $quantificationId = $quantificationObject->getQuantificationId();

    push (@quantificationIds, $quantificationId);
  }

  $self->error("More/less than two entries found for acqusitions @$acquisitionIdsRef in RAD3.Quantification") 
    if (scalar @quantificationIds ne 2); 
    
  my $relatedQuantificationCnt = 0;

  my $quantificationAssociationOne = GUS::Model::RAD3::RelatedQuantification->new({
    quantification_id            => $quantificationIds[0],
    associated_quantification_id => $quantificationIds[1],
    name                         => $assayName,
    designation                  => @$acquisitionChannelsRef[0],
    associated_designation       => @$acquisitionChannelsRef[1]
  });
  $relatedQuantificationCnt++;

  my $quantificationAssociationTwo = GUS::Model::RAD3::RelatedQuantification->new({
    quantification_id            => $quantificationIds[1],
    associated_quantification_id => $quantificationIds[0],
    name                         => $assayName,
    designation                  => @$acquisitionChannelsRef[1],
    associated_designation       => @$acquisitionChannelsRef[0]
  });
  $relatedQuantificationCnt++;

  $quantificationAssociationOne->submit() if ($self->getArgs->{commit});
  $quantificationAssociationTwo->submit() if ($self->getArgs->{commit});

  return $relatedQuantificationCnt;
}

###############################

sub findAssayNames {
  my ($self,$assayNameFilesDir) = @_;

  my @assayNames;
  my $modifiedAssayFileURIs;

  my $requiredExtension = "gpr";  # filenames correspond to assay names
  my ($localFilePath, $specificPath) = split "RAD/", $assayNameFilesDir; # HARD-CODED. Based on our convention for naming files

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

    $modifiedAssayFileURIs->{$1} = "$specificPath/$1.$2";
  }
 
  return (\@assayNames, $modifiedAssayFileURIs);
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

sub getImageFileNames {
  my ($self, $imageFilesDir) = @_;

  my ($imageFilesRef, $modifiedImageFileURI);

  opendir (DIR,$imageFilesDir) || $self->userError("Cannot open dir $imageFilesDir");
  my @imageFiles = readdir DIR; 
  close (DIR);

  my ($localPath, $specificPath) = split "RAD_images/", $imageFilesDir; # HARD-CODED. Based on our convention for naming files

  foreach my $imageFile (@imageFiles) { 

    next if ($imageFile eq '.' || $imageFile eq '..'); # skip '.' and '..' files

    my ($fileName, $extention) = $imageFile =~ /(.+)\.(\w+$)/;
    my ($assay, $type) = $fileName =~ /(.+)\_(.+)/;

    if ($type eq "Cy5Cy3" || $type eq "Cy3Cy5") {  # HARD-CODED. Based on our convention for naming files

      $imageFilesRef->{$assay."_Cy5"} = "$imageFilesDir/$imageFile"; # HARD-CODED. Based on our convention for naming files
      $imageFilesRef->{$assay."_Cy3"} = "$imageFilesDir/$imageFile"; # HARD-CODED. Based on our convention for naming files

      $modifiedImageFileURI->{$assay."_Cy5"} = "$specificPath/$imageFile"; # HARD-CODED. Based on our convention for naming files
      $modifiedImageFileURI->{$assay."_Cy3"} = "$specificPath/$imageFile"; # HARD-CODED. Based on our convention for naming files

    } else {
      $imageFilesRef->{$assay."_$type"} = "$imageFilesDir/$imageFile";       # HARD-CODED. Based on our convention for naming files
      $modifiedImageFileURI->{$assay."_$type"} = "$specificPath/$imageFile"; # HARD-CODED. Based on our convention for naming files
    }
  }

  return ($imageFilesRef, $modifiedImageFileURI);
}

###############################

sub createSingleGUSAssay {
  my ($self, $assayName, $modifiedAssayFileURIRef, $hybDateHashRef, $scanDateHashRef, $assayDescriptionHashRef, $imageFilesRef, $modifiedImageFileURIRef) = @_;

  $self->log("STATUS","----- Assay $assayName -----");

  $self->checkRequiredFilesExist($assayName, $imageFilesRef);

  my $GPRinfo = $self->parseTabFile('gpr', $assayName);

  my $gusAssay = $self->createGusAssay($assayName, $hybDateHashRef, $assayDescriptionHashRef);

  my ($gusAcquisitionCy5, $gusAcquisitionCy3)       = $self->createGusAcquisition($assayName, $modifiedImageFileURIRef, $scanDateHashRef);
  my ($gusQuantificationCy5, $gusQuantificationCy3) = $self->createGusQuantification($assayName, $modifiedAssayFileURIRef, $GPRinfo);
  my ($gusQuantParamsCy5Ref, $gusQuantParamsCy3Ref) = $self->createGusQuantParams($GPRinfo);

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
  my ($self, $assayName, $imageFilesRef) = @_;

  my $gprFile     = $self->{propertySet}->getProp("gpr_File_Path")."/$assayName.gpr";
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

  my $filePath = $self->{propertySet}->getProp("${prefix}_File_Path");

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

  # HARD-CODED. 
  # All names and values are modified in this subroutine to suit our
  # instance of RAD. Please modify names and their values based on your
  # instance, if necessary.

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

  my $arrayId       = $self->{propertySet}->getProp("Array_ID");
  my $batchId       = $self->{propertySet}->getProp("Batch_ID");
  my $hybProtocolId = $self->{propertySet}->getProp("Hyb_Protocol_ID");
  my $hybOperatorId = $self->{propertySet}->getProp("Hyb_Operator_ID");
  
  $self->checkDatabaseEntry("GUS::Model::RAD3::Array", "array_id", $arrayId);
  $self->checkDatabaseEntry("GUS::Model::RAD3::Protocol", "protocol_id", $hybProtocolId);
  $self->checkDatabaseEntry("GUS::Model::SRes::Contact", "contact_id", $hybOperatorId);

  my $hybDate = $hybDateHashRef->{$assayName};
  my $description = $assayDescriptionHashRef->{$assayName};

  my $params = {
    array_id    => $arrayId,
    assay_date  => $hybDate,
    protocol_id => $hybProtocolId,
    operator_id => $hybOperatorId,
    name        => $assayName,
  };

  $params->{"array_batch_identifier"} = $batchId if ($batchId ne "null");
  $params->{"description"} = $description if ($description ne "");

  my $assay = GUS::Model::RAD3::Assay->new($params);

  $self->log("STATUS","OK Inserted 1 row in table RAD3.Assay for assay $assayName");

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

# gusAssayParams (or hyb params) are to be input via the Study Annotator website

###############################

sub createGusAcquisition {
  my ($self, $assayName, $modifiedImageFileURIRef, $scanDateHashRef) = @_;

  my $acqProtocolId = $self->{propertySet}->getProp("Acq_Protocol_ID");

  my $acqDate = $scanDateHashRef->{$assayName};
  my $channelDefs = {
    'Cy5' => "",   # HARD-CODED: select channel def from rad3.channel from your own instance
    'Cy3' => ""    # HARD-CODED: select channel def from rad3.channel from your own instance
  };

  my $protocolObject = GUS::Model::RAD3::Protocol->new({protocol_id => $acqProtocolId});
  $self->error("Create object failed: Table RAD3.Protocol, ID $acqProtocolId") 
   unless ($protocolObject->retrieveFromDB);
  my $protocolName = $protocolObject->getName();

  my $acquisitionCnt = 0;
  foreach my $channel (keys %$channelDefs) {

    my $channelObject = GUS::Model::RAD3::Channel->new({name => $channel});
    $self->error("Create object failed: Table RAD3.Channel, name $channel") 
     unless ($channelObject->retrieveFromDB);
    $channelDefs->{$channel} = $channelObject->getChannelId();

    my $acqName = "$assayName-$channel-".$protocolName;
    my $acqParameters = {
      name             => $acqName,
      channel_id       => $channelDefs->{$channel},
      protocol_id      => $acqProtocolId,
      acquisition_date => $acqDate,
      uri              => $modifiedImageFileURIRef->{$assayName."_$channel"}
    };

    $channelDefs->{$channel} = $acqParameters;
    $acquisitionCnt++;
  }

  my $acquisitionCy5 = GUS::Model::RAD3::Acquisition->new($channelDefs->{"Cy5"});
  my $acquisitionCy3 = GUS::Model::RAD3::Acquisition->new($channelDefs->{"Cy3"}); 

  $self->log("STATUS","OK Inserted $acquisitionCnt rows in table RAD3.Acquisition for Cy5 and Cy3 acquisitions");
 
 return ($acquisitionCy5, $acquisitionCy3);
}

###############################

# acquisitionParams are to be input via the Study Annotator website

###############################

sub createGusQuantification {
  my ($self, $assayName, $modifiedAssayFileURIRef, $GPRinfo) = @_;

  my (@gusQuantificationsCy5, @gusQuantificationsCy3);

  my $acqProtocolId   = $self->{propertySet}->getProp("Acq_Protocol_ID");
  my $quantOperatorId = $self->{propertySet}->getProp("Quant_Operator_ID");
  my $quantProtocolId = $self->{propertySet}->getProp("Quant_Protocol_ID");

  my $quantDate = $GPRinfo->{"DateTime"};
  my $gprURI = $modifiedAssayFileURIRef->{$assayName};

  my $protocolObject = GUS::Model::RAD3::Protocol->new({protocol_id => $acqProtocolId});
  $self->error("Create object failed: Table RAD3.Protocol, protocol_id $acqProtocolId") 
   unless ($protocolObject->retrieveFromDB);
  my $tempAcqName = $protocolObject->getName();

  my $gprQuantParameters = {
    protocol_id         => $quantProtocolId,
    quantification_date => $quantDate,
    uri                 => $gprURI
  };

  $gprQuantParameters->{operator_id} = $quantOperatorId if (defined $quantOperatorId);

  my $acqNameCy5                 = "$assayName-Cy5-$tempAcqName-Genepix quantification"; # HARD-CODED. Replace by your name if necessary.
  my $gprQuantParametersCy5      = $gprQuantParameters;
  $gprQuantParametersCy5->{name} = $acqNameCy5;
  my $gprQuantificationCy5       = GUS::Model::RAD3::Quantification->new($gprQuantParametersCy5);

  my $acqNameCy3                 = "$assayName-Cy3-$tempAcqName-Genepix quantification"; # HARD-CODED. Replace by your name if necessary.
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
  $self->checkDatabaseEntry("GUS::Model::RAD3::Protocol", "protocol_id", $quantProtocolId);

  my (@gusQuantParamsCy5, @gusQuantParamsCy3);
  my $quantParamKeywordCnt = 0;

  my $params = {
    'ratio formulations'         => 1,  # HARD-CODED. Replace by your RAD3.ProtocolParam.name.
    'standard deviation'         => 1,  # HARD-CODED. Replace by your RAD3.ProtocolParam.name.
    'background density measure' => 1,  # HARD-CODED. Replace by your RAD3.ProtocolParam.name.
    'software version'           => 1   # HARD-CODED. Replace by your RAD3.ProtocolParam.name.
  };

  foreach my $param (keys %$params) {

    my $protocolParamObject = GUS::Model::RAD3::ProtocolParam->new({
        protocol_id => $quantProtocolId,
        name        => $param
    });

    $self->error("Create object failed: Table RAD3.ProtocolParam, name $param")
      unless ($protocolParamObject->retrieveFromDB);

    my $quantParametersCy5 = GUS::Model::RAD3::QuantificationParam->new({
     name  => $param,
     value => $GPRinfo->{$param}
     });
    $quantParametersCy5->setParent($protocolParamObject); # protocolParam in only needed here, so set parent here
    push(@gusQuantParamsCy5, $quantParametersCy5);
    $quantParamKeywordCnt++;

    my $quantParametersCy3 = GUS::Model::RAD3::QuantificationParam->new({
     name  => $param,
     value => $GPRinfo->{$param}
     });
    $quantParametersCy3->setParent($protocolParamObject); # protocolParam in only needed here, so set parent here
    push(@gusQuantParamsCy3, $quantParametersCy3);
    $quantParamKeywordCnt++;
  }

  $self->log("STATUS","OK Inserted $quantParamKeywordCnt rows in table RAD3.QuantificationParam for Cy5 and Cy3 quantification parameters");

  return (\@gusQuantParamsCy5, \@gusQuantParamsCy3);
}

#################### END
