##
## LoadRow Plugin
## $Id$
##

package GUS::Supported::Plugin::LoadRow;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
use CBIL::Util::Disp;
use GUS::PluginMgr::Plugin;

my $argsDeclaration =
[

 tableNameArg({name           => 'tablename',
	       descr          => 'Name of table or view to submit to, eg, Core::UserInfo',
	       reqd           => 1,
	       constraintFunc => undef,
	       isList         =>0 }),
 
 stringArg({   name           => 'attrlist',
	       descr          => 'List of attributes to update (comma delimited)',
	       reqd           => 1,
	       constraintFunc => undef,
	       isList         => 1 }),
 
 stringArg({   name           => 'valuelist',
	       descr          => 'List of values to update (^^^ delimited)',
	       reqd           => 1,
	       constraintFunc => undef,
	       isList         => 0 }),
];

my $purpose = <<PURPOSE;
This plugin either inserts or updates a row in the database, depending upon
whether the you provide a primary key as one of the attributes.  If you do,
that row will be read, updated with the attribute values you supply, and
written.  Otherwise, a new row will be inserted.
PURPOSE

my $purposeBrief = <<PURPOSE_BRIEF;
Update a row with values supplied as command line arguments.
PURPOSE_BRIEF

my $notes = <<NOTES;
This plugin replaces C<GUS::Community::Plugin::UpdateGusFromCla>
NOTES

my $tablesAffected = <<TABLES_AFFECTED;
TABLES_AFFECTED

my $tablesDependedOn = <<TABLES_DEPENDED_ON;
TABLES_DEPENDED_ON

  my $howToRestart = <<RESTART;
There are no restart facilities for this plugin
RESTART

my $failureCases = <<FAIL_CASES;
FAIL_CASES

my $documentation = { purpose          => $purpose,
		      purposeBrief     => $purposeBrief,
		      notes            => $notes,
		      tablesAffected   => $tablesAffected,
		      tablesDependedOn => $tablesDependedOn,
		      howToRestart     => $howToRestart,
		      failureCases     => $failureCases };

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  $self->initialize({ requiredDbVersion => 4.0,
		      cvsRevision       => '$Revision$',
		      name              => ref($self),
		      argsDeclaration   => $argsDeclaration,
		      documentation     => $documentation});

  return $self;
}

sub run {
  my ($self) = @_;
  $self->logAlgInvocationId;
  $self->logCommit;

  $self->{attrHash} = $self->makeAttrHash();

  my $tableName = $self->getArg('tablename');
  my $className = $self->getFullTableClassName("$tableName");
  $self->userError("'$tableName' is not a valid table name") unless $className;

  my $row;

  my $pkName =  $self->getPrimaryKeyName($className);
  my $pkValue = $self->{attrHash}->{$pkName};

  if ($pkValue) {
    $row = $self->updateRow($pkName, $pkValue, $className);
  } else {
    $row = $self->insertRow($className);
  }

  $row->submit();
  $self->log("Row submitted");
}

sub makeAttrHash {
  my ($self) = @_;

  my $attrList = $self->getArg('attrlist');
  my @valueList = split(/\^\^\^/, $self->getArg('valuelist'));

  $self->userError("attrlist and valuelist must have the same number of elements") if (scalar(@$attrList) != scalar(@valueList));

  my %attrHash;
  for (my $i=0; $i<@$attrList; $i++) {
    $valueList[$i]=~ s/^\s+|\s+$//g;
    $attrHash{$attrList->[$i]} = $valueList[$i];
  }
  return \%attrHash;
}

sub getPrimaryKeyName {
  my ($self, $tableName) = @_;

  my $extent = $self->getDb->getTable($tableName);

  $self->error("Failed to get a handle on db table $tableName") 
    unless $extent;

  # assume single value key
  return $extent->getPrimaryKeyAttributes()->[0];
}

sub updateRow {
  my ($self, $pkName, $pkValue, $className) = @_;

  eval "require $className";
  my $row = $className->new({$pkName => $pkValue});
  if (!$row->retrieveFromDB()) {
    $self->error("Can't update.  No row found with primary key $pkName = $pkValue");
  }
  foreach my $attr (keys %{$self->{attrHash}}) {
    next if $attr eq $pkName;
    $row->set($attr, $self->{attrHash}->{$attr});
  }
  $self->setResultDescr("Updated one row");
  $self->log("Updating one row");
  return $row;
}

sub insertRow {
  my ($self, $className) = @_;

  eval "require $className";
  my $row = $className->new($self->{attrHash});
  $self->setResultDescr("Inserted one row");
  $self->log("Inserting one row");
  return $row;
}

1;

