package GUS::Common::Plugin::UpdateRow;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
use CBIL::Util::Disp;

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  my $usage = 'Update a row with values supplied as command line arguments.';

  my $easycsp =
    [{ h => 'if true then update the row with new modification data and algorithmInvocation regardless if has changed from the database',
       t => 'boolean',
       o => 'refresh',
     },
     {	h => 'list of attributes to update (comma delimited)',
	t => 'string',
	r => 1,
	o => 'attrlist',
     },
     {	h => 'list of values to update (^^^ delimited)',
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
  my ($self) = @_;
  $self->logAlgInvocationId;
  $self->logCommit;

  $self->checkArgs();

  $self->{attrHash} = $self->makeAttrHash();

  my $tableName = $self->getArgs->{'tablename'};
  my ($db, $tbl) = split(/::/, $tableName);
  my $className = "GUS::Model::${db}::${tbl}";
  eval "require $className";

  my $row;
  if ($self->getArgs->{refresh}) {
    $row = $self->refreshedRow($className);

  } else {
   $self->logDebug(CBIL::Util::Disp::Display($self->{attrHash}));
   $row = $className->new($self->{attrHash});
  }
  $row->submit();
}

sub makeAttrHash {
  my ($self) = @_;

  my @attrList = split(/,/, $self->getArgs->{attrlist});
  my @valueList = split(/\^\^\^/, $self->getArgs->{valuelist});

  $self->userError("attrlist and valuelist must have the same number of elements") if (scalar(@attrList) != scalar(@valueList));

  my %attrHash;
  for (my $i=0; $i<@attrList; $i++) {
    $valueList[$i]=~ s/^\s+|\s+$//g;
    $attrHash{$attrList[$i]} = $valueList[$i];
  }
  return \%attrHash;
}

sub refreshedRow {
  my ($self, $className) = @_;

  my ($pkName, $pkValue) = $self->getPrimaryKey($className);
  my $row = $className->new({$pkName => $pkValue});
  my $exclude = ['modification_date','row_alg_invocation_id'];
  if (!$row->retrieveFromDB($exclude)){
    $self->error("no row found with primary key $pkName=$pkValue");
  }
  foreach my $attr (keys %{$self->{attrHash}}) {
    next if $attr eq $pkName;
    my $value = $self->{attrHash}->{$attr};
    $value=~ s/^\s+|\s+$//g;
    $row->set($attr, $value);
  }
  return $row;
}

sub getPrimaryKey {
  my ($self, $tableName) = @_;

  my $extent = $self->getDb->getTable($tableName);

  $self->error("Failed to get a handle on db table $tableName") 
    unless $extent;

  # assume single value key
  my $pkName = $extent->getPrimaryKeyAttributes()->[0];

  $self->userError("You must supply the primary key attribute $pkName if using --refresh") unless $self->{attrHash}->{$pkName};

  return ($pkName, $self->{attrHash}->{$pkName});
}

sub checkArgs {
  my ($self) = @_;

  my $tableName = $self->getArgs->{'tablename'};

  $self->userError("--tablename must be in the form: 'schema::table'") unless $tableName =~ /\w+::\w+/;

}

1;

