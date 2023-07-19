/*
 * Created on Feb 2, 2005
 */
package org.gusdb.dbadmin.exception;

/**
 * @author msaffitz
 * @version $Revision$ $Date$
 */
public class NonExistentObjectException extends Exception {


    private static final long serialVersionUID = 1L;

    public NonExistentObjectException() {
        super();
    }

    public NonExistentObjectException(String message) {
        super(message);
    }

    public NonExistentObjectException(String message, Throwable cause) {
        super(message, cause);
    }

    public NonExistentObjectException(Throwable cause) {
        super(cause);
    }

}
