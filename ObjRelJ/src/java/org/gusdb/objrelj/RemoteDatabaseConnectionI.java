package org.gusdb.objrelj;

import java.rmi.Remote;
import java.rmi.RemoteException;

/**
 * RemoteDatabaseConnectionI.java
 *
 * A Remote version of DatabaseConnectionI.
 *
 * @author Dave Barkan, Jonathan Crabtree
 * @version $Revision$ $Date$ $Author$
 */
public interface RemoteDatabaseConnectionI implements DatabaseConnectionI, Remote {

    public GUSRow retrieveObject(String owner, String tname, long pk, String clobAtt, Long start, Long end)
	throws RemoteException;
    
    public Vector retrieveGusRowsFromQuery(String owner, String tname, String query)
	throws RemoteException;
    
    public SubmitResult submitObject(GUSRow obj)
	throws RemoteException;
    
    public GUSRow retrieveParent(GUSRow row, String owner, String tname, String childAtt)
	throws RemoteException;
    
    public GUSRow[] retrieveParentsForAllObjects(Vector children, String parentOwner, String parentName, String childAtt)
	throws RemoteException;
    
    public GUSRow retrieveChild(GUSRow row, String owner, String tname, String childAtt)
	throws RemoteException;
    
    public Vector retrieveChildren(GUSRow row, String owner, String tname, String childAtt)
	throws RemoteException;

} // RemoteDatabaseConnectionI
