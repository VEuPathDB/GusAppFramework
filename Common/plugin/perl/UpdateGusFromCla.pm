package GUS::Common::Plugin::UpdateGusFromCla;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict;

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  my $usage = 'parse a list of command line arguments and updates GUS: "// on newline delimits submits';

  my $easycsp =
    [{ h => 'if true then will update the row with new modification data and algorithmInvocation regardless if has changed from the database',
       t => 'boolean',
       o => 'refresh',
     },
     {	h => 'name of argument containing list of attribute',
	t => 'string',
	r => 1,
	o => 'attrlist',
     },
     {	h => 'name of argument containing list of values',
	t => 'string',
	r => 1,
	o => 'valuelist',
     },
     {	h => 'name of table or view',
	t => 'string',
	r => 1,
	o => 'tablename',
     }];

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
  my $M   = shift;
  $M->logRAIID;
  $M->logArgs;
  $M->logCommit;
  my @attributesToNotRetrieve = ('modification_date', 'row_alg_invocation_id');
  my $RV;

  my $object = $M->getCla->{'tablename'};
  my @attrList=split(/,/, $M->getCla->{attrlist});
  my @valueList=split(/\^\^\^/, $M->getCla->{valuelist});
  #    print "$attrList[0]\n$attrList[1]\n$attrList[2]\n$valueList[0]\n$valueList[1]\n$valueList[2]\n$valueList[3]\n$valueList[4]\n$valueList[5]\n";
  #    return;
  my ($db, $class)=split(/::/, $object);
  my $className = "GUS::Model::$db::$object";
  eval "require $className";
  if ($M->getCla->{refresh}) {
    my $key = $M->getPKName($object);
    my ($pk) = @$key;
 
    if (grep(/^$pk$/, @attrList) ) {
      for (my $i=0; $i<@attrList; $i++) {
	if ($attrList[$i] eq $pk ) {
	  my $attrHash;
	  $valueList[$i]=~ s/^\s+|\s+$//g;
	  $attrHash->{$attrList[$i]} = $valueList[$i];	   
	  my $o=$className->new($attrHash);
	  if ($o->retrieveFromDB(\@attributesToNotRetrieve)) {
	   
	    $RV = "primary key is found in database, doing update";
	    $M->log("Result", $RV);
	    for (my $j=0; $j<@attrList; $j++) {
	      next if($attrList[$j] eq $pk);
	      print "$attrList[$j]\t $valueList[$j]\n";
	      $valueList[$j]=~ s/^\s+|\s+$//g;
	      $o->set("$attrList[$j]", $valueList[$j]);
	      #    $o->setName('test3');
	      #    print $o->toString;
	    }

	    return;
	  } else {
	    $RV = "value provided for primary key is not found in database";
	    $M->log("Error", $RV);
	    return;
	  }
	}
      }
    } else {
      $RV = "primary key must be provided on command line, if refresh is set";
      $M->log("Error", $RV);
      return;
    }
  } else {
    my $attrHash;
    for (my $i=0; $i<@attrList; $i++) {
      $valueList[$i]=~ s/^\s+|\s+$//g;
      $attrHash->{$attrList[$i]} = $valueList[$i];
    }
    my $o=$className->new($attrHash);
    $o->submit();
    my $id=$o->getId();
    print "Id\t$id\n";
  }
}

sub getPKName{
  my $M = shift;
  my ($table_name) = @_;
  $M->setOk(1);
  my $RV;
  # get the database handle
  my $extent=$M->getDb->getTable($table_name);
  if (not defined($extent)) {
    $M->setOk(0);
    $RV = join(' ','Cannot get the database handle', $table_name);
    $M->log('Result', $RV);
    return;
  }
  # retrive attribute infor for the table
  my $primarykey=$extent->getPrimaryKeyAttributes();
  return $primarykey;
}


1;

