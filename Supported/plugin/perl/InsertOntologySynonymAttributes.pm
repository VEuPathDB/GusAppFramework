package GUS::Supported::Plugin::InsertOntologySynonymAttributes;

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

use Text::CSV;

my $argsDeclaration =
[
 fileArg({name           => 'attributesFile',
    descr          => 'A tab-delimited file with headers matching SRes.OntologySynonym column names',
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
  booleanArg({name => 'append',
    descr => 'Will insert a new synonym if the ontology_term_id for SOURCE_ID exists', 
    constraintFunc => undef,
    reqd => 0,
  }),
];

my $purpose = <<PURPOSE;
Update SRes.OntologySynonym with attributes that were not loaded in GUS::Supported::Plugin::InsertOntologyTermsAndRelationships (because these attributes are not stored in the .owl file)
PURPOSE

my $purposeBrief = <<PURPOSE_BRIEF;
Update SRes.OntologySynonym  
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
  my $file = $self->getArg('attributesFile');
  my $append = $self->getArg('append');
  my $synonymsCount = $self->loadSynonyms($file,$extDbRlsId,$append);
  return "Updated $synonymsCount rows in SRes::OntologySynonym";
}

#--------------------------------------------------------------------------------


sub loadSynonyms {
  my ($self, $file, $extDbRlsId, $append) = @_;

  unless(-e $file){
    $self->log(sprintf("WARN: file %s does not exist", $file));
  }
  my $count = 0;

  my $externalDatabaseSpecs = {};

  my $csv = Text::CSV->new({binary => 1, escape_char => "\\", quote_char => undef, sep_char => "\t"});
  open(my $fh, "<$file") or die "Cannot read $file:$!\n";
  my $hr = $csv->getline($fh);
  my $k = $hr->[0];
  $csv->column_names($hr);
  my %vars;
  $vars{$_} = 1 for @$hr; 
  my %data;
  my $x = 0;
  while(my $r = $csv->getline_hr($fh)){
    $x++;
    $data{ $r->{$k} } = $r;
    delete($data{ $r->{$k} }->{ $k }); # remove source_id
  }
  close($fh);
  # $self->log(sprintf("Read %d lines from file", $x));
  

  foreach my $ontologyTermSourceId(keys %data){
    my $attrs = $data{$ontologyTermSourceId};

    next unless($ontologyTermSourceId);
    my $ontologyTerm = GUS::Model::SRes::OntologyTerm->new({ source_id =>  $ontologyTermSourceId });
    unless ( $ontologyTerm->retrieveFromDB() || $append ) {
      $self->error("unable to find ontology term $ontologyTermSourceId");
    }
    else {
      $ontologyTerm->submit();
    }
    my $synonym = GUS::Model::SRes::OntologySynonym->new({
      external_database_release_id => $extDbRlsId,
      ontology_term_id => $ontologyTerm->getId,
    });
    # $synonym->setParent($ontologyTerm);
    unless( $synonym->retrieveFromDB() || $append ) { 
      $self->error("unable to find ontology synonym for $ontologyTermSourceId in $extDbRlsId");
    }
  
    my $validAttrs = $synonym->getAttributes();
    
    foreach my $attr ( keys %$attrs ){
   #  unless(exists($validAttrs->{$attr})){
   #    $self->log("$attr not a valid attribute, skipping");
   #    next;
   #  }
      $self->log("SETTING: $attr = $attrs->{$attr}");
      $synonym->set($attr, $attrs->{$attr});
    }
    my $status = $synonym->submit();
    $count++;
  }
  return $count;
}

#--------------------------------------------------------------------------------

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
  # we only update here! no deletions
  return ();
}

1;
