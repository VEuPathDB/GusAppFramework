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
use GUS::Model::SRes::Contact;
use GUS::Model::RAD3::Channel;


sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  my $purposeBrief = 'Plugin is BatchLoader, creates assays, acquisitions and quantifications for Affymetrix assays in RAD3 tables.';
  
  my $purpose = <<PURPOSE; 
The plugin creates assays, acquisitions and quantifications for Affymetrix assays in RAD3 tables from multiple files in a batch mode, eliminating the need to load these files one by one. 
PURPOSE
  
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

=head2 F<Database requirements>

This plugin assumes that the following entries exist in your instance of the database:

1. The study in RAD3.Study

2. The appropriate Affymetrix array in RAD3.Array

3. The hybridization protocol, the acquisition protocol, the quantification protocol in RAD3.Protocol

4. For each of the protocol entries in 3, all of its parameters in RAD3.ProtocolParam

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
    ["EXPFilePath", "",""],
    ["RPTFilePath", "",""],
    ["CELFilePath", "",""],
    ["DATFilePath", "NOVALUEPROVIDED",""],
    ["MetricsFilePath", "",""],
    ["Hyb_Protocol_ID", "",""],
    ["Acq_Protocol_ID", "",""],
    ["Cel_Protocol_ID", "",""],
    ["Chp_Protocol_ID", "",""],
    ["Hyb_Operator_ID", "",""],
    ["Cel_Quant_Operator_ID", "",""],
    ["Chp_Quant_Operator_ID", "",""],
    ["Study_ID", "",""]
 ); 

###############################

sub run {
  my $self = shift;
    
  $self->logAlgInvocationId();
  $self->logCommit();
  $self->logArgs();

  my $startTime = `date`;
  $self->log("STATUS","Time now: $startTime");

  $self->{propertySet} = CBIL::Util::PropertySet->new($self->getArg('cfg_file'), \@properties);

  my ($gusAssays, $skippedAssayCnt, $totalAssayCnt)  = $self->createGUSAssaysFromFiles();
  my $gusInsertedAssayCnt                            = $self->submitGUSAssays($gusAssays);
  
  $self->setResultDescr(
   "Total assays: $totalAssayCnt; Assay/s inserted in DB: $gusInsertedAssayCnt; Skipped assay/s: $skippedAssayCnt"
  );
}

###############################

sub createGUSAssaysFromFiles {
  my ($self) = @_;

  my $assayNames =    $self->findAssayNames($self->{propertySet}->getProp("EXPFilePath"));
  my $testNumber =    $self->getArgs->{testnumber};
  my @skipAssayList = @{$self->getArgs->{skip}};

  my $skipAssayCnt = scalar @skipAssayList;
  my $totalAssayCnt = scalar @$assayNames;

  $self->log("STATUS","Found $totalAssayCnt assays");

  my @gusAssays;
  my $assayCnt = 0;

  $self->log("STATUS","Skipping assay/s @skipAssayList") if (scalar @skipAssayList > 0);

  foreach my $assayName (@$assayNames) {

    next if (($assayCnt > ($testNumber - 1)) && (defined $testNumber));
    next if (grep { $assayName =~ /^$_/ } @skipAssayList);
    my $gusAssay = $self->createSingleGUSAssay($assayName);
    push(@gusAssays, $gusAssay);
    $assayCnt++;
  }

  $self->log("STATUS","-------- End Assay Descriptions --------");
  $self->log("STATUS","OK   Created $assayCnt assay/s");

  return (\@gusAssays, $skipAssayCnt, $totalAssayCnt);
}

###############################

sub submitGUSAssays {
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

sub findAssayNames {
  my ($self,$assayNameFilesDir) = @_;

  my (@assayNames, @assayDir);
  my $requiredExtension = "EXP";                          # EXP filenames correspond to assay names

  opendir (DIR,$assayNameFilesDir) || $self->userError("Cannot open dir $assayNameFilesDir");
  @assayDir = readdir DIR; 
  close (DIR);

  $self->userError("Cannot create assays, directory $assayNameFilesDir is empty!") 
    if (scalar @assayDir eq 0); 

  foreach my $file (@assayDir) { 

    next if ($file eq '.' || $file eq '..');              # skip '.' and '..' files

    my ($fileName, $extension) = $file =~ /(.+)\.(\w+)/;
    next unless ($extension);                             # skip files with no extension
    next if ($extension ne $requiredExtension);           # skip files with diff extension

    push (@assayNames,$1);
  }
 
  return \@assayNames;
}

###############################

sub createSingleGUSAssay {
  my ($self, $assayName) = @_;

  $self->log("STATUS","----- Assay $assayName -----");

  $self->checkRequiredFilesExist($assayName);

  my ($EXPinfo, $EXPfluidicsInfo) = $self->parseTabFile('EXP', $assayName);
  my ($RPTinfo, $RPTfluidicsInfo) = $self->parseTabFile('RPT', $assayName);
  
  my $gusAssay = $self->createGusAssay($assayName, $EXPinfo);
  my $gusAssayParams = $self->createGusAssayParams($EXPinfo, $EXPfluidicsInfo);
  foreach my $gusAssayParam (@$gusAssayParams) { 
    $gusAssayParam->setParent($gusAssay); 
  }
  
  my $gusAcquisition = $self->createGusAcquisition($assayName, $EXPinfo);
  $gusAcquisition->setParent($gusAssay);

  my $gusAcquistionParamsRef = $self->createGusAcquisitionParams($EXPinfo);
  foreach my $gusAcquisitionParam (@$gusAcquistionParamsRef) { 
    $gusAcquisitionParam->setParent($gusAcquisition); 
  }
  
  my $gusQuantificationsRef = $self->createGUSQuantification($assayName);
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
  my ($self, $assayName) = @_;

  my $expFile =     $self->{propertySet}->getProp("EXPFilePath")."/$assayName.EXP";
  my $rptFile =     $self->{propertySet}->getProp("RPTFilePath")."/$assayName.RPT";
  my $celFile =     $self->{propertySet}->getProp("CELFilePath")."/$assayName.CEL";
  my $datFile =     $self->{propertySet}->getProp("DATFilePath")."/$assayName.DAT";
  my $metricsFile = $self->{propertySet}->getProp("MetricsFilePath")."/$assayName"."_Metrics.txt";

  $self->userError("Missing file: $rptFile") if ( ! -e $rptFile ); 
  $self->userError("Missing file: $celFile") if ( ! -e $celFile );

  $self->userError("Missing file: $datFile for assay $assayName") 
   if (( ! -e $datFile ) && ($self->{propertySet}->getProp("DATFilePath") ne "NOVALUEPROVIDED"));

  $self->userError("Missing file: $metricsFile") if ( ! -e $metricsFile );
  $self->userError("Empty file: $expFile") if ( -z $expFile ); 
  $self->userError("Empty file: $rptFile") if ( -z $rptFile ); 

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

  my $arrayName =         $EXPinfo->{"Chip Type"};
  my $batchId =            $EXPinfo->{"Chip Lot"}; 
  my $description =        $EXPinfo->{"Description"}; 
  my $hybDate =            $EXPinfo->{"Hybridize Date"};
  my $hybProtocolId =   $self->{propertySet}->getProp("Hyb_Protocol_ID");
  my $hybOperatorId =    $self->{propertySet}->getProp("Hyb_Operator_ID");
  
  my $arrayIdParams;

  if ($arrayName =~ /^(\S+)(v\d)$/) {  # eg: MG_U74Av2, where version may/may-not be included
    $arrayIdParams = GUS::Model::RAD3::Array->new({
      name => "Affymetrix $1",
      version => $2
    });

  } else {
    $arrayIdParams = GUS::Model::RAD3::Array->new({
      name => "Affymetrix $arrayName",
      version => "null"
    });
  }

  $self->error("Create object failed, array name $arrayName absent in table RAD3::Array") 
    unless ($arrayIdParams->retrieveFromDB);

  my $arrayId = $arrayIdParams->getArrayId();

  my $params = {
    array_id => $arrayId, 
    protocol_id => $hybProtocolId, 
    operator_id => $hybOperatorId, 
    name => $assayName,
    array_batch_identifier => $batchId, 
    description => $description
  };
  
  $params->{assay_date} = $self->modifyDate($hybDate) if ($hybDate);

  my $assay = GUS::Model::RAD3::Assay->new($params);

  $self->log("STATUS","OK   Inserted 1 row in table RAD3.Assay");
  return $assay;
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
        name => $key
    });
 
    $self->error("Create object failed, protocol ID $hybProtocolId or name $key absent in table RAD3::ProtocolParam") 
        unless ($protocolParam->retrieveFromDB);
    
    my $protocolParamId = $protocolParam->getProtocolParamId();

    my $assayParam = GUS::Model::RAD3::AssayParam->new({
        protocol_param_id => $protocolParamId, 
        value => $value
    }); 
    $fluidicsKeywordCnt++;
    push (@gusAssayParams, $assayParam);
  }

  $self->log("STATUS","OK   Inserted $fluidicsKeywordCnt rows in table RAD3.AssayParam");
  return \@gusAssayParams;
}

###############################

sub createGusAcquisition {
  my ($self, $assayName, $EXPinfo) = @_;

  my $datURI =          $self->{propertySet}->getProp("DATFilePath")."/$assayName".".DAT";
  my $acqProtocolId =   $self->{propertySet}->getProp("Acq_Protocol_ID");
  my $scanDate =        $EXPinfo->{"Scan Date"};

  my $channelDef =      "biotin";  # HARD-CODED: select channel def from rad3.channel from your own instance

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
    name => $acqName, 
    protocol_id => $acqProtocolId, 
    channel_id => $channelId,
    uri => $datURI
  };
    
  $acqParameters->{acquisition_date} = $self->modifyDate($scanDate) if ($scanDate);

  my $acquisition = GUS::Model::RAD3::Acquisition->new($acqParameters);

  $self->log("STATUS","OK   Inserted 1 row in table RAD3.Acquisition");
  return $acquisition;
}

###############################

sub createGusAcquisitionParams {
  my ($self, $EXPinfo) = @_;

  my %params = (
    'Pixel Size'=>1,        # WARNING. The plugin assumes this is your RAD3.ProtocolParam.name for 'Pixel Size'.
    'Filter'=>1,            # WARNING. The plugin assumes this is your RAD3.ProtocolParam.name for 'Filter'.
    'Number of Scans'=>1,   # WARNING. The plugin assumes this is your RAD3.ProtocolParam.name for 'Number of Scans'.
  );

  my $acqProtocolId = $self->{propertySet}->getProp("Acq_Protocol_ID");

  my @gusAcquisitionParams;
  my $acqParamKeywordCnt = 0;

  foreach my $param (keys %params) {

    my $protocolParam = GUS::Model::RAD3::ProtocolParam->new({
        protocol_id => $acqProtocolId, 
        name => "$param"
    });

    $self->error("Create object failed, parameter $param absent in table RAD3::ProtocolParam") 
        unless ($protocolParam->retrieveFromDB);

    my $acquisitionParamId = $protocolParam->getProtocolParamId();
    my $acquisitionParam = GUS::Model::RAD3::AcquisitionParam->new({
        protocol_param_id => $acquisitionParamId, 
        name => $param, 
        value => $EXPinfo->{$param} 
    });

    $acqParamKeywordCnt++;
    push (@gusAcquisitionParams,$acquisitionParam);
  }

  $self->log("STATUS","OK   Inserted $acqParamKeywordCnt rows in table RAD3.AcquisitionParam");
  return \@gusAcquisitionParams;
}

###############################

sub createGUSQuantification {
  my ($self, $assayName) = @_;
  my (@gusQuantifications, $celQuantification, $chpQuantification);


  my $celURI =             $self->{propertySet}->getProp("CELFilePath")."/$assayName".".CEL";
  my $chpURI =             $self->{propertySet}->getProp("MetricsFilePath")."/$assayName"."_Metrics.txt";
  my $acqProtocolId =      $self->{propertySet}->getProp("Acq_Protocol_ID");
  my $celProtocolId =      $self->{propertySet}->getProp("Cel_Protocol_ID");
  my $chpProtocolId =      $self->{propertySet}->getProp("Chp_Protocol_ID");
  my $celQuantOperatorId = $self->{propertySet}->getProp("Cel_Quant_Operator_ID");
  my $chpQuantOperatorId = $self->{propertySet}->getProp("Chp_Quant_Operator_ID");

  my $protocol = GUS::Model::RAD3::Protocol->new({protocol_id => $acqProtocolId});

  $self->error("Create object failed, $acqProtocolId absent in table RAD3::Protocol") 
    unless ($protocol->retrieveFromDB);

  my $tempAcqName = $protocol->getName();
  my $acqName = $assayName."-Biotin-".$tempAcqName;

  my $celQuantParameters = {
    protocol_id => $celProtocolId, 
    name => $acqName."-Affymetrix Probe Cell Analysis", 
    uri => $celURI
  }; 

  my $chpQuantParameters = {
    protocol_id => $chpProtocolId,
    name => $acqName."-Affymetrix MAS5 Absolute Expression Analysis", 
    uri => $chpURI
  };

  $celQuantParameters->{operator_id} = $celQuantOperatorId if ( defined $celQuantOperatorId );
  $chpQuantParameters->{operator_id} = $chpQuantOperatorId if ( defined $chpQuantOperatorId );

  my $celQuantification = GUS::Model::RAD3::Quantification->new($celQuantParameters);
  my $chpQuantification = GUS::Model::RAD3::Quantification->new($chpQuantParameters);

  push (@gusQuantifications, $celQuantification, $chpQuantification);

  $self->log("STATUS","OK   Inserted 2 rows in table RAD3.Quantification for CEL & CHP quantification");
  return \@gusQuantifications;
}

###############################

sub createGUSQuantParams {
  my ($self, $RPTinfo) = @_;

  my $params = {
    'Alpha1'=>1,  # WARNING. The plugin assumes this is your RAD3.ProtocalParam.name for 'Alpha1'.
    'Alpha2'=>1,  # WARNING. The plugin assumes this is your RAD3.ProtocalParam.name for 'Alpha2'.
    'Tau'=>1,     # WARNING. The plugin assumes this is your RAD3.ProtocalParam.name for 'Tau'.
    'TGT'=>1,     # HARD-CODED. Replace 'TGT' by your RAD3.ProtocolParam.name for 'TGT Value'.
    'SF'=>1       # HARD-CODED. Replace 'SF' your RAD3.ProtocolParam.name for 'Scale Factor (SF)'.
  };

  # Note: 
  # 'TGT' in RAD is represented as 'TGT Value' in .RPT files.
  # 'SF' in RAD is represented as 'Scale Factor (SF)' in .RPT files. 

  my $chpProtocolId = $self->{propertySet}->getProp("Chp_Protocol_ID");

  my @gusQuantParams;
  my $quantParamKeywordCnt = 0;

  foreach my $param (keys %$params) {

    my $protocolParam = GUS::Model::RAD3::ProtocolParam->new({
      protocol_id => $chpProtocolId, 
      name => $param
    });

    $self->error("Create object failed, name $param absent in table RAD3::ProtocolParam")
      unless ($protocolParam->retrieveFromDB);

    my $quantParameters = GUS::Model::RAD3::QuantificationParam->new({name => $param});

    if ($param eq "TGT") {   # HARD-CODED. Replace 'TGT' by your RAD3.ProtocolParam.name for 'TGT Value'.
      $quantParameters->{value} = $RPTinfo->{"TGT Value"}; 
    } elsif ($param eq "SF") {    # HARD-CODED. Replace 'SF' your RAD3.ProtocolParam.name for 'Scale Factor (SF)'.
      $quantParameters->{value} = $RPTinfo->{"Scale Factor (SF)"}; 
    } else {
      $quantParameters->{value} = $RPTinfo->{$param};
    }
    
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
    $finalTime = $hourMinArray[0] + 12;
    $finalTime .= ":$hourMinArray[1]:00";

  } else {
    $finalTime = "$tempTime:00";
  }

  my $monthNum = $monthHash{$dateArray[0]};
  my $finalDateTime = "$dateArray[2]-$monthNum-$dateArray[1]". " $finalTime";

  return $finalDateTime;
}
