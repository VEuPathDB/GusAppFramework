package org.gusdb.objrelj;

import java.rmi.server.*;
import java.rmi.*;

/**
 * RemoteJDBCServer.java
 *
 * A simple implementation of RemoteDatabaseServerI.  The server 
 * has a DatabaseDriverI that produces the remote database connection; 
 * it takes command line arguments that specify the JDBC url, login, 
 * and password for the driver.  Currently the server produces
 * connections to oracle databases.
 *
 * Created:Thu Apr 3 15:30:05 EST 2003
 *
 * @author Dave Barkan, Jonathan Crabtree
 * @version $Revision$ $Date$  $Author$
 */

public class RemoteJDBCServer extends UnicastRemoteObject implements RemoteDatabaseServerI{

    // -----------------------------------------------------------------
    // Instance variables
    // -----------------------------------------------------------------

    /**
     * Database Driver that actually produces requested connections
     */
    protected DatabaseDriverI driver;

    // ------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------

    /**
     * @param driver  driver for this new RemoteJDBCServer
     */
    public RemoteJDBCServer(DatabaseDriverI driver) throws RemoteException {
	
	super();
 	this.driver = driver;
    } 


    public DatabaseConnectionI createRemoteConnection(String gusUser, String gusPassword) 
	throws RemoteException{
	
	
	RemoteDatabaseConnectionI remoteConn = null;
	try {
	    DatabaseConnectionI localConn = driver.getConnection(gusUser, gusPassword);
	    remoteConn = new RemoteDatabaseConnection(localConn);
	}
	catch (GUSInvalidLoginException e){

	    System.err.println(e.getMessage());
	    e.printStackTrace();
	}
	return remoteConn;
    } 

    // ------------------------------------------------------------------
    // main()
    // ------------------------------------------------------------------
    
    public static void main(String[] args){
	
	if (args.length != 3){
	    System.err.println("Usage: java [-Dremotejdbcservername=<name>] " +
			       "org.gusdb.objrelj.RemoteJDBCServer jdbcURL jdbcLogin jdbcPassword");
	    System.exit(1); //force an exit because there may be hanging RMI threads.
	}
	
	String jdbcUrl = args[0];
	String jdbcUser = args[1];
	String jdbcPassword = args[2];
	
	String driverClass = "oracle.jdbc.driver.OracleDriver";

	SQLutilsI utils = new OracleSQLutils();
	
	
	//dtb: need to decide how to handle database specific implementation here.
	//For now, assume using an oracle connection.  Later, maybe say RemoteJDBCServer can have different
	//drivers for different databases and the client can specify which database it wants
	//and the appropriate driver can return the connection with the correct SQLutils, 
	//and driver class
	
	
	DatabaseDriverI jdbcDriver = new JDBCDriver(driverClass, utils, jdbcUrl, jdbcUser, jdbcPassword);
	
	try {
	    
	    RemoteJDBCServer server = new RemoteJDBCServer(jdbcDriver);
	    
	    //dtb: decide exact naming convention
	    String name = System.getProperty("remotejdbcservername", "rmi://localhost/RemoteJDBCServer_1") ;
	    Naming.rebind(name, server);
	    System.out.println(name + " is bound in RMIRegistry and ready to serve.");
	} 
	catch ( Exception e ) {
	    System.err.println(e);
	    System.err.println("Usage: java [-Dremotejdbcservername=<name>] " +
			       "org.gusdb.objrelj.RemoteJDBCServer jdbcURL jdbcLogin jdbcPassword");
	    System.exit(1); //force an exit because there may be hanging RMI threads.
	}
    }
    
    
} //RemoteJDBCServer





