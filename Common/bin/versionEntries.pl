#!@perl@

##takes in an SQL query and versions entries one at a time...
## query must return primary key of versioned table.

use strict;
use lib "$ENV{GUS_HOME}/lib/perl";
use Getopt::Long;
use GUS::ObjRelP::DbiDatabase;
use GUS::Model::Core::TableInfo;
use GUS::Common::GusConfig;

$| = 1;

my ($verbose,$idSQL,$table,$userId,$tablePK,$logfile,$gusConfigFile);
&GetOptions("verbose!"=> \$verbose,
	    "idSQL=s" => \$idSQL, 
	    "table=s" => \$table,
	    "gusConfigFile=s" => \$gusConfigFile,
	    "userId=i" => \$userId,
	    "tablePK=s" => \$tablePK,
	    "logfile=s" => \$logfile);

print STDERR "Establishing dbi login\n" if $verbose;

my $gusconfig = GUS::Common::GusConfig->new($gusConfigFile);

my $db = GUS::ObjRelP::DbiDatabase->new($gusconfig->getDbiDsn(),
					$gusconfig->getReadOnlyDatabaseLogin(),
					$gusconfig->getReadOnlyDatabasePassword(),
					$verbose,0,1,
					$gusconfig->getCoreSchemaName());

my $dbh = $db->getQueryHandle();

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

    print STDERR "usage: deleteEntries.pl --idSQL 'sql query returns primary keys of table' --table <tablename to version in schema.table format> --userId <user_id from UserInfo> --tablePK <table primary_key> --logfile <logfile needed for restarts> --gusConfigFile <\$GUS_CONFIG_FILE>\n";

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
    $tablever =~ s/\./Ver./;

    for(my $i=0;$i<scalar(@ids);$i++){ 
	my $stm = "insert into $tablever (select *,$userId,SYSDATE,1 from $table where $tablePK=$ids[$i])";
	print STDERR "Versioning row with $tablePK:\t$ids[$i]\n";
	$ctVer += $dbh->do($stm) if ($versioned{$ids[$i]} != 1);
	$dbh->commit();
	print STDERR "$ctVer rows versioned",`date` if $ctVer%100==0;
    }
}
