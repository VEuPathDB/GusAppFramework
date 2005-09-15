package GUS::Supported::Plugin::InsertSequenceFeatures;

# todo:
#  - handle seqVersion more robustly
#  - add logging info
#  - undo

@ISA = qw(GUS::PluginMgr::Plugin);

use strict;

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
use GUS::Model::DoTS::NAEntry;
use GUS::Model::DoTS::SecondaryAccs;
use GUS::Model::DoTS::NALocation;
use GUS::Model::DoTS::NASequenceRef;
use GUS::Model::DoTS::Keyword;
use GUS::Model::DoTS::NASequenceKeyword;
use GUS::Model::DoTS::NAComment;

#USED BY TRANSCRIPT FEATURES TO LOAD THE TRANSLATED PROTEIN SEQ
use GUS::Model::DoTS::TranslatedAAFeature;
use GUS::Model::DoTS::TranslatedAASequence;

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

This plugin is designed to be flexible in its mapping from the features and qualifiers found in the input to the tables in GUS.  The flexibility is specified in the "XML mapping file" provided on the command line (--mapFile).

A default mapping is provided as a reference  (see \$GUS_HOME/config/genbank2gus.xml).  That file provides a mapping for the complete genbank feature table.

It is often the case that your input may come from unofficial sources that, while conforming to one of the bioperl supported formats, invent features or qualifiers, and stuff unexpected values into already existing qualifiers.

In that case, you will need to write your own mapping file.  Use the provided default as an example.  The main purpose of the file is to specify which subclass of NAFeature should store the input feature, and, which columns should store which qualifiers.

There is an additional level of configurability provided by "plugable" qualifier handlers.  As you will see in the default XML file, some qualifiers do not fit neatly into a column in the feature table.  Those that don't are called "special cases."  In the XML file you can declare the availability of one or more special case qualifier handlers to handle those special cases   The default file declares one of these at the top of the file.  Your XML file can declare additional handlers that you write.  (See the code in the default handler to learn how to write your own.)  In the XML file, qualifiers that need special handling specify the name of the handler object and a method in it to call to handle the qualifier.
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
   ['DoTS.NAEntry', ''],
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
Restart is not supported.  Coming soon will be "undo," which will at least provide a way to back out failed results.
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

   fileArg({name => 'seqFile',
	    descr => 'Text file containing features and optionally sequence data',
	    constraintFunc=> undef,
	    reqd  => 1,
	    isList => 0,
	    mustExist => 1,
	    format=>'Text'
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
	      descr => 'Format of external data being loaded.  See Bio::SeqIO::new() for allowed options.  GFF2 and gff3 are an additional options',
	      constraintFunc=> undef,
	      reqd  => 1,
	      isList => 0
	     }),

   enumArg({name => 'gffFormat',
	      descr => 'Format (version) of GFF, if GFF is the input format',
	      constraintFunc=> undef,
	      reqd  => 0,
	      isList => 0,
	      enum=>"2,3",
              default => 2,
	     }),

   stringArg({name => 'gff2GroupTag',
	      descr => 'Name of the tag to be used for GFF2 grouping',
	      constraintFunc=> undef,
	      reqd  => 0,
	      isList => 1,
              default => "GenePrediction,Gene",
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

   stringArg({name => 'downloadURL',
	      descr => 'URL from whence this file came should include filename',
	      constraintFunc=> undef,
	      reqd  => 0,
	      isList => 0
	     }),

   stringArg({name => 'extDbRlsDate',
	      descr => 'Release date of external data source',
	      constraintFunc=> undef,
	      reqd  => 0,
	      isList => 0
	     }),

   stringArg({name => 'filename',
	      descr => 'Name of the file in the resource (including path)',
	      constraintFunc=> undef,
	      reqd  => 0,
	      isList => 0
	     }),

   stringArg({name => 'description',
	      descr => 'a quoted description of the resource, should include the download date',
	      constraintFunc=> undef,
	      reqd  => 0,
	      isList => 0
	     }),

   stringArg({name => 'failDir',
	      descr => 'where to place a failure log',
	      constraintFunc=> undef,
	      reqd  => 0,
	      isList => 0
	     }),

   stringArg({name => 'projectName',
	      descr => 'project this data belongs to - must in entered in GUS',
	      constraintFunc=> undef,
	      reqd  => 0,
	      isList => 0
	     }),

   stringArg({name => 'defaultOrganism',
	      descr => 'The organism name to use if a sequence in the input file does not provide organism information.  Eg "Plasmodium falciparum"',
	      constraintFunc=> undef,
	      reqd  => 0,
	      isList => 0
	     }),

   integerArg({name => 'restartPoint',
	       descr => 'Point at which to restart submitting data.  Format = SEQ:[ID] or FEAT:[ID]',
	       constraintFunc=> undef,
	       reqd  => 0,
	       isList => 0
	      }),

   integerArg({name => 'testNumber',
	       descr => 'number of entries to do test on',
	       constraintFunc=> undef,
	       reqd  => 0,
	       isList => 0
	      }),

   booleanArg({name => 'isUpdateMode',
	       descr => 'whether this is an update mode',
	       constraintFunc=> undef,
	       reqd  => 0,
	       isList => 0,
	       default => 0,
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

sub run{
  my ($self) = @_;

  $self->{mapperSet} =
    GUS::Supported::BioperlFeatMapperSet->new($self->getArg('mapFile'));

  my $dbRlsId = $self->getExtDbRlsId($self->getArg('extDbName'),
				     $self->getArg('extDbRlsVer'))
    or die "Couldn't retrieve external database!\n";

  $self->getSoPrimaryKeys(); ## pre-load into memory and validate

  $self->{immedFeatureCount} = 0;
  my $featureTreeCount=0;
  my $seqCount=0;
  my $bioperlSeqIO = $self->getSeqIO();

  while (my $bioperlSeq = $bioperlSeqIO->next_seq() ) {

    my $naSequence;
    if ($self->getArg('naSequenceSubclass')) {
      $naSequence = $self->retrieveNASequence($bioperlSeq);
    } else {
      $naSequence = $self->bioperl2NASequence($bioperlSeq);
      $naSequence->submit();
    }

    # use id instead of object because object is zapped by undefPointerCache
    my $naSequenceId = $naSequence->getNaSequenceId();

    $seqCount++;

    $self->unflatten($bioperlSeq)
      unless ($self->getArg("fileFormat") =~ m/^gff$/i);

    foreach my $bioperlFeatureTree ($bioperlSeq->get_SeqFeatures()) {
      my $NAFeature = $self->makeFeature($bioperlFeatureTree, $naSequenceId);
      if (!$NAFeature) { next; }
      $NAFeature->submit();
      $featureTreeCount++;
      $self->log("Inserted $featureTreeCount feature trees") 
	if $featureTreeCount % 100 == 0;
    }
    $self->undefPointerCache();
  }

  my $filename = $self->getArg('seqFile');
  my $format = $self->getArg('fileFormat');
  $self->setResultDescr("Processed: $filename : $format \n\t Seqs Inserted: $seqCount \n\t Features Inserted: $self->{immedFeatureCount} \n\t Feature Trees Inserted: $featureTreeCount");
}

sub unflatten {
  my ($self, $seq) = @_;

  my $unflattener =
    $self->{_unflattener} ||= Bio::SeqFeature::Tools::Unflattener->new();

  $unflattener->unflatten_seq(-seq => $seq,
			      -use_magic => 1);
}

sub getSeqIO {
  my ($self) = @_;

  my $format = $self->getArg('fileFormat');

  my $bioperlSeqIO;

  # SDF: what does bioperl do on a parsing error?   does it die?   if so,
  # we probably want to catch that error, and add to it the filename we are
  # parsing, if they don't already state that

  # AJM: it throws an error (i.e. dies with context) during next_seq
  # (which is when/where the parsing is happening, not here during IO
  # construction); it also can throw warnings which you might also
  # want to catch via a $SIG{__WARN__} handler

  if ($format =~ m/^gff$/i) {
    $bioperlSeqIO = $self->convertGFFStreamToSeqIO();
  } else {
    $bioperlSeqIO = Bio::SeqIO->new(-format => $format,
				    -file   => $self->getArg('seqFile'));
  }

  return $bioperlSeqIO;
}

sub convertGFFStreamToSeqIO {

  my $self = shift;

  # convert a GFF "features-referring-to-sequence" stream into a
  # "sequences-with-features" stream; also aggregate grouped features.
  my $gffIO = Bio::Tools::GFF->new(-file => $self->getArg('seqFile'),
				   -gff_format => $self->getArg('gffFormat')
				  );

  # a list of "standard" feature aggregator types for GFF2 support;
  # only "processed_transcript" for now, but leaving room for others
  # if necessary.
  my @aggregators = qw(Bio::DB::GFF::Aggregator::processed_transcript);

  # build Feature::Aggregator objects for each aggregator type:
  @aggregators =
    map {
      Feature::Aggregator->new($_, $self->getArg("gff2GroupTag"));
    } @aggregators;

  my %seqs; my @seqs;
  while (my $feature = $gffIO->next_feature()) {
    push @{$seqs{$feature->seq_id}}, $feature;
  }

  while (my ($seq_id, $features) = each %seqs) {
    my $seq = Bio::Seq->new( -alphabet => 'dna',
			     -display_id => $seq_id,
			     -accession_number => $seq_id,
			   );

    if ($self->getArg('gffFormat') < 3) {
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

###########################################################################
########     sequence processing
###########################################################################

# if the input does not include sequence, get it from the db
sub retrieveNASequence {
  my ($self, $bioperlSeq) = @_;

  my $dbRlsId = $self->getExtDbRlsId($self->getArg('extDbName'),
				     $self->getArg('extDbRlsVer'));

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
  my ($self, $bioperlSeq) = @_;

  my $dbRlsId = $self->getExtDbRlsId($self->getArg('extDbName'),
				     $self->getArg('extDbRlsVer'));

  my $naSequence = $self->constructNASequence($bioperlSeq, $dbRlsId);

  my $naEntry = $self->makeNAEntry($bioperlSeq);

  $naSequence->addChild($naEntry);

  $self->addSecondaryAccs($bioperlSeq, $naEntry, $dbRlsId);

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
  my $naSequence = GUS::Model::DoTS::ExternalNASequence->
    new({ external_database_release_id => $dbRlsId,
	  source_id => $bioperlSeq->accession_number()});

  my $seqType = $self->getArg('seqType');
  if ($seqType) { 
    $naSequence->setSequenceTypeId($self->getSeqTypeId($seqType));
  }
  my $soTerm = $self->getArg('seqSoTerm');
  if ($soTerm) {
    $naSequence->setSequenceOntologyId($self->{soPrimaryKeys}->{$soTerm});
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
  my ($self, $bioperlSeq, $naEntry, $dbRlsId) = @_;

  my @bioperlSecondaryAccs = $bioperlSeq->get_secondary_accessions();

  foreach my $bioperlSecondaryAcc (@bioperlSecondaryAccs) {
    my $secondaryAccession = GUS::Model::DoTS::SecondaryAccs->new();
    $secondaryAccession->setSourceId($bioperlSeq->accession_number());
    $secondaryAccession->setSecondaryAccs($bioperlSecondaryAcc);
    $secondaryAccession->setExternalDatabaseReleaseId($dbRlsId);
    $naEntry->addChild($secondaryAccession);
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


sub makeNAEntry {
  my ($self, $bioperlSeq) = @_;

  my $NAEntry = GUS::Model::DoTS::NAEntry->new();
  $NAEntry->setSourceId($bioperlSeq->accession_number());
  $NAEntry->setDivision($bioperlSeq->division());
  $NAEntry->setVersion($bioperlSeq->seq_version());
  return $NAEntry;
}



###########################################################################
########     feature processing
###########################################################################

sub makeFeature {
  my ($self, $bioperlFeature, $naSequenceId) = @_; 


  # there is an error in the bioperl unflattener such that there may be
  # exon-less rRNAs (eg, in C.parvum short contigs containing only rRNAs)
  # this method has extra logic to compensate for that problem.

  # map the immediate bioperl feature into a gus feature
  my $feature = $self->makeImmediateFeature($bioperlFeature, $naSequenceId);

  if ($feature) {
    # call method to handle unflattener error of giving rRNAs no exon.
    $self->handleExonlessRRNA($bioperlFeature, $feature,$naSequenceId);

    # recurse through the children
    foreach my $bioperlChildFeature ($bioperlFeature->get_SeqFeatures()) {
      my $childFeature =
	$self->makeFeature($bioperlChildFeature, $naSequenceId);
      $feature->addChild($childFeature);
    }
  }
  return $feature;
}

# make a feature itself without worrying about its children
sub makeImmediateFeature {
  my ($self, $bioperlFeature, $naSequenceId) = @_;


  my $tag = $bioperlFeature->primary_tag();

  my $featureMapper = $self->{mapperSet}->getMapperByFeatureName($tag);

  return undef if $featureMapper->ignoreFeature();

  my $gusObjName = $featureMapper->getGusObjectName();

  my $feature = eval "{require $gusObjName; $gusObjName->new()}";

  $feature->setNaSequenceId($naSequenceId);
  $feature->setName($bioperlFeature->primary_tag());

  my $soTerm = $featureMapper->getSoTerm();
  if ($soTerm) {
    $feature->setSequenceOntologyId($self->{soPrimaryKeys}->{$soTerm});
  }
  $feature->addChild($self->makeLocation($bioperlFeature->location(),
					 $bioperlFeature->strand()));

  foreach my $tag ($bioperlFeature->get_all_tags()) {
    $self->handleFeatureTag($bioperlFeature, $featureMapper, $feature, $tag);
  }

  $self->{immedFeatureCount}++;
  return $feature;
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

  my $gus_location = GUS::Model::DoTS::NALocation->new();
  $gus_location->setStartMax($max_start);
  $gus_location->setStartMin($min_start);
  $gus_location->setEndMax($max_end);
  $gus_location->setEndMin($min_end);
  $gus_location->setIsReversed($strand);
  $gus_location->setLocationType($location_type);

  return $gus_location;
}

sub getSoGusId {
  my ($self, $SOname) = @_;

  return $self->getIdFromCache('seqOntologyCache',
			       $SOname,
			       'GUS::Model::SRes::SequenceOntology',
			       "so_id",
			      );

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

  my $species = $bioperlSeq->species();
  my $sciName;
  if ($species) {
    $sciName = $species->genus() . " " . $species->species();
  } else {
    $sciName = $self->getArg('defaultOrganism');
    if (!$sciName) {
      my $acc = $bioperlSeq->accession_number();
      $self->userError("Sequence '$acc' does not have organism information, and, you have not supplied a --defaultOrganism argument on the command line");
    }
    $sciName =~ /\w+ \w+/ || $self->userError("Command line argument '--defaultOrganism $sciName' is not in 'genus species' format");
  }


  return $self->getIdFromCache('taxonIdCache',
			       $sciName,
			       'GUS::Model::SRes::TaxonName',
			       "name",
			      );

}

sub handleFeatureTag {
  my ($self, $bioperlFeature, $featureMapper, $feature, $tag) = @_;

  return if ($featureMapper->ignoreTag($tag));

  # if special case, pass to special case handler
  # it creates a set of child objects to add to the feature
  # and optionally sets one or more columns in the feature
  if ($featureMapper->isSpecialCase($tag)) {
    my $handlerName = $featureMapper->getHandlerName($tag);
    my $method = $featureMapper->getHandlerMethod($tag);
    my $handler= $self->{mapperSet}->getHandler($handlerName);
    my @children = $handler->$method($tag, $bioperlFeature, $feature);

    foreach my $child (@children) {
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
}

# compensate from error in unflattener that gives no exon to rRNAs sometimes
sub handleExonlessRRNA {
  my ($self, $bioperlFeature, $feature, $naSequenceId) = @_;

  if ($bioperlFeature->primary_tag() eq 'rRNA'
      && (scalar($bioperlFeature->get_SeqFeatures()) == 0)) {
    my $exonFeature = GUS::Model::DoTS::ExonFeature->new();
    $exonFeature->setNaSequenceId($naSequenceId);
    $exonFeature->setName('Exon');
    $exonFeature->addChild($self->makeLocation($bioperlFeature->location(),
					       $bioperlFeature->strand()));
    #exonFeature->setSequenceOntologyId();
    $feature->addChild($exonFeature);
  }
}




##############################################################################
# Utilities
##############################################################################

sub getIdFromCache {
  my ($self, $cacheName, $name, $type, $field) = @_;

  if ($self->{$cacheName} == undef) {
    $self->{$cacheName}= {};
  }

  $name || die "Attempting to get id from cache with null name";

  if (!$self->{$cacheName}->{$name}) {
    my $obj = $type->new({$field => $name });
    $obj->retrieveFromDB() 
      || die "Failed to retrieve $type id for $field = '$name'";
    $self->{$cacheName}->{$name} = $obj->getId();
  }
  return $self->{$cacheName}->{$name};
}

# for all SO terms used, find the GUS primary key
# include in search all SO terms in the mapping file, and the seq SO term
# from the cmd line
sub getSoPrimaryKeys {
  my ($self) = @_;

  my @soTerms = $self->{mapperSet}->getAllSoTerms();
  my $seqSoTerm = $self->getArg('seqSoTerm');
  if ($seqSoTerm) { push(@soTerms, $seqSoTerm); }

  return if (scalar(@soTerms) == 0);

  my $terms = join("', '", @soTerms);
  $terms = "'$terms'";

  my $soCvsVersion = $self->getArg('soCvsVersion');

  $soCvsVersion or $self->userError("You are using Sequence Ontology terms but have not provided a --soCvsVersion on the command line");

  my $dbh = $self->getQueryHandle();
  my $sql = "
select term_name, sequence_ontology_id
from sres.SequenceOntology
where term_name in ($terms)
and so_cvs_version = '$soCvsVersion'
";
  my $stmt = $dbh->prepareAndExecute($sql);
  while (my ($term, $pk) = $stmt->fetchrow_array()){
    $self->{soPrimaryKeys}->{$term} = $pk;
  }

  my @badSoTerms;
  foreach my $soTerm (@soTerms) {
    push(@badSoTerms, $soTerm) unless $self->{soPrimaryKeys}->{$soTerm};
  }

  my $mappingFile = $self->getArg('mapFile');
  (scalar(@badSoTerms) == 0) or $self->userError("Mapping file '$mappingFile' or cmd line args are using the following SO terms that are not found in the database for SO CVS version '$soCvsVersion': " . join(", ", @badSoTerms));
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
