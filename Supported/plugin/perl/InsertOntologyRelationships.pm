package GUS::Supported::Plugin::InsertOntologyRelationships;

@ISA = qw(GUS::PluginMgr::Plugin);

# ----------------------------------------------------------------------

use strict;

use GUS::PluginMgr::Plugin;
use GUS::PluginMgr::PluginUtilities;

use UNIVERSAL qw(isa);

use FileHandle;

use GUS::Model::SRes::OntologyTerm;
use GUS::Model::SRes::OntologyRelationship;

use Data::Dumper;

my $argsDeclaration =
[

 fileArg({name           => 'inFile',
	  descr          => 'A file of Representing Ontology Relationships.',
	  reqd           => 1,
	  mustExist      => 1,
	  format         => 'tab-delimited txt file',
	  constraintFunc => undef,
	  isList         => 0, 
	 }),
];

my $purpose = <<PURPOSE;
The purpose of this plugin is to parse a tabFile and load as Ontology Relationships.  
PURPOSE

my $purposeBrief = <<PURPOSE_BRIEF;
The purpose of this plugin is to load Ontology Relationships.
PURPOSE_BRIEF

my $notes = <<NOTES;

NOTES

my $tablesAffected = <<TABLES_AFFECTED;
SRes::OntologyRelationship
TABLES_AFFECTED

my $tablesDependedOn = <<TABLES_DEPENDED_ON;
SRes.OntologyTerm
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


=head2 Subroutines

=over 4

=item C<run>

Main method which Reads in the tab File,
Converts to SRes::OntologyRelationships

B<Return type:> 

 C<string> Descriptive statement of how many rows were entered

=cut

sub run {
  my ($self) = @_;

  my $file = $self->getArg('inFile');
  my $relationshipLines = $self->readFile($file);
  my $relCount = scalar (@$relationshipLines);
  my $relationships = $self->doRelationships($relationshipLines);
  $self->submitObjectList($relationships);

  my $relationshipCount = scalar(@$relationships);
	print STDERR "Inserted $relationshipCount SRes::OntologyRelationships\n";
  return "Inserted $relationshipCount SRes::OntologyRelationships";
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

  
  my $isHeader = 1;
  my $headerSize = 0;
  my @Header;
  my $lines;

  my $validHeader = 2;

  open(FILE, "< $fn") or $self->error("Could Not open file $fn for reading: $!");
  foreach my $row (<FILE>){
	chomp $row;
	next unless $row;
	my %hash;

  
	if ($isHeader) {
	  @Header = split ("\t" , $row);
	  $isHeader=0;
	  $validHeader = 1;
	  next;
	}
    push (@$lines,$row);
	

  }
  close FILE;  

  return $lines;
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
  my ($self, $lines) = @_;

  my @relationships;
  my $count = 0;

    my $externalDatabaseSpecs = {};
  
  foreach my $line (@$lines) {
  	my $values = [split ("\t" , $line)];
	my $subjectTerm = $values->[0];
	my $objectTerm = $values->[2];
	my $relationshipTerm = $values->[4];
	my $subjectEDRId = $self->handleExtDbRlsSpec($values->[1],$externalDatabaseSpecs);
	my $objectEDRId = $self->handleExtDbRlsSpec($values->[3],$externalDatabaseSpecs);
	my $relationshipEDRId = $self->handleExtDbRlsSpec($values->[5],$externalDatabaseSpecs);
	
	my $subject = $self->getTermId($subjectTerm,$subjectEDRId) or $self->error("Could not retrieve id for subject $subjectTerm for ext_db $subjectEDRId: $!");
	my $object = $self->getTermId($objectTerm,$objectEDRId) or $self->error("Could not retrieve id for object $objectTerm for ext_db $objectEDRId: $!");
	my $relationshipType = $self->getTermId($relationshipTerm,$relationshipEDRId) or $self->error("Could not retrieve id for relationship $relationshipTerm : $!");
	my $relationship;
	if (scalar (@$values) == 6) {
       $relationship = GUS::Model::SRes::OntologyRelationship->
          new({subject_term_id => $subject,
               object_term_id => $object,
               ontology_relationship_type_id => $relationshipType,
              });
	}
 

	elsif (scalar (@$values) == 8) {
		my $predicateTerm = $values->[6];
		my $predicateEDRId = $self->handleExtDbRlsSpec($values->[7],$externalDatabaseSpecs);
		my $predicate = $self->getTermId($predicateTerm,$predicateEDRId) or $self->error("Could not retrieve id for object $predicateTerm : $!");
		 $relationship = GUS::Model::SRes::OntologyRelationship->
          new({subject_term_id => $subject,
	       predicate_term_id => $predicate,
               object_term_id => $object,
               ontology_relationship_type_id => $relationshipType,
              });
	}
	push(@relationships, $relationship);
      $count++;
        if($count % 100 == 0) {
          $self->log("Inserted $count SRes::OntologyRelationships");
          $self->undefPointerCache();
        }
      }
    $self->undefPointerCache();
  return \@relationships;
}

sub handleExtDbRlsSpec {
	my ($self,$spec,$extDbRlsSpecs) = @_;
	my $ext_db_rls_id;
	if (exists $extDbRlsSpecs->{ $spec }) {
		$ext_db_rls_id = $extDbRlsSpecs->{ $spec };
	}
	else {
		$ext_db_rls_id = $self->getExtDbRlsId( $spec ) or $self->error("Could not get external database release id for spec $spec : $!");
	}
	return $ext_db_rls_id;

}
sub getTermId {
	my ($self,$term,$ext_db_rls_id) = @_;
	my $lcTerm =  lc($term);
	my $dbh = $self->getQueryHandle();
	my $sql = "select ontology_term_id 
	             from sres.ontologyTerm 
	            where lower(name) = ?
				  and external_database_release_id =?
	                                                ";
	my $sh = $dbh->prepare($sql);
	$sh->execute($lcTerm,$ext_db_rls_id);
	my $id = $sh->fetchrow();
	return $id;
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

  return ('SRes.OntologyRelationship');
}

1;
