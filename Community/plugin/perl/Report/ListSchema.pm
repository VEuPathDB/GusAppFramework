
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
   ({ requiredDbVersion => '3.6',
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
        stringArg({  name    => 'OwnerRx',
                     descr   => 'select owners that look like this regexp',
                     reqd    => 0,
                     default => '.',
                     isList  => 0,
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
   } grep {
      $_->{owner} =~ $Self->getArg('OwnerRx')
   } $Self->sqlAsHashRefs( Sql => <<Sql );
SELECT owner, table_name
FROM   all_tables
WHERE  owner in ('CORE', 'DOTS', 'PROT', 'RAD', 'SRES', 'STUDY', 'TESS')
Sql

   # get a dictionary mapping (most) uppercase names to Camel-cased names
   my %tableCamelCase_dict = $Self->sqlAsDictionary( Sql => <<Sql );
   SELECT upper(ti.name), ti.name
   FROM   core.DatabaseInfo di
   ,      core.TableInfo    ti
   WHERE  di.database_id = ti.database_id
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

   # query handle to get foreign key constraints for a table.
   my $outRef_sh = $Self->getQueryHandle()->prepare(<<Sql);
select acc.constraint_name, accr.owner as r_owner, accr.column_name as r_column
from   all_cons_columns acc
,      all_constraints  ac
,      all_cons_columns accr
where  acc.owner           = ?
and    acc.table_name      = ?
and    acc.column_name     = ?
and    acc.owner           = ac.owner
and    acc.constraint_name = ac.constraint_name
and    ac.constraint_type  = 'R'
and    ac.r_owner           = accr.owner
and    ac.r_constraint_name = accr.constraint_name
Sql

   # query handle to get table and column documentation
   my $doc_sh = $Self->getQueryHandle()->prepare(<<Sql);
select dd.attribute_name, dd.html_documentation
from   core.databaseInfo          di
,      core.tableInfo             ti
,      core.databaseDocumentation dd
where  di.name           = ?
and    di.database_id    = ti.database_id
and    lower(ti.name)    = lower(?)
and    ti.table_id       = dd.table_id
Sql

  foreach my $_table (@_tables) {

     my @table_bind = ( $_table->{owner}, $_table->{table_name} );

     my $camelTable
     = $tableCamelCase_dict{$_table->{table_name}} || $_table->{table_name};

     my @_columns = sort {
        $a->{column_id} <=> $b->{column_id}
     } $Self->sqlAsHashRefs( Handle => $cols_sh,
                             Bind   => \@table_bind
                           );

     my %doc_dict = $Self->sqlAsDictionary( Handle => $doc_sh,
                                            Bind   => \@table_bind,
                                          );
     foreach (keys %doc_dict) {
        $doc_dict{$_} =~ s/\s/ /g;
     }

     my $name_n = CBIL::Util::V::max(map { length $_->{column_name} } @_columns);
     my $_fmt   =  '%-'.$name_n. '.'. $name_n. 's';

     print join("\t", $_table->{owner}, $camelTable,
                '', 'Type', 'P', 'S', 'Indices', 'Refs',
                $doc_dict{''}
               ), "\n";

     foreach my $_col (@_columns) {

        my @column_bind = ( @table_bind, $_col->{column_name} );

        my @row = ( $_table->{owner}, $camelTable,
                    sprintf($_fmt, lc $_col->{column_name}),
                    map { $_col->{$_} } qw( data_type data_precision data_scale)
                  );

        # get indices this column participates in
        my @indices = $Self->sqlAsArray( Handle => $ndx_sh,
                                         Bind   => \@column_bind
                                       );
        push(@row, join('; ', @indices) || 'no indices');

        # get references to other tables
        my @_refs = $Self->sqlAsHashRefs( Handle => $outRef_sh,
                                          Bind   => \@column_bind,
                                        );
        push(@row,
             join('; ',
                  map {
                     sprintf('(%s)->%s.%s',
                             $_->{constraint_name},
                             $_->{r_owner},
                             lc $_->{r_column}
                            )
                  } @_refs
                 ) || 'no refs'
            );

        # add documentation for row
        push(@row, $doc_dict{lc $_col->{column_name}} || 'no doc');

        # print the row for the column
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
