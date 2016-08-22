#######################################################################
##                 
## $Id: InsertNaFeatureDiffResult.pm  manduchi $
##
#######################################################################
 
package GUS::Community::Plugin::InsertNaFeatureDiffResult;
@ISA = qw( GUS::PluginMgr::Plugin );

use strict;
use GUS::PluginMgr::Plugin;
use GUS::Model::DoTS::NAFeature;
use GUS::Model::Results::NAFeatureDiffResult;

# ----------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------

sub getArgumentsDeclaration {
  my $argumentDeclaration =
    [
     fileArg({name => 'resultFile',
	      descr => 'The full path to a tab-delimited file mapping feature names to results.',
	      constraintFunc=> undef,
	      reqd  => 1,
	      isList => 0,
	      mustExist => 1,
	      format => ''
	     }),
     stringArg({ name  => 'columnMap',
		 descr => "Comma-separated list, of length equal to the number of columns in -resultFile, indicating which  values each column corresponds to. Fields relevant to database loading must be indicated with the appropriate among: feature_name, mean1, sd1, mean2, sd2, fdr, fold_change, test_statistic, p_value, adj_p_value, q_value, confidence_up, confidence_down. Other fields won't be considered and can be denoted as desired.",
		 constraintFunc => undef,
		 reqd           => 1,
		 isList         => 1 
	     }),
     integerArg({ name  => 'skip',
		 descr => "How many lines at the top of -resultFile should be skipped, including possible header. Default is 0.",
		 constraintFunc => undef,
		 reqd           => 0,
		 isList         => 0 ,
		 default        => 0
	     }),
     integerArg({ name  => 'protAppNodeId',
		 descr => "The protocol_app_node_id to attach to these entries.",
		 constraintFunc => undef,
		 reqd           => 1,
		 isList         => 0
	     }),
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
  my $purposeBrief = 'Insert entries in Results.NAFeatureDiffResult';

  my $purpose = "This plugin reads a file associating differential results to na_features and populates Results.NAFeatureDiffResult.";

  my $tablesAffected = [['Results::NAFeatureDiffResult', 'Enters a row for each valid entry in the file']];

  my $tablesDependedOn = [['SRes::ExternalDatabaseRelease', 'The release of the external database identifying these na_features'], ['Dots::NAFeature', 'The na_features the expression values refer to']];

  my $howToRestart = "Use the --skip option to start loading from where desired in --resultFile.";

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

  my $index = $self->checkHeader();

  my ($resultCount) = $self->insertResults($index);

  my $resultDescrip = "Inserted $resultCount entries in Results.NAFeatureDiffResult";
  return $resultDescrip;
}

# ----------------------------------------------------------------------
# methods
# ----------------------------------------------------------------------
sub checkHeader {
  my ($self) = @_;
  my %index;
  my $i = 0;
  foreach my $header (@{$self->getArg('columnMap')}) {
    $index{$header} = $i;
    $i++;
  }
  if (!defined($index{'feature_name'})) {
    $self->userError("-columnMap must include 'feature_name'");
  }
  elsif (!defined($index{'mean1'}) && !defined($index{'sd1'}) && !defined($index{'mean2'}) && !defined($index{'sd2'}) && !defined($index{'fdr'}) && !defined($index{'fold_change'}) && !defined($index{'test_statistic'}) && !defined($index{'p_value'}) && !defined($index{'adj_p_value'}) && !defined($index{'q_value'}) && !defined($index{'confidence_up'}) && !defined($index{'confidence_down'})) {
    $self->userError("-columnMap must include at least one of: mean1, sd2, mean2, sd2, fdr, fold_change, test_statistic, p_value, adj_p_value, q_value, confidence_up, confidence_down");   
  }
  else {
    foreach my $header (keys %index) {
      if ($header ne 'feature_name' && $header ne 'mean1' && $header ne 'sd1' && $header ne 'mean2' && $header ne 'sd2' && $header ne 'fdr' && $header ne 'fold_change' && $header ne 'test_statistic' && $header ne 'p_value' && $header ne 'adj_p_value' && $header ne 'q_value' && $header ne 'confidence_up' && $header ne 'confidence_down') {
	$self->logData('column corresponding to header $header will not be loaded');
	undef $index{$header};
      }
    }
    return \%index;
  }
}

sub insertResults {
  my ($self, $index) = @_;
  my $resultCount = 0;

  my $skip = $self->getArg('skip');
  my $file = $self->getArg('resultFile');
  my $protAppNodeId = $self->getArg('protAppNodeId');
  my $extDbRls = $self->getExtDbRlsId($self->getArg('extDbRlsSpec'));
  $self->logDebug("Ext Db Rls Id: $extDbRls");

  open(my $fh ,'<', $file);
  for (my $i=0; $i<$skip; $i++) {
    my $line = <$fh>;
  }
  my $count = 0;
  while (my $line=<$fh>) {
    $count++;
    if ($count % 1000 == 0) {
      $self->logData("Read $count data lines.");
    }
    chomp($line);
    my @arr = split(/\t/, $line);
    my $naFeature =GUS::Model::DoTS::NAFeature->new({name=>$arr[$index->{'feature_name'}], external_database_release_id=>$extDbRls});
    if ($naFeature->retrieveFromDB()) {
      my $naFeatureId = $naFeature->getId();
      my $naFeatureDiffRes = GUS::Model::Results::NAFeatureDiffResult->new({na_feature_id => $naFeatureId, protocol_app_node_id => $protAppNodeId});
      foreach my $header (keys %{$index}) {
	if ($header ne 'feature_name') {
	  $naFeatureDiffRes->set($header, $arr[$index->{$header}]);
	}
      }
      $naFeatureDiffRes->submit();
      $resultCount++;
    }
    $self->undefPointerCache();
  }
  close($fh);
  return ($resultCount);
}

# ----------------------------------------------------------------------
# Undo
# ----------------------------------------------------------------------

sub undoTables {
  my ($self) = @_;
  return ('Results.NAFeatureDiffResult');
}

1;
