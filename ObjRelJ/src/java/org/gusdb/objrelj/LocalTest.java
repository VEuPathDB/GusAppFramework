package org.gusdb.objrelj;

import java.util.*;

/**
 * LocalTest.java
 *
 * A simple test program for the Java object layer that relies
 * on a <B>local</B> JDBC connection to the database.
 *
 * @author Jonathan Crabtree
 * @version $Revision$ $Date$ $Author$
 */
public class LocalTest {

    // ------------------------------------------------------------------
    // main()
    // ------------------------------------------------------------------
    
    public static void main(String args[]) {

	if (args.length != 5) {
	    System.out.println("Usage: java org.gusdb.objrelj.LocalTest jdbcURL jdbcLogin jdbcPassword gusUser gusPassword");
	    System.exit(1);
	}
	
	// JC: Specific to Oracle thin JDBC driver
	String driverClass = "oracle.jdbc.driver.OracleDriver";

	SQLutilsI utils = new OracleSQLutils();
	String url = args[0];
	String user = args[1];
	String password = args[2];
	String gusUser = args[3];
	String gusPassword = args[4];

	DatabaseDriverI driver = new JDBCDriver(driverClass,utils,url,user,password);
	ServerI server = new GUSServer(driver);
	String s1 = null;

	// Retrieve set of existing objects
	// 
	try {
	    s1 = server.openConnection(gusUser, gusPassword);
	    Vector objs = server.retrieveAllObjects(s1, "DoTS", "SequenceType");
	    
	    System.out.println("Retrieved " + objs.size() + " objects: \n");
	    
	    Iterator i = objs.iterator();
	    while (i.hasNext()) {
		GUSRow obj = (GUSRow)i.next();
		System.out.println(obj.toString());
		System.out.println(obj.toXML());
	    }
	} catch (Throwable t) {
	    t.printStackTrace(System.err);
	}

	try {
	    server.closeConnection(s1);
	} catch (GUSNoConnectionException nce) {}
    }
}
