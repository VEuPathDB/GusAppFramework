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

use File::Basename;


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
stringArg({ name  => 'extDbRlsSpec',
		  descr => "The ExternalDBRelease specifier for this Ontology Synonym. Must be in the format 'name|version', where the name must match an name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
		  constraintFunc => undef,
		  reqd           => 1,
		  isList         => 0 }),
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

  my $extDbRlsSpec = $self->getArg('extDbRlsSpec');
  my $extDbRlsId = $self->getExtDbRlsId( $extDbRlsSpec );
  my $file = $self->getArg('inFile');
  my $synonymsCount = $self->loadSynonyms($file,$extDbRlsId);

  return "Inserted $synonymsCount SRes::OntologySynonyms";
}

#--------------------------------------------------------------------------------

=item C<readFile>

Opens the out file and reads ALL lines into an arrayref. (Chomps off the newline chars)

B<Parameters:>

 $fn(string): full path to the .out file

B<Return Type:> 

 C<ARRAYREF> Each element is a file line

=cut

sub loadSynonyms {
  my ($self, $fn,$extDbRlsId) = @_;

  my $count = 0;

  my $externalDatabaseSpecs = {};

  open(FILE, "< $fn") or $self->error("Could Not open file $fn for reading: $!");
  <FILE>; #removing header
  foreach my $row (<FILE>){
    chomp $row;
    next unless $row;
    my %hash;
    

    my @values = split ("\t" , $row);
    my $ontologyTermSource = $values[1];
    my $synonym = $values[0];

    my $ontologyTermSourceId = basename $ontologyTermSource;

    my $ontologyTerm = GUS::Model::SRes::OntologyTerm->
      new({
           source_id =>  $ontologyTermSourceId,
          });
    unless ( $ontologyTerm->retrieveFromDB()) {
      $self->error("unable to find ontology term $ontologyTermSourceId");
    }
 
    
    my $synonym = GUS::Model::SRes::OntologySynonym->
      new({
           external_database_release_id => $extDbRlsId,
           ontology_synonym => $synonym,
          });

    $synonym->setParent($ontologyTerm);
    $synonym->submit();
    $count++;
    if($count % 100 == 0) {
      $self->log("Inserted $count SRes::OntologySynonyms");
      $self->undefPointerCache();
    }
  }

  close FILE;
  return $count;
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

sub undoTables {
  my ($self) = @_;

  return ('SRes.OntologySynonym');
}

1;
