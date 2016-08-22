#######################################################################
##                   LoadSequenceOnotolgyOBO.pm
##
## Plug-in to load Sequence Ontology from a tab delimited file.
## $Id: InsertSequenceOntology.pm 3400 2005-09-06 19:10:34Z jldommer $
##
## Drafted from the old LoadSequenceOntologyPlugin, Oct, 2005 E.R.
#######################################################################

package GUS::Supported::Plugin::InsertSequenceOntologyOBO;
@ISA = qw(GUS::PluginMgr::Plugin);
 
use strict;

use FileHandle;
use GUS::ObjRelP::DbiDatabase;
use GUS::Model::SRes::OntologyTerm;
use GUS::PluginMgr::Plugin;

$| = 1;


my $argsDeclaration =
[

 fileArg({name => 'inputFile',
	  descr => 'name of the SO OBO file (usually, so.obo)',
	  constraintFunc => undef,
	  reqd => 1,
	  isList => 0,
	  mustExist => 1,
	  format => 'Text'
        }),

 stringArg({name => 'extDbRlsSpec',
	    descr => 'The extDbRlsSpec of Sequence Ontology',
	    constraintFunc => undef,
	    reqd => 0,
	    isList => 0
	   }),

 ];


my $purposeBrief = <<PURPOSEBRIEF;
Inserts the Sequence Ontology from so.obo file.
PURPOSEBRIEF

my $purpose = <<PLUGIN_PURPOSE;
Extracts the id, name, and def fields from a so.obo file and inserts new entries into into the SRes.OntologyTerm table.
PLUGIN_PURPOSE

my $tablesAffected = [
['SRes.OntologyTerm','New SO entries are placed in this table']
];

my $tablesDependedOn = [];

my $howToRestart = <<PLUGIN_RESTART;
This plugin can be restarted.  Before it submits an SO term, it checks for its existence in the database, skipping it if it is already there.
PLUGIN_RESTART

my $failureCases = <<PLUGIN_FAILURE_CASES;
unknown
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
This plugin parses OBO format and is valid for any version of so.obo.  It replaces the older versions of this plugin which used the so.definition file.
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
		       cvsRevision =>  '$Revision$',
		       name => ref($self),
		       argsDeclaration   => $argsDeclaration,
		       documentation     => $documentation
		      });

    return $self;
}

sub run {
    my ($self) = @_;

    my $obo;
    my $type;
    my $count= 0;

    my $soFile = $self->getArg('inputFile');

    my $extDbRlsSpec = $self->getArg('extDbRlsSpec');

    my $extDbRlsId = $self->getExtDbRlsId($extDbRlsSpec);

    open(SO_FILE, $soFile);

    while (<SO_FILE>){

      if (/^\n/) {
        unless ($type ne 'Term') {
           my $soTerm = $self->makeSequenceOntology($obo, $extDbRlsId);
              $soTerm->submit() unless $soTerm->retrieveFromDB();
              $count++;
                  if($count % 100 == 0){
                      $self->log("Submitted $count terms");
                  }
        }
        undef $obo; #may have left over defs.
        undef $type;
      }
      else {
        if (/\[(Term)\]/ || /\[(Typedef)\]/) {
           $type = $1; 
        }
        my ($nam,$val) = split(/\:\s/,$_,2);
        $obo->{$nam} = $val;
      }
   }
   return "Inserted $count terms into OntologyTerm";
}

sub makeSequenceOntology {
   my ($self, $obo, $extDbRlsId) = @_;

   if (!$obo->{'name'} || !$obo->{'id'}) {
      $self->error("Invalid OBO File: missing term name or so id");
   }

   my $definition = $obo->{'def'};

   if ($definition eq '') {$definition = ' '};

   $definition =~ s/\n//g;
   $obo->{'id'}=~ s/\n//g;
   $obo->{'name'}=~ s/\n//g;


   my $soTerm = GUS::Model::SRes::OntologyTerm->
     new({'source_id' => $obo->{'id'},
          'external_database_release_id' => $extDbRlsId,
	  'name' => $obo->{'name'},
	  'definition' => $definition }
     );
 
   return $soTerm;
}

sub undoTables {
   qw(
   SRes.OntologyTerm
   );
}
1;
