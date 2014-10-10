package org.gusdb.objrelj;

import java.util.List;
import java.util.Vector;

/**
 * ServerI.java
 *
 * The main API for Java access to a GUS database instance.  It contains
 * methods to allow the application to retrieve GUS objects (i.e., objects
 * that subclass GUSRow) from the database, to create new GUS objects,
 * to traverse the parent/child relationships that connect GUS objects,
 * and to submit modified GUS objects back to the database.
 *
 * Created: Mon Mar 10 23:02:19 EST 2003
 *
 * @author Sharon Diskin, Dave Barkan, Jonathan Crabtree
 * @version $Revision$ $Date$ $Author$ 
 */
public interface ServerI {

    // ------------------------------------------------------------------
    // SESSION MANAGEMENT
    // ------------------------------------------------------------------

    /**
     * Open a connection to a GUS database instance, thus establishing a session.
     *
     * @param user     A GUS login/username from core.UserInfo.login.
     * @param password The password that corresponds to <code>user</code> in core.UserInfo.
     * @return A session string that can be passed to the other methods in this class.
     */
    public String openConnection(String user, String password) throws GUSInvalidLoginException;

    /**
     * Close an existing session's database connection.
     * 
     * @param session  A session identifier returned by <code>openConnection</code>
     */
    public void closeConnection(String session) throws GUSNoConnectionException;

    /**
     * Returns a list of the actions performed so far in a session.
     *
     * @param session  A session identifier returned by <code>openConnection</code>
     * @return A List of Strings detailing the actions performed so far in the session.
     */
    public List getSessionHistory(String session) throws GUSNoConnectionException;

    // ------------------------------------------------------------------
    // RETRIEVE OBJECTS FROM DATABASE OR CACHE
    // ------------------------------------------------------------------

    /**
     * Retrieve a single object from the database by side effect by filling in the values of 
     * <code>gusRow</code>.  If the object has already  been retrieved in this session, 
     * then the same Java object will be retrieved from the cache. and returned.  Optionally, 
     * the user can specify  to retrieve an empty version of the GUSRow, with no attributes set 
     * except for the primary key.  The object will still be stored in the cache, and its
     * attributes will be filled in if it is later fully retrieved from the database.
     *
     * @param session               A session identifier returned by <code>openConnection</code>
     * @param gusRow                The GUSRow object which has already been constructed by a GUSRow 
     *                              subclass and will have its attributes filled in from the database.
     * @param retrieveFromDatabase  Whether or not to actually get this from the database
     *                              or just return an version of it with no attributes set 
     *                              except for the primary key.
     */
    public GUSRow retrieveGUSRow(String session, GUSTable table, long pkValue, boolean retrieveEager)
        throws GUSNoConnectionException, GUSObjectNotUniqueException;

    /**
     * Retrieve all objects from a single table.  This method will always query
     * the database, but any objects that have already been retrieved will be 
     * returned from the cache.
     *
     * @param session  A session identifier returned by <code>openConnection</code>
     * @param table    The GUSTable object representing the table to query.
     * @return A Vector of GUSRow objects.
     */
    public Vector retrieveAllGUSRows(String session, GUSTable table)
        throws GUSNoConnectionException;

    /**
     * Retrieve a set of GUSRow objects using an SQL query.  It is assumed that the 
     * objects will all be instances of the same subclass of GUSRow.  This method 
     * will always query the database, but any objects that have already been 
     * retrieved will be returned from the cache.
     *
     * @param session  A session identifier returned by <code>openConnection</code>
     * @param query    An SQL query that does a select * from a single table.
     * @param table    The GUSTable representing the table that the query selects from.
     * @return A Vector of GUSRow objects corresponding to the rows selected.
     */
    public Vector retrieveGUSRowsFromQuery(String session, GUSTable table, String query)
	throws GUSNoConnectionException;

    /**
     * Run an SQL query and return the results as a Vector of Hashtables.
     * Each Hashtable maps from column name to data value.  This method is 
     * an escape to SQL and its use should be limited.
     *
     * @param session  A session identifier returned by <code>openConnection</code>
     * @param sql      An arbitrary SQL query.
     * @return A Vector of Hashtables corresponding to the rows selected.
     */
    public Vector runSqlQuery(String session, String sql) throws GUSNoConnectionException;

    // ------------------------------------------------------------------
    // RETRIEVE FROM DATABASE OR CACHE - OBJECTS WITH CLOB VALUES
    // ------------------------------------------------------------------
    
    /**
     * Retrieve, by side effect, a single object from the database, but only retrieve as much of the
     * specified CLOB value as indicated by <code>start</code> and <code>end</code>.
     * To retrieve the entire CLOB value, either set both <code>start</code> and
     * <code>end</code> to NULL, or use the the standard <code>retrieveGUSRow</code>
     * method instead.  If the requested object has already been retrieved then it
     * will be returned from the cache, but its cached CLOB value will be updated
     * to reflect the parameters of the method call.
     *
     * Optionally, the user can specify to retrieve an empty version of the GUSRow, 
     * with no attributes set except for the primary key.  The object will still be 
     * stored in the cache, and its attributes will be filled in if it is later 
     * fully retrieved from the database.
     *
     * @param session  A session identifier returned by <code>openConnection</code>
     * @param table    The GUSTable object representing the GUSRow's table.
     * @param pk       Primary key value for the row of interest.
     * @param clobAtt  The name of the CLOB-containing attribute.
     * @param start    Start coordinate of the CLOB range to retrieve and cache in 1-based 
     *                 coordinates.  If null and clobAtt != null then the value 1 will be used instead.
     * @param end      End coordinate of the CLOB range to retrieve and cache in 1-based 
     *                 coordinates.  If null and clobAtt != null then the value clobAtt.length() 
     *                 will be used instead.
     * @param retrieveFromDatabase  Whether or not to actually get this from the database
     *                              or just return an version of it with no attributes set 
     *                              except for the primary key.
     */
    public GUSRow retrieveGUSRow(String session, GUSTable table, long pkValue, boolean retrieveEager,
				 String clobAtt, Long start, Long end)
	throws GUSNoConnectionException, GUSObjectNotUniqueException;

    // ------------------------------------------------------------------
    // UPDATE DATABASE
    // ------------------------------------------------------------------

    /**
     * Submit an object to the database.  This can result in the object and/or
     * its children being deleted, updated, or inserted, depending on the situation.  
     * If <code>deepSubmit == true</code> then all of the GUSRow's child objects
     * will also be submitted.
     *
     * @param session     A session identifier returned by <code>openConnection</code>
     * @param obj         The new or updated object to write back to the database.
     * @param deepSubmit  Whether to also submit all the child objects of <code>obj</code>
     */
    public SubmitResult submitGUSRow(String session, GUSRow obj, boolean deepSubmit, boolean newTransaction) 
	throws GUSNoConnectionException;
    
    // ------------------------------------------------------------------
    // CREATE *NEW* OBJECT(S)
    // ------------------------------------------------------------------

    /**
     * Create a <i>new</i> object, not yet connected to a row in the database.
     *
     * @param session  A session identifier returned by <code>openConnection</code>
     * @param table    GUSTable representing the table to which the new object belongs.
     * @return A new GUSRow for which <code>isNew() == true</code>
     */
    public GUSRow createGUSRow(String session, GUSTable table)
        throws GUSNoConnectionException;

    // ------------------------------------------------------------------
    // RETRIEVE PARENT/CHILD OBJECTS
    // ------------------------------------------------------------------

    // JC: All of these methods will both return the requested object and also
    // updated the supplied GUSRow appropriately.  For example, calling getParent 
    // on a row should  both return the parent object and also call addParent on the 
    // row.  *However*, note that these side effects will not be visible when 
    // invoking these methods over RMI (because RMI employs call-by-value, not 
    // call-by-reference.)

    /**
     * Retrieve a row (parent) referenced by another.
     *
     * @param session   A session identifier returned by <code>openConnection</code>
     * @param row       The row whose parent is to be retrieved.
     * @param owner     The owner of the parent object's table.
     * @param tname     The name of the parent object's table.
     * @param childAtt  The name of the referencing attribute in the child table.
     * @return The unique parent object if one exists, null otherwise.
     */
    public GUSRow retrieveParent(String session, GUSRow row, String owner, String tname, String childAtt)
        throws GUSNoConnectionException, GUSNoSuchRelationException, GUSObjectNotUniqueException;
    


    //DTB: alternate way of getting parent...will have to document.
    public GUSRow retrieveParent(String sessionId, GUSRow child, GUSTable parentTable, String childAtt)
	throws GUSNoConnectionException, GUSNoSuchRelationException, GUSObjectNotUniqueException;


    /**
     * Retrieve all the parent rows for a set of child rows.
     *
     * @param session      A session identifier returned by <code>openConnection</code>
     * @param children     The rows whose (unique) parent rows are to be returned.
     * @param parentOwner  The owner of the parent table.
     * @param parentName   The name of the parent table
     * @param childAtt  The name of the referencing attribute in the child table.
     * @return An array of size <code>children.size()</code>, containing the parents.
     */
    public GUSRow[] retrieveParentsForAllGUSRows(String session, Vector children, String parentOwner, 
						 String parentName, String childAtt)
	throws GUSNoConnectionException, GUSNoSuchRelationException, GUSObjectNotUniqueException;

    // JC: the following method should throw an exception (GUSMultipleObjectsException?) if 
    // there are multiple children that meet the specified criteria.

    /**
     * Retrieve the single row in a given table (child) that references a specified row (the parent.)
     *
     * @param session   A session identifier returned by <code>openConnection</code>
     * @param row       The row whose child is to be retrieved.
     * @param owner     The owner of the child object's table.
     * @param tname     The name of the child object's table.
     * @param childAtt  The name of the referencing attribute in the child table.
     * @return The unique child row if one exists, null otherwise.
     */
    public GUSRow retrieveChild(String session, GUSRow row, String owner, String tname, String childAtt)
	       throws GUSNoConnectionException, GUSNoSuchRelationException, GUSObjectNotUniqueException;

    /**
     * Retrieve all rows in a given table (children) that reference a specified row (the parent).
     *
     * @param session  A session identifier returned by <code>openConnection</code>
     * @param row      The row whose children are to be retrieved.
     * @param owner    The owner of the child objects' table.
     * @param tname    The name of the child objects' table.
     * @param childAtt  The name of the referencing attribute in the child table.
     */
    public Vector retrieveChildren(String session, GUSRow row, String owner, String tname, String childAtt)
	       throws GUSNoConnectionException, GUSNoSuchRelationException;


} //ServerI

// Note: for annotator interface (or any other app that uses this object layer)
//       can have remote methods to select everything we want for an RNA for example. 
//       Then we can pass back the object graph/tree.  Should do some analysis of speed. 

// JC:  More generally, we need to consider the issue of "deep" or recursive database
//      retrievals, in which we retrieve an object and a number of related or dependent
//      objects in a single method call (though probably not in a single database query)
