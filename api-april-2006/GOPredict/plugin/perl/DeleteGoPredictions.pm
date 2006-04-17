############################################################
## Change Package name....
############################################################
package DeleteGoPredictions;

use strict;
use DBI;

############################################################
# Add any specific objects (Objects::GUSdev::Objectname) here
############################################################
use Objects::GUSdev::AASequenceGOFunction;
use Objects::GUSdev::ProteinGOFunction;

my $Cfg;  ##global configuration object....passed into constructor as second arg


sub new {
	my $Class = shift;
	$Cfg = shift;  ##configuration object...

	return bless {}, $Class;
}

sub Usage {
	my $M   = shift;
	return 'Deletes GO Associations given an sql query and table name.';
}

############################################################
# put the options in this method....
############################################################
sub EasyCspOptions {
	my $M   = shift;
	{

  testnumber        => {
                        o => 'testnumber',
                        t => 'int',
                        h => 'number of iterations for testing',
                       },
  idSQL             => {
                        o => 'idSQL=s',
                        h => 'SQL statement:  must return list of primary key identifiers (aa_sequence_go_function_id or protein_go_function_id)',
                       },
  doNotVersion      => {
                        o => 'doNotVersion',
                        t => 'boolean',
                        h => 'if true does not version any rows',
                       },
  deleteEvidence    => {
                        o => 'deleteEvidence',
                        t => 'boolean',
                        h => 'if true deletes evidence that aasequencegofunction may be used in....slow
                          if false, then need to clean up evidence tables later...more efficient?',
                       },
  log_frequency     => {
                        o => 'log_frequency=i',
                        h => 'Write line to log file once every this many entries',
                        d => 100,
                       },
  table_name        => {
                        o => 'table_name=s',
                        h => 'Table name to delete from (AASequenceGOFunction or ProteinGOFunction)',
                        d => 'ProteinGOFunction',
                       },
  primary_key       => {
                        o => 'primary_key=s',
                        h => 'primary key of table_name',
                        d => 'protein_go_function_id'
                       },

	}
}

my $ctx;
my $debug = 0;
$| = 1;

sub Run {
  my $M   = shift;
  $ctx = shift;

  die "--idSQL is required\n" unless $ctx->{cla}->{idSQL};
  die "--table_name is required\n" unless $ctx->{cla}->{table_name};

  $ctx->{self_inv}->setGlobalNoVersion(1) if $ctx->{cla}->{doNotVersion};
  $ctx->{self_inv}->setGlobalDeleteEvidenceOnDelete(0) unless $ctx->{cla}->{deleteEvidence};
  
  print $ctx->{'commit'} ? "***COMMIT ON***\n" : "***COMMIT TURNED OFF***\n";
  print "Testing on $ctx->{'testnumber'}\n" if $ctx->{'testnumber'};
  
  my $tname = $ctx->{cla}->{table_name};
  my $pk = $ctx->{cla}->{primary_key};

  ##DBI handle to be used for queries outside the objects...
  my $dbh = $ctx->{'self_inv'}->getQueryHandle();

  my $stmt = $dbh->prepareAndExecute($ctx->{cla}->{idSQL});
  my @idsToDelete;
  my $ct = 0;
  while(my($id) = $stmt->fetchrow_array()){
    push(@idsToDelete,$id);
    $ct++;
    print STDERR "fetching $ct ids to delete\n" if $ct % 10000 == 0;
    last if $ctx->{cla}->{testnumber} and $ct >=  $ctx->{cla}->{testnumber};
  }
  my $numToDelete = scalar(@idsToDelete);
  print STDERR "Deleting $numToDelete  entries\n";

  my $ctEntries = 0;
  foreach my $id (@idsToDelete){
    #my $agf = AASequenceGOFunction->new({'aa_sequence_go_function_id' => $id});
    my $agf = $tname->new({$pk => $id}); 
    if($agf->retrieveFromDB()){
      $agf->markDeleted(1);
      $ctEntries += $agf->submit();
     }else{
       print STDERR "Unable to retrieve " . $tname ." " . $id ."from GUSdev\n";
     }
    $agf->undefPointerCache();
    print STDERR "$ctEntries deleted, ",$numToDelete - $ctEntries," remaining ",($ctEntries % ($ctx->{cla}->{log_frequency} * 10) == 0 ? `date` : "\n") if $ctEntries % $ctx->{cla}->{log_frequency} == 0;
  }
  
  my $res = "Deleted $ctEntries $tname entries: total Deletes = ".$ctx->{self_inv}->getTotalDeletes();
  return $res;
}

1;
