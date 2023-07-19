package org.gusdb.objrelj;

/**
 * GUSInvalidPrimaryKeyException
 *
 * Thrown when an attempt is made to perform an operation that requires a primary key
 * on a new GUSRow.
 *
 * Created: Thurs Jan 8 11:57:30 EST 2004
 *
 * @author Dave Barkan
 */
public class GUSInvalidPrimaryKeyException extends GUSException implements java.io.Serializable {
    private static final long serialVersionUID = 1L;
    public GUSInvalidPrimaryKeyException(String msg){ super(msg); }
}
