package org.gusdb.objrelj;

/**
 * SubmitResult.java
 *
 * A simple class that represents the result of submitting a GUSRow
 * to the database using <code>GUSServerI.submitObject()</code>
 *
 * Created: Mon Mar 10 23:16:12 EST 2003
 *
 * @author Jonathan Crabtree
 * @version $Revision$ $Date$ $Author$
 */
public class SubmitResult implements java.io.Serializable {

    // ------------------------------------------------------------------
    // Instance variables
    // ------------------------------------------------------------------
    
    /**
     * Whether the submit operation succeeded.  If false then the remaining
     * instance variables should be ignored.
     */
    protected boolean submitSucceeded;

    /**
     * The number of rows inserted as a result of the submit.
     */
    protected int rowsInserted;

    /**
     * The number of rows updated as a result of the submit.
     */
    protected int rowsUpdated;

    /**
     * The number of rows deleted as a result of the submit.
     */
    protected int rowsDeleted;

    /**
     * The new primary key values for any newly-inserted rows.
     */
    protected long[] newPrimaryKeys;

    // ------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------

    public SubmitResult(boolean success, int rowsInserted, int rowsUpdated, int rowsDeleted, long pkeys[]) 
    {
	this.submitSucceeded = success;
	this.rowsInserted = rowsInserted;
	this.rowsUpdated = rowsUpdated;
	this.rowsDeleted = rowsDeleted;
	this.newPrimaryKeys = pkeys;
    }

    // ------------------------------------------------------------------
    // Public methods
    // ------------------------------------------------------------------

    public boolean submitSucceeded() { return this.submitSucceeded; }
    public int getRowsInserted() { return this.rowsInserted; }
    public int getRowsUpdated() { return this.rowsUpdated; }
    public int getRowsDeleted() { return this.rowsDeleted; }
    public long[] getNewPrimaryKeys() { return this.newPrimaryKeys; }

}
