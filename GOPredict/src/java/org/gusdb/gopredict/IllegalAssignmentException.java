package org.gusdb.gopredict;

/**
 * IllegalAssignmentException.java
 *
 * Thrown when an attempt is made to assign an Association to be both
 * 'verified' and 'rejected'.
 *
 * Created: Tue Aug 12 03:57:30 EST 2003
 *
 * @author David Barkan
 *
 */
public class IllegalAssignmentException extends Exception {
    private static final long serialVersionUID = 1L;
    public IllegalAssignmentException(String msg){ super(msg); }

}
