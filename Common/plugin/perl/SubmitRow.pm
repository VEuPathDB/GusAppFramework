package GUS::Common::Plugin::SubmitRow;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
use CBIL::Util::Disp;
use GUS::PluginMgr::Plugin;

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  my $purposeBrief = 'Update a row with values supplied as command line arguments.';

  my $purpose = <<PLUGIN_PURPOSE;
This plugin either inserts or updates a row in the database, depending upon whether the you provide a primary key as one of the attributes.  If you do, that row will be read, updated with the attribute values you supply, and written.  Otherwise, a new row will be inserted.
PLUGIN_PURPOSE

  my $tablesAffected = 
    [
    ];

  my $tablesDependedOn =
    [
    ];

  my $howToRestart = <<PLUGIN_RESTART;
This plugin has no restart facility.
PLUGIN_RESTART

  my $failureCases = <<PLUGIN_FAILURE_CASES;
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
This plugin replaces C<GUS::Common::Plugin::UpdateGusFromCla>
PLUGIN_NOTES

  my $documentation = { purpose=>$purpose,
			purposeBrief=>$purposeBrief,
			tablesAffected=>$tablesAffected,
			tablesDependedOn=>$tablesDependedOn,
			howToRestart=>$howToRestart,
			failureCases=>$failureCases,
			notes=>$notes
		      };

  my $argsDeclaration =
  [
   tableNameArg({name  => 'tablename',
		 descr => 'Name of table or view to submit to, eg, Core::UserInfo',
		 reqd  => 1,
		 constraintFunc=> undef,
		 isList=>0,
	   }),
   stringArg({name  => 'attrlist',
	      descr => 'List of attributes to update',
	      reqd  => 1,
	      constraintFunc=> undef,
	      isList=>1,
	   }),
   stringArg({name  => 'valuelist',
	      descr => 'List of values to update (^^^ delimited)',
	      reqd  => 1,
	      constraintFunc=> undef,
	      isList=>0,
	   }),
   booleanArg({name  => 'refresh',
	       descr => 'True to update the row with new modification data and algorithmInvocation regardless of whether it has changed from the database',
	       reqd  => 0,
	       default=> 0,
	     }),
  ];


  $self->initialize({requiredDbVersion => {},
		     cvsRevision => '$Revision$', # cvs fills this in!
		     cvsTag => '$Name$', # cvs fills this in!
		     name => ref($self),
		     revisionNotes => 'make consistent with GUS 3.0',
		     argsDeclaration => $argsDeclaration,
		     documentation => $documentation
		    });
  return $self;
}

sub run {
  my ($self) = @_;
  $self->logAlgInvocationId;
  $self->logCommit;

  $self->{attrHash} = $self->makeAttrHash();

  my $tableName = $self->getArgs->{'tablename'};
  my ($db, $tbl) = split(/::/, $tableName);
  my $className = "GUS::Model::${db}::${tbl}";
  eval "require $className";

  my $row;
  if ($self->getArgs->{refresh}) {
    $row = $self->refreshedRow($className);
    $self->setResultDescr("Refreshed one row");

  } else {
    $row = $className->new($self->{attrHash});
    $self->setResultDescr("Updated one row");
  }

  $row->submit();

  $self->log("Row updated");
}

sub makeAttrHash {
  my ($self) = @_;

  my $attrList = $self->getArgs->{attrlist};
  my @valueList = split(/\^\^\^/, $self->getArgs->{valuelist});

  $self->userError("attrlist and valuelist must have the same number of elements") if (scalar(@$attrList) != scalar(@valueList));

  my %attrHash;
  for (my $i=0; $i<@$attrList; $i++) {
    $valueList[$i]=~ s/^\s+|\s+$//g;
    $attrHash{$attrList->[$i]} = $valueList[$i];
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

1;

