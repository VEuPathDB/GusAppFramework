#!/usr/bin/perl

use strict;
use GUS::Supported::GusConfig;
use DBI;

my @schemas = ( "DoTS", "Core", "Prot", "SRes", "TESS", "Study", "RAD",
		"DoTSVer", "CoreVer", "ProtVer", "SResVer", "TESSVer", "StudyVer", 
                "RADVER");

my $configFile = "$ENV{GUS_HOME}/config/gus.config";
my $gusConfig = GUS::Supported::GusConfig->new($configFile);

my $dbi = $gusConfig->getDbiDsn();
my $schemaList;
my $dbLogin = $gusConfig->getDatabaseLogin();

foreach my $schema ( @schemas ) {
    $schemaList .= $schema . " ";
}   

print<<END;

***************************************************************************
***************************************************************************
WARNING!  This script will deinstall an instance of GUS by dropping 
(deleting) GUS schemas/users.  This will operate on:

Username: $dbLogin

Database: $dbi

Schemas: $schemaList

The user listed above must have dba privileges to continue

***************************************************************************
***************************************************************************

END

print "Type YES to continue.  All other input will cancel: ";

my $response = <STDIN>;
chomp($response);

if ( $response ne "YES" ) {
    print "\n\n Aborted. \n\n";
    exit;
}

my $dbh = DBI->connect($gusConfig->getDbiDsn(),
		       $gusConfig->getDatabaseLogin(),
		       $gusConfig->getDatabasePassword())
    or die("Unable to connect to the database");

my $modifier;

if ( $gusConfig->getDatabaseVendor() =~ /Oracle/i ) { $modifier = "user"; } 
elsif ( $gusConfig->getDatabaseVendor() =~ /Postgres/i ) { $modifier = "schema"; }
else { die("Unknown Database Vendor: ".$gusConfig->getDatabaseVendor()); }

foreach my $schema ( @schemas ) {
    my $sql = "drop $modifier $schema cascade;";
    print $sql . "\n";
}


print "\nDone.\n";


1;
