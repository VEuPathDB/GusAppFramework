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

   stringArg({name => 'algoInvocationId',
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
		     cvsRevision => '$Revision: 3419 $',
		     name => ref($self),
		     argsDeclaration => $argsDeclaration,
		     documentation => $documentation
		    });

  return $self;
}

sub run{
  my ($self) = @_;
  $self->{'algoInvocationIds'} = $self->getArg('algoInvocationId');
  $self->{'dbh'} = $self->getQueryHandle();

  $self->{'dbh'}->{AutoCommit}=0;

  $self->undoFeatures();

  $self->undoSequences();

  $self->deleteFromTable('Core.AlgorithmInvocation');

  $self->{'dbh'}->commit() if($self->getArgs('commit'));
}

sub undoFeatures{
   my ($self) = @_;

   $self->undoSpecialCaseQualifiers();

   $self->deleteFromTable('DoTS.Location');

   $self->setParentToNull();

   $self->deleteFromTable('DoTS.NAFeature');
}

sub setParentToNull{
  my ($self) = @_;

  my $sql =
"UPDATE DoTS.NAFeature
SET parent_id = NULL
WHERE row_alg_invocation_id IN ($self->{algoInvocationIds})";

   $self->{'dbh'}->prepareAndExecute($sql);

}

sub undoSpecialCaseQualifiers{
  my ($self) = @_;

  $self->{mapperSet} =
    GUS::Supported::BioperlFeatMapperSet->new($self->getArg('mapFile'));

  my $handlerName = $featureMapper->getHandlerName($tag);
  my $handler= $self->{mapperSet}->getHandler($handlerName);
  $handler->undoAll($self->{'algoInvocationIds'}, $self->{'dbh'});

}

sub undoSequences{
  my ($self) = @_;

  $self->deleteFromTable('DoTS.NAEntry');
  $self->deleteFromTable('DoTS.SecondaryAccs');
  $self->deleteFromTable('DoTS.NASequenceRef');
  $self->deleteFromTable('DoTS.Keyword');
  $self->deleteFromTable('DoTS.NASequenceKeyword');
  $self->deleteFromTable('DoTS.NAComment');
}

sub deleteFromTable{
  my ($self, $tableName) = @_;
  my $sql = 
"DELETE FROM $tableName
WHERE row_alg_invocation_id IN ($self->{algoInvocationIds})";

   $self->{'dbh'}->prepareAndExecute($sql);
}


1;
