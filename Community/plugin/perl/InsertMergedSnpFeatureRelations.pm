#######################################################################
##                 InsertMergedSnpFeatureRelations.pm
##
## Loads information from dbSNP's RsMergeArch table 
## (http://www.ncbi.nlm.nih.gov/projects/SNP/snp_db_table_description.cgi?t=RsMergeArch)
## that tracks merge history of SNPs

## $Id: InsertMergedSnpFeatureRelations allenem $
##
#######################################################################

package GUS::Community::Plugin::InsertMergedSnpFeatureRelations;

@ISA = qw( GUS::PluginMgr::Plugin);

use strict 'vars';

use GUS::PluginMgr::Plugin;
use lib "$ENV{GUS_HOME}/lib/perl";

use GUS::Model::DoTS::SnpFeature;
use GUS::Model::DoTS::NAFeatureRelationship;
use GUS::Model::DoTS::NAFeatRelationshipType;

use Data::Dumper;
use FileHandle;


my $argsDeclaration =
  [
   fileArg({ name           => 'inFile',
	     descr          => 'input data file; expects RsArchMerge.bcp download',
	     reqd           => 1,
	     mustExist      => 1,
	     format         => 'tab-delimited format',
	     constraintFunc => undef,
	     isList         => 0,
	   }),
 
   stringArg({ name  => 'extDbRlsSpec',
	       descr => "The ExternalDBRelease specifier for the result. Must be in the format 'name|version', where the name must match an name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
	       constraintFunc => undef,
	       reqd           => 0,
	       isList         => 0 }),
 
   stringArg({ name  => 'type',
	       descr => "the NAFeature relationship type; will create new if no match found in the 'name' field of DoTS.NAFeatRelationshipType",
	       constraintFunc => undef,
	       reqd           => 1,
	       isList         => 0 }),

  integerArg({ name  => 'skip',
	       descr => "skip until line",
	       constraintFunc => undef,
	       reqd           => 0,
	       isList         => 0 }),

 booleanArg({ name  => 'skipAll',
	       descr => "iterate over file to find nested merges, only load those",
	       constraintFunc => undef,
	       reqd           => 0,
	       isList         => 0 }),
 
  
  ];


my $purposeBrief = <<PURPOSEBRIEF;
Load merged SNPs and create links to new ids.
PURPOSEBRIEF

my $purpose = <<PLUGIN_PURPOSE;
Loads SNPs whose rs identifiers have been merged as new SNP features and then links to current SNP features via
NAFeatureRelationship table
PLUGIN_PURPOSE

my $tablesAffected = [
                      ['DoTS::SnpFeature', 'Each record stores one deprecated SNP feature'],
                      ['DoTS::NAFeatureRelation', 'Each record links a deprecated SNP to new rs ID'],
                      ['DoTS::NAFeatRelationType', 'Type of relationship between merged SNPs'],
                     ];

my $tablesDependedOn = [
                     
                        ['SRes.ExternalDatabaseRelease', 'Lookups of external database specifications']
 
];

my $howToRestart = <<PLUGIN_RESTART;
Restart with skip flag.  Plugin will still iterate over file to assemble hash to catch nested merges.  
To skip all and just load nested merges, use the --skipAll option

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
		     cvsRevision => '$Revision: 16461 $', # cvs fills this in!
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

  my $relationshipTypeId = $self->fetchRelationshipTypeId();
  my $xdbrId = $self->getExtDbRlsId($self->getArg('extDbRlsSpec'));

  # begin transaction management
  $self->getDb()->manageTransaction(undef, "begin"); # start a transaction

  my $submitCount = 0;
  my $missingTargets = undef;
  my $missingTargetCount = 0;

  my $rowCount = 0;
  my $skip = $self->getArg('skip');
  my $skipAll = $self->getArg('skipAll');

  my $fName = $self->getArg('inFile');

  my $fh = FileHandle->new;
  $fh->open("<$fName") || $self->error("Unable to open input file: $fName\n");
  while (<$fh>) {
      my @values = split /\t/;
      chomp(@values);

      $rowCount += 1;

      $self->undefPointerCache() if (!$rowCount % 1000); # need to clear the pointer cache
      if (!$rowCount % 5000) {
	$self->log("SKIPPED $rowCount rows.") if ($skipAll or $rowCount <= $skip) ;
      }
      # dbSnp merges high to low; rsHigh is the id that was merged
      my $rsHigh = 'rs' . $values[0]; # rsHigh
      my $rsLow = 'rs' . $values[1]; # rsLow

      my $lowSnpFeature = $self->retrieveSnpFeature($rsLow, $xdbrId);
      unless ($lowSnpFeature->retrieveFromDB()) {
	# the lowSnpFeature might not be in the DB -- either it is itself later merged in the file
	# or it is defined against a different genome build (dbSNP releases may be for multiple builds)
	# so save for later; cannot distinguish without second pass
	$missingTargetCount++;
	$missingTargets->{$rsHigh} = $rsLow;
	$self->log("Merge target SNP $rsLow for $rsHigh not found in DB. Saving for second pass.")
	  if ($self->getArg('veryVerbose'));
	next;
      }

      next if ($skipAll);
      next if ($rowCount <= $skip);
      $self->log("SKIPPED $rowCount rows.  Resuming load with $rsHigh -> $rsLow.") if ($rowCount > $skip);

      # create a new entry in SnpFeature for the high snp
      my $highSnpFeature = $self->retrieveSnpFeature($rsHigh, $xdbrId);
    
      unless ($highSnpFeature->retrieveFromDB()) {
	$highSnpFeature->setName('merged');
	$highSnpFeature->submit(undef, 1); # noTran = 1 --> do not commit at this point
	$submitCount++;
      }

      # create the feature relationships
      my $featureRelation = GUS::Model::DoTS::NAFeatureRelationship->new({
            parent_na_feature_id => $lowSnpFeature->getNaFeatureId(),
            child_na_feature_id => $highSnpFeature->getNaFeatureId(),
            na_feat_relationship_type_id => $relationshipTypeId
									 });

      $featureRelation->submit(undef, 1); # noTran = 1 --> do not commit at this point
      $submitCount += 1;

      unless ($submitCount % 1000) {
	if ($self->getArg("commit")) {
	  $self->getDb()->manageTransaction(undef, "commit"); # commit
	  $self->getDb()->manageTransaction(undef, "begin");
	}
	
 	# $self->undefPointerCache();
	$self->log("$submitCount records loaded.")
	  if $self->getArg('verbose');
      }
    }

  if ($self->getArg("commit")) {
    $self->getDb()->manageTransaction(undef, "commit"); # commit final batch
    $self->log("$submitCount records loaded.") if $self->getArg('verbose');
  }
  
  $fh->close();

  # make pass over targets (lowSnps) that were not found in DB, but may have been added 
  # as a merged snp
  $self->log("Making second pass to load $missingTargetCount whose target SNP id was missing from the DB.");
  $self->insertMissedTargets($missingTargets, $xdbrId, $relationshipTypeId);
}

sub insertMissedTargets {
  my ($self, $mergeRelations, $xdbrId, $relationshipTypeId) = @_;
  my $submitCount = 0;

  while  (my ($rsHigh, $rsLow) = each %$mergeRelations) {
    my $lowSnpFeature = $self->retrieveSnpFeature($rsLow, $xdbrId);
    next unless ($lowSnpFeature->retrieveFromDB()); # if lowSNP is not in the DB, it must be from another genome build, skip
      
    # create a new entry in SnpFeature for the high snp
    my $highSnpFeature = $self->retrieveSnpFeature($rsHigh, $xdbrId);
      
    unless ($highSnpFeature->retrieveFromDB()) { # if we resumed, this may have already been loaded
	$highSnpFeature->setName('merged');
	$highSnpFeature->submit(undef, 1); # noTran = 1 --> do not commit at this point
	$submitCount++;
    }
 
     
    # create the feature relationships
    my $featureRelation = GUS::Model::DoTS::NAFeatureRelationship->new({
	parent_na_feature_id => $lowSnpFeature->getNaFeatureId(),
	child_na_feature_id => $highSnpFeature->getNaFeatureId(),
	na_feat_relationship_type_id => $relationshipTypeId
								       });
    unless ($featureRelation->retrieveFromDB()) {# again, if resumed, this may have already been loaded
	$featureRelation->submit(undef, 1); # noTran = 1 --> do not commit at this point
	$submitCount += 1;
    }
    
    unless ($submitCount % 1000) {
	if ($self->getArg("commit")) {
	    $self->getDb()->manageTransaction(undef, "commit"); # commit
	    $self->getDb()->manageTransaction(undef, "begin");
	}
	
	$self->undefPointerCache();
	$self->log("$submitCount records loaded.")
	    if $self->getArg('verbose');
    }
  } # end iterate over hash

  if ($self->getArg("commit")) {
    $self->getDb()->manageTransaction(undef, "commit"); # commit final batch
    $self->log("$submitCount additional records loaded.") if $self->getArg('verbose');
  }
}

sub retrieveSnpFeature {
  my ($self, $rsId, $xdbrId) = @_;
  
  my $snpFeature = GUS::Model::DoTS::SnpFeature->new(
						     {source_id => $rsId,
						      external_database_release_id => $xdbrId}
						    );
 
  return $snpFeature;

}

sub fetchRelationshipTypeId {
    my ($self) = @_;

    my $type = $self->getArg('type');
    my $relationshipType = GUS::Model::DoTS::NAFeatRelationshipType->new({name => $type});
    unless ($relationshipType->retrieveFromDB()) {
      $relationshipType->setDescription($type); # description can't be null so just use same value
      $relationshipType->submit();
    }

    return $relationshipType->getNaFeatRelationshipTypeId();
}

sub undoTables {
  my ($self) = @_;

  return ('DoTS.NAFeatureRelationship',
          'DoTS.SnpFeature');  # snp feature won't work

}

1;
