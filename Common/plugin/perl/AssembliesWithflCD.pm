
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
#add evidence that assembly has RefSeq; also this will have to have delete or update so when updates are done assemblies will be marked as full length that contain RefSeqs


my $stmt = $self->getQueryHandle()->prepareAndExecute("select distinct a.na_sequence_id from dots.externalNAsequence eas,dots.assemblysequence aseq, dots.assembly a where eas.external_database_release_id = 992 and eas.na_sequence_id = aseq.na_sequence_id and aseq.assembly_na_sequence_id = a.na_sequence_id ");


my @na_seqs;

while((my $na_seq) = $stmt->fetchrow_array( ))  {

  push(@na_seqs, $na_seq);

   }

my $ct = 0;

foreach my $na_seq(@na_seqs)    {

print STDERR "$na_seq\n";

   $ct++;


    last if $self->getArgs->{testnumber} && $ct > $self->getArgs->{testnumber};


    my $assembly = GUS::Model::DoTS::Assembly->new({'na_sequence_id' => $na_seq});

    if($assembly->retrieveFromDB())    {


      $assembly->setFullLengthCds(1);

      $self->getAlgInvocation->submit();


      $self->undefPointerCache();

    } else {

      print STDERR "Did not retrieve $na_seq from db\n";

  }

  }
}




























