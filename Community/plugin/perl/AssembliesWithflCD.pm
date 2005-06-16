
package GUS::Community::Plugin::AssembliesWithflCD;

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
 #    { h => 'number of iterations for testing',
  #     t => 'int',
   #    o => 'testnumber',
    # },

 #   { h => 'number of iterations for testing',
   #    t => 'int',
  #     o => 'testnumber2',
    # },



#consider adding the +2 in query for feature location equivalence and in substring identification
#992 is external database release id for RefSeq (this should not change?)
     { h => 'external database release id for RefSeq',
       t => 'int',
       o => 'external_database_release_id',
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
  #print "Testing on Assembly $self->getArgs->{'testnumber'}\n" if $self->getArgs->{'testnumber'};

  #can add new log ability  $self->logCommit();
  #move out external_database_release_id put as cla external_database_release_id = $self->getArgs->{'external_database_release_id'}
  #move out in all queries



  my $stmt1 = $self->getQueryHandle()->prepareAndExecute("select distinct a.na_sequence_id, eas.source_id from dots.externalNAsequence eas,dots.assemblysequence aseq, dots.assembly a where eas.external_database_release_id = " .$self->getArgs->{'external_database_release_id'}." and eas.na_sequence_id = aseq.na_sequence_id and aseq.assembly_na_sequence_id = a.na_sequence_id");

  my $stmt2 = $self->getQueryHandle()->prepareAndExecute("select a.na_sequence_id from dots.externalNAsequence eas, dots.assemblysequence aseq, dots.assembly a where eas.na_sequence_id = aseq.na_sequence_id and aseq.assembly_na_sequence_id = a.na_sequence_id and eas.external_database_release_id = 992 and a.full_length_CDS = 1");

#fact_table_id = 89 is ExternalNASequence

  my $stmt3 = $self->getQueryHandle()->prepareAndExecute("select target_id from dots.evidence where attribute_name = 'full_length_CDS' and fact_table_id = 89");

#this query reflects those which no longer have a RefSeq associated with them

  my $stmt4 = $self->getQueryHandle()->prepareAndExecute("select a.na_sequence_id from dots.assembly a, dots.evidence e where e.fact_table_id = 89 and e.target_id = a.na_sequence_id and a.full_length_CDS = 1 minus select a.na_sequence_id from dots.externalNAsequence eas, dots.assemblysequence aseq, dots.assembly a where eas.na_sequence_id = aseq.na_sequence_id and aseq.assembly_na_sequence_id = a.na_sequence_id and eas.external_database_release_id = 992 and a.full_length_CDS = 1");


  my $stmt5 = $self->getQueryHandle()->prepareAndExecute("select asm.na_sequence_id, taf.translation_stop, taf.aa_feature_id from dots.assembly asm, dots.NAFeatureImp naf, dots.TranslatedAAFeature taf, dots.TranslatedAAsequence ts where asm.na_sequence_id = naf.na_sequence_id and naf.na_feature_id = taf.na_feature_id and taf.translation_start = taf.diana_atg_position + 2 and taf.diana_atg_score > 0.5 and taf.p_value < 0.5 and taf.aa_sequence_id = ts.aa_sequence_id and ts.length > 100");

#fact_table_id = 338 is translatedAAsequence

  my $stmt6 = $self->getQueryHandle()->prepareAndExecute("select target_id from dots.evidence where attribute_name = 'full_length_CDS' and fact_table_id = 338");



  my @na_sourceids = ();
  my @naSequenceIds = ();
  my @DTSasEvidenceTarget = ();
  my @RemoveAsMarkedFL = ();
  my @DTs = ();
  my @NaSeqStop = ();
  my @DTsMarkedUsingFeatures = ();


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

    while (my($naSeq,$tStop,$featureId) = $stmt5->fetchrow_array( )) {
    push(@NaSeqStop, [$naSeq, $tStop,$featureId]); 
  }

    while (my($target_Id) = $stmt6->fetchrow_array( )) {
    push(@DTsMarkedUsingFeatures,$target_Id);
  }


#to Mark Assemblies as full CDS using RefSeqs
   $self->RefSeqFLAssemblies(\@na_sourceids);

#Delete the evidence if no longer containing a RefSeq

   $self->DeleteEvidence(\@DTs,\@DTSasEvidenceTarget);

#Unmark as FL those no longer containing a RefSeq

   $self->UnmarkFullLength(\@RemoveAsMarkedFL);

#Mark FL using features; first call unmark then delete; this has to done first since the features may change from build to build

#although below implies that that all features are based on framefinder; features can also be based on trivial translation if better than FF translation

    $self->UnMarkAssembliesAsFrameFinderFL(\@DTsMarkedUsingFeatures);

    $self->DeleteFrameFinderEvidence(\@DTsMarkedUsingFeatures);

#now Mark as FL using translated features
    $self->MarkFLUsingFFfeatures(\@NaSeqStop);

#need this return to finish run of plugin adds result set attribute to algorithm invoc.
    return "Assemblies marked as full length";

}



sub RefSeqFLAssemblies {

  my $self = shift;
  my ($na_sourceids) = @_;
  my $ct = 0;

   foreach my $A (@$na_sourceids) {

    my($na_seq, $source_id) = @{$A};

    print STDERR "ConsideringForFLDT.$na_seq\n";
  #  last if $self->getArgs->{testnumber} && $ct >$self->getArgs->{testnumber};



    my $assembly = GUS::Model::DoTS::Assembly->new({'na_sequence_id' => $na_seq});

    if ($assembly->retrieveFromDB())  {

      if (!($assembly->getFullLengthCds(1)))  {

    $self->toAddEvidenceSourceID($source_id, $assembly);
    $assembly->setFullLengthCds(1);
    $assembly->submit();
    $self->undefPointerCache();


     $ct++;
  }

    }

  }
    print STDERR "$ct Number marked using RefSeq\n";


}





# check to see if all previous evidence still valid using array of target ids and compare to array of DTs that now contain RefSeqs
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
                                                    'attribute_name' =>"full_length_CDS",
                                                   'fact_table_id' => 89 });
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

# these may later be marked full length by translated features

sub UnmarkFullLength {

  my $self = shift;
  my ($RemoveAsMarkedFL) = @_;

  foreach my $DTnotFLength(@$RemoveAsMarkedFL)  {

  print STDERR "DT.$DTnotFLength does not have a RefSeq any longer\n";

  my $assembly = GUS::Model::DoTS::Assembly->new({'na_sequence_id' => $DTnotFLength,
                                                  'full_length_CDS' => 1 });

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


 if (!($assembly->getFullLengthCds(1)))  {


  my $fact = GUS::Model::DoTS::ExternalNASequence->new({'source_id' => $source_id });

	if($fact->retrieveFromDB()){
     	$assembly->addEvidence($fact,1,"full_length_CDS");

   print STDERR "EvidenceAdded$source_id\n";

      }else 
        {   print STDERR "Can not add evidence\n";
        }


    }
}


sub MarkFLUsingFFfeatures  {

   my $self = shift;
   my ($NaSeqStop) = @_;


   my $ct = 0;

   foreach my $B(@$NaSeqStop) {

    my($naSeq, $tStop,$featureId) = @{$B};

    print STDERR "ConsideringForFLDT.$naSeq using Features\n";


 #  last if $self->getArgs->{testnumber2} && $ct >$self->getArgs->{testnumber2};



    my $assembly = GUS::Model::DoTS::Assembly->new({'na_sequence_id' => $naSeq});

    if ($assembly->retrieveFromDB( ))  {


      if (!($assembly->getFullLengthCds(1)))  {

    #need to substract 2 to get the stop codon string from FF stop location
      my  $sequence = $assembly ->getSubstrFromClob('sequence', $tStop - 2, 3);

      if (($sequence eq 'TAA') || ($sequence eq 'TAG') || ($sequence eq 'TGA')) {

    print STDERR "$naSeq,$sequence\n";

        $self->AddEvidenceTranslatedFeature($assembly,$featureId);
        $assembly->setFullLengthCds(1);
        $assembly->submit();
        $self->undefPointerCache();

     print STDERR "$naSeq marked full length by features\n";
     $ct++;
  }

    }
    }
  }
     print STDERR "$ct Number marked using features\n";

}







sub AddEvidenceTranslatedFeature  {


  my $self = shift;
  my ($assembly, $featureId) = @_;

#whole row in translatedAAfeature by aa_feature_id as Evidence

   my $fact = GUS::Model::DoTS::TranslatedAAFeature->new({'aa_feature_id' => $featureId });

	if($fact->retrieveFromDB()){
     	$assembly->addEvidence($fact,1,"full_length_CDS");

   print STDERR "EvidenceAddedFeatureRow$featureId\n";

      }else 
        {   print STDERR "Can not add FeatureEvidence\n";
        }


}

#UnMark all assemblies which have used features to mark them full length
sub  UnMarkAssembliesAsFrameFinderFL  {

  my $self = shift;
  my ($DTsMarkedUsingFeatures ) = @_;

  foreach my $targetId(@$DTsMarkedUsingFeatures)  {

  print STDERR "DT.$targetId Unmarked as FL from FF\n";

  my $assembly = GUS::Model::DoTS::Assembly->new({'na_sequence_id' => $targetId });
  if( $assembly->retrieveFromDB())  {
      $assembly->setFullLengthCds(0);
      $assembly->submit();

      $self->undefPointerCache();

}else {


      print STDERR "Can not retrieve assembly; deleted by build?\n";
}


}

}

#delete feature evidence from the evidence table

sub DeleteFrameFinderEvidence {


  my $self = shift;
  my ($DTsMarkedUsingFeatures) = @_;


  foreach my $target_id(@$DTsMarkedUsingFeatures) {
    my $Evidence = GUS::Model::DoTS::Evidence->new({'target_id' => $target_id,
                                                   'attribute_name' =>"full_length_CDS",
                                                   'fact_table_id' => 338 });

    if ($Evidence->retrieveFromDB()) {
        $Evidence->markDeleted(1);
        $Evidence->submit();

        $self->undefPointerCache();

      print STDERR  "DT.$target_id FeatureEvidence deleted\n"; 
    } else {
      print STDERR  "Cannot delete DT.$target_id FeatureEvidence; not retrieved\n";
    }

  }

}

1;



####check framefinderProteinsDeleteEvidence
##check for unmark also for these assemblies 



#Notes
#could also use best_evidence attribute in Evidence table for those containing refSeq

#since framefinder or diana may not find the refSeq ATG it maybe best to keep them separate and if meet this additional criteria
#looks as if in table framefinder translation start is +2 greater than DIANA ATG
#query for marking as full length based on DIANA ATG and translations
#will also mark those assemblies which have good DIANA ATG prediction which equals the framefinder and also has framefinder stop codon, could also use a length greater than 100 amino acids




#How to handle updates in this case ???? if assemblies chance in this case have to evaluate all parameters
#maybe the best way to do this would be to delete all DTs.that are marked full length which have a certain type of attribute evidence (diana ATG prediction for example and then jusr rerun to mark new set as full length so would need a plugin to delete than a plugin to rerun; first run delete in work flow or have delete first in plugin and then remark as full length in for this criteria if run RefSeq plugin first then will have an additional attribute evidence for this

#there would always be a subset of them that would be marked as full length from RefSef so would not want to unmark these; use evidence to check on this so if evidence is also target table id for externalANsequence do not delete or unmark as full length in the assembly table 










