
package GUS::PluginMgr::Plugin;

use strict 'vars';

use Carp;
use CBIL::Util::A;
use CBIL::Util::Disp;
use CBIL::Util::Utils;

use GUS::ObjRelP::DbiDatabase;
use GUS::Common::GusConfig;

# ----------------------------------------------------------------------
# CLASS methods
# ----------------------------------------------------------------------

sub new {
  my $C = shift;
  my $A = shift;

  my $m = bless {}, $C;

  $m->error('This plugin must override the new method: ' . ref $m);
}

# ----------------------------------------------------------------------
# INSTANCE methods
# ----------------------------------------------------------------------

# called by subclass in its constructor
sub initialize {
  my ($self, $argsHashRef) = @_;

  my @args = ('requiredDbVersion', 'cvsRevision', 'cvsTag', 'name',
	      'revisionNotes', 'usage', 'easyCspOptions');

  foreach my $arg (@args) {
    $self->_failinit($arg) unless exists $argsHashRef->{$arg};
    $self->{$arg} = $argsHashRef->{$arg};
  }

  $self->_initEasyCspOptions($self->{easyCspOptions});

  $self->_failinit('requiredDbVersion')
    unless (ref($self->{requiredDbVersion}) eq "HASH");
  $self->_failinit('easyCspOptions')
    unless (ref($self->{easyCspOptions}) eq "HASH");
  $self->setOk(1); #assume all is well to start
}

# ----------------------------------------------------------------------
# Public Utilities
# ----------------------------------------------------------------------

sub className2oracleName {
  my ($self, $className) = @_;
  return GUS::ObjRelP::DbiDatabase::className2oracleName($className);
}

# ----------------------------------------------------------------------
# Error Handling
# ----------------------------------------------------------------------
sub error {
  my ($self, $msg) = @_;

  confess("\nERROR: $msg\n\n--------------------------- STACK TRACE -------------------------\n");
}

sub userError{
  my ($self, $msg) = @_;

  die "\nUSER ERROR: $msg\n";
}


# ----------------------------------------------------------------------
# Public Accessors
# ----------------------------------------------------------------------

# what does the plugin do
sub getUsage             { $_[0]->{usage} }

# what version of the schema does the plugin require?
sub getRequiredDbVersion { $_[0]->{requiredDbVersion} }

# what cvs version of the plugin is this?
# parse out revision from string of the form '$Revision 1.2 $'
sub getCVSRevision {
  my ($self) = @_;

  $self->{cvsRevision} =~ /Revision:\s+(\S+)\s+/ || die "The plugin has an illegal cvs revision: '$self->{cvsRevision}'.  If that doesn't include a revision number, then the plugin has never been checked into CVS.  Please do so to give it an intial revision";
  return $1;
}

sub setResultDescr {$_[0]->{resultDescr} = $_[1];}
sub getResultDescr{ $_[0]->{resultDescr}}

# what cvs tag of the plugin is this?
sub getCVSTag {
  my ($self) = @_;
  $self->{cvsTag} =~ /Name: (.*)\$/ || die "Illegal cvs tag";
  return $1;
}

# revisionNotes about the implementation
sub getRevisionNotes       { $_[0]->{revisionNotes} }

# what options are needed
sub getEasyCspOptions    { $_[0]->{easyCspOptions} }

# the name of the plugin
sub getName       { $_[0]->{name} }

# file that contains the plugin
sub getFile       { $_[0]->{__gus__plugin__FILE} }

# command line options as parsed
sub getArgs        { $_[0]->{__gus__plugin__cla} }

# the DBI database
sub getDb         { $_[0]->{__gus__plugin__db} }

# the GUS::Model::Core::AlgorithmInvocation for current run
sub getAlgInvocation    { $_[0]->{__gus__plugin__self_inv} }

sub getQueryHandle    { $_[0]->getDb ? $_[0]->getDb->getQueryHandle : undef }

sub getCheckSum {
  my $M = shift;

  if (!$M->{md5}) {
    my $f = $M->getFile;

    if (defined $f) {
      $M->{md5} = &runCmd("$M->{md5sum_executable} $f");
      chomp $M->{md5};
      $M->{md5} =~ s/^(\S+).+/$1/;
    } else {
      $M->error("Cannot find the plugin's executable file $M->getFile");
    }
  }
  return $M->{md5};
}
# The Algorithm for the plugin
sub getAlgorithm  { $_[0]->{__gus__plugin__algorithm} }

# Implementation - locate by executable name and version
sub getImplementation  { $_[0]->{__gus__plugin__implementation} }

sub undefPointerCache {	$_[0]->getAlgInvocation->undefPointerCache }

# ----------------------------------------------------------------------
# Deprecated
# ----------------------------------------------------------------------
sub getSelfInv    { $_[0]->getAlgInvocation(); }
sub getCla        { $_[0]->getArgs(); }
sub logAlert      { my $M = shift; $M->log(@_); }
sub getOk         { $_[0]->{__gus__plugin__OK} }
sub setOk         { $_[0]->{__gus__plugin__OK} = $_[1]; $_[0] }
sub logRAIID      {$_[0]->logAlgInvocationId(); }

# ----------------------------------------------------------------------
# Public Logging Methods
# ----------------------------------------------------------------------

# Write a time-stamped tab-delimited error message to STDERR.
sub log {
  my $M = shift;

  my $time_stamp_s = localtime;

  my $msg = join("\t", $time_stamp_s, @_);

  print STDERR "$msg\n";
}

sub logDebug {
  my $M = shift;

  return unless $M->getArgs()->{debug};
  my $msg = join("\t", @_);

  print STDERR "\n$msg\n";
}

sub logVerbose {
  my $M = shift;

  $M->log(@_) if $M->getArgs()->{verbose};
}

sub logVeryVerbose {
  my $M = shift;

  $M->log(@_) if $M->getArgs()->{veryVerbose};
}

# to stdout
sub logData {
  my $M = shift;
  my $T = shift;

  my $time_stamp_s = localtime;

  my $msg = join("\t", $time_stamp_s, $T, @_);

  print "$msg\n";

  # RETURN
  $msg

}

sub logAlgInvocationId {
  my $M = shift;

  $M->log('ALGINVID', $M->getAlgInvocation->getId)
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
    } else {
      $M->log('ARGS', $flag, $value);
    }
  }
}

# ----------------------------------------------------------------------
# Common SQL routines
# ----------------------------------------------------------------------

sub sql_get_as_array {
  my $M = shift;
  my $Q = shift;		# SQL query
  my $H = shift;		# handle and ...
  my $B = shift;		# bind args hich are used only if SQL is not defined.

  my @RV;

  # get a statement handle.
  my $sh;
  if (defined $Q) {
    $sh = $M->getQueryHandle->prepareAndExecute($Q);
  } else {
    $sh = $H;
    $sh->execute(@$B);
  }

  # collect results
  while (my @row = $sh->fetchrow_array) {
    push(@RV,@row);
  }
  $sh->finish;

  #CBIL::Util::Disp::Display(\@RV);

  # RETURN
  \@RV
}

sub sql_get_as_array_refs {
  my $M = shift;
  my $Q = shift;		# SQL query
  my $H = shift;		# handle and ...
  my $B = shift;		# bind args hich are used only if SQL is not defined.

  my @RV;

  # get a statement handle.
  my $sh;
  if (defined $Q) {
    $sh = $M->getQueryHandle->prepareAndExecute($Q);
  } else {
    $sh = $H;
    $sh->execute(@$B);
  }

  # collect results
  while (my @row = $sh->fetchrow_array) {
    push(@RV,\@row);
  }
  $sh->finish;

  #CBIL::Util::Disp::Display(\@RV);

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
  } else {
    $sh = $H;
    $sh->execute(@$B);
  }

  # collect results
  # while (my $row = $sh->fetchrow_hashref('NAME_lc')) {
  while (my $row = $sh->fetchrow_hashref) {
    push(@RV,$row);
  }
  $sh->finish;

  # RETURN
  \@RV
}

sub sql_get_as_hash_refs_lc {
  my $M = shift;
  my $Q = shift;
  my $H = shift;
  my $B = shift;

  my @RV;

  # get a statement handle.
  my $sh;
  if (defined $Q) {
    $sh = $M->getQueryHandle->prepareAndExecute($Q);
  } else {
    $sh = $H;
    $sh->execute(@$B);
  }

  # collect results
  while (my $row = $sh->fetchrow_hashref('NAME_lc')) {
    push(@RV,$row);
  }
  $sh->finish;

  # RETURN
  \@RV
}

# ----------------------------------------------------------------------

sub sql_translate {
  my $M  = shift;
  my $T  = shift;		# table
  my $Kc = shift;		# key column name
  my $Vc = shift;		# value column name
  my $V  = shift;		# value

  # load cache if we need to.
  if (not defined $M->{__gus__plugin_sql_xlate_cache}->{$T}->{$Vc}) {
    my $sql = "select $Vc,$Kc from $T";
    my %cache = map {@$_} @{$M->sql_get_as_array_refs($sql)};
    $M->{__gus__plugin_sql_xlate_cache}->{$T}->{$Vc} = \%cache;
    #CBIL::Util::Disp::Display(\%cache);
    #CBIL::Util::Disp::Display([$T, $Kc,$Vc, $V, $M->{__gus__plugin_sql_xlate_cache}->{$T}->{$Vc}->{$V}] );
  }

  # RETURN
  $M->{__gus__plugin_sql_xlate_cache}->{$T}->{$Vc}->{$V}
}


# ----------------------------------------------------------------------
# Initialization Methods - called by GusApplication
# ----------------------------------------------------------------------

sub initName       {
  my $M = shift;
  my $N = shift;

  $M->{__gus__plugin__name} = $N;
  my $c = $N; $c =~ s/::/\//g; $c .= '.pm';
  $M->_initFile($INC{$c});

  # RETURN
  $M
}

sub initMd5Executable {
  my ($self, $md5sum) = @_;

  $self->userError("The file '$md5sum' is not an executable md5sum program.  Please configure \$GUS_HOME/config/GUS-Plugin.prop to specify the correct location of the md5sum program (using the 'md5sum=/your/md5sum' property)") unless -x $md5sum;
  $self->{md5sum_executable} = $md5sum;
}

sub initArgs        { $_[0]->{__gus__plugin__cla} = $_[1]; $_[0] }
sub initDb         { $_[0]->{__gus__plugin__db} = $_[1]; $_[0] }
sub initAlgInvocation    { $_[0]->{__gus__plugin__self_inv} = $_[1]; $_[0] }
sub initAlgorithm  { $_[0]->{__gus__plugin__algorithm} = $_[1]; $_[0] }
sub initImplementation  { $_[0]->{__gus__plugin__implementation} = $_[1]; $_[0] }
sub initConfig {
  my ($self, $config) = @_;
  $self->{config} = $config;
}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------
sub _initEasyCspOptions    {
  my $M = shift;

  my $args_n = scalar @_;
  my $type_s = ref $_[0];

  # list (of assumed hash refs)
  if ($args_n > 1) {
    $M->{easyCspOptions} = { map {($_->{o},$_)} @_ };
  }

  # list ref (of assumed hash refs)
  elsif ($type_s eq 'ARRAY') {
    $M->{easyCspOptions} = { map {($_->{o},$_)} @{$_[0]} };
  }

  # direct hash ref
  else {
    $_[0]->{easyCspOptions} = $_[1];
  }

  # RETURN
  $M
}

sub _initFile       { $_[0]->{__gus__plugin__FILE} = $_[1]; $_[0] }

sub _failinit {
  my ($self, $argname) = @_;

  print STDERR "Plugin initialization failed: invalid argument '$argname'\n";
  exit 1;
}

1;

