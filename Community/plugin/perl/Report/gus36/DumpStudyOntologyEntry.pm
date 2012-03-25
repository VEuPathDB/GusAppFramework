
package GUS::Community::Plugin::Report::DumpStudyOntologyEntry;
@ISA = qw(GUS::PluginMgr::Plugin);

# ----------------------------------------------------------------------

use strict;

use FileHandle; 

use GUS::PluginMgr::Plugin;

use GUS::PluginMgr::PluginUtilities::ConstraintFunction;
use GUS::PluginMgr::PluginUtilities;

use GUS::Model::Study::OntologyEntry;
use GUS::Model::SRes::ExternalDatabaseRelease;
use GUS::Model::SRes::ExternalDatabase;

# ======================================================================

sub new {
   my $Class = shift;

   my $self = bless {}, $Class;

   my $selfPodCommand = 'pod2text '. __FILE__;
   my $selfPod        = `$selfPodCommand`;

   $self->initialize
   ({ requiredDbVersion => '3.6',
      cvsRevision       => ' $Revision:  $ ',
      name              => ref($self),

      # just expand
      revisionNotes     => '',
      revisionNotes     => 'initial creation and testing',

      # ARGUMENTS
      argsDeclaration   =>
      [
       stringArg({name  => 'fileName',
		  descr => 'The name of the output file to write contents of table dump to',
		  constraintFunc=> undef,
		  reqd  => 1,
		  isList => 0
		  }),
       
      ],

      # DOCUMENTATION
      documentation     =>
      { purpose          => <<Purpose,

  This plugin dumps the content of the Study.OntologyEntry table for those rows that are from the MGED Ontology and Sequence Ontology and re-formats the data so that the value of the parent_id contains the Study.OntologyEntry.value string to allow for use in GUS instances outside of CBIL.

Purpose
        purposeBrief     => 'Dump contents of Study.OntologyEntry for entries that are from the MGED Ontology and the Sequence Ontology and re-format any primary key values to strings so that the file can be used by other GUS instances.',
        tablesAffected   => 
        [ ],
        tablesDependedOn =>
        [
        ],
        howToRestart     => 'just restart; this is a reader',
        failureCases     => 'just run again',
        notes            => $selfPod,
      },
    });

   # RETURN
   $self
}

# ======================================================================

sub run {	
    my $Self = shift;
    $Self->logArgs();
    
    open (FILE, ">" . $Self->getArg('fileName'));
    print FILE ("OE_ID\tPARENT_NAME\tEXT_DB_SOURCE\tSOURCE\tTABLE_NAME\tROW_NAME\tVALUE\tDEF\tNAME\tURI\tCATEGORY\n");
    
    # seed hash with value that is not queriable in bulk hash query
    my ($value, $key);
    my %hash = ();
    my $seedValue = 'MGEDOntology';
    my $sth = $Self->getQueryHandle()->prepareAndExecute("select ontology_entry_id from study.ontologyentry where value like '$seedValue'");
    my $seedKey = $sth->fetchrow_array();
    $sth->finish();

    # Query table to build hash
    # Use this to replace parent_id with string oe.value of parent row
    my $sth = $Self->getQueryHandle()->prepareAndExecute("select value, ontology_entry_id from study.ontologyentry where  category not in ('CellLine', 'CellType', 'DevelopmentalStage', 'DiseaseState', 'HistologyDatabase', 'OrganismPart', 'StrainOrLine', 'TargetedCellTypeDatabase', 'TumorGradingDatabase') and (name not like 'user_defined' or name is null or value like 'transformation_protocol_series') and parent_id is not null");
    # Build hash
    while (my @ary = $sth->fetchrow_array())  {
	$value = shift@ary;
	$key = shift@ary;
	$hash{$key}=$value;
	$hash{$seedKey} = $seedValue; #added this here
    }

    # Query to dump all the data
    my $sql = "select ontology_entry_id, parent_id, external_database_release_id, source_id, table_id, row_id, value, definition, name, uri, category  from study.ontologyentry where category not in ('CellLine', 'CellType', 'DevelopmentalStage', 'DiseaseState', 'HistologyDatabase', 'OrganismPart', 'StrainOrLine', 'TargetedCellTypeDatabase', 'TumorGradingDatabase') and (name not like 'user_defined' or name is null or value like 'transformation_protocol_series') and value not like 'activity_units_per_ml'";
    
    my $sth = $Self->getQueryHandle()->prepareAndExecute($sql);
    while (my @arr = $sth->fetchrow_array())  {
	
	my $oeId = shift@arr;
	my $parentId = shift@arr;
	my $extDbRelId = shift@arr;
	my $srcId = shift@arr;
	my $tableId = shift@arr;
	my $rowId = shift@arr;
	my $value = shift @arr;
	my $def = shift@arr;
	my $name = shift@arr;
	my $uri = shift@arr;
	my $category = shift@arr;
	
	# Replace extDbRelId with name of resource
	my  $resourceName ;
	my $sth = $Self->getQueryHandle()->prepareAndExecute("select edb.name from sres.externaldatabase edb, sres.externaldatabaserelease edbr where edbr.external_database_id=edb.external_database_id and edbr.external_database_release_id='$extDbRelId'");
	my $extDbName = $sth->fetchrow_array();
	if ($extDbName eq 'MGED Ontology')  {
	    $resourceName = 'MO_term';
	}
	elsif ($extDbName eq 'SequenceOntology')  {
	    $resourceName = 'SO_term';
	}
	else {
	    $resourceName = 'RAD_term';
	}
	
	# Replace rowId
	my $rowName = $value;

	# Replace tableId
	my $sth = $Self->getQueryHandle()->prepareAndExecute("select ti.name from core.tableinfo ti where ti.table_id='$tableId'");
	my $tableName = $sth->fetchrow_array();
	
	# Replace parentId
	my $parentName = $hash{$parentId};
	
	$Self->logData("$oeId\t$parentName\t$resourceName\t$srcId\t$tableName\t$rowName\t$value\t$def\t$name\t$uri\t$category");

	print FILE ("$oeId\t$parentName\t$resourceName\t$srcId\t$tableName\t$rowName\t$value\t$def\t$name\t$uri\t$category\n");
    }
    close (FILE);
}
# ----------------------------------------------------------------------

1;
