package GUS::Community::Plugin::Undo;

# todo:
#  - handle seqVersion more robustly
#  - add logging info
#  - undo

@ISA = qw(GUS::PluginMgr::Plugin);

use strict;

use GUS::PluginMgr::Plugin;

my $purpose = <<PURPOSE;
The Undo plugin is very simple:

  - it takes a plugin name and a list of algorithm_invocation_ids as arguments

  - when it runs, it calls a method on the target plugin:   \$targetPlugin->undo(\$algInvIds, \$dbh)

  - if the target plugin has not defined such a method, Undo will fail.

  - if it has, then that method is responsible for performing the undo.  

  - it also provides a convenient method GUS::Community::Plugin::Undo::deleteFromTable(\$table, \$algInvIds, \$dbh).  This method removes from the specified table all rows with any of the specified algortithm_invocation_ids.


The strategy of an plugin's undo method should be:

  1. call deleteFromTable on every table that it writes rows into (either directly or indirectly)

  2. do so in the proper order, so that children are deleted before parents (otherwise you'll get constraint violations)

  3. some tables will need special processing.  For example, deleting from tables that have links to themselves (eg NAFeature) must either proceed from child to parent (which is tricky), or, if the links are nullable, must have those links deleted first, before the rows are deleted.

This is something of a use-at-your-own-risk plugin.  

The risks are:

  1. you will mistakenly remove an incorrect algorithm_invocation_id, thereby losing valuable data

  2. the undo method in the target plugin could be written incorrectly such that it forgets to delete from some tables.  There is some protection against this because most tables that a plugin writes to are child tables.  It is not possible to forget those because that would cause a constraint violation.  It is only a problem if the Undo forgets to delete from tables that have no parents (or whose parents are also forgotten).

The advantages are:

  1. a correctly written undo() method is much more trustworthy than deleting by hand

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
  ];


sub new {
  my $class = shift;
  my $self = {};
  bless($self, $class);

  $self->initialize({requiredDbVersion => 3.5,
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
  $self->{'algInvocationIds'} = $self->getArg('algInvocationId');
  $self->{'dbh'} = $self->getQueryHandle();
  $self->{'dbh'}->{AutoCommit}=0;

  my $plugin = eval "require $pluginName; $pluginName->new()";

  $self->error("'$pluginName' is not a valid plugin name") unless $plugin;

  $plugin->undo($self->{algInvocationIds}, $self->{dbh});

  if ($self->getArg('commit')) {
    print STDERR "Committing\n";
    $self->{'dbh'}->commit()
      || die "Commit failed: " . $self->{'dbh'}->errstr() . "\n";
  } else {
    print STDERR "Rolling back\n";
    $self->{'dbh'}->rollback()
      || die "Rollback failed: " . $self->{'dbh'}->errstr() . "\n";
  }
}

sub deleteFromTable{
  my ($tableName, $algInvocationIds, $dbh) = @_;

  my $algoInvocIds = join(', ', @{$algInvocationIds});

  my $sql = 
"DELETE FROM $tableName
WHERE row_alg_invocation_id IN ($algoInvocIds)";

  my $rows = $dbh->do($sql) || die "Failed running sql:\n$sql\n";
  $rows = 0 if $rows eq "0E0";
  print STDERR "Deleted $rows rows from $tableName\n";
}


1;
