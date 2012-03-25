package GUS::Supported::Plugin::CalculateTransitiveClosure;

@ISA = qw(GUS::PluginMgr::Plugin);

use strict;

use GUS::PluginMgr::Plugin;

use GUS::Model::SRes::GOTerm;
use GUS::Model::SRes::GORelationship;
use GUS::Model::SRes::GORelationshipType;
use GUS::Model::SRes::GOSynonym;

use Text::Balanced qw(extract_quotelike extract_delimited);

my $argsDeclaration =
  [


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
SRes.GOTerme, SRes.GORelationship, SRes.GORelationshipType, SRes.GOSynonym
TABLES_AFFECTED

my $tablesDependedOn = <<TABLES_DEPENDED_ON;
None.
TABLES_DEPENDED_ON

my $howToRestart = <<RESTART;
Just reexecute the plugin; all existing terms, synonyms and
relationships (defined by the specified External Database Release)
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

  $self->initialize({ requiredDbVersion => 3.6,
		      cvsRevision       => '$Revision: 7390 $',
		      name              => ref($self),
		      argsDeclaration   => $argsDeclaration,
		      documentation     => $documentation
		    });

  return $self;
}

sub run {
  my ($self) = @_;



  my $extDbRlsName = $self->getArg('extDbRlsName');
  my $extDbRlsVer = $self->getArg('extDbRlsVer');



  my $extDbRlsId = $self->getExtDbRlsId($extDbRlsName, $extDbRlsVer);


    $self->_calcTransitiveClosure($extDbRlsId);
}


sub _calcTransitiveClosure {

  my ($self, $extDbRlsId) = @_;

  my $dbh = $self->getQueryHandle();

  $dbh->do("DROP TABLE go_tc");
  $dbh->do(<<EOSQL);
    CREATE TABLE go_tc (
      child_id NUMBER(10,0) NOT NULL,
      parent_id NUMBER(10,0) NOT NULL,
      depth NUMBER(3,0) NOT NULL,
      PRIMARY KEY (child_id, parent_id)
    )
EOSQL

  $dbh->do(<<EOSQL);
    INSERT INTO go_tc (child_id, parent_id, depth)
    SELECT go_term_id,
           go_term_id,
           0
    FROM   SRes.GOTerm
    WHERE  external_database_release_id = $extDbRlsId
EOSQL

  $dbh->do(<<EOSQL);

    INSERT INTO go_tc (child_id, parent_id, depth)
    SELECT child_term_id,
           parent_term_id,
           1
    FROM   SRes.GORelationship gr,
           SRes.GOTerm gtc,
           SRes.GOTerm gtp
    WHERE  gtc.go_term_id = gr.child_term_id
      AND  gtp.go_term_id = gr.parent_term_id
      AND  gtc.external_database_release_id = $extDbRlsId
      AND  gtp.external_database_release_id = $extDbRlsId
EOSQL

  my $select = $dbh->prepare(<<EOSQL);
    SELECT DISTINCT tc1.child_id,
                    tc2.parent_id,
                    tc1.depth + 1
    FROM   go_tc tc1,
           go_tc tc2
    WHERE  tc1.parent_id = tc2.child_id
      AND  tc2.depth = 1
      AND  tc1.depth = ?
      AND  NOT EXISTS (
             SELECT 'x'
             FROM go_tc tc3
             WHERE tc3.child_id = tc1.child_id
               AND tc3.parent_id = tc2.parent_id
           )
EOSQL

  my $insert = $dbh->prepare(<<EOSQL);
    INSERT INTO go_tc (child_id, parent_id, depth)
               VALUES (    ?,      ?,      ?)
EOSQL

  my ($oldsize) =
    $dbh->selectrow_array("SELECT COUNT(*) FROM go_tc");

  my ($num) = $dbh->selectrow_array("SELECT COUNT(*) FROM SRes.GOTerm WHERE external_database_release_id = $extDbRlsId");
  warn "GO Terms: $num\n";
  ($num) = $dbh->selectrow_array("SELECT COUNT(*) FROM SRes.GORelationship");
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
      GUS::Model::SRes::GORelationshipType->new({ name => 'closure' });

  unless ($closureRelationshipType->retrieveFromDB()) {
    $closureRelationshipType->submit();
  }

  my $closureRelationshipTypeId = $closureRelationshipType->getGoRelationshipTypeId();

  my $sth = $dbh->prepare("SELECT child_id, parent_id, depth FROM go_tc");
  $sth->execute();


  while (my ($child_id, $parent_id, $depth) = $sth->fetchrow_array()) {
    $self->undefPointerCache();
    my $goRelationship = GUS::Model::SRes::GORelationship->new({
      parent_term_id          => $parent_id,
      child_term_id           => $child_id,
      go_relationship_type_id => $closureRelationshipTypeId,
    });
    $goRelationship->submit();
  }
  
  $dbh->do("DROP TABLE go_tc");
  $dbh->commit(); # ga no longer doing this by default

}

sub _deleteTermsAndRelationships {

  my ($self, $extDbRlsId) = @_;

  my $dbh = $self->getQueryHandle();

  my $goTerms = $dbh->prepare(<<EOSQL);

  SELECT go_term_id
  FROM   SRes.GOTerm
  WHERE  external_database_release_id = ?

EOSQL

  my $deleteRelationships = $dbh->prepare(<<EOSQL);

  DELETE
  FROM   SRes.GORelationship
  WHERE  parent_term_id = ?
     OR  child_term_id = ?

EOSQL

  my $deleteSynonyms = $dbh->prepare(<<EOSQL);

  DELETE
  FROM   SRes.GOSynonym
  WHERE  go_term_id = ?

EOSQL

  my $deleteTerm = $dbh->prepare(<<EOSQL);

  DELETE
  FROM   SRes.GOTerm
  WHERE  go_term_id = ?

EOSQL
  
  $goTerms->execute($extDbRlsId);
  while (my ($goTermId) = $goTerms->fetchrow_array()) {
    $deleteRelationships->execute($goTermId, $goTermId);
    $deleteSynonyms->execute($goTermId);
    $deleteTerm->execute($goTermId);
  }
}


1;
