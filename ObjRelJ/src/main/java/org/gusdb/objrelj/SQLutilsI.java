package org.gusdb.objrelj;

import java.util.Hashtable;

/**
 * SQLutilsI.java
 *
 * An interface that describes the SQL-handling methods that must be
 * defined for each database management system (e.g. Oracle 8i, Sybase
 * 11.9.1) supported by the Java object layer.
 *
 * Created: Wed Mar  5 10:27:45 EST 2003
 *
 * @author Jonathan Crabtree
 * @version $Revision$ $Date$ $Author$ 
 */
public interface SQLutilsI {

    // ------------------------------------------------------------------
    // SELECT
    // ------------------------------------------------------------------

    /**
     * Generate an SQL SELECT statement that will retrieve all the rows
     * from a given table.
     *
     * @param owner     Owner of the table from which to select
     * @param table     Name of the table from which to select.
     * @return A String that contains the SQL select statement.
     */
    public String makeSelectAllRowsSQL(String owner, String table);

    // JC: Is there a reason that we're not passing GUSRow objects directly to
    // these methods (e.g., makeInsertSQL, makeUpdateSQL)?

    // ------------------------------------------------------------------
    // INSERT 
    // ------------------------------------------------------------------

    /**
     * Generate an SQL INSERT statement for a (GUS) row.  Neither <code>atts</code>
     * nor <code>defaults</code> should contain the primary key column, nor should
     * <code>atts</code> and <code>defaults</code> contain any of the same columns.
     *
     * @param owner     Owner of the table into which to insert.
     * @param table     Name of the table into which to insert.
     * @param pkatt     Name of the table's primary key column.
     * @param pk        Primary key value of the row to insert.
     * @param atts      Values for <B>all</B> of the table's non-nullable, non-primary key columns.
     * @return A String that contains the SQL insert statement.
     */
    public String makeInsertSQL(String owner, String table, String pkatt, 
				long pk, Hashtable atts);

    // ------------------------------------------------------------------
    // UPDATE
    // ------------------------------------------------------------------
	
    /**
     * Generate an SQL UPDATE statement for a (GUS) row.
     *
     * @param owner     Owner of the table to be updated.
     * @param table     Name of the table to be updated.
     * @param pkatt     Name of the table's primary key column.
     * @param pk        Primary key value of the row to update.
     * @param atts      New values for 0 or more of the table's NON-primary key columns.
     * @param oldAtts   <i>Original</i> values for the columns in <code>atts</code>.
     * @return A String that contains the SQL update statement.
     */    
    public String makeUpdateSQL(String owner, String table, String pkatt, 
				long pk, Hashtable atts);

    // ------------------------------------------------------------------
    // DELETE
    // ------------------------------------------------------------------

    // JC: This will have to change in order to support versioning; at the very
    // least we'll need to add a method to get the command that creates the 
    // version table row.

    /**
     * Construct an SQL DELETE statement for a (GUS) row.
     *
     * @param owner     Owner of the table containing the row to delete.
     * @param table     Name of the table containing the row to delete.
     * @param pkatt     Name of the table's primary key column.
     * @param pk        Primary key value of the row to delete.
     * @return A String that contains the SQL delete statement.
     */
    public String makeDeleteSQL(String owner, String table, String pkatt, long pk);

    // ------------------------------------------------------------------
    // PRIMARY KEY VALUES
    // ------------------------------------------------------------------

    /**
     * Construct an SQL statement that will generate a new unique primary key
     * value for the row in question.
     *
     * @param row       The GUSTable for which a new primary key value should be generated.
     * @return A String that contains the SQL select statement.
     */
    public String makeNewIdSQL(GUSTable table);

    // ------------------------------------------------------------------
    // TRANSACTIONS
    // ------------------------------------------------------------------

    /**
     * Return the SQL that corresponds to a given transaction management command. 
     *
     * @param noTran     Whether transactions have been disabled.
     * @param cmd        Either 'commit' or 'rollback'
     * @return The SQL command that corresponds to <code>cmd</code>, if <code>!noTran</code>
     */

    // DTB: take 'noTran' out as a parameter?  Need to figure out scenarios for its usage.

    public String makeTransactionSQL(boolean noTran, String cmd);

    /**
     * Retrieve a date (as a <code>String</code>) that represents the time at which
     * an object is submitted to the database.
     */ 
    public String getSubmitDate();


} //SQLutilsI
