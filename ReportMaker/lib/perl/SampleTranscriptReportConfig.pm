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

  my $lengthCol =
    GUS::ReportMaker::DefaultColumn->new("Length",
					 "Sequence Length");
  push(@columns, $lengthCol);

  my $seqsInAssemCol =
    GUS::ReportMaker::DefaultColumn->new("SeqsInAssem",
					 "Sequences in assembly");
  push(@columns, $seqsInAssemCol);

  my $containsmRNACol =
    GUS::ReportMaker::DefaultColumn->new("ContainsMRNA",
					 "Contains mRNA");
  push(@columns, $containsmRNACol);

  my $locusLinkCol =
    GUS::ReportMaker::DefaultColumn->new("LocusLink",
					 "Locus Link ID");
  push(@columns, $locusLinkCol);

  my $geneCardsCol =
    GUS::ReportMaker::DefaultColumn->new("GeneCards",
					 "Gene Cards ID");
  push(@columns, $geneCardsCol);

  my $dotsGeneCol =
    GUS::ReportMaker::DefaultColumn->new("DoTSGene",
					 "DoTS Gene ID");
  push(@columns, $dotsGeneCol);

  my $geneSymbolCol =
    GUS::ReportMaker::DefaultColumn->new("GeneSymbol",
					 "Gene Symbol");
  push(@columns, $geneSymbolCol);

  my $descriptionCol =
    GUS::ReportMaker::DefaultColumn->new("Description",
					 "Description");
  my $organismCol =
    GUS::ReportMaker::DefaultColumn->new("Organism",
					 "Organism");
  push(@columns, $descriptionCol);

  my $goIdCol =
    GUS::ReportMaker::DefaultColumn->new("GoId",
					 "GO Id");
  push(@columns, $goIdCol);

  my $goFuncCol =
    GUS::ReportMaker::DefaultColumn->new("GoFunction",
					 "GO Function");
  push(@columns, $goFuncCol);

  my $motifsCol =
    GUS::ReportMaker::DefaultColumn->new("Motifs",
					 "Motifs");
  push(@columns, $motifsCol);

  my $mgiCol =
    GUS::ReportMaker::DefaultColumn->new("MGI",
					 "MGI ID");
  push(@columns, $mgiCol);

  my $assemSql = 
"select distinct tmp.$primaryKeyName, description, tn.name, length,
number_of_contained_sequences as seqs_in_assem, contains_mrna
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
g.name as genesymbol
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


  my $gofunctionSql = 
"select distinct gomax.na_sequence_id, go.go_id as goid, go.name as gofunction
 from
 gusdev.ProteinGOFunction pgf, 
 gusdev.ProteinAssembly pa,
 gusdev.GOFunction go,
  (select tmp.$primaryKeyName, max(go.maximum_level) as maximum_level
    from 
      $tempTable tmp, 
      gusdev.ProteinGOFunction pgf, 
      gusdev.ProteinAssembly pa,
      gusdev.GOFunction go
    where pa.na_sequence_id = tmp.$primaryKeyName
    and pgf.protein_id = pa.protein_id
    and go.go_function_id = pgf.go_function_id
    and go.go_cvs_version = '2.155'
    group by tmp.$primaryKeyName
  ) gomax
where pa.na_sequence_id = gomax.na_sequence_id
    and pgf.protein_id = pa.protein_id
    and go.go_function_id = pgf.go_function_id
    and go.maximum_level = gomax.maximum_level
";
  my $gofunctionQuery = 
    GUS::ReportMaker::Query->new($gofunctionSql,
				 [$goIdCol,
				  $goFuncCol,
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


  return GUS::ReportMaker::Report->new("DoTS_Transcript",
				      [$assemQuery,
				       $locuslinkQuery,
				       $genecardsQuery,
				       $mgiQuery,
				       $geneQuery,
				       $motifsQuery],
				      \@columns);
}

1;
