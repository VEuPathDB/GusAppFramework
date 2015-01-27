package org.gusdb.objrelj;

import java.rmi.Naming;
import java.rmi.RemoteException;

/**
 * RemoteDatabaseDriver.java
 * 
 * Implementation of DatabaseDriverI.  When this class is instantiated 
 * as an object, it connects to an instance of a RemoteDatabaseServerI 
 * (rmi) object.  The driver can then be used to retrieve remote connections
 * to the database using the remote object
 *
 * Created:Thu Apr 3 13:30:05 EST 2003
 *
 * @author Dave Barkan, Jonathan Crabtree
 * @version $Revision$ $Date$  $Author$
 */

public class RemoteDatabaseDriver implements DatabaseDriverI {

    // -----------------------------------------------------------------
    // Instance variables
    // -----------------------------------------------------------------

    /**
     * RemoteDatabaseServerI-implementing object that will accepts connection requests 
     */
    private RemoteDatabaseServerI server;
    

    // ------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------

    public RemoteDatabaseDriver(String rmiUrl){
	
	//dtb: issue of whether we want connection to RemoteJDBCServer to be persistant connection 
	//or just make when calling getConnection.  For now make persistant connection.
	
	System.out.println("Connecting to remote jdbc server at " + rmiUrl);
	
	try {
	    this.server = (RemoteDatabaseServerI)Naming.lookup(rmiUrl);
	    if (server != null){
	    }
	}
	catch (Exception e){
	    System.err.println(e.getMessage());
	    e.printStackTrace();
	    System.err.println("RemoteDatabaseDriver: did not connect to server");

	    return;
	}
    }
    
    @Override
    public DatabaseConnectionI getConnection(String gusUser, String gusPassword)
	throws GUSInvalidLoginException{
	DatabaseConnectionI remoteConn = null;
	if (server != null){
	    try {
		
		remoteConn = server.createRemoteConnection(gusUser, gusPassword);
		if (remoteConn.setCurrentUser(gusUser, gusPassword) == -1){
		   throw new GUSInvalidLoginException("Error: incorrect GUS login or password");
		}
	    } catch (RemoteException e){
		
		System.err.println(e.getMessage());
		e.printStackTrace();
	    }
	}
	else{
	    System.err.println("Error: Tried to get Database Connection without having reference to remote server");
	}
	return remoteConn;
    }
}  //RemoteDatabaseDriver.java


