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

import java.util.Vector;


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
    Vector<GoTermInfo> allGoTerms;

    // ------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------

    /**
     * Basic constructor; just initializes the object
     */
    public GoResultSet(){
	allGoTerms = new Vector<>();
    }

    // ------------------------------------------------------------------
    // Public Methods
    // ------------------------------------------------------------------

    /**
     * Adds info for one Go Term, places in appropriate objects, puts those
     * objects in a vector and adds to this GoResultSet.
     */

    public void addGoTermInfo(String realGoId, int gusId, int childGusId){

	Integer bigGusId = Integer.valueOf(gusId);

	Integer bigChildGusId = null;
	if (childGusId != NULL_CHILD_ID){
	     bigChildGusId = Integer.valueOf(childGusId);
	}
	GoTermInfo thisGoTerm = new GoTermInfo();
	thisGoTerm.realGoId = realGoId;
	thisGoTerm.gusId = bigGusId;
	thisGoTerm.childGusId = bigChildGusId;
	allGoTerms.add(thisGoTerm);
    }

    /**
     * Returns the GO Info Vector at the specified position of this GoResultSet.
     */
    public GoTermInfo get(int i){
	return allGoTerms.get(i);
    }

    /**
     * Returns the size of this GoResultSet.
     */

    public int size(){
	return allGoTerms.size();
    }

}
