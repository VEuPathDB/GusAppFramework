package org.gusdb.objrelj;

/**
 * GUSNoConnectionException.java
 *
 * An exception thrown by GUSServer when an operation is attempted
 * that requires a database connection, and none is available (e.g.,
 * because an application is working in offline mode.)
 *
 * Created: Wed May 15 16 12:02:00 2002
 *
 * @author Sharon Diskin
 * @version $Revision$ $Date$ $Author$ 
 */
public class GUSNoConnectionException extends GUSException implements java.io.Serializable {
    private static final long serialVersionUID = 1L;
    public GUSNoConnectionException(String msg){ super(msg); }
}

