/**
 * GoResultSet.java
 * 
 * A wrapper class for a two dimensional array.  Each row in the array
 * represents information for one Go Term, of the form [realGoId][GusGoId][childGusId].
 * Best used as a way to feed data into the constructor for a GoGraph to be converted
 * into GoTerm Objects.
 *
 * Created Wed July 23 14:28:30 2003
 *
 * @author David Barkan
 *
 */

package org.gusdb.gopredict;

import java.io.*;
import java.util.*;
import org.gusdb.gopredict.*;


public class GoResultSet{


    // ------------------------------------------------------------------
    // Static Variables
    // ------------------------------------------------------------------
    
    /**
     * If a GO Term in the result set has no children, pass this value as the
     * child go ID to the GoResultSet to indicate such.
     */
    public static final int NULL_CHILD_ID = -999;
    

    // ------------------------------------------------------------------
    // Instance Variables
    // ------------------------------------------------------------------

    /**
     * The vector that tracks all Go Terms; each entry in the vector is another
     * vector as described above.
     */
    Vector allGoTerms;

    // ------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------

    /**
     * Basic constructor; just initializes the object
     */
    public GoResultSet(){
	allGoTerms = new Vector();
    }

    // ------------------------------------------------------------------
    // Public Methods
    // ------------------------------------------------------------------

    /**
     * Adds info for one Go Term, places in appropriate objects, puts those
     * objects in a vector and adds to this GoResultSet.
     */

    public void addGoTermInfo(String realGoId, int gusId, int childGusId){

	Integer bigGusId = new Integer(gusId);

	Integer bigChildGusId = null;
	if (childGusId != NULL_CHILD_ID){
	     bigChildGusId = new Integer(childGusId);
	}
	Vector thisGoTerm = new Vector();
	thisGoTerm.add(realGoId);
	thisGoTerm.add(bigGusId);
	thisGoTerm.add(bigChildGusId);
	allGoTerms.add(thisGoTerm);
    }

    /**
     * Returns the GO Info Vector at the specified position of this GoResultSet.
     */
    public Object get(int i){
	return allGoTerms.get(i);
    }

    /**
     * Returns the size of this GoResultSet.
     */

    public int size(){
	return allGoTerms.size();
    }

}
