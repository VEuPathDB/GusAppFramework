package org.gusdb.objrelj;

/**
 * JDBCDriver.java
 *
 * A simple implementation of DatabaseDriverI that works by 
 * making direct JDBC connections from the local host to the
 * target database.  The JDBC URL, username, and password are
 * specified when the driver is created and the same connection
 * parameters are used by all connections created by this 
 * driver.  More sophisticated versions of this class might use
 * different connection parameters depending on which GUS user
 * account is supplied to the getConnection method.
 *
 * Created:Tue Mar 11 20:29:01 EST 2003
 *
 * @author Jonathan Crabtree
 * @version $Revision$ $Date$ $Author$
 */
public class JDBCDriver implements DatabaseDriverI {
    
    // ------------------------------------------------------------------
    // Instance variables
    // ------------------------------------------------------------------
    
    /**
     * SQLUtils to be used by all connections created by this object.
     */
    protected SQLutilsI utils;

    /**
     * JDBC URL to be used by all connections created by this object.
     */
    protected String url;

    /**
     * JDBC username to be used by all connections created by this object.
     */
    protected String user;
    
    /**
     * JDBC password to be used by all connections created by this object.
     */
    protected String password;

    // ------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------
    
    /**
     * @param jdbcDriverClass   Name of the JDBC driver class.
     */
    public JDBCDriver(String jdbcDriverClass, SQLutilsI utils, String url, String user, String password) 
    {
	try {
	    System.out.println("JDBCDriver: creating new with driverclass: " + jdbcDriverClass);
	    Class.forName(jdbcDriverClass);
	} 
	catch (ClassNotFoundException cnfe) {}

	this.utils = utils;
	this.url = url;
	this.user = user;
	this.password = password;
    }

    // ------------------------------------------------------------------
    // DatabaseDriverI
    // ------------------------------------------------------------------

    //
    // This implementation ignores its arguments
    //
    @Override
    public DatabaseConnectionI getConnection(String gusUser, String gusPassword) {
	return new JDBCDatabaseConnection(utils, url, this.user, this.password);
    }

}
