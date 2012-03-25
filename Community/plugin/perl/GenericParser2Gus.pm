#-----------------------------------------------------------
# GenericParser2Gus
#
# Loads any file recognised by Bioperl into GUS (tested on
# EMBL, Sanger PSU style).
# It uses the Bioperl2GUS package to handle the mapping of
# Bioperl to GUS objects.
#
# NOTE: You will need to put Bioperl into your PERL5LIB!!!
#       You will also need the PSU Perl code. At the time of
#       writing it was here
#        http://cvsweb.sanger.ac.uk/cgi-bin/cvsweb.cgi/psu/genlib/perl/?cvsroot=Pathogen&f=h
# Created: 
#
# Original by Arnaud Kerhornou (GUSdev)
# Modified by Paul Mooney (GUS3.0)
# Modified for PlasmoDB by Trish Whetzel
# ----------------------------------------------------------

#
# build GUS install -append ; ga GUS::Community::Plugin::GenericParser2Gus --filetype=embl --filepath=/nfs/team81/pjm/temp/c212_0 -sequencetype=ds-DNA |& less
# the only filetype used so far is ds-DNA
#
# cp -f Common/plugin/perl/GenericParser2Gus.pm ~pjm/GUS/lib/perl/GUS/Common/Plugin/GenericParser2Gus.pm ; cp -f Common/lib/perl/Bioperl2Gus.pm ~pjm/GUS/lib/perl/GUS/Common/Bioperl2Gus.pm ; ga GUS::Community::Plugin::GenericParser2Gus --filetype=embl --filepath=/nfs/team81/pjm/temp/FAKE7.embl -sequencetype=ds-DNA | & less

#
# TODO LIST
#
# 0. What about stuff that needs to be deleted? I.e. A gene feature just "disappears".... Do we need a clean up
#    operation????????
#
#    CleanUp is probably another library like BioPerl2Gus.
#    Loop over every feature and remove any no longer in the EMBL file that are attached to this sequence.
#
#    What happens when the sequence ID changes, will need "OLD_SEQUENCE_ID" in source?????????
#
#    SignalP, TMHMMs are *deleted* each time a data load takes place. A prediction is not an update of
#    an old prediction. Dunno if this will need to change?

#
# 1. name or standard_name??????????
# 2. Sequence update procedure: The gus sequence is retrieved by name - the name to start with could be quite unstable.
# 3. Previous gene names need to be looked up to find the corrrect gene in the DB.
# 4. ?
#
# *** Tracking features/objects via their name ***
#
# This was taken from the WIKI on 20 Jan and summerized;
#
#   /systematic_id           - final systematic name 
#   /temporary_systematic_id - for temporary systematic name used during projects where sequence is unfinished
#   /previous_systematic_id  - for systematic names no longer in use. 
#   /synonym                 - used for other gene names still in use and to be displayed on the gene page 
#   /obsolete_name           - redundant gene names
#   /primary_name            - for published or agreed unique user friendly gene name
#   /reserved_name           - pre-publication names that will, presumably, become the primary_name 
#

package GUS::Community::Plugin::GenericParser2Gus;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
#use DBI;
use Data::Dumper;
use Carp;

use Benchmark;
use FileHandle;
use IO::File;

#################################
# Load the bioperl2Gus module
#################################
use GUS::Community::Bioperl2Gus;


use Bio::Location::Simple;
use Bio::SeqIO;

my $logdir = "/tmp/"; # Not sure how useful this log is...

# OUTPUT_AUTOFLUSH forced
$| = 1;
my $debug = 1;

print STDERR "GUSLOGS ENV: $ENV{GUSLOGS}\n";

if (exists $ENV{GUSLOGS}) {
    print STDERR "GUSLOGS exists!!\n";
    $logdir = $ENV{GUSLOGS};
}


sub new {
  my $class = shift;
  my $self  = {};
  bless($self,$class);

  my $usage = 'Imports finished gene annotation from any file format '.
      'recognised by bioperl';
  my $easycsp =
   [{
        o => 'filepath',
        t => 'string',
        r => 1,
        h => 'Annotations file or directory',
    },
       { 
        o => 'filetype',
        t => 'string',
        r => 1,
        h => 'file type (genbank or embl or Fasta format). '.
             'Not specifying this meant things did not work, hence why this '.
             'is a requried field',
    },
    {
        o => 'sequencetype',
        t => 'string',
        r => 1,
        h => 'type of sequence to upload into GUS (e.g. ss-DNA, ds-DNA, ssRNA, ds-RNA, tRNA, mRNA, rRNA, EST, GSS, RNA, predictied_mRNA)',
    },
    {
        o => 'log',
        t => 'string',
        h => 'Path to log file.',
        d => "$logdir/GenericParser2Gusdev.pid$$.log",
    },
    {
        o => 'project',
        t => 'string',
        h => 'GUS project name',
    },
    {
        o => 'comment',
        t => 'string',
        h => 'attach this comment to the alg inv',
    },
    {
        o => 'verbose',
        t => 'boolean',
        h => 'activate process messages display',
        d => 0,
    },
    {
        o => 'parserDebug',
        t => 'boolean',
        h => 'Display helpful debug messages',
        d => 0,
    },
    {
        o => 'reviewstatus',
        t => 'string',
        h => 'Your default value to use for review_status_id on all tables that require it. The default is 5 so you *must* change it to your sites default if it is different - See SRes::ReviewStatus for a list.',
        d => 5,
    },
   ];

  $self->initialize({requiredDbVersion => {},
                     cvsRevision    => '$Revision$', # cvs fills this in!',
                     cvsTag         => '$Name$', # cvs fills this in!',
                     name           => ref($self),
                     revisionNotes  => 'make consistent with GUS 3.0',
                     easyCspOptions => $easycsp,
                     usage          => $usage
                     });
  return $self;
}


################################################################################
# run
#
sub run {
    my $self = shift;
    my $t1   = Benchmark->new ();
  
    print $self->getArgs->{'commit'} ? "***COMMIT ON***\n" : "***COMMIT TURNED OFF***\n";
    print "Testing on ",$self->getArgs->{'testnumber'},"\n" if $self->getArgs->{'testnumber'};

    if ($self->getCla->{'parserDebug'}) {
        $debug = 1;
        print "***DEBUGGING ON***\n";
    }

    # Is this line still needed???
    #eval("require Objects::GUSdev::".$self->getArgs->{seq_table_name});

    my $path          = $self->getArgs->{filepath};
    my $fileType      = $self->getArgs->{filetype};
    my $sequenceType  = $self->getArgs->{sequencetype};
    my $strand        = $self->getArgs->{strand};
    my $review_status = $self->getArgs->{reviewstatus} || 5; #TW-change default from 5
    my $log           = FileHandle->new( '>'. $self->getArgs->{log} );
    my $projId        = $self->getArgs->{project};
    print STDERR "GPG-PRJID:$projId\n";


    print STDERR "Dumping log: " . Dumper ($self->getArgs->{log}) . "\n";

    $log->print("FILE: ", $self->getArgs->{ filepath }, "\n");

    my $verbose      = $self->getArgs->{'verbose'};
    my $n            = 0;
    my $update_count = 0;
    my $insert_count = 0;

    # Load the Bioperl2Gusdev converter and create bioperl objects
    #
    my $bioperl2Gus =
        GUS::Community::Bioperl2Gus->new (sequenceType          => $sequenceType,
                                       debug                 => $debug,
                                       default_review_status => $review_status,
                                       projId                => $projId,  
				       );

    my @bioperl_seqs = $self->parseSequenceFiles ($path, $fileType);

    # process the bioperl sequence objects
    #
    foreach my $bioperl_sequence (@bioperl_seqs) {
        print "Processing bioperl sequence, " . $bioperl_sequence->display_id . "...\n";
        $bioperl2Gus->setBioperlSequence ($bioperl_sequence);

        # Check if sequence is already in the database
        #
	
	print STDERR "hello1\n";
	my ($gus_sequence, $source) = $bioperl2Gus->getGusSequenceFromDB($bioperl_sequence);
	print STDERR "hello2\n";

        if (not defined ($gus_sequence)) {
            print STDERR "GUS Sequence creation failed!!! Going to next sequence.\n";
	    $self->log("GUS Sequence creation failed for $gus_sequence!!! Going to next sequence");
            next;
        }
       
        else {
            # Has seq changed? IDs used in EMBL files are not probably not temp. only
            print STDERR "GUS Sequence already in the database. Checking to see if sequence has changed...\n";
	    $self->log("GUS Sequence already in the database. Checking to see if sequence has changed...");
	    
	    #TW - do not need to look for sequence 
            #if ($bioperl_sequence->seq() ne $gus_sequence->getSequence()) {
	    print STDERR "\n*** The sequence has changed ***\n\n";
	    print STDERR "Loading Sequence\n";
	    
	    my ($the_same_gus_seq, $new_source) = $bioperl2Gus->buildNASequence($gus_sequence);
	    $bioperl2Gus->submitWithProjectLink($the_same_gus_seq); # Versioning - *** use update *** if sequence too big to version
	    $new_source->submit();
	    #}
            
	    #TW - do not need to look for sequence, just load
	    #else {
	    #	print STDERR "The sequence has not changed.\n";
	    #	$source = $bioperl2Gus->get_source($gus_sequence);
	    #	print STDERR "SOURCE:$source\n\n";
	    #	$source->submit;
	    #	print STDERR "Source submitted.\n";
            #}
        }
	

        print STDERR "Getting all features for the sequence.\n";
        my @bioperl_features = $bioperl_sequence->all_SeqFeatures;

        print STDERR scalar(@bioperl_features), " features to process in EMBL file";

        foreach my $bioperl_feature (@bioperl_features) {
            $bioperl2Gus->setBioperlFeature ($bioperl_feature);
            my $primary_tag  = $bioperl_feature->primary_tag;

            print STDERR "\n-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n";
            print "Processing '$primary_tag' bioperl feature...\n";


            ##############################
            # Get /systematic_id qualifier (or equivalent) for CDS & RNA features

            my $systematic_id = undef;
            #my @need_id       = ('CDS', 'tRNA', 'rRNA', 'mRNA', 'misc_RNA');

            if ($primary_tag eq 'CDS' ||  $primary_tag =~ /.*RNA$/) {
                if ($bioperl_feature->has_tag ('systematic_id')) {
                    my @values      = $bioperl_feature->each_tag_value ('systematic_id');	  
                    $systematic_id  = $values[0];

                    if (scalar(@values) > 1) {
                        die "ERROR: 2+ /systematic_ids found : '" . join (', ', @values) . "'.\n";
                    }
                }
                elsif ($bioperl_feature->has_tag ('temporary_systematic_id')) {
                    my @systematic_ids = $bioperl_feature->each_tag_value ('temporary_systematic_id');
                    $systematic_id     = $systematic_ids[0];
                }
                else {
                    print STDERR "\n\n*** ERROR: can't find any (temporary) systematic id tag for current '".
                        $bioperl_feature->primary_tag."' bioperl feature ***\n\n\n";
                    next;
                }

                if (!defined $systematic_id || $systematic_id eq '') {
                    print STDERR "ERROR: variable \$systematic_id has not been defined. ".
                        "Is there an empty qualifier for the name of this feature?\n";
                    next; 
                }
            }

            my $gene_type = "UNKNOWN";

            ##################
            # CDS
            if ($bioperl_feature->primary_tag eq 'CDS') {
                $gene_type = "protein coding";
            }
            #################################
            # mRNA feature i.e. ESTs
            elsif ($bioperl_feature->primary_tag eq 'mRNA') {
                $gene_type = "protein coding"; # !!!
            }

            ##################
            # tRNAs, rRNA, misc_RNA etc etc
            elsif ($bioperl_feature->primary_tag =~ /.*RNA$/) {
                $gene_type = $bioperl_feature->primary_tag;
            }

            if ($gene_type ne 'UNKNOWN') {
                $self->process($log, $bioperl_feature, $bioperl2Gus, $systematic_id, $gene_type);
            }
            else {
                print "Ignoring ", $bioperl_feature->primary_tag, "";
            }

            # Uncaching stuff here for the current sequence and attached features
            # Uncaching the gus sequence object, does it also uncache the attached
            # features???
            $self->undefPointerCache;

        } # next bioperl feature object process

    } # next bioperl sequence object process


    my $t2 = Benchmark->new ();
    print  STDERR "\nTotal: ", timestr (timediff ($t2, $t1)), "\n";
    $log->print( "Total: timestr (timediff ($t2, $t1)\n");

    return "Objects inserted= $insert_count;  updated= $update_count; total #(inserted::updated::deleted)=" . $self->getSelfInv->getTotalInserts() . "::" . $self->getSelfInv->getTotalUpdates() . "::" . $self->getSelfInv->getTotalDeletes() .  "\n";

}

################################################################################
# The PSU can have multiple name qualifiers.
# These qulaifiers are fairly stable but change over time
#
#   /primary_name                 DoTS.GeneFeature.Name
#   /systematic_id                DoTS.GeneFeature.standard_name
#   /temporary_systematic_id      ??                               
#   /previous_systematic_name     ??
#   /synonym                      DoTS.GeneSynonym.synonym_name
#   /obsolete_name                ??
#   /reserved_name                ??
#
# NOTE: if the /systematic_id does not exist, /temporary_systematic_id will be
#       used in its place, for now.
##

sub check_names {
    my ($self, $bioperl_feature ) = @_;
    my @errors;

    if ($bioperl_feature->has_tag ('primary_name')) {
        my @values      = $bioperl_feature->each_tag_value ('primary_name');	  

        if (scalar(@values) > 1) {
            push @errors, "ERROR: 2+ /primary_naames found : '" . join (', ', @values) . "'.\n";
        }
    }

    if ($bioperl_feature->has_tag ('systematic_id')) {
        my @values      = $bioperl_feature->each_tag_value ('systematic_id');	  

        if (scalar(@values) > 1) {
            push @errors, "ERROR: 2+ /systematic_ids found : '" . join (', ', @values) . "'.\n";
        }
    }

    if ($bioperl_feature->has_tag ('temporary_systematic_id')) {
        my @systematic_ids = $bioperl_feature->each_tag_value ('temporary_systematic_id');

        if (scalar(@systematic_ids) > 1) {
            push @errors, "ERROR: 2+ /temporary_systematic_ids found : '" . join (', ', @systematic_ids) . "'.\n";
        }
    }

    unless ($bioperl_feature->has_tag ('primary_name')      ||
                $bioperl_feature->has_tag ('systematic_id') ||
                $bioperl_feature->has_tag ('temporary_systematic_id')){
        print STDERR "\n\n*** ERROR: can't find /primary_name or (temporary) systematic id tag for current '".
            $bioperl_feature->primary_tag."' bioperl feature at ",  $bioperl_feature->location->to_FTstring(), "***\n\n\n";
        next;
    }
}


#########################################################################
# Builds object heirarchy to represent a CDS.
# We submit all objects before creating and submitting GO objects.
#
# DoTS.Attribution needs the row ID of GeneFeature too.
#
# @returns number of object created. Not sure if this is helpful or not...
####
sub process{
    my ($self, $log, $bioperl_feature, $bioperl2Gus, $systematic_id, $gene_type) = @_;

    my $insert_count  = 0;    # return value in here

    if ($bioperl_feature->has_tag ('pseudo')) {
        $gene_type = "pseudogene";
        print STDERR "parsing a pseudogene ...!\n";
    }
    else {
        print STDERR "parsing a protein coding gene ...!\n";
    }

    # Create/update/leave alone DoTS::GeneFeature and all child objects
    #
    my @gus_objects = $self->buildFeatureObjects ($bioperl2Gus, $gene_type, $systematic_id); 

    #
    # DEBUG TO SEE WHATS IN THE ARRAY SO FAR
    #
    if ($debug) {
        print "\n*** process(): All child objects about to be submitted (not GO, yet) ***\n";
        print "\n*** ------------------------------------------------------------------- ***\n";

        foreach my $obj (@gus_objects){
            print "*** \$obj = $obj ***\n";
        }
    }

    ##############################################################################
    # commit the GUS objects associated with the CDS bioperl feature object
    # The submit allows all children to be submitted (no parameter $notDeep set).
    # Further submits on child objects won't do anything so this loop is not that
    # useful...
    ########################

    foreach my $object (@gus_objects) {
        print STDERR "Object type is '", ref($object), "', \$object = $object\n";
                
        unless (defined $object) {
            print STDERR "\n*** WARNING: undef value returned for an object;\n\n";
            next;
        }
        elsif (ref($object) eq 'HASH') {
            print STDERR "\n*** ERROR: this is not a class;\n", Dumper($object), "\n";
            next;
        }

        if ($self->getArgs->{'verbose'}) {
            print $object->toXML();
        }

	      
        ###############################################################3
        # FIXME ???????? Probably but this won't hurt for now;
        # NOTE: We are submitting deep, hence we may try and submit everything 2+ times!
        #       Add '1' as the argument to submit() to make it a non-deep submit!!!
        ##
        # NOTE2: processDomainFeatureHack() needs things to be commited non-deep.

        print "Inserting ",ref($object),"\n"; 

        $self->processDomainFeatureHack($object); # FIXME: to be taken out when design erro fixed - 2 fields can have same parent!!

        $object->submit(1); # Will version the object *if* it has changed


        $log->print( "object INSERTED (", ref($object),")\n");

        $insert_count++;


	######
        # Can only link GOAssociation to a TranslatedAASequence when 
	# it has a row_id, hence been submitted
        ######
	#TW GO terms are linked to aa_sequence_id of GeneFeature
	#TW TAAS is NOT in @gus_objects anymore and is submitted separately
	#if (ref($object) eq 'GUS::Model::DoTS::Protein') {
	#    print STDERR"\nInserted Protein Object. Call buildAndSubmitGO_Objects()\n";
        #    $insert_count += $self->buildAndSubmitGO_Objects($log, $bioperl2Gus, $aa_seq);
        #}


	#####
        # Create attribution once GeneFeature has been committed
        #####
        if (ref($object) eq 'GUS::Model::DoTS::GeneFeature') {
            $insert_count += $bioperl2Gus->buildAndSubmitAttribution($object);
        }
    }

    return $insert_count;
}



################################################################################
#
#                                                 =-=-=-= HACK HACK HACK =-=-=-=
##
sub processDomainFeatureHack {
    my ($self, $domain_feature) = @_;

    if (ref($domain_feature) eq 'GUS::Model::DoTS::DomainFeature') {
        my $aa_seq = $domain_feature->getParent('DoTS::TranslatedAASequence');

        print "processDomainFeatureHack(): \$aa_seq = $aa_seq, id = ", $aa_seq->getId(), "\n";

        $domain_feature->set('aa_sequence_id', $aa_seq->getId());

        print STDERR "processDomainFeatureHack(): Done.\n";
    }
}

################################################################################
#
#
#
sub parseSequenceFiles {
  my ($self, $path, $fileType) = @_;
  my @bioperl_seqs = ();

  # if it is a text file
  if (-T $path) {
    my $bioperl_seq = $self->parseOneSequenceFile ($path, $fileType);
    push (@bioperl_seqs, $bioperl_seq);
  }
  # else if it is a directory
  elsif (-d $path) {
    opendir (DIR, $path) or die "can't open directory, $path!!\n";
    my @files = grep { not /\.$/ } map { "$path/$_" } readdir DIR;
    closedir DIR;

    print STDERR @files . " files to parse...\n";

    foreach my $fileName (@files) {
      if (-T $fileName) {
        my $bioperl_seq = $self->parseOneSequenceFile ($fileName, $fileType);
        push (@bioperl_seqs, $bioperl_seq);
      }
    }
  }
  else {
    print STDERR "ERROR: $path is not a valid file or directory name!!\n";
  }

  return @bioperl_seqs;
}

################################################################################
#
# This part strips off anything from the start of an EMBL file before the ID
# line as Bioperl thinks it's not EMBL (in its book).
#
# This code needs to be re-written so as not to use PSU perl code
#
sub parseOneSequenceFile {
  my ($self, $fileName, $fileType) = @_;
  
  print STDERR "$fileType file to parse, $fileName...\n";

  # Basic Seq factory object - direct stream from file
  
  my $in  = Bio::SeqIO->new('-file'   => $fileName,
                            '-format' => $fileType);
  return $in->next_seq();

}


################################################################################
#
# Called to create features for CDS, tRNA, rRNA and mRNA
#
#
sub buildFeatureObjects {
    my ($self, $bioperl2Gus, $gene_type, $systematic_id) = @_;
    my @gus_objects = ();

    my $bioperl_feature   = $bioperl2Gus->getBioperlFeature;
    my $bioperl_locations = $bioperl_feature->location;

    # print STDERR "Dumping bioperl locations object: " . Dumper ($bioperl_locations) . "\n";

    my @bioperl_locations = ();

    my $partial = 0;

    if (ref ($bioperl_locations) =~ /Split/) {
        @bioperl_locations = $bioperl_locations->sub_Location();
    }
    elsif (ref ($bioperl_locations) =~ /Simple/) {
        push (@bioperl_locations, $bioperl_locations);
    }
    elsif (ref ($bioperl_locations) =~ /Fuzzy/) {
        push (@bioperl_locations, $bioperl_locations);
        # partial CDS
        $partial = 1;
    }
    else {
        print STDERR  "bioperl_locations object type unknown, " . ref ($bioperl_locations) . " !!!\n";
    }

    #####
    # GeneFeature object
    # buildGeneFeature returns the GeneFeature plus child objects (plus NALocation,
    # possibly Reference/DbRef objects)
    #####
    my $bioperl_geneLocation  = $self->getGeneLocation (@bioperl_locations);
    my $number_of_exons       = scalar(@bioperl_locations);
    my ($gf, @gus_gf_objects) =
        $bioperl2Gus->buildGeneFeature ($number_of_exons, $bioperl_geneLocation, $gene_type, $partial, $systematic_id);
    push (@gus_objects, $gf);  #TW-bindu added $gf->submit() to BG, is this still needed?  #@gus_objects gets returned
    #TW-need to add call to submitWithProjectLink, may need to submit $gf then call method
    $bioperl2Gus->submitWithProjectLink($gf);
    push (@gus_objects, @gus_gf_objects);

    


    ###############################################################
    # If it's a pseudogene, generate only the gene feature object
    #
    # *** QUESTION: what about the gene in the Central Dogma? ***
    #
    ###############################################################

    if ($gene_type =~ /pseudogene/i) {
        return @gus_objects;
    }


    print STDERR "*** Gene was not a pseudogene, it is a $gene_type, creating RNA related objects\n"; # DEBUG




    # RNAFeature - set $snas (SplicedNASequence) and $gf (GeneFeature) to be the parent
    #
    # *** Question: how is this object different to the NALocation for the GeneFeature above???
    #
    my $snas = $bioperl2Gus->buildSplicedNASequence($gf);
    my ($rnaf, $gus_naLocation_rf) =
        $bioperl2Gus->buildRNAFeature ($gf, $snas, $number_of_exons, $bioperl_geneLocation, $systematic_id);

    push (@gus_objects, $rnaf);
    push (@gus_objects, $gus_naLocation_rf);

    if (defined $snas) { # IS THIS IF STATEMENT REALLY NEEDED???
        push (@gus_objects, $snas);
    }
    else {
        print STDERR "spliced sequence object not defined !!!! - not added !!!\n";
    }

    # ExonFeatures, link each to RNAFeature via RNAFeatureExon
    #
    my $i = 1;

    # Bioperl represents sequence going right to left if reverse strand. Change it so more like EMBL,
    # always go 5' to 3'
    #if (scalar(@bioperl_locations) > 1) {
    #    if (($bioperl_locations[0]->start > $bioperl_locations[1]->start)
    #             && $bioperl_locations[0]->strand == -1) {
    #        @bioperl_locations = reverse @bioperl_locations;
    #        $loc_order         = scalar(@bioperl_locations);
    #        $loc_add           = -1;
    #    }
    #}

    foreach my $bioperl_location (@bioperl_locations) {
        print STDERR "Creating ExonFeature $i\n";

        my $is_initial_exon = 0;
        my $is_final_exon   = 0;

        if ($i == 1) {
            $is_initial_exon = 1;
        }
        if ($i == $number_of_exons) {
            $is_final_exon = 1;
        }

        my $ef = $bioperl2Gus->buildExonFeature ($gf, $is_initial_exon, $is_final_exon,
                                                 $bioperl_location, $i);
        push (@gus_objects, $ef);

        my $gus_naLocation_ef = $bioperl2Gus->buildNALocation ($ef, $bioperl_location, $i);
        push (@gus_objects, $gus_naLocation_ef);
    
        my $rfe = $bioperl2Gus->buildRNAFeatureExon ($ef, $rnaf);
        push (@gus_objects, $rfe);

        $i++;
    }

    ###
    # if it's not a protein coding gene, don't generate any protein feature
    ##

    if ($gene_type =~ /RNA/) {
        return @gus_objects;
    }
    
    
    my ($aa_seq, @properties) =
        #$bioperl2Gus->buildTranslatedAASequence ($gf, $aa_feature_translated, $systematic_id);
	$bioperl2Gus->buildTranslatedAASequence ($gf, $systematic_id);
    #push (@gus_objects, $aa_seq);
    $aa_seq->submit();  #Need to submit here in order to have the aa_sequence_id to make an AASequenceEnzymeClass object 
    push (@gus_objects, @properties);
    print STDERR "\nGP:DEBUG-AASEQ:$aa_seq\n\n";
    
    #Can now build GO Associations
    #$insert_count +=
    $self->buildAndSubmitGO_Objects($bioperl2Gus, $aa_seq);  #TW


    ##################
    # The Protein Feature object as both a TranslatedAAFeature and a ProteinFeature(?)
    # 
    # to do : build NALocation objects attached to the ProteinFeature object
    #
    # If $aa_feature_translated (TranslatedAAFeature) has a parent of 
    # TranslatedAASequence the old
    # one will be retieved.
    ########
    print STDERR "DEBUG-Called buildTranslatedAAFeature(), GPG\n";
    my ($aa_feature_translated) = $bioperl2Gus->buildTranslatedAAFeature ($rnaf, $aa_seq);
    #TW my ($aa_feature_translated) = $bioperl2Gus->buildProteinFeature ($rnaf); #, $aa_seq);
    #push (@gus_objects, $aa_feature_protein);  ???
    push (@gus_objects, $aa_feature_translated);
    print "DEBUG-Method buildTranslatedAAFeature() done, GPG\n\n";


    #####
    # Add EC Number/TranslatedAASequence associations
    print STDERR "DEBUG-Called  buildEcNumber(), GPG\n"; 
    my @aasec = $bioperl2Gus->buildEcNumber($aa_seq);
    push(@gus_objects, @aasec);
    print STDERR "DONE Building EC number/TranslatedAASequence associations, GPG\n\n";
    

    #####
    # AAFeatures and their location objects
    # e.g. SignalP, PredictedAAFeatures (TMHMM & Pfam)
    ##
    print STDERR "Building AAFeatures\n";
    my @aafs = $bioperl2Gus->buildAAFeatures ($aa_seq, $gf->getName);  #TW maybe this should be $gf->getSourceId()
    push (@gus_objects, @aafs);
    print STDERR "DONE Building AAFeatures, GPG\n\n";
    

    #TW - Does $ec_num need to be addded here??????
    #TWmy @gus_CentralDogma_objects =
        #$self->buildCentralDogmaObjects ($bioperl2Gus, $gf, $rnaf,
         #                                $aa_feature_protein, $aa_seq,
         #                                $gene_type);
    my @gus_CentralDogma_objects =
        $self->buildCentralDogmaObjects ($bioperl2Gus, $gf, $rnaf,
                                         $aa_seq, $gene_type); #TW 
    push (@gus_objects, @gus_CentralDogma_objects);
  
    return @gus_objects;
}

################################################################################
#
#
sub buildCentralDogmaObjects {
    #TWmy ($self, $bioperl2Gus, $gf, $rnaf, $aa_feature_protein, $aa_seq, $gene_type) = @_;

    my ($self, $bioperl2Gus, $gf, $rnaf, $aa_seq, $gene_type) = @_;  #TW 

    my @central_dogma_objects = ();

    ##
    # Gene object
    ##

    my ($gene_object, @gene_synonyms) = $bioperl2Gus->buildGene ($gf);
    print STDERR "DEBUG-Called method buildGene(), GPG\n";
    push (@central_dogma_objects, $gene_object);
    push (@central_dogma_objects, @gene_synonyms);
    print STDERR "DEBUG-DONE method buildGene(), GPG\n\n";

    # GeneInstance Object, links Gene to GeneFeature
    #START---
    #TW-GeneInstance is not used by PlasmoDB
    #my $geneSequence = $bioperl2Gus->buildGeneInstance ($gene_object, $gf);
    #push (@central_dogma_objects, $geneSequence);
    #END----
    if ($gene_type =~ /pseudogene/i) {
        return @central_dogma_objects;
    }


    ##
    # build RNA object
    ##

    my $rna_object = $bioperl2Gus->buildRNA ($gene_object);
    print STDERR "DEBUG-Called method buildRNA(), GPG\n";
    push (@central_dogma_objects, $rna_object);
    print STDERR "DEBUG-DONE method buildGene(), GPG\n\n";

    #START---
    #TW-RNAInstance not used by PlasmoDB
    #my $rnaSequence = $bioperl2Gus->buildRNAInstance ($rna_object, $rnaf, $gene_type);
    #push (@central_dogma_objects, $rnaSequence);
    #END---

    if ($gene_type =~ /RNA/) {
        return @central_dogma_objects;
    }

    ##
    # build protein object
    #
    # ProteinFeature is on top of NASequenceImp so it can not be linked to ProteinInstance
    # This is why it buildProteinInstance() is commented out.
    ##

    my $protein_object = $bioperl2Gus->buildProtein ($rna_object, $aa_seq, $gf);
    push (@central_dogma_objects, $protein_object);

    #my $proteinSequence = $bioperl2Gus->buildProteinInstance ($protein_object, $aa_feature_protein);
    #push (@central_dogma_objects, $proteinSequence);

    return @central_dogma_objects;
}

################################################################################
# This has to be called after the protein/RNA object has been created so we can
# use its row_id value in the GOAssociation - an object not yet submitted will not
# have a value.
#
# Also note: all GO objects will have been submitted by the method, no need to
# submit again in this method. The row_id would have been required when linking
# tables together.
#

sub buildAndSubmitGO_Objects {
    #TWmy ($self, $log, $bioperl2Gus, $object) = @_;
    my ($self, $bioperl2Gus, $object) = @_;
    my $dbh        = $self->getQueryHandle();
    my @go_objects = ();
    my $sth = $dbh->prepare(
qq[SELECT external_database_release_id, release_date, version
FROM   SRes.ExternalDatabaseRelease  edr, SRes.ExternalDatabase ed
WHERE  ed.name = ?
AND    ed.external_database_id = edr.external_database_id
ORDER BY release_date, external_database_release_id]);

    unless (defined $sth) {
        confess("ERROR: buildAndSubmitGO_Objects() \$sth is undefined, is plugin connected to the DB anymore ? \$dbh = $dbh");
    }

    #GO info can be in two forms
    #style 1
    #push @go_objects, $bioperl2Gus->buildGO_aspectAssociation($dbh, 'GO_process',  $object);
    #push @go_objects, $bioperl2Gus->buildGO_aspectAssociation($dbh, 'GO_component',$object);
    #push @go_objects, $bioperl2Gus->buildGO_aspectAssociation($dbh, 'GO_function', $object);

    #style 2
    push @go_objects, $bioperl2Gus->buildGOAssociations($dbh, $object); # /GO=""

    print STDERR "GO objects submitted = ", scalar(@go_objects), "\n\n";


    #foreach my $obj (@go_objects){
    #    print STDERR "\$obj = '$obj'";
    #    $obj->submit();
    #    $log->print( "GO Record inserted", ref($obj),")\n");
    #    print STDERR "GO Record inserted", ref($obj),")\n";
    #}

    return scalar(@go_objects); # How many created
}

################################################################################
# From a set of locations (e.g. a set of exon corrdinates, returns a location
# where the start is the start of the first location and the end is the end of
# the last location

sub getGeneLocation {
  my ($self, @locations) = @_;
  my $number_of_exons = @locations;

  if ($number_of_exons == 1) {
    return $locations[0];
  }
  if ($number_of_exons > 1) {
    my $firstExonLocation = $locations[0];
    my $lastExonLocation  = $locations[$number_of_exons-1];
    
    if ((ref ($firstExonLocation) =~ /Fuzzy/) || (ref ($lastExonLocation) =~ /Fuzzy/)) {
      my $start_min = $firstExonLocation->min_start;
      my $start_max = $firstExonLocation->max_start;
      my $end_min   = $lastExonLocation->min_end;
      my $end_max   = $lastExonLocation->max_end;
      
      my $strand   = $firstExonLocation->strand;
      my $location = Bio::Location::Fuzzy->new (
						-min_start  => $start_min,
						-max_start  => $start_max,
						-min_end    => $end_min,
						-max_end    => $end_max,
						-strand     => $strand,
					       );
      return $location;
    }
    else {
      my $start  = $firstExonLocation->start;
      my $end    = $lastExonLocation->end;
      my $strand = $firstExonLocation->strand;
      
      my $location = Bio::Location::Simple->new (
						 -start  => $start,
						 -end    => $end,
						 -strand => $strand,
						);
      return $location;
    }
  }
  else {
    print STDERR "no location found into the locations array\n";
    return undef;
  }
}


1; # END OF MODULE #
