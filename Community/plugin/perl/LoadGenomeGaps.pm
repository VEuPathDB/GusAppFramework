# ----------------------------------------------------------------------
# LoadGenomeGaps.pm
#
# load gap info into temp space, this is needed by LoadBLATAlignment
#
# Created by Thomas Gan: Wed Mar 24 14:09:35 EST 2004
#
# $Revision$ $Date$ $Author$
# ----------------------------------------------------------------------

package GUS::Community::Plugin::LoadGenomeGaps;

@ISA = qw(GUS::PluginMgr::Plugin);
 
use strict;
use DBI;
$| = 1;

sub new {
    my $class = shift;

    my $self = {};
    bless($self,$class);

    my $usage = 'Plug_in to load genome gap info into temp tablespace)';

  my $easycsp =
    [{o => 'genomeVersion',
      t => 'string',
      h => 'goldenpath genome version, e.g. hg16, mm4',
     }, 
     {o => 'gapDir',
      t => 'string',
      h => 'directory containing gap info',
      d => '',
     },
     {o => 'tempLogin',
      t => 'string',
      h => 'login for space being used for temp table eg ygan',
     },
     {o => 'tempPassword',
      t => 'string',
      h => 'password for space being used for temp table',
     },
     {o => 'dbiStr',
      t	=> 'string',
      h => 'server and machine for temp table, e.g. dbi:Oracle:host=cbilbld.pcbi.upenn.edu;sid=cbilbld',
     },
     {o => 'delete',
      t	=> 'boolean',
      h => 'delete previous or partially loaded gap info to start from anew',
     }
     ];

  $self->initialize({requiredDbVersion => {},
		  cvsRevision => '$Revision$', # cvs fills this in!
		  cvsTag => '$Name$', # cvs fills this in!
		  name => ref($self),
		  revisionNotes => 'stub created',
		  easyCspOptions => $easycsp,
		  usage => $usage
		 });

  return $self;
}

sub run {
    my $self  = shift;
    $self->getArgs()->{'commit'} ? $self->log("***COMMIT ON***\n") : $self->log("**COMMIT TURNED OFF**\n");
    
    my $genomeVer = $self->getArgs()->{'genomeVersion'} || die "genomeVersion not supplied\n";
    my $gapDir = $self->getArgs()->{'gapDir'} || die "gapDir not supplied\n";
    my $tempLogin = $self->getArgs()->{'tempLogin'} || die " not supplied\n";
    my $tempPassword = $self->getArgs()->{'tempPassword'} || die " not supplied\n";
    my $DBI_STR = $self->getArgs->{'dbiStr'} || die "must provide server and sid for temp table\n";
    my $dbh = DBI->connect($DBI_STR, $tempLogin, $tempPassword);

    my $chrs = &_getChrs($dbh, $genomeVer);
    my $tables = {};
    foreach my $chr (keys %$chrs) {
	my $table = $genomeVer . '_' . "chr$chr" . '_gap';
	$tables->{$chr} = $table;
        $dbh->do("drop table $table") or print "was not able to drop table $table, maybe doesnot exist\n"; 
        &_createGapTable($dbh, $table);
    }

    my @chrs = `ls $gapDir`;
    foreach my $chr(@chrs) {
	chomp $chr;
	my $c = $1 if $chr =~ /chr(\S+)_gap/;
	my $table = $tables->{$c};
	next unless $table;

	my $gap_file = "$gapDir/$chr";
	open IN, "$gap_file";
	my $count = 0;

	my ($sql, $sth);
	while(my $line = <IN>) {
	    next if $line =~ /^\#/;
	    if($line =~
	       /^(\d+)\s+(chr[\w|\_]+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\S)\s+(\d+)\s+(\S+)\s+(\S+)/) {
		my ($b,$c,$s,$e,$ix,$n,$sz,$t,$br) = ($1,$2,$3,$4,$5,$6,$7,$8,$9);
		$n =~ s/\'/\'\'/g;
		$sql = "insert into $table(bin, chrom, chromstart, chromend, \n"
		    . "ix, n, length, type, bridge) \n"
		    . "values($b, '$c', $s, $e, $ix, '$n', $sz, '$t', '$br')\n";
		$sth = $dbh->prepare($sql);
		$count++;
		$sth->execute() or die "could not run $sql";
	    }
	}
	close IN;
	$sth->finish if $sth;
	print "loaded $count gaps into $table from $gapDir/$chr\n";
    }
    $dbh->commit;
    return "genome gaps loaded";
}
#-------------------------

sub _getChrs {
    my ($dbh, $gVer) = @_;

    my $sql = "select vs.chromosome from DoTS.VirtualSequence vs, SRES.ExternalDatabaseRelease dbr "
            . "where vs.external_database_release_id = dbr.external_database_release_id "
            . "and dbr.version like '$gVer%'";
    my $sth = $dbh->prepare($sql) or die "bad sql $sql: $!\n";
    $sth->execute or die "could not run $sql: $!\n";
    my $chrs = {};
    while (my ($c) = $sth->fetchrow_array) { $chrs->{$c} = ''; }
    $chrs;
}

sub _unload {
    my ($dbh, $db) = @_;

    my $db_rel_id = &_getDBReleaseID($dbh, $db);

    my $sql = "select chromosome from dots.VirtualSequence "
	 . "where external_database_release_id = $db_rel_id "
	 . "order by chromosome_order_num asc";
    my $sth = $dbh->prepare($sql) or die "bad sql $sql: $!\n";
    $sth->execute or print "skip execution of $sql: $!\n";
    my @chrs;
    while (my ($c) = $sth->fetchrow_array) { push @chrs, $c; }

    foreach my $c (@chrs) {
	my $tbl = $db . '_' . "chr$c" . '_gap';
	$sql = "drop table $tbl";
        print "dropping table $tbl...\n";
	$sth = $dbh->do($sql) or print "# WARNING: did not drop table $tbl: $!\n";
    }
    if (defined($sth)) { $sth->finish; }
}

sub _getDBReleaseID {
    my ($dbh, $db) = @_;

    my $sql = "select external_database_release_id " .
	      "from sres.ExternalDatabaseRelease " .
	      "where version like '$db:%'";
    
    my $sth = $dbh->prepare($sql) or die "bad sql $sql: $!\n";
    $sth->execute or print "skip execution of $sql: $!\n";
    my @ids;
    while (my ($id) = $sth->fetchrow_array) { push @ids, $id; }
    my $c = scalar(@ids);
    die "ERROR: expected 1 release id for $db but got $c\n" if $c != 1;

    $ids[0];
}

sub _createGapTable {
    my ($dbh, $tbl) = @_;

    my $sql = "create table $tbl("
	    . "BIN NUMBER(6),  CHROM VARCHAR2(255), CHROMSTART NUMBER(10), "
	    . "CHROMEND NUMBER(10), IX NUMBER(11), N CHAR(1),  LENGTH NUMBER(10), "
	    . "TYPE VARCHAR2(255), BRIDGE VARCHAR2(255))";
    my $sth = $dbh->prepare($sql) or die "bad sql $sql: $!\n";
    print "sql=$sql\n";
    $sth->execute or print "# WARNING: could not create table $tbl$!\n";

    $sql = "grant select on $tbl to public";
    $sth = $dbh->do($sql) or die "could not grant permission to $tbl:$!\n";
}

1;
