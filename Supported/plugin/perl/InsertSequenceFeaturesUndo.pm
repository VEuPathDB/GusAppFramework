package GUS::Supported::Plugin::InsertSequenceFeaturesUndo;

# todo:
#  - handle seqVersion more robustly
#  - add logging info
#  - undo

@ISA = qw(GUS::PluginMgr::Plugin);

use strict;

use Bio::SeqIO;
use Bio::Tools::SeqStats;
use Bio::Tools::GFF;
use Bio::SeqFeature::Tools::Unflattener;

use GUS::PluginMgr::Plugin;
use GUS::Supported::BioperlFeatMapperSet;
use GUS::Supported::SequenceIterator;

my $purpose = <<PURPOSE;

PURPOSE

  my $purposeBrief = <<PURPOSEBRIEF;

PURPOSEBRIEF

  my $notes = <<NOTES;

NOTES

  my $tablesAffected =
  [
   ['SRes.Reference', ''],
   ['SRes.SequenceOntology', ''],
   ['DoTS.SequenceType', ''],
   ['DoTS.NASequence', ''],
   ['DoTS.ExternalNASequence', ''],
   ['DoTS.VirtualSequence', ''],
   ['DoTS.Assembly', ''],
   ['DoTS.SplicedNASequence', ''],
   ['DoTS.NAEntry', ''],
   ['DoTS.SecondaryAccs', ''],
   ['DoTS.NALocation', ''],
   ['DoTS.NASequenceRef', ''],
   ['DoTS.Keyword', ''],
   ['DoTS.NAComment', ''],
   ['DoTS.TranslatedAAFeature', ''],
   ['DoTS.TranslatedAASequence', ''],
   ['DoTS.NAGene', ''],
   ['DoTS.NAProtein', ''],
   ['SRes.DbRef', ''],
   ['DoTS.NAFeatureComment', ''],
   ['DoTS.NASequenceKeyword', ''],
   ['DoTS.NAFeatureNAGene', ''],
   ['DoTS.NAFeatureNAProtein', ''],
   ['DoTS.DbRefNAFeature', ''],
  ];


  my $tablesDependedOn = 
  [
   ['SRes.TaxonName', ''],
   ['SRes.SequenceOntology', ''],
   ['SRes.ExternalDatabase', ''],
   ['SRes.ExternalDatabaseRelease', ''],
  ];

  my $howToRestart = <<RESTART;
No restart
RESTART

  my $failureCases = <<FAIL;
FAIL

my $documentation = { purpose=>$purpose, 
		      purposeBrief=>$purposeBrief,
		      tablesAffected=>$tablesAffected,
		      tablesDependedOn=>$tablesDependedOn,
		      howToRestart=>$howToRestart,
		      failureCases=>$failureCases,
		      notes=>$notes
		    };

my $argsDeclaration  =
  [

   fileArg({name => 'mapFile',
	    descr => 'XML file with mapping of Sequence Features from BioPerl to GUS.  For an example, see $GUS_HOME/config/genbank2gus.xml',
	    constraintFunc=> undef,
	    reqd  => 1,
	    isList => 0,
	    mustExist => 1,
	    format=>'XML'
	   }),

   stringArg({name => 'algInvocationId',
	      descr => 'A comma delimited list of algorithm invocation ids to undo',
	      constraintFunc=> undef,
	      reqd  => 0,
	      isList => 1,
	     })
  ];


sub new {
  my $class = shift;
  my $self = {};
  bless($self, $class);

  $self->initialize({requiredDbVersion => 3.5,
		     cvsRevision => '$Revision$',
		     name => ref($self),
		     argsDeclaration => $argsDeclaration,
		     documentation => $documentation
		    });

  return $self;
}

sub run{
  my ($self) = @_;
  $self->{'algInvocationIds'} = $self->getArg('algInvocationId');
  $self->{'dbh'} = $self->getQueryHandle();

  $self->{'dbh'}->{AutoCommit}=0;

  $self->undoFeatures();

  $self->undoSequences();

  $self->_deleteFromTable('Core.AlgorithmParam');

  $self->_deleteFromTable('Core.AlgorithmInvocation');

  if ($self->getArg('commit')) {
    print STDERR "Committing\n";
    $self->{'dbh'}->commit()
      || die "Commit failed: " . $self->{'dbh'}->errstr() . "\n";
  } else {
    print STDERR "Rolling back\n";
    $self->{'dbh'}->rollback()
      || die "Rollback failed: " . $self->{'dbh'}->errstr() . "\n";
  }
}

sub undoFeatures{
   my ($self) = @_;

   $self->undoSpecialCaseQualifiers();

   $self->_deleteFromTable('DoTS.NALocation');

   $self->setParentToNull();

   $self->_deleteFromTable('DoTS.NAFeature');
}

sub setParentToNull{
  my ($self) = @_;

  my $algoInvocIds = join(', ', @{$self->{'algInvocationIds'}});

  my $sql =
"UPDATE DoTS.NAFeature
SET parent_id = NULL
WHERE row_alg_invocation_id IN ($algoInvocIds)";

   $self->{'dbh'}->prepareAndExecute($sql);

}

sub undoSpecialCaseQualifiers{
  my ($self) = @_;

  my $mapperSet = GUS::Supported::BioperlFeatMapperSet->new($self->getArg('mapFile'));

  my @handlers = $mapperSet->getAllHandlers();
  foreach my $handler (@handlers){
     $handler->undoAll($self->{'algInvocationIds'}, $self->{'dbh'});
   }
}

sub undoSequences{
  my ($self) = @_;

  $self->_deleteFromTable('DoTS.NAEntry');
  $self->_deleteFromTable('DoTS.SecondaryAccs');
  $self->_deleteFromTable('DoTS.NASequenceRef');
  $self->_deleteFromTable('DoTS.Keyword');
  $self->_deleteFromTable('DoTS.NASequenceKeyword');
  $self->_deleteFromTable('DoTS.NAComment');
  $self->_deleteFromTable('DoTS.NASequence');
}

sub _deleteFromTable{
   my ($self, $tableName) = @_;

  &deleteFromTable($tableName, $self->{'algInvocationIds'}, $self->{'dbh'});
}

sub deleteFromTable{
  my ($tableName, $algInvocationIds, $dbh) = @_;

  my $algoInvocIds = join(', ', @{$algInvocationIds});

  my $sql = 
"DELETE FROM $tableName
WHERE row_alg_invocation_id IN ($algoInvocIds)";

  my $rows = $dbh->do($sql) || die "Failed running sql:\n$sql\n";
  $rows = 0 if $rows eq "0E0";
  print STDERR "Deleted $rows rows from $tableName\n";
}


1;
