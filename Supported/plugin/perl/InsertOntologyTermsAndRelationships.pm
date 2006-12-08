package GUS::Supported::Plugin::InsertOntologyTermsAndRelationships;

@ISA = qw(GUS::PluginMgr::Plugin);

# ----------------------------------------------------------------------

use strict;

use GUS::PluginMgr::Plugin;
use GUS::PluginMgr::PluginUtilities;

use UNIVERSAL qw(isa);

use XML::LibXML;
use FileHandle;

use Data::Dumper;

use GUS::Model::SRes::OntologyTerm;
use GUS::Model::SRes::OntologyRelationship;

my $argsDeclaration =
[

 fileArg({name           => 'inFile',
	  descr          => 'A file of MGED Ontology Terms and Relationships',
	  reqd           => 1,
	  mustExist      => 1,
	  format         => 'daml or owl',
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

 enumArg({  name => 'fileType',
	    descr => 'is this a daml or owl file',
	    constraintFunc => undef,
	    reqd => 1,
	    isList => 0,
	    enum => 'daml,owl'
	   }),


];

my $purpose = <<PURPOSE;
The purpose of this plugin is to parse a daml or owl file and load the resulting Ontology Terms and Relationships.  
PURPOSE

my $purposeBrief = <<PURPOSE_BRIEF;
The purpose of this plugin is to load Ontology Terms and Relationships.
PURPOSE_BRIEF

my $notes = <<NOTES;
This plugin depends on the perl module XML::LibXML.  May fail in non-commit mode...must have terms loaded to 
load Relationships. 
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

  my $ns = $self->getArg('fileType');

  if(!$self->getArgs->{commit}) {
    $self->log("WARNING:  To parse relationships must run with commit on.");
  }

  my $numTerms = $self->_makeTerms($root, $ns);
  $self->log("Finished Loading Terms...");

  if($ns eq 'daml') {
    $self->_makeRelationships($root, $ns);
  }
  elsif($ns eq 'owl') {
    $self->_makeOwlRelationships($root, $ns);
  }
  else {
    die "File of Type $ns not supported: $!";
  }

  return("Loaded $numTerms Terms into SRes::OntologyTerm and
         $numRelationships into SRes::OntologyRelationship");

}

# ----------------------------------------------------------------------
=pod

=head2 Subroutines

=over 4

=item C<_makeTerms >

Terms are parsed out of xml Tree.  

B<Parameters:>

$root(XML::LibXML::Element): The root node of the Document. 
$ns(scalar): The prefix of the NodeName (ie 'daml' or 'owl')

B<Return type:> C<int> 

Number of Rows Loaded into SRes::OntologyTerms

=cut

sub _makeTerms {
  my ($self, $root, $ns) = @_;

  my (%terms, $numTermsLoaded);

  # Make String and Thing First
  #------------------------------------------------------------------
  my $type = 'Datatype';
  my $string = {string => ''};
  $numTermsLoaded = $self->_loadTerms($type, $string) + $numTermsLoaded;

  $type = 'Root';
  my $thing = {Thing => ''};
  $numTermsLoaded = $self->_loadTerms($type, $thing) + $numTermsLoaded;
  #------------------------------------------------------------------

  my $terms;

  my $termTypes = ['Class', 'ObjectProperty', 'DatatypeProperty', 
                   'FunctionalProperty', 'UniqueProperty'];

  if($ns  eq 'owl') {
    push(@$termTypes, 'Individual', 'Thing');

    foreach my $type (@$termTypes) {
      $terms = $self->_getOwlTerms($root, $ns, $type);

      $type = 'Individual' if($type eq 'Thing');
      $numTermsLoaded = $self->_loadTerms($type, $terms) + $numTermsLoaded;
    }
  }
  elsif($ns eq 'daml') {
    foreach my $type (@$termTypes) {
      $terms = $self->_getTermsFromNodes($type, $root, $ns);
      $numTermsLoaded = $self->_loadTerms($type, $terms) + $numTermsLoaded;
    }

    $type = 'Individual';
    $terms = $self->_getTermsFromDescription($root);
    $numTermsLoaded = $self->_loadTerms($type, $terms) + $numTermsLoaded;
  }
  else {
    die "File of Type $ns not supported: $!";
  }

  return($numTermsLoaded);
}

# ----------------------------------------------------------------------

=pod

=item C<_getTermsFromNodes>

Extract Term and Def from a node Type.  Looks at 'type' (node Name)
and gets the label (term) and comment (def) values.

B<Parameters:>

$type(string): Node Name ("$ns:" Will be appended)
$root(XML::LibXML::Element): The root node of the Document. 
$ns(scalar): The prefix of the NodeName (ie 'daml' or 'owl')

B<Return type:> C<hashRef> 

key=term, value=def

=cut

sub _getTermsFromNodes {
  my ($self, $type, $root, $ns) = @_;

  my %rv;

  foreach my $node ($root->findnodes("$ns:$type")) {
    my $term;

    if(!($term = $node->getAttribute('ID'))) {
      $term = $node->getAttribute('about');
    }

    if($ns eq 'daml' && $type ne 'UniqueProperty') {
      $term = $node->findvalue('rdfs:label');
    }

    $term =~ s/#// if($ns eq 'owl');

    my $def = $node->findvalue('rdfs:comment');

    $rv{$term} = $def if($term);
  }
  return(\%rv);
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

=item C<_getOwlTerms>

Loops through ALL the Nodes in the Document.  Any Node with and 
Attribute of "ID" is considered a term.  Also, when looping through
the Individual types the URI's are gotten.

B<Parameters:>

$root(XML::LibXML::Element): The root node of the Document. 
$ns(string):  owl or daml
$type(string):  Essentially an SRes.OntologyTermType value

B<Return type:> C<hashRef> 

key=term, value=def (in the case of uri terms there is no def)

=cut

sub _getOwlTerms {
  my ($self, $root, $ns, $type) = @_;

  my %terms;

  # Loop through ALL Nodes
  foreach my $node ($root->findnodes('//*')) {
    my $term = $node->getAttribute('ID');
    $term = $node->getAttribute('about') if(!$term);
    $term = $self->_nameFromHtml($term);

    if($term && ($node->getName() eq "$ns:$type" || 
                 ($node->getName() !~ /^$ns:/ && $type eq 'Individual'))) {

      my $def = $node->findvalue('rdfs:comment');

      if($terms{$term} && $def && $terms{$term} ne $def) {
        print STDERR "Def1=$terms{$term}\nDef2=$def\n";
        die "Term Defs do not match form term $term" ;
      }
      elsif(!$terms{$term}) {
        $terms{$term} = $def;
      }
      elsif(!$def && $terms{$term}) {}
      else {
        die "def1=$terms{$term}\tdef2=$def\tterm=$term";
      }

    }

    my $nodeName = $node->nodeName;
    if($type eq 'Individual' && $nodeName =~ 'has_(human|machine)_readable_URI') {
      $term = $node->textContent;

      next unless $term;
      $terms{$term} = '';
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

  $self->log("Working on Loading terms of type: $type");

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
      my ($source, $uri) = $self->_getSourceAndUri($term, $uriArg);

      #Clean out the newline chars from def
      my $def = $termsHashRef->{$term};
      $def =~ s/\n//g;

      my $ontologyTerm = GUS::Model::SRes::OntologyTerm->
	new({ ontology_term_type_id => $termTypeId,
	      external_database_release_id => $dbReleaseId,
	      source_id => $source,
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

  $self->log("Inserted $num OntologyTerms of Type:  $type");

  return($num);
}

# ----------------------------------------------------------------------

sub _getSourceAndUri {
  my ($self, $term, $uriArg) = @_;

  my ($uri, $source);

  if($term =~ /^http:/ || $term =~ /^ftp:/) {
    $uri = '';
    $source = $term;
  }
  elsif($term eq 'string' || $term eq 'Thing') {
    $uri = '';
    $source = '#'.$term;
  }
  else {
    $uri = $uriArg.'#'.$term;
    $source =  '#'.$term;
  }

return($source, $uri);

}

# ----------------------------------------------------------------------

=pod

=item C<_makeRelationships>

Parse daml Relationship data from root node.

B<Parameters:>

$root(XML::LibXML::Element): The root node of the Document. 
$ns(string): The prefix of the NodeName (ie 'daml' or 'owl')

B<Return type:> C<void> 

=cut

sub _makeRelationships {
  my ($self, $root, $ns) = @_;

  my $ontologyIds = $self->_getOntologyTermIds();

  foreach my $class ($root->findnodes("$ns:Class")) {
    my $className = $class->getAttribute('about');
    $className = $self->_nameFromHtml($className);

    $self->_doClassData($class, $className, $ontologyIds, $ns);
  }

  foreach my $objectProperty ($root->findnodes("$ns:ObjectProperty")) {
    my $opName = $objectProperty->getAttribute('about');
    $opName = $self->_nameFromHtml($opName);

    $self->_doObjectPropertyData($objectProperty, $opName, $ontologyIds, $ns);
  }

  foreach my $description ($root->findnodes('rdf:Description')) {
    my $descName = $description->getAttribute('about');
    $descName = $self->_nameFromHtml($descName);

    $self->_doInstanceData($description, $descName, $ontologyIds, $ns);
  }
}

# ----------------------------------------------------------------------

=pod

=item C<_makeOwlRelationships>

Parse owl Relationship data from root node.

B<Parameters:>

$root(XML::LibXML::Element): The root node of the Document. 
$ns(scalar): The prefix of the NodeName (ie 'daml' or 'owl')

B<Return type:> C<void> 

=cut

sub _makeOwlRelationships {
  my ($self, $root, $ns) = @_;

  my $ontologyIds = $self->_getOntologyTermIds();

  foreach my $class ($root->findnodes("$ns:Class")) {
    my $className = $class->getAttribute('ID');
    $className = $class->getAttribute('about') if(!$className);

    $className = $self->_nameFromHtml($className);

    if(!$className) {
      print STDERR $class->toString()."\n";
      die "No Classname for above node: $!";
    }
    $self->_doClassData($class, $className, $ontologyIds, $ns);
  }

  foreach my $objectProperty ($root->findnodes("$ns:ObjectProperty")) {
    my $opName = $objectProperty->getAttribute('about');
    $opName = $objectProperty->getAttribute('ID') if(!$opName);

    $opName = $self->_nameFromHtml($opName);
    $self->_doObjectPropertyData($objectProperty, $opName, $ontologyIds, $ns);
  }

  foreach my $node ($root->findnodes('//*')) {
    next if($node->getName() =~ /^$ns:/ && $node->getName() !~ /^$ns:Thing/);

    my $nodeName = $node->getAttribute('ID');

    if($nodeName) {
      $self->_doOwlInstanceData($node, $nodeName, $ontologyIds, $ns);
    }
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
$ontologyIds(hashRef):  key=SRes.OntologyTerm.name, value=SRes.OntologyTerm.ontology_term_id
$ns(scalar): The prefix of the NodeName (ie 'daml' or 'owl')

B<Return type:> C<boolean> 

has Child Nodes

=cut

sub _doClassData {
  my ($self, $node, $className, $ontologyIds, $ns) = @_;

  if($node->nodeName eq 'rdfs:subClassOf') {
    $self->_parseAndLoadSubClasses($node, $className, $ontologyIds, $ns);
  }

  if($node->nodeName eq "$ns:Restriction") {
    $self->_parseAndLoadRestrictions($node, $className, $ontologyIds, $ns);
  }

  if($node->nodeName eq "$ns:first" || $node->nodeName eq "$ns:rest") {
    $self->_parseAndLoadThings($node, $className, $ontologyIds, $ns);
  }

  if(!$node->hasChildNodes()) {
    return(0);
  }

  # Recurse throught the nodes
  foreach my $child ($node->childNodes) {
    $self->_doClassData($child, $className, $ontologyIds, $ns);
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
$ontologyIds(hashRef):  key=SRes.OntologyTerm.name, value=SRes.OntologyTerm.ontology_term_id
$ns(scalar): The prefix of the NodeName (ie 'daml' or 'owl')

B<Return type:> C<void> 

=cut


sub _parseAndLoadSubClasses {
  my ($self, $node, $className, $ontologyIds, $ns) = @_;

  my $relationshipType = 'subClassOf';

  my @subClasses =  $node->findnodes("$ns:Class");

  foreach(@subClasses) {
    my $superClass = $_->getAttribute('about');
    $superClass = $_->getAttribute('ID') if(!$superClass);

    $superClass = $self->_nameFromHtml($superClass);
    $self->_loadRelationship($className, '', $superClass, $relationshipType, $ontologyIds);
  }

  # This is for the owl format
  if(my $resource = $node->getAttribute('resource')) {
    $resource = $self->_nameFromHtml($resource);
    $self->_loadRelationship($className, '', $resource, $relationshipType, $ontologyIds);
  }
}

# ----------------------------------------------------------------------

=pod

=item C<_parseAndLoadRestrictions>

Parse Relationship of type 'hasDatatype' or 'subClassOf'

B<Parameters:>

$node(XML::LibXML::Element): The node of interest.
$className(string):  Name of the Class Node
$ontologyIds(hashRef):  key=SRes.OntologyTerm.name, value=SRes.OntologyTerm.ontology_term_id
$ns(scalar): The prefix of the NodeName (ie 'daml' or 'owl')

B<Return type:> C<void> 

=cut

sub _parseAndLoadRestrictions {
  my ($self, $node, $className, $ontologyIds, $ns) = @_;

  my $relationshipType;

  my $onProperty =  $node->findnodes("$ns:onProperty");
  my $someValuesFrom = $node->findnodes("$ns:someValuesFrom");
  my $hasClass =  $node->findnodes("$ns:hasClass");

  my $numOnProperty = $onProperty->size();
  my $numSomeValuesFrom = $someValuesFrom->size();
  my $numHasClass = $hasClass->size();

  # The onProperties should be either someValuesFrom or hasClass
  if($numOnProperty != $numSomeValuesFrom && $numOnProperty != $numHasClass) {
    foreach my $node ($onProperty->get_nodelist()) {
      my $string = $node->toString();
      $string =~ s/\s//g;

      $self->log("WARN:  **** Skipping onProperty\n$string");

      my $parent = $node->parentNode();
      print STDERR $parent->toString . "\n" if($self->getArg('debug'));
    }
    return;
  }

  for(my $i = 0; $i < scalar(@$onProperty); $i++) {
    my $op = $onProperty->[$i];

    my $property = $op->getAttribute('resource');
    $property = $op->childNodes->[1]->getAttribute('about') if(!$property);
    $property = $op->childNodes->[1]->getAttribute('ID') if(!$property);

    $property = $self->_nameFromHtml($property);

    if($ns eq 'daml' && $hasClass->[$i]->getAttribute('resource')) {
      $relationshipType = 'hasDatatype';
      $self->_loadRelationship($className, $property, 'string', $relationshipType, $ontologyIds);
    }
    elsif($ns eq 'daml') {
      $relationshipType = 'hasClass';
      foreach($hasClass->[$i]->findnodes("$ns:Class")) {
        if(my $filler = $_->getAttribute('about')) {
          $filler = $self->_nameFromHtml($filler);
          $self->_loadRelationship($className, $property, $filler, $relationshipType, $ontologyIds);
        }
      }
    }
    elsif($ns eq 'owl') {
      my $filler;

      if($op->childNodes->[1]->nodeName =~ /owl:DatatypeProperty/) {
        $relationshipType = 'hasDatatype';
      }
      else {
        $relationshipType = 'someValuesFrom';
      }

      unless ($filler = $someValuesFrom->[$i]->getAttribute('resource')) {
        foreach($someValuesFrom->[$i]->findnodes("$ns:Class")) {
          if($_->hasChildNodes) {
            $self->_parseAndLoadOwlThings($_, $property, $className, $ontologyIds, $ns );
          }
          $filler = $_->getAttribute('ID');
          $filler = $_->getAttribute('about') if(!$filler);
        }
      }
      if($filler = $self->_nameFromHtml($filler)) {
        $self->_loadRelationship($className, $property, $filler, $relationshipType, $ontologyIds);
      }
    }
    else {
      die "File of Type $ns not supported: $!";
    }
  }
}

# ----------------------------------------------------------------------

=pod

=item C<_parseAndLoadThings>

Parse Relationship of type 'oneOf' from owl format

B<Parameters:>

$node(XML::LibXML::Element): The node of interest.
$className(string):  Name of the Class Node
$ontologyIds(hashRef):  key=SRes.OntologyTerm.name, value=SRes.OntologyTerm.ontology_term_id
$ns(scalar): The prefix of the NodeName (ie 'daml' or 'owl')

B<Return type:> C<void> 

=cut

sub _parseAndLoadOwlThings {
  my ($self, $node, $property, $className, $ontologyIds, $ns) = @_;

  my $relationshipType = 'oneOf';

  foreach my $thingNode ($node->findnodes('owl:oneOf/*')) {
    my $filler = $thingNode->getAttribute('ID');
    $filler = $thingNode->getAttribute('about') if(!$filler);

    $filler = $self->_nameFromHtml($filler);
    $self->_loadRelationship($className, $property, $filler, $relationshipType, $ontologyIds);
  }
}

# ----------------------------------------------------------------------

=pod

=item C<_parseAndLoadThings>

Parse Relationship of type 'oneOf' 

B<Parameters:>

$node(XML::LibXML::Element): The node of interest.
$className(string):  Name of the Class Node
$ontologyIds(hashRef):  key=SRes.OntologyTerm.name, value=SRes.OntologyTerm.ontology_term_id
$ns(scalar): The prefix of the NodeName (ie 'daml' or 'owl')

B<Return type:> C<void> 

=cut

sub _parseAndLoadThings {
  my ($self, $node, $className, $ontologyIds, $ns) = @_;

  my @resources;

  my $relationshipType = 'oneOf';

  my @things = $node->childNodes();
  foreach(@things) {
    if($_->hasAttributes()) {
      my $resource;

      my $filler = $_->getAttribute('about');
      $filler = $self->_nameFromHtml($filler);

      my $parent = $node->parentNode();
      while($parent->nodeName ne "$ns:Restriction") {
	$parent = $parent->parentNode();
      }

      foreach($parent->findnodes("$ns:onProperty")) {
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
$ontologyIds(hashRef):  key=SRes.OntologyTerm.name, value=SRes.OntologyTerm.ontology_term_id
$ns(scalar): The prefix of the NodeName (ie 'daml' or 'owl')

B<Return type:> C<void> 

=cut

sub _doObjectPropertyData {
  my ($self, $objectProperty, $opName, $ontologyIds, $ns) = @_;

  my $relationshipType = 'domain';

  foreach my $node ($objectProperty->findnodes('rdfs:domain')) {
    my $domain;

    if($ns eq 'daml') {
      foreach my $class ($node->findnodes("$ns:Class")) {
        $domain = $class->getAttribute('about');
      }
    }
    elsif($ns eq 'owl') {
      $domain = $node->getAttribute('resource');
    }
    else {
      die "File of Type $ns not supported: $!";
    }
    $domain = $self->_nameFromHtml($domain);
    $self->_loadRelationship($opName, '', $domain, $relationshipType, $ontologyIds);
  }
}

# ----------------------------------------------------------------------

=pod

=item C<_doOwlInstanceData>

Parse Relationship of type 'instanceOf' or 'hasInstance' for olw format

B<Parameters:>

$description(XML::LibXML::Element): The node of interest.
$descName(string):  Name of the Class Node
$ontologyIds(hashRef):  key=SRes.OntologyTerm.name, value=SRes.OntologyTerm.ontology_term_id
$ns(scalar): The prefix of the NodeName (ie 'daml' or 'owl')

B<Return type:> C<void> 

=cut


sub _doOwlInstanceData {
  my ($self, $description, $descName, $ontologyIds, $ns) = @_;

  my $relationshipType = 'instanceOf';

  foreach my $node ($description->findnodes('rdf:type')) {
    my $inst = $node->getAttribute('resource');
    $inst = $self->_nameFromHtml($inst);

    $self->_loadRelationship($descName, '', $inst, $relationshipType, $ontologyIds);
  }

  my $descNodeName = $description->nodeName;
  $descNodeName = 'Thing' if($descNodeName eq 'owl:Thing');
  $self->_loadRelationship($descName, '', $descNodeName, $relationshipType, $ontologyIds);

  $relationshipType = 'hasInstance';

  foreach my $node ($description->findnodes('*')) {
    my $name = $node->nodeName;

    if($name !~ /rdf(s)?:/) {
      my $uriNode = $node;

      my $object = $uriNode->getAttribute('resource');
      $object = $uriNode->textContent if(!$object);

      foreach ($uriNode->findnodes('*')) {
        if($_->hasAttributes()) {
          $object = $_->getAttribute('ID');
        }
      }

      $object = $self->_nameFromHtml($object);
      my $predicate = $uriNode->nodeName;
      $self->_loadRelationship($descName, $predicate, $object, $relationshipType, $ontologyIds);
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
$ontologyIds(hashRef):  key=SRes.OntologyTerm.name, value=SRes.OntologyTerm.ontology_term_id
$ns(scalar): The prefix of the NodeName (ie 'daml' or 'owl')

B<Return type:> C<void> 

=cut

sub _doInstanceData {
  my ($self, $description, $descName, $ontologyIds, $ns) = @_;

  my $relationshipType = 'instanceOf';

  foreach my $node ($description->findnodes('rdf:type')) {
    foreach my $class ($node->findnodes("$ns:Class")) {
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

  # TODO make this a global hash...
  my $sh = $self->getQueryHandle->prepare("SELECT ontology_relationship_type_id 
                                            FROM SRes.OntologyRelationshiptype
                                             WHERE name = '$relType'");
  $sh->execute ();

  if(my ($relTypeId) = $sh->fetchrow_array()) {
    my $subjectOntologyId = $ontologyIds->{$subject};
    my $objectOntologyId = $ontologyIds->{$object};

    if($self->getArgs->{commit} && !$subjectOntologyId) {
      $self->log("WARNING Subject Not found as existing ontology term: $subject");
    }
    if($self->getArgs->{commit} && !$objectOntologyId) {
      $self->log("WARNING Object Not found as existing ontology term: $object");
    }

    if($subjectOntologyId && $objectOntologyId && $self->getArgs->{commit}) {
      my $ontologyRelationship = GUS::Model::SRes::OntologyRelationship->
        new({ subject_term_id => $ontologyIds->{$subject},
              predicate_term_id => $ontologyIds->{$predicate},
              object_term_id => $ontologyIds->{$object},
              ontology_relationship_type_id => $relTypeId,
            });

      $ontologyRelationship->submit();
      $numRelationships++; #global var
    }
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
    die "No Ontology Terms Found!  Perhaps you need to run with commit on.:$!";
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

# ----------------------------------------------------------------------

sub _isIncluded {
  my ($self, $ar, $val) = @_;

  foreach(@$ar) {
    return(1) if($_ eq $val);
  }
  return(0);
}


1;
