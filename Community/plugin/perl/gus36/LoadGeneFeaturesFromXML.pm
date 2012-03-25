package GUS::Community::Plugin::LoadGeneFeaturesFromXML;

# $Id$ 

# --------------------------------------------------------------------
# developed originally by J Schug
# modified for GUS30 by B Gajria
# --------------------------------------------------------------------
# for additional comments, look for 'NOTE:'

@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
use DBI;
use CBIL::Util::Disp;
use XML::Simple;


# Add the specific objects GUS::Model::(DbName)::(ObjectName) here
# --------------------------------------------------------------------
use GUS::Model::Core::Algorithm;
use GUS::Model::Core::ProjectInfo;
use GUS::Model::DoTS::GeneFeature;
use GUS::Model::DoTS::ExonFeature;
use GUS::Model::DoTS::ExternalNASequence;
use GUS::Model::DoTS::NAFeatureComment;
use GUS::Model::DoTS::NALocation;
use GUS::Model::DoTS::ProjectLink;
use GUS::Model::DoTS::RNAFeature; 
use GUS::Model::SRes::ExternalDatabase;
use GUS::Model::SRes::ExternalDatabaseRelease;
use GUS::Model::SRes::TaxonName;

### use GUS::Model::DoTS::ScaffoldGapFeature;
### NOTE: This object (and view) is currently missing; but the yoelii XML
### has no SCAFFOLD. So, not urgently needed, but needs to be fixed.

use GUS::Community::Sequence;


sub new {
  my $class = shift;
  my $self = {};
  my $usage = 'loads gene features from an XML data file...';

  my $easycsp =
    [{ h => 'Read XML from this file',
       t => 'string',
       l => 1,
       o => 'XmlFile'
     },
     { h => 'scientific name for taxon',
       t => 'string',
       o => 'Taxon',
       d => 'Plasmodium falciparum',
     },
     { h => 'project name',
       t => 'string',
       o => 'Project',
       d => 'PlasmodiumDB-4.0',
     },
     { h => 'algorithm name',
       t => 'string',
       o => 'Algorithm',
       d => 'Pf Annotation',
     },
     { h => 'Indicates what task to accomplish',
       t => 'string',
       e => [qw( LoadGenomicSequence UpdateGenomicSequence
		 ScaffoldGapFeatures
		 GeneFeatures FixGeneFeatures
		 GoAnnotation EcAnnotation )],
       o => 'taskFlag',
     },
     { h => 'overwrite existing sequence (=1), or dont (=0)',
       t => 'boolean',
       d => 0,
       o => 'seqFlag',
     },
     { h => "chr# or pfal_chr# for NASequence source_id",
       t => 'string',
       o => 'chr'
     },
     { h => "chr# for tRNA source_id",
       t => 'string',
       o => 'chrnum'
     },
     { h => 'use this go_cvs_version to bind GO Function ids to GUS',
       t => 'string',
       d => '2.483',
       o => 'FunctionGoCvsVersion',
     },
     { h => 'use this go_cvs_version to bind GO Compoment ids to GUS',
       t => 'string',
       d => '2.249',
       o => 'ComponentGoCvsVersion',
     },
     { h => 'use this go_cvs_version to bind GO Process ids to GUS',
       t => 'string',
       d => '2.571',
       o => 'ProcessGoCvsVersion',
     },
     { h => 'GO ID synonym file',
       t => 'string',
       d => '/usr/local/db/others/GO/2002-09-17/synonyms.tab',
       o => 'GoSynonymFile',
     },
     { h => 'Disp::Display XML structures when they might be interesting',
       t => 'boolean',
       o => 'Display',
     },
     { h => 'Just Survey what is to be done',
       t => 'boolean',
       o => 'Survey',
     }
     ];
  bless($self, $class);
  $self->initialize({requiredDbVersion => {},
		  cvsRevision => '$Revision$', # keyword filled in by cvs
		  cvsTag => '$Name$', # keyword filled in by cvs
		  name => ref($self),
		  revisionNotes => 'first pass of plugin for GUS 3.0',
		  easyCspOptions => $easycsp,
		  usage => $usage
		 });

  return $self;
}


# global variables
# --------------------------------------------------------------------

$| = 1;
my $ctx;
my $debug = 0; 
my $extDbId;     # ExternalDatabaseId
my $extDbRelId;  # ExternalDatabaseReleaseId
my $projId;      # ProjectId
my $algId;       # AlgorithmId
my $dbh;         # database query handle
my $Version;


sub run {
  my $self = shift;
  $ctx =shift; 

  $self->logRAIID;
  $self->logCommit;
  $self->logArgs;

  die "Name of the XML file\n" unless $self->getArgs()->{'XmlFile'};

#  my $external_database_release_id = $self->getArgs()->{'extDbRelId'} || 
#      die 'external_database_release_id not supplied\n';

  $dbh = $self->getQueryHandle;

 ### GusApplication::Log('INFO', 'RAIID', $ctx->{self_inv}->getId);

  if ($self->setAlgId) {
    foreach my $glob (@{$ctx->{cla}->{XmlFile}}) {
      my @files = glob($glob);
      foreach my $file (@files) {
	my $tree = $self->parseFile($file);

###  NOTE: use argument to both createObjects and setExtDbId as not $tree, but
###     $tree->{PSEUDOCHROMOSOME} if the PSEUDOCHROMOSOME tag is present in XML,
###     as is the case with falciparum XML, but it is not so for yoelii XML.

	$self->createObjects($tree->{PSEUDOCHROMOSOME}) if ($self->setProjId && $self->setExtDbId($tree->{PSEUDOCHROMOSOME})
					&& $self->setExtDbRelId($tree->{PSEUDOCHROMOSOME}));
      }
    }
  }
  return 1;
}


#
# Loads a TIGR XML file.  Only thing to note here is the need to force
# some tags to be stored as arrays when they occasionally appear as
# singletons.  Add tag names as necessary.
# --------------------------------------------------------------------

sub parseFile{
  my $self = shift;
  my $F = shift;
  
 ### self->log("Loading XML file" . $F);
  print "Loading XML file: $F\n";
  my $xp = XML::Simple->new();
  my $tree = $xp->XMLin($F, forcearray=>['EXON', 'RNA-EXON', 'PRE-TRNA',
					 'GO_ID', 'GO_EVIDENCE',
					 'EC_NUM',
					 'TU']);
  CBIL::Util::Disp::Display($tree) if $ctx->{cla}->{verbose};

  return $tree;
}



# --------------------------------------------------------------------

sub setAlgId {
  my $self = shift;
  $self->log("Finding Algorithm");

  my %alg = ( name => $ctx->{cla}->{Algorithm} ||  'Pf Annotation' );

  my $alg_gus = GUS::Model::Core::Algorithm->new(\%alg);
  if ($alg_gus->retrieveFromDB){
    $algId = $alg_gus->getId;
  } else {
    print "ERROR in returning AlgId\n";
    return undef;
  }
  return 1;
}

sub getAlgId {
  return $algId;
}

# --------------------------------------------------------------------

sub setProjId {
  my $self = shift;
  $self->log("Finding Project");

  my %project = ( name => $ctx->{cla}->{Project} || 'PlasmodiumDB-4.0' );

  my $project_gus = GUS::Model::Core::ProjectInfo->new(\%project);
  if ($project_gus->retrieveFromDB) {
    $projId = $project_gus->getId;
  } else {
    print "ERROR in returning ProjectID\n";
    return undef;
  }
  return 1;
}

sub getProjId {
  return $projId;
}

# --------------------------------------------------------------------

sub setExtDbRelId {
  my $self = shift;
  my $T = shift;

  my $id = $self->getExtDbId;   # the external_database_id;
  $self->log("the external_database_id = ". $id);
  $self->log("Finding ExternalDatabaseReleaseId");

  # ExternalDatabaseRelease
  my %extdbrel;
  $extdbrel{external_database_id} = $id;
  ## NOTE: version may need to be modified; 2 possible values are: 'unknown' and 'final'
  $extdbrel{version} = 'final'; 

  my $extdbrel_gus = GUS::Model::SRes::ExternalDatabaseRelease->new(\%extdbrel);
  if ($extdbrel_gus->retrieveFromDB){
   $extDbRelId = $extdbrel_gus->getExternalDatabaseReleaseId;
  }
  else {
    print "ERROR in returning ExtDbRelId\n";
    return undef;
  }
  return 1;
}

sub getExtDbRelId {
  return $extDbRelId;
}

# --------------------------------------------------------------------

sub setExtDbId {
  my $self = shift;
  my $T = shift;
  $self->log("Finding ExternalDatabaseId");

  # ExternalDatabase
  my %extdb;
  if ($self->{ExtDb}){
    $extdb{lowercase_name} = $self->{ExtDb};
  } else {
    my $seqsrc = $T->{ASSEMBLY}->{HEADER}->{SEQ_GROUP};

    my %dbsrc =
	( 'TIGR'                => 'plasmodium_falciparum_tigr',
	  'Sanger Institute'    => 'plasmodium_falciparum_sanger',
	  'Stanford University' => 'plasmodium_falciparum_stanford',
	  );
    print $dbsrc{$seqsrc} . " -- SOURCE\n";
    $extdb{lowercase_name} = $dbsrc{$seqsrc};
  }

  my $extdb_gus = GUS::Model::SRes::ExternalDatabase->new(\%extdb);
  if ($extdb_gus->retrieveFromDB){
      $extDbId = $extdb_gus->getExternalDatabaseId;
  }
  else {
    print "ERROR in returning ExtDbId\n";
    return undef;
  }
  return 1;
}

sub getExtDbId {
  return $extDbId;
}

# --------------------------------------------------------------------

sub getTaxonId {
  my $self = shift;
  my $T = shift;
  $self->log("Finding TaxonID");

  # Taxon
  my %taxon = ( name => 
		$T->{ASSEMBLY}->{HEADER}->{ORGANISM} || $ctx->{cla}->{Taxon},
	      );

  my $taxon_gus = GUS::Model::SRes::TaxonName->new(\%taxon);
  if ($taxon_gus->retrieveFromDB) {
    return $taxon_gus->getTaxonId;
  }
  else {
    print "ERROR in returning TaxonId\n";
    return undef;
  }
}


# --------------------------------------------------------------------
### To populate relevant objects, by picking up data from tree elements

sub createObjects{
  my $self = shift;
  my $t = shift;  # parsed tree

  # ExternalNASequence entry
  my $ena_gus = $self->makeChromosome($t);

  if ($ena_gus && $ctx->{cla}->{taskFlag} ne'LoadGenomicSequence') {
    # create method name from task.
    my $method = 'TASK_'. $ctx->{cla}->{taskFlag};

    ###$self->log("METHOD: " . $method); 
    # execute it if plugin has a method for it.
    if (my $sub = $self->can($method)) {
      $sub->($self,$t,$ena_gus);
    }
    # otherwise let user known they've messed up.  This is actually
    # also programmer's error since this bad task passed the error
    # checking.
    else {
      $self->log("ERROR: " . "no method found for $ctx->{cla}->{taskFlag}");
    }
  }
}

# --------------------------------------------------------------------
# Initial population of ScaffoldGapFeatures from XML
#  -could be modified to load both the gap features and also 
#   ScaffoldContigFeatures (table not yet created)

### NOTE: NOT YET UPDATED 
sub TASK_ScaffoldGapFeatures {
  my $self = shift; # plugin
  my $X = shift; # hash ref           : XML tree from file.
  my $C = shift; # ExternalNASequence : chromosome

  my $naSeqId = $C->get('na_sequence_id');
  my $seqSrcId = $C->get('source_id');
  my $seqExtDbId = $C->get('external_db_id');
  my $nGaps = 0;
  my $scaffold = $X->{SCAFFOLD};

  if ($scaffold) {
    my $components = $scaffold->{SCAFFOLD_COMPONENT};
    my $ncomp = scalar(@$components);

    # Last value of CHR_RIGHT_COORD 
    my $lastCr = undef;
    # Last value of ASMBL_ID->CLONE_NAME
    my $lastClone = undef;

    for (my $i = 0;$i < $ncomp;++$i) {
      my $comp = $components->[$i];
      my $asmbl_id = $comp->{ASMBL_ID};
      my $clone = $asmbl_id->{CLONE_NAME};
      my $cl = $comp->{CHR_LEFT_COORD};
      my $cr = $comp->{CHR_RIGHT_COORD};
      my $al = $comp->{ASMBL_LEFT_COORD};
      my $ar = $comp->{ASMBL_RIGHT_COORD};
      my $or = $comp->{ORIENTATION};

      # Create ScaffoldGapFeature
      if (defined($lastCr)) {
	my $sg = ScaffoldGapFeature->new({
	    na_sequence_id => $naSeqId,
	    name => 'assembly gap',
	    external_db_id => $seqExtDbId,
	    left_contig => $lastClone,
	    right_contig => $clone,
	});

	my $nal = GUS::Model::DoTS::NALocation->new({
	    start_min => $lastCr,
	    start_max => $lastCr,
	    end_min => $cl,
	    end_max => $cl,
	    is_reversed => 0,
	});

	$sg->addChild($nal);
	$sg->submit();
	++$nGaps;
      } elsif ($cl != 1) {
	  $self->log("WARN: " . "first SCAFFOLD_COMPONENT for $seqSrcId does not start at position 1");
      }

      if ($i == ($ncomp - 1)) {
	my $seqLen = $C->get('length');
	if ($seqLen != $cr) {
	    $self->log("WARN: " . "last SCAFFOLD_COMPONENT for $seqSrcId ends at $cr, not $seqLen");
	}
      }

      $lastCr = $cr;
      $lastClone = $clone;
    }
  }
  $self->log("created $nGaps ScaffoldGapFeatures on $seqSrcId");
}

# --------------------------------------------------------------------
# Initial population of GeneFeatures from XML

sub TASK_GeneFeatures {
  my $self = shift; # plugin
  my $X = shift; # hash ref           : XML tree from file.
  my $C = shift; # ExternalNASequence : chromosome

  # GeneModel entries
  my $ref_gmodel;

  # protein-coding genes
  $ref_gmodel = $X->{ASSEMBLY}->{GENE_LIST}->{PROTEIN_CODING}->{TU};  # array ref
  foreach my $genemodel (@$ref_gmodel){
    $self->makeGeneModel($C, $genemodel, 'protein coding');
  }
  
  # non-protein-coding genes
  $ref_gmodel = $X->{ASSEMBLY}->{GENE_LIST}->{RNA_GENES}->{'PRE-TRNA'};
  foreach my $genemodel (@$ref_gmodel){
    $self->makeGeneModel($C, $genemodel, 'trna');
  }
}

# --------------------------------------------------------------------

sub findGeneFromXml {
  my $self = shift; # plugin
  my $G = shift; # hash ref : TIGR XML at TU level.
  my $C = shift; # ExternalNaSequence : the chromosome.

  my $gene_gus = GUS::Model::DoTS::GeneFeature->new({ na_sequence_id => $C->getId,
				    gene           => $G->{GENE_INFO}->{LOCUS},
				  });

  if ($gene_gus->retrieveFromDB) {
    return $gene_gus;
  } else {
    return undef;
  }
}

# --------------------------------------------------------------------

sub makeProjLink {
  my $self = shift;
  my $T = shift;  # table object;
  my %plink;

  # table
  $plink{table_id} = $T->getTableIdFromTableName($T->getClassName);
  $plink{id}       = $T->getId();

  my $projlink_gus = GUS::Model::DoTS::ProjectLink->new(\%plink);

  if ($projlink_gus->retrieveFromDB) {
    # case when projectLink is in dB
    print "ProjectLink already in DB with ID " . $projlink_gus->getId . "\n";
    return undef;
  } else {
    $projlink_gus->setProjectId($self->getProjId());

    # using setParent method here creates a NEW row in ProjectInfo table, if needed:
    # $projlink_gus->setParent($project_gus);

    $projlink_gus->submit();
    return 1;
  }
}

# --------------------------------------------------------------------

sub map_asmbl_id_to_source_id {
  my $self = shift;
  my $X = shift;

  # map supplied by BG that enforces naming convention.
  my %map = ( 2271 => "pfal_chr1",
	      1400 => "pfal_chr2",
	      1757 => "pfal_chr3",
	      1758 => "pfal_chr4",
	      2272 => "pfal_chr5",
	      2278 => "chr6",
	      2279 => "chr7",
	      2280 => "chr8",
	      2274 => "pfal_chr9",
	      1398 => "chr10",
	      1399 => "chr11",
	      2277 => "chr12",
	      2281 => "chr13_1",
	      2282 => "chr13_2",
	      1396 => "chr14",
	      2283 => "unmapped_1",
	      2284 => "unmapped_2",
	      2285 => "unmapped_3",
	      2286 => "unmapped_4",
	      );
  
  my $x = $X->{ASSEMBLY}->{ASMBL_ID}->{content};
  return $map{$x};
}

# --------------------------------------------------------------------

sub makeChromosome {
  my $self = shift;
  my $T = shift;

  # Find ExternalNASequence
  my %enaSeq = ( taxon_id       => $self->getTaxonId($T),
		 external_database_release_id => $self->getExtDbRelId,
		 );

  # NOTE: for falciparum XML, map_asmbl_id_to_source_id method was used to set 
  #       the source_id appropriately.
  $enaSeq{source_id} = $self->map_asmbl_id_to_source_id($T);
  
  # NOTE: for P_yoelii, source_id is of the form: chrPyl_(\d\d\d\d\d)
  #       so, source_id needs to be cushioned with 0s (zeroes)
  #my $tmpStr = $T->{ASSEMBLY}->{ASMBL_ID}->{content};
  #while (length ($tmpStr) < 5) { $tmpStr = '0'.$tmpStr; }
  #$enaSeq{source_id} = 'chrPyl_' . $tmpStr;
      

  my $ena_gus = GUS::Model::DoTS::ExternalNASequence->new(\%enaSeq);

  # got it
  if ($ena_gus->retrieveFromDB) {
    print "ExternalNASequence already in DB with ID " . $ena_gus->getId . "\n";

    # update if requested by task.  We should do this elsewhere?
    if ($ctx->{cla}->{taskFlag} eq 'UpdateGenomicSequence') {
	
      my $tmp_chr = $ctx->{cla}->{chrnum};
      $tmp_chr =~ s/chr//;

      $enaSeq{chromosome}           = $tmp_chr||$T->{ASSEMBLY}->{CHROMOSOME};
      #  $enaSeq{chromosome}           = 'unmapped';

      $enaSeq{sequence_version}     = 1;
      $enaSeq{sequence_type_id}     = 3;   # for double-stranded DNA
    }
  }
  # couldn't find it
  else {
    # we expect to make new entries.
      if ($ctx->{cla}->{taskFlag} eq 'LoadGenomicSequence') {
	# case when sequence is in dB and may be over-written, OR sequence not in dB

	  ### $ena_gus->setSequenceTypeId     = 3;   # for double-stranded DNA
	  $ena_gus->setSecondaryIdentifier($T->{ASSEMBLY}->{ASMBL_ID}->{content});
	  $ena_gus->setName($T->{ASSEMBLY}->{HEADER}->{CLONE_NAME});
	  $ena_gus->setChromosomeOrderNum($T->{ASSEMBLY}->{CHROMOSOME});
	  #$ena_gus->setSequence($T->{ASSEMBLY}->{ASSEMBLY_SEQUENCE});
	  my $sequence = $T->{ASSEMBLY}->{ASSEMBLY_SEQUENCE};
	  my $cts = &GUS::Community::Sequence::getCounts($sequence, length($sequence), 1);
	  $ena_gus->set('length', length($sequence));
	  $ena_gus->set('a_count', $cts->{'a'});
	  $ena_gus->set('g_count', $cts->{'g'});
	  $ena_gus->set('t_count', $cts->{'t'});
	  $ena_gus->set('c_count', $cts->{'c'});
	  $ena_gus->set('other_count', $cts->{'o'});
	  $ena_gus->setSequence($sequence);
	  $ena_gus->setSequenceTypeId(3);

	  # DEBUG
	  print "Submitting sequence ", length($sequence), "\n";

	  $ena_gus->submit();
	  $self->makeProjLink($ena_gus);
        }

      # couldn't find sequence but expected to; just let 'em know and toss the ExtNaSeq.
      else {
	$self->log("WARN: " . "Did not find matching chromosome " .
		   $T->{ASSEMBLY}->{ASMBL_ID}->{content},
		   $ena_gus->getSourceId
		  );
	undef $ena_gus;
      }
  }
  return $ena_gus;
}

# --------------------------------------------------------------------

sub makeGeneModel {
  my $self = shift;
  my $C = shift; # ExternalNASequence : chromosome
  my $G = shift; # hash ref : XML gene model
  my $T = shift; # string : gene type, i.e., protein coding or trna

  my $trna_src_id;

  $trna_src_id = $G->{TRNA}->{FEAT_NAME};
  $trna_src_id =~ s/(\d+)\.(\S+)/$2/;
  $trna_src_id = $ctx->{cla}->{chrnum} . "-" . $trna_src_id;
  # make the gene feature
  my %gene_feat_h =
    ( external_database_release_id => $self->getExtDbRelId,
      na_sequence_id               => $C->getId,
      gene                         => $G->{GENE_INFO}->{LOCUS} || $G->{TRNA}->{COM_NAME},
      gene_type                    => $T,
      name                         => 'GeneFeature', # other choices: CDS, gene, snRNA, tRNA
      source_id                    => ($T eq 'trna'? $trna_src_id:$G->{GENE_INFO}->{PUB_LOCUS}),
    );

  my $gene_feat_gus = GUS::Model::DoTS::GeneFeature->new(\%gene_feat_h);

  if ($gene_feat_gus->retrieveFromDB && !$ctx->{cla}->{seqFlag}){
    # case when gene feature is in dB, and not to be over-written
    print "GeneFeature already in DB with ID " . $gene_feat_gus->getId . "\n";
    return undef;
  } else {
    # case when gene feature is in dB and may be over-written, OR not in dB
    if ($T eq 'trna'){
      $gene_feat_gus->setFunction("anticodon=". $G->{TRNA}->{ANTICODON});
      $gene_feat_gus->setProduct($G->{TRNA}->{COM_NAME} . " anticodon");
    } else {
      $gene_feat_gus->setProduct($G->{GENE_INFO}->{COM_NAME});
      $gene_feat_gus->setIsPseudo($G->{GENE_INFO}->{IS_PSEUDOGENE});
      $gene_feat_gus->setReviewStatusId($G->{GENE_INFO}->{FUNCT_ANNOT_EVIDENCE}->{TYPE} eq 'CURATED' ? 1 : 0);
      $gene_feat_gus->setConfirmedBySimilarity
	  ($G->{MODEL}->{MODEL_EVIDENCE}->{EVIDENCE_TYPE}->{SEQUENCE_DB_MATCH}->{SEARCH_DB} ? 1 : 0);
    }
    $gene_feat_gus->setPredictionAlgorithmId(getAlgId);
    $gene_feat_gus->setIsPredicted(1);
  }

  $gene_feat_gus ->setParent($C); #new

  # make and attach location, if need be
  my $naloc = &addNALocation($gene_feat_gus,$G->{COORDSET},1);
  $gene_feat_gus -> addChild($naloc); #--check

  if ($T ne 'trna'){
    # add/append note
    addNote($gene_feat_gus, $G->{GENE_INFO}->{COMMENT}, 'COMMENT') if ($G->{GENE_INFO}->{COMMENT});
    addNote($gene_feat_gus, $G->{GENE_INFO}->{PUB_COMMENT}, 'PUB_COMMENT') if ($G->{GENE_INFO}->{PUB_COMMENT});
  }
  # add exons
  my $exons_xml;
  if ($T eq 'protein coding'){
    $exons_xml= $G->{MODEL}->{EXON};
  } elsif ($T eq 'trna'){
    $exons_xml= $G->{TRNA}->{'RNA-EXON'};
  }
  my $exon_reversed=0;

  $gene_feat_gus->setNumberOfExons(scalar @$exons_xml);
  if (scalar @$exons_xml > 0) {
    $gene_feat_gus->setHasInitialExon(1);
    $gene_feat_gus->setHasFinalExon(1);
    # to establish directionality of ordering the exons.
    if (($$exons_xml[0])->{COORDSET}->{END5} > ($$exons_xml[0])->{COORDSET}->{END3}){
      $exon_reversed = 1;
    } 
  }
  if (!$exon_reversed){
    sort orderExons@$exons_xml;
  } else {
    sort revorderExons@$exons_xml;
  }

  for (my $i = 0; $i < @$exons_xml; $i++) {
    addExon($gene_feat_gus, $C, $exons_xml->[$i], $i, scalar @$exons_xml);
  }
  # add further gene-related features
  if ($T eq 'protein coding' ){
    $gene_feat_gus->makePredictedRnaToProtein(undef,
					      $self->getExtDbRelId,
					      $gene_feat_gus->getSourceId);
    # spliced rna sequence
    my $rna_gus = $gene_feat_gus->getChild('DoTS::RNAFeature');      # RNAFeature
    # RNAFeature.review_status_id value to match corresponding GeneFeature value
    $rna_gus->setReviewStatusId($G->{GENE_INFO}->{FUNCT_ANNOT_EVIDENCE}->{TYPE} eq 'CURATED' ? 1 : 0);
    my $sseq_gus = $rna_gus->getParent('DoTS::SplicedNASequence');   # SplicedNASequence

    my $dbSeq = $sseq_gus->getSequence();
    my $cts = &GUS::Community::Sequence::getCounts($dbSeq, length($dbSeq), 1);
    $sseq_gus->set('length', length($dbSeq));
    $sseq_gus->set('a_count', $cts->{'a'});
    $sseq_gus->set('g_count', $cts->{'g'});
    $sseq_gus->set('t_count', $cts->{'t'});
    $sseq_gus->set('c_count', $cts->{'c'});
    $sseq_gus->set('other_count', $cts->{'o'});
      
    $sseq_gus->setTaxonId($C->getTaxonId);

    ### TRANSCRIPT_SEQUENCE: provides unspliced genomic nucleotide sequence representing entire
    ### transcribed region of gene - so not to be used as though earlier

    # translated aminoacid sequence
    my $tas_gus = $gene_feat_gus->getChild('DoTS::RNAFeature')
	->getChild('DoTS::TranslatedAAFeature')
	    ->getParent('DoTS::TranslatedAASequence');

    my $proSeq  = $G->{MODEL}->{PROTEIN_SEQUENCE};
    $proSeq =~ s/\s+//g;         # remove whitespaces (eg: newlines)
    $proSeq =~ tr/[a-z]/[A-Z]/;  # convert to uppercase
    $proSeq =~ s/(\S+)\*$/$1/;   # remove the terminal stop codon

    # check for sequence equality
    if (!$proSeq) {
      print "NO Translated AminoAcid sequence in XML\n";
      # set some sequence in DB??
    } elsif ($tas_gus->getSequence() && ($tas_gus->getSequence() ne $proSeq)) {
      print "Translated AminoAcid sequence does not match with DB entry\n";
      print "TranslatedAAS db Entry = \n" . $tas_gus->getSequence() . "\n";
      print "proteinSeq in XML: \n" . $proSeq . "\n"; ## remove --check
      $tas_gus->setSequence($proSeq) if $ctx->{cla}->{seqFlag};
    } else {
      print "Translated AminoAcid sequence identical\n";
      $tas_gus->setSequence($proSeq);
    }
    ##FILL	$tas_gus->setDescription
    ##FILL	$tas_gus->setSecondaryId
      
  } elsif ($T eq 'trna'){
    $gene_feat_gus->makePredictedRna(undef,
				     $self->getExtDbRelId,
				     $gene_feat_gus->getSourceId);
  }

  $gene_feat_gus->submit();
  $self->makeProjLink($gene_feat_gus);
  
  $gene_feat_gus->submit();
}

# --------------------------------------------------------------------

sub orderExons {
  $a->{COORDSET}->{END5} <=> 	$b->{COORDSET}->{END5};
}

sub revorderExons {
  $b->{COORDSET}->{END5} <=> 	$a->{COORDSET}->{END5};
}

# --------------------------------------------------------------------

sub addNALocation {
  my $F = shift; # NAFeature
  my $C = shift; # hash ref : XML COORDSET
  my $O = shift; # int : order number

  my $start       = $C->{END5};
  my $stop        = $C->{END3};
  my $is_reversed = 0;

  if ($start > $stop) {
    ($start,$stop) = ($stop, $start);
    $is_reversed = 1;
  }

  my $l = GUS::Model::DoTS::NALocation->new({'start_min'   => $start,
			   'start_max'   => $start,
			   'end_min'     => $stop,
			   'end_max'     => $stop,
			   'is_reversed' => $is_reversed
			  });
  $l->set('loc_order',$O) if $O;
  $l->setParent($F);

  return $l;
}

# --------------------------------------------------------------------

sub addNote {
  my $F = shift;   # NAFeature
  my $S = shift;   # string: note
  my $rem = shift; # string

  $rem = "Sequencing Center " . $rem;
  my $n = GUS::Model::DoTS::NAFeatureComment->new
      ({'comment_string'   => $rem . $S,
       });
  $n->setParent($F);

  return $n;
}

# --------------------------------------------------------------------

sub addExon {
  my $G = shift; # GeneFeature
  my $C = shift; # ExternalNASequence : chromosome
  my $E = shift; # hash ref : XML EXON
  my $O = shift; # int : order number
  my $l = shift; # length of exon array

  # make the ExonFeature
  my %exon_h = 
    ( external_database_release_id => getExtDbId,
      na_sequence_id               => $C->getId,
      source_id                    => $E->{FEAT_NAME},
      prediction_algorithm_id      => $G->getPredictionAlgorithmId,
      is_predicted                 => $G->getIsPredicted,
      review_status_id             => $G->getReviewStatusId,
      order_number                 => $O+1,  # NOTE: starting exon order_number with 1
      coding_start                 => abs($E->{COORDSET}->{END5} -
					  $E->{CDS}->{COORDSET}->{END5})+1,
      name                         => 'ExonFeature',
      coding_end                   => abs($E->{COORDSET}->{END5} -
					  $E->{CDS}->{COORDSET}->{END3})+1,
      );
  $exon_h{is_initial_exon} = 1 if ($O == 0);
  $exon_h{is_final_exon} = 1 if ($O == $l-1);

  my $exon_gus = GUS::Model::DoTS::ExonFeature->new(\%exon_h);

  # give it a location
  addNALocation($exon_gus,$E->{COORDSET},1);

  # attach to GeneFeature
  $exon_gus->setParent($G);

  return $exon_gus;
}


# ====================================================================
# Fixes atributes of GeneFeatures.
#
# 1: enforce pseudo-gene status.

sub TASK_FixGeneFeatures {
  my $self = shift; # plugin
  my $X = shift; # hash ref           : XML tree from file.
  my $C = shift; # ExternalNASequence : chromosome

  # get the (protein coding) genes on this assembly.
  my $genes_xml = $X->{ASSEMBLY}->{GENE_LIST}->{PROTEIN_CODING}->{TU};
  # count found and fixed genes
  my $found_genes_n = 0;

  # count missing genes
  my $missing_genes_n = 0;

  # process each one.
  foreach my $gene_xml (@$genes_xml) {

    # find the gene feature
    if (my $gene_gus = $self->findGeneFromXml($gene_xml,$C)) {
      # count found genes
      $found_genes_n++;

      # fix genes
      # ........................................

      # adjust pseudogene settings.
      $self->log("TALLY: " . $gene_gus->getSourceId,
		 $gene_gus->getIsPseudo,
		 $gene_xml->{GENE_INFO}->{IS_PSEUDOGENE});
      $gene_gus->setIsPseudo($gene_xml->{GENE_INFO}->{IS_PSEUDOGENE});
      # put more fixes here as needed.
      # at end of fixes
      # ........................................

      unless ($ctx->{cla}->{Survey}) {
	$gene_gus->submit;
      }
      $gene_gus->undefPointerCache;
    }

    # could not find the gene features
    else {
      # count missing genes
      $missing_genes_n++;

      # give a warning.
      $self->log("WARN: ". 'Could not get GeneFeature',
		 $gene_xml->{GENE_INFO}->{PUB_LOCUS},
		 $gene_xml->{GENE_INFO}->{COM_NAME},
		 );
    }
  } # eo genes
  $self->log("STATUS: " . 
	     "Found and repaired $found_genes_n genes." .
	     "  There were $missing_genes_n missing genes."
	     );
}

# ====================================================================
# Attaches AASequenceEnzymeClass rows to TranslatedAASequences.

sub TASK_EcAnnotation {
  my $self = shift; # plugin
  my $X = shift; # hash ref           : XML tree from file.
  my $C = shift; # ExternalNASequence : chromosome

  require GUS::Model::DoTS::AASequenceEnzymeClass;
  require GUS::Model::SRes::EnzymeClass;
  # get the (protein coding) genes on this assembly.
  my $genes_xml
      = $X->{ASSEMBLY}->{GENE_LIST}->{PROTEIN_CODING}->{TU};

  # number of associations made
  my $assoc_made_n = 0;

  # number of associations supplied
  my $assoc_given_n = 0;

  # EnzymeClass object cache.
  my $ec_cache_x = {};

  # process each one.
  foreach my $gene_xml (@$genes_xml) {
    # find any EC annotation it has
    my $ec_xml     = $gene_xml->{GENE_INFO}->{EC_NUM};
    my $ec_annot_n = defined $ec_xml ? scalar @$ec_xml : 0;
    $self->log("Count " .
	       $gene_xml->{GENE_INFO}->{PUB_LOCUS},
	       $ec_annot_n);
    CBIL::Util::Disp::Display($ec_xml) if $ctx->{cla}->{Display};

    # count the number of associations given
    $assoc_given_n += $ec_annot_n;

    # process if it has some
    if ($ec_annot_n) {
      # find a gene then get its RNAFeature, TranslatedAAFeature,
      # and finally its TranslatedAASeq.

      if (my $gene_gus = $self->findGeneFromXml($gene_xml,$C)) {
        if (my ($rna_feat_gus) = $gene_gus->getChild('DoTS::RNAFeature',1)) {
	  if (my ($xaa_feat_gus) = $rna_feat_gus->getChild('DoTS::TranslatedAAFeature',1)) {
	    if (my ($xaa_seq_gus)  = $xaa_feat_gus->getParent('DoTS::TranslatedAASequence',1)) {
	      # process the links.
	      foreach my $asn_xml (@$ec_xml) {
		# clean up the EC number
		$asn_xml =~ s/_/-/g;  # convert underscore to hyphens
		$asn_xml =~ s/\.$//;  # remove trailing dots.

		# get the EnzymeClass
		my $ec_gus = $ec_cache_x->{$asn_xml};
		unless ($ec_gus) {
		  $ec_gus = GUS::Model::SRes::EnzymeClass->new({ ec_number => $asn_xml, external_database_release_id=>7199 });
		  if ($ec_gus->retrieveFromDB) {
		    $ec_cache_x->{$asn_xml} = $ec_gus;
		  } else {
		    $ec_gus = undef;
		    $self->log("WARN: " . "Could not find EnzymeClass " .
			       $asn_xml );
		  }
	        }

		# make the association if we found an
	        # EnzymeClass and process parents as well.
		
		while ($ec_gus) {
		  my $aaSequenceEnzymeClass =
		      GUS::Model::DoTS::AASequenceEnzymeClass->new({ evidence_code        => 'UNK',
						   review_status_id=> 1,
					       });
		  # note that these are done on the  attributes so that 
		  # we can check for prexisting annotations.
		  $aaSequenceEnzymeClass->setAaSequenceId($xaa_seq_gus->getId);
		  $aaSequenceEnzymeClass->setEnzymeClassId($ec_gus->getId);

		  my $new_or_old;
		  if ($aaSequenceEnzymeClass->retrieveFromDB) {
		    $new_or_old = 'old';
		  } else {
		    $new_or_old = 'new';
		    $aaSequenceEnzymeClass->submit() unless $ctx->{cla}->{Survey};
		    $assoc_made_n++;
		  }
		  $self->log("$new_or_old" . 
			     $gene_xml->{GENE_INFO}->{PUB_LOCUS},
			     $gene_xml->{GENE_INFO}->{COM_NAME},
			     $ec_gus->getEcNumber);
		  
		  # get parent.
		  my $ec_parent_gus = $ec_gus->getParent('SRes::EnzymeClass',1);
		  if (!$ec_parent_gus) {
		    $self->log("WARN: " . 'No parent found',
			       $ec_gus->getEcNumber,
			       $gene_xml->{GENE_INFO}->{PUB_LOCUS},
			       $gene_xml->{GENE_INFO}->{COM_NAME},
			       );
		    last;
		  }

		  # bail out at root.
		  elsif ($ec_parent_gus->getDepth == 0) {
		    last;
		  }

		  # make parent the 'current' EC.
		  else {
		    $ec_gus = $ec_parent_gus;
		  }
	        }
	      } # eo associations for a gene
	    } else {
	      $self->log("WARN: " .
			 'Could not get TranslatedAASequence',
			 $xaa_feat_gus->getId,
			 );
	    }
	  } else {
	      $self->log("WARN: " .
			 'Could not get TranslatedAAFeature',
			 $rna_feat_gus->getId,
			 );
	  }
        } else {
	  $self->log("WARN" .
		     'Could not get RNAFeature',
		     $gene_gus->getId,
		     );
        }
      } else {
	$self->log("WARN: ".
		   'Could not get GeneFeature',
		   $gene_xml->{GENE_INFO}->{PUB_LOCUS},
		   $gene_xml->{GENE_INFO}->{COM_NAME},
		   );
      }
    } # eo XML gene has go annotation
  } # eo XML gene scan
  $self->log("Made $assoc_made_n associations given $assoc_given_n associations.");
}

# ======================================================================
# Attaches GO annotation for a TIGR XML gene to AASequences associated
# with a GUS GeneFeature.

### NOTE: NOT YET UPDATED
sub TASK_GoAnnotation {
  my $self = shift; # plugin
  my $X = shift; # hash ref           : XML tree from file.
  my $C = shift; # ExternalNASequence : chromosome

  require GUS::Model::DoTS::AASequenceGOProcess;
  require GUS::Model::DoTS::AASequenceGOComponent;
  require GUS::Model::DoTS::AASequenceGOFunction;

  require GUS::Model::DoTS::ProteinGOProcess;
  require GUS::Model::DoTS::ProteinGOComponent;
  require GUS::Model::DoTS::ProteinGOFunction;

  # make sure we have cached the GO terms.
  $self->goPopulateCache($dbh);

  # load the synonym cache
  $self->goLoadSynonyms;

  # get the (protein coding) genes on this assembly.
  my $genes_xml = $X->{ASSEMBLY}->{GENE_LIST}->{PROTEIN_CODING}->{TU};

  # number of associations made
  my $assoc_made_n = 0;

  # number of associations supplied
  my $assoc_given_n = 0;

  # process each one.
  foreach my $gene_xml (@$genes_xml) {

    # find any GO annotation it has
    my $go_xml = $gene_xml->{GENE_INFO}->{GENE_ONTOLOGY}->{GO_ID};
    my $go_annot_n = defined $go_xml ? scalar @$go_xml : 0;
    $self->log("GOANON" . $gene_xml->{GENE_INFO}->{PUB_LOCUS}, $go_annot_n);
    CBIL::Util::Disp::Display($go_xml) if $ctx->{cla}->{Display};

    # count the number of associations given
    $assoc_given_n += $go_annot_n;

    # process if it has some
    if ($go_annot_n) {

      # indicate what kinds of annotation this is.
      foreach (@$go_xml) {
	my $cache = $self->goLookupInCache($_->{ASSIGNMENT});
        $self->log($_->{ASSIGNMENT} . 
		   $cache->{go_table_id}, );
      }

      # find a gene then get its RNAFeature, TranslatedAAFeature,
      # and finally its TranslatedAASeq.

      if (my $gene_gus = $self->findGeneFromXml($gene_xml,$C)) {
	if (my ($rna_feat_gus) = $gene_gus->getChild('RNAFeature',1)) {
	  if (my ($xaa_feat_gus) = $rna_feat_gus->getChild('TranslatedAAFeature',1)) {
	    if (my ($xaa_seq_gus)  = $xaa_feat_gus->getParent('TranslatedAASequence',1)) {
	      # process the links.
	      foreach my $asn_xml (@$go_xml) {
		my $go_evidence = 
		    join(',',
			 map { $_->{EV_CODE}->{CODE} } @{$asn_xml->{GO_EVIDENCE}}
			 );
		$assoc_made_n +=
		    $self->goMakeSequenceLink($asn_xml->{ASSIGNMENT},
					      $xaa_seq_gus,
					      $go_evidence
					      );
	      }
	      $xaa_seq_gus->submit();
	      
	    } else {
	      $self->log("WARN: " . 'GOASSOC' .
			 'Could not get TranslatedAASequence',
			 $xaa_feat_gus->getId,
			 );
	    }
	  } else {
	    $self->log("WARN:" . 'GOASSOC',
		       'Could not get TranslatedAAFeature',
		       $rna_feat_gus->getId,
		       );
	  }
        } else {
	  $self->log("WARN: " . 'GOASSOC',
		     'Could not get RNAFeature',
		     $gene_gus->getId,
		     );
        }
	
	$gene_gus->undefPointerCache;
      } else {
	$self->log("WARN: " . 'GOASSOC',
		   'Could not get GeneFeature',
		   $gene_xml->{GENE_INFO}->{PUB_LOCUS},
		   $gene_xml->{GENE_INFO}->{COM_NAME},
		   );
      }
    } # eo XML gene has go annotation
  } # eo XML gene scan

  $self->log("GOASSOC" .
	     "Made $assoc_made_n associations given $assoc_given_n associations."
	     );
}

# --------------------------------------------------------------------
# Loads a cache of (naked) GO ids mapped to a useful structure.

# Note that the query is not done on go_cvs_version since not all
# tables have this column.

sub goPopulateCache {
  my $self = shift; # plugin
  my $H = shift; # db handle :

  return if $self->{GoTermCache};

  $self->log("GOCACHE" . 'Loading GoCache');

  # count how many terms we find.
  my %counts;

  # divisions
  my @divisions = qw( Function Process Component ) ;

  # load each division
  foreach my $division (@divisions) {

    # table names
    my $table    = 'GO'. $division;
    my $hier_tbl = $table. 'Hierarchy';

    # selection atribute
    my $attr = lc "go_${division}_id";

    # terse access to go version;
    my $go_version = $self->{$division. 'GoCvsVersion'};

    # load terms
    # ......................................................................
    {
	# query SQL
	my $sql = sprintf("select go_id, $attr, name from $table where go_version like '%%%s%%'",
			  $go_version);
        $self->log('GOCACHE' . $sql);
	my $sh  = $H->prepareAndExecute($sql);

	# populate cache
	while (my ($go_id, $go_gus_id, $name) = $sh->fetchrow_array) {
	  $self->{GoTermCache}->{$go_id} = { go_id     => $go_id,
					     go_gus_id => $go_gus_id,
					     gus_table => $table,
					     gus_attr  => $attr,
					     go_term   => substr($name,0,32),
					 };
	  $counts{$division}++;
        }
	$sh->finish;
      }

    # load links
    # ......................................................................
    {
      # query SQL
      my $sql = <<HierSql;

      select h.$attr, t.go_id
	  from $table t, $hier_tbl h
          where h.parent_id = t.$attr
              and t.go_version    like '\%$go_version\%'
		  
HierSql

      $self->log('GOCACHE' . $sql);
      my $sh  = $H->prepareAndExecute($sql);

      # populate cache
      while (my ($child_gus_id, $parent_go_id) = $sh->fetchrow_array) {
	$self->{GoEdgeCache}->{$child_gus_id}->{$parent_go_id} = 1;
      }
      $sh->finish;
    }
  }
   $self->log('GOCACHE' . map { "$_=$counts{$_}" } @divisions );
}

# --------------------------------------------------------------------

sub goLoadSynonyms {
  my $self = shift;

  if (!$self->{GoSynonymCache}) {
    $self->{GoSynonymCache} = {};

    if ($self->{GoSynonymFile}) {
      if (my $fh = FileHandle->new('<'. $self->{GoSynonymFile})) {
	while (<$fh>) {
	    chomp;
	    s/GO:0+//g;
	    my ($new, $old) = split /\t/;
	    $self->{GoSynonymCache}->{$old} = $new;
	}
	$fh->close;
      } else {
	$self->log("WARN: " . 'Could not open GoSynoymFile',
		   $self->{GoSynonymFile},
		   $!);
      }
    }
  }
}

# --------------------------------------------------------------------

sub goLookupInCache  {
  my $self = shift; # plugin
  my $G = shift; # string : GO id

  # get the GO in the proper format.
  my $g = $G; $g =~ s/GO://; $g += 0; # convert to an integer.

  # get description.
  my $cache_entry = $self->{GoTermCache}->{$g} || $self->{GoTermCache}->{$self->{GoSynonymCache}->{$g}};

  return $cache_entry;
}

# --------------------------------------------------------------------

sub goMakeProteinLink {
  my $self = shift; # plugin
  my $G = shift; # string  : target GO id
  my $O = shift; # GUS obj : target object
  my $R = shift; # boolean : manually reviewed
  my $C = shift; # string  : confidence
  my $N = shift; # string  : reviwer notes

  my $cache_entry = $self->goLookupInCache($G);

  # make sure cache is loaded
  $self->log("ERROR: " . 'goMakeLink', 'cache is not loaded') if scalar keys %{$self->{GoTermCache}} < 1;

  # figure out the link table name
  my $link_name = "Protein$cache_entry->{gus_table}";

  # create a link object
  #require "GUS::Model::DoTS::$link_name";
  my $link_obj = eval "new $link_name";

  # link to GO term.
  $link_obj->set($cache_entry->{gus_attr},$cache_entry->{go_gus_id});

  # link to bio object
  $link_obj->setParent($O);

  # set other info
  $link_obj->setManuallyReviewed($R);
  $link_obj->setConfidence($C);
  $link_obj->setReviewerNotes($N);

  # done
  return $link_obj;
}

# --------------------------------------------------------------------

sub goMakeSequenceLink {
  my $self = shift; # plugin  :
  my $G = shift; # string  : target GO id
  my $O = shift; # GUS obj : target object
  my $E = shift; # string  : go evidence

  # RETURN : integer : number of links made
  my $RV = 0;

  # make sure cache is loaded
  $self->log("ERROR: " . 'goMakeLink', 'cache is not loaded') if scalar keys %{$self->{GoTermCache}} < 1;

  # a queue of GO ids to process
  my @go_id_queue = ($G);

  # a hash of GO ids we've processed
  my %go_id_history;

  # process GO ids as long as queue is not empty
  while (my $g = pop @go_id_queue) {
    # skip this if we've seen it before.
    next if $go_id_history{$g};

    # note that we've seen this
    $go_id_history{$g} = 1;

    # find cache element
    if (my $cache_entry = $self->goLookupInCache($g)) {

      # figure out the link table name
      my $link_name = "AASequence$cache_entry->{gus_table}";

      # create a link object
      #require "GUS::Model::DoTS::$link_name";
      my $link_obj = eval "new $link_name";

      # link to GO term.
      $link_obj->set($cache_entry->{gus_attr},$cache_entry->{go_gus_id});

      # link to bio object
      $link_obj->setParent($O);

      # set other info
      $link_obj->setGoEvidence($E);

      # log
      $self->log('GOCACHE',
		 $G, $cache_entry->{go_gus_id}, $cache_entry->{gus_table},
		 $cache_entry->{go_term},
		 $O->getDescription, $E);
      
      # add parent GO ids to queue
      push(@go_id_queue, keys %{$self->{GoEdgeCache}->{$cache_entry->{go_gus_id}}});

      $RV++;
    }

    # log missing cache entry
    else {
      $self->log("WARN: " . 'Missing GoTermCache entry', $g);
    }
  }

  return $RV;
}

# --------------------------------------------------------------------


if ( $0 !~ /ga$/i ) {

  my $usg = Usage();
  my $name = $0; $name =~ s/\.pm$//; $name =~ s/^.+\///;
  my $md5 = `/usr/bin/md5sum $0`;
  chomp $md5;
  $md5 =~ s/^(\S+).+/$1/;

  print <<XML;
<Algorithm xml_id="1001">
  <name>$name</name>
  <description>$usg</description>
</Algorithm>

<AlgorithmImplementation xml_id="1002" parent="1001">
  <version>$Version</version>
  <executable>$0</executable>
  <executable_md5>$md5</executable_md5>
</AlgorithmImplementation>
XML

}

1;
