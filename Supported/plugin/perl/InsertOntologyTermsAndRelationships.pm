package GUS::Supported::Plugin::InsertOntologyTermsAndRelationships;

@ISA = qw(GUS::PluginMgr::Plugin);

# ----------------------------------------------------------------------

use strict;

use GUS::PluginMgr::Plugin;
use GUS::PluginMgr::PluginUtilities;

use UNIVERSAL qw(isa);

use FileHandle;

use GUS::Model::SRes::OntologyTerm;
use GUS::Model::SRes::OntologyRelationship;
use GUS::Model::SRes::OntologySynonym;

use Data::Dumper;

my $argsDeclaration =
[

 fileArg({name           => 'inFile',
    descr          => 'A file of Representing Ontology Terms and Relationships.  Currently owl format is Supported.',
    reqd           => 1,
    mustExist      => 1,
    format         => 'rdf statements',
    constraintFunc => undef,
    isList         => 0, 
   }),


 stringArg({ descr => 'Name of the External Database',
       name  => 'extDbRlsSpec',
       isList    => 0,
       reqd  => 1,
       constraintFunc => undef,
     }),

 stringArg({ descr => 'Owl Reader Class',
       name  => 'owlReader',
       isList    => 0,
       reqd  => 0,
       constraintFunc => undef,
     }),


 stringArg({ descr => '',
       name  => 'relTypeExtDbRlsSpec',
       isList    => 0,
       reqd  => 1,
       constraintFunc => undef,
     }),
     enumArg({name => 'isPreferred',
                 descr => 'set the name and definition in ontologyterm; mark ontologysynonym as is_preferred; value must be either true or false',
                 reqd           => 0,
                 isList         => 0,
                 enum => "true,false",
    constraintFunc => undef,
               }),


];

my $purpose = <<PURPOSE;
The purpose of this plugin is to parse a an owl file (rdf; list of ontology statements) and load as Ontology Terms and Relationships.  
PURPOSE

my $purposeBrief = <<PURPOSE_BRIEF;
The purpose of this plugin is to load Ontology Terms and Relationships.
PURPOSE_BRIEF

my $notes = <<NOTES;
Only load subclassOf relations
NOTES

my $tablesAffected = <<TABLES_AFFECTED;
SRes::OntologyTerm, SRes::OntologyRelationship
TABLES_AFFECTED

my $tablesDependedOn = <<TABLES_DEPENDED_ON;
SRes.OntologyTermType, SRes::OntologyRelationShipType
TABLES_DEPENDED_ON

my $howToRestart = <<RESTART;
No Restart utilities for this plugin.
RESTART

my $failureCases = <<FAIL_CASES;
FAIL_CASES

my $documentation = { purpose          => $purpose,
          purposeBrief     => $purposeBrief,
          notes            => $notes,
          tablesAffected   => $tablesAffected,
          tablesDependedOn => $tablesDependedOn,
          howToRestart     => $howToRestart,
          failureCases     => $failureCases };

my $numRelationships = 0;

# ----------------------------------------------------------------------

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  $self->initialize({ requiredDbVersion => 4.0,
          cvsRevision       => '$Revision$',
          name              => ref($self),
          argsDeclaration   => $argsDeclaration,
          documentation     => $documentation});

  return $self;
}

# ----------------------------------------------------------------------

sub getExtDbRls {$_[0]->{ext_db_rls_id}}
sub setExtDbRls {$_[0]->{ext_db_rls_id} = $_[1]}

# ----------------------------------------------------------------------

=head2 Subroutines

=over 4

=item C<run>

Main method which Reads in the Owl File,
Converts to SRes::OntologyTerm and SRes::OntologyRelationships

B<Return type:> 

 C<string> Descriptive statement of how many rows were entered

=cut

sub run {
  my ($self) = @_;

  my $file = $self->getArg('inFile');
  
  my $extDbRlsId = $self->getExtDbRlsId($self->getArg('extDbRlsSpec'));
  $self->setExtDbRls($extDbRlsId);
  my $owlReaderClass = $self->getArg('owlReader') || "ApiCommonData::Load::OwlReader";
  $self->log("Loading $file using $owlReaderClass");
  eval "require $owlReaderClass";
  if($@){ die "Cannot load $owlReaderClass: $@";}
  my $owlReader = $owlReaderClass->new($file);
  die "Cannot use $owlReaderClass" unless $owlReader;
  my $termIds = $self->doTerms($owlReader);
  
  my $termCount = keys %$termIds;
  $self->undefPointerCache();
  $self->log("Inserted ", $termCount, " SRes::OntologyTerms");

  my $relationshipTypes = $self->getRelationshipTypes();

  my $relationships = $self->doRelationships($termIds, $owlReader, $relationshipTypes);
  $self->submitObjectList($relationships);

  my $relationshipCount = scalar(@$relationships);

  return "Inserted $termCount SRes::OntologyTerms and $relationshipCount SRes::OntologyRelationships";
}

#--------------------------------------------------------------------------------

=item C<readFile>

Opens the out file and reads ALL lines into an arrayref. (Chomps off the newline chars)

B<Parameters:>

 $fn(string): full path to the .out file

B<Return Type:> 

 C<ARRAYREF> Each element is a file line

=cut

sub readFile {
  my ($self, $fn) = @_;

  open(FILE, "< $fn") or $self->error("Could Not open file $fn for reading: $!");

  my @lines;

  <FILE>; #remove the header

  while(<FILE>) {
    chomp;

    push(@lines, $_);
  }
  close(FILE);

  return \@lines;
}

#--------------------------------------------------------------------------------

=item C<doTerms>

Loops through an array ref.  Each element of the array is split into 6 elements
ID      Name    Definition      Synonyms        URI     is obsolete

B<Parameters:>

 $lines(ARRAYREF): list of the file lines
 $termTypes(HASHREF): hash linking the ontology term types to their ids

B<Return Type:> 

 C<[GUS::Model::SRes::OntologyTerm]> ArrayRef of SRes.OntologyTerms

=cut

sub doTerms {
  my ($self, $owlReader) = @_;

  my $extDbRlsId = $self->getExtDbRls();

  my %seen;

  my $isPreferred = $self->getArg('isPreferred') eq 'true' ? 1 : 0;

  my $terms = $owlReader->getTerms();
  # my $displayOrder = $owlReader->getDisplayOrder();
  # my $variable = $owlReader->getVariable();

  my %termIds;
  foreach my $term (@$terms) {
    my $sourceId = $term->{sid};
    my $name = $term->{name};
    my $isObsolete = $term->{obs};

    next if($seen{$sourceId}); # in case there are dups
    $seen{$sourceId} = 1;
    next if($isObsolete eq 'true');
    next unless($name && uc($name) ne "NULL");

    my $definition;
    if(ref $term->{def} eq 'ARRAY'){
      $definition = join(",",@{$term->{def}});
    }
    else{
      $definition = $term->{def};
    }
    my $uri = $term->{uri};
      
    my $length = length($name);
    if ($length > 400) {
      $name = substr($name,0,397) . "...";
      print STDERR "Term $name was $length chars, truncated to 400\n";
    }

    $length = length($definition); 
    if ($length > 2000) {
      $definition = substr($definition,0,2000) . " ...";
      print STDERR "Definiton for term $name was $length chars, trucated to 2000\n";
    }

    my $ontologyTerm = GUS::Model::SRes::OntologyTerm->new({source_id => $sourceId});

    if($ontologyTerm->retrieveFromDB()) {

      if($isPreferred) {
        my $dbName = $ontologyTerm->getName();
        my $dbDef = $ontologyTerm->getDefinition();

        # GUS does not allow name to be null
        $name ||= "NULL";
        $ontologyTerm->setName($name);
        $ontologyTerm->setDefinition($definition);
        print STDERR "updated term and Definition for $sourceId: $dbName to $name and $dbDef to $definition\n" if($dbName ne $name || $dbDef ne $definition);
      }
    }
    else {
      $ontologyTerm->setName($name);
      $ontologyTerm->setUri($uri);
      $ontologyTerm->setDefinition($definition);
    }
    # $variable->{$sourceId} =~ s/^(.{1495}).+$/$1.../; # max field size 1500 chars
    # if($displayOrder->{$sourceId} =~ /NA/i) { delete($displayOrder->{$sourceId}) }
    # my $ontologySynonym = GUS::Model::SRes::OntologySynonym->new({ontology_synonym => $name, definition => $definition, variable => $variable->{$sourceId}, external_database_release_id => $extDbRlsId, display_order => $displayOrder->{$sourceId}});
    my $ontologySynonym = GUS::Model::SRes::OntologySynonym->new({ontology_synonym => $name, definition => $definition, external_database_release_id => $extDbRlsId});
    $ontologySynonym->setParent($ontologyTerm);
    $ontologySynonym->setIsPreferred(1) if($isPreferred);

    # my @synArr = split(/,/, $synonyms);
    # for (my $i=0; $i<@synArr; $i++) {
    #   $synArr[$i] =~ s/^\s+|\s+$//g;
    #   my $ontologySynonym = GUS::Model::SRes::OntologySynonym->new({ontology_synonym => $synArr[$i], external_database_release_id => $extDbRls});  
    #   $ontologySynonym->setParent($ontologyTerm);
    # }

    $ontologyTerm->submit();
    $termIds{$ontologyTerm->getSourceId()}=$ontologyTerm->getId();
    $self->undefPointerCache();
  }

  return \%termIds;
}



#--------------------------------------------------------------------------------

=item C<doRelationships>

Loop through all the file lines and create the relationships. 

B<Parameters:>

 $terms([GUS::Model::SRes::OntologyTerm]) ArrayRef of Official Terms with definitions
 $lines(ARRAYREF): list of the relationship file lines
 $relationshipTypes(HASHREF): hash linking the ontology relationship types to their ids

B<Return Type:> 

 C<[GUS::Model::SRes::OntologyRelationship]>  ArrayRef of OntologyRelationships

=cut

sub doRelationships {
  my ($self, $termIds, $owlReader, $relationshipTypes) = @_;

  my @relationships;
  my $count = 0;

  my $extDbRlsId = $self->getExtDbRls();

  my $relationships = $owlReader->getRelationships();
  my $multifilters = $owlReader->getMultifilters();
  push(@{$relationships}, @{$multifilters});

  foreach my $triple (@$relationships) {
    my ($subject, $type, $object) = ($triple->{subject},$triple->{type}, $triple->{object});
    my $line = join(",", $subject, $type, $object);

    my $subjectTermId = $$termIds{$subject};
    my $objectTermId = $$termIds{$object};
    $objectTermId ||= $relationshipTypes->{$object};

    my $relationshipTypeId = $relationshipTypes->{$type};
    unless($relationshipTypeId) {
      $self->error("OntologyRelationshipType is Required at line: $line");
    }

    if($subjectTermId && $objectTermId) {
      my $relationship = GUS::Model::SRes::OntologyRelationship->
          new({subject_term_id => $subjectTermId,
               object_term_id => $objectTermId,
               predicate_term_id => $relationshipTypeId,
               external_database_release_id => $extDbRlsId
              });

      push(@relationships, $relationship);
      $self->undefPointerCache();

      $count++;
      if($count % 250 == 0) {
        $self->log("Inserted $count SRes::OntologyRelationships");
      }
    }
    else {
      $self->log("Skipped Relationship $line");
    }
  }
  $self->log("Inserted $count SRes::OntologyRelationships");

  return \@relationships;
}

#--------------------------------------------------------------------------------

=item C<getTermIdFromSourceId>

Helper method which loops through an array of SRes::OntologyTerms and returns its id (undef if not found)

B<Parameters:>

 $terms([GUS::Model::SRes::OntologyTerm]) ArrayRef of Official Terms with definitions
 $wantedName(scalar): Term that you want

B<Return Type:> 

 C<scalar>  SRes::ontologyTerm ID

=cut


sub getTermIdFromSourceId {
  my ($self, $terms, $wanted) = @_;

  foreach my $term (@$terms) {
    my $sourceId = $term->getSourceId();

    if($sourceId eq $wanted) {
      return $term->getId();
    }
  }
  return undef;
}


#--------------------------------------------------------------------------------

=item C<getRelationshipTypes>

Prepare and Execute an sql statment.  The key is the first value in the 
result, the value is the second value in the result;

B<Parameters:>

 $sql(scalar): Any sql statment can be used... Here used to map ontology[term|relationship] types to their ids

B<Return Type:> 

 C<HASHREF> 

=cut

sub getRelationshipTypes {
  my ($self, $sql) = @_;

  my %rv;

  my $extDbRlsId = $self->getExtDbRlsId($self->getArg('relTypeExtDbRlsSpec'));

	$sql ||= "SELECT ot.name,ot.source_id,ot.ONTOLOGY_TERM_ID FROM sres.ontologyterm ot
LEFT JOIN sres.EXTERNALDATABASERELEASE edr ON ot.EXTERNAL_DATABASE_RELEASE_ID=edr.EXTERNAL_DATABASE_RELEASE_ID
LEFT JOIN sres.EXTERNALDATABASE ed ON edr.external_database_id=ed.EXTERNAL_DATABASE_ID
WHERE ed.name='Ontology_Relationship_Types_RSRC'";

  my $sh = $self->getQueryHandle()->prepare($sql);
  $sh->execute();

  while(my ($name, $sourceId, $id) = $sh->fetchrow_array()) {
    $rv{$sourceId} = $id;
  }
  $sh->finish();

  return \%rv;
}

#--------------------------------------------------------------------------------

sub submitObjectList {
  my ($self, $list) = @_;

  foreach my $gusObj (@$list) {
    $gusObj->submit();
  }

}

#--------------------------------------------------------------------------------

sub undoTables {
  my ($self) = @_;

  return ('SRes.OntologyRelationship', 'SRes.OntologySynonym');
}

1;
