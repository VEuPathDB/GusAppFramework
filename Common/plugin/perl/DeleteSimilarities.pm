package GUS::Common::Plugin::DeleteSimilarities;

@ISA = qw(GUS::PluginMgr::Plugin); 
use strict;

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  my $usage = 'version Similarities given query_table and idSQL identifying rows in that table and deletes all dependent children (SimilaritySpans, ConsistentAlignments and IndexWordSimLinks';

  my $easycsp =
    [{o => 'idSQL',
      t => 'string',
      h => 'SQL statement:  must return list of similarity_ids to be deleted',
     },
     {o => 'doNotVersion',
      t => 'boolean',
      h => 'if true does not version any rows,  default versions only Similarity rows',
     },
     {o => 'versionAll',
      t => 'boolean',
      h => 'if true versions all rows,  default versions only Similarity rows',
     },
     {o => 'deleteEvidence',
      t => 'boolean',
      h => 'if true deletes evidence that similarities may be used in....slow
                          if false, then need to clean up evidence tables later...more efficient?',
     },
     {o => 'log_frequency=i',
      h => 'Write line to log file once every this many entries',
      d => 100,
     },


   }];

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


my $ctx;
my $debug = 0;
$| = 1;

sub run {
  my $M   = shift;
  $ctx = shift;

  die "--idSQL are required\n" unless ($ctx->{cla}->{idSQL});

  print $ctx->{'commit'} ? "***COMMIT ON***\n" : "***COMMIT TURNED OFF***\n";

  print "Deleting similarities match query '$ctx->{cla}->{idSQL}'\n
";

  ##DBI handle to be used for queries outside the objects...
  my $dbh = $ctx->{'self_inv'}->getQueryHandle();

  if (!$ctx->{cla}->{commit}) {
    print "Not in commit mode...Determining number of similarities that satisify the query\n";
    my $stmt = $dbh->prepareAndExecute("select count(*) from similarity where  similarity_id in ($ctx->{cla}->{idSQL})");
    while (my($num) = $stmt->fetchrow_array()) {
      print "  There are $num Similarities to be deleted\n";
    }
  }

  my $ctSim;
  ##first version the Similarities...
  if (!$ctx->{cla}->{doNotVersion}) { ##version similarities..
    #    $dbh->do("set transaction use rollback segment BIGRBS0"); ##ensures using  big rollback segment
    my $ver = "insert into dotsver.SimilarityVer (select s.*,".$ctx->{self_inv}->getId().",SYSDATE,1 from dots.Similarity s where similarity_id in ($ctx->{cla}->{idSQL}))";
    print "Versioning similarities...\n\t$ver\n",`date`;
    if ($ctx->{cla}->{commit}) {
      $ctSim = $dbh->do($ver);
      $dbh->commit();
      print "\tInserted $ctSim rows into SimilarityVer: ",`date`,"\n";
    }
  }

  ##mark the similarities deleted by setting query_table_id and subject_table_id to 1
  $dbh->do("set transaction use rollback segment BIGRBS0"); ##ensures using  big rollback segment
  my $markQuery = "update dots.Similarity set query_table_id = 1, subject_table_id = 1 where similarity_id in ($ctx->{cla}->{idSQL})";
  print "marking Similarities deleted....\n\t$markQuery\n",`date`;
  if ($ctx->{cla}->{commit}) {
    print "\tUpdated ",$dbh->do($markQuery)," rows in Similarity: ",`date`,"\n";
    $dbh->commit();
  }
  
  my $ctDep = 0;

  ##next delete the SimilaritySpans
  $dbh->do("set transaction use rollback segment BIGRBS0"); ##ensures using  big rollback segment
  ##need to version if --versionAll
  if ($ctx->{cla}->{versionAll}) {
    my $verSS = "insert into dotsver.SimilaritySpanVer (select l.*,".$ctx->{self_inv}->getId().",SYSDATE,1 from dots.SimilaritySpan l where l.similarity_id in (select s.similarity_id from dots.Similarity s where s.query_table_id = 1 and s.subject_table_id = 1 ))";
    print "Versioning SimilaritySpan...$verSS\n",`date`;
    if ($ctx->{cla}->{commit}) {
      print "\tVersioned ",$dbh->do($verSS)," rows ",`date`,"\n";
      $dbh->commit();
      $dbh->do("set transaction use rollback segment BIGRBS0"); ##ensures using  big rollback segment
    }
  }
  my $delSpan = "delete from dots.similarityspan where similarity_id in (select s.similarity_id from dots.Similarity s where s.query_table_id = 1 and s.subject_table_id = 1)";
  print "Deleting SimilaritySpans ....\n\t$delSpan\n",`date`;
  if ($ctx->{cla}->{commit}) {
    $ctDep += $dbh->do($delSpan);
    $dbh->commit();
    print "\tDeleted $ctDep rows from SimilaritySpan: ",`date`,"\n";
  }

  ##now the ConsistentAlignments
  $dbh->do("set transaction use rollback segment BIGRBS0"); ##ensures using  big rollback segment
  ##need to version if --versionAll
  if ($ctx->{cla}->{versionAll}) {
    my $verCA = "insert into dotsver.ConsistentAlignmentVer (select l.*,".$ctx->{self_inv}->getId().",SYSDATE,1 from dots.ConsistentAlignment l where l.similarity_id in (select s.similarity_id from dots.Similarity s where s.query_table_id = 1 and s.subject_table_id = 1))";
    print "Versioning ConsistentAlignments...$verCA\n",`date`;
    if ($ctx->{cla}->{commit}) {
      print "\tVersioned ",$dbh->do($verCA)," rows ",`date`,"\n";
      $dbh->commit();
      $dbh->do("set transaction use rollback segment BIGRBS0"); ##ensures using  big rollback segment
    }
  }
  my $delConsAl = "delete from dots.ConsistentAlignment where similarity_id in (select s.similarity_id from dots.Similarity s where s.query_table_id =  1 and s.subject_table_id = 1)";
  print "Deleting ConsistentAlignments....\n\t$delConsAl\n",`date`;
  if ($ctx->{cla}->{commit}) {
    my $ctAl = $dbh->do($delConsAl);
    $ctDep += $ctAl;
    $dbh->commit();
    print "\tDeleted $ctAl rows from ConsistentAlignment: ",`date`,"\n";
  }

  ##now the IndexWordSimLinks
  $dbh->do("set transaction use rollback segment BIGRBS0"); ##ensures using  big rollback segment
  ##need to version if --versionAll
  if ($ctx->{cla}->{versionAll}) {
    my $verIW = "insert into dotsver.IndexWordSimLinkVer (select l.*,".$ctx->{self_inv}->getId().",SYSDATE,1 from dots.IndexWordSimLink l where l.best_similarity_id in (select s.similarity_id from dots.Similarity s where s.query_table_id = 1 and s.subject_table_id = 1 ))";
    print "Versioning IndexWordSimLinks...$verIW\n",`date`;
    if ($ctx->{cla}->{commit}) {
      print "\tVersioned ",$dbh->do($verIW)," rows ",`date`,"\n";
      $dbh->commit();
      $dbh->do("set transaction use rollback segment BIGRBS0"); ##ensures using  big rollback segment
    }
  }

  my $delIWSL = "delete from dots.IndexWordSimLink where best_similarity_id in (select s.similarity_id from dots.Similarity s where s.query_table_id = 1 and s.subject_table_id = 1 )";
  print "Deleting IndexWordSimLinks....\n\t$delIWSL\n",`date`;
  if ($ctx->{cla}->{commit}) {
    my $ctLinks = $dbh->do($delIWSL);
    $ctDep += $ctLinks;
    $dbh->commit();
    print "\tDeleted $ctLinks rows from IndexWordSimLink: ",`date`,"\n";
  }

  ##finally the similarities...use DeleteEntriesFromTable.pl to do 1000 rows at a time
  ##alternative here is to copy the table except for the entries to  be  deleted then rename etc...
  my $cmd = "deleteEntries.pl --table dots.Similarity --gusConfigFile $ctx->{cla}->{gusconfigfile}--idSQL 'select s.similarity_id from dots.Similarity s where s.query_table_id = 1 and s.subject_table_id = 1'";
  print "Deleting Similarities ...$cmd\n",`date`;
  if ($ctx->{cla}->{commit}) {
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
