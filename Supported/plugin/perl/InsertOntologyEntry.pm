#######################################################################
##                   InsertOnotolgyEntry.pm
##
## Plug-in to populate the OntologyEntry table from a tab delimited file.
## $Id:$
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
 ];


my $purposeBrief = <<PURPOSEBRIEF;
Populates the OntologyEntry table from a file that was generated as a dump of the table with the additional change of replaicing all the primary keys with a string to be used as an alternate key.
PURPOSEBRIEF

my $purpose = <<PLUGIN_PURPOSE;
Populates the OntologyEntry table.
PLUGIN_PURPOSE

my $tablesAffected = [
['Study.OntologyEntry','Populate the OntologyEntry table']
];

my $tablesDependedOn = ['SRes.ExternalDatabase', 'SRes.ExternalDatabaseRelease','SRes.MGEDOntologyTerm', 'Core.TableInfo'];

my $howToRestart = <<PLUGIN_RESTART;
This plugin can be ??? restarted.  Before it submits a row into OntologEntry, it checks for its existence in the database, skipping it if it is already there.
PLUGIN_RESTART

my $failureCases = <<PLUGIN_FAILURE_CASES;
unknown
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
This plugin is sensitive to changes in the SO file format and should be checked for compatibility with each new so.definition release.  Currently we expect the entries to be in block format with term, SOid, Definition, and definition_reference newline delimited, with a blank line between each entry.  If this format changes, the plugin may need to be modified.
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
		       cvsRevision =>  '$Revision: $', #CVS fills this in
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
    
    while (<OE_FILE>){
	chomp;

	#my ($t_name, $r_name, $p_name, $val, $def, $name, $cat, $ext_db_name, $ext_db_rel_version, $src_id) = split (/\t/, $_);
	my @data = split (/\t/, $_);

        #Add checks for file format?

	my $oeTerm = $self->makeOntologyEntry(@data);
	$oeTerm->submit() unless $oeTerm->retrieveFromDB();

	undef @data;

#	undef $t_name;
#	undef $r_name;
#	undef $p_name;
#	undef $val;
#	undef $def;
#	undef $name;
#	undef $cat;
#	undef $ext_db_name;
#	undef $ext_db_rel_version;
#	undef $src_id;
	$count++
	}
    return "Inserted $count terms into OntologyEntry";
}

sub makeOntologyEntry {

   my ($self, @data) = @_;
   my $t_name = @data[0];
   my $r_name = @data[1];
   my $p_name = @data[2];
   my $val = @data[3];
   my $def = @data[4]; 
   my $name = @data[5];
   my $cat = @data[6];
   my $ext_db_name = @data[7];
   my $ext_db_rel_version = @data[8];
   my $src_id = @data[9]; 

   #Get table_id based on table name
   my $t_id = getTableId($t_name);
   
   #Get row_id based on name of term, need ext db version
   

   #Get parent_id based on name of parent term, need ext db version
   

   #Get external_database_release_id based on external databaes name and version
   my $ext_db_rel_id = getExternalDatabaseReleaseId($ext_db_name, $ext_db_rel_version);


   my $oeTerm = GUS::Model::Study::OntologyEntry->new({
       'table_id' => $t_id,
       #'row_id' => $r_id;
       #'parent_id' => $p_id,
       'value' => $val,
       'name' => $name,
       'definition' => $def,
       'category' => $cat,
       'external_database_release_id' => $ext_db_rel_id,
       'source_id' => $src_id 
       });
   
   return $oeTerm;
}

1;
