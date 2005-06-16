package GUS::Community::Plugin::DeleteFromTable;

@ISA = qw(GUS::PluginMgr::Plugin);

use strict;



$| = 1;

sub new {
  my $class = shift;
  my $self = bless {}, $class;

  my $usage = 'Plug_in to delete rows from given table and its children';

  my $easycsp =
    [{o => 'testnumber',
      t => 'int',
      h => 'number of iterations for testing',
     },
     {o => 'idSQL',
      t => 'string',
      h => 'query used to get ids of rows to delete',
     },
     {o => 'table',
      t => 'string',
      h => 'table from which to delete, in standarg form e.g. DoTS::ExternalNASequence ',
     },
     {o => 'delete_children',
      t => 'boolean',
      h => 'explicit option to delete children, used as a safeguard',
     },
     {o => 'doNotVersion',
      t => 'boolean',
      h => 'option to avoid versioning'
     }
     ];

 $self->initialize({requiredDbVersion => {},
                  cvsRevision => '$Revision$', # cvs fills this in!
                  cvsTag => '$Name$', # cvs fills this in!
                  name => ref($self),
                  revisionNotes => 'make consistent with GUS 3.0',
                  easyCspOptions => $easycsp,
                  usage => $usage
                 });
  return $self;
}

sub run {
  my $self  = shift;
  $self->getArgs()->{'commit'} ? $self->log("***COMMIT ON***\n") : $self->log("**COMMIT TURNED OFF**\n");
  $self->log("Testing on " . $self->getArgs()->{'testnumber'}) if $self->getArgs()->{'testnumber'};

  die "Supply sql and table\n" unless ($self->getArgs()->{'table'} && $self->getArgs()->{'idSQL'});

  my $ids = $self->getIdsToDelete();
  my $results = $self->deleteRows($ids);
  return $results;

}


sub getIdsToDelete { 
  my ($self) = @_;

  my @ids;
  $self->log("Getting ids to delete");

  my $dbh = $self->getDb()->getDbHandle();
  my $sql = ($self->getArgs()->{'idSQL'});

  $sql .= " and rownum < " .$self->getArgs()->{'testnumber'} if ($self->getArgs()->{'testnumber'} && $sql =~ /where/);
  $sql .= " where rownum < " .$self->getArgs()->{'testnumber'} if ($self->getArgs()->{'testnumber'} && $sql !~ /where/);


  my $stmt = $dbh->prepareAndExecute($sql) || die "SQL failed: $sql\n";

  while (my ($id) = $stmt->fetchrow_array()) {
    push (@ids, $id);
  }

  $stmt->finish;

  my $num =  @ids;
  $self->log("Got $num ids to delete\n using: $sql\n");

  return \@ids;
}

sub deleteRows {
  my ($self, $ids) = @_;
  my $table = $self->getArgs()->{'table'};
  eval("require GUS::Model::".$table);
  my $numDelete = 0;
  my $algInv = $self->getAlgInvocation();
  my $prim_key = $algInv->getTablePKFromTableId($algInv->getTableIdFromTableName($self->getArgs()->{'table'}));
  $algInv->setMaximumNumberOfObjects(500000);
  $algInv->setGlobalNoVersion(1) if $self->getArgs()->{'doNotVersion'};
  $table = "GUS::Model::".$table;

  foreach my $id (@$ids) {
    my $newTable = $table->new ({$prim_key=>$id});
    $newTable->retrieveFromDB();
    $newTable->retrieveAllChildrenFromDB(1) if ($self->getArgs()->{'delete_children'});
    if ($self->getArgs()->{'delete_children'}) {
      $newTable->markDeleted(1);
    }
    else {
      $newTable->markDeleted(1);
    }
    my $n = $newTable->submit();
    $newTable->undefPointerCache();
    $numDelete++ if $n >= 1;
  }
  my $results = "Number of rows deleted from $table : $numDelete\n";
  return $results;
}

1;
__END__
