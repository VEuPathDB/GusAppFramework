package org.gusdb.objrelj;

/**
 * RemoteDatabaseConnection.java
 *
 * A generic implementation of RemoteDatabaseConnectionI that acts
 * as a wrapper class to convert a non-remote DatabaseConnectionI
 * into a RemoteDatabaseConnectionI.
 *
 * @author Dave Barkan, Jonathan Crabtree
 * @version $Revision$ $Date$ $Author$
 */
public class RemoteDatabaseConnection extends UnicastRemoteObject, implements RemoteDatabaseConnectionI {

    // ------------------------------------------------------------------
    // Instance variables
    // ------------------------------------------------------------------

    /**
     * The non-remote database connection used to do the actual work.
     */
    protected DatabaseConnectionI localConn;

    // ------------------------------------------------------------------
    // Constructors
    // ------------------------------------------------------------------
    
    public RemoteDatabaseConnection(DatabaseConnectionI conn) {
	this.localConn = conn;
    }

    // ------------------------------------------------------------------
    // RemoteDatabaseConnectionI
    // ------------------------------------------------------------------

    public GUSRow retrieveObject(String owner, String tname, long pk, String clobAtt, Long start, Long end)
	throws RemoteException 
    {
	return localConn.retrieveObject(owner, tname, pk, clobAtt, start, end);
    }
    
    public Vector retrieveGusRowsFromQuery(String owner, String tname, String query)
	throws RemoteException
    {
	return localConn.retrieveGusRowsFromQuery(owner, tname, query);
    }
    
    public SubmitResult submitObject(GUSRow obj)
	throws RemoteException
    {
	return localConn.submitObject(obj);
    }
    
    public GUSRow retrieveParent(GUSRow row, String owner, String tname, String childAtt)
	throws RemoteException
    {
	return localConn.retrieveParent(row, owner, tname, childAtt);
    }
    
    public GUSRow[] retrieveParentsForAllObjects(Vector children, String parentOwner, String parentName, String childAtt)
	throws RemoteException
    {
	return localConn.retrieveParentsForAllObjects(children, parentOwner, parentName, childAtt);
    }
    
    public GUSRow retrieveChild(GUSRow row, String owner, String tname, String childAtt)
	throws RemoteException
    {
	return localConn.retrieveChild(row, owner, tname, childAtt);
    }

    public Vector retrieveChildren(GUSRow row, String owner, String tname, String childAtt)
	throws RemoteException
    {
	return localConn.retrieveChildren(row, owner, tname, childAtt);
    }

} // RemoteDatabaseConnection
