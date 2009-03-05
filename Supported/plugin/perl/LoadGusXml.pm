##
## LoadGusXml Plugin
## $Id$
##

package GUS::Supported::Plugin::LoadGusXml;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
use FileHandle;
use GUS::PluginMgr::Plugin;

my $argsDeclaration =
  [
booleanArg({ name           => 'refresh',
	     descr          => 'If true, update row (algorithm invocation, modification date) regardless of whether changes have occured.',
	     constraintFunc => undef,
	     reqd           => 0,
	     isList         => 0 }),

   fileArg({name           => 'filename',
	    descr          => 'Name of XML file to insert',
	    constraintFunc => undef,
	    reqd           => 1,
	    isList         => 0,
	    format         => 'Simple GUS XML Format.  See the notes.',
	    mustExist      => 1 }),

   stringArg({name => 'tableName',
	      descr => 'name of the table for inserts, used for undo, schema.table format, e.g. dots.nasequence',
	      reqd => 0,
	      constraintFunc => undef,
	      isList => 0,
	     })

  ];



my $purpose = <<PURPOSE;
Insert data in from a simple GUS XML format into GUS.
PURPOSE

my $purposeBrief = <<PURPOSE_BRIEF;
Insert data in from a simple GUS XML format into GUS
PURPOSE_BRIEF

my $notes = <<EOF;
The XML format is:
<Schema::table>
  <column>value</column>
  ...
</Schema::table>
  ...
Each major tag represents a table and nested within it are elements for column values. The file introduces a special non-xml syntax to delimit a submit (and a transaction).  A line beginning with "//" indicates that the objects created since the last submit (and commit) should be submitted and committed.
EOF

my $tablesAffected = <<EOF;
EOF

my $tablesDependedOn = <<EOF;
EOF

my $howToRestart = <<EOF;
There are no restart facilities for this plugin, can undo, must provide tableName for undo
EOF

my $failureCases = <<EOF;
EOF

my $documentation = { purpose          => $purpose,
		      purposeBrief     => $purposeBrief,
		      notes            => $notes,
		      tablesAffected   => $tablesAffected,
		      tablesDependedOn => $tablesDependedOn,
		      howToRestart     => $howToRestart,
		      failureCases     => $failureCases };
sub new {
  my ($class) = @_;
  my $self    = {};
  bless($self, $class);

  $self->initialize({
      requiredDbVersion => 3.5,
      cvsRevision       => '$Revision$',            # Completed by CVS
      name              => ref($self),
      argsDeclaration   => $argsDeclaration,
      documentation     => $documentation
      });

  return $self;
}

# ----------------------------------------------------------------------
# plugin-global variables.

my $countObjs = 0;
my $countUpdates = 0;

# ----------------------------------------------------------------------
# run method to do the work

sub run {
  my $self = shift;

  my $RV;

  my $overheadInsertCount = $self->getTotalInserts();

  open(XMLFILE, $self->getArg('filename')) 
    || die "can't open file " .$self->getArg('filename') ;

  my @xml;
  while (<XMLFILE>) {
    if (/^\/\/\s*$/) {	##"//" on a newline defines entry
      $self->process(\@xml) if scalar(@xml) > 1; ##must be at least 3 actually to be valid...
      undef @xml;		##reset for the new one...
    } else {
      push(@xml,$_);
    }
  }
  close(XMLFILE);

  $self->process(\@xml) if scalar(@xml) > 1; ##must be at least 3 actually to be valid...

  # write the parsable output (don't change this!!)
  $self->logData("INSERTED (non-overhead)", $self->getTotalInserts() - $overheadInsertCount);
  $self->logData("UPDATED (non-overhead)",  $self->getTotalUpdates() || 0);   

  # create, log, and return result string.
  $RV = join(' ',
	     "processed $countObjs objects, inserted",
	     $self->getTotalInserts(),
	     'and updated',
	     $self->getTotalUpdates() || 0,
	    );

  return $RV;
}

# ----------------------------------------------------------------------
# do the real work.
sub process {
  my $self    = shift;
  my($xml) = @_;

  $self->getAlgInvocation()->parseXML($xml);
  $self->countChangedObjs($self->getAlgInvocation());

  ##now submit the sucker...
  ##must first remove invocation parent before submitting immediate children
  $self->getAlgInvocation()->manageTransaction(undef,'begin');
  foreach my $c ($self->getAlgInvocation()->getAllChildren()) {
    $c->removeParent($self->getAlgInvocation());
    $c->submit(undef,1);
    $c->setParent($self->getAlgInvocation()); ##add back so can see at the end...
  }
  $self->getAlgInvocation()->manageTransaction(undef,'commit');
  if (!$self->getArg('commit')) {
    $self->logVerbose("XML that was not committed to the database\n\n");
    foreach my $c ($self->getAlgInvocation()->getAllChildren()) {
      $self->logVerbose($c->toXML());
    }
  }
  $self->getAlgInvocation()->removeAllChildren();
  $self->getAlgInvocation()->undefPointerCache();
}

sub countChangedObjs {
  my $self = shift;
  my($par) = @_;

  foreach my $c ($par->getAllChildren()) {
    $self->logDebug('DEBUG',
	    "Checking to see if has changed attributes\n".$c->toXML()) if $self->getArg('debug');
    $countObjs++;
    $countUpdates++;
    if (!$self->getArg('refresh') && !$c->hasChangedAttributes()) {
      $self->logDebug('DEBUG','There are no changed attributes') if $self->getArg->('debug');
      $countUpdates--;
    }
    $self->countChangedObjs($c);
  }
}

sub undoTables {
  my ($self) = @_;
  return if (!$self->getArg('tableName'));
  my $table = $self->getArg('tableName');
  return ($table);
}

1;

