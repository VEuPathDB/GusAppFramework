package org.gusdb.dbadmin.exception;
/*
 * Created on Feb 2, 2005
 */

/**
 * @author msaffitz
 * @version $Revision$ $Date$
 */
public class NoPrimaryKeyException extends Exception {

    private static final long serialVersionUID = 1L;

    public NoPrimaryKeyException() {
        super();
    }
    public NoPrimaryKeyException(String message) {
        super(message);
    }
    public NoPrimaryKeyException(String message, Throwable cause) {
        super(message, cause);
    }
    public NoPrimaryKeyException(Throwable cause) {
        super(cause);
    }
}
