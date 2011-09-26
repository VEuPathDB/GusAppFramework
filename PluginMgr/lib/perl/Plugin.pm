package GUS::PluginMgr::Plugin;
 
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(stringArg booleanArg fileArg integerArg floatArg globArg tableNameArg enumArg);

use strict 'vars';

use Carp;
use CBIL::Util::A;
use CBIL::Util::Disp;
use CBIL::Util::Utils;

use GUS::ObjRelP::DbiDatabase;
use GUS::Supported::GusConfig;
use GUS::PluginMgr::Args::StringArg;
use GUS::PluginMgr::Args::BooleanArg;
use GUS::PluginMgr::Args::FileArg;
use GUS::PluginMgr::Args::EnumArg;
use GUS::PluginMgr::Args::GlobArg;
use GUS::PluginMgr::Args::IntegerArg;
use GUS::PluginMgr::Args::TableNameArg;
use GUS::PluginMgr::Args::FloatArg;
use GUS::PluginMgr::Args::Arg;

use GUS::Model::Core::DatabaseInfo;
use GUS::Model::Core::TableInfo;

use Data::Dumper qw(Dumper);

=pod

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

=pod

=head2 Constructor

=item C<new()>

Construct a new Plugin.  This method I<must be overridden> by the
plugin subclass.  That is, the subclass must have its own C<new>
method which must:

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

=pod

=head2 Initialization

=over 4

=item C<initialize($argsHashRef)>

Initialize the plugin.  This method is called in the plugin's C<new>
method.

B<Parameters>

- argsHashRef (hash ref).  This argument is a hash ref which must
  contain the following key values pairs:

=over 4

=item * requiredDbVersion (string)

=item * cvsRevision (string)

The CVS revision number (eg 1.11) of the plugin.  The value for this
key I<must> be specified using the CVS magic substitution format.  In
particular, it must be: C<'$Revision$'>. CVS will substitute in
the revision number, so that, after substitution, the value will be,
eg, C<'$Revision$>'

=item * name (string)

The name of the plugin.  This value for this key I<must> be specified
like this: C<ref($self)>.

=item * C<documentation> (I<hashref>)

The documentation for this plugin (excluding the documentation for
command line arguments which is covered by C<argsDeclaration>).

The hashref may include only the following standard keys.  All string
values (e.g., C<purpose>, C<notes>) may include embedded POD
formatting directives.  If you use Perl's "here" document syntax (the
<< operator) to define your POD string, then you can use POD commands
as you ordinarily would. Otherwise, precede and follow all commands
(e.g., C<=item>) with C<\\n\\n>.

=over 4

=item * purpose (string)

The purpose of the plugin.  This should be as thorough as possible.

=item * purposeBrief (string)

A one sentence summary of the plugin's purpose.  This is displayed on
the first line of the help page.  It is also written into the
Core::Algorithm table as a description of the plugin.

=item * tablesAffected (listref of listrefs)

A list of tables the plugin writes to (excluding the standard overhead
tables).  For example:

C<my $tablesAffected = [
   ['DoTS::Assembly', 'Writes the finished assemblies here'],
   ['DoTS::Similarity', 'Writes its similarity here'],
];

=item * tablesDependedOn (listref of listrefs)

A list of tables the plugin depends on (excluding the standard
overhead tables).  This should include all controlled vocabulary
tables that the data the plugin is generating depends upon.

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

A declaration of the command line arguments expected by the plugin.
Each element of the list is an object which is a subclass of
C<GUS::PluginMgr::Args::Arg>.  See the Argument Declaration
Constructors (e.g. C<stringArg()>, C<fileArg>, etc).  These are
methods which construct and return these objects.

=item * revisionNotes (string)

This has been B<deprecated>.  It is not replaced by anything.

=item * easyCspOptions 

This has been B<deprecated>.  It is replaced by C<argsDeclaration>

=item * usage

This has been B<deprecated>.  It is replaced by C<documentation>

=cut

sub initialize {
  my ($self, $argsHashRef) = @_;

  my @args = ('requiredDbVersion', 'cvsRevision', 'name');

  foreach my $arg (@args) {
    $self->_failinit($arg) unless exists $argsHashRef->{$arg};
    $self->{$arg} = $argsHashRef->{$arg};
  }

  if (exists $argsHashRef->{usage}) {
    $self->{usage} = $argsHashRef->{usage};
  } elsif (exists $argsHashRef->{documentation}) {
    $self->{documentation} = $argsHashRef->{documentation};
    $self->checkDocumentation();
    $self->{usage} = $argsHashRef->{documentation}->{purposeBrief};
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

  $self->setOk(1); #assume all is well to start
}



# ----------------------------------------------------------------------
# Public Accessors
# ----------------------------------------------------------------------

=pod

=head2 Setters

=over 4

=item C<setResultDescr($resultDescrip)>

Set the result description.  This value is stored in the database in
the AlgorithmInvocation table's result column after the plugin
completes.

B<Params:>

- resultDescrip: a description of the plugin's main result for posterity.

=cut
sub setResultDescr {$_[0]->{resultDescr} = $_[1];}

=item C<setPointerCacheSize()>

The object cache holds 10000 objects by default. Use this method to change its
capacity.

=cut
sub setPointerCacheSize {
  my ($self, $size) = @_;
  $self->getDb()->setMaximumNumberOfObjects($size);
}

=item C<setOracleDateFormat($oracleDateFormat)>

Set Oracle's NLS_DATE_FORMAT for the duration of this plugin's run.  This is the format which oracle will allow for data of type 'Date.'  See Oracle's documentation to find valid formats.  The default format is 'YYYY-MM-DD HH24:MI:SS.'

B<Params:>

- oracleDateFormat: a string specifying a valid Oracle date format

=cut

sub setOracleDateFormat {
  my ($self, $oracleDateFormat) = @_;
  
  my $dateSql = $self->getDb()->getDbPlatform->dateFormatSql($oracleDateFormat);

  my $dbh = $self->getDb()->getDbHandle();

  $dbh->do($dateSql);
}

=pod

=head2 Getters

=over 4

=item C<getUsage()>

Get the plugin's usage.  This value is set by the C<initialize>
method.

B<Return type:> C<string>

=cut
sub getUsage             { $_[0]->{usage} }

=item C<getDocumentation()>

Get a hashref holding the plugin's documentation.  This value is set
by the C<initialize> method.

B<Return type:> C<string>

=cut
sub getDocumentation { $_[0]->{documentation} }

=item C<getRequiredDbVersion()>

Get the plugin's required database version.  This value is set by the
C<initialize> method.

B<Return type:> C<string>

=cut
sub getRequiredDbVersion { $_[0]->{requiredDbVersion} }

=item C<getCVSRevision()>

Get the plugin's CVS revision number.  This value is set by the
C<initialize> method.

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

=item C<getArgsDeclaration()>

Get the plugin's argument declaration.  This value is set by the
C<initialize> method.

B<Return type:> C<ref_to_list_of_Args>

=cut
sub getArgsDeclaration    { $_[0]->{argsDeclaration} }

=item C<getName()>

Get the name of the plugin, eg, C<GUS::Supported::Plugin::LoadRow>

B<Return type:> C<string>

=cut
sub getName       { $_[0]->{name} }

=item C<getFile()>

Get the full path of the file that contains the plugin, eg,
/home/me/gushome/lib/perl/GUS/Supported/Plugin/LoadRow.pm

B<Return type:> C<string>

=cut
sub getFile       { $_[0]->{__gus__plugin__FILE} }

=item C<getArg($name)>

Get the value of one of the plugin's command line arguments.

B<Return type:> scalar or list reference

=cut
sub getArg {
  my ($self, $name) = @_;
  my $args = $self->getArgs();
  die("Attempting to access command line argument '$name', but there is no such argument\n") unless exists($args->{$name});
  return $args->{$name};
}

=item C<setArg($name, $value)>

Force the value of one of the plugin's command line arguments to be 
the provided value.  (Caution: use this only if you know what you are
doing)

B<Return type:> none

=cut
sub setArg {
  my ($self, $name, $value) = @_;
  $self->{__gus__plugin__cla}->{$name} = $value;
}

=item C<getDb()>

Get the DbiDatabase object which represents the database this plugin
accesses.

B<Return type:> C<GUS::ObjRelP::DbiDatabase>

=cut
sub getDb         { $_[0]->{__gus__plugin__db} }

=item C<getAlgInvocation()>

Get the AlgorithmInvocation which tracks the running of this plugin in
the database.

B<Return type:> C<GUS::Model::Core::AlgorithmInvocation>

=cut
sub getAlgInvocation    { $_[0]->{__gus__plugin__self_inv} }

=item C<getDbHandle()>

Get the DbiDbHandle which objects use to submit themselves to the database.  This handle obeys the --commit flag.

B<Return type:> C<GUS::ObjRelP::DbiDbHandle>

=cut
sub getDbHandle    { $_[0]->getDb ? $_[0]->getDb->getDbHandle : undef }

=item C<getQueryHandle()>

Get a DbiDbHandle that is distinct from that used by the objects, for querying purposes.  This handle ignores the --commit flag.  Auto commit is off by default (ie, if no autocommit arg value is provided).  Any open transactions are rolled back upon plugin completion.  Warning: do not use this handle for writing permanant data, because it ignores the --commit flag.

B<Return type:> C<GUS::ObjRelP::DbiDbHandle>

=cut
sub getQueryHandle {
  my ($self, $autocommit) = @_;

  if (!$self->getDb()) {return undef};

  return $self->getDb()->getQueryHandle($autocommit);
}


=item C<getCheckSum()>

Get an md5 digest checksum of the perl file which codes this plugin.
(This is used by GusApplication when registering the plugin in the
database.)

B<Return type:> C<string>

=cut
sub getCheckSum {
  my $Self = shift;

  if (!$Self->{md5}) {
    my $f = $Self->getFile;

    if (defined $f) {
      $Self->{md5} = &runCmd("$Self->{md5sum_executable} $f");
      chomp $Self->{md5};
      $Self->{md5} =~ s/^(\S+).+/$1/;
    } else {
      $Self->error("Cannot find the plugin's executable file $Self->getFile");
    }
  }
  return $Self->{md5};
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

=pod

=head2 Argument Declaration Constructors

The Argument Declaration Constructors return Argument Declaration
objects, as expected by the initialize() method in its
C<argDeclaration> parameter.  Each arg declaration object specifies
the details of a command line argument expected by the plugin.  The
different constructors below are used to declare arguments of
different types, such as string, int, file, etc.

The argument declaration constructor methods each take a hashref as
their sole parameter.  This hashref must include the required set of
keys.

The following keys are standard and required for all the argument
declaration constructors. (Additional non-standard keys are indicated
below for each method as applicable.)

=over 4

=item * name (string)

The name of the argument (e.g., 'length' will expect a --length
argument on the command line)

=item * descr (string)

A description of the argument and what kinds of values are allowed.

=item * reqd (0 or 1)

Whether the user is required to provide this argument on the command
line

=item * default

The default value to use if the user doesn't supply one (or undef if
none)

=item * constraintFunc (method ref)

The method to call to check the validity of the value the user has
supplied (undef if none).  The method is called with two arugments:
($self, $argvalue) [where $self is the plugin object].  The method
returns a string describing the problem with the value if there is
one, or undef if there is no problem.

=item * isList (0 or 1)

True if the argument expects a comma delimited list of values instead
of a single value.

=back

=back

=item C<stringArg($argDescriptorHashRef)>

Construct a string argument declaration.

B<Parameters>

- argDescriptorHashRef (hash ref).  This argument is a hash ref which
  must contain the standard keys described above.

B<Return type:> C<GUS::PluginMgr::Args::StringArg>

=cut
sub stringArg {
  my ($paramsHashRef) = @_;
  return GUS::PluginMgr::Args::StringArg->new($paramsHashRef);
}

=item C<integerArg($argDescriptorHashRef)>

Construct a integer argument declaration.

B<Parameters>

- argDescriptorHashRef (hash ref).  This argument is a hash ref which
  must contain the standard keys described above.

B<Return type:> C<GUS::PluginMgr::Args::IntegerArg>

=cut
sub integerArg {
  my ($paramsHashRef) = @_;
  return GUS::PluginMgr::Args::IntegerArg->new($paramsHashRef);
}

=item C<booleanArg($argDescriptorHashRef)>

Construct a boolean argument declaration.

B<Parameters>

- argDescriptorHashRef (hash ref).  This argument is a hash ref which
  must contain the standard keys described above with the exception of
  'isList' and 'constraintFunc', which are not applicable.

B<Return type:> C<GUS::PluginMgr::Args::BooleanArg>

=cut
sub booleanArg {
  my ($paramsHashRef) = @_;
  return GUS::PluginMgr::Args::BooleanArg->new($paramsHashRef);
}

=item C<tableNameArg($argDescriptorHashRef)>

Construct a tableName argument declaration.

B<Parameters>

- argDescriptorHashRef (hash ref).  This argument is a hash ref which
  must contain the standard keys described above.

B<Return type:> C<GUS::PluginMgr::Args::TableNameArg>

=cut
sub tableNameArg {
  my ($paramsHashRef) = @_;
  return GUS::PluginMgr::Args::TableNameArg->new($paramsHashRef);
}

=item C<floatArg($argDescriptorHashRef)>

Construct a float argument declaration.

B<Parameters>

- argDescriptorHashRef (hash ref).  This argument is a hash ref which
  must contain the standard keys described above.

B<Return type:> C<GUS::PluginMgr::Args::FloatArg>

=cut
sub floatArg {
  my ($paramsHashRef) = @_;
  return GUS::PluginMgr::Args::FloatArg->new($paramsHashRef);
}

# ----------------------------------------------------------------------

=item C<fileArg($argDescriptorHashRef)>

Construct a file argument declaration.

B<Parameters>

- argDescriptorHashRef (hash ref).  This argument is a hash ref which must contain the standard keys described above and also

over 4

=item * mustExist (0 or 1)

Whether the file must exist

=item * format (string)

A description of the file's format

B<Return type:> C<GUS::PluginMgr::Args::FileArg>

=cut

sub fileArg {
  my ($paramsHashRef) = @_;
  return GUS::PluginMgr::Args::FileArg->new($paramsHashRef);
}


=item C<enumArg($argDescriptorHashRef)>

Construct an enum argument declaration.

B<Parameters>

- argDescriptorHashRef (hash ref).  This argument is a hash ref which must contain the standard keys described above and also

over 4

=item * enum (a comma delimited list of terms)

The allowed values for this arugment

B<Return type:> C<GUS::PluginMgr::Args::EnumArg>

=cut

sub enumArg {
  my ($paramsHashRef) = @_;
  return GUS::PluginMgr::Args::EnumArg->new($paramsHashRef);
}


# ----------------------------------------------------------------------

=item C<globArg($argDescriptorHashRef)>

Construct a glob argument declaration.

B<Parameters>

- argDescriptorHashRef (hash ref).  This argument is a hash ref which must contain the standard keys described above and also

over 4

=item * mustExist (0 or 1)

Whether the glob must match some existing files.

=item * format (string)

A description of the format of the files that match the glob.

B<Return type:> C<GUS::PluginMgr::Args::GlobArg>

=cut

sub globArg {
  my ($paramsHashRef) = @_;
  return GUS::PluginMgr::Args::GlobArg->new($paramsHashRef);
}

# ----------------------------------------------------------------------

=item C<globArg($argDescriptorHashRef)>

Construct a glob argument declaration.

B<Parameters>

- argDescriptorHashRef (hash ref).  This argument is a hash ref which must contain the standard keys described above and also

over 4

=item * mustExist (0 or 1)

Whether the glob must match some existing files.

=item * format (string)

A description of the format of the files that match the glob.

B<Return type:> C<GUS::PluginMgr::Args::GlobArg>

=cut

sub globArg {
  my ($paramsHashRef) = @_;
  return GUS::PluginMgr::Args::GlobArg->new($paramsHashRef);
}

# ----------------------------------------------------------------------
# Public Utilities
# ----------------------------------------------------------------------

=pod

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

=item C<getExtDbRlsId($dbName, $dbVersion)>

Retrieve an external database release id from SRes::ExternalDatabaseRelease given the name of a database and the version corresponding to the release.  

Whether provided as (name, version) or "name|version", the name must match an name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease

Die if none found.  (If you just want to test for its existence, call the method in an eval{} block.)

B<Parameters:>

    - dbNameOrSpecifier (string): Either the name of the database (in which case the dbVersion argument is required) or a specifier (in which case the dbVersion argument must be undefined).  The specifier must be in the form: name|version.
    - dbVersion (string): Version of the database.  Required only if the first parameter is a name not a specifier.

B<Return type:> C<integer>

=cut
sub getExtDbRlsId {
    my ($self, $dbNameOrSpecifier, $dbVersion) = @_;

    my $dbName;
    if ($dbNameOrSpecifier =~ /(.+)\|(.+)/) {
      die "Can't provide a dbSpecifier and a dbVersion" if $dbVersion;
      $dbName = $1;
      $dbVersion = $2
    } else {
      die "Database specifier '$dbNameOrSpecifier' is not in 'name|version' format" unless $dbVersion;
      $dbName = $dbNameOrSpecifier;
    }

    my $lcName = lc($dbName);
    my $sql = "select ex.external_database_release_id
               from sres.externaldatabaserelease ex, sres.externaldatabase e
               where e.external_database_id = ex.external_database_id
               and ex.version = '$dbVersion'
               and lower(e.name) = '$lcName'";

    my $sth = $self->getQueryHandle()->prepareAndExecute($sql);

    my ($releaseId) = $sth->fetchrow_array();

    die "Couldn't find an external database release id for db '$dbName' version '$dbVersion'.  Use the plugins InsertExternalDatabase and InsertExternalDatabaseRls to insert this information into the database" unless $releaseId;

    return $releaseId;
}

=item C<prepareAndExecute($sql)>

Prepare an SQL statement and execute it.  This method is a convenience wrapper around $self->getQueryHandle()->prepareAndExecute().  In plugins, SQL is usually reserved for querying, not for writing to the database.  GUS objects do that work with better tracking and more easily.  For more complicated database operations see the file $PROJECT_HOME/OblRelP/lib/perl/DbiDbHandle.pm


B<Parameters:>

- sql (string): The SQL to prepare and execute.

B<Return type:> C<statementHandle>

=cut
sub prepareAndExecute {
  my ($self, $sql) = @_;
  $self->getQueryHandle()->prepareAndExecute($sql);
}

=item C<getControlledVocabMapping($cvMappingFile, $cvTable, $cvTermColumn, $cvTermPKColumn)>

Read a file mapping input terms to a GUS CV.  Validate the GUS CV against
the provided table.  If the GUS CV in the file is not entirely contained in the table, die.  If it is, return the CV as a hash with the input terms as key and a reference to an array with tuple [gusTerm, gusPrimaryKey] as value.

B<Parameters:>

- cvMappingFile (string): The name of the file which contains the mapping.  It must be two columns tab delimited where the first column is the input terms and the second column is the GUS CV.

- cvTable (string):  The name of the table in gus (in schema.table format) which contains the CV.

- cvTermColumn (string):  The name of the column in cvTable that contains the terms.

- cvTermPKColumn (string):  The name of the column in cvTable that contains its primary key.

B<Return type:> C<hash reference>

=cut
sub getControlledVocabMapping {
  my ($self, $cvMappingFile, $cvTable, $cvTermColumn, $cvTermPKColumn) = @_;

  -r $cvMappingFile
    || $self->error("file '" . $cvMappingFile ."' cannot be open for reading");

  # connect to db to read the cv from GUS
  my $sql = 
    "select $cvTermPKColumn, $cvTermColumn
     from $cvTable";

  my $queryHandle = $self->getQueryHandle();
  my $sth = $queryHandle->prepareAndExecute($sql);

  my %gusTerm2PrimaryKey;
  while (my ($primaryKey, $term) = $sth->fetchrow_array()) {
    $gusTerm2PrimaryKey{$term} = $primaryKey;
  }

  my %userTerm2PrimaryKey;
  my %userTerm2GusTerm;
  my %userTerm2GusTermAndPrimaryKey;
  my @notReallyGusTerms;

  open(MAPPING_FILE, $cvMappingFile) 
    || $self->userError("can't open file '$cvMappingFile'");
  while (<MAPPING_FILE>) {
    /^(\w+)\t(\w+)\s*$/
      || $self->userError("File '$cvMappingFile' is not in two column tab-delimited format: '$_'");
    my $userTerm = $1;
    my $inputGusTerm = $2;
    if (!$gusTerm2PrimaryKey{$inputGusTerm}) {
      push(@notReallyGusTerms, $inputGusTerm);
    } else {
      if ($userTerm2GusTerm{$userTerm}
	  && $userTerm2GusTerm{$userTerm} ne $inputGusTerm) {
	die "CV mapping file '$cvMappingFile' has inconsistent mappings forinput term  '$userTerm'"
      }
      $userTerm2GusTerm{$userTerm} = $inputGusTerm;
      $userTerm2GusTermAndPrimaryKey{$userTerm} =
	[$inputGusTerm, $gusTerm2PrimaryKey{$inputGusTerm}];
    }
  }

  if (scalar @notReallyGusTerms > 0) {
    $self->userError("The following terms found in file '$cvMappingFile' are not in GUS table $self->{table}: " . join(" ", @notReallyGusTerms));
  }

  return \%userTerm2GusTermAndPrimaryKey;
}

=item C<getTotalInserts()>

Get the total number of inserts.

=cut
sub getTotalInserts {
  my ($self) = @_;
  $self->getAlgInvocation()->getTotalInserts()
    - $self->{irrelevantTotalInserts};
}

=item C<getTotalUpdates()>

Get the total number of updates.

=cut
sub getTotalUpdates {
  my ($self) = @_;
  $self->getAlgInvocation()->getTotalUpdates()
    - $self->{irrelevantTotalUpdates};
}

sub initIrrelevantCounts {
    my ($self) = @_;
    $self->{irrelevantTotalInserts} = 
      $self->getAlgInvocation()->getTotalInserts();
    $self->{irrelevantTotalUpdates} = 
      $self->getAlgInvocation()->getTotalUpdates();
}

=item C<className2TableId($className)>

Convert a perl style class name for a database object to a numerical table id suitable for comparison to one of GUS's many table_id columns.  For example, convert Core::Algorithm to something like 34.

B<Parameters:>

- className (string):  A class name in the form: Core::Algorithm

B<Return type:> C<integer>

=cut
sub className2TableId {
  my ($self, $className) = @_;
  $self->getAlgInvocation()->getTableIdFromTableName($className);
}

=item C<getFullTableClassName($className)>

If given a full class name or one in schema::table format (case insensitive in both cases), return the full class name w/ proper case, ie GUS::Model:Schema:Table or null if no such table

B<Parameters:>
 -

- getFullTableClassName (string):  A class name in the form: Core::Algorithm (case insensitive)

B<Return type:> C<string>

=cut
sub getFullTableClassName {
  my ($self, $className) = @_;
  $self->getDb()->getFullTableClassName($className);
}

=item C<className2tableId($className)>

Convert a perl style class name for a database object to a numerical table id suitable for comparison to one of GUS's many table_id columns.  For example, convert Core::Algorithm to something like 34.

B<Parameters:>

- className (string):  A class name in the form: Core::Algorithm (case sensitive)

B<Return type:> C<integer>

=cut
sub className2tableId {
  my ($self, $className) = @_;

  my @classParts = split /::/, $className;

  if ($#classParts != 1) {
    die("className2tableId requires a table name argument " .
	"in the format 'schema::table'");
  }

  my $dbName = $classParts[0];
  my $tableName = $classParts[1];

  my $db =
    GUS::Model::Core::DatabaseInfo->new( { name => $dbName } );

  if (! $db->retrieveFromDB() ) {
    die("can't find database schema $dbName");
  }

  my $table =
    GUS::Model::Core::TableInfo->new
	( {
	   name => $tableName,
	   database_id => $db->getDatabaseId()
	  } );

  if (! $table->retrieveFromDB() ) {
    die("can't find table $tableName in schema $dbName");
  }

  return $table->getTableId();
}

=item C<undefPointerCache()>

Clear out the GUS Object Layer's cache of database objects.  The
object cache holds 10000 objects by default.  (You can change its
capacity by calling C<< $self->getDb()->setMaximumNumberOfObjects()
>>.)  Typically a plugin may loop over a set of input, using a number
of objects for each iteration through the loop.  Because the next time
through the loop will not need those objects, it is good practice to
call C<< $self->undefPointerCache() >> at the bottom of the loop to
avoid filling the cache with objects that are not needed anymore.

=cut
sub undefPointerCache {	$_[0]->getAlgInvocation->undefPointerCache }


# ----------------------------------------------------------------------
# Documentation
# ----------------------------------------------------------------------

=pod

=head2 Documentation

=over 4

=item C<printDocumentationText($synopsis, $argDetails)>

Print documentation for this plugin in text format.  The documentation
includes a synopsis, description, and argument details

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

Print documentation for this plugin in HTML format.  The documentation
includes a synopsis, description, and argument details

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

sub Pod2Text {
   my ($File) = @_;

   my $command = "pod2text $File";
   return `$command`;
}

sub _formatDocumentationPod {
  my ($self, $synopsis, $argDetails) = @_;

  my $doc = $self->getDocumentation();

  my $s .= "\n=head1 NAME\n\n";
  $s .= "$self->{name} -  $doc->{purposeBrief} \n\n";
  $s .= "\n=head1 SYNOPSIS\n\n";
  $s .= "$synopsis\n\n";
  $s .= "\n=head1 DESCRIPTION\n\n";
  $s .= "$doc->{purpose}\n";
  $s .= "\n=head1 TABLES AFFECTED\n\n";
  my $tablesAffected = $self->_getTablesAffected();
  foreach my $tbl (@$tablesAffected) {
    my ($tblName, $descrip) = @$tbl;
    $s .= "\n=item B<$tblName>\n\n=over 4\n\n$descrip\n\n=back\n\n";
  }
  $s .= "\n";
  $s .= "\n=head1 TABLES DEPENDED ON\n\n";
  my $tablesDependedOn = $self->_getTablesDependedOn();
  foreach my $tbl (@$tablesDependedOn) {
    my ($tblName, $descrip) = @$tbl;
    $s .= "\n=item B<$tblName>\n\n=over 4\n\n$descrip\n\n=back\n\n";
  }
  $s .= "\n";
  if ($doc->{failureCases}) {
    $s .= "\n=head1 FAILURE CASES\n\n";
    $s .= "$doc->{failureCases}\n";
  }
  if ($doc->{howToRestart}) {
    $s .= "\n=head1 RESTARTING\n\n";
    $s .= "$doc->{howToRestart}\n";
  }
  $s .= "\n=head1 ARGUMENTS IN DETAIL\n\n";
  $s .= "$argDetails\n";
  if ($doc->{notes}) {
    $s .= "\n=head1 NOTES\n\n";
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

=pod

=head2 Error handling

=over 4

=item C<error($msg)>

Handle a fatal error in a plugin.  This method terminates the plugin
gracefully, writing the provided message to STDERR.  It also writes a
stack trace showing where the error occurred.

When the plugin is terminated, GusApplication will still catch the
error and attempt to track the plugin's failure in the database.

Do not use this method to report user errors such as invalid argument
values (use C<userError> for that).

B<Parameters>

- msg (string):  the error message to write.

=cut
sub error {
  my ($self, $msg) = @_;

  die "\nERROR: $msg\n";

}

=item C<userError($msg)>

Handle a fatal user error in a plugin.  This method terminates the
plugin gracefully, writing the provided message to STDERR.  It it
intended only for errors made by the user of the plugin (such as
incorrect argument values).

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

=pod

=head2 Logging

=over 4

=item C<log($msg1, $msg2, ...)>

Write a date stamped tab delimited message to STDERR.  The messages
supplied as arguments are joined with tabs in between.

B<Parameters>

- @messages (list of strings):  the error messages to write.

=cut

sub log {
  my $Self = shift;

  my $time_stamp_ = localtime;

  my $msg = join("\t", $time_stamp_, @_);

  print STDERR "$msg\n";
}

=item C<logDebug($msg1, $msg2, ...)>

Write a date stamped tab delimited debugging message to STDERR.  The
messages supplied as arguments are joined with tabs in between.  It
will only be written if the user specifies the C<--debug> argument.

B<Parameters>

- @messages (list of strings):  the error messages to write.

=cut

sub logDebug {
  my $Self = shift;

  return unless $Self->getArgs()->{debug};
  my $msg = join("\t", @_);

  print STDERR "\n$msg\n";
}

=item C<logVerbose($msg1, $msg2, ...)>

Write a date stamped tab delimited debugging message to STDERR.  The
messages supplied as arguments are joined with tabs in between.  It
will only be written if the user specifies the C<--verbose> argument.

B<Parameters>

- @messages (list of strings):  the error messages to write.

=cut
sub logVerbose {
  my $Self = shift;

  $Self->log(@_) if $Self->getArgs()->{verbose};
}

=item C<logVeryVerbose($msg1, $msg2, ...)>

Write a date stamped tab delimited debugging message to STDERR.  The
messages supplied as arguments are joined with tabs in between.  It
will only be written if the user specifies the C<--veryVerbose>
argument.

B<Parameters>

- @messages (list of strings):  the error messages to write.

=cut
sub logVeryVerbose {
  my $Self = shift;

  $Self->log(@_) if $Self->getArgs()->{veryVerbose};
}

=item C<logData($msg1, $msg2, ...)>

Write a date stamped tab delimited debugging message to STDOUT.  The
messages supplied as arguments are joined with tabs in between.

B<Parameters>

- @messages (list of strings):  the error messages to write.

=cut
sub logData {
  my $Self = shift;
  my $T = shift;

  my $time_stamp_ = localtime;

  my $msg = join("\t", $time_stamp_, $T, @_);

  print "$msg\n";

  # RETURN
  $msg

}

=item C<logDsn()>

Log to STDERR the Data Source Name used for this run of the plugin.

=cut
sub logDsn {
    my $Self = shift;
    $Self->log('DSN', $Self->getDb->getDSN);
}

=item C<logAlgInvocationId()>

Log to STDERR the id for the AlgorithmInvocation that represents this
run of the plugin in the database.

=cut
sub logAlgInvocationId {
  my $Self = shift;

  $Self->log('AlgInvocationId', $Self->getAlgInvocation->getId)
}

=item C<logCommit()>

Log to STDERR the state of the commit flag for this run of the plugin.

=cut
sub logCommit {
  my $Self = shift;

  $Self->log('COMMIT', $Self->getCla->{commit} ? 'commit on' : 'commit off');
}

=item C<logArgs()>

Log to STDERR the argument values used for this run of the plugin.

=cut

sub logArgs {

  my $Self = shift;

  foreach my $flag (sort keys %{$Self->getCla}) {
    my $value = $Self->getCla->{$flag};
    if (ref($value) eq "ARRAY") {
      $Self->log('ARG', $flag, @$value);
    } elsif (ref($value)) {
      $Self->log('ARG', $flag, Dumper($value));
    } else {
      $Self->log('ARG', $flag, $value);
    }
  }
}

=item C<logArgs()>

Log to STDERR the argument values used for this run of the plugin.

=cut

sub logPluginName {

  my $Self = shift;

  my $name = ref($Self);
  $Self->log('PLUGIN', $name);
}

=item C<logRowsInserted()>

Log to STDERR a report, by table, of the count of rows actually written
with the run's algorithm invocation id.  (only possible if the plugin has a
undoTables() method)

=cut

sub logRowsInserted {
  my ($self) = @_;

  if ($self->can(undoTables)) {  # test for existance of undoTables method
    my @tables = $self->undoTables();
    foreach my $table (@tables) {
      $self->_logMyRows($table);
    }
  } else {
    $self->log('Rows Written', "N/A (plugin has no 'undoTables()' method)");
  }
}

sub logWrap {
   my $Self = shift;
   my $Tag  = shift;
   my $Text = shift;

   my @lines = split(/\n/, $Text);

   foreach (@lines) {
      $Self->log($Tag, $_);
   }
}

# ----------------------------------------------------------------------
# Pod-based documentation
# ----------------------------------------------------------------------

=head2 Pod-based Documentation

=cut

sub extractDocumentationFromMyPod {
   my $Self = shift;

   my %Rv = ( purpose          => '',
              purposeBrief     => '',
              howToRestart     => '',
              failureCases     => '',
              notes            => '',
            );

   my $tag = 'notes';
   my $pod_b;

   my $class = ref($Self);
   $class =~ s/::/\//g;
   my $_f  = $INC{"$class.pm"};
   my $_fh = FileHandle->new("<$_f")
   || die "Can not open self in '$class' as '$_f' for pod documentation: $!";
   while (<$_fh>) {
      if (/^=pod/) {
         $pod_b = 1;
      }

      elsif (/^=cut/) {
         $pod_b = 0;
      }

      elsif ($pod_b) {
         if (/^=head1 \s*(.+?)\s*$/) {
            my $head1 = $1; $head1 =~ s/\s+/ /g;

            if ($head1 =~ /^Purpose$/i) {
               $tag = 'purpose';
            }
            elsif ($head1 =~ /^Purpose Brief$/i) {
               $tag = 'purposeBrief';
            }
            elsif ($head1 =~ /^How to Restart$/i) {
               $tag = 'howToRestart';
            }
            elsif ($head1 =~ /^Failure Cases$/i) {
               $tag = 'falilureCases';
            }
            elsif ($head1 =~ /^Notes$/i) {
               $tag = 'notes';
            }
            else {
               $tag = 'notes';
               $Rv{$tag} .= $_;
            }
         }

         elsif (defined $tag) {
            $Rv{$tag} .= $_;
         }
      }
   }
   $_fh->close();

   return wantarray ? %Rv : \%Rv;;
}

# ----------------------------------------------------------------------
# Common SQL routines
# ----------------------------------------------------------------------

=head2 SQL utilities

=head3 New Version

The new version of these methods take a hash (ref) as an argument
which can contain the following keys.

  Sql    - string - an SQL statement to evaluate

  Handle - statement handle - previously prepared
  Bind   - array ref        - values to bind to Handle

  Code   - code ref - a call back routine to process each row.
         - string   - name of a plugin method to call with row as argument.

Sql or Handle and Bind must be present.

Code is optional.  If not supplied then all rows will be returned in
an array (ref).  Fetching will stop when Code function returns a false
value.

For example

  # get a list of user_ids from the database
  my @ids = $Self->sqlAsArray( Sql => 'select user_id from SRes.UserInfo' );

  # build up a dictionary of user ids
  my %users = ();
  $Self->sqlAsHashRef( Sql  => 'select user_id, last_name from SRes.UserInfo',
                       Code => sub {
                          my $Row = shift;
                          $users{$Row->{user_id}} = $Row->{last_name}
                          return 1;
                       }
                     );

  #
  $Self->sqlAsArray( Sql  => 'select user_id, last_name from SRes.UserInfo',
                     Code => 'processUser'
                   );
  ...
  sub processUser {
     my $Self     = shift;
     my $UserId   = shift;
     my $LastName = shift;

     # process
     ...

     return 1;
  }

  # as above, but more simply.
  my $users = $Self->sqlAsDictionary( Sql  => 'select user_id, last_name from SRes.UserInfo' );


=cut

sub sqlDie {
   my $Self = shift;
   my $Sql  = shift;

   $Self->log('INFO', 'OffendingSqlStatement', $Sql);
   die $@;
}

sub sqlGetStatementHandle {
   my $Self = shift;
   my $Args = shift;

   my $Rv;

   if (defined $Args->{Sql}) {
      eval { $Rv = $Self->getQueryHandle->prepareAndExecute($Args->{Sql}) };
      $@ && $Self->sqlDie($Args->{Sql});
   }
   else {
      $Rv = $Args->{Handle};
      $Rv->execute(@{$Args->{Bind}});
   }

   return $Rv;
}

=pod

=head4 sqlAsNoResult

Executes the statement, but does not expect a return value.

=cut

sub sqlAsNoResult {
   my $Self = shift;
   my $Args = ref $_[0] ? shift : {@_};

   my $Rv;

   eval {
      if ($Self->sqlGetStatementHandle($Args)) {
         $Rv = 1;
      }
      else {
         $Rv = 0;
      }
   };
   $@ && $Self->sqlDie($Args->{Sql});

   return $Rv;
}

=pod

=head4 sqlAsArray

Fetches rows as arrays.  If there is no C<Code> supplied, then the
rows are merged into one big array for the return value.  This is most
useful when there is only one column or one row returned.

=cut

sub sqlAsArray {
   my $Self = shift;
   my $Args = ref $_[0] ? shift : {@_};

   my @Rv;

   my $sh = $Self->sqlGetStatementHandle($Args);

   eval {

      my $Code = $Args->{Code};

      # code ref
      if (ref $Code) {
         while (my @row = $sh->fetchrow_array()) {
            last unless $Code->(@row);
         }
      }

      # method name
      elsif ($Code) {
         while (my @row = $sh->fetchrow_array()) {
            last unless $Self->$Code(@row);
         }
      }

      # push on list
      else {
         while (my @row = $sh->fetchrow_array()) {
            push(@Rv, @row);
         }
      }

      $sh->finish();
   };

   $@ && $Self->sqlDie($Args->{Sql});

   return wantarray ? @Rv : \@Rv;
}

sub sqlAsArrayRefs {
   my $Self = shift;
   my $Args = ref $_[0] ? shift : {@_};

   my @Rv;

   my $sh = $Self->sqlGetStatementHandle($Args);

   eval {

      my $Code = $Args->{Code};

      # code ref
      if (ref $Code) {
         while (my $row = $sh->fetchrow_arrayref()) {
            last unless $Code->($row);
         }
      }

      # method name
      elsif ($Code) {
         while (my $row = $sh->fetchrow_arrayref()) {
            last unless $Self->$Code($row);
         }
      }

      # push on list
      else {
         while (my $row = $sh->fetchrow_arrayref()) {
            push(@Rv, $row);
         }
      }

      $sh->finish();
   };

   $@ && $Self->sqlDie($Args->{Sql});

   return wantarray ? @Rv : \@Rv;
}

sub sqlAsHashRefs {
   my $Self = shift;
   my $Args = ref $_[0] ? shift : {@_};

   my @Rv;

   my $sh = $Self->sqlGetStatementHandle($Args);

   eval {

      my $Code = $Args->{Code};

      # code ref
      if (ref $Code) {
         while (my $row = $sh->fetchrow_hashref('NAME_lc')) {
            last unless $Code->($row);
         }
      }

      # method name
      elsif ($Code) {
         while (my $row = $sh->fetchrow_hashref('NAME_lc')) {
            last unless $Self->$Code($row);
         }
      }

      # push on list
      else {
         while (my $row = $sh->fetchrow_hashref('NAME_lc')) {
            push(@Rv, $row);
         }
      }

      $sh->finish();
   };

   $@ && $Self->sqlDie($Args->{Sql});

   return wantarray ? @Rv : \@Rv;
}

=pod

=head2 sqlAsDictionary

Assumes the query has (at least) two columns.  It executes the query
and uses the first column as the key and the second column as the
value.  The results are put in a dictionary (hash) which is return as
a ref or not depending on the context.

=cut

sub sqlAsDictionary {
   my $Self = shift;
   my $Args = ref $_[0] ? shift : {@_};

   my %Rv;

   $Self->sqlAsArray({ %$Args,
                       Code => sub { $Rv{$_[0]} = $_[1]; return 1; }
                     });

   return wantarray ? %Rv : \%Rv;
}

# ------------------------ Old Style SQL Support -------------------------
=over 4

=item C<sql_get_as_array()>



B<Return type:> C<string>

=cut

sub sql_get_as_array {
  my $Self = shift;
  my $Sql = shift;		# SQL query
  my $H = shift;		# handle and ...
  my $B = shift;		# bind args which are used only if SQL is not defined.

  my @RV;

  # get a statement handle.
  my $sh;
  if (defined $Sql) {
		 eval { $sh = $Self->getQueryHandle->prepareAndExecute($Sql) };
		 if ($@) {
				$Self->log('INFO', 'OffendingSqlStatement', $Sql);
				die $@;
		 }
  } else {
    $sh = $H;
    $sh->execute(@$B);
  }

  # collect results
	eval {
		 while (my @row = $sh->fetchrow_array) {
				push(@RV,@row);
		 }
		 $sh->finish;
	};

	if ($@) {
		 $Self->log('INFO', 'OffendingSqlStatement', $Sql) if $Sql;
		 die $@;
	}
  #CBIL::Util::Disp::Display(\@RV);

  # RETURN
  \@RV
}

=item C<()>

B<Return type:> C<string>

=cut
sub sql_get_as_array_refs {
  my $Self = shift;
  my $Sql = shift;		# SQL query
  my $H = shift;		# handle and ...
  my $B = shift;		# bind args which are used only if SQL is not defined.
  my $CallBack = shift;

  my @RV;

  # get a statement handle.
  my $sh;
  if (defined $Sql) {
    eval { $sh = $Self->getQueryHandle->prepareAndExecute($Sql) };
		 if ($@) {
				$Self->log('INFO', 'OffendingSqlStatement', $Sql);
				die $@;
		 }
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
  my $Self = shift;
  my $Sql = shift;
  my $H = shift;
  my $B = shift;

  my @RV;

  # get a statement handle.
  my $sh;
  if (defined $Sql) {
    eval { $sh = $Self->getQueryHandle->prepareAndExecute($Sql) };
		 if ($@) {
				$Self->log('INFO', 'OffendingSqlStatement', $Sql);
				die $@;
		 }
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
  my $Self = shift;
  my $Sql = shift;
  my $H = shift;
  my $B = shift;

  my @RV;

  # get a statement handle.
  my $sh;
  if (defined $Sql) {
		 eval { $sh = $Self->getQueryHandle->prepareAndExecute($Sql) };
		 if ($@) {
				$Self->log('INFO', 'OffendingSqlStatement', $Sql);
				die $@;
		 }
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

=item C<sql_translate()>

B<Return type:> C<string>

=cut
sub sql_translate {
  my $Self  = shift;
  my $T  = shift;		# table
  my $Kc = shift;		# key column name
  my $Vc = shift;		# value column name
  my $V  = shift;		# value

  # load cache if we need to.
  if (not defined $Self->{__gus__plugin_sql_xlate_cache}->{$T}->{$Vc}) {
    my $sql = "select $Vc,$Kc from $T";
    my %cache = map {@$_} @{$Self->sql_get_as_array_refs($sql)};
    $Self->{__gus__plugin_sql_xlate_cache}->{$T}->{$Vc} = \%cache;
    #CBIL::Util::Disp::Display(\%cache);
    #CBIL::Util::Disp::Display([$T, $Kc,$Vc, $V, $Self->{__gus__plugin_sql_xlate_cache}->{$T}->{$Vc}->{$V}] );
  }

  # RETURN
  $Self->{__gus__plugin_sql_xlate_cache}->{$T}->{$Vc}->{$V};
}

# ----------------------------------------------------------------------
# Deprecated
# ----------------------------------------------------------------------

=pod

=head2 Deprecated

=over 4

=item C<getEasyCspOptions()>

Replaced by getArgsDeclaration()

=cut
sub getEasyCspOptions { 
  my ($self) = @_;
  if ($self->{argsDeclaration} && !$self->{easyCspOptions}) {
    $self->{easyCspOptions} = {};
    foreach my $arg (@{$self->{argsDeclaration}}) {
      $self->{easyCspOptions}->{$arg->getName} = $arg->getEasyCsp();
    }
  }

  return $self->{easyCspOptions};
}

=item C<getRevisionNotes()>

No longer used.

B<Return type:> C<string>

=cut
sub getRevisionNotes       { $_[0]->{revisionNotes} }

=item C<getArgs()>

Replaced by getArg()

=cut
sub getArgs { 
  my ($self, $nono) = @_;

  $self->error("getArgs() is being called with an argument.  Use getArg() instead") if $nono;

  return$self->{__gus__plugin__cla};
}

=item C<getSelfInv()>

Replaced by C<getAlgInvocation>

=cut
sub getSelfInv    { $_[0]->getAlgInvocation(); }

=item C<getCla()>

Replaced by C<getArg>

=cut
sub getCla        { $_[0]->getArgs(); }

=item C<logAlert()>

Replaced by C<log>

=cut
sub logAlert      { my $Self = shift; $Self->log(@_); }

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
  my $Self = shift;
  my $N = shift;

  $Self->{__gus__plugin__name} = $N;
  my $c = $N; $c =~ s/::/\//g; $c .= '.pm';
  $Self->_initFile($INC{$c});

  # RETURN
  $Self
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
sub _logMyRows {
  my ($self, $tableName) = @_;

  my $raii = $self->getAlgInvocation()->getId();
  my $sql =
"SELECT count(*) from $tableName
WHERE row_alg_invocation_id = $raii";

  my $stmt = $self->getQueryHandle->prepareAndExecute($sql);

  my ($count) = $stmt->fetchrow_array();
  $self->log('Rows Written', "$tableName: $count");
}

sub _initEasyCspOptions    {
  my $Self = shift;

  my $args_n = scalar @_;
  my $type_s = ref $_[0];

  # list (of assumed hash refs)
  if ($args_n > 1) {
    $Self->{easyCspOptions} = { map {($_->{o},$_)} @_ };
  }

  # list ref (of assumed hash refs)
  # (this is the expected case, the others being legacy)
  elsif ($type_s eq 'ARRAY') {
    $Self->{easyCspOptions} = { map {($_->{o},$_)} @{$_[0]} };
  }

  # direct hash ref
  else {
    $Self->{easyCspOptions} = $_[1];
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

  foreach my $argKey (keys %{$Self->{easyCspOptions}}) {
    my $arg = $Self->{easyCspOptions}->{$argKey};
    $Self->error("EasyCspOption '$arg->{o}' has an invalid type '$arg->{t}'.  Valid types are: $types") unless $types{$arg->{t}};
  }

  # RETURN
  $Self
}

sub _initFile       { $_[0]->{__gus__plugin__FILE} = $_[1]; $_[0] }

sub _failinit {
  my ($self, $argname) = @_;

  print STDERR "Plugin initialization failed: invalid argument '$argname'\n";
  exit 1;
}

1;


