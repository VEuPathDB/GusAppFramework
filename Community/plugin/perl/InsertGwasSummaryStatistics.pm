#######################################################################
##                 InsertGwasSummaryStatistics.pm
##
## Loads gwas summary statistics from tab-delimited file and links to
## annotations via the Study.ProtocolAppNode
## $Id: InsertGwasSummaryStatistics.pm 12488 2013-07-11 15:02:27Z allenem $
##
#######################################################################

package GUS::Community::Plugin::InsertGwasSummaryStatistics;
@ISA = qw( GUS::PluginMgr::Plugin);

use strict 'vars';

use GUS::PluginMgr::Plugin;
use lib "$ENV{GUS_HOME}/lib/perl";
use FileHandle;
use Carp;
use GUS::Model::Study::ProtocolAppNode;
use GUS::Model::Study::Characteristic;
use GUS::Model::Results::SeqVariation;
use Data::Dumper;

my %chromosomeSequenceId;

my $argsDeclaration =
  [
   fileArg({ name           => 'file',
	     descr          => 'input data file; see NOTES for file format details',
	     reqd           => 1,
	     mustExist      => 1,
	     format         => 'tab-delimited format',
	     constraintFunc => undef,
	     isList         => 0,
	   }),
     stringArg({ name  => 'extDbRlsSpec',
		  descr => "The ExternalDBRelease specifier. Must be in the format 'name|version', where the name must match an name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
		  constraintFunc => undef,
		  reqd           => 1,
		  isList         => 0 }),
     stringArg({ name  => 'label',
		  descr => "the display label for this dataset",
		  constraintFunc => undef,
		  reqd           => 1,
		  isList         => 0 }),
     stringArg({ name  => 'description',
		  descr => "description for the dataset",
		  constraintFunc => undef,
		  reqd           => 1,
		  isList         => 0 }),
   stringArg({ name  => 'source_id',
		  descr => "external database source_id; or internal unique dataset identifier",
		  constraintFunc => undef,
		  reqd           => 1,
		  isList         => 0 }),
     stringArg({ name  => 'type',
		  descr => "An ontology/ontology-term pair describing the type of this track. The ontology name and term name are separated by a slash",
		  constraintFunc => undef,
		  reqd           => 1,
		  isList         => 0 }),
     stringArg({ name  => 'terms',
		  descr => "A comma-separated list of ontology terms related to this track. Each item in the list consists of an ontology name and a term name, separated by a slash",
		  constraintFunc => undef,
		  reqd           => 1,
		  isList         => 0 })
  ];


my $purposeBrief = <<PURPOSEBRIEF;
Loads the genomic spans of a genome-browser track
PURPOSEBRIEF

my $purpose = <<PLUGIN_PURPOSE;
Loads the genomic spans of a genome-browser track
PLUGIN_PURPOSE

my $tablesAffected = [
                      ['Study::ProtocolAppNode', 'Each track is represented by one record.'],
                      ['Study::Characteristic', 'Each record links a track to an ontology term.'],
                      ['Results::SegmentResult', 'Each record stores one genomic span for the track.'],
                     ];

my $tablesDependedOn = [];

my $howToRestart = <<PLUGIN_RESTART;
No restart facility available.
PLUGIN_RESTART

my $failureCases = <<PLUGIN_FAILURE_CASES;
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
INPUT FILE must be tab-delimited with first column 
containing official snp identifiers (e.g. dbSNP rs ids). 

Column headers required.
marker and p_value columns required.
optional columns include: frequency, allele, odds_ratio, allele_percent


PLUGIN_NOTES

my $documentation = { purpose=>$purpose,
		      purposeBrief=>$purposeBrief,
		      tablesAffected=>$tablesAffected,
		      tablesDependedOn=>$tablesDependedOn,
		      howToRestart=>$howToRestart,
		      failureCases=>$failureCases,
		      notes=>$notes
		    };

sub new {
    my ($class) = @_;
    my $self = {};
    bless($self,$class);


    $self->initialize({requiredDbVersion => 4.0,
		       cvsRevision => '$Revision: 16139 $', # cvs fills this in!
		       name => ref($self),
		       argsDeclaration => $argsDeclaration,
		       documentation => $documentation
		      });

    return $self;
}

#######################################################################
# Main Routine
#######################################################################

sub run {
    my ($self) = @_;

    # each track has one ProtocolAppNode
    my $pan = GUS::Model::Study::ProtocolAppNode->new({
	external_database_release_id => $self->getExtDbRlsId($self->getArg('extDbRlsSpec')),
	type_id => $self->getOntologyTermId(split("/", $self->getArg('type'))),
	name => $self->getArg('name'),
	source_id => $self->getArg('source_id'),
	description => $self->getArg('description'),
					  });
    $pan->submit()
	unless ($pan->retrieveFromDB());
    my $panId = $pan->{'attributes'}->{'protocol_app_node_id'};

    # each ontology term is a Characteristic
    foreach my $ot (split(',', $self->getArg('terms'))){
	my ($ontology, $term) = split("/", $ot);
	my $c = GUS::Model::Study::Characteristic->new({
	    protocol_app_node_id => $panId,
	    ontology_term_id => $self->getOntologyTermId($ontology, $term),
						       });
	$c->submit()
	    unless ($c->retrieveFromDB());
    }

    # put gwas summary statistics records in Results::SeqVariation
    open (FILE, $self->getArg('file')) || die "Can't open input file.";
    my $recordCount;
    my $fields = parseHeader(<FILE>);

    while (<FILE>) {
      chomp;
      $recordCount++;

      my @values = split /\t/;

      my $snpNAFeatureId = getSnpNAFeatureId($values[0]);
 
      my $fieldValues = {protocol_app_node_id => $panId,
			 snp_na_feature_id => $snpNAFeatureId,
			 p_value => $values[$fields->{p_value}] };

      $fieldValues->{frequency} = $values[$fields->{frequency}] if (exists $fields->{frequency});
      $fieldValues->{allele} = $values[$fields->{allele}] if (exists $fields->{allele});
      $fieldValues->{odds_ratio} = $values[$fields->{odds_ratio}] if (exists $fields->{odds_ratio});
      $fieldValues->{allele_percent} = $values[$fields->{allele_percent}] if (exists $fields->{allele_percent});

      my $seqVariation = GUS::Model::Results::SeqVariation->new($fieldValues);

      $seqVariation->submit()
	  unless ($seqVariation->retrieveFromDB());

      unless ($recordCount % 5000) {
          $self->undefPointerCache();
	  $self->log("Inserted $recordCount spans")
      }
    }

    my $msg = "$recordCount spans inserted into SegmentResult";
    return $msg;
}

sub getSnpNAFeatureId {
  my ($self, $snpId) = @_;

  my $sth = $self->getQueryHandle()->pepareAndExecute(<<"SQL");
     select na_feature_id from
     dots.snpfeature
     where source_id = '$snpId'
SQL

  my ($na_feature_id) = $sth->fetchrow_array();
  $sth->finish();
  die "Couldn't find SnpFeature record for snp \"$snpId\"" unless $na_feature_id;

  return $na_feature_id;
}

sub parseHeader {
  my ($header) = @_;
  chomp($header);
  my @arr = split("\t", $header);
  my %fields = map {$arr[$_] => $_ } 0..$#arr;

  die "Error with input file: field containing p-value must be labeled 'p_value'.  See NOTES for more information." if (!exists $fields{p_value});

  return \%fields;

}

sub undoTables {
  my ($self) = @_;

  return ('Study.ProtocolAppNode',
          'Study.Characteristic',
          'Results.SegmentResult',
         );
}

1;
