
package GUS::Common::Plugin::AssembliesWithflCD;

@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
use GUS::Model::DoTS::Assembly;
use GUS::ObjRelP::DbiDatabase;
use GUS::Model::DoTS::ExternalNASequence;
use GUS::Model::DoTS::Evidence;
use GUS::Model::Core::AlgorithmInvocation;

use GUS::Model::DoTS::TranslatedAAFeature;




$| = 1;

#JM This plugin is only in testing phase 12/11/03
# ----------------------------------------------------------------------
# create and initialize new plugin instance.

sub new {
  my ($class) = @_;

  my $self = {};
  bless($self, $class);

  my $usage = 'mark Assemblies as coding for full length protein must include initial Met';

  my $easycsp =
    [
     { h => 'number of iterations for testing',
       t => 'int',
       o => 'testnumber',
     },



         ];

  $self->initialize({requiredDbVersion => {},
                     cvsRevision => '$Revision$', # cvs fills this in!
                     cvsTag => '$Name$', # cvs fills this in!
                     name => ref($self),
                     revisionNotes => 'make consistent with GUS 3.0',
                     easyCspOptions => $easycsp,
                     usage => $usage
                 });

  return $self;

}



# ----------------------------------------------------------------------
# run

sub run {
  my $self   = shift;
  print "Testing on Assembly $self->getArgs->{'testnumber'}\n" if $self->getArgs->{'testnumber'};

  #can add new log ability  $self->logCommit();
  #move out external_database_release_id put as cla external_database_release_id = $self->getArgs->{'external_database_release_id'}
  #NOTE FOR TESTING taxon set to human only FOR THIS Query also check for rownum


  my $stmt1 = $self->getQueryHandle()->prepareAndExecute("select distinct a.na_sequence_id, eas.source_id from dots.externalNAsequence eas,dots.assemblysequence aseq, dots.assembly a where eas.external_database_release_id = 992 and eas.na_sequence_id = aseq.na_sequence_id and aseq.assembly_na_sequence_id = a.na_sequence_id and a.taxon_id = 8 and rownum < 5");

  my $stmt2 = $self->getQueryHandle()->prepareAndExecute("select distinct a.na_sequence_id from dots.externalNAsequence eas, dots.assemblysequence aseq, dots.assembly a where eas.na_sequence_id = aseq.na_sequence_id and aseq.assembly_na_sequence_id = a.na_sequence_id and eas.external_database_release_id = 992 and a.full_length_CDS = 1 and a.taxon_id = 8");

  my $stmt3 = $self->getQueryHandle()->prepareAndExecute("select target_id from dots.evidence where attribute_name = 'full_length_CDS'");

  my $stmt4 = $self->getQueryHandle()->prepareAndExecute("select distinct a.na_sequence_id from dots.assembly a where a.full_length_CDS = 1 and a.taxon_id = 8 minus select distinct a.na_sequence_id from dots.externalNAsequence eas, dots.assemblysequence aseq, dots.assembly a where eas.na_sequence_id = aseq.na_sequence_id and aseq.assembly_na_sequence_id = a.na_sequence_id and eas.external_database_release_id = 992 and a.full_length_CDS = 1 and a.taxon_id = 8");


#Note that this query is restricted to human

  my $stmt5 = $self->getQueryHandle()->prepareAndExecute("select asm.na_sequence_id, taf.translation_stop from dots.assembly asm, dots.NAFeatureImp naf, dots.TranslatedAAFeature taf, dots.TranslatedAAsequence ts where asm.na_sequence_id = naf.na_sequence_id and naf.na_feature_id = taf.na_feature_id and taf.translation_start = taf.diana_atg_position + 2 and taf.diana_atg_score > 0.5 and taf.p_value < 0.5 and asm.taxon_id = 8 and taf.aa_sequence_id = ts.aa_sequence_id and ts.length > 100");





  my @na_sourceids = ();
  my @naSequenceIds = ();
  my @DTSasEvidenceTarget = ();
  my @RemoveAsMarkedFL = ();
  my @DTs = ();


  my @NaSeqStop = ();

  while (my($na_seq, $source_id) = $stmt1->fetchrow_array( )) {
    push(@na_sourceids, [$na_seq, $source_id]);
    push(@DTs, $na_seq);
  }

  while (my($na_sequence_id) = $stmt2->fetchrow_array( )) {
    push(@naSequenceIds, $na_sequence_id);
  }

  while (my($target_id) = $stmt3->fetchrow_array( )) {
    push(@DTSasEvidenceTarget, $target_id);
  }

  while (my($DTnotFLength) = $stmt4->fetchrow_array()) {
   push (@RemoveAsMarkedFL,$DTnotFLength);
  }


    while (my($naSeq, $tStop) = $stmt5->fetchrow_array( )) {
    push(@NaSeqStop, [$naSeq, $tStop]); 
  }



   my $ct = 0;

   foreach my $A (@na_sourceids) {

    my($na_seq, $source_id) = @{$A};

    print STDERR "ConsideringForFLDT.$na_seq\n";
    last if $self->getArgs->{testnumber} && $ct >$self->getArgs->{testnumber};

    $ct++;
    my $assembly = GUS::Model::DoTS::Assembly->new({'na_sequence_id' => $na_seq});

    $assembly->retrieveFromDB();
    $assembly->setFullLengthCds(1);
    $self->toAddEvidenceSourceID($source_id, $assembly);
    $assembly->submit();
    $self->undefPointerCache();
  }

   $self->DeleteEvidence(\@DTs,\@DTSasEvidenceTarget);
   $self->UnmarkFullLength(\@RemoveAsMarkedFL);

#first call delete then new assemblies marked fl using translatedAAfeatures
#if marked full length using framefinderStop As evidence or DIANA ATG delete
#   $self->DeleteFrameFinderFL(   );

    $self->MarkFLUsingFFfeatures(\@NaSeqStop);

#need this return to finish run of plugin adds result set attribute to algorithm invoc.
  return "$ct marked as full length";

}


 # check to see if all previous evidence still valid using array of target ids and compare to array of DTs
sub  DeleteEvidence   {

  my $self = shift;
  my ($DTs,$DTSasEvidenceTarget) = @_;


  my %seen = ();
  my @diffArray = ();
  my $dt;

  foreach $dt(@$DTs) {
    $seen{$dt} = 1;
  }
  foreach $dt(@$DTSasEvidenceTarget) {
    unless ($seen{$dt}) { 
     push (@diffArray, $dt);
    }
  }

  print STDERR "Arrayids@diffArray\n";
  my $ids = scalar(@diffArray);
  print STDERR "number in diffarray= $ids\n";

  foreach my $target_id (@diffArray) {
    my $Evidence = GUS::Model::DoTS::Evidence->new({'target_id' => $target_id,
                                                    'attribute_name' =>"full_length_CDS"});
    if ($Evidence->retrieveFromDB()) {
        $Evidence->markDeleted(1);
        $Evidence->submit();

      print STDERR  "DT.$target_id Evidence deleted\n"; 
    } else {
      print STDERR  "Cannot delete DT.$target_id Evidence; not retrieved\n";
    }

    $self->undefPointerCache();

  }

}



#  those assemblies that no longer contain a refSeq
sub UnmarkFullLength {

  my $self = shift;
  my ($RemoveAsMarkedFL) = @_;

  foreach my $DTnotFLength(@$RemoveAsMarkedFL)  {

  print STDERR "DT.$DTnotFLength does not have a RefSeq any longer\n";

  my $assembly = GUS::Model::DoTS::Assembly->new({'na_sequence_id' => $DTnotFLength});

      $assembly->retrieveFromDB();
      $assembly->setFullLengthCds(0);
      $assembly->submit();

      $self->undefPointerCache();
   }

}



#use RefSeq source_id as evidence for marking assembly as full length CDS containing

  sub toAddEvidenceSourceID {

  my $self = shift;
  my ($source_id,$assembly) = @_;

  print STDERR "Evidence$source_id\n";

  my $fact = GUS::Model::DoTS::ExternalNASequence->new({'source_id' => $source_id });

	if($fact->retrieveFromDB()){
     	$assembly->addEvidence($fact,1,"full_length_CDS");
      }

  }


1;




sub MarkFLUsingFFfeatures  {

   my $self = shift;
   my ($NaSeqStop) = @_;

   foreach my $B(@$NASeqStop) {

    my($naSeq, $tStop) = @{$B};

    print STDERR "ConsideringForFLDT.$naSeq using Features\n";
  
   #need to add testing for this
   #last if $self->getArgs->{testnumber} && $ct >$self->getArgs->{testnumber};
   #$ct++;
 

    my $assembly = GUS::Model::DoTS::Assembly->new({'na_sequence_id' => $naSeq});

    if ($assembly->retrieveFromDB( ))  {
    
    #need to substract 2 to get the stop codon string
      my  $sequence = $assembly ->getSubstrFromClob('sequence', $tStop - 2, 3);

      if (($sequence eq 'TAA') || ($sequence eq 'TAG') || ($sequence eq 'TGA')) {

    print STDERR "$naSeq,$sequence\n";

        $assembly->retrieveFromDB();
        $assembly->setFullLengthCds(1);
        $assembly->submit();
        $self->undefPointerCache();

#  $self->AddEvidenceTranslatedFeature($assembly,$tStop);

      }
    }
  }
}









#Notes
#could also use best_evidence attribute in Evidence table for those containing refSeq

#since framefinder or diana may not find the refSeq ATG it maybe best to keep them separate and if meet this additional criteria
#looks as if in table framefinder translation start is +2 greater than DIANA ATG
#query for marking as full length based on DIANA ATG and translations
#will also mark those assemblies which have good DIANA ATG prediction which equals the framefinder and also has framefinder stop codon, could also use a length greater than 50 amino acids

#NOTE taxon_id in this query

#select distinct naf.na_sequence_id from dots.assembly asm, dots.NAFeatureImp naf, dots.TranslatedAAFeature taf, dots.TranslatedAAsequence ts where asm.na_sequence_id = naf.na_sequence_id and naf.na_feature_id = taf.na_feature_id and taf.translation_start = taf.diana_atg_position + 2 and taf.diana_atg_score > 0.5 and taf.p_value < 0.5 and asm.taxon_id = 8 and taf.aa_sequence_id = ts.aa_sequence_id and ts.length > 100

#How to handle updates in this case ???? if assemblies chance in this case have to evaluate all parameters
#maybe the best way to do this would be to delete all DTs.that are marked full length which have a certain type of attribute evidence (diana ATG prediction for example and then jusr rerun to mark new set as full length so would need a plugin to delete than a plugin to rerun; first run delete in work flow or have delete first in plugin and then remark as full length in for this criteria if run RefSeq plugin first then will have an additional attribute evidence for this

#there would always be a subset of them that would be marked as full length from RefSef so would not want to unmark these; use evidence to check on this so if evidence is also target table id for externalANsequence do not delete or unmark as full length in the assembly table 










