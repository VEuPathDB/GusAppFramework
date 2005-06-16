##
## InsertPhylogeneticProfiles.pm
## $Id$
##

package GUS::Supported::Plugin::InsertPhylogeneticProfiles;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
use GUS::PluginMgr::Plugin;
use GUS::Model::DoTS::PhylogeneticProfile;
use GUS::Model::DoTS::PhylogeneticProfileMember;
use FileHandle;

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

my $argsDeclaration =
  [integerArg({name           => 'phylogenetic_profile_set_id',
	       descr          => 'phylogenetic_profile_set_id',
	       reqd           => 1,
	       constraintFunc => undef,
	       isList         => 0, }),

   fileArg({name            => 'datafile',
	    descr           => 'datafile',
	    reqd            => 1,
	    mustExist       => 1,
	    format          =>
'This file contains a header record listing taxonIDs, separated by greater-than symbols, followed by a record for each gene.  The gene records are as in this example:
>pfalciparum|101717199  1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 0.085 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 0.053 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 0.034 0.087 0.047 1.000 0.043 1.000 0.007 1.000 1.000
where:
pfalciparum is a taxon name
101717199 is the na_feature_id of the gene
and the remaining values are presence-or-absence calls for homologs of this genein each of the taxa whose IDs are given in the first record
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

  my $datafile = $self->getArg('datafile');
  my $phylogeneticProfileSetId = $self->getArg('phylogenetic_profile_set_id');

  my $fh = FileHandle->new('<'.$datafile);
  if (! $fh) {
      die ("Can't open datafile $datafile");
  }

  my $taxonLine = <$fh>;
  chomp($taxonLine);
  my @taxonIdList = split(/>/, $taxonLine);

  my ($cCalls, $hCalls, $eCalls, $aa_sequence_id);
  while (<$fh>) {
      chomp;

      my ($geneDoc, $valueString) = split(/\t/, $_);
      my $sourceId = (split(/\|/, $geneDoc))[3];

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
	  phylogenetic_profile_set_id => $phylogeneticProfileSetId,
	  na_feature_id => $naFeatureId,
      });

      $profile->submit();

      my @values = split(/ /, $valueString);
      for (my $i=0; $i <= $#values; $i++) {

	  my $profileMember = GUS::Model::DoTS::PhylogeneticProfileMember->new({
	      phylogenetic_profile_id => $profile->getPhylogeneticProfileId(),
	      taxon_id => $taxonIdList[$i],
	      minus_log_e_value => $values[$i]*1000,
	  });

	  $profileMember->submit();

      }

      $self->undefPointerCache();
  }
  $fh->close();

}
