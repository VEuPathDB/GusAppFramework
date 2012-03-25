package GUS::Community::Plugin::IdentifyAndLoadSnpsFromAssemblies;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
use DBI;
use GUS::PluginMgr::Plugin;
############################################################
# Add any specific objects (Objects::GUSdev::Objectname) here
############################################################
use GUS::Model::DoTS::Assembly;
use GUS::Model::DoTS::AssemblySNP;
use GUS::Model::DoTS::AssemblySequenceSNP;


sub new {
  my ($class) = @_;
  my $self = {};
  bless($self, $class);
  my $usage ='Identifies SNPS in Assemblies and loads AssemblySNP and AssemblySequenceSNP';

  my $easycsp =
    
      [
       {
	   o => 'testnumber',
	   t => 'int',
	   h => 'number of iterations for testing',
       },
       {
	   o => 'idSQL',
	   t => 'string',
	   h => 'SQL statement that returns list of Assembly.na_sequence_ids where number_of_contained_sequences >= minDepth',
       },
       {
	   o => 'restartSQL',
	   t => 'string',
	   h => 'SQL statement that returns list of Assembly.na_sequence_ids from AssemblySnp table to ignore:  NOTE, is not executed if also include --inputFile',
       },
       {
	   o => 'logFile',
	   t => 'string',
	   h => 'file for recording log...required',
       },
       {
	   o => 'writeInputFile',
	   t => 'string',
	   h => 'file name to create input file with remaining ids to process....does not run',
       },
       {
	   o => 'inputFile',
	   t => 'string',
	   h => 'file name to read ids to process from....does not  query db for ids',
       },
       {
	   o => 'mod',
	   t => 'int',
	   h => 'for breaking input file into multiple runs...value to mod entries..ie \$ct % --mod',
	   d => '1',  ##does every entry...
       },
       {
	   o => 'modValue',
	   t => 'int',
	   h => 'for breaking input file into multiple runs...return value of \$ct % --mod',
	   d => '0',  ##does every entry...
       },
       {
	   o => 'minDepth',
	   t => 'int',
	   h => 'minimum depth at any column for finding snps',
	   d => '4',
       },
       {
	   o => 'maxBestPercent',
	   t => 'float',
	   h => 'maximum percent for major nucleotide at position to be considered snp',
	   d => '0.9',
       },
       {
	   o => 'minDepthLessBest',
	   t => 'int',
	   h => 'minimum number of non-best nucleotides',
	   d => '2',
       },
       { 
	   o => 'assemblySnpOnly',
	   t => 'boolean',
	   h => 'generate only AssemblySNP and  not AssemblySequenceSNP',
       },
#  log_frequency     => {
#                        o => 'log_frequency=i',
#                        h => 'Write line to log file once every this many entries',
#                        d => 1,
#                       },

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



sub run {
  my ($self) = @_;
  $self->logAlgInvocationId;
  $self->logCommit;
  $self->getAlgInvocation()->setMaximumNumberOfObjects(100000);

  die "You must provide (--idSQL or --inputFile) and --logFile\n" unless ( $self->getCla->{inputFile} || $self->getCla->{idSQL} ) && $self->getCla->{logFile};

  
  print "Testing on $self->getCla->{'testnumber'}\n" if $self->getCla->{'testnumber'};

  $self->logAlert('COMMIT', $self->getCla->{commit} ? 'ON' : 'OFF' );

  my $snpObjectType = $self->getCla->{assemblySnpOnly} ? 1 : 2;
  
  ##DBI handle to be used for queries outside the objects...
  my $dbh = $self->getQueryHandle();

  my %done;
  if($self->getCla->{restartSQL}){
    my $resStmt = $dbh->prepareAndExecute($self->getCla->{restartSQL});
    while(my($id) = $resStmt->fetchrow_array()){
      $done{$id} = 1;
    }
    print STDERR "Restarting..ignoring ",scalar(keys%done)," ids\n";
  }

  if(-e "$self->getCla->{logFile}"){
    open(L, "$self->getCla->{logFile}");
    while(<L>){
      if(/^(\d+)/){
        $done{$1} = 1;
      }
    }
    print STDERR "Restarting..ignoring ",scalar(keys%done)," ids\n";
    close L;
  }
  open(LOG, ">>$self->getCla->{logFile}");
  select LOG; $| = 1; select STDOUT;

  open(INF, ">$self->getCla}->{writeInputFile}") if $self->getCla->{writeInputFile};

  my $total = 0;
  my @ids;
  
  if($self->getCla->{inputFile}){  ##have input file so read from that...
    my $ct = 0;
    open(I, "$self->getCla->{inputFile}");
    while(<I>){
      if(/^(\d+)/){
        $ct++;
        if($ct % $self->getCla->{mod} == $self->getCla->{modValue}){
          $total++;
          push(@ids,$1);
        }
      }
    }
  }else{
    my $stmt = $dbh->prepareAndExecute($self->getCla->{idSQL});
    while(my($id) = $stmt->fetchrow_array()){
      next if $done{$id};
      if($self->getCla->{writeInputFile}){
        print INF "$id\n";
      }else{
        push(@ids, $id);
      }
      $total++;
      last if ($self->getCla->{testnumber} && $total >= $self->getCla->{testnumber});
      print "Retrieving $total\n" if $total % 1000 == 0;
    }

  }
  print "Have $total entries to process\n"; 

  print LOG  "Have $total entries to process\n";

  my $ctSNPs = 0;
  my $ctSeqs = 0;
  foreach my $id (@ids){
    $ctSeqs++;
#    print STDERR "processing $id\n";
    my $a =  GUS::Model::DoTS::Assembly->new({'na_sequence_id' => $id});
    unless($a->retrieveFromDB()){
      print STDERR "Unable to retrieve Assembly.$id\n" ;
      next;
    }
    ##now find the snps...
    my $snps = $a->findSNPs($self->getCla->{minDepth}, undef, $self->getCla->{maxBestPercent}, $self->getCla->{minDepthLessBest}, $snpObjectType);
    print STDERR "\n$id:\n$snps\n\n";
    print STDERR $a->getCap2Alignment();
    my $cts = scalar($a->getChildren('DoTS::AssemblySNP'));
    $ctSNPs += $cts;
    $a->submit();
    $self->getSelfInv->undefPointerCache();
    print LOG "$id: $cts snps ",($ctSeqs % 100 == 0 ? "$ctSeqs processed..".($total - $ctSeqs)." remaining ".`date` : "\n");
  }
  close LOG;
  my $ret = "Processed $ctSeqs sequences, found $ctSNPs SNPs using depth=".$self->getCla->{minDepth}.", maxBestPercent=".$self->getCla->{maxBestPercent}.", minDepthLessBest=".$self->getCla->{minDepthLessBest};
  print "\n$ret\n\n";
  return $ret;
}

1;

