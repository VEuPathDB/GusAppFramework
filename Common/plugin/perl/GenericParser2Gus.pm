# ----------------------------------------------------------
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
# ----------------------------------------------------------

#
# build GUS install -append ; ga GUS::Common::Plugin::GenericParser2Gus --filetype=embl --filepath=/nfs/team81/pjm/temp/c212_0 -sequencetype=ds-DNA |& less
# 

package GUS::Common::Plugin::GenericParser2Gus;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
#use DBI;
use Data::Dumper;
use Benchmark;
use FileHandle;

#################################
# Load the bioperl2Gus module
#################################
use GUS::Common::Bioperl2Gus;


use Bio::Location::Simple;
use Bio::SeqIO;

# BioPSU
use Bio::PSU::IO::BufferFH;
use IO::File;

my $logdir = "/nfs/pathdb/logs/upload"; # HARD CODING IS BAD - FIXME

# OUTPUT_AUTOFLUSH forced
$| = 1;
my $debug = 0;

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
  print "Testing on ",$self->getArgs->{'testnumber'},"\n"
      if $self->getArgs->{'testnumber'};

  if ($self->getCla->{'debug'}) {
      $debug = 1;
      print "***DEBUGGING ON***\n";
  }

  # Is this line still needed???
  #eval("require Objects::GUSdev::".$self->getArgs->{seq_table_name});

  my $path         = $self->getArgs->{filepath};
  my $fileType     = $self->getArgs->{filetype};
  my $sequenceType = $self->getArgs->{sequencetype};
  #my $db           = $self->getArgs->{ db }; # These 2 never used?
  #my $dbh          = $db->getDbHandle();
  
  my $log          = FileHandle->new( '>'. $self->getArgs->{log} );

  print STDERR "Dumping log: " . Dumper ($self->getArgs->{log}) . "\n";

  $log->print("FILE: ", $self->getArgs->{ filepath }, "\n");

  my $verbose      = $self->getArgs->{'verbose'};
  my $n            = 0;
  my $update_count = 0;
  my $insert_count = 0;
  
  # Load the Bioperl2Gusdev converter
  
  my $bioperl2Gus =
    GUS::Common::Bioperl2Gus->new (
                                   sequenceType => $sequenceType,
                                   debug        => $debug,
                                   );
  # parsing the file(s)
  
  my @bioperl_seqs = $self->parseSequenceFiles ($path, $fileType);

  # process the bioperl sequence objects

  foreach my $bioperl_sequence (@bioperl_seqs) {
    print "processing bioperl sequence, " . $bioperl_sequence->display_id . "...\n";
    $bioperl2Gus->setBioperlSequence ($bioperl_sequence);

    # Check if sequence is already in the database

    my $gus_sequence = $bioperl2Gus->getGusSequenceFromDB ($bioperl_sequence);

    if (not defined ($gus_sequence)) {

      print STDERR "sequence not in GUS yet\n";

      $gus_sequence = $bioperl2Gus->buildNASequence;
      
      if (defined $gus_sequence) {
	print STDERR "GUS Sequence creation done\n";
	
	if ($verbose) {
	  print $gus_sequence->toXML();
	}
	
	$gus_sequence->submit();
	$log->print( "INSERTED: ", $gus_sequence->getName(), ";\n");
	$insert_count++;
      }
      else {
	print STDERR "GUS Sequence creation failed!!\n";
	next;
      }
    }
    else {
      print STDERR "GUS Sequence already in the database!\n";
    }
    
    my @bioperl_features = $bioperl_sequence->all_SeqFeatures;
    foreach my $bioperl_feature (@bioperl_features) {
      print "processing " . $bioperl_feature->primary_tag . " bioperl feature...\n";
      $bioperl2Gus->setBioperlFeature ($bioperl_feature);
      my @gus_objects = ();
      
      ##################
      # process a CDS
      ##

      if ($bioperl_feature->primary_tag =~ /CDS/) {
	# checking if the gene is already in the database

	#########################
	# NEW NAMING CONVENTION
	#########################
	
	my $systematic_id = undef;
	if ($bioperl_feature->has_tag ('systematic_id')) {
	  my @values = $bioperl_feature->each_tag_value ('systematic_id');
	  
	  print STDERR "check if unique name always the first one !! - " . join (', ', @values) . "\n";
	  
	  $systematic_id  = $values[0];
	}
	elsif ($bioperl_feature->has_tag ('temporary_systematic_id')) {
	  my @systematic_ids = $bioperl_feature->each_tag_value ('temporary_systematic_id');
	  $systematic_id = $systematic_ids[0];
	}
	else {
	  print STDERR "ERROR - no systematic or temporary systematic id set up!!!\n";
	}

	if (defined $systematic_id) {
	  
	  my $gf    = GUS::Model::DoTS::GeneFeature->new({'standard_name'=> $systematic_id});
	  my $is_in = $gf->retrieveFromDB();
	  my $gene_type = "protein coding";
	  
	  if ($bioperl_feature->has_tag ('pseudo')) {
	    $gene_type = "pseudogene";
	    print STDERR "parsing a pseudogene ...!\n";
	  }
	  else {
	    print STDERR "parsing a protein coding gene ...!\n";
	  }
	  
	  if ($is_in) {
	    $log->print("File, $path, not processed, as the gene, $systematic_id, is already in the database\n");
	    print STDERR "\nGene '$systematic_id' already in the database\n";    
	  }
	  else {
	    print STDERR "\nGene '$systematic_id' is being added into the database...\n";
	    
	    my @gus_objects = $self->processGene ($bioperl2Gus, $gene_type);
	    print STDERR "gus objects done\n";
	    
	    # commit the GUS objects associated with the CDS bioperl feature object
	    
	    foreach my $object (@gus_objects) {
              #print STDERR "Object type is '", ref($object), "', \$object = $object\n";

              unless (defined $object) {
                  print STDERR "\n*** WARNING: undef value returned for an object;\n\n";
                  next;
              }
              elsif (ref($object) eq 'HASH') {
                print STDERR "\n*** ERROR: this is not a class;\n", Dumper($object), "\n";
                next;
              }

	      if ($verbose) {
		print $object->toXML();
	      }
	      
	      $object->submit();
              $log->print( "object INSERTED (", ref($object),")\n");

	      $insert_count++;

              # Can only link GOAssociation to a Protein when it has a row_id, hence been submitted
              #
              if (ref($object) eq 'GUS::Model::DoTS::Protein') {
                  print STDERR"Attempting to insert GO objects\n";
                  $insert_count += $self->buildAndSubmitGO_Objects($log, $bioperl2Gus, $object);
              }

	    } # end commiting GUS gene objects
	  }
	}
	else {
	  print STDERR "ERROR - can't find any (temporary) systematic id tag for current bioperl feature!!!\n";
	  print STDERR "feature not processed!\n";
	}
      } # end processing CDS bioperl feature
      
      ##################
      # Process tRNAs
      ##################
      
      elsif ($bioperl_feature->primary_tag =~ /tRNA/) {
	# checking if the gene is already in the database
	
	#########################
	# NEW NAMING CONVENTION
	#########################
	
	my $systematic_id = undef;
	if ($bioperl_feature->has_tag ('systematic_id')) {
	  my @values = $bioperl_feature->each_tag_value ('systematic_id');
	  
	  print STDERR "check if unique name always the first one !! - " . join (', ', @values) . "\n";
	  
	  $systematic_id  = $values[0];
	}
	elsif ($bioperl_feature->has_tag ('temporary_systematic_id')) {
	  my @systematic_ids = $bioperl_feature->each_tag_value ('temporary_systematic_id');
	  $systematic_id = $systematic_ids[0];
	}
	else {
	  print STDERR "ERROR - no systematic or temporary systematic id set up!!!\n";
	}

	if (defined $systematic_id) {
	  
	  my $gf    = GUS::Model::DoTS::GeneFeature->new({'standard_name'=> $systematic_id});
	  my $is_in = $gf->retrieveFromDB();
	  my $gene_type = "tRNA";
	  
	  if ($bioperl_feature->has_tag ('pseudo')) {
	    $gene_type = "pseudogene";
	    print STDERR "parsing a pseudogene ...!\n";
	  }
	  else {
	    print STDERR "parsing a tRNA gene ...!\n";
	  }
	  
	  if ($is_in) {
	    $log->print("File, $path, not processed, as the gene, $systematic_id, is already in the database\n");
	    print STDERR "gene, $systematic_id, already in the database\n";    
	  }
	  else {
	    print STDERR "gene, $systematic_id, is being added into the database...\n";  	    
	    print STDERR "gus objects generation ...\n";
	    
	    my @gus_objects = $self->process_tRNA ($bioperl2Gus, $gene_type);
	    print STDERR "gus objects done\n";
	    
	    # commit the GUS objects associated with the CDS bioperl feature object
	    
	    foreach my $object (@gus_objects) {
	      if ($verbose) {
		print $object->toXML();
	      }
	      
	      $object->submit();
              $log->print( "object INSERTED (", ref($object),")\n");


	      $insert_count++;
	      
	    } # end commit GUS tRNA gene objects
	  }
	}
	else {
	  print STDERR "ERROR - can't find any (temporary) systematic_id tag for current bioperl feature!!!\n";
	  print STDERR "feature not processed!\n";
	}
      } # end processing tRNAs feature

      #################################
      # elsif rRNA feature ...
      ###
      
      elsif ($bioperl_feature->primary_tag =~ /rRNA/) {
	# checking if the gene is already in the database
	
	#########################
	# NEW NAMING CONVENTION
	#########################
	
	my $systematic_id = undef;
	if ($bioperl_feature->has_tag ('systematic_id')) {
	  my @values = $bioperl_feature->each_tag_value ('systematic_id');
	  
	  print STDERR "check if unique name always the first one !! - " . join (', ', @values) . "\n";
	  
	  $systematic_id  = $values[0];
	}
	elsif ($bioperl_feature->has_tag ('temporary_systematic_id')) {
	  my @systematic_ids = $bioperl_feature->each_tag_value ('temporary_systematic_id');
	  $systematic_id = $systematic_ids[0];
	}
	else {
	  print STDERR "ERROR - no systematic or temporary systematic id set up!!!\n";
	}
	
	if (defined $systematic_id) {
	  
	  my $gf    = GUS::Model::DoTS::GeneFeature->new({'standard_name'=> $systematic_id});
	  my $is_in = $gf->retrieveFromDB();
	  my $gene_type = "rRNA";
	  
	  if ($bioperl_feature->has_tag ('pseudo')) {
	    $gene_type = "pseudogene";
	    print STDERR "parsing a pseudogene ...!\n";
	  }
	  else {
	    print STDERR "parsing a rRNA gene ...!\n";
	  }

	  if ($is_in) {
	    $log->print("File, $path, not processed, as the gene, $systematic_id, is already in the database\n");
	    print STDERR "gene, $systematic_id, already in the database\n";    
	  }
	  else {
	    print STDERR "gene, $systematic_id, is being added into the database...\n";  	    
	    print STDERR "gus objects generation ...\n";
	    
	    my @gus_objects = $self->process_rRNA ($bioperl2Gus, $gene_type);
	    print STDERR "gus objects done\n";
	    
	    # commit the GUS objects associated with the CDS bioperl feature object
	    
	    foreach my $object (@gus_objects) {
	      if ($verbose) {
		print $object->toXML();
	      }
	      
	      $object->submit();
              $log->print( "object INSERTED (", ref($object),")\n");

	      $insert_count++;
	      
	    } # end commit GUS rRNA gene objects
	  }
	}
	else {
	  print STDERR "ERROR - can't find any (temporary) systematic_id tag for current bioperl feature!!\n";
	  print STDERR "feature not processed!!!\n";
	}
      }

      #################################
      # elsif mRNA feature ...
      # ie ESTs
      ###
      
      elsif ($bioperl_feature->primary_tag =~ /mRNA/) {
	# checking if the gene is already in the database
	
	#########################
	# NEW NAMING CONVENTION
	#########################
	
	my $systematic_id = undef;
	if ($bioperl_feature->has_tag ('systematic_id')) {
	  my @values = $bioperl_feature->each_tag_value ('systematic_id');
	  
	  print STDERR "check if unique name always the first one !! - " . join (', ', @values) . "\n";
	  
	  $systematic_id  = $values[0];
	}
	elsif ($bioperl_feature->has_tag ('temporary_systematic_id')) {
	  my @systematic_ids = $bioperl_feature->each_tag_value ('temporary_systematic_id');
	  $systematic_id = $systematic_ids[0];
	}
	else {
	  print STDERR "ERROR - no systematic or temporary systematic id set up!!!\n";
	}
	
	if (defined $systematic_id) {
	  
	  my $gf    = GUS::Model::DoTS::GeneFeature->new({'standard_name'=> $systematic_id});
	  my $is_in = $gf->retrieveFromDB();
	  my $gene_type = "protein coding";
	  
	  if ($bioperl_feature->has_tag ('pseudo')) {
	    $gene_type = "pseudogene";
	    print STDERR "parsing a pseudogene ...!\n";
	  }
	  else {
	    print STDERR "parsing a protein coding gene - attached to a mRNA sequence ...!\n";
	  }

	  if ($is_in) {
	    $log->print("File, $path, not processed, as the gene, $systematic_id, is already in the database\n");
	    print STDERR "gene, $systematic_id, already in the database\n";    
	  }
	  else {
	    print STDERR "gene, $systematic_id, is being added into the database...\n";  	    
	    print STDERR "gus objects generation ...\n";
	    
	    my @gus_objects = $self->process_mRNA ($bioperl2Gus, $gene_type);
	    print STDERR "gus objects done\n";
	    
	    # commit the GUS objects associated with the CDS bioperl feature object
	    
	    foreach my $object (@gus_objects) {
	      if ($verbose) {
		print $object->toXML();
	      }
	      
	      $object->submit();
	      $log->print( "object INSERTED (", ref($object),")\n");

	      $insert_count++;
	      
	    } # end commit GUS mRNA gene objects
	  }
	}
	else {
	  print STDERR "ERROR - can't find any (temporary) systematic_id tag for current bioperl feature!!\n";
	  print STDERR "feature not processed!!!\n";
	}


      }
      #################################
      # elsif feature is of type ...
      # ...
      ###

      # Uncaching stuff here for the current sequence and attached features
      # Uncaching the gus sequence object, does it also uncache the attached
      #features
      $self->undefPointerCache

    } # next bioperl feature object process

  } # next bioperl sequence object process

  ## Close DBI handle
  #$self->getQueryHandle()->closeQueryHandle();
  #$self->{'self_inv'}->closeQueryHandle();

  my $t2 = Benchmark->new ();
  print  STDERR "\nTotal: ", timestr (timediff ($t2, $t1)), "\n";
  $log->print( "Total: timestr (timediff ($t2, $t1)\n");

  return "Objects inserted= $insert_count;  updated= $update_count; total #(inserted::updated::deleted)=" . $self->getSelfInv->getTotalInserts() . "::" . $self->getSelfInv->getTotalUpdates() . "::" . $self->getSelfInv->getTotalDeletes() .  "\n";

}


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


sub parseOneSequenceFile {
  my ($self, $fileName, $fileType) = @_;
  
  print STDERR "$fileType file to parse, $fileName...\n";

  # Basic Seq factory object - direct stream from file
  
  if ($fileType ne "embl") {

    my $in  = Bio::SeqIO->new('-file'   => $fileName,
			      '-format' => $fileType);
    return $in->next_seq();

  }
  else {
    
    # more complex seq factory - stream the file into a temporary buffer where the some lines are filtered
    # e.g. if DR line or XX line before ID line, get rid of them as bioperl expects embl files to start with an ID line !!
    
    my $biopsu_fh  = Bio::PSU::IO::BufferFH->new(-file => $fileName);
    
    my $line = $biopsu_fh->buffered_read;
    if ($line =~ /^ID/) {
      # the file starts with an ID line which is fine !!

      print STDERR "ID line fine!!!\n";
      ## process it normally

      # undef $biopsu_fh;
      #my $in  = Bio::SeqIO->new('-file'   => $fileName,
      #				'-format' => $fileType);
      #return $in->next_seq();

      my $tmp_fh = IO::File->new_tmpfile() or die "can't create a temporary file, $!\n";
      print $tmp_fh "$line\n";
      my $has_FH = 0;
      
      while ($line = $biopsu_fh->buffered_read) {
	if ($line =~ /^FH/) {
	  $has_FH = 1;
	}
	if ($line =~ /^FT   source/) {
	  print STDERR "source feature found, $line!!\n";
	
	  # if not FH line present, add it just before the source feature
	  if (! $has_FH) {
	    
	    print STDERR "no FH line, adding it!\n";

	    print $tmp_fh "FH   Key             Location/Qualifiers\n";
	    #print $tmp_fh "FH\n";
	  }
	  
	  # add 'FT   source' line
	  print $tmp_fh "$line\n";
	}
	else {
	  print $tmp_fh "$line\n";
	}
      }

      undef $biopsu_fh;
      seek ($tmp_fh, 0, 0);
      my $sembl    = Bio::SeqIO->new('-fh'   => $tmp_fh,
				     '-format' => 'embl');
      
      return $sembl->next_seq();
      
    }
    else {
      # doesn't start with an ID line
      # filter the lines until ID line
      
      my $tmp_fh = IO::File->new_tmpfile() or die "can't create a temporary file, $!\n";

      print STDERR "file doesn't start with an ID line!!!\n";
      
      while (defined $line && not ($line =~ /^ID/)) {
	$line = $biopsu_fh->buffered_read;
      }
      
      if (defined $line) {
	print STDERR "got it!! - line: $line\n";
	
	# Finally found the ID line!!
	print $tmp_fh "$line\n";

	my $has_FH = 0;
	
	while ($line = $biopsu_fh->buffered_read) {
	  if ($line =~ /^FH/) {
	    $has_FH = 1;
	  }
	  if ($line =~ /^FT   source/) {
	    # if not FH line present, add it just before the source feature
	    if (! $has_FH) {
	      
	      print STDERR "no FH line, adding it!\n";
	      
	      print $tmp_fh "FH   Key             Location/Qualifiers\n";
	      #print $tmp_fh "FH\n";
	    }

	    # add 'FT   source' line
	    print $tmp_fh "$line\n";
	  }
	  else {
	    print $tmp_fh "$line\n";
	  }
	}
      }
      else {
	print STDERR "no ID line found in embl file, $fileName!!!\n";
      }
      
      undef $biopsu_fh;
      seek ($tmp_fh, 0, 0);
      my $sembl    = Bio::SeqIO->new('-fh'   => $tmp_fh,
				     '-format' => 'embl');
      
      return $sembl->next_seq();
      
    }
  }
}

# @param a Bioperl2Gusdev converter object
# @return a set of GUS feature objects

sub processGene {
  my ($self, $bioperl2Gus, $gene_type) = @_;

  my @gus_objects = $self->buildFeatureObjects ($bioperl2Gus, $gene_type);  
  return @gus_objects;
}

sub process_tRNA {
  my ($self, $bioperl2Gus, $gene_type) = @_;

  my @gus_objects = $self->buildFeatureObjects ($bioperl2Gus, $gene_type);
  return @gus_objects;
}

sub process_rRNA {
  my ($self, $bioperl2Gus, $gene_type) = @_;

  my @gus_objects = $self->buildFeatureObjects ($bioperl2Gus, $gene_type);
  return @gus_objects;
}

sub process_mRNA {
  my ($self, $bioperl2Gus, $gene_type) = @_;

  my @gus_objects = $self->buildFeatureObjects ($bioperl2Gus, $gene_type);
  return @gus_objects;
}

sub buildFeatureObjects {
  my ($self, $bioperl2Gus, $gene_type) = @_;
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

  my $number_of_exons = @bioperl_locations;

  # GeneFeature object
  #
  my ($gf, @gus_gf_notes_objects) = $bioperl2Gus->buildGeneFeature ($number_of_exons, $gene_type, $partial);
  push (@gus_objects, @gus_gf_notes_objects);

  # print STDERR @bioperl_locations . " exons for gene, " . $gf->getStandardName . "\n";
  # print STDERR "Dumping bioperl locations array: " . Dumper (@bioperl_locations) . "\n";

  # NALocation object related to the Gene

 
  my $bioperl_geneLocation = $self->getGeneLocation (@bioperl_locations);
  my $gus_naLocation_gf = $bioperl2Gus->buildNALocation ($gf, $bioperl_geneLocation);
  push (@gus_objects, $gus_naLocation_gf);

  ###############################################################
  # If it's a pseudogene, generate only the gene feature object
  ###############################################################

  if ($gene_type =~ /pseudogene/i) {
    return @gus_objects;
  }

  print STDERR "*** Gene was not a pseudogene, it is a $gene_type\n"; # DEBUG

  # SplicedNASequence associated with the RNAFeature

  if ($debug) {
    print STDERR "adding spliced na sequence for gene, " . $gf->getName() . "...\n";
  }

  my $snas = $bioperl2Gus->buildSplicedNASequence ();

  if (defined $snas) {
    push (@gus_objects, $snas);
  }
  else {
    print STDERR "spliced sequence object not defined !!!! - not added !!!\n";
  }

  # RNAFeature - set $snas (SplicedNASequence) to be the parent
  #
  my $rnaf = $bioperl2Gus->buildRNAFeature ($gf, $snas, $number_of_exons);
  push (@gus_objects, $rnaf);

  # NALocation object related to the RNA

  my $gus_naLocation_rf = $bioperl2Gus->buildNALocation ($rnaf, $bioperl_geneLocation);
  push (@gus_objects, $gus_naLocation_rf);

  # ExonFeatures

  # useful ????
  # my $coding_start   = 0;
  # my $coding_end     = 0;

  my $i  = 1;

  foreach my $bioperl_location (@bioperl_locations) {
    my $is_initial_exon = 0;
    my $is_final_exon   = 0;

    if ($i == 1) {
      $is_initial_exon = 1;
    }
    if ($i == $number_of_exons) {
      $is_final_exon = 1;
    }

    my $ef = $bioperl2Gus->buildExonFeature ($gf, $is_initial_exon, $is_final_exon, $i);
    push (@gus_objects, $ef);

    my $gus_naLocation_ef = $bioperl2Gus->buildNALocation ($ef, $bioperl_location);    
    push (@gus_objects, $gus_naLocation_ef);
    
    # RNAFeatureExon foreach ExonFeature
    
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
  
  # TranslatedAASequence
  
  # HOW TO GET THE TRANSLATION ????????????????
  
  my $aa_seq = $bioperl2Gus->buildTranslatedAASequence ($gf);
  push (@gus_objects, $aa_seq);
  
  # The Protein Feature object as both a TranslatedAAFeature and a ProteinFeature
  # ProteinFeature stores the EC number

  # to do : build NALocation objects attached to the ProteinFeature object

  my ($aa_feature_protein, $aa_feature_translated) = $bioperl2Gus->buildProteinFeature ($rnaf, $aa_seq);
  push (@gus_objects, $aa_feature_protein);
  push (@gus_objects, $aa_feature_translated);

  my $start  = 1;
  my $end    = length ($aa_seq->getSequence());
  # no aa sequence => end = 1
  $end = 1;

  my $bioperl_aaLocation = Bio::Location::Simple->new (
						       -start  => $start,
						       -end    => $end,
						       -strand => 1,
						      );

  my $gus_aaLocation = $bioperl2Gus->buildAALocation ($aa_feature_protein, $bioperl_aaLocation);
  push (@gus_objects, $gus_aaLocation);

  # AAFeatures and their location object
  # e.g. SignalP ...

  my $gene_name = $gf->getName;
  my @aafs = $bioperl2Gus->buildAAFeatures ($aa_seq, $gene_name);
  push (@gus_objects, @aafs);

  my @gus_CentralDogma_objects =
      $self->buildCentralDogmaObjects ($bioperl2Gus, $gf, $rnaf,
                                       $aa_feature_protein, $aa_seq,
                                       $gene_type);
  push (@gus_objects, @gus_CentralDogma_objects);
  
  return @gus_objects;
}


sub buildCentralDogmaObjects {
  my ($self, $bioperl2Gus, $gf, $rnaf, $aa_feature_protein, $aa_seq, $gene_type) = @_;

  my @central_dogma_objects = ();

  # Gene object
  #

  my ($gene_object, @gene_synonyms) = $bioperl2Gus->buildGene ($gf);
  push (@central_dogma_objects, $gene_object);
  push (@central_dogma_objects, @gene_synonyms);

  # GeneInstance Object, links Gene to GeneFeature
  my $geneSequence = $bioperl2Gus->buildGeneInstance ($gene_object, $gf);
  push (@central_dogma_objects, $geneSequence);
 
  if ($gene_type =~ /pseudogene/i) {
    return @central_dogma_objects;
  }

  # build RNA object
  #

  my $rna_object = $bioperl2Gus->buildRNA ($gene_object);
  push (@central_dogma_objects, $rna_object);

  my $rnaSequence = $bioperl2Gus->buildRNAInstance ($rna_object, $rnaf, $gene_type);
  push (@central_dogma_objects, $rnaSequence);

  if ($gene_type =~ /RNA/) {
    return @central_dogma_objects;
  }

  # build protein object
  #

  my $protein_object = $bioperl2Gus->buildProtein ($rna_object, $aa_seq, $gf);
  push (@central_dogma_objects, $protein_object);
  
  my $proteinSequence = $bioperl2Gus->buildProteinInstance ($protein_object, $aa_feature_protein);
  push (@central_dogma_objects, $proteinSequence);

  # GO Functional Classification Objects

  #my @GO_Objects = $self->buildGO_Objects ($bioperl2Gus, $protein_object, $rna_object);
  #push (@central_dogma_objects, @GO_Objects);

  return @central_dogma_objects;
}

################################################################################
# This has to be called after the protein/RNA object has been created so we can
# use its row_id value in the GOAssociation - an object no yet submitted will not
# have a value.
#
# Also note: all GO objects will have been submitted by the method, no need to
# submit again in this method. The row_id would have been required when linking
# tables together.
#

sub buildAndSubmitGO_Objects {
    my ($self, $log, $bioperl2Gus, $object) = @_;

    my $dbh        = $self->getQueryHandle();
    my @go_objects = ();

    push @go_objects, $bioperl2Gus->buildGO_aspectAssociation($dbh, 'GO_process',  $object);
    push @go_objects, $bioperl2Gus->buildGO_aspectAssociation($dbh, 'GO_component',$object);
    push @go_objects, $bioperl2Gus->buildGO_aspectAssociation($dbh, 'GO_function', $object);
    
    push @go_objects, $bioperl2Gus->buildGOAssociations($dbh, $object); # /GO=""

    print STDERR "GO objects submitted = ", scalar(@go_objects), "\n";

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

1;
