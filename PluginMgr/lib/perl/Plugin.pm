package GUS::PluginMgr::Plugin;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(stringArg booleanArg fileArg integerArg floatArg tableNameArg);

use strict 'vars';

use Carp;
use CBIL::Util::A;
use CBIL::Util::Disp;
use CBIL::Util::Utils;

use GUS::ObjRelP::DbiDatabase;
use GUS::Common::GusConfig;
use GUS::PluginMgr::Args::StringArg;
use GUS::PluginMgr::Args::BooleanArg;
use GUS::PluginMgr::Args::FileArg;
use GUS::PluginMgr::Args::IntegerArg;
use GUS::PluginMgr::Args::TableNameArg;
use GUS::PluginMgr::Args::FloatArg;
use GUS::PluginMgr::Args::Arg;
use GUS::PluginMgr::Args::Arg;
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

=head2 Initialization

=over 4

=item C<initialize($argsHashRef)>

Initialize the plugin.  This method is called in the plugin's C<new> method.

B<Parameters>

- argsHashRef (hash ref).  This argument is a hash ref which must contain the following key values pairs:

=over 4

=item * requiredDbVersion (string)

=item * cvsRevision (string)

The CVS revision number (eg 1.11) of the plugin.  The value for this key I<must> be specified using the CVS magic substitution format.  In particular, it must be: C<'$Revision$'>. CVS will substitute in the revision number, so that, after substitution, the value will be, eg, C<'$Revision$>'

=item * cvsTag (string)

The CVS tag (ie, the software release it is from) of the plugin.  The value for this key I<must> be specified using the CVS magic substitution format.  In particular, it must be: C<'$Name$'>. CVS will substitute in the tag, so that, after substitution, the value will be, eg, C<'$Name$>'

=item * name (string)

The name of the plugin.  This value for this key I<must> be specified like this: C<ref($self)>.

=item * C<documentation> (I<hashref>)

The documentation for this plugin (excluding the documentation for command line arguments which is covered by C<argsDeclaration>).  

The hashref may include only the following standard keys.  All string values (e.g., C<purpose>, C<notes>) may include embedded POD formatting directives.  Precede and follow all command (e.g., C<=item>) with C<\\n\\n>.

=over 4

=item * purpose (string)

The purpose of the plugin.  This should be as thorough as possible.

=item * purposeBrief (string)

A one sentence summary of the plugin's purpose.  This is displayed on the first line of the help page.  It is also written into the Core::Algorithm table as a description of the plugin.

=item * tablesAffected (listref of listrefs)

A list of tables the plugin writes to (excluding the standard overhead tables).  
For example:

C<my $tablesAffected = [
   ['DoTS::Assembly', 'Writes the finished assemblies here'],
   ['DoTS::Similarity', 'Writes its similarity here'],
];

=item * tablesDependedOn (listref of listrefs)

A list of tables the plugin depends on (excluding the standard overhead tables).  This should include all controlled vocabulary tables that the data the plugin is generating depends upon.

The format is the same as that for C<tablesAffected>

=item * howToRestart (string)

The details of how to restart the plugin.

=item * failureCases (string)

Known types of failure cases and what to do about them.

=item * notes (string)

Additional notes.  This should include the details of:

=over 4

=item * file formats used as input, and how they are produced

=item * file formats used as output.

=item * other plugins that must be run first.


=back

=back

=item

=item * argsDeclaration (listref of C<GUS::PluginMgr::Args::Arg> subclasses)

A declaration of the command line arguments expected by the plugin.  Each element of the list is an object which is a subclass of C<GUS::PluginMgr::Args::Arg>.  See the Argument Declaration Constructors (e.g. C<stringArg()>, C<fileArg>, etc).  These are methods which construct and return these objects.  

=item * revisionNotes (string)

An explanation of what is new in this revision of the plugin.  This value is written into the description field of the Core.AlgorithmImplementation table when the plugin's registration is updated (by using ga +update).

=item * easyCspOptions 

This has been B<deprecated>.  It is replaced by C<argsDeclaration>

=item * usage

This has been B<deprecated>.  It is replaced by C<documentation>

=cut

sub initialize {
  my ($self, $argsHashRef) = @_;

  my @args = ('requiredDbVersion', 'cvsRevision', 'cvsTag', 'name',
	      'revisionNotes');

  foreach my $arg (@args) {
    $self->_failinit($arg) unless exists $argsHashRef->{$arg};
    $self->{$arg} = $argsHashRef->{$arg};
  }

  if (exists $argsHashRef->{usage}) {
    $self->{usage} = $argsHashRef->{usage};
  } elsif (exists $argsHashRef->{documentation}) {
    $self->{documentation} = $argsHashRef->{documentation};
    $self->checkDocumentation();
  } else {
    $self->_failinit('documentation');
  }

  if ($argsHashRef->{easyCspOptions}) {
    $self->{easyCspOptions} = $argsHashRef->{easyCspOptions};
    $self->_initEasyCspOptions($self->{easyCspOptions});
    $self->_failinit('easyCspOptions')
      unless (ref($self->{easyCspOptions}) eq "HASH");
  } elsif ($argsHashRef->{argsDeclaration}) {
    $self->{argsDeclaration} = $argsHashRef->{argsDeclaration};
  } else {
    $self->_failinit('argsDeclaration');
  }


  $self->_failinit('requiredDbVersion')
    unless (ref($self->{requiredDbVersion}) eq "HASH");

  $self->setOk(1); #assume all is well to start
}



# ----------------------------------------------------------------------
# Public Accessors
# ----------------------------------------------------------------------

=head2 Setters

=over 4

=item C<setResultDescr($resultDescrip)>

Set the result description.  This value is stored in the database in the AlgorithmInvocation table's result column after the plugin completes.

B<Params:>

- resultDescrip: a description of the plugin's main result for posterity.

=cut
sub setResultDescr {$_[0]->{resultDescr} = $_[1];}

=item C<setOracleDateFormat($oracleDateFormat)>

Set Oracle's NLS_DATE_FORMAT for the duration of this plugin's run.  This is the format which oracle will allow for data of type 'Date.'  See Oracle's documentation to find valid formats.  The default format is 'YYYY-MM-DD HH24:MI:SS.'

B<Params:>

- oracleDateFormat: a string specifying a valid Oracle date format

=cut

sub setOracleDateFormat {
  my ($self, $oracleDateFormat) = @_;
  
  my $dbh = $self->getDb()->getDbHandle();

  $dbh->do("alter session set NLS_DATE_FORMAT='$oracleDateFormat'");
}

=head2 Getters

=over 4

=item C<getUsage()>

Get the plugin's usage.  This value is set by the C<initialize> method.

B<Return type:> C<string>

=cut
sub getUsage             { $_[0]->{usage} }

=item C<getDocumentation()>

Get a hashref holding the plugin's documentation.  This value is set by the C<initialize> method.

B<Return type:> C<string>

=cut
sub getDocumentation { $_[0]->{documentation} }

=item C<getRequiredDbVersion()>

Get the plugin's required database version.  This value is set by the C<initialize> method.

B<Return type:> C<string>

=cut
sub getRequiredDbVersion { $_[0]->{requiredDbVersion} }

=item C<getCVSRevision()>

Get the plugin's CVS revision number.  This value is set by the C<initialize> method.

B<Return type:> C<string>

=cut
# parse out revision from string of the form '$Revision 1.2 $'
sub getCVSRevision {
  my ($self) = @_;

  $self->{cvsRevision} =~ /Revision:\s+(\S+)\s+/ || die "The plugin has an illegal cvs revision: '$self->{cvsRevision}'.  If that doesn't include a revision number, then the plugin has never been checked into CVS.  Please do so to give it an intial revision";
  return $1;
}

=item C<getResultDescr>

Get the result description.

B<Return type:> C<string>

=cut

sub getResultDescr{ $_[0]->{resultDescr}}

=item C<getCVSTag()>

Get the plugin's CVS tag.  This value is set by the C<initialize> method.

B<Return type:> C<string>

=cut
sub getCVSTag {
  my ($self) = @_;
  $self->{cvsTag} =~ /Name: (.*)\$/ || die "Illegal cvs tag";
  return $1;
}

=item C<getRevisionNotes()>

Get the plugin's revision notes.  This value is set by the C<initialize> method.

B<Return type:> C<string>

=cut
sub getRevisionNotes       { $_[0]->{revisionNotes} }

=item C<getEasyCspOptions()>

Get the plugin's EasyCsp options.  This value is set by the C<initialize> method.

B<Return type:> C<string>

=cut
sub getArgsDeclaration    { $_[0]->{argsDeclaration} }

=item C<getArgsDeclaration()>

Get the plugin's argument declaration.  This value is set by the C<initialize> method.

B<Return type:> C<ref_to_list_of_Args>

=cut
sub getEasyCspOptions    { $_[0]->{easyCspOptions} }

=item C<getName()>

Get the name of the plugin, eg, C<GUS::Common::Plugin::UpdateRow>

B<Return type:> C<string>

=cut
sub getName       { $_[0]->{name} }

=item C<getFile()>

Get the full path of the file that contains the plugin, eg, /home/me/gushome/lib/perl/GUS/Common/Plugin/UpdateRow.pm

B<Return type:> C<string>

=cut
sub getFile       { $_[0]->{__gus__plugin__FILE} }

=item C<getArgs()>

Get the plugin's command line arguments.  To access these within the plugin, use: C<< $self->getArgs()->{arg_name} >>.

B<Return type:> Hash reference

=cut
sub getArgs        { $_[0]->{__gus__plugin__cla} }


=item C<getDb()>

Get the DbiDatabase object which represents the database this plugin accesses.

B<Return type:> C<GUS::ObjRelP::DbiDatabase>

=cut
sub getDb         { $_[0]->{__gus__plugin__db} }

=item C<getAlgInvocation()>

Get the AlgorithmInvocation which tracks the running of this plugin in the database.

B<Return type:> C<GUS::Model::Core::AlgorithmInvocation>

=cut
sub getAlgInvocation    { $_[0]->{__gus__plugin__self_inv} }

=item C<getQueryHandle()>

Get the DbiDbHandle which this plugin uses to access the database.

B<Return type:> C<GUS::ObjRelP::DbiDbHandle>

=cut
sub getQueryHandle    { $_[0]->getDb ? $_[0]->getDb->getQueryHandle : undef }

=item C<getCheckSum()>

Get an md5 digest checksum of the perl file which codes this plugin.  (This is used by GusApplication when registering the plugin in the database.)

B<Return type:> C<string>

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

=item C<getAlgorithm()>

Get the Algorithm that represents this plugin in the database.

B<Return type:> C<GUS::Model::Core::Algorithm>

=cut
sub getAlgorithm  { $_[0]->{__gus__plugin__algorithm} }

=item C<getImplementation()>

Get the AlgorithmImplementation that represents this version of this plugin in the database.

B<Return type:> C<GUS::Model::Core::AlgorithmImplementation>

=cut
sub getImplementation  { $_[0]->{__gus__plugin__implementation} }

# ----------------------------------------------------------------------
# Argument Declaration Constructors
# ----------------------------------------------------------------------

=head2 Argument Declaration Constructors

The Argument Declaration Constructors return Argument Declaration objects, as expected by the initialize() method in its C<argDeclaration> parameter.  Each arg declaration object specifies the details of a command line argument expected by the plugin.  The different constructors below are used to declare arguments of different types, such as string, int, file, etc.

The argument declaration constructor methods each take a hashref as their sole parameter.  This hashref must include the required set of keys.

The following keys are standard and required for all the argument declaration constructors. (Additional non-standard keys are indicated below for each method as applicable.)

=over 4

=item * name (string)

The name of the argument (e.g., 'length' will expect a --length argument on the command line)

=item * descr (string)

A description of the argument and what kinds of values are allowed.

=item * reqd (0 or 1)

Whether the user is required to provide this argument on the command line

=item * default

The default value to use if the user doesn't supply one (or undef if none)

=item * constraintFunc (method ref)

The method to call to check the validity of the value the user has supplied (undef if none).  The method is called with the value as an arugment.  The method returns a string describing the problem witht the value if there is one, or undef if there is no problem.

=item * isList (0 or 1)

True if the argument expects a comma delimited list of values instead of a single value.

=back

=back

=item C<stringArg($argDescriptorHashRef)>

Construct a string argument declaration.

B<Parameters>

- argDescriptorHashRef (hash ref).  This argument is a hash ref which must contain the standard keys described above.

B<Return type:> C<GUS::PluginMgr::Args::StringArg>

=cut
sub stringArg {
  my ($paramsHashRef) = @_;
  return GUS::PluginMgr::Args::StringArg->new($paramsHashRef);
}

=item C<integerArg($argDescriptorHashRef)>

Construct a integer argument declaration.

B<Parameters>

- argDescriptorHashRef (hash ref).  This argument is a hash ref which must contain the standard keys described above.

B<Return type:> C<GUS::PluginMgr::Args::IntegerArg>

=cut
sub integerArg {
  my ($paramsHashRef) = @_;
  return GUS::PluginMgr::Args::IntegerArg->new($paramsHashRef);
}

=item C<booleanArg($argDescriptorHashRef)>

Construct a boolean argument declaration.

B<Parameters>

- argDescriptorHashRef (hash ref).  This argument is a hash ref which must contain the standard keys described above with the exception of 'isList' and 'constraintFunc', which are not applicable.

B<Return type:> C<GUS::PluginMgr::Args::BooleanArg>

=cut
sub booleanArg {
  my ($paramsHashRef) = @_;
  return GUS::PluginMgr::Args::BooleanArg->new($paramsHashRef);
}

=item C<tableNameArg($argDescriptorHashRef)>

Construct a tableName argument declaration.

B<Parameters>

- argDescriptorHashRef (hash ref).  This argument is a hash ref which must contain the standard keys described above.

B<Return type:> C<GUS::PluginMgr::Args::TableNameArg>

=cut
sub tableNameArg {
  my ($paramsHashRef) = @_;
  return GUS::PluginMgr::Args::TableNameArg->new($paramsHashRef);
}

=item C<floatArg($argDescriptorHashRef)>

Construct a float argument declaration.

B<Parameters>

- argDescriptorHashRef (hash ref).  This argument is a hash ref which must contain the standard keys described above.

B<Return type:> C<GUS::PluginMgr::Args::FloatArg>

=cut
sub floatArg {
  my ($paramsHashRef) = @_;
  return GUS::PluginMgr::Args::FloatArg->new($paramsHashRef);
}

=item C<fileArg($argDescriptorHashRef)>

Construct a file argument declaration.

B<Parameters>

- argDescriptorHashRef (hash ref).  This argument is a hash ref which must contain the standard keys described above and also

over 4

=item * mustExist (0 or 1)

Whether the file must exist

=item * format (string)

The a description of the file's format

B<Return type:> C<GUS::PluginMgr::Args::FileArg>

=cut
sub fileArg {
  my ($paramsHashRef) = @_;
  return GUS::PluginMgr::Args::FileArg->new($paramsHashRef);
}

# ----------------------------------------------------------------------
# Public Utilities
# ----------------------------------------------------------------------

=head2 Utilities

=over 4

=item C<className2oracleName($className)>

Convert a perl style class name for a database object to the form required in an SQL statement.  For example, convert Core::Algorithm to core.algorithm

B<Parameters:>

- className (string):  A class name in the form: GUS::Model::Core::Algorithm or Core::Algorithm

B<Return type:> C<string>

=cut
sub className2oracleName {
  my ($self, $className) = @_;
  return GUS::ObjRelP::DbiDatabase::className2oracleName($className);
}

=item C<undefPointerCache()>

Clear out the GUS Object Layer's cache of database objects.  The object cache holds 10000 objects by default.  (You can change its capacity by calling C<< $self->getDb()->setMaximumNumberOfObjects() >>.)  Typically a plugin may loop over a set of input, using a number of objects for each iteration through the loop.  Because the next time through the loop will not need those objects, it is good practice to call C<< $self->undefPointerCache() >> at the bottom of the loop to avoid filling the cache with objects that are not needed anymore.

=cut
sub undefPointerCache {	$_[0]->getAlgInvocation->undefPointerCache }


# ----------------------------------------------------------------------
# Documentation
# ----------------------------------------------------------------------

=head2 Documentation

=over 4

=item C<printDocumentationText($synopsis, $argDetails)>

Print documentation for this plugin in text format.  The documentation includes a synopsis, description, and argument details

B<Parameters>

- $synopsis (string):  text providing a synopsis.
- $argDetails (string):  text providing details of the arguments.

=cut
sub printDocumentationText {
  $| = 1;
  my ($self, $synopsis, $argDetails) = @_;
  open(POD, "| pod2text") || die "couldn't open pod2text";
  print POD $self->_formatDocumentationPod($synopsis, $argDetails);
  close(POD);
}

=item C<printDocumentationHTML($synopsis, $argDetails)>

Print documentation for this plugin in HTML format.  The documentation includes a synopsis, description, and argument details

B<Parameters>

- $synopsis (string):  text providing a synopsis.
- $argDetails (string):  text providing details of the arguments.

=cut
sub printDocumentationHTML {
  my ($self, $synopsis, $argDetails) = @_;
  print "\n";
  open(POD, "| pod2html") || die "couldn't open pod2html";
  print POD $self->_formatDocumentationPod($synopsis, $argDetails);
  close(POD);
}

sub _formatDocumentationPod {
  my ($self, $synopsis, $argDetails) = @_;

  my $doc = $self->getDocumentation();

  my $s .= "\n=head1 NAME\n\n";
  $s .= "C<$self->{name}> -  $doc->{purposeBrief} \n\n";
  $s .= "=head1 SYNOPSIS\n\n";
  $s .= "$synopsis\n\n";
  $s .= "=head1 DESCRIPTION\n\n";
  $s .= "$doc->{purpose}\n";
  $s .= "=head1 TABLES AFFECTED\n\n";
  my $tablesAffected = $self->_getTablesAffected();
  foreach my $tbl (@$tablesAffected) {
    my ($tblName, $descrip) = @$tbl;
    $s .= "=item B<$tblName>\n\n=over 4\n\n$descrip\n\n=back\n\n";
  }
  $s .= "\n";
  $s .= "=head1 TABLES DEPENDED ON\n\n";
  my $tablesDependedOn = $self->_getTablesDependedOn();
  foreach my $tbl (@$tablesDependedOn) {
    my ($tblName, $descrip) = @$tbl;
    $s .= "=item B<$tblName>\n\n=over 4\n\n$descrip\n\n=back\n\n";
  }
  $s .= "\n";
  if ($doc->{failureCases}) {
    $s .= "=head1 FAILURE CASES\n\n";
    $s .= "$doc->{failureCases}\n";
  }
  if ($doc->{howToRestart}) {
    $s .= "=head1 RESTARTING\n\n";
    $s .= "$doc->{howToRestart}\n";
  }
  $s .= "=head1 ARGUMENTS IN DETAIL\n";
  $s .= "$argDetails\n";
  if ($doc->{notes}) {
    $s .= "=head1 NOTES\n\n";
    $s .= "$doc->{notes}\n";
  }

  return $s;
}

sub checkDocumentation {
  my ($self) = @_;

  my $doc = $self->getDocumentation();

  my @fields = ('purposeBrief', 'purpose', 'tablesAffected', 'tablesDependedOn',
		'howToRestart', 'failureCases', 'notes');

  foreach my $field (@fields) {
    if (!exists $doc->{$field}) {
      print STDERR "Plugin initialization failed: documentation field '$field' not provided\n";
      exit(1);
    }
  }
}

sub _getTablesAffected {
  my ($self) = @_;

  return [@{$self->{documentation}->{tablesAffected}},
	  ['Core::AlgorithmInvocation', "The plugin manager (ga) inserts a row into this table describing the plugin and the parameter values used"],
	 ];
}

sub _getTablesDependedOn {
  my ($self) = @_;

  return [@{$self->{documentation}->{tablesDependedOn}},
	  ['Core::Algorithm', "The algorithm (ie, this plugin) responsible for the update"],
	  ['Core::AlgorithmImplementation', "The specific implementation of it"],
	  ['Core::AlgorithmParamKey', "The keys for the plugin's command line parameters"],
	  ['Core::AlgorithmParamKeyType', "The data types of the parameters"],
	 ];
}

# ----------------------------------------------------------------------
# Error Handling
# ----------------------------------------------------------------------

=head2 Error handling

=over 4

=item C<error($msg)>

Handle a fatal error in a plugin.  This method terminates the plugin gracefully, writing the provided message to STDERR.  It also writes a stack trace showing where the error occurred.

When the plugin is terminated, GusApplication will still catch the error and attempt to track the plugin's failure in the database.

Do not use this method to report user errors such as invalid argument values (use C<userError> for that).

B<Parameters>

- msg (string):  the error message to write.

=cut
sub error {
  my ($self, $msg) = @_;

  confess("\nERROR: $msg\n\n--------------------------- STACK TRACE -------------------------\n");
}

=item C<userError($msg)>

Handle a fatal user error in a plugin.  This method terminates the plugin gracefully, writing the provided message to STDERR.  It it intended only for errors made by the user of the plugin (such as incorrect argument values).

B<Parameters>

- msg (string):  the error message to write.

=cut
sub userError{
  my ($self, $msg) = @_;

  die "\nUSER ERROR: $msg\n";
}

# ----------------------------------------------------------------------
# Public Logging Methods
# ----------------------------------------------------------------------

=head2 Logging

=over 4

=item C<log($msg1, $msg2, ...)>

Write a date stamped tab delimited message to STDERR.  The messages supplied as arguments are joined with tabs in between.

B<Parameters>

- @messages (list of strings):  the error messages to write.

=cut
sub log {
  my $M = shift;

  my $time_stamp_s = localtime;

  my $msg = join("\t", $time_stamp_s, @_);

  print STDERR "$msg\n";
}

=item C<logDebug($msg1, $msg2, ...)>

Write a date stamped tab delimited debugging message to STDERR.  The messages supplied as arguments are joined with tabs in between.  It will only be written if the user specifies the C<--debug> argument.

B<Parameters>

- @messages (list of strings):  the error messages to write.

=cut
sub logDebug {
  my $M = shift;

  return unless $M->getArgs()->{debug};
  my $msg = join("\t", @_);

  print STDERR "\n$msg\n";
}

=item C<logVerbose($msg1, $msg2, ...)>

Write a date stamped tab delimited debugging message to STDERR.  The messages supplied as arguments are joined with tabs in between.  It will only be written if the user specifies the C<--verbose> argument.

B<Parameters>

- @messages (list of strings):  the error messages to write.

=cut
sub logVerbose {
  my $M = shift;

  $M->log(@_) if $M->getArgs()->{verbose};
}

=item C<logVeryVerbose($msg1, $msg2, ...)>

Write a date stamped tab delimited debugging message to STDERR.  The messages supplied as arguments are joined with tabs in between.  It will only be written if the user specifies the C<--veryVerbose> argument.

B<Parameters>

- @messages (list of strings):  the error messages to write.

=cut
sub logVeryVerbose {
  my $M = shift;

  $M->log(@_) if $M->getArgs()->{veryVerbose};
}

=item C<logData($msg1, $msg2, ...)>

Write a date stamped tab delimited debugging message to STDOUT.  The messages supplied as arguments are joined with tabs in between.

B<Parameters>

- @messages (list of strings):  the error messages to write.

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

=item C<logAlgInvocationId()>

Log to STDERR the id for the AlgorithmInvocation that represents this run of the plugin in the database.

=cut
sub logAlgInvocationId {
  my $M = shift;

  $M->log('ALGINVID', $M->getAlgInvocation->getId)
}

=item C<logCommit()>

Log to STDERR the state of the commit flag for this run of the plugin.

=cut
sub logCommit {
  my $M = shift;

  $M->log('COMMIT', $M->getCla->{commit} ? 'commit on' : 'commit off');
}

=item C<logArgs()>

Log to STDERR the argument values used for this run of the plugin.

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

=head2 SQL utilities

=over 4

=item C<sql_get_as_array()>



B<Return type:> C<string>

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



B<Return type:> C<string>

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



B<Return type:> C<string>

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



B<Return type:> C<string>

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



B<Return type:> C<string>

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
# Deprecated
# ----------------------------------------------------------------------

=head2 Deprecated

=over 4

=item C<getSelfInv()>

Replaced by C<getAlgInvocation>

=cut
sub getSelfInv    { $_[0]->getAlgInvocation(); }

=item C<getCla()>

Replaced by C<getArgs>

=cut
sub getCla        { $_[0]->getArgs(); }

=item C<logAlert()>

Replaced by C<log>

=cut
sub logAlert      { my $M = shift; $M->log(@_); }

=item C<getOk()>

This method is replaced by the C<die/eval> facilities of perl.  Instead of using C<setOK(0)>, use C<die>. 

=cut

sub getOk         { $_[0]->{__gus__plugin__OK} }

=item C<setOk()>

This method is replaced by the C<die/eval> facilities of perl.  Instead of using C<getOK()>, use C<eval>.

=cut
sub setOk         { $_[0]->{__gus__plugin__OK} = $_[1]; $_[0] }

=item C<logRAIID()>

Replaced by C<logAlgInvocationId>

=cut
sub logRAIID      {$_[0]->logAlgInvocationId(); }

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

