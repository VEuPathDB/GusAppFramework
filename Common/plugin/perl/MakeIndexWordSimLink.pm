package GUS::Common::Plugin::MakeIndexWordSimLink;

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
     {o => 'query_table',
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
      h => 'sql query that returns query_id from the Similarity table for indexing, e.g. select distinct na_sequence_id from dots.similarity where s.query_table_id = 56 and s.subject_table_id = 277',
     },
     {o => 'idQuerySQL',
      t => 'string',
      h => 'sql query that returns primary keys from the query table, e.g. select na_sequence_id from dots.assembly where taxon_id = 8',
     },
     {o => 'range',
      t => 'int',
      h => 'number of primary keys returned per iteration',
      d => 1000,
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


$| = 1;

sub run {
  my ($self)   = shift;

  print $self->getArgs()->{'commit'} ? "***COMMIT ON***\n" : "***COMMIT TURNED OFF***\n";
  print "Testing on $self->getArgs()->{'testnumber'}\n" if $self->getArgs()>{'testnumber'};

  die "You must provide  --query_table, --idQuerySQL, --range, --similarity_table and --idSQL on command line\n" unless $self->getArgs()->{query_table} && $self->getArgs()->{similarity_table} && $self->getArgs()->{idSQL} && $self->getArgs()->{idQuerySQL};

  my $ignore = $self->restart() if $self->getArgs()->{restart};

  my $primArr = $self->getPrimaryArr();

  my ($ctDeletes,$ctInserts,$ct) = $self->makeLoop($ignore,$primArr);

  my $result = "Processed $ct". $self->getArgs()->{target_table}.": Inserted $ctInserts and deleted $ctDeletes rows in IndexWordSimLink";
  print STDERR "$result\n";
  return $result;
}

sub restart {

  my ($self) = @_;

  my $algoInvo = $self->getAlgInvocation();

  my $dbh = $self->getQueryHandle();

  my $query_table_id = $algoInvo->getTableIdFromTableName($self->getArgs()->{query_table});

  my $similarity_table_id = $algoInvo->getTableIdFromTableName($$self->getArgs()->{similarity_table});

  my %ignore;

  $self->log ("Restarting....\n");
  
  my $resStmt = $dbh->prepare("select target_id from Dots.IndexWordSimLink where target_table_id = $query_table_id and similarity_table_id = $similarity_table_id");
    
  $resStmt->execute();
    
  my $ct = 0;
    
  while (my($rs_id) = $resStmt->fetchrow_array()) {
    $ct++;
    $self->log ("Reading in $ct rows from RNAIndexWord\n") if $ct % 10000 == 0;
    $ignore{$rs_id} = 1;
  }
  
  $resStmt->finish();

  $self->log ("Ignoring ".scalar(keys%ignore)." entries already processed\n");

  return \%ignore;
}

sub getPrimaryArr {

  my ($self) = @_;

  my $dbh = $self->getQueryHandle();

  my $stmt = $dbh->prepareAndExecute($self->getArgs()->{idQuerySQL});

  my $refArr = $stmt->fetchall_arrayref();

  my @arr;

  foreach my $row (@$refArr) {
    push (@arr, @$row);
  }
    

  my @primArr = sort {$a <=> $b} @arr;

  return \@primArr;
}

sub makeLoop {

  my ($self,$ignore,$primArr) = @_;

  my $range = $self->getArgs()->{range};

  my $start = 0;

  my $end = ($range - 1);

  my $arrLength = @$primArr;

  my ($ctDeletes,$ctInserts,$ct);

  while ($start < $arrLength) {

    my ($Deletes,$Inserts,$count) = $self->getQueryIds($ignore,$start,$end,$primArr);

    $ctDeletes += $Deletes;

    $ctInserts += $Inserts;

    $ct += $count;

    $start += $range;

    if ($start > ($arrLength - 1)) {
      last;
    }
    $end = $end < $arrLength  ? ($end + $range) : ($arrLength - 1);

  }

  return ($ctDeletes,$ctInserts,$ct);
}

sub getQueryIds {

  my ($self,$ignore,$start,$end,$primArr) = @_;

  my $dbh = $self->getQueryHandle();

  my $idSQL = $self->getArgs()->{idSQL}." and query_id in (". join(' , ',@{$primArr}[$start..$end]).")";

  my $stmt = $dbh->prepare($idSQL);

  $stmt->execute();

  my %data;

  my $ct = 0;

  while (my($rs) = $stmt->fetchrow_array()) {

    next if exists $ignore->{$rs};

    $ct++;

    $data{$rs} = 1;

  }

  $stmt->finish();

  my ($ctDeletes,$ctInserts) = $self->processData(\%data);

  return ($ctDeletes,$ctInserts,$ct);

}

sub processData {

  my ($self,$data) = @_;

  my $algoInvo = $self->getAlgInvocation();

  my $query_table_id = $algoInvo->getTableIdFromTableName($self->getArgs()->{query_table});

  my $similarity_table_id = $algoInvo->getTableIdFromTableName($$self->getArgs()->{similarity_table});

  my $dbh = $self->getQueryHandle();

  my $bestSQL = "select wl.index_word_id,s.similarity_id,s.pvalue_mant,pvalue_exp,s.score
  from dots.Similarity s,  dots.IndexWordLink wl
  where s.query_id = ?
  and s.query_table_id = $query_table_id 
  and wl.target_table_id = $similarity_table_id
  and wl.target_id = s.subject_id";
  
  ##now  if want to ignore specific algorithminvocations of similarities
  $bestSQL .= " and s.row_alg_invocation_id not in ($self->getArgs()->{ignoreAlgInv})" if $self->getArgs()->{ignoreAlgInv};
  
  $bestSQL .= " order by wl.index_word_id,s.pvalue_exp,s.pvalue_mant";
  
  my $bestStmt = $dbh->prepare($bestSQL);

  my $delStmt;
  my $sql = "select * from dots.IndexWordSimLink 
  where target_table_id = $query_table_id 
  and target_id = ? 
  and similarity_table_id = $similarity_table_id";

  $delStmt = $dbh->prepare($sql) if $self->getArgs()->{update};

  $self->log ("Inserting IndexWordNeighbor for ".scalar (keys %{$data})." $self->getArgs()->{target_table} rows\n");
  
  my $ct = 0;
  my $ctInserts = 0;
  my $ctDeletes = 0;
  my @submit;
  foreach my $id (keys %$data) {
    $ct++;
    $self->log ($self->getArgs()->{query_table}."$id: Processing $ct " . ($ct % ($self->getArgs()->{log_frequency} * 10) == 0 ? `date` : "\n")) if $ct % $self->getArgs()->{log_frequency} == 0;
    
    ##implement updating...need to just delete rows for this target_id before proceeding...
    if ($self->getArgs()->{update}) {
      $delStmt->execute($id);
      while (my ($del_id) = $delStmt->fetchrow_array()) {
        my $del = GUS::Model::DoTS::IndexWordSimLink->new({'index_word_sim_link_id' => $del_id});
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
      next if $sim->getPValue() > $self->getArgs()->{max_p_value};
      my $rwl = GUS::Model::DoTS::IndexWordSimLink->new({'target_id' => $id,
							 'target_table_id' => $query_table_id,
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
    my $algoInvo = $self->getAlgInvocation();
    $algoInvo->manageTransaction(undef,'begin');
    foreach my $iwn (@submit) {
      $iwn->submit(undef,1);
    }
    $algoInvo->manageTransaction(undef,'commit');
    
    ##reset for the next one...
    undef @submit;
    $algoInvo->undefPointerCache();
    return ($ctDeletes,$ctInserts);
  }
}
  1;


__END__

=pod
=head1 Description
B<Template> - a template plug-in for C<ga> (GUS application) package.

=head1 Purpose
B<Template> is a minimal 'plug-in' GUS application.

=cut
