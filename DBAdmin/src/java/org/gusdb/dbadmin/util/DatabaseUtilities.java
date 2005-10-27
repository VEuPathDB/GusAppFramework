/**
 */
package org.gusdb.dbadmin.util;

import java.util.Collection;
import java.util.Iterator;

import org.gusdb.dbadmin.model.Table;
import org.gusdb.dbadmin.model.GusTable;
import org.gusdb.dbadmin.model.Index;
import org.gusdb.dbadmin.model.Database;
import org.gusdb.dbadmin.model.Schema;

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
    public static Table getTableFromCollection( Collection tables, String schemaName, String tableName ) {
        for ( Iterator i = tables.iterator(); i.hasNext();  ) {
            Table table  = (Table) i.next();

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
		for ( Iterator i = db.getSchemas().iterator(); i.hasNext();  ) {
			for ( Iterator j = ((Schema) i.next()).getTables().iterator(); j.hasNext(); ) {
				Table table = (Table) j.next();
				table.setTablespace(tablespaceName);
				
				if ( table.getClass() == GusTable.class ) {
					for ( Iterator k = ((GusTable)table).getIndexs().iterator(); k.hasNext(); ) {
						((Index) k.next()).setTablespace(tablespaceName);
					}
				}
			}
		}	
    }


}

