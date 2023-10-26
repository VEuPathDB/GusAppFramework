package org.gusdb.objrelj;

/**
 * DatabaseDriverI.java
 *
 * Analogous to a JDBC driver, this object allows one to make 
 * connections to a GUS database.
 *
 * @author Jonathan Crabtree
 * @version $Revision$ $Date$ $Author$
 */
public interface DatabaseDriverI {

    /**
     * @param user     A valid GUS username from core.UserInfo.login.
     * @param password The password for <code>user</code>
     *
     * @return A new database connection.
     */
    public DatabaseConnectionI getConnection(String user, String password)
	throws GUSInvalidLoginException;

}
