#######################################################################
##                 InsertOntologyRelationships
##
## Community plugin for InsertOntologyRelationships to create relationships
## between existing ontology terms
## $Id: InsertOntologyRelationships.pm allenem $
##
#######################################################################


package GUS::Community::Plugin::InsertOntologyRelationships;

@ISA = qw(GUS::PluginMgr::Plugin);

use strict;

use GUS::PluginMgr::Plugin;

use GUS::Model::SRes::OntologyTerm;
use GUS::Model::SRes::OntologyRelationship;
use GUS::Model::SRes::OntologySynonym;

my $argsDeclaration =
  [

   fileArg({ name           => 'relationshipFile',
	     descr          => 'A tab-delimited file containing relationships; see NOTES for file format',
	     reqd           => 1,
	     mustExist      => 1,
	     format         => 'tab-delimited',
	     constraintFunc => undef,
	     isList         => 0,
	   }),

  ];

my $purpose = <<PURPOSE;
Insert relationships between ontology terms already existing in the DB.  Load will fail if a term in the OntologyRelationship file is not found in SRes.OntologyTerm or SRes.OntologySynonym.
PURPOSE

my $purposeBrief = <<PURPOSE_BRIEF;
Insert relationships between existing ontology terms.
PURPOSE_BRIEF

my $notes = <<NOTES;
relationship file should be tab-delimited with the following header:
subject subject_xdbr object object_xdbr predicate predicate_xdbr
where _xdbr is the external database release, specified by Name|Version
subject, object, and predicate may be specified by either the term or the source_id of the term in the external database
NOTES

my $tablesAffected = <<TABLES_AFFECTED;
SRes.OntologyRelationship
TABLES_AFFECTED

my $tablesDependedOn = <<TABLES_DEPENDED_ON;
SRes.OntologyTerm, SRes.OntologySynonym
TABLES_DEPENDED_ON

my $howToRestart = <<RESTART;
Just re-execute the plugin; Relationships which already exist will not be duplicated.
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

  $self->initialize({ requiredDbVersion => 4.0,
		      cvsRevision       => '$Revision: 16159 $',
		      name              => ref($self),
		      argsDeclaration   => $argsDeclaration,
		      documentation     => $documentation
		    });

  return $self;
}

sub run {
  my ($self) = @_;

  $self->loadRelationships();
}


sub extDbRlsId {
    my ($self, $extDbRls, $extDbRlsMap) = @_;

    unless (exists $extDbRlsMap->{$extDbRls}) {
	unless ($self->getExtDbRlsId($extDbRls)) {
	    $self->error($extDbRls . " not in DB.");
	}
	$extDbRlsMap->{$extDbRls} =  $self->getExtDbRlsId($extDbRls);
    }

    return $extDbRlsMap;
}

sub loadRelationships {

    my ($self) = @_;

    $self->getDb()->manageTransaction(undef, "begin"); # start a transaction

    my $extDbRlsMap = undef;
    my $relCount = 0;
    my $relationshipFile = $self->getArg('relationshipFile');

    open(RELATIONSHIPS, "<$relationshipFile") or $self->error("Couldn't open '$relationshipFile': $!\n");
    my $header = <RELATIONSHIPS>;

    while (<RELATIONSHIPS>) {
	chomp;
	my ($subject, $subjectExtDbRls, $object, $objectExtDbRls, $predicate, $predicateExtDbRls) = split /\t/;

	$self->log("Relationship:" . $subject ." -> "
		   . $predicate . " -> "  . $object)
	  if $self->getArg('veryVerbose');

	$extDbRlsMap = $self->extDbRlsId($subjectExtDbRls, $extDbRlsMap);
	$extDbRlsMap = $self->extDbRlsId($objectExtDbRls, $extDbRlsMap);
	$extDbRlsMap = $self->extDbRlsId($predicateExtDbRls, $extDbRlsMap);

	my $subjectTerm = $self->retrieveOntologyTerm($subject, $extDbRlsMap->{$subjectExtDbRls});
	my $objectTerm = $self->retrieveOntologyTerm($object, $extDbRlsMap->{$objectExtDbRls});
	my $predicateTerm = $self->retrieveOntologyTerm($predicate, $extDbRlsMap->{$predicateExtDbRls});

	my $ontologyRelationship =
	    GUS::Model::SRes::OntologyRelationship->new({
		subject_term_id   => $subjectTerm->getOntologyTermId(),
		predicate_term_id => $predicateTerm->getOntologyTermId(),
		object_term_id    => $objectTerm->getOntologyTermId(),
							});

	$ontologyRelationship->submit(undef, 1); # noTran = 1 --> do not commit at this point

	unless (++$relCount % 500) {
	  if ($self->getArg("commit")) {
	    $self->getDb()->manageTransaction(undef, "commit"); # commit
	    $self->getDb()->manageTransaction(undef, "begin");
	  }
	  $self->undefPointerCache();
	  $self->log("$relCount relationships loaded.")
	    if $self->getArg('verbose');
	}
      }
  
    $self->getDb()->manageTransaction(undef, "commit")
      if ($self->getArg("commit")); # commit final batch
    
    $self->log("Loaded $relCount records into SRes.OntologyRelationship");

  }


sub retrieveOntologyTerm {

  my ($self, $term, $extDbRlsId) = @_;
  
  my $ontologyTerm = GUS::Model::SRes::OntologyTerm->new({ # try against source_id
    source_id                    => $term,
    external_database_release_id => $extDbRlsId,
  });

  unless ($ontologyTerm->retrieveFromDB()) { # try against name 
    $ontologyTerm = GUS::Model::SRes::OntologyTerm->new({
      name                         => $term,
      external_database_release_id => $extDbRlsId,
							});
  }

  unless ($ontologyTerm->retrieveFromDB()) { # try against synonyms
    my $ontologySynonym = GUS::Model::SRes::OntologySynonym->new({ 
      ontology_synonym                         => $term,
      external_database_release_id              => $extDbRlsId,
								 });
    if ($ontologySynonym->retrieveFromDB()) {
      $ontologyTerm = GUS::Model::SRes::OntologyTerm->new({
	   ontology_term_id => $ontologySynonym->getOntologyTermId()
							  });
    }
  }

  unless ($ontologyTerm->retrieveFromDB()) {
    $self->error("Term " . $term . " with extDbRlsId " . $extDbRlsId . " not in SRes.OntologyTerm or SRes.OntologySynonym"); 
  }

  return $ontologyTerm;
}


sub undoTables {
  my ($self) = @_;

  return ('SRes.OntologyRelationship'
	 );
}
