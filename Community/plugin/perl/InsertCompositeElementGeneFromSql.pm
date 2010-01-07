##
## InsertCompositeElementGeneFromSql Plugin
## $Id: $
##

package GUS::Community::Plugin::InsertCompositeElementGeneFromSql;
@ISA = qw( GUS::PluginMgr::Plugin );

use strict;
use IO::File;
use GUS::PluginMgr::Plugin;

use GUS::Model::DoTS::Gene;
use GUS::Model::RAD::CompositeElementGene;

# ----------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------

sub getArgumentsDeclaration {
  my $argumentDeclaration  =
    [
     fileArg({name => 'sqlFile',
	      descr => 'The full path of a tab-delimited file whose 1st column contains sqls returning (composite_element_id, gene_id) pairs. One sql statement per line with variable DoTS.Gene.external_database_release_id',
	      constraintFunc=> undef,
	      reqd  => 1,
	      isList => 0,
	      mustExist => 1,
	      format => ''
	     }),
     stringArg({ name  => 'extDbRlsSpec',
		 descr => "The ExternalDBRelease specifier for the Taxon.gene_info file to which Entrez Gene Ids should refer. Must be in the format 'name|version', where the name must match an name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
		 constraintFunc => undef,
		 reqd           => 1,
		 isList         => 0 }),
     integerArg({name  => 'testnum',
		 descr => 'The number of entries to load. Not to be used in commit mode.',
		 constraintFunc=> undef,
		 reqd  => 0,
		 isList => 0
		})
    ];
  return $argumentDeclaration;
}

# ----------------------------------------------------------------------
# Documentation
# ----------------------------------------------------------------------


sub getDocumentation {
  my $purposeBrief = 'Loads Entrez Gene annotation for an array into RAD.CompositeElementGene using sql queries.';
  
  my $purpose = "This plugin runs a set of sql queries returning (composite_element_id, gene_id) pairs and populates RAD.CompositeElementGene.";

  my $tablesAffected = [['RAD::CompositeElementGene', 'Enters a row for each pair returned by an sql query.']];

  my $tablesDependedOn = [];

  my $howToRestart = "Use the plugin GUS::Community::Plugin::Undo to delete all entries inserted by a specific call to this plugin. Then this plugin can be re-run from fresh.";

  my $failureCases = "";

  my $notes = <<NOTES;

=head1 AUTHOR

Written by Elisabetta Manduchi.

=head1 COPYRIGHT

Copyright Elisabetta Manduchi, Trustees of University of Pennsylvania 2008. 
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


  $self->initialize({requiredDbVersion => 3.5,
		     cvsRevision => '$Revision: 7796$',
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

  if (defined($self->getArg('testnum')) && $self->getArg('commit')) {
    $self->userError("The --testnum argument can only be provided if COMMIT is OFF.");
  }

  my $resultDescrip = $self->insertCompositeElementGene();

  $self->setResultDescr($resultDescrip);
  $self->logData($resultDescrip);
}

# ----------------------------------------------------------------------
# methods called by run
# ----------------------------------------------------------------------

sub insertCompositeElementGene {
  my ($self) = @_;
  my $resultDescrip = '';
  my $lineNum1 = 0;
  my $insertCount = 0;
  my $file = $self->getArg('sqlFile');
  my $fh = IO::File->new("<$file") || die "Cannot open file $file\n.";
  my $dbh = $self->getQueryHandle();
  my $extDbRls = $self->getExtDbRlsId($self->getArg('extDbRlsSpec'));

  while (my $line=<$fh>) {
    my $lineNum2 = 0;
    chomp($line);
    my ($sql, @rest) = split(/\t/, $line);
 
    $self->log("$sql\n");
    my $sth = $dbh->prepare("$sql") || die $dbh->errstr;
    $sth->execute($extDbRls) || die $dbh->errstr;
    while (my ($ceId, $geneId)=$sth->fetchrow_array()) {
      $lineNum1++;
      $lineNum2++;
      if (defined $self->getArg('testnum') && $lineNum1==$self->getArg('testnum')) {
	last;
      }
      if ($lineNum2 % 200 == 0) {
	$self->log("Working on row $lineNum2.");
      }
      my $compositeElementGene = GUS::Model::RAD::CompositeElementGene->new({composite_element_id => $ceId, gene_id => $geneId});
      if (!$compositeElementGene->retrieveFromDB()) {
	$compositeElementGene->submit();
	$insertCount++;
      }
      $self->undefPointerCache();
    }
  }
  $fh->close();
  $resultDescrip .= "Entered $insertCount rows in RAD.CompositeElementGene";
  return ($resultDescrip);
}

# ----------------------------------------------------------------------
# Undo
# ----------------------------------------------------------------------

sub undoTables {
  my ($self) = @_;

  return ('RAD.CompositeElementGene');
}

1;
