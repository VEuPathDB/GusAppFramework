
package GUS::Common::Plugin::AssembliesWithflCD;

@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
use GUS::Model::DoTS::Assembly;
use GUS::ObjRelP::DbiDatabase;


$| = 1;

#JM This plugin is only in testing phase 7/17/03
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

$self->logCommit();


#get the assembly ids that contain RefSeqs
#add evidence that assembly has RefSeq; also this will have to have delete or update attribute so when updates are done assemblies will be marked as full length that contain RefSeqs;mark attribute value as null if assembly still exists then rerun plugin


my $stmt = $self->getQueryHandle()->prepareAndExecute("select distinct a.na_sequence_id, eas.source_id from dots.externalNAsequence eas,dots.assemblysequence aseq, dots.assembly a where eas.external_database_release_id = 992 and eas.na_sequence_id = aseq.na_sequence_id and aseq.assembly_na_sequence_id = a.na_sequence_id ");


my @na_sourceids;


while(my($na_seq, $source_id) = $stmt->fetchrow_array( ))  {

  push(@na_sourceids, [$na_seq, $source_id]);

   }

my $ct = 0;

foreach my $A(@na_sourceids)    {

  my($na_seq, $source_id) = @{$A};
  
   $ct++;

    print STDERR "$na_seq\n";

    last if $self->getArgs->{testnumber} && $ct > $self->getArgs->{testnumber};

    my $assembly = GUS::Model::DoTS::Assembly->new({'na_sequence_id' => $na_seq});

      $assembly->retrieveFromDB();    

      $assembly->setFullLengthCds(1);


  print STDERR "source_id\n";
      
      $self->toAddEvidenceSourceID($source_id, $assembly);

      $assembly->submit();


      $self->undefPointerCache();

      }

 }

#use RefSeq source_id as evidence for marking assembly as full length CDS containing

  sub toAddEvidenceSourceID {

  my $self = shift;

  my ($source_id,$assembly) = @_;

  print STDERR "source_id\n";

  my $fact = GUS::Model::DoTS::ExternalNASequence->new({'source_id' => $source_id });
 
	if($fact->retrieveFromDB()){
     	$assembly->addEvidence($fact,1,"full_length_CDS");
      }
 
  }






















