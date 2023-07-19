package org.gusdb.objrelj;

/**
 * GUSException.java
 *
 * A superclass for all GUS-specific exceptions.
 *
 * Created: Wed May 15 16 12:02:00 2002
 *
 * @author Sharon Diskin
 * @version $Revision$ $Date$ $Author$
 */
public class GUSException extends Exception implements java.io.Serializable {
    private static final long serialVersionUID = 1L;
    public GUSException(String msg){ super(msg); }
}

