package GUS::Common::Plugin::LoadSequenceOntology;

@ISA = qw(GUS::PluginMgr::Plugin);
 
use strict;
use FileHandle;
use GUS::ObjRelP::DbiDatabase;
$| = 1;

#on command line need input file, so version, so cvs version
#InputFile has format SOid\tTerm\tdefinition\n



sub new {
    my ($class) = @_;
    my $self = {};
    bless($self, $class);
    my $usage = 'Loads Sequence Ontology from tab delimited file';
    my $easycsp =
        [{o => 'inputFile',
          t => 'string',
          h => 'name of the file',
          { h => 'so_version',
          t => 'int',
          o => 'so_version',
          },
          { h => 'so_cvs_version',
          t => 'int',
          o => 'so_cvs_version',
         },
         }];

     $self->initialize({requiredDbVersion => {Core => '3'},
                       cvsRevision => '$Revision$', #CVS fills this in
                       cvsTag => '$Name$', #CVS fills this in
                       name => ref($self),
                       revisionNotes => 'make consistent with GUS 3.0',
                       easyCspOptions => $easycsp,
                       usage => $usage
                      });
    return $self;
}



sub run {
        my $self = shift;

        $self->getArgs()->{'commit'} ? $self->log("***COMMIT ON***\n") : $self->log("**COMMIT TURNED OFF**\n");
        $self->getArgs->{'inputFile'};

        if (!$self->getArgs->{'inputFile'}) {
          die "provide --inputFile name on the command line\n";
        }
        my $Input = FileHandle->new('<' . $self->getArgs->{inputFile});

        while (<$Input>){

          chomp;
          my ($SOid, $Term, $definition) = split (/\t/, $_);

          print STDERR "$SOid, $Term, $definition\n";

        $self->Insert($SOid,$Term,$definition);
        }

       $Input->close;

        return "LoadedSOontologyFromFile";
}

sub Insert {

   my $self = shift;

   my ($SOid, $Term, $definition) = @_;

   my $ontology_name = 'sequence';

   my $so_version =  $self->getArgs->{'so_version'};
   my $so_cvs_version = $self->getArgs->{'so_cvs_version'};

   my $dbh = $db->getQueryHandle();

   print STDERR "$SOid,$ontology_name, $so_version, $so_cvs_version, $Term, $definition\n";

  $dbh->do("INSERT into sres.SequenceOntology (so_id, ontology_name, so_version, so_cvs_version, term_name, definition) values ('$SOid', '$ontology_name', '$so_version', '$so_cvs_version', '$Term', '$definition')");



}



