#!/usr/bin/perl

use strict;

use lib "$ENV{GUS_HOME}/lib/perl/";

use DBI;
use DBD::Oracle;
use Getopt::Long;

use CBIL::Util::PropertySet;

my ($help, $gusConfigFile, $insertSql, $dataFile, $rowsPerCommit, $dateFormat, $fieldDelimiter, $rowDelimiter);
&GetOptions('help|h' => \$help,
            'gusConfigFile=s' => \$gusConfigFile,
            'data_file=s' => \$dataFile,
            'insert_sql=s' => \$insertSql,
            'rows_per_commit=i' => \$rowsPerCommit,
            'date_format=s' => \$dateFormat,
            'field_delimiter=s' => \$fieldDelimiter,
            'row_delimiter=s' => \$rowDelimiter,
    );

$rowsPerCommit = 1000 unless($rowsPerCommit);
$dateFormat = "yyyy-mm-dd hh24:mi:ss" unless($dateFormat);

$fieldDelimiter = "\t" unless($fieldDelimiter);

$rowDelimiter = "\n" unless($rowDelimiter);

##Create db handle
if(!$gusConfigFile) {
  $gusConfigFile = $ENV{GUS_HOME} . "/config/gus.config";
}

&usage("Config file $gusConfigFile does not exist.") unless -e $gusConfigFile;

my @properties;
my $gusconfig = CBIL::Util::PropertySet->new($gusConfigFile, \@properties, 1);

my $dbiDsn = $gusconfig->{props}->{dbiDsn};
my $dbiUser = $gusconfig->{props}->{databaseLogin};
my $dbiPswd = $gusconfig->{props}->{databasePassword};

my $dbh = DBI->connect($dbiDsn, $dbiUser, $dbiPswd) or die DBI->errstr;
$dbh->{RaiseError} = 1;
$dbh->{AutoCommit} = 0;
$dbh->do("alter session set nls_date_format = '$dateFormat'") or die $dbh->errstr;

open(FILE, $dataFile) or die "Cannot open file $dataFile for reading: $!";

my $insertSh = $dbh->prepare($insertSql);

my $count;

my @rows;

my $totalInserted = 0;


$/ = $rowDelimiter; # so chomp works
while(<FILE>) {
  chomp;

  my @a = split(/$fieldDelimiter/, $_, -1);
  
  for(my $i = 0; $i < scalar @a; $i++) {
    push @{$rows[$i]}, $a[$i];
  }

   if($count++ % $rowsPerCommit == 0) {
     my $tuples = $insertSh->execute_array(
       { ArrayTupleStatus => \my @tuple_status },
       @rows
         );
     if ($tuples) {
       $totalInserted = $totalInserted + $tuples;
#       print "Successfully inserted $tuples records (total=$totalInserted, expected=$count)\n";
     }
     else {
       die "";
     }
     @rows = ();
     $dbh->commit;
   }
}

if(scalar @rows > 0) {
  my $tuples = $insertSh->execute_array(
    { ArrayTupleStatus => \my @tuple_status },
    @rows
      );
  if ($tuples) {
    $totalInserted = $totalInserted + $tuples;
#    print "Successfully inserted $tuples records (total=$totalInserted, expected=$count)\n";
  }
  else {
    die "";
  }
  
  $dbh->commit;
}

$insertSh->finish();

$dbh->disconnect();

1;
