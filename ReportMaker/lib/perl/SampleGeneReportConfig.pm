package GUS::ReportMaker::SampleGeneReportConfig;

our @ISA = qw(Exporter);
our @EXPORT = qw(createReport getPrimaryKeyColumn);

use strict;
use GUS::ReportMaker::DefaultColumn;
use GUS::ReportMaker::Query;
use GUS::ReportMaker::Report;

sub getPrimaryKeyColumn {
  return "gene_id";
}

sub createReport {
  my ($tempTable) = @_;

  my @columns;

  my $symbolCol =
    GUS::ReportMaker::DefaultColumn->new("gene_symbol",
					 "Gene Symbol");
  push(@columns, $symbolCol);

  my $synonymCol =
    GUS::ReportMaker::DefaultColumn->new("synonyms",
					 "Gene Synonyms");
  push(@columns, $synonymCol);


  my $symbolSql = 
"select distinct tmp.gene_id, g.gene_symbol
from DoTS.gene g, $tempTable tmp
where g.gene_id = tmp.gene_id
";
  my $symbolQuery = 
    GUS::ReportMaker::Query->new($symbolSql,
				 [$symbolCol,
				 ]);

  my $synonymSql =
"select distinct tmp.gene_id, gs.synonym_name as synonyms
from DoTS.genesynonym gs, $tempTable tmp
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


1;
