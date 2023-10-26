/**
 * GoGraph.java
 *
 * Created Wednesday July 23 14:21:30 2003
 *
 * @author David Barkan
 */

package org.gusdb.gopredict;

import java.util.Hashtable;

public class GoGraph {


    // ------------------------------------------------------------------
    // Static variables
    // ------------------------------------------------------------------

    // ------------------------------------------------------------------
    // Instance variables
    // ------------------------------------------------------------------

    /**
     * Hashtable tracking GoTerms; keys are Strings of real GO Ids (in 
     * GO:XXXXXX format) and values are GoTerms.
     */
    Hashtable<String, GoTerm> realIdHash;

    /**
     * Hashtable tracking GoTerms; keys are Integers of GO Ids in GUS 
     * and values are GoTerms.
     */
    Hashtable<Integer, GoTerm> gusIdHash;


    /**
     * GoTerm representing the root term of the Molecular Function 
     * branch of the GO Hierarchy.
     */
    GoTerm rootTerm;


    // ------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------

    /**
     * Make a Go Graph from the given GoResultSet (see GoResultSet.java for format).
     */

    //dtb: port of newFromResultSet in perl version
    public GoGraph(GoResultSet grs, String functionRootGoId){

	realIdHash = new Hashtable<>();
	gusIdHash = new Hashtable<>();

	for (int i = 0; i < grs.size(); i ++){

	    GoTermInfo nextGoTermInfo = grs.get(i);
	    String realGoId = nextGoTermInfo.realGoId;
	    Integer gusId = nextGoTermInfo.gusId;
	    Integer childGusId = nextGoTermInfo.childGusId;

	    GoTerm goTerm = makeGoTerm(gusId, realGoId, functionRootGoId);
	    //GoTerm tempGoTerm = getGoTermFromGusGoId(gusId.intValue());
	    //if (tempGoTerm == null){ System.out.println ("Go term for gusId " + gusId.intValue() + " is null");}
	    if (childGusId != null){
		GoTerm childGoTerm = makeGoTerm(childGusId, null, functionRootGoId);
		goTerm.addChild(childGoTerm);
	    }
	}
    }
		   


    // ------------------------------------------------------------------
    // Public Methods
    // ------------------------------------------------------------------

    /** 
     * Factory method that returns a GO Term given the necessary information,
     * creating a new one if necessary.
     *
     * It uses the GOTerm's gusId to do the check; the realId may be null if
     * this method is being called to make a child GO Term.
     */
    public GoTerm makeGoTerm(Integer gusId, String realId, String functionRootGoId){

	GoTerm goTerm = getGoTermFromGusGoId(gusId.intValue());

	if (goTerm != null){
	    if (goTerm.getRealId() == null && realId != null){  //previously added child with no realId set yet
		goTerm.setRealId(realId);
		addGoTermToRealIdHash(goTerm);
	    }
	}
	else{

	    goTerm = new GoTerm(realId, gusId.intValue());
	    //	    System.out.println("adding go term to hashes: " + goTerm.toString());
	    addGoTerm(goTerm);
	    if (realId != null){
		if (realId.equals(functionRootGoId)){
		    setRootTerm(goTerm);
		    System.err.println("set root term");
		}
	    }
	}

	return goTerm;
    }

    public GoTerm getGoTermFromRealGoId(String realGoId){
	GoTerm goTerm = null;
	goTerm = realIdHash.get(realGoId);
	return goTerm;
    }

    public GoTerm getGoTermFromGusGoId(int gusGoId){

	GoTerm goTerm = gusIdHash.get(Integer.valueOf(gusGoId));
	return goTerm;
    }

    public void addGoTerm(GoTerm goTerm){

	Integer gusId = Integer.valueOf(goTerm.getGusId());
	String realId = goTerm.getRealId();

	if (realId != null){ //if not adding as a child

	    realIdHash.put(realId, goTerm);
	}
	gusIdHash.put(gusId, goTerm);
    
    }

    public void setRootTerm(GoTerm root){
	this.rootTerm = root;
    }
    
    public GoTerm getRootTerm(){
	return rootTerm;
    }


    @Override
    public String toString(){
	
	return getRootTerm().toString("\t");
	
    }

    // ------------------------------------------------------------------
    // Private Methods
    // ------------------------------------------------------------------


    private void addGoTermToRealIdHash(GoTerm goTerm){
	String realId = goTerm.getRealId();
	realIdHash.put(realId, goTerm);
    }

    @SuppressWarnings("unused")
    private void addGoTermToGusIdHash(GoTerm goTerm){
	Integer gusId = Integer.valueOf(goTerm.getGusId());
	gusIdHash.put(gusId, goTerm);
    }

}
