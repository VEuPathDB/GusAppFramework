package GUS::Community::Plugin::Undo;

# todo:
#  - handle seqVersion more robustly
#  - add logging info
#  - undo

@ISA = qw(GUS::PluginMgr::Plugin);

use strict;

use GUS::PluginMgr::Plugin;

my $purpose = <<PURPOSE;
Undo one or more runs of GUS::Supported::Plugin::InsertSequenceFeatures.  Uses the algorithm_invocation_id to find the data to remove (find this the log of the plugin run).

If the ISF plugin mapping file uses special case handlers, their undoAll() method is called as part of the undo process.   They are called in the order the handlers are declared in the mapping file.
PURPOSE

  my $purposeBrief = <<PURPOSEBRIEF;
Undo one or more runs of GUS::Supported::Plugin::InsertSequenceFeatures.
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
	      isList => 1,
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
		     cvsRevision => '$Revision: 3872 $',
		     name => ref($self),
		     argsDeclaration => $argsDeclaration,
		     documentation => $documentation
		    });

  return $self;
}

sub run{
  my ($self) = @_;

  my $pluginName = $self->getArg('pluginName');
  $self->{'algInvocationIds'} = $self->getArg('algInvocationId');
  $self->{'dbh'} = $self->getQueryHandle();
  $self->{'dbh'}->{AutoCommit}=0;

  my $plugin = eval "require $pluginName; $pluginName->new()";

  $plugin->undoAll($self->{algInvocationIds}, $self->{dbh});

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
