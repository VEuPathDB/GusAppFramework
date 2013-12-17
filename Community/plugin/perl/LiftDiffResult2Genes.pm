#######################################################################
##                 
## $Id: LiftDiffResult2Genes.pm  manduchi $
##
#######################################################################
 
package GUS::Community::Plugin::LiftDiffResult2Genes;
@ISA = qw( GUS::PluginMgr::Plugin );

use strict;
use GUS::PluginMgr::Plugin;
use GUS::Model::Results::GeneDiffResult;

# ----------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------

sub getArgumentsDeclaration {
  my $argumentDeclaration =
    [
     intArg({name => 'protAppNodeId',
	      descr => 'Identifies the protocol application node for which results should be lifted',
	      constraintFunc=> undef,
	      reqd  => 1,
	      isList => 0	     }),
     stringArg({ name  => 'extDbRlsSpec',
		 descr => "The ExternalDBRelease specifier for these na_features. Must be in the format 'name|version', where the name must match a name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
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
  my $purposeBrief = 'Insert entries in Results.GeneDiffResult';

  my $purpose = "This plugin populates Results.GeneDiffResult based on Results.NAFeatureDiffResult for those genes which have only one NAFeature associated to them (disregarding UNIQUE parts of NAFeatures).";

  my $tablesAffected = [['Results::GeneDiffResult', 'Enters a row for each gene having only one NAFeature.']];

  my $tablesDependedOn = [['Results::NAFeatureDiffResult', 'The na_feature results to be lifted']];

  my $howToRestart = "Undo and rerun";

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
		     cvsRevision => '$Revision$',
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

  my $count = 0;
  my $extDbRls = $self->getExtDbRlsId($self->getArg('extDbRlsSpec'));
  my $dbh = $self->getQueryHandle();
  my $protAppNodeId = $self->getArg('protAppNodeId');

  my $stm1 = "select na_feature_id, mean1, sd1, mean2, sd2, fdr, fold_change, test_statistic, p_value, adj_p_value, q_value, confidence_up, confidence_down from Results.NAFeatureResult where protocol_app_node_id=$protAppNodeId";
  my $sth1 = $dbh->prepare($stm1);

  my $sth2 = $dbh->prepare("select g.gene_id, gf.na_feature_id, gf.name from DoTS.GeneFeature gf, DoTS.GeneInstance gi1, DoTS.GeneInstance gi2 where gf.external_database_release_id=$extDbRls and gf.na_feature_id=gi1.na_feature_id and gi1.gene_id=gi2.gene_id and gi2.na_feature_id=?");
 

  while (my ($naFeatureId1, $mean1, $sd1, $mean2, $sd2, $fdr, $foldChange, $testStat, $pValue, $adjPValue, $qValue, $confUp, $confDown) = $sth1->fetchrow_array()) {
    my $geneId;
    $sth2->execute($naFeatureId1);
    my %names;
    while (my ($geneId2, $naFeatureId2, $name) = $sth2->fetchrow_array()) {
      if (defined($geneId) && $geneId2!=$geneId) {
	$self->userError("Multiple genes for na_feature_id=$naFeatureId1");
      }
      $names{$naFeatureId2} = $name;
    }
    if ($names{$naFeatureId1} =~ /^UNIQUE/) {
      next;
    }
    $names{$naFeatureId1} =~ s/^\*//;
    if (scalar(keys %names)>2) {
      next;
    }
    elsif (scalar(keys %names)==2) {
      my $toss = 0;
      foreach my $key (keys %names) {
	if ($key!=$naFeatureId1 && $names{$key} ne "UNIQUE-" . $names{$naFeatureId1}) {
	  $toss = 1;
	  last;
	}
      }
      if ($toss) {
	next;
      }
      else {
	my $geneDiffRes = GUS::Model::Results::GeneDiffResult->new({gene_id => $geneId, protocol_app_node_id => $protAppNodeId, mean1 => $mean1, sd1 => $sd1, mean2 => $mean2, sd2 => $sd2, fdr => $fdr, fold_change => $foldChange, test_statistic => $testStat, p_value => $pValue, adj_p_value => $adjPValue, q_value => $qValue, confidence_up => $confUp, confidence_down => $confDown});
	$geneDiffRes->submit();
	$count++;
      }
    }
    else {
      my $geneDiffRes = GUS::Model::Results::GeneDiffResult->new({gene_id => $geneId, protocol_app_node_id => $protAppNodeId, mean1 => $mean1, sd1 => $sd1, mean2 => $mean2, sd2 => $sd2, fdr => $fdr, fold_change => $foldChange, test_statistic => $testStat, p_value => $pValue, adj_p_value => $adjPValue, q_value => $qValue, confidence_up => $confUp, confidence_down => $confDown});
      $geneDiffRes->submit();
      $count++;
    }
  }

  my $resultDescrip = "Inserted $count entries in Results.GeneDiffResult";
  return $resultDescrip;
}

# ----------------------------------------------------------------------
# Undo
# ----------------------------------------------------------------------

sub undoTables {
  my ($self) = @_;
  return ('Results.GeneDiffResult');
}

1;
