package org.gusdb.objrelj;

import java.rmi.Remote;
import java.rmi.RemoteException;

/**
 * RemoteDatabaseServerI.java
 * 
 * This is an RMI interface that will be implemented by objects acting
 * remotely.  The server acts as a factory object to listen 
 * for and return requests for remote database connections.
 *
 * Created:Thu Apr 3 14:30:05 EST 2003
 *
 * @author Dave Barkan, Jonathan Crabtree
 * @version $Revision$ $Date$  $Author$
 */

public interface RemoteDatabaseServerI extends Remote{


    // ------------------------------------------------------------------
    // Public Methods
    // ------------------------------------------------------------------
    /**
     * Create remote connection to database.
     *
     * @return reference to remote object that can then be used to query database
     * @param gusUser   valid user login to GUS.
     * @param gusPassword   valid password for given user.
     */
    public DatabaseConnectionI createRemoteConnection (String gusUser, String gusPassword) 
	throws RemoteException;   

}
