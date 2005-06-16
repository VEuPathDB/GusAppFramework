package GUS::Common::Plugin::UpdateGusFromXML;

@ISA = qw(GUS::PluginMgr::Plugin);
use strict;

use FileHandle;

# ----------------------------------------------------------------------
# create and initalize new plugin instance.

sub new {
  my ($class) = @_;

  my $self = {};
  bless($self, $class);

  my $usage = 'update GUS from an XML file. ("// on newline delimits submits)';

  my $easycsp =
    [
     { h => 'if true then will update the row with new modification data and algorithmInvocation regardless if has changed from the database',
       t => 'boolean',
       o => 'refresh',
     },
     { h => 'name of file containing XML',
       t => 'string',
       d => '-',
       o => 'filename',
     },
    ];

  $self->initialize({requiredDbVersion => {},
		     cvsRevision => '$Revision$', # cvs fills this in!
		     name => ref($self),
		     revisionNotes => 'make consistent with GUS 3.0',
		     easyCspOptions => $easycsp,
		     usage => $usage
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
  my $self   = shift;

  my $RV;

  my $overheadInsertCount = $self->getSelfInv->getTotalInserts();

  my $fh = FileHandle->new('<'.$self->getCla->{'filename'});
  if ($fh) {

    $self->logAlert('COMMIT', $self->getCla->{commit} ? 'ON' : 'OFF' );


    # process XML file.
    my @xml;
    while (<$fh>) {
      if (/^\/\/\s*$/) {	##"//" on a newline defines entry
	$self->process(\@xml) if scalar(@xml) > 1; ##must be at least 3 actually to be valid...
	undef @xml;		##reset for the new one...
      } else {
	push(@xml,$_);
      }
    }
    $self->process(\@xml) if scalar(@xml) > 1; ##must be at least 3 actually to be valid...
    $fh->close;

    # write the parsable output (don't change this!!)
    $self->logData("INSERTED (non-overhead)", $self->getSelfInv->getTotalInserts() - $overheadInsertCount);
    $self->logData("UPDATED (non-overhead)",  $self->getSelfInv->getTotalUpdates() || 0);   

    # create, log, and return result string.
    $RV = join(' ',
	       "processed $countObjs objects, inserted",
	       $self->getSelfInv->getTotalInserts(),
	       'and updated',
	       $self->getSelfInv->getTotalUpdates() || 0,
	      );
  }

  # no file.
  else {
    $RV = join(' ',
	       'a valid --filename <filename> must be on the commandline',
	       $self->getCla->{filename},
	       $!);
  }

#  $self->logAlert('RESULT', $RV);
  return $RV;
}

# ----------------------------------------------------------------------
# do the real work.
sub process {
  my $self    = shift;
  my($xml) = @_;

  $self->getSelfInv->parseXML($xml);
  $self->countChangedObjs($self->getSelfInv);

  ##now submit the sucker...
  ##must first remove invocation parent before submitting immediate children
  $self->getSelfInv->manageTransaction(undef,'begin');
  foreach my $c ($self->getSelfInv->getAllChildren()) {
    $c->removeParent($self->getSelfInv);
    $c->submit(undef,1);
    $c->setParent($self->getSelfInv); ##add back so can see at the end...
  }
  $self->getSelfInv->manageTransaction(undef,'commit');
  if (!$self->getCla->{commit}) {
    $self->logAlert('ERROR', "XML that was not committed to the database\n\n");
    foreach my $c ($self->getSelfInv->getAllChildren()) {
      $self->logAlert('BAD-XML', $c->toXML());
    }
  }
  $self->getSelfInv->removeAllChildren();
  $self->getSelfInv->undefPointerCache();
}

sub countChangedObjs {
  my $self = shift;
  my($par) = @_;

  foreach my $c ($par->getAllChildren()) {
    $self->logAlert('DEBUG',
	    "Checking to see if has changed attributes\n".$c->toXML()) if $self->getCla->{debug};
    $countObjs++;
    $countUpdates++;
    if (!$self->getCla->{refresh} && !$c->hasChangedAttributes()) {
      $self->logAlert('DEBUG','There are no changed attributes') if $self->getCla->{debug};
      $countUpdates--;
    }
    $self->countChangedObjs($c);
  }
}

1;

