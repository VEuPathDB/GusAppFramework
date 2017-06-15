#!/usr/bin/perl

use strict;

use lib "$ENV{GUS_HOME}/lib/perl";

use Getopt::Long;

use DBI;
use DBD::Oracle;

my ($gusConfigFile, $externalDatabaseName);

&GetOptions("gusConfigFile|gc=s"=> \$gusConfigFile,
            "externalDatabaseName=s" => \$externalDatabaseName,
    );

$gusConfigFile = $ENV{GUS_HOME} . "/config/gus.config" unless(-e $gusConfigFile);

unless($externalDatabaseName) {
  die "Required param externalDatabaseName is missing";  
}

unless(-e $gusConfigFile) {
  die "GUS Config file $gusConfigFile does not exist";
}

my $gusConfig = GUS::Supported::GusConfig->new($gusConfigFile);

my $db = GUS::ObjRelP::DbiDatabase->new($gusConfig->getDbiDsn(),
                                         $gusConfig->getDatabaseLogin(),
                                         $gusConfig->getDatabasePassword(),
                                         0, 0, 1,
                                         $gusConfig->getCoreSchemaName()
                                        );

my $dbh = $db->getQueryHandle();

# this gets back all versions of this ontology
my $extDbRlsIdsSql = "select r.external_database_release_id 
  from SRES.EXTERNALDATABASE d, sres.externaldatabaserelease r 
  where d.name = '$externalDatabaseName' and d.EXTERNAL_DATABASE_ID = r.EXTERNAL_DATABASE_ID";

my $delRelsRows = $dbh->do("delete sres.ontologyrelationship where EXTERNAL_DATABASE_RELEASE_ID in ($extDbRlsIdsSql)");

my $delSynRows = $dbh->do("delete sres.ontologysynonym where EXTERNAL_DATABASE_RELEASE_ID in ($extDbRlsIdsSql)");

$dbh->commit();

$dbh->disconnect();

print STDERR "Deleted $delRelsRows from OntologyRelationship and $delSynRows from OntologySynonym for ExternalDatabase $externalDatabaseName";

1;
