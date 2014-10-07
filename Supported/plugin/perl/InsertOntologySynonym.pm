package GUS::Supported::Plugin::InsertOntologySynonym;

@ISA = qw(GUS::PluginMgr::Plugin);

# ----------------------------------------------------------------------

use strict;

use GUS::PluginMgr::Plugin;
use GUS::PluginMgr::PluginUtilities;

use UNIVERSAL qw(isa);

use FileHandle;

use GUS::Model::SRes::OntologyTerm;
use GUS::Model::SRes::OntologySynonym;

use Data::Dumper;

my $argsDeclaration =
[

 fileArg({name           => 'inFile',
	  descr          => 'A file to map OntologyTerm to Synonym',
	  reqd           => 1,
	  mustExist      => 1,
	  format         => 'tab-delimited txt file',
	  constraintFunc => undef,
	  isList         => 0, 
	 }),
];

my $purpose = <<PURPOSE;
The purpose of this plugin is to parse a tabFile and load as Ontology Synonym.  
PURPOSE

my $purposeBrief = <<PURPOSE_BRIEF;
The purpose of this plugin is to load Ontology Synonym.
PURPOSE_BRIEF

my $notes = <<NOTES;

NOTES

my $tablesAffected = <<TABLES_AFFECTED;
SRes::OntologySynonym
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

my $numSynonyms = 0;

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
Converts to SRes::OntologySynonym

B<Return type:> 

 C<string> Descriptive statement of how many rows were entered

=cut

sub run {
  my ($self) = @_;

  my $file = $self->getArg('inFile');
  my $synonymLines = $self->readFile($file);
  my $synCount = scalar (@$synonymLines);
  my $synonyms = $self->doSynonyms($synonymLines);
  $self->submitObjectList($synonyms);

  my $synonymsCount = scalar(@$synonyms);
	print STDERR "Inserted $synCount SRes::OntologySynonyms\n";
  return "Inserted $synCount SRes::OntologySynonyms";
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

=item C<doSynonyms>

Loop through all the file lines and create the synonyms. 

B<Parameters:>

 $terms([GUS::Model::SRes::OntologyTerm]) ArrayRef of Official Terms with definitions
 $lines(ARRAYREF): list of the synonym file lines
 $synonymTypes(HASHREF): hash linking the ontology synonym types to their ids

B<Return Type:> 

 C<[GUS::Model::SRes::OntologySynonym]>  ArrayRef of OntologySynonyms

=cut

sub doSynonyms {
  my ($self, $lines) = @_;

  my @synonyms;
  my $count = 0;

    my $externalDatabaseSpecs = {};
  
  foreach my $line (@$lines) {
  	my $values = [split ("\t" , $line)];
	my $ontologyTerm = $values->[0];
	my $synonymTerm = $values->[2];
	my $EDRId = $self->handleExtDbRlsSpec($values->[1],$externalDatabaseSpecs);
	
	my $ontologyTerm = $self->getTermId($ontologyTerm,$EDRId) or $self->error("Could not retrieve id for ontology Term $ontologyTerm : $!");
	my $synonym;
	if (scalar (@$values) == 3) {
          $synonym = GUS::Model::SRes::OntologySynonym->
            new({ontology_term_id => $ontologyTerm,
                 external_database_release_id => $EDRId,
                 ontology_synonym => $synonymTerm,
                });
	}

	push(@synonyms, $synonym);
      $count++;
      if($count % 100 == 0) {
        $self->log("Inserted $count SRes::OntologySynonyms");
      }
	}
  return \@synonyms;
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
	print STDERR $term."\n";
	my $lcTerm =  lc($term);
	my $dbh = $self->getQueryHandle();
	my $sql = "select name 
	             from sres.ontologyTerm 
	            where lower(name) = ?
				  and external_database_release_id =?
	                                                ";
	my $sh = $dbh->prepare($sql);
	$sh->execute($lcTerm,$ext_db_rls_id);
	$term = $sh->fetchrow();
	my $ontologyTerm = GUS::Model::SRes::OntologyTerm->
          new({name => $term,
               external_database_release_id => $ext_db_rls_id,
              });
	$ontologyTerm->retrieveFromDB();
	my $id = $ontologyTerm->getId();
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

  return ('SRes.OntologySynonym');
}

1;
