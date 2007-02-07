package GUS::Supported::SpecialCaseQualifierHandlers;

use strict;

use GUS::Model::DoTS::NAGene;
use GUS::Model::DoTS::NAProtein;
use GUS::Model::SRes::DbRef;
use GUS::Model::DoTS::NAFeatureComment;
use GUS::Model::DoTS::NAFeatureNAGene;
use GUS::Model::DoTS::NAFeatureNAProtein;
use GUS::Model::DoTS::DbRefNAFeature;
use GUS::Supported::Plugin::InsertSequenceFeaturesUndo;

# This is a pluggable module for GUS::Supported::Plugin::InsertSequenceFeatures 
# It handles commonly seen qualifiers that need special case treatment (ie,
# their values are not simply stuffed into a column of NAFeature or its 
# subclasses
#
# Handlers must
#  - provide a parallel undo method that is included in undoAll
#  - return either
#     - a reference to a (possibly empty) array of child objects to add to the 
#       feature
#     - undef to indicate that the entire feature should be ignored

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self, $class);
  return $self;
}

sub setPlugin{
  my ($self, $plugin) = @_;
  $self->{plugin} = $plugin;

}

sub initUndo{
  my ($self, $algoInvocIds, $dbh) = @_;

  $self->{'algInvocationIds'} = $algoInvocIds;
  $self->{'dbh'} = $dbh;
}

sub undoAll{
  my ($self, $algoInvocIds, $dbh) = @_;

  $self->initUndo($algoInvocIds, $dbh);

  $self->_undoGene();
  $self->_undoDbXRef();
  $self->_undoNote();
  $self->_undoProtein();
  $self->_undoTranslation();
  $self->_undoGapLength();

}

################ Gene ###############################3

sub gene {
  my ($self, $tag, $bioperlFeature, $feature) = @_;

  my @genes;
  foreach my $tagValue ($bioperlFeature->get_tag_values($tag)) {
    my $geneID = $self->_getNAGeneId($tagValue);
    my $gene = GUS::Model::DoTS::NAFeatureNAGene->new();
    $gene->setNaGeneId($geneID);
    push(@genes, $gene);
  }
  return \@genes;
}

sub _getNAGeneId {   
  my ($self, $geneName) = @_;
  my $truncName = substr($geneName,0,300);

  $self->{geneNameIds} = {} unless $self->{geneNameIds};

  if (!$self->{geneNameIds}->{$truncName}) {
    my $gene = GUS::Model::DoTS::NAGene->new({'name' => $truncName});
    unless ($gene->retrieveFromDB()){
      $gene->setIsVerified(0);
      $gene->submit();
    }
    $self->{geneNameIds}->{$truncName} = $gene->getId();
  }
  return $self->{geneNameIds}->{$truncName};
}

sub _undoGene{
  my ($self) = @_;

  $self->_deleteFromTable('DoTS.NAFeatureNAGene');
  $self->_deleteFromTable('DoTS.NAGene');
}

############### db Xrefs  #########################################

sub dbXRef {
  my ($self, $tag, $bioperlFeature, $feature) = @_;

  my @dbRefNaFeatures;
  foreach my $tagValue ($bioperlFeature->get_tag_values($tag)) {
    push(@dbRefNaFeatures, &buildDbXRef($self->{plugin}, $tagValue));
  }
  return \@dbRefNaFeatures;
}

# this static subroutine is public because it can be reused by other special
# case handler modules that parse their dbSpecifiers in a different way
sub buildDbXRef {
  my ($plugin, $dbSpecifier) = @_;

  my $dbRefNaFeature = GUS::Model::DoTS::DbRefNAFeature->new();
  my $id = &_getDbXRefId($plugin, $dbSpecifier);
  $dbRefNaFeature->setDbRefId($id);

  return $dbRefNaFeature;
}

# static subroutine
# store state in plugin so it can be reused by other special case handlers
sub _getDbXRefId {
  my ($plugin, $dbSpecifier) = @_;

  if (!$plugin->{dbXrefIds}->{$dbSpecifier}) {
    my @split= split(/\:/, $dbSpecifier);
    $plugin->error("Invalid db_xref: '$dbSpecifier'")
      unless scalar(@split) == 2 || scalar(@split) == 3;
    my ($dbName, $id, $sid)= @split;
    $id =~ s/^\s*//;
    my $extDbRlsId = &_getExtDatabaseRlsId($plugin, $dbName);
    my $dbref = GUS::Model::SRes::DbRef->new({'external_database_release_id' => $extDbRlsId, 
					      'primary_identifier' => $id});

    if ($sid) {
      $dbref->setSecondaryIdentifier($sid);
    }
    unless ($dbref->retrieveFromDB()) {
      $dbref->submit();
    }

    $plugin->{dbXrefIds}->{$dbSpecifier} = $dbref->getId();
  }

  return $plugin->{dbXrefIds}->{$dbSpecifier};
}

# static subroutine
# store state in plugin so it can be reused by other special case handlers
sub _getExtDatabaseRlsId {
  my ($plugin, $name) = @_;

  if (!$plugin->{extDbRlsIds}->{$name}) {
    my $externalDatabase
      = GUS::Model::SRes::ExternalDatabase->new({"name" => $name});

    unless($externalDatabase->retrieveFromDB()) {
      $externalDatabase->submit();
    }

    my $externalDatabaseRls = GUS::Model::SRes::ExternalDatabaseRelease->
      new ({'external_database_id'=>$externalDatabase->getId(),
	    'version'=>'unknown'});

    unless($externalDatabaseRls->retrieveFromDB()) {
      $externalDatabaseRls->submit();
    }

    $plugin->{extDbRlsIds}->{$name} = $externalDatabaseRls->getId();
  }
  return $plugin->{extDbRlsIds}->{$name};
}

# note: do not delete from ExternalDatabase and ExternalDatabaseRelease.
# these are handled by ISF itself
sub _undoDbXRef{
  my ($self) = @_;
  $self->_deleteFromTable('DoTS.DbRefNAFeature');
  $self->_deleteFromTable('SRes.DbRef');
}

################ Note ########################################
sub note {
  my ($self, $tag, $bioperlFeature, $feature) = @_;

  my @notes;
  foreach my $tagValue ($bioperlFeature->get_tag_values($tag)) {
    my $arg = {comment_string => substr($tagValue, 0, 4000)};
    push(@notes, GUS::Model::DoTS::NAFeatureComment->new($arg));

  }
  return \@notes;
}

sub _undoNote{
  my ($self) = @_;
  $self->_deleteFromTable('DoTS.NAFeatureComment');
}

############### Protein ##################################
sub protein {
  my ($self, $tag, $bioperlFeature, $feature) = @_;

  my @naFeatureNaProteins;
  foreach my $tagValue ($bioperlFeature->get_tag_values($tag)) {
    my $nameTrunc = substr($tagValue, 0, 300);

    my $naFeatureNaProtein = GUS::Model::DoTS::NAFeatureNAProtein->new();

    my $protein = GUS::Model::DoTS::NAProtein->new({'name' => $nameTrunc});
    unless ($protein->retrieveFromDB()){
      $protein->setIsVerified(0);
      $protein->submit();
    }

    $naFeatureNaProtein->setNaProteinId($protein->getId());
    push(@naFeatureNaProteins, $naFeatureNaProtein);
  }
  return \@naFeatureNaProteins;
}

sub _undoProtein{
  my ($self) = @_;
  $self->_deleteFromTable('DoTS.NAProtein');
  $self->_deleteFromTable('DoTS.NAFeatureNAProtein');
}

############### TranslatedAAFeature  ###############################3

sub translation {
  my ($self, $tag, $bioperlFeature, $feature) = @_;

  my @tags = $bioperlFeature->get_tag_values($tag);
  die "Feature has more than one translation \n" if scalar(@tags) != 1;

  my $transAaFeat = GUS::Model::DoTS::TranslatedAAFeature->new();
  $transAaFeat->setIsPredicted(1);

  my $aaSeq = GUS::Model::DoTS::TranslatedAASequence->
    new({'sequence' => $tags[0]});

  $aaSeq->submit();

  $transAaFeat->setAaSequenceId($aaSeq->getId());

  return [$transAaFeat];
}

sub _undoTranslation{
  my ($self) = @_;

  $self->_deleteFromTable('DoTS.TranslatedAAFeature');
  $self->_deleteFromTable('DoTS.TranslatedAASequence');

}

################ Gap Length ###############################

# put estimated gap length of ScaffoldGapFeature into min and max lengths
sub gapLength {
  my ($self, $tag, $bioperlFeature, $feature) = @_;

  my @emptyArray;
  my @tagValues = $bioperlFeature->get_tag_values($tag);
  if ($tagValues[0] =~ /\d+/) {
    $feature->setMinSize($tagValues[0]);
    $feature->setMaxSize($tagValues[0]);
  }
  return \@emptyArray;
}

# nothing special to do
sub _undoGapLength{
  my ($self) = @_;

}

##################  Ignore entire feature #########################

# the presence of the qualifer that uses this handler forces the entire
# feature to be ignored
sub ignoreFeature {
  my ($self, $tag, $bioperlFeature, $feature) = @_;
  return undef;
}

#################################################################

sub _deleteFromTable{
   my ($self, $tableName) = @_;

  &GUS::Supported::Plugin::InsertSequenceFeaturesUndo::deleteFromTable($tableName, $self->{'algInvocationIds'}, $self->{'dbh'});
}

1;

