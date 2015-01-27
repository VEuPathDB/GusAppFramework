package org.gusdb.objrelj;

/**
 * GUSObjectNotUniqueException.java
 *
 * Thrown when an operation that is supposed to uniquely identify 
 * a single object/database row instead finds multiple rows.
 *
 * Created: Tue Mar 11 23:17:09 EST 2003
 *
 * @author Jonathan Crabtree
 * @version $Revision$ $Date$ $Author$
 */
public class GUSObjectNotUniqueException extends GUSException implements java.io.Serializable {
    private static final long serialVersionUID = 1L;
    public GUSObjectNotUniqueException(String msg){ super(msg); }
}
