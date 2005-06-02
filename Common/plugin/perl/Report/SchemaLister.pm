
package GUS::Common::Plugin::Report::SchemaLister;
@ISA = qw(GUS::PluginMgr::Plugin);

# ----------------------------------------------------------------------

use strict;

use FileHandle;
use V;

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
   ({ requiredDbVersion => {},
      cvsRevision       => ' $Revision$ ',
      cvsTag            => ' $Name$ ',
      name              => ref($self),

      # just expand
      revisionNotes     => '',
      revisionNotes     => 'initial creation and testing',

      # ARGUMENTS
      argsDeclaration   =>
      [
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
                 $_db->getVersion(),
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
