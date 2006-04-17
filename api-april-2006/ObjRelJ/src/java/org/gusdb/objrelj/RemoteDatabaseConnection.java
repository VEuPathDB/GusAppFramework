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

    public void retrieveGUSRow(GUSRow gusRow, String clobAtt, Long start, Long end)
	throws RemoteException, GUSObjectNotUniqueException
    {
	localConn.retrieveGUSRow(gusRow, clobAtt, start, end);
    }
    
    public Vector retrieveGUSRowsFromQuery(GUSTable table, String query)
	throws RemoteException
    {
	return localConn.retrieveGUSRowsFromQuery(table, query);
    }

    public Vector runSqlQuery(String query)
	throws RemoteException
    {
	return localConn.runSqlQuery(query);
    }
    
    public SubmitResult submitGUSRow(GUSRow obj)
	throws RemoteException
    {
	return localConn.submitGUSRow(obj);
    }
    
    public Long getParentPk(GUSRow child, GUSTable parentTable, String childAtt)
    	throws RemoteException, GUSNoSuchRelationException, GUSObjectNotUniqueException{
	return localConn.getParentPk(child, parentTable, childAtt);
    }


    public GUSRow retrieveParent(GUSRow row, String owner, String tname, String childAtt)
	throws RemoteException, GUSNoSuchRelationException, GUSObjectNotUniqueException
    {
	return localConn.retrieveParent(row, owner, tname, childAtt);
    }
    
    public GUSRow[] retrieveParentsForAllGUSRows(Vector children, String parentOwner, String parentName, String childAtt)
	throws RemoteException, GUSNoSuchRelationException, GUSObjectNotUniqueException
    {
	return localConn.retrieveParentsForAllGUSRows(children, parentOwner, parentName, childAtt);
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

    public String getSubmitDate() throws RemoteException
    {
	return localConn.getSubmitDate();
    }

    public boolean commit() throws RemoteException
    {
	return localConn.commit();
    }

    public void close() 
	throws RemoteException
    {
	localConn.close();
    }

} // RemoteDatabaseConnection
