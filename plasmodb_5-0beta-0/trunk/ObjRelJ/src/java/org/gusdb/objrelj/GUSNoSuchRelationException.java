package org.gusdb.objrelj;

/**
 * GUSNoSuchRelationException.java
 *
 * Thrown when an attempt is made to traverse a nonexistent relationship.
 *
 * Created: Tue Mar 11 23:13:48 EST 2003
 *
 * @author Jonathan Crabtree
 * @version $Revision$ $Date$ $Author$
 */
public class GUSNoSuchRelationException extends GUSException implements java.io.Serializable {
    public GUSNoSuchRelationException(String msg){ super(msg); }
}
