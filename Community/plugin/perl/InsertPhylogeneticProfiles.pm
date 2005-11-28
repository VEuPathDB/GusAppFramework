##
## InsertPhylogeneticProfiles.pm
## $Id$
##

package GUS::Community::Plugin::InsertPhylogeneticProfiles;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
use GUS::PluginMgr::Plugin;
use GUS::Model::DoTS::PhylogeneticProfileSet;
use GUS::Model::DoTS::PhylogeneticProfile;
use GUS::Model::DoTS::PhylogeneticProfileMember;

use FileHandle;
use IO::gzip;

  my $purposeBrief = "Load phylogenetic profiles from a file.";

my $purpose = <<PLUGIN_PURPOSE;
This plugin loads phylogenetic profiles.  Each of these profiles describes
a gene in terms of which organisms' genomes contain orthologs of it.
PLUGIN_PURPOSE

my $tablesAffected =
  [ ['DoTS::PhylogeneticProfile', 'Insert one record per gene'],
    ['DoTS::PhylogeneticProfileMember',
     'For each profile, insert one record per genome'],
  ];

my $tablesDependedOn =
  [
  ];

my $howToRestart = <<PLUGIN_RESTART;
This plugin has no restart facility.
PLUGIN_RESTART

my $failureCases = <<PLUGIN_FAILURE_CASES;
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
PLUGIN_NOTES

my $documentation = { purpose          => $purpose,
		      purposeBrief     => $purposeBrief,
		      tablesAffected   => $tablesAffected,
		      tablesDependedOn => $tablesDependedOn,
		      howToRestart     => $howToRestart,
		      failureCases     => $failureCases,
		      notes            => $notes
		    };

my $argsDeclaration = [

 stringArg({ descr => 'Desciption of the PhylogeneticProfileSet',
	     name  => 'ProfileSetDescription',
	     isList    => 0,
	     reqd  => 1,
	     constraintFunc => undef,
	   }),

 fileArg({name           => 'headerFile',
	  descr          => 'File containing Genbank Taxon Names',
	  reqd           => 1,
	  mustExist      => 1,
	  format         => 'Each Line Contains a Taxon Names',
	  constraintFunc => undef,
	  isList         => 0, 
	 }),

   fileArg({name            => 'datafile',
	    descr           => '',
	    reqd            => 1,
	    mustExist       => 1,
	    format          =>
'This file (can be .gz) contains a record for each gene.  The gene records are as in this example:
>pfalciparum|Pfa3D7|pfal_chr1|PFA0135w|Annotation|Sanger        1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 0.062 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 0.002 1.000 1.000 
where:
pfalciparum is a taxon name
PFA0135w is the Dots.GeneFeature.source_id of the gene
and the remaining values after the tab are presence-or-absence calls for homologs of this genein each of the taxa whose IDs are given in the first record
',
	    constraintFunc  => undef,
	    isList          => 0, }),
                      ];

sub new {
  my ($class) = @_;
  my $self    = {};
  bless($self,$class);

  $self->initialize({requiredDbVersion => 3.5,
                     cvsRevision       => '$Revision$', # cvs fills this in!
                     name              => ref($self),
                     argsDeclaration   => $argsDeclaration,
                     documentation     => $documentation
                    });

  return $self;
}

sub run {
  my ($self) = @_;
  $self->logAlgInvocationId;
  $self->logCommit;

  my $phylogeneticProfileSet = GUS::Model::DoTS::PhylogeneticProfileSet->
    new({DESCRIPTION => $self->getArg('ProfileSetDescription'),
         PRED_ALG_INVOCATION_ID => $self->getAlgInvocation()->getId(),
         });

  $phylogeneticProfileSet->submit();

  my $datafile = $self->getArg('datafile');

  if ($datafile =~ /(.*)\.gz$/){
    system("gunzip $datafile");
    $fileName = $1;
  }
  else {
    $fileName = $datafile;
  }

  open(FILE, "< $filename") || die "Can't open datafile $filename";

  my $taxonIdList = $self->_getTaxonIds();

  my ($cCalls, $hCalls, $eCalls, $aa_sequence_id);
  while (<$fh>) {
      chomp;

      my ($geneDoc, $valueString) = split(/\t/, $_);
      my $sourceId = (split(/\|/, $geneDoc))[1];

      my $sql = <<SQL;
      SELECT max(na_feature_id)
	  FROM DoTS.geneFeature
	  WHERE source_id='$sourceId'
SQL
      my $sth = $self->prepareAndExecute($sql);
      my ($naFeatureId) = $sth->fetchrow_array();

      if (!$naFeatureId) {
	  print die "Can't get na_feature_id for source_id $sourceId\n";
	  next;
      }

      my $profile = GUS::Model::DoTS::PhylogeneticProfile->new({
	  phylogenetic_profile_set_id => $phylogeneticProfileSet->getId(),
	  na_feature_id => $naFeatureId,
      });

      my @values = split(/ /, $valueString);
      for (my $i=0; $i <= $#values; $i++) {

	  my $profileMember = GUS::Model::DoTS::PhylogeneticProfileMember->new({
	      taxon_id => $taxonIdList->[$i],
	      minus_log_e_value => $values[$i]*1000,
	  })->setParent($profile);

	  $profile->submit();
      }

      $self->undefPointerCache();
  }
  $fh->close();

}

sub _getTaxonIds {
  my ($self) = @_;

  my $fn = $self->getArgs()->{headerFile};

  open(HEADER, "< $fn") || die "Cannot open $fn for reading: $!";

  my @rv;
  my $count = 0;

  while(my $name = <HEADER>) {
    chomp($name);
    $count++;

    my $sql = "SELECT taxon_id FROM SRes.TaxonName WHERE name = '$name'";
    my $sh = $self->getQueryHandle->prepare($sql);
    $sh->execute();

    while(my ($taxonId) = $sh->fetchrow_array()) {
      push(@rv, $taxonId);
    }
  }

  close(HEADER);

  if($count =! scalar @rv) {
    die "The number of taxonNames provided in the header file does not match the number of taxons found in the db\n";
  }

  return(\@rv);
}

1;
