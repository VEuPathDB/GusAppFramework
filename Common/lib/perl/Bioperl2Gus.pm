
package GUS::Common::Bioperl2Gus;

# ----------------------------------------------------------
# Bioperl2Gus.pm
#
# A package to hold the mapping of Bioperl to GUS
#
# Created: 
#
# Original by Arnaud Kerhornou (GUSdev)
# Modified by Paul Mooney (GUS3.0)
# ----------------------------------------------------------



use strict;
use Data::Dumper;
use Carp;

use GUS::Model::DoTS::ExternalNASequence;
use GUS::Model::SRes::Taxon;
use GUS::Model::SRes::TaxonName;

use GUS::Model::DoTS::SequenceType;
use GUS::Model::DoTS::PfamEntry;
use GUS::Model::DoTS::GeneFeature;
use GUS::Model::DoTS::ExonFeature;
use GUS::Model::DoTS::NALocation;
use GUS::Model::DoTS::AALocation;
use GUS::Model::DoTS::RNAFeature;
use GUS::Model::DoTS::SplicedNASequence;
use GUS::Model::DoTS::RNAFeatureExon;
use GUS::Model::DoTS::TranslatedAAFeature;
use GUS::Model::DoTS::TranslatedAASequence;
use GUS::Model::DoTS::ProteinFeature;
use GUS::Model::DoTS::PredictedAAFeature;
use GUS::Model::DoTS::SignalPeptideFeature;
use GUS::Model::DoTS::Gene;
use GUS::Model::DoTS::RNA;
use GUS::Model::DoTS::Protein;
use GUS::Model::Core::Algorithm;
use GUS::Model::DoTS::GeneSynonym;

use GUS::Model::DoTS::GeneInstance;
use GUS::Model::DoTS::GeneInstanceCategory;

use GUS::Model::DoTS::RNAInstance;
use GUS::Model::DoTS::RNAInstanceCategory;

use GUS::Model::DoTS::ProteinInstance;
use GUS::Model::DoTS::ProteinInstanceCategory;

#use GUS::Model::DoTS::GeneSequence;        # replaced by:  DoTS::GeneInstance
#use GUS::Model::DoTS::RNASequence;         # replaced by:  DoTS::RNAInstance
#use GUS::Model::DoTS::RNASequenceType;     # replaced by:  DoTS::RNAInstanceCategory
#use GUS::Model::DoTS::ProteinSequence;     # replaced by:  DoTS::ProteinInstance

#use GUS::Model::DoTS::Note; # !!!!! THIS NO LONGER EXISTS!!!!!!!!!!!!!!!!!!!!!!



# The GO stuff in the schema is scary bananas...
#
use GUS::Model::SRes::GOTerm;
use GUS::Model::DoTS::GOAssociation;
use GUS::Model::DoTS::GOAssociationInstance;
use GUS::Model::DoTS::GOAssociationInstanceLOE;
use GUS::Model::DoTS::GOAssocInstEvidCode;

use GUS::Model::SRes::GOEvidenceCode;

use GUS::Model::DoTS::Evidence;
use GUS::Model::SRes::ExternalDatabaseEntry;


# Bioperl
use Bio::SeqUtils;

################################################################################
# CONSTANTS
################################################################################

my $REVIEW_STATUS_ID = 5;

################################################################################
# SUBROUTINES
################################################################################


sub new {
  my $invocant = shift;
  my $class    = ref ($invocant) || $invocant;

  if(@_ % 2) {
    croak "Default options must be name => value pairs (odd number supplied)";
  }

  my %args         = @_;
  my $debug        = 0 || $args{'debug'};
  my $sequenceType = undef || $args{'sequenceType'};

  my $self = {
	      bioperlSequence  => undef,
	      bioperlFeature   => undef,
	      sequenceType     => $sequenceType,
	      debug            => $debug,
	      gusSequence      => undef,
	      @_,
	     };
  bless ($self, $class);
  return $self;
}

###################################
# Set the Bioperl Sequence object
#
##

sub setDebug {
  my $self = shift;
  $self->{'debug'} = shift;
}

###################################
# Set the Bioperl Sequence object
#
##

sub setBioperlSequence {
  my $self = shift;
  my ($bioperl_seq) = @_;
  $self->{bioperlSequence} = $bioperl_seq;
}

##################################
# Get the Bioperl Sequence object
#
##

sub getBioperlSequence {
  my $self = shift;
  return $self->{bioperlSequence};
}

##################################
# Set the Bioperl Feature object
#
##

sub setBioperlFeature {
  my $self = shift;
  my ($bioperl_feature) = @_;
  $self->{bioperlFeature} = $bioperl_feature;
}

##################################
# Get the Bioperl Feature object
#
##

sub getBioperlFeature {
  my $self = shift;
  return $self->{bioperlFeature};
}

##################################
# Set the type of sequence
# e.g. DNA, GSS, EST
##

sub setSequenceType {
  my $self = shift;
  my ($seq_type) = @_;
  $self->{sequenceType} = $seq_type;
}

##################################
# Get the Bioperl Sequence object
#
##

sub getSequenceType {
  my $self = shift;
  return $self->{sequenceType};
}

##################################
# Set the GUS Sequence object
#
##

sub setGusSequence {
  my $self = shift;
  my ($gus_seq) = @_;
  $self->{gusSequence} = $gus_seq;
}

##################################
# Get the GUS Sequence object
#
##

sub getGusSequence {
  my $self = shift;
  return $self->{gusSequence};
}


##################################
##################################
#
# Build Gusdev Objects methods
#
##################################
##################################


##################################
# Build Gusdev ExternalNASequence object
##################################

sub buildNASequence {
  my ($self, $gus_seq) = @_;

  my $bioperl_sequence = $self->{bioperlSequence};
  my $sequenceType     = $self->{sequenceType};
  my $debug            = $self->{debug};

  if (not (defined ($bioperl_sequence) && defined ($sequenceType))) {
    print STDERR "ERROR - can't generate the NA Sequence object, bioperl sequence object or sequence type not specified !!\n";
    return undef;
  }

  my $seq_type_id = getSequenceTypeIdentifier ($sequenceType);
  # the description is into the description or the definition tags
  my $seq_descr   = $bioperl_sequence->desc;
  my $seq         = $bioperl_sequence->seq;
  my $length      = length ($seq);
  my %basesCount  = getBasesCount ($seq);
  my $a_count     = $basesCount{a};
  my $t_count     = $basesCount{t};
  my $c_count     = $basesCount{c};
  my $g_count     = $basesCount{g};
  my $other_count = $basesCount{o};
  my $accession   = $bioperl_sequence->accession_number;
  my $id          = $bioperl_sequence->display_id;
  # name - the only thing is ID
  my $name        = $id;

  my $seq_version = "1";

  # FIXME: Arnaud, please check this is correct, I can not find Seq::seq_version
  #        in the Bioperl API.

  #if ($bioperl_sequence->seq_version()) {
  if ($bioperl_sequence->version()) {
    # seq version is not the bioperl interface but present into GB file
    $seq_version = $bioperl_sequence->seq_version();
  }

  # chromosome and organism info from the 'source' feature
  
  # chromosome is not an attribute of ExternalNASequence => into the source_id field
  
  my $chromosome       = undef;
  my $organism         = undef;
  my $chr_order_number = undef;
  my @features         = $bioperl_sequence->get_all_SeqFeatures();

  #print STDERR "\n*** \$bioperl_sequence = $bioperl_sequence\n\n";
  #print STDERR "Dumper: ",Dumper($bioperl_sequence), "\n";
  print STDERR "number of features = ", scalar(@features), "\n";

  foreach my $feature (@features) {
    print "primary_tag = ", $feature->primary_tag, "\n";

    if ($feature->primary_tag() =~ /source/) {

      my @tags = $feature->all_tags();

      if ($debug) {
	print STDERR "found source feature\n";
	print STDERR "tags: @tags\n";
      }

      foreach my $tag (@tags) {
	if ($tag =~ /chromosome$/i) {
	  my @values = $feature->each_tag_value('chromosome');
	  $chromosome = $values[0];
	}
	elsif ($tag =~ /organism/i) {
	  my @values = $feature->each_tag_value('organism');
	  $organism = $values[0];
	}
	elsif ($tag =~ /chromosome_order_number/i) {
	  my @values = $feature->each_tag_value('chromosome_order_number');
	  $chr_order_number = $values[0];
	}
      }
    }
    last;
  }

  if (not defined $organism) {
    print STDERR "don't know which organism this sequence is attached to !!!\n";
    exit 1;
  }

  my $taxon_id = getTaxonIdentifier ($organism);
  my $source_id = "chr. " . $chromosome;

  print STDERR "organism, taxon id: $organism, $taxon_id\n";

  my $h = {
	   'sequence_type_id' => $seq_type_id,
	   'taxon_id'         => $taxon_id,
	   'name'             => $name,
	   'sequence_version' => $seq_version,
	   'description'      => $seq_descr,
	   'sequence'         => $seq,
	   'a_count'          => $a_count,
	   'c_count'          => $c_count,
	   'g_count'          => $g_count,
	   't_count'          => $t_count,
	   'other_count'      => $other_count,
	   'length'           => $length,
	   'source_id'        => $source_id,
	   'chromosome'       => $chromosome,
	  };

  # $gus_seq may have been passed in just to be brought up-to-date
  #
  unless (defined $gus_seq) {
      $gus_seq = GUS::Model::DoTS::ExternalNASequence->new ($h);
  }
  else {
      # Reset attribute values for existing sequence obj
      foreach my $att (keys %{$h}) {
          $gus_seq->set($att, $h->{$att});
      }
  }

  if (defined $chr_order_number) {
    $gus_seq->setChromosomeOrderNum ($chr_order_number);
  }

  $self->{gusSequence} = $gus_seq;
  return $gus_seq;
}

#########################
# Build Feature Objects
##

sub buildGeneFeature {
  my ($self, $number_of_exons, $gene_type, $is_partial) = @_;

  my $debug             = $self->{debug};
  my $bioperl_feature   = $self->{bioperlFeature};
  my $gus_sequence      = $self->{gusSequence}; # This is a cheat for mRNA - maybe have a fake sequence called chromosome "unknown"?

  my @gus_note_objects = ();

  #######################################
  # WAS
  #######################################

  # standard name => the systematic name - UNIQUE
  # name => primary name

  ##################################
  # NOW
  ##################################

  ##################################
  # systematic_id or temporary_systematic_id => standard name
  # => compulsory
  # name => primary name
  # => not compulsory
  # + synonym(s)

  ########################################
  # deprecated code
  # => commented !!

  ##
  # my @names = $bioperl_feature->each_tag_value ('standard_name');
  # my $standard_name = $names[0];
  ##

  my $systematic_id = undef;

  if ($bioperl_feature->has_tag ('systematic_id')) {
    my @systematic_ids = $bioperl_feature->each_tag_value ('systematic_id');
    $systematic_id = $systematic_ids[0];
  }
  elsif ($bioperl_feature->has_tag ('temporary_systematic_id')) {
    my @systematic_ids = $bioperl_feature->each_tag_value ('temporary_systematic_id');
    $systematic_id = $systematic_ids[0];
  }
  else {
    print STDERR "ERROR - no systematic or temporary systematic id set up!!!\n";
  }

  #########################################

  #########################################
  # new naming convention implementation

  my $primary_name = undef;
  if ($bioperl_feature->has_tag ('primary_name')) {

    my @primary_names = $bioperl_feature->each_tag_value ('primary_name');
    $primary_name = $primary_names[0];

    print STDERR "\n*** WOW *** primary name = '$primary_name'\n\n";
  }  

  #########################################

  my $is_predicted      = 1;
  my $review_status_id  = $REVIEW_STATUS_ID;
  my $na_sequence_id    = $gus_sequence->getNaSequenceId ();
  my $subclass_view     = "GeneFeature";

  # may not have a product if it's a pseudo gene
  #
  my $product = undef;

  if ($bioperl_feature->has_tag ('product')) {
    my @products = $bioperl_feature->each_tag_value ('product');
    # may have several product tags
    # in that case, the product is the first element of the products list
    $product = $products[0];
  }

  ####################################
  # to figure out if it's partial, other way is to parse the Bioperl Range object
  # e.g. => <1..200>
  # it is done before calling buildGeneFeature, so this information is in $is_parital parameter
  ####################################

  if ($bioperl_feature->has_tag ('partial')) {
    $is_partial = 1;
  }

  my $is_pseudo = 0;
  if ($gene_type =~ /pseudogene/i) {
    $is_pseudo = 1;
  }

  my $prediction_algorithm_id = undef;
  if ($bioperl_feature->has_tag ('method')) {
    my @methods = $bioperl_feature->each_tag_value ('method');
    my $method = $methods[0];

    if ($method =~ /manual annotation/i) {
      $method = "Manual Annotation";
    }
    elsif ($method =~ /automatic annotation/i) {
      $method = "Automatic Annotation";
    }

    my $algo = GUS::Model::Core::Algorithm->new ({'name' => "$method"});
    my $result = $algo->retrieveFromDB();

    if ($result == 1) {
      $prediction_algorithm_id = $algo->getAlgorithmId();
    }
    else {
      # Annotate the gene feature as a 'Manual Annotation' per default
      $algo   =
        GUS::Model::Core::Algorithm->new ({'name' => "Manual Annotation"});
      $result = $algo->retrieveFromDB();

      if ($result == 1) {
	$prediction_algorithm_id = $algo->getAlgorithmId();
      }
    }
  }
  
  # the source_id is a unique identifier for the gene
  # => the gene name
  
  # my $source_id = $gus_sequence->getSourceId();
  # my $source_id = $standard_name;
  my $source_id = $systematic_id;

  ##############################################
  # Attribution Site in a Contact Entry
  ##############################################

  # gusdev hasn't been designed to cover attributions data
  # GUS3 has an attribution table to fill the gap
  # But with gusdev, if it's really needed, it is possible though to use the evidence table to link Contacts and Features.

  my $attribution_site = undef;
  if ($bioperl_feature->has_tag ('attribution_site')) {
    my @attribution_sites = $bioperl_feature->each_tag_value ('attribution_site');
    $attribution_site = $attribution_sites[0];
  }

  # Contact and Evidence Entries Generation ...
  # ...

  ##############################################

  # FIXME;
  # if several 'product' tag, take the first one.
  # for the following ones, there is no GUS column to put them into !!
  # in a description attribute - concatenation of the product qualifiers
  # e.g. for pombe
  # annotation_method ???

  my $h = {
           'standard_name'     => $systematic_id,
	   'is_predicted'      => $is_predicted,
           'review_status_id'  => $review_status_id,
	   'na_sequence_id'    => $na_sequence_id,   # When the sequence changes, this changes
	   'subclass_view'     => $subclass_view,
	   'number_of_exons'   => $number_of_exons,
	   'gene_type'         => $gene_type,
	   'is_pseudo'         => $is_pseudo,
	   'is_partial'        => $is_partial,
	   'source_id'         => $source_id,
	  };

  my $gf = GUS::Model::DoTS::GeneFeature->new ($h);
  $gf->setParent ($gus_sequence);

  if (defined $product) {
    $gf->setProduct ($product);
  }

  if (defined $prediction_algorithm_id) {
    $gf->set ('prediction_algorithm_id', $prediction_algorithm_id);
  }

  if (defined $primary_name) {
    $gf->set ('name', $primary_name);
  }
  else {
    print STDERR "'name' is going to be null for GeneFeature, using '$systematic_id' instead\n";
    $gf->set ('name', $systematic_id);
  }

  push (@gus_note_objects, $gf);

  ###################################
  #
  # processing the note & curation qualifiers
  #
  ###################################

  my @gus_notes = ();

  if ($bioperl_feature->has_tag ('note')) {
    my @bioperl_notes = $bioperl_feature->each_tag_value ('note');
    foreach my $bioperl_note (@bioperl_notes) {
      my $h = {
	       'remark'     => $bioperl_note,
	      };

      # FIXME - The Note table has gone. What has replaced it???

      #my $gus_note = Note->new ($h);
      #$gus_note->setParent ($gf);
      #push (@gus_notes, $gus_note);
    }
  }

  if ($bioperl_feature->has_tag ('curation')) {
    my @bioperl_curations = $bioperl_feature->each_tag_value ('curation');
    foreach my $bioperl_curation (@bioperl_curations) {
      my $h = {
	       'remark'     => $bioperl_curation,
	      };
      
      # FIXME - The Note table has gone. What has replaced it???

      #my $gus_note = Note->new ($h);
      #$gus_note->setParent ($gf);
      #push (@gus_notes, $gus_note);
    }
  }

  push (@gus_note_objects, @gus_notes);

  return @gus_note_objects;
}


sub buildRNAFeature {
  my $self = shift;
  my ($gf, $snas, $number_of_exons) = @_;

  my $debug             = $self->{debug};
  my $bioperl_feature   = $self->{bioperlFeature};
  my $gus_sequence      = $self->{gusSequence};

  # translation start and stop => start and end if not partial or not pseudogene

  # at the moment not several mRNA but in theory could be !!

  my $subclass_view     = "RNAFeature";
  my $name              = $gf->get ('standard_name');
  my $is_predicted      = 1;
  my $review_status_id  = $REVIEW_STATUS_ID;
  my $na_sequence_id    = $gus_sequence->getNaSequenceId ();
  my $source_id         = $gus_sequence->getSourceId();

  my $h = {
	    'name'              => $name,
	    'is_predicted'      => $is_predicted,
	    'review_status_id'  => $review_status_id,
	    'na_sequence_id'    => $na_sequence_id,
	    'subclass_view'     => $subclass_view,
	    'number_of_exons'   => $number_of_exons,
	    'source_id'         => $source_id
	   };

  # attached to a RNA NA Sequence ?????????
  # the sequence is in the XML file
  # or can be seen as a CDS => a set of exon locations

  my $rnaf = GUS::Model::DoTS::RNAFeature->new ($h);

  $rnaf->setParent ($gf);
  $rnaf->setParent ($snas);

  # need source ?????
  # $rnaf->setSourceId ($source_feature->getNaFeatureId());

  return $rnaf;
}

sub buildSplicedNASequence {
    my $self = shift;

    my $debug             = $self->{debug};
    my $bioperl_feature   = $self->{bioperlFeature};
    my $gus_sequence      = $self->{gusSequence};

    # what for ??
    my $sequence_version  = 1;
    ##
    my $subclass_view     = "SplicedNASequence";
    my $source_id         = $gus_sequence->getSourceId();
    my $sequence          = $bioperl_feature->spliced_seq();
    my $sequence_type_id  = getSequenceTypeIdentifier ('RNA');

    if (not defined $sequence_type_id) {
      print STDERR "can't find any SequenceType Database entry associated with RNA\n";
      print STDERR "failed creating a SplicedNaSequence entry...\n";
      return undef;
    }

    if ($debug) {
      print STDERR "Spliced sequence:\n";
      print STDERR $sequence->seq() . "\n";
    }

    my $h = {
	    'sequence_version'  => $sequence_version,
	    'sequence_type_id'  => $sequence_type_id,
	    'subclass_view'     => $subclass_view,
	    'source_id'         => $source_id,
	    'sequence'          => $sequence->seq()
	   };
    my $snas = GUS::Model::DoTS::SplicedNASequence->new ($h);

    return $snas;
}

sub buildExonFeature {
  my $self = shift;
  my ($gf, $is_initial_exon, $is_final_exon, $order_number) = @_;

  my $debug             = $self->{debug};
  my $bioperl_feature   = $self->{bioperlFeature};
  my $gus_sequence      = $self->{gusSequence};

  my $subclass_view = "ExonFeature";
  # my $reading_frame   = 0; # ??????????????????
  
  my $name = $gf->get ('standard_name') . ".exon $order_number";
  my $is_predicted      = 1;
  my $review_status_id = $REVIEW_STATUS_ID;
  my $na_sequence_id    = $gus_sequence->getNaSequenceId ();
  my $source_id = $gus_sequence->getSourceId();

  my $h = {
	   'name'              => $name,
	   'is_predicted'      => $is_predicted,
	   'review_status_id'  => $review_status_id,
	   'na_sequence_id'    => $na_sequence_id,
	   'subclass_view'     => $subclass_view,
	   'order_number'      => $order_number,
	   'is_initial_exon'   => $is_initial_exon,
	   'is_final_exon'     => $is_final_exon,
	   'source_id'         => $source_id
	  };

  my $ef = GUS::Model::DoTS::ExonFeature->new ($h);
  $ef->setParent ($gf);
  # $ef->setSourceId ($source_feature->getNaFeatureId()); # ?????
  
  return $ef;
}


sub buildRNAFeatureExon {
  my $self = shift;
  my ($ef, $rnaf) = @_;
  
  my $rfe = GUS::Model::DoTS::RNAFeatureExon->new();
  $rfe->setParent($ef);
  $rfe->setParent($rnaf);

  return $rfe;
}


sub buildTranslatedAASequence {
  my $self = shift;
  my ($gf) = @_;

  my $debug = $self->{debug};
  my $bioperl_feature   = $self->{bioperlFeature};

  my $subclass_view = "TranslatedAASequence";
  my $name    = $gf->get ('standard_name');
  # description => the product line
  # not anymore !!!!!!!!
  # the description is now the concatenation of the set of product qualifiers

  ##
  # my $product = $gf->getProduct;
  # my $aa_seq_descr  = "this protein, $product, is coded by the gene, \'$name\'";
  ##

  my $aa_seq_descr = "";
  if ($bioperl_feature->has_tag ('product')) {
    my @bioperl_products = $bioperl_feature->each_tag_value ('product');
    foreach my $bioperl_product (@bioperl_products) {
      $aa_seq_descr = $aa_seq_descr . $bioperl_product . "; ";
    }
  }
  
  my $seq_version   = 1;
  
  ##############################
  # Get the translated sequence
  # using bioperl
  ##

  my $spliced_seq = $bioperl_feature->spliced_seq();
  # process the frame and the is_partial
  
  # partial gene information

  my $is_partial   = $gf->get ('is_partial');
  my $is_complete  = 0;
  $is_complete     = 1 unless $is_partial;

  # frame information

  my $frame = 0;
  if ($bioperl_feature->has_tag ('codon_start')) {
    my @start_codons = $bioperl_feature->each_tag_value ('codon_start');
    my $start_codon  = $start_codons[0];
    $frame = $start_codon - 1;
  }
      
  my $prot_seq = $spliced_seq->translate (undef,undef,$frame,$is_complete,0);
  
  if ($debug) {
    print STDERR "translated protein sequence for gene, $name:\n";
    print STDERR $prot_seq->seq() . "\n";
  }

  my $h = {
	   'subclass_view'    => $subclass_view,
	   'sequence_version' => $seq_version,
	   'description'      => $aa_seq_descr,
	   'sequence'         => $prot_seq->seq()
	  };

  my $aa_seq = GUS::Model::DoTS::TranslatedAASequence->new ($h);
  # need source ?????
  # $aa_seq->setSourceId ($source_feature->getNaFeatureId());
  
  # Molecular Weight
  
  if ($bioperl_feature->has_tag ('molecular_weight')) {
    my @tmp = $bioperl_feature->each_tag_value('molecular_weight');
    my $mol_weight = $tmp[0];
    if ($mol_weight =~ /da/i) {
      print STDERR "mol weight: $mol_weight\n";
    }
    $mol_weight =~ s/\s*da//i;
    print STDERR "mol weight: $mol_weight\n";
    $aa_seq->set ('molecular_weight', $mol_weight);
  }

  # Peptide Length

  if ($bioperl_feature->has_tag ('peptide_length')) {
    my @tmp = $bioperl_feature->each_tag_value('peptide_length');
    my $length = $tmp[0];
    print STDERR "peptide length: $length\n";
    $aa_seq->set ('length', $length);
  }
  
  return $aa_seq;
}

# build both a TranslatedAAFeature object and a ProteinFeature Object
# The ProteinFeature object stores the EC_number

sub buildProteinFeature {
  my $self = shift;
  my ($rf, $aa_seq) = @_;
  
  my $gus_sequence      = $self->{gusSequence};
  my $bioperl_feature   = $self->{bioperlFeature};
  my $debug = $self->{debug};

  # TranslatedAAFeature

  my $subclass_view     = "TranslatedAAFeature";
  my $is_predicted      = 1;
  my $review_status_id = $REVIEW_STATUS_ID;
  my $description       = $aa_seq->get ('description');
  # codon_table, is_simple, tr_start, tr_stop ????

  my $h = {
	   'subclass_view'    => $subclass_view,
	   'is_predicted'     => $is_predicted,
	   'review_status_id' => $review_status_id,
	   'description'      => $description,
	  };

  my $aaf = GUS::Model::DoTS::TranslatedAAFeature->new ($h);
  $aaf->setParent ($rf);
  $aaf->setParent ($aa_seq);

  # ProteinFeature

  my $name = $rf->getName;
  $subclass_view = "ProteinFeature";
  my $ec_number = undef;
  if ($bioperl_feature->has_tag ('EC_number')) {
    my @ec_numbers = $bioperl_feature->each_tag_value ('EC_number');
    $ec_number = $ec_numbers[0];
  }

  $h = {
           'subclass_view' => $subclass_view,
           'name'          => $name,
          };

  my $pf = GUS::Model::DoTS::ProteinFeature->new ($h);
  $pf->setParent ($rf);
  $pf->setParent ($gus_sequence);
  if (defined $ec_number) {
    $pf->set ('ec_number', $ec_number);
  }

  return ($aaf, $pf);
}

sub buildAAFeatures {
  my $self = shift;
  my ($aa_seq, $gene_name) = @_;

  my $debug           = $self->{debug};
  my $bioperl_feature = $self->{bioperlFeature};  

  my @aa_objects = ();

  $debug = 1;

  # print STDERR "bioperl2Gusdev object debug: " . $self->{debug} . ".\n";

  my @misc_features = $self->getMiscFeatures ($gene_name);
  
  # print STDERR "Dumping misc_features: " . Dumper (@misc_features) . "\n";

  my $misc_feature_tm;
  my $misc_feature_sp;

  foreach my $misc_feature (@misc_features) {
    my @notes = $misc_feature->each_tag_value ('note');
    foreach my $note (@notes) {
      if ($note =~ /signal peptide/i) {
        $misc_feature_sp = $misc_feature;
      }
      elsif ($note =~ /transmembrane heli/i) {
	$misc_feature_tm = $misc_feature;
      }
    }
  }

  # SignalPeptide

  my @signalP_objects = $self->buildSignalPFeature ($misc_feature_sp, $aa_seq);
  push (@aa_objects, @signalP_objects);

  # Transmembrane domain

  my @transmembrane_objects = $self->buildTransmembraneDomainFeature ($misc_feature_tm, $aa_seq);
  push (@aa_objects, @transmembrane_objects);

  # Pfam

  if ($bioperl_feature->has_tag ('domain')) {
    my @domain_objects = $self->buildDomainFeature ($aa_seq);
    push (@aa_objects, @domain_objects);
  }

  # print STDERR "Dumping aa feature objects: " . Dumper (@aa_objects) . "\n";

  return @aa_objects;
}

#
# Return an array of Bioperl features that have the words
#   'signal peptide' or 'transmembrane heli'
# and the string $gene_name in the not field.
#
#
# DOES THIS NEED TO BE FASTER? CACHE THE $bioperl_feature TO $gene_name MAPPING ON FIRST PASS
# THEN LOOKUP THE HASH THERE AFTER....
#
sub getMiscFeatures {
    my $self = shift;
    my ($gene_name) = @_;

    $self->{getMiscFeaturesCount}++;
    print "getMiscFeatures called ", $self->{getMiscFeaturesCount}, " times\n";


    my $debug            = $self->{debug};
    my $bioperl_sequence = $self->{bioperlSequence};

    my @misc_features    = ();
    my @bioperl_features = $bioperl_sequence->all_SeqFeatures;

    foreach my $bioperl_feature (@bioperl_features) {
        if ($bioperl_feature->primary_tag =~ /misc_feature/) {
            my @notes = ();

            eval {
                @notes = $bioperl_feature->each_tag_value ('note');
            };

            if ($@) {
                print STDERR "WARNING: misc_feature did not have a 'note' field\n";
                print STDERR "         number of tags for feature == ", scalar($bioperl_feature->all_tags()), "\n";
                print STDERR "         location == ", $bioperl_feature->location()->to_FTstring(),"\n";

                foreach my $tag ( $bioperl_feature->all_tags() ) {
                    print STDERR "  misc_feature has tag ", $tag,
                        "with values, ", join(' ', $bioperl_feature->each_tag_value($tag)), "\n";
                }

                next;
            }

            foreach my $note (@notes) {
                if (($note =~ /[signal peptide]|[transmembrane heli]/) && ($note =~ /$gene_name/i)) {
                    if ($debug) {
                        print STDERR "found misc_feature for gene, $gene_name!\n";
                    }
                    push (@misc_features, $bioperl_feature);
                }
            }
        }
    }

    return @misc_features;
}

sub buildSignalPFeature {
  my $self = shift;
  my ($misc_feature, $aa_seq) = @_;
  
  my $debug        = $self->{debug};
  my $gus_sequence = $self->{gusSequence};
  my $bioperl_feature = $self->{bioperlFeature};

  my @signalP_objects = ();

  if (not $bioperl_feature->has_tag ('signal_peptide')) {
    return @signalP_objects;
  }

  # my @signal_peptides = $misc_feature->each_tag_value ('note');

  my @signal_peptides = $bioperl_feature->each_tag_value ('signal_peptide');

  foreach my $signal_peptide (@signal_peptides) {
    if ($signal_peptide =~ /signal peptide/i) {
      my $subclass_view  = "SignalPeptideFeature";
      my $description    = $signal_peptide;
      my $algorithm_name = "SignalP 2.0 HMM";
      
      $signal_peptide =~ /.+by\s([^\(\)]+)\(\D+([^,]+),\D+([^\(\)]+)\).+/;
      
      $algorithm_name        = $1;
      my $signal_probability = $2;
      my $anchor_probability = $3;
      my $is_predicted       = 1;
      my $review_status_id  = $REVIEW_STATUS_ID;
      my $source_id          = $gus_sequence->getSourceId();
      
      # start and end coordinates ??
      
      my $start = 1;
      my $end   = 1;
      
      my $bioperl_location = Bio::Location::Simple->new (
							 -start  => $start,
							 -end    => $end,
							 -strand => 1,
							);

      my $h = {
	       'subclass_view'      => $subclass_view,
	       'description'        => $description,
	       'algorithm_name'     => $algorithm_name,
	       'is_predicted'       => $is_predicted,
	       'review_status_id'   => $review_status_id,
	       'source_id'          => $source_id,
	      };
      my $gus_signalPFeature = GUS::Model::DoTS::SignalPeptideFeature->new ($h);
      $gus_signalPFeature->setParent ($aa_seq);

      # $gus_signalPFeature->set ('signal_probability', $signal_probability);
      # $gus_signalPFeature->set ('anchor_probability', $anchor_probability);

      push (@signalP_objects, $gus_signalPFeature);

      my $gus_aaLocation = $self->buildAALocation ($gus_signalPFeature, $bioperl_location);
      push (@signalP_objects, $gus_aaLocation);
    }
  }

  return @signalP_objects;
}

sub buildTransmembraneDomainFeature {
  my $self = shift;
  my ($misc_feature, $aa_seq) = @_;
  
  my $debug        = $self->{debug};
  my $gus_sequence = $self->{gusSequence};
  my $bioperl_feature = $self->{bioperlFeature};

  $debug = 1;

  my @transmembrane_objects = ();

  if (not $bioperl_feature->has_tag ('transmembrane_domain')) {
    return @transmembrane_objects;
  }

  # my @tms = $misc_feature->each_tag_value ('note');
  my @tms = $bioperl_feature->each_tag_value ('transmembrane_domain');

  # print STDERR "Dumping tms: " . Dumper (@tms) . "\n";

  foreach my $tm (@tms) {
    if ($tm =~ /transmembrane/i) {

      my @bioperl_locations = ();

      my $name             = "TMhelix";
      my $subclass_view    = "PredictedAAFeature";
      my $description      = $tm;
      my $algorithm_name   = "TMHMM2.0";
      my $is_predicted     = 1;
      my $review_status_id= $REVIEW_STATUS_ID;
      my $source_id        = $gus_sequence->getSourceId();

      if ($tm =~ /by\s/) {

	$tm =~ /.+by\s([^at]+).*/;
	$algorithm_name  = $1;

	print STDERR "Algorithm name entry, $algorithm_name\n";
      }

      if ($tm =~ /at aa/) {

	print STDERR "location information\n";

	$tm =~ /.+by\s([^at]+)at aa (\d+)\D(\d+)(.*)/;
	
	my $start        = $2;
	my $end          = $3;
	my $other_locations = $4;
	
	my $bioperl_location = Bio::Location::Simple->new (
							   -start  => $start,
							   -end    => $end,
							   -strand => 1,
							  );
	push (@bioperl_locations, $bioperl_location);
	
	$other_locations =~ s/\sand\s/\, /g;
	
	if ($debug) {
	  # print STDERR "tm: $tm\n";
	  # print STDERR "other locations to parse: $other_locations.\n";
	}
	
	while (length ($other_locations) > 0) {
	  $other_locations =~ /,\s(\d+)\D(\d+)(.*)/;
	  $start = $1;
	  $end   = $2;
	  $other_locations = $3;
	  my $bioperl_location = Bio::Location::Simple->new (
							     -start  => $start,
							     -end    => $end,
							     -strand => 1,
							    );
	  push (@bioperl_locations, $bioperl_location);
	  if ($debug) {
	    # print STDERR "looping to parse other locations: $other_locations\n";
	  }
	}
      }
      
      my $h = {
	       'name'               => $name,
	       'subclass_view'      => $subclass_view,
	       'description'        => $description,
	       'algorithm_name'     => $algorithm_name,
	       'is_predicted'       => $is_predicted,
	       'review_status_id'   => $review_status_id,
	       'source_id'          => $source_id,
	      };
      my $gus_transmembraneFeature = GUS::Model::DoTS::PredictedAAFeature->new ($h);
      $gus_transmembraneFeature->setParent ($aa_seq);
      push (@transmembrane_objects, $gus_transmembraneFeature);

      foreach my $bioperl_location (@bioperl_locations) {
	my $gus_aaLocation = $self->buildAALocation ($gus_transmembraneFeature, $bioperl_location);
	push (@transmembrane_objects, $gus_aaLocation);
      }
    }
  }

  return @transmembrane_objects;
}


sub buildDomainFeature {
  my $self = shift;
  my ($aa_seq) = @_;

  my $debug           = $self->{debug};
  my $bioperl_feature = $self->{bioperlFeature};
  my $gus_sequence    = $self->{gusSequence};

  my @domain_objects = ();

  my @domain_values = $bioperl_feature->each_tag_value ('domain');
  foreach my $domain_value (@domain_values) {
    my @bioperl_locations = ();

    print STDERR "domain value: $domain_value\n";

    # parsing the domain qualifier...

    # There is a special case where a ';' is included in the domain name. Then this ';' has not to be considered as a separator.
    # GeneDB output does the distinction by adding a '\' just before this special ';'. 

    # PB : has to be inside above !!!!

    my $db_name;
    my $domain_id;
    my $domain_name;
    my $score_or_evalue;
    my $other_locations;

    if ($domain_value =~ /\\;/) {

      ###
      # Parsing the ';' prefixed by '\' as part of the domain name
      ###

      print STDERR "has a \\\n";
      
      $domain_value =~ s/\\//;

      $domain_value =~ /([^:]+):([^;]+);([^;]+;[^;]+);?([^;]*);?(.*)/;

      $db_name     = $1;
      $domain_id   = $2;
      
      # get rid of the spaces !!!
      $domain_id =~ s/\s//g;
      
      $domain_name = $3;
      $score_or_evalue = $4;
      $other_locations = $5;
      
    }
    else {

      ###
      # all ';' are separator
      ###

      $domain_value =~ /([^:]+):([^;]+);([^;]+);?([^;]*);?(.*)/;

      $db_name     = $1;
      $domain_id   = $2;
      
      # get rid of the spaces !!!
      $domain_id =~ s/\s//g;
      
      $domain_name = $3;
      $score_or_evalue = $4;
      $other_locations = $5;
      
    }

    print STDERR "db name, domain id, domain name: $db_name, $domain_id, $domain_name\n";

    while (defined $other_locations && length ($other_locations) > 0) {
      $other_locations =~ /(\d+)\D(\d+),?(.*)/;
      my $start       = $1;
      my $end         = $2;
      my $bioperl_location = Bio::Location::Simple->new (
							 -start  => $start,
							 -end    => $end,
							 -strand => 1,
							);
      push (@bioperl_locations, $bioperl_location);
      $other_locations = $3;
    }

    my $subclass_view    = "PredictedAAFeature";
    my $description      = $domain_name;
    my $name             = "$db_name:$domain_id";
    # my $prediction_algo_id = ???????;
    my $is_predicted     = 1;
    my $review_status_id= $REVIEW_STATUS_ID;
    my $source_id        = $gus_sequence->getSourceId();

    print STDERR "Generating PredictedAAFeature Entry for $db_name domain, $domain_id ($domain_name)...\n";

    my $h = {
	     'subclass_view'     => $subclass_view,
	     'description'       => $description,
	     'name'              => $name,
	     'is_predicted'      => $is_predicted,
	     'review_status_id'  => $review_status_id,
	     'source_id'         => $source_id,
	    };

    my $gus_PAAFeature = GUS::Model::DoTS::PredictedAAFeature->new ($h);
    $gus_PAAFeature->setParent ($aa_seq);

    # Set Motif Id if Pfam Domain entry
    if ($db_name =~ /pfam/i) {
      print STDERR "mapping Pfam domain, $domain_id, to PfamEntry table Id...\n";
      my $dbh       = $gus_PAAFeature->getDatabase()->getDbHandle();
      my $pfamEntry = getPfamEntry ($domain_id, $dbh);

      if (defined $pfamEntry) {
        my $pfam_entry_id = $pfamEntry->getPfamEntryId;

        print STDERR "Found pfam_entry_id = $pfam_entry_id\n";

        if (defined ($pfam_entry_id)) {
	  #$gus_PAAFeature->setMotifId ($motif_id);
          $gus_PAAFeature->setPfamEntryId($pfam_entry_id);
        }
      }
      else {
	print STDERR "Pfam accession, $domain_id, can not be found !!!\n";
      }
    }

    push (@domain_objects, $gus_PAAFeature);

    foreach my $bioperl_location (@bioperl_locations) {
      my $gus_aaLocation = $self->buildAALocation ($gus_PAAFeature, $bioperl_location);
      push (@domain_objects, $gus_aaLocation);
    }
  }

  return @domain_objects;
}

############################
# Build Central Dogma Objects
##

sub buildGene {
  my $self = shift;
  my ($gf) = @_;

  my $debug           = $self->{debug};
  my $bioperl_feature = $self->{bioperlFeature};

  my $gene_name        = $gf->get ('standard_name');
  my $review_status_id= $REVIEW_STATUS_ID;

  # is_reference ?????????????
  #my $is_reference = 0;

  # build gene object

  my $h = {
	   'name'              => $gene_name,
	   'review_status_id'  => $review_status_id,
	   #'is_reference'      => $is_reference, # I don't think there is anything in GUS3 to replace this...
	  };
  my $gene_object = GUS::Model::DoTS::Gene->new ($h);

  ###################################
  #
  # processing the synonym qualifiers
  #
  ###################################
  
  my @gene_synonyms = ();

  if ($bioperl_feature->has_tag ('synonym')) {
    my @synonyms = $bioperl_feature->each_tag_value ('synonym');
    foreach my $synonym (@synonyms) {
    
      # create a GeneSynonym Entry foreach gene synonym
      
      my $review_status_id= $REVIEW_STATUS_ID;

      my $h = {
	       'synonym_name'     => $synonym,
	       'review_status_id' => $review_status_id,
	      };
      
      my $geneSynonym = GUS::Model::DoTS::GeneSynonym->new ($h);
      $geneSynonym->setParent ($gene_object);

      push (@gene_synonyms, $geneSynonym);

    }
  }
  
  ###################################

  return ($gene_object, @gene_synonyms);
}

################################################################################
# Creates the linking table between Central Dogma and Feature Land i.e.
#
#   Gene  <---  GeneInstance  --->  GeneFeature
#
# Explanation of the GeneInstanceCategory, as of 4 Dec 2003;
#
# A gene can be predictied by 3 seperte programs (glimmer, GeneFinder, Phat).
# Each one will get a GeneInstanceCategory of predicited linking it to the single
# gene.
# 
# A software package can "auto select" one prediction to be The One. Its catergory
# is changed to "auto select". At this point the "mirror" GeneFeature will be
# created which is a clone of the auto selected one.
# 
# A curator can review the predictions and choose the right one. They set the
# category of the prediction to "manually selected" and create a new GeneFeature
# that is a clone of the prediction BUT its boundries maybe modified etc.
#
sub buildGeneInstance {
  my ($self, $gene_object, $gf) = @_;

  my $review_status_id     = $gene_object->get ('review_status_id');

  my $geneInstanceCategory = GUS::Model::DoTS::GeneInstanceCategory->new({'name' => 'manually selected'});
  my $exists               = $geneInstanceCategory->retrieveFromDB();

  unless ($exists) {
      die "ERROR: Could not get DoTS::GeneInstanceCategory by name";
  }

  my $geneInstance = GUS::Model::DoTS::GeneInstance->new({'review_status_id'  => $review_status_id,
                                                          'is_reference'      => 1,
                                                      });
  $geneInstance->setParent($gene_object);
  $geneInstance->setParent($gf);
  $geneInstance->setParent($geneInstanceCategory);

  return $geneInstance;
}

################################################################################
#
#

sub buildRNA {
  my $self = shift;
  my ($gene_object) = @_;

  my $gene_id           = $gene_object->getId;
  my $review_status_id  = $gene_object->get ('review_status_id');
  #my $is_reference      = $gene_object->get ('is_reference');

  my $h = {
	   #'name'             => $gene_name,
           'gene_id'          => $gene_id,
	   'review_status_id' => $review_status_id,
	   #'is_reference'     => $is_reference,
	  };

  my $rna_object = GUS::Model::DoTS::RNA->new ($h);
  # Transcript Unit is the parent not gene !!
  # different with GUS3 in which Transcript unit is no longer available
  # $rna_object->setParent ($gene_object);

  return $rna_object;
}

################################################################################
# Creates the linking table between Central Dogma and Feature Land i.e.
#
#   RNA  <---  RNAInstance  --->  RNAFeature
#
# As of 4 Dec 2003, only "assembly" (from EST) and "predicted" (RNA from CDS)
# are the RNAInstanceCategorys

sub buildRNAInstance {
  my ($self, $rna_object, $rnaf, $rna_type) = @_;

  #print STDERR "buildRNAInstance() : $rna_object, $rnaf, $rna_type\n";

  my $review_status_id = $rna_object->get ('review_status_id');

  my $rnaInstanceCategory = GUS::Model::DoTS::RNAInstanceCategory->new({'name' => 'predicted'});
  my $exists              = $rnaInstanceCategory->retrieveFromDB();

  unless ($exists) {
      die "ERROR: Could not get DoTS::RNAInstanceCategory by name";
  }

  my $rnaInstance = GUS::Model::DoTS::RNAInstance->new({'review_status_id'  => $review_status_id,
                                                        'is_reference'      => 1,
                                                    });
  $rnaInstance->setParent($rna_object);
  $rnaInstance->setParent($rnaf);
  $rnaInstance->setParent($rnaInstanceCategory);

  return $rnaInstance;
}

################################################################################
#
#

sub buildProtein {
  my $self = shift;
  my ($rna_object, $aa_seq, $gf) = @_;

  my $protein_name        = $gf->getProduct;
  my $protein_description = $aa_seq->getDescription;
  my $review_status_id    = $rna_object->get ('review_status_id');
  #my $is_reference        = $rna_object->get ('is_reference');

  my $h = {
	   'review_status_id' => $review_status_id,
	   'description'      => $protein_description,
	   #'is_reference'     => $is_reference,
	  };
  
  my $protein_object = GUS::Model::DoTS::Protein->new ($h);
  $protein_object->setParent ($rna_object);

  # if $protein_name length > 100, means it is a description more than a product name !!, so don't assign a name to this entry !!
  # e.g pombe product qualifier => description product

  if (length ($protein_name) < 100) {
    $protein_object->setName ($protein_name);
  }

  return $protein_object;
}


################################################################################
# Creates the linking table between Central Dogma and Feature Land i.e.
#
#   Protein  <---  ProteinInstance  --->  ProteinFeature
#
# As of 4 Dec 2003 only one ProteinInstanceCategory. Will more ever be required?
#

sub buildProteinInstance {
  my ($self, $protein_object, $aa_feature_protein) = @_;

  my $review_status_id = $protein_object->get ('review_status_id');

  my $proteinInstanceCategory = GUS::Model::DoTS::ProteinInstanceCategory->new({'name' => 'mirror'});
  my $exists                  = $proteinInstanceCategory->retrieveFromDB();

  unless ($exists) {
      die "ERROR: Could not get DoTS::ProteinInstanceCategory by name";
  }

  my $proteinInstance = GUS::Model::DoTS::ProteinInstance->new({'review_status_id'  => $review_status_id,
                                                                'is_reference'      => 1,
                                                            });
  $proteinInstance->setParent($protein_object);
  $proteinInstance->setParent($aa_feature_protein);
  $proteinInstance->setParent($proteinInstanceCategory);

  return $proteinInstance;
}


################################################################################
# The GO methods need to know which is the latest ExternalDatabaseRelease for
# the given GO aspect. This returns it (once its cached it for future reference).
#
# The aspect (or name in the ExternalDatabase) is 'Go Process', 'Go Component'
# and 'Go Function'. This is normalized to process, component and function for
# the keys returned;
#
#  %edrId = $VAR1 = {
#            'function'  => '8',
#            'process'   => '7',
#            'component' => '9'
#          };
#
sub getReleaseIds {
    my ($self, $dbh) = @_;

    unless (defined $self->{'cache'}->{edrId}) {

        my $sth = $dbh->prepare(
qq[SELECT external_database_release_id, release_date, version
FROM   SRes.ExternalDatabaseRelease  edr, SRes.ExternalDatabase ed
WHERE  ed.name = ?
AND    ed.external_database_id = edr.external_database_id
ORDER BY release_date, external_database_release_id]);

        my %edrId = ();

        foreach my $aspect ('GO Process', 'GO Component', 'GO Function'){
            $sth->execute($aspect);
            my $fetch_all     = $sth->fetchall_arrayref();
            my $last_index    = @{$fetch_all} - 1;
            my $no_go         = lc( substr($aspect, 3) ); # Turn 'GO Process' into 'process'
            $edrId{$no_go}    = $fetch_all->[$last_index]->[0];
        }

        $self->{'cache'}->{'edrId'} = \%edrId ;
    }

    return $self->{'cache'}->{'edrId'};
}

################################################################################
# Return the table_id for a given tables name.
# It uses a cache as it could be called multiple times.
#
sub getTableId {
    my ($self, $dbh, $table_name) = @_;

    unless ( defined $self->{'cache'}->{'table_name'}->{$table_name} ) {
        my $sth = $dbh->prepare(qq[select table_id FROM Core.TableInfo WHERE  name = ?]);
        $sth->execute($table_name);
        
        my @row      = $sth->fetchrow_array();
        my $table_id = $row[0];

        $self->{'cache'}->{'table_name'}->{$table_name} = $table_id;
    }

    return $self->{'cache'}->{'table_name'}->{$table_name};
}

################################################################################
# Build GO Associations for Process, Function and Component
# It works out the last ExternalDatabaseRelease for GO as it needs that when
# creating the GOTerm
#
# /GO="aspect=process; GOid=GO:0006810; term=transport; evidence=ISS;
#      db_xref=GOC:unpublished; with=SPTR:Q9UQ36; date=20001122" 
#
# aspect    : GoTerm is already linked to the ExternalDatabase
#             (i.e. 'GO Process', 'GO Function', 'GO Component')
#
# GOid      : already in GoTerm table
#
# term      : already in GoTerm table
#
# evidence  : GOAssociationInstance->GOAsscoiationInstEvidCode->GOEvidenceCode
#             That last table is a dictionary of terms (ISS, IEA etc).
#
# db_xref   : GOAssociationInstance->Evidence->ExternalDatabaseEntry
#             Evidence could link to anything in the DB in theory i.e.
#             NOTE: and Interpro:0 is a Interpro to GO mapping and will have
#             a fake record.
#
# with/from : Almost the same as db_xref BUT linked against
#             GOAssociationInstEvidCode 'cos only some some GO codes will need
#             them
#
# date      : Use the modification date in GOAssociationInstance table
#
###

sub buildGOAssociations {
    my ($self, $dbh, $protein_object) = @_;

    my $debug           = $self->{debug};
    my $bioperl_feature = $self->{bioperlFeature};

    my @gus_go_objects  = (); # Hold the GUS objects we create, ued as the return value
    my @go_qualifiers   = (); # Each /GO="x y z"

    if ($bioperl_feature->has_tag ('GO')) {
        @go_qualifiers = $bioperl_feature->each_tag_value ('GO');
    }

    my %edrId             = %{$self->getReleaseIds($dbh)};
    my @go_aspect_objects = ();

    foreach my $go_qual (@go_qualifiers){
        my @key_values = split(';', $go_qual);

        my %hash = ();

        foreach my $key_val (@key_values){
            my ($key, $val) = ($key_val =~ /^\s*(.*?)=(.*?)\s*$/);
            $hash{$key}     = $val;
        }

        unless (defined($hash{'aspect'}) &&
                defined($hash{'GOid'})   &&
                defined($hash{'evidence'}) &&
                defined($hash{'db_xref'}) ){
            print STDERR "WARNING: Ignoring incomplete or invalid GO field: '$go_qual'\n";
            next;
        }

        my ($go_id) = ($hash{'GOid'} =~ /GO:(\d+)/);

        push @go_aspect_objects,
             $self->createGoObjects($dbh, $hash{'aspect'}, $go_id, $hash{'evidence'}, $hash{'db_xref'},
                                    $hash{'with'}, $hash{'date'}, $protein_object);
    }

    return @go_aspect_objects; 
}

################################################################################
# Build GO Associations for GO_process, GO_component, GO_function
# The number of tables and the way they ae linked is quite complex. Here is an
# attempt to explain;
#
# See comments for buildGOAssociations() on what GO data goes where.
#
#
# NOTE: $rna_object used to be passed in - IT IS NEVER USED???
#       IT SEEMS LIKE IT NEVER WAS, MAYBE INTENDED TOO IN A FUTURE VERSION???
#
##

sub buildGO_aspectAssociation {
    my ($self, $dbh, $GO_aspect, $protein_object) = @_;
    my $debug           = $self->{debug};
    my $bioperl_feature = $self->{bioperlFeature};


  
    return unless $bioperl_feature->has_tag($GO_aspect);



    my %edrId             = (); # ExternalDatabaseReleaseIds for process, component and function
    my $edrId4Aspect      = undef;
    my @go_aspect_objects = ();
    my @go_aspect         = ();

    my ($go_aspect) = ($GO_aspect =~ /^GO_(.+)$/); # Store 'process', not 'GO_process'

    @go_aspect    = $bioperl_feature->each_tag_value ($GO_aspect);
    %edrId        = %{$self->getReleaseIds($dbh)};
    $edrId4Aspect = $edrId{$go_aspect};

    my $table_id_4_protein = $self->getTableId($dbh, 'Protein');

    foreach my $go_qual (@go_aspect) {
        # Parse something like;
        # /GO_process="GO:0006810 (transport); ISS; TR:Q9UQ36 (EMBL:AB016091); source (TAS; PMID:8662204)" 
        #
        my @go_data    = split(';', $go_qual);
        my ($go_id)    = ($go_data[0] =~ /\s*GO:(\d+)/);    # GO:123 (transport)
        my ($evi_code) = ($go_data[1] =~ /\s*(\S+)\s*/);    # ISS
        my ($db_xref)  = ($go_data[2] =~ /\s*(\S+)\s*\(?/); # 'TR:Q9UQ36 (EMBL:AB016091)' or just 'TR:Q9UQ36'
        my ($with)     = ($go_data[3] =~ /\s*source\s*\(\w+\;\s*(.+\s*\))/); # source (TAS; PMID:8662204)
        my $date       = ''; # Is set in /GO qual, no GO_xxx qualifiers

        push @go_aspect_objects,
             $self->createGoObjects($dbh, $go_aspect, $go_id, $evi_code, $db_xref, $with, $date, $protein_object);
    }


    #print "\@go_aspect_objects = '", Dumper(\@go_aspect_objects), "'\n";

    return @go_aspect_objects;
}

################################################################################
#
# This is sub is shared by buildGO_aspectAssociation() and 
#
#
#
################################################################################

sub createGoObjects {
    my ($self, $dbh, $go_aspect, $go_id, $evi_code, $db_xref, $with, $date, $protein_object) = @_; 

    if ($self->{'debug'}) {
        print STDERR "createGoObjects() called with these values;\n",
                     "   \$go_aspect      = $go_aspect, \$go_id = $go_id, \$evi_code = $evi_code\n",
                     "   \$db_xref        = $db_xref,   \$with  = $with,  \$date     = $date,\n",
                     "   \$protein_object = $protein_object\n";
    }

    my %edrId              = %{$self->getReleaseIds($dbh)};
    my $edrId4Aspect       = $edrId{$go_aspect};
    my $table_id_4_protein = $self->getTableId($dbh, 'Protein');


    my $go_term_obj = GUS::Model::SRes::GOTerm->new ({"go_id", "GO:".$go_id,
                                                      'external_database_release_id', $edrId4Aspect });
    my $exists      = $go_term_obj->retrieveFromDB ();
    my $go_ass;

    unless ($exists) {
        print STDERR "\n*** WARNING: 'GO:$go_id' not found in database ***\n\n";
    }
    else {
        #print SDTERR "\n$GO_aspect Term id : $go_id existed, about to create a GOAssociation object\n";
        $go_ass = GUS::Model::DoTS::GOAssociation->new({'go_term_id'       => $go_term_obj->getGoTermId(),
                                                        'review_status_id' => $REVIEW_STATUS_ID,
                                                        'table_id'         => $table_id_4_protein,
                                                        'row_id'           => $protein_object->getProteinId(),
                                                        'is_not'           => 0,
                                                        'defining'         => 0,
                                                    });

# THINK
#
# *I THINK* the GOAssociation will auto be versioned when this is submitted.
# This needs to be checked out.
#

        # May already be in DB
        my $go_ass_exists = 0; # $go_ass->retrieveFromDB(); # TEST

        if ($go_ass_exists) {
            print STDERR "  WARNING: GO:$go_id already exists - ".
                "CHECK THE EMBL FILE FOR MULTIPLE GO:$go_id FOR THIS FEATURE";
        }
        else {
            $go_ass->submit();
            print STDERR "*** GOAssociation created *** \n\n" if $self->{'debug'};

            my $go_ass_inst_loe = $self->createGOAssociationInstanceLOE('in-house curation', '');
            print STDERR "*** createGOAssociationInstanceLOE ran ***\n" if $self->{'debug'};


            my $go_ass_inst = $self->createGOAssociationInstance($dbh, $go_ass, $go_ass_inst_loe, $db_xref, $date);
            print STDERR "*** createGOAssociationInstance ran *** \n" if $self->{'debug'};

                
            $self->createGOAssocInstEvidCode($dbh, $go_ass_inst, $evi_code, $with); # need XML of CBIL GOEvidenceCode
            print STDERR "*** ExternalDatabaseLink ran ***\n" if $self->{'debug'};
        }
    }

    #print "createGoObjects() returning $go_ass\n";

    return $go_ass;
}

################################################################################
#
# Returns a GOAssociationInstanceLOE.
#
################################################################################

sub createGOAssociationInstanceLOE {
    my ($self, $name, $desc) = @_;

    my $go_ass_inst_loe =
      GUS::Model::DoTS::GOAssociationInstanceLOE->new({'name'        => $name,
                                                       'description' => $desc,
                                                   });
    my $exists = 0; # $go_ass_inst_loe->retrieveFromDB(); # TEST
    $go_ass_inst_loe->submit() unless $exists;

    return $go_ass_inst_loe;
}

################################################################################
#
# Returns a GOAssociationInstance. Currently the date is the only useful info
# stored in this table. The "links" to DoTS.Evidence are the crucial part.
#
# Created DoTS.Evidence and SRes.ExternalDatabaseEntry for the db_xref
#
################################################################################

sub createGOAssociationInstance {
    my ($self, $dbh, $go_ass, $go_ass_inst_loe, $db_xref, $date) = @_;

    #
    # Get external_database_release_id for $db_xref (i.e. SPTR:123)
    #

    my $go_ass_inst =
      GUS::Model::DoTS::GOAssociationInstance->new({'go_association_id'    => $go_ass->getId(),
                                                    'go_assoc_inst_loe_id' => $go_ass_inst_loe->getId(),
                                                    'defining' => 0, # THIS IS NOT PRESENT ON www.gusdb.org!!!!
                                                    #'is_deprecated' => 0,# THIS IS NOT PRESENT ON www.gusdb.org!!!!
                                                    #'is_primary' => 0, # On www.gusdb.org!!!
                                                    'review_status_id' => $REVIEW_STATUS_ID,

                                                    #'external_database_release_id' => , # Not used?
                                                    #'source_id'                    => ,
                                                });
    $go_ass_inst->submit();

    # Create  SRes.ExternalDatabaseEntry  for the fact/db_xref
    # Need to get ExternalDatabaseRelease id first

    my ($db_xref_name, $db_xef_id) = ($db_xref =~ /(.+):(.+)/);

    my ($edri)                     = $self->getExternalDatabaseReleaseId($dbh, $db_xref_name);

    my $ede = GUS::Model::SRes::ExternalDatabaseEntry->new({'external_database_release_id' => $edri,
                                                            'external_primary_identifier'  => $db_xef_id,
                                                            'name'                         => $db_xref,
                                                            'review_status_id'             => $REVIEW_STATUS_ID,
                                                        });
    my $exists = 0; # $ede->retrieveFromDB(); # TEST
    $ede->submit() unless ($exists);

    # Now GOAssociationInstance can be 'joined' together with ExternalDatabaseEntry with Evidence
    #
    my $table_id_4_gai = $self->getTableId($dbh, 'GOAssociationInstance');
    my $table_id_4_ede = $self->getTableId($dbh, 'ExternalDatabaseEntry');

    my $evidence = GUS::Model::DoTS::Evidence->new({'target_table_id' => $table_id_4_gai,
                                                    'target_id'       => $go_ass_inst->getId(),
                                                    'fact_table_id'   => $table_id_4_ede,
                                                    'fact_id'         => $ede->getId(),
                                                    'evidence_group_id' => 1, # 1 supports association
                                                });
    $exists = 0; # $evidence->retrieveFromDB(); TEST
    $evidence->submit() unless $exists;

    return $go_ass_inst;
}

################################################################################
#
# Returns ExternalDatabaseReleaseId. It uses a cache.
# This method should be merged with getReleaseIds() which is similar
#
################################################################################

sub getExternalDatabaseReleaseId {
    my ($self, $dbh, $db_name) = @_;

    unless (defined $self->{'cache'}->{'db_name'}->{$db_name}) {

        # WHY DOES THIS NOT USE THE PERL OBJECT LAYER???????????????

        my $sth = $dbh->prepare(
qq[SELECT external_database_release_id, release_date, version
FROM   SRes.ExternalDatabaseRelease  edr, SRes.ExternalDatabase ed
WHERE  ed.name = ?
AND    ed.external_database_id = edr.external_database_id
ORDER BY release_date, external_database_release_id]);

        $sth->execute($db_name);
        my $fetch_all     = $sth->fetchall_arrayref();

        if( scalar(@{$fetch_all}) <= 0 ){
            #
            # is this folly, trying to auto create a new DB record if it does not
            # yet exist?
            #

            #print "ERROR: No ExternalDatabase called '$db_name' ***\n";
            #print "Would you like to create it? [y/n]";
            #my $input;

            #eval {
            #    $SIG{ALRM} = sub { die "No input given, not creating record(s). *** Stopping ***"; };
            #    alarm 10;
            #    $input = <STDIN>;
            #    alarm 0;
            #};

            #if ($@ && $@ =~ /Stopping/ ) {
            #    die "\n".$@;
            #}
            #else {
            #    print "\nCreating records now\n";
            #}

            die "ERROR: No ExternalDatabase called '$db_name' *** ";
        }

        my $last_index    = @{$fetch_all} - 1;
        my $edri          = $fetch_all->[$last_index]->[0]; # edri = ExternalDatabaseReleaseId

        $self->{'cache'}->{'db_name'}->{$db_name} = $edri;
    }

    return $self->{'cache'}->{'db_name'}->{$db_name};
}

################################################################################
#
#
# need XML of CBIL GOEvidenceCode to stay in sync
# HOWEVER, I populated GUS3 with /nfs/team81/pjm/temp/GUS_XML/GOEvidenceCode.xml
#
# Creates a GOAssocInstEvidCode thats is linked to GOEvidenceCode.
# Creates an Evidence link for the 'with' part of the GO qaulifier, i.e.
#   GOEvidience  <-GOAssocInstEvidCode->  Evidence->ExternalDatabaseEntry
################################################################################

sub createGOAssocInstEvidCode {
    my ($self, $dbh, $go_ass_inst, $evi_code, $with) = @_;

    my $go_evidence_code = GUS::Model::SRes::GOEvidenceCode->new({'name' => $evi_code});
    my $exists           = $go_evidence_code->retrieveFromDB();

    unless ($exists) {
        die "ERROR: could not get evidence code '$evi_code' from table GOEvidenceCode.";
    }

    my $gaiec =
      GUS::Model::DoTS::GOAssocInstEvidCode->new({'go_evidence_code_id'        => $go_evidence_code->getId(),
                                                  'go_association_instance_id' => $go_ass_inst->getId(),
                                                  'review_status_id'           => $REVIEW_STATUS_ID,
                                              });
    $gaiec->submit();

    # IF a with field is present;
    #
    # Now create Evidence and ExternalDatabaseEntry that is the 'fact' table
    # for the 'with' database id i.e.
    #      GOAssocInstEvidCode->Evidence->ExternalDatabaseEntry
    #


    return unless (defined $with && $with ne '' ); # <---- Exit point


    my ($db_name, $db_id) = ($with =~ /(.+):(.+)/);
    my ($edri)            = $self->getExternalDatabaseReleaseId($dbh, $db_name);

    my $ede = GUS::Model::SRes::ExternalDatabaseEntry->new({'external_database_release_id' => $edri,
                                                            'external_primary_identifier'  => $db_id,
                                                            'name'                         => $with,
                                                            'review_status_id'             => $REVIEW_STATUS_ID,
                                                        });
    my $exists = 0; #$ede->retrieveFromDB(); # TEST
    $ede->submit() unless ($exists);

    my $table_id_4_gaiec = $self->getTableId($dbh, 'GOAssocInstEvidCode');
    my $table_id_4_ede   = $self->getTableId($dbh, 'ExternalDatabaseEntry');

    my $evidence = GUS::Model::DoTS::Evidence->new({'target_table_id' => $table_id_4_gaiec,
                                                    'target_id'       => $gaiec->getId(),
                                                    'fact_table_id'   => $table_id_4_ede,
                                                    'fact_id'         => $ede->getId(),
                                                    'evidence_group_id' => 1, # 1 supports association
                                                });
    $exists = 0; # $evidence->retrieveFromDB(); # TEST
    $evidence->submit() unless $exists;
}



##########################
# Build Location Objects
##

###########################
# Check if the location object has a strand !!!!!!!!!
###########################

sub buildNALocation {
  my $self = shift;
  my ($feature_obj, $range) = @_;
  
  my $debug = $self->{debug};

  my $location_type = ref ($range);

  # Bioperl Location types

  my $start_min = undef;
  my $start_max = undef;
  my $end_min   = undef;
  my $end_max   = undef;
  
  if ($location_type =~ /Fuzzy/) {

    # print STDERR "Dumping Fuzzy location: " . Dumper ($range) . "\n";

    $start_min = $range->min_start;
    $start_max = $range->max_start;
    $end_min   = $range->min_end;
    $end_max   = $range->max_end;
  }
  else {
    $start_min = $range->start;
    $start_max = $range->start;
    $end_min   = $range->end;
    $end_max   = $range->end;
  }
  my $is_reversed = - ($range->strand);

  my $h = {
	   'is_reversed' => $is_reversed,
	   'location_type' => $range->location_type
	  };

  my $naLocation = GUS::Model::DoTS::NALocation->new ($h);
  $naLocation->setParent($feature_obj);
  
  if (defined $start_min) {
    $naLocation->setStartMin ($start_min);
  }
  if (defined $start_max) {
    $naLocation->setStartMax ($start_max);
  }
  if (defined $end_min) {
    $naLocation->setEndMin ($end_min);
  }
  if (defined $end_max) {
    $naLocation->setStartMax ($start_max);
  }

  return $naLocation;
}


sub buildAALocation {
  my $self = shift;
  my ($feature_obj, $range) = @_;

  my $debug = $self->{debug};

  my $start = $range->start;
  my $end   = $range->end;

  my $h = {
	   'start_min' => $start,
	   'start_max' => $start,
	   'end_min'   => $end,
	   'end_max'   => $end,
	  };

  my $aaLocation = GUS::Model::DoTS::AALocation->new ($h);
  $aaLocation->setParent($feature_obj);

  return $aaLocation;
}


#################################
# 
# Get GUS objects from DB methods
#
#################################

# Get an ExternalNASequence object, giving the corresponding bioperl sequence object
# @Return an ExternalNASequence object reference
# @Return undef if not found

sub getGusSequenceFromDB {
  my $self             = shift;
  my $bioperl_sequence = $self->{bioperlSequence};
  my $debug            = $self->{debug};

  my $sequence_name = $bioperl_sequence->display_id;

  if ($debug) {
    print STDERR "sequence name extracted: $sequence_name\n";
  }

  my $gus_sequence = GUS::Model::DoTS::ExternalNASequence->new ();
  $gus_sequence->setName ($sequence_name);

  if ($gus_sequence->retrieveFromDB()) {
    $self->{gusSequence} = $gus_sequence;
    return $gus_sequence;
  }
  else {
      print STDERR "sequence not in GUS yet\n";

      $gus_sequence = $self->buildNASequence();
      
      if (defined $gus_sequence) {
          $gus_sequence->submit();
          return $gus_sequence;
      }
      else {
          print SDTERR "\n*** ERROR: Unable to create new ExternalNASequence\n";
          return undef;
      }
  }
}

##################################
##################################
#
# "Private" methods
#
##################################
##################################

# input : a NA sequence as a string
# output: a hashtable with respectively a_count, t_count, c_count, g_count and other_count

sub getBasesCount {
  my ($seq) = @_;

  my @seq = split (//, $seq);
  my %basesCount = (
		    'a' => 0,
		    't' => 0,
		    'c' => 0,
		    'g' => 0,
		    'o' => 0,
		   );
  my $i = 0;
  
  while ($i<length($seq)) {
    if    ($seq[$i] =~ /a/i) { $basesCount{a} ++; }
    elsif ($seq[$i] =~ /t/i) { $basesCount{t} ++; }
    elsif ($seq[$i] =~ /c/i) { $basesCount{c} ++; }
    elsif ($seq[$i] =~ /g/i) { $basesCount{g} ++; }
    else  { $basesCount{o} ++; }
    $i++;
  }
  
  return %basesCount;
}

######################################
# Get the Taxon Id from the database,
# giving a scientific name
##

sub getTaxonIdentifier { #this is on-demand caching
  my $sci_name = shift;
  
  my $taxonNameRow = GUS::Model::SRes::TaxonName->new({"name" => $sci_name});
  $taxonNameRow->retrieveFromDB();
  
  return $taxonNameRow->getTaxonId();
  #return $taxonNameRow->{'TAXON_ID'};
  #return $taxonNameRow->get('taxon_id');
}

######################################
# Get the Sequence Type Id from the database,
# giving a sequence type name
##

sub getSequenceTypeIdentifier {
  my ($type) = @_;
  
  my $typeRow = GUS::Model::DoTS::SequenceType->new({"name" => $type});
  my $exist = $typeRow->retrieveFromDB();
  
  if ($exist) {
    return $typeRow->getId();
  }
  else {
    print STDERR "can't find SequenceType, $type\n";
    return undef;
  }
}

sub getRNASequenceType {
  my ($type) = @_;

  # FIXME = RNASequenceType no longer exists

  #my $rnaSequenceType = RNASequenceType->new ({'name' => $type});
  #my $exist = $rnaSequenceType->retrieveFromDB;
  my $exist = 0;

  if ($exist) {
    #return $rnaSequenceType;
  }
  else {
    print STDERR "can't find RNASequenceType, $type\n";
    return undef;
  }
}

# Get the Pfam GUS Entry correlated to the domain accession number given in parameter
# Return the pfam Entry GUS object corresponding to the **LAST** Pfam release

sub getPfamEntry {
  my ($domain_id, $dbh) = @_;

  print STDERR "Domain Id to map: $domain_id\n";

  # Get Release 

  my $release = undef;
  my $sql = "select max (distinct release) from DoTS.PfamEntry";
  my $sth = $dbh->prepare ($sql);
  $sth->execute();


  if (($release) = $sth->fetchrow_array) {
  }

  if (not defined $release) {
    print STDERR "Pfam release undefined !!!\n";
  }

  my $pfamEntry =
    GUS::Model::DoTS::PfamEntry->new (
                                      {
                                          'accession' => $domain_id,
                                          'release'   => $release
                                          }
                                      );

  #my $pfamEntry = PfamEntry->new ({'accession' => $domain_id,});

  my $exist = $pfamEntry->retrieveFromDB;

  if ($exist) {
    print STDERR "release: " . $pfamEntry->getRelease . "\n";
    return $pfamEntry;
  }
  else {
    print STDERR "can't find Pfam entry, $domain_id!\n";
    return undef;
  }
}

1;
