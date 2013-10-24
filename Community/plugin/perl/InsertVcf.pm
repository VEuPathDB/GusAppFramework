##
## InsertVcf Plugin
## $Id: InsertVcf.pm $
##


package GUS::Community::Plugin::InsertVcf;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
use GUS::PluginMgr::Plugin;
use Data::Dumper;
use Vcf;
# use Bio::EnsEMBL::Variation::Utils::dbSNP qw(decode_bitfield);
# use GUS::Community::Utils::dbSnpBits;

use GUS::Model::DoTS::SnpFeature;
use GUS::Model::DoTS::ExternalNASequence;
use GUS::Model::DoTS::NALocation;
use GUS::Model::DoTS::DbRefNAFeature;
use GUS::Model::SRes::DbRef;
use GUS::Model::Results::SeqVariation;

my %infoHash;

# ----------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------

sub getArgumentsDeclaration {
  my $argumentDeclaration  =
    [
     fileArg({name => 'vcfFile',
	      descr => 'The full path of the input VCF file.',
	      constraintFunc=> undef,
	      reqd  => 1,
	      isList => 0,
	      mustExist => 1,
	      format => 'VCF'
	     }),
     stringArg({ name  => 'extDbRlsSpec',
                 descr => "The ExternalDBRelease specifier for dbSnp. Must be in the format 'name|version', where the name must match a name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
                 constraintFunc => undef,
                 reqd           => 1,
                 isList         => 0 
             }),
    ];
  return $argumentDeclaration;
}

# ----------------------------------------------------------------------
# Documentation
# ----------------------------------------------------------------------

sub getDocumentation {
  my $purposeBrief = 'Loads dbSNP';

  my $purpose = 'This plugin reads SNPs from a VCF file, and inserts its content into GUS';

  my $tablesAffected = [['Study::Protocol', 'Loads the "sample" protocol, which links a population to one of its members'], ['Study::ProtocolApp', 'Creates applications of the "sample" protocol'], ];

  my $tablesDependedOn = []; 

  my $howToRestart = '';

  my $failureCases = '';

  my $notes = <<NOTES;

Written by John Iodice.
Copyright Trustees of University of Pennsylvania 2013. 
NOTES

  my $documentation = {purpose=>$purpose, purposeBrief=>$purposeBrief, tablesAffected=>$tablesAffected, tablesDependedOn=>$tablesDependedOn, howToRestart=>$howToRestart, failureCases=>$failureCases, notes=>$notes};

  return $documentation;
}

# ----------------------------------------------------------------------
# create and initalize new plugin instance.
# ----------------------------------------------------------------------

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);


  my $documentation = &getDocumentation();
  my $argumentDeclaration    = &getArgumentsDeclaration();

  $self->initialize({requiredDbVersion => 4.0,
		     cvsRevision => '$Revision$',
		     name => ref($self),
		     revisionNotes => '',
		     argsDeclaration => $argumentDeclaration,
		     documentation => $documentation
		    });
  return $self;
}

# ----------------------------------------------------------------------
# run method to do the work
# ----------------------------------------------------------------------

sub run {
  my ($self) = @_;

  $self->logAlgInvocationId();
  $self->logCommit();
  $self->logArgs();
  $self->getAlgInvocation()->setMaximumNumberOfObjects(100000);


  $self->{extDbRlsId} = $self->getExtDbRlsId($self->getArg('extDbRlsSpec'));

  $self->processVcfFile($self->getArg('vcfFile'));

}

# ----------------------------------------------------------------------
# methods called by run
# ----------------------------------------------------------------------


sub processVcfFile {
    my ($self, $vcfFile) = @_;

    my $vcf = Vcf->new(file=>$vcfFile);
    $vcf->parse_header();

    my $recordCount;

    while (my $vcfHash = $vcf->next_data_hash()) {

	my $rsId = $vcfHash->{ID};
	my $snpFeature = GUS::Model::DoTS::SnpFeature
	    ->new( {
		"source_id" => "$rsId",
		   } );
	if ($snpFeature->retrieveFromDB()) {
	    next;
	}

	my $naSequenceId = $self->getSequenceId($vcfHash->{CHROM});
	$snpFeature->setNaSequenceId($naSequenceId);
	$snpFeature->setName('variation');
	$snpFeature->setMajorAllele($vcfHash->{REF});
	$snpFeature->setMinorAllele(join(',', @{$vcfHash->{ALT}}));
	$snpFeature->submit();

	my $pos = $vcfHash->{POS};
	my $naLocation = GUS::Model::DoTS::NALocation
	    ->new( {
		"na_feature_id" => $snpFeature->getNaFeatureId(),
		"start_min" => $pos,
		"end_max" => $pos,
		   } );
	$naLocation->submit();

	$self->log("$rsId on chromosome " . $vcfHash->{CHROM} . " at location " . $vcfHash->{POS})
	    if $self->getArg('veryVerbose');

	# is "FILTER" used? We aren't handling that.
	my $filterString = ${$vcfHash->{FILTER}}[0];
	if ($filterString ne '.') {
	    $self->log("WARNING: $rsId has the filter \"$filterString\"");
	}

	my %info = %{$vcfHash->{INFO}};
	my $infoString;
	foreach my  $infoKey (keys %info) {
	    my $infoVal = $info{$infoKey};
	    my %headerHash = %{$vcf->get_header_line(key=>'INFO', ID=>$infoKey)->[0]};
	    $infoString .= ";" if $infoString;
	    $infoString .= $infoKey;
	    $infoString .= "=\"$infoVal\"" if defined($infoVal);

	    my $dbRefId = $self->getDbRefId($vcf, $infoKey);
	    my $dbRefNaFeature = GUS::Model::DoTS::DbRefNAFeature
		->new( {
		    "db_ref_id" => $dbRefId,
		    "na_feature_id" => $snpFeature->getId(),
		       } );
	    $dbRefNaFeature->submit();
	    
	    if ($self->getArg('veryVerbose')) {
		my $infoMsg;
		$infoMsg .= "  info:\n" unless $infoString;
		$infoMsg .= "    $infoKey";
		$infoMsg .= " = \"$infoVal\"" if defined($infoVal);
		$infoMsg .= " (" . $headerHash{Description} . ")";
		$infoMsg .= "\n";
		$self->log($infoMsg);
	    }

	    # if this is the "VC" field, use its value to set name
	    if ($infoKey eq "VC" && defined($infoVal)) {
		$snpFeature->setName($infoVal);
	    }

#	    # if this is the "VP" bitfield, decode it
#             or don't; it turns out VP basically duplicates the other INFO tags
#	    if ($infoKey eq "VP") {
#		my $bitfieldHashref = decode_bitfield($infoVal);
#		foreach my $bitfield (keys(%{$bitfieldHashref})) {
#		    my $def = GUS::Community::Utils::dbSnpBits::define_bitfield($bitfield);
#		    print "      $bitfield ";
#		    print "= " . $bitfieldHashref->{$bitfield}
#		    if GUS::Community::Utils::dbSnpBits::has_value($bitfield);
#		    print " ($def)";
#		    print " (BITFIELD)\n";
#		}
#	    }

	}
	$snpFeature->setDescription($infoString);
	$snpFeature->submit();

	unless ( ($recordCount++) % 100) {
	    $self->undefPointerCache();
	    $self->log("$recordCount records loaded")
		if $self->getArg('verbose');
	}
    }
    $self->log("loaded $recordCount records");
}

# getSequenceId
#
# find the na_sequence_id for the given chromosome name
sub getSequenceId {
  my ($self, $chromosome) = @_;

  my $externalNASequence = GUS::Model::DoTS::ExternalNASequence
      ->new( {
	  "chromosome" => $chromosome,
	     } );

  if (!$externalNASequence->retrieveFromDB()) {

      # couldn't find it with that name -- remove the prefix "chr" if present
      if ($chromosome =~ /^chr(.*)$/) {
	  $externalNASequence->setChromosome($1);
      }

      if (!$externalNASequence->retrieveFromDB()) {
	  # couldn't find that either -- insert
	  # $externalNASequence->setChromosome($chromosome); # use unabbreviated chromosome name
	  $self->log("adding new sequence record for chromosome \"$chromosome\"")
	      if $self->getArg('verbose');
	  $externalNASequence->setSequenceVersion("1");
	  $externalNASequence->submit();
      }
  }
  return $externalNASequence->getId();
}

# getDbRefId
#
# find the db_ref_id for the given info message
sub getDbRefId {
    my ($self, $vcf, $infoKey) = @_;

    unless ($infoHash{$infoKey}) {

	my $dbRef = GUS::Model::SRes::DbRef
	    ->new( {
		"primary_identifier" => $infoKey,
		"external_database_release_id" => $self->{extDbRlsId},
		   } );

	if (!$dbRef->retrieveFromDB()) {
	    my %headerHash = %{$vcf->get_header_line(key=>'INFO', ID=>$infoKey)->[0]};
	    my $description = $headerHash{Description};
	    $dbRef->setRemark($description);
	    $dbRef->submit();
	}
	$infoHash{$infoKey} = $dbRef->getId();
    }

    return $infoHash{$infoKey}
}

# ----------------------------------------------------------------------
sub undoTables {
  my ($self) = @_;

  return ('DoTS.SnpFeature', 'DoTS.NALocation', 'DoTS.ExternalNASequence', 'SRes.DbRef', 'DoTS.DbRefNAFeature');
}

1;
