package GUS::ReportMaker::Query;

use strict;

# A class to represent a modular query that is available to a report.
# The query contains a list of column names that it can provide values for.


# sql: the sql to run for the query (with _RESULT_TABLE_NAME_ as stand-in)
# columns: ref to list of columns that it returns
sub new {
  my ($class, $sql, $columns) = @_;

  my $self = {};
  bless($self, $class);

  $self->{sql} = $sql;
  foreach my $columnRef (@$columns) {
    $self->{columnsHash}->{$columnRef->getName()} = $columnRef;
  }

  return $self;
}

# Run the query, placing values for the requested columns in $answerHash.
# The query may return more than one row per primary key, so the value of
# a primaryKey->column is a list.
#
# primaryKeyName: name of db column which has primary key
# requestedColumns: list of GUS::ReportMaker::Column
# resultTableName: name of table with list of primary keys to report on
# dbh: GUS::ObjRelP::DbiDatabase
# answerHash: ref to hash of primaryKey->column->value
sub run {
  my ($self, $primaryKeyName, $requestedColumns, $resultTableName, $dbh,
      $answerHash) = @_;

  my $sql = $self->{sql};

  $sql =~ s/_RESULT_TABLE_NAME_/$resultTableName/;

  my $q = substr($self->{sql}, 0, 60);
  print STDERR "\nrunning query: \n${q}...\n";

  my $stmt  = $dbh->prepare($sql);
  $stmt->execute();

  my $count;
  while (my $row = $stmt->fetchrow_hashref('NAME_lc')) {
    my $primaryKey = $row->{$primaryKeyName};
    foreach my $requestedCol (@$requestedColumns) {
      my $value = $requestedCol->getValue($row);
      my $colName = $requestedCol->getName();
      push(@{$answerHash->{$primaryKey}->{$colName}}, $value);
    }
  }
}

# return a listref of column names: the intersection of report's columns and query's columns
sub findRelevantColumns {
  my ($self, $reportColumnNamesHash) = @_;

  my @cols;
  my @columns = values(%{$self->{columnsHash}});
  foreach my $column (@columns) {
    my $columnName = $column->getName();
    if ($reportColumnNamesHash->{$columnName}){
      push(@cols, $self->{columnsHash}->{$columnName});
    }
  }
  return \@cols;
}

1;
