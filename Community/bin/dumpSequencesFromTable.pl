#!/usr/bin/perl

## dumps sequences from sequence table 
##note the sequence must be returned as thelast item

## Brian Brunk 01/05/2000

use strict;
use lib "$ENV{GUS_HOME}/lib/perl";
use Getopt::Long;
use GUS::ObjRelP::DbiDatabase;
use CBIL::Bio::SequenceUtils;
use CBIL::Util::PropertySet;

use Data::Dumper;

my ($gusConfigFile,$debug,$verbose,$outFile,$idSQL,$minLength);
&GetOptions("verbose!"=> \$verbose,
            "outputFile=s" => \$outFile,"idSQL=s" => \$idSQL, 
            "minLength=i" => \$minLength,"debug!" => \$debug,
            "gusConfigFile=s" => \$gusConfigFile);

if(!$idSQL || !$outFile){
	die "usage: dumpSequencesFromFile.pl --outputFile <outfile> --verbose --debug --idSQL 'sql stmt that returns (primary_identifier,arbritrary number of atts to be joined on defline by spaces,sequence)' --minLength <minimum length to output [1]> --gusConfigFile [\$GUS_CONFIG_FILE]\n";
}

if(!$gusConfigFile) {
  $gusConfigFile = $ENV{GUS_HOME} . "/config/gus.config";
  
}

my $CHUNK_SIZE;

my @properties = ();

##set the defaults
$minLength = $minLength ? $minLength : 1;

print STDERR "Establishing dbi login\n" if $verbose;
die "Config file $gusConfigFile does not exist." unless -e $gusConfigFile;

my $gusconfig = CBIL::Util::PropertySet->new($gusConfigFile, \@properties, 1);

my $db = GUS::ObjRelP::DbiDatabase->new($gusconfig->{props}->{dbiDsn},
                                        $gusconfig->{props}->{databaseLogin},
                                        $gusconfig->{props}->{databasePassword},
					$verbose,0,1,
					$gusconfig->{props}->{coreSchemaName},
				       );

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
my $idStmt = $dbh->prepare($idSQL, { ora_auto_lob => 0 })  or die "Can't prepare SQL statement: " . $dbh->errstr();
$idStmt->execute();
my @ids;
while(my (@row) = $idStmt->fetchrow_array()){
  $count++;
  print STDERR "Getting id for $count\n" if $verbose && $count % 10000 == 0;
  next if exists $done{$row[0]};  ##don't put into hash if already have...
  &printSequence($dbh, \@row);
}

sub printSequence {
	my ($dbh, $row) = @_;
#	print STDERR "$gene_id,$na_id,$description,$number,$taxon,$assembly_id,$length,$seq_ver\n";

  my @row = @$row;

  my $lobLoc = pop(@row);

  my $sequence = &readClob($lobLoc, $dbh);


  if(length($sequence) < $minLength){
    print STDERR "ERROR: $row[0] too short: ",length($sequence),"\n";
    return;
  }
	my $defline = "\>".join(' ',@row)."\n";
	print OUT $defline . CBIL::Bio::SequenceUtils::breakSequence($sequence,60);
}

sub readClob {
  my ($lobLocator, $dbh) = @_;

  my $chunkSize = defined $CHUNK_SIZE ? $CHUNK_SIZE : $dbh->ora_lob_chunk_size($lobLocator);

  my $offset = 1;   # Offsets start at 1, not 0

  my $output;

  while(1) {
    my $data = $dbh->ora_lob_read($lobLocator, $offset, $chunkSize );
    last unless length $data;
    $output .= $data;
    $offset += $chunkSize;
  }

  return $output;
}
