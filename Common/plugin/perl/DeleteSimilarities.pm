package GUS::Common::Plugin::DeleteSimilarities;

@ISA = qw(GUS::PluginMgr::Plugin); 
use strict;
$| = 1;
sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  my $usage = 'version Similarities given query_table and idSQL identifying rows in that table and deletes all dependent children (SimilaritySpans and IndexWordSimLinks';

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
     {o => 'testnumber',
      t => 'int',
      h => 'number of iteratins for testing',
     }
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



$| = 1;

sub run {
  my $self   = shift;

  die "--idSQL are required\n" unless ($self->getArgs()->{idSQL});

  $self->log ($self->getArgs()->{'commit'} ? "***COMMIT ON***\n" : "***COMMIT TURNED OFF***\n");

  $self->log ("Deleting similarities match query ".$self->getArgs()->{idSQL}."\n");

  $self->getIds();

}

sub getIds {
  my ($self) = @_;

  my $dbh = $self->getQueryHandle();

  my $idSQL = $self->getArgs()->{'idSQL'};

  my $stmt = $dbh->prepareAndExecute($idSQL);

  my $total;
  my @ids;
  my $ct;

  while (my ($id) = $stmt->fetchrow_array()){
    push (@ids,$id);
    $ct++;	
    if ($self->getArgs()->{'testnumber'} && $ct > $self->getArgs()->{'testnumber'}) {
      last;
    }
    if ($ct % 1000 == 0) {
      my $del = $self->doDeletes(\@ids);
      $total += $del;
      @ids = ();
    }	
  }
  if ($ct > 0 && $ct % 1000 != 0) {
    my $del = $self->doDeletes(\@ids);
    $total += $del;
  }
  $self->log ("$total Similarity rows and children deleted\n");
  $self->log ("$ct Similarity rows should have been deleted\n"); 
}	


sub doDeletes {
	my ($self,$ids) = @_;
	my $dbh = $self->getQueryHandle();
	my $max = (scalar(@$ids) - 1); 

	my $rows = $dbh->do("insert into dotsver.SimilarityVer (select s.*,".$self->getAlgInvocation->getId.",SYSDATE,1 from dots.Similarity s where similarity_id in (".join(', ',@{$ids}[0..$max])."))") unless $self->getArgs()->{'doNotVersion'};
	$self->log("Inserted $rows into dotsver.SimilarityVer, $$ids[0] - $$ids[$max]\n") unless $self->getArgs()->{'doNotVersion'};


	my $rows2 = $dbh->do("insert into dotsver.SimilaritySpanVer (select l.*,".$self->getAlgInvocation->getId.",SYSDATE,1 from dots.SimilaritySpan l where l.similarity_id in (".join(', ',@{$ids}[0..$max])."))") if $self->getArgs->{'versionAll'};
	$self->log("Inserted $rows2 into dotsver.SimilaritySpanVer\n") if $self->getArgs->{'versionAll'};

	my $rows3 = $dbh->do("delete from dots.similarityspan where similarity_id in (".join(', ',@{$ids}[0..$max]).")");
	$self->log("$rows3 row of dots.similarityspan deleted\n");

	my $rows4 = $dbh->do("insert into dotsver.IndexWordSimLinkVer (select l.*,".$self->getAlgInvocation->getId.",SYSDATE,1 from dots.IndexWordSimLink l where l.best_similarity_id in (".join(', ',@{$ids}[0..$max])."))") if $self->getArgs->{'versionAll'};
	$self->log("Inserted $rows4 rows into dotsver.IndexWordSimLinkVer\n") if $self->getArgs->{'versionAll'};

	my $rows5 = $dbh->do("delete from dots.IndexWordSimLink where best_similarity_id in (".join(', ',@{$ids}[0..$max]).")");
	$self->log("$rows5 row of dots.IndexWordSimLink deleted\n");

	my $rows6 = $dbh->do("delete from dots.Similarity where similarity_id in (".join(', ',@{$ids}[0..$max]).")");
	$self->log("$rows6 row of dots.Similarity deleted\n");

	if ($self->getArgs()->{'commit'}) {
		$dbh->commit;
	}
	else {
		$dbh->rollback;
	}
	return $rows6;
}


1;

__END__

=pod
=head1 Description
B<Template> - a template plug-in for C<ga> (GUS application) package.

=head1 Purpose
B<Template> is a minimal 'plug-in' GUS application.

=cut
