package GUS::ReportMaker::SampleConfig;

use strict;
use GUS::ReportMaker::DefaultColumn;
use GUS::ReportMaker::Query;
use GUS::ReportMaker::Report;

sub createDoTSGeneReport {
  my ($geneTempTable) = @_;

  my @columns;

  my $symbolCol =
    GUS::ReportMaker::DefaultColumn->new("gene_symbol",
					 "Gene Symbol");
  push(@columns, $symbolCol);

  my $synonymCol =
    GUS::ReportMaker::DefaultColumn->new("synonym_name",
					 "Gene Synonym");
  push(@columns, $synonymCol);


  my $symbolSql = 
"select distinct tmp.gene_id, g.gene_symbol
from DoTS.gene g, $geneTempTable tmp
where g.gene_id = tmp.gene_id
";
  my $symbolQuery = 
    GUS::ReportMaker::Query->new($symbolSql,
				 [$symbolCol,
				 ]);

  my $synonymSql =
"select distinct tmp.gene_id, gs.synonym_name
from DoTS.genesynonym gs, $geneTempTable tmp
where gs.gene_id = tmp.gene_id
";

  my $synonymQuery = 
    GUS::ReportMaker::Query->new($synonymSql,
				 [$synonymCol,
				 ]);


  return GUS::ReportMaker::Report->new("DoTS_Gene", 'gene_id',
				      [$synonymQuery, $symbolQuery],
				      \@columns);
}

sub createDoTSTranscriptReport {
  my ($rnaTempTable) = @_;

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
"select distinct a.na_sequence_id, description, scientific_name, length,
number_of_contained_sequences as seqs_in_assem, contains_mrna
from gusdev.Assembly a, gusdev.Taxon ta, $rnaTempTable tmp
where a.na_sequence_id = tmp.na_sequence_id
and ta.taxon_id = a.taxon_id
";
  my $assemQuery = 
    GUS::ReportMaker::Query->new($assemSql,
				 [$descriptionCol->getName(),
				  $organismCol->getName(),
				  $lengthCol->getName(),
				  $seqsInAssemCol->getName(),
				  $containsmRNACol->getName(),
				 ]);

  my $locuslinkSql = 
"select distinct tmp.na_sequence_id, dbref.primary_identifier as locuslink
from gusdev.DbRefNASequence dbrnas, gusdev.DbRef dbref, $rnaTempTable tmp
where dbrnas.na_sequence_id = tmp.na_sequence_id
and dbref.db_ref_id  = dbrnas.db_ref_id
and dbref.external_db_id = 6095
";
  my $locuslinkQuery = 
    GUS::ReportMaker::Query->new($locuslinkSql,
				 [$locusLinkCol->getName(),
				 ]);


  my $genecardsSql =
"select distinct tmp.na_sequence_id, dbref.primary_identifier as genecards
from gusdev.DbRefNASequence dbrnas, gusdev.DbRef dbref, $rnaTempTable tmp
where dbrnas.na_sequence_id = tmp.na_sequence_id
and dbref.db_ref_id  = dbrnas.db_ref_id
and dbref.external_db_id = 4892
";
  my $genecardsQuery =
    GUS::ReportMaker::Query->new($genecardsSql,
				 [$geneCardsCol->getName(),
				 ]);


  my $mgiSql =
"select distinct tmp.na_sequence_id, dbref.primary_identifier as genecards
from gusdev.DbRefNASequence dbrnas, gusdev.DbRef dbref, $rnaTempTable tmp
where dbrnas.na_sequence_id = tmp.na_sequence_id
and dbref.db_ref_id  = dbrnas.db_ref_id
and dbref.external_db_id = 4893
";
  my $mgiQuery =
    GUS::ReportMaker::Query->new($mgiSql,
				 [$mgiCol->getName(),
				 ]);


  my $geneSql = 
"select distinct tmp.na_sequence_id, g.gene_id as dots_gene, 
g.name as genesymbol
from gusdev.RNA r, $rnaTempTable tmp, gusdev.RNASequence rs, 
     gusdev.NAFeature naf, gusdev.TranscriptUnit tu, gusdev.Gene g 
where     naf.na_sequence_id = tmp.na_sequence_id
and       rs.na_feature_id  = naf.na_feature_id
and         r.rna_id  = rs.rna_id
and           tu.transcript_unit_id  = r.transcript_unit_id 
and             g.gene_id  = tu.gene_id 
";
  my $geneQuery = 
    GUS::ReportMaker::Query->new($geneSql,
				 [$dotsGeneCol->getName(),
				  $geneSymbolCol->getName(),
				 ]);


  my $gofunctionSql = 
"select distinct gomax.na_sequence_id, go.go_id as goid, go.name as gofunction
 from
 gusdev.ProteinGOFunction pgf, 
 gusdev.ProteinAssembly pa,
 gusdev.GOFunction go,
  (select tmp.na_sequence_id, max(go.maximum_level) as maximum_level
    from 
      $rnaTempTable tmp, 
      gusdev.ProteinGOFunction pgf, 
      gusdev.ProteinAssembly pa,
      gusdev.GOFunction go
    where pa.na_sequence_id = tmp.na_sequence_id
    and pgf.protein_id = pa.protein_id
    and go.go_function_id = pgf.go_function_id
    and go.go_cvs_version = '2.155'
    group by tmp.na_sequence_id
  ) gomax
where pa.na_sequence_id = gomax.na_sequence_id
    and pgf.protein_id = pa.protein_id
    and go.go_function_id = pgf.go_function_id
    and go.maximum_level = gomax.maximum_level
";
  my $gofunctionQuery = 
    GUS::ReportMaker::Query->new($gofunctionSql,
				 [$goIdCol->getName(),
				  $goFuncCol->getName(),
				 ]);

  my $motifsSql = 
"select distinct tmp.na_sequence_id, mas.source_id as motifs
from gusdev.Similarity s, gusdev.MotifAASequence mas, $rnaTempTable tmp 
where s.query_id = tmp.na_sequence_id 
 and s.query_table_id = 56 
 and s.subject_table_id = 277 
 and s.pvalue_exp <= -50
 and mas.aa_sequence_id = s.subject_id 
";
  my $motifsQuery = 
    GUS::ReportMaker::Query->new($motifsSql,
				 [$motifsCol->getName(),
				 ]);


  return GUS::ReportMaker::Report->new("DoTS_Transcript", 'na_sequence_id',
				      [$assemQuery],
				      \@columns);
}


1;
