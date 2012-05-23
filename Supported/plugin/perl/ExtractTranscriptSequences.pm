package GUS::Supported::Plugin::ExtractTranscriptSequences;
@ISA = qw( GUS::PluginMgr::Plugin);

use GUS::PluginMgr::Plugin;
use GUS::Model::DoTS::Transcript;
use GUS::Model::DoTS::ExonFeature;
use GUS::Model::DoTS::NASequence;
use CBIL::Bio::SequenceUtils;
use FileHandle;
use Carp;
use lib "$ENV{GUS_HOME}/lib/perl";
use strict;


$| = 1;

sub getArgsDeclaration {

  my $argsDeclaration =
    [
     stringArg({ name => 'extDbName',
		 descr => 'External Database name of the transcripts to be translated',
		 constraintFunc => undef,
		 isList => 0,
		 reqd => 1,
	       }),

     stringArg({ name => 'extDbRlsVer',
		 descr => 'Extexrnal Database Release version of the transcripts to be translated',
		 constraintFunc => undef,
		 isList => 0,
		 reqd => 1,
	       }),

     stringArg({ name => 'seqExtDbName',
		 descr => 'External Database name of the sequence where transcript feature is found',
		 constraintFunc => undef,
		 isList => 0,
		 reqd => 0,
	       }),

     stringArg({ name => 'seqExtDbRlsVer',
		 descr => 'Extexrnal Database Release version of the sequence where transcript feature is found',
		 constraintFunc => undef,
		 isList => 0,
		 reqd => 0,
	       }),

     stringArg({ name => 'sequenceFile',
		 descr => 'file for fasta formatted sequences',
		 constraintFunc => undef,
		 reqd => 1,
		 isList => 0,
	       }),
     booleanArg({ name => 'cds',
                 descr => 'coding sequence only with UTRs removed, default is entire spliced transcript',
                 constraintFunc => undef,
                 reqd => 0,
                 isList => 0,
               }),
    ];

  return $argsDeclaration;
}

sub getDocumentation {

  my $purposeBrief = <<PURPOSEBRIEF;
Prints a fasta file of transcript sequences.
PURPOSEBRIEF

  my $purpose = <<PLUGIN_PURPOSE;
Extracts and concatenates exon sequences for transcripts and prints to a fasta file..
PLUGIN_PURPOSE

  my $tablesAffected =
    [
     ['DoTS.TranslatedAASequence' =>
      'Translations are deposited in the `sequence` field of DoTS.TranslatedAASequence'
     ],
     ['DoTS.TranslatedAAFeature' =>
      'TranslatedAASequences are associated with Transcripts by TranslatedAAFeatures'
     ],
    ];

  my $tablesDependedOn = 
    [
     ['DoTS.Transcript' =>
      'rows from Transcript are fetched for a specific database release id'
     ],
     ['DoTS.ExonFeature' =>
      'ExonFeature rows are retrieved for each transcript, and their sequences are concatenated in the appropriate order'
     ],
     ['DoTS.NASequence' =>
      'sequences are retrieved using getFeatureSequence'
     ],

    ];

  my $howToRestart = <<PLUGIN_RESTART;
Retarted plugin will overwrite the ouput file.
PLUGIN_RESTART

  my $failureCases = <<PLUGIN_FAILURE_CASES;
Transcripts without exons or sequence will fail.
PLUGIN_FAILURE_CASES

  my $notes = <<PLUGIN_NOTES;
No additional notes.
PLUGIN_NOTES

  my $documentation = { purposeBrief => $purposeBrief,
			purpose => $purpose,
			tablesAffected => $tablesAffected,
			tablesDependedOn => $tablesDependedOn,
			howToRestart => $howToRestart,
			failureCases => $failureCases,
			notes => $notes,
		      };

  return ($documentation);
}


sub new {
   my $class = shift;
   my $self = {};
   bless($self, $class);

      my $documentation = &getDocumentation();
      my $args = &getArgsDeclaration();

      $self->initialize({requiredDbVersion => 4.0, 
                 cvsRevision => '$Revision$',
                 cvsTag => '$Name:  $',
                 name => ref($self),
                 revisionNotes => '',
                 argsDeclaration => $args,
                 documentation => $documentation
                });

   return $self;
}


sub run {

  my ($self) = @_;

  $self->logAlgInvocationId;
  $self->logCommit;

  my $transcripts = $self->getTranscriptIds();

  foreach my $vals (@$transcripts) {
    my $transcriptSequence = $self->calculateTranscriptSequence($vals->{'sourceId'});

    $vals->{'sequence'} = $transcriptSequence;
  }

  $self->printSequences($transcripts);

  my $total = scalar (@$transcripts);

  my $resultDescrip = "$total = total number of transcript sequences\n";

  $self->setResultDescr($resultDescrip);
  $self->logData($resultDescrip);
}


 sub getTranscriptIds {
   my ($self) = @_;

   my @transcripts;

   my $extDbRlsName = $self->getArg("extDbName");
   my $extDbRlsVer = $self->getArg("extDbRlsVer");

   my $extDbRlsId = $self->getExtDbRlsId($extDbRlsName, $extDbRlsVer);

   my $seqExtDbRlsName = $self->getArg("seqExtDbName") if $self->getArg("seqExtDbName");
   my $seqExtDbRlsVer = $self->getArg("seqExtDbRlsVer") if $self->getArg("seqExtDbRlsVer");

   my $seqExtDbRlsId = $self->getExtDbRlsId($seqExtDbRlsName, $seqExtDbRlsVer) if ($seqExtDbRlsName && $seqExtDbRlsVer);

   unless ($extDbRlsId) {
     $self->error ("No such External Database Release / Version:\n $extDbRlsName / $extDbRlsVer\n");
   }

   my $dbh = $self->getQueryHandle();

   my $sql = <<EOSQL;
  SELECT t.source_id,g.product
  FROM   DoTS.Transcript t, dots.genefeature g, dots.nasequence n
  WHERE  t.external_database_release_id = ? and t.parent_id = g.na_feature_id
EOSQL

   $sql .= " and t.na_sequence_id = n.na_sequence_id and n.external_database_release_id = $seqExtDbRlsId" if $seqExtDbRlsId;

   my $sth = $dbh->prepare($sql);

   $sth->execute($extDbRlsId);

   while (my ($sourceId,$product) = $sth->fetchrow()) {
     my %vals =  (
		  'sourceId' => $sourceId,
		  'product' => $product
		 );
     push(@transcripts,\%vals);
   }

   return \@transcripts;
}

sub calculateTranscriptSequence {
  my ($self,$id) = @_;

  my $transcript = GUS::Model::DoTS::Transcript->new({ source_id => $id });

  unless ($transcript->retrieveFromDB()) {
    $self->error ("No Transcript row was fetched with source_id = $id\n");
  }

  my $ntSeq = $transcript->getParent("DoTS::NASequence", 1);

  unless ($ntSeq) {
    $self->error ("Transcript with source_id = $id had no associated NASequence\n");
  }

  my @exons = $transcript->getChildren("DoTS::ExonFeature", 1);

  unless (@exons) {
    self->error ("Transcript with source_id = $id had no exons\n");
  }

  @exons = map { $_->[0] }
    sort { $a->[3] ? $b->[1] <=> $a->[1] : $a->[1] <=> $b->[1] }
      map { [ $_, $_->getFeatureLocation ]}
	@exons;

  my $transcriptSequence;

  for my $exon (@exons) {
    my $chunk = $exon->getFeatureSequence();

    if ($self->getArg('cds')) {
      my ($exonStart, $exonEnd, $exonIsReversed) = $exon->getFeatureLocation();
      my $codingStart = $exon->getCodingStart();
      my $codingEnd = $exon->getCodingEnd();
      next unless ($codingStart && $codingEnd);
      my $trim5 = $exonIsReversed ? $exonEnd - $codingStart : $codingStart - $exonStart;
      substr($chunk, 0, $trim5, "") if $trim5 > 0;
      my $trim3 = $exonIsReversed ? $codingEnd - $exonStart : $exonEnd - $codingEnd;
      substr($chunk, -$trim3, $trim3, "") if $trim3 > 0;
    }
    $transcriptSequence .= $chunk;

  }

  $self->undefPointerCache();

  return $transcriptSequence;
}

sub printSequences {
  my ($self,$transcripts) = @_;

  my $sequenceFile = $self->getArg('sequenceFile');

  my $fh = FileHandle->new(">$sequenceFile") || $self->error("cannot open $sequenceFile for writing\n");

  foreach my $vals (@$transcripts) {
    my $id = $vals->{'sourceId'};
    my $product = $vals->{'product'};
    my $seq = $vals->{'sequence'};
    my $length = length ($seq);
    next if ($length == 0);

    my $defline = "\>$id $product length=$length\n";
    print $fh ("$defline" . CBIL::Bio::SequenceUtils::breakSequence($seq,60));
  }
}

1;
