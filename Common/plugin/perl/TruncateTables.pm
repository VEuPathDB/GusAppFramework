# ##############################################################################
# TruncateTables
#
# Truncating a table is _much_ faster than deleting all the rows. HOWEVER -
# there will be no rollback, no way to undo a truncate.
# *** You have been warned ***
#
# There are 2 hashes in the code below. One is for tables you do NOT want to
# truncate, the other for tables you do. Before a truncte can take place the
# contraints to child tables must be DISABLED, then ENABLED afterwards.
#
#
# NOTE: These are tables, not views.
#       You can not truncate a view.
#       Doing so would would destroy all other views onto the IMP table
#
#
# Safe gauards;
# . The 2 hashes are compared. No table is allowed to appear in both.
# . The data base is scanned to find all populated tables. Any table found that
#   is not mentioned in the hashes is reported and this program stops.
#
# ##############################################################################
#
# Author: Paul Mooney (pjm@sanger.ac.uk)
#


package GUS::Common::Plugin::TruncateTables;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
#use DBI;
use Data::Dumper;



# OUTPUT_AUTOFLUSH forced
$| = 1;
my $debug = 1;

# DSN, users amd paswords are parsed from  .gus.properties
my $db_user     = "GUSro";

my %isSystemTable = 
    ("CORE.ALGORITHM"                 => 1,
     "CORE.ALGORITHMIMPLEMENTATION"   => 1, 
     "CORE.ALGORITHMINVOCATION"       => 1,
     "CORE.ALGORITHMPARAM"            => 1,
     "CORE.ALGORITHMPARAMKEY"         => 1,
     "CORE.ALGORITHMPARAMKEYTYPE"     => 1,
     "CORE.DATABASEINFO"              => 1,
     "CORE.PROJECTINFO"               => 1,
     "CORE.GROUPINFO"                 => 1,
     "CORE.MACHINE"                   => 1,
     "CORE.TABLEINFO"                 => 1,
     "CORE.USERINFO"                  => 1,

     "DOTS.GENEINSTANCECATEGORY"      => 1,
     "DOTS.PROTEININSTANCECATEGORY"   => 1,
     "DOTS.RNAINSTANCECATEGORY"       => 1, 
     "DOTS.SEQUENCETYPE"              => 1,
     "DOTS.DBREFPFAMENTRY"            => 1,
     "DOTS.PFAMENTRY"                 => 1,
     "DOTS.PROTEINPROPERTYTYPE"       => 1,

     "DOTSVER.PROTEINPROPERTYTYPEVER" => 1,


     "SRES.CONTACT"                   => 1,
     "SRES.REVIEWSTATUS"              => 1,
     "SRES.GENETICCODE"               => 1,
     "SRES.TAXON"                     => 221097,
     "SRES.TAXONNAME"                 => 282112,

     "SRES.GOEVIDENCECODE"            => 1,
     "SRES.GORELATIONSHIP"            => 1,
     "SRES.GOSYNONYM"                 => 1,
     "SRES.GOTERM"                    => 1,
     "SRES.GORELATIONSHIPTYPE"        => 1,


                                            # DOTS.DBREFPFAMENTRY references this table - 66489 rows at last count...
                                            # This table could be referenced a _lot_ from other tables.
                                            # Not needed yet BUT could create list of child tables and their column name for
                                            # db_ef_id
    #"SRES.DBREF"                     => {'SRes.Reference' => 'db_ref_id', },
     "SRES.DBREF"                     => 1,

     "SRES.EXTERNALDATABASE"          => 1,
     "SRES.EXTERNALDATABASERELEASE"   => 1,

     "DOTSVER.AAFEATUREIMPVER"        => 1, # No onjects for version tables, can not truncates easily????
     "DOTSVER.AALOCATIONVER"          => 1,
     "DOTSVER.AASEQUENCEIMPVER"       => 1,
     "DOTSVER.GENESYNONYMVER"         => 1,
     "DOTSVER.NAFEATUREIMPVER"        => 1,
     "DOTSVER.NALOCATIONVER"          => 1,
     "DOTSVER.NASEQUENCEIMPVER"       => 1,
     "DOTSVER.PROTEINVER"             => 1,
     "DOTSVER.PROTEINPROPERTYVER"     => 1,
     );

#
# Order is inmportant, done by the value.
# When a constraint is reenabled, the parent value must exit in the parent, hence
# we truncte the children first.
#
my %optInTables =
    ("DOTS.AALOCATION"                => 1,
     "DOTS.AAFEATUREIMP"              => 2,
     "DOTS.PROTEINPROPERTY"           => 3,
     "DOTS.AASEQUENCEIMP"             => 4,
     "DOTS.EVIDENCE"                  => 5,
     "DOTS.GENESYNONYM"               => 6,
     "DOTS.GENEINSTANCE"              => 7,
     "DOTS.GOASSOCIATIONINSTANCELOE"  => 9,
     "DOTS.GOASSOCINSTEVIDCODE"       => 1,
     "DOTS.GOASSOCIATIONINSTANCE"     => 8,
     "DOTS.GOASSOCIATION"             => 10,
     "DOTS.NALOCATION"                => 11,
     "DOTS.RNAFEATUREEXON"            => 12,
     "DOTS.RNAINSTANCE"               => 13,
     "DOTS.DBREFNAFEATURE"            => 14,
     "DOTS.NAFEATUREIMP"              => 15,
     "DOTS.PROTEIN"                   => 16,
     "DOTS.RNA"                       => 17,
     "DOTS.GENE"                      => 18,
     "DOTS.NASEQUENCEIMP"             => 19,
     "DOTS.ATTRIBUTION"               => 20,
     "SRES.EXTERNALDATABASEENTRY"     => 21,
     );





sub new {
  my $class = shift;
  my $self  = {};
  bless($self,$class);

  my $usage = "ga GUS::Common::Plugin::TruncateTables followed by --commit. Once you destroy your data, there is  ging back! Without --commit you'll see which tables will be TRUNCATEd and which contraints will be DISABLED.";



  my $purposeBrief = "Destroy all data *quickly*..";

  my $purpose = <<PLUGIN_PURPOSE;
The PSU have a data refresh every week. This may mean re-loading all the EMBL
files. This plugin TRUNCATES all the non dictionary tables which is much faster
than multiple DELETEs.

The downside is you can never get that data back!

The tables to be truncated (and the ones NOT to be truncated) are specified
in the plugin itself. If other centers use this plugin I can change it so an
external configuration file is read so different tables can be truncated.

The GUS schemas (Core, DoTS etc) are scanned to see if any tables
contain data that have not been specified - the plugin will stop 
and report which tables contain data, thus giving a small safe guard.
Also, no tables are truncated if a table appears in both lists.
PLUGIN_PURPOSE

  my $tablesAffected =
    [
     ["DOTS.AALOCATION"                , 'TRUNCATE!!!'],
     ["DOTS.AAFEATUREIMP"              , 'TRUNCATE!!!'],
     ["DOTS.AASEQUENCEIMP"             , 'TRUNCATE!!!'],
     ["DOTS.EVIDENCE"                  , 'TRUNCATE!!!'],
     ["DOTS.GENESYNONYM"               , 'TRUNCATE!!!'],
     ["DOTS.GENEINSTANCE"              , 'TRUNCATE!!!'],
     ["DOTS.GOASSOCIATIONINSTANCELOE"  , 'TRUNCATE!!!'],
     ["DOTS.GOASSOCIATIONINSTANCE"     , 'TRUNCATE!!!'],
     ["DOTS.GOASSOCIATION"             , 'TRUNCATE!!!'],
     ["DOTS.NALOCATION"                , 'TRUNCATE!!!'],
     ["DOTS.RNAFEATUREEXON"            , 'TRUNCATE!!!'],
     ["DOTS.RNAINSTANCE"               , 'TRUNCATE!!!'],
     ["DOTS.NAFEATUREIMP"              , 'TRUNCATE!!!'],
     ["DOTS.PROTEIN"                   , 'TRUNCATE!!!'],
     ["DOTS.RNA"                       , 'TRUNCATE!!!'],
     ["DOTS.GENE"                      , 'TRUNCATE!!!'],
     ["DOTS.NASEQUENCEIMP"             , 'TRUNCATE!!!'],
     ["SRES.EXTERNALDATABASEENTRY"     , 'TRUNCATE!!!'],
    ];

  my $tablesDependedOn =
    [ ['Core::DatabaseInfo', 'Look up table IDs by database/table names'],
      ['Core::TableInfo', 'Look up table IDs by database/table names'],
    ];

  my $howToRestart = <<PLUGIN_RESTART;
This plugin has no restart facility. If it fails, it may have truncated some
of the tables but not all!
PLUGIN_RESTART

  my $failureCases = <<PLUGIN_FAILURE_CASES;
If the order of the opt-in-tables is not correct, you may delete a parent
before a child table. Re-enabling the contraints will fail because of this.
Simply changing the order and re-running the plugin will fix the problem.
PLUGIN_FAILURE_CASES

  my $notes = <<PLUGIN_NOTES;
Only use this plugin if you are sure you know what you\'re doing!
It could be very useful for testing any data loading code you have.
PLUGIN_NOTES

  my $documentation = { purpose          => $purpose,
                        purposeBrief     => $purposeBrief,
                        tablesAffected   => $tablesAffected,
                        tablesDependedOn => $tablesDependedOn,
                        howToRestart     => $howToRestart,
                        failureCases     => $failureCases,
                        notes            => $notes
                      };

  my $easycsp =
   [#{
    #    o => 'reallyTruncate',
    #    t => 'string',
    #    r => 1,
    #    h => '',
    #},

   ];

  my $argsDeclaration = [];

  $self->initialize({requiredDbVersion => {},
                     cvsRevision    => '$Revision$', # 'cvs fills this in!,
                     name           => ref($self),
                     revisionNotes  => 'make consistent with GUS 3.0',
                     #easyCspOptions => $easycsp,
                     #usage          => $usage,
                     argsDeclaration => $argsDeclaration,
                     documentation   => $documentation                   
                     });

  $self->{'db_user'} = $db_user;

  return $self;
}


################################################################################
# run
#
sub run {
    my $self       = shift;
    my $gene_name  = $self->getArgs->{'genename'};
    my $table_name = 'DoTS::Gene';

    if (defined($self->getArgs->{'commit'})) {
        $self->{'doit'} = 1;
    }
    else {
        $self->{'doit'} = 0;
    }


    $self->check_no_overlaps(\%isSystemTable, \%optInTables);

    my ($dsn, %users_password) = $self->parse_schema_prop();

    $self->set_dsn($dsn);
    $self->set_user_passwords(\%users_password);



    eval {
        print "connect as ", $self->{'db_user'}, " using password '",
            $self->get_user_password($self->{'db_user'}), "'\n";

        $self->{'dbh'} = DBI->connect($dsn, $self->{'db_user'}, $self->get_user_password($self->{'db_user'}),
                                      { RaiseError => 1, AutoCommit => 0 });

        my $to_truncate =
            $self->check_no_other_populated_rows($dsn, $db_user,,
                                                 \%isSystemTable, \%optInTables);

        print "\nTables to be truncated;\n\n";            # DEBUG
        foreach my $full_table_name (@{$to_truncate}) {
            print "$full_table_name\n";
        }                                                 # END DEBUG


        $self->truncate_tables($dsn, \%optInTables, @{$to_truncate});

        ##
        # Report on any non SYSTEM constraints that are not disbled.
        ##
        $self->report_disabled_contraints();

        $self->{'dbh'}->disconnect();

        $self->disconnect_user_db_handles();
    };

    if( $@ ){
        my $error = $@;
        eval {$self->{'dbh'}->disconnect();}; # try at least to close connection
        die $error;
    }



    return 1; # This value gets inserted into CORE.ALGORITHMINVOCATION.RESULT
}



################################################################################
#
# Compare the 2 hashes to make sure the keys a unique.
#
# exit 1 is the result of finding 1 or more "overlaps"
##

sub check_no_overlaps {
    my ($self, $isSystemTable, $optInTables) = @_;
    my $quit = 0;

    foreach my $key (%{$isSystemTable}) {
        if (defined $optInTables->{$key}) {
            print "ERROR: Table $key in both system and opt-in hashes!\n";
            $quit = 1;
        }
    }

    exit 1 if $quit;
}

################################################################################
# parse_schema_prop
#
# Parse $GUS_HOME/config/schema.prop to create DSN and return it al;ong with
# hash of every users name and password
#
# Due to Oracle being case in-sensitive, I upper case all user names so things
# are consistant (the schema.prop file recommends you do not change the default
# users names which are a mixture of upper and lower case).
##

sub parse_schema_prop {
    my ($self) = @_;

    unless (defined $ENV{'GUS_HOME'}) {
        die "ERROR: Your GUS_HOME environment variable is not set.";
    }

    my %key_value;
    my %user_password;

    open SCHEMA_PROP, "<".$ENV{'GUS_HOME'}."/config/schema.prop";

    while (<SCHEMA_PROP>) {
        next if /^\s*#/;
        next if /^\s*$/;

        my ($key, $value) = ($_ =~ /^(.+)=(.+)$/);

        #print "key, value = $key, $value\n";
        $key_value{$key} = $value;
    }

    close SCHEMA_PROP;

    ##
    # DSN

    my $dsn = 'dbi:Oracle:host='.$key_value{'oracle_host'}.';sid='.$key_value{'oracle_SID'}.';port='.$key_value{'oracle_port'};

    #print "DSN = $dsn\n";

    ##
    # Work out user passwords - only clue to a users name is what comes before Password and
    # after oracle_ i.e. oracle_corePassword=xxx, then look up real user name in oracle_core=

    foreach my $key (%key_value) {
        #print "$key =~ /^(.+?)_(.+?)Password$/ \n";

        if ($key =~ /^(.+?)_(.+?)Password$/) {
            my $db              = $1;
            my $gus_schema_name = $2;
            #print "Looking up ${db}_$gus_schema_name\n";

            my $user_name       = $key_value{"${db}_${gus_schema_name}"};
            my $password        = $key_value{"${db}_${gus_schema_name}Password"};

            #print "User, password = $user_name, $password\n";
            #print "User, password = ", uc($user_name), ", $password\n\n";
            
            $user_password{uc($user_name)} = $password;
        }
    }

    return ($dsn, %user_password);
}

################################################################################
#
# Compare the 2 hashes to make sure the keys a unique.
#
# exit 1 is the result of finding 1 or more "overlaps"
##

sub check_no_other_populated_rows {
    my ($self, $dsn, $user, $isSystemTable, $optInTables) = @_;

    my ($dbh, @truncate, %notOptInTables);

    eval {
        #$dbh = DBI->connect($dsn, $user, $self->get_user_password($user),
        #                    { RaiseError => 1, AutoCommit => 0 });

        my $sth_all = $self->{'dbh'}->prepare("SELECT owner, table_name FROM all_tables WHERE  owner in ('APP', 'APPVER', 'CORE', 'COREVER', 'DOTS', 'DOTSVER', 'RAD3', 'RAD3VER', 'SRES', 'SRESVER', 'TESS', 'TESSVER') ORDER BY owner, table_name");
        $sth_all->execute();

        while ( my @row = $sth_all->fetchrow_array ) {
            my ($user, $table_name) = @row;
            my $full_table_name     = "${user}.${table_name}";

            #if ($debug) { print "  $full_table_name\n"; }

            next if defined $isSystemTable->{$full_table_name};

            #if ($debug) { print "  $full_table_name is NOT a system table\n"; }

            my @count_row = $self->{'dbh'}->selectrow_array("SELECT count(*) FROM $full_table_name");
            my $num_rows  = $count_row[0];

            #if ($debug) { print "    $num_rows\n";}

            if ($num_rows != 0) {
                print sprintf("     %-32s has %d rows\n", '"'.$full_table_name.'"', $num_rows);

                if ($optInTables->{$full_table_name}) {
                    push @truncate, $full_table_name;
                }
                else {
                    $notOptInTables{$full_table_name}++;
                }
            }
        }

        if (keys %notOptInTables) {
            print "\n#############################################################################\n";
            print "ERROR: one or more tables found to contain records not specified to be truncated or ignored!\n";

            foreach my $key (keys %notOptInTables) {
                print "  $key\n";
            }

            die "ERROR: tables populated but not specified to be ignoed or truncated! Please fix and try again!";
        }
        else {
            #&truncate_tables($dbh, $dsn, \%users_password, \%optInTables, @truncate);
        }
    };

    if( $@ ){
        my $error = $@;
        #print $error;
        die $error;
    }

    return \@truncate;
}


################################################################################
# truncate_tables
#
# Given an array of tables to truncate (@tables), find the foriegn key
# constraints (R = relational) and create statements DISABLE and ENABLE
# them before and after the TRUNCATE statement.
##

sub truncate_tables {
    my ($self, $dsn, $ref_optInTables, @tables) = @_;

    my $dbh  = $self->{'dbh'};
    my $sql  =
        "SELECT CONSTRAINT_NAME ".
        "FROM   all_constraints ".
        "WHERE  owner      = ? ".
        "AND    table_name = ? ".
        "AND    CONSTRAINT_TYPE = 'R'";
    my $sth1 = $dbh->prepare($sql);

    ##
    # Need to order the tables, child first
    my @ordered =
        sort {$ref_optInTables->{$a} <=> $ref_optInTables->{$b}} keys %{$ref_optInTables};

    #foreach my $full_table_name (@tables) {
    foreach my $full_table_name (@ordered) {
    
        print "\n/* $full_table_name */\n";

        my ($owner, $table) = ($full_table_name =~ /^(.+?)\.(.+?)$/);


        ##
        # Disable child table contraints

        my @disabled_contraints = $self->disable_child_table_contraints($dbh, $sth1, $owner, $table);


        ##
        # DISABLE contraints fro this table

        $sth1->execute($owner, $table);

        my $user_dbh = $self->get_user_db_handle_for($owner);
        my @constraints;

        while (my @row = $sth1->fetchrow_array()) {
            my $constraint_name = $row[0];
            push @constraints, $constraint_name;
            my $cmd = qq{ALTER TABLE $full_table_name DISABLE CONSTRAINT $constraint_name};

            print "$cmd\n";

            if ($self->{'doit'}) {
                $user_dbh->do($cmd);
            }
        }

        ##
        ## TRUNCATE the table

        my $trunc_cmd = qq{TRUNCATE TABLE $full_table_name};
        print "$trunc_cmd\n";

        if ($self->{'doit'}) {
            $user_dbh->do($trunc_cmd);
        }

        ##
        # Re-ENABLE contraints

        foreach my $constraint_name (@constraints) {
            my $cmd = qq{ALTER TABLE $full_table_name ENABLE CONSTRAINT $constraint_name};
            print "$cmd\n";

            if ($self->{'doit'}) {
                $user_dbh->do($cmd);
            }
        }

        ##
        # re-ENABLE *child* table constraints

        $self->enable_child_table_contraints($dbh, $owner, $table, @disabled_contraints);

    }
}

################################################################################
#
##

sub disable_child_table_contraints {
    my ($self, $dbh, $sth, $owner, $table) = @_;

    ##
    # Create instance of object so it can tell us its children
    # Need to require that tables' module
    ##

    my $gus_schema         = $self->gus_schema_name_for($owner);
    my $gus_object         = $self->gus_table_name_for($owner, $table);

    my $require_table_name = $gus_object;
    $require_table_name    =~ s!::!/!g;
    $require_table_name   .= '.pm';

    #print "\ndisable_child_table_contraints(): require $require_table_name\n\n";

    eval { require $require_table_name; };

    if ($@) {
        die "ERROR: Could not load table '$gus_object';\n$@";
    }

    my $obj            = undef;
    my $code           = "\$obj = ${gus_object}->new({}) ";
    #print "disable_child_table_contraints(): code = $code\n";

    eval $code;

    if ($@) {
        die $@;
    }

    #print "disable_child_table_contraints(): \$obj = $obj\n";

    #my @children = $obj->getChildren();
    my @children = $obj->getChildList();
    #my @children = $obj->getChildListWithAtts(); # returns the hash ref of child objects

    my @disabled_contraints;();

    foreach my $child (@children) {
        print "disable_child_table_contraints(): CHILD = '$child'\n";

        my ($child_owner, $child_table) = ($child =~ /^.+?::.+?::(.+?)::(.+?)$/);
        my @constraints;

        #my $sth = $dbh->prepare($sql);
        $sth->execute(uc($child_owner), uc($child_table));

        #print "disable_child_table_contraints(): Executed: owner = ", uc($child_owner), ", table = ", uc($child_table), "\n";

        while (my @row = $sth->fetchrow_array()) {
            my $constraint_name = $row[0];
            push @constraints, $constraint_name;

            my $cmd = "ALTER TABLE ${child_owner}.${child_table} DISABLE CONSTRAINT $constraint_name";

            push @disabled_contraints, $cmd;
            print "   $cmd\n";

            my $user_dbh = $self->get_user_db_handle_for($child_owner);

            if ($self->{'doit'}) {
                $user_dbh->do($cmd);
            }
        }
    }

    print "\n";

    return @disabled_contraints;
}

################################################################################
#
##

sub enable_child_table_contraints {
    my ($self, $dbh, $owner, $table, @disabled_contraints) = @_;

    foreach my $constraint (@disabled_contraints) {
        $constraint =~ s/DISABLE/ENABLE/;

        my ($owner, $table) = ($constraint =~ /^ALTER TABLE (.+?)\.(.+?) /);

        #print "enable_child_table_contraints(): owner = $owner, table = $table, cmd = $constraint\n";
        print "   $constraint\n";

        if ($self->{'doit'}) {
            my $user_dbh = $self->get_user_db_handle_for($owner);
            $user_dbh->do($constraint);
        }
    }

    print "\n";
}

################################################################################
#
##

sub gus_schema_name_for {
    my ($self, $owner) = @_;

    for ($owner) {
        /^DOTS$/    and do {return 'DoTS'};
        /^DOTSVER$/ and do {return 'DoTSVer'};
        /^APP$/     and do {return 'App'};
        /^CORE$/    and do {return 'Core'};
        /^SRES$/    and do {return 'SRes'};
        /^RAD3$/    and do {return 'RAD3'};
        /^TESS$/    and do {return 'TESS'};        
        die "ERROR: Unknown schema '$owner'";
    }
}


################################################################################
# For a given upper cased table name, say DOTS.PROTEIN, return the nice case
# sensitive GUS object name, GUS::Model::DoTS::Protein
# Oracle returns everything as uppercase...
##

sub gus_table_name_for {
    my ($self, $owner, $table) = @_;

    unless (defined($self->{'table_name_store'})) {
        # Store DOTS::PROTEIN, not GUS::MODEL::DOTS::PROTEIN
        # as key
        my $dbi        = $self->getDb();
        my $tables_ref = $dbi->getTableNames();
        my %table_name_hash;

        foreach my $table_name (@{$tables_ref}) {
 
            my ($key) = ($table_name =~ /^.+?::.+?::(.+?::.+?)$/);
            $key      = uc($key);

            $table_name_hash{$key} = $table_name;

            #print uc($key), " = $table_name\n";
        }

        $self->{'table_name_store'} = \%table_name_hash;
    }

    my $gusify_table_name = "${owner}::${table}";

    if (defined($self->{'table_name_store'}->{$gusify_table_name})) {
        #print "For $gusify_table_name I'm returning ", $self->{'table_name_store'}->{$gusify_table_name}, "\n";

        return $self->{'table_name_store'}->{$gusify_table_name};
    }
    else {
        die "ERROR: Could not find '$gusify_table_name'";
    }
}


################################################################################
# No transactions happen in this code, so its ok to give out the same handle
# each time
##

sub get_user_db_handle_for {
    my ($self, $owner) = @_;
    my $user_dbh;

    $owner = uc($owner);

    if (defined $self->{'db_handles'}->{$owner}) {
        $user_dbh = $self->{'db_handles'}->{$owner};
    }
    else {
        $user_dbh = DBI->connect($self->get_dsn(), $owner, $self->get_user_password($owner),
                                 { RaiseError => 1, AutoCommit => 0 });
        $self->{'db_handles'}->{$owner} = $user_dbh;
    }

    #print "get_user_db_handle_for(): for $owner, returning $user_dbh\n";

    return $user_dbh;
}

################################################################################
# 
##

sub disconnect_user_db_handles {
    my ($self) = @_;

    if (defined $self->{'db_handles'}) {
        print "\nDisconnecting user DB handles\n";

        foreach my $owner (keys %{$self->{'db_handles'}}) {
            print "  Disconnect $owner\n";

            eval {$self->{'db_handles'}->{$owner}->disconnect();};

            if ($@) {
                print "ERROR: Tried to close DB handle for $owner: $@";
            }
        }
    }
}

################################################################################
#
##

sub set_dsn {
    my ($self, $dsn) = @_;
    $self->{'dsn'} = $dsn;
}

################################################################################
#
##

sub get_dsn {
    my ($self) = @_;

    return $self->{'dsn'} if defined $self->{'dsn'};

    print STDERR "WARNING: get_dsn(): Asking for DSN when it has not yet been set!\n";
    return undef;
}

################################################################################
#
##

sub set_user_passwords {
    my ($self, $ref_users_password) = @_;
    $self->{'user_passwords'} = $ref_users_password;
}

################################################################################
#
##

sub get_user_password {
    my ($self, $user) = @_;

    $user = uc($user);

    return $self->{'user_passwords'}->{$user} if defined $self->{'user_passwords'}->{$user};

    print Data::Dumper::Dumper($self->{'user_passwords'});

    print STDERR "WARNING: get_user_password(): Requesting password for '$user' when it has not yet been set!\n";
    return undef;
}

################################################################################
#
##

sub report_disabled_contraints {
    my ($self) = @_;

    my $sth = $self->{'dbh'}->prepare("SELECT CONSTRAINT_NAME, STATUS, CONSTRAINT_TYPE ".
                                      "FROM   all_constraints ".
                                      "WHERE  STATUS = 'DISABLED' ".
                                      "AND    OWNER != 'SYSTEM'");
    $sth->execute();
    my @display;

    while (my @row = $sth->fetchrow_array()) {
        my ($constraint_name, $status, $type) = @row;

        push @display, "  $constraint_name\n"; 
    }

    if (@display) {
        print "********************************************************************************\n".
            "WARNING: Some contraints in the DB are DISABLED!!! See below;\n".
            "********************************************************************************\n\n";
        print @display;
    }
}

1;
