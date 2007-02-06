package GUS::Community::Plugin::InsertNAFeatureComment;

@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
use GUS::PluginMgr::Plugin;
use DBI;
use GUS::Model::DoTS::NAFeatureComment;


my $purposeBrief = <<PURPOSEBRIEF;
Plugin to insert na feature comments.
PURPOSEBRIEF

my $purpose = <<PLUGIN_PURPOSE;
Plugin to insert NA feature comments into DoTS.NAFeatureComment.
PLUGIN_PURPOSE

my $tablesAffected = [["DoTS.PredictedAAFeature", "Information about the motif will go here."], ["DoTS.AALocation", "The location of the motif will go here."]];
my $tablesDependedOn = [["SRes.ExternalDatabase", "The information about the data source will be found here."], ["SRes.ExternalDatabaseRelease", "The version of the external data source will be found here."]];

my $howToRestart = <<PLUGIN_RESTART;
Simply reexecute the plugin.
PLUGIN_RESTART

my $failureCases = <<PLUGIN_FAILURE_CASES;
None known.
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
This plugin takes a tab delimited file in the form: source_id   comment
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
   fileArg({name => 'inputFile',
	    descr => 'name of file containing gene name [tab] comments',
	    reqd => 1,
	    mustExist => 1,
	    format => 'tab-delimited of the form: gene_identifier   comment',
	    constraintFunc => undef,
	    isList => 0,
	   }),

];

# ----------------------------------------------------------------------
# create and initalize new plugin instance.
sub new {
    my ($class) = @_;
    my $self = {};
    bless($self,$class);

    $self->initialize({requiredDbVersion => 3.5,
		       cvsRevision => '$Revision$', # cvs fills this in!
		       name => ref($self),
		       argsDeclaration => $argsDeclaration,
		       documentation => $documentation
		      });

    return $self;
}


# ----------------------------------------------------------------------
# run method to do the work

sub run {
  my ($self) = @_;
  my $countObjs = 0;
  my $RV;

  my $overheadInsertCount = $self->getSelfInv->getTotalInserts();

  open(FILE, '<'.$self->getArg('inputFile'));

  my $dbh = $self->getQueryHandle();
  my $sth = $dbh->prepare("select na_feature_id from dots.nafeatureimp where source_id=?");

    # process file.
    while (<FILE>) {
	chomp;
	my $fid;
	my ($gene, $comm) = split('\t', $_);

	$sth->execute($gene);

	if (my ($fid) = $sth->fetchrow_array()) {
	  my $naFeatCom = GUS::Model::DoTS::NAFeatureComment->new({
						     'na_feature_id' => $fid,
						     'comment_string' => $comm,
						    });

	$naFeatCom->submit();
	$countObjs++;

	}else{
	  $self->log("invalid gene name: $gene");
	}
      }
    close(FILE);

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


#  $self->logAlert('RESULT', $RV);
  return $RV;
}

1;
