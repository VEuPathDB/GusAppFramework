package org.gusdb.objrelj;

import java.rmi.RemoteException;
import java.util.Vector;

/**
 * DatabaseConnectionI.java
 *
 * An API that describes the minimum functionality required of a 
 * GUS database connection by the Java object layer (i.e., GUSServerI).  
 * Note that the methods in this interface are very similar to those 
 * that appear in <code>GUSServerI</code>.  However, the methods 
 * described in this interface are not required to implement the 
 * caching behavior described in <code>GUSServerI</code>.
 *
 * @author Dave Barkan, Jonathan Crabtree
 * @version $Revision$ $Date$ $Author$
 */
public interface DatabaseConnectionI {

    /**
     * @return the SQLutils for this database.
     */
    public SQLutilsI getSqlUtils() throws RemoteException;

    /**
     * Sets and authenticates the GUS user.  If the specified username and
     * password correspond to a valid entry in the Core.UserInfo table, 
     * then the assigned user_id will be returned.
     *
     * @param user       A value from core.UserInfo.login
     * @param password   The corresponding value from core.UserInfo.password
     * @param The user_id of the user, if the login information is valid, -1 otherwise.
     */
    public long setCurrentUser(String user, String password)
	throws RemoteException;

    /**
     * @return The core.UserInfo.user_id of the current user.
     */
    public long getCurrentUserId()
	throws RemoteException;

    /**
     * Retrieve a single object from the database, and only retrieve as much of the
     * specified CLOB value as indicated by <code>start</code> and <code>end</code>, 
     * if <code>clobAtt != null</code>.  If <code>clobAtt == null</code> then all of
     * the row's attributes will be retrieved in their entirety.
     *
     * @param owner    The owner of the object's table.
     * @param tname    The object's table.
     * @param pk       Primary key value for the row of interest.
     * @param clobAtt  The name of the CLOB-containing attribute.
     * @param start    Start coordinate of the CLOB range to retrieve and cache in 1-based 
     *                 coordinates.  If null and clobAtt != null then the value 1 will be used instead.
     * @param end      End coordinate of the CLOB range to retrieve and cache in 1-based 
     *                 coordinates.  If null and clobAtt != null then the value clobAtt.length() 
     *                 will be used instead.
     */
    public void retrieveGUSRow(GUSRow gusRow, String clobAtt, Long start, Long end)
	throws RemoteException, GUSObjectNotUniqueException;

    /**
     * Retrieve a set of GUSRow objects from the database using an SQL query.  It is 
     * assumed that the objects will all be instances of the same subclass of GUSRow.
     *
     * @param owner    The owner of the table that the query selects from.
     * @param tname    The name of the table that the query selects from.
     * @param query    An SQL query that does a select * from a single table.
     * @return A Vector of GUSRow objects corresponding to the rows selected.
     */
    public Vector retrieveGUSRowsFromQuery(GUSTable table, String query)
	throws RemoteException;
    
    /**
     * Run an SQL query and return the results as a Vector of Hashtables.
     * Each Hashtable maps from column name to data value.  This method is 
     * an escape to SQL and its use should be limited.
     *
     * @param sql      An arbitrary SQL query.
     * @return A Vector of Hashtables corresponding to the rows selected.
     */
    public Vector runSqlQuery(String sql) 
	throws RemoteException;

    /**
     * Submit a <B>single</B> object to the database (i.e., this is not a "deep" submit).  
     * This can result in the object being deleted, updated, or inserted, depending 
     * on the situation.  The GUSRow object itself will <b>not</b> be modified in any
     * way.
     *
     * @param obj         The new or updated object to write back to the database.
     * @return The result of the update, insert, or delete.
     */
    public SubmitResult submitGUSRow(GUSRow obj)
	throws RemoteException;

    /**
     * Retrieve a row (parent) referenced by another.
     *
     * @param row       The row whose parent is to be retrieved.
     * @param owner     The owner of the parent object's table.
     * @param tname     The name of the parent object's table.
     * @param childAtt  The name of the referencing attribute in the child table.
     * @return The unique parent object if one exists, null otherwise.
     */
    public GUSRow retrieveParent(GUSRow row, String owner, String tname, String childAtt)
	throws RemoteException, GUSNoSuchRelationException, GUSObjectNotUniqueException;
	

    public Long getParentPk(GUSRow child, GUSTable parentTable, String childAtt)
    	throws RemoteException, GUSNoSuchRelationException, GUSObjectNotUniqueException;

    /**
     * Retrieve all the parent rows for a set of child rows.
     *
     * @param children     The rows whose (unique) parent rows are to be returned.
     * @param parentOwner  The owner of the parent table.
     * @param parentName   The name of the parent table
     * @param childAtt  The name of the referencing attribute in the child table.
     * @return An array of size <code>children.size()</code>, containing the parents.
     */
    public GUSRow[] retrieveParentsForAllGUSRows(Vector children, String parentOwner, String parentName, String childAtt)
	throws RemoteException, GUSNoSuchRelationException, GUSObjectNotUniqueException;

    /**
     * Retrieve the single row in a given table (child) that references a specified row (the parent.)
     *
     * @param row       The row whose child is to be retrieved.
     * @param owner     The owner of the child object's table.
     * @param tname     The name of the child object's table.
     * @param childAtt  The name of the referencing attribute in the child table.
     * @return The unique child row if one exists, null otherwise.
     */
    public GUSRow retrieveChild(GUSRow row, String owner, String tname, String childAtt)
	throws RemoteException, GUSNoSuchRelationException, GUSObjectNotUniqueException;
	
    /**
     * Retrieve all rows in a given table (children) that reference a specified row (the parent).
     *
     * @param row      The row whose children are to be retrieved.
     * @param owner    The owner of the child objects' table.
     * @param tname    The name of the child objects' table.
     * @param childAtt  The name of the referencing attribute in the child table.
     */
    public Vector retrieveChildren(GUSRow row, String owner, String tname, String childAtt)
	throws RemoteException, GUSNoSuchRelationException;

    /**
     * Retrieve a date (as a <code>String</code>) that represents the time at which
     * an object is submitted to the database.
     */ 
    public String getSubmitDate() throws RemoteException;

    /**
     * Close the connection, freeing any resources that it holds.
     */
    public void close() 
	throws RemoteException;

    public boolean commit() throws RemoteException;

} // DatabaseConnectionI
