/**
 * 
 */
package org.gusdb.dbadmin.util;

import java.util.Collection;
import java.util.Iterator;
import java.util.Vector;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.gusdb.dbadmin.model.Column;
import org.gusdb.dbadmin.model.Database;
import org.gusdb.dbadmin.model.GusSchema;
import org.gusdb.dbadmin.model.GusTable;
import org.gusdb.dbadmin.model.Schema;
import org.gusdb.dbadmin.model.Table;

/**
 * @author msaffitz
 */
public class SchemaComparator {

    protected static final Log log = LogFactory.getLog(SchemaComparator.class);
    
    private Database   leftDatabase;
    private Database   rightDatabase;

    private Collection leftIdenticalTables = new Vector();

    private Collection leftRenamedTables = new Vector();
    private Collection leftChangedTables = new Vector();
    private Collection leftDroppedTables = new Vector();

    private Collection rightAddedTables;

    public SchemaComparator( Database leftDatabase, Database rightDatabase ) {
        this.leftDatabase = leftDatabase;
        this.rightDatabase = rightDatabase;
    }

    public boolean compare( ) {
        findLeftIdenticalTables();
        findLeftRenamedTables();
        findLeftChangedTables();
        findLeftDroppedTables();
        findRightAddedTables();
        
        return false;
    }

    public Collection findLeftIdenticalTables() {
       if ( ! leftIdenticalTables.isEmpty() ) return leftIdenticalTables;
        
        for ( Iterator i = leftDatabase.getSchemas( true ).iterator( ); i
                .hasNext( ); ) {
            GusSchema schema = (GusSchema) i.next( );
            for ( Iterator j = schema.getTables( ).iterator( ); j.hasNext( ); ) {
                GusTable table = (GusTable) j.next( );

                Schema rightSchema = rightDatabase.getSchema( table.getSchema( )
                        .getName( ) );
                if ( rightSchema == null ) continue;
                Table rightTable = rightSchema.getTable( table.getName( ) );
                if ( rightTable == null ) continue;

                if ( !table.equals( rightTable ) ) continue;
                if ( !table.columnsEqual( rightTable ) ) continue;
                if ( !table.subclassesEqual( rightTable ) ) continue;
                if ( !table.constraintsEqual( rightTable ) ) continue;
                if ( !table.indexesEqual( rightTable ) ) continue;
                leftIdenticalTables.add( table );
            }
        }
        
        return leftIdenticalTables;
    }

    public Collection findLeftRenamedTables( ) {
        if ( ! leftRenamedTables.isEmpty() ) return leftRenamedTables;
        for ( Iterator i = leftDatabase.getSchemas(true).iterator(); i.hasNext(); ) {
            GusSchema schema = (GusSchema) i.next();
            for ( Iterator j = schema.getTables().iterator(); j.hasNext(); ) {
                GusTable table = (GusTable) j.next();
                if ( findLeftIdenticalTables().contains(table) ) continue;
                if ( rightDatabase.getSchema(table.getSchema().getName()) != null &&
                        rightDatabase.getSchema(table.getSchema().getName()).getTable(table.getName()) != null ) continue;
                Table renamedTable = findRenameMatch( table, rightDatabase, 0 );
                if ( renamedTable != null ) {
                    leftRenamedTables.add(table);
                }
            }
        }
        
        
        return leftRenamedTables;
        
    }
    
    public Collection findLeftChangedTables() {
        return leftChangedTables;
    }
    
    public Collection findLeftDroppedTables() {
        return leftDroppedTables;
    }
    
    public Collection findRightAddedTables() {
        return rightAddedTables;
        
    }
    
    public static Table findRenameMatch( Table table, Database db, int maxModifiedColumns  ) {
        // TODO Cache with ahs map
        Collection potentialMatches = new Vector();
        
        for ( Iterator i = db.getSchemas(true).iterator(); i.hasNext(); ) {
            Schema schema = (Schema) i.next();
            for ( Iterator j = schema.getTables().iterator(); j.hasNext(); ) {
                Table targetTable = (Table) j.next();
                if ( targetTable.getSchema().getName() == table.getSchema().getName() &&
                     targetTable.getName() == table.getName() ) continue;

                int foundModifiedColumns = targetTable.getColumns(false).size() - table.getColumns(false).size();
                if ( foundModifiedColumns < 0 ) foundModifiedColumns = 0;

                for ( Iterator k = table.getColumns().iterator(); k.hasNext(); ) {
                    Column column = (Column) k.next();
                    if ( targetTable.getColumn(column.getName()) == null ) foundModifiedColumns++;
                    else if ( ! column.equals(targetTable.getColumn(column.getName())) ) foundModifiedColumns++;
                }
                if ( foundModifiedColumns > maxModifiedColumns ) continue;
                potentialMatches.add(targetTable);
           }
                    
       }
        // TODO  Need TO Just Get ONe
        if ( potentialMatches.isEmpty() ) return null;
        if ( potentialMatches.size() > 1 ) {
            log.info("More than one potential renaming for " + table.getSchema().getName() + "." + table.getName());
        }
        return (Table) potentialMatches.toArray()[0];
    }
    
    
    
}
