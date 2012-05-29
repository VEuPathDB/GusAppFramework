package GUS::Supported::Plugin::InsertGeneOntology;

@ISA = qw(GUS::PluginMgr::Plugin);

use strict;

use GUS::PluginMgr::Plugin;

use GUS::Model::SRes::OntologyTerm;
use GUS::Model::SRes::OntologyTermType;
use GUS::Model::SRes::OntologyRelationship;
use GUS::Model::SRes::OntologyRelationshipType;
use GUS::Model::SRes::OntologySynonym;

use Text::Balanced qw(extract_quotelike extract_delimited);

my $ontologyTermTypeId;
my $parenthoodOntologyTermId;

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
	       descr          => 'external database release version for the GO ontology. Must be equal to the cvs version of the GO ontology as stated in the oboFile',
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
MINIMUM_LEVEL, MAXIMUM_LEVEL, and NUMBER_OF_LEVELS fields are
currently left at a default of 1; i.e. with respect to the schema,
this plugin is (marginally) incomplete.
NOTES

my $tablesAffected = <<TABLES_AFFECTED;
SRes.OntologyTerm, SRes.OntologyTermType, SRes.OntologyRelationship, SRes.OntologyRelationshipType, SRes.OntologySynonym
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
		      cvsRevision       => '$Revision: 9030 $',
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

  my $cvsRevision = $self->_parseCvsRevision(\*OBO);

  my $extDbRlsName = $self->getArg('extDbRlsName');
  my $extDbRlsVer = $self->getArg('extDbRlsVer');

  $self->error("extDbRlsVer $extDbRlsVer does not match CVS version $cvsRevision of the obo file\n")
    unless $cvsRevision eq $extDbRlsVer;

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

  my $ontologyRelationshipType =
    $self->{_ontologyRelationshipTypeCache}->{$type} ||= do {
      my $goType = GUS::Model::SRes::OntologyRelationshipType->new({ name => $type });
      unless ($goType->retrieveFromDB()) {
	$goType->submit();
      }
      $goType;
    };

  my $ontologyRelationship =
    GUS::Model::SRes::OntologyRelationship->new({
      subject_term_id               => $parentTerm->getOntologyTermId(),
      predicate_term_id             => _getParenthoodOntologyTermId($extDbRlsId),
      object_term_id                => $childTerm->getOntologyTermId(),
      ontology_relationship_type_id => $ontologyRelationshipType->getOntologyRelationshipTypeId(),
    });

  $ontologyRelationship->submit();
}

sub _getParenthoodOntologyTermId {
  my ($extDbRlsId) = @_;

  if (!$parenthoodOntologyTermId) {
    my $ontologyTermType = GUS::Model::SRes::OntologyTermType->new({
      name                         => "Gene Ontology term",
    });

    my $ontologyTerm = GUS::Model::SRes::OntologyTerm->new({
      name                    => "is parent of",
      ontology_term_type_id   => $ontologyTermType->getOntologyTermTypeId(),
    });

    unless ($ontologyTerm->retrieveFromDB()) {
      $ontologyTerm->setOntologyTermTypeId(_getOntologyTermTypeId());
      $ontologyTerm->submit();
    }

    $parenthoodOntologyTermId = $ontologyTerm->getOntologyTermId();
  }

  return($parenthoodOntologyTermId);
}

sub _retrieveOntologyTerm {

  my ($self, $id, $name, $def, $comment, $synonyms, $isObsolete, $extDbRlsId) = @_;

  my $ontologyTerm = GUS::Model::SRes::OntologyTerm->new({
    source_id                    => $id,
    ontology_term_type_id        => _getOntologyTermTypeId(),
    external_database_release_id => $extDbRlsId,
  });

  unless ($ontologyTerm->retrieveFromDB()) {
      $ontologyTerm->setName("Not yet available");
      $ontologyTerm->setMinimumLevel(1);
      $ontologyTerm->setMaximumLevel(1);
      $ontologyTerm->setNumberOfLevels(1);
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

  if (!$ontologyTermTypeId) {
    my $ontologyTermType = GUS::Model::SRes::OntologyTermType->new({
      name                         => "Gene Ontology term",
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

  my $dbh = $self->getQueryHandle();

  $dbh->do("DROP TABLE ontology_tc");
  $dbh->do(<<EOSQL);
    CREATE TABLE ontology_tc (
      child_id NUMBER(10,0) NOT NULL,
      parent_id NUMBER(10,0) NOT NULL,
      depth NUMBER(3,0) NOT NULL,
      PRIMARY KEY (child_id, parent_id)
    )
EOSQL

  $dbh->do(<<EOSQL);
    INSERT INTO ontology_tc (child_id, parent_id, depth)
    SELECT ontology_term_id,
           ontology_term_id,
           0
    FROM   SRes.OntologyTerm
    WHERE  external_database_release_id = $extDbRlsId
EOSQL

  $dbh->do(<<EOSQL);

    INSERT INTO ontology_tc (child_id, parent_id, depth)
    SELECT child_term_id,
           parent_term_id,
           1
    FROM   SRes.OntologyRelationship gr,
           SRes.OntologyTerm gtc,
           SRes.OntologyTerm gtp
    WHERE  gtc.ontology_term_id = gr.child_term_id
      AND  gtp.ontology_term_id = gr.parent_term_id
      AND  gtc.external_database_release_id = $extDbRlsId
      AND  gtp.external_database_release_id = $extDbRlsId
EOSQL

  my $select = $dbh->prepare(<<EOSQL);
    SELECT DISTINCT tc1.child_id,
                    tc2.parent_id,
                    tc1.depth + 1
    FROM   ontology_tc tc1,
           ontology_tc tc2
    WHERE  tc1.parent_id = tc2.child_id
      AND  tc2.depth = 1
      AND  tc1.depth = ?
      AND  NOT EXISTS (
             SELECT 'x'
             FROM ontology_tc tc3
             WHERE tc3.child_id = tc1.child_id
               AND tc3.parent_id = tc2.parent_id
           )
EOSQL

  my $insert = $dbh->prepare(<<EOSQL);
    INSERT INTO ontology_tc (child_id, parent_id, depth)
               VALUES (    ?,      ?,      ?)
EOSQL

  my ($oldsize) =
    $dbh->selectrow_array("SELECT COUNT(*) FROM ontology_tc");

  my ($num) = $dbh->selectrow_array("SELECT COUNT(*) FROM SRes.OntologyTerm WHERE external_database_release_id = $extDbRlsId");
  warn "GO Terms: $num\n";
  ($num) = $dbh->selectrow_array("SELECT COUNT(*) FROM SRes.OntologyRelationship");
  warn "Relationships: $num\n";
  warn "starting size: $oldsize\n";

  my $newsize = 0;
  my $len = 1;

  while (!$newsize || $oldsize < $newsize) {
    $oldsize = $newsize || $oldsize;
    $newsize = $oldsize;
    $select->execute($len++);
    while(my @data = $select->fetchrow_array) {
      $insert->execute(@data);
      $newsize++;
    }
    warn "Transitive closure (length $len): added @{[$newsize - $oldsize]} edges\n";
  }

  my $closureRelationshipType =
      GUS::Model::SRes::OntologyRelationshipType->new({ name => 'closure' });

  unless ($closureRelationshipType->retrieveFromDB()) {
    $closureRelationshipType->submit();
  }

  my $closureRelationshipTypeId = $closureRelationshipType->getOntologyRelationshipTypeId();

  my $sth = $dbh->prepare("SELECT child_id, parent_id, depth FROM ontology_tc");
  $sth->execute();


  while (my ($child_id, $parent_id, $depth) = $sth->fetchrow_array()) {
    $self->undefPointerCache();
    my $ontologyRelationship = GUS::Model::SRes::OntologyRelationship->new({
      parent_term_id          => $parent_id,
      child_term_id           => $child_id,
      ontology_relationship_type_id => $closureRelationshipTypeId,
    });
    $ontologyRelationship->submit();
  }

  $dbh->do("DROP TABLE ontology_tc");
  $dbh->commit(); # ga no longer doing this by default

}

sub _deleteTermsAndRelationships {

  my ($self, $extDbRlsId) = @_;

  my $dbh = $self->getQueryHandle();

  my $ontologyTerms = $dbh->prepare(<<EOSQL);

  SELECT ontology_term_id
  FROM   SRes.OntologyTerm
  WHERE  external_database_release_id = ?

EOSQL

  my $deleteRelationships = $dbh->prepare(<<EOSQL);

  DELETE
  FROM   SRes.OntologyRelationship
  WHERE  parent_term_id = ?
     OR  child_term_id = ?

EOSQL

  my $deleteSynonyms = $dbh->prepare(<<EOSQL);

  DELETE
  FROM   SRes.OntologySynonym
  WHERE  ontology_term_id = ?

EOSQL

  my $deleteTerm = $dbh->prepare(<<EOSQL);

  DELETE
  FROM   SRes.OntologyTerm
  WHERE  ontology_term_id = ?

EOSQL

  $ontologyTerms->execute($extDbRlsId);
  while (my ($ontologyTermId) = $ontologyTerms->fetchrow_array()) {
    $deleteRelationships->execute($ontologyTermId, $ontologyTermId);
    $deleteSynonyms->execute($ontologyTermId);
    $deleteTerm->execute($ontologyTermId);
  }
}

sub _parseCvsRevision {

  my ($self, $fh) = @_;

  my $cvsRevision;
  while (<$fh>) {
    if (m/cvs version\: \$Revision: (\S+)/) {
      $cvsRevision = $1;
      last;
    }
  }

  unless (length $cvsRevision) {
    $self->error("Couldn't parse out the CVS version!\n");
  }

  return $cvsRevision;
}

sub undoTables {
  my ($self) = @_;

  return ('SRes.OntologyRelationship',
	  'SRes.OntologyRelationshipType',
	  'SRes.OntologySynonym',
	  'SRes.OntologyTerm',
	 );
}
