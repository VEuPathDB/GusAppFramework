package GUS::ObjRelP::DbiDbHandle;
use strict;
use DBI;
use vars qw(@ISA $verbose $noInsert $exitOnFailure);
@ISA = qw( DBI::db DBI );
my ($NO_EMPTY_STRINGS);

$| = 1;

sub new{
  my($class, $dsn, $user, $password, $verbose, $noInsert, $autoCommit) = @_;
  #  my $self = {};
  #  my $self = $class->connect($dsn, $user, $password, 
  #                          {AutoCommit=>$autoCommit, RaiseError=>1});
  my $self = $class->connect($dsn, $user, $password, 
                             {AutoCommit=>$autoCommit});
  bless $self, $class;
  $self->setVerbose($verbose);
  $self->setNoInsert($noInsert);
  $self->{rollBack} = 0;
  return $self;
}

sub setVerbose{
	my ($self, $v) = @_;
	if (defined $v){$verbose = $v;}
}

sub getVerbose{
	my ($self) = @_; 	
  return $verbose;
}

sub setNoInsert{
	my ($self, $noIns) = @_;
	if (defined $noIns){$noInsert = $noIns;}
}

sub getNoInsert{ 
	my ($self) = @_;
	return $noInsert;
}
sub setNoEmptyStrings { shift; my($bool)=@_; $NO_EMPTY_STRINGS = $bool; }
sub getNoEmptyStrings {return $NO_EMPTY_STRINGS;}

sub setRollBack { my($self,$rb) = @_; $self->{rollBack} = $rb; }
sub getRollBack { my $self = shift; return $self->{rollBack}; }

sub getTransactionStatus {
  my($self) = @_;
  return $self->getRollBack() ? 0 : 1;
}

##default is 1;
$exitOnFailure = 1;
sub setExitOnFailure{
	my ($self, $exitFlag) = @_;
	if (defined $exitFlag){$exitOnFailure = $exitFlag;}
}

sub getExitOnFailure{
	my ($self) = @_;
	return $exitOnFailure;
}

#add error checking here.
sub prepareAndExecute {
	my ($self, $sql_cmd) = @_;
  if ($verbose) { print STDERR"\n\nprepareAndExecute: $sql_cmd \n"; }
	my $sth = $self->prepare($sql_cmd) || print STDERR "prepareAndExecute FAILED: $self->errstr\n";
	$sth->execute() || print STDERR "prepareAndExecute FAILED: $sth->errstr \n";
  return $sth;
}

sub sqlexec {
  my ($dbh, $sql_cmd) = @_; ## $dbh is $self
  if (!$dbh) { die "\n NO DBH for $sql_cmd \n"; }
  if ($verbose) { print STDERR"\n\nsqlexec: $sql_cmd \n"; }
	 if(!($dbh->do($sql_cmd))){ 
           if ($exitOnFailure) { $dbh->rollback; exit(1); } else {$dbh->setRollBack(1); return 0;}
	}
  return 1; # succeeded!
}

#assumes at least one row should be inserted, throws errow if not.
#returns the number of rows affected/inserted.
sub sqlexecIns {
  my ($dbh, $sql_cmd,$longValues) = @_;
	my $row_count = 0;
  if ($verbose) { print STDERR"\n\nsqlexecIns: \n $sql_cmd \n"; print STDERR "LongValues (",join(', ',@$longValues),")\n" if $longValues;}
  if ($noInsert) {
	  print STDERR "\n DbiDbHandle:do\nSET NOEXEC ON \n";
    $dbh->do("SET NOEXEC ON"); 
    if ($verbose) { print STDERR "TESTRUN - INSERT/UPDATE NOT EXECUTED \n"; }
  }
  if($longValues){
    my $stmt = $dbh->prepare($sql_cmd);
    if($stmt->execute(@$longValues)){
      $row_count = 1;  ##not true but will throw error if not successful and objects only do one row!!
    }else{
      print STDERR "\n DbiDbHandle:sqlexecIns: SQL ERROR!! involving\n $sql_cmd \n longValues (",join(', ', @$longValues),")\n";
      if ($exitOnFailure) { $dbh->rollback; exit(1); } else {$dbh->setRollBack(1); return 0;}
    }

  }else{
    if(!($row_count = $dbh->do($sql_cmd))){
      print STDERR "\n DbiDbHandle:sqlexecIns: SQL ERROR!! involving\n $sql_cmd \n";
      if ($exitOnFailure) { $dbh->rollback; exit(1); } else {$dbh->setRollBack(1); return 0;}
    }
  }
	if ($verbose) {print STDERR "rowcount:" . $row_count ."\n";}
	if ($row_count > 0) {
		if ($verbose) { print STDERR " DbiHandle:sqlexecIns:insert succeeded $row_count row(s)\n";}
	} else {
		print STDERR " DbiHandle:sqlexecIns:insert failed on  \n $sql_cmd \n no rows inserted\n";		
	}
  if ($noInsert) {
    $dbh->do("SET NOEXEC OFF");  ##SJD - Check same for ORACLE!
    if ($verbose) { print STDERR "Turning execution back on. \n"; }
  }
  return $row_count; # return number of rows inserted.
}

##new exec method...takes in statement..is here only to take advantage of $verbose, $exitOnFailure
sub sqlExec {
  my($dbh,$stmt,$values,$sql_cmd) = @_;
#  if ($verbose) { print STDERR"\n\nsqlExec: $sql_cmd \n  bindValues (",join(', ',@$values),")\n";}
  if ($verbose) { print STDERR"\n\nsqlExec: $stmt->{Statement}\n  bindValues (",join(', ',@$values),")\n";}
  if ($noInsert) {
	  print STDERR "\n DbiDbHandle:do\nSET NOEXEC ON \n";
    $dbh->do("SET NOEXEC ON"); 
    if ($verbose) { print STDERR "TESTRUN - INSERT/UPDATE NOT EXECUTED \n"; }
  }
  if($stmt->execute(@$values)){
    if ($verbose) { print STDERR " DbiHandle:sqlExec:insert succeeded 1 row(s)\n";}
  }else{
    print STDERR "\n DbiDbHandle:sqlExec: SQL ERROR!! involving\n $stmt->{Statement}\n bindValues (",join(', ', @$values),")\n";
    if ($exitOnFailure) { $dbh->rollback; exit(1); } else {$dbh->setRollBack(1); return 0;}
  }

  if ($noInsert) {
    $dbh->do("SET NOEXEC OFF");  ##SJD - Check same for ORACLE!
    if ($verbose) { print STDERR "Turning execution back on. \n"; }
  }
  return 1; 
}

#SJD begin_tran and commit_tran are for use with Sybase only. 
#Oracle will only use commit, a DBI method. NOTE that if using
#Sybase will need to change commit to commit_tran.  Should 
#really just handle all this here, so can have consistent 
#code - only need to know here where sybase or oracle. Add to to
#do list!
sub begin_tran { 
  my ($dbh) = @_; 
  $dbh->do("BEGIN TRAN"); 
}

sub commit_tran { 
my ($dbh) = @_; 
$dbh->do("COMMIT TRAN");
} 

sub rollback_tran { 
my ($dbh) = @_; 
$dbh->do("ROLLBACK TRAN");
}

sub free{
	my $self = shift;
	$self->disconnect();

} 

1;
