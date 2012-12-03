#######################################################################
##                 InsertHugo.pm
##
## Loads HUGO genes from the tab-delimted file available from gennames.org
## $Id$
##
#######################################################################

package GUS::Community::Plugin::InsertHugo;
@ISA = qw( GUS::PluginMgr::Plugin);

use strict 'vars';


use GUS::PluginMgr::Plugin;
use lib "$ENV{GUS_HOME}/lib/perl";
use FileHandle;
use Carp;
use GUS::Model::DoTS::Gene;

my $argsDeclaration =
  [
   fileArg({ name           => 'hugoFile',
	     descr          => 'HUGO input file',
	     reqd           => 1,
	     mustExist      => 1,
	     format         => 'HUGO tab-delimited format',
	     constraintFunc => undef,
	     isList         => 0,
	   }),
     stringArg({ name  => 'extDbRlsSpec',
		  descr => "The ExternalDBRelease specifier for HUGO. Must be in the format 'name|version', where the name must match an name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
		  constraintFunc => undef,
		  reqd           => 1,
		  isList         => 0 }),
  ];


my $purposeBrief = <<PURPOSEBRIEF;
Loads HUGO genes into dots.Gene
PURPOSEBRIEF

my $purpose = <<PLUGIN_PURPOSE;
Reads the tab-delimited file supplied by the HUGO Gene Nomenclature Committee and creates a record in dots.Gene for each input record with status "Approved". (Status can also be "Symbol Withdrawn" or "Entry Withdrawn".)
PLUGIN_PURPOSE

my $tablesAffected =
	[['DoTS.Gene', 'Each approved gene gets a record in dots.Gene']];

my $tablesDependedOn = [];

my $howToRestart = <<PLUGIN_RESTART;
No restart facility available.
PLUGIN_RESTART

my $failureCases = <<PLUGIN_FAILURE_CASES;
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
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
		       cvsRevision => '$Revision$', # cvs fills this in!
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

    my $extDbRlsId = $self->getExtDbRlsId($self->getArg('extDbRlsSpec'));

    open (HUGO, $self->getArg('hugoFile')) || die "Can't open input file of HUGO genes.";

    my $insertCount;
    my %countByStatus;

    while (<HUGO>) {
      # HGNC ID	Approved Symbol	Status	Accession Numbers	Entrez Gene ID	Ensembl Gene ID	RefSeq IDs	Primary IDs	Entrez Gene ID (mapped data supplied by NCBI)	Ensembl ID (mapped data supplied by Ensembl)	UCSC ID (mapped data supplied by UCSC)
      if (/^(.*)\t(.*)\t(.*)\t.*\t(.*)\t(.*)\t.*\t.*\t(.*)\t(.*)\t(.*)$/) {
	my $id = $1;
	my $symbol = $2;
	my $status = $3;

	next if $id eq "HGNC ID"; # header record documents columns

	$countByStatus{$status}++;

	next unless $status eq "Approved";

	my $gene = GUS::Model::DoTS::Gene->new({
	    source_id => $id,
            gene_symbol => $symbol,
            external_database_release_id => $extDbRlsId,
	   });
	$gene->submit();
	$insertCount++;
	unless ($insertCount % 1000) {
	  $self->undefPointerCache();
	  print STDERR "inserted $insertCount HUGO genes\n";
	}
      }
    }

    my $msg = "Input record counts: " . 
              join(', ', (map {$countByStatus{$_} . " " . $_; } keys(%countByStatus))) .
              "; $insertCount records inserted";
    return $msg;
}

sub undoTables {
  my ($self) = @_;

  return ('DoTS.Gene');
}

1;
