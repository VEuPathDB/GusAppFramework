
package GUS::Common::Plugin::AssembliesWithflCD;

@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
use GUS::Model::DoTS::Assembly;
use GUS::ObjRelP::DbiDatabase;
use GUS::Model::DoTS::ExternalNASequence;
use GUS::Model::DoTS::Evidence;
use GUS::Model::Core::AlgorithmInvocation;




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
  #NOTE FOR TESTING taxon set to human only FOR THIS Query


  my $stmt1 = $self->getQueryHandle()->prepareAndExecute("select distinct a.na_sequence_id, eas.source_id from dots.externalNAsequence eas,dots.assemblysequence aseq, dots.assembly a where eas.external_database_release_id = 992 and eas.na_sequence_id = aseq.na_sequence_id and aseq.assembly_na_sequence_id = a.na_sequence_id and a.taxon_id = 8");

  my $stmt2 = $self->getQueryHandle()->prepareAndExecute("select distinct a.na_sequence_id from dots.externalNAsequence eas, dots.assemblysequence aseq, dots.assembly a where eas.na_sequence_id = aseq.na_sequence_id and aseq.assembly_na_sequence_id = a.na_sequence_id and eas.external_database_release_id = 992 and a.full_length_CDS = 1 and a.taxon_id = 8");

  my $stmt3 = $self->getQueryHandle()->prepareAndExecute("select target_id from dots.evidence where attribute_name = 'full_length_CDS'");

  my $stmt4 = $self->getQueryHandle()->prepareAndExecute("select distinct a.na_sequence_id from dots.assembly a where a.full_length_CDS = 1 and a.taxon_id = 8 minus select distinct a.na_sequence_id from dots.externalNAsequence eas, dots.assemblysequence aseq, dots.assembly a where eas.na_sequence_id = aseq.na_sequence_id and aseq.assembly_na_sequence_id = a.na_sequence_id and eas.external_database_release_id = 992 and a.full_length_CDS = 1 and a.taxon_id = 8");




  my @na_sourceids = ();
  my @naSequenceIds = ();
  my @DTSasEvidenceTarget = ();
  my @RemoveAsMarkedFL = ();
  my @DTs = ();


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





#Notes
#could also use best_evidence attribute in Evidence table for those containing refSeq
#want to exclude those which have already been marked using refSeq source id or include and use DIANA and framefinder attributes as additonal evidence
#since framefinder or diana may not find the refSeq ATG it maybe best to keep them separate and if meet this additional criteria
#looks as if in table framefinder translation start is +2 greater than DIANA ATG
#query for marking as full length based on DIANA ATG and translations
#select naf.na_sequence_id, taf.aa_sequence_id from dots.assembly asm, dots.NAFeatureImp naf, dots.TranslatedAAFeature taf
#where asm.na_sequence_id = naf.na_sequence_id and naf.na_feature_id = taf.na_feature_id and taf.translation_start = taf.diana_atg_position + 2
#and taf.diana_atg_score > 0.5 and taf.p_value < 0.5
#will also mark those assemblies which have good DIANA ATG prediction which equals the framefinder and also has framefinder stop codon, could also use a length greater than 50 amino acids
















