package GUS::ReportMaker::SampleTranscriptReportConfig;

our @ISA = qw(Exporter);
our @EXPORT = qw(createReport getPrimaryKeyColumn);

use strict;
use GUS::ReportMaker::DefaultColumn;
use GUS::ReportMaker::Query;
use GUS::ReportMaker::Report;

sub createReport {
  my ($tempTable, $primaryKeyName, $mappedToName) = @_;

  my @columns;

  my $mappedToCol =
    GUS::ReportMaker::DefaultColumn->new("$mappedToName",
					 "Mapped To");
  push(@columns, $mappedToCol);

  my $lengthCol =
    GUS::ReportMaker::DefaultColumn->new("Length",
					 "Length of the assembly consensus sequence (i.e., predicted mRNA sequence)");
  push(@columns, $lengthCol);

  my $seqsInAssemCol =
    GUS::ReportMaker::DefaultColumn->new("SeqsInAssem",
					 "Number of sequences (ESTs and mRNAs) in the assembly");
  push(@columns, $seqsInAssemCol);

  my $containsmRNACol =
    GUS::ReportMaker::DefaultColumn->new("ContainsMRNA",
					 "Whether the assembly contains at least one mRNA sequence (returns 0 or 1)");
  push(@columns, $containsmRNACol);

  my $locusLinkCol =
    GUS::ReportMaker::DefaultColumn->new("LocusLink",
					 "LocusLink entries linked to the assembly");
  push(@columns, $locusLinkCol);

  my $geneCardsCol =
    GUS::ReportMaker::DefaultColumn->new("GeneCards",
					 "GeneCards entries linked to the assembly (human transcripts only)");
  push(@columns, $geneCardsCol);

  my $dotsGeneCol =
    GUS::ReportMaker::DefaultColumn->new("DoTSGene",
					 "DoTS Gene that this assembly belongs to");
  push(@columns, $dotsGeneCol);

  my $geneSymbolCol =
    GUS::ReportMaker::DefaultColumn->new("GeneSymbol",
					 "Official gene symbol (e.g. HUGO or MGI gene name) for the transcript");
  push(@columns, $geneSymbolCol);

  my $descriptionCol =
    GUS::ReportMaker::DefaultColumn->new("Description",
					 "Description of the assembly generated based on similarity to known proteins");
  push(@columns, $descriptionCol);

  my $organismCol =
    GUS::ReportMaker::DefaultColumn->new("Organism",
					 "Organism/species to which the transcript belongs");
  push(@columns, $organismCol);

  my $goIdCol =
    GUS::ReportMaker::DefaultColumn->new("GOid",
					 "IDs of Gene Ontology (GO) consortium terms assigned to the transcript");
  push(@columns, $goIdCol);

  my $goNameCol =
    GUS::ReportMaker::DefaultColumn->new("GoName",
					 "Names of Gene Ontology (GO) consortium terms assigned to the transcript");
  push(@columns, $goNameCol);

  my $motifsCol =
    GUS::ReportMaker::DefaultColumn->new("Motifs",
					 "Protein motifs/domains found in the mRNA with p-value <= 10E-50");
  push(@columns, $motifsCol);

  my $mgiCol =
    GUS::ReportMaker::DefaultColumn->new("MGI",
					 "MGI gene IDs assigned to the transcript (mouse transcripts only)");
  push(@columns, $mgiCol);

  my $mrnaSeqCol =
    GUS::ReportMaker::DefaultColumn->new("mRNASeq",
					 "Predicted mRNA sequence for the transcript, derived from the assembly consensus sequence");
  push(@columns, $mrnaSeqCol);

  my $protSeqCol =
    GUS::ReportMaker::DefaultColumn->new("proteinSeq",
					 "Predicted protein sequence for the transcript, derived from a FrameFinder prediction");
  push(@columns, $protSeqCol);

  my $mappedToSql = 
"select distinct tmp.$primaryKeyName, tmp.$mappedToName
from $tempTable tmp
";
  my $mappedToQuery = 
    GUS::ReportMaker::Query->new($mappedToSql,
				 [$mappedToCol,
				 ]);

  my $assemSql = 
"select distinct tmp.$primaryKeyName, description, tn.name as organism, length,
number_of_contained_sequences as SeqsInAssem, contains_mrna as ContainsMRNA
from DoTS.Assembly a, Sres.TaxonNAme tn, $tempTable tmp
where a.na_sequence_id = tmp.$primaryKeyName
and tn.taxon_id = a.taxon_id
and tn.name_class = 'scientific name'
";
  my $assemQuery = 
    GUS::ReportMaker::Query->new($assemSql,
				 [$descriptionCol,
				  $organismCol,
				  $lengthCol,
				  $seqsInAssemCol,
				  $containsmRNACol,
				 ]);

  my $locuslinkSql = 
"select distinct tmp.$primaryKeyName, dbref.primary_identifier as locuslink
from dots.DbRefNASequence dbrnas, sres.DbRef dbref, $tempTable tmp
where dbrnas.na_sequence_id = tmp.$primaryKeyName
and dbref.db_ref_id  = dbrnas.db_ref_id
and dbref.external_database_release_id = 6095
";
  my $locuslinkQuery = 
    GUS::ReportMaker::Query->new($locuslinkSql,
				 [$locusLinkCol,
				 ]);


  my $genecardsSql =
"select distinct tmp.$primaryKeyName, dbref.primary_identifier as genecards
from dots.DbRefNASequence dbrnas, sres.DbRef dbref, $tempTable tmp
where dbrnas.na_sequence_id = tmp.$primaryKeyName
and dbref.db_ref_id  = dbrnas.db_ref_id
and dbref.external_database_release_id =4892
";
  my $genecardsQuery =
    GUS::ReportMaker::Query->new($genecardsSql,
				 [$geneCardsCol,
				 ]);


  my $mgiSql =
"select distinct tmp.$primaryKeyName, dbref.primary_identifier as MGI
from dots.DbRefNASequence dbrnas, sres.DbRef dbref, $tempTable tmp
where dbrnas.na_sequence_id = tmp.$primaryKeyName
and dbref.db_ref_id  = dbrnas.db_ref_id
and dbref.external_database_release_id =4893
";
  my $mgiQuery =
    GUS::ReportMaker::Query->new($mgiSql,
				 [$mgiCol,
				 ]);

  my $geneSql = 
"select distinct tmp.$primaryKeyName, g.gene_id as dotsgene, 
g.gene_symbol as genesymbol
from dots.RNA r, $tempTable tmp, dots.RNAInstance ri, 
     dots.NAFeature naf, dots.Gene g 
where     naf.na_sequence_id = tmp.$primaryKeyName
and       ri.na_feature_id  = naf.na_feature_id
and         r.rna_id  = ri.rna_id
and             g.gene_id  = r.gene_id 
";

  my $geneQuery = 
    GUS::ReportMaker::Query->new($geneSql,
				 [$dotsGeneCol,
				  $geneSymbolCol,
				 ]);

# Not tested yet
  my $gofunctionSql = 
"select distinct pa.na_sequence_id, gt.go_id as goid, gt.name as goname
 from $tempTable tmp, sres.goterm gt, allgenes_60.ProteinAssembly pa, dots.goassociation ga
 where ga.row_id = pa.protein_id
    and pa.na_sequence_id = tmp.$primaryKeyName
    and ga.table_id = 180
    and ga.defining = 1
    and ga.is_deprecated != 1
    and ga.is_not != 1
    and ga.go_term_id = gt.go_term_id
";
  my $gofunctionQuery = 
    GUS::ReportMaker::Query->new($gofunctionSql,
				 [$goIdCol,
				  $goNameCol,
				 ]);

  my $motifsSql = 
"select distinct tmp.$primaryKeyName, mas.source_id as motifs
from dots.Similarity s, dots.MotifAASequence mas, $tempTable tmp 
where s.query_id = tmp.$primaryKeyName 
 and s.query_table_id = 56 
 and s.subject_table_id = 277 
 and s.pvalue_exp <= -50
 and mas.aa_sequence_id = s.subject_id 
";
  my $motifsQuery = 
    GUS::ReportMaker::Query->new($motifsSql,
				 [$motifsCol,
				 ]);

  my $seqSql =
"select tmp.$primaryKeyName, tas.sequence as proteinSeq, a.sequence as mRNASeq
from $tempTable tmp, allgenes_60.ProteinAssembly pa, dots.TranslatedAAFeature taf,  
     dots.TranslatedAASequence tas, dots.Assembly a
where tmp.$primaryKeyName = pa.na_sequence_id
and pa.na_feature_id = taf.na_feature_id
and taf.aa_sequence_id = tas.aa_sequence_id
and pa.na_sequence_id = a.na_sequence_id
";
  my $seqQuery =
    GUS::ReportMaker::Query->new($seqSql,
				 [$protSeqCol,
				  $mrnaSeqCol
				 ]);

  return GUS::ReportMaker::Report->new("DoTS_Transcript",
				      [$assemQuery,
				       $locuslinkQuery,
				       $genecardsQuery,
				       $mgiQuery,
				       $geneQuery,
				       $mappedToQuery,
				       $motifsQuery,
				       $seqQuery,
				       ],
				      \@columns);
}

1;
