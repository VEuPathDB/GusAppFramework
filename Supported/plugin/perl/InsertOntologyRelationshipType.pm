##                   InsertOnotolgyRelationshipType.pm
##
## Plug-in to load OntologyRelationshipType from a tab delimited file.
## $Id$
##
#######################################################################

package GUS::Supported::Plugin::InsertOntologyRelationshipType;
@ISA = qw(GUS::PluginMgr::Plugin);
 
use strict;

use FileHandle;
use GUS::ObjRelP::DbiDatabase;
use GUS::Model::SRes::OntologyTerm;
use GUS::PluginMgr::Plugin;

$| = 1;


my $argsDeclaration =  [
 fileArg({name => 'inputFile',
	  descr => 'name of the inputFile file',
	  constraintFunc => undef,
	  reqd => 1,
	  isList => 0,
	  mustExist => 1,
	  format => 'Text'
        }),

 stringArg({ descr => 'Name of the External Database',
	     name  => 'extDbRlsSpec',
	     isList    => 0,
	     reqd  => 1,
	     constraintFunc => undef,
	   }),

 ];


my $purposeBrief = <<PURPOSEBRIEF;
Inserts the Ontology term types, e.g. Class, Individual, etc.
PURPOSEBRIEF

my $purpose = <<PLUGIN_PURPOSE;
Loads the term name and the description of the term into the SRes.OntologyTerm table.
PLUGIN_PURPOSE

my $tablesAffected = [
['SRes.OntologyTerm','Ontology relationship types are loaded in this tables']
];

my $tablesDependedOn = [];

my $howToRestart = <<PLUGIN_RESTART;
This plugin can not be restarted.  
PLUGIN_RESTART

my $failureCases = <<PLUGIN_FAILURE_CASES;
unknown
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
The input file to this plugin is a two-column tab-delimited file.  The first column is the field name and the second column is the field is_native.  The input file for this plugin is generated as a table dump from SRes.OntologyRelationshipType by selecting the above two columns.
PLUGIN_NOTES

my $documentation = {purposeBrief => $purposeBrief,
		     purpose => $purpose,
		     tablesAffected => $tablesAffected,
		     tablesDependedOn => $tablesDependedOn,
		     howToRestart => $howToRestart,
		     failureCases => $failureCases,
		     notes => $notes
		    };


sub getExtDbRls {$_[0]->{ext_db_rls_id}}
sub setExtDbRls {$_[0]->{ext_db_rls_id} = $_[1]}

sub new {
    my ($class) = @_;
    my $self = {};
    bless($self, $class);

    $self->initialize({requiredDbVersion => 4.0,
		       cvsRevision =>  '$Revision$', #CVS fills this in
		       name => ref($self),
		       argsDeclaration   => $argsDeclaration,
		       documentation     => $documentation
		      });
    return $self;
}

sub run {
    my ($self) = @_;

    my $term;
    my $definition;
    my $count = 0;

    my $relationshipTypeFile = $self->getArg('inputFile');
    my $extDbRlsId = $self->getExtDbRlsId($self->getArg('extDbRlsSpec'));
    $self->setExtDbRls($extDbRlsId);

    open(RT_FILE, $relationshipTypeFile) || die "Couldn't open file '$relationshipTypeFile'\n";

    while (<RT_FILE>){
	chomp;
	
	my @data = split (/\t/, $_);
	if (scalar(@data) != 2)  {
	    die "inputFile $relationshipTypeFile does not contain 2 columns."
	}
	
	my $term = $data[0];
	my $is_native = $data[1];
	
	my $relType = $self->makeOntologyRelType($term,$is_native);
	$relType->submit() unless $relType->retrieveFromDB();
	
	undef $term;
	undef $is_native;
	$count++
	}  
    return "Inserted $count terms into OntologyRelationshipType";
}

sub makeOntologyRelType {
   my ($self, $term, $is_native) = @_;
   my $extDbRls = $self->getExtDbRls();

   my $term = GUS::Model::SRes::OntologyTerm->new({
       'name' => $term,
       'external_database_release_id' => $extDbRls });
   
   return $term;
}

sub undoTables {
  my ($self) = @_;

  return ('SRes.OntologyTerm');
}

1;
