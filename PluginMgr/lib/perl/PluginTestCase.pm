package GUS::PluginMgr::PluginTestCase;
use base qw(Test::Unit::TestCase);

use strict;

use GUS::ObjRelP::DbiDatabase;

use GUS::Supported::GusConfig;

use GUS::PluginMgr::GusApplication;

=head1 NAME

 GUS::PluginMgr::PluginTestCase

=head1 SYNOPSIS

 package GUS::Supported::Plugin::TestSomePlugin;
 use base qw(GUS::PluginMgr::PluginTestCase);

 use strict;

 sub set_up {
   my ($self) = @_;

   # Plugin Specific Args
   my $pluginArgs = { file => 'testFile.in',
                      externalDatabase => 'NCBI RefSeq',
                      externalDatabaseVersion => 'UNKNOWN',
                    };

   $self->SUPER::set_up('GUS::Supported::Plugin::TestSomePlugin', $args);
 }

 test_someMethod {
   my $self = shift;

   my $plugin = $self->getPlugin();
   my $someValue = $plugin->someMethod();

   # Test Equality
   $self->assert_equals('expected', $someValue);

   # OR Test with Regex
   $self->assert_matches(qr(expected), $someValue);

   # OR Test with a boolean
   $self->assert('expected' eq $someValue);

 }

 sub test_insertContact {
   my $self = shift;

   my $plugin = $self->getPlugin();
 
   # Call a method from your plugin which contains a submit
   $plugin->insertContact();

   # use row_alg_invocation_id to test submits with a regular expression.
   # Default is row alg_invocation_id is -99 ... All Transactions are rolled back
   my $sqlList = [ ['\d+', 'select contact_id from SRes.CONTACT where row_alg_invocation_id = -99,  'contact_id'],
                   ['^Brestelli$', 'Select last from SRes.Contact where contact_id = $$contact_id$$'] ];

   $self->sqlStatmentsTest($sqlList);

 }

 -----------------------

=head1 DESCRIPTION

Subclass of Test::Unit::TestCase.  This class is meant to be the base class for 
any PluginTest.  Your PluginTest Class should Extend this by providing a set_up
method as illustrated above and by providing ALL applicable tests cases for your Plugin.

PluginTestCase also provides a utility method to query and test values returned from
sql statemnts.  The argument ls a listing of expected values (regex), an
sql statment, and an optional parameter which may be used in subsequent sql statments.

 Any rows you submit will be rolled back.
 Only submit a few rows.  
 Be Specific with your regex's (Surround your literals with ^ and $)
 use single quotes when defining your sql
 The default row_alg_invocation_id given to these rows will be -99.

 You can modify this in you PluginTest by 
 $self->{_dbi_database}->setDefaultAlgoInvoId(-99);

=cut

my $ga = GUS::PluginMgr::GusApplication->new();

my $testCount;

#--------------------------------------------------------------------------------

sub new {
  my $self = shift()->SUPER::new(@_);

  $testCount = scalar $self->list_tests();

  return $self;
}

#--------------------------------------------------------------------------------

sub set_up {
  my ($self, $pluginName, $pluginArgsHashRef) = @_;

  # Make the config file
  my $configFile = "$ENV{GUS_HOME}/config/gus.config";
  $ga->{config} = GUS::Supported::GusConfig->new($configFile);

  # Create the plugin and database
  my $plugin = $ga->newFromPluginName($pluginName);

  unless(GUS::ObjRelP::DbiDatabase->getDefaultDatabase()) {
    $ga->connect_to_database($plugin);
  }

  $self->{_dbi_database} = $self->setupDatabase(GUS::ObjRelP::DbiDatabase->getDefaultDatabase());

  # Setup the Plugin Args
  my $argDecl = [@{$plugin->getArgsDeclaration()},
                 @{$ga->getStandardArgsDeclaration()},
                ];

  foreach my $arg (@$argDecl) {
    my $name = $arg->getName();

    unless(exists $pluginArgsHashRef->{$name}) {
      $pluginArgsHashRef->{$name} = $arg->getValue();
    }
  }

  $plugin->initArgs($pluginArgsHashRef);

  $self->{_plugin} = $plugin;

  return $plugin;
}

#--------------------------------------------------------------------------------

sub getPlugin { $_[0]->{_plugin}}
sub getDbiDatabase { $_[0]->{_dbi_database}}

sub tear_down {
  my ($self) = @_;

  $testCount--;

  # LOG OUT AFTER ALL TESTS ARE FINISHED
  if($testCount <= 0) {
    GUS::ObjRelP::DbiDatabase->getDefaultDatabase()->logout();
    GUS::ObjRelP::DbiDatabase->setDefaultDatabase(undef);

    print STDERR "\nLOGGING OUT FROM DBI DATABASE\n";
  }
}

#--------------------------------------------------------------------------------

sub setupDatabase {
  my ($self, $database) = @_;

  my $val = 0;

  $database->setDefaultProjectId($val);
  $database->setDefaultUserId($val);
  $database->setDefaultGroupId($val);
  $database->setDefaultGroupRead($val);
  $database->setDefaultGroupWrite($val);
  $database->setDefaultOtherRead($val);
  $database->setDefaultOtherWrite($val);

  $database->setDefaultAlgoInvoId(-99);

  $database->setDefaultUserRead(1);
  $database->setDefaultUserWrite(1);

  $database->setCommitState(0);

  return $database;
}

#--------------------------------------------------------------------------------

sub sqlStatmentsTest {
  my ($self, $sqlList) = @_;

  my $testHash = $self->_parseLines($sqlList);

  foreach my $test (keys %$testHash){
    my $expected = $testHash->{$test}->{expected};
    my $actual = $testHash->{$test}->{actual};

    $self->assert_matches(qr($expected), $actual, "Expected '$expected' did not match '$actual' for statment\n$test");
  }
}

#--------------------------------------------------------------------------------

sub _parseLines {
  my ($self, $sqlList) = @_;

  my @lines = @$sqlList;

  my (%params, %sqlAsserts);

  foreach my $line (@lines) {
    next unless $line;
    my ($expected, $actual, $statement) = $self->_parseLine($line, \%params);

    unless($expected eq 'NA') {
      $sqlAsserts{$statement} = {expected => $expected,
                                 actual => $actual,
                                };
    }
  }

  return \%sqlAsserts;
}

#--------------------------------------------------------------------------------

sub _parseLine {
  my ($self, $line, $params) = @_;

  my ($regex, $sql, $param) = @$line;

  if($sql =~ s/(\$\$(\w+)\$\$)/$params->{$2}/) {
    die "No Param for $2 was defined" unless(exists $params->{$2});
  }

  my $result = $self->_runSql($sql);

  if($param) {
    $params->{$param} = $result; 
  }

  return ($regex, $result, $sql);
}

#--------------------------------------------------------------------------------

sub _runSql {
  my ($self, $sql) = @_;

  my @rv;

  my $dbh = $self->{_dbi_database}->getDbHandle();

  my $sh = $dbh->prepare($sql);

  $sh->execute();

  while(my @ar = $sh->fetchrow_array()) {
    push(@rv, @ar);
  }
  $sh->finish();

  if(scalar(@rv) == 0) {
    die "No Result for sql: $sql";
  }

  if(scalar(@rv) > 1) {
    return join(',', @rv);
  }

  return $rv[0];

}


#--------------------------------------------------------------------------------

1;
