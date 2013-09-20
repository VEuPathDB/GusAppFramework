##
## InsertDbsnp Plugin
## $Id: InsertDbsnp.pm $
##


package GUS::Community::Plugin::InsertDbsnp;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
# use CBIL::Util::Disp;
use GUS::PluginMgr::Plugin;
use XML::LibXML;
use XML::LibXML::XPathContext;
use Data::Dumper;

use GUS::Model::DoTS::SnpFeature;
use GUS::Model::DoTS::ExternalNASequence;
use GUS::Model::SRes::OntologyTerm;
use GUS::Model::Study::Protocol;
use GUS::Model::Study::ProtocolApp;
use GUS::Model::Study::ProtocolAppNode;
use GUS::Model::Study::Characteristic;

# ----------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------

sub getArgumentsDeclaration {
  my $argumentDeclaration  =
    [
     fileArg({name => 'xmlFile',
	      descr => 'The full path of the xml file.',
	      constraintFunc=> undef,
	      reqd  => 1,
	      isList => 0,
	      mustExist => 1,
	      format => 'dbSNP XML format'
	     }),
    ];
  return $argumentDeclaration;
}

# ----------------------------------------------------------------------
# Documentation
# ----------------------------------------------------------------------

sub getDocumentation {
  my $purposeBrief = 'Loads dbSNP';

  my $purpose = 'This plugin reads a dbSNP xml file, and inserts its content into GUS';

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
		     cvsRevision => '$Revision: 12828 $',
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

  $self->processXmlFile($self->getArg('xmlFile'));

}

# ----------------------------------------------------------------------
# methods called by run
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# processXmlFile
#
# Read the dbSNP XML file named in the argument (contents as below) to populate GUS
#
# <?xml version="1.0" encoding="UTF-8"?>
# <GenoExchange xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.ncbi.nlm.nih.gov/SNP/geno" xsi:schemaLocation="http://www.ncbi.nlm.nih.gov/SNP/geno ftp://ftp.ncbi.nlm.nih.gov/snp/specs/genoex_1_5.xsd" dbSNPBuildNo="138" reportId="22" reportType="chromosome">
#     <Population popId= handle= locPopId=>
#         <popClass self=/>
#     </Population>
#     <Individual indId= taxId= sex= indGroup=>
#         <SourceInfo source= sourceType= ncbiPedId= pedId= indId= maId= paId= srcIndGroup=/>
#         <SubmitInfo popId= submittedIndId= subIndGroup=/>
#     </Individual>
#     <Pedigree ncbiPedId= authority= authorityPedId=/>
#     <SnpInfo rsId= observed=>
#         <SnpLoc genomicAssembly= geneId= geneSymbol= chrom= start= end= locType= rsOrientToChrom= contigAllele= contig=/>
#         <SsInfo ssId= locSnpId= ssOrientToRs=>
#             <ByPop popId= probeId= hwProb= hwChi2= hwDf= sampleSize=>
#                 <AlleleFreq allele= freq=/>
#                 <GTypeFreq gtype= freq=/>
#                 <GTypeByInd gtype= indId= flag=/>
#             </ByPop>
#         </SsInfo>
#         <GTypeFreq gtype= freq=/>
#     </SnpInfo>
#     <FlagDesc flag= desc=/>
# </GenoExchange>
#
# ----------------------------------------------------------------------

sub processXmlFile {
    my ($self, $xmlFile) = @_;

    my ($foundInXml, $alreadyInDb, $added); # record counts

    my $parser = XML::LibXML->new();
    my $doc = $parser->parse_file($xmlFile);
    my $xc = XML::LibXML::XPathContext->new($doc);
    my $namespace = "http://www.ncbi.nlm.nih.gov/SNP/geno";
    $xc->registerNs('GE', 'http://www.ncbi.nlm.nih.gov/SNP/geno');

#     <SnpInfo rsId= observed=>
    foreach my $snpInfo ($xc->findnodes('//GE:SnpInfo')) {
	$foundInXml++;
	my $rsId = $snpInfo->getAttribute("rsId");
	my $snpFeature = GUS::Model::DoTS::SnpFeature
	    ->new( {
		"source_id" => "rs$rsId",
		"name" => "SNP",
		   } );
	if ($snpFeature->retrieveFromDB()) {
	    $alreadyInDb++;
	    next;
	}
	$snpFeature->setDescription(optionalAttribute("observed". $snpInfo->getAttribute("observed")));
	$snpFeature->submit();

	my $naSequenceId;
	my $snpInfoXc  = XML::LibXML::XPathContext->new($snpInfo);
	$snpInfoXc->registerNs('GE', 'http://www.ncbi.nlm.nih.gov/SNP/geno');
#         <SnpLoc genomicAssembly= geneId= geneSymbol= chrom= start= end= locType= rsOrientToChrom= contigAllele= contig=/>
	foreach my $snpLoc ($snpInfoXc->findnodes('//GE:SnpLoc')) {
	    $naSequenceId = getSequenceId($snpLoc->getAttribute("contig"));
	    if ($naSequenceId) {
		my $start = $snpLoc->getAttribute("start");
		my $end = $snpLoc->getAttribute("end") || $start;
		my $isReversed;
		my $rsOrientToChrom = $snpLoc->getAttribute("rsOrientToChrom");
		if ($rsOrientToChrom eq 'fwd' || !$rsOrientToChrom) {
		    $isReversed = 0;
		} elsif ($rsOrientToChrom eq 'rev') {
		    $isReversed = 1;
		} else {
		    $self->log("WARNING: unfamiliar value \"$rsOrientToChrom\" for rsOrientToChrom attribute");
		}
		my $remark = optionalAttribute("genomicAssembly". $snpLoc->getAttribute("genomicAssembly"))
		    .  optionalAttribute("geneId". $snpLoc->getAttribute("geneId"))
		    .  optionalAttribute("geneSymbol". $snpLoc->getAttribute("geneSymbol"))
		    .  optionalAttribute("chrom". $snpLoc->getAttribute("chrom"))
		    .  optionalAttribute("start". $start)
		    .  optionalAttribute("end". $end)
		    .  optionalAttribute("locType". $snpLoc->getAttribute("locType"))
		    .  optionalAttribute("rsOrientToChrom". $rsOrientToChrom)
		    .  optionalAttribute("contigAllele". $snpLoc->getAttribute("contigAllele"))
		    .  optionalAttribute("contig". $snpLoc->getAttribute("contig"));

		my $naLocation = GUS::Model::DoTS::NALocation
		    ->new( {
			"na_feature_id" => $snpFeature->getNaFeatureId(),
			"start_min" => $start,
			"end_max" => $end,
			"is_reversed" => $isReversed,
			"remark" => $remark,
			   } );
		$naLocation->submit();
	    }
	}

	if (!$naSequenceId) {
	    $self->log("WARNING: no location found for rs$rsId");
	}

#         <GTypeFreq gtype= freq=/>
	foreach my $gTypeFreq ($snpInfoXc->findnodes('./GE:GTypeFreq')) {
	    my $gtype = $gTypeFreq->getAttribute("gtype");
	    my $freq = $gTypeFreq->getAttribute("freq");
	}

#         <SsInfo ssId= locSnpId= ssOrientToRs=>
	foreach my $ssInfo ($snpInfoXc->findnodes('./GE:SsInfo')) {
	    my $ssId = $ssInfo->getAttribute("ssId");
	    my $locSnpId = $ssInfo->getAttribute("locSnpId");
	    my $ssOrientToRs = $ssInfo->getAttribute("ssOrientToRs");

	    my $ssInfoXc  = XML::LibXML::XPathContext->new($ssInfo);
	    $ssInfoXc->registerNs('GE', 'http://www.ncbi.nlm.nih.gov/SNP/geno');

#             <ByPop popId= probeId= hwProb= hwChi2= hwDf= sampleSize=>
	    foreach my $byPop ($ssInfoXc->findnodes('./GE:ByPop')) {
		my $popId = $byPop->getAttribute("popId");
		my $probeId = $byPop->getAttribute("probeId");
		my $hwProb = $byPop->getAttribute("hwProb");
		my $hwChi2 = $byPop->getAttribute("hwChi2");
		my $hwDf = $byPop->getAttribute("hwDf");
		my $sampleSize = $byPop->getAttribute("sampleSize");

		# look up population by popId
		my ($pop) = $xc->findnodes("//GE:Population[\@popId='$popId']");
		if ($pop) {
#     <Population popId= handle= locPopId=>
		    my $handle = $pop->getAttribute("handle");
		    my $locPopId = $pop->getAttribute("locPopId");
		    
		    my $popXc  = XML::LibXML::XPathContext->new($pop);
		    $popXc->registerNs('GE', 'http://www.ncbi.nlm.nih.gov/SNP/geno');
#         <popClass self=/>
		    foreach my $popClass ($popXc->findnodes('./GE:popClass')) {
			my $self = $popClass->getAttribute("self");
		    }
		} else {
		    $self->log("WARNING: failed to find population with popId=\"$popId\"");
		}

		my $byPopXc  = XML::LibXML::XPathContext->new($byPop);
		$byPopXc->registerNs('GE', 'http://www.ncbi.nlm.nih.gov/SNP/geno');
#                 <AlleleFreq allele= freq=/>
		foreach my $alleleFreq ($byPopXc->findnodes('./GE:AlleleFreq')) {
		    my $allele = $alleleFreq->getAttribute("allele");
		    my $freq = $alleleFreq->getAttribute("freq");
		}

#                 <GTypeFreq gtype= freq=/>
		foreach my $gTypeFreq ($byPopXc->findnodes('./GE:GTypeFreq')) {
		    my $gtype = $gTypeFreq->getAttribute("gtype");
		    my $freq = $gTypeFreq->getAttribute("freq");
		}

#                 <GTypeByInd gtype= indId= flag=/>
		foreach my $gTypeByInd ($byPopXc->findnodes('./GE:GTypeByInd')) {
		    my $gtype = $gTypeByInd->getAttribute("gtype");
		    my $indId = $gTypeByInd->getAttribute("indId");
		}

	    } # </ByPop>
	} # </SsInfo>
    } # </SnpInfo>

}

# optionalAttribute
#
# return "<attribute>="<value>"<space>" if value is not empty
sub optionalAttribute {
    my ($attribute, $value) = @_;

    return "$attribute=\"$value\" "
	if ($value);
}

# getSequenceId
#
# find the na_sequence_id for the given source ID
sub getSequenceId {
  my ($sourceId) = @_;

  my $externalNASequence = GUS::Model::DoTS::ExternalNASequence
      ->new( {
	  "source_id" => $sourceId,
	     } );

  return ($externalNASequence->getNaSequenceId())
      if $externalNASequence;
}

# ----------------------------------------------------------------------
sub undoTables {
  my ($self) = @_;

  return ('Study.Characteristic', 'Study.Input', 'Study.Output');
}

1;
