#######################################################################
##                 MakeGenesFromAlignments
##
## Creates GeneFeature/ExonFeature structures from BLAT alignments of
## genes to contigs
##
#######################################################################
 
package GUS::Community::Plugin::MakeGenesFromAlignments;
@ISA = qw( GUS::PluginMgr::Plugin);

use strict 'vars';

use GUS::PluginMgr::Plugin;
use GUS::Model::DoTS::GeneFeature;
use GUS::Model::DoTS::ExonFeature;
use GUS::Model::DoTS::NALocation;
use lib "$ENV{GUS_HOME}/lib/perl";
use FileHandle;
use Carp;

my $argsDeclaration = 
  [
  ];

my $purposeBrief = <<PURPOSEBRIEF;
Uses BLAT alignments to compute GeneFeature/ExonFeature structures
PURPOSEBRIEF
    
my $purpose = <<PLUGIN_PURPOSE;
Uses BLAT alignments to compute GeneFeature/ExonFeature structures.
PLUGIN_PURPOSE
   
my $tablesAffected = [
                      ['DoTS.GeneFeature', 'Gene records created here'],
                      ['DoTS.ExonFeature', 'Exon records created here'],
                      ['DoTS.NaLocation', 'Gene and exon locations stored here'],
                     ];


my $tablesDependedOn = [ ['DoTS.ExternalNaSeqence', 'Gene and contig sequences stored here'],
                         ['DoTS.BlatAlignment', 'BLAT alignments of genes against contigs']
                        ];

my $howToRestart = <<PLUGIN_RESTART;
No restart facility provided.
PLUGIN_RESTART

my $failureCases = <<PLUGIN_FAILURE_CASES;
None known.
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;

PLUGIN_NOTES

my $documentation = { purpose=>$purpose,
		      purposeBrief=>$purposeBrief,
		      tablesAffected=>$tablesAffected,
		      tablesDependedOn=>$tablesDependedOn,
		      howToRestart=>$howToRestart,
		      failureCases=>$failureCases,
		      notes=>$notes
		    };

sub new {
    my ($class) = @_;
    my $self = {};
    bless($self,$class);

    $self->initialize({requiredDbVersion => 3.5,
		       cvsRevision => '$Revision: 2822 $', # cvs fills this in!
		       name => ref($self),
		       argsDeclaration => $argsDeclaration,
		       documentation => $documentation
		      });

    return $self;
}

#######################################################################
# Main Routine
#######################################################################

sub run {
    my $self = shift;
    my ($geneCount, $exonCount);
    my $geneEnd;

    my $sql = <<SQL;
SELECT query.source_id, query.description, query.secondary_identifier,
       query.external_database_release_id, ba.target_na_sequence_id,
       ba.tstarts, ba.blocksizes, ba.score, ba.is_reversed, ba.number_of_spans
FROM dots.ExternalNaSequence query, dots.BlatAlignment ba, core.TableInfo ti
WHERE query.source_id NOT IN (SELECT source_id from dots.GeneFeature)
  AND ba.query_na_sequence_id = query.na_sequence_id
  AND ba.query_table_id = ti.table_id
  AND ba.target_table_id = ti.table_id
  AND ti.name = 'ExternalNASequence'
SQL

    my $sth = $self->prepareAndExecute($sql);
    while (my ($sourceId, $product, $label, $dbRlsId, $naSequenceId, $tStarts,
               $blockSizes, $isReversed, $numberOfExons)
              = $sth->fetchrow_array()) {

	my $geneFeature = GUS::Model::DoTS::GeneFeature->
	    new({ source_id => $sourceId,
		  na_sequence_id => $naSequenceId,
		  product => $product,
		  label => $label,
		  external_database_release_id => $dbRlsId,
		  name => 'gene',
		  });

	my $exonsMade = 0;
	my @starts = split(chop($tStarts), ',');
	foreach my $blockSize ( split(chop($blockSizes), ',')) {
	    $exonsMade++;
	    my $start = pop(@starts);

	    my $exonFeature = GUS::Model::DoTS::ExonFeature->
		new({ source_id => $sourceId,
		      na_sequence_id => $naSequenceId,
		      external_database_release_id => $dbRlsId,
		  });

	    my $exonLocation = GUS::Model::DoTS::NALocation->
		new({ start_min => $start,
                      start_max => $start,
                      end_min => $start + $blockSize,
                      end_min => $start + $blockSize,
		      is_reversed => $isReversed,
		  });

	    $exonFeature->addChild($exonLocation);
	    $geneFeature->addChild($exonFeature);

	    $geneEnd = $start + $blockSize;
	}

	my $geneLocation = GUS::Model::DoTS::NALocation->
	    new({ start_min => $starts[0],
		  start_max => $starts[0],
		  end_min => $geneEnd,
		  end_min => $geneEnd,
		  is_reversed => $isReversed,
	      });
	$geneFeature->addChild($geneLocation);
	$geneFeature->submit();
    }

    return "MakeGenesFromAlignments completed";
}

1;
