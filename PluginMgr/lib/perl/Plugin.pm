package GUS::PluginMgr::Plugin;

use strict 'vars';

use Carp;
use CBIL::Util::A;
use CBIL::Util::Disp;
use CBIL::Util::Utils;

use GUS::ObjRelP::DbiDatabase;
use GUS::Common::GusConfig;

=head1 Name

C<GUS::PluginMgr::Plugin>

=head1 Description

C<GUS::PluginMgr::Plugin> is the superclass of all GusApplication plugins.

Unless otherwise noted, all of its methods are I<instance> methods.  That is,
they are called like this:  C<< $self->my_instance_method(); >>

=head1 Methods

=cut

# ----------------------------------------------------------------------
# CLASS methods
# ----------------------------------------------------------------------

=head2 Constructor

=item C<new()>

Construct a new Plugin.  This method I<must be overridden> by the plugin subclass.  That is, the subclass must have its own C<new> method which must:

- create and C<bless> a C<$self>

- call the C<initialize> method described below

- return C<$self>

B<Return type:> hash ref

=cut

sub new {
  my ($class) = @_;

  my $self = {};
  bless($self, $class);

  $self->error('This plugin must override the new method: ' . ref $self);
  return $self;
}

# ----------------------------------------------------------------------
# INSTANCE methods
# ----------------------------------------------------------------------

=head2 Instance methods

=over 4

=item C<initialize()>

Initialize the plugin.  This method is called in the plugin's C<new> method.

B<Return type:> none

=cut

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
# Public Accessors
# ----------------------------------------------------------------------

=item C<getUsage()>

Get the plugin's usage.  This value is set by the C<initialize> method.

B<Return type:> string

=cut
sub getUsage             { $_[0]->{usage} }

=item C<getRequiredDbVersion()>

Get the plugin's required database version.  This value is set by the C<initialize> method.

B<Return type:> string

=cut
sub getRequiredDbVersion { $_[0]->{requiredDbVersion} }

=item C<getCVSRevision()>

Get the plugin's CVS revision number.  This value is set by the C<initialize> method.

B<Return type:> string

=cut
# parse out revision from string of the form '$Revision 1.2 $'
sub getCVSRevision {
  my ($self) = @_;

  $self->{cvsRevision} =~ /Revision:\s+(\S+)\s+/ || die "The plugin has an illegal cvs revision: '$self->{cvsRevision}'.  If that doesn't include a revision number, then the plugin has never been checked into CVS.  Please do so to give it an intial revision";
  return $1;
}

=item C<setResultDescr($resultDescrip)>

Set the result description.  This value is stored in the database in the AlgorithmInvocation table's result column after the plugin completes.

B<Params:>

- resultDescrip: a description of the plugin's main result for posterity.

B<Return type:> string

=cut
sub setResultDescr {$_[0]->{resultDescr} = $_[1];}

=item C<getResultDescr>

Get the result description.

B<Return type:> string

=cut

sub getResultDescr{ $_[0]->{resultDescr}}

=item C<getCVSTag()>

Get the plugin's CVS tag.  This value is set by the C<initialize> method.

B<Return type:> string

=cut
sub getCVSTag {
  my ($self) = @_;
  $self->{cvsTag} =~ /Name: (.*)\$/ || die "Illegal cvs tag";
  return $1;
}

=item C<getRevisionNotes()>

Get the plugin's revision notes.  This value is set by the C<initialize> method.

B<Return type:> string

=cut
sub getRevisionNotes       { $_[0]->{revisionNotes} }

=item C<getEasyCspOptions()>

Get the plugin's EasyCsp options.  This value is set by the C<initialize> method.

B<Return type:> string

=cut
sub getEasyCspOptions    { $_[0]->{easyCspOptions} }

=item C<getName()>

  Get the name of the plugin, eg, C<GUS::Common::Plugin::UpdateRow>

B<Return type:> string

=cut
sub getName       { $_[0]->{name} }

=item C<getFile()>

Get the fill path of the file that contains the plugin, eg, /home/me/gushome/lib/perl/GUS/Common/Plugin/UpdateRow.pm

B<Return type:> string

=cut
sub getFile       { $_[0]->{__gus__plugin__FILE} }

=item C<getArgs()>

Get 

B<Return type:> string

=cut
sub getArgs        { $_[0]->{__gus__plugin__cla} }

# the DBI database
=item C<()>



B<Return type:> string

=cut
sub getDb         { $_[0]->{__gus__plugin__db} }

# the GUS::Model::Core::AlgorithmInvocation for current run
=item C<()>



B<Return type:> string

=cut
sub getAlgInvocation    { $_[0]->{__gus__plugin__self_inv} }

=item C<()>



B<Return type:> string

=cut
sub getQueryHandle    { $_[0]->getDb ? $_[0]->getDb->getQueryHandle : undef }

=item C<()>



B<Return type:> string

=cut
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
=item C<()>



B<Return type:> string

=cut
sub getAlgorithm  { $_[0]->{__gus__plugin__algorithm} }

# Implementation - locate by executable name and version
=item C<()>



B<Return type:> string

=cut
sub getImplementation  { $_[0]->{__gus__plugin__implementation} }

# ----------------------------------------------------------------------
# Public Utilities
# ----------------------------------------------------------------------

=item C<()>



B<Return type:> string

=cut
sub className2oracleName {
  my ($self, $className) = @_;
  return GUS::ObjRelP::DbiDatabase::className2oracleName($className);
}

=item C<()>



B<Return type:> string

=cut
sub undefPointerCache {	$_[0]->getAlgInvocation->undefPointerCache }


# ----------------------------------------------------------------------
# Error Handling
# ----------------------------------------------------------------------
=item C<()>



B<Return type:> string

=cut
sub error {
  my ($self, $msg) = @_;

  confess("\nERROR: $msg\n\n--------------------------- STACK TRACE -------------------------\n");
}

=item C<()>



B<Return type:> string

=cut
sub userError{
  my ($self, $msg) = @_;

  die "\nUSER ERROR: $msg\n";
}
# ----------------------------------------------------------------------
# Deprecated
# ----------------------------------------------------------------------
=item C<()>



B<Return type:> string

=cut
sub getSelfInv    { $_[0]->getAlgInvocation(); }
=item C<()>



B<Return type:> string

=cut
sub getCla        { $_[0]->getArgs(); }
=item C<()>



B<Return type:> string

=cut
sub logAlert      { my $M = shift; $M->log(@_); }
=item C<()>



B<Return type:> string

=cut
sub getOk         { $_[0]->{__gus__plugin__OK} }
=item C<()>



B<Return type:> string

=cut
sub setOk         { $_[0]->{__gus__plugin__OK} = $_[1]; $_[0] }
=item C<()>



B<Return type:> string

=cut
sub logRAIID      {$_[0]->logAlgInvocationId(); }

# ----------------------------------------------------------------------
# Public Logging Methods
# ----------------------------------------------------------------------

# Write a time-stamped tab-delimited error message to STDERR.
=item C<()>



B<Return type:> string

=cut
sub log {
  my $M = shift;

  my $time_stamp_s = localtime;

  my $msg = join("\t", $time_stamp_s, @_);

  print STDERR "$msg\n";
}

=item C<()>



B<Return type:> string

=cut
sub logDebug {
  my $M = shift;

  return unless $M->getArgs()->{debug};
  my $msg = join("\t", @_);

  print STDERR "\n$msg\n";
}

=item C<()>



B<Return type:> string

=cut
sub logVerbose {
  my $M = shift;

  $M->log(@_) if $M->getArgs()->{verbose};
}

=item C<()>



B<Return type:> string

=cut
sub logVeryVerbose {
  my $M = shift;

  $M->log(@_) if $M->getArgs()->{veryVerbose};
}

# to stdout
=item C<()>



B<Return type:> string

=cut
sub logData {
  my $M = shift;
  my $T = shift;

  my $time_stamp_s = localtime;

  my $msg = join("\t", $time_stamp_s, $T, @_);

  print "$msg\n";

  # RETURN
  $msg

}

=item C<()>



B<Return type:> string

=cut
sub logAlgInvocationId {
  my $M = shift;

  $M->log('ALGINVID', $M->getAlgInvocation->getId)
}

=item C<()>



B<Return type:> string

=cut
sub logCommit {
  my $M = shift;

  $M->log('COMMIT', $M->getCla->{commit} ? 'commit on' : 'commit off');
}

=item C<()>



B<Return type:> string

=cut
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

=item C<()>



B<Return type:> string

=cut
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

=item C<()>



B<Return type:> string

=cut
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

=item C<()>



B<Return type:> string

=cut
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

=item C<()>



B<Return type:> string

=cut
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

=item C<()>



B<Return type:> string

=cut
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
  # (this is the expected case, the others being legacy)
  elsif ($type_s eq 'ARRAY') {
    $M->{easyCspOptions} = { map {($_->{o},$_)} @{$_[0]} };
  }

  # direct hash ref
  else {
    $M->{easyCspOptions} = $_[1];
  }

  my %types = ('id' => 1,
	       'date' => 1,
	       'float' => 1,
	       'int' => 1,
	       'string' => 1,
	       'boolean' => 1,
	       'table_id' => 1,
	      );

  my $types = join (", ", keys(%types));

  foreach my $argKey (keys %{$M->{easyCspOptions}}) {
    my $arg = $M->{easyCspOptions}->{$argKey};
    $M->error("EasyCspOption '$arg->{o}' has an invalid type '$arg->{t}'.  Valid types are: $types") unless $types{$arg->{t}};
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

