/**
 * 
 */
package org.gusdb.dbadmin.util;

import java.util.Collection;
import java.util.Iterator;

import org.gusdb.dbadmin.model.Table;

/**
 * @author msaffitz
 */
public abstract class DatabaseUtilities {

    public static Table getTableFromCollection( Collection tables, String schemaName, String tableName ) {
        for ( Iterator i = tables.iterator( ); i.hasNext( ); ) {
            Table table = (Table) i.next( );
            if ( table.getSchema( ).getName( ).equalsIgnoreCase( schemaName )
                    && table.getName( ).equalsIgnoreCase( tableName ) ) {
                return table;
            }
        }
        return null;
    }

}
