package GUS::Community::Plugin::InsertOntologyRelationships;

@ISA = qw(GUS::PluginMgr::Plugin);

use strict;

use GUS::PluginMgr::Plugin;

use GUS::Model::SRes::OntologyTerm;
use GUS::Model::SRes::OntologyTermType;
use GUS::Model::SRes::OntologyRelationship;

use Data::Dumper;


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
Insert GO relationships from a tab-delimited file.
PURPOSE

my $purposeBrief = <<PURPOSE_BRIEF;
Insert GO relationships from a tab-delimited file.
PURPOSE_BRIEF

my $notes = <<NOTES;
relationship file should be tab-delimited with the following header:
subject subject_xdbr object object_xdbr predicate predicate_xdbr
where _xdbr is the external database release, specified by Name|Version
subject, object, and predicate may be specified by either the term or the source_id of the term in the external database
NOTES

my $tablesAffected = <<TABLES_AFFECTED;
SRes.OntologyTermType, SRes.OntologyRelationship
TABLES_AFFECTED

my $tablesDependedOn = <<TABLES_DEPENDED_ON;
SRes.OntologyTerm, SRes.OntologySynonym
TABLES_DEPENDED_ON

my $howToRestart = <<RESTART;
Just reexecute the plugin; Relationships which alread exist will not be duplicated.
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


sub getExtDbRlsId {
    my ($self, $extDbRls, $extDbRlsMap) = @_;
$self->log($self->getExtDbRlsId($extDbRls)) if $self->getArg('verbose');
    if (!exists $extDbRlsMap->{$extDbRls}) {
      $self->log($self->getExtDbRlsId($extDbRls)) if $self->getArg('verbose');
	$extDbRlsMap->{$extDbRls} = $self->getExtDbRlsId($extDbRls);
      
    }

    return $extDbRlsMap;
}
sub loadRelationships {

    my ($self) = @_;

    $self->getDb()->manageTransaction(undef, "begin"); # start a transaction

    my $xdbrId = undef;
    my $extDbRlsMap = undef;
    my $relCount = 0;
    my $relationshipFile = $self->getArg('relationshipFile');

    open(RELATIONSHIPS, "<$relationshipFile") or $self->error("Couldn't open '$relationshipFile': $!\n");
    my $header = <RELATIONSHIPS>;

    while (<RELATIONSHIPS>) {
	chomp;
	my ($subject, $subjectExtDbRls, $object, $objectExtDbRls, $predicate, $predicateExtDbRls) = split /\t/;

	$self->log($subject .", " . $object) if $self->getArg('verbose');

	$extDbRlsMap = $self->getExtDbRlsId($subjectExtDbRls, $extDbRlsMap);
	$extDbRlsMap = $self->getExtDbRlsId($objectExtDbRls, $extDbRlsMap);
	$extDbRlsMap = $self->getExtDbRlsId($predicateExtDbRls, $extDbRlsMap);

	$self->log(Dumper($extDbRlsMap)) if $self->getArg('verbose');

	$self->log($subjectExtDbRls . ":" . $extDbRlsMap->{$subjectExtDbRls}) if $self->getArg('verbose');

	my $subjectTerm = $self->retrieveOntologyTerm($subject, $extDbRlsMap->{$subjectExtDbRls});
	my $objectTerm = $self->retrieveOntologyTerm($object, $extDbRlsMap->{$objectExtDbRls});
	my $predicateTerm = $self->retrieveOntologyTerm($predicate, $extDbRlsMap->{$objectExtDbRls});


	my $ontologyRelationship =
	    GUS::Model::SRes::OntologyRelationship->new({
		subject_term_id   => $subjectTerm->getOntologyTermId(),
		predicate_term_id => $predicateTerm->getOntologyTermId(),
		object_term_id    => $objectTerm->getOntologyTermId(),
							});

	if ($self->getArg("verbose")) {
	  $self->log($relCount . ":" . Dumper($ontologyRelationship));
	}


	$ontologyRelationship->submit(undef, 1); # noTran = 1 --> do not commit at this point

	unless (++$relCount % 500) {
	  if ($self->getArg("commit")) {
	    $self->getDb()->manageTransaction(undef, "commit"); # commit
	    $self->getDb()->manageTransaction(undef, "begin");
	  }
	  $self->undefPointerCache();
	  $self->log("$relCount relationships loaded")
	    if $self->getArg('verbose');
	}
      }
  
    $self->getDb()->manageTransaction(undef, "commit")
      if ($self->getArg("commit")); # commit final batch
    
    $self->log("loaded $relCount relationships");

  }


sub retrieveOntologyTerm {

  my ($self, $term, $extDbRlsId) = @_;
  
  $self->log($term . " " . $extDbRlsId) if $self->getArg("verbose");

  my $ontologyTerm = GUS::Model::SRes::OntologyTerm->new({
    source_id                    => $term,
    external_database_release_id => $extDbRlsId,
  });

  unless ($ontologyTerm->retrieveFromDB()) { # try against name value
    $ontologyTerm = GUS::Model::SRes::OntologyTerm->new({
      name                         => $term,
      external_database_release_id => $extDbRlsId,
							});
  }

  unless ($ontologyTerm->retrieveFromDB()) {
    $self->log($term . ' not in db');
    $self->error("Term " . $term . "not in DB."); 
  }

  return $ontologyTerm;
}


sub undoTables {
  my ($self) = @_;

  return ('SRes.OntologyRelationship',
	 );
}
