##
## InsertHomoloGene Plugin
## $Id: $
##

package GUS::Community::Plugin::InsertHomoloGene;
@ISA = qw( GUS::PluginMgr::Plugin );

use strict;
use IO::File;
use GUS::PluginMgr::Plugin;

use GUS::Model::DoTS::Gene;
use GUS::Model::DoTS::Family;
use GUS::Model::DoTS::FamilyGene;

# ----------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------

sub getArgumentsDeclaration {
  my $argumentDeclaration  =
    [
     fileArg({name => 'homologeneFile',
	      descr => 'The full path of the homologene.data file downloaded from NCBI.',
	      constraintFunc=> undef,
	      reqd  => 1,
	      isList => 0,
	      mustExist => 1,
	      format => ''
	     }),
     stringArg({ name  => 'homologeneExtDbRlsSpec',
		  descr => "The ExternalDBRelease specifier for --homologeneFile. Must be in the format 'name|version', where the name must match an name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
		  constraintFunc => undef,
		  reqd           => 1,
		  isList         => 0 }),
     stringArg({ name  => 'taxaGeneInfoExtDbRlsSpecs',
		  descr => "The ExternalDBRelease specifiers for the Taxon.gene_info files to consider. Must be a comma-separated list with each entry in the format 'name|version', where the name must match an name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
		  constraintFunc => undef,
		  reqd           => 1,
		  isList         => 1 }),
     integerArg({name  => 'restart',
		 descr => 'Line number in --homologeneFile from which loading should be resumed (line 1 is the first line, empty lines are counted).',
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
  my $purposeBrief = 'Loads data from an NCBI homologene.data file into DoTS.';

  my $purpose = "This plugin reads a homologene.data file from NCBI HomoloGene and populates the DoTS Family and FamilyGene tables for the specified taxa.";

  my $tablesAffected = [['DoTS::Family', 'Enters a row for each homologene in the file for the taxa of interest'], ['DoTS::FamilyGene', 'Enters rows linking each entered homologene to its genes']];

  my $tablesDependedOn = [['SRes::ExternalDatabaseRelease', 'The release of the Homologene database for --homologeneFile and the releases of the Taxon Entrez Gene external databases identifying the Entrez Genes for the taxa of interest'], ['SRes::Taxon', 'The taxa of interest']];

  my $howToRestart = "Loading can be resumed using the I<--restart n> argument where n is the line number in the homologene.data file of the first row to load upon restarting (line 1 is the first line, empty lines are counted). Alternatively, one can use the plugin GUS::Community::Plugin::Undo to delete all entries inserted by a specific call to this plugin. Then this plugin can be re-run from fresh.";

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
  my $resultDescrip;

  if (defined($self->getArg('testnum')) && $self->getArg('commit')) {
    $self->userError("The --testnum argument can only be provided if COMMIT is OFF.");
  }
  my $dbh = $self->getQueryHandle();
  my $taxa = $self->getTaxa($dbh);

  $resultDescrip .= $self->insertHomoloGene($taxa);

  $self->setResultDescr($resultDescrip);
  $self->logData($resultDescrip);
}

# ----------------------------------------------------------------------
# methods called by run
# ----------------------------------------------------------------------

sub getTaxa {
  my ($self, $dbh) = @_;
  my @taxaSpecs = @{$self->getArg('taxaGeneInfoExtDbRlsSpecs')};
  my $taxa;
  my $sth = $dbh->prepare('select distinct t.nci_tax_id from Sres.Taxon t, SRes.Gene g where t.taxon_id=g.taxon_id and g.external_database_release_id=?') || die $dbh->errstr;

  for (my $i=0; $i<@taxaSpecs; $i++) {
    my $extDbRls = $self->getExtDbRlsId($taxaSpecs[$i]);
    $sth->execute($extDbRls)  || die $dbh->errstr;
    my $taxon = $sth->fetchrow_array();
    $sth->finish();
    $taxa->{$taxon} = $extDbRls;
    $self->logData("NIC taxon_id $taxon will be considered.\n");
  }
  return($taxa);
}

sub insertHomoloGene {
  my ($self, $taxa) = @_;
  my $resultDescrip = '';
  my $file = $self->getArg('homologeneFile');
  my $extDbRls = $self->getExtDbRlsId($self->getArg('homologeneExtDbRlsSpec'));
  my $lineNum = 0;
  my $familyCount = 0;
  my $familyGeneCount = 0;

  my $fh = IO::File->new("<file") || die "Cannot open file $file";
  my $startLine = defined $self->getArg('restart') ? $self->getArg('restart') : 1;
  my $endLine;
  if (defined $self->getArg('testnum')) {
    $endLine = $startLine-1+$self->getArg('testnum');
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
    my ($hid, $taxId, $geneId, @rest) = split(/\t/, $line);
    if (!defined ($taxa->{$taxId})) {
      next;
    }
    else {
      my $family = GUS::Model::DoTS::Family->new(external_database_release_id => $extDbRls, source_id => $hid);
      my $gene = GUS::Model::DoTS::Gene->new({external_database_release_id => $taxa->{$taxId}, source_id => $geneId});
      if ($gene->retrieveFromDB()) {
	if (!$family->retrieveFromDB()) {
	  $familyCount++;
	}
	my $familyGene = GUS::Model::DoTS::FamilyGene->new({});
	$familyGeneCount++;
	$familyGene->setParent($family);
	$familyGene->setParent($gene);
	$family->submit();
      }
    }
    $resultDescrip .= "Entered $familyCount rows in DoTS.Family and $familyGeneCount rows in DoTS.FamilyGene";
    return ($resultDescrip);
  }
}

# ----------------------------------------------------------------------
# Undo
# ----------------------------------------------------------------------

sub undoTables {
  my ($self) = @_;

  return ('DoTS.FamilyGene', 'DoTS.Family');
}

1;
