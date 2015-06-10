##
## InsertOntologyFromTabDelim Plugin
## $Id: InsertOntologyFromTabDelim.pm manduchi $
##

package GUS::Supported::Plugin::InsertOntologyFromTabDelim;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
use IO::File;
use CBIL::Util::Disp;
use GUS::PluginMgr::Plugin;

use GUS::Model::SRes::OntologyTerm;
use GUS::Model::SRes::OntologySynonym;
use GUS::Model::SRes::OntologyRelationship;

# ----------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------

sub getArgumentsDeclaration {
  my $argumentDeclaration  =
    [
     fileArg({name => 'termFile',
	      descr => 'The full path of the file containing the ontology terms. .',
	      constraintFunc=> undef,
	      reqd  => 1,
	      isList => 0,
	      mustExist => 1,
	      format => 'See the NOTES for the format of this file'
	     }),
     fileArg({name => 'relFile',
	      descr => 'The full path of the file containing the relationships. .',
	      constraintFunc=> undef,
	      reqd  => 0,
	      isList => 0,
	      mustExist => 1,
	      format => 'See the NOTES for the format of this file'
	     }),
     stringArg({ name  => 'extDbRlsSpec',
		  descr => "The ExternalDBRelease specifier for this Ontology. Must be in the format 'name|version', where the name must match an name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
		  constraintFunc => undef,
		  reqd           => 1,
		  isList         => 0 }),
     stringArg({ name  => 'relTypeExtDbRlsSpec',
		  descr => "The ExternalDBRelease specifier for the relationship types. Must be in the format 'name|version', where the name must match an name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
		  constraintFunc => undef,
		  reqd           => 0,
		  isList         => 0 }),
 booleanArg({name => 'hasHeader',
             descr => 'do the input files have a header row?',
reqd => 0
            }),



    ];
  return $argumentDeclaration;
}

# ----------------------------------------------------------------------
# Documentation
# ----------------------------------------------------------------------


sub getDocumentation {
  my $purposeBrief = 'Loads data from two tab-delimited text files into the tables OntologyTerm, OntologySynonym and OntologyRelationship in SRes.';

  my $purpose = "This plugin populates the Ontology tables in SRes.";

  my $tablesAffected = [['SRes::OntologyTerm', 'Enters a row for each term'], ['SRes::OntologySynomym', 'Enters rows linking each entered term to its Synonyms'], ['SRes::OntologyRelationship', 'Links related terms']];

  my $tablesDependedOn = [['SRes::ExternalDatabaseRelease', 'The release of the Ontology']];

  my $howToRestart = "No restart. Delete entries (can use Undo.pm) and rerun.";

  my $failureCases = "";

  my $notes = "

=head1 AUTHOR

Written by Elisabetta Manduchi.

=head1 COPYRIGHT

Copyright Elisabetta Manduchi, Trustees of University of Pennsylvania 2012.

=head1 Ontology Term File Format

Tab delimited text file with the following header (order matters): id, name, def, synonyms (comma-separated), uri, is_obsolete [true/false]

=head1 Relationship File Format

A 3-column file with: subject_term_child, relationship_id, object_term_id 
The ids should match those listed in the Ontology Term File.

";

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

  $self->initialize({requiredDbVersion => 4.0,
		     cvsRevision => '$Revision$',
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

  $self->logAlgInvocationId();
  $self->logCommit();
  $self->logArgs();

  my $termFile = $self->getArg('termFile');

  my $extDbRls = $self->getExtDbRlsId($self->getArg('extDbRlsSpec'));
  my $relFile = $self->getArg('relFile');

  my $resultDescr = $self->insertTerms($termFile, $extDbRls);
  if ($relFile) {
    $resultDescr .= $self->insertRelationships($relFile, $extDbRls);
  }

  $self->setResultDescr($resultDescr);
  $self->logData($resultDescr);
}

# ----------------------------------------------------------------------
# methods called by run
# ----------------------------------------------------------------------

sub insertTerms {
  my ($self, $file, $extDbRls) = @_;  
  my $fh = IO::File->new("<$file");
  my $countTerms = 0;
  my $countSyns = 0;

  my $line = <$fh> if($self->getArg('hasHeader'));
  while ($line=<$fh>) {
    chomp($line);
    my ($id, $name, $def, $synonyms, $uri, $isObsolete) = split(/\t/, $line);
    $isObsolete = $isObsolete eq 'false' ? 0 : 1;
    my $ontologyTerm = GUS::Model::SRes::OntologyTerm->new({name => $name, definition => $def, external_database_release_id => $extDbRls, source_id => $id, uri => $uri, is_obsolete => $isObsolete });   
    if (!$ontologyTerm->retrieveFromDB()) {
      $countTerms++;
    }
    my @synArr = split(/,/, $synonyms);
    for (my $i=0; $i<@synArr; $i++) {
      $synArr[$i] =~ s/^\s+|\s+$//g;
      my $ontologySynonym = GUS::Model::SRes::OntologySynonym->new({ontology_synonym => $synArr[$i], external_database_release_id => $extDbRls});  
      $ontologySynonym->setParent($ontologyTerm);
      if (!$ontologySynonym->retrieveFromDB()) {
	$countSyns++;
      }    
    }
    $ontologyTerm->submit();
    $self->undefPointerCache();
  }
  $fh->close();

  my $resultDescr = "Inserted $countTerms rows in SRes.OntologyTerm and $countSyns row in SRes.OntologySynonym";
  return ($resultDescr);
}

sub insertRelationships {
  my ($self, $file, $extDbRls) = @_;  
  my $fh = IO::File->new("<$file");
  my $countRels = 0;

  my $line = <$fh>  if($self->getArg('hasHeader'));
  while ($line=<$fh>) {
    chomp($line);
    my ($subjectId, $predicateId, $objectId, $relationshipTypeId) = split(/\t/, $line);
    
    my $subject = GUS::Model::SRes::OntologyTerm->new({external_database_release_id => $extDbRls, source_id => $subjectId});    
    if(!$subject->retrieveFromDB()) {
      $self->userError("Failure retrieving subject ontology term \"$subjectId\"");
    }

    my $predicate;
    if($predicateId) {
      $predicate = GUS::Model::SRes::OntologyTerm->new({external_database_release_id => $extDbRls, source_id => $predicateId});
      if(!$predicate->retrieveFromDB()) {
        $self->userError("Failure retrieving predicate ontology term \"$predicateId\"");
      }
    }

    my $object = GUS::Model::SRes::OntologyTerm->new({external_database_release_id => $extDbRls, source_id => $objectId});
    if(!$object->retrieveFromDB()) {
      $self->userError("Failure retrieving object ontology term \"$objectId\"");
    }

    my $relationshipType;
    if($relationshipTypeId) {

      my $relTypeExtDbRls = $self->getExtDbRlsId($self->getArg('relTypeExtDbRlsSpec'));
      $relationshipType = GUS::Model::SRes::OntologyTerm->new({external_database_release_id => $relTypeExtDbRls, source_id => $relationshipTypeId});
      if(!$relationshipType->retrieveFromDB()) {
        $self->userError("Failure retrieving relationshipType ontology term \"$relationshipTypeId\"");
      }
    }

    my $ontologyRelationship = GUS::Model::SRes::OntologyRelationship->new();   
    $ontologyRelationship->setSubjectTermId($subject->getId());
    $ontologyRelationship->setPredicateTermId($predicate->getId()) if($predicate); 
    $ontologyRelationship->setObjectTermId($object->getId());
    $ontologyRelationship->setOntologyRelationshipTypeId($relationshipType->getId());

    if (!$ontologyRelationship->retrieveFromDB()) {
      $countRels++;
    }
    $ontologyRelationship->submit();
    $self->undefPointerCache();
  }
  $fh->close();
  my $resultDescr = ". Inserted $countRels rows in SRes.OntologyRelationship";
  return ($resultDescr);
}

sub undoTables {
  my ($self) = @_;

  return ('SRes.OntologyRelationship', 'SRes.OntologySynonym', 'SRes.OntologyTerm');
}

1;
