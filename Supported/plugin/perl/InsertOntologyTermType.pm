#######################################################################
##                   InsertOnotolgyTermType.pm
##
## Plug-in to load OntologyTermType from a tab delimited file.
## $Id$
##
#######################################################################

package GUS::Supported::Plugin::InsertOntologyTermType;
@ISA = qw(GUS::PluginMgr::Plugin);
 
use strict;

use FileHandle;
use GUS::ObjRelP::DbiDatabase;
use GUS::Model::SRes::OntologyTermType;
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
 ];


my $purposeBrief = <<PURPOSEBRIEF;
Inserts the Ontology term types, e.g. Class, Individual, etc.
PURPOSEBRIEF

my $purpose = <<PLUGIN_PURPOSE;
Loads the term name and the description of the term into the SRes.OntologyTermType table.
PLUGIN_PURPOSE

my $tablesAffected = [
['SRes.OntologyTermType','Ontology term types are loaded in this tables']
];

my $tablesDependedOn = [];

my $howToRestart = <<PLUGIN_RESTART;
This plugin can not be restarted.  
PLUGIN_RESTART

my $failureCases = <<PLUGIN_FAILURE_CASES;
unknown
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
The input file for this plugin is a two-column tab-delimited file that contains the field name and description.  This file is generated as a table dump from SRes.OntologyTermType.
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

    my $termTypeFile = $self->getArg('inputFile');

    open(TT_FILE, $termTypeFile) || die "Couldn't open file '$termTypeFile'\n";

    while (<TT_FILE>){
	chomp;
	
	my @data = split (/\t/, $_);
	if (scalar(@data) != 2)  {
	    die "inputFile $termTypeFile does not contain 2 columns."
	    }
	
	my $term = $data[0];
	my $definition = $data[1];
	
	my $termType = $self->makeOntologyTermType($term, $definition);
	#$termType->submit() unless $termType->retrieveFromDB();
	if (!$termType->retrieveFromDB($term, $definition)) {
	    $termType->submit();
	    $count++;
	}
	
	undef $term;
	undef $definition;
	#$count++;
    } 
    
    return "Inserted $count terms into OntologyTermType";
}

sub makeOntologyTermType {
   my ($self, $term, $definition) = @_;

   my $term = GUS::Model::SRes::OntologyTermType->new({
       'name' => $term,
       'description' => $definition });
   
   return $term;
}

sub undoTables {
  my ($self) = @_;

  return ('SRes.OntologyTermType');
}

1;
