##
## InsertAffy2Gene Plugin
## $Id: $
##

package GUS::Community::Plugin::InsertAffy2Gene;
@ISA = qw( GUS::PluginMgr::Plugin );

use strict;
use IO::File;
use GUS::PluginMgr::Plugin;

use GUS::Model::DoTS::Gene;
use GUS::Model::RAD::ArrayDesign;
use GUS::Model::RAD::ShortOligoFamily;
use GUS::Model::RAD::CompositeElementGene;

# ----------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------

sub getArgumentsDeclaration {
  my $argumentDeclaration  =
    [
     fileArg({name => 'inFile',
	      descr => 'The full path of the Affymetrix annotation file.',
	      constraintFunc=> undef,
	      reqd  => 1,
	      isList => 0,
	      mustExist => 1,
	      format => ''
	     }),
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
		  isList         => 0 }),
     integerArg({name  => 'restart',
		 descr => 'Line number in Taxon.gene_info file from which loading should be resumed (line 1 is the first line after the header, empty lines are counted).',
		 constraintFunc=> undef,
		 reqd  => 0,
		 isList => 0
		}),
     integerArg({name  => 'testnum',
		 descr => 'The number of data lines to read when testing this plugin. Not to be used in commit mode.',
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
  my $purposeBrief = 'Loads Entrez Gene annotation for an Affymetrix array into RAD.CompositeElementGene';

  my $purpose = "This plugin reads an Affymetrix annotation file for a specified array and populates RAD.CompositeElementGene for that array.";

  my $tablesAffected = [['RAD::CompositeElementGene', 'Enters a row for each annotated composite_element in the specified array.']];

  my $tablesDependedOn = [['RAD::ArrayDesign', 'The array of interest'], ['RAD::ShortOligoFamily', 'The composite elements for the specified array'], ['DoTS::Gene', 'The Entrez Genes to which the specified array maps'], ['SRes::ExternalDatabaseRelease', 'The release of the Taxon Entrez Gene external database identifying the Entrez Genes']];

  my $howToRestart = "Loading can be resumed using the I<--restart n> argument where n is the line number in the annotation file of the first row to load upon restarting (line 1 is the first line after the header, empty lines are counted). Alternatively, one can use the plugin GUS::Community::Plugin::Undo to delete all entries inserted by a specific call to this plugin. Then this plugin can be re-run from fresh.";

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
		     cvsRevision => '$Revision: 6086 $',
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
  $self->checkArrayDesignId();
  
  my $resultDescrip = $self->insertCompositeElementGene();
  
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
  else {
    my $name = $arrayDesign->getName();
    if ($name !~ /affymetrix/i) {
      $self->userError("The --arrayDesignId provided doesn't correspond to an array whose name contains 'Affymetrix'.");
    }
  }
}

sub insertCompositeElementGene {
  my ($self) = @_;
  my $resultDescrip = '';
  my $file = $self->getArg('inFile');
  my $lineNum = 0;
  my $insertCount = 0;
  my $arrayDesignId = $self->getArg('arrayDesignId');
  my $extDbRls = $self->getExtDbRlsId($self->getArg('extDbRlsSpec'));

  my $fh = IO::File->new("<$file") || die "Cannot open file $file";
  my $startLine = defined $self->getArg('restart') ? $self->getArg('restart') : 1;
  my $endLine;
  if (defined $self->getArg('testnum')) {
    $endLine = $startLine-1+$self->getArg('testnum');
  }
  my %positions;
  my $line = <$fh>;
  chomp($line);
  my @arr = split(/\"\s*,\s*\"/, $line);
  for (my $i=0; $i<@arr; $i++) {
    $arr[$i] =~ s/^\s+|\s+$//g;
    $arr[$i] =~ s/\"//g;
    if ($arr[$i] =~ /probe\s+set\s+id$/i) {
      $positions{'id'} = $i;
      $self->logDebug("Probe Set column: $i");
    }
    if ($arr[$i] =~ /^entrez\s+gene$/i) {
      $positions{'entrez'} = $i;
      $self->logDebug("Entrez Gene column: $i");
    }   
  }
  while (my $line=<$fh>) {
      $lineNum++;
      if ($lineNum<$startLine) {
	  next;
      }
      if (defined $endLine && $lineNum>$endLine) {
	  last;
      }
      if ($lineNum % 200 == 0) {
	  $self->log("Working on line $lineNum-th.");
      }
      chomp($line);
      if ($line =~ /^\s+$/) {
	  next;
      }
      my @arr = split(/\"\s*,\s*\"/, $line);
      for (my $i=0; $i<@arr; $i++) {
	  $arr[$i] =~ s/^\s+|\s+$//g;
	  $arr[$i] =~ s/\"//g;
      }
      my $id = $arr[$positions{'id'}];
      my $entrez = $arr[$positions{'entrez'}];
      if ($entrez !~ /^\d+$/) {
	  next;
      }
      else {
	  my $gene = GUS::Model::DoTS::Gene->new({external_database_release_id => $extDbRls, source_id => $entrez});
	  if ($gene->retrieveFromDB()) {
	      my  $compositeElement = GUS::Model::RAD::ShortOligoFamily->new({name => $id, array_design_id => $arrayDesignId});
	      if ($compositeElement->retrieveFromDB()) {
		  my $compositeElementGene = GUS::Model::RAD::CompositeElementGene->new({});
		  $compositeElementGene->setParent($gene);
		  $compositeElementGene->setParent($compositeElement);
		  $compositeElementGene->submit();
		  $insertCount++;
	      }
	  }
	  else {
	      next;
	  }
      }
      $self->undefPointerCache();
 }
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
