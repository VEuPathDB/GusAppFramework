package GUS::ReportMaker::Report;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(print);

use strict;

# primaryColumnName: "DoTS_Transcript_Id" for example
# queries: ref to list of GUS::ReportMaker::Query objects
# columns: ref to list of GUS::ReportMaker::Column objects
sub new {
  my ($class, $primaryColumnName, $queries, $columns) = @_;

  my $self = {};
  bless($self, $class);

  $self->{primaryColumnName} = $primaryColumnName;
  $self->{queries} = $queries;

  my %columns;
  foreach my $column (@$columns) {
    $columns{$column->getName()} = $column;
  }
  $self->{columns} = \%columns;
  $self->{columnsList} = $columns;

  return $self;
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
  my ($self, $primaryKeyName, $requestedColumnNames, $resultTableName, 
      $dbiDb, $verbose) = @_;

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
    $self->_printRow($primaryKey, $answer{$primaryKey}, $requestedColumnNames);
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
    print "$columnName\t";
  }
  print "\n";
}

sub _printRow {
  my ($self, $primaryKey, $answerRow, $requestedColumnNames) = @_;

  print "$primaryKey\t";
  foreach my $columnName (@$requestedColumnNames) {
    $self->{columns}->{$columnName}->print($answerRow);
  }
  print "\n";
}

1;
