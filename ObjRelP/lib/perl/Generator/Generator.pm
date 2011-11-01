#
# Generate a set of database objects
#
# Nico Zigouras. 12/09/99, updated until 01/15/99
# modified by Brian Brunk
# additional modifications 3/29/2000 so that generator does not 
# create any method names that over-ride methods in super classes
# Modified by Sharon Diskin 7/5/2000 to support DBI.
#
# Refactored into TableGenerator, RowGenerator and WrapperGenerator by Steve Fischer 10/29/2002

package GUS::ObjRelP::Generator::Generator;

use strict;
use GUS::ObjRelP::DbiDatabase;

use GUS::ObjRelP::Generator::PerlTableGenerator;
use GUS::ObjRelP::Generator::PerlRowGenerator;
use GUS::ObjRelP::Generator::PerlWrapperGenerator;

use GUS::ObjRelP::Generator::JavaTableGenerator;
use GUS::ObjRelP::Generator::JavaRowGenerator;
use GUS::ObjRelP::Generator::JavaWrapperGenerator;



# param db: dbi object
# param special_cases_file: ???
# param targetDir: directory to generate into.  also holds .man files
# param superclassesLibDir: directory in which to find superclass files
# param schemas: a list of schemas to restrict generation to.  null = all
# param tables: a list of tables to restrict generation to.  null = all
sub new {
  my( $class, $db, $targetDir, $specialCasesFile, $superclassesLibDir,
      $javaOrPerl, $schemas, $tables, $makeImpTables) = @_;

  my $self = {};
  bless $self, $class;

  die "Target directory $targetDir doesn't exist" unless -d $targetDir;

  die "Superclasses lib directory $superclassesLibDir doesn't exist"
      unless -d $superclassesLibDir;

  $self->{db} =  $db;
  $self->{targetDir} = $targetDir;
  $self->{superclassesLibDir} = $superclassesLibDir;
  $self->{tables} = $tables;
  $self->{tables} = $self->{db}->getTableAndViewNames()
    unless scalar(@{$self->{tables}});
  $self->{javaOrPerl} = $javaOrPerl;
  $self->{makeImpTables} = 0 unless $makeImpTables == 0;

  if ($specialCasesFile) {
    die "Special cases file $specialCasesFile doesn't exist"
      unless -e $specialCasesFile;
    $self->_parseSpecialCasesFile($specialCasesFile);
  }

  if (scalar(@$schemas)) {
    $self->{schemas} = {};
    foreach my $s (@$schemas) { $self->{schemas}->{$s} = 1 };
  }

  return $self;
}

sub generate {
    my ($self, $newOnly) = @_;

    my $cnt = scalar(@{$self->{tables}});
    print "Generating objects for $cnt $self->{javaOrPerl} tables and views\n";

    my %schema;

    foreach my $table (sort @{$self->{tables}}) {

	# parse schema::tablename format
	$table =~ /(GUS::Model::)?(\w+)::(\w+)/ || die "ERROR: table '$table' not in schema::tablename format\n";

	my ($schemaName, $tableName) = ($2, $3);

	if ($self->{javaOrPerl} eq "java" && !$self->{makeImpTables}){
	    next if ( $tableName =~ /Imp$/ || $schemaName eq "TESS");
	}
	next if (($self->{schemas} && !$self->{schemas}->{$schemaName})
		 || $tableName =~ /Ver$/);

	print "generating $self->{javaOrPerl} object for $schemaName" . "::" . $tableName . "\n";

	$self->{db}->checkTableExists($table) || die "ERROR: $table does not exist in db\n";

        if(!$schema{$schemaName} && !-d "$self->{targetDir}/$schemaName"){
          `mkdir -p $self->{targetDir}/$schemaName`;
          $schema{$schemaName} = 1;
        }
	my $tableG; my $rowG; my $wrapperG;

	if ($self->{javaOrPerl} eq "java"){

	    $rowG = GUS::ObjRelP::Generator::JavaRowGenerator->new($self, $schemaName, $tableName, $tableG);
	    $wrapperG = GUS::ObjRelP::Generator::JavaWrapperGenerator->new($self, $schemaName, $tableName, $tableG);
	    $tableG =  GUS::ObjRelP::Generator::JavaTableGenerator->new($self, $schemaName, $tableName);
	}
	elsif ($self->{javaOrPerl} eq "perl") {
	    $tableG = GUS::ObjRelP::Generator::PerlTableGenerator->new($self, $schemaName, $tableName);
	    $rowG = GUS::ObjRelP::Generator::PerlRowGenerator->new($self, $schemaName, $tableName, $tableG);
	    $wrapperG = GUS::ObjRelP::Generator::PerlWrapperGenerator->new($self, $schemaName, $tableName);
	}
	else {die "please set attribute --javaOrPerl to be either \'java\' or \'perl\' depending on which object layer you are generating";}

	my $type = 2;
	$tableG->generate($newOnly) if ($type == 1 || $type == 2);
	$rowG->generate($newOnly) if ($type == 1 || $type == 2);
	$wrapperG->generate($newOnly) if ($type == 0 || $type == 2);

    }
}


##############################################################################
######################## Public Utility methods ##############################
##############################################################################


sub getSpecialCases {
  my ($self) = @_;

  return $self->{spec_cases};
}

#creates associations between "imp" tables and views upon those tables
sub getSubclasses {
    my($self, $superName) = @_;

    $superName = $self->getFullTableClassName($superName);

    if (! $self->{subclasses}) {
	print "(Caching all subclasses)\n";

	my $dbh= $self->{'db'}->getDbHandle();

	my $coreName = $self->{db}->getCoreName();
	my $sql =
"select d.name, t2.name, t1.name\
 from $coreName.TableInfo t1,$coreName.TableInfo t2, $coreName.DatabaseInfo d\
 where t2.table_id = t1.view_on_table_id\
 and t1.database_id = d.database_id";

	my $sth = $dbh->prepareAndExecute($sql);
	while (my($schema,$superclass,$subclass) = $sth->fetchrow_array()) {
	    next if $subclass =~ /ver$/i;
	    my $superclassFull =
		$self->getFullTableClassName($schema.'::'.$superclass);
	    my $subclassFull = 
		$self->getFullTableClassName($schema.'::'.$subclass);
	    push(@{$self->{subclasses}->{$superclassFull}}, $subclassFull);
	}
    }
    my @answer = ();
    @answer =  @{$self->{subclasses}->{$superName}} 
      if $self->{subclasses}->{$superName};
    return @answer;
}

sub isValidAttribute {
  my($self, $tableName, $att) = @_;


  if (!exists $self->{'attList'}->{'$tableName'}) {
    $tableName = $self->getFullTableClassName($tableName);
    my $list = $self->getTable($tableName, 1)->getAttributeList();
    foreach my $a (@{$list}) {
      $self->{'attList'}->{$tableName}->{$a} = 1;
    }
  }
  return exists $self->{'attList'}->{$tableName}->{$att};
}


# if table is a view, return the viewed table, else, just table name
#returns in form of schema::tablename
sub getRealTableName {
  my($self, $className) = @_;

  $className = $self->getFullTableClassName($className);

  if(!exists $self->{realTableName}){
    print "(Caching all real table names)\n";
    my $coreName = $self->{db}->getCoreName();
    my $sql =
"select d.name, t2.name, t1.name\
 from $coreName.TableInfo t1,$coreName.TableInfo t2, $coreName.DatabaseInfo d\
 where t2.table_id = t1.view_on_table_id\
 and t2.database_id = d.database_id";
    my $stmt = $self->{db}->getDbHandle()->prepareAndExecute($sql);
    while (my($sc,$vn,$tn) = $stmt->fetchrow_array()) {
      my $vFull = $self->getFullTableClassName($sc.'::'.$vn);
      my $tFull = $self->getFullTableClassName($sc.'::'.$tn);
      $self->{realTableName}->{$tFull} = $vFull;
    }
  }

  return $self->{realTableName}->{$className} ?
   $self->{realTableName}->{$className} : $className ;
}

#param classname: form of schema::table
#creates associations between "tables" (really views) and their subclasses
sub getParentTable {
    my($self, $className) = @_;
    
    $className = $self->getFullTableClassName($className);
    #returns GUS::Model::schema::table

    if(!exists $self->{parentTable}){
	print "(Caching all parents)\n";
	my $coreName = $self->{db}->getCoreName();
	my $sql =
	    "select d.name, t2.name, t1.name
 from $coreName.TableInfo t1,$coreName.TableInfo t2, $coreName.DatabaseInfo d
 where t2.table_id = t1.superclass_table_id
 and t2.database_id = d.database_id";
	my $stmt = $self->{db}->getDbHandle()->prepareAndExecute($sql);
	while (my($sc,$pn,$tn) = $stmt->fetchrow_array()) {
	    my $pFull = $self->getFullTableClassName($sc.'::'.$pn);
	    my $tFull = $self->getFullTableClassName($sc.'::'.$tn);
	    $self->{parentTable}->{$tFull} = $pFull;
	}
    }
    return $self->{parentTable}->{$className};
}

sub getVersionable {
  my($self, $className) = @_;

  $className = $self->getFullTableClassName($className);

  if (! exists $self->{versionable}) {
    print "(Caching all versionables)\n";

    my $coreName = $self->{db}->getCoreName();
    my $sql =
"select d.name, t.name, is_versioned
 from $coreName.TableInfo t, $coreName.DatabaseInfo d
 where t.database_id = d.database_id";

    my $stmt = $self->{db}->getDbHandle()->prepareAndExecute($sql);
    while (my($sch,$tn,$v) = $stmt->fetchrow_array()) {
      my $tFull = $self->getFullTableClassName($sch.'::'.$tn);
      $self->{versionable}->{$tFull} = $v;
    }
  }
  return $self->{versionable}->{$className};
}

## gets all method names in ObjRelP super classes
sub getDontOverride {
  my ($self) = @_;

  if (!$self->{dontOverrideSubs}) {

    $self->{dontOverrideSubs} = {};

    foreach my $f ('GUS/Model/lib/perl/GusRow.pm', 'GUS/ObjRelP/lib/perl/DbiRow.pm') {
      my $file = "$self->{superclassesLibDir}/$f";

      open(F, $file) || print STDERR "Can't open superclass $file\n";
      while (<F>) {
	if (/^\s*sub\s+(\w+)/) {
	  $self->{dontOverrideSubs}->{$1} = 1;
	}
      }
    }
  }
  return $self->{dontOverrideSubs};
}

sub getTable {
  my ($self, $fullName, $dbiTable) = @_;

  return $self->{db}->getTable($fullName, $dbiTable);
}

sub getFullTableClassName {
  my ($self, $className) = @_;

  return $self->{db}->getFullTableClassName($className);
}


##############################################################################
######################## Private methods #####################################
##############################################################################

sub _parseSpecialCasesFile {
  my ($self, $specialCasesFile) = @_;

  $self->{spec_cases} = {};

  open( REL, $specialCasesFile)
    || die "Special cases file $specialCasesFile can't be opened\n";

  while ( <REL> ) {
    chomp( $_ );
    my @data = split( /\s+/, $_ );
    if ( $data[0] eq "rel" ) {
      shift @data;
      push(@{$self->{'spec_cases'}->{'rels'}},\@data);
    } elsif ( $data[0] eq "255" ) {
      shift @data;
      push(@{$self->{'spec_cases'}->{'255'}},\@data);
    }
  }
  close( REL );
}

sub _toString() {
  my ($self) = @_;

  print "db: $self->{db}\n";
  print "targetDir: $self->{targetDir}\n";
  print "superclassesLibDir: $self->{superclassesLibDir}\n";

  foreach my $rel ( @{$self->{spec_cases}->{rels}} ) {
    my @data = @{$rel};
    print join(" ", @data) . "\n";
  }

  foreach my $rel255 ( @{$self->{spec_cases}->{255}} ) {
    my @data = @{$rel255};
    print join(" ", @data) . "\n";
  }

  foreach my $table (@{$self->{tables}}) {
    print "$table\n";
  }
}

1;
