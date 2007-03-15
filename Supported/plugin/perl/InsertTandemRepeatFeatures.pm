package GUS::Supported::Plugin::InsertTandemRepeatFeatures;

@ISA = qw(GUS::PluginMgr::Plugin);

# ----------------------------------------------------------------------

use strict;

use GUS::PluginMgr::Plugin;
use GUS::PluginMgr::PluginUtilities;

use FileHandle;

use GUS::Model::DoTS::TandemRepeatFeature;
use GUS::Model::DoTS::NALocation;
use GUS::Model::DoTS::ExternalNASequence;
use GUS::Model::DoTS::VirtualSequence;

my $argsDeclaration =
[

 fileArg({name           => 'tandemRepeatFile',
	  descr          => 'File containing the tandem Repeat Feature Data',
	  reqd           => 1,
	  mustExist      => 1,
	  format         => 'see notes',
	  constraintFunc => undef,
	  isList         => 0, 
	 }),

 stringArg({ descr => 'Name of the External Database',
	     name  => 'extDbName',
	     isList    => 0,
	     reqd  => 1,
	     constraintFunc => undef,
	   }),

 stringArg({ descr => 'Version of the External Database Release',
	     name  => 'extDbVersion',
	     isList    => 0,
	     reqd  => 1,
	     constraintFunc => undef,
	   }),
# enumArg({ descr => 'Table in which to find sequences: DoTS::ExternalNASequence or DoTS::VirtualSequence',
#           name  => 'seqTable',
#           isList    => 0,
#           reqd  => 1,
#           constraintFunc => undef,
#           enum => "DoTS::ExternalNASequence, DoTS::VirtualSequence",
#           }),
];

my $purpose = <<PURPOSE;
The purpose of this plugin is to load the output of Tandom Repeat Finder software or similar into DoTS::TandemRepeatFeature.
PURPOSE

my $purposeBrief = <<PURPOSE_BRIEF;
$purpose
PURPOSE_BRIEF

my $notes = <<NOTES;
This plugin is written for TandemRepeatFinder (TRF) and the .dat
file this software produces.  It is not necessary that this 
is used but the input file to the plugin must be in the following
format:

>>> begin snippet >>>

Sequence: source_id




Parameters: 2 7 7 80 10 50 500



1 2409 171 14.2 169 70 7 1398 28 17 20 34 1.95 TAGACAGA

1 2410 340 7.1 341 85 1 3083 28 17 20 34 1.95 TAGACAGA


<<< end snippet <<<

The line of data is space separated with each of the following values (start, stop, and fullSequence are NOT loaded):

 start, stop, periodSize, copyNumber, consensusSize, 
 percentMatches, percentIndels, score, aCount, cCount, 
 gCount, tCount, entropy, consensus, fullSequence

The parameters are space separated each should be represented in the paramKeyFile
NOTES

my $tablesAffected = <<TABLES_AFFECTED;
Dots::TandemRepeatFeature
TABLES_AFFECTED

my $tablesDependedOn = <<TABLES_DEPENDED_ON;
SRes::ExternalDatabase, SRes::ExternalDatabaseRelease, Dots::NaFeature
TABLES_DEPENDED_ON

my $howToRestart = <<RESTART;
No Restart utilities for this plugin.
RESTART

my $failureCases = <<FAIL_CASES;
FAIL_CASES

my $documentation = { purpose          => $purpose,
		      purposeBrief     => $purposeBrief,
		      notes            => $notes,
		      tablesAffected   => $tablesAffected,
		      tablesDependedOn => $tablesDependedOn,
		      howToRestart     => $howToRestart,
		      failureCases     => $failureCases };

my $tandomRepeatCount;

# ----------------------------------------------------------------------

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  $self->initialize({ requiredDbVersion => 3.5,
		      cvsRevision       => '$Revision$',
		      name              => ref($self),
		      argsDeclaration   => $argsDeclaration,
		      documentation     => $documentation});

  return $self;
}

# ======================================================================


sub run {
  my ($self) = @_;

  my $dbReleaseId = $self->getExtDbRlsId($self->getArgs()->{extDbName}, 
					 $self->getArgs()->{extDbVersion});

  my $fn = $self->getArgs()->{tandemRepeatFile};
  open(FILE, $fn) || die "Cannot open $fn for reading:$!";

  my $expectedValues = [ "start", "stop", "periodSize", "copyNumber", "consensusSize", 
                         "percentMatches", "percentIndels", "score", "aCount", "cCount", 
                         "gCount", "tCount", "entropy", "consensus", "fullSequence" ];

  my ($sequence, $parameters, $start);
  my $count = 1;

  while(<FILE>) {
    chomp;

    if($count++ % 1000 == 0) {
      $self->log("Processed $count lines of data file");
    }

    next if(!$_);

    if(/Sequence: (\S+)/) {
      $sequence = $1;
    }
    elsif(/Parameters: ((?:\d+\s*)+)/) {
      $parameters = $1;
      next;
    }
    else {
      next if(!$sequence);
      $self->_loadTandemRepeat($sequence, $parameters, $_, $expectedValues, $dbReleaseId);
    }
  }
  close(FILE);

  return("Inserted $tandomRepeatCount DoTS::TandemRepeatFeatures");
}

#------------------------------------------------------------------------

sub _loadTandemRepeat {
  my ($self, $seq, $param, $dat, $expected, $dbReleaseId) = @_;

  #my ($table) = $self->getArg("seqTable");
  #$table = "GUS::Model::$table";

  my $dataHash = {};
  my @data = split(' ', $dat);

  if(scalar(@data) != scalar(@$expected)) {
    die "Unrecognized value $dat in data file: $!";
  }

  for(my $i; $i < scalar(@$expected); $i++) {
    my $nm = $expected->[$i];
    my $value = $data[$i];

    $dataHash->{$nm} = $value;
  }

  my $name = "TR: $seq";

  my $tandemRepeat = GUS::Model::DoTS::TandemRepeatFeature->
    new({ name                           => $name,
          external_database_release_id   => $dbReleaseId,
          source_id                      => $seq,
          period                         => $dataHash->{periodSize},
          copynum                        => $dataHash->{copyNumber},
          consensus_size                 => $dataHash->{consensusSize},
          percent_match                  => $dataHash->{percentMatches},
          percent_indel                  => $dataHash->{percentIndels},
          score                          => $dataHash->{score},
          a_count                        => $dataHash->{aCount},
          c_count                        => $dataHash->{cCount},
          g_count                        => $dataHash->{gCount},
          t_count                        => $dataHash->{tCount},
          entropy                        => $dataHash->{entropy},
          consensus                      => $dataHash->{consensus},
        });

  my $seqArgs = {external_database_release_id => $dbReleaseId,
                 source_id =>$seq};

  my $extNaSeq = GUS::Model::DoTS::ExternalNASequence->new($seqArgs);

  #Try to get a Virtual Sequence if there is no ExternalNASequence
  if(!$extNaSeq->retrieveFromDB()) {
    $extNaSeq = GUS::Model::DoTS::VirtualSequence->new($seqArgs);
    if(!$extNaSeq->retrieveFromDB()) {
      die "Cannot Retrieve NASequence with source_id $seq and extdbrel_id $dbReleaseId";
    }
  }

  $tandemRepeat->setParent($extNaSeq);

  my $naLoc = $self->getNaLoc($dataHash->{start},$dataHash->{stop});

  $tandemRepeat->addChild($naLoc);

  $tandemRepeat->submit();
  $tandomRepeatCount++;

  $self->undefPointerCache();
}

sub getNaLoc {
  my ($self,$start,$stop) = @_;

  my $naLoc = GUS::Model::DoTS::NALocation->
    new({'start_min' => $start,
	 'start_max' => $start,
	 'end_min' => $stop,
	 'end_max' => $stop
	 });

  return $naLoc;
}

1;
