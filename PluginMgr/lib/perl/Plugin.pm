
package GUS::PluginMgr::Plugin;

use strict 'vars';

use CBIL::Util::A;
use CBIL::Util::Disp;

use GUS::ObjRelP::DbiDatabase;

# ----------------------------------------------------------------------
# CLASS methods
# ----------------------------------------------------------------------

sub new {
	my $C = shift;
	my $A = shift;

	my $m = bless {}, $C;

	$m->log('ERROR',
					'You have not overridden the new method.',
					ref $m,
				 );

	$m->initialize($A);

	$m
}

# ----------------------------------------------------------------------
# INSTANCE methods
# ----------------------------------------------------------------------

# should be overridden in subclass
sub initialize {
	my $M = shift;
	my $A = shift;

	$M->log('ERROR',
					'You have not overridden the initialize method.',
					ref $M,
				 );

	# RETURN
	$M
}

# ----------------------------------------------------------------------
# TO-BE-SET by subclass to ensure good behavior
# ----------------------------------------------------------------------

# what does the plugin do, i.e., GUS::Model::Core::Algorithm
sub getUsage             { $_[0]->{__gus__plugin__USAGE} }
sub setUsage             { $_[0]->{__gus__plugin__USAGE} = $_[1]; $_[0] }

# what version of the schema does the plugin require?
sub getRequiredDbVersion { $_[0]->{__gus__plugin__RQ_DB_VERSION} }
sub setRequiredDbVersion { $_[0]->{__gus__plugin__RQ_DB_VERSION} = $_[1]; $_[0] }

# what version of the implementation is this?
sub getVersion           { $_[0]->{__gus__plugin__VERSION} }
sub setVersion           { $_[0]->{__gus__plugin__VERSION} = $_[1]; $_[0] }

# description about the implementation
sub getDescription       { $_[0]->{__gus__plugin__DESCRIPTION} }
sub setDescription       { $_[0]->{__gus__plugin__DESCRIPTION} = $_[1]; $_[0] }

# what options are needed
sub getEasyCspOptions    { $_[0]->{__gus__plugin__ECO} }
sub setEasyCspOptions    {
	my $M = shift;

	my $args_n = scalar @_;
	my $type_s = ref $_[0];

	# list (of assumed hash refs)
	if ($args_n > 1) {
		$M->{__gus__plugin__ECO} = { map {($_->{o},$_)} @_ };
	}

	# list ref (of assumed hash refs)
	elsif ($type_s eq 'ARRAY') {
		$M->{__gus__plugin__ECO} = { map {($_->{o},$_)} @{$_[0]} };
	}

	# direct hash ref
	else {
		$_[0]->{__gus__plugin__ECO} = $_[1];
	}

	# RETURN
	$M
}

# ----------------------------------------------------------------------
# NOT-TO-BE_OVERRIDDEN methods
# ----------------------------------------------------------------------

# is the plugin ok, i.e., ready to run
sub getOk         { $_[0]->{__gus__plugin__OK} }
sub setOk         { $_[0]->{__gus__plugin__OK} = $_[1]; $_[0] }

# the name of the plugin
sub getName       { $_[0]->{__gus__plugin__name} }
sub setName       {
	my $M = shift;
	my $N = shift;

	$M->{__gus__plugin__name} = $N;
	my $c = $N; $c =~ s/::/\//g; $c .= '.pm';
	$M->setNameAsPath($c);
	$c = "GUS30/GA_plugins/$c" unless $c =~ /^GUS30\//;
	$M->setFile($INC{$c});

	# RETURN
	$M
 }

# file that contains the plugin
sub getFile       { $_[0]->{__gus__plugin__FILE} }
sub setFile       { $_[0]->{__gus__plugin__FILE} = $_[1]; $_[0] }

# module name as path
sub getNameAsPath { $_[0]->{__gus__plugin__NAMEASPATH} }
sub setNameAsPath { $_[0]->{__gus__plugin__NAMEASPATH} = $_[1]; $_[0] }

# hmm, what did I mean by this?
sub getStatus     { $_[0]->{__gus__plugin__status} }
sub setStatus     { $_[0]->{__gus__plugin__status} = $_[1]; $_[0] }

# command line options as parsed
sub getCla        { $_[0]->{__gus__plugin__cla} }
sub setCla        { $_[0]->{__gus__plugin__cla} = $_[1]; $_[0] }

# the DBI database
sub getDb         { $_[0]->{__gus__plugin__db} }
sub setDb         { $_[0]->{__gus__plugin__db} = $_[1]; $_[0] }

# the GUS::Model::Core::AlgorithmInvocation for current run
sub getSelfInv    { $_[0]->{__gus__plugin__self_inv} }
sub setSelfInv    { $_[0]->{__gus__plugin__self_inv} = $_[1]; $_[0] }

# User, Group, and Project ids
# Note that the user, group, and project names are in the ...
sub getUserId     { $_[0]->{__gus__plugin__user_id} }
sub setUserId     { $_[0]->{__gus__plugin__user_id}    = $_[1]; $_[0] }

sub getGroupId    { $_[0]->{__gus__plugin__group_id} }
sub setGroupId    { $_[0]->{__gus__plugin__group_id}   = $_[1]; $_[0] }

sub getProjectId  { $_[0]->{__gus__plugin__project_id} }
sub setProjectId  { $_[0]->{__gus__plugin__project_id} = $_[1]; $_[0] }

# ----------------------------------------------------------------------
# Accessors without set-ters.

sub getQueryHandle    { $_[0]->getDb ? $_[0]->getDb->getQueryHandle : undef }

sub undefPointerCache {	$_[0]->getSelfInv->undefPointerCache }

sub getCheckSum {
	my $M = shift;

	my $f = $M->getFile;

	if (defined $f) {
		my $executable_md5 = `/usr/bin/md5sum $f`;
		chomp $executable_md5;  $executable_md5 =~ s/^(\S+).+/$1/;
		return $executable_md5
	}

	else {
		$M->log('ERROR',
						$M->getName,
						$M->getFile,
						'Can not find executable,'
					 );
		return '';
	}
}


# ---------------------------------------------------------------------
# The Algorithm for the plugin

sub getAlgorithm  { $_[0]->{__gus__plugin__algorithm} }
sub setAlgorithm  { $_[0]->{__gus__plugin__algorithm} = $_[1]; $_[0] }

# ----------------------------------------------------------------------
# Implementation - locate by executable name and version

sub getImplementation  { $_[0]->{__gus__plugin__implementation} }
sub setImplementation  { $_[0]->{__gus__plugin__implementation} = $_[1]; $_[0] }

# ----------------------------------------------------------------------
# Reads parameter key/value pairs from a file.  Tries a bunch of
# different places and names.

sub getConfig    { $_[0]->{__gus__plugin__config} }
sub setConfig    { $_[0]->{__gus__plugin__config} = $_[1]; $_[0] }
sub loadConfig   {
	my $M = shift;

	# find a file.
	my $f_cfg = $ENV{GUS30_CFG};
	$f_cfg    = './.gus30.cfg'                     unless -f $f_cfg;
	$f_cfg    = $ENV{HOME}. '/.gus30.cfg'          unless -f $f_cfg;
	$f_cfg    = '/usr/local/db/cbil/GUS/gus30.cfg' unless -f $f_cfg;

	# read it in
	require GUS::PluginMgr::Configuration;
	$M->setConfig(new Configuration(new CBIL::Util::A {
		CONFIG_FILE => $f_cfg
	}));

	# RETURN
	$M
}

# ----------------------------------------------------------------------

sub getGlobalEasyCspOptions {
	my $M = shift;

	my $RV =
	{
	 map {($_->{o},$_)}
	 (
		{ h => 'actually commit changes to database',
			t => 'boolean',
			o => 'commit',
		},

		{ h => 'set this GUS user name from Core.UserInfo table in new or changed rows',
			t => 'string',
			o => 'user',
		},

		{ h => 'set this GUS group name from Core.GroupInfo table in new or changed rows',
			t => 'string',
			o => 'group',
		},

		{ h => 'set this GUS project name from Core.Project table in new or changed rows',
			t => 'string',
			o => 'project',
		},

		{ h => 'set this algorithm invocation to rows in new or changed rows',
			t => 'integer',
			d => 1,
			o => 'algoinvo',
		},

		{ h => 'set this comment to the Core.AlgorithmInvocation',
			t => 'string',
			o => 'comment',
		},

		{ h => 'this implementation of application',
			t => 'integer',
			o => 'implementation',
		},

		{ h => 'use this database',
			t => 'string',
			o => 'database',
		},

		{ h => 'use this server',
			t => 'string',
			o => 'server',
		},
	 )
	};

	# apply defaults from configuration if we've loaded one.
	if (my $cfg = $M->getConfig) {
		foreach my $a ( qw( user group project algoinvo database ) ) {
			my $d = $cfg->lookup( undef, "gus/$a" );
			if (defined $d) {
				$RV->{$a}->{d} = $d;
			}
		}
	}

	# RETURN
	return $RV
}

# ----------------------------------------------------------------------
# Write a time-stamped tab-delimited error message to STDOUT.
# ----------------------------------------------------------------------

sub log {
	my $M = shift;
	my $T = shift;

	my $time_stamp_s = localtime;

	my $msg = join("\t", $T, $time_stamp_s, @_);

	print "$msg\n";

	# RETURN
	$msg
}

sub logRAIID {
	my $M = shift;

	$M->log('RAIID', $M->getSelfInv->getId)
}

sub logCommit {
	my $M = shift;

	$M->log('COMMIT', $M->getCla->{commit} ? 'commit on' : 'commit off');
}

sub logArgs {
	my $M = shift;

	foreach my $flag (sort keys %{$M->getCla}) {
		my $value = $M->getCla->{$flag};
		if (ref $value) {
			$M->log('ARGS', $flag, @$value);
		}
		else {
			$M->log('ARGS', $flag, $value);
		}
	}
}

# ----------------------------------------------------------------------
# Common SQL routines
# ----------------------------------------------------------------------

sub sql_get_as_array {
	my $M = shift;
	my $Q = shift; # SQL query
	my $H = shift; # handle and ...
	my $B = shift; # bind args hich are used only if SQL is not defined.

	my @RV;

	# get a statement handle.
	my $sh;
	if (defined $Q) {
		$sh = $M->getQueryHandle->prepareAndExecute($Q);
	}
	else {
		$sh = $H;
		$sh->execute(@$B);
	}

	# collect results
	while (my @row = $sh->fetchrow_array) {
		push(@RV,@row);
	}
	$sh->finish;

	#CBIL::Util::CBIL::Util::Disp:: Display(\@RV);

	# RETURN
	\@RV
}

sub sql_get_as_array_refs {
	my $M = shift;
	my $Q = shift; # SQL query
	my $H = shift; # handle and ...
	my $B = shift; # bind args hich are used only if SQL is not defined.

	my @RV;

	# get a statement handle.
	my $sh;
	if (defined $Q) {
		$sh = $M->getQueryHandle->prepareAndExecute($Q);
	}
	else {
		$sh = $H;
		$sh->execute(@$B);
	}

	# collect results
	while (my @row = $sh->fetchrow_array) {
		push(@RV,\@row);
	}
	$sh->finish;

	#CBIL::Util::CBIL::Util::Disp:: Display(\@RV);

	# RETURN
	\@RV
}

# ----------------------------------------------------------------------

sub sql_get_as_hash_refs {
	my $M = shift;
	my $Q = shift;
	my $H = shift;
	my $B = shift;

	my @RV;

	# get a statement handle.
	my $sh;
	if (defined $Q) {
		$sh = $M->getQueryHandle->prepareAndExecute($Q);
	}
	else {
		$sh = $H;
		$sh->execute(@$B);
	}

	# collect results
	while (my $row = $sh->fetchrow_hashref) {
		push(@RV,$row);
	}
	$sh->finish;

	# RETURN
	\@RV
}

# ----------------------------------------------------------------------

sub sql_translate {
	my $M  = shift;
	my $T  = shift; # table
	my $Kc = shift; # key column name
	my $Vc = shift; # value column name
	my $V  = shift; # value

	# load cache if we need to.
	if (not defined $M->{__gus__plugin_sql_xlate_cache}->{$T}->{$Vc}) {
		my $sql = "select $Vc,$Kc from $T";
		my %cache = map {@$_} @{$M->sql_get_as_array_refs($sql)};
		$M->{__gus__plugin_sql_xlate_cache}->{$T}->{$Vc} = \%cache;
		#CBIL::Util::CBIL::Util::Disp:: Display(\%cache);
		#CBIL::Util::CBIL::Util::Disp:: Display([$T, $Kc,$Vc, $V, $M->{__gus__plugin_sql_xlate_cache}->{$T}->{$Vc}->{$V}] );
	}

	# RETURN
	$M->{__gus__plugin_sql_xlate_cache}->{$T}->{$Vc}->{$V}
}

# ----------------------------------------------------------------------

1;

