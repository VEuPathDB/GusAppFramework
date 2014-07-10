package GUS::Supported::Plugin::InsertGeneOntology;

@ISA = qw(GUS::PluginMgr::Plugin);

use strict;

use GUS::PluginMgr::Plugin;

use GUS::Model::SRes::OntologyTerm;
use GUS::Model::SRes::OntologyTermType;
use GUS::Model::SRes::OntologyRelationship;
use GUS::Model::SRes::OntologySynonym;

use Text::Balanced qw(extract_quotelike extract_delimited);

my $ontologyTermTypeId;

my %idSet;
my %transitiveClosure; # the smallest superset of the OBO file's relationship set that is a transitive

my $argsDeclaration =
  [
   fileArg({ name           => 'oboFile',
	     descr          => 'The Gene Ontology OBO file',
	     reqd           => 1,
	     mustExist      => 1,
	     format         => 'OBO format',
	     constraintFunc => undef,
	     isList         => 0,
	   }),

   stringArg({ name           => 'extDbRlsName',
	       descr          => 'external database release name for the GO ontology',
	       reqd           => 1,
	       constraintFunc => undef,
	       isList         => 0,
	     }),

   stringArg({ name           => 'extDbRlsVer',
	       descr          => 'external database release version for the GO ontology. Must be equal to the data-version of the GO ontology as stated in the oboFile',
	       reqd           => 1,
	       constraintFunc => undef,
	       isList         => 0,
	     }),
   booleanArg({ name          => 'calcTransitiveClosure',
		descr         => 'If this argument is given, a transitive closure table is created and populated',
		reqd         => 0,
		default      => 0
	    })
  ];

my $purpose = <<PURPOSE;
Insert all terms from a Gene Ontology OBO file.
PURPOSE

my $purposeBrief = <<PURPOSE_BRIEF;
Insert all terms from a Gene Ontology OBO file.
PURPOSE_BRIEF

my $notes = <<NOTES;
This plugin does not populate the MINIMUM_LEVEL, MAXIMUM_LEVEL, or NUMBER_OF_LEVELS fields.
NOTES

my $tablesAffected = <<TABLES_AFFECTED;
SRes.OntologyTerm, SRes.OntologyTermType, SRes.OntologyRelationship, SRes.OntologySynonym
TABLES_AFFECTED

my $tablesDependedOn = <<TABLES_DEPENDED_ON;
None.
TABLES_DEPENDED_ON

my $howToRestart = <<RESTART;
Just reexecute the plugin; all existing terms, synonyms and
relationships for the specified External Database Release
will be removed.
RESTART

my $failureCases = <<FAIL_CASES;
If GO associations have been entered for pre-existing terms, this
plugin won't be able to delete the terms (integrity violation), and
the plugin will die; you'll need to first delete the associations
before reexecuting this plugin.
FAIL_CASES

my $documentation =
  { purpose          => $purpose,
    purposeBrief     => $purposeBrief,
    notes            => $notes,
    tablesAffected   => $tablesAffected,
    tablesDependedOn => $tablesDependedOn,
    howToRestart     => $howToRestart,
    failureCases     => $failureCases
  };

sub new {
  my ($class) = @_;
  $class = ref $class || $class;

  my $self = bless({}, $class);

  $self->initialize({ requiredDbVersion => 4.0,
		      cvsRevision       => '$Revision: 10797 $',
		      name              => ref($self),
		      argsDeclaration   => $argsDeclaration,
		      documentation     => $documentation
		    });

  return $self;
}

sub run {
  my ($self) = @_;

  my $oboFile = $self->getArg('oboFile');
  open(OBO, "<$oboFile") or $self->error("Couldn't open '$oboFile': $!\n");

  my $dataVersion = $self->_parseDataVersion(\*OBO);

  my $extDbRlsName = $self->getArg('extDbRlsName');
  my $extDbRlsVer = $self->getArg('extDbRlsVer');

  $self->error("extDbRlsVer $extDbRlsVer does not match data-version $dataVersion of the obo file\n")
    unless $dataVersion eq $extDbRlsVer;

  my $extDbRlsId = $self->getExtDbRlsId($extDbRlsName, $extDbRlsVer);

  $self->_deleteTermsAndRelationships($extDbRlsId);
  my $ancestors = $self->_parseTerms(\*OBO, $extDbRlsId);

  close(OBO);
  $self->_updateAncestors($extDbRlsId, $ancestors);

  if ($self->getArg('calcTransitiveClosure')) {
    $self->_calcTransitiveClosure($extDbRlsId);
  }
}

sub _parseTerms {

  my ($self, $fh, $extDbRlsId) = @_;
  my $ancestors;

  my $block = "";
  while (<$fh>) {
    if (m/^\[ ([^\]]+) \]/x) {
      $ancestors = $self->_processBlock($block, $extDbRlsId, $ancestors)
	if $block =~ m/\A\[Term\]/; # the very first block will be the
                                    # header, and so should not get
                                    # processed; also, some blocks may
                                    # be [Typedef] blocks
      $self->undefPointerCache();
      $block = "";
    }
    $block .= $_;
  }

  $ancestors = $self->_processBlock($block, $extDbRlsId, $ancestors)
    if $block =~ m/\A\[Term\]/; # the very first block will be the
                                # header, and so should not get
                                # processed; also, some blocks may be
                                # [Typedef] blocks
  return($ancestors);
}

sub _processBlock {

  my ($self, $block, $extDbRlsId, $ancestors) = @_;

  $self->{_count}++;

  my ($id, $name, $namespace, $def, $comment,
      $synonyms, $relationships,
      $isObsolete) = $self->_parseBlock($block);

  my $ontologyTerm = $self->_retrieveOntologyTerm($id, $name, $def, $comment,
				      $synonyms, $isObsolete,
				      $extDbRlsId);
  $ancestors->{$id} = $namespace;
  $idSet{$ontologyTerm->getOntologyTermId()} = 1;

  for my $relationship (@$relationships) {
    $self->_processRelationship($ontologyTerm, $relationship, $extDbRlsId);
  }

  warn "Processed $self->{_count} terms\n" unless $self->{_count} % 500;
  return($ancestors);
}

sub _processRelationship {

  my ($self, $childTerm, $relationship, $extDbRlsId) = @_;

  my ($type, $parentId) = @$relationship;

  my $parentTerm = $self->_retrieveOntologyTerm($parentId, undef, undef, undef,					  undef, undef, $extDbRlsId);

  # add this link to the data structure we'll use later to find the transitive closure
  $transitiveClosure{$childTerm->getOntologyTermId()}{$parentTerm->getOntologyTermId()} = 1;

  my $predicate = $self->_retrieveRelationshipPredicate($type, $extDbRlsId);

  my $ontologyRelationship =
    GUS::Model::SRes::OntologyRelationship->new({
      subject_term_id   => $childTerm->getOntologyTermId(),
      predicate_term_id => $predicate->getOntologyTermId(),
      object_term_id    => $parentTerm->getOntologyTermId(),
    });

  $ontologyRelationship->submit();
}

sub _retrieveRelationshipPredicate {

  my ($self, $type, $extDbRlsId) = @_;

  my $predicateTerm = GUS::Model::SRes::OntologyTerm->new({
    name                         => $type,
    ontology_term_type_id        => $self->_getOntologyTermTypeId('relationship'),
    external_database_release_id => $extDbRlsId,
  });

  $predicateTerm->submit()
    unless ($predicateTerm->retrieveFromDB());

  return $predicateTerm;
}

sub _retrieveOntologyTerm {

  my ($self, $id, $name, $def, $comment, $synonyms, $isObsolete, $extDbRlsId) = @_;

  my $ontologyTerm = GUS::Model::SRes::OntologyTerm->new({
    source_id                    => $id,
    ontology_term_type_id        => $self->_getOntologyTermTypeId('class'),
    external_database_release_id => $extDbRlsId,
  });

  unless ($ontologyTerm->retrieveFromDB()) {
      $ontologyTerm->setName("Not yet available");
    }

  # some of these may not actually yet be available, if we've been
  # called while building a relationship:

  $ontologyTerm->setName($name) if length($name);
  $ontologyTerm->setDefinition($def) if length($def);
  $ontologyTerm->setNotes($comment) if length($comment);
  $ontologyTerm->setIsObsolete(1) if ($isObsolete && $isObsolete eq "true");

  $self->_setOntologyTermSynonyms($ontologyTerm, $synonyms, $extDbRlsId) if $synonyms;

  $ontologyTerm->submit();

  return $ontologyTerm;
}

sub _getOntologyTermTypeId {

  my ($self, $name) = @_;

  if (!$ontologyTermTypeId) {
    my $ontologyTermType = GUS::Model::SRes::OntologyTermType->new({
      name                         => $name,
    });

    $ontologyTermType->submit()
      unless ($ontologyTermType->retrieveFromDB());

    $ontologyTermTypeId = $ontologyTermType->getOntologyTermTypeId();
  }

  return ($ontologyTermTypeId);
}

sub _setOntologyTermSynonyms {

  my ($self, $ontologyTerm, $synonyms, $extDbRlsId) = @_;

  for my $synonym (@$synonyms) {
    my ($type, $text) = @$synonym;

    my $sourceId;
    if ($type eq "alt_id") {
	$sourceId = $text;
    }

    my $ontologySynonym = GUS::Model::SRes::OntologySynonym->new({
      ontology_synonym             => $text,
      source_id                    => $sourceId,
      external_database_release_id => $extDbRlsId,
    });
    $ontologyTerm->addChild($ontologySynonym);
  }
}


sub _parseBlock {

  my ($self, $block) = @_;

  my ($id) = $block =~ m/^id:\s+(GO:\d+)/m;
  my ($name) = $block =~ m/^name:\s+(.*)/m;
  my ($namespace) = $block =~ m/^namespace:\s+(.*)/m;
  my ($comment) = $block =~ m/^comment:\s+(.*)/m;
  my ($def) = $block =~ m/^def:\s+(.*)/ms;
  ($def) = extract_quotelike($def);
  $def =~ s/\A"|"\Z//msg;

  # remove OBO-format special character escaping:
  $comment =~ s/ \\ ([
                       \: \, \" \\
                       \( \) \[ \] \{ \}
                       \n
                     ])
               /$1/xg;

  $def =~ s/ \\ ([
                   \: \, \" \\
                   \( \) \[ \] \{ \}
                   \n
                 ])
           /$1/xg;


  my @synonyms;
  while ($block =~ m/^((?:\S+_)?synonym):\s+\"([^\"]*)\"/mg) {
    push @synonyms, [$1, $2];
  }

  while ($block =~ m/^alt_id:\s+(GO:\d+)/mg) {
    push @synonyms, ["alt_id", $1];
  }

  my @relationships;
  while ($block =~ m/^is_a:\s+(GO:\d+)/mg) {
    push @relationships, ["is_a", $1];
  }

  while ($block =~ m/^relationship:\s+part_of\s+(GO:\d+)/mg) {
    push @relationships, ["part_of", $1];
  }

  my ($isObsolete) = $block =~ m/^is_obsolete:\s+(\S+)/m;

  return ($id, $name, $namespace, $def, $comment, \@synonyms, \@relationships, $isObsolete)
}

sub _updateAncestors {

  my ($self, $extDbRlsId, $ancestors) = @_;
  my %ancestorIds;

  my $mf = GUS::Model::SRes::OntologyTerm->new({
    name                        => 'molecular_function',
    external_database_release_id => $extDbRlsId,
  });
  my $cc = GUS::Model::SRes::OntologyTerm->new({
    name                        => 'cellular_component',
    external_database_release_id => $extDbRlsId,
  });
  my $bp = GUS::Model::SRes::OntologyTerm->new({
    name                        => 'biological_process',
    external_database_release_id => $extDbRlsId,
  });

  if ($mf->retrieveFromDB()) {
    $ancestorIds{'molecular_function'} = $mf->getOntologyTermId();
  }
  else {
    STDERR->print("There is no molecular_function term.\n");
  }
  if ($cc->retrieveFromDB()) {
    $ancestorIds{'cellular_component'} = $cc->getOntologyTermId();
  }
  else {
    STDERR->print("There is no cellular_component term.\n");
  }
  if ($bp->retrieveFromDB()) {
    $ancestorIds{'biological_process'} = $bp->getOntologyTermId();
  }
  else {
    STDERR->print("There is no biological_process term.\n");
  }

  foreach my $goId (keys %{$ancestors}) {
    my $ontologyTerm = GUS::Model::SRes::OntologyTerm->new({
       source_id                        => $goId,
       external_database_release_id => $extDbRlsId
    });
    if ($ontologyTerm->retrieveFromDB()) {
      $ontologyTerm->setAncestorTermId($ancestorIds{$ancestors->{$goId}});
      $ontologyTerm->submit();
    }
     $self->undefPointerCache();
  }
}

sub _calcTransitiveClosure {

  my ($self, $extDbRlsId) = @_;
  my %augmentation; # just the added relationships, unlike %transitiveCloure, which contains both explicitly-given relationships and those added here

  my $somethingWasAdded;
  warn "calculating transitive closure\n";

  # find transitive closure
  do {
    warn "iterating through big loop\n";
    $somethingWasAdded = undef;

    foreach my $key1 (sort keys %transitiveClosure)  {
      foreach my $key2 (sort keys %{$transitiveClosure{$key1}}) {
	foreach my $key3 (sort keys %{$transitiveClosure{$key2}}) {
	  if (!$transitiveClosure{$key1}{$key3}) {
	    $transitiveClosure{$key1}{$key3} = 1;
	    $augmentation{$key1}{$key3} = 1;
	    $somethingWasAdded = 1;
	  }
	}
      }
    }
  } until !$somethingWasAdded;

  # add links as needed to make relation reflexive, so each term is an ancestor of itself.
  # this simplifies the use of OntologyRelationship in queries. (and maintains compatibility
  # with GUS 3.6)
  warn "adding self-links\n";
  foreach my $id (keys %idSet) {
    $augmentation{$id}{$id} = 1
      unless ($transitiveClosure{$id}{$id});
  }

  # get a predicate term for closure links
  my $predicate = $self->_retrieveRelationshipPredicate("closure", $extDbRlsId);

  my $counter;
  # put transitive-closure links into database
  foreach my $key1 (sort keys %augmentation)
    {
      foreach my $key2 (sort keys %{$augmentation{$key1}})
        {
	  my $ontologyRelationship =
             GUS::Model::SRes::OntologyRelationship->new({
               subject_term_id   => $key1,
               predicate_term_id => $predicate->getOntologyTermId(),
               object_term_id    => $key2,
             });

	  $ontologyRelationship->submit();
	  $self->undefPointerCache()
	    if ($counter++) % 500;
        }
    }

  warn "added $counter new relationships\n";

  my $dbh = $self->getQueryHandle();
  $dbh->commit(); # ga no longer doing this by default
}

sub _deleteTermsAndRelationships {

  my ($self, $extDbRlsId) = @_;

  my $dbh = $self->getQueryHandle();

  $dbh->do(<<SQL) or die "deleting old records from OntologySynonym";
    delete from sres.OntologySynonym
    where ontology_term_id in (select ontology_term_id
                               from sres.OntologyTerm
                               where external_database_release_id = $extDbRlsId)
SQL

  $dbh->do(<<SQL) or die "deleting old records from ";
    delete from sres.OntologyRelationship
    where subject_term_id in (select ontology_term_id
                              from sres.OntologyTerm
                              where external_database_release_id = $extDbRlsId)
                  or predicate_term_id in (select ontology_term_id
                              from sres.OntologyTerm
                              where external_database_release_id = $extDbRlsId)
                  or object_term_id in (select ontology_term_id
                              from sres.OntologyTerm
                              where external_database_release_id = $extDbRlsId)
SQL

  $dbh->do(<<SQL) or die "deleting old records from ";
    delete  from sres.OntologyTerm
    where external_database_release_id = $extDbRlsId
SQL

}

sub _parseDataVersion {

  my ($self, $fh) = @_;

  my $dataVersion;
  while (<$fh>) {
    if (m/^version\: (\S+)$/) {
      $dataVersion = $1;
      last;
    }
  }

  unless (length $dataVersion) {
    $self->error("Couldn't parse out the data-version!\n");
  }

  return $dataVersion;
}

sub undoTables {
  my ($self) = @_;

  return ('SRes.OntologyRelationship',
	  'SRes.OntologySynonym',
	  'SRes.OntologyTerm',
	 );
}
