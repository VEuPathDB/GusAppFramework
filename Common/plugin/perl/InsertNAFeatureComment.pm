package GUS::Common::Plugin::InsertNAFeatureComment;

@ISA = qw(GUS::PluginMgr::Plugin);
use strict;
use DBI;
use FileHandle;
use GUS::Model::DoTS::NAFeatureComment;
# ----------------------------------------------------------------------
# create and initalize new plugin instance.

sub new {
  my ($class) = @_;

  my $self = {};
  bless($self, $class);

  my $usage = 'insert comment to DoTS::NAFeatureComment';

  my $easycsp =
    [
     { h => 'name of file containing gene name [tab] comments',
       t => 'string',
       d => '-',
       o => 'filename',
     },
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
  
  my $dbh = $self->getQueryHandle();
  my $sth = $dbh->prepare("select na_feature_id from dots.nafeatureimp where source_id=?");

  if ($fh) {
    $self->logAlert('COMMIT', $self->getCla->{commit} ? 'ON' : 'OFF' );

    # process file.    
    while (<$fh>) {
	chomp;
	my $fid;
	my ($gene, $comm) = split('\t', $_);
	$sth->execute($gene);
	if(my ($id) = $sth->fetchrow_array()) {
	    $fid = $id;
	}else {
	    print STDERR "invalid gene name: $gene\n";
	}
	my $c = GUS::Model::DoTS::NAFeatureComment->new();
	$c->set('na_feature_id',$fid);
	$c->set('comment',$comm);
	$c->submit();
    }
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

1;
