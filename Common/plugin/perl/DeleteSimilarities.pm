############################################################
## Change Package name....
############################################################
package DeleteSimilarities;

use strict;
use DBI;

############################################################
# Add any specific objects (GUS::Model::::Objectname) here
############################################################
use GUS::Model::::Similarity;

my $Cfg;  ##global configuration object....passed into constructor as second arg


sub new {
	my $Class = shift;
	$Cfg = shift;  ##configuration object...

	return bless {}, $Class;
}

sub Usage {
	my $M   = shift;
	return "plugin that Versions Similarities given query_table and idSQL identifying rows in that table
\t\t\tand deletes all dependent children (SimilaritySpans, ConsistentAlignments and IndexWordSimLinks";
}

############################################################
# put the options in this method....
############################################################
sub CBIL::Util::EasyCspOptions {
	my $M   = shift;
	{

#		test_opt1 => {
#									o => 'opt1',  ##variable name in app = $ctx->{cla}->{opt1}
#		              t => 'int',   ## type of this argument ('int','float','boolean','string')
#									h => 'option 1 for test application',  ##help text
#									d => 4,  ##default value
#									l => 1,	 ##is list valued if true
#                ld => ':',  ##list delimiter (default is ",")
#									e => [ qw( 1 2 3 4 ) ], ##allowed values
#								 },

# testnumber        => {
#                        o => 'testnumber',
#                        t => 'int',
#                        h => 'number of iterations for testing',
#                       },
  idSQL             => {
                        o => 'idSQL',
                        t => 'string',
                        h => 'SQL statement:  must return list of similarity_ids to be deleted',
                       },
#  queryTable       => {
#                        o => 'queryTable',
#                        t => 'string',
#                        h => 'name of  the  query_table for which the similarities will be removed',
#                       },
#  subjectTable       => {
#                        o => 'subjectTable',
#                        t => 'string',
#                        h => 'name of  the  subject_table for which the similarities will be removed',
#                       },
  doNotVersion      => {
                        o => 'doNotVersion',
                        t => 'boolean',
                        h => 'if true does not version any rows,  default versions only Similarity rows',
                       },
  versionAll        => {
                        o => 'versionAll',
                        t => 'boolean',
                        h => 'if true versions all rows,  default versions only Similarity rows',
                       },
  deleteEvidence    => {
                        o => 'deleteEvidence',
                        t => 'boolean',
                        h => 'if true deletes evidence that similarities may be used in....slow
                          if false, then need to clean up evidence tables later...more efficient?',
                       },
  log_frequency     => {
                        o => 'log_frequency=i',
                        h => 'Write line to log file once every this many entries',
                        d => 100,
                       },

	}
}

my $ctx;
my $debug = 0;
$| = 1;

sub Run {
  my $M   = shift;
  $ctx = shift;

  die "--idSQL are required\n" unless ($ctx->{cla}->{idSQL});

  print $ctx->{'commit'} ? "***COMMIT ON***\n" : "***COMMIT TURNED OFF***\n";

  print "Deleting similarities match query '$ctx->{cla}->{idSQL}'\n
";

  ##DBI handle to be used for queries outside the objects...
  my $dbh = $ctx->{'self_inv'}->getQueryHandle();

  if(!$ctx->{cla}->{commit}){
    print "Not in commit mode...Determining number of similarities that satisify the query\n";
    my $stmt = $dbh->prepareAndExecute("select count(*) from similarity where  similarity_id in ($ctx->{cla}->{idSQL})");
    while(my($num) = $stmt->fetchrow_array()){
      print "  There are $num Similarities to be deleted\n";
    }
  }

  my $ctSim;
  ##first version the Similarities...
  if(!$ctx->{cla}->{doNotVersion}){  ##version similarities..
#    $dbh->do("set transaction use rollback segment BIGRBS0"); ##ensures using  big rollback segment
    my $ver = "insert into SimilarityVer (select s.*,".$ctx->{self_inv}->getId().",SYSDATE,1 from Similarity s where similarity_id in ($ctx->{cla}->{idSQL}))";
    print "Versioning similarities...\n\t$ver\n",`date`;
    if($ctx->{cla}->{commit}){
      $ctSim = $dbh->do($ver);
      $dbh->commit();
      print "\tInserted $ctSim rows into SimilarityVer: ",`date`,"\n";
    }
  }

  ##mark the similarities deleted by setting query_table_id and subject_table_id to 1
  $dbh->do("set transaction use rollback segment BIGRBS0"); ##ensures using  big rollback segment
  my $markQuery = "update Similarity set query_table_id = 1, subject_table_id = 1 where similarity_id in ($ctx->{cla}->{idSQL})";
  print "marking Similarities deleted....\n\t$markQuery\n",`date`;
  if($ctx->{cla}->{commit}){
    print "\tUpdated ",$dbh->do($markQuery)," rows in Similarity: ",`date`,"\n";
    $dbh->commit();
  }
  
  my $ctDep = 0;

  ##next delete the SimilaritySpans
  $dbh->do("set transaction use rollback segment BIGRBS0"); ##ensures using  big rollback segment
  ##need to version if --versionAll
  if($ctx->{cla}->{versionAll}){
    my $verSS = "insert into SimilaritySpanVer (select l.*,".$ctx->{self_inv}->getId().",SYSDATE,1 from SimilaritySpan l where l.similarity_id in (select s.similarity_id from Similarity s where s.query_table_id = 1 and s.subject_table_id = 1 ))";
    print "Versioning SimilaritySpan...$verSS\n",`date`;
    if($ctx->{cla}->{commit}){
      print "\tVersioned ",$dbh->do($verSS)," rows ",`date`,"\n";
      $dbh->commit();
      $dbh->do("set transaction use rollback segment BIGRBS0"); ##ensures using  big rollback segment
    }
  }
  my $delSpan = "delete from similarityspan where similarity_id in (select s.similarity_id from Similarity s where s.query_table_id = 1 and s.subject_table_id = 1)";
  print "Deleting SimilaritySpans ....\n\t$delSpan\n",`date`;
  if($ctx->{cla}->{commit}){
    $ctDep += $dbh->do($delSpan);
    $dbh->commit();
    print "\tDeleted $ctDep rows from SimilaritySpan: ",`date`,"\n";
  }

  ##now the ConsistentAlignments
  $dbh->do("set transaction use rollback segment BIGRBS0"); ##ensures using  big rollback segment
  ##need to version if --versionAll
  if($ctx->{cla}->{versionAll}){
    my $verCA = "insert into ConsistentAlignmentVer (select l.*,".$ctx->{self_inv}->getId().",SYSDATE,1 from ConsistentAlignment l where l.similarity_id in (select s.similarity_id from Similarity s where s.query_table_id = 1 and s.subject_table_id = 1))";
    print "Versioning ConsistentAlignments...$verCA\n",`date`;
    if($ctx->{cla}->{commit}){
      print "\tVersioned ",$dbh->do($verCA)," rows ",`date`,"\n";
      $dbh->commit();
      $dbh->do("set transaction use rollback segment BIGRBS0"); ##ensures using  big rollback segment
    }
  }
  my $delConsAl = "delete from ConsistentAlignment where similarity_id in (select s.similarity_id from Similarity s where s.query_table_id =  1 and s.subject_table_id = 1)";
  print "Deleting ConsistentAlignments....\n\t$delConsAl\n",`date`;
  if($ctx->{cla}->{commit}){
    my $ctAl = $dbh->do($delConsAl);
    $ctDep += $ctAl;
    $dbh->commit();
    print "\tDeleted $ctAl rows from ConsistentAlignment: ",`date`,"\n";
  }

  ##now the IndexWordSimLinks
  $dbh->do("set transaction use rollback segment BIGRBS0"); ##ensures using  big rollback segment
  ##need to version if --versionAll
  if($ctx->{cla}->{versionAll}){
    my $verIW = "insert into IndexWordSimLinkVer (select l.*,".$ctx->{self_inv}->getId().",SYSDATE,1 from IndexWordSimLink l where l.best_similarity_id in (select s.similarity_id from Similarity s where s.query_table_id = 1 and s.subject_table_id = 1 ))";
    print "Versioning IndexWordSimLinks...$verIW\n",`date`;
    if($ctx->{cla}->{commit}){
      print "\tVersioned ",$dbh->do($verIW)," rows ",`date`,"\n";
      $dbh->commit();
      $dbh->do("set transaction use rollback segment BIGRBS0"); ##ensures using  big rollback segment
    }
  }

  my $delIWSL = "delete from IndexWordSimLink where best_similarity_id in (select s.similarity_id from Similarity s where s.query_table_id = 1 and s.subject_table_id = 1 )";
  print "Deleting IndexWordSimLinks....\n\t$delIWSL\n",`date`;
  if($ctx->{cla}->{commit}){
    my $ctLinks = $dbh->do($delIWSL);
    $ctDep += $ctLinks;
    $dbh->commit();
    print "\tDeleted $ctLinks rows from IndexWordSimLink: ",`date`,"\n";
  }

  ##finally the similarities...use DeleteEntriesFromTable.pl to do 1000 rows at a time
  ##alternative here is to copy the table except for the entries to  be  deleted then rename etc...
  my $cmd = "/usr/local/bin/databases/perl/deleteEntries.pl --table Similarity --idSQL 'select s.similarity_id from Similarity s where s.query_table_id = 1 and s.subject_table_id = 1'";
  print "Deleting Similarities ...$cmd\n",`date`;
  if($ctx->{cla}->{commit}){
    system("$cmd");
  }

  ############################################################
  # return status
  # replace word "done" with meaningful return value/summary
  ############################################################
  my $res = "Deleted $ctSim Similarities and $ctDep Dependent Children";
  print "\n\nComplete: $res\n";
  return $res;
}

1;

__END__

=pod
=head1 Description
B<Template> - a template plug-in for C<ga> (GUS application) package.

=head1 Purpose
B<Template> is a minimal 'plug-in' GUS application.

=cut
