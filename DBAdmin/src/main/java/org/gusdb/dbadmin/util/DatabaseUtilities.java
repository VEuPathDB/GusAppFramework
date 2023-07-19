/**
 */
package org.gusdb.dbadmin.util;

import java.util.ArrayList;

import org.gusdb.dbadmin.model.Database;
import org.gusdb.dbadmin.model.GusTable;
import org.gusdb.dbadmin.model.Index;
import org.gusdb.dbadmin.model.Table;

/**
 *@author     msaffitz
 *@created    October 12, 2005
 */
public abstract class DatabaseUtilities {

    /**
     *  Gets the tableFromCollection attribute of the DatabaseUtilities class
     *
     *@param  tables      Description of the Parameter
     *@param  schemaName  Description of the Parameter
     *@param  tableName   Description of the Parameter
     *@return             The tableFromCollection value
     */
    public static Table getTableFromCollection( ArrayList<Table> tables, String schemaName, String tableName ) {
        for ( Table table : tables ) {
            if ( table.getSchema().getName().equalsIgnoreCase( schemaName )
                 && table.getName().equalsIgnoreCase( tableName ) ) {
                return table;
            }
        }
        return null;
    }


    /**
     *  Sets all objects in the database to use a common tablespace
     *
     *@param  db              Database to act on
     *@param  tablespaceName  Tablespace name to set
     */
    public static void setTablespace( Database db, String tablespaceName ) {
	    for ( Table table : db.getAllTables() ) {
			table.setTablespace(tablespaceName);
				
			if ( table.getClass() == GusTable.class ) {
                for ( Index i : ((GusTable) table).getIndexes() ) {
					i.setTablespace(tablespaceName);
				}
			}
		}	
    }


}

