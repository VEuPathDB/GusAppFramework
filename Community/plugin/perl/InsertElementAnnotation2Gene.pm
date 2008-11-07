##
## InsertElementAnnotation2Gene Plugin
## $Id: $
##

package GUS::Community::Plugin::InsertElementAnnotation2Gene;
@ISA = qw( GUS::PluginMgr::Plugin );

use strict;
use IO::File;
use GUS::PluginMgr::Plugin;

use GUS::Model::DoTS::Gene;
use GUS::Model::RAD::ArrayDesign;
use GUS::Model::RAD::ElementGene;

# ----------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------

sub getArgumentsDeclaration {
  my $argumentDeclaration  =
    [
     integerArg({name  => 'arrayDesignId',
		 descr => 'The RAD array_design_id of the Affymetrix array to link.',
		 constraintFunc=> undef,
		 reqd  => 1,
		 isList => 0
		}),
     stringArg({ name  => 'extDbRlsSpec',
		 descr => "The ExternalDBRelease specifier for the Taxon.gene_info file to which Entrez Gene Ids should refer. Must be in the format 'name|version', where the name must match an name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
		 constraintFunc => undef,
		 reqd           => 1,
		 isList         => 0 })
    ];
  return $argumentDeclaration;
}

# ----------------------------------------------------------------------
# Documentation
# ----------------------------------------------------------------------


sub getDocumentation {
  my $purposeBrief = 'Loads Entrez Gene annotation from RAD.ElementAnnotation into RAD.ElementGene';

  my $purpose = "This plugin retrieves Entrez Gene Id annotation from RAD.ElementAnnotation for a specified array and populates RAD.ElementGene for that array.";
  
  my $tablesAffected = [['RAD::ElementGene', 'Enters a row for each annotated element in the specified array.']];
  
  my $tablesDependedOn = [['RAD::ArrayDesign', 'The array of interest'], ['RAD::ElementAnnotation', 'The Entrez Gene Id annotations for the specified array'], ['DoTS::Gene', 'The Entrez Genes to which the specified array should map'], ['SRes::ExternalDatabaseRelease', 'The release of the Taxon Entrez Gene external database identifying the Entrez Genes']];
  
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
  
  $self->checkArrayDesignId();
  
  my $resultDescrip = $self->insertElementGene();
  
  $self->setResultDescr($resultDescrip);
  $self->logData($resultDescrip);
}

# ----------------------------------------------------------------------
# methods called by run
# ----------------------------------------------------------------------

sub checkArrayDesignId {
  my ($self) = @_;
  my $arrayDesignId = $self->getArg('arrayDesignId');
  my $arrayDesign = GUS::Model::RAD::ArrayDesign->new({array_design_id => $arrayDesignId});
  if (!$arrayDesign->retrieveFromDB()) {
    $self->userError("The --arrayDesignId provided is not valid.");
  }    
}

sub insertElementGene {
  my ($self) = @_;
  my $resultDescrip = '';
  my $lineNum = 0;
  my $insertCount = 0;
  my $arrayDesignId = $self->getArg('arrayDesignId');
  my $extDbRls = $self->getExtDbRlsId($self->getArg('extDbRlsSpec'));

  my $dbh = $self->getQueryHandle();
  my $sth = $dbh->prepare("select ea.element_id, ea.value from RAD.ElementAnnotation ea, RAD.ElementImp s where s.array_design_id=$arrayDesignId and s.element_id=ea.element_id and ea.name='Entrez Gene Id'") || die $dbh->errstr;

  $sth->execute() || $dbh->errstr;
  while (my ($elementId, $entrez) = $sth->fetchrow_array()) {
    $lineNum++;
    if ($lineNum % 200 == 0) {
      $self->log("Working on entry $lineNum-th.");
    }
    my $gene = GUS::Model::DoTS::Gene->new({external_database_release_id => $extDbRls, source_id => $entrez});
    if ($gene->retrieveFromDB()) {
      my $elementGene = GUS::Model::RAD::ElementGene->new({element_id => $elementId});
      $elementGene->setParent($gene);
      $elementGene->submit();
      $insertCount++;
    }
    $self->undefPointerCache();
  }
  $resultDescrip .= "Entered $insertCount rows in RAD.ElementGene";
  return ($resultDescrip);
}

# ----------------------------------------------------------------------
# Undo
# ----------------------------------------------------------------------

sub undoTables {
  my ($self) = @_;
  
  return ('RAD.ElementGene');
}

1;
