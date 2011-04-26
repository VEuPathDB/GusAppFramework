package GUS::Community::Plugin::InsertGenericRadAssaysAndBioSamples;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
use GUS::PluginMgr::Plugin;

use GUS::Model::Study::Study;

use GUS::Model::RAD::Assay;
use GUS::Model::RAD::StudyAssay;
use GUS::Model::RAD::Acquisition;
use GUS::Model::RAD::Quantification;
use GUS::Model::RAD::RelatedAcquisition;
use GUS::Model::RAD::RelatedQuantification;
use GUS::Model::RAD::StudyBioMaterial;
use GUS::Model::RAD::AssayBioMaterial;
use GUS::Model::RAD::AssayLabeledExtract;
use GUS::Model::RAD::Treatment;
use GUS::Model::RAD::BioMaterialMeasurement;

use GUS::Model::Study::BioSource;
use GUS::Model::Study::BioSample;
use GUS::Model::Study::LabeledExtract;


use FileHandle;
use Data::Dumper;

my $purposeBrief = <<PURPOSE_BRIEF;
Load rows in RAD corresponding to ModuleI and ModuleIII of the RADSA Forms.
PURPOSE_BRIEF

my $purpose = <<PLUGIN_PURPOSE;
Load rows in RAD corresponding to ModuleI and ModuleIII of the RADSA Forms.  This plugin is generic but will not work for every possible case imaginable.  See NOTES for when appropriate to use this plugin and for what will and will not be loaded.
PLUGIN_PURPOSE

my $tablesAffected = [ ['RAD::Assay', 'One Row for each row of Tab Data file'],
                       ['RAD::StudyAssay', 'Linking table'],
                       ['RAD::Acquisition', 'At least one row for each row of Tab Data File'],
                       ['RAD::Quantification', 'At least one row for each row of Tab Data File'],
                       ['RAD::RelatedAcquisition', 'Acquisitions are related automatically if needed'],
                       ['RAD::RelatedQuantification', 'There is a boolean Arg for Relating Quantifications'],
                       ['RAD::StudyBioMaterial', 'Linking table'],
                       ['RAD::AssayBioMaterial', 'Linking table'],
                       ['RAD::AssayLabeledExtract', 'Linking table'],
                       ['RAD::Treatment', 'One row for each protocol step'],
                       ['RAD::BioMaterialMeasurement', 'One row for each protocol step'],
                       ['Study::BioSource', 'One row for each initial biomaterial'],
                       ['Study::BioSample', 'The number populated depends on the number of previous biomaterials'],
                       ['Study::LabeledExtract', 'The number populated depends on the number of previous biomaterials.  Must match the number expected from tab file'],
                     ];

my $tablesDependedOn =[ ['RAD::Study', 'Study provided as Arg must exist'],
                        ['SRes::Contact', 'Used for BioSource Provider'],
                        ['Study::OntologyEntry', 'Used multiple times'],
                        ['RAD::Protocol', 'Protocol ids taken from config file'] ];

my $howToRestart = <<PLUGIN_RESTART;
This plugin has no restart facility.
PLUGIN_RESTART

my $failureCases = <<PLUGIN_FAILURE_CASES;
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
=pod

=head2 DISCLAIMER

This plugin will NOT handle all the possible variations which the RAD schema can handle.  The plugin takes a data files which contains several ids.  Care must be taken to ensure these are correct or will mess up downstream (ie dataloading).  The plugin does minimal checking to ensure values are not null (ie. if you don't want a value to be null, make sure to fill in the column of the data file).  If you are doing something very complex, you will probably be better off using the RADSA.  

=head1 TAB_DATA_FILE

File which contains the "ModuleI" data to be loaded.  All Column Headers must exist or the plugin will die.  The order of the columns doesn't matter and neither does case.  Please note the following:

=over 4

=item *

The Header is checked but the values are not...ex. assay_operator_id is required by the db schema but currently it is not checked for in the plugin.  (If you leave it null the plugin will fail with an sql error)

=item *

Any date must be in the format "yyyy-mm-dd' ex: 2004-10-04

=item *

acquisition_fn can be a comma separated list and is also used to find the study.ontologyentry.ontology_entry_id of the "channel" ie the channel_id.  ie. image files (if they exist) should follow the following naming convention:  "name_channel.ext" where channel is a study.ontologyEntry value of category "LabelCompound'.  If there is no image file then the just list the channel used...ex:  1054512_Cy3.tif,1054512_Cy5.tif or just Cy3,Cy5 or just biotin.

=item *

quantification_fn can be a comma delimeted list but each will point to each of the acquisitions.  most common examples are:

=over 2

=item 1

"biotin" as the one acquisitoin_fn and one or more quantification files pointing to the one aquisition

=item 2

"Cy3" and "Cy5" as two acquisition_fn's and one quantification_fn pointing to both of them.  This will create 2 Rad.Quantifications (one for each channel)

=back

=item *

cel_fn and cel_protocol_id are only applicable to affymetrix experiments and will also point to each acquisition


=back

=head1 PROTOCOL_FILE

This is a machine readable config file.  It's SeriesName is used to link to the PROTOCOL_SERIES_NM in the Data file.  The data file is read first, and the number of LabeledExtracts created will be equal to the number counted from that file.  It has  the following format:

 ---------------------------
 TaxonName=
 Provider=
 SeriesName=
 BioSourceNumber=
 LabelMethodId=
 Name|MaterialType|Description=

 Protocol|Number=
 Name|MaterialType|Description=

 ...

 next
 --------------------------

=over 4

=item *

The Last Protocol in the Series must be a labeling protocol.

=item *

TaxonScientificName is a Study.OntologyEntry.value

=item *

Provider is an SRes.Contact.name

=item *

Series Name is required and has to match the PROTOCOL_SERIES_NM from the Tab data file

=item *

Protocol_Id|Number=Rad.Protocol.protocol_id|integer...the integer should only be included when the protocol_id is splitting or pooling.  It is the number of BioSamples resulting from the split or pool.

=item *

Name|MaterialType|Description... No Restrictions on Name or Description (Check db schema for number of characters allowed).  The MaterialType is a Study.OntologyEntry.value with a category of 'MaterialType'

=item *

The last "next" is optional

=item *

There are a few checks done when parsing this file... You cannot list 2 "Protocol_Id|Number"'s consecutively nor can you list 2 "Name|MaterialType|Description"'s consecutively.  

=item *

The order of TaxonScientificName, Provider, and SeriesName are unimportant.  You must include a "SeriesName".

=back

=cut

PLUGIN_NOTES

my $documentation = { purpose          => $purpose,
		      purposeBrief     => $purposeBrief,
		      tablesAffected   => $tablesAffected,
		      tablesDependedOn => $tablesDependedOn,
		      howToRestart     => $howToRestart,
		      failureCases     => $failureCases,
		      notes            => $notes
		    };

my $expectedNames = [ "ASSAY_DATE",  "ARRAY_IDENTIFIER", "ASSAY_OPERATOR_ID", "ASSAY_DESCRIPTION", 
                      "ARRAY_DESIGN_ID", "ASSAY_PROTOCOL_ID", "ASSAY_NAME", "ACQUISITION_PROTOCOL_ID", 
                      "ACQUISITION_DATE","ACQUISITION_FN", "QUANTIFICATION_OPERATOR_ID", 
                      "QUANTIFICATION_DATE", "QUANTIFICATION_PROTOCOL_ID", "RESULT_TABLE_ID",
                      "QUANTIFICATION_FN", "CEL_PROTOCOL_ID", "CEL_FN", "PROTOCOL_SERIES_NM" ];

my $printExpectedNames = join("\|", @$expectedNames) . "\n";

my $argsDeclaration =  
  [
   fileArg({name           => 'DataFile',
            descr          => 'Tab delimeted File containing Data.  See NOTES',
            reqd           => 1,
            mustExist      => 1,
            format         => $printExpectedNames,
            constraintFunc => undef,
            isList         => 0, 
           }),

   fileArg({name           => 'BioMaterialFile',
            descr          => 'Tab delimeted File containing Protocols in an Ordered way.  See NOTES',
            reqd           => 1,
            mustExist      => 1,
            format         => 'see NOTES',
            constraintFunc => undef,
            isList         => 0, 
           }),

   stringArg({descr => 'The QuantUri is a partial path to the directory data files are stored.  See NOTES',
              name  => 'QuantUri',
              isList    => 0,
              reqd  => 1,
              constraintFunc => undef,
             }),

   stringArg({descr => 'The QuantUri is a partial path to the quant directory.  See NOTES',
              name  => 'QuantDirPrefix',
              isList    => 0,
              reqd  => 0,
              default => "/files/cbil/data/cbil/RAD/",
              constraintFunc => undef,
             }),

   stringArg({descr => 'The AcquUri is a partial path to directory image files are stored.  See NOTES',
              name  => 'AcquUri',
              isList    => 0,
              reqd  => 0,
              constraintFunc => undef,
             }),

   stringArg({ descr => 'The AcquUri is a partial path to the quant directory.  See NOTES',
               name  => 'AcquDirPrefix',
               isList    => 0,
               reqd  => 0,
               default => "/files/cbil/data/cbil/RAD_images/",
               constraintFunc => undef,
             }),

   integerArg({name => 'StudyId',
               descr => 'Study.Study.study_id which will be linked to assays and biomaterials',
               reqd => 1,
               constraintFunc => undef,
               isList => 0
              }),

   booleanArg ({name => 'RelateQuantifications',
                descr => 'Acquisitions are always related automatically... see notes ',
                reqd => 0,
                default => 0
               }),


                       ];

# ----------------------------------------------------------------------

sub new {
  my ($class) = @_;
  my $self    = {};
  bless($self,$class);

  $self->initialize({requiredDbVersion => 3.6,
                     cvsRevision       => '$Revision$',
                     name              => ref($self),
                     argsDeclaration   => $argsDeclaration,
                     documentation     => $documentation
                    });

  return $self;
}

# ----------------------------------------------------------------------

sub run {
  my ($self) = @_;

  my $studyId = $self->getArgs()->{StudyId};

  my $study = GUS::Model::Study::Study->new({ study_id => $studyId });
  die "Could not retrieve StudyId from DB" unless($study->retrieveFromDB());

  my ($protocolCounts, $colNames) = $self->_readTabFile();

  my $radProtocols = $self->_readBioMaterialFile();

  my $linkingNameToLexHash = $self->_makeBioMaterials($protocolCounts, $radProtocols, $study);

  my $fn = $self->getArgs()->{DataFile};
  open(FILE, $fn) || die "Cannot open file $fn for reading: $!";

  <FILE>; #remove the header
  while(<FILE>) {
    chomp;

    my %data;
    my @row = split(/\t/, $_);

    for(my $i; $i < scalar(@$colNames); $i++) {
      my $cn = $colNames->[$i];
      $cn =~ tr/[A-Z]/[a-z]/;

      $data{$cn} = $row[$i];
    }

    my $assay = $self->_makeAssay(\%data, $study);
    $assay->submit();

    $self->_relateAcquisitionsAndQuantifications(\%data, $assay);

    if($self->getArgs->{commit}) {
      $self->_linkAssayToLex($assay, $linkingNameToLexHash, $data{protocol_series_nm}, $studyId);
    }
    $self->undefPointerCache();
  }
  close(FILE);

  $self->_printSummary();
  return("Inserted AssayToBioMaterial rows for studyId $studyId");
}

# ----------------------------------------------------------------------
=pod

=head2 Subroutines

=over 4

=item C<_getProtocolCounts >

Initial Read of the Tab file... counts the number of protocol_series_nm's 
and gets the column headers.  Checks the column headers of the tab file
against expected.

B<Return type:> C<array> 

First element if a hashref (key=protocol_series_nm, value=number from tab file) and the
second element is the column headers found in the tab file.

=cut

sub _readTabFile {
  my ($self) = @_;

  my %protocolCounts;

  my $fn = $self->getArgs()->{DataFile};

  open(FILE, $fn) || die "Cannot open file $fn for reading: $!";

  my $header = <FILE>;
  chomp($header);
  my @colNames = split(/\t/, $header);

  $self->_checkHeaderRow(\@colNames);

  my $index;
  for(my $i = 0; $i < scalar(@colNames); $i++) {
    $index = $i if($colNames[$i] =~ /PROTOCOL_SERIES_NM/i);
  }
  while(<FILE>) {
    chomp;

    my @ar = split(/\t/, $_);
    my @protocolNames = split(',', $ar[$index]);

    foreach my $protocolName (@protocolNames) {
      $protocolCounts{$protocolName}++;
    }
  }
  close(FILE);

  return(\%protocolCounts, \@colNames);
}

# ----------------------------------------------------------------------
=pod

=item C<_readBioMaterialFile>

Parse the BioMaterial file into a data structure

B<Return type:> C<arrayref> 

List of _RadProtocol objects

=cut

sub _readBioMaterialFile {
  my ($self) = @_;

  my $fn = $self->getArgs()->{BioMaterialFile};

  open(FILE, $fn) || die "Cannot open file $fn for reading: $!";

  my (@rv, $i);
  push(@rv, _RadProtocol->new({ }));

  my $seenProt = -1;
  my ($wasBioPrev, $protocolName, $treatmentProtocolId);

  while(<FILE>) {
    chomp;
    next if(!$_);
    next if(/^#/);

    my ($id, $val) = split('=', $_);

    if($id eq 'TaxonName') {
      my $sql = "select distinct taxon_id from SRes.TaxonName where name = '$val'";
      my ($tId) = $self->sqlAsArray( Sql => $sql );

      $rv[$i]->setTaxonId($tId);
    }
    elsif($id eq 'LabelMethodId') {
      $rv[$i]->setLabelMethodId($val);
    }
    elsif($id eq 'ProviderName') {
      my $sql = "select contact_id from SRes.Contact where name = '$val'";
      my ($pId) = $self->sqlAsArray(Sql => $sql );

      $rv[$i]->setProviderId($pId);
    }
    elsif($id eq 'SeriesName') {
      $rv[$i]->setName($val);
    }
    elsif($id eq 'BioSourceNumber') {
      $rv[$i]->setBioMaterialNumber($val);
    }
    elsif($id eq 'next') {
      if(!$wasBioPrev || !$rv[$i]->getBioMaterialNumber() || !$rv[$i]->getName()) {
        die "Error in protocol file on line: $_";
      }
      push(@rv, _RadProtocol->new({ }));

      $i++;
      $seenProt = -1;
      $wasBioPrev = 0;
      $protocolName = undef;
      $treatmentProtocolId = undef;
    }
    elsif($id eq 'Protocol|Number') {
      die "Error in protocol file on line: $_" if(!$wasBioPrev);
      my ($p, $n) = split(/\|/, $val);

      my $sql = "select protocol_id from Rad.Protocol where name = '$p'";
      ($seenProt) = $self->sqlAsArray(Sql => $sql );

      $sql = defined($seenProt) 
        ? "select oc.ontology_entry_id from Rad.Protocol p, Study.ONTOLOGYENTRY op, Study.ONTOLOGYENTRY oc where op.ontology_entry_id = p.protocol_type_id and oc.value = op.value and oc.category = 'ComplexAction' and p.protocol_id = $seenProt"
          : "select ontology_entry_id from Study.OntologyEntry where value = '$p' and category = 'ComplexAction'";

      ($treatmentProtocolId) = $self->sqlAsArray(Sql => $sql);
      $protocolName = $p;
      $seenProt = $seenProt . "|" . $n;
      $wasBioPrev = 0;
    }
    elsif($id eq 'Name|MaterialType|Description') {
      die "Error in protocol file on line: $_" if($wasBioPrev);
      $wasBioPrev = 1;

      my $step = { protocol_id => $seenProt, bm_name => $val, protocol_nm => $protocolName, treatment_type_id => $treatmentProtocolId};
      my ($bmName, $mt, $bmDescription) = split(/\|/, $step->{bm_name});

      my $sql = "select ontology_entry_id from study.ontologyEntry where value = '$mt' and category = 'MaterialType'";
      my ($oeId) = $self->sqlAsArray(Sql => $sql );

      $rv[$i]->addProtocolStep($step, $oeId);
    }
    else {
      die "Error in protocol file:  Id $id undefined on line $_";
    }
  }
  if($seenProt == -1) {
    die "Error in protocol file:  No data to parse: $!" if(!@rv);
    pop(@rv);
  }
  return(\@rv);
}

#=======================================================================
=pod

=head2 Internal Class

=item C<_RadProtocol>

Data structure for storing protocols

=cut

package _RadProtocol;

sub new {
         my $Class = shift;
         my $Args  = shift;

         bless $Args, $Class;
}

sub getName                    { $_[0]->{name} }
sub setName                    { $_[0]->{name} = $_[1] }

sub getBioMaterialNumber       { $_[0]->{bio_source_number} }
sub setBioMaterialNumber       { $_[0]->{bio_source_number} = $_[1] }

sub getTaxonId                 { $_[0]->{taxon_id} }
sub setTaxonId                 { $_[0]->{taxon_id} = $_[1] }

sub getProviderId              { $_[0]->{provider_id} }
sub setProviderId              { $_[0]->{provider_id} = $_[1] }

sub getProtocolId              { $_[0]->{protocol_id} }
sub setProtocolId              { $_[0]->{protocol_id} = $_[1] }

sub getProtocolNm              { $_[0]->{protocol_name} }
sub setProtocolNm              { $_[0]->{protocol_name} = $_[1] }

sub getLabelMethodId           { $_[0]->{label_method_id} }
sub setLabelMethodId           { $_[0]->{label_method_id} = $_[1] }

sub getMaterialType            { $_[0]->{material_type} }
sub setMaterialType            { $_[0]->{material_type} = $_[1] }

sub getDescription             { $_[0]->{description} }
sub setDescription             { $_[1]->{description} = $_[1] }

sub getMaterialTypeOntologyId  { $_[0]->{material_type_ontology_id} }
sub setMaterialTypeOntologyId  { $_[0]->{material_type_ontology_id} = $_[1] }

sub getTreatmentTypeId         { $_[0]->{treatment_type_id} }

sub getProtocolSeries          { $_[0]->{protocol_series} }

sub addProtocolStep {
  my ($self, $step, $oeId) = @_;

  if(!$self->getProtocolSeries()) {
    $self->{protocol_series} = [];
  }

  if(!$step->{protocol_id} || !$step->{bm_name}) {
    die "A Protocol Step must specifiy both: protocol_id and bm_name";
  }
  my ($pId, $n) = split(/\|/, $step->{protocol_id});

  if($step->{protocol_id} == -1) {
    $n = $self->getBioMaterialNumber();
  }
  die "Each Protocol Must also provide The number of Output BioMaterials" if(!$n);

  my ($bmName, $matType, $bmDescription) = split(/\|/, $step->{bm_name});

  my $protocolStep = _RadProtocol->
    new({ protocol_id => $pId,
          bio_source_number => $n,
          name => $bmName,
          description => $bmDescription,
          material_type_ontology_id => $oeId,
          material_type => $matType,
          protocol_name => $step->{protocol_nm},
          treatment_type_id => $step->{treatment_type_id},
        });

  push(@{$self->getProtocolSeries()}, $protocolStep);

  return $self;
}

#=======================================================================

package GUS::Community::Plugin::InsertGenericRadAssaysAndBioSamples;

# ----------------------------------------------------------------------
=pod

=item C<_makeBioMaterials>

Creates Study.BioSource, Study.BioSample, and Study.LabeledExtract objects.

B<Parameters:>

$protocolCounts(hashRef): How many LEX for each protocol_series_nm
$radProtocols(arrayRef): List of _RadProtocol Objects
$study(GUS::Model::Study::Study):  study object

B<Return type:> C<void> 

=cut

sub _makeBioMaterials {
  my ($self, $protocolCounts, $radProtocols, $study) = @_;

  my %rv;

  foreach my $protocol (@$radProtocols) {
    my $linkingName = $protocol->getName();

    if(!exists($protocolCounts->{$linkingName})) {
      die "Protocol $linkingName not found in data file";
    }

    my $protocolSeries = $protocol->getProtocolSeries();

    my $prevBioMaterials = [];
    for(my $i = 0; $i < scalar(@$protocolSeries); $i++) {

      if($i == 0) {
        $prevBioMaterials = $self->_makeBioSources($protocol, $protocolSeries->[$i], $study);
      }

      elsif($i == scalar(@$protocolSeries) - 1) {
        my $expectedLabelMethodId = $protocol->getLabelMethodId();
        my $labeledExtracts = $self->_makeLabeledExtracts($protocolSeries->[$i], $prevBioMaterials, $expectedLabelMethodId, $study);

        push(@{$rv{$linkingName}}, @$labeledExtracts);
      }

      else {
        $prevBioMaterials = $self->_makeBioSamples($protocolSeries->[$i], $prevBioMaterials, $study);
      }
    }
  }
  return(\%rv);
}

# ----------------------------------------------------------------------

sub _makeBioSources {
  my ($self, $protocol, $step, $study) = @_;

  my $n = $step->getBioMaterialNumber();
  my @rv;

  foreach(1..$n) {
    my $nm = $step->getName() . " $_";

    print STDERR "Working on BioSource $nm\n";

    my $biosource = GUS::Model::Study::BioSource-> 
      new({ taxon_id => $protocol->getTaxonId(),
            bio_source_provider_id => $protocol->getProviderId(),
            bio_material_type_id => $step->getMaterialTypeOntologyId(),
            name => $nm,
            description => $step->getDescription(),
          });

    my $studyBioMaterial = GUS::Model::RAD::StudyBioMaterial->
      new({study_id => $study->getId()});
    $studyBioMaterial->setParent($biosource);

    $biosource->submit();
    push(@rv, $biosource);
  }
  return(\@rv);
}

# ----------------------------------------------------------------------

sub _makeBioSamples {
  my ($self, $step, $prevBioSamples, $study) = @_;

  my @rv;

  my $sql = "select value, ontology_entry_id from STudy.ONTOLOGYENTRY where value in ('split', 'pool')";

  my %splitPoolOntologyIds;

  my $processRows =  sub {
    my $row = shift;
    push(@{$splitPoolOntologyIds{$row->{value}}}, $row->{ontology_entry_id});
  };

  $self->sqlAsHashRefs(Sql => $sql, Code => $processRows);

  my $n = $step->getBioMaterialNumber();
  my $treatId = $step->getTreatmentTypeId();
  my $nm = $step->getName();
  my $prevNumber = scalar(@$prevBioSamples);

  my $numberToPool = 1;
  if($self->_isIncluded($treatId, $splitPoolOntologyIds{pool})) {
    die "Pooling protocol chosen but same number of prevBioSamples as current $n" if($n == $prevNumber);
    die "Inncorrect Number of biosamples for pooling:  $prevNumber not divisible by $n for protocol $nm" if($prevNumber % $n != 0);

    $numberToPool = $prevNumber / $n;
  }

  my $numberToSplit = 1;
  if($self->_isIncluded($treatId, $splitPoolOntologyIds{split})) {
    die "Splitting protocol chosen but same number of prevBioSamples as current $n" if($n == $prevNumber);
    die "Inncorrect Number of biosamples for splitting:  $n not divisible by $prevNumber for protocol $nm" if($n % $prevNumber != 0);

    $numberToSplit = $n / $prevNumber;
  }

  my $count = 1;
  while(my $prevBM = pop(@$prevBioSamples)) {
    foreach(1..$numberToSplit) {

      my $name = "$nm $count";
      print STDERR "Working on BioSample $name\n";

      my $bioSample = GUS::Model::Study::BioSample->
        new({BIO_MATERIAL_TYPE_ID => $step->getMaterialTypeOntologyId(),
             NAME => $name,
             DESCRIPTION => $step->getDescription,
            });

      my $studyBioMaterial = GUS::Model::RAD::StudyBioMaterial->
        new({study_id => $study->getId()});

      $studyBioMaterial->setParent($bioSample);

      my $treatment = GUS::Model::RAD::Treatment->
        new({order_num => 1,
             TREATMENT_TYPE_ID => $treatId,
             PROTOCOL_ID => $step->getProtocolId,
             NAME => $step->getProtocolNm(),
            });

      $treatment->setParent($bioSample);

      foreach my $poolCount (1..$numberToPool) {
        $prevBM = pop(@$prevBioSamples) unless($poolCount == 1);

        my $bmMeasurement = GUS::Model::RAD::BioMaterialMeasurement->new({});

        $bmMeasurement->setParent($prevBM);
        $bmMeasurement->setParent($treatment);
      }

      $bioSample->submit();
      push(@rv, $bioSample);
      $count++;
    }
  }
  return(\@rv);
}

# ----------------------------------------------------------------------

sub _makeLabeledExtracts {
  my ($self, $step, $prevBioSamples, $labelMethodId, $study) = @_;

  my @rv;

  my $sql = "select protocol_id from Rad.LABELMETHOD where label_method_id  = $labelMethodId";
  my ($expectedProtocolId) = $self->sqlAsArray(Sql => $sql);

  my $protocolId = $step->getProtocolId();
  my $nm = $step->getName();

  if($expectedProtocolId != $protocolId) {
    die "Mismatch in protocolIds for Labeled extract $expectedProtocolId and $protocolId";
  }

  my $count = 1;
  foreach my $prevBM (@$prevBioSamples) {

    my $name = "$nm $count";
    print STDERR "Working on LabeledExtract $name\n";

    my $labeledExtract = GUS::Model::Study::LabeledExtract->
          new({BIO_MATERIAL_TYPE_ID => $step->getMaterialTypeOntologyId(),	
               LABEL_METHOD_ID => $labelMethodId,
               NAME => $name,
               DESCRIPTION => $step->getDescription()
              });

    my $studyBioMaterial = GUS::Model::RAD::StudyBioMaterial->
      new({study_id => $study->getId()});

    $studyBioMaterial->setParent($labeledExtract);

    my $treatment = GUS::Model::RAD::Treatment->
      new({order_num => 1,
           TREATMENT_TYPE_ID => $step->getTreatmentTypeId(),
           PROTOCOL_ID => $step->getProtocolId,
           NAME => $step->getProtocolNm(),
          });

    $treatment->setParent($labeledExtract);

    my $bmMeasurement = GUS::Model::RAD::BioMaterialMeasurement->new({});

    $bmMeasurement->setParent($prevBM);
    $bmMeasurement->setParent($treatment);

    $labeledExtract->submit();
    push(@rv, $labeledExtract);
    $count++;
  }
  return(\@rv);
}

# ----------------------------------------------------------------------

sub _makeAssay {
  my ($self, $data, $study) = @_;

  my $assay = GUS::Model::RAD::Assay->
    new({assay_date => $data->{assay_date},
         array_identifier => $data->{array_identifier},
         operator_id => $data->{assay_operator_id},
         description => $data->{assay_description},
         array_design_id => $data->{array_design_id},
         protocol_id => $data->{assay_protocol_id},
         name => $data->{assay_name},
         });

  my $studyAssay = GUS::Model::RAD::StudyAssay->new({});

  $assay->addChild($studyAssay);
  $study->addChild($studyAssay);

  $self->_makeAcquisition($data, $assay);

  return($assay);
}

# ----------------------------------------------------------------------

sub _makeAcquisition {
  my ($self, $data, $assay) = @_;

  my ($acquisitionProtocolId, $acquisitionName);
  if($acquisitionProtocolId = $data->{acquisition_protocol_id}) {
    ($acquisitionName) = $self->sqlAsArray( Sql => "select name from rad.protocol where protocol_id = $acquisitionProtocolId" );
  }
  else {
    $acquisitionName = 'Image Acquisition';
  }
  my @acquisitionFNs = split(',', $data->{acquisition_fn});

  foreach my $fn (@acquisitionFNs) {
    my $acquisitionUri = $self->getArgs()->{AcquUri} . $fn;
    my $acquisitionFileCheck = $self->getArgs()->{AcquDirPrefix} . $acquisitionUri;

    if (! -e $acquisitionFileCheck) {
      $self->log("WARNING:  $acquisitionFileCheck does not exist.");
      $acquisitionUri = '';
    }

    my ($nm, $channel, $ext) = $fn =~ /(.+)_(.+)\.(.+)/;
    $channel = $fn unless($channel);

    my $oeSql = "select ontology_entry_id from study.ontologyEntry where category = 'LabelCompound' and value = ?";
    my $sh = $self->getQueryHandle()->prepare($oeSql);
    $sh->execute($channel);

    my ($channelId) = $sh->fetchrow_array();
    $sh->finish();

    die "No OntologyEntry found for $fn" if(!$channelId);

    my $aName = $data->{assay_name} . "-". $acquisitionName . "-" . $channel;

    my $acquisition = GUS::Model::RAD::Acquisition->
      new({protocol_id => $acquisitionProtocolId,
           channel_id => $channelId,
           acquisition_date => $data->{acquisition_date},
           name => $aName,
          });

    $acquisition->setParent($assay);

    $self->_makeCelQuantification($data, $channel, $acquisition);
    $self->_makeQuantification($data, $channel, $acquisition);
  }
}
# ----------------------------------------------------------------------

sub _makeCelQuantification {
  my ($self, $data, $channel, $acquisition) = @_;

  if($data->{cel_fn}) {
    my $celUri = $self->getArgs()->{QuantUri} . $data->{cel_fn};
    my $celFileCheck = $self->getArgs()->{QuantDirPrefix} . $celUri;

    die "CEL FILE  $celFileCheck does not Exist" if (! -e $celFileCheck);

    my $celName;
    if(my $celProtocolId = $data->{cel_protocol_id}) {
      ($celName) = $self->sqlAsArray( Sql => "select name from rad.protocol where protocol_id = $celProtocolId" );
    }
    else {
      $celName = "Probe Cel Analysis";
    }
    my $cName = $data->{assay_name} . "-". $celName . "-". $channel;

    my $celQuantification = GUS::Model::RAD::Quantification->
      new({protocol_id => $data->{cel_protocol_id},
           name => $cName,
           uri => $celUri,
           });

    $celQuantification->setParent($acquisition);
  }
}

# ----------------------------------------------------------------------

sub _makeQuantification {
  my ($self, $data, $channel, $acquisition) = @_;

  my @quantificationFNs = split(',', $data->{quantification_fn});

  foreach my $fn (@quantificationFNs) {
    my $quantUri = $self->getArgs()->{QuantUri} . $fn;
    my $quantFileCheck = $self->getArgs()->{QuantDirPrefix} . $quantUri;

    die "Quantification FILE  $quantFileCheck does not Exist" if (! -e $quantFileCheck);

    my ($quantificationName, $quantProtocolId);
    if($quantProtocolId = $data->{quantification_protocol_id}) {
      ($quantificationName) = $self->sqlAsArray( Sql => "select name from rad.protocol where protocol_id = $quantProtocolId" );
    }
    else {
      $quantificationName = 'Quantification';
    }

    my $qName = $data->{assay_name} . "-". $quantificationName . "-" . $channel;

    # TODO:  This if statement should come out eventually...The quant files would need to have a naming convention though
    if($fn =~ /notnorm/) {
      $qName = $qName." Not Normalized";
    }

    my $quantification = GUS::Model::RAD::Quantification->
      new({operator_id => $data->{quantification_operator_id},
           quantification_date => $data->{quantification_date},
           protocol_id => $quantProtocolId,
           result_table_id => $data->{result_table_id},
           name => $qName,
           uri => $quantUri
          });

    $quantification->setParent($acquisition);
  }
}

# ----------------------------------------------------------------------

sub _relateAcquisitionsAndQuantifications {
  my ($self, $data, $assay) = @_;

  my $assayId = $assay->getId();
  my $assayName = $data->{assay_name};

  my $acquisitions = $self->sqlAsDictionary( Sql => "select a.acquisition_id, o.value from Rad.Acquisition a, Study.ONTOLOGYENTRY o where a.channel_id = o.ontology_entry_id and a.assay_id = $assayId" );

  foreach my $acquisition (keys %$acquisitions) {
    foreach my $related (keys %$acquisitions) {
      next if($acquisition == $related);

      my $relatedAcquisition = GUS::Model::RAD::RelatedAcquisition->
        new({ACQUISITION_ID => $acquisition,
             ASSOCIATED_ACQUISITION_ID => $related,
             NAME => $assayName,
             DESIGNATION => $acquisitions->{$acquisition},
             ASSOCIATED_DESIGNATION => $acquisitions->{$related},
            });

      $relatedAcquisition->submit();
    }
  }

  return(1) unless($self->getArgs()->{RelateQuantifications});

  my $quantifications = $self->sqlAsDictionary( Sql => "select q.quantification_id, o.value from Rad.Acquisition a, Study.ONTOLOGYENTRY o, Rad.QUANTIFICATION q where q.acquisition_id = a.acquisition_id and a.channel_id = o.ontology_entry_id and a.assay_id = $assayId" );

  foreach my $quant (keys %$quantifications) {
    foreach my $relatedQuant (keys %$quantifications) {
      next if($quant == $relatedQuant);

      my $relatedQuantification = GUS::Model::RAD::RelatedQuantification->
        new({Quantification_ID => $quant,
             ASSOCIATED_quantification_ID => $relatedQuant,
             NAME => $assayName,
             DESIGNATION => $quantifications->{$quant},
             ASSOCIATED_DESIGNATION => $quantifications->{$relatedQuant},
            });

      $relatedQuantification->submit();
    }
  }
  return(1);
}

# ----------------------------------------------------------------------

sub _linkAssayToLex {
  my ($self, $assay, $link, $nm, $studyId) = @_;

  my $sql = "select b.bio_material_id as old, t.bio_material_id as new 
              from Rad.Treatment t, Rad.BioMaterialMeasurement b 
              where t.treatment_id = b.treatment_id 
               and t.bio_material_id in (select bio_material_id from Rad.StudyBioMaterial where study_id = $studyId)";

  my %bmMap;
  my $processRows =  sub {
    push(@{$bmMap{$_[0]->{new}}}, $_[0]->{old});
  };

  $self->sqlAsHashRefs(Sql => $sql, Code => $processRows);

  my @names = split(',', $nm);

  foreach(@names) {
    my $lex = pop(@{$link->{$_}});

    my $bmId = $lex->getId();

    my $sql = "select lm.channel_id 
               from Study.LABELEDEXTRACT lex, Rad.LABELMETHOD lm 
               where lex.label_method_id = lm.label_method_id  and bio_material_id = $bmId";

    my ($channelId) = $self->sqlAsArray(Sql => $sql);

    my $assayLex = GUS::Model::RAD::AssayLabeledExtract->
      new({ channel_id => $channelId });

    $assayLex->setParent($assay);
    $assayLex->setParent($lex);

    $assayLex->submit();

    my $key = $lex->getId();

    $self->_linkAssayBioMaterials($key, \%bmMap, $assay);
  }
}

# ----------------------------------------------------------------------

sub _linkAssayBioMaterials {
  my ($self, $node, $map, $assay) = @_;

  my $assayBioMaterial = GUS::Model::RAD::AssayBioMaterial->
    new({bio_material_id => $node});

  $assayBioMaterial->setParent($assay);
  $assayBioMaterial->submit();

  foreach(@{$map->{$node}}) {
    $self->_linkAssayBioMaterials($_, $map, $assay);
  }
  return(1);
}


# ----------------------------------------------------------------------

sub _checkHeaderRow {
  my ($self, $colNames) = @_;

  if(scalar(@$colNames) != scalar(@$expectedNames)) {
    print STDERR join("\|", @$expectedNames) . "\n";
    die "Header does not contain the correct Number of columns: $!";
  }

  foreach(@$colNames) {
    if(!$self->_isIncluded($_, $expectedNames)) {
      print STDERR join("\|", @$expectedNames) . "\n";
      die "Use expected values above separated by tabs" 
    }
  }
  return(1);
}

# ----------------------------------------------------------------------


sub _isIncluded {
  my ($self, $val, $ar) = @_;

  foreach(@$ar) {
      return(1) if(/$val/i);
  }
  return(0);
}

# ----------------------------------------------------------------------

sub _printSummary {
  my ($self) = @_;

  my @tables = $self->undoTables();
  my $algInvoc = $self->getAlgInvocation();
  my $algInvocId = $algInvoc->getId();

  print STDERR "Table\tCount\n";
  foreach my $t (@tables) {
    my ($count) = $self->sqlAsArray( Sql => "select count(*) from $t where row_alg_invocation_id = $algInvocId" );

    $count = 0 unless($count);
    print STDERR "$t\t$count\n";
  }
  return(1);
}

# ----------------------------------------------------------------------

sub undoTables {
  return ('RAD.BioMaterialMeasurement',
          'RAD.Treatment',
          'RAD.StudyBioMaterial',
          'RAD.AssayBioMaterial',
          'RAD.AssayLabeledExtract',
          'Study.LabeledExtract',
          'Study.BioSample',
          'Study.BioSource',
          'RAD.RelatedQuantification',
          'RAD.Quantification',
          'RAD.RelatedAcquisition',
          'RAD.Acquisition',
          'RAD.StudyAssay',
          'RAD.Assay');
}

# ----------------------------------------------------------------------

1;
