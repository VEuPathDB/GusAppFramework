#!/usr/bin/perl

##takes in an SQL query and deletes entries one at a time...
## query must return primary key of table..

use strict;
use DBI;
use Getopt::Long;
use Objects::GUS::ObjRelP::DbiDatabase;
use GUS::Model::::TableInfo;

$| = 1;

my ($verbose,$idSQL,$table,$batch_size);
&GetOptions("verbose!"=> \$verbose,"idSQL=s" => \$idSQL, "table=s" => \$table,"batch_size=i" => \$batch_size);

die "usage: deleteEntries.pl --idSQL 'sql query returns primary keys of table' --table <tablename> --verbose --batch_size [100]\n" unless $idSQL && $table;

$batch_size = $batch_size ? $batch_size : 1000;

print STDERR "Establishing dbi login\n" if $verbose;
my $db = new GUS::ObjRelP::DbiDatabase( undef, 'GUSrw', 'pskwa82', $verbose, 0, 1, 'GUSdev' );

my $dbh = $db->makeNewHandle();

my $o = TableInfo->new();
my $pk = $o->getTablePKFromTableId($o->getTableIdFromTableName($table));

print STDERR "Query: $idSQL\n" if $verbose;

my $stmt = $dbh->prepareAndExecute($idSQL);
my @ids;
my $ct = 0;
while(my($id) = $stmt->fetchrow_array()){
  $ct++;
  push(@ids,$id);
  print STDERR "Retrieving ids: $ct\n" if $ct % 1000 == 0;
}
print STDERR "deleting ",scalar(@ids)," ids from $table\n";

$ct = 0;
for(my $i=0;$i<scalar(@ids);$i += $batch_size){
  $ct += $dbh->do("delete from $table where $pk in (".join(', ',@ids[$i..($i + $batch_size - 1 < scalar(@ids) ? $i + $batch_size - 1 : scalar(@ids) - 1)]).")");
  $dbh->commit();
  print STDERR "$ct deleted ",`date`;
}
$dbh->disconnect();
$db->logout();
  
