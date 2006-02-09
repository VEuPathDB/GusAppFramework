##########################################################
# Filename:    CopyAASeqGoFuncToProtGoFunc.pm
#
# Description: Used to copy AASequenceGoFunction predictions
#              for assemblies to ProteinGOFunction. The
#              ProteinGoFunction table is updated by the 
#              annotators.  AASequenceGoFunction is where
#              the computationally predicted functions are 
#              stored.  Evidence for the ProteinGoFunction
#              is the AASequenceGoFunction entry.
#              In the future, we will not be making a full
#              copy of the predictions in ProteinGoFunction.
#
# Modified   By               Description
# _________________________________________________________
#
# 07/31/01   Sharon Diskin    Created
#
############################################################
package CopyAASeqGoFuncToProtGoFunc;

use strict;

require Objects::GUSdev::AASequenceGOFunction;
require Objects::GUSdev::ProteinGOFunction;

sub new {
	my $Class = shift;

	return bless {}, $Class;
}

sub Usage {
	my $M   = shift;
	return 'Copies AASequenceGoFunction predictions to ProteinGoFunction.';
}

sub EasyCspOptions {
	my $M   = shift;
	{

 log_frequency      => {
												o => 'log_frequency=i',
												h => 'frequency for writing to log',
												d => 10,
											 },

  testnumber        => {
												o => 'testnumber',
												t => 'int',
												h => 'number of iterations for testing',
											 },
							
  idSQL             => {
											 o => 'idSQL=s',
											 h => 'SQL statement:  should select aa_sequence_go_function_id (s) that you want to copy.',
											},
 idExclSQL         => {
											 o => 'idExclSQL=s',
											 h => 'SQL statement:  should select protein_id (s) that you want to exclude from the copying process - for example, if they have been manually reviewed/annotated.',
											}, 
 addEvidIfRev      => { o => 'addEvidIfRev',
                        t => 'boolean',
                        h => 'add prediction as Evidence for reviewed ProteinGOFunction if exists',
                        d => 1,
                      },
 excl_all      => { o => 'excl_all',
                        t => 'boolean',
                        h => 'exclude all proteins from copy - set to 1 if only want to update evidence for existing entries.',
                        d => 0,
                      },

  }
}

my $ctx;
my $debug = 0;
my $dbh;
$| = 1;

sub Run {
	my $M   = shift;
	$ctx = shift;

  die "--idSQL is required\n" unless $ctx->{cla}->{idSQL};

  print $ctx->{'commit'} ? "***COMMIT ON***\n" : "***COMMIT TURNED OFF***\n";
  print "Testing on $ctx->{'testnumber'}\n" if $ctx->{'testnumber'};

  # Get the database handle.
	#
  print STDERR "Establishing dbi login\n" if $debug || $ctx->{cla}->{verbose};
	$dbh = $ctx->{self_inv}->getQueryHandle();

  my $ct = 0;
  my $count = 0;

  # Use the idSQL to select the primary keys of the AASequenceGoFunction
  #
  my %ids;
  my  $stmt = $dbh->prepareAndExecute($ctx->{cla}->{idSQL});
	while(my($id) = $stmt->fetchrow_array()){
		$ids{$id} = 1;
		$ct++;
		last if($ctx->{cla}->{testnumber} && scalar(keys%ids) >= $ctx->{cla}->{testnumber});
		print STDERR "retrieving $ct rows\n" if $ct % 100 == 0;
	}
	print STDERR "Retrieved ".scalar(keys%ids)." aa_sequence_go_function_ids to process\n";

  # Use the idExclSQL(if provided) to obtain a set of protein_ids to exclude from
  # the copy process.
  #
  my $excl_ct = 0;
  my %excl_ids;
  if ($ctx->{cla}->{idExclSQL}){
    my  $stmt2 = $dbh->prepareAndExecute($ctx->{cla}->{idExclSQL});
    while(my($id) = $stmt2->fetchrow_array()){
      $excl_ids{$id} = 1;
      $excl_ct++;
    }
    print STDERR "Excluding ".scalar(keys%excl_ids)." protein_ids from copying process\n";
  }

	my $ctProcessed = 0;
	foreach my $id (keys%ids){
      
    $ctProcessed++;

    # Retrieve the existing AASequenceGOFunction entry.
    #
    my $agf = AASequenceGOFunction->new( { 'aa_sequence_go_function_id' => $id } );
    if (!$agf->retrieveFromDB()){
      print "ERROR: Unable to retrieve AASequenceGOFunction $id from database\n";
      next;
    }

    # Get the corresponding protein_id for this entry.
    #
#
# SJD - When have time should really change this so queries for all protein ids up front - 
# create a mapping AGF to protein id.  Then, don't need to do query for every AGF!
#
    my $protein_id = &getProteinIdFromAASequenceId($agf->getAaSequenceId());
    if (!$protein_id){
      print "ERROR: Unable to retrieve protein_id for aa_sequence_id ". $agf->getAaSequenceId() . "\n";
      next;
    }

    my $pgf = ProteinGOFunction->new({ 'protein_id'     => $protein_id,
                                       'go_function_id' => $agf->getGoFunctionId() });

    if ($pgf->retrieveFromDB()){

      print STDERR "retrieveFromDB: $protein_id ". $agf->getGoFunctionId() ." already exists in ProteinGoFunction.\n";

      # Check if has been manually reviewed. If yes, then add this aasequencegofunction
      # entry as additional evidence for its existence.  Otherwise - DUPLICATE, this should
      # not happen.

      if ($pgf->getManuallyReviewed() && $ctx->{cla}->{addEvidIfRev}){
        print STDERR "REVPRED: $protein_id ". $agf->getGoFunctionId() ." already exists in ProteinGoFunction and has been reviewed.\n";
        $pgf->addEvidence($agf);
        $count += $pgf->submit();     #NOTE:  THIS WILL NOT MODIFY THE PGF ENTRY - WANT TO MAINTAIN ROW_USER_ID
      }else{ 
        print STDERR  "DUPPRED: $protein_id ". $agf->getGoFunctionId() ." already exists in ProteinGoFunction and has NOT been reviewed.\n";
        next;
      }
    }else{
      
      # Double check that this protein_id is not in the list to be excluded.  
      # Note that there may be reviewed predictions that were deleted from
      # proteingofunction.  These exist in the version table, and their 
      # protein_ids should be included in the idExclSQL passed in as CLA.

      if ((!$excl_ids{$protein_id}) && ($ctx->{ cla }->{ excl_all } == 0)){
         print STDERR "NEWPRED: $protein_id ". $agf->getGoFunctionId() ." is new, creating ProteinGoFunction.\n";
   
        # Add the AASequenceGoFunction Entry as evidence for the ProteinGoFunction.
        # and set manually_reviewed to 0, this is a entry.
        #
        $pgf->addEvidence( $agf );
        $pgf->setManuallyReviewed(0);

        $count += $pgf->submit();
       }else{
        print STDERR "EXCLPRED: $protein_id ". $agf->getGoFunctionId() ." protein was excluded from copy process, not copying.\n";
      }
    }

    print "Processed $ctProcessed, Copied  $count aa_sequence_go_function_ids\n"  if $count % $ctx->{cla}->{log_frequency} == 0;

    $ctx->{self_inv}->undefPointerCache();
    
  }
 
	return "Copied  $count AASequenceGoFunctions to ProteinGoFunction\n";

}

my %aaSeqToProt;

sub getProteinIdFromAASequenceId{
  my $aa_sequence_id = shift;

  if (! $aaSeqToProt{$aa_sequence_id}){
    my $sql = "select p.protein_id from translatedaafeature af, rnafeature rf, rnasequence rs, rna r, protein p where af.aa_sequence_id = ".$aa_sequence_id. " and rf.na_feature_id = af.na_feature_id and rs.na_feature_id = rf.na_feature_id 	and rs.rna_id = r.rna_id and p.rna_id = r.rna_id";
											
     my $stmt = $dbh->prepareAndExecute($sql);
     if (my ($protein_id)  = $stmt->fetchrow_array()){
         $aaSeqToProt{$aa_sequence_id} = $protein_id;
     }else{
         print STDERR "Unable to obtain protein_id for ". $aa_sequence_id."\n";
     }
   }
  return $aaSeqToProt{$aa_sequence_id};
}
                    

1;

__END__

