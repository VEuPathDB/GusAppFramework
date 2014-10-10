package org.gusdb.objrelj;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.rmi.Naming;
import java.rmi.RemoteException;
import java.rmi.server.UnicastRemoteObject;
import java.util.Properties;

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

    private static final long serialVersionUID = 1L;

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


    @Override
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
	
	if (args.length != 1){
	    System.err.println("Usage: java " +
			       "org.gusdb.objrelj.RemoteJDBCServer propertiesFilePath");
	    System.exit(1); //force an exit because there may be hanging RMI threads.
	}
	FileInputStream fis = null;
	String propsFilePath = args[0];
	File propsFile = new File(propsFilePath);
	try {
	    fis = new FileInputStream(propsFile);
	}
	catch (FileNotFoundException fe){
	    fe.getMessage();
	    fe.printStackTrace();
	}
	Properties props = new Properties();
	
	try {
	    props.load(fis);
	}
	catch (IOException ie){
	    System.err.println(ie.getMessage());
	    ie.printStackTrace();
	}

	String jdbcUrl = props.getProperty("jdbcUrl");
	String jdbcUser = props.getProperty("jdbcUser");
	String jdbcPassword = props.getProperty("jdbcPassword");
	String rmiUrl = props.getProperty("rmiUrl");
	
	String driverClass = "oracle.jdbc.driver.OracleDriver";

	SQLutilsI utils = new OracleSQLutils();
	
	
	//dtb: need to decide how to handle database specific implementation here.
	//For now, assume using an oracle connection.  Later, maybe say RemoteJDBCServer can have different
	//drivers for different databases and the client can specify which database it wants
	//and the appropriate driver can return the connection with the correct SQLutils, 
	//and driver class
	
	System.err.println("attempting to connect with driverClass " + driverClass + " url " + jdbcUrl + " user " + jdbcUser + " password " + jdbcPassword);	
	DatabaseDriverI jdbcDriver = new JDBCDriver(driverClass, utils, jdbcUrl, jdbcUser, jdbcPassword);
	System.err.println("made connection, doing rmi");
	try {
	    
	    RemoteJDBCServer server = new RemoteJDBCServer(jdbcDriver);
	    
	    //dtb: decide exact naming convention
	    Naming.rebind(rmiUrl, server);
	    System.out.println(rmiUrl + " is bound in RMIRegistry and ready to serve.");
	} 
	catch ( Exception e ) {
	    System.err.println(e);
	    System.err.println("Usage: java " +
			       "org.gusdb.objrelj.RemoteJDBCServer propertiesFilePath");
	    System.exit(1); //force an exit because there may be hanging RMI threads.
	}
    }
    
    
} //RemoteJDBCServer





