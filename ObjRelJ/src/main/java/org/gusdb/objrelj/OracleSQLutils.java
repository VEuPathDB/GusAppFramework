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
public class OracleSQLutils implements SQLutilsI, java.io.Serializable {

    private static final long serialVersionUID = 1L;

    // ------------------------------------------------------------------
    // SQLutilsI
    // ------------------------------------------------------------------

    @Override
    public String makeSelectAllRowsSQL(String owner, String table) 
    {
	return "select * from " + owner + "." + table;
    }

    @Override
    public String makeInsertSQL(String owner, String table, String pkatt, long pk, Hashtable atts)
    {
	StringBuffer insertSQL = new StringBuffer("INSERT into " + owner + "." + table + "\n(" );
	StringBuffer valuesClause = new StringBuffer("VALUES \n(" );
	String key;
	GUSRowAttribute grAtt;
	Object val;

	insertSQL.append(pkatt);
	valuesClause.append(pk);

	Enumeration attKeys= atts.keys();
	while (attKeys.hasMoreElements()){
	    key = (String)attKeys.nextElement();
	    insertSQL.append(",\n" + key);
	    grAtt = (GUSRowAttribute)atts.get(key);
	    val = grAtt.getSubmitValue();
	    valuesClause.append(", " + makeAppendValue(key, val));
	}
	
	insertSQL.append(")\n" + valuesClause + ")\n" );
	return insertSQL.toString();
    }

    @Override
    public String makeUpdateSQL(String owner, String table, String pkatt, 
				long pk, Hashtable atts) 
    {	
	StringBuffer updateSQL = new StringBuffer("update " + owner + "." + table +  " set \n ");
	StringBuffer whereSQL = new StringBuffer(" where " + pkatt + " = " + pk );
    
	Enumeration attKeys= atts.keys();
	GUSRowAttribute grAtt;

	int i = 0;
	while (attKeys.hasMoreElements()){
	    
	    String key = (String)attKeys.nextElement();
	    grAtt = (GUSRowAttribute)atts.get(key);

	    if (grAtt.isSetByApp()){
		if (i > 0) { updateSQL.append(",\n"); }
		i++;
		updateSQL.append(key.toUpperCase() + " = ");
		Object val = grAtt.getSubmitValue();
		updateSQL.append(makeAppendValue(key, val));
	    }
	}
	updateSQL.append(whereSQL.toString());
	return updateSQL.toString();
    } 

    @Override
    public String makeDeleteSQL(String owner, String table, String pkatt, long pk) {

	// NOTE: WE REALLY WILL WANT TO VERSION HERE, THIS IS JUST FOR 
	// TEST PURPOSES...    SJD

	// JC: Actually, the versioning won't be done here, but most likely we will
	// simply add another method that generates the (separate) SQL statement
	// required to handle to versioning step.

	StringBuffer deleteSQL = new StringBuffer("DELETE from " + owner + "." + table + "\n" );
	deleteSQL.append("WHERE " + pkatt + " = " + pk);
	return deleteSQL.toString();    }

    @Override
    public String makeNewIdSQL(GUSTable table) {
	String owner = table.getSchemaName();
	String tname = table.getTableName();

	// If the table in question has a SEQUENCE object, select the next
	// primary key value from there.
	//
	if (table.hasSequence()) {
	    return ("SELECT " + owner + "." + tname +"_SQ.NEXTVAL from DUAL" );
	}

	// If not, do a select max(prim_key_att) + 1
	//

	// JC: Presumably this is done in a transaction?  What happens if another 
	// application grabs the same primary key value and both try to insert?
	else {
	    String pkatt = table.getPrimaryKeyName();
	    return "SELECT max(" + owner + "." + tname +"."+ pkatt +") + 1 as pk_val from " + owner + "." + tname;
	}
    }

    @Override
    public String getSubmitDate(){
	return "SYSDATE";
    }
    
    //DTB:  is this database-specific?
    @Override
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
		final_value = " '" + value + "'";
	    } else if (value instanceof Boolean) {
		final_value = ((Boolean)value).booleanValue() ? "1" : "0";
	    }
	    else {
		final_value = value.toString();
	    }
	}   
	return final_value;
    }

} //OracleSQLutils
