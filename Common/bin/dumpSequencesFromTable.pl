#!/usr/bin/perl

## dumps sequences from sequence table 
##note the sequence must be returned as thelast item

## Brian Brunk 01/05/2000

use strict;
use DBI;
use Getopt::Long;
use Objects::GUS::ObjRelP::DbiDatabase;
use CBIL::Bio::SequenceUtils;

my ($login,$password,$debug,$verbose,$outFile,$idSQL,$minLength,$database);
&GetOptions("verbose!"=> \$verbose,
            "outputFile=s" => \$outFile,"idSQL=s" => \$idSQL, 
            "minLength=i" => \$minLength,"debug!" => \$debug,
            "login=s" => \$login,"password=s" => \$password,
            "database=s" => \$database );

if(!$idSQL || !$outFile){
	die "usage: dumpSequencesFromFile.pl --outputFile <outfile> --verbose --debug --idSQL 'sql stmt that returns (primary_identifier,arbritrary number of atts to be joined on defline by spaces,sequence)' --minLength <minimum length to output [1]> --login [GUSrw] --database [GUSdev]\n";
}

##set the defaults
$minLength = $minLength ? $minLength : 1;
$database = $database ? $database : "GUSdev";
$login = $login ? $login : 'gusrw';

if(!$password){
  print STDERR "Enter the password for login $login\n";
  $password = <STDIN>;
  chomp $password;
}

print STDERR "Establishing dbi login\n" if $verbose;
my $db = new GUS::ObjRelP::DbiDatabase( undef, $login, $password, $verbose, 0, 1, $database );

my $dbh = $db->getQueryHandle();

##want to be able to restart it....
my %done;
if(-e $outFile){
	open(F,"$outFile");
	while(<F>){
		if(/^\>(\S+)/){
			$done{$1} = 1;
		}
	}
	close F;
	print STDERR "Ignoring ".scalar(keys%done)." entries already dumped\n" if $verbose;
}

open(OUT,">>$outFile");

print STDERR "SQL: $idSQL\n" if $verbose;
my $count = 0;
my $idStmt = $dbh->prepare($idSQL);
$idStmt->execute();
my @ids;
while(my (@row) = $idStmt->fetchrow_array()){
  $count++;
  print STDERR "Getting id for $count\n" if $verbose && $count % 10000 == 0;
  next if exists $done{$row[0]};  ##don't put into hash if already have...
  &printSequence(@row)
}

sub printSequence{
	my @row = @_;
#	print STDERR "$gene_id,$na_id,$description,$number,$taxon,$assembly_id,$length,$seq_ver\n";
  my $sequence = pop(@row);
  if(length($sequence) < $minLength){
    print STDERR "ERROR: $row[0] too short: ",length($sequence),"\n";
    return;
  }
	my $defline = "\>".join(' ',@row)."\n";
	print OUT $defline . SequenceUtils::breakSequence($sequence,60);
}

