package GUS::ReportMaker::Report;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(print);

use strict;

my $MAP_TABLE_DELIM = ":";  # used to delimit the mapping table info

# primaryColumnName: "DoTS_Transcript_Id" for example
# queries: ref to list of GUS::ReportMaker::Query objects
# columns: ref to list of GUS::ReportMaker::Column objects
sub new {
  my ($class, $primaryColumnName, $queries, $columns) = @_;

  my $self = {};
  bless($self, $class);

  $self->{primaryColumnName} = $primaryColumnName;
  $self->{queries} = $queries;

  $self->{columns} = {};
  $self->{columnsList} = [];

  $self->_addColumns($columns);

  return $self;
}

# columns: ref to list of GUS::ReportMaker::Column objects
sub _addColumns {
  my ($self, $columns) = @_;

  foreach my $column (@$columns) {
    $self->{columns}->{$column->getName()} = $column;
    push(@{$self->{columnsList}}, $column);
  }
}

sub listColumns {
  my ($self) = @_;

  print "\nColumnName\tDescription\n";
  foreach my $column (@{$self->{columnsList}}) {
    print $column->getName() . "\t" . $column->getDescription() . "\n";
  }
}

sub validateColumnsRequest {
  my ($self, $requestedColumnNames) = @_;

  foreach my $columnName (@$requestedColumnNames) {
    die "\nError: $columnName is not a supported column\n" unless $self->{columns}->{$columnName};
  }
  
}

# requesteColumnNames: list of names for requested columns
# resultTableName: name of db table containing result
# dbiDb: GUS::ObjRelP::DbiDatabase
sub print {
  my ($self, $primaryKeyName, $primaryKeyPrefix, $requestedColumnNames, 
      $resultTableName, $dbiDb, $verbose) = @_;

  # hash of query->[columns]
  my %relevantQueries = $self->_findRelevantQueries($requestedColumnNames);

  my $dbh = $dbiDb->getQueryHandle();

  my %answer;
  foreach my $q (keys(%relevantQueries)) {
    my $query = $relevantQueries{$q}->[0];
    my $relevantColumns = $relevantQueries{$q}->[1];
    $query->run($primaryKeyName, $relevantColumns, $resultTableName, 
		$dbh, \%answer, $verbose);
  }

  $self->_printHeader($requestedColumnNames);
  foreach my $primaryKey (keys %answer) {
    $self->_printRow($primaryKey, $primaryKeyPrefix, $answer{$primaryKey}, $requestedColumnNames);
  }
}

# mappingTables: a string holding a list of 'datasetname:tablename, ...'
# mappingTableValueColumnName: the name of the col in the mapping table that holds the mapped value
# tempTable: the name of the table that holds the main result set
# primaryKeyColumnName: the name of the column in both tables that will join them.
sub addMappingTables {
  my ($self, $mappingTables, $mappingTableValueColumnName,
      $tempTable, $primaryKeyColumnName) = @_;

  my @mappingTables = split(/,\s*/, $mappingTables);
  foreach my $mappingTableDescriptor (@mappingTables) {
    $mappingTableDescriptor =~ /(\w+)$MAP_TABLE_DELIM(\S+)/
      || die "mapping table descriptor '$mappingTableDescriptor' is not in the correct format";
    my $mappingName = $1;
    my $mappingTable = $2;

    my $mappingTableSql = 
"select distinct $tempTable.$primaryKeyColumnName, 
$mappingTable.$mappingTableValueColumnName as $mappingName
from $mappingTable, $tempTable 
where $mappingTable.$primaryKeyColumnName = $tempTable.$primaryKeyColumnName
";

    my $mappingTableCol =
      GUS::ReportMaker::DefaultColumn->new("$mappingName",
					   "Your data set named '$mappingName'");
    $self->_addColumns([$mappingTableCol]);
    my $mappingQuery = 
      GUS::ReportMaker::Query->new($mappingTableSql,
				 [$mappingTableCol,
				 ]);
    push(@{$self->{queries}}, $mappingQuery);
  }
}

# for now, this is a trivial method, assuming that there is only one relevant
# query per column, but is a hook for optimization.
# returns hash of query->[columns]
sub _findRelevantQueries {
  my ($self, $requestedColumnNames) = @_;

  my %columnNames;
  foreach my $colName (@$requestedColumnNames) {
    $columnNames{$colName} = 1;
  }
  my %relevantQueries;
  foreach my $query (@{$self->{queries}}) {
    my $relevantCols = $query->findRelevantColumns(\%columnNames);
    $relevantQueries{$query} = [$query, $relevantCols] if scalar(@$relevantCols);
  }
  return %relevantQueries;
}

sub _printHeader {
  my ($self, $requestedColumnNames) = @_;

  print "$self->{primaryColumnName}\t";
  foreach my $columnName (@$requestedColumnNames) {
    my $heading = $self->{columns}->{$columnName}->getName();
    print "$heading\t";
  }
  print "\n";
}

sub _printRow {
  my ($self, $primaryKey, $primaryKeyPrefix, $answerRow, $requestedColumnNames) = @_;

  print "${primaryKeyPrefix}${primaryKey}\t";
  foreach my $columnName (@$requestedColumnNames) {
    $self->{columns}->{$columnName}->print($answerRow);
  }
  print "\n";
}

1;
