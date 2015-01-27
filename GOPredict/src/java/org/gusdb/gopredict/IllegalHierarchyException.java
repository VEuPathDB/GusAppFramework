package org.gusdb.gopredict;

/**
 * IllegalHierarchyException.java
 *
 * Thrown when an attempt is made to assign an 'is not' Association as an ancestor of an 
 * Association that has been manually reviewed and verified.
 *
 * Created: Tue Aug 12 03:57:30 EST 2003
 *
 * @author David Barkan
 *
 */
public class IllegalHierarchyException extends Exception {
    private static final long serialVersionUID = 1L;
    public IllegalHierarchyException(String msg){ super(msg); }

}
