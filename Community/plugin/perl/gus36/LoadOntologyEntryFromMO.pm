package GUS::Community::Plugin::LoadOntologyEntryFromMO;

# this plugin is incompatible with version 4.0 of GUS because it references tables
# which have been dropped, such as study.OntolgyEntry

@ISA = qw(GUS::PluginMgr::Plugin);

use strict;

use GUS::Model::Study::OntologyEntry;
use GUS::Model::SRes::OntologyTerm;
use GUS::Model::SRes::OntologyRelationship;

use GUS::PluginMgr::Plugin;

use Data::Dumper;

my $argsDeclaration = 
  [ fileArg({name => 'nameChangesFile',
             descr => 'Any time a something is renamed since the previous version of MO.  This can also be use_def terms upgraded to official terms.  OldName<TAB>NewName',
             constraintFunc => undef,
             reqd => 0,
             isList => 0,
             mustExist => 1,
             format => 'Text'
            }),

    stringArg({name => 'externalDatabase',
               descr => 'External database for the MO Terms',
               constraintFunc=> undef,
               reqd  => 1,
               isList => 0
              }),

    stringArg({name => 'externalDatabaseRls',
               descr => 'Version of external database for the NEW Release existing in SRes::OntologyTerm which we will be updating in Study::OntologyEntry',
               constraintFunc=> undef,
               reqd  => 1,
               isList => 0
              }),

  ];

my $purposeBrief = <<PURPOSEBRIEF;
Update Study::OntologyEntry based on a new release of MGED Ontology loaded into SRes Tables.
PURPOSEBRIEF

my $purpose = <<PLUGIN_PURPOSE;
Update Study::OntologyEntry based on a new release of MGED Ontology loaded into SRes Tables.  It is VERY IMPORTANT to carefully create the nameChangesFile.  Any term which is deprecated and renamed or is a user_defined term and has been upgraded to an official term should be put in this file.  You must go through all the changes in MO since the last version of MO that you have installed.  
PLUGIN_PURPOSE

my $tablesAffected = [['Study.OntologyEntry','Populate the OntologyEntry table']];

my $tablesDependedOn = ['SRes.ExternalDatabase', 'SRes.ExternalDatabaseRelease','SRes.OntologyTerm', 'SRes.OntologyRelationship','Core.TableInfo'];

my $howToRestart = <<PLUGIN_RESTART;
This plugin can not be restarted.
PLUGIN_RESTART

my $failureCases = <<PLUGIN_FAILURE_CASES;
Check the SRes.OntologyTerm and SRes.OntologyRelationship tables, then re run
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
PLUGIN_NOTES

my $documentation = {purposeBrief => $purposeBrief,
		     purpose => $purpose,
		     tablesAffected => $tablesAffected,
		     tablesDependedOn => $tablesDependedOn,
		     howToRestart => $howToRestart,
		     failureCases => $failureCases,
		     notes => $notes
		    };

#-------------------------------------------------------------------------------

my $ontologyTermTableIdSql = <<Sql;
select table_id 
  from CORE.TABLEINFO t, 
  CORE.DATABASEINFO d
  where t.name = 'OntologyTerm' 
  and d.name = 'SRes'
  and t.database_id = d.database_id
Sql

my $ontologyTermChildrenSql = <<Sql;
select s.name
 from SRes.ONTOLOGYRELATIONSHIP r, SRes.ONTOLOGYTERM s, 
      SRes.ONTOLOGYTERM o, SRes.ONTOLOGYRELATIONSHIPTYPE rt
 where rt.name in ('instanceOf','subClassOf')
   and r.subject_term_id = s.ontology_term_id
   and r.object_term_id = o.ontology_term_id
   and rt.ontology_relationship_type_id = r.ontology_relationship_type_id
   and o.external_database_release_id = ?
   and s.external_database_release_id = ?
   and o.name = ?
Sql

my $soExternalDatabaseReleaseSql = <<Sql;
select r.external_database_release_id
from SRes.EXTERNALDATABASERELEASE r, SRes.EXTERNALDATABASE d
where d.external_database_id = r.external_database_id
and d.name = 'SequenceOntology'
Sql

#-------------------------------------------------------------------------------

sub new {
  my ($class) = @_;
  my $self = { names_hash => {},
               deprecated_values => [],
               number_processed => 0,
               seen_ontology_entry => {},};

  bless($self, $class);

  $self->initialize({requiredDbVersion => 3.6,
                     cvsRevision =>  '$Revision$',
                     name => ref($self),
                     argsDeclaration   => $argsDeclaration,
                     documentation     => $documentation
                    });

  return $self;
}

#-------------------------------------------------------------------------------

=head2 Subroutines

=over 4

=cut

sub addDeprecatedValues {
  my $self = shift;

  push(@{$self->{deprecated_values}}, @_);
}

sub getDeprecatedValues {$_[0]->{deprecated_values}}

sub getNamesHash {$_[0]->{names_hash}}

sub getRootNode {$_[0]->{root_node}}
sub setRootNode {$_[0]->{root_node} = $_[1]}

sub getRootParent { $_[0]->{root_parent}}
sub setRootParent { $_[0]->{root_parent} = $_[1]}

sub setRelationshipQueryHandle {$_[0]->{relationship_query_handle} = $_[1]}
sub getRelationshipQueryHandle {$_[0]->{relationship_query_handle}}

sub setExternalDatabaseReleaseId {$_[0]->{external_database_release_id} = $_[1]}
sub getExternalDatabaseReleaseId {$_[0]->{external_database_release_id}}

sub getCount { $_[0]->{number_processed} }
sub addToCount {$_[0]->{number_processed}++ }

sub getSeenOntologyEntry {$_[0]->{seen_ontology_entry}}

sub getOntologyTermTableIdSql {return $ontologyTermTableIdSql}
sub getOntologyTermChildrenSql {return  $ontologyTermChildrenSql}
sub getSoExternalDatabaseReleaseSql {return $soExternalDatabaseReleaseSql}


=item C<hasSeenOntologyEntry>

Returns true is the combination of parent and child have been seen
and adds the name/parentName combination to the hash

=cut

sub hasSeenOntologyEntry {
  my ($self, $name, $parentName) = @_;

  my $parents = $self->getSeenOntologyEntry()->{$name};

  my $hasSeen = $self->isIncluded($parents, $parentName);

  push(@{$self->getSeenOntologyEntry()->{$name}}, $parentName);
  return($hasSeen);

}

=item C<_setOntologyTermTableId>

Retrieve the core.tableInfo table_id for SRes::OntologyTerm and set the instance variable.

=cut

sub setOntologyTermTableId {
  my ($self) = @_;

  my ($tableId) = $self->sqlAsArray( Sql =>  $ontologyTermTableIdSql );

  $self->{ontology_term_table_id} = $tableId;
}

sub getOntologyTermTableId {$_[0]->{ontology_term_table_id}}

=item C<_setOntologyTermTableId>

Retrieve the SequenceOntology ExternalDatabaseReleaseId's 

Will skip even if value and category match.

=cut

sub setSoExternalDatabaseRelease {
  my ($self) = @_;

  my @ids = $self->sqlAsArray( Sql =>  $soExternalDatabaseReleaseSql );

  $self->{so_external_database_release_list} = \@ids;
}

sub getSoExternalDatabaseRelease {$_[0]->{so_external_database_release_list}}

=item C<isIncluded>

Loop through an arrayref and return true if the value is somewhere in the array.

=cut

sub isIncluded {
  my ($self, $ar, $val) = @_;

  foreach(@$ar) {
    return(1) if($_ eq $val);
  }
  return(0);
}

#-------------------------------------------------------------------------------

=item C<run>

Read the config file, use args to set instance variables and load OntologyEntry rows

B<Return type:> C<scalar> 

The message describing the number of inserts and updates performed.

=cut

sub run {
  my ($self) = @_;

  my $coreInserts = $self->getTotalInserts();

  my ($package, $file, $line) = caller;

  unless($package eq "GUS::Community::Plugin::Test::TestLoadOntologyEntryFromMO") {
    $self->setupGlobalInstanceVars();
  }

  # Give it the Root node and let it read the Ontology as a Tree
  my $root = $self->getRootNode();
  my $rootParent = $self->getRootParent();

  $self->processOntologyRelationships($root, $rootParent);

  $self->updateOntologyEntryForDeprecatedTerms();

  my $coreInserts = 0;
  my $insertCount = $self->getTotalInserts() - $coreInserts;
  my $updateCount = $self->getTotalUpdates() || 0;

  my $msg = "Inserted $insertCount and Updated $updateCount for Study::OntologyEntry";

  return($msg);
}

#-------------------------------------------------------------------------------

sub updateOntologyEntryForDeprecatedTerms {
  my ($self) = @_;

  my $deprecatedValues = $self->getDeprecatedValues();

  # Don't use the query handle here because I need stuff that I just submitted
  my $dbh =  $self->getDbHandle();
  my $sh = $dbh->prepare("select distinct category from Study.OntologyEntry where value = ?");

  foreach my $deprecatedValue (@$deprecatedValues) {
    $sh->execute($deprecatedValue);

    while(my ($category) = $sh->fetchrow_array()) {
      my $oe = GUS::Model::Study::OntologyEntry->new({value => $deprecatedValue, category => $category});
      unless($oe->retrieveFromDB()) {
        $self->error("Should have been able to retrieveFromDB OntologyEntry\n" . $oe->toString());
      }

      my $message = "[deprecated_term:  [$deprecatedValue] with category [$category]]";
      $category = "DeprecatedTerms_$category";

      # Only Don't update those with some other ExtDbRelease (like SO for example)!!
      if($oe->getExternalDatabaseReleaseId() == $self->getExternalDatabaseReleaseId()) {
        $self->log($message);
        $oe->setCategory($category);
        $oe->submit();
      }
    }
    $sh->finish();
  }
}

#-------------------------------------------------------------------------------

sub setupGlobalInstanceVars {
  my ($self) = @_;

  $self->setRootNode('MGEDOntology');

  my $thing = GUS::Model::Study::OntologyEntry->new({value => 'thing'});
  $self->setRootParent($thing);

  my $nameChanges = $self->getArg('nameChangesFile');
  $self->setNamesHashFromConfigFile($nameChanges);

  my $dbRlsId = $self->getExtDbRlsId($self->getArg('externalDatabase'),
                                     $self->getArg('externalDatabaseRls'));

  $self->setExternalDatabaseReleaseId($dbRlsId);
  $self->setOntologyTermTableId();
  $self->setSoExternalDatabaseRelease();

  my $dbh = $self->getQueryHandle();
  my $sh = $dbh->prepare($ontologyTermChildrenSql);

  $self->setRelationshipQueryHandle($sh);
}

#-------------------------------------------------------------------------------

=item C<_setNamesHashFromConfigFile>

reads the config file and creates a hash of new names to old names

B<Parameters:>

$fn(scalar): path of the file to be read

B<Return type:> C<undef> 

This hash is stored as an instance variable.  

=cut

sub setNamesHashFromConfigFile {
  my ($self, $fn) = @_;

  return unless($fn);

  open(FILE, $fn) or die "Cannot open file $fn for reading: $!";

  while(my $line = readline(*FILE)) {
    chomp($line);

    my ($prevName, $newName) = split(/\t/, $line);
    $self->getNamesHash()->{$newName} = $prevName;
  }
  return $self->getNamesHash();
}

#-------------------------------------------------------------------------------

=item C<_processOntologyRelationships>

This method does most of the work.  Processes SRes::OntologyTerms as a tree (depth first).  The 
top most node in the MO is "MGEDOntology" which does not have a Study::OntologyEntry parent 
(MGEDOntology's parent is 'thing').  

B<Parameters:>

$name(scalar): string which along with the external_database_release_id will define an SRes::OntologyTerm
$parentOntologyEntry(Study::OntologyEntry): The parent for this OntologyEntry (is null for root node)

B<Return type:> C<undef> 

=cut

sub processOntologyRelationships {
  my ($self, $name, $parentOntologyEntry) = @_;

  print STDERR $name . "|" . $parentOntologyEntry->getValue() . "\n" if($self->getArg('debug'));

  my $term = GUS::Model::SRes::OntologyTerm->
    new({name => $name, external_database_release_id => $self->getExternalDatabaseReleaseId() });

  unless($term->retrieveFromDB()) {
    $self->error("Could not retrieve a record for ontology_term $name");
  }

  my $existingName = $self->getNamesHash()->{$name};

  unless($existingName) {
    $existingName = $name;
  }

  my $parentName = $parentOntologyEntry->getValue();

  my $ontologyEntry = GUS::Model::Study::OntologyEntry->
    new({value => $existingName, category => $parentName});

  if($ontologyEntry->retrieveFromDB() && $existingName ne $name) {
    my $message = "[Updating oe $existingName to $name]";
    $self->log($message);
  }

  $self->loadOntologyEntry($ontologyEntry, $term,  $parentOntologyEntry);

  my $sh = $self->getRelationshipQueryHandle();
  my $bindValues = [$self->getExternalDatabaseReleaseId(),
                    $self->getExternalDatabaseReleaseId(),
                    $term->getName()];

  my @children = $self->sqlAsArray( Handle => $sh, Bind => $bindValues );

  foreach my $kidName (@children) {
    $self->processOntologyRelationships($kidName, $ontologyEntry);
  }
}

#-------------------------------------------------------------------------------

=item C<loadOntologyEntry>

Every ontologyEntry which has a name in MO or is in the config file is updated
unless it is Deprecated in the MO AND is not in the database instance you are
populating.

B<Parameters:>

$ontologyEntry(Study::OntologyEntry): The object to be updated
$term(SRes::OntologyTerm): The OntologyTerm which the OntologyEntry is based
$parentOntologyEntry(Study::OntologyEntry): The direct parent for the main ontologyEntry object

B<Return type:> C<undef> 

=cut

sub loadOntologyEntry {
  my ($self, $ontologyEntry, $term, $parentOntologyEntry) = @_;

  my $value = $term->getName();
  my $definition = $term->getDefinition();
  my $externalDatabaseReleaseId =  $term->getExternalDatabaseReleaseId();
  my $rowId = $term->getId();
  my $sourceId = $term->getSourceId();
  my $uri = $term->getUri();

  my ($parentId, $category) = $self->getParentInfo($parentOntologyEntry);

  # Don't process the same term with the same parent twice
  return 0 if($self->hasSeenOntologyEntry($value, $category));

  # Make a running list of the values of DeprecatedTerms
  if($parentOntologyEntry->getValue eq 'DeprecatedTerms') {
    my $deprecatedValues = $self->getDeprecatedValues();
    $self->addDeprecatedValues($value) unless($self->isIncluded($deprecatedValues, $value));
  }

  # Don't process if the ExternalDatabaseReleaseId is not an MGED one
  if($self->isIncluded($self->getSoExternalDatabaseRelease(), $ontologyEntry->getExternalDatabaseReleaseId())) {
    $self->log("[SKIP $value Invalid ExternalDatabaseRelease]");
    return 0;
  }

  # Don't process if it doesn't exist in the database AND is a deprecated term
  if($parentOntologyEntry->getValue eq 'DeprecatedTerms' && !$ontologyEntry->getId) {
    $self->log("[SKIP $value:  NEW Deprecated Term]");
    return 0;
  }

  my $oeName = $ontologyEntry->getName();

  if($oeName eq 'user_defined') {
    $ontologyEntry->setName('');

    my $newValue = $ontologyEntry->getValue();
    my $message = "[upgraded user_defined oe $value to $newValue]";
    $self->log($message);
  }

  my $tableId = $self->getOntologyTermTableId();

  $ontologyEntry->setValue($value);
  $ontologyEntry->setDefinition($definition);
  $ontologyEntry->setExternalDatabaseReleaseId($externalDatabaseReleaseId);
  $ontologyEntry->setRowId($rowId);
  $ontologyEntry->setTableId($tableId);
  $ontologyEntry->setSourceId($sourceId);
  $ontologyEntry->setUri($uri);
  $ontologyEntry->setCategory($category);
  $ontologyEntry->set('parent_id', $parentId);

  $ontologyEntry->submit();

  my $count = $self->addToCount();
  if($count > 1 && $count % 100 == 0) {
    my $count = $self->getCount();
    $self->log("Processed $count Study::OntologyEntry Rows");
  }

  return 1;
}

#-------------------------------------------------------------------------------

sub getParentInfo {
  my ($self, $parentOntologyEntry) = @_;

  my ($parentId, $category);

  $parentId = $parentOntologyEntry->getId();
  $category = $parentOntologyEntry->getValue();

  return($parentId, $category);
}

#-------------------------------------------------------------------------------


sub undoTables {
  my ($self) = @_;

  return ('Study.OntologyEntry');
}

1;
