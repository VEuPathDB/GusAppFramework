package org.gusdb.objrelj;

/**
 * GUSInvalidLoginException.java
 *
 * Previously named GUSInvalidPasswordException; changed the name to
 * indicate that something is wrong with the supplied login
 * information, but the problem may not be restricted to the password.
 * For the security conscious, this hides from the application any 
 * information about exactly which part of the login was bogus.
 *
 * Created: Wed May 15 16 12:02:00 2002
 *
 * @author Sharon Diskin, Jonathan Crabtree
 * @version $Revision$ $Date$ $Author$ 
 */
public class GUSInvalidLoginException extends GUSException implements java.io.Serializable {
    private static final long serialVersionUID = 1L;
    public GUSInvalidLoginException(String msg){ super(msg); }
}

