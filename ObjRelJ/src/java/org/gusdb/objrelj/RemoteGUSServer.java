package org.gusdb.objrelj;

import java.util.*;
import java.sql.*;
import java.rmi.Remote;
import java.rmi.RemoteException;

/**
 * RemoteGUSServer.java
 *
 * A <B>remote</B> implementation of GUSServerI
 *
 * The RMI remote interface for a RemoteGUSServer; a RemoteGUSServer
 * is a factory object that applications can use to connect to a GUS
 * database instance and then create and update GUS objects (i.e., 
 * objects that subclass GUSRow.)
 *
 * Created: Wed May 15 12:10:02 2002
 *
 * @author Sharon Diskin, Dave Barkan, Jonathan Crabtree
 * @version $Revision$ $Date$ $Author$ 
 */
public interface RemoteGUSServer extends Remote {

    // JC: need to document how the use of the object cache affects the semantics of these methods

    // ------------------------------------------------------------------
    // SESSION MANAGEMENT
    // ------------------------------------------------------------------

    /**
     * Open a connection to a GUS database instance, establishing a session.
     *
     * @param user     A GUS login/username from core.UserInfo.login.
     * @param password The password that corresponds to <code>usr</code> in core.UserInfo.
     * @return A session string that can be passed to the other methods in this class.
     */
    public String openConnection(String user, String password) throws RemoteException, GUSInvalidLoginException;

    /**
     * Close an existing session's database connection.
     * 
     * @param session  A session identifier returned by <code>openConnection</code>
     */
    public void closeConnection(String session) throws RemoteException, GUSNoConnectionException;

    /**
     * Returns a list of the actions performed so far in a session.
     *
     * @param session  A session identifier returned by <code>openConnection</code>
     * @return A List of Strings detailing the actions performed so far in the session.
     */
    public List getSessionHistory(String session) throws RemoteException, GUSNoConnectionException;

    // ------------------------------------------------------------------
    // RETRIEVE FROM DATABASE OR CACHE
    // ------------------------------------------------------------------

    /**
     * Retrieve a single object from the database or cache.
     *
     * @param session  A session identifier returned by <code>openConnection</code>
     * @param owner    The owner of the object's table.
     * @param tname    The object's table.
     * @param pk       Primary key value for the row of interest.
     */
    public GUSRow retrieveObject(String session, String owner, String tname, long pk)
        throws RemoteException, GUSNoConnectionException;

    /**
     * Retrieve all objects from a single table.
     *
     * @param session  A session identifier returned by <code>openConnection</code>
     * @param owner    The owner of the table to query.
     * @param tname    The table to query.
     * @return A Vector of GUSRow objects.
     */
    public Vector retrieveAllObjects(String session, String owner, String tname)
        throws RemoteException, GUSNoConnectionException;

    /**
     * Retrieve a set of GUSRow objects using an SQL query.  It is assumed that the objects
     * will all be instances of the same subclass of GUSRow.
     *
     * @param session  A session identifier returned by <code>openConnection</code>
     * @param query    An SQL query that does a select * from a single table.
     * @param owner    The owner of the table that the query selects from.
     * @param tname    The name of the table that the query selects from.
     * @return A Vector of GUSRow objects corresponding to the rows selected from 
     */
    public Vector retrieveGusRowsFromQuery(String session, String query, String owner, String tname)
	throws RemoteException, GUSNoConnectionException;

    // ------------------------------------------------------------------
    // RETRIEVE FROM DATABASE OR CACHE - OBJECTS WITH CLOB VALUES
    // ------------------------------------------------------------------
    
    // JC: This method should be further generalized to handle the case where 
    // an object has *multiple* CLOB values.  We should also add an argument to
    // the retrieveObject methods to allow the user to specify a set of attributes
    // that should not be retrieved at all e.g., allowing us to skip reading 
    // CLOB values that aren't needed.  However, this may require some modification
    // to the GUSRow, so that we know which attributes weren't retrieved (versus
    // those that really are null in the database.)
    
    /**
     * Retrieve a single object from the database, but only retrieve as much of the
     * specified CLOB value as indicated by <code>start</code> and <code>end</code>.
     * To retrieve the entire CLOB value, either set both <code>start</code> and
     * <code>end</code> to NULL, or use the the standard <code>retrieveObject</code>
     * method instead.
     *
     * @param session  A session identifier returned by <code>openConnection</code>
     * @param owner    The owner of the object's table.
     * @param tname    The object's table.
     * @param pk       Primary key value for the row of interest.
     * @param clobAtt  The name of the CLOB-containing attribute.
     * @param start    Start coordinate of the CLOB range to retrieve and cache.  If null 
     *                 the value 0 will be used instead.
     * @param end      End coordinate of the CLOB range to retrieve and cache.  If null
     *                 clobAtt.length() will be used instead.
     */
    public GUSRow retrieveObject(String session, String owner, String tname, long pk, 
				 String clobAtt, Long start, Long end)
	throws RemoteException, GUSNoConnectionException;

    // ------------------------------------------------------------------
    // UPDATE DATABASE
    // ------------------------------------------------------------------

    /**
     * Submit an object to the database.  This can result in the object being
     * deleted, updated, or inserted, depending on the situation.
     *
     * @param session  A session identifier returned by <code>openConnection</code>
     * @param obj      The new or updated object to write back to the database.
     * @return The number of updated and/or inserted rows.
     */
    public int submitObject(String session, GUSRow obj)
        throws RemoteException, GUSNoConnectionException, SQLException;

    // ------------------------------------------------------------------
    // CREATE *NEW* OBJECT(S)
    // ------------------------------------------------------------------

    /**
     * Create a <i>new</i> object, not yet connected to a row in the database.
     *
     * @param session  A session identifier returned by <code>openConnection</code>
     * @param owner    Owner of the table in which to the new object belongs.
     * @param tname    Name of the table in which the new object belongs.
     * @return A new GUSRow for which <code>isNew() == true</code>
     */
    public GUSRow createObject(String session, String owner, String tname)
        throws RemoteException, GUSNoConnectionException;

    // ------------------------------------------------------------------
    // RETRIEVE PARENT/CHILD OBJECTS
    // ------------------------------------------------------------------

    // JC: I assume that all of these methods both return the requested object *and*
    // also update the provided GUSRow.  i.e., calling getParent on a row should 
    // both return the parent object and also call addParent on the row.
    // This is a crucial issue, because the side-effects (i.e. calling addParent or
    // addChild on the original row) will *not* be visible over RMI, and so the client
    // application will be relying on the return values.  This is the main reason that 
    // we're planning to refactor this interface.  It will be changed into an 
    // interface that *only* does the db access, without modifying the objects.  i.e.,
    // it cannot depend at all on call by reference.  A separate interface will be 
    // the interface that the client application sees, and it will be allowed to use
    // call by reference semantics.  This second interface/object will use the first
    // interface/object to perform all the actions requiring db access.

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
        throws RemoteException, GUSNoConnectionException;

    // JC: this won't work over RMI because it requires call-by-reference semantics
    
    /**
     * Retrieve all the parent rows for a set of child rows.
     *
     * @param session      A session identifier returned by <code>openConnection</code>
     * @param children     The rows whose parent rows are to be returned.
     * @param parentOwner  The owner of the parent table.
     * @param parentName   The name of the parent table
     * @param childAtt  The name of the referencing attribute in the child table.
     */
    //    public void retrieveParentsForAllObjects(String session, Vector children, String parentOwner, 
    //					     String parentName, String childAtt)
    //	throws RemoteException, GUSNoConnectionException;

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
	       throws RemoteException, GUSNoConnectionException;

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
	       throws RemoteException, GUSNoConnectionException;

} //RemoteGUSServer

// Note: for annotator interface (or any other app that uses this object layer)
//       can have remote methods to select everything we want for an RNA for example. 
//       Then we can pass back the object graph/tree.  Should do some analysis of speed. 

// JC:  More generally, we need to consider the issue of "deep" or recursive database
//      retrievals, in which we retrieve an object and a number of related or dependent
//      objects in a single method call (though probably not in a single database query)
