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
