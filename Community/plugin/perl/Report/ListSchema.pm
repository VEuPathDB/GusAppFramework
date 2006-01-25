
package GUS::Community::Plugin::Report::ListSchema;
@ISA = qw(GUS::PluginMgr::Plugin);

# ----------------------------------------------------------------------

use strict;

use FileHandle;
use CBIL::Util::V;

use GUS::PluginMgr::Plugin;

use GUS::PluginMgr::PluginUtilities::ConstraintFunction;
use GUS::PluginMgr::PluginUtilities;

use GUS::Model::SRes::ExternalDatabase;

# ======================================================================

sub new {
   my $Class = shift;

   my $self = bless {}, $Class;

   my $selfPodCommand = 'pod2text '. __FILE__;
   my $selfPod        = `$selfPodCommand`;

   $self->initialize
   ({ requiredDbVersion => '3.5',
      cvsRevision       => ' $Revision: 2892 $ ',
      name              => ref($self),

      # just expand
      revisionNotes     => '',
      revisionNotes     => 'initial creation and testing',

      # ARGUMENTS
      argsDeclaration   =>
      [ booleanArg({ name   => 'FromOracle',
                     descr  => 'read Oracle tables for info',
                     reqd   => 0,
                     isList => 0,
                     constraintFunc => sub { CfIsAnything(@_) },
                   }),

        booleanArg({ name   => 'FromGus',
                     descr  => 'read Oracle tables for info',
                     reqd   => 0,
                     isList => 0,
                     constraintFunc => sub { CfIsAnything(@_) },
                   }),
      ],

      # DOCUMENTATION
      documentation     =>
      { purpose          => <<Purpose,

  This plugin lists Core.Database, Core.TableInfo, Core.DatabaseInfo.

Purpose
        purposeBrief     => 'List SRes.ExternalDatabase',
        tablesAffected   =>
        [ ],
        tablesDependedOn =>
        [ [ 'Core.DatabaseInfo',          'reads databases from this table'  ],
          [ 'Core.TableInfo',             'reads tables from this table'  ],
          [ 'Core.DatabaseDocumentation', 'reads documentation for tables and rows' ]
        ],
        howToRestart     => 'just restart; this is a reader',
        failureCases     => 'just run again',
        notes            => $selfPod,
      },
    });

   # RETURN
   $self
}

# ======================================================================

sub run {
   my $Self       = shift;

   $Self->logArgs();

   $Self->oracleDump() if $Self->getArg('FromOracle');
   $Self->gusDump()    if $Self->getArg('FromGus');

   return "That's all folks!";
}

# ------------------------------ oracleDump ------------------------------

sub oracleDump {
   my $Self = shift;

   my @_tables = sort {
      $a->{owner} cmp $b->{owner} ||
      $a->{table_name} cmp $b->{table_name}
   } $Self->sqlAsHashRefs( Sql => <<Sql );
SELECT owner, table_name
FROM   all_tables
WHERE  owner in ('CORE', 'DOTS', 'PROT', 'RAD', 'SRES', 'STUDY', 'TESS')
Sql

   my $cols_sh = $Self->getQueryHandle()->prepare(<<Sql);
SELECT column_name, data_type, data_precision, data_scale, column_id
FROM   all_tab_columns
WHERE  owner      = ?
AND    table_name = ?
Sql

   my $ndx_sh = $Self->getQueryHandle()->prepare(<<Sql);
SELECT index_name
FROM   ALL_IND_COLUMNS
WHERE  table_owner = ?
AND    table_name  = ?
AND    column_name = ?
Sql

   my $inRef_sh = $Self->getQueryHandle()->prepare(<<Sql);
SELECT constraint_name, r_owner, r_constraint_name
FROM   ALL_CONSTRAINTS
WHERE  owner      = ?
AND    table_name = ?
AND    constraint_type = 'R'
Sql

  foreach my $_table (@_tables) {

     print join("\t", $_table->{owner}, $_table->{table_name}), "\n";

     my @_columns = sort {
        $a->{column_id} <=> $b->{column_id}
     } $Self->sqlAsHashRefs( Handle => $cols_sh,
                             Bind   => [ $_table->{owner}, $_table->{table_name} ]
                          );

     my @_inRefs = $Self->sqlAsHashRefs( Handle => $inRef_sh,
                                         Bind   => [ $_table->{owner}, $_table->{table_name} ]
                                       );
     foreach my $_inRef (@_inRefs) {
        print join("\t",
                   '<--',
                   ( map { $_inRef->{$_} } qw( constraint_name r_owner r_constraint_name ) )
                  ), "\n";
     }

     my $name_n = CBIL::Util::V::max(map { length $_->{column_name} } @_columns);
     my $_fmt   =  '%-'.$name_n. '.'. $name_n. 's';

     foreach my $_col (@_columns) {
        my @row = ( '',
                    sprintf($_fmt, lc $_col->{column_name}),
                    map { $_col->{$_} } qw( data_type data_precision data_scale)
                  );
        my @indices = $Self->sqlAsArray( Handle => $ndx_sh,
                                         Bind   => [ $_table->{owner}, $_table->{table_name}, $_col->{column_name} ]
                                       );
        push(@row, @indices);
        print join("\t", @row), "\n";
     }
  }
}

# ------------------------------- gusDump --------------------------------

sub gusDump {
   my $Self = shift;
   
   # get maximum width of databasenames
   my ($table_w) = @{$Self->sql_get_as_array
   ('select max(length(name)) from Core.TableInfo')
   };
   
   # get maximum width of columnnames
   my ($column_w) = @{$Self->sql_get_as_array
   ('select max(length(attribute_name)) from Core.DatabaseDocumentation')
   };
   $column_w = 32 if $column_w > 32;

   
   # get all non-version databases in order by name
   my @db_ids = 
   @{$Self->sql_get_as_array("select database_id from Core.DatabaseInfo")};
   
   my @_dbs = 
   sort { uc $a->getName() cmp uc $b->getName() }
   grep { $_->getName() !~ /Ver$/ }
   map  { 
     my $_db = GUS::Model::Core::DatabaseInfo->new({database_id => $_});
     if ($_db->retrieveFromDB()) {
       ($_db)
     } else {
       ()
     }
   } @db_ids;
   
   # process each database
   foreach my $_db (@_dbs) {
   
      print '=' x 120, "\n";
      print join("\t", 'DB', $_db->getName(),
                 $_db->getId(),
                 #$_db->getVersion(),
                 $_db->getDescription()
                ), "\n";
                  
      my @_tables = 
      sort { uc $a->getName() cmp uc $b->getName() }
      grep { $_->getTableType() ne 'version' }
      $_db->getChildren('Core::TableInfo',1);
      
      foreach my $_table (@_tables) {
      
         print '-' x 120, "\n";
      
         my $table = sprintf("%-${table_w}.${table_w}s", $_table->getName());
         my $kind  = $_table->getIsView() ? 'VIEW' : 'TBL';

         print join("\t", $kind, $_db->getName(), $table,
                    $_table->getPrimaryKeyColumn(),
                   ), "\n";
                   
         my @_docs = 
         sort { $a->getAttributeName() cmp $b->getAttributeName() }
         $_table->getChildren('Core::DatabaseDocumentation', 1);
          
         foreach my $_doc (@_docs) {
         
            my $att = sprintf("%-${column_w}.${column_w}s",
                              $_doc->getAttributeName() || 'TABLE'
                             );
               
         
            my $doc = $_doc->getHtmlDocumentation();
            chomp $doc;

            print join("\t", 'ROW',
                       $_db->getName(), $table,
                       $att,
                       $doc
                      ), "\n";
          }
      }
   }

}

# ----------------------------------------------------------------------

1;
