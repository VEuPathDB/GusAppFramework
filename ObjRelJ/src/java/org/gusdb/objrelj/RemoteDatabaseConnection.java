package org.gusdb.objrelj;

import java.rmi.*;
import java.rmi.server.*;

import java.util.Vector;

/**
 * RemoteDatabaseConnection.java
 *
 * A generic implementation of RemoteDatabaseConnectionI; it acts
 * as a wrapper class to convert a non-remote DatabaseConnectionI
 * into a RemoteDatabaseConnectionI.
 *
 * @author Dave Barkan, Jonathan Crabtree
 * @version $Revision$ $Date$ $Author$
 */
public class RemoteDatabaseConnection extends UnicastRemoteObject implements RemoteDatabaseConnectionI {

    // ------------------------------------------------------------------
    // Instance variables
    // ------------------------------------------------------------------

    /**
     * The <B>local</B> database connection used to do the actual work.
     */
    protected DatabaseConnectionI localConn;

    // ------------------------------------------------------------------
    // Constructors
    // ------------------------------------------------------------------
    
    public RemoteDatabaseConnection(DatabaseConnectionI conn) 
	throws RemoteException 
    {
	this.localConn = conn;
    }

    // ------------------------------------------------------------------
    // RemoteDatabaseConnectionI
    // ------------------------------------------------------------------

    // All of these methods are simply delegated to <code>conn</code>

    public SQLutilsI getSqlUtils()
	throws RemoteException 
    { 
	return localConn.getSqlUtils(); 
    }

    public long setCurrentUser(String user, String password) 
	throws RemoteException 
    {
	return localConn.setCurrentUser(user, password);
    }

    public long getCurrentUserId()
	throws RemoteException 
    {
	return localConn.getCurrentUserId();
    }

    public GUSRow retrieveObject(String owner, String tname, long pk, String clobAtt, Long start, Long end)
	throws RemoteException, GUSObjectNotUniqueException
    {
	return localConn.retrieveObject(owner, tname, pk, clobAtt, start, end);
    }
    
    public Vector retrieveObjectsFromQuery(String owner, String tname, String query)
	throws RemoteException
    {
	return localConn.retrieveObjectsFromQuery(owner, tname, query);
    }
    
    public SubmitResult submitObject(GUSRow obj)
	throws RemoteException
    {
	return localConn.submitObject(obj);
    }
    
    public GUSRow retrieveParent(GUSRow row, String owner, String tname, String childAtt)
	throws RemoteException, GUSNoSuchRelationException, GUSObjectNotUniqueException
    {
	return localConn.retrieveParent(row, owner, tname, childAtt);
    }
    
    public GUSRow[] retrieveParentsForAllObjects(Vector children, String parentOwner, String parentName, String childAtt)
	throws RemoteException, GUSNoSuchRelationException, GUSObjectNotUniqueException
    {
	return localConn.retrieveParentsForAllObjects(children, parentOwner, parentName, childAtt);
    }
    
    public GUSRow retrieveChild(GUSRow row, String owner, String tname, String childAtt)
	throws RemoteException, GUSNoSuchRelationException, GUSObjectNotUniqueException
    {
	return localConn.retrieveChild(row, owner, tname, childAtt);
    }

    public Vector retrieveChildren(GUSRow row, String owner, String tname, String childAtt)
	throws RemoteException, GUSNoSuchRelationException
    {
	return localConn.retrieveChildren(row, owner, tname, childAtt);
    }

    public void close() 
	throws RemoteException
    {
	localConn.close();
    }

} // RemoteDatabaseConnection
