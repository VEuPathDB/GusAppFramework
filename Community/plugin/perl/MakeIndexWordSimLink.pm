package GUS::Community::Plugin::MakeIndexWordSimLink;

use GUS::Model::DoTS::Similarity;
use GUS::Model::DoTS::IndexWordSimLink;
use DBI;

@ISA = qw(GUS::PluginMgr::Plugin);

use strict;

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  my $usage = 'Make materialized view for IndexWordNeighbor';
  my $easycsp =
    [{o => 'testnumber',
      t => 'int',
      h => 'number of iterations for testing',
     },
     {o => 'restart',
      t => 'boolean',
      h => 'Restarts ignoring sequences already in IndexWordSimLink from target_table and similarity_table',
     },
     {o => 'target_table',
      t => 'string',
      h => 'table that am creating entries for.... (schema::table format)',
     },
     {o => 'max_p_value',
      t => 'float',
      h => 'maximum P Value for valid neighbors (similarities)',
      d => 1e-10,
     },
     {o => 'similarity_table',
      t => 'string',
      h => 'table for IndexWordLink (currently DoTS::MotifAASequence|DoTS::ExternalAASequence)',
     },
     {o => 'idSQL',
      t => 'string',
      h => 'sql query that returns primary keys for the target_table for indexing',
     },
     {o => 'ignoreAlgInv',
      t => 'string',
      h => 'includes " and s.row_alg_invocation_id not in (ignoreAlgInv)" in similarity query',
     },
     {o => 'log_frequency',
      t => 'int',
      h => 'frequency for writing to log (per id processed)',
      d => 10,
     },
     {o => 'update',
      t => 'boolean',
      h => 'update existing rows rather than create new',
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

  print $ctx->{cla}->{'commit'} ? "***COMMIT ON***\n" : "***COMMIT TURNED OFF***\n";
  print "Testing on $ctx->{cla}->{'testnumber'}\n" if $ctx->{cla}->{'testnumber'};

  die "You must provide  --target_table, --similarity_table and --idSQL on command line\n" unless $ctx->{cla}->{target_table} && $ctx->{cla}->{similarity_table} && $ctx->{cla}->{idSQL};
  my $target_table_id = $ctx->{self_inv}->getTableIdFromTableName($ctx->{cla}->{target_table});
  #	my $target_table_pk = $ctx->{self_inv}->getTablePKFromTableId($target_table_id);
  my $similarity_table_id = $ctx->{self_inv}->getTableIdFromTableName($ctx->{cla}->{similarity_table});

  my $dbh =  $ctx->{self_inv}->getQueryHandle();
	
  my %ignore;
  if ($ctx->{cla}->{restart}) {
    print STDERR "Restarting....\n";
    my $resStmt = $dbh->prepare("select target_id from Dots.IndexWordSimLink where target_table_id = $target_table_id and similarity_table_id = $similarity_table_id");
    $resStmt->execute();
    my $ct = 0;
    while (my($rs_id) = $resStmt->fetchrow_array()) {
      $ct++;
      print STDERR "Reading in $ct rows from RNAIndexWord\n" if $ct % 10000 == 0;
      $ignore{$rs_id} = 1;
    }
    $resStmt->finish();
    print STDERR "Ignoring ".scalar(keys%ignore)." entries already processed\n";
  }


  my $loopStmt = $dbh->prepare($ctx->{cla}->{idSQL});

  ##and s.pValue <= $ctx->{cla}->{max_p_value}
  my $bestSQL =  
"select wl.index_word_id,s.similarity_id,s.pvalue_mant,pvalue_exp,s.score
  from dots.Similarity s,  dots.IndexWordLink wl
  where s.query_id = ?
  and s.query_table_id = $target_table_id 
  and wl.target_table_id = $similarity_table_id
  and wl.target_id = s.subject_id";
  
  ##now  if want to ignore specific algorithminvocations of similarities
  $bestSQL .= " and s.row_alg_invocation_id not in ($ctx->{cla}->{ignoreAlgInv})" if $ctx->{cla}->{ignoreAlgInv};

  $bestSQL .= " order by wl.index_word_id,s.pvalue_exp,s.pvalue_mant";

  my $bestStmt = $dbh->prepare($bestSQL);

  my $delStmt;
  my $sql = 
"select * from dots.IndexWordSimLink 
where target_table_id = $target_table_id 
and target_id = ? 
and similarity_table_id = $similarity_table_id";
  $delStmt = $dbh->prepare($sql) if $ctx->{cla}->{update};
	

  $loopStmt->execute();
  ##note perhaps should put into datastructure so don't tie up sybase resources
  my %data;
  my $ct = 0;
  while (my($rs) = $loopStmt->fetchrow_array()) {
    next if exists $ignore{$rs}; ##already have processed this one!!
    $ct++;
    print STDERR "Retrieving $ct\n" if $ct % 10000 == 0;
    $data{$rs} = 1;
    #		push(@data, $rs);
    ##implement testnumber....
    last if($ctx->{cla}->{testnumber} && scalar(keys%data) >= $ctx->{cla}->{testnumber});
  }
  $loopStmt->finish();
  undef %ignore;                ##free this memory
  print STDERR "Inserting IndexWordNeighbor for ".scalar(keys%data)." $ctx->{cla}->{target_table} rows\n";
  $ct = 0;
  my $ctInserts = 0;
  my $ctDeletes = 0;
  my @submit;
  foreach my $id (keys%data) {
    $ct++;
    print STDERR "$ctx->{cla}->{target_table}.$id: Processing $ct " . ($ct % ($ctx->{cla}->{log_frequency} * 10) == 0 ? `date` : "\n") if $ct % $ctx->{cla}->{log_frequency} == 0;

    ##implement updating...need to just delete rows for this target_id before proceeding...
    if ($ctx->{cla}->{update}) {
      $delStmt->execute($id);
      while (my ($del_id) = $delStmt->fetchrow_array()) {
        my $del = IndexWordNeighbor->new({'index_word_sim_link_id' => $del_id});
        $del->setVersionable(0); ##don't version this as is derived...
        $del->markDeleted();
        push(@submit,$del);
        $ctDeletes++;
      }
    }

    $bestStmt->execute($id);
    my %have;
    while (my($iw_id,$sim_id,$pMant,$pExp,$score) = $bestStmt->fetchrow_array()) {
      next if $have{$iw_id};
      $have{$iw_id} = 1;
      #			print STDERR  "Processing index_word $iw_id\n";
      ##first create Similarity Object as that gives the pValue
      my $sim = GUS::Model::DoTS::Similarity->new({'similarity_id' => $sim_id,
                                 'pvalue_mant' => $pMant,
                                 'pvalue_exp' => $pExp });
      next if $sim->getPValue() > $ctx->{cla}->{max_p_value};
      my $rwl = GUS::Model::DoTS::IndexWordSimLink->new({'target_id' => $id,
                                       'target_table_id' => $target_table_id,
                                       'similarity_table_id' => $similarity_table_id,
                                       'index_word_id' => $iw_id,
                                       'best_similarity_id' => $sim_id,
                                       'best_p_value_mant' => $pMant,
                                       'best_p_value_exp' => $pExp,
                                       'best_score' => $score });
      push(@submit,$rwl);
      $ctInserts++;
    }
    ##submit the sucker!!
    $ctx->{self_inv}->manageTransaction(undef,'begin');
    foreach my $iwn (@submit) {
      $iwn->submit(undef,1);
    }
    $ctx->{self_inv}->manageTransaction(undef,'commit');
		
    ##reset for the next one...
    undef @submit;
    $ctx->{self_inv}->undefPointerCache();
  }
	
	
  $dbh->disconnect();           ##close database connection

  ############################################################
  # return status
  # replace word "done" with meaningful return value/summary
  ############################################################
  my $result = "Processed ".scalar(keys%data). " $ctx->{cla}->{target_table}: Inserted $ctInserts and deleted $ctDeletes rows in IndexWordSimLink";
  print STDERR "$result\n";
  return $result;
}

1;

__END__

=pod
=head1 Description
B<Template> - a template plug-in for C<ga> (GUS application) package.

=head1 Purpose
B<Template> is a minimal 'plug-in' GUS application.

=cut
