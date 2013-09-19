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
		     cvsRevision => '$Revision: 11754 $',
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

    my $parser = XML::LibXML->new();
    my $doc = $parser->parse_file($xmlFile);
    my $xc = XML::LibXML::XPathContext->new($doc);
    my $namespace = "http://www.ncbi.nlm.nih.gov/SNP/geno";
    $xc->registerNs('GE', 'http://www.ncbi.nlm.nih.gov/SNP/geno');

#     <SnpInfo rsId= observed=>
    foreach my $snpInfo ($xc->findnodes('//GE:SnpInfo')) {

	my $rsId = $snpInfo->getAttribute("rsId");
	my $observed = $snpInfo->getAttribute("observed");
	print "rsId = \"$rsId\"\n";
	print "observed = \"$observed\"\n";

	my $snpInfoXc  = XML::LibXML::XPathContext->new($snpInfo);
	$snpInfoXc->registerNs('GE', 'http://www.ncbi.nlm.nih.gov/SNP/geno');
#         <SnpLoc genomicAssembly= geneId= geneSymbol= chrom= start= end= locType= rsOrientToChrom= contigAllele= contig=/>
	foreach my $snpLoc ($snpInfoXc->findnodes('//GE:SnpLoc')) {
	    my $genomicAssembly = $snpLoc->getAttribute("genomicAssembly");
	    my $geneId = $snpLoc->getAttribute("geneId");
	    my $geneSymbol = $snpLoc->getAttribute("geneSymbol");
	    my $end = $snpLoc->getAttribute("end");
	    my $chrom = $snpLoc->getAttribute("chrom");
	    my $start = $snpLoc->getAttribute("start");
	    my $locType = $snpLoc->getAttribute("locType");
	    my $rsOrientToChrom = $snpLoc->getAttribute("rsOrientToChrom");
	    my $contigAllele = $snpLoc->getAttribute("contigAllele");
	    my $contig = $snpLoc->getAttribute("contig");

	    print "genomicAssembly = \"$genomicAssembly\"\n";
	    print "chrom = \"$chrom\"\n";
	    print "geneId = \"$geneId\"\n";
	    print "geneSymbol = \"$geneSymbol\"\n";
	    print "end = \"$end\"\n";
	    print "start = \"$start\"\n";
	    print "locType = \"$locType\"\n";
	    print "rsOrientToChrom = \"$rsOrientToChrom\"\n";
	    print "contigAllele = \"$contigAllele\"\n";
	    print "contig = \"$contig\"\n";
	    print "\n";
	}

	print "----(per-snp) genotype frequencies\n";
#         <GTypeFreq gtype= freq=/>
	foreach my $gTypeFreq ($snpInfoXc->findnodes('./GE:GTypeFreq')) {
	    my $gtype = $gTypeFreq->getAttribute("gtype");
	    my $freq = $gTypeFreq->getAttribute("freq");

	    print "gtype = \"$gtype\"; ";
	    print "freq = \"$freq\"\n";
	}

	print "\n---- submitted snps\n";
#         <SsInfo ssId= locSnpId= ssOrientToRs=>
	foreach my $ssInfo ($snpInfoXc->findnodes('./GE:SsInfo')) {
	    my $ssId = $ssInfo->getAttribute("ssId");
	    my $locSnpId = $ssInfo->getAttribute("locSnpId");
	    my $ssOrientToRs = $ssInfo->getAttribute("ssOrientToRs");

	    print "ssId = \"$ssId\"\n";
	    print "locSnpId = \"$locSnpId\"\n";
	    print "ssOrientToRs = \"$ssOrientToRs\"\n";
	    print "\n";

	    my $ssInfoXc  = XML::LibXML::XPathContext->new($ssInfo);
	    $ssInfoXc->registerNs('GE', 'http://www.ncbi.nlm.nih.gov/SNP/geno');
	    print "\n---- populations\n";
#             <ByPop popId= probeId= hwProb= hwChi2= hwDf= sampleSize=>
	    foreach my $byPop ($ssInfoXc->findnodes('./GE:ByPop')) {
		my $popId = $byPop->getAttribute("popId");
		my $probeId = $byPop->getAttribute("probeId");
		my $hwProb = $byPop->getAttribute("hwProb");
		my $hwChi2 = $byPop->getAttribute("hwChi2");
		my $hwDf = $byPop->getAttribute("hwDf");
		my $sampleSize = $byPop->getAttribute("sampleSize");

		print "popId = \"$popId\"\n";
		print "probeId = \"$probeId\"\n";
		print "hwProb = \"$hwProb\"\n";
		print "hwChi2 = \"$hwChi2\"\n";
		print "hwDf = \"$hwDf\"\n";
		print "sampleSize = \"$sampleSize\"\n";
		print "\n";

		# look up population by popId
		print "looking for population with popid \"$popId\"\n";
		my ($pop) = $xc->findnodes("//GE:Population[\@popId='$popId']");
		if ($pop) {
#     <Population popId= handle= locPopId=>
		    my $handle = $pop->getAttribute("handle");
		    my $locPopId = $pop->getAttribute("locPopId");
		    print "handle = \"$handle\"; ";
		    print "locPopId = \"$locPopId\"\n";
		    
		    my $popXc  = XML::LibXML::XPathContext->new($pop);
		    $popXc->registerNs('GE', 'http://www.ncbi.nlm.nih.gov/SNP/geno');
#         <popClass self=/>
		    foreach my $popClass ($popXc->findnodes('./GE:popClass')) {
			my $self = $popClass->getAttribute("self");
			print "self = \"$self\"\n";
		    }
		} else {
		    print "WARNING: failed to find population with popId=\"$popId\"\n";
		}

		my $byPopXc  = XML::LibXML::XPathContext->new($byPop);
		$byPopXc->registerNs('GE', 'http://www.ncbi.nlm.nih.gov/SNP/geno');
		print "---- allele frequencies\n";
#                 <AlleleFreq allele= freq=/>
		foreach my $alleleFreq ($byPopXc->findnodes('./GE:AlleleFreq')) {
		    my $allele = $alleleFreq->getAttribute("allele");
		    my $freq = $alleleFreq->getAttribute("freq");
		    print "allele = \"$allele\"; ";
		    print "freq = \"$freq\"\n";
		}

		print "---- genotype frequencies\n";
#                 <GTypeFreq gtype= freq=/>
		foreach my $gTypeFreq ($byPopXc->findnodes('./GE:GTypeFreq')) {
		    my $gtype = $gTypeFreq->getAttribute("gtype");
		    my $freq = $gTypeFreq->getAttribute("freq");
		    print "gtype = \"$gtype\"; ";
		    print "freq = \"$freq\"\n";
		}

		print "---- genotypes by individual\n";
#                 <GTypeByInd gtype= indId= flag=/>
		foreach my $gTypeByInd ($byPopXc->findnodes('./GE:GTypeByInd')) {
		    my $gtype = $gTypeByInd->getAttribute("gtype");
		    my $indId = $gTypeByInd->getAttribute("indId");
		    print "gtype = \"$gtype\"; ";
		    print "indId = \"$indId\"\n";
		}

		print "----- end of population (popId $popId) ----\n\n";
	    } # </ByPop>
	} # </SsInfo>
    } # </SnpInfo>

}

# ----------------------------------------------------------------------
sub undoTables {
  my ($self) = @_;

  return ('Study.Characteristic', 'Study.Input', 'Study.Output');
}

1;
