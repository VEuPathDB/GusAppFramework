package GUS::ReportMaker::SampleGeneReportConfig;

our @ISA = qw(Exporter);
our @EXPORT = qw(createReport);

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

  my $symbolCol =
    GUS::ReportMaker::DefaultColumn->new("gene_symbol",
					 "Gene Symbol");
  push(@columns, $symbolCol);

  my $geneCardsCol =
    GUS::ReportMaker::DefaultColumn->new("gene_cards_id",
					 "GeneCardsId");
  push(@columns, $geneCardsCol);

  my $mgiLocusCol =
    GUS::ReportMaker::DefaultColumn->new("mgi_locus",
					 "MGI Locus");
  push(@columns, $mgiLocusCol);

  my $synonymCol =
    GUS::ReportMaker::DefaultColumn->new("synonyms",
					 "Gene Synonyms");
  push(@columns, $synonymCol);


  my $mappedToSql = 
"select distinct tmp.$primaryKeyName, tmp.$mappedToName
from $tempTable tmp
";
  my $mappedToQuery = 
    GUS::ReportMaker::Query->new($mappedToSql,
				 [$mappedToCol,
				 ]);

  my $geneCardsSql = 
"select distinct tmp.$primaryKeyName, dbr.primary_identifier as gene_cards_id
from $tempTable tmp, dots.DBRefNASequence dbrn, sres.DBRef dbr,
     sres.ExternalDatabaseRelease edr,
     dots.nafeature naf, dots.rna r, dots.RNAInstance rs
where r.gene_id = tmp.$primaryKeyName
 and rs.rna_id = r.rna_id 
 and rs.na_feature_id = naf.na_feature_id
 and naf.na_sequence_id = dbrn.na_sequence_id
 and dbrn.db_ref_id = dbr.db_ref_id
 and dbr.external_database_release_id = 4892
";
  my $geneCardsQuery = 
    GUS::ReportMaker::Query->new($geneCardsSql,
				 [$geneCardsCol,
				 ]);

   my $mgiLocusSql = 
"select distinct tmp.$primaryKeyName, dbr.secondary_identifier as mgi_locus
from $tempTable tmp, dots.DBRefNASequence dbrn, sres.DBRef dbr,
     sres.ExternalDatabaseRelease edr,
     dots.nafeature naf, dots.rna r, dots.RNAInstance rs
where r.gene_id = tmp.$primaryKeyName
 and rs.rna_id = r.rna_id 
 and rs.na_feature_id = naf.na_feature_id
 and naf.na_sequence_id = dbrn.na_sequence_id
 and dbrn.db_ref_id = dbr.db_ref_id
 and dbr.external_database_release_id = 4893
";
  my $mgiLocusQuery = 
    GUS::ReportMaker::Query->new($mgiLocusSql,
				 [$mgiLocusCol,
				 ]);

 my $symbolSql = 
"select distinct tmp.$primaryKeyName, g.gene_symbol
from DoTS.gene g, $tempTable tmp
where g.gene_id = tmp.$primaryKeyName
";
  my $symbolQuery = 
    GUS::ReportMaker::Query->new($symbolSql,
				 [$symbolCol,
				 ]);

  my $synonymSql =
"select distinct tmp.$primaryKeyName, gs.synonym_name as synonyms
from DoTS.genesynonym gs, $tempTable tmp
where gs.gene_id = tmp.$primaryKeyName
";

  my $synonymQuery = 
    GUS::ReportMaker::Query->new($synonymSql,
				 [$synonymCol,
				 ]);


  return GUS::ReportMaker::Report->new("DoTS_Gene",
				      [$synonymQuery,
				       $symbolQuery,
				       $mappedToQuery],
				      \@columns);
}


1;
