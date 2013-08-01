#######################################################################
##                 InsertEnsemblGenes.pm
## $Id: InsertAvgGeneExpression.pm  manduchi $
##
#######################################################################
 
package GUS::Community::Plugin::InsertAvgGeneExpression;
@ISA = qw( GUS::PluginMgr::Plugin );

use strict;
use DBI;
use Statistics::Descriptive;
use GUS::PluginMgr::Plugin;
use GUS::Model::Results::GeneExpression;

# ----------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------

sub getArgumentsDeclaration {
  my $argumentDeclaration =
    [
     integerArg({ name  => 'protAppNodeId',
		 descr => "The protocol_app_node_id for which to load gene expression values.",
		 constraintFunc => undef,
		 reqd           => 1,
		 isList         => 0
	     })
    ];
  return $argumentDeclaration;
}

# ----------------------------------------------------------------------
# Documentation
# ----------------------------------------------------------------------

sub getDocumentation {
  my $purposeBrief = 'Insert entries in Results.GeneExpression';

  my $purpose = "This plugin computes average gene feature expressions and standard errors by gene for a given protocol application node and inserts the results into Results.GeneExpression.";

  my $tablesAffected = [['Results::GeneExpression', 'Enters a row for each gene']];

  my $tablesDependedOn = [['Dots::GeneFeature', 'The gene features whose expression values need to be averaged over genes'], ['Results:NAFeatureExpression', 'The expression values for the given protocol app node id']];

  my $howToRestart = "";

  my $failureCases = "";

  my $notes = <<NOTES;

=head1 AUTHOR

Written by Elisabetta Manduchi.

=head1 COPYRIGHT

Copyright Elisabetta Manduchi, Trustees of University of Pennsylvania 2013. 
NOTES

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

  $self->initialize({requiredDbVersion => 4.0,
		     cvsRevision => '$Revision: 12616  $',
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

  my ($resultCount) = $self->insertResults();

  my $resultDescrip = "Inserted $resultCount entries in Results.GeneExpression";
  return $resultDescrip;
}

# ----------------------------------------------------------------------
# methods
# ----------------------------------------------------------------------

sub insertResults {
  my ($self) = @_;

  my $resultCount = 0;
  my $protAppNodeId = $self->getArg('protAppNodeId');

  my $dbh = $self->getQueryHandle();
  my $sth = $dbh->prepareAndExecute("select gi.gene_id, avg(e.value), stddev(e.value), count(e.value) from dots.geneinstance gi, results.nafeatureexpression e where gi.na_feature_id=e.na_feature_id and e.protocol_app_node_id=$protAppNodeId group by gi.gene_id");
  while (my ($geneId, $avg, $stdDev, $count)=$sth->fetchrow_array()) {
    my $geneExpr = GUS::Model::Results::GeneExpression->new({gene_id => $geneId, protocol_app_node_id => $protAppNodeId, value => $avg, standard_error => $stdDev/$count});
    $geneExpr->submit();
    $resultCount++;
    if ($resultCount % 1000 == 0) {
      $self->logData("Inserted $resultCount values");
    }
    $self->undefPointerCache();
  }
  $sth->finish();
  return($resultCount);
}

# ----------------------------------------------------------------------
# Undo
# ----------------------------------------------------------------------

sub undoTables {
  my ($self) = @_;
  return ('Results.GeneExpression');
}

1;
