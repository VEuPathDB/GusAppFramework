package GUS::RAD::Plugin::GenePixStudyModuleILoader;

@ISA = qw( GUS::PluginMgr::Plugin);

use strict 'vars';
#use IO::File;
use Date::Manip;

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
    ["GPRFilePath", "",""],
    ["DATFilePath", "NOVALUEPROVIDED",""],
    ["Hyb_Protocol_ID", "",""],
    ["Acq_Protocol_ID", "",""],
    ["Cel_Protocol_ID", "",""],
    ["Chp_Protocol_ID", "",""],
    ["Hyb_Operator_ID", "",""],
    ["Cel_Quant_Operator_ID", "",""],
    ["Chp_Quant_Operator_ID", "",""],
    ["Study_ID", "",""],
    ["arrayId", "",""],
    ["batchId", "",""],
    ["hybDates", "",""],
    ["description", "",""],
    ["scanDate", "",""]
 ); 

###############################

sub run {
  my $self = shift;
    
  $self->logAlgInvocationId();
  $self->logCommit();
  $self->logArgs();

  $self->{propertySet} = CBIL::Util::PropertySet->new($self->getArg('cfg_file'), \@properties);

  my ($skipAssayCnt, $totalAssayCnt) = $self->createGUSAssaysFromFiles();
  print "skipped $skipAssayCnt, total $totalAssayCnt\n";


}

###############################

sub createGUSAssaysFromFiles {
  my ($self) = @_;

  my $testNumber = $self->getArgs->{testnumber};
  my @skipAssayList = @{$self->getArgs->{skip}};
  my $skipAssayCnt = scalar @skipAssayList;

  my $assayNames = $self->findAssayNames($self->{propertySet}->getProp("GPRFilePath"));
  my $totalAssayCnt = scalar @$assayNames;
  $self->log("STATUS","Found $totalAssayCnt assays");

  my (@gusAssays);
  my $assayCnt = 0;

  $self->log("STATUS","Skipping assay/s @skipAssayList") if (scalar @skipAssayList > 0);

  # ------------------- get hyb dates ---------------------------------------#

  my $hybDateHashRef;
  my @hybDates = split /\;/,$self->{propertySet}->getProp("hybDates");

  foreach my $hybDate (@hybDates) {
    #split /\|/;
    #print "hybdates: $1,$2 \n";
    my ($assayName,$date) = split /\|/,$hybDate;
    print "hybdates: $assayName,$date \n";
    $hybDateHashRef->{$assayName} = $date;
  }

  # ------------------- get hyb dates ---------------------------------------#

  foreach my $assayName (@$assayNames) {
    next if (($assayCnt > ($testNumber - 1)) && (defined $testNumber));
    next if (grep { $assayName =~ /^$_/ } @skipAssayList);
    my $gusAssay = $self->createSingleGUSAssay($assayName, $hybDateHashRef);
    push(@gusAssays, $gusAssay);
    $assayCnt++;
  }

  $self->log("STATUS","-------- End Assay Descriptions --------");
  $self->log("STATUS","OK Created $assayCnt assay/s");

  #return (\@gusAssays, $skipAssayCnt, $totalAssayCnt);
  return ($skipAssayCnt, $totalAssayCnt);
}


###############################

sub findAssayNames {
  my ($self,$assayNameFilesDir) = @_;

  my @assayNames;
  my $requiredExtension = "gpr";  # thes filenames correspond to assay names

  opendir (DIR,$assayNameFilesDir) || $self->userError("Cannot open dir $assayNameFilesDir");
  my @assayDir = readdir DIR; 
  close (DIR);

  $self->userError("Cannot create assays, directory $assayNameFilesDir is empty!") 
    if (scalar @assayDir eq 0); 

  foreach my $file (@assayDir) { 

    next if ($file eq '.' || $file eq '..'); # skip '.' and '..' files

    $file =~ /(.+)\.(\w+)/; # 

    next unless ($2); # skip files with no extension
    next if ($2 ne $requiredExtension); # skip files with diff extension

    push (@assayNames,$1);
  }
 
  return \@assayNames;
}

###############################

sub createSingleGUSAssay {
  my ($self, $assayName, $hybDateHashRef) = @_;

  $self->log("STATUS","----- Assay $assayName -----");

  $self->checkRequiredFilesExist($assayName);

  my $GPRinfo = $self->parseTabFile('GPR', $assayName);




  foreach my $some (keys %$GPRinfo) {
    my $value = $GPRinfo->{$some};
    print "$assayName: $some, $value \n";
  }

  my $gusAssay = $self->createGusAssay($assayName, $GPRinfo, $hybDateHashRef);


  my $gusCy5Acquisition = $self->createGusCy5Acquisition($assayName);
  print "gusCy5Acquisition $gusCy5Acquisition \n";
  $gusCy5Acquisition->setParent($gusAssay);

  my $gusCy3Acquisition = $self->createGusCy5Acquisition($assayName);
  print "gusCy5Acquisition $gusCy3Acquisition \n";
  $gusCy3Acquisition->setParent($gusAssay);


}

###############################

sub checkRequiredFilesExist {
  my ($self, $assayName) = @_;

  my $gprFile = $self->{propertySet}->getProp("GPRFilePath")."/$assayName.gpr";

  $self->userError("Missing file: $gprFile") if (! -e $gprFile); 
}

###############################

sub parseTabFile {
  my ($self, $prefix, $assayName) = @_;

  my $info;
  my $flag = 1;

  my $filePath = $self->{propertySet}->getProp("${prefix}FilePath");

  $prefix = "gpr" if ($prefix eq "GPR"); # quick fix
 
  my $file = "$filePath/$assayName.$prefix";

  open (FILE, $file) || $self->userError("Can't open $file: $!");
  while (<FILE>) {

    chomp $_;
    my ($key, $value);

    $flag = 0 if ($_ =~ /Block/);  # skip all lines after the 'Block' line

    next if ($flag eq 0); # skip lines not required
    next if (/^\s+$/);  # skip empty lines

    s/\r$//; # remove ^M at the end
    s/\"//g; # remove '"' in each line
    #next if (!($_ =~ m/\=/));

    my @keyValue = split /\=/,$_;
    my $key = $keyValue[0];

    if (defined $keyValue[1]) {
      $value = $keyValue[1]; 

    } else { 
      $value = "N/A"; 
    }

    $info->{$key} = $value;

  }

  close (FILE);

  return $info;
}

###############################

sub createGusAssay {
  my ($self, $assayName, $GPRinfo, $hybDateHashRef) = @_;


  #my $hybDate = $GPRinfo->{"DateTime"}; # hyb date comes from config file (see notes)
  #"DateTime"}; #  quantification date
  # $arrayId = config

  my $arrayId = $self->{propertySet}->getProp("arrayId");
  my $batchId = $self->{propertySet}->getProp("batchId");
  my $description = $self->{propertySet}->getProp("description");

  my $hybProtocolId = $self->{propertySet}->getProp("Hyb_Protocol_ID");
  my $hybOperatorId = $self->{propertySet}->getProp("Hyb_Operator_ID");

  my $hybDate = $hybDateHashRef->{$assayName};


  print "params: $arrayId, $batchId, $hybDate, $description, $hybProtocolId, $hybOperatorId\n";

  my $params = {
    array_id => $arrayId,
    assay_id => $hybDate,
    protocol_id => $hybProtocolId,
    operator_id => $hybOperatorId,
    name => $assayName,
    array_batch_identifier => $batchId,
    description => $description
  };

  my $assay = GUS::Model::RAD3::Assay->new($params);

  $self->log("STATUS","OK Inserted 1 row in table RAD3.Assay for assay $assayName");
  return $assay;

}


# gusAssayParams (or hyb params) are to be input via the Study Annotator website


sub createGusCy5Acquisition {
  my ($self, $assayName) = @_;

  my $datURI =          $self->{propertySet}->getProp("DATFilePath")."/$assayName".".DAT";
  my $acqProtocolId =   $self->{propertySet}->getProp("Acq_Protocol_ID");
  my $acqDate =        $self->{propertySet}->getProp("scanDate");

  my $protocol = GUS::Model::RAD3::Protocol->new({
    protocol_id => $acqProtocolId
  });

  $self->error("Create object failed, protocol ID $acqProtocolId absent in table RAD3::Protocol")
    unless ($protocol->retrieveFromDB);

  my $tempAcqName = $protocol->getName();
  my $acqName = "Cy5 $assayName".$protocol;

  my $acqParameters = {
    name => $acqName,
    acquisition_date => $acqDate,
    protocol_id => $acqProtocolId,
    channel_id => 3,
    uri => $datURI
  };


  my $Cy5Acquisition = GUS::Model::RAD3::Acquisition->new($acqParameters);

  $self->log("STATUS","OK Inserted 1 row in table RAD3.Acquisition for assay $assayName channel Cy5");
  return $Cy5Acquisition;
}

sub createGusCy3Acquisition {
  my ($self, $assayName) = @_;

  my $datURI =          $self->{propertySet}->getProp("DATFilePath")."/$assayName".".DAT";
  my $acqProtocolId =   $self->{propertySet}->getProp("Acq_Protocol_ID");
  my $acqDate =        $self->{propertySet}->getProp("scanDate");

  my $protocol = GUS::Model::RAD3::Protocol->new({
    protocol_id => $acqProtocolId
  });

  $self->error("Create object failed, protocol ID $acqProtocolId absent in table RAD3::Protocol")
    unless ($protocol->retrieveFromDB);

  my $tempAcqName = $protocol->getName();
  my $acqName = "Cy3 $assayName".$protocol;

  my $acqParameters = {
    name => $acqName,
    acquisition_date => $acqDate,
    protocol_id => $acqProtocolId,
    channel_id => 4,
    uri => $datURI
  };


  my $Cy3Acquisition = GUS::Model::RAD3::Acquisition->new($acqParameters);

  $self->log("STATUS","OK Inserted 1 row in table RAD3.Acquisition for assay $assayName channel Cy5");
  return $Cy3Acquisition;
}

# acquistionParams are to be input via the Study Annotator website


