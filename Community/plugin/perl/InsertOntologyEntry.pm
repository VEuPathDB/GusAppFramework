######################################################################
##                   InsertOntologyEntry.pm
##
## Plug-in to populate the OntologyEntry table from a tab delimited file.
## $Id$
##
#######################################################################

package GUS::Community::Plugin::InsertOntologyEntry;
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

    $self->initialize({requiredDbVersion => 3.5,
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
	    die "Input file '$oeFile' does not have 11 tab delimited files";
	} 
	
	my $id = $data[0];
	my $parentName = $data[1];

	print "OEID:$id\tParentName:$parentName\n";

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


sub submitOntologyEntryTree {
  my ($self, $id) = @_;
  
  my $ontologyEntry = $self->makeOntologyEntry($id);
  $ontologyEntry->submit();

  my $rowName = $ontologyEntry->getValue();
  # if i have kids, iterate through them, calling this method recursively
  if (my $kids = $self->{parentChildTree}->{$rowName}){
      foreach my $childId (@$kids) {
      $self->submitOntologyEntryTree($childId);
    }
  }
}

sub makeOntologyEntry {

   my ($self, $id) = @_;
   my $pName =              $self->{rowsById}->{$id}->[1];
   my $tName =              $self->{rowsById}->{$id}->[2];
   my $rName =              $self->{rowsById}->{$id}->[3];
   my $val =                $self->{rowsById}->{$id}->[4];
   my $def =                $self->{rowsById}->{$id}->[5];
   my $name =               $self->{rowsById}->{$id}->[6];
   my $cat =                $self->{rowsById}->{$id}->[7];
   my $extDbName =          $self->{rowsById}->{$id}->[8];
   my $extDbRelVersion =    $self->{rowsById}->{$id}->[9];
   my $srcId =              $self->{rowsById}->{$id}->[10];


   print "OE:$id\tpName:$pName\n\n";

   my $dbh = $self->getQueryHandle();

   #Get external_database_release_id based on external database name and version
   my $sth = $dbh->prepare("select external_database_release_id from sres.externaldatabase edb, sres.externaldatabaserelease edbr where edb.external_database_id=edbr.external_database_id and edb.name like '$extDbName' and edbr.version like '$extDbRelVersion'");
   $sth->execute();
   my $extDbRelId = $sth->fetchrow_array();
   
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
       'source_id' => $srcId 
       });
  
   print "TID:$tableId\tRID:$rowId\tPID:$parentId\tVAL:$val\tNAME:$name\tDEF:$def\tCAT:$cat\tEDBR:$extDbRelId\tSRCID:$srcId\n";

   return $oeTerm;
}

1;

