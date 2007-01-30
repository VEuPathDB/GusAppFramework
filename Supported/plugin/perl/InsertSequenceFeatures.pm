package GUS::Supported::Plugin::InsertSequenceFeatures;

# todo:
#  - handle seqVersion more robustly
#  - add logging info
#  - undo

@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
use Data::Dumper;
use FileHandle;

use Bio::SeqIO;
use Bio::Tools::SeqStats;
use Bio::Tools::GFF;
use Bio::SeqFeature::Tools::Unflattener;

use GUS::PluginMgr::Plugin;
use GUS::Supported::BioperlFeatMapperSet;
use GUS::Supported::SequenceIterator;

#GENERAL USAGE TABLES
use GUS::Model::SRes::ExternalDatabase;
use GUS::Model::SRes::ExternalDatabaseRelease;
use GUS::Model::SRes::Reference;

#USED IN LOADING NASEQUENCE
use GUS::Model::SRes::TaxonName;
use GUS::Model::SRes::SequenceOntology;
use GUS::Model::DoTS::SequenceType;
use GUS::Model::DoTS::NASequence;
use GUS::Model::DoTS::ExternalNASequence;
use GUS::Model::DoTS::VirtualSequence;
use GUS::Model::DoTS::Assembly;
use GUS::Model::DoTS::SplicedNASequence;
use GUS::Model::DoTS::SecondaryAccs;
use GUS::Model::DoTS::NALocation;
use GUS::Model::DoTS::NASequenceRef;
use GUS::Model::DoTS::Keyword;
use GUS::Model::DoTS::NASequenceKeyword;
use GUS::Model::DoTS::NAComment;
use GUS::Model::DoTS::ExonFeature;

# future considerations....
#
# - need chromosome in na sequence, not just source.
#
# - handling dbxrefs (if we ever need this):
#    - by default, use name from input as db name
#    - by default, use "unknown" as version
#    - take optional --defaultDbxrefVersion on command line
#    - take optional --dbxrefMapFile on command line
#    - the map file maps from input name to GUS name and (optionally) version
#    - when a name is first encountered in input, read all its ids into memory
#    - if a name is not found in GUS or mapping filem, error
#
# - do we need to fill in info in TranslatedAASeq and TranslatedAAFeat such as:
#    - so term
#    - source id
#    - is simple 
#
# - take a cmd line arg for a mapping file for SeqType CV
#
# - handle the case of multiple tag values better... should be controlled by xml file

  my $purpose = <<PURPOSE;
Insert files containing NA sequence and features, that are in a format handled by bioperl's Bio::SeqIO parser package (eg, genbank, embl, TIGR). See that package for more details about what the bioperl parser can handle.  Also supports files in GFF2 and GFF3 format.

(Note that, like all plugins that start with Insert, this plugin only inserts rows and never updates them.   This means that the plugin cannot be used to update an existing set of sequences in the database.  It assumes a database management strategy that rebuilds from scratch the set of sequences instead of attempting the much more difficult task of updating.  This strategy will work for most datasets, but, not for huge ones such as the human genome.)

The sequence level attributes that are currently supported are: taxon, SO assignment, comments, keywords, secondary accessions and references.

The sequence may be absent from the input file.  But, in that case it must have been loaded into GUS already.  (The seqIdColumn argument indicates which column of the subclass specified by the naSequenceSubclass argument should be matched against the input to locate the proper sequence in the database.)

This plugin is designed to be flexible in its mapping from the features and qualifiers found in the input to the tables in GUS.  The flexibility is specified in the "XML mapping file" provided on the command line (--mapFile).

A default mapping is provided as a reference  (see \$GUS_HOME/config/genbank2gus.xml).  That file provides a mapping for the complete genbank feature table.

It is often the case that your input may come from unofficial sources that, while conforming to one of the bioperl supported formats, invent features or qualifiers, and stuff unexpected values into already existing qualifiers.

In that case, you will need to write your own mapping file.  Use the provided default as an example.  The main purpose of the file is to specify which subclass of NAFeature should store the input feature, and, which columns should store which qualifiers.

Another way to generate a template mapping file is by using the command reportFeatureQualifiers.  This command analyzes a set of input files, and reports the feature/qualifier structure found in them.  It can output the report in simple text form, or in XML that is a template for the mapping file.

There is an additional level of configurability provided by "plugable" qualifier handlers.  As you will see in the default XML file, some qualifiers do not fit neatly into a column in the feature table.  Those that don't are called "special cases."  In the XML file you can declare the availability of one or more special case qualifier handlers to handle those special cases   The default file declares one of these at the top of the file.  Your XML file can declare additional handlers that you write.  (See the code in the default handler to learn how to write your own.)  In the XML file, qualifiers that need special handling specify the name of the handler object and a method in it to call to handle the qualifier.

You can also use a qualifier handler to modify or even ignore the feature that the qualifier belongs to.  An argument to the handler is \$feature, so if you need to modify it directly you can.  Also, if the handler returns undef, that is a signal to force the entire feature to be ignored.  An advanced use of the handler exploits the fact that the handler method is an instance method on a handler object that lives throughout the plugin run.  So, you can store state in the handler object during one call to a handler method, and that state will be available to other calls.  This is a way to combine data from more than one qualifier.

The qualifiers of a feature are passed to the handler in the order found in the mapping file (not the order found in the input).

PURPOSE

  my $purposeBrief = <<PURPOSEBRIEF;
Load files containing NA sequence and features.
PURPOSEBRIEF

  my $notes = <<NOTES;
The bioperl parser includes an "unflattener" that analyzes feature locations of genes, rna, cds, etc and constructs gene feature trees of them (ie, gene models). (See the bioperl API documentation for Bio::SeqFeature::Tools::Unflattener.)  The plugin preserves these relationships (using the feature's parent_id to capture the tree).

To avoid memory problems with sequences that have huge numbers of features, the plugin submits the NASequence as one transaction, and each feature tree as one transation.
NOTES

  my $tablesAffected =
  [
   ['SRes.Reference', ''],
   ['SRes.SequenceOntology', ''],
   ['DoTS.SequenceType', ''],
   ['DoTS.NASequence', ''],
   ['DoTS.ExternalNASequence', ''],
   ['DoTS.VirtualSequence', ''],
   ['DoTS.Assembly', ''],
   ['DoTS.SplicedNASequence', ''],
   ['DoTS.SecondaryAccs', ''],
   ['DoTS.NALocation', ''],
   ['DoTS.NASequenceRef', ''],
   ['DoTS.Keyword', ''],
   ['DoTS.NAComment', ''],
   ['DoTS.TranslatedAAFeature', ''],
   ['DoTS.TranslatedAASequence', ''],
   ['DoTS.NAGene', ''],
   ['DoTS.NAProtein', ''],
   ['SRes.DbRef', ''],
   ['DoTS.NAFeatureComment', ''],
   ['DoTS.NASequenceKeyword', ''],
   ['DoTS.NAFeatureNAGene', ''],
   ['DoTS.NAFeatureNAProtein', ''],
   ['DoTS.DbRefNAFeature', ''],
  ];


  my $tablesDependedOn = 
  [
   ['SRes.TaxonName', ''],
   ['SRes.SequenceOntology', ''],
   ['SRes.ExternalDatabase', ''],
   ['SRes.ExternalDatabaseRelease', ''],
  ];

  my $howToRestart = <<RESTART;
Restart is not supported.  Use the GUS::Supported::Plugin::InsertSequenceFeaturesUndo plugin to back out failed runs.
RESTART

  my $failureCases = <<FAIL;
FAIL

my $documentation = { purpose=>$purpose, 
		      purposeBrief=>$purposeBrief,
		      tablesAffected=>$tablesAffected,
		      tablesDependedOn=>$tablesDependedOn,
		      howToRestart=>$howToRestart,
		      failureCases=>$failureCases,
		      notes=>$notes
		    };

my $argsDeclaration  =
  [
   fileArg({name => 'mapFile',
	    descr => 'XML file with mapping of Sequence Features from BioPerl to GUS.  For an example, see $GUS_HOME/config/genbank2gus.xml',
	    constraintFunc=> undef,
	    reqd  => 1,
	    isList => 0,
	    mustExist => 1,
	    format=>'XML'
	   }),

   fileArg({name => 'inputFileOrDir',
	    descr => 'Text file containing features and optionally sequence data, or a directory containing such files',
	    constraintFunc=> undef,
	    reqd  => 1,
	    isList => 0,
	    mustExist => 1,
	    format=>'Text'
	   }),

   stringArg({name => 'inputFileExtension',
	      descr => 'The extension that input files must have (useful if you are providing a directory of input files, to filter out irrelevant files)',
	      constraintFunc=> undef,
	      reqd  => 0,
	      isList => 0,
	     }),

   enumArg({name => 'naSequenceSubclass',
	    descr => 'If the input file does not include the sequence, the subclass of NASequence in which to find the sequence (which must already be in the database)',
	    constraintFunc=> undef,
	    reqd  => 0,
	    isList => 0,
	    enum => "ExternalNASequence, VirtualSequence, Assembly, SplicedNASequence",
	   }),

   enumArg({name => 'seqIdColumn',
	    descr => 'The column to use to identify the sequence in the database (if input does not contain sequence).',
	    constraintFunc=> undef,
	    reqd  => 0,
	    isList => 0,
	    enum => "na_sequence_id, source_id",
	    default => "source_id",
	   }),


   stringArg({name => 'seqType',
	      descr => 'The type of the sequences in the input file (from DoTS.SequenceType.name)',
	      constraintFunc=> undef,
	      reqd  => 0,
	      isList => 0,
	     }),

   stringArg({name => 'seqSoTerm',
	      descr => 'The SO term describing the sequences in the input file ',
	      constraintFunc=> undef,
	      reqd  => 0,
	      isList => 0,
	     }),

   stringArg({name => 'soCvsVersion',
	      descr => 'The CVS version of the Sequence Ontology to use',
	      constraintFunc=> undef,
	      reqd  => 0,
	      isList => 0,
	     }),

   stringArg({name => 'fileFormat',
	      descr => 'Format of external data being loaded.  See Bio::SeqIO::new() for allowed options.  gff2 and gff3 are additional options',
	      constraintFunc=> undef,
	      reqd  => 1,
	      isList => 0
	     }),

   stringArg({name => 'gff2GroupTag',
	      descr => 'Name of the tag to be used for GFF2 grouping',
	      constraintFunc=> undef,
	      reqd  => 0,
	      isList => 1,
	     }),

   stringArg({name => 'extDbName',
	      descr => 'External database from whence this data came',
	      constraintFunc=> undef,
	      reqd  => 1,
	      isList => 0
	     }),

   stringArg({name => 'extDbRlsVer',
	      descr => 'Version of external database from whence this data came',
	      constraintFunc=> undef,
	      reqd  => 1,
	      isList => 0
	     }),

   stringArg({name => 'seqExtDbName',
	      descr => 'External database where sequences can be found',
	      constraintFunc=> undef,
	      reqd  => 0,
	      isList => 0
	     }),

   stringArg({name => 'seqExtDbRlsVer',
	      descr => 'Version of external database where sequences can be found',
	      constraintFunc=> undef,
	      reqd  => 0,
	      isList => 0
	     }),



   stringArg({name => 'defaultOrganism',
	      descr => 'The organism name to use if a sequence in the input file does not provide organism information and the --organism parameter is not provided.  Eg "Plasmodium falciparum"',
	      constraintFunc=> undef,
	      reqd  => 0,
	      isList => 0
	     }),

   stringArg({name => 'organism',
	      descr => 'The organism name to use no matter what.  Eg "Plasmodium falciparum"',
	      constraintFunc=> undef,
	      reqd  => 0,
	      isList => 0
	     }),

   stringArg({name => 'handlerExternalDbs',
	      descr => "A list of ExternalDatabase names and releases for use by any qualifier handler.  For example, a handler might want to use the EnzymeClass controlled vocab.  To do so, it must access it correctly with an external_database_rls_id.  It can get that using values provided by this argument.  The format is a list of Tag:Name:Release.  Eg, 'enzyme:Enzyme Database:2.1.0'.  The plugin makes the external_databse_rls_id available to the handler with a method getExternalDbRlsIdByTag(\$tag).  The handler must throw a userError() if the tag it expects is not found.  It is an error to provide in this argument a tag more than once.",
	      constraintFunc=> undef,
	      reqd  => 0,
	      isList => 1
	     }),

   integerArg({name => 'testNumber',
	       descr => 'number of feature trees to do test on',
	       constraintFunc=> undef,
	       reqd  => 0,
	       isList => 0
	      }),

   fileArg({name => 'bioperlTreeOutput',
	    descr => 'print Bioperl trees (after reshaping) to this file',
	    constraintFunc=> undef,
            reqd  => 0,
            isList => 0,
            default => 0,
	    mustExist => 0,
	    format=>'XML'
           }),

  ];


sub new {
  my $class = shift;
  my $self = {};
  bless($self, $class);

  $self->initialize({requiredDbVersion => 3.5,
		     cvsRevision => '$Revision$',
		     name => ref($self),
		     argsDeclaration => $argsDeclaration,
		     documentation => $documentation
		    });
  return $self;
}

sub run {
  my ($self) = @_;

  $self->{mapperSet} =
    GUS::Supported::BioperlFeatMapperSet->new($self->getArg('mapFile'), $self);

  my $dbRlsId = $self->getExtDbRlsId($self->getArg('extDbName'),
				     $self->getArg('extDbRlsVer'))
      or die "Couldn't retrieve external database!\n";

  
  my $seqExtDbRlsId = $dbRlsId;

  if ($self->getArg('seqExtDbName')) {
      $seqExtDbRlsId = $self->getExtDbRlsId($self->getArg('seqExtDbName'),
					    $self->getArg('seqExtDbRlsVer'))
	  or die "Couldn't retrieve external database for sequences!\n";
  }

  $self->initHandlerExternalDbs();

  my $format = $self->getArg('fileFormat');
  $self->{totalFeatureCount} = 0;
  $self->{totalFeatureTreeCount} = 0;
  my $totalSeqCount = 0;
  my $fileCount = 0;
  my $action = $self->getArg('seqIdColumn')? 'Processed' : 'Inserted';

  my @inputFiles = $self->getInputFiles();

  my $btFh = $self->openBioperlTreeFile();

  foreach my $inputFile (@inputFiles) {
    $self->{fileFeatureCount} = 0;
    $self->{fileFeatureTreeCount} = 0;
    my $seqCount=0;

    $self->log("Processing file '$inputFile'...");

    my $bioperlSeqIO = $self->getSeqIO($inputFile);
    while (my $bioperlSeq = $bioperlSeqIO->next_seq() ) {

      # use id instead of object because object is zapped by undefPointerCache
      my $naSequenceId = $self->processSequence($bioperlSeq, $seqExtDbRlsId);

      $seqCount++;

      $self->{mapperSet}->preprocessBioperlSeq($bioperlSeq, $self);

      $self->processFeatureTrees($bioperlSeq, $naSequenceId, $dbRlsId, $btFh);

      $self->undefPointerCache();

      last if $self->checkTestNum();
    }

    $self->log("Processed $inputFile: $format \n\t Seqs $action: $seqCount \n\t Features Inserted: $self->{fileFeatureCount} \n\t Feature Trees Inserted: $self->{fileFeatureTreeCount}");
    $totalSeqCount += $seqCount;
    $fileCount++;
    last if $self->checkTestNum();
  }

  my $fileOrDir = $self->getArg('inputFileOrDir');
  $self->setResultDescr("Processed $fileCount files from $fileOrDir: $format \n\t Total Seqs $action: $totalSeqCount \n\t Total Features Inserted: $self->{totalFeatureCount} \n\t Total Feature Trees Inserted: $self->{totalFeatureTreeCount}");
}

sub openBioperlTreeFile {
  my ($self) = @_;

  my $bioperlTreeFile = $self->getArg('bioperlTreeOutput');
  my $btFh;
  if ($bioperlTreeFile) {
    $btFh = FileHandle->new();
    $btFh->open(">$bioperlTreeFile")
      || die "can't open bioperlTreeFile '$bioperlTreeFile'";
  }
  return $btFh;
}

sub getInputFiles {
  my ($self) = @_;

  my $fileOrDir = $self->getArg('inputFileOrDir');
  my $seqFileExtension = $self->getArg('inputFileExtension');

  my @inputFiles;
  if (-d $fileOrDir) {
    opendir(DIR, $fileOrDir) || die "Can't open directory '$fileOrDir'";
    my @noDotFiles = grep { $_ ne '.' && $_ ne '..' } readdir(DIR);
    @inputFiles = map { "$fileOrDir/$_" } @noDotFiles;
    @inputFiles = grep(/.*\.$seqFileExtension$/, @inputFiles) if $seqFileExtension;
  } else {
    $inputFiles[0] = $fileOrDir;
  }
  return @inputFiles;
}

sub getSeqIO {
  my ($self, $inputFile) = @_;

  my $format = $self->getArg('fileFormat');

  my $bioperlSeqIO;

  # SDF: what does bioperl do on a parsing error?   does it die?   if so,
  # we probably want to catch that error, and add to it the filename we are
  # parsing, if they don't already state that

  # AJM: it throws an error (i.e. dies with context) during next_seq
  # (which is when/where the parsing is happening, not here during IO
  # construction); it also can throw warnings which you might also
  # want to catch via a $SIG{__WARN__} handler

  if ($format =~ m/^gff([2|3])$/i) {
    $self->log("pre-processing GFF file...");
    $bioperlSeqIO = $self->convertGFFStreamToSeqIO($1);
    $self->log("done pre-processing");
  } else {
    $bioperlSeqIO = Bio::SeqIO->new(-format => $format,
				    -file   => $inputFile);
  }

  return $bioperlSeqIO;
}

sub convertGFFStreamToSeqIO {

  my ($self, $gffVersion) = @_;

  # convert a GFF "features-referring-to-sequence" stream into a
  # "sequences-with-features" stream; also aggregate grouped features.

  $self->userError("For now, gff formats only support a single file")
    if (-d $self->getArg('inputFileOrDir'));

  my @aggregators = $self->makeAggregators($gffVersion);

  my $gffIO = Bio::Tools::GFF->new(-file => $self->getArg('inputFileOrDir'),
				   -gff_format => $gffVersion
				  );

  my %seqs; my @seqs;
  while (my $feature = $gffIO->next_feature()) {
    push @{$seqs{$feature->seq_id}}, $feature;
  }

  while (my ($seq_id, $features) = each %seqs) {
    my $seq = Bio::Seq->new( -alphabet => 'dna',
			     -display_id => $seq_id,
			     -accession_number => $seq_id,
			   );

    if ($gffVersion < 3) {
      # GFF2 - use group aggregators to re-nest subfeatures
      for my $aggregator (@aggregators) {
	$aggregator->aggregate($features);
      }
    } else {
      # GFF3 - use explicit ID/Parent hierarchy to re-nest
      # subfeatures

      my %top;      # associative list of top-level features: $id => $feature
      my %children; # mapping of parents to children:
                    # $parent_id => [ [$child_id, $child],
                    #                 [$child_id, $child],
                    #               ]
      my @keep;     # list of features to replace flat feature list.

      # first, fill the datastructures we'll use to rebuild
      for my $feature (@$features) {
	my $id = 0;
	($id) = $feature->each_tag_value("ID")
	  if $feature->has_tag("ID");
	if ($feature->has_tag("Parent")) {
	  for my $parent ($feature->each_tag_value("Parent")) {
	    push @{$children{$parent}}, [$id, $feature];
	  }
	} else {
	  push @keep, $feature;
	  $top{$id} = $feature if $id; # only features with IDs can
	                               # have children
	}
      }

      while (my ($id, $feature) = each %top) {
	# build a stack of children to be associated with their
	# parent feature:
	# [$child_id, $child_feature, $parent_feature]
	my @children =
	  map {
	    push @$_, $feature;
	  } @{delete($children{$id}) || []};

	# now iterate over the stack until empty:
	while (my $child = shift @children) {
	  my ($child_id, $child, $parent) = @$child;
	  # make the association:
	  $parent->add_SubFeature($child);

	  # add to the stack any nested children of this child
	  push @children,
	    map {
	      push @$_, $child;
	    } @{delete($children{$child_id}) || []};
	}
      }

      # the entire contents of %children should now have been
      # processed:
      if (keys %children) {
	warn "Unassociated children features (missing parents):\n  ";
	warn join("  \n", keys %children), "\n";
      }

      # replace original feature list with new nested versions:
      @$features = @keep;
    }

    $seq->add_SeqFeature($_) for @$features;
    push @seqs, $seq;
  }

  return GUS::Supported::SequenceIterator->new(\@seqs);
}

sub makeAggregators {
  my ($self, $gffVersion) = @_;

  return undef if ($gffVersion != 2);

  $self->userError("Must supply --gff2GroupTag if using GFF2 format") unless $self->getArg("gff2GroupTag");

  # a list of "standard" feature aggregator types for GFF2 support;
  # only "processed_transcript" for now, but leaving room for others
  # if necessary.
  my @aggregators = qw(Bio::DB::GFF::Aggregator::processed_transcript Bio::DB::GFF::Aggregator::transcript);

  # build Feature::Aggregator objects for each aggregator type:
  @aggregators =
    map {
      Feature::Aggregator->new($_, $self->getArg("gff2GroupTag"));
    } @aggregators;
  return @aggregators;
}

###########################################################################
########     sequence processing 
###########################################################################

sub processSequence {
  my ($self, $bioperlSeq, $dbRlsId) = @_;

  my $naSequence;
  if ($self->getArg('naSequenceSubclass')) {
    $naSequence = $self->retrieveNASequence($bioperlSeq, $dbRlsId);
  } else {
    $naSequence = $self->bioperl2NASequence($bioperlSeq, $dbRlsId);
    $naSequence->submit();
  }

  return $naSequence->getNaSequenceId();
}

# if the input does not include sequence, get it from the db
sub retrieveNASequence {
  my ($self, $bioperlSeq, $dbRlsId) = @_;

  my $naSequenceSubclass = $self->getArg('naSequenceSubclass');
  my $seqIdColumn = $self->getArg('seqIdColumn');

  $seqIdColumn or die "if you provide --naSequenceSubclass you must also provide --seqIdColumn";

  my $class = "GUS::Model::DoTS::$naSequenceSubclass";
  my $naSequence = $class->
    new({ external_database_release_id => $dbRlsId,
	  $seqIdColumn => $bioperlSeq->accession_number});

  $naSequence->retrieveFromDB() or die "--naSequenceSubclass is set on the command line so input file is not providing the sequence.  Failed attempting to retrieve naSequenceSubclass '$naSequenceSubclass' with seqIdColumn '$seqIdColumn' and extDbRlsId: '$dbRlsId'\n";

  return $naSequence;
}

# if the input does include sequence, make GUS NASequence from bioperlSeq
sub bioperl2NASequence {
  my ($self, $bioperlSeq, $dbRlsId) = @_;

  my $naSequence = $self->constructNASequence($bioperlSeq, $dbRlsId);

  $self->addSecondaryAccs($bioperlSeq, $dbRlsId);

  $self->addReferences($bioperlSeq, $naSequence);

  $self->addComments($bioperlSeq, $naSequence);

  $self->addKeywords($bioperlSeq, $naSequence);

  #Annotations we haven't used yet
  #   SEGMENT      segment             SimpleValue e.g. "1 of 2"
  #   ORIGIN       origin              SimpleValue e.g. "X Chromosome."
  #   INV          date_changed        SimpleValue e.g. "08-JUL-1994"

  return $naSequence;
}

sub constructNASequence {
  my ($self, $bioperlSeq, $dbRlsId) = @_;

  if (!$bioperlSeq->seq()) {
    die "No input sequence found for accession '" . $bioperlSeq->accession_number() . "'.  If the input intentionally contains no sequence, please use --naSequenceSubclass and --seqIdColumn\n";
  }
  
  my $bioperlId = $bioperlSeq->accession_number();
  $bioperlId = $bioperlSeq->display_id() if $bioperlId eq "unknown";

  my $naSequence = GUS::Model::DoTS::ExternalNASequence->
      new({ external_database_release_id => $dbRlsId,
	    source_id => $bioperlId
	 });

  my $seqType = $self->getArg('seqType');
  if ($seqType) { 
    $naSequence->setSequenceTypeId($self->getSeqTypeId($seqType));
  }
  my $soTerm = $self->getArg('seqSoTerm');
  if ($soTerm) {
    $naSequence->setSequenceOntologyId($self->getSOPrimaryKey($soTerm));
  }
  my $taxId = $self->getTaxonId($bioperlSeq);
  $naSequence->setTaxonId($taxId);

  # workaround the bioperl embl parser's lack of an exception
  # if it can't parse the ID line
  my $displayId = $bioperlSeq->display_id();
  if ($displayId eq "unknown id") {
    $self->error("Sequence with accession '" . $bioperlSeq->accession_number() . "' does not have a parsable display id");
  }

  $naSequence->setName($displayId);
  $naSequence->setDescription($bioperlSeq->desc());
  my $seqVersion = $bioperlSeq->seq_version();
  $seqVersion = 1 unless $seqVersion;
  $naSequence->setSequenceVersion($seqVersion);

  if ($bioperlSeq->seq) {
      my $seqcount = Bio::Tools::SeqStats->count_monomers($bioperlSeq);
      $naSequence->setSequence($bioperlSeq->seq());
      $naSequence->setACount(%$seqcount->{'A'});
      $naSequence->setCCount(%$seqcount->{'C'});
      $naSequence->setGCount(%$seqcount->{'G'});
      $naSequence->setTCount(%$seqcount->{'T'}); #RNA Seqs??
      $naSequence->setLength($bioperlSeq->length());
  }

  return $naSequence;
}

sub addSecondaryAccs{
  my ($self, $bioperlSeq, $dbRlsId) = @_;

  my @bioperlSecondaryAccs = $bioperlSeq->get_secondary_accessions();

  foreach my $bioperlSecondaryAcc (@bioperlSecondaryAccs) {
    my $secondaryAccession = GUS::Model::DoTS::SecondaryAccs->new();
    $secondaryAccession->setSourceId($bioperlSeq->accession_number());
    $secondaryAccession->setSecondaryAccs($bioperlSecondaryAcc);
    $secondaryAccession->setExternalDatabaseReleaseId($dbRlsId);
  }
}

sub addReferences {
  my ($self, $bioperlSeq, $naSequence,) = @_;

  my $bioperlAnnotation = $bioperlSeq->annotation();

  my @bioperlReferences = $bioperlAnnotation->get_Annotations('reference');

  foreach my $bioperlReference (@bioperlReferences) {
    my $reference = GUS::Model::SRes::Reference->new() ;
    $reference->setAuthor($bioperlReference->authors());
    $reference->setTitle($bioperlReference->title());
    $reference->setJournalOrBookName($bioperlReference->location());

    unless ($reference->retrieveFromDB())  {
      $reference->submit();
    }

    my $refId = $reference->getId();
    my $naSequenceRef = 
      GUS::Model::DoTS::NASequenceRef->new({'reference_id'=>$refId});

    $naSequence->addChild($naSequenceRef);
  }
}

sub addComments {
  my ($self, $bioperlSeq, $naSequence) = @_;

  my $bioperlAnnotation = $bioperlSeq->annotation();

  my @bioperlComments = $bioperlAnnotation->get_Annotations('comment');
  foreach my $bioperlComment (@bioperlComments) {
    my $naComment = GUS::Model::DoTS::NAComment->
      new({'comment_string'=>$bioperlComment->text()});
    $naSequence->addChild($naComment);
  }
}

sub addKeywords {
  my ($self, $bioperlSeq, $naSequence) = @_;

  my $bioperlAnnotation = $bioperlSeq->annotation();

    my @bioperlKeywords = $bioperlAnnotation->get_Annotations('keyword');
    foreach my $bioperlKeyword (@bioperlKeywords) {
      next if $bioperlKeyword->value() eq '';
      my $keyword = 
	GUS::Model::DoTS::Keyword->new({'keyword'=>$bioperlKeyword->value()});

      unless ($keyword->retrieveFromDB())  {
	$keyword->submit();
      }

      my $keyId = $keyword->getId();
      my $naSequenceKeyword =
	GUS::Model::DoTS::NASequenceKeyword->new({'keyword_id'=>$keyId});

      $naSequence->addChild($naSequenceKeyword);
    }
}





###########################################################################
########     feature processing
###########################################################################

sub processFeatureTrees {
  my ($self, $bioperlSeq, $naSequenceId, $dbRlsId, $btFh) = @_;

  foreach my $bioperlFeatureTree ($bioperlSeq->get_SeqFeatures()) {

    $self->defaultPrintFeatureTree($btFh, $bioperlFeatureTree, "");

    # traverse bioperl tree to make gus skeleton (linked to bioperl objects)
    my $NAFeature =
      $self->makeGusFeatureSkeleton($bioperlFeatureTree, $bioperlSeq,
				    $naSequenceId, $dbRlsId);

    next unless $NAFeature;    # if we're supposed to ignore this type of feat

    # traverse bioperl tree again, applying qualifiers to the gus skeleton
    my $ignoreFeature = $self->applyQualifiers($bioperlFeatureTree);

    next if $ignoreFeature;

    $NAFeature->submit();
    $self->{fileFeatureTreeCount}++;
    $self->{totalFeatureTreeCount}++;
    $self->log("Inserted $self->{fileFeatureTreeCount} feature trees") 
      if $self->{fileFeatureTreeCount} % 100 == 0;
    $self->undefPointerCache();
    last if $self->checkTestNum();
  }
}

# make the gus feature tree in skeletal form, ie, with only the parent-child
# relations set, not attributes
sub makeGusFeatureSkeleton {
  my ($self, $bioperlFeature, $bioperlSeq,  $naSequenceId, $dbRlsId) = @_;

  my $tag = $bioperlFeature->primary_tag();

  my $featureMapper = $self->{mapperSet}->getMapperByFeatureName($tag);

  return undef if $featureMapper->ignoreFeature();

  my $tableName = $featureMapper->getGusTable();

  my $gusSkeletonMakerClassName
    = $self->{mapperSet}->getGusSkeletonMakerClassName();

  my $gusSkeleton;

  if ($tableName) {
    $gusSkeleton = $self->defaultGusSkeletonMaker($bioperlFeature, $naSequenceId, $dbRlsId);
  }
  else {
    eval {
      no strict "refs";
      eval "require $gusSkeletonMakerClassName";
      my $method = "${gusSkeletonMakerClassName}::makeGusSkeleton";
      my $taxonId = $self->getTaxonId($bioperlSeq);
      $gusSkeleton =
	&$method($self, $bioperlFeature, $naSequenceId, $dbRlsId, $taxonId);
    };

    my $err = $@;
    if ($err) { die "Can't run gus skeleton maker method '${gusSkeletonMakerClassName}::makeGusSkeleton'.  Error:\n $err\n"; }
  }

  return $gusSkeleton;
}

sub defaultGusSkeletonMaker {
  my ($self, $bioperlFeature, $naSequenceId, $dbRlsId) = @_; 

  my $tag = $bioperlFeature->primary_tag();

  my $featureMapper = $self->{mapperSet}->getMapperByFeatureName($tag);

  my $gusObjName = $featureMapper->getGusObjectName();

  return undef if $featureMapper->ignoreFeature();

  my $soTerm = $featureMapper->getSoTerm();

  my $feature = $self->makeSkeletalGusFeature($bioperlFeature, $naSequenceId,
					      $dbRlsId, $gusObjName, $soTerm);
  $bioperlFeature->{gusFeature} = $feature;

  if ($feature) {
    # recurse through the children
    foreach my $bioperlChildFeature ($bioperlFeature->get_SeqFeatures()) {
      my $childFeature = $self->defaultGusSkeletonMaker($bioperlChildFeature,
							$naSequenceId,
							$dbRlsId);

      if ($childFeature) { $feature->addChild($childFeature); }
    }
  }
  return $feature;
}

# make a bare bones gus feature object, setting only its absolute minimum state
sub makeSkeletalGusFeature {
  my ($self, $bioperlFeature, $naSequenceId, $dbRlsId, $gusObjName, $soTerm) = @_;

  my $feature = eval "{require $gusObjName; $gusObjName->new()}";

  $feature->setNaSequenceId($naSequenceId);
  $feature->setExternalDatabaseReleaseId($dbRlsId);

  $bioperlFeature->{gusFeature} = $feature;

  if ($soTerm) {
    $feature->setSequenceOntologyId($self->getSOPrimaryKey($soTerm));
    $feature->setName($bioperlFeature->primary_tag());
  } else {
    $feature->setName($bioperlFeature->primary_tag());
  }
  $feature->addChild($self->makeLocation($bioperlFeature->location(),
					 $bioperlFeature->strand()));
  #  $feature->submit();
  return $feature;
}

# return 1 if we should ignore the whole feature
sub applyQualifiers {
  my ($self, $bioperlFeature) = @_;

  my $tag = $bioperlFeature->primary_tag();

  my $featureMapper = $self->{mapperSet}->getMapperByFeatureName($tag);

  my @sortedTags = $featureMapper->sortTags($bioperlFeature->get_all_tags());
  my $ignoreFeature;
  foreach my $tag (@sortedTags) {
    my $gusFeature = $bioperlFeature->{gusFeature};
    my $ignoreFeature =
      $self->handleFeatureTag($bioperlFeature, $featureMapper, $gusFeature,$tag);
    return 1 if $ignoreFeature;
  }

  foreach my $bioperlChildFeature ($bioperlFeature->get_SeqFeatures()) {
    $self->applyQualifiers($bioperlChildFeature);
  }
  $self->{fileFeatureCount}++;
  $self->{totalFeatureCount}++;
  return 0;
}

sub makeLocation {
  my ($self, $f_location, $strand) = @_;

  if ($strand == 0) {
    $strand = '';
  }
  if ($strand == 1) {
    $strand = 0;
  }
  if ($strand == -1) {
    $strand = 1;
  }
   
  my $min_start = $f_location->min_start();
  my $max_start = $f_location->max_start();
  my $min_end = $f_location->min_end();
  my $max_end = $f_location->max_end();
  my $start_pos_type = $f_location->start_pos_type();
  my $end_pos_type = $f_location->end_pos_type();
  my $location_type = $f_location->location_type();
  my $start = $f_location->start();
  my $end = $f_location->end();

  if ($start > $end){
    if ($strand == 1){
      ($start, $end) = ($end, $start);
      ($max_start, $min_end) = ($min_end, $max_start);
      ($min_start, $max_end) = ($max_end, $min_start);
    }
    else{
      $self->log("The start value $start is greater than the end value $end, but the feature is on the @{[$strand ? -1 : +1]} strand.");
    }
  }

  unless ($min_start && $max_start) {
    if (!$min_start){
      $min_start = $max_start;
    }else{
      $max_start = $min_start;
    }
  }

  unless ($min_end && $max_end) {
    if (!$min_end){
      $min_end = $max_end;
    }else{
      $max_end = $min_end;
    }
  }

  my $gus_location = GUS::Model::DoTS::NALocation->new();
  $gus_location->setStartMax($max_start);
  $gus_location->setStartMin($min_start);
  $gus_location->setEndMax($max_end);
  $gus_location->setEndMin($min_end);
  $gus_location->setIsReversed($strand);
  $gus_location->setLocationType($location_type);

  return $gus_location;
}

sub getSeqTypeId {
  my ($self, $seqType) = @_;

  return $self->getIdFromCache('seqTypeCache',
			       $seqType,
			       'GUS::Model::DoTS::SequenceType',
			       "name",
			      );
}

sub getTaxonId {
  my ($self, $bioperlSeq) = @_;

  my $sciName = $self->getArg('organism');
  if (!$sciName){
    my $species = $bioperlSeq->species();

    if ($species) {
      # for exotic taxa, common name is more likely to match in NCBI
      # Taxonomy than whatever BioPerl guesses the genus/species names
      # to be:
      $sciName = $species->common_name();
    } else {
      $sciName = $self->getArg('defaultOrganism');
      if (!$sciName) {
	my $acc = $bioperlSeq->accession_number();
	$self->userError("Sequence '$acc' does not have organism information, and, you have not supplied a --defaultOrganism argument on the command line");
      }
      # this is an invalid assumption, e.g. 'Blastocrithidia sp. ex Triatoma garciabesi':
      # $sciName =~ /\w+ \w+/ || $self->userError("Command line argument '--defaultOrganism $sciName' is not in 'genus species' format");
    }
  }

  return $self->getIdFromCache('taxonNameCache',
			       $sciName,
			       'GUS::Model::SRes::TaxonName',
			       "name",
			       "taxon_id"
			      );

}

# handle feature tags.
# also: return true to ignore the feature;  return false to keep it
sub handleFeatureTag {
  my ($self, $bioperlFeature, $featureMapper, $feature, $tag) = @_;

  return 0 if ($featureMapper->ignoreTag($tag));

  # if special case, pass to special case handler
  # it creates a set of child objects to add to the feature
  # and optionally sets one or more columns in the feature
  if ($featureMapper->isSpecialCase($tag)) {
    my $handlerName = $featureMapper->getHandlerName($tag);
    my $method = $featureMapper->getHandlerMethod($tag);
    my $handler= $self->{mapperSet}->getHandler($handlerName);
    my $children = $handler->$method($tag, $bioperlFeature, $feature);

    return 1 if (!defined($children));  # ignore entire feature

    foreach my $child (@{$children}) {
      $feature->addChild($child);
    }
  }

  # standard case handles a simple assignment of a single tag value to
  # a column in the feature.  (multiple tag values must be a special 
  # case because they require a child per value)
  else {
    my $gusColumnName = $featureMapper->getGusColumn($tag);
    if ($tag && !$gusColumnName) { die "invalid tag, No Mapping [$tag]\n"; }

    my @tagValues = $bioperlFeature->get_tag_values($tag);
    if (scalar(@tagValues) == 1) { 
      if (@tagValues[0] ne "_no_value") { 
	$feature->set($gusColumnName, $tagValues[0]);
      }
    }
    else {
      my $featureName = $bioperlFeature->primary_tag();
      $self->error("Feature '$featureName' has more than one value for tag '$tag'\nThe values are:\n\t" . join("\n\t", @tagValues) . "\n");
    }
  }
  return 0;
}

# compensate from error in unflattener that gives no exon to rRNAs sometimes
sub handleExonlessRRNA {
  my ($self, $bioperlFeature, $feature, $naSequenceId, $dbRlsId) = @_;

  if ($bioperlFeature->primary_tag() eq 'rRNA'
      && (scalar($bioperlFeature->get_SeqFeatures()) == 0)) {
    my $location = $bioperlFeature->location();
    my @locations = $location->each_Location();
      foreach my $loc (@locations) {
         my $exonFeature = GUS::Model::DoTS::ExonFeature->new();
         $exonFeature->setNaSequenceId($naSequenceId);
         $exonFeature->setExternalDatabaseReleaseId($dbRlsId);
         $exonFeature->setName('Exon');
         #$exonFeature->addChild($self->makeLocation($bioperlFeature->location(),
         $exonFeature->addChild($self->makeLocation($loc,
					            $bioperlFeature->strand()));
         #exonFeature->setSequenceOntologyId();
         $feature->addChild($exonFeature);
      }
  }
}

# inidvidual preprocessors can provide their own printer.  use this if none
sub defaultPrintFeatureTree {
  my ($self, $btFh, $bioperlFeatureTree, $indent) = @_;

  return unless $btFh;

  $btFh->print("\n") unless $indent;
  my $type = $bioperlFeatureTree->primary_tag();
  $btFh->print("$indent< $type >\n");
  my @locations = $bioperlFeatureTree->location()->each_Location();
  foreach my $location (@locations) {
    my $seqId =  $location->seq_id();
    my $start = $location->start();
    my $end = $location->end();
    my $strand = $location->strand();
    $btFh->print("$indent$seqId $start-$end strand:$strand\n");
  }
  my @tags = $bioperlFeatureTree->get_all_tags();
  foreach my $tag (@tags) {
    my @annotations = $bioperlFeatureTree->get_tag_values($tag);
    foreach my $annotation (@annotations) {
      if (length($annotation) > 50) {
	$annotation = substr($annotation, 0, 50) . "...";
      }
      $btFh->print("$indent$tag: $annotation\n");
    }
  }

  foreach my $bioperlChildFeature ($bioperlFeatureTree->get_SeqFeatures()) {
    $self->defaultPrintFeatureTree($btFh, $bioperlChildFeature, "  $indent");
  }
}

##############################################################################
# Utilities
##############################################################################

sub checkTestNum {
  my ($self) = @_;

  return $self->getArg('testNumber')
    && $self->getArg('testNumber') == $self->{totalFeatureTreeCount};
}

sub getIdFromCache {
  my ($self, $cacheName, $name, $type, $field, $idColumn) = @_;

  if ($self->{$cacheName} == undef) {
    $self->{$cacheName}= {};
  }

  $name || die "Attempting to get id from cache with null name";

  if (!$self->{$cacheName}->{$name}) {
    my $obj = $type->new({$field => $name });
    $obj->retrieveFromDB() 
      || die "Failed to retrieve $type id for $field = '$name'";
    if ($idColumn) {
      $self->{$cacheName}->{$name} = $obj->get($idColumn);
    } else {
      $self->{$cacheName}->{$name} = $obj->getId();
    }
  }
  return $self->{$cacheName}->{$name};
}

sub getSOPrimaryKey {
  my ($self, $soTerm) = @_;

  if (!$self->{soPrimaryKeys}) {
    my $soCvsVersion = $self->getArg('soCvsVersion');

    $soCvsVersion or $self->userError("You are using Sequence Ontology terms but have not provided a --soCvsVersion on the command line");

    my $dbh = $self->getQueryHandle();
    my $sql = "
select term_name, sequence_ontology_id
from sres.SequenceOntology
where so_cvs_version = '$soCvsVersion'
";
    my $stmt = $dbh->prepareAndExecute($sql);
    while (my ($term, $pk) = $stmt->fetchrow_array()){
      $self->{soPrimaryKeys}->{$term} = $pk;
    }

    my @badSoTerms;
    foreach my $soTerm (keys %{$self->{soPrimaryKeys}}) {
      push(@badSoTerms, $soTerm) unless $self->{soPrimaryKeys}->{$soTerm};
    }

    my $mappingFile = $self->getArg('mapFile');
    (scalar(@badSoTerms) == 0) or $self->userError("Mapping file '$mappingFile' or cmd line args are using the following SO terms that are not found in the database for SO CVS version '$soCvsVersion': " . join(", ", @badSoTerms));
  }
  $self->error("Can't find primary key for SO term '$soTerm'")
    unless $self->{soPrimaryKeys}->{$soTerm};
  return $self->{soPrimaryKeys}->{$soTerm};
}

sub initHandlerExternalDbs {
  my ($self) = @_;

  $self->{handlerExternalDbRlsIds} = {};

  return unless $self->getArg('handlerExternalDbs');

  my $dbDescriptors = $self->getArg('handlerExternalDbs');

  foreach my $dbDescriptor (@{$dbDescriptors}) {
    my @split = split(/\:/, $dbDescriptor);
    $self->userError("Invalid argument to --handlerExternalDbs: '$dbDescriptor'") unless scalar(@split) == 3;
    my ($tag, $dbName, $dbRelease) = @split;
    $self->userError("Argument --handlerExternalDbs uses tag '$tag' more than once")
      if $self->{handlerExternalDbRlsIds}->{$tag};
    my $dbRlsId = $self->getExtDbRlsId($dbName, $dbRelease);
    $self->{handlerExternalDbRlsIds}->{$tag} = $dbRlsId;
  }
}

sub getExternalDbRlsIdByTag {
  my ($self, $tag) = @_;

  return $self->{handlerExternalDbRlsIds}->{$tag};
}


############################################################################
# Aggregator private class
############################################################################

package Feature::Aggregator;

sub new {
  my ($class, $agg, $grouptag) = @_;
  $class = ref $class || $class;

  my $self = { };
  bless $self, $class;

  eval "require $agg"; $agg = $agg->new();
  $self->{_matchsub} = $self->match_sub($agg);
  $self->{_main} = $agg->main_name;
  $self->{_grouptag} = $grouptag;

  return $self;
}

sub match_sub {
  my ($self, $agg) = @_;
  my @match = ($agg->main_name, $agg->part_names);
  my $matchre = join("|", map { "\Q$_\E" } @match);
  return sub {
    my $f = shift;
    $f->primary_tag =~ m/$matchre/i;
  }
}

sub aggregate {

  my ($self, $features) = @_;

  my @keep;
  my %groups;
  my @grouptags = @{$self->{_grouptag}};
  for my $feature (@$features) {
    if ($self->{_matchsub}->($feature)) {
      my $group;
      for my $grouptag (@grouptags) {
	($group) = $feature->each_tag_value($grouptag)
	  if ($feature->has_tag($grouptag));
      }
      die "No group tag in @{[join(', ', @grouptags)]}!" unless $group;
      if ($feature->primary_tag =~ m/$self->{_main}/i) {
	$groups{$feature->source_tag}->{$group}{base} = $feature;
	push @keep, $feature;
      } else {
	push @{$groups{$feature->source_tag}->{$group}{subparts}}, $feature;
      }
    } else {
      push @keep, $feature;
    }
  }

  for my $groups (values %groups) {
    while (my ($group, $parts) = each %$groups) {
      my ($base, $subparts) = @{$parts}{qw(base subparts)};
      unless ($base) {
	$base = $subparts->[0]->clone; # auto-vivify top-level feature
	push @keep, $base;
      }
      $base->add_SeqFeature($_) for @$subparts;
    }
  }

  @$features = @keep;
}



return 1;

