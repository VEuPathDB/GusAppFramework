package GUS::ReportMaker::SampleGeneReportConfig;

our @ISA = qw(Exporter);
our @EXPORT = qw(createReport);

use strict;
use GUS::ReportMaker::DefaultColumn;
use GUS::ReportMaker::Query;
use GUS::ReportMaker::Report;

sub createReport {
  my ($tempTable, $primaryKeyName, $mappedToName, $mappingTables) = @_;

  my @columns;

  my $mappedToCol =
    GUS::ReportMaker::DefaultColumn->new("$mappedToName",
					 "Mapped To");

  push(@columns, $mappedToCol);

  my $symbolCol =
    GUS::ReportMaker::DefaultColumn->new("GeneSymbol",
					 "Gene Symbol");
  push(@columns, $symbolCol);

  my $geneCardsCol =
    GUS::ReportMaker::DefaultColumn->new("GeneCardsId",
					 "GeneCardsId");
  push(@columns, $geneCardsCol);

  my $mgiLocusCol =
    GUS::ReportMaker::DefaultColumn->new("MGILocus",
					 "MGI Locus");
  push(@columns, $mgiLocusCol);

  my $mgiIdCol =
    GUS::ReportMaker::DefaultColumn->new("MGI_Id",
					 "MGI Id");
  push(@columns, $mgiIdCol);

  my $synonymCol =
    GUS::ReportMaker::DefaultColumn->new("Synonyms",
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
"select distinct tmp.$primaryKeyName, dbr.primary_identifier as GeneCardsId
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

   my $mgiSql = 
"select distinct tmp.$primaryKeyName, dbr.primary_identifier as MGI_Id, dbr.secondary_identifier as MGILocus
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
  my $mgiQuery = 
    GUS::ReportMaker::Query->new($mgiSql,
				 [$mgiLocusCol,
                                  $mgiIdCol,
				 ]);

 my $symbolSql = 
"select distinct tmp.$primaryKeyName, g.GeneSymbol
from DoTS.gene g, $tempTable tmp
where g.gene_id = tmp.$primaryKeyName
";
  my $symbolQuery = 
    GUS::ReportMaker::Query->new($symbolSql,
				 [$symbolCol,
				 ]);

  my $synonymSql =
"select distinct tmp.$primaryKeyName, gs.synonym_name as Synonyms
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
                                       $geneCardsQuery,
                                       $mgiQuery,
				       $mappedToQuery],
				      \@columns);
}


1;
