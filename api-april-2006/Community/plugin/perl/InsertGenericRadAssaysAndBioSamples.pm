package GUS::Community::Plugin::InsertGenericRadAssaysAndBioSamples;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
use GUS::PluginMgr::Plugin;

use GUS::Model::Study::Study;

use GUS::Model::RAD::Assay;
use GUS::Model::RAD::StudyAssay;
use GUS::Model::RAD::Acquisition;
use GUS::Model::RAD::Quantification;

use FileHandle;

my $purposeBrief = <<PURPOSE_BRIEF;
Load rows in RAD corresponding to ModuleI and ModuleIII of the RADSA Forms.
PURPOSE_BRIEF

my $purpose = <<PLUGIN_PURPOSE;
Load rows in RAD corresponding to ModuleI and ModuleIII of the RADSA Forms.  This plugin is generic but will not work for every possible case imaginable.  See NOTES for when appropriate to use this plugin and for what will and will not be loaded.
PLUGIN_PURPOSE

my $tablesAffected = [ ['RAD::Assay', 'One Row for each row of Tab Data file'],
                       ['RAD::StudyAssay', 'One row for each row of Tab Data File'],
                       ['RAD::Acquisition', 'At least one row for each row of Tab Data File'],
                       ['RAD::Quantification', 'At least one row for each row of Tab Data File'],
                     ];

my $tablesDependedOn =[ ['RAD::Study', 'Study provided as Arg must exist'] ];

my $howToRestart = <<PLUGIN_RESTART;
This plugin has no restart facility.
PLUGIN_RESTART

my $failureCases = <<PLUGIN_FAILURE_CASES;
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
=head2 DISCLAIMER

This plugin will NOT handle all the possible variations which the RAD schema can handle.  The plugin takes a data files which contains several ids.  Care must be taken to ensure these are correct or will mess up downstream (ie dataloading).  The plugin does minimal checking to ensure values are not null (ie. if you don't want a value to be null, make sure to fill in the column of the data file).  If you are doing something very complex, you will probably be better off using the RADSA.  

=head1 TAB_DATA_FILE

File which contains the "ModuleI" data to be loaded.  All Column Headers must exist or the plugin will die.  The order of the columns doesn't matter and upper or lower case will work.  Please not the following:

=over 4

=item *

The Header is checked but the values are not...ex. assay_operator_id is required by the db schema but currently it is not checked for in the plugin.

=item *

"assay_date" must be in the format "year-month-date' ex: 2004-10-04

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

PLUGIN_NOTES

my $documentation = { purpose          => $purpose,
		      purposeBrief     => $purposeBrief,
		      tablesAffected   => $tablesAffected,
		      tablesDependedOn => $tablesDependedOn,
		      howToRestart     => $howToRestart,
		      failureCases     => $failureCases,
		      notes            => $notes
		    };

my $expectedNames = [ "ASSAY_DATE",  "ASSAY_IDENTIFIER", "ASSAY_OPERATOR_ID", "ASSAY_DESCRIPTION", 
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
            descr          => 'Tab delimeted File containing Protocols in an Ordered way.',
            reqd           => 1,
            mustExist      => 1,
            format         => 'see NOTES',
            constraintFunc => undef,
            isList         => 0, 
           }),

   stringArg({ descr => 'The QuantUri is a partial path to the directory data files are stored.  See NOTES',
               name  => 'QuantUri',
               isList    => 0,
               reqd  => 1,
               constraintFunc => undef,
             }),

   stringArg({ descr => 'The QuantUri is a partial path to the quant directory.  See NOTES',
               name  => 'QuantDirPrefix',
               isList    => 0,
               reqd  => 0,
               default => "/files/cbil/data/cbil/RAD/",
               constraintFunc => undef,
             }),

   stringArg({ descr => 'The AcquUri is a partial path to directory image files are stored.  See NOTES',
               name  => 'AcquUri',
               isList    => 0,
               reqd  => 0,
               constraintFunc => undef,
             }),

   stringArg({ descr => 'The AcquUri is a partial path to the quant directory.  See NOTES',
               name  => 'AcquDirPrefix',
               isList    => 0,
               reqd  => 0,
               default => "/files/cbil/data/cbil/RAD_Images/",
               constraintFunc => undef,
             }),

   integerArg({name => 'StudyId',
               descr => 'Study For which These will belong to',
               reqd => 1,
               constraintFunc => undef,
               isList => 0
              }),

                       ];

# ----------------------------------------------------------------------

sub new {
  my ($class) = @_;
  my $self    = {};
  bless($self,$class);

  $self->initialize({requiredDbVersion => 3.5,
                     cvsRevision       => '$Revision: 1 $',
                     name              => ref($self),
                     argsDeclaration   => $argsDeclaration,
                     documentation     => $documentation
                    });

  return $self;
}

# ----------------------------------------------------------------------

sub run {
  my ($self) = @_;

  my $study = GUS::Model::Study::Study->
    new({ study_id => $self->getArgs()->{StudyId}, });

  die "Could not retrieve StudyId from DB" if(!$study->retrieveFromDB());

  my ($bmCount, $colNames) = $self->_getProtocolCounts();
  $self->_readBioMaterialFile();

  my $biomaterials = $self->_makeBioMaterials($bmCount);

  my $fn = $self->getArgs()->{DataFile};
  open(FILE, $fn) || die "Cannot open file $fn for reading: $!";

  <FILE>;
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


    $self->undefPointerCache();
    exit(1);
  }

  close(FILE);

}

# ----------------------------------------------------------------------

sub _readBioMaterialFile {
  my ($self) = @_;

  my $fn = $self->getArgs()->{BioMaterialFile};

  open(FILE, $fn) || die "Cannot open file $fn for reading: $!";

  my $rv = [];
  my $count = 1;

  my ($taxonId, $providerId);
  my ($nmState, $protState);
  while(<FILE>) {
    chomp;
    next if(!$_);

    my ($id, $val) = split('=', $_);

    if($id eq 'TaxonScientificName') {
      $taxonId = $self->_getTaxonId($id);
    }
    if($id eq 'ProviderName') {
      $providerId = $self->_getProviderId($id);
    }
    if($id eq 'next') {
      $nmState = undef;
      $taxonId = undef;
      $providerId = undef;
      $count++;
    }

    if($id eq 'Name|MaterialType|Description') {
      if($protState) {
        #$rv->{$val}->{protocol_series}->[$n];
      }
      $rv->[$count] = {taxon_id => $taxonId,
                       provider_id => $providerId,
                       protocol_series => []
                      };

    }

  }

}


# ----------------------------------------------------------------------

sub _getProtocolCounts {
  my ($self, $colNames) = @_;

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
    my $protocolName = $ar[$index];

    $protocolCounts{$protocolName}++;
  }
  close(FILE);

  return(\%protocolCounts, \@colNames);
}

# ----------------------------------------------------------------------

sub _makeBioMaterials {
  my ($self, $bmCount) = @_;

  

}


# ----------------------------------------------------------------------

sub _makeAssay {
  my ($self, $data, $study) = @_;

  my $assay = GUS::Model::RAD::Assay->
    new({assay_date => $data->{assay_date},
         assay_identifier => $data->{assay_identifier},
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

    my ($nm, $channel, $ext) = $acquisitionUri =~ /(.+)_(.+)\.(.+)/;

    my $channelId;

    my $oeSql = "select ontology_entry_id from study.ontologyEntry where category = 'LabelCompound' and value = ?";
    my $sh = $self->getQueryHandle()->prepare($oeSql);
    $sh->execute($channel);

    if(!(($channelId) = $sh->fetchrow_array())) {
      $sh->execute($fn);
      ($channelId) = $sh->fetchrow_array();
    }
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

    my $qName = $data->{assay_name} . "-". $quantificationName;

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


1;
