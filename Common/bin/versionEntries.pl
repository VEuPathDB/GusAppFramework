#!/usr/bin/perl

##takes in an SQL query and versions entries one at a time...
## query must return primary key of versioned table.

use strict;
use Getopt::Long;
use GUS::ObjRelP::DbiDatabase;
use GUS::Model::Core::TableInfo;

$| = 1;

my ($verbose,$idSQL,$table,$userId,$tablePK,$logfile);
&GetOptions("verbose!"=> \$verbose,
	    "idSQL=s" => \$idSQL, 
	    "table=s" => \$table,
	    "userId=i" => \$userId,
	    "tablePK=s" => \$tablePK,
	    "logfile=s" => \$logfile);

print STDERR "Establishing dbi login\n" if $verbose;
my $db = new DbiDatabase( undef, 'GUSrw', 'pskwa82', $verbose, 0, 1, 'GUSdev' );
my $dbh = $db->makeNewHandle();

my %versioned;
my @ids;
my $ct=0;
my $ctVer=0;

&usage() unless $idSQL && $table && $userId && $tablePK;

&getVersioned() if (-s $logfile);

&getIds();

&versionRows();

$dbh->disconnect();
$db->logout();

print STDERR "$ct ids were obtained from the query\n$ctVer rows were versioned\n"; 

sub usage {

    print STDERR "usage: deleteEntries.pl --idSQL 'sql query returns primary keys of table' --table <tablename to version> --userId <user_id from UserInfo> --tablePK <table primary_key> --logfile <logfile needed for restarts>\n";

    exit;
}

sub getVersioned {

    open (LOG, $logfile);
    while (<LOG>) {
	my $line = $_;
	if ($line =~ /:\t(\d*)/) {
	    $versioned{$1}=1;
	}
    }
}

sub getIds {

    print STDERR "Query to get primary keys: $idSQL\n";
    my $stmt = $dbh->prepareAndExecute($idSQL);
    while(my($id) = $stmt->fetchrow_array()){
	$ct++;
	push(@ids,$id);
	print STDERR "Retrieving $ct ids\n" if $ct % 1000 == 0;
    }
}
    
sub versionRows {
    
    print STDERR "versioning ",scalar(@ids)," rows from $table\n";

    my $tablever = $table . "Ver";

    for(my $i=0;$i<scalar(@ids);$i++){ 
	my $stm = "insert into $tablever (select *,$userId,SYSDATE,1 from $table where $tablePK=$ids[$i])";
	print STDERR "Versioning row with $tablePK:\t$id[$i]\n";
	$ctVer += $dbh->do($stm) if ($versioned{$ids[$i]} != 1);
	$dbh->commit();
	print STDERR "$ctVer rows versioned",`date` if $ctVer%100==0;
    }
}
