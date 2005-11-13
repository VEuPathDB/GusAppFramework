package GUS::Supported::Plugin::InsertOntologyTermsAndRelationships;

@ISA = qw(GUS::PluginMgr::Plugin);

# ----------------------------------------------------------------------

use strict;

use GUS::PluginMgr::Plugin;
use GUS::PluginMgr::PluginUtilities;

use XML::LibXML;
use FileHandle;

use GUS::Model::SRes::OntologyTerm;
use GUS::Model::SRes::OntologyRelationship;

my $argsDeclaration =
[

 fileArg({name           => 'inFile',
	  descr          => 'A daml file of MGED Ontology Terms and Relationships',
	  reqd           => 1,
	  mustExist      => 1,
	  format         => 'daml',
	  constraintFunc => undef,
	  isList         => 0, 
	 }),


 stringArg({ descr => 'Name of the External Database',
	     name  => 'extDbName',
	     isList    => 0,
	     reqd  => 1,
	     constraintFunc => undef,
	   }),

 stringArg({ descr => 'Version of the External Database Release',
	     name  => 'extDbVersion',
	     isList    => 0,
	     reqd  => 1,
	     constraintFunc => undef,
	   }),

 stringArg({ descr => 'uri for the MGED Ontlogy',
	     name  => 'uri',
	     isList    => 0,
	     reqd  => 0,
	     default => "http://mged.sourceforge.net/ontologies/MGEDontology.php",
	     constraintFunc => undef,
	   }),

];

my $purpose = <<PURPOSE;
The purpose of this plugin is to load Ontology Terms and Relationships.
PURPOSE

my $purposeBrief = <<PURPOSE_BRIEF;
The purpose of this plugin is to load Ontology Terms and Relationships.
PURPOSE_BRIEF

my $notes = <<NOTES;
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

  $self->initialize({ requiredDbVersion => 3.5,
		      cvsRevision       => '$Revision$',
		      name              => ref($self),
		      argsDeclaration   => $argsDeclaration,
		      documentation     => $documentation});

  return $self;
}

# ======================================================================

sub run {
  my ($self) = @_;

  my $file = $self->getArgs()->{inFile};
  my $parser = XML::LibXML->new();

  my $tree = $parser->parse_file($file);
  my $root = $tree->getDocumentElement;

  my $numTerms = $self->_makeTerms($root);
  $self->_makeRelationships($root);

  print "Loaded $numTerms Terms into SRes::OntologyTerm and
         $numRelationships into SRes::OntologyRelationship\n";

}

# ----------------------------------------------------------------------
=pod

=head2 Subroutines

=over 4

=item C<_makeTerms >

Terms are parsed out of xml Tree.  

B<Parameters:>

$root(XML::LibXML::Element): The root node of the Document. 

B<Return type:> C<int> 

Number of Rows Loaded into SRes::OntologyTerms

=cut

sub _makeTerms {
  my ($self, $root) = @_;

  my (%terms, $numTermsLoaded);

  my $termTypes = ['Class', 'ObjectProperty', 'DatatypeProperty'];

  foreach my $type (@$termTypes) {
    my $terms = $self->_getTermsFromNodes($type, $root);
    $numTermsLoaded = $self->_loadTerms($type, $terms) + $numTermsLoaded;
  }

  my $type = 'UniqueProperty';
  my $upTerms = $self->_getUniquePropertyTerms($root);
  $numTermsLoaded = $self->_loadTerms($type, $upTerms) + $numTermsLoaded;

  $type = 'Instance';
  my $attrTerms = $self->_getTermsFromDescription($root);
  $numTermsLoaded = $self->_loadTerms($type, $attrTerms) + $numTermsLoaded;

  return($numTermsLoaded);
}

# ----------------------------------------------------------------------

=pod

=item C<_getTermsFromNodes>

Extract Term and Def from a node Type.  Looks at 'type' (node Name)
and gets the label (term) and comment (def) values.

B<Parameters:>

$type(string): Node Name ("daml:" Will be appended)
$root(XML::LibXML::Element): The root node of the Document. 

B<Return type:> C<hashRef> 

key=term, value=def

=cut

sub _getTermsFromNodes {
  my ($self, $type, $root) = @_;

  $type = "daml:".$type;

  my %rv;

  foreach my $node ($root->findnodes($type)) {
    my $term = $node->findvalue('rdfs:label');
    my $def = $node->findvalue('rdfs:comment');

    $rv{$term} = $def if($term);
  }
  return(\%rv);
}

# ----------------------------------------------------------------------

=pod

=item C<_getUniquePropertyTerms>

Unique Property terms have no Def.  Extract from Nodes...

B<Parameters:>

$type(string): Node Name ("daml:" Will be appended)
$root(XML::LibXML::Element): The root node of the Document. 

B<Return type:> C<hashRef> 

key=term, value=def

=cut

sub _getUniquePropertyTerms {
  my ($self, $root) = @_;

  my %terms;

  foreach my $up ($root->findnodes('daml:UniqueProperty')) {
    my $term = $up->getAttribute('about');
    $term = $self->_nameFromHtml($term);

    $terms{$term} = '';
  }
  return(\%terms);
}

# ----------------------------------------------------------------------

=pod

=item C<_getTermsFromDescription>

Extract Term and Def from 'Description' Node.  Looks at 
Description 'about' attrite for term and 'rdfs:comment' value
for the def.  Also handles ns0 terms 'human_read' and 'machine_read'

B<Parameters:>

$root(XML::LibXML::Element): The root node of the Document. 

B<Return type:> C<hashRef> 

key=term, value=def (in the case of ns0 terms there is no def)

=cut

sub _getTermsFromDescription {
  my ($self, $root) = @_;

  my (%terms);

  foreach my $desc ($root->findnodes('rdf:Description')) {
    my $term =  $desc->getAttribute('about');
    $term = $self->_nameFromHtml($term);

    # Remove newline chars from def
    my $def = $desc->findvalue('rdfs:comment');

    $terms{$term} = $def;

    foreach my $hr ($desc->findnodes('ns0:has_human_readable_URI')) {
      foreach my $xsd ($hr->findnodes('xsd:string')) {
	my $attr = $xsd->getAttribute('value');
	$terms{$attr} = '';
      }
    }
    foreach my $hr ($desc->findnodes('ns0:has_machine_readable_URI')) {
      foreach my $xsd ($hr->findnodes('xsd:string')) {
	my $attr = $xsd->getAttribute('value');
	$terms{$attr} = '';
      }
    }
  }
  return(\%terms);
}

# ----------------------------------------------------------------------

=pod

=item C<_loadTerms>

Given terms, def, and type, load terms into SRes::OntologyTerm Table.  

B<Parameters:>

$type(string): Sres.OntologyTermType.name
$root(XML::LibXML::Element): The root node of the Document. 

B<Return type:> C<int> 

number of rows loaded

=cut

sub _loadTerms {
  my ($self, $type, $termsHashRef) = @_;

  my $num = 0;

  my $uriArg = $self->getArgs()->{uri};

  my $dbReleaseId = $self->getExtDbRlsId($self->getArgs()->{extDbName}, 
					 $self->getArgs()->{extDbVersion});

  my $sh = $self->getQueryHandle()->prepare("SELECT ontology_term_type_id 
                                              FROM SRes.OntologyTermType 
                                                 WHERE name='$type'");
  $sh->execute ();

  if(my ($termTypeId) = $ sh->fetchrow_array()) {
    foreach my $term (keys %$termsHashRef) {
      my $uri = $uriArg.'#'.$term;

      my $def = $termsHashRef->{$term};
      $def =~ s/\n//g;

      print STDERR "Inserting:  SourceID #$term\n";

      my $ontologyTerm = GUS::Model::SRes::OntologyTerm->
	new({ ontology_term_type_id => $termTypeId,
	      external_database_release_id => $dbReleaseId,
	      source_id => '#'.$term,
	      uri => $uri,
	      name => $term,
	      definition => $def,
	    });

      $ontologyTerm->submit();
      $num++;
    }
  }
  else {
    die "Term of Type $type not Defined: $!";
  }
  return($num);
}

# ----------------------------------------------------------------------

=pod

=item C<_makeRelationships>

Parse Relationship data from root node.

B<Parameters:>

$root(XML::LibXML::Element): The root node of the Document. 

B<Return type:> C<?> 

=cut

sub _makeRelationships {
  my ($self, $root) = @_;

  my $ontologyIds = $self->_getOntologyTermIds();

  foreach my $class ($root->findnodes('daml:Class')) {
    my $className = $class->getAttribute('about');
    $className = $self->_nameFromHtml($className);

    $self->_doClassData($class, $className, $ontologyIds);
  }

  foreach my $objectProperty ($root->findnodes('daml:ObjectProperty')) {
    my $opName = $objectProperty->getAttribute('about');
    $opName = $self->_nameFromHtml($opName);

    $self->_doObjectPropertyData($objectProperty, $opName, $ontologyIds);
  }

  foreach my $description ($root->findnodes('rdf:Description')) {
    my $descName = $description->getAttribute('about');
    $descName = $self->_nameFromHtml($descName);

    $self->_doInstanceData($description, $descName, $ontologyIds);
  }
}

# ----------------------------------------------------------------------

=pod

=item C<_doClassData>

Recursive Search through Class Nodes for certain nodes. 
Will then call methods to load data from those.

B<Parameters:>

$node(XML::LibXML::Element): The node to be searched
$className(string):  Name of the 'root' Class Node

B<Return type:> C<boolean> 

has Child Nodes

=cut

sub _doClassData {
  my ($self, $node, $className, $ontologyIds) = @_;

  if(!$node->hasChildNodes()) {
    return(0);
  }

  if($node->nodeName eq 'rdfs:subClassOf') {
    $self->_parseAndLoadSubClasses($node, $className, $ontologyIds);
  }

  if($node->nodeName eq 'daml:Restriction') {
    $self->_parseAndLoadHasClasses($node, $className, $ontologyIds);
  }

  if($node->nodeName eq 'daml:first' || $node->nodeName eq 'daml:rest') {
    $self->_parseAndLoadThings($node, $className, $ontologyIds);
  }

  # Recurse throught the nodes
  foreach my $child ($node->childNodes) {
    $self->_doClassData($child, $className, $ontologyIds);
  }
  return(1);
}


# ----------------------------------------------------------------------

=pod

=item C<_parseAndLoadSubClasses>

Parse Relationship of type 'subClassOf' 

B<Parameters:>

$node(XML::LibXML::Element): The node of interest.
$className(string):  Name of the Class Node

B<Return type:> C<void> 

=cut


sub _parseAndLoadSubClasses {
  my ($self, $node, $className, $ontologyIds) = @_;

  my $relationshipType = 'subClassOf';

  my @subClasses =  $node->findnodes('daml:Class');

  foreach(@subClasses) {
    my $superClass = $_->getAttribute('about');
    $superClass = $self->_nameFromHtml($superClass);

    $self->_loadRelationship($className, '', $superClass, $relationshipType, $ontologyIds);
  }
}

# ----------------------------------------------------------------------

=pod

=item C<_parseAndLoadHasClasses>

Parse Relationship of type 'hasDatatype' or 'subClassOf'

B<Parameters:>

$node(XML::LibXML::Element): The node of interest.
$className(string):  Name of the Class Node

B<Return type:> C<void> 

=cut

sub _parseAndLoadHasClasses {
  my ($self, $node, $className, $ontologyIds) = @_;

  my $relationshipType;

  my $onProperty =  $node->findnodes('daml:onProperty');
  my $hasClass =  $node->findnodes('daml:hasClass');

  if(scalar @$onProperty != scalar @$hasClass) {
    die "Multiple props or subclasses\n";
  }

  foreach(my $i = 0; $i < length @$hasClass; $i++) {
    my $property = $onProperty->[$i]->getAttribute('resource');
    $property = $self->_nameFromHtml($property);

    if(my $resource = $hasClass->[$i]->getAttribute('resource')) {
      $relationshipType = 'hasDatatype';

      $self->_loadRelationship($className, $property, 'string', $relationshipType, $ontologyIds);
    }
    else {
      $relationshipType = 'hasClass';

      foreach($hasClass->[$i]->findnodes('daml:Class')) {
	my $filler = $_->getAttribute('about');
	$filler = $self->_nameFromHtml($filler);

	if($filler) {
	  $self->_loadRelationship($className, $property, $filler, $relationshipType, $ontologyIds);
	}
      }
    }
  }
}

# ----------------------------------------------------------------------

=pod

=item C<_parseAndLoadThings>

Parse Relationship of type 'oneOf' 

B<Parameters:>

$node(XML::LibXML::Element): The node of interest.
$className(string):  Name of the Class Node

B<Return type:> C<void> 

=cut

sub _parseAndLoadThings {
  my ($self, $node, $className, $ontologyIds) = @_;

  my @resources;

  my $relationshipType = 'oneOf';

  my @things = $node->childNodes();
  foreach(@things) {
    if($_->hasAttributes()) {
      my $resource;

      my $filler = $_->getAttribute('about');
      $filler = $self->_nameFromHtml($filler);

      my $parent = $node->parentNode();
      while($parent->nodeName ne 'daml:Restriction') {
	$parent = $parent->parentNode();
      }

      foreach($parent->findnodes('daml:onProperty')) {
	push(@resources, $_->getAttribute('resource'));
	if(scalar @resources > 1) {
	  die "Multiple onProps for $className";
	}

	$resources[0] = $self->_nameFromHtml($resources[0]);
      }
      $self->_loadRelationship($className, $resources[0], $filler, $relationshipType, $ontologyIds);
    }
  }
}

# ----------------------------------------------------------------------

=pod

=item C<_doObjectPropertyData>

Parse Relationship of type 'domain' 

B<Parameters:>

$node(XML::LibXML::Element): The node of interest.
$opName(string):  Name of the onProp

B<Return type:> C<void> 

=cut

sub _doObjectPropertyData {
  my ($self, $objectProperty, $opName, $ontologyIds) = @_;

  my $relationshipType = 'domain';

  my $tmp = $objectProperty->getAttribute('about');
  my ($junk, $label) = split('#', $tmp);

  foreach my $node ($objectProperty->findnodes('rdfs:domain')) {
    foreach my $class ($node->findnodes('daml:Class')) {
      my $domain = $class->getAttribute('about');
      $domain = $self->_nameFromHtml($domain);

      $self->_loadRelationship($opName, '', $domain, $relationshipType, $ontologyIds);
    }
  }
}

# ----------------------------------------------------------------------

=pod

=item C<_doInstanceData>

Parse Relationship of type 'instanceOf' or 'hasInstance'

B<Parameters:>

$desc(XML::LibXML::Element): The node of interest.
$descName(string):  Name of the Class Node

B<Return type:> C<void> 

=cut

sub _doInstanceData {
  my ($self, $description, $descName, $ontologyIds) = @_;

  my $relationshipType = 'instanceOf';

  foreach my $node ($description->findnodes('rdf:type')) {
    foreach my $class ($node->findnodes('daml:Class')) {
      my $inst = $class->getAttribute('about');
      $inst = $self->_nameFromHtml($inst);

      $self->_loadRelationship($descName, '', $inst, $relationshipType, $ontologyIds);
    }
  }

  $relationshipType = 'hasInstance';

  foreach my $node ($description->childNodes) {
    if($node->nodeName =~ /^ns/ && $node->hasAttributes()) {
      my $resource = $node->getAttribute('resource');
      $resource = $self->_nameFromHtml($resource);

      my $prop = $self->_nameFromHtml($node->nodeName, ":");
      $self->_loadRelationship($descName, $prop, $resource, $relationshipType, $ontologyIds);
    }
    elsif($node->nodeName =~ /^ns/ && !$node->hasAttributes())  {
      foreach my $humRead ($node->findnodes('xsd:string')) {
	my $prop = $self->_nameFromHtml($humRead->parentNode->nodeName, ":");

	my $inst = $humRead->getAttribute('value');
	$self->_loadRelationship($descName, $prop, $inst, $relationshipType, $ontologyIds);
      }
    }
    else {}
  }
}

# ----------------------------------------------------------------------


sub _loadRelationship {
  my ($self, $subject, $predicate, $object, $relType, $ontologyIds) = @_;

  my $sh = $self->getQueryHandle->prepare("SELECT ontology_relationship_type_id 
                                            FROM SRes.OntologyRelationshiptype
                                             WHERE name = '$relType'");
  $sh->execute ();

  if(my ($relTypeId) = $sh->fetchrow_array()) {

    print STDERR  "Inserting:  $subject\n";

    my $ontologyRelationship = GUS::Model::SRes::OntologyRelationship->
      new({ subject_term_id => $ontologyIds->{$subject},
	    predicate_term_id => $ontologyIds->{$predicate},
	    object_term_id => $ontologyIds->{$object},
	    ontology_relationship_type_id => $relTypeId,
	  });

    $ontologyRelationship->submit();
    $numRelationships++; #global var
  }
  else {
    die "No RelationshipType Id for $relType: $!";
  }
}


# ----------------------------------------------------------------------

sub _getOntologyTermIds {
  my ($self) = @_;


  my $dbReleaseId = $self->getExtDbRlsId($self->getArgs()->{extDbName}, 
					 $self->getArgs()->{extDbVersion});

  my $sh = $self->getQueryHandle->prepare("SELECT ontology_term_id, name 
                                            FROM SRes.OntologyTerm 
                                             WHERE external_database_release_id = $dbReleaseId");
  $sh->execute ();
  my $rowcount = 0;

  my %rv;

  while(my ($id, $name) = $sh->fetchrow_array ())  {
    $rowcount++;
    $rv{$name} = $id;
  }
  $sh->finish ();

  if(!$rowcount) {
    die "No Ontology Terms Found:$!";
  }

  return(\%rv);
}


# ----------------------------------------------------------------------

=pod

=item C<_nameFromHtml>

Splits the 'junk' out of a html attribute.  The last value is retained.

B<Parameters:>

$string(string): String to be split
$char(char):  Character to do the splitting.  Defaults to '#' if none provided.

B<Return type:> C<string>

Last value in the array after splitting. 

=cut

sub _nameFromHtml {
  my ($self, $string, $char) = @_;

  if(!$char) {
    $char = '#';
  }
  my @ar = split($char, $string);

  return($ar[scalar(@ar) - 1]);
}

1;
