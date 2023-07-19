package org.gusdb.objrelj;

import java.util.Vector;

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

    private static final long serialVersionUID = 1L;

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
     * The new primary key values for any newly-inserted rows; a Vector of Longs
     */
    protected Vector newPrimaryKeys;

    /**
     * Message from the database to the user regarding this attempt to submit.  
     * A good place to pass Exception error messages along.
     */
    protected String message;

    // ------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------

    public SubmitResult(boolean success, int rowsInserted, int rowsUpdated, int rowsDeleted, Vector pkeys) 
    {
	this.submitSucceeded = success;
	this.rowsInserted = rowsInserted;
	this.rowsUpdated = rowsUpdated;
	this.rowsDeleted = rowsDeleted;
	this.newPrimaryKeys = pkeys;
	this.message = "";
    }

    // ------------------------------------------------------------------
    // Public methods
    // ------------------------------------------------------------------

    // Accessors
    public boolean submitSucceeded() { return this.submitSucceeded; }
    public int getRowsInserted() { return this.rowsInserted; }
    public int getRowsUpdated() { return this.rowsUpdated; }
    public int getRowsDeleted() { return this.rowsDeleted; }
    public Vector getNewPrimaryKeys() { return this.newPrimaryKeys; }
    public String getMessage() { return this.message; }

    public void setMessage(String newMessage){
	message = newMessage;
    }

    // ------------------------------------------------------------------
    // Package-scoped methods
    // ------------------------------------------------------------------

    /**
     * Update the contents of this object based on those of another.
     * Assumes that this object is being used to aggregate the results
     * of several other submits.
     */
    void update(SubmitResult sr) {
	if (this.submitSucceeded) {
	    this.submitSucceeded = sr.submitSucceeded();
	}
	if (this.submitSucceeded){
	    this.rowsInserted += sr.getRowsInserted();
	    this.rowsUpdated+= sr.getRowsUpdated();
	    this.rowsDeleted += sr.getRowsDeleted();
	    Vector myPrimaryKeys = this.getNewPrimaryKeys();
	    Vector newPrimaryKeys = sr.getNewPrimaryKeys();
	    if (myPrimaryKeys != null && newPrimaryKeys != null){
		this.getNewPrimaryKeys().addAll(sr.getNewPrimaryKeys());
	    }
	}
    }
}
