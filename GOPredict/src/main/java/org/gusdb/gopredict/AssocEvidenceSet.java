package org.gusdb.gopredict;

import java.util.Vector;

/**
 * AssocEvidenceSet.java
 * 
 * A container class that holds the GUS GO Id of an association, along with
 * an Instance.  The instance should have an object representing the 
 * evidence used to make a modification to the association.
 *
 * Generally, modifications will have been done by an annotator using an 
 * Annotator's Interface; examples include verifying the association or 
 * rejecting it.  Using an AssocEvidenceSet is a good way to propogate these
 * modifications and the evidence to other related Associations. 
 *
 * Created: Tue Jul 15 16:55:30 2003
 *
 * @author David Barkan
 */

public class AssocEvidenceSet  {


    // ------------------------------------------------------------------
    // Instance Variables
    // ------------------------------------------------------------------
    
    /**
     * The GO Term Id of the modified Association.
     */
    int goTermId;

    /**
     * The contained Instance; it should have a piece of Evidence representing
     * the reason for a change to the Association.
     */
    //Instance instance;

    Vector<Instance> instances;
    

    // ------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------
      
    public AssocEvidenceSet(int id){
	this.goTermId = id;
	instances = new Vector<>();
    }
 
    public void addInstance(Instance instance){
	instances.add(instance);
    }

    
    //    public AssocEvidenceSet(int id, Instance inputInstance){

    //	this.goTermId = id;
	//this.instance = inputInstance;

    //    }
    /*    public Instance getInstance(){
	return this.instance;
	}*/

    public Vector<Instance> getInstances(){
	return instances;
    }

    public int getModifiedGoTermId(){
	return this.goTermId;
    }

}
