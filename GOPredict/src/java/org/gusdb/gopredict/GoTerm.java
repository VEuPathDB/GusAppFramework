/**
 * GoTerm.java
 *
 * Created: Wed Jul 22 14:03:30 2003
 *
 * @author David Barkan
 *
 */
package org.gusdb.gopredict;

import java.util.Vector;

public class GoTerm  {

    
    // ------------------------------------------------------------------
    // Static variables
    // ------------------------------------------------------------------

    

    // ------------------------------------------------------------------
    // Instance variables
    // ------------------------------------------------------------------

    /**
     * The GO Id (GO:XXXXXXX) assigned to this GO Term.
     */
    String realId;

    /**
     * The Id in GUS for this GO Term.
     * dtb: maybe possible to filter this out to enhance portability?
     */
    int gusId;
    
    /**
     * Vectors representing relationships with other GO Terms in the GO Hierarchy.
     */
    Vector<GoTerm> children;
    Vector<GoTerm> parents;




    // ------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------

    public GoTerm(String realId, int gusId){

	setRealId(realId);
	setGusId(gusId);
	children = new Vector<>();
	parents = new Vector<>();

    }

    // ------------------------------------------------------------------
    // Public Methods
    // ------------------------------------------------------------------

    public int getGusId(){
	return gusId;
    }

    public String toString(String tab){
	
	String myself = new String(tab + "GusGoID: " + gusId + " RealGoId: " + realId + "\n");
	
	//	    String nextChildString = nextChild.toString(tab + "\t");
	// myself = myself.concat(nextChildString);
	
	return myself;
    }

    public void setGusId(int gusId){
	this.gusId = gusId;
    }

    public String getRealId(){
	return realId;
    }

    public void setRealId(String realId){
	this.realId = realId;
    }

    public Vector<GoTerm> getParents(){
	return parents;
    }

    public Vector<GoTerm> getChildren(){
	return children;
    }

    /**
     * Add this GoTerm as a child to me (adds myself as a parent for the child too).
     */
     public void addChild(GoTerm child){

	children.add(child);
	child.addParent(this);
    }
	
    // ------------------------------------------------------------------
    // Protected Methods
    // ------------------------------------------------------------------
    
    /**
     * Add a GoTerm to the list of this GoTerm's parents.
     * Only called from the method 'addChild', which is the public method
     * used to set a relationship between two GoTerms.
     */
    protected void addParent(GoTerm parent){
	parents.add(parent);
    }

    // ------------------------------------------------------------------
    // Private Methods
    // ------------------------------------------------------------------




}
