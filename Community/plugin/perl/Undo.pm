package GUS::Community::Plugin::Undo;

@ISA = qw(GUS::PluginMgr::Plugin);

use strict;

use GUS::PluginMgr::Plugin;


my $purpose = <<PURPOSE;
The Undo plugin is very simple:

  - it takes a plugin name and a list of algorithm_invocation_ids as arguments

  - when it runs, it calls a method on the target plugin:
    \$targetPlugin->undoTables()

  - if the target plugin has not defined such a method, Undo will fail.

  - if it has, then that method returns a list of tables to undo from.
    Undo will remove from each of those tables any rows whose
    row_alg_invocation_id is in the list supplied on the command line.
    The order of the tables in the list returned by undoTables() must
    be such that child tables come before parent tables.  Otherwise
    you will get constraint violations.

  - Undo also deletes from AlgorithmParam and AlgorithmInvocation.

  - all deletes are performed as part of one transaction.  The deletes
    are only committed if Undo is run with --commit

  - Undo does *not* write to the version tables.

This is something of a use-at-your-own-risk plugin.  

The risks are:

  1. you will mistakenly undo an incorrect algorithm_invocation_id,
     thereby losing valuable data

  2. the undoTables() method in the target plugin could be written
     incorrectly such that it forgets some tables.  There is some
     protection against this because most tables that a plugin writes
     to are child tables.  It is not possible to forget those because
     that would cause a constraint violation.  It is only a problem if
     the Undo forgets to delete from tables that have no parents (or
     whose parents are also forgotten).

  3. the data you are deleting is not versioned, and so is not recoverable.

  4. it is possible that the list of tables supplied by undoTables()
     is true for the current version of the plugin, but not for the
     version that was run when the data was loaded (ie, the plugin has
     changed since).

The advantages are:

  1. a correctly written undoTables() method is much more trustworthy
     than deleting by hand

  2. undoing becomes doable
PURPOSE

my $purposeBrief = <<PURPOSEBRIEF;
Undo one or more runs of a specified plugin.
PURPOSEBRIEF

my $notes = <<NOTES;

NOTES

my $tablesAffected = [];

my $tablesDependedOn = [];

my $howToRestart = <<RESTART;
No restart
RESTART

my $failureCases = <<FAIL;
FAIL

my $documentation = { purpose=>$purpose, 
                      purposeBrief=>$purposeBrief,
                      tablesAffected=>$tablesAffected,
                      tablesDependedOn=>$tablesDependedOn,
                      howToRestart=>$howToRestart,
                      failureCases=>$failureCases,
                      notes=>$notes
                    };

my $argsDeclaration  =
[

 stringArg({name => 'plugin',
            descr => 'The name of the plugin that loaded the data to be undone',
            constraintFunc=> undef,
            reqd  => 1,
            isList => 0,
           }),

 stringArg({name => 'algInvocationId',
            descr => 'A comma delimited list of algorithm invocation ids to undo',
            constraintFunc=> undef,
            reqd  => 1,
            isList => 1,
           }),

 booleanArg({name  => 'workflowContext',
	     descr => 'The plugin was run by a workflow, so rows in WorkflowStepAlgInvocation must be deleted.',
	     reqd  => 0,
	     default=> 0,
	    }),

 stringArg({name => 'undoTables',
            descr => 'A comma delimited list of table names to undo, schema.table format, e.g. dots.nasequence.',
            constraintFunc=> undef,
            reqd  => 0,
            isList => 0,
           }),

];



sub new {
   my $class = shift;
   my $self = {};
   bless($self, $class);

   $self->initialize({requiredDbVersion => 4.0,
                      cvsRevision => '$Revision$',
                      name => ref($self),
                      argsDeclaration => $argsDeclaration,
                      documentation => $documentation
                     });

   return $self;
}

sub run{
   my ($self) = @_;

   my $pluginName = $self->getArg('plugin');
   my $workflowContext = $self->getArg('workflowContext');
   $self->{'algInvocationIds'} = $self->getArg('algInvocationId');
   $self->{'dbh'} = $self->getQueryHandle();
   $self->{'dbh'}->{AutoCommit}=0;
   $self->{'commit'} = $self->getArg('commit');

   my $plugin = eval "require $pluginName; $pluginName->new()";

   $self->error("Failed trying to create new plugin '$pluginName' with error '$@'") unless $plugin;
   my @tables;

   if ($self->getArg('undoTables'))
   {
       @tables = split (/,/,$self->getArg('undoTables'));

   }else{
       @tables = $plugin->undoTables();
   }


   foreach my $table (@tables) {

      $self->deleteFromTable($table,'row_alg_invocation_id');
   }

   if ($workflowContext) {
     $self->deleteFromTable('ApiDB.WorkflowStepAlgInvocation', 'algorithm_invocation_id');
   }

   $self->deleteFromTable('Core.AlgorithmParam', 'row_alg_invocation_id');

   $self->deleteFromTable('Core.AlgorithmInvocation', 'row_alg_invocation_id');

}

sub deleteFromTable{
   my ($self, $tableName, $algInvIdColumnName) = @_;

   my $algoInvocIds = join(', ', @{$self->{algInvocationIds}});
   my $rows = 1;
   while ($rows) {
     my $sql =
       "SELECT COUNT(*) FROM $tableName
       WHERE $algInvIdColumnName IN ($algoInvocIds)";
     my $stmt = $self->{dbh}->prepareAndExecute($sql);
     
     
     if(($rows) = $stmt->fetchrow_array()){
       if ($self->{commit} == 1) {
	 my $sql = 
	   "DELETE FROM $tableName
            WHERE $algInvIdColumnName IN ($algoInvocIds) and rownum<=10000";
	 warn "\n$sql\n" if $self->getArg('verbose');       
	 if($rows > 0){
	   $self->{dbh}->do($sql) || die "Failed running sql:\n$sql\n";
	   my $numDeleted = $rows>10000 ? 10000 : $rows;
	   $self->log("Deleted $rows rows from $tableName");              
         
	   $self->{dbh}->commit()
	     || die "Committing deletions from $tableName failed: " . $self->{dbh}->errstr() . "\n";
	   $self->log("Committed deletions from $tableName");
	 }
	 else{
	   $self->log("Deleted 0 rows from $tableName");
	 }
       }
       else{
         $self->log("Plugin will attempt to delete $rows rows from $tableName when run in commit mode\n");
       }
     }
   }
}


1;
