#!/usr/bin/perl 
package GUS::Common::Plugin::LoadAnnotatedSeqs;
@ISA = qw(GUS::PluginMgr::Plugin);

#########################################################
#                LoadAnnotatedSeqs.pm
#
#    Ed Robinson, Steve Fischer, Thomas Gan: December 2004
#  Mapping File Format: Deborah Pinney, John Iodice
#
#  Copyright: Board of Regents, University System of GA
#                      C. 2004 
#
#  Use: A file for taking inputs in a variety of files
#       processing them through BioPerl's Seq and
#       SeqFeature objects and inserting them into GUS
#       according to a mapping file.
#
#   **  DOCUMENTATION IS AT THE END OF THIS FILE  **
##########################################################

use strict 'vars';

######CPAN Perl Libraries
use XML::Simple;

######CBIL Libraries
use DBI;
use CBIL::Util::Disp;

## BioPerl Libraries
use Bio::SeqIO;
#use Bio:Seq::RichSeq;
use Bio::SeqFeature::Tools::Unflattener;
use Bio::Tools::SeqStats;
use Bio::SeqFeature::Generic;
use Bio::LocationI;

######GUS Objects
use GUS::PluginMgr::Plugin;
 #Primary Tables fot Sequence Information
 use GUS::Model::DoTS::NASequence; ## View -> NASequenceImp
 use GUS::Model::DoTS::ExternalNASequence; ## View -> NASequenceImp
 use GUS::Model::DoTS::NAEntry;
 use GUS::Model::DoTS::SecondaryAccs;
 use GUS::Model::DoTS::NALocation; #NEED TO IMPLEMENT THIS FOR EACH FEATURE!!!!!!!!!!!!!!!!!!!!!
 #tables for checking your parameters
 #tables called by special cases
  use GUS::Model::DoTS::NAGene;
  use GUS::Model::DoTS::NAProtein;
  use GUS::Model::DoTS::NAPrimaryTranscript;
  use GUS::Model::SRes::DbRef;
  use GUS::Model::DoTS::Organelle;
  use GUS::Model::DoTS::NAFeatureComment;
  ## many-to-many
  use GUS::Model::DoTS::NASequenceRef;
  use GUS::Model::DoTS::NASequenceOrganelle;
  use GUS::Model::DoTS::NASequenceKeyword;
  use GUS::Model::DoTS::NAFeatureNAGene;
  use GUS::Model::DoTS::NAFeatureNAPT;
  use GUS::Model::DoTS::NAFeatureNAProtein;
  use GUS::Model::DoTS::DbRefNAFeature;
  use GUS::Model::DoTS::DbRefNASequence;
  use GUS::Model::SRes::ExternalDatabaseKeyword;
  ## NAFeature and assoc. views called by the maps
    use GUS::Model::DoTS::NAFeatureImp;
    use GUS::Model::DoTS::NAFeature;
    use GUS::Model::DoTS::DNARegulatory;
    use GUS::Model::DoTS::DNAStructure;
    use GUS::Model::DoTS::STS;
    use GUS::Model::DoTS::GeneFeature;
    use GUS::Model::DoTS::RNAType;
    use GUS::Model::DoTS::Repeats;
    use GUS::Model::DoTS::Miscellaneous;
    use GUS::Model::DoTS::Immunoglobulin;
    use GUS::Model::DoTS::ProteinFeature;
    use GUS::Model::DoTS::SeqVariation;
    use GUS::Model::DoTS::RNAStructure;
    use GUS::Model::DoTS::Source;
    use GUS::Model::DoTS::Transcript;
    use GUS::Model::DoTS::ExonFeature;




############################################################ 
# Application Context
############################################################

sub new {
  my $class = shift;
  my $self = {};
  bless($self, $class);

  my $documentation = getDocumentation();

  my $args = getArgsDeclaration();

  $self->initialize({requiredDbVersion => {RAD3 => '3', Core => '3'},
             cvsRevision => '$Revision$',
             cvsTag => '$Name$',
             name => ref($self),
             revisionNotes => '',
             argsDeclaration => $args,
             documentation => $documentation
            });

  return ($self, $class);

}




###############################################################
#Main Routine
##############################################################

sub run{
  my $self = shift;
  my ($map, $extdbrel, $seqtype, $taxid, $datafile, $format) = getArguments();

# ----------------------------------------------------------
# Parse your input and load your data
# ----------------------------------------------------------

  #create your BioSeq object 
#  my $in = new Bio::SeqIO(-format=>$format, -file=>$datafile ); 

  # generate an Unflattener object
#  my $unflattener = Bio::SeqFeature::Tools::Unflattener->new;


  #process each seq in the BioSeq Object
#  foreach my $seq_in ($in->next_seq()) {          
#    my $na_seq = makeNASequence($seq_in, $extdbrel, $seqtype, $taxid);

#make parent, make child
#NaSequence addChild - > NaSequence

#Submit can call the object model which has these parent child relationships in it.

    #create unflattened features for this seq
#     my $out = Bio::SeqIO->new(-format=>'asciitree');
#       if ($self->getArg('format') eq 'genbank') {
#       $unflattener->unflatten_seq(-seq=>$seq_in,-use_magic=>1);
#       $out->write_seq($seq_in);}
         
         #process each feature tree 
#         foreach my $feat_tree ($seq_in->get_SeqFeatures()) {    
#              my @feat = MakeFeature($feat_tree, $map, $na_seq);   #HOW DO WE JOIN IT UP TO ITS NA ID

              #submit feature tree
#         }
 # }
  print "*** testing ***\n";
  return "short summary";

}

=cut

#####################################################################
#Sub-routines
#####################################################################

# ----------------------------------------------------------
# Make your sequence and call load features 
# ----------------------------------------------------------

sub makeNASequence{
#NEED TO HANDLE ANNOTATIONS, WE HAVEN'T DONE THAT HERE
  $my ($seqobj, $ExtDbRel, $SeqType, $TaxId) = @_;
#HOW DO QWE HANDLE PASSING AND ATTACHING TABLE PATHS

  my $gusSeq = $seqobj->getNewGusSequence();  #I'm *GUESSING* there is such a method, check with Steve
      $gusSeq->addChild(makeSequence($seqobj));  #I'm not sure if I am doing this right, need to see how these methods work.
      $gusSeq->addChild(makeNAEntry($seqobj));
      $gusSeq->addChild(makeSecACCs($seqobj));

return $gusSeq;

}



# ----------------------------------------------------------
# Make your Primary Sequence
# ----------------------------------------------------------

sub makeSequence {
  $my ($seqobj, $ExtDbRel, $SeqType, $TaxId) = @_;

     my $seqcount = Bio::Tools::SeqStats->count_monomers($seqobj);
     my $seqentry = {'source_id'=> $seqobj->accession_number(),
           'external_database_release_id' => $ExtDbRel, 
           'sequence_type_id' => $SeqType, 
           'taxon_id' => $TaxId,
           'name' => $seqobj->primary_id(),
           'description' => $seqobj->desc(),
           'sequence' => $seqobj->seq(),
           'sequence_version' => $seqobj->seq_version(),
           #'secondary_id' => $seqobj->seq_gi),   #I don't know if this is in the GUS::Model, may blow up!
           'a_count' => %$seqcount->{'a'},
           'c_count' => %$seqcount->{'c'},
           'g_count' => %$seqcount->{'g'},
           't_count' => %$seqcount->{'t'},
           'length' => $seqobj->length()    };
     my $path = GUS::Model::DoTS::ExternalNASequence;
     
  return ($path,$seqentry);
}


# ----------------------------------------------------------
# Make and NAEntry 
# ----------------------------------------------------------

sub makeNAEntry {
  my $seqobj = @_;

          my $naentry = {
		'source_id'=>$seqobj->accession_number(),
		'division'=>$seqobj->division(),
		'version'=>$seqobj->seq_version() };
          my $path = GUS::Model::DoTS::NAEntry;

  return ($path,$naentry);
}


# ----------------------------------------------------------
# Make your SecondaryACCs
# ----------------------------------------------------------
sub makeSecACCs {
#NEED TO INVOKE BIO::RICHSEQ AT SOME POINT TO GET SECONDARY ACCS ETC.

                my $accsentry = {'source_id'=> $seqobj->accession_number(),
			'secondary_accs'=> $seqobj->accession_number(),  #this is wrong, need to use Bio::RichSeq.
			'na_entry_id'=>$naid,
			'external_database_release_id'=>$args->{'ExtDbRel'} };
                my $path = GUS::Model::DoTS::SecondaryACCS;

return ($path,$accsentry);
}



# ----------------------------------------------------------
# Load your features 
# ----------------------------------------------------------

  #------------------------
  # Process Tree

sub makeFeature {
  my ($inputFeature, $map) = @_;   #DO WE EVEN NEED THE MAP HERE?!?!

  # map the immediate input feature into a gus feature
  my $gusFeature = &makeImmediateFeature($inputFeature, $map);

  # recurse through the children
  foreach $inputChildFeature ($inputFeature->get_SeqFeatures()) {
    my $gusChildFeature = makeFeature($inputChildFeature, $map);
    $gusFeature->addChild($gusChildFeature);
  }

  return $gusFeature;
}


  #------------------------
  # Make each feature-set

sub makeImmediateFeature {
  my ($inputFeature, $map) = @_;
  my $featureMapper = loadMap($inputFeature,$map);
  my $gusTable = getGusTable($featureMapper);
  #DON'T i HAVE TO SET IT UP WITH MY TABLE SOMEWHERE?????!!!!!!?????
  my $gusFeature = $featureMapper->getNewGusFeature();  #ask steve how this works

  $gusFeature->addChild(makeLocation($inputFeature,$inputFeature->strand()));

	foreach my $tag ($inputFeature->get_all_tags()) {
	  if (isSpecialCase($featureMapper,$tag)) { #if a special case
	    $gusFeature->addChild(makeSpecial($tag,$featureMapper,$inputFeature);  #I've got some questions in their section
	  } else {
	    my $gusAttrName = $featureMapper->getAttrName($tag);
	    my @tagValues = $inputFeature->get_tag_values($tag);
		if (scalar(@tagValues) != 1) {
		  die "invalid tag: more than one value\n"; }
	  $gusFeature->setAttribute($gusAttrName, $tagValues[0]);
	 }
       }

return $gusFeature;
}



# ----------------------------------------------------------
# Make Your Feature Location
# ----------------------------------------------------------

sub makeLocation {
my $feature = shift;
my $is_reversed = shift;

  my $f_location = Bio::LocationI->new($feature)
    my $min_start = $f_location->min_start();  
    my $max_start = $f_location->max_start();  
    my $min_end = $f_location->min_end();  
    my $max_end = $f_location->max_end();  
    my $start_pos_type = $f_location->start_pos_type();  
    my $end_pos_type = $f_location->end_pos_type();  
    my $location_type = $f_location->location_type();  
    my $start = $f_location->start();  
    my $end = $f_location->end();  

#Look at differences in values so we do logic according to GUS standards.
#NEED SOME LOGIC HERE

#Do I need to add a table to this so we know which table to use?
#NOW, JUST BUILD IT UP LIKE WE HARDCODED THE SEQUENCE
my $location = {'StartMin'=>$min_start,
  'StartMax'=>$max_start,
  'EndMin'=>$min_end,
  'EndMax'=>$max_end,
  #'LocOrder'=>
  'IsReveresed'=>$is_reversed
  #'IsExcluded'=>
  'LocationType'=>$location_type
  'Remark'=>$start_pos_type." - ".$end_pos_type
  };


return $location;
}



# ----------------------------------------------------------
# Load your data map
# ----------------------------------------------------------

sub loadMap{  
  my ($inputFeature, $map) = @_;
  my $simple = XML::Simple->new();
  my $mapping = $simple->XMLin($map, forcearray=>['feature']);
  my $mapHash = {};;

    my $featureMapper = $mapping->{'feature'}->{$inputFeature->primary_tag()}->{'qualifier'};

  return $featureMapper;
}



# ----------------------------------------------------------
# Submit something to GUS
# ----------------------------------------------------------

sub submitToGus {
my $path = shift;
my $obj = shift;

  #NEED DUPE AND UPDATE CHECKING/SUBMISSION HERE
  my $entry = $path->new($obj); 
  $entry->submit();
  my $result = $entry->getId();
}




# ----------------------------------------------------------
# Get GUS field for a tag name
# ----------------------------------------------------------

sub getAttrName{

  my $gusAttrName = $featureMapper->{$tag};

  if ($gusAttrName = '') {$gusAttrName = $tag;}

return $gusAttrName;
}



# ----------------------------------------------------------
# Test for special cases
# ----------------------------------------------------------

sub getGusTable {
  my $featureMapper = @_;

  $myGusTable = $featureMapper->{'table'}; 

  return $myGusTable;
}




# ----------------------------------------------------------
# Test for special cases
# ----------------------------------------------------------

sub isSpecialCase {
  my ($featureMapper, $tag) = @_;

  my $specialcase = $featureMapper->{'quailifier'}->{$tag}->{'specialcase'}; 

  return $specialcase;
}



# ----------------------------------------------------------
# Handler for special cases
# ----------------------------------------------------------

sub specialCase {
  my ($tag, $featureMapper, $inputFeature) = @_;

  my $specialcase = isSpecialCase($tag,$featureMapper);

  my $value = 
	    my @tagValues = $inputFeature->get_tag_values($tag);
		if (scalar(@tagValues) != 1) {
		  die "invalid tag: more than one value\n"; }
	  $gusFeature->setAttribute($gusAttrName, $tagValues[0]);
	 }

#WARNING: Only specialcases needed for Crypto DB have been added so far
if ($specialcase eq 'dbxref') { my $special =  buildDBXref($tag,$value); }
if ($specialcase eq 'product') { my $special = buildProtein($tag,$value); }


return $special;
}


sub buildDbXRef {
 my ($tag, $value) = @_; 
  my $path = GUS::Model::DoTS::DbRefNAFeature->new();


#get your ext_db_rel_ids for these five databases: this is a pisser


#oh crap, I need the ref as the f_k to go into my seq table.
   #this is the reverse of things since THIS table is the parent_id and not the other way around.
#what about dupe checking?

  my $v = $q->getValue();
  my $id = &getDbXRefId($v);
  $o->setDbRefId($id);
  ## If DbRef is outside of Genbank, then link directly to sequence
  if (!($v =~ /taxon|GI|pseudo|dbSTS|dbEST/i)) {
    my $o2 = GUS::Model::DoTS::DbRefNASequence->new();
    $o2->setDbRefId($id);
    $seq->addChild($o2);
  }
  return $o;
}


sub buildProtein {
  my ($tag, $value) = @_;
  #my $n = substr($q->getValue(),0,300);
  #my $p = &getNaProteinId($n);
  my $path = GUS::Model::DoTS::NAFeatureNAProtein->new();

#do I do the submit here and return the values as a F_K to the seqobj
  return $o;
}

sub getNaProteinId {
  my $n = shift;
  if (!$NaProteinCache{$n}) {
    my $p = GUS::Model::DoTS::NAProtein->new({'name' => $n});
    unless ($p->retrieveFromDB()){
      $p->set('is_verified', 0);
      $p->submit();
    }
    $NaProteinCache{$n} = $p->getId();
  }
  return $NaProteinCache{$n};
}




}

=cut


# ----------------------------------------------------------
# Load Arguments
# ----------------------------------------------------------

sub getArgsDeclaration {
  my $argsDeclaration  =
    [
     fileArg({name => 'map_xml',
	      descr => 'XML file with Mapping of Sequence Feature from BioPerl to GUS',
	      constraintFunc=> undef,
	      reqd  => 1,
	      isList => 0,
	      mustExist => 1,
	      format => 'XML',
	     }),

     fileArg({name => 'data_file',
	      descr => 'text file with GenBank records of sequence annotation data',
	      constraintFunc=> undef,
	      reqd  => 1,
	      isList => 0,
	      mustExist => 1,
	      format => 'genbank',
	     }),

     integerArg({name => 'db_rls_id',
		 descr => 'external database release id for the data',
		 constraintFunc=> undef,
		 reqd  => 1,
		 isList => 0
		}),

     integerArg({name => 'test_number',
		 descr => 'number of entries to do test on',
		 constraintFunc=> undef,
		 reqd  => 0,
		 isList => 0
		}),

     booleanArg({name => 'is_update_mode',
		 descr => 'whether this is an update mode',
		 constraintFunc=> undef,
		 reqd  => 0,
		 isList => 0,
		 default => 0,
		}),
    ];

  return $argsDeclaration;
}


# ----------------------------------------------------------
# Documentation
# ----------------------------------------------------------

sub getDocumentation {

my $description = <<NOTES;
 Watch more star trek re-runs.  You can learn everything you need
 to know about computer engineering from Spock and Scotty.
NOTES

my $purpose = <<PURPOSE;
 Plate of shrimp.
PURPOSE

my $purposeBrief = <<PURPOSEBRIEF;
 Plate of shrimp.
PURPOSEBRIEF

my $syntax = <<SYNTAX;
 Why booze is so expensive in GA.
SYNTAX

my $notes = <<NOTES;
 Homer Simpson
NOTES

my $tablesAffected = <<AFFECT;
 Tables deficated
AFFECT

my $tablesDependedOn = <<TABD;
 Tables dumped
TABD

my $howToRestart = <<RESTART;
 Flick the power switch
RESTART

my $failureCases = <<FAIL;
 Delta Delta Delta can we help ya help ya help ya
FAIL

  my $documentation = {purpose=>$purpose, purposeBrief=>$purposeBrief,tablesAffected=>$tablesAffected,tablesDependedOn=>$tablesDependedOn,howToRestart=>$howToRestart,failureCases=>$failureCases,notes=>$notes};

return ($documentation);

}

