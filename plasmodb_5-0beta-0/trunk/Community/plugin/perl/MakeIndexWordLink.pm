package GUS::Community::Plugin::MakeIndexWordLink;

use GUS::Model::DoTS::IndexWord;
use GUS::Model::DoTS::IndexWordLink;
use DBI;

@ISA = qw(GUS::PluginMgr::Plugin);

use strict;

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  my $usage = 'Create entries in IndexWord(Link) tables for indexing specific attributes';
  my $easycsp =
    [{o => 'testnumber',
      t => 'int',
      h => 'number of iterations for testing',
     },
     {o => 'minLength',
      t => 'int',
      h => 'Minimun length words to keep',
      d => '3',
     },
     {o => 'table',
      t => 'string',
      h => 'Table name to index (in schema::table format)',
     },
     {o => 'attribute',
      t => 'string',
      h => 'attribute to index',
      d => 'description',
     },
     { o => 'noDigits',
      t => 'boolean',
      h => 'Do not keep words that are numbers',
      d => '1',
     },
     {o => 'restart',
      t => 'boolean',
      h => 'For restarting...ignores entries from IndexWordLink from table',
     },
     {o => 'idSQL',
      t => 'string',
      h => 'sql query that returns primary_key,attribute_to_index from --table',
     },];

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
my $target_table_id; 
my $primary_key; 
my %words;                      ##hash to hold word => index_word_id
my $ctNewWords = 0;
my $totalLinks = 0;
my %taxon;                      ##genus and species

sub run {
  my $M   = shift;
  $ctx = shift;

  print STDERR $ctx->{cla}->{'commit'} ? "***COMMIT ON***\n" : "***COMMIT TURNED OFF***\n";
  print STDERR "Testing on $ctx->{cla}->{'testnumber'}\n" if $ctx->{cla}->{'testnumber'};

  die "--table and (--attribute or --idSQL) are required arguments\n" unless $ctx->{cla}->{table} && ($ctx->{cla}->{table} || $ctx->{cla}->{table});

  my $dbh = $ctx->{self_inv}->getQueryHandle();

  $target_table_id = $ctx->{self_inv}->getTableIdFromTableName($ctx->{cla}->{table});
  $primary_key = $ctx->{self_inv}->getTablePKFromTableId($target_table_id);

  ##first need to get the current list of words from IndexWord
  my $wdStmt = $dbh->prepare("select index_word_id,word from dots.IndexWord");
  $wdStmt->execute();
  while (my($i,$w) = $wdStmt->fetchrow_array()) {
    $words{$w} = $i;
  }
  $wdStmt->finish();
  print STDERR "Fetched ".scalar(keys%words)." IndexWords from db\n";

  ##next need to get genus and species so can not index these!!

  my $sql = 
"select name
from sres.taxonName, sres.taxon
where rank = 'species'
and name_class = 'scientific name'
and rownum < 100";

  my $taxStmt = $dbh->prepare($sql);
  $taxStmt->execute();
  while (my($name) = $taxStmt->fetchrow_array()) {
    my @a = split(/\s+/, $name);
    foreach my $a (@a) { $taxon{$a} = 1; print STDERR "adding $a to taxon\n";}
  }
  $taxStmt->finish();
  print STDERR "Ignoring ".scalar(keys%taxon)." organism names\n";

  ##need to also be able to restart....
  my %restart;
  if ($ctx->{cla}->{restart}) {
    my $resStmt = $dbh->prepare("select target_id from dots.IndexWordLink where target_table_id = $target_table_id");
    $resStmt->execute() || die $DBI::errstr;
    while (my($i) = $resStmt->fetchrow_array()) {
      $restart{$i} = 1;
    }
    print STDERR "restarting, ignoring ".scalar(keys%restart)." target_ids\n";
    $resStmt->finish();
  }

  my ($sch, $tbl) = split(/::/, $ctx->{cla}->{table});
  my $query = "select $primary_key,$ctx->{cla}->{attribute} from $sch.$tbl where $ctx->{cla}->{attribute} is not null";
  print STDERR "Query: ",($ctx->{cla}->{idSQL} ? "$ctx->{cla}->{idSQL}\n" : "$query\n") if $debug;
  my $stmt = $dbh->prepare($ctx->{cla}->{idSQL} ? $ctx->{cla}->{idSQL} : $query);

  $stmt->execute() || die $DBI::errstr;
	
  my $ct = 0;
  while (my($id,$desc) = $stmt->fetchrow_array()) {
    next if exists $restart{$id};
    if ($ctx->{cla}->{testnumber} && $ct >= $ctx->{cla}->{testnumber}) {
      $stmt->finish();
      last;
    }
    $ct++;
    print STDERR "Processing $ct: ".`date` if $ct % 1000 == 0;
    print STDERR "$id: $desc\n" if $debug;

    ##need to do something about genus/species things.....think about this!!
    ##could get all from taxon table and then ignore!!!YES...only 55k entries!!
    
    ##need to remove dups...
    my %words;
    foreach my $wd (split(' +',$desc)) {
      $words{$wd} = 1;
    }
    foreach my $wd (keys%words){
      &processWord($id,$wd);
    }
    $ctx->{self_inv}->undefPointerCache();
  }
  $dbh->disconnect();           ##close database connection

  ############################################################
  # return status
  # replace word "done" with meaningful return value/summary
  ############################################################
  return "created index words for $ct $ctx->{cla}->{table}.$ctx->{cla}->{attribute} rows, $ctNewWords new words and $totalLinks words indexed";
}

##subs
sub processWord {
  my($id,$word) = @_;
  $word =~ tr/A-Z/a-z/;
  $word =~ s/-/Z/g;
  $word =~ s/\W//g;
  $word =~ s/Z/-/g;

  ##if following removal of "-" I have only digits then return...
  my $tmp = $word;
  $tmp =~ s/-//g;
  return if $tmp =~ /^\d+$/;

  ##need to deal with those "-" appropriately!!
  ## remove "-" from beginning...
  $word =~ s/^-+//;
  ##get rid  of ones from end...
  while ($word =~ /-$/) {
    chop $word;
  }

  ##create link obj and submit..
  &createIWL($id,$word);

  ##want to submit things with "-" as individual words
  my @split = split('-',$word);
  if (scalar(@split) > 1) {
    foreach my $w (@split) {
      &createIWL($id,$w);
    }
  }
}

sub createIWL {
  my($id,$word) = @_;
  ##apply filters..
  return if length($word) < $ctx->{cla}->{minLength};
  return if $ctx->{cla}->{noDigits} && $word =~ /^\d+$/;
  return if $word =~ /^\w{1,2}\d+$/; ##looks like an accession from nrdb...
  return if $word =~ /^(protein|the|from|gene|type|region|product|putative|factor|peptide|and)$/;
  return if $word =~ /^(dna|with|singleton|identity|unnamed|unknown|similarities|null|for)$/;
  return if exists $taxon{$word}; ##orgnanism name
  print STDERR "$word\n" if $debug;
  my $wl = GUS::Model::DoTS::IndexWordLink->
    new({'target_table_id' => $target_table_id,
	 'target_id' => $id,
	 'index_word_id' => &getWordId($word,$id),
	});
  $wl->submit();
  $totalLinks++;
}

sub getWordId {
  my($word,$id) = @_;
  if (!exists $words{$word}) {  ##is new word
    #		print STDERR "New Word $id: '$word'\n";
    $ctNewWords++;
    my $iw = GUS::Model::DoTS::IndexWord->new({'word' => $word});
    $iw->submit();
    $words{$word} = $iw->getId();
  }
  return $words{$word};
}

1;

