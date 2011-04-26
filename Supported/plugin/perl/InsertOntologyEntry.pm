######################################################################
##                   InsertOntologyEntry.pm
##
## Plug-in to populate the OntologyEntry table from a tab delimited file.
## $Id$
##
#######################################################################

package GUS::Supported::Plugin::InsertOntologyEntry;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict;

use FileHandle;
use GUS::ObjRelP::DbiDatabase;
use GUS::Model::Study::OntologyEntry;
use GUS::PluginMgr::Plugin;

$| = 1;

my $argsDeclaration =
[

fileArg({name => 'inputFile',
	 descr => 'name of the file with OntologyEntry entries',
	 constraintFunc => undef,
	 reqd => 1,
	 isList => 0,
	 mustExist => 1,
	 format => 'Text'
        }),

stringArg({name  => 'moExternalDatabaseSpec',
		descr => 'The name|version of the external database release of the MGED Ontology to point to',
		constraintFunc=> undef,
		reqd  => 1,
		isList => 0
	       }),

stringArg({name  => 'soExternalDatabaseSpec',
		descr => 'The name|version of the external database release of the Sequence Ontology to point to',
		constraintFunc=> undef,
		reqd  => 1,
		isList => 0
	       }),
 ];


my $purposeBrief = <<PURPOSEBRIEF;
Populates the OntologyEntry table from a file that was generated as a dump of the table with the additional change of replacing all the primary keys with a string to be used as an alternate key.
PURPOSEBRIEF

my $purpose = <<PLUGIN_PURPOSE;
Populates the OntologyEntry table.
PLUGIN_PURPOSE

my $tablesAffected = [
['Study.OntologyEntry','Populate the OntologyEntry table']
    ];

my $tablesDependedOn = ['SRes.ExternalDatabase', 'SRes.ExternalDatabaseRelease','SRes.OntologyTerm', 'Core.TableInfo'];

my $howToRestart = <<PLUGIN_RESTART;
This plugin can be not be restarted.
PLUGIN_RESTART
    
my $failureCases = <<PLUGIN_FAILURE_CASES;
unknown
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
This plugin takes in a tab-delimited file that represents the entries in the OntologyEntry table.  
PLUGIN_NOTES

my $documentation = {purposeBrief => $purposeBrief,
		     purpose => $purpose,
		     tablesAffected => $tablesAffected,
		     tablesDependedOn => $tablesDependedOn,
		     howToRestart => $howToRestart,
		     failureCases => $failureCases,
		     notes => $notes
		    };


sub new {
    my ($class) = @_;
    my $self = {};
    bless($self, $class);

    $self->initialize({requiredDbVersion => 3.6,
		       cvsRevision =>  '$Revision$', #CVS fills this in
		       name => ref($self),
		       argsDeclaration   => $argsDeclaration,
		       documentation     => $documentation
		      });

    return $self;
}

sub run {
    my ($self) = @_;
    my $count=0;
    my $oeFile = $self->getArg('inputFile');

    my $dbh = $self->getQueryHandle();
    #my $extDbRelIds = $self->getExtDbRelIds($dbh); #can this be called elsewhere?

    open(OE_FILE, $oeFile) || die "Couldn't open file '$oeFile'\n";
    
    #declare our three major data structures
    # a list of entries that have no parent
    $self->{roots} = [];

    # a hash with parentName as key and listref of its kids as values
    $self->{parentChildTree} = {};

    # a hash with entry id as key and listref of that complete row as values
    $self->{rowsById} = {};

    my $count;
    while (<OE_FILE>){
	chomp;

	#split attributes, @data is one row from file
	my @data = split (/\t/, $_);
	
	if (scalar(@data) != 11) { 
	    print join (", ", @data);
	    die "Input file '$oeFile' does not have 12 tab delimited files.Please check file and run plugin again\n";
	} 
	
	my $id = $data[0];
	my $parentName = $data[1];

	$self->{rowsById}->{$id} =\@data;

	if (!$parentName) {
	  push(@{$self->{roots}}, $id);
	}
	else {
	  if (!defined $self->{parentChildTree}->{$parentName}) {
	    $self->{parentChildTree}->{$parentName} = [];
	  }
	  push(@{$self->{parentChildTree}->{$parentName}},$id);
	}

	$count++
      }

    foreach my $root (@{$self->{roots}}) {
	$self->submitOntologyEntryTree($root);
    }

    return "Inserted $count terms into OntologyEntry";
}

sub getExtDbRelIds {
  my ($self, $dbh) = @_;
  my $extDbRelIds;

  $self->log("Getting the external database release ids.");
  
  $extDbRelIds->{'mo'} = $self->getExtDbRlsId($self->getArg('moExternalDatabaseSpec'));
  $self->logDebug("MGED Ontology ExtDbRlsId: $extDbRelIds->{'mo'}");

  $extDbRelIds->{'so'} = $self->getExtDbRlsId($self->getArg('soExternalDatabaseSpec'));
  $self->logDebug("Sequence Ontology ExtDbRlsId: $extDbRelIds->{'so'}");

   return $extDbRelIds;
}


sub submitOntologyEntryTree {
  my ($self, $id) = @_;
 
  my $ontologyEntry = $self->makeOntologyEntry($id);
  
  #check that entry does not already exist
  my $dbh = $self->getQueryHandle(); #NOTE: this is now specified in the run method so may not be needed here
  my $category = $ontologyEntry->getCategory();
  my $value = $ontologyEntry->getValue();
  
  my $sth = $dbh->prepareAndExecute("select ontology_entry_id 
                                from study.ontologyentry 
                                where value like '$value' and category like '$category'");
  my $isLoaded = $sth->fetchrow_array();
  if(!$isLoaded)  {
      $ontologyEntry->submit();
      print STDERR "TERM LOADED - Value:$value\tCategory:$category\n\n";
  }
  else {
      print STDERR "TERM NOT LOADED/ALREADY EXISTS - OEID:$isLoaded\tValue:$value\tCategory:$category\n\n";
  }

  # if i have kids, iterate through them, calling this method recursively
  my $rowName = $ontologyEntry->getValue();  
  if (my $kids = $self->{parentChildTree}->{$rowName}){
      foreach my $childId (@$kids) {
      $self->submitOntologyEntryTree($childId);
    }
  }
}

sub makeOntologyEntry {

   my ($self, $id) = @_;
   my $pName =              $self->{rowsById}->{$id}->[1];
   my $extDbSource =           $self->{rowsById}->{$id}->[2]; #NOTE: row will be marked with source of term from DumpStudyOntologyEntry plugin
   #my $extDbRelVersion =    $self->{rowsById}->{$id}->[3]; #NOTE: this will be a value from the cla and then queried out from db instance
   my $srcId =              $self->{rowsById}->{$id}->[3];
   my $tName =              $self->{rowsById}->{$id}->[4];
   my $rName =              $self->{rowsById}->{$id}->[5];
   my $val =                $self->{rowsById}->{$id}->[6];
   my $def =                $self->{rowsById}->{$id}->[7];
   my $name =               $self->{rowsById}->{$id}->[8];
   my $uri =                $self->{rowsById}->{$id}->[9];
   my $cat =                $self->{rowsById}->{$id}->[10];

   my $dbh = $self->getQueryHandle();
   my $extDbRelIds = $self->getExtDbRelIds($dbh);
   
   # NOTE: The value of transformation_protocol_series must be loaded 
   # into the OntologyEntry table since it is needed by the RAD Applications 
   
   my $extDbRelId;
   if ($extDbSource eq "MO_term")  {
       print STDERR "Term is from MO\n";
       #if ($val ne "transformation_protocol_series")  { 
	   $extDbRelId =  $extDbRelIds->{'mo'};
       #}
   }
   elsif ($extDbSource eq "SO_term")  {
       print STDERR "Term is from SO";
       $extDbRelId = $extDbRelIds->{'so'};
   }
   else {
       print STDERR "Term is required for RAD code.  No external_database_release_id exists\n";
   }


=pod
   # the above code for$extDbRelId replaces the commented out code
   my $extDbRelId;
   if ($extDbUri eq "http://mged.sourceforge.net/ontologies/MGEDOntology.daml")  {
       print STDERR "Term is from MO\n";
       if ($val ne "transformation_protocol_series")  { 
	   #Get external_database_release_id based on external database uri and version
	   my $sth = $dbh->prepare("select external_database_release_id from sres.externaldatabaserelease edbr where edbr.download_url like '$extDbUri' and edbr.version like '$extDbRelVersion'");
	   $sth->execute();
	   $extDbRelId = $sth->fetchrow_array() || die "Value:$val - The entry for the MGED Ontology can not be found in the SRes.ExternalDatabaseRelease table for the version of the MGED Ontology used in the input file.\n";
       }
   }
   else {
       print STDERR "Term is not from the MGED Ontology\n";
       my $sth = $dbh->prepare("select external_database_release_id from sres.externaldatabaserelease edbr where edbr.download_url like '$extDbUri' and edbr.version like '$extDbRelVersion'");
       $sth->execute();
       $extDbRelId = $sth->fetchrow_array();
   }
=cut   

   #Get table_id based on table name
   my $sth = $dbh->prepare("select table_id from core.tableinfo where name like '$tName'");
   $sth->execute();
   my $tableId = $sth->fetchrow_array();
   
   #Get row_id based on name of term, need ext db version
   my $sth = $dbh->prepare("select ontology_term_id from sres.ontologyterm where name like '$rName' and external_database_release_id='$extDbRelId'");
   $sth->execute();
   my $rowId = $sth->fetchrow_array();
      
   #Get parent_id based on name of parent term, need ext db version
   $sth = $dbh->prepare("select ontology_entry_id from study.ontologyentry where value like '$pName'");
   $sth->execute();
   my $parentId = $sth->fetchrow_array();
   
   my $oeTerm = GUS::Model::Study::OntologyEntry->new({
       'table_id' => $tableId,
       'row_id' => $rowId,
       'parent_id' => $parentId,
       'value' => $val,
       'name' => $name,
       'definition' => $def,
       'category' => $cat,
       'external_database_release_id' => $extDbRelId,
       'source_id' => $srcId, 
       'uri' =>  $uri   
      });
  
   print STDERR "TID:$tableId\tRID:$rowId\tPID:$parentId\tVAL:$val\tNAME:$name\tDEF:$def\tCAT:$cat\tEDBR:$extDbRelId\tSRCID:$srcId\tURI:$uri\n";

   return $oeTerm;
}

1;

