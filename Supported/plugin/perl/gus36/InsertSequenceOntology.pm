#######################################################################
##                   LoadSequenceOnotolgy.pm
##
## Plug-in to load Sequence Ontology from a tab delimited file.
## $Id$
##
#######################################################################

# this plugin is incompatible with version 4.0 of GUS because it references tables
# which have been dropped, such as sres.SequenceOntology

package GUS::Supported::Plugin::InsertSequenceOntology;
@ISA = qw(GUS::PluginMgr::Plugin);
 
use strict;

use FileHandle;
use GUS::ObjRelP::DbiDatabase;
use GUS::Model::SRes::SequenceOntology;
use GUS::PluginMgr::Plugin;

$| = 1;


my $argsDeclaration =
[

 fileArg({name => 'inputFile',
	  descr => 'name of the SO definition file',
	  constraintFunc => undef,
	  reqd => 1,
	  isList => 0,
	  mustExist => 1,
	  format => 'Text'
        }),

 stringArg({name => 'soVersion',
	    descr => 'version of Sequence Ontology',
	    constraintFunc => undef,
	    reqd => 1,
	    isList => 0
	   }),

 stringArg({name => 'soCvsVersion',
	    descr => 'cvs version of Sequence Ontology',
	    constraintFunc => undef,
	    reqd => 1,
	    isList => 0
	   })

 ];


my $purposeBrief = <<PURPOSEBRIEF;
Inserts the Sequence Ontology from an so.definition file.
PURPOSEBRIEF

my $purpose = <<PLUGIN_PURPOSE;
Extracts the id, term, and definition fields from an so.definition file and inserts new entries into into the SRes.SequenceOntology table in the form so_id, ontology_name, so_version, so_cvs_version, term_name, definition.
PLUGIN_PURPOSE

my $tablesAffected = [
['SRes.SequenceOntology','New SO entries are placed in this table']
];

my $tablesDependedOn = [];

my $howToRestart = <<PLUGIN_RESTART;
This plugin can be restarted.  Before it submits an SO term, it checks for its existence in the database, skipping it if it is already there.
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

    my $soId;
    my $term;
    my $definition;
    my $count= 0;

    my $soFile = $self->getArg('inputFile');

    open(SO_FILE, $soFile) || die "Couldn't open file '$soFile'\n";

    while (<SO_FILE>){
      next if (/^!/);
      next if (/^\s*$/);
      next if (/definition_reference:\s(.+)$/);
      next if (/comment:\s(.+)$/);
      chomp;

      if (!$term) {
	/term:\s(.+)$/ || die "unexpected file format";
	$term = $1;
	next;
      }

      if (!$soId) {
	/id:\s(.+)$/ || die "unexpected file format";
	$soId = $1;
	next;
      }

      if (!$definition) {
	/definition:\s(.+)$/ || die "unexpected file format";
	$definition = $1;

	my $soTerm = $self->makeSequenceOntology($soId,$term,$definition);
	$soTerm->submit() unless $soTerm->retrieveFromDB();
	if($count % 100 == 0){
	    $self->log("Submitted $count terms");
	}

	undef $soId;
	undef $term;
	undef $definition;
	$count++
      }

    }

    return "Inserted $count terms into SequenceOntology";
  }

sub makeSequenceOntology {

   my ($self, $SOid, $term, $definition) = @_;

   my $soVersion =  $self->getArg('soVersion');
   my $soCvsVersion = $self->getArg('soCvsVersion');
   my $ontologyName = 'sequence';

   my $soTerm = GUS::Model::SRes::SequenceOntology->
     new({'so_id' => $SOid,
	  'ontology_name' => $ontologyName, #this is hard coded
	  'so_version' => $soVersion,
	  'so_cvs_version' => $soCvsVersion,
	  'term_name' => $term,
	  'definition' => $definition });

   return $soTerm;
}


1;
