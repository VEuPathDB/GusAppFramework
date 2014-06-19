##
## DumpGoPredecessorsOrDescendants Plugin
## $Id: $
##

package GUS::Community::Plugin::Report::DumpGoPredecessorsOrDescendants;
@ISA = qw( GUS::PluginMgr::Plugin );

use strict;
use IO::File;
use GUS::PluginMgr::Plugin;

# ----------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------

sub getArgumentsDeclaration {
  my $argumentDeclaration =
    [
     stringArg({name  => 'goExternalDatabaseSpec',
		descr => 'The name|version of the GO external database release to use',
		constraintFunc=> undef,
		reqd  => 1,
		isList => 0
	       }),
     stringArg({name  => 'mode',
		descr => 'Specify whether to retrieve predecessors (p) or descendants (d).',
		reqd  => 1,
		constraintFunc => undef,
		isList => 0,
	       }),
    ];
  return $argumentDeclaration;
}

# ----------------------------------------------------------------------
# Documentation
# ----------------------------------------------------------------------
sub getDocumentation {
  my $purposeBrief = "Dumps a file with 3 columns: GO_ID, NAME, Predecessors/Descendants IDs, Predecessors/Descendants Names.";

  my $purpose = "For each GO ID in the specified external database release this plugin retrieves its name and all predecessors or descendants according to what is specified in the --mode argument. For each GO ID its name is displayed together with a comma-separated list of its predecessors/descendants GO IDs and a comma-separated list of its predecessors/descendants names.";

  my $tablesAffected = [];
  my $tablesDependedOn = [['SRes::ExternalDatabaseRelease', 'The database releases of GO to be used'], ['SRes::ExternalDatabase', 'The GO databases to which the release refers'], ['SRes::GoTerm', 'The GO terms whose predecessors or descendants are being retrieved'], ['SRes::GoRelationship', 'The GO relationships used to retrieve predecessors or descendants']];
  my $howToRestart = "No restart option.";
  my $failureCases = "";
  my $notes = "";

  my $documentation = {purpose=>$purpose, purposeBrief=>$purposeBrief, tablesAffected=>$tablesAffected, tablesDependedOn=>$tablesDependedOn, howToRestart=>$howToRestart, failureCases=>$failureCases, notes=>$notes};

  return $documentation;
}

# ----------------------------------------------------------------------
# create and initalize new plugin instance.
# ----------------------------------------------------------------------

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  my $documentation = &getDocumentation();
  my $argumentDeclaration    = &getArgumentsDeclaration();

  $self->initialize({requiredDbVersion => 3.6,
		     cvsRevision => '$Revision: $',
		     name => ref($self),
		     revisionNotes => '',
		     argsDeclaration => $argumentDeclaration,
		     documentation => $documentation
		    });
  return $self;
}

# ----------------------------------------------------------------------
# run method to do the work
# ----------------------------------------------------------------------

sub run {
  my ($self) = @_;
  $self->logArgs();
  
  my $extDbRelId = $self->getExtDbRlsId($self->getArg('goExternalDatabaseSpec'));
  $self->logDebug("ExtDbRelId: $extDbRelId");
  my $dbh = $self->getQueryHandle();
  my $goTerms = $self->getGoTerms($dbh, $extDbRelId);
  my $query;
  my $mode = $self->getArg('mode');
  if ($mode eq 'p') {
    $query = "select go_id, name from SRes.GoTerm where go_term_id in (select distinct parent_term_id from sres.gorelationship connect by prior parent_term_id = child_term_id start with child_term_id=?) and external_database_release_id=$extDbRelId";
    STDOUT->print("GO_ID\tName\tPredecessors_IDs\tPredecessors_Names\n");
  }
  elsif ($mode eq 'd') {
    $query = "select go_id, name from SRes.GoTerm where go_term_id in (select distinct child_term_id from sres.gorelationship connect by prior child_term_id = parent_term_id start with parent_term_id=?) and external_database_release_id=$extDbRelId";
    STDOUT->print("GO_ID\tName\tDescendants_IDs\tDescendants_Names\n");
  }
  else {
    die("The --mode argument must be one of 'p' or 'd'.");
  }
  my $sth = $dbh->prepare($query);
  $self->printDump($goTerms, $sth);
  return("Dumped predecessors or descendants for external database release id $extDbRelId");
}

# ----------------------------------------------------------------------
# other methods
# ----------------------------------------------------------------------

sub getGoTerms {
  my ($self, $dbh, $extDbRelId) = @_;
  my $goTerms;
  my $sth = $dbh->prepare("select go_term_id, go_id, name from SRes.GoTerm where external_database_release_id=$extDbRelId");
  $sth->execute();
  while (my ($goTermId, $goId, $name)=$sth->fetchrow_array()) {
    $goTerms->{$goId}->{'goTermId'} = $goTermId;
    $goTerms->{$goId}->{'name'} = $name;
  }
  return($goTerms);
}

sub printDump {
  my ($self, $goTerms, $sth) = @_;
  foreach my $goId (keys %{$goTerms}) {
    STDOUT->print("$goId\t$goTerms->{$goId}->{'name'}\t");
    $sth->execute($goTerms->{$goId}->{'goTermId'});
    my @listIds;
    my @listNames;
    while (my ($id, $name) = $sth->fetchrow_array()) {
      push(@listIds, $id);
      push(@listNames, $name);
    }
    my $listIdsString = join(",", @listIds);
    my $listNamesString = join(",", @listNames);
    STDOUT->print("$listIdsString\t$listNamesString\n"); 
    $sth->finish();
  }
}
1;
