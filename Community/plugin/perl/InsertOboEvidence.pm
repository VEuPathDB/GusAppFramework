package GUS::Community::Plugin::InsertOboEvidence;

@ISA = qw(GUS::PluginMgr::Plugin);

use strict;

use GUS::PluginMgr::Plugin;

use GUS::Model::SRes::OntologyTerm;
use GUS::Model::SRes::OntologyRelationship;
use GUS::Model::SRes::OntologyRelationshipType;

use Text::Balanced qw(extract_quotelike extract_delimited);

my $argsDeclaration =
  [
   fileArg({ name           => 'oboFile',
	     descr          => 'The Evidence OBO file',
	     reqd           => 1,
	     mustExist      => 1,
	     format         => 'OBO format',
	     constraintFunc => undef,
	     isList         => 0,
	   }),

   stringArg({ name           => 'extDbRlsSpec',
	       descr          => "The ExternalDBRelease specifier for the evidence file. Must be in the format 'name|version', where the name must match a name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease for the evidence ontology",
	       reqd           => 1,
	       constraintFunc => undef,
	       isList         => 0,
	     })
  ];

my $purpose = <<PURPOSE;
Insert all terms from an Evidence OBO file.
PURPOSE

my $purposeBrief = <<PURPOSE_BRIEF;
Insert all terms from an Evidence OBO file.
PURPOSE_BRIEF

my $notes = <<NOTES;
NOTES

my $tablesAffected = <<TABLES_AFFECTED;
SRes.OntologyTerme, SRes.OntologyRelationship, SRes.OntologyRelationshipType
TABLES_AFFECTED

my $tablesDependedOn = <<TABLES_DEPENDED_ON;
None.
TABLES_DEPENDED_ON

my $howToRestart = <<RESTART;
Just reexecute the plugin; all existing terms, and
relationships (defined by the specified External Database Release)
will be removed.
RESTART

my $failureCases = <<FAIL_CASES;
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

  $self->initialize({ requiredDbVersion => 3.5,
		      cvsRevision       => '$Revision: 7433$',
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

  my $extDbRlsId = $self->getExtDbRlsId($self->getArg('extDbRlsSpec'));

  $self->_deleteTermsAndRelationships($extDbRlsId);
  $self->_parseTerms(\*OBO, $extDbRlsId);

  close(OBO);
}

sub _parseTerms {

  my ($self, $fh, $extDbRlsId) = @_;

  my $block = "";
  while (<$fh>) {
    if (m/^\[ ([^\]]+) \]/x) {
      $self->_processBlock($block, $extDbRlsId)
	if $block =~ m/\A\[Term\]/; # the very first block will be the
                                    # header, and so should not get
                                    # processed; also, some blocks may
                                    # be [Typedef] blocks
      $self->undefPointerCache();
      $block = "";
    }
    $block .= $_;
  }

  $self->_processBlock($block, $extDbRlsId)
    if $block =~ m/\A\[Term\]/; # the very first block will be the
                                # header, and so should not get
                                # processed; also, some blocks may be
                                # [Typedef] blocks
}

sub _processBlock {

  my ($self, $block, $extDbRlsId) = @_;

  $self->{_count}++;

  my ($id, $name, $def, $relationships) = $self->_parseBlock($block);

  my $term = $self->_retrieveTerm($id, $name, $def, $extDbRlsId);

  for my $relationship (@$relationships) {
    $self->_processRelationship($term, $relationship, $extDbRlsId);
  }

  warn "Processed $self->{_count} terms\n" unless $self->{_count} % 500;
}

sub _processRelationship {

  my ($self, $subjectTerm, $relationship, $extDbRlsId) = @_;

  my ($type, $objectId) = @$relationship;

  my $objectTerm = $self->_retrieveTerm($objectId, undef, undef, $extDbRlsId);

  my $ontologyRelationshipType = GUS::Model::SRes::OntologyRelationshipType->new({ name => $type , is_native => 1});
  unless ($type->retrieveFromDB()) {
    $type->submit();
  }

  my $ontologyRelationship =
    GUS::Model::SRes::OntologyRelationship->new({
      subject_term_id          => $subjectTerm->getOntologyTermId(),
      object_term_id           => $objectTerm->getOntologyTermId(),
      ontology_relationship_type_id => $ontologyRelationshipType->getOntologyRelationshipTypeId(),
    });

  $ontologyRelationship->submit();
}

sub _retrieveTerm {

  my ($self, $id, $name, $def, $extDbRlsId) = @_;

  my $term = GUS::Model::SRes::OntologyTerm->new({
    source_id                    => $id,
    external_database_release_id => $extDbRlsId,
  });

  unless ($term->retrieveFromDB()) {
      $term->setName("Not yet available");
    }

  # some of these may not actually yet be available, if we've been
  # called while building a relationship:

  $term->setName($name) if length($name);
  $term->setDefinition($def) if length($def);

  $term->submit();

  return $term;
}


sub _parseBlock {

  my ($self, $block) = @_;

  my ($id) = $block =~ m/^id:\s+(ECO:\d+)/m;
  my ($name) = $block =~ m/^name:\s+(.*)/m;
  my ($def) = $block =~ m/^def:\s+(.*)/ms;
  ($def) = extract_quotelike($def);
  $def =~ s/\A"|"\Z//msg;

  # remove OBO-format special character escaping:
  $def =~ s/ \\ ([
                   \: \, \" \\
                   \( \) \[ \] \{ \}
                   \n
                 ])
           /$1/xg;


  my @relationships;
  while ($block =~ m/^is_a:\s+(ECO:\d+)\s/mg) {
    push @relationships, ["is_a", $1];
  }

  return ($id, $name, $def, \@relationships)
}

sub _deleteTermsAndRelationships {

  my ($self, $extDbRlsId) = @_;

  my $dbh = $self->getQueryHandle();

  my $terms = $dbh->prepare(<<EOSQL);

  SELECT ontology_term_id
  FROM   SRes.OntologyTerm
  WHERE  external_database_release_id = ?

EOSQL

  my $deleteRelationships = $dbh->prepare(<<EOSQL);

  DELETE
  FROM   SRes.OntologyRelationship
  WHERE  subject_term_id = ?
     OR  object_term_id = ?

EOSQL


  my $deleteTerm = $dbh->prepare(<<EOSQL);

  DELETE
  FROM   SRes.OntologyTerm
  WHERE  ontology_term_id = ?

EOSQL
  
  $terms->execute($extDbRlsId);
  while (my ($termId) = $terms->fetchrow_array()) {
    $deleteRelationships->execute($termId, $termId);
    $deleteTerm->execute($termId);
  }
}

sub undoTables {
  my ($self) = @_;

  return ('SRes.OntologyRelationship',
	  'SRes.OntologyRelationshipType',
	  'SRes.OntologyTerm',
	 );
}
