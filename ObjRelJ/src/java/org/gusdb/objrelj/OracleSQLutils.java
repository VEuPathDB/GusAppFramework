package org.gusdb.objrelj;

import java.sql.*;
import java.util.Hashtable;
import java.util.Enumeration;

/**
 * OracleSQLutils.java
 *
 * An Oracle-specific implementation of SQLutilsI.
 *
 * Created: Wed May 16 12:30:00 2002
 *
 * @author Sharon Diskin, Dave Barkan, Jonathan Crabtree
 * @version $Revision$ $Date$ $Author$
 */
public class OracleSQLutils implements SQLutilsI {

    // ------------------------------------------------------------------
    // SQLutilsI
    // ------------------------------------------------------------------

    public String makeInsertSQL(String owner, String table, String pkatt, 
				Integer pk, Hashtable atts, Hashtable defaults) 
    {
	StringBuffer insertSQL = new StringBuffer("INSERT into " + owner + "." + table + "\n(" );
	StringBuffer valuesClause = new StringBuffer("VALUES \n(" );
	String key;
	Object val;

	insertSQL.append(pkatt);
	valuesClause.append(pk.toString());

	// Note that atts and defaults are handled *exactly* the same way; the
	// only reason that the two are separated is to make it easier for the
	// object layer to set the GUS "overhead" columns (e.g., modification_date,
	// row_alg_invocation_id, etc.)
	
	Enumeration attKeys= atts.keys();
	while (attKeys.hasMoreElements()){
	    key = (String)attKeys.nextElement();
	    insertSQL.append(",\n" + key);
	    val = atts.get(key);
	    valuesClause.append(", " + makeAppendValue(key, val));
	}
	
	// add on the default values...
	Enumeration defKeys= defaults.keys();
	while (defKeys.hasMoreElements()){
	    key = (String)defKeys.nextElement();
	    insertSQL.append(",\n" + key);
	    val = defaults.get(key);
	    valuesClause.append(", " + makeAppendValue(key, val));
	}
	
	insertSQL.append(")\n" + valuesClause + ")\n" );
	return insertSQL.toString();
    }

    public String makeUpdateSQL(String owner, String table, String pkatt, 
				Long pk, Hashtable atts, Hashtable oldAtts) 
    {	
	StringBuffer updateSQL = new StringBuffer("update " + owner + "." + table +  " set \n ");
	StringBuffer whereSQL = new StringBuffer(" where " + pkatt + " = " + pk.toString() );
    
	Enumeration attKeys= atts.keys();
	Enumeration oldAttKeys = oldAtts.keys();

	int i = 0;
	while (attKeys.hasMoreElements()){
	    if (i++ == 0) { updateSQL.append(",\n"); }
	    String key = (String)attKeys.nextElement();
	    updateSQL.append(key.toUpperCase() + " = ");
	    Object val = atts.get(key);
	    updateSQL.append(makeAppendValue(key, val));
	}

	//attributes that are in oldAttKeys but not attKeys have been set to NULL
	while (oldAttKeys.hasMoreElements()){
	    Object oldKey = oldAttKeys.nextElement();
	    if (!(atts.containsKey(oldKey))){
		updateSQL.append(", \n" + key + " = NULL ");
	    }
	}
	    
	updateSQL.append(whereSQL.toString());
	return updateSQL.toString();
    } 

    public String makeDeleteSQL(String owner, String table, String pkatt, Long pk) {

	// NOTE: WE REALLY WILL WANT TO VERSION HERE, THIS IS JUST FOR 
	// TEST PURPOSES...    SJD

	// JC: Actually, the versioning won't be done here, but most likely we will
	// simply add another method that generates the (separate) SQL statement
	// required to handle to versioning step.

	StringBuffer deleteSQL = new StringBuffer("DELETE from " + owner + "." + table + "\n" );
	deleteSQL.append("WHERE " + pkatt + " = " + pk.toString());
	return deleteSQLtoString();
    }

    public String makeNewIdSQL(GUSTable table) {
	String owner = table.getOwnerName();
	String table = table.getTableName();

	// If the table in question has a SEQUENCE object, select the next
	// primary key value from there.
	//
	if (table.hasSequence()) {
	    return ("SELECT " + owner + "." + table +"_SQ.NEXTVAL from DUAL" );
	}

	// If not, do a select max(prim_key_att) + 1
	//

	// JC: Presumably this is done in a transaction?  What happens if another 
	// application grabs the same primary key value and both try to insert?
	else {
	    String pkatt = table.getPrimaryKeyName();
	    return "SELECT max(" + owner + "." + table +"."+ pkatt +") + 1 as pk_val from " + owner + "." + table;
	}
    }

    public String makeTransactionSQL(boolean noTran, String cmd) {
        String command = null;
        if (!noTran){
            if (cmd.equals("commit")){
                command = "COMMIT";
            } else if (cmd.equals("rollback")){
                command = "ROLLBACK";
            }
        }
        return command;
    } 

    // ------------------------------------------------------------------
    // Protected methods
    // ------------------------------------------------------------------

    /**
     * Generate a string that can be appended to an SQL INSERT or
     * UPDATE statement.
     *
     * @param key      The name of the column.
     * @param value    The value for that column.
     * @return The value to be appended to the SQL statement.
     */
    protected String makeAppendValue(String key, Object value){
	String final_value;

        if (value == null){ 
            final_value = "\nNULL";
        } 
        else {
            if (value instanceof String || value instanceof Date) {
		// JC: Don't we have to worry about quoting embedded quote characters here?
		// JC: this is another oracle-specific section
		final_value = "\n'" + value + "'";
	    } else if (value instanceof Boolean) {
		final_value = value.booleanValue() ? "1" : "0";
	    }
	    else {
		final_value = value.toString();
	    }
	}   
	return final_value;
    }

} //OracleSQLutils
