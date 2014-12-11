package GUS::Community::Bioperl2Gus;
#vvvvvvvvvvvvvvvvvvvvvvvvv GUS4_STATUS vvvvvvvvvvvvvvvvvvvvvvvvv
  # GUS4_STATUS | SRes.OntologyTerm              | auto   | absent
  # GUS4_STATUS | SRes.SequenceOntology          | auto   | absent
  # GUS4_STATUS | Study.OntologyEntry            | auto   | absent
  # GUS4_STATUS | SRes.GOTerm                    | auto   | broken
  # GUS4_STATUS | Dots.RNAFeatureExon            | auto   | broken
  # GUS4_STATUS | RAD.SageTag                    | auto   | absent
  # GUS4_STATUS | RAD.Analysis                   | auto   | absent
  # GUS4_STATUS | ApiDB.Profile                  | auto   | absent
  # GUS4_STATUS | Study.Study                    | auto   | absent
  # GUS4_STATUS | Dots.Isolate                   | auto   | absent
  # GUS4_STATUS | DeprecatedTables               | auto   | broken
  # GUS4_STATUS | Pathway                        | auto   | absent
  # GUS4_STATUS | DoTS.SequenceVariation         | auto   | absent
  # GUS4_STATUS | RNASeq Junctions               | auto   | absent
  # GUS4_STATUS | Simple Rename                  | auto   | absent
  # GUS4_STATUS | ApiDB Tuning Gene              | auto   | absent
  # GUS4_STATUS | Rethink                        | auto   | absent
  # GUS4_STATUS | dots.gene                      | manual | unreviewed
die 'This file has broken or unreviewed GUS4_STATUS rules.  Please remove this line when all are fixed or absent';
#^^^^^^^^^^^^^^^^^^^^^^^^^ End GUS4_STATUS ^^^^^^^^^^^^^^^^^^^^

# ----------------------------------------------------------
# Bioperl2Gus.pm
#
# A package to hold the mapping of Bioperl to GUS
#
# Created: 
#
# Original by Arnaud Kerhornou (GUSdev)
# Modified by Paul Mooney (GUS3.0)
# Modified by Trish Whetzel for PlasmoDB
# ----------------------------------------------------------

use strict;
use Data::Dumper;
use Carp;

use GUS::Model::DoTS::ExternalAASequence;
use GUS::Model::DoTS::ExternalNASequence;
use GUS::Model::DoTS::Source;
use GUS::Model::SRes::Taxon;
use GUS::Model::SRes::TaxonName;
use GUS::Model::SRes::DbRef;
use GUS::Model::DoTS::DbRefNAFeature;
use GUS::Model::DoTS::ProjectLink;
use GUS::Model::Core::ProjectInfo;

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
use GUS::Model::DoTS::DomainFeature;
use GUS::Model::DoTS::SignalPeptideFeature;
use GUS::Model::DoTS::PostTranslationalModFeature;
use GUS::Model::DoTS::ProteinProperty;
use GUS::Model::DoTS::ProteinFeature;

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

use GUS::Model::DoTS::Evidence;
use GUS::Model::SRes::ExternalDatabaseEntry;
use GUS::Model::SRes::ExternalDatabase;
use GUS::Model::SRes::ExternalDatabaseRelease;

use GUS::Model::DoTS::NAFeatureComment;
use GUS::Model::DoTS::Attribution;
use GUS::Model::SRes::EnzymeClass;
use GUS::Model::DoTS::AASequenceEnzymeClass;

# The GO stuff
#
use GUS::Model::SRes::GOTerm;
use GUS::Model::DoTS::GOAssociation;
use GUS::Model::DoTS::GOAssociationInstance;
use GUS::Model::DoTS::GOAssociationInstanceLOE;
use GUS::Model::DoTS::GOAssocInstEvidCode;
use GUS::Model::SRes::GOEvidenceCode;

# Bioperl
use Bio::SeqUtils;

################################################################################
# CONSTANTS
################################################################################

my $REVIEW_STATUS_ID = 0; #changed for PlasmoDB
my $UPDATE=0;  #TW
my $EXT_DB_REL_ID=9914;

#----------------------------------
#Global variables
my $projId;      # ProjectId
#----------------------------------


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
  my $pId          = undef || $args{'projId'};

  print STDERR "SEQTYPE:$sequenceType\n";
  print STDERR "PRJID:$pId\n";

  my $self = {
	      bioperlSequence  => undef,
	      bioperlFeature   => undef,
	      sequenceType     => $sequenceType,
	      debug            => $debug,
	      gusSequence      => undef,
	      pId              => $pId,
	      @_,
	     };
  bless ($self, $class);

  if (defined $self->{'default_review_status'}) {
      $REVIEW_STATUS_ID = $self->{'default_review_status'};
  }

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

################################################################################
# Build DoTS::ExternalAASequence object
#
# => Uniprot storage purposes
#

sub buildAASequence {
  my ($self, $gus_seq, $no_sequence, $external_database_release_id) = @_;
  my $bioperl_sequence = $self->{bioperlSequence};
  my $debug            = $self->{debug};
  
  if (not defined ($bioperl_sequence)) {
    print STDERR "ERROR - can't generate the AA Sequence object, bioperl sequence object not specified !!\n";
    return undef;
  }
  
  my $seq_descr   = $bioperl_sequence->desc;
  my $accession   = $bioperl_sequence->accession_number;
  my $id          = $bioperl_sequence->display_id;
  my $name        = $id;
  my $seq_length  = length ($bioperl_sequence->seq);
  # source_id ???
  my $source_id   = "";

  my $h = {
	   'name'             => $name,
	   'description'      => $seq_descr,
	   'length'           => $seq_length,
	  };
  
  # $gus_seq may have been passed in just to be brought up-to-date
  #
  $gus_seq = GUS::Model::DoTS::ExternalAASequence->new ($h);

  if (not $no_sequence) {
    $gus_seq->setSequence ($bioperl_sequence->seq);
  }

  # print STDERR "Dumping AA sequence object, " . Dumper ($gus_seq) . "\n";

  # The sequence ...

  $self->{gusSequence} = $gus_seq;
  return $gus_seq;
}


########################################################
# Build DoTS::ExternalNASequence object
# NOTE: this function does not do any versioning.
########################################################

sub buildNASequence {
    my ($self, $gus_seq) = @_;

    my $bioperl_sequence = $self->{bioperlSequence};
    my $sequenceType     = $self->{sequenceType};
    my $debug            = $self->{debug};
    
    if (not (defined ($bioperl_sequence) && defined ($sequenceType))) {
	print STDERR "ERROR - can't generate the NA Sequence object, bioperl sequence object or sequence type not specified !!\n";
	return undef;
    }
    
    my $seq_type_id = $self->getSequenceTypeIdentifier ($sequenceType);
    my $seq_descr   = $bioperl_sequence->desc;  # the description is into the description or the definition tags  #TW
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
    my $name        = $id;  # name - the only thing is ID
    my $seq_version = "1";
    
    print STDERR "SEQ_DESC-1:$seq_descr\n";

    # FIXME: Arnaud, please check this is correct, I can not find Seq::seq_version
    #        in the Bioperl API.
    #if ($bioperl_sequence->seq_version()) {
    if ($bioperl_sequence->version()) {
	# seq version is not the bioperl interface but present into GB file
	$seq_version = $bioperl_sequence->seq_version();
    }
    print STDERR "SEQVER:$seq_version\n\n"; #TW - why is there the check for seq_version when it is already set 
    
    # chromosome and organism info from the 'source' feature
    # chromosome is not an attribute of ExternalNASequence => into the source_id field
    
    my $chromosome       = undef;
    my $organism         = undef;
    my $clone            = "UNKNOWN";
    my $strain           = "UNKNOWN";
    my $chr_order_number = undef;
    my $datasource       = undef;
    my @features         = $bioperl_sequence->get_all_SeqFeatures();
    
    #print STDERR "\n*** \$bioperl_sequence = $bioperl_sequence\n\n";
    #print STDERR "Dumper: ",Dumper($bioperl_sequence), "\n";
    print STDERR "number of features = ", scalar(@features), "\n";
    
    foreach my $feature (@features) {
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
		elsif ($tag =~ /clone/i) {
		    my @values = $feature->each_tag_value('clone');
		    $clone = $values[0];
		}
		elsif ($tag =~ /strain/i) {
		    my @values = $feature->each_tag_value('strain');
		    $strain = $values[0];
		}
		elsif ($tag =~ /datasource/i) {
		    my @values = $feature->each_tag_value('datasource');
		    $datasource = $values[0];
		}
	    }
	    
	    last;
	}
    }

    print STDERR "CHR:$chromosome\tORGANISM:$organism\tCHROM_ORDER_NUM:$chr_order_number\tCLONE:$clone\tSTRAIN:$strain\tDATASOURCE:$datasource\n\n";
    
    #TW-print STDERR "CHROM_ORDER_NUM:$chr_order_number\n\n";
    #TW-print STDERR "CHROM_ORDER_NUM:Dumper($chr_order_number)\n\n";


    if (not defined $organism) {
	print STDERR "don't know which organism this sequence is attached to !!!\n";
	exit 1;
    }
    
    my $taxon_id  = getTaxonIdentifier ($organism);
    my $source_id = "chr. " . $chromosome;
    my $chr_ord_num = $chromosome;

    print STDERR "ORGANISM:$organism\tTAXON id:$taxon_id\tCHR_ORD_NUM:$chr_ord_num\n";
    
    my $h = {
	'sequence_type_id' => $seq_type_id,
	'taxon_id'         => $taxon_id,
	'name'             => $name,
	'sequence_version' => $seq_version,
	'description'      => $seq_descr,  #TW
	'sequence'         => $seq,
	'a_count'          => $a_count,
	'c_count'          => $c_count,
	'g_count'          => $g_count,
	't_count'          => $t_count,
	'other_count'      => $other_count,
	'length'           => $length,
	'source_id'        => $source_id,
	'chromosome'       => $chromosome,
	'chromosome_order_num' => $chr_ord_num,
	'external_database_release_id'  => $EXT_DB_REL_ID,
    };
    
    #print STDERR "SEQ_DESC-2:$seq_descr\n";
    print STDERR "TID:$taxon_id\n";
    # $gus_seq may have been passed in just to be brought up-to-date
    #
    unless (defined $gus_seq) {
	$gus_seq = GUS::Model::DoTS::ExternalNASequence->new ($h);
    }
    #TW-DO NOT UPDATE EXISTING VALUES
    #else {
	# Reset attribute values for existing sequence obj
	# if it has changed
	#foreach my $att (keys %{$h}) {
	#    if ($gus_seq->get($att) ne $h->{$att}) {
	#	print STDERR $h->{$att}, " has changed for DoTS::ExternalNASequence $name\n";
	#	$gus_seq->set($att, $h->{$att});
	#    }
	#}
    #}
    
    if (defined $chr_order_number) {
	$gus_seq->setChromosomeOrderNum ($chr_order_number);
    }
    
 
    #TW-PLASMODB DOES NOT USE DOTS.SOURCE
    my $source = $self->get_source($gus_seq, $name, $clone, $chromosome, $strain);    
    if (defined $datasource) {
	$self->{datasource} = $datasource;
    }
    else {
	print STDERR "ERROR - can't get the datasource from the source feature!!\n";
	exit 1;
    }
    $self->{gusSequence} = $gus_seq;
    return ($gus_seq, $source);
}


################################################################################
#
##
sub get_source {
    my ($self, $gus_seq, $name, $clone, $chromosome, $strain) = @_;

    print STDERR "1: get_source(): $gus_seq, $name, $clone, $chromosome, $strain\n";

    unless (defined $name && defined $clone && defined $chromosome) {
        my @features = $self->{bioperlSequence}->get_all_SeqFeatures();

        print STDERR "get_source(): num features = ", scalar(@features), "\n";

        foreach my $feature (@features) {
            if ($feature->primary_tag() =~ /source/) {

                print STDERR "get_source(): Found 'source' feature\n";

                my @tags = $feature->all_tags();

                foreach my $tag (@tags) {
                    print STDERR "get_source(): Looking at $tag\n";

                    if ($tag =~ /chromosome$/i) {
                        my @values = $feature->each_tag_value('chromosome');
                        $chromosome = $values[0];
                    }
                    elsif ($tag =~ /clone/i) {
                        my @values = $feature->each_tag_value('clone');
                        $clone = $values[0];
                    }
                    elsif ($tag =~ /strain/i) {
                        my @values = $feature->each_tag_value('strain');
                        $strain = $values[0];
                    }

                    print STDERR "get_source(): Finished looking at $tag\n";
                }

                last;
            }
        }
    }

    print STDERR "2: get_source(): $gus_seq, $name, $clone, $chromosome, $strain\n";
    
    my $h_source = {'name'       => $self->{bioperlSequence}->display_id,
                    'clone'      => $clone,
                    'chromosome' => $chromosome,
                    'strain'     => $strain,
                };

    my $source = $gus_seq->getChild('DoTS::Source', 1);

    unless (defined $source) {
        print STDERR "get_source(): creating new DoTS::Source\n";

        $source = GUS::Model::DoTS::Source->new($h_source);
        $source->setParent($gus_seq);
    }
    else {
        print STDERR "get_source(): See if DoTS::Source needs updating\n";

        foreach my $att (keys %{$h_source}) {
            #if (defined ($h_source->{$att}) && $source->get($att) ne $h_source->{$att}) {
                #print STDERR "'$att' has changed for DoTS::Source $name (", $self->{bioperlSequence}->accession_number, ") from ", $source->get($att), " to ", $h_source->{$att}, "\n";
                $source->set($att, $h_source->{$att});
            #}
        }
    }

    print "get_source(): returning $source\n";

    return $source;
}

################################################################################
# Build DoTS::GeneFeature object, updates it if it has changed.
#
# Returns: GeneFeature, NALocation. "Note" objects should be returned but no
# longer in GUS3... See FIXME below;
#
# FIXME;
#   . Note objects not created as they no longer exist in GUS3
#
# TO BE DONE;
#    . Contact info
#    . Evidence Entries 
##############################################

sub buildGeneFeature {
    my ($self, $number_of_exons, $bioperl_geneLocation, $gene_type, $is_partial, $systematic_id) = @_;

    my $debug             = $self->{debug};
    my $bioperl_feature   = $self->{bioperlFeature};
    my $gus_sequence      = $self->{gusSequence}; # This is a cheat for mRNA - maybe have a fake sequence called chromosome "unknown"?
     my $datasource       = $self->{datasource};

    # These are used direct in the DoTS::GeneFeature creation
    #
    my $is_predicted      = 1;
    my $review_status_id  = $REVIEW_STATUS_ID;
    my $na_sequence_id    = $gus_sequence->getNaSequenceId();
    my $subclass_view     = "GeneFeature";  #Value for name attribute

    my @gus_note_objects  = ();

    ########################################
    # Return if $systematic_id not ok
    #
    unless ($systematic_id) {
        print STDERR "\n*** ERROR - no 'systematic_id' passed to buildGeneFeature for $gene_type : ",$bioperl_feature->location()," ***\n\n";
        return;
    }

    #########################################
    # Get primary_name
    my $primary_name = undef;
    #my $systematic_name = undef;
    
    if ($bioperl_feature->has_tag ('primary_name')) {
    #TWif ($bioperl_feature->has_tag ('systematic_id')) {
        my @primary_names = $bioperl_feature->each_tag_value ('primary_name');
	#TWmy @systematic_names = $bioperl_feature->each_tag_value ('systematic_id');
	$primary_name = $primary_names[0];
        #TW$systematic_name = $systematic_names[0];
        print STDERR "\n*** WOW *** primary name = '$primary_name'\n\n";
	#print STDERR "\n*** WOW TW *** source_id = '$systematic_name'\n\n";
    }  

    #########################################
    #TW - Get temp systematic id
    my $temporary_systematic_id =undef;
    if ($bioperl_feature->has_tag('temporary_systematic_id'))  {
	my @temporary_systematic_id = $bioperl_feature->each_tag_value('temporary_systematic_id');
	$temporary_systematic_id = $temporary_systematic_id[0];
	print STDERR "\n*** WOW *** temp sys name = '$temporary_systematic_id'\n\n";
    }

    #########################################
    #TW - Get decription
    my $desc =undef;
    if ($bioperl_feature->has_tag('description'))  {
	my @desc = $bioperl_feature->each_tag_value('description');
	$desc = $desc[0];
	print STDERR "\n*** WOW *** desc = '$desc'\n\n";
    }
    

    ##############################################
    # may not have a product if it's a pseudo gene
    # may have several product tags
    #
    # FIXME: the product is the first element of the products list
    #        we need to store all of them!!!
    #        Perhaps concatentate all of them for now??? ie product1;product2
    
    #NOTE:TW-there are no product tags in any of the files (01/17/05)!!!
    my $product = undef;
    if ($bioperl_feature->has_tag ('product')) {
        my @products = $bioperl_feature->each_tag_value ('product');
        #$product = join('; ', @products); # axk says GeneFeature.product is first product (product name)
        $product = $products[0];
    }

    ##############################################################
    # Get the external_database_release_id associated with it
    print STDERR "LOOKING FOR EXTDB_REL-ID\n";
    my $ext_db = GUS::Model::SRes::ExternalDatabase->new ({"name" => $datasource});
    my $exist  = $ext_db->retrieveFromDB();
    my $ext_db_id;
    print STDERR "TAAF-EXTDB_REL-ID:$ext_db\n\n";  #TW
    my $ext_db_release_id;
    if ($exist) {
	$ext_db_id = $ext_db->getId();
	my $ext_db_release = GUS::Model::SRes::ExternalDatabaseRelease->new ({"external_database_id" => $ext_db_id});
	#TW-$exist = $ext_db_release->retrieveFromDB();
	$exist = $ext_db_release_id = $EXT_DB_REL_ID;  #TW - hard-coded
	if ($exist) {
	    #$ext_db_release_id = $ext_db_release->getId();
	    print STDERR "EXTDB_REL-ID:$ext_db_release_id\n\n";
	}
	else {
	    print STDERR "ERROR-ExtDbRelId - can't get the External Database Release ID associated with this datasource, $datasource!\n";
	    exit 1;
	}
    }


    ####################################
    # to figure out if it's partial, other way is to parse the Bioperl Range object
    # e.g. => <1..200>
    # it is done before calling buildGeneFeature, so this information is in $is_parital parameter
    ####################################
    #TW-what is this for???
    if ($bioperl_feature->has_tag ('partial')) {
        $is_partial = 1;
    }

    my $is_pseudo = 0;
    if ($gene_type =~ /pseudogene/i) {
        $is_pseudo = 1;
    }

    #########################################
    # Figure out the $prediction_algorithm_id
    # using /method
    ####
    #TW-method is ok
    my $prediction_algorithm_id = undef;

    if ($bioperl_feature->has_tag ('method')) {
        my @methods = $bioperl_feature->each_tag_value ('method');
        my $method  = $methods[0];

        if ($method =~ /manual annotation/i) {
            #$method = "Manual Annotation";
	    $method = "Pf Annotation"; #value from Database for previous GeneFeature entries
        }
        elsif ($method =~ /automatic annotation/i) {
            $method = "Automatic Annotation";
	    exit 1; #TW - don't know how to handle this IF it happens
        }

	my $algo   = GUS::Model::Core::Algorithm->new ({'name' => "$method"});
        my $result = $algo->retrieveFromDB();

        if ($result == 1) {
            $prediction_algorithm_id = $algo->getAlgorithmId();
        }
        else {
            # Annotate the gene feature as a 'Manual Annotation' per default
            $algo   =
		#TW GUS::Model::Core::Algorithm->new ({'name' => "Manual Annotation"});
		GUS::Model::Core::Algorithm->new ({'name' => "Pf Annotation"});
	    $result = $algo->retrieveFromDB();
            
            if ($result == 1) {
                $prediction_algorithm_id = $algo->getAlgorithmId();
            }
        }
    }
    print STDERR "GF-PREDICTION_ALG_ID:$prediction_algorithm_id\n\n";
    
    # the source_id is a unique identifier for the gene
    # => the gene name
    # my $source_id = $gus_sequence->getSourceId();
    # my $source_id = $standard_name;
    #my $source_id = $systematic_id;

    print STDERR "BuildGeneFeature() : Got details, about to retrieve/create GeneFeature\n";

    # get GeneFeature by name  
    #TW-CHANGE, get GeneFeature by source_id OR just add new GeneFeature 
    # get property, conditionaly set property if diff to the "new" one
    # on submit only if a value or values have changed will it get versioned and updated
    # Any property that has been set, even if it is the same as the last will get versioned and updated

    my $h = {
        'is_predicted'            => $is_predicted,
        'review_status_id'        => $review_status_id,
        'number_of_exons'         => $number_of_exons,
        'gene_type'               => $gene_type,
        'is_pseudo'               => $is_pseudo,
        'is_partial'              => $is_partial,
        'product'                 => $product,
        'prediction_algorithm_id' => $prediction_algorithm_id,
	'name'                    => $subclass_view, 
	'label'                   => $primary_name,
	'source_id'               => $systematic_id,
	'gene'                    => $temporary_systematic_id,
	'product'                 => $desc,
	'external_database_release_id' => $EXT_DB_REL_ID,
    };
    
    #$h->{'standard_name'} = $primary_name if defined $primary_name; #TW, woring mapping
    $h->{'label'} = $primary_name if defined $primary_name; #TW
    print STDERR "***LABEL:$primary_name\n";

    #my $gf    = GUS::Model::DoTS::GeneFeature->new ({'name' => $systematic_id});
    #my $is_in = $gf->retrieveFromDB(); # 0 means zero or 2+ records exist, 1 means 1 record exists

    
    
    my($gf, $is_in) = $self->getFeatureFromDB('DoTS::GeneFeature'); 
    print STDERR "\n*** GUS::Model::DoTS::GeneFeature \$gf = $gf, \$is_in = $is_in ***\n\n";
    
    if ($UPDATE)  { #TW - no need to delete old gene features
	if ($is_in) {
	    ############
	    # Delete previous NALocation predictions
	    ##
	    my @children = $gf->getChildren('DoTS::NALocation', 1);
	    $gf->markChildrenDeleted(@children);
	    
	    print STDERR "buildGeneFeature() : Mark deleted ", scalar(@children), " NALocation(s)\n";
	}
    }

    unless ($gf->getParent('DoTS::ExternalNASequence')) {
        $gf->setParent ($gus_sequence);
    }
    
    #if ($UPDATE)  {
	foreach my $att (keys %{$h}) {
	    #if ($gf->get($att) ne $h->{$att}) {
		#print STDERR "buildGeneFeature(): $att has changed/will be set to for DoTS::GeneFeature $systematic_id: Object value == '",$gf->get($att), "' lastest value == '", $h->{$att},"'\n";
	    print STDERR "Setting values from GeneFeature object: lastest value == '", $h->{$att},"'\n";
	    $gf->set($att, $h->{$att});
	    #}
	}
    #}
    
    ###############
    # NALocation object related to the Gene
    ###
    my $gus_naLocation_gf = $self->buildNALocation ($gf, $bioperl_geneLocation);


    ##########################################
    # Process the note & curation qualifiers
    #
    # FIXME: BUT WHERE DO THEY GO?????
    #
    # TW-/note and /curation entered into 
    # DoTS.NAFeatureComment 01/17/05 
    ##########################################

    my @gus_notes = ();
    
    if ($bioperl_feature->has_tag ('note')) {
	print STDERR "FOUND A NOTE:$bioperl_feature FOR GF:$gf\n";
        my @bioperl_notes = $bioperl_feature->each_tag_value ('note');
        foreach my $bioperl_note (@bioperl_notes) {
            my $h = {
                'comment_string'     => $bioperl_note,
            };
	    
            # FIXME - The Note table has gone. What has replaced it???
            my $gus_note = GUS::Model::DoTS::NAFeatureComment->new ($h);
            #$gus_note->retrieveFromDB();  #TW - why is this needed? Also, table has CLOB.
            $gus_note->setParent ($gf);  
	    push (@gus_notes, $gus_note);
        }
    }
        
    print STDERR join ("\n" , map {"NOTES(map):" . $_->getCommentString()} @gus_notes) . "\n";


    if ($bioperl_feature->has_tag ('curation')) {
        my @bioperl_curations = $bioperl_feature->each_tag_value ('curation');
        foreach my $bioperl_curation (@bioperl_curations) {
            my $h = {
                'remark'     => $bioperl_curation,
            };
      
            # FIXME - The Note table has gone. What has replaced it???
            #my $gus_note = Note->new ($h);
            #$gus_note->retrieveFromDB();
            #$gus_note->setParent ($gf);
            #push (@gus_notes, $gus_note);
        }
    }

    ##
    # /db_xref & psu_db_xref - the later can have a description after the DB:123 bit.
    ##
    my @child_refs = $self->buildDbRefs($gf);

    ##
    # /literature
    ##

    # Delete old /literature info, no versioning here.

#
# THIS CODE NEEDS TO BE EXAMINED IN DETAIL, CUT AND PASTE JOBS HENCE LOGIC CORRECT BUT NOT OBJECT NAMES ETC
#

    #my @children = $rnaf->getChildren('DoTS::NALocation', 1);
    #$rnaf->markChildrenDeleted(@children);

    #print STDERR "buildGeneFeature() : Mark deleted ", scalar(@children), " NALocation(s)\n";

    # create new literature
    #if ($bioperl_feature->has_tag ('literature')) {
    #    my @lit_strings = $bioperl_feature->each_tag_value ('literature');

    #    foreach my $lit (@lit_strings) {
    #        # parse out 'PubMed:8719249; blah blah blah'
    #        my ($db, $remark) = split(/\s*;\s*/, $lit); 

    #        my $db_ref_id = $self->get_db_ref_id($db);

    #        my $h = {
    #            'db_ref_id' => $db_ref_id,
    #            'remark'    => $remark,
    #        };
      
            # FIXME - The Note table has gone. What has replaced it???

            #my $gus_note = Note->new ($h);
            #$gus_note->retrieveFromDB();
            #$gus_note->setParent ($gf);
            #push (@gus_notes, $gus_note);
    #    }
    #}


    push (@gus_note_objects, @gus_notes);

    $gf->submit();  ## ##BG submit here?? YES, else, na_feature_id not found
    print STDERR "CHECK buildGeneFeature - id=" . $gf->getId() ."\n";

    return ($gf, $gus_naLocation_gf, @gus_note_objects, @child_refs);
}



#################################################################
# Probably based in a GeneFeature but could be anything.
# Deletes old db refs, no versioning
# Creates new DbRefNAFeature -> SRes.DbRef
####

#TW-NOTE: this is handled differently by PlasmoDB, DoTS.Comment????

sub buildDbRefs {
    my ($self, $na_feature) = @_;
    my @objects;

    # Delete old, no versioning here (yet). DbRef holds remark, hence can not be shared between
    # "identical" DbRefs
    my @children = $na_feature->getChildren('DoTS::DbRefNAFeature', 1);

    foreach my $child (@children) {
        my $db_ref_parent = $child->getParent('SRes::DbRef');
        print "\$db_ref_parent  = $db_ref_parent\n";
        $db_ref_parent->markDeleted();  #TW-what is this?
    }

    $na_feature->markChildrenDeleted(@children);  #TW-what is this?

    print STDERR "buildDdRefs() : Mark deleted ", scalar(@children), " NALocation(s)\n";

    my @all_refs = ();

    if ($self->{'bioperlFeature'}->has_tag('db_xref')) { # 
        my @db_xrefs = $self->{'bioperlFeature'}->each_tag_value('db_xref');
        @all_refs    = map { [$_, undef] } @db_xrefs;
    }

    # db_xref
    #
    if ($self->{'bioperlFeature'}->has_tag('db_xref')) { # 
        my @db_xrefs = $self->{'bioperlFeature'}->each_tag_value('db_xref');

        foreach my $db_xref (@db_xrefs) {
            my $db_ref_obj = $self->buildDbRef($db_xref, undef, $na_feature->getDatabase()->getDbHandle());

            next unless defined $db_ref_obj;

            my $db_ref_na_feature = GUS::Model::DoTS::DbRefNAFeature->new();
            $db_ref_na_feature->setParent($na_feature);
            $db_ref_na_feature->setParent($db_ref_obj);

            push @objects, ($db_ref_obj, $db_ref_na_feature);
        }
    }

    # psu_db_xref - it has a remark field, db_xref does not.
    #
    if ($self->{'bioperlFeature'}->has_tag('psu_db_xref')) { # 
        my @psu_db_xrefs = $self->{'bioperlFeature'}->each_tag_value('psu_db_xref');

        foreach my $psu_ref (@psu_db_xrefs) {
            my ($db_ref, $remark) = split(/\s*;\s*/, $psu_ref); # parse out 'PubMed:8719249; This is a link'

            my $db_ref_obj = $self->buildDbRef($db_ref, $remark, $na_feature->getDatabase()->getDbHandle());

            next unless defined $db_ref_obj;

            my $db_ref_na_feature = GUS::Model::DoTS::DbRefNAFeature->new();
            $db_ref_na_feature->setParent($na_feature);
            $db_ref_na_feature->setParent($db_ref_obj);

            push @objects, ($db_ref_obj, $db_ref_na_feature);
        }
    }

    print "buildDbRefs() returning ", join(', ', @objects), "\n";

    return @objects;
}


#######################################################################
# Return a SRes::DbRef object given an string e.g. 'PubMed:123'
####

sub buildDbRef {
    my ($self, $ref, $remark, $dbh) = @_;

    if ((! defined $ref) || ($ref eq '')) {
        die "ERROR: buildDbRef() passed invalid xref = '$ref'";
    }

    my ($db, $id) = split(':', $ref);
    my ($edri)    = $self->getExternalDatabaseReleaseId($dbh, $db);

    unless (defined $edri) {
        print STDERR "WARNING: Can not build SRes::DbRef without a external_database_release_id for $db\n";
        return undef;
    }

    my $db_ref    = GUS::Model::SRes::DbRef->new({'external_database_release_id' => $edri,
                                                  'primary_identifier'           => $id,
                                                  'lowercase_primary_identifier' => lc($id),});
    if (defined $remark) {
        $db_ref->setRemark($remark);
    }

    #my $result    = $db_ref->retrieveFromDB();

    return $db_ref;
}


#####################################################################
#Creates new RNAFeature or updates the old one.
#
#NOTE: The old version used to set na_sequence (its parent) to be 
#the unspliced_sequence
#       I presume this is a bug.
#
# FIXME?
# It will not update values to its parents GeneFeature and SplicedNASequence.
# Is this an issue??? Possibly
####

sub buildRNAFeature {
    my ($self, $gf, $snas, $number_of_exons, $bioperl_geneLocation, $systematic_id) = @_;

    my $debug             = $self->{debug};
    my $bioperl_feature   = $self->{bioperlFeature};
    my $gus_sequence      = $self->{gusSequence};

    # translation start and stop => start and end if not partial or not pseudogene

    # at the moment not several mRNA but in theory could be !!

    #my $subclass_view     = "RNAFeature";
    #my $name              = $gf->get ('standard_name');
    my $is_predicted      = 1;
    my $review_status_id  = $REVIEW_STATUS_ID;
    #'my $na_sequence_id    = $gus_sequence->getNaSequenceId (); # This is the UNSPLICED na_sequence!!!
    #my $source_id         = $gus_sequence->getSourceId();
    my $parent_id         = $gf->getId();  ## ## BG
    print STDERR "CHECK buildRNAFeature - parent_id=" . $parent_id . "\n";


    ####################################
    # Get codon start information
    ############
    my $c_start=undef;
    
    if ($bioperl_feature->has_tag('codon_start'))  {
	my @start_codons = $bioperl_feature->each_tag_value ('codon_start');
        $c_start  = $start_codons[0];
        print STDERR "RF-Start codon:$c_start\n";
    }

    ################################
    # Get codon stop information
    ##############
    my $c_stop=undef;
    
    # First, get peptide length value from EMBL file
    if ($bioperl_feature->has_tag('peptide_length')) {
        my @tmp    = $bioperl_feature->each_tag_value('peptide_length');
        my $length = $tmp[0];
        print STDERR "peptide length: $length\n";
	
	$c_stop = ($c_start - 1) + (3 * $length);
	print STDERR "RF-CODON START:$c_start\tSTOP:$c_stop\tPEPLEN:$length\n";
	#my $c=$c_start-1;
	#print STDERR "RF-C:$c\n";
    }



    #########################################
    # Figure out the $prediction_algorithm_id
    # using /method
    ####
    #TW-method is ok
    my $prediction_algorithm_id = undef;

    if ($bioperl_feature->has_tag ('method')) {
        my @methods = $bioperl_feature->each_tag_value ('method');
        my $method  = $methods[0];

        if ($method =~ /manual annotation/i) {
            #$method = "Manual Annotation";
	    $method = "Pf Annotation"; #value from Database for previous GeneFeature entries
        }
        elsif ($method =~ /automatic annotation/i) {
            $method = "Automatic Annotation";
	    exit 1; #TW - don't know how to handle this IF it happens
        }

	my $algo   = GUS::Model::Core::Algorithm->new ({'name' => "$method"});
        my $result = $algo->retrieveFromDB();

        if ($result == 1) {
            $prediction_algorithm_id = $algo->getAlgorithmId();
        }
        else {
            # Annotate the gene feature as a 'Manual Annotation' per default
            $algo   =
		#TW GUS::Model::Core::Algorithm->new ({'name' => "Manual Annotation"});
		GUS::Model::Core::Algorithm->new ({'name' => "Pf Annotation"});
	    $result = $algo->retrieveFromDB();
            
            if ($result == 1) {
                $prediction_algorithm_id = $algo->getAlgorithmId();
            }
        }
    }
    print STDERR "RF-PREDICTION_ALG_ID:$prediction_algorithm_id\n\n";
    ####################


    my $h = {
        'is_predicted'        => $is_predicted,
        'review_status_id'    => $review_status_id,
        # This is what it used to do, which is surely wrong
        #'na_sequence_id'     => $na_sequence_id, # this is the unspliced sequence!
        'number_of_exons'     => $number_of_exons,
        #'source_id'          => $standard_name, #TW-previously source_id
        'external_database_release_id'  => $EXT_DB_REL_ID,
	'prediction_algorithm_id'       => $prediction_algorithm_id,
	'name'                => 'RNAFeature', 
	'translation_start'   => $c_start,
	'translation_stop'    => $c_stop,
    };

    #my $rnaf  = GUS::Model::DoTS::RNAFeature->new ({'name' => $systematic_id});
    #my $is_in = $rnaf->retrieveFromDB();

    #my ($rnaf, $is_new) = $self->getFeatureFromDB('DoTS::RNAFeature');
    my $rnaf = $gf->getChild('DoTS::RNAFeature', 1);

    if ($rnaf) {
	#TW-NOTE: No need to delete any children!!!
        ########
        # Delete NALocation child object
        #######
        my @children = $rnaf->getChildren('DoTS::NALocation', 1);
        $rnaf->markChildrenDeleted(@children);
        print STDERR "buildRNAFeature() : Mark deleted ", scalar(@children),
        " NALocation(s)\n";
    }
    else {
        my $sys_id = $self->get_best_systematic_id();
        $rnaf  = GUS::Model::DoTS::RNAFeature->new ({'source_id' => $sys_id}); #TW - use src_id
    }

    unless ($rnaf->getParent($gf->getClassName(), 1)) {
        $rnaf->setParent($gf);
    }

    unless ($rnaf->getParent($snas->getClassName(), 1)) {
        $rnaf->setParent($snas);
    }

    #TW-just load new RNAFeatures, do not compare
    foreach my $att (keys %{$h}) {
        #TWif ($rnaf->get($att) ne $h->{$att}) {
            print STDERR "buildRNAFeature(): $att has changed/will be set to for DoTS::RNAFeature $systematic_id: Object value == '",$rnaf->get($att), "' lastest value == '", $h->{$att},"'\n";
            $rnaf->set($att, $h->{$att});
        #TW}
    }

    print STDERR "CHECK: rna_feat_id=" . $rnaf->getId . "\n"; ## ##BG
    ##
    # New NALocation object
    ##
    my $gus_naLocation_rf = $self->buildNALocation($rnaf, $bioperl_geneLocation);
    $rnaf->submit();  ## ##BG submit here?? YES, else, na_feature_id not found
    print STDERR "CHECK buildRNAFeature - id=" . $rnaf->getId() ."\n";

    return $rnaf, $gus_naLocation_rf;
}

################################################################################
# Return a new DoTS::SplicedNASequence object or the existing one that *may*
# have been updated if values have changed.
#
sub buildSplicedNASequence {
    my ($self, $gene_feature)  = @_;
    
    my $debug             = $self->{debug};
    my $bioperl_feature   = $self->{bioperlFeature};
    my $gus_sequence      = $self->{gusSequence};
    #my $display_id       = $self->{bioperlSequence}->display_id; # The NAME
    my $display_id        = $gene_feature->getName();
    print STDERR "GF:$display_id\n\n";
    my $sequence_version  = 1;

    my $bioperl_sequence = $self->{bioperlSequence};  #TW, to get organism tag?



    #################
    # Get value of organism tag
    #############
    my $organism=undef;
    my @features         = $bioperl_sequence->get_all_SeqFeatures();
    foreach my $feature (@features) {
	if ($feature->primary_tag() =~ /source/) {
	    my @tags = $feature->all_tags();
	    
	    if ($debug) {
		print STDERR "Found source feature\n";
		print STDERR "Tags: @tags\n";
	    }
	    
	    foreach my $tag (@tags) {
		if ($tag =~ /organism/i) {
		    my @values = $feature->each_tag_value('organism');
		    $organism = $values[0];
		}
		
	    }
	}
    }
    my $taxon_id  = getTaxonIdentifier ($organism);
    
    

    #################
    # Get source_id
    ######
    #TW-this may not be getting the right value
    #my $source_id = $gus_sequence->getSourceId(); #SOURCE_ID used by us to store chromo info i.e. 'chr. 1'
    #print STDERR "DEBUG-SRCID:$source_id\n";
    

    my $sequence          = $bioperl_feature->spliced_seq();  #TW-is this correct?
    #print STDERR "SplicedNASequence:$sequence\n";
    #print STDERR "DEBUG-SplicedNASeq-bg1\n";


    ######################
    # Get the base count
    ########
    my $spl_sequence = $sequence->seq();
    my %basesCount  = getBasesCount ($spl_sequence);
    my $a_count     = $basesCount{a};
    my $t_count     = $basesCount{t};
    my $c_count     = $basesCount{c};
    my $g_count     = $basesCount{g};
    my $other_count = $basesCount{o};
    my $length      = length ($spl_sequence);


    
    my $sequence_type_id  = $self->getSequenceTypeIdentifier ('RNA');
    print STDERR "DEBUG-SEQID for RNA:$sequence_type_id\n";
    print STDERR "DEBUG-SplicedNASeq-bg2\n";
    if (not defined $sequence_type_id) {
        print STDERR "can't find any SequenceType Database entry associated with RNA\n";
        print STDERR "failed creating a SplicedNaSequence entry...\n";
        return undef;
    }
    print STDERR "DEBUG-SplicedNASeq-bg3\n";

    if ($self->{debug}) {
        print STDERR "Spliced sequence:\n";
        print STDERR $sequence->seq() . "\n";
    }
    
    
    if ($debug)  {
	#print STDERR "buildSplicedNASequence(): source_id == $source_id, display_id = $display_id\n"; # if $self->{debug};
	#print STDERR "buildSplicedNASequence():display_id = $display_id\n";
    }
    #TWmy $snas  = GUS::Model::DoTS::SplicedNASequence->new({'name' => $display_id});
    #TW  my $is_in = $snas->retrieveFromDB(); # 0 means zero or 2+ records exist, 1 means 1 record exists
    #TW unless ($is_in) {
        #PSU  WHAT ABOUT THE CHILD, 'RNAFEATURE'???    
    #TW }

    my $h = {
	    'sequence_version'  => $sequence_version,
	    'sequence_type_id'  => $sequence_type_id,
	    'external_database_release_id'  => $EXT_DB_REL_ID,
	   #'source_id'         => $source_id, #TW	
	    'name'              => 'SplicedNASequence',
	    'taxon_id'          => $taxon_id,		
	    'sequence'          => $sequence->seq(),
	    'a_count'           => $a_count,
	    'c_count'           => $c_count,
	    'g_count'           => $g_count,
	    't_count'           => $t_count,
	    'other_count'       => $other_count,
	    'length'            => $length,	
	};
    
    print STDERR "SNAS-LEN:$length\n";

    #TW-START---------------------
    my $sys_id = $self->get_best_systematic_id();
    my $snas  = GUS::Model::DoTS::SplicedNASequence->new ({'source_id' => $sys_id});
    print STDERR "SNAS-SRC_ID:$sys_id\n";
    #TW-END-----------------------
    
    foreach my $att (keys %{$h}) {
        #TWif ($snas->get($att) ne $h->{$att}) {
            print STDERR "buildSplicedNASequence(): $att has changed for DoTS::SplicedNASequence $display_id: Object == '",$snas->get($att), "' lastest value == '", $h->{$att},"'\n";
            $snas->set($att, $h->{$att});
        #TW}
    }
    $snas->submit();## ##BG submit here else no ID
    print STDERR "CHECK buildSplicedNASequence - id=" . $snas->getId() . "\n";
    return $snas;
}

################################################################################
# This is linked to NASequence, not UnsplicedNASequence
#
# FIXME: Will this always find the original child feature??????
###########

sub buildExonFeature {
    my ($self, $gf, $is_initial_exon, $is_final_exon, $location, $order_number) = @_;

    my $debug             = $self->{debug};
    my $bioperl_feature   = $self->{bioperlFeature};
    my $gus_sequence      = $self->{gusSequence};
    #my $name              = $gf->get ('standard_name') . ".exon $order_number";
    #TWmy $name              = $gf->get('name') . ".exon $order_number";
    my $name              = 'ExonFeature';
    my $is_predicted      = 1;
    my $review_status_id  = $REVIEW_STATUS_ID;
    my $na_sequence_id    = $gus_sequence->getNaSequenceId();
    #TWmy $source_id         = $gus_sequence->getSourceId();     # SOURCE_ID used by us to store chromo info i.e. 'chr. 1'

    print STDERR "EF-NAME:$name\n";

    my ($start, $end)     = ($location->start, $location->end);
    if ($location->strand == -1) {
        # no 'is_reversed' like NALocation has, just switch the coords round to show 'strandiness'
        ($start, $end) = ($end, $start);
    }


    #########################################
    # Figure out the $prediction_algorithm_id
    # using /method
    ####
    #TW-method is ok
    my $prediction_algorithm_id = undef;

    if ($bioperl_feature->has_tag ('method')) {
        my @methods = $bioperl_feature->each_tag_value ('method');
        my $method  = $methods[0];

        if ($method =~ /manual annotation/i) {
            #$method = "Manual Annotation";
	    $method = "Pf Annotation"; #value from Database for previous GeneFeature entries
        }
        elsif ($method =~ /automatic annotation/i) {
            $method = "Automatic Annotation";
	    exit 1; #TW - don't know how to handle this IF it happens
        }

	my $algo   = GUS::Model::Core::Algorithm->new ({'name' => "$method"});
        my $result = $algo->retrieveFromDB();

        if ($result == 1) {
            $prediction_algorithm_id = $algo->getAlgorithmId();
        }
        else {
            # Annotate the gene feature as a 'Manual Annotation' per default
            $algo   =
		#TW GUS::Model::Core::Algorithm->new ({'name' => "Manual Annotation"});
		GUS::Model::Core::Algorithm->new ({'name' => "Pf Annotation"});
	    $result = $algo->retrieveFromDB();
            
            if ($result == 1) {
                $prediction_algorithm_id = $algo->getAlgorithmId();
            }
        }
    }
    print STDERR "EF-PREDICTION_ALG_ID:$prediction_algorithm_id\n\n";


    #TW-START---------------------
    my $sys_id = $self->get_best_systematic_id();
    #my $ef  = GUS::Model::DoTS::ExonFeature->new ({'source_id' => $sys_id});
    print STDERR "EF-SRC_ID:$sys_id\n";
    #TW-END-----------------------


    my $h = {
        'name'             => $name,
        'is_predicted'     => $is_predicted,
        'review_status_id' => $review_status_id,
        'na_sequence_id'   => $na_sequence_id,
        'order_number'     => $order_number,
        'is_initial_exon'  => $is_initial_exon,
        'is_final_exon'    => $is_final_exon,
	'source_id'        => $sys_id,
        'coding_start'     => $start,
        'coding_end'       => $end,
	'external_database_release_id'  => $EXT_DB_REL_ID,
	'prediction_algorithm_id'       => $prediction_algorithm_id,
    };


    my $ef = GUS::Model::DoTS::ExonFeature->new ($h);
    $ef->retrieveFromDB();

    unless ($ef->getParent($gf->getClassName(), 1)) {
        $ef->setParent($gf);
    }

    foreach my $att (keys %{$h}) {
        #TWif ($ef->get($att) ne $h->{$att}) {
            print STDERR "buildExonFeature(): $att has changed for DoTS::buildExonFeature ".$gf->getName().": Object == '",$ef->get($att), "' lastest value == '", $h->{$att},"'\n";
            $ef->set($att, $h->{$att});
        #TW}
    }
    return $ef;
}


################################################################################
#
# This is linked to NASequence, not UnsplicedNASequence
#
sub buildRNAFeatureExon {
  my ($self, $ef, $rnaf) = @_;

  print "buildRNAFeatureExon(): \$rnaf->getId() = ", $rnaf->getId(), ", \$ef->getId() = ", $ef->getId(), " \n";

  my $h = {
      'rna_feature_id'  => $rnaf->getId(),
      'exon_feature_id' => $ef->getId()
      };

  my $rfe   = GUS::Model::DoTS::RNAFeatureExon->new($h);
  my $is_in = $rfe->retrieveFromDB();

  return $rfe if $is_in;

  print "\$rfe;\n", $rfe->toXML();  #TW-what is toXML()
  print "parents: ", $rfe->getParent($rnaf->getClassName()), ", ", $rfe->getParent($ef->getClassName()), "\n";


  # The $rnaf and $ef (RNAFeature and ExonFeatures) may not have been
  # commited to the database yet. Hence the above won't have set any
  # values in our new RNAFeatureExon object
  #
  unless ($rfe->getParent($rnaf->getClassName())) {
      $rfe->setParent($rnaf);
  }

  unless ($rfe->getParent($ef->getClassName()) ){
      $rfe->setParent($ef);
  }

  return $rfe;
}

################################################################################
# Gets already created DoTS::TranslatedAASequence and updates it or creates a
# new one.
#############

sub buildTranslatedAASequence {
    ###  my ($self, $gf, $aa_feature_translated, $systematic_id) = @_;
    my ($self, $gf, $systematic_id) = @_;
    
    my $debug            = $self->{debug};
    my $bioperl_feature  = $self->{bioperlFeature};
    my $bioperl_sequence = $self->{bioperlSequence};
    my $datasource       = $self->{datasource};
    
    my $seq_version  = 1;
    my $is_simple = 1;

    ################################
    # Get the external_database_release_id associated with it
    #TW-NOTE:This is overwritten by GLOBAL VARIABLE
    #TW-this was done for time efficieny and is NOT RECOMENDED PRACTICE!
    print STDERR "LOOKING FOR EXTDB_REL-ID\n";
    my $ext_db = GUS::Model::SRes::ExternalDatabase->new ({"name" => $datasource});
    my $exist  = $ext_db->retrieveFromDB();
    my $ext_db_id;
    print STDERR "TAAF-EXTDB_REL-ID:$ext_db\n\n";  #TW
    my $ext_db_release_id;
    if ($exist) {
	$ext_db_id = $ext_db->getId();
	my $ext_db_release = GUS::Model::SRes::ExternalDatabaseRelease->new ({"external_database_id" => $ext_db_id});
	#TW-$exist = $ext_db_release->retrieveFromDB();
	$exist = $ext_db_release_id = $EXT_DB_REL_ID;  #TW - hard-coded
	if ($exist) {
	    #$ext_db_release_id = $ext_db_release->getId();
	    print STDERR "EXTDB_REL-ID:$ext_db_release_id\n\n";
	}
	else {
	    print STDERR "ERROR-ExtDbRelId - can't get the External Database Release ID associated with this datasource, $datasource!\n";
	    exit 1;
	}
    }
    else {
	print STDERR "ERROR-ExtDbId - can't get the External Database ID associated with this datasource, $datasource!\n";
	exit 1;
    }
    
    print STDERR "In buildTranslatedAASequence()\n";

    my $subclass_view = "TranslatedAASequence"; 
    #my $name          = $gf->get ('standard_name'); # This was only used in debug output


    #TW-there are no product qualifiers
    # Description is now the concatenation of the set of product qualifiers
    #
    my $aa_seq_descr = "";

    if ($bioperl_feature->has_tag ('product')) {
        my @bioperl_products = $bioperl_feature->each_tag_value ('product');

        foreach my $bioperl_product (@bioperl_products) {
            $aa_seq_descr .= $bioperl_product . "; ";
        }
    }
    $aa_seq_descr =~ s/\s$//; # Remove last space put on above via "; "

    
  
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

    ##########
    # Frame information
    my $frame = 0;

    if ($bioperl_feature->has_tag ('codon_start')) {
        my @start_codons = $bioperl_feature->each_tag_value ('codon_start');
        my $start_codon  = $start_codons[0];
        $frame = $start_codon - 1;
    }

    ##########
    # Translation table to use
    my $transl_table = 1;

    if ($bioperl_feature->has_tag ('transl_table')) {
        my @transl_tables = $bioperl_feature->each_tag_value ('transl_table');

        if ($transl_tables[0] != -1) {
            $transl_table  = $transl_tables[0];

            print "\n################################################################################\n";
            print "WARNING: buildTranslatedAASequence(): using \$transl_table = '$transl_table'\n";
            print "         This bit needs to be fully checked.\n";
            print "################################################################################\n\n";
        }

    }

    # For args to translate(), see http://doc.bioperl.org/releases/bioperl-1.4/Bio/PrimarySeqI.html#POD10
    # 1. character for terminator (optional) defaults to '*'
    # 2. character for unknown amino acid (optional) defaults to 'X'
    # 3. frame (optional) valid values 0, 1, 2, defaults to 0
    # 4. codon table id (optional) defaults to 1
    # 5. complete coding sequence expected, defaults to 0 (false)

    #my $prot_seq = $spliced_seq->translate(undef,undef,$frame,$is_complete,0);
    my $prot_seq = $spliced_seq->translate(undef, undef, $frame, $transl_table, $is_complete);
    my $test_prot_seq = $prot_seq->seq();
    print STDERR "TAAS:TEST-PROT_SEQ:$test_prot_seq\n";
    print STDERR "TAAS:EXT_DB_REL_ID:$EXT_DB_REL_ID\n";

    if ($debug) {
        print STDERR "translated protein sequence for gene, $systematic_id:\n";
        #TW-print STDERR $prot_seq->seq() . "\n";
    }

    my $h = {
	     'subclass_view'    => $subclass_view,
	     'sequence_version' => $seq_version,
	     'description'      => $aa_seq_descr,
	     #'sequence'         => $prot_seq->seq(),
	     'sequence'         => $test_prot_seq, 
	     'external_database_release_id' => $EXT_DB_REL_ID,
	     #'is_simple'        => $is_simple,
	 };

    
    my $aa_seq  = GUS::Model::DoTS::TranslatedAASequence->new($h); ###BG
    
    $aa_seq->setIsSimple($is_simple);
    print "TAAS:IS_SIMPLE:$is_simple\tAASEQ:" .  $aa_seq->getIsSimple() . "\n";

    print "PROTSEQ:" . $prot_seq->seq()  . "\n";
    
    # need source_id
    #$aa_seq->setSourceId ($source_feature->getNaFeatureId());
    #TW-START---------------------
    my $sys_id = $self->get_best_systematic_id();
    my $aa_seq  = GUS::Model::DoTS::TranslatedAASequence->new ({'source_id' => $sys_id});
    print STDERR "TAAS-SRC_ID:$sys_id\n";
    #TW-END-----------------------



    ###
    # Molecular Weight
    #
    if ($bioperl_feature->has_tag ('molecular_weight')) {
        my @tmp        = $bioperl_feature->each_tag_value('molecular_weight');
        my $mol_weight = $tmp[0];
        $mol_weight    =~ s/\s*da//i;
        print STDERR "mol weight    : $mol_weight\n";

	if (! ($mol_weight =~ /^\d+$/)) {
	  print STDERR "molecular weight, $mol_weight, not a number !!!\n";
	}
	else {
	    if ($aa_seq->get('molecular_weight') != $mol_weight) {
		$aa_seq->set ('molecular_weight', $mol_weight);
	    print STDERR "NO molecular weight\n";
	  }
	}
    }

    ###
    # Peptide Length
    #
    if ($bioperl_feature->has_tag('peptide_length')) {
        my @tmp    = $bioperl_feature->each_tag_value('peptide_length');
        my $length = $tmp[0];
        print STDERR "peptide length: $length\n";

        if ($aa_seq->get('length') != $length) {
            $aa_seq->set('length', $length);
        }
    }

    # We may have got the "old" TranslatedAASequence from $aa_feature_translated
    # in the first place.
    #
#    unless ($aa_feature_translated->getParent($aa_seq->getClassName())) {
#        $aa_feature_translated->setParent($aa_seq);
#    }

    my (@properties) = $self->buildProteinProperties($aa_seq);

    return ($aa_seq, @properties);;
}


################################################################################
# Set stuff like molecular_weight, isoelectric_point etc.
#
# Due to design error in Schema (DomainFeature has 2 parents of
# TranslatedAASequence) the objects created here must be returned. No deep
# submit can be done - DoaminFeature bodge in place in genericParser2Gus
##

sub buildProteinProperties {
    my ($self, $aa_seq) = @_;

    ###
    # get dictionary ProteinPropertyType

    my $sql                      = "SELECT name, protein_property_type_id FROM DoTS.ProteinPropertyType";
    my $queryHandle              = $aa_seq->getDatabase()->getDbHandle();
    my $sth                      = $queryHandle->prepareAndExecute($sql);
    my %protein_property_type_id = ();
    my $bioperl_feature          = $self->{'bioperlFeature'};

    while (my ($name, $id) = $sth->fetchrow_array()) {
        $protein_property_type_id{$name} = $id;
    }

    ###
    # Make hash map of each protein_type to the object

    my @protein_properties = $aa_seq->getChildren('DoTS::ProteinProperty', 1);
    my %hash_properties    = map {$_->get('protein_property_type_id'), $_} @protein_properties;

    # 
    #print "buildProteinProperties(): \%hash_properites (previous versions values) ;\n";
    #print Data::Dumper::Dumper(\%hash_properties);

    foreach my $type_id (keys %hash_properties) { 
        my $type        = $hash_properties{$type_id}->{'attributes'}->{'protein_property_type_id'};
        my $value       = $hash_properties{$type_id}->{'attributes'}->{'value'};
        my $value_units = $hash_properties{$type_id}->{'attributes'}->{'value_units'};
        print "   Type ID: '$type'  Value & Units: '$value' '$value_units'\n";
    }

    ###
    # For each ProteinPropertyType, alter old value or create new one.
    # Delete if value no longer is in EMBL file
    my @properties;

    foreach my $prop (keys %protein_property_type_id) {
        my ($pp, $embl_value, $embl_unit) = (undef, undef, undef); 
        my $prop_type_id = $protein_property_type_id{$prop};
	
        if ($bioperl_feature->has_tag($prop)) {
            my @values = $bioperl_feature->each_tag_value($prop);
            my $value  = $values[0];
            ($embl_value, $embl_unit) = split(/\s+/, $value);
	    
            if ($embl_value eq 'pH'){ # special case for ioselectric-point
                ($embl_value, $embl_unit) = ($embl_unit, $embl_value);
            }
	    
            $embl_unit = 'unknown' unless defined $embl_unit;
        }
	
        if (defined($hash_properties{$prop_type_id})) {
            $pp = $hash_properties{$prop_type_id};
        }

        print "buildProteinProperties(): prop = $prop, type_id = ", $protein_property_type_id{$prop}, "  pp = $pp\n";

        # Delete if prop no longer in EMBL file but still exists in DB
        #
        if ( (! defined($embl_value)) && $pp) {
            print "buildProteinProperties(): Deleting $pp, value no longer in EMBL file\n";
            $pp->markDeleted();
        }
        # Update if no changed in EMBL file
        elsif ($embl_value && $pp) {
            if ($pp->getValue() ne $embl_value) {
                print "buildProteinProperties(): Changing from ", $pp->getValue(), " to $embl_value, $embl_unit\n";

                $pp->setValue($embl_value);
                $pp->setValueUnits($embl_unit);
            }
        }
	
        #Create new one if in EMBL file but not hash
        elsif ($embl_value && (! defined($pp))) {
            print "buildProteinProperties(): Creating new ProteinProperty of type '$prop' with values $embl_value, $embl_unit\n";
	    
            $pp = GUS::Model::DoTS::ProteinProperty->new({
                'value'                    => $embl_value,
                'value_units'              => $embl_unit,
                'protein_property_type_id' => $protein_property_type_id{$prop},
            });
	    
            $pp->setParent($aa_seq);
        }
	
        push @properties, $pp if defined $pp;
    }
    
    print "buildProteinProperties(): returning: ", join(', ', @properties), "\n";

    return @properties;
}

########################################################
# Build EC Number - TranslatedAAFeature Associtations
#
# Populate DoTS.AASequenceEnzymeClass table
######################

sub buildEcNumber  {
    my ($self, $aa_seq) = @_;
    my $bioperl_feature  = $self->{bioperlFeature}; 
    my $ec_num  = undef;
    print STDERR "Method ECNUM called\n";
    
    my @aaSequenceEnzymeClass; #TW
    
    # number of associations made
    my $assoc_made_n = 0;
    
    # number of associations supplied
    my $assoc_given_n = 0;
    
    if ($bioperl_feature->has_tag ('EC_number')) {
	print STDERR "Found and EC number\n";
        my @ec_numbers = $bioperl_feature->each_tag_value ('EC_number');
        #$ec_num = $ec_numbers[0];  #TW
	
	foreach $ec_num(@ec_numbers)  {
	    print STDERR "EC_NUMS:$ec_num\n\n";
	    
	    #EnzymeClass object cache.
	    my $ec_cache_x = {};
	    
	    #get the EnzymeClass
	    my $ec_gus = $ec_cache_x->{$ec_num};
	    print STDERR "EC_GUS:$ec_gus\n";
	    unless ($ec_gus) {
		$ec_gus = GUS::Model::SRes::EnzymeClass->new({ ec_number => $ec_num, external_database_release_id=>7199 });
		if ($ec_gus->retrieveFromDB) {
		    $ec_cache_x->{$ec_num} = $ec_gus;
		} else {
		    $ec_gus = undef;
		    print STDERR "WARN-EC: " . "Could not find EnzymeClass " . "EC num:" . $ec_num;
		}
	    }
	    
	    # make the association if we found an
	    # EnzymeClass and process parents as well
	    while ($ec_gus) {
		my $aaSequenceEnzymeClass =
		    GUS::Model::DoTS::AASequenceEnzymeClass->new({ 
			evidence_code        => 'UNK',
			review_status_id=> 1,
		    });
		# note that these are done on the  attributes so that 
		# we can check for prexisting annotations.
		$aaSequenceEnzymeClass->setAaSequenceId($aa_seq->getId);
		print "AASEC1:$aaSequenceEnzymeClass\n";
		$aaSequenceEnzymeClass->setEnzymeClassId($ec_gus->getId);
		print "AASEC2:$aaSequenceEnzymeClass\n";

		#check to see association already exists between EC number and TranslatedAAFeature
		my $new_or_old;
		if ($aaSequenceEnzymeClass->retrieveFromDB) {
		    $new_or_old = 'old';
		} else {
		    $new_or_old = 'new ';
		    #TW$aaSequenceEnzymeClass->submit();
		    push (@aaSequenceEnzymeClass, $aaSequenceEnzymeClass);
		    $assoc_made_n++;
		    print "-ADDED EC->GENEASSOC\n";
		}
		print STDERR "NEW_OLD: $new_or_old " . 
		    $aa_seq->getId,
		    $ec_gus->getEcNumber . "\n";
		
		# get parent.
		print STDERR "Looking for EC parent\n";
		my $ec_parent_gus = $ec_gus->getParent('SRes::EnzymeClass',1);
		print STDERR "EC parent:$ec_parent_gus\n";
		if (!$ec_parent_gus) {
		    print STDERR "WARN: " . 'No parent found',$ec_gus->getEcNumber . "\n";
		    last;
		}
		
		#bail out at root.
		elsif ($ec_parent_gus->getDepth == 0) {
		    print SRDERR "ECNUM - ROOT FOUND\n";
		    last;
		}
		
		#make parent the 'current' EC.
		else {
		    $ec_gus = $ec_parent_gus;
		    print STDERR "ECNUM - Continue making ec_num associations\n";
		}
	    }
	    
	    #print STDERR "TOTAL OF:$assoc_made_n EC NUMBER ASSOCIATIONS MADE\n\n";
	    
	} 
	print STDERR "TOTAL OF:$assoc_made_n EC NUMBER ASSOCIATIONS MADE\n\n";
    }
    return @aaSequenceEnzymeClass; 
}


################################################################################
# Builds both
#     . TranslatedAAFeature (link table between na_feature and aa_feature/aa_sequence)
#     . ProteinFeature
#
# objects and returns them in that order.
#
# The ProteinFeature object stores the EC_number
####

sub buildProteinFeature {  ## ##BG
    my ($self, $rnaf)    = @_;
    my $gus_sequence     = $self->{gusSequence};
    my $bioperl_feature  = $self->{bioperlFeature};

    my $aaf = $rnaf->getChild('DoTS::TranslatedAAFeature', 1);

    print STDERR "buildProteinFeature(): getChild(TranslatedAAFeature) returned '$aaf'\n";
    print STDERR " CHECK - buildProteinFeature - rnafeature_id=" . $rnaf->getId() . "\n";
    ##
    # TranslatedAAFeature
    ##

    #my $subclass_view   = "TranslatedAAFeature";
    my $is_predicted     = 1;
    my $review_status_id = $REVIEW_STATUS_ID;
    # codon_table, is_simple, tr_start, tr_stop ????

    my $description      = "";

    if ($bioperl_feature->has_tag ('product')) {
        my @bioperl_products = $bioperl_feature->each_tag_value ('product');

        foreach my $bioperl_product (@bioperl_products) {
            $description .= $bioperl_product . "; ";
        }
    }

    $description =~ s/\s$//; # Remove trailing space from above "; "

    my $h = {
        #'subclass_view'    => $subclass_view,
        'is_predicted'     => $is_predicted,
        'review_status_id' => $review_status_id,
        'description'      => $description,
    };

    unless ($aaf) {
        $aaf = GUS::Model::DoTS::TranslatedAAFeature->new ($h);
        $aaf->setParent($rnaf);
        #$aaf->setParent($aa_seq);
    }

    foreach my $att (keys %{$h}) {
        #if ($aaf->get($att) ne $h->{$att}) {
            #print STDERR "buildProteinFeature(): $att has changed for DoTS::TranslatedAAFeature ",$rnaf->getName(),": Object == '",$aaf->get($att), "' lastest value == '", $h->{$att},"'\n";
            $aaf->set($att, $h->{$att});
        #}
    }

#    $aaf->submit(); ## ##BG    
    print STDERR "CHECK - buildProteinFeature(): 1 getChild(TranslatedAAFeature) returned" . $aaf . "  ID=" .$aaf->getId() ."  parent_id= " . $aaf->getNaFeatureId()  . "\n";



    ###
    # ProteinFeature
    ###

    #my $pf = $rnaf->getChild('GUS::Model::DoTS::ProteinFeature', 1);  #TW
    #print STDERR "buildProteinFeature(): getChild(ProteinFeature) returned '$pf'\n";

    my $name       = $rnaf->getName;
    #$subclass_view = "ProteinFeature";
    my $ec_num  = undef;


    my $aaSequenceEnzymeClass; #TW

    # number of associations made
    my $assoc_made_n = 0;
    
    # number of associations supplied
    my $assoc_given_n = 0;
    
    
    #TW-find all lines with EC_number 
    #Make sure all EC_ numbers are captured for a gene model!
    if ($bioperl_feature->has_tag ('EC_number')) {
        my @ec_numbers = $bioperl_feature->each_tag_value ('EC_number');
        $ec_num = $ec_numbers[0];
    }
    print STDERR "EC_NUMS:$ec_num\n\n";

    $h = {
        #'subclass_view' => $subclass_view,
        'name'          => $name,
    };

    #START---------------------
    #TW-EC info needs to be added to DoTS.AASequenceEnzymeClass NOT DoTS.ProteinFeature
    #unless ($pf) {

    #$pf = GUS::Model::DoTS::ProteinFeature->new ($h);
    #    $pf->setParent ($rnaf);
    #    $pf->setParent ($gus_sequence);
    #}
    #END----------------------


    #EnzymeClass object cache.
    my $ec_cache_x = {};
    
    #get the EnzymeClass
    my $ec_gus = $ec_cache_x->{$ec_num};
    unless ($ec_gus) {
	$ec_gus = GUS::Model::SRes::EnzymeClass->new({ ec_number => $ec_num, external_database_release_id=>7199 });
	if ($ec_gus->retrieveFromDB) {
	    $ec_cache_x->{$ec_num} = $ec_gus;
	} else {
	    $ec_gus = undef;
	    print STDERR "WARN-EC: " . "Could not find EnzymeClass " . "EC num:" . $ec_num;
	}
    }
    

    # make the association if we found an
    # EnzymeClass and process parents as well
    while ($ec_gus) {
	$aaSequenceEnzymeClass =
	    GUS::Model::DoTS::AASequenceEnzymeClass->new({ 
		evidence_code        => 'UNK',
		review_status_id=> 1,
	    });
	# note that these are done on the  attributes so that 
	# we can check for prexisting annotations.
	$aaSequenceEnzymeClass->setAaSequenceId($aaf->getId);
	$aaSequenceEnzymeClass->setEnzymeClassId($ec_gus->getId);
	
	#check to see association already exists between EC number and TranslatedAAFeature
	my $new_or_old;
	if ($aaSequenceEnzymeClass->retrieveFromDB) {
	    $new_or_old = 'old';
	} else {
	    $new_or_old = 'new';
	    #TW$aaSequenceEnzymeClass->submit();
	    $assoc_made_n++;
	    print "-ADDED EC->GENEASSOC\n";
	}
	 print STDERR "NEW_OLD: $new_or_old " . 
	     #$gene_xml->{GENE_INFO}->{PUB_LOCUS} || $gene_xml->{GENE_INFO}->{LOCUS},
	     #$gene_xml->{GENE_INFO}->{COM_NAME}, 
	     $aaf->getId, ##BG $aaf, 
	     $ec_gus->getEcNumber . "\n";
	
	# get parent.
	##BG more than one parent found; need to put in a release_id perhaps?
	 print STDERR "OLD: extdbid=" . $ec_gus->getExternalDatabaseReleaseId .
	     " and ecnum=" . $ec_gus->getEcNumber .
	     " and aaseqid=" . $aaSequenceEnzymeClass->setAaSequenceId($aaf->getId) .
	     "\n";	     ;   ## ##BG
	###BG   $ec_gus = GUS::Model::SRes::EnzymeClass->new({ ec_number => $ec_num, external_database_release_id=>7199 }); ##
	my $ec_parent_gus = $ec_gus->getParent('SRes::EnzymeClass',1);
	print STDERR "Looking for EC parent\n";
	if (!$ec_parent_gus) {
	    print STDERR "WARN: " . 'No parent found',$ec_gus->getEcNumber;
	    #$gene_xml->{GENE_INFO}->{PUB_LOCUS} || $gene_xml->{GENE_INFO}->{LOCUS},
	    #$gene_xml->{GENE_INFO}->{COM_NAME}, );
				   
	    last;
	}
	
	#bail out at root.
	elsif ($ec_parent_gus->getDepth == 0) {
	    print SRDERR "ECNUM - ROOT FOUND\n";
	    last;
	}
	
	#make parent the 'current' EC.
	else {
	    $ec_gus = $ec_parent_gus;
	    print STDERR "ECNUM - Continue making ec_num associations\n";
	}
    }

    print STDERR "TOTAL OF:$assoc_made_n EC NUMBER ASSOCIATIONS MADE\n\n";


    #START ------------------------------------------
    #TW-NOTE:do not need to delete
    #else {
    # May need to change the name here????????
    #$self->updateNames($pf);
    #}

    #if ($ec_num ne $pf->get('ec_number') ) {
    #    $pf->set ('ec_number', $ec_num);
    #}

    #return ($aaf, $pf);
    #END --------------------------------------------
    return ($aaf, $aaSequenceEnzymeClass);
}


##########################################################
sub buildTranslatedAAFeature {
    my ($self, $rnaf, $aa_seq)    = @_;
    my $gus_sequence     = $self->{gusSequence};
    my $bioperl_feature  = $self->{bioperlFeature};

    my $aaf = $rnaf->getChild('DoTS::TranslatedAAFeature', 1);

    print STDERR "buildTranslatedAAFeature(): getChild(TranslatedAAFeature) returned '$aaf'\n";
    print STDERR "CHECK - buildTranslatedAAFeature - rnafeature_id=" . $rnaf->getId() . "\n";
    ##
    # TranslatedAAFeature
    ##

    #my $subclass_view   = "TranslatedAAFeature";
    my $is_predicted     = 1;
    my $review_status_id = $REVIEW_STATUS_ID;
    # codon_table, is_simple, tr_start, tr_stop ????


    ####################################
    # Get codon start information
    ############
    my $c_start=undef;
    
    if ($bioperl_feature->has_tag('codon_start'))  {
	my @start_codons = $bioperl_feature->each_tag_value ('codon_start');
        $c_start  = $start_codons[0];
        print STDERR "TAAF-Start codon:$c_start\n";
    }

    ################################
    # Get codon stop information
    ##############
    my $c_stop=undef;
    
    # First, get peptide length value from EMBL file
    if ($bioperl_feature->has_tag('peptide_length')) {
        my @tmp    = $bioperl_feature->each_tag_value('peptide_length');
        my $length = $tmp[0];
        print STDERR "peptide length: $length\n";
	
	$c_stop = ($c_start - 1) + (3 * $length);
	print STDERR "TAAF-CODON START:$c_start\tSTOP:$c_stop\tPEPLEN:$length\n";
	#my $c=$c_start-1;
	#print STDERR "RF-C:$c\n";
    }



    #########################################
    # Figure out the $prediction_algorithm_id
    # using /method
    ####
    #TW-method is ok
    my $prediction_algorithm_id = undef;

    if ($bioperl_feature->has_tag ('method')) {
        my @methods = $bioperl_feature->each_tag_value ('method');
        my $method  = $methods[0];

        if ($method =~ /manual annotation/i) {
            #$method = "Manual Annotation";
	    $method = "Pf Annotation"; #value from Database for previous GeneFeature entries
        }
        elsif ($method =~ /automatic annotation/i) {
            $method = "Automatic Annotation";
	    exit 1; #TW - don't know how to handle this IF it happens
        }

	my $algo   = GUS::Model::Core::Algorithm->new ({'name' => "$method"});
        my $result = $algo->retrieveFromDB();

        if ($result == 1) {
            $prediction_algorithm_id = $algo->getAlgorithmId();
        }
        else {
            # Annotate the gene feature as a 'Manual Annotation' per default
            $algo   =
		#TW GUS::Model::Core::Algorithm->new ({'name' => "Manual Annotation"});
		GUS::Model::Core::Algorithm->new ({'name' => "Pf Annotation"});
	    $result = $algo->retrieveFromDB();
            
            if ($result == 1) {
                $prediction_algorithm_id = $algo->getAlgorithmId();
            }
        }
    }
    print STDERR "TAAF-PREDICTION_ALG_ID:$prediction_algorithm_id\n\n";



    ####################
    # Get description
    ###########
    my $description      = "";
    if ($bioperl_feature->has_tag ('product')) {
        my @bioperl_products = $bioperl_feature->each_tag_value ('product');

        foreach my $bioperl_product (@bioperl_products) {
            $description .= $bioperl_product . "; ";
        }
    }
    $description =~ s/\s$//; # Remove trailing space from above "; "



    my $h = {
        #'subclass_view'    => $subclass_view,
        'is_predicted'     => $is_predicted,
        'review_status_id' => $review_status_id,
        'description'      => $description,
	'prediction_algorithm_id'  => $prediction_algorithm_id,	
	'translation_start'   => $c_start,
	'translation_stop'    => $c_stop,
    };

    unless ($aaf) {
	print STDERR "DEBUG-TAAF1, BP\n";
        $aaf = GUS::Model::DoTS::TranslatedAAFeature->new ($h);
        $aaf->setParent($rnaf);
	print STDERR "DEBUG-Parent1:$rnaf, BP\n";
        $aaf->setParent($aa_seq);
	print STDERR "DEBUG-Parent2:$rnaf, BP\n";
    }

    foreach my $att (keys %{$h}) {
        #TWif ($aaf->get($att) ne $h->{$att}) {
            print STDERR "buildTranslatedAAFeature(): $att has changed for DoTS::TranslatedAAFeature ",$rnaf->getName(),": Object == '",$aaf->get($att), "' lastest value == '", $h->{$att},"'\n";
            $aaf->set($att, $h->{$att});
        #TW}
    }

#    $aaf->submit(); ## ##BG    
    print STDERR "CHECK - buildTranslatedAAFeature(): 1 getChild(TranslatedAAFeature) returned" . $aaf . "  ID=" .$aaf->getId() ."  parent_id= " . $aaf->getNaFeatureId()  . "\n";



    ###################
    # ProteinFeature
    ######
    #my $pf = $rnaf->getChild('GUS::Model::DoTS::ProteinFeature', 1);  #TW
    #print STDERR "buildTranslatedAAFeature(): getChild(ProteinFeature) returned '$pf'\n";
    my $name       = $rnaf->getName;
    
    return ($aaf);
}


################################################################################
#
# Build SignalPeptide, Transmembrane domain, link to Pfam objects, and make 
# $aa_seq the parent.
#
# Any "old" features of these type are marked for deletion. It is too hard to
# see which new prediction matches up to an old prediction and probably not
# worth the effort for an EMBL file.
#
# $aa_seq is a TranslatedAASequence, the protein for this CDS
####

sub buildAAFeatures {
    my ($self, $aa_seq, $gene_name) = @_;

    my $debug           = $self->{debug};
    my $bioperl_feature = $self->{bioperlFeature};  

    my @aa_objects = ();

    ###
    # Remove all predicted features & SigP features before we re-create them
    # If its just been created and its not yet in the DB it won't delete anything....
    ###
    #TW-NOTE:do not need to delete 
    if ($aa_seq) {
        print STDERR "buildAAFeatures() : \$aa_seq already exists (ID = ", $aa_seq->getId(),"), deleting certain children\n";

        $aa_seq->retrieveChildrenFromDB('DoTS::DomainFeature');        # Force loading from DB of "old" objects
        $aa_seq->retrieveChildrenFromDB('DoTS::SignalPeptideFeature'); # Force loading from DB of "old" objects
        $aa_seq->retrieveChildrenFromDB('DoTS::PostTranslationalModFeature');

        my @d_features    = $aa_seq->getChildren('DoTS::DomainFeature');
        my @sigp_features = $aa_seq->getChildren('DoTS::SignalPeptideFeature');

        # Remove child locations too
        foreach my $aaf (@d_features, @sigp_features){
            my @aa_locs = $aaf->getChildren('DoTS::AALOCATION', 1);

            $aaf->markChildrenDeleted(@aa_locs);
            $aaf->markDeleted();
        }

        $aa_seq->markChildrenDeleted(@d_features, @sigp_features);

        print STDERR "buildAAFeatures() : \@d_features = ", scalar(@d_features),
            " \@sigp_features = ", scalar(@sigp_features), "\n";

        print STDERR "buildAAFeatures() : deleted ",
            (scalar(@d_features) + scalar(@sigp_features)),
            " children plus any AALocations\n";
    }

    ###
    # Get misc_features of type sigP and TMHMM
    # NOTE: GeneDB now outputs a single qualifier for each TMHMM, SignalP and GPI anchor
    #       and _no_ misc_features, hence this code is now redenudant (yes?).
    ###
    #my @misc_features = $self->getMiscFeatures ($gene_name);
    

    my $misc_feature_tm; # left here so it compiles!
    my $misc_feature_sp;

    #foreach my $misc_feature (@misc_features) {
    #    my @notes = $misc_feature->each_tag_value ('note');

    #    foreach my $note (@notes) {
    #        if ($note =~ /signal peptide/i) {
    #            $misc_feature_sp = $misc_feature;
    #        }
    #        elsif ($note =~ /transmembrane heli/i) {
    #            $misc_feature_tm = $misc_feature;
    #        }
    #    }
    #}

    ###
    # Create SignalPeptide
    ##
    print STDERR "Call method SignalPeptide, BPG\n";
    my @signalP_objects = $self->buildSignalPFeature ($misc_feature_sp, $aa_seq);
    push (@aa_objects, @signalP_objects);

    ###
    # Create Transmembrane domain
    ##
    print STDERR "Call method Transmembrance domain\n";
    my @transmembrane_objects = $self->buildTransmembraneDomainFeature ($misc_feature_tm, $aa_seq);
    push (@aa_objects, @transmembrane_objects);

    ###
    # Create GPI-anchor (DoTS.PostTranslationalModFeature)
    ##
    print STDERR "Call method GPI-anchor\n";
    my @transmembrane_objects = $self->buildGPIAnchorFeature($aa_seq);
    push (@aa_objects, @transmembrane_objects);


    ###
    # Create Domain
    ##
    if ($bioperl_feature->has_tag ('domain')) {
        my @domain_objects = $self->buildDomainFeature ($aa_seq);
        push (@aa_objects, @domain_objects);
    }

    # print STDERR "Dumping aa feature objects: " . Dumper (@aa_objects) . "\n";

    return @aa_objects;
}

################################################################################
# Return an array of Bioperl features that have the words
#   'signal peptide' or 'transmembrane heli'
# and the string $gene_name in the note field.
#
#
# DOES THIS NEED TO BE FASTER? CACHE THE $bioperl_feature TO $gene_name MAPPING
# ON FIRST PASS THEN LOOKUP THE HASH THERE AFTER....
#
#TW-NOTE:based on above comment, protein features have their own qualifier so this may not be needed

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


################################################################################
#
# This gets a $misc_feature but GeneDB adds a signal_peptide qualifier to the
# CDS which is used instead.
#
# $aa_seq is a TranslatedAFeature
#
# Important: No versioning happens for SignalPeptideFeatures.
#            They are predictions after all.
#            No such thing as an "updated" sigP prediction!
#            How would you work out which prediction updates which old prediction?
#         
################################################################################

sub buildSignalPFeature {
    my ($self, $misc_feature, $aa_seq) = @_;

    #TW-NOTE:check that this subroutine is working

    ##
    # Delete previous SigP predictions
    ##
    #my @children = $aa_seq->getChildren('DoTS::SignalPeptideFeature', 1);

    #print STDERR "buildSignalPFeature() : About to delete ", scalar(@children),
    #" SignalPeptideFeature(s) plus their child AALocations\n";

    #foreach my $sigp (@children){
    #    my @aa_locs = $sigp->getChildren('DoTS::AALOCATION', 1);

    #    $sigp->markChildrenDeleted(@aa_locs);
    #    $sigp->markDeleted();
    #}

    ##
    # Loop through each /signal_peptide and create a new one, no updates.
    ##

    my $debug           = $self->{debug};
    my $gus_sequence    = $self->{gusSequence};
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
            my $algorithm_name = "SignalP 2.0 HMM"; # this gets overwritten below. Eh?

            $signal_peptide    =~ /.+by\s([^\(\)]+)\(\D+([^,]+),\D+([^\(\)]+)\).+/;
      
            $algorithm_name        = $1;
            my $signal_probability = $2;
            my $anchor_probability = $3;
            my $is_predicted       = 1;
            my $review_status_id   = $REVIEW_STATUS_ID;
            my $source_id          = $gus_sequence->getSourceId();
      
            # FIXME
            # start and end coordinates ??
            # This was ok for GUSdev boolean queries but not GUS3 implementation

            my $start = 1;
            my $end   = 1;
      
            my $bioperl_location = Bio::Location::Simple->new (
                                                               -start  => $start,
                                                               -end    => $end,
                                                               -strand => 1,
                                                               );
            my $h = {
                'subclass_view'      => $subclass_view,
                #'description'        => $description,
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


################################################################################
#
# Although the $misc_feature is passed in, it is not used. The GeneDB added
# qualifier 'transmembrane_domain' is used instead. For now :)
#

sub buildTransmembraneDomainFeature {
    my ($self, $misc_feature, $aa_seq) = @_;

    my $td_name         = "TMhelix";
    my $debug           = $self->{debug};
    my $gus_sequence    = $self->{gusSequence};
    my $bioperl_feature = $self->{bioperlFeature};

    ##
    # Return if no /transmembrane_domain
    ## 
    my @transmembrane_objects = ();

    if (not $bioperl_feature->has_tag ('transmembrane_domain')) {
        return @transmembrane_objects;
    }

    ##
    # Loop over each /transmembrane_domain and build DomainFeature and AALocation
    ##

    # my @tms = $misc_feature->each_tag_value ('note');
    my @tms = $bioperl_feature->each_tag_value ('transmembrane_domain');

    foreach my $tm (@tms) {
        if ($tm =~ /transmembrane/i) {

            my @bioperl_locations = ();

            #my $subclass_view    = "DomainFeature";
            my $description      = $tm;
            my $algorithm_name   = "TMHMM2.0"; # default
            my $is_predicted     = 1;
            my $review_status_id = $REVIEW_STATUS_ID;
            my $source_id        = $gus_sequence->getSourceId();

            if ($tm =~ /by\s/) {

                $tm              =~ /.+by\s([^at]+).*/;
                $algorithm_name  = $1;

                print STDERR "Algorithm name entry, $algorithm_name\n";
            }

            if ($tm =~ /at aa/) {
                $tm =~ /.+by\s([^at]+)at aa (\d+)\D(\d+)(.*)/;
		
                my $start            = $2;
                my $end              = $3;
                my $other_locations  = $4;
        
                my $bioperl_location = Bio::Location::Simple->new (
                                                                   -start  => $start,
                                                                   -end    => $end,
                                                                   -strand => 1,
                                                                   );
                push (@bioperl_locations, $bioperl_location);
		
                $other_locations =~ s/\sand\s/\, /g;
		
                #if ($debug) {
		# print STDERR "tm: $tm\n";
                    # print STDERR "other locations to parse: $other_locations.\n";
                #}
		
                while (length ($other_locations) > 0) {
                    $other_locations     =~ /,\s(\d+)\D(\d+)(.*)/;
                    $start               = $1;
                    $end                 = $2;
                    $other_locations     = $3;
                    my $bioperl_location = Bio::Location::Simple->new (
                                                                       -start  => $start,
                                                                       -end    => $end,
                                                                       -strand => 1,
                                                                       );
                    push (@bioperl_locations, $bioperl_location);
		    
                    #print STDERR "buildTransmembraneDomainFeature() : ", scalar(@bioperl_locations), " locations for TMHMM\n";
                }
            }
	    
            my $h = {
                'name'               => $td_name,
                #'subclass_view'      => $subclass_view,
                'description'        => $description,
                'algorithm_name'     => $algorithm_name,
                'is_predicted'       => $is_predicted,
                'review_status_id'   => $review_status_id,
                'source_id'          => $source_id,
                'number_of_domains'  => scalar(@bioperl_locations),
            };

            my $gus_transmembraneFeature = GUS::Model::DoTS::DomainFeature->new ($h);
            $gus_transmembraneFeature->setParent($aa_seq); # DESIGN ERROR - 2 parents same object, see processDomainFeatureHack() in GenericParser2Gus

#print STDERR "buildTransmembraneDomainFeature(): domain feature parent ($aa_seq)= ", $gus_transmembraneFeature->getParent($aa_seq->getClassName()), "\n";
#print STDERR "buildTransmembraneDomainFeature(): aa_sequence_id = ", $gus_transmembraneFeature->get('aa_sequence_id'), "\n";

            push (@transmembrane_objects, $gus_transmembraneFeature);

            foreach my $bioperl_location (@bioperl_locations) {
                my $gus_aaLocation = $self->buildAALocation ($gus_transmembraneFeature, $bioperl_location);
                push (@transmembrane_objects, $gus_aaLocation);
            }
        }
    }

    return @transmembrane_objects;
}


################################################################################
#
# build PostTranslationalModFeature for GPI-Anchor
##
sub buildGPIAnchorFeature {
    my ($self, $aa_seq) = @_;

    print STDERR "Processing GPI-Anchor data...\n" if $self->{'debug'};

    if (not $self->{bioperlFeature}->has_tag ('gpi_anchor')) {
        print STDERR "  - no /gpi_anchor qualifier, returning.\n" if $self->{'debug'};
        return ();
    }

    my @gpi_objects     = ();
    my @gpis            = $self->{bioperlFeature}->each_tag_value ('gpi_anchor');

    foreach my $gpi (@gpis) {
        if ($gpi =~ /gpi-anchor/i) {

            if ($self->{'debug'}) {
                print STDERR "Parsing next GPI feature/qualifier...\n" if $self->{'debug'};
            }

            my @bioperl_locations = ();

            # set defaults before getting real values
            my $name              = "GPI-Anchored Signal";
            my $description       = $gpi;
            my $algorithm_name    = "DGPI v2.04";
            my $is_predicted      = 1;
            my $review_status_id  = $REVIEW_STATUS_ID;
            my $source_id         = $self->{'gusSequence'}->getSourceId();
            my $bioperl_location;

            if ($gpi =~ /by\s/) {

                $gpi             =~ /.+by\s([^with]+).*/;
                $algorithm_name  = $1;

                print STDERR "Algorithm name , $algorithm_name\n" if $self->{'debug'};

                # xxx
                # Need to look up algorithm_id - algorithms not loaded yet...
            }

            if ($gpi =~ /near (\d+)$/) {
                my $start = $1;
                my $end   = $start;

                print STDERR "location information: start & end = $start\n" if $self->{'debug'};

                $bioperl_location = Bio::Location::Simple->new (-start  => $start,
                                                                -end    => $end,
                                                                -strand => 1,);
                push (@bioperl_locations, $bioperl_location);
            }
      
            my $h = {
                'name'               => $name,
                'description'        => $description,
                #'prediction_algorithm_id'     => $algorithm_name, # need to lookup algorithm_id, see above
                'review_status_id'   => $review_status_id,
                'is_predicted'       => $is_predicted,
                'source_id'          => $source_id,
            };

            my $gus_gpiFeature = GUS::Model::DoTS::PostTranslationalModFeature->new($h);

            $gus_gpiFeature->setParent ($aa_seq);

            print "567 parent = $aa_seq\n";
            print "567 parent = ", $gus_gpiFeature->getParent($aa_seq->getClassName()), "\n";
            

            push (@gpi_objects, $gus_gpiFeature);

            my $gus_aaLocation = $self->buildAALocation ($gus_gpiFeature, $bioperl_location);
            push (@gpi_objects, $gus_aaLocation);
        }
    }

    return @gpi_objects;
}


################################################################################
#
# Creates records DomainFeature from /domain
# If its a Pfam entry, set the link to the PfamEntry object
#
# GUSdev used to use PredictedAAFeature instead of DomainFeature but it is
# almost identical :)
#
sub buildDomainFeature {
    my ($self, $aa_seq) = @_;

    my $debug           = $self->{debug};
    my $bioperl_feature = $self->{bioperlFeature};
    my $gus_sequence    = $self->{gusSequence};

    my @domain_objects  = ();
    my @domain_values   = $bioperl_feature->each_tag_value ('domain');

    foreach my $domain_value (@domain_values) {
        my @bioperl_locations = ();

        print STDERR "buildDomainFeature() : domain value: $domain_value\n";

        # parsing the domain qualifier...

        # There is a special case where a ';' is included in the domain name.
        # Then this ';' has not to be considered as a separator.
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

            print STDERR "buildDomainFeature() : has a \\\n";
      
            $domain_value    =~ s/\\//;
            $domain_value    =~ /([^:]+):([^;]+);([^;]+;[^;]+);?([^;]*);?(.*)/;

            $db_name         = $1;
            $domain_id       = $2;

            $domain_id       =~ s/\s//g; # get rid of the spaces !!!
            $domain_name     = $3;
            $score_or_evalue = $4;
            $other_locations = $5;
        }
        else {
            ###
            # all ';' are separator
            ###

            $domain_value    =~ /([^:]+):([^;]+);([^;]+);?([^;]*);?(.*)/;

            $db_name         = $1;
            $domain_id       = $2;

            $domain_id       =~ s/\s//g; # get rid of the spaces !!!
            $domain_name     = $3;
            $score_or_evalue = $4;
            $other_locations = $5;
        }

        print STDERR "buildDomainFeature() : db name, domain id, domain name: $db_name, $domain_id, $domain_name\n";

        while (defined $other_locations && length ($other_locations) > 0) {
            $other_locations     =~ /(\d+)\D(\d+),?(.*)/;
            my $start            = $1;
            my $end              = $2;
            my $bioperl_location = Bio::Location::Simple->new (
                                                               -start  => $start,
                                                               -end    => $end,
                                                               -strand => 1,
                                                               );
            push (@bioperl_locations, $bioperl_location);
            $other_locations = $3;
        }

        my $description      = $domain_name;
        my $name             = "$db_name:$domain_id";
        # my $prediction_algo_id = ???????;
        my $is_predicted     = 1;
        my $review_status_id = $REVIEW_STATUS_ID;
        my $source_id        = $gus_sequence->getSourceId();

        print STDERR "buildDomainFeature() : Generating DomainFeature Entry for $db_name domain, $domain_id ($domain_name)...\n";

        my $h = {
            'description'       => $description,
            'name'              => $name,
            'is_predicted'      => $is_predicted,
            'review_status_id'  => $review_status_id,
            'source_id'         => $source_id,
        };

        my $gus_DomainFeature = GUS::Model::DoTS::DomainFeature->new ($h);
        $gus_DomainFeature->setParent ($aa_seq);

        print STDERR "domain feature parent ($aa_seq)= ", $gus_DomainFeature->getParent($aa_seq->getClassName()), "\n";

        ##
        # If Pfam, setPfamEntryId()
        ##
        if ($db_name =~ /pfam/i) {
            print STDERR "buildDomainFeature() : Mapping Pfam domain, $domain_id, to PfamEntry table Id...\n";
            my $dbh       = $gus_DomainFeature->getDatabase()->getDbHandle();
            my $pfamEntry = $self->getPfamEntry ($domain_id, $dbh);

            if (defined $pfamEntry) {
                my $pfam_entry_id = $pfamEntry->getPfamEntryId;

                print STDERR "buildDomainFeature() : Found pfam_entry_id = $pfam_entry_id\n";

                if (defined ($pfam_entry_id)) {
                    $gus_DomainFeature->setPfamEntryId($pfam_entry_id);
                }
            }
            else {
                print STDERR "WARNING: buildDomainFeature() : Pfam accession, $domain_id, can not be found !!!\n";
            }
        }

        push (@domain_objects, $gus_DomainFeature);

        ##
        # Build any location objects
        ##
        foreach my $bioperl_location (@bioperl_locations) {
            my $gus_aaLocation = $self->buildAALocation ($gus_DomainFeature, $bioperl_location);
            push (@domain_objects, $gus_aaLocation);
        }
    }

    return @domain_objects;
}


################################################################################
################################################################################

#                  Build Central Dogma Objects

################################################################################
################################################################################


################################################################################
#
# Returns the Gene object plus all child GeneSynonym objects, including those
# to be deleted, created and no change.
#
# A GeneSynonym is /synonym and /obsolete_name, the latter having is_obsolete = 1
##

#TW-NOTE:this table is not used by PlasmoDB

sub buildGene {
    my ($self, $gf) = @_;
    
    my $debug            = $self->{debug};
    my $bioperl_feature  = $self->{bioperlFeature};

    # FIXME: name or standard_name???????????
    my $gene_name        = $gf->get('name'); #$gf->get ('standard_name');
    my $review_status_id = $REVIEW_STATUS_ID;


    print STDERR "buildGene() : building '$gene_name'\n";

    ##
    # build gene object
    ##

    my $h = {
        'name'              => $gene_name,
        'review_status_id'  => $review_status_id,
    };

    my $gene_object = GUS::Model::DoTS::Gene->new ($h);
    my $is_in       = $gene_object->retrieveFromDB();

    print STDERR "buildGene() : DoTS.Gene \$is_in = $is_in\n";


    
    #TW-NOTE:this table is not used by PlasmoDB
    ##
    # Create DoTS.GeneSynonyms
    ##
    my @gus_gene_synonyms       = $gene_object->getChildren('DoTS::GeneSynonym', 1, undef, {'is_obsolete' => 0});
    my @gus_gene_obsolete_names = $gene_object->getChildren('DoTS::GeneSynonym', 1, undef, {'is_obsolete' => 1});

    ##
    # /obsolete_name
    ##
    my @bioperl_obsolete_names  = ();

    if ($bioperl_feature->has_tag ('obsolete_name')) {
        @bioperl_obsolete_names = $bioperl_feature->each_tag_value ('obsolete_name');
    }

    my @obsolete_objs = $self->createGeneSynonyms(1, $gene_object, \@gus_gene_obsolete_names, \@bioperl_obsolete_names);

    ##
    # /synonym
    ##
    my @bioperl_gene_synonyms  = ();

    if ($bioperl_feature->has_tag ('synonym')) {
        @bioperl_gene_synonyms = $bioperl_feature->each_tag_value ('synonym');

        # Check no dodgy '/synonym="gyra or pard or nala or hisw or b2231"' type qualifiers
        #@bioperl_gene_synonyms = grep !/ or /, @bioperl_gene_synonyms ;
    }

    my @synonym_objs = $self->createGeneSynonyms(0, $gene_object, \@gus_gene_synonyms, \@bioperl_gene_synonyms);

    return ($gene_object, @obsolete_objs, @synonym_objs);
}

################################################################################
#
# Creates/deletes DoTS.GeneSynonym objects.
# No modifications are done as all they hold is a name.
##

#TW-NOTE:this is not needed, table not used by PlasmoDB
sub createGeneSynonyms {
    my ($self, $is_obsolete, $gene_object, $gus_gene_synonyms_ref, $bioperl_gene_synonyms_ref) = @_;

    my @to_be_created_synonyms = ();
    my @to_be_deleted_synonyms = ();
    my @in_both                = (); # holds GUS GeneSynonym objects common to both GUS & Bioperl
    my @gene_synonyms          = (); # The return array of ALL GeneSynonym objects created and marked deleted


    print "createGeneSynonyms(): is_obsolete = $is_obsolete, gene_object = $gene_object\n";
    print "createGeneSynonyms(): bioperl_gene_synonyms_ref = ", join(', ', @{$bioperl_gene_synonyms_ref}), "\n";
    print "createGeneSynonyms(): gus_gene_synonyms_ref     = ", join(', ', @{$gus_gene_synonyms_ref}), "\n";

    ##
    # What needs to be created?
    ##
    foreach my $bioperl_synonym (@{$bioperl_gene_synonyms_ref}) {    
        my $not_found = 1;

        foreach my $gus_synonym (@{$gus_gene_synonyms_ref}) {
            if ($gus_synonym->getSynonymName() eq $bioperl_synonym) {
                $not_found = 0;
            }
        }

        if ($not_found) {
            push(@to_be_created_synonyms, $bioperl_synonym);
        }
    }

    ##
    # What needs to be deleted?
    ##
    foreach my $gus_synonym (@{$gus_gene_synonyms_ref}) {    
        my $not_found = 1;

        foreach my $bioperl_synonym (@{$bioperl_gene_synonyms_ref}) {
            if ($bioperl_synonym eq $gus_synonym->getSynonymName()) {
                $not_found = 0;
            }
        }

        if ($not_found) {
            push (@to_be_deleted_synonyms, $gus_synonym);
        }
        else {
            push(@in_both, $gus_synonym); # Need to return objects with no change
        }
    }

    ##
    # Create
    ##
    foreach my $bioperl_synonym (@to_be_created_synonyms) {
        my $review_status_id = $REVIEW_STATUS_ID;      
 
        my $h = {
            'synonym_name'     => $bioperl_synonym,
            'review_status_id' => $review_status_id,
            'is_obsolete'      => $is_obsolete,
        };

        my $geneSynonym = GUS::Model::DoTS::GeneSynonym->new ($h);
        $geneSynonym->setParent ($gene_object);

        push (@gene_synonyms, $geneSynonym);

        print STDERR "createGeneSynonyms() : created '$bioperl_synonym', is_obsolete = $is_obsolete\n";
    }

    ##
    # Delete
    ##
    foreach my $gus_synonym (@to_be_deleted_synonyms) {
        $gus_synonym->markDeleted();
        push (@gene_synonyms, $gus_synonym);

        print STDERR "buildGene() : deleted '", $gus_synonym->getSynonymName(),"'\n";
    }

    ##
    # DEBUG OUTPUT
    ##
#    if (@in_both) {
#        print STDERR "buildGene() : unchanged ";
#
#        foreach my $geneSymObj (@in_both) {
#            print STDERR $geneSymObj->getSynonymName(), ", ";
#        }
#
#        print STDERR "\n";
#    }


    print STDERR "createGeneSynonyms() : returning: $gene_object, CHANGED", join(', ', @gene_synonyms),", UNCHANGED: ", join(', ', @in_both), "\n";


    return (@gene_synonyms, @in_both);
}


#############################################################################
# Creates the linking table between Central Dogma and Feature Land i.e.
#
#   Gene  <---  GeneInstance  --->  GeneFeature
#
# Explanation of the GeneInstanceCategory, as of 4 Dec 2003;
#
# A gene can be predictied by 3 seperte programs (glimmer, GeneFinder, Phat).
# Each one will get a GeneInstanceCategory of predicited linking 
# it to the single gene.
# 
# A software package can "auto select" one prediction to be The One. 
# Its catergory is changed to "auto select". At this point the "mirror" 
# GeneFeature will be created which is a clone of the auto selected one.
# 
# A curator can review the predictions and choose the right one. They set the
# category of the prediction to "manually selected" and create a 
# new GeneFeature that is a clone of the prediction BUT its boundries 
# maybe modified etc.
###############################


#TW-NOTE:NOT USED BY PLASMODB
sub buildGeneInstance {
    my ($self, $gene_object, $gf) = @_;

    my $review_status_id     = $gene_object->get('review_status_id');

    my $geneInstanceCategory = GUS::Model::DoTS::GeneInstanceCategory->new({'name' => 'manually selected'});
    my $exists               = $geneInstanceCategory->retrieveFromDB();

    unless ($exists) {
        die "ERROR: Could not get DoTS::GeneInstanceCategory by name";
    }

    #my $geneInstance = GUS::Model::DoTS::GeneInstance->new({'review_status_id'  => $review_status_id,
    #                                                        'is_reference'      => 1,
    #                                                    });
    #$geneInstance->setParent($gene_object);
    #$geneInstance->setParent($gf);
    #$geneInstance->setParent($geneInstanceCategory);


    ##
    # If a Gene object has an ID, its in the DB, hence a GeneInstance is probably there too.
    ##
    my $is_in        = 0;
    my $geneInstance = undef;

    if ($gene_object->getId()) {

        $geneInstance = GUS::Model::DoTS::GeneInstance->new({'review_status_id'  => $review_status_id,
                                                             'is_reference'      => 1,
                                                             'gene_id'           => $gene_object->getId(),
                                                             'na_feature_id'     => $gf->getId(),
                                                         });
        $is_in = $geneInstance->retrieveFromDB();

        print STDERR "buildGeneInstance() : \$is_in = $is_in\n";
    }

    if ($is_in) {
        # Only difference that could be is the GeneInstanceCategory which is unlikely
        # to change in the near future at the PSU
        if ($geneInstance->getGeneInstanceCategoryId() ne $geneInstanceCategory->getId()) {
            print STDERR "buildGeneInstance() : setting parent to \$geneInstanceCategory\n";
            $geneInstance->setParent($geneInstanceCategory);
        }
    }
    else {
        $geneInstance = GUS::Model::DoTS::GeneInstance->new({'review_status_id'  => $review_status_id,
                                                             'is_reference'      => 1,
                                                         });

        $geneInstance->setParent($geneInstanceCategory);
        $geneInstance->setParent($gene_object);
        $geneInstance->setParent($gf);
    }

    return $geneInstance;
}

############################################################################
#
####

#TW-NOTE:NOT USED BY PLASMODB
sub buildRNA {
    my ($self, $gene_object) = @_;

    #my $gene_id              = $gene_object->getId;
    #my $review_status_id     = $gene_object->get ('review_status_id');
    #my $is_reference         = $gene_object->get ('is_reference');

    my $rna_object = undef;

    if ($gene_object) {
        $rna_object = $gene_object->getChild('DoTS::RNA', 1);
    }


    unless ($rna_object) {
        my $h = {
            'review_status_id' => $gene_object->getReviewStatusId(),
            #'is_reference'     => $is_reference,
        };

        $rna_object = GUS::Model::DoTS::RNA->new ($h);
        $rna_object->setParent($gene_object);
        
        # Transcript Unit is the parent not gene !!
        # different with GUS3 in which Transcript unit is no longer available

        print STDERR "buildRNA() : DoTS.RNA created.\n";
    }
    else {
        print STDERR "buildRNA() : DoTS.RNA retrieved via Gene->getChild()\n";
    }

    return $rna_object;
}

#############################################################################
# Creates the linking table between Central Dogma and Feature Land i.e.
#
#   RNA  <---  RNAInstance  --->  RNAFeature
#
# As of 4 Dec 2003, only "assembly" (from EST) and "predicted" (RNA from CDS)
# are the RNAInstanceCategorys
#####################################

#TW-NOTE:NOT USED BY PLASMODB
sub buildRNAInstance {
    my ($self, $rna_object, $rnaf, $rna_type) = @_;

    #print STDERR "buildRNAInstance() : $rna_object, $rnaf, $rna_type\n";

    my $review_status_id = $rna_object->get ('review_status_id');

    my $rnaInstanceCategory = GUS::Model::DoTS::RNAInstanceCategory->new({'name' => 'predicted'});
    my $exists              = $rnaInstanceCategory->retrieveFromDB();

    unless ($exists) {
        die "ERROR: Could not get DoTS::RNAInstanceCategory by name";
    }

    print STDERR "buildRNAInstance() : \$rna_object->getId() = ", $rna_object->getId(), "\n";

    my $rnaInstance = undef;

    ##
    # If the RNA object already exists it will have an ID and probably a linking RNAInstance
    ##
    if ($rna_object->getId() > 0) {
        print STDERR "buildRNAInstance() : Attempting to get existing RNAInstance object\n";

        $rnaInstance = GUS::Model::DoTS::RNAInstance->new({'review_status_id'  => $review_status_id,
                                                           'is_reference'      => 1,
                                                           'rna_id'            => $rna_object->getId(),
                                                           'na_feature_id'     => $rnaf->getId(),
                                                       });
        my $is_in = $rnaInstance->retrieveFromDB();

        print STDERR "buildRNAInstance() : \$is_in = $is_in\n";

        if ($is_in) {
            # Only difference that could be is the GeneInstanceCategory which is unlikely
            # to change in the near future at the PSU

            if ($rnaInstance->getRnaInstanceCategoryId() ne $rnaInstanceCategory->getId()) {
                print STDERR "buildRNAInstance() : setting parent to \$rnaInstanceCategory\n";
                $rnaInstance->setParent($rnaInstanceCategory);
            }
        }
        else {
            $rnaInstance->setParent($rnaInstanceCategory);
        }
    }
    else {
        print STDERR "buildRNAInstance() : Creating brand new RNAInstance\n";

        $rnaInstance = GUS::Model::DoTS::RNAInstance->new({'review_status_id'  => $review_status_id,
                                                           'is_reference'      => 1,
                                                       });
        $rnaInstance->setParent($rna_object);
        $rnaInstance->setParent($rnaf);
        $rnaInstance->setParent($rnaInstanceCategory);
        
    }

    return $rnaInstance;
}

############################################################################
#
# /product is used (wrongly) to store descriptions.
# This will change shortly (13/02/04);
####

#TW-NOTE:NOT USED BY PLASMODB
sub buildProtein {
    my ($self, $rna_object, $aa_seq, $gf) = @_;

    #my $protein_name        = $gf->getProduct();
    my $protein_name        = $gf->getName();
    #my $protein_description = $aa_seq->getDescription();  #TW TEMP COMMENT OUT ONLY!
    my $review_status_id    = $rna_object->get('review_status_id');
    #my $is_reference        = $rna_object->get ('is_reference');

    my $h = {
        'review_status_id' => $review_status_id,
        #'description'      => $protein_description, #TW TEMP COMMENT OUT ONLY!
        'name'             => $gf->getName(),
        #'is_reference'     => $is_reference,
    };

    ##
    # Get RNAs child Protein, if it exists, and update it
    ##

    my @protein_objects = $rna_object->getChildren('DoTS::Protein', 1);
    my $protein_object  = $protein_objects[0];


    if ($protein_object) {
        # Update existing Protein
        #
        foreach my $att (keys %{$h}) {
            if ($protein_object->get($att) ne $h->{$att}) {
                print STDERR "buildProtein(): $att has changed: Object == '",
                    $protein_object->get($att), "' lastest value == '", $h->{$att},"'\n";
                $protein_object->set($att, $h->{$att});
            }
        }

        #if ($protein_object->getName() ne $gf->getProduct()) {
        #    $protein_object->setName($gf->getProduct());
        #}
    }
    else {
        # Create new protein object
        #
        $protein_object = GUS::Model::DoTS::Protein->new ($h);
        $protein_object->setParent ($rna_object);

        # if $protein_name length > 100, means it is a description more than a product name !!,
        # so don't assign a name to this entry !!
        # e.g pombe product qualifier => description product

        if (length ($protein_name) < 100) {
            $protein_object->setName ($protein_name);
        }
    }
    return $protein_object;
}

################################################################################
#
# THIS METHOD IS NOT USED!!!
#
# NAFeatureImp is the parent of ProteinFeature, hence it can not be the parent
# of ProteinInstance.
#
# ******************************************************************************
#
##
#
# Creates the linking table between Central Dogma and Feature Land i.e.
#
#   Protein  <---  ProteinInstance  --->  ProteinFeature
#
# As of 4 Dec 2003 only one ProteinInstanceCategory. Will more ever be required?
#

#sub buildProteinInstance {
#    my ($self, $protein_object, $aa_feature_protein) = @_;
#
#    my $review_status_id = $protein_object->get ('review_status_id');
#
#    my $proteinInstanceCategory = GUS::Model::DoTS::ProteinInstanceCategory->new({'name' => 'mirror'});
#    my $exists                  = $proteinInstanceCategory->retrieveFromDB();
#
#    unless ($exists) {
#        die "ERROR: Could not get DoTS::ProteinInstanceCategory by name";
#    }
#
#    my $h = {
#        'review_status_id'  => $review_status_id,
#        'is_reference'      => 1,
#    };
#
    ##
    # If the $protein_object exists it should have an existing ProteinInstance object to update
    ##

#    my @protein_instances = $protein_object->getChildren('DoTS::ProteinInstance', 1);
#    my $protein_instance  = $protein_instances[0];
#
#    print STDERR "buildProteinInstance() : \$protein_instance = $protein_instance\n";
#
#    unless ($protein_instance) {
#        $protein_instance = GUS::Model::DoTS::ProteinInstance->new($h);
#          print STDERR "buildProteinInstance() : seeting \$protein_object\n";
#        $protein_instance->setParent($protein_object);
#          print STDERR "buildProteinInstance() : seeting \$aa_feature_protein\n";
#        $protein_instance->setParent($aa_feature_protein); # <---- This fails, no protein feature as a parent
#         print STDERR "buildProteinInstance() : seeting \$proteinInstanceCategory\n";
#        $protein_instance->setParent($proteinInstanceCategory);
#    }
#
#
#    return $protein_instance;
#}


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

        unless (defined $sth) {
            confess("ERROR: getReleaseIds() \$sth is undefined, is plugin connected to the DB? \$dbh = $dbh");
        }

        my %edrId = ();

        foreach my $aspect ('GO Process', 'GO Component', 'GO Function'){
	#TWforeach my $aspect ('GO_process', 'GO_component', 'GO_function'){
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
# It will die if schema.table not in Core.TableInfo
##

sub getTableId {
    my ($self, $dbh, $schema, $table) = @_;

    unless ( defined $self->{'cache'}->{$schema}->{$table}) {

        my $sth_t_id =
            $dbh->prepare("SELECT ti.table_id FROM Core.TableInfo ti, Core.DatabaseInfo di ".
                          "WHERE  di.name        = ? ".
                          "AND    ti.name        = ? ".
                          "AND    ti.database_id = di.database_id");
        $sth_t_id->execute($schema, $table);

        my $ref = $sth_t_id->fetchall_arrayref();

        if (scalar(@{$ref}) == 0) {
            die "ERROR: ${schema}.${table} was not found in Core.TableInfo!!!";
        }
        else {
            $self->{'cache'}->{$schema}->{$table} = $ref->[0]->[0];
        }
    }
    return $self->{'cache'}->{$schema}->{$table};
}

################################################################################
# return contact_id from SRes.Contact. It uses a cache.
# Attribution_site should map to SRes.Contact.name
#
# It will die if $attribution_site is not in SRes.Contact
##

sub getContactId {
    my ($self, $dbh, $attribution_site) = @_;

    print "getContactId(): called :)\n";

    # Sanger EMBL files do not have /attribution_site in them, hence we default to Sanger here;
    # Sanger files now have /attribution_site qualifier
   #unless (defined $attribution_site) {
        $attribution_site = 'The Sanger Centre';  #name in CBIL SRes.Contact
    #}

    print "getContactId(): attribution_site = $attribution_site\n";

    unless ( defined $self->{'cache'}->{'contact'}->{$attribution_site}) {

        my $sth_c_id =
            $dbh->prepare("SELECT c.contact_id ".
                          "FROM   SRes.Contact c ".
                          "WHERE  LOWER (name) = LOWER (?)");
        $sth_c_id->execute($attribution_site);

        my $ref = $sth_c_id->fetchall_arrayref();

        print Data::Dumper::Dumper($ref);

        if (scalar(@{$ref}) == 0) {
            die "Could not get SRes.Contact.contact_id for /attribution_site quual to '$attribution_site' - do you need to add a new contact?";
        }
        else {
            $self->{'cache'}->{'contact'}->{$attribution_site} = $ref->[0]->[0];
        }
    }

    print "getContactId(): returning ", $self->{'cache'}->{'contact'}->{$attribution_site}, " for $attribution_site\n";

    return $self->{'cache'}->{'contact'}->{$attribution_site};
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
# evidence  : GOAssociationInstance->GOAssociationInstEvidCode->GOEvidenceCode
#             That last table is a dictionary of terms (ISS, IEA etc).
#
# db_xref   : GOAssociationInstance->Evidence->ExternalDatabaseEntry
#             Evidence could link to anything in the DB in theory i.e.
#             NOTE: and Interpro:0 is a Interpro to GO mapping and will have
#             a fake record.
#             NOTE(TW):This linking is NOT used by PlasmoDB
#
# with/from : Almost the same as db_xref BUT linked against
#             GOAssociationInstEvidCode 'cos only some some GO codes will need
#             them
#
# date      : Use the modification date in GOAssociationInstance table
#
###

sub buildGOAssociations {
    my ($self, $dbh, $taas_object) = @_;

    my $debug           = $self->{debug};
    my $bioperl_feature = $self->{bioperlFeature};

    my @gus_go_objects  = (); # Hold the GUS objects we create, ued as the return value
    my @go_qualifiers   = (); # Each /GO="x y z"

    if ($bioperl_feature->has_tag ('GO')) {
        @go_qualifiers = $bioperl_feature->each_tag_value ('GO');
    }
    else {
        return ();
    }

    #TW-need to check that ids are correct
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
                #defined($hash{'GOid'})   &&  #TW-use capital I instead of i
                defined($hash{'GOId'})   &&
		defined($hash{'evidence'}) &&
                #defined($hash{'dbref'}) ){ #TW
		defined($hash{'db_xref'}) ){
            print STDERR "WARNING: Ignoring incomplete or invalid GO field: '$go_qual'\n";
            next;
        }

        if ($hash{'evidence'} =~ /\?/ || $hash{'GOId'} =~ /\?/) {
            print STDERR "WARNING: Ignoring invalid GO field: '$go_qual' - wildcards present\n";
            next;
        }

        my ($go_id) = ($hash{'GOId'} =~ /GO:(\d+)/);

        push @go_aspect_objects,
             $self->createGoObjects($dbh, $hash{'aspect'}, $go_id, $hash{'evidence'}, $hash{'db_xref'},
                                    $hash{'with'}, $hash{'date'}, $taas_object);
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
    my ($self, $dbh, $GO_aspect, $taas_object) = @_;
    my $debug           = $self->{debug};
    my $bioperl_feature = $self->{bioperlFeature};

    print STDERR "METHOD-GO:buildGO_aspectAssociation()\n";
    return unless $bioperl_feature->has_tag($GO_aspect);
    print STDERR "Found a GO tag\n";

    my %edrId             = (); # ExternalDatabaseReleaseIds for process, component and function
    my $edrId4Aspect      = undef;
    my @go_aspect_objects = ();
    my @go_aspect         = ();

    my ($go_aspect) = ($GO_aspect =~ /^GO_(.+)$/); # Store 'process', not 'GO_process'
    print STDERR "GO_ASPECT:$go_aspect\n";

    @go_aspect    = $bioperl_feature->each_tag_value ($GO_aspect);
    %edrId        = %{$self->getReleaseIds($dbh)};  
#TW-check that proper ext_db_rel_id are used    
    #%edrId         = 
#	(function  => 7798, 
#	 component => 7799,
#	 process   => 7800,
#	 );  #TW-this is hardcoded in other plugin, re-use for ease of coding
    
    $edrId4Aspect = $edrId{$go_aspect};

    my $table_id_4_protein = $self->getTableId($dbh, 'DoTS', 'TranslatedAASequence');
    my %already_created    = ();

    print STDERR "-== GO ==-\n";

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

	print STDERR "\nDEBUG:DB_XREF:$db_xref\n";

        unless (defined $already_created{$go_id}) {
            $already_created{$go_id}++;

	    #TW-need to clean-up this section
            print STDERR "$go_qual -=- \$go_id = $go_id, \$evi_code = $evi_code, \$db_xref = $db_xref\n";

            if ($evi_code =~ /\?/ ||$evi_code =~ /\*/  || $evi_code =~ /\*/ || $go_id =~ /\?/ || $go_id !~ /\d+/) {
                print STDERR "WARNING: Ignoring invalid GO field: '$go_qual' - wildcards present/invalid go ID\n";
                    next;
            }

            push @go_aspect_objects,
               $self->createGoObjects($dbh, $go_aspect, $go_id, $evi_code, $db_xref, $with, $date, $taas_object);
        }
        else {
            # FIXME: One GO ID can have multiple evidence codes
            #        i.e. something could be annotated to a GO ID both by IDA and IPI
            print STDERR "\n\n",'*'x80,"\n";
            print STDERR "WARNING: GO:", $go_id, " already exists for this feature!!!\n";
            print STDERR "         DOES IT HAVE A DIFFERENT EVIDENCE CODE? THIS IS NOT YET HANDLED BY THIS PARSER\n";
            print STDERR "",'*'x80,"\n\n";
        }
    }


    #print "\@go_aspect_objects = '", Dumper(\@go_aspect_objects), "'\n";

    return @go_aspect_objects;
}

################################################################################
#
# This is sub is shared by buildGO_aspectAssociation() and buildGOAssociations()
#
################################################################################

sub createGoObjects {
    my ($self, $dbh, $go_aspect, $go_id, $evi_code, $db_xref, $with, $date, $taas_object) = @_; 
    print STDERR "\n";
    
    if ($self->{'debug'}) {
        print STDERR "createGoObjects() called with these values;\n",
                     "   \$go_aspect      = $go_aspect, \$go_id = $go_id, \$evi_code = $evi_code\n",
                     "   \$db_xref        = $db_xref,   \$with  = $with,  \$date     = $date,\n",
                     "   \$taas_object = $taas_object\n";
    }

    #my %edrId              = %{$self->getReleaseIds($dbh)};
    #TW-hardcode hash of ids, same as used by other plugin
    my %edrId  =   
	(F => 9456,
	 C => 9454,
	 P => 9455,
	 );
    my $edrId4Aspect       = $edrId{$go_aspect};
    print STDERR "EDR:$edrId4Aspect\n";
    my $table_id_4_taas = $self->getTableId($dbh, 'DoTS', 'TranslatedAASequence');
    print STDERR "TID:$table_id_4_taas\n";

    my $go_term_obj = GUS::Model::SRes::GOTerm->new ({"go_id", "GO:".$go_id,
                                                      'external_database_release_id', $edrId4Aspect });
    my $exists      = $go_term_obj->retrieveFromDB ();
    my $go_ass;

    unless ($exists) {
        print STDERR "\n*** WARNING: 'GO:$go_id' not found in database ***\n\n";
    }
    else {
        if ($self->{'debug'}) {
            print STDERR "createGoObjects(): \$table_id_4_taas = $table_id_4_taas, \$taas_object->getId() = ",$taas_object->getId(),"\n";
        }

        #print SDTERR "\n$GO_aspect Term id : $go_id existed, about to create a GOAssociation object\n";
        $go_ass = GUS::Model::DoTS::GOAssociation->new({'go_term_id'       => $go_term_obj->getGoTermId(),
                                                        'review_status_id' => $REVIEW_STATUS_ID,
                                                        'table_id'         => $table_id_4_taas,
                                                        'row_id'           => $taas_object->getId(),
                                                        'is_deprecated'    => 0,
                                                        'is_not'           => 0,
                                                        'defining'         => 0,
                                                    });
	print STDERR "Created a new GOAssociation Object:$go_ass\n";
	

# URGENT FIXME FIXME
# The way it is currently written the GO stuff is not versioned.
#TW-what needs to be versioned???

        # May already be in DB
        my $go_ass_exists = $go_ass->retrieveFromDB();

        if ($go_ass_exists) {
            #print STDERR "  WARNING: GO:$go_id already exists - ".
            #    "CHECK THE EMBL FILE FOR MULTIPLE GO:$go_id FOR THIS FEATURE";
            print STDERR "\nWARNING: createGoObjects() will not version GO:",$go_id, " for ", $self->{bioperlFeature}->each_tag_value ('systematic_id'),"\n";
            print STDERR "         FIXME!\n\n";
        }
        else {
            $go_ass->submit();
            print STDERR "*** GOAssociation created *** \n\n" if $self->{'debug'};
	    
            #TW-my $go_ass_inst_loe = $self->createGOAssociationInstanceLOE('in-house curation', '');
	    my $go_ass_inst_loe = $self->createGOAssociationInstanceLOE('Curator', '');  #TW 
	    #TW-matches a name in CBIL version of this table
            print STDERR "*** createGOAssociationInstanceLOE ran, returned '$go_ass_inst_loe' ***\n\n"
                if $self->{'debug'};

            my $go_ass_inst = $self->createGOAssociationInstance($dbh, $go_ass, $go_ass_inst_loe, $db_xref, $date);
            print STDERR "*** createGOAssociationInstance ran *** \n\n" if $self->{'debug'};

            if ($go_ass_inst) {
                $self->createGOAssocInstEvidCode($dbh, $go_ass_inst, $evi_code, $with); # need XML of CBIL GOEvidenceCode
                print STDERR "*** createGOAssocInstEvidCode ran ***\n\n" if $self->{'debug'};
            }
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
    
    print STDERR "In createGOAssociationInstanceLOE()\n";
    my $go_ass_inst_loe =
      GUS::Model::DoTS::GOAssociationInstanceLOE->new({'name'        => $name,
                                                       'description' => $desc,
                                                   });
    my $exists = 0;#$go_ass_inst_loe->retrieveFromDB(); # TEST
    #print STDERR "EXISTS:$exists\n";
    $go_ass_inst_loe->submit() unless $exists;
    print STDERR "GAILOE:$go_ass_inst_loe\n";
    
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

    print STDERR "In createGOAssociationInstance()\n";

    #!!!!!!!!!!
    # NOTE: external_database_release_id is nullable in this table
    #!!!!!!!!!!
    
    #####
    # ExternalDatabaseReleaseId may not exist...
    #####
    #print STDERR "DB_XREF:$db_xref\n";
    my ($db_xref_name, $db_xef_id) = ($db_xref =~ /(.+):(.+)/);
    #print STDERR "AFTER PATTERN MATCH - DB_XREF_NAME:$db_xref_name\tDB_XEF_ID:$db_xef_id\n";

    #TW-START-------------------------
    #my ($edri)                     = $self->getExternalDatabaseReleaseId($dbh, $db_xref_name);
    #print STDERR "Method called createGOAssociationInstance()\$edri = $edri\n";

    #unless ($edri) {
    #    print STDERR "\nWARNING: Could not get an ExternalDatabaseReleaseId for $db_xref_name ($db_xref)\n";
    #    print STDERR "         ", $self->{bioperlFeature}->primary_tag, " [", $self->{bioperlFeature}->start, "..", $self->{bioperlFeature}->end, " \n";
    #    print STDERR "         \$db_xref = $db_xref, \$date = $date\n";
    #    return undef;
    #}
    
    #print STDERR "createGOAssociationInstance(): Everything ok?\n";
    #TW-END---------------------

    ##
    # Get external_database_release_id for $db_xref (i.e. SPTR:123)
    ##
    my $go_ass_inst =
      GUS::Model::DoTS::GOAssociationInstance->new({'go_association_id'    => $go_ass->getId(),
                                                    'go_assoc_inst_loe_id' => $go_ass_inst_loe->getId(),
                                                    'is_deprecated'        => 0,
                                                    'is_primary'           => 0,
                                                    'review_status_id'     => $REVIEW_STATUS_ID,

                                                    #'external_database_release_id' => , # Not used?  #TW-use to debug
                                                    #'source_id'                    => , #TW-use for debug
                                                });
    $go_ass_inst->submit();
    print STDERR "Created a new GOAssociationInstance object:$go_ass_inst\n";
    

    #!!!!!!!!!!!!!
    #TW-this table has never neen used by PlasmoDB, therefore do not use now
    #!!!!!!!!!!!!!
    
    #TW-START--------------------------
    ##
    # Create  SRes.ExternalDatabaseEntry  for the fact/db_xref
    # Using the above fetched ExternalDatabaseRelease id
    ##
    #print STDERR "--build SRes.ExternalDatabaseEntry object\n";
    #my $ede = GUS::Model::SRes::ExternalDatabaseEntry->new({'external_database_release_id' => $edri,
    #                                                        'external_primary_identifier'  => $db_xef_id,
    #                                                        'name'                         => $db_xref,
    #                                                        'review_status_id'             => $REVIEW_STATUS_ID,
    #                                                    });
    #my $exists = 0; # $ede->retrieveFromDB(); # TEST
    #$ede->submit() unless ($exists);
    #print STDERR "--submitted SRes.ExternalDatabaseEntry object\n";
    #TW-END------------------------


    #TW-START----------------------------
    #This table is not populated by PlasmoDB
    #######
    # Now GOAssociationInstance can be 'joined' together with ExternalDatabaseEntry with Evidence
    ######
    #print STDERR "--build DoTS::Evidence object\n";
    #my $table_id_4_gai = $self->getTableId($dbh, 'DoTS', 'GOAssociationInstance');
    #my $table_id_4_ede = $self->getTableId($dbh, 'SRes', 'ExternalDatabaseEntry');

    #my $evidence = GUS::Model::DoTS::Evidence->new({'target_table_id' => $table_id_4_gai,
    #                                                'target_id'       => $go_ass_inst->getId(),
    #                                                'fact_table_id'   => $table_id_4_ede,
    #                                                'fact_id'         => $ede->getId(),
    #                                                'evidence_group_id' => 1, # 1 supports association
    #                                            });
    #$exists = 0; # $evidence->retrieveFromDB(); TEST
    #$evidence->submit() unless $exists;
    #print STDERR "--submitted oTS::Evidence object\n";

    return $go_ass_inst;
    #TW-END-----------------------------------
}

################################################################################
#
# Returns ExternalDatabaseReleaseId. It uses a cache.
# This method should be merged with getReleaseIds() which is similar
#
# On error it returns undef (i.e. the $db_name does not exist).
#
################################################################################

sub getExternalDatabaseReleaseId {
    my ($self, $dbh, $db_name) = @_;

    unless (defined $self->{'cache'}->{'db_name'}->{$db_name}) {

        # WHY DOES THIS NOT USE THE PERL OBJECT LAYER???????????????

        my $sth = $dbh->prepare(
qq[SELECT external_database_release_id, release_date, version
FROM   SRes.ExternalDatabaseRelease  edr, SRes.ExternalDatabase ed
WHERE  ed.lowercase_name = ?
AND    ed.external_database_id = edr.external_database_id
ORDER BY release_date, external_database_release_id]);

        $sth->execute(lc($db_name));
        my $fetch_all     = $sth->fetchall_arrayref();

        if( scalar(@{$fetch_all}) <= 0 ){
            print STDERR "WARNING: No ExternalDatabase called '$db_name' ***\n";
            return undef;
        }
        else {
            my $last_index    = @{$fetch_all} - 1;
            my $edri          = $fetch_all->[$last_index]->[0]; # edri = ExternalDatabaseReleaseId

            $self->{'cache'}->{'db_name'}->{$db_name} = $edri;
        }
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
#
# Does nothing and returns undef if no $with value
#
################################################################################

sub createGOAssocInstEvidCode {
    my ($self, $dbh, $go_ass_inst, $evi_code, $with) = @_;

    # Exit point below for same thing!
    # How else can ISS, IEA etc be stored???
    #unless ($with) {
    #    return undef;
    #}


    my $go_evidence_code = GUS::Model::SRes::GOEvidenceCode->new({'name' => $evi_code});
    my $exists           = $go_evidence_code->retrieveFromDB();

    unless ($exists) {
        die "ERROR: could not get evidence code '$evi_code' from table GOEvidenceCode.";
    }

    print STDERR "createGOAssocInstEvidCode(): \$evi_code = '$evi_code', \$exists = $exists\n";
    print STDERR "GO_EV_CODE:$go_evidence_code, GO_ASSOC_INST_ID:$go_ass_inst\n";

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

    unless ($edri) {
        print STDERR "\nWARNING: Could not get a ExternalDatabaseReleaseId for $db_name\n";
        print STDERR "         ",$self->{bioperlFeature},"\n";
        print STDERR "         \$go_ass_inst = $go_ass_inst, \$evi_code = $evi_code, \$with = $with\n";

        return undef;
    }

    my $ede = GUS::Model::SRes::ExternalDatabaseEntry->new({'external_database_release_id' => $edri,
                                                            'external_primary_identifier'  => $db_id,
                                                            'name'                         => $with,
                                                            'review_status_id'             => $REVIEW_STATUS_ID,
                                                        });
    my $exists = 0; #$ede->retrieveFromDB(); # TEST
    $ede->submit() unless ($exists);

    my $table_id_4_gaiec = $self->getTableId($dbh, 'DoTS', 'GOAssocInstEvidCode');
    my $table_id_4_ede   = $self->getTableId($dbh, 'SRes', 'ExternalDatabaseEntry');

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


################################################################################
# Creates a new NALocation from the bioperl $range and sets $feature_obj to be
# its parent.
####

sub buildNALocation {
    my ($self, $feature_obj, $range, $loc_order) = @_;
  
    my $debug         = $self->{debug};
    my $location_type = ref ($range);

    # Bioperl Location types
    #
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
        'is_reversed'   => $is_reversed,
        'location_type' => $range->location_type,
        'start_min'     => $start_min,
        'start_max'     => $start_max,
        'end_min'       => $end_min,
        'end_max'       => $end_max,
        'loc_order'     => $loc_order,
    };

    my $naLocation = GUS::Model::DoTS::NALocation->new ($h);
    $naLocation->setParent($feature_obj);

    return $naLocation;
}

################################################################################
#
# Link $object -> DoTS.Attribution -> SRes.Contact
#
# Currently only a DoTS.GeneFeature is understood, but trivial to add others
# The Bioperl feature must have an /attribution_site, no action is taken otherwise.
#
# Returns: number of objects sunmitted - 0 or 1.
##
sub buildAndSubmitAttribution {
    my ($self, $object) = @_;

    my $object_id  = -1;
    my $table_id   = -1;
    my $dbh        = $object->getDatabase()->getDbHandle();
    my $contact_id = undef;

    if ($self->{'bioperlFeature'}->has_tag ('attribution_site')) {
        my @attribution_sites = $self->{bioperlFeature}->each_tag_value ('attribution_site');
        my $attribution_site  = $attribution_sites[0];
        $contact_id           = $self->getContactId($dbh, $attribution_site);
    }
    else {
        return 0;
    }

    ##
    # DoTS.GeneFeature
    ##
    if (ref($object) eq 'GUS::Model::DoTS::GeneFeature') {
        $object_id = $object->getNaFeatureId();
        $table_id  = $self->getTableId($dbh, 'DoTS', 'GeneFeature');
    }

    print "buildAndSubmitAttribution(): \$object_id = $object_id, \$table_id = $table_id, \$contact_id = $contact_id (object is type ",ref($object),") \n";

    if ($object_id != -1 && $table_id != -1) {
        my $att_obj = GUS::Model::DoTS::Attribution->new({'table_id'   => $table_id,
                                                          'row_id'     => $object_id,
                                                          'contact_id' => $contact_id
                                                          });
        $att_obj->submit(1);
        return 1;
    }

    return 0;
}

################################################################################
#
# Create a DoTS::AALocation object and set the parent to be $feature_obj
# No updating done here: which location gets updated if 2+ locations ???
# Can't be done... Can it?
#
sub buildAALocation {
    my ($self, $feature_obj, $range) = @_;

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

####################################################################
# THIS IS THE OLD VERSION THAT TRIED TO VERSION THE AALocation
#
#sub buildAALocation {
#    my ($self, $feature_obj, $range) = @_;
#
#    my $debug = $self->{debug};
#
#    my $start = $range->start;
#    my $end   = $range->end;
#
#    my $h = {
#        'start_min' => $start,
#        'start_max' => $start,
#        'end_min'   => $end,
#        'end_max'   => $end,
#    };
#
#    my $aaLocation = $feature_obj->getChild('DoTS::AALocation', 1);
#
#    unless ($aaLocation) {
#        $aaLocation = GUS::Model::DoTS::AALocation->new ($h);
#        $aaLocation->setParent($feature_obj);
#    }
#    else {
#        foreach my $att (keys %{$h}) {
#            if ($aaLocation->get($att) ne $h->{$att}) {
#                print STDERR "buildAALocation(): $att has changed for DoTS::AALocation : Object == '",$aaLocation->get($att), "' lastest value == '", $h->{$att},"'\n";
#                $aaLocation->set($att, $h->{$att});
#            }
#        }
#    }
#
#    return $aaLocation;
#}




#################################
# 
# Get GUS objects from DB methods
#
#################################

# Get an ExternalNASequence object, giving the corresponding bioperl sequence object
# @Return an ExternalNASequence object reference
# @Return undef if not found

#TW-no need to check, just load new sequence

sub getGusSequenceFromDB {
  my $self             = shift;
  my $bioperl_sequence = $self->{bioperlSequence};
  my $debug            = $self->{debug};

  my $sequence_name = $bioperl_sequence->display_id;

  if ($debug) {
      print STDERR "sequence name extracted: $sequence_name\n";
  }
  
  print STDERR "bg1\n";
  my $gus_sequence = GUS::Model::DoTS::ExternalNASequence->new ();
  print STDERR "bg2\n";
  #$gus_sequence->setName ($sequence_name);
  $gus_sequence->setSourceId ($sequence_name); #TW-query on src_id, not name
  print STDERR "SN:$sequence_name\n";
  print STDERR "bg3\n";
  
  if ($gus_sequence->retrieveFromDB()) {
      print STDERR "bg3a\n";
      $self->{gusSequence} = $gus_sequence;
      my $source = $self->get_source($gus_sequence);
      print STDERR "bg4\n";
      return ($gus_sequence, $source);
  }
  else {
      print STDERR "bg5\n";
      print STDERR "sequence not in GUS yet\n";
      
      my $source;
      ($gus_sequence, $source) = $self->buildNASequence();
      print STDERR "bg6\n";
      if (defined $gus_sequence) {
          $self->submitWithProjectLink($gus_sequence);
          $source->submit();
          return ($gus_sequence, $source);
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

#############################################
# Get the Sequence Type Id from the database,
# giving a sequence type name
##

sub getSequenceTypeIdentifier {
  my ($self, $type) = @_;

  my $typeRow = GUS::Model::DoTS::SequenceType->new({"name" => $type});
  
  my $exist = $typeRow->retrieveFromDB();
  
  if ($exist) {
    return $typeRow->getId();
    print STDERR "SEQUENCE TYPE ID:$typeRow\n\n";
  }
  else {
    print STDERR "ERROR: getSequenceTypeIdentifier(): can't find SequenceType, $type\n";
    #return undef;
    confess("getSequenceTypeIdentifier(): can't find SequenceType, $type");
  }
}

#TW-this does not seem to be called anywhere
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

################################################################################
# Get the Pfam GUS Entry correlated to the domain accession number given in
# parameter. Return the pfam Entry GUS object corresponding to the **LAST**
# Pfam release
#
sub getPfamEntry {
    my ($self, $domain_id, $dbh) = @_;

    print STDERR "getPfamEntry() : Domain Id to map: $domain_id\n";

    # Get last release (from cache?)
    #
    unless (defined $self->{'pfam_release'}) {
        my $release = undef;
        my $sql     = "select max (distinct release) from DoTS.PfamEntry";
        my $sth     = $dbh->prepare ($sql);
        $sth->execute();

        ($release) = $sth->fetchrow_array;

        if (not defined $release) {
            print STDERR "getPfamEntry() : Pfam release undefined !!!\n";
            return undef;
        }

        $self->{'pfam_release'} = $release;
    }

    my $pfamEntry =
      GUS::Model::DoTS::PfamEntry->new({'accession' => $domain_id,
                                        'release'   => $self->{'pfam_release'},
                                    });

    my $exist = $pfamEntry->retrieveFromDB;

    if ($exist) {
        print STDERR "getPfamEntry() : PfamEntry exists for $domain_id release: " . $self->{'pfam_release'} . "\n";
        return $pfamEntry;
    }
    else {
        print STDERR "getPfamEntry() : can't find Pfam entry, $domain_id!\n";
        return undef;
    }
}

################################################################################
# A single point where gene names from various qualifiers can be used to find
# the $feature and return it.
#
# This is also a good place to update the name, since a gene may go from
# /temporary_systematic_id to /systematic_id
#
# Return: Feature Object,
#         true if object is in the DB, false if it isn't
##

#TW-this method is not needed, just load new Gene Feature

sub getFeatureFromDB {
    my ($self, $feature_type) = @_;
    print STDERR "gFFBD1\n";
    my $return_feat = undef; # This holds the value returned.
    print STDERR "gFFBD2\n";
    my @name_order  = &getNameOrder();
    my %name_value  = ();

    foreach my $qualifier (@name_order) {
        next unless $self->{bioperlFeature}->has_tag($qualifier);
	print STDERR "gFFBD3:has_tag:$qualifier\n";
        my @values = $self->{bioperlFeature}->each_tag_value($qualifier);
	print STDERR "gFFBD4\n";
        if (@values) {
            $name_value{$qualifier} = $values[0];
        }
        else {
            $name_value{$qualifier} = undef;
        }
    }
    
    print STDERR "gFFBD5\n";
    ## DEBUG START #########################################################
    print STDERR "getFeatureFromDB() : \$feature_type = $feature_type\n";  #
    print STDERR "getFeatureFromDB() : Got Qualifiers ";                   #
    foreach my $qualifier (@name_order) {                                  #
        print STDERR ", $qualifier = ", $name_value{$qualifier};           #
    }                                                                      #
    print STDERR "\n";                                                     #
    ## DEBUG END   #########################################################

    my $is_in = 0;

    if ($feature_type eq 'DoTS::GeneFeature') {
        return $self->getGeneFeatureFromDB(\@name_order, \%name_value);
    }
# Genefeature should be the start of any named search
#    elsif ($feature_type eq 'DoTS::RNAFeature') {
#        return $self->getRNAFeatureFromDB(\@name_order, \%name_value);
#    }
    else {
        die "ERROR: feature of type $feature_type not currently supported";
    }

    print STDERR "getFeatureFromDB() : returning $return_feat\n";

    return ($return_feat, $is_in);

}

################################################################################
#
# Get a Genefeature from the DB using the qualifiers in the array
# @{$name_order_ref} OR return a brand new one.
##

sub getGeneFeatureFromDB {
    my ($self, $name_order_ref, $name_value_ref) = @_;
    my $gf    = undef;
    my $is_in = 0;


    # SHOULD I ONLY BE LOOKING FOR GENE WITH A SYSTEMATIC ID?
    # Cerevisiae and Pombe both have cdc2!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    #if ($self->{bioperlFeature}->has_tag('primary_name')) {
    #    my $primary_name = $self->{bioperlFeature}->each_tag_value('primary_name');
    #    $gf              = GUS::Model::DoTS::GeneFeature->new({'standard_name'=> $primary_name});
    #    $is_in           = $gf->retrieveFromDB();
    #}
    #print STDERR "getGeneFeatureFromDB() : standard_name: 'primary_name' \$is_in = $is_in\n";

    ##
    # name qualifeir can hold systematic and temporary_systematic_id


#----------------------------------------------
#TW-no need to check
#    unless ($is_in) {
#        foreach my $qualifier (@{$name_order_ref}) {
#            if (defined $name_value_ref->{$qualifier}) {
#                # Does feature with this name exist?
#
#                $gf = GUS::Model::DoTS::GeneFeature->new({'name'=> $name_value_ref->{$qualifier}});
#                $is_in = $gf->retrieveFromDB();
#
#                print STDERR "getGeneFeatureFromDB() : name:          '",$name_value_ref->{$qualifier},"' \$is_in = $is_in\n";
#
#                if ($is_in == 1) {
#                    last;
#                }
#            }
#        }
#   }
#-----------------------------------------------


    ##
    # If GeneFeature not found, create new one from "best" name qualifier
    ##
    unless ($is_in) {
        #if ($self->{bioperlFeature}->has_tag('primary_name')) {
        #    my $primary_name = $self->{bioperlFeature}->each_tag_value('primary_name');
        #    $gf = GUS::Model::DoTS::GeneFeature->new({'standard_name'=> $name_value_ref->{$qualifier}});
        #}
        #else {
	#TW-need to add additional attributes to be added here
	            foreach my $qualifier (@{$name_order_ref}) {
                if (defined $name_value_ref->{$qualifier}) {
		    #if ($UPDATE) { #TW
			#$gf = GUS::Model::DoTS::GeneFeature->new({'name'=> $name_value_ref->{$qualifier}});
		    $gf = GUS::Model::DoTS::GeneFeature->new({'source_id'=> $name_value_ref->{$qualifier}});
		    #} 
		    #else { #TW----START
			#print STDERR "UPDATE:$UPDATE\n";
			#$gf = GUS::Model::DoTS::GeneFeature->new();
			#$gf->setSourceId($name_value_ref->{$qualifier});
		    #}  #TW---END
                    last;
                }
            }
        #}
    }

    print STDERR "getGeneFeatureFromDB() : Returning $gf, $is_in\n";

    return ($gf, $is_in);
}

################################################################################
#
# RNAFeature only has one name field, called name :)


# IS THIS METHOD NEEDED????
# WE CAN GETTHE RNAFeature  FROM THE GeneFeature!!!!!!!!


##

#sub getRNAFeatureFromDB {
#    my ($self, $name_order_ref, $name_value_ref) = @_;
#
#    my $rnaf  = undef;
#    my $is_in = 0;
#
#    foreach my $qualifier (@{$name_order_ref}) {
#        if (defined $name_value_ref->{$qualifier}) {
#            # Does feature with this name exist?
#
#            $rnaf  = GUS::Model::DoTS::RNAFeature->new({'name'=> $name_value_ref->{$qualifier}});
#            $is_in = $rnaf->retrieveFromDB();
#
#            print STDERR "getRNAFeatureFromDB() : name:          '",$name_value_ref->{$qualifier},"' \$is_in = $is_in\n";
#
#            if ($is_in == 1) {
#                last;
#            }
#        }
#    }

#    ##
#    # If RNAFeature not found, create new one from "best" name qualifier
#    ##
#    unless ($is_in) {
#        foreach my $qualifier (@{$name_order_ref}) {
#            if (defined $name_value_ref->{$qualifier}) {
#                $rnaf = GUS::Model::DoTS::RNAFeature->new({'name'=> $name_value_ref->{$qualifier}});
#                last;
#            }
#        }
#    }
#
#    print STDERR "getRNAFeatureFromDB() : Returning $rnaf, $is_in\n";
#
#    return ($rnaf, $is_in); 
#}

################################################################################
#
##
sub updateNames {
    my ($self, $feat) = @_;
    my @name_order    = &getNameOrder();

    if (ref($feat) eq 'GUS::Model::DoTS::GeneFeature') {
        # If systematic_id is the "name", all is well
        # If the systematic_id exists and its not the "name", it needs to be updated

        # ``'`'`'`'`'`'`'`'`'`'`'`'`'`'`'`'`'`'`'`'`'`'`'`'`'`'`'`''`'`'`'`'`'`'`'`'`'`'`'`'`'`'`'

        # Do we traverse the objects GeneFeature, RNAFeature, ProteinFeature, Gene, RNA, Protein
        # to change the name??????????
        # Could do this once a GeneFeature has been retreived.

        # ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    }
}

################################################################################
# Return the preferred name order.
##
sub getNameOrder {
    return ('systematic_id', 'temporary_systematic_id', 'previous_systematic_id');
}


################################################################################
#
##
sub get_best_systematic_id {
    my ($self) = @_;

    my @name_order  = &getNameOrder();
    my %name_value  = ();

    foreach my $qualifier (@name_order) {
        next unless $self->{bioperlFeature}->has_tag($qualifier);

        my @values = $self->{bioperlFeature}->each_tag_value($qualifier);

        if (@values) {
             return $values[0];
        }
    }
}
#--------------------------------
sub submitWithProjectLink {
    my $self = shift;
    my $T = shift;

    $T->submit();
    $self->buildProjectLink($T);
}

# --------------------------------------------------------------------

sub buildProjectLink {
  my $self = shift;
  my $T = shift;  # table object;
  my %plink;
 

  print STDERR "METHOD:1-buildProjectLink\n";

  # table
  $plink{table_id} = $T->getTableIdFromTableName($T->getClassName);
  $plink{id}       = $T->getId();

  my $projlink_gus = GUS::Model::DoTS::ProjectLink->new(\%plink);

  if ($projlink_gus->retrieveFromDB) {
    # case when projectLink is in dB
    print "ProjectLink already in DB with ID " . $projlink_gus->getId() . "\n";
    return undef;
    print STDERR "METHOD:2a-buildProjectLink\n";
  } 
  else {
      print STDERR "METHOD:2b-buildProjectLink\n";
      #$projlink_gus->setProjectId($self->getProjId());
      #$projlink_gus->setProjectId($self->getProjectId());
      $projlink_gus->setProjectId(1178);
      print STDERR "METHOD:2c-Setting PID as $projlink_gus\n";
   
      # using setParent method here creates a NEW row in ProjectInfo table, if needed:
      # $projlink_gus->setParent($project_gus);
   
      #print STDERR "PID:" . Dumper($projlink_gus). "\n\n";
      #print STDERR Data::Dumper::Dumper($projlink_gus);
      $projlink_gus->submit();
      return 1;
      print STDERR "METHOD:2d-buildProjectLink\n";
  }
}

#############################################
# Get the Project Id from the database,
# given the Project name
###

sub getProjectId {
  my ($self) = @_;
  my $projId;

  my $typeRow = GUS::Model::Core::ProjectInfo->new({"name" => $self->{pId}});
  print STDERR "PID:$typeRow\n";

  my $exist = $typeRow->retrieveFromDB();
  print STDERR "DB Query executed ...\n";

  if ($exist) {
    return $typeRow->getId();
    print STDERR "PROJECT ID:$typeRow\n\n";
  }
  else {
    print STDERR "ERROR: getProjectId(): can't find Project Id, $self->{pId}\n";
    #return undef;
    confess("getProjectId(): can't find Project ID, $self->{pId}");
  }
}


# --------------------------------------------------------------------
sub setProjId {
  my $self = shift;
  #$self->log("Finding Project");
  print STDERR "Finding Project\n\n";

  my %project = ( name => $self->{'projectId'} || 'PlasmodiumDB-4.4' );

  my $project_gus = GUS::Model::Core::ProjectInfo->new(\%project);
  if ($project_gus->retrieveFromDB) {
    $projId = $project_gus->getId;
    print STDERR "RETURNED VALUE OF PID:$projId\n";
} 
  else {
      print STDERR "ERROR in returning ProjectID\n";
      return undef;
  }
  return 1;
}

#-------------------------------------------------------------------
sub getProjId {
    return $projId;
    print STDERR "PROJECT-ID:$projId\n"; 
}

#-------------

1;
