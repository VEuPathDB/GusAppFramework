/*
 * Created on Feb 2, 2005
 */
package org.gusdb.dbadmin.exception;

/**
 * @author msaffitz
 * @version $Revision$ $Date$
 */
public class ColumnCountException extends Exception {

    
    public ColumnCountException() {
        super();
    }
    public ColumnCountException(String message) {
        super(message);
    }
    public ColumnCountException(String message, Throwable cause) {
        super(message, cause);
    }
    public ColumnCountException(Throwable cause) {
        super(cause);
    }
}
