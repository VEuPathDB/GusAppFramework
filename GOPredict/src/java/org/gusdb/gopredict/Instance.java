/**
 * Instance.java
 *
 * Created Tuesday July 22 11:04:30 2003
 *
 * @author David Barkan
 */

package org.gusdb.gopredict;

public class Instance {

    // ------------------------------------------------------------------
    // Instance variables
    // ------------------------------------------------------------------

    /**
     * Object for which this class is a container.
     */
    private Object containedObject;

    /**
     * Evidence supporting this instance.  Note that this is different from the 
     * Perl version of AssociationGraph in that there is only one possible Evidence
     * Object.  However, one can cheat and use a Vector or similar container to 
     * represent multiple pieces of Evidence.
     */
    private Object evidenceObject;

    /**
     * Represents the ID in GUS of the current review status of this
     * Instance.
     */
    private int reviewStatusId;

    /**
     * Represents the Line Of Evidence ID in GUS for this Instance.
     * The LOEId is basically a reason for the existance of the Instance.
     */
    private int loeId;

    /**
     * Flag representing whether this Instance represents an Association that
     * has been set to 'is not' by the curator.
     */
    private boolean isNot;

    /**
     * Flag representing whether this Instance represents an Association that
     * has been created directly by an automated or manual method rather than
     * existing solely because it is an ancestor of such an Association.
     */
    private boolean isPrimary;

    /**
     * Flag indicating whether this Instance has been deprecated, because it 
     * exists from an earlier run of a GO prediction algorithm such as the
     * CBIL GO Predictor.
     */
    private boolean isDeprecated;

    /**
     * Flag indicating that this Instance was propogated from a rejected
     * Association to the verified Association (that this instance is pointing
     * to).  
     *
     * (This flag is not in the GUS GOAssociationInstance table, but is a good
     * way to handle some tricky Evidence issues that arise when performing 
     * the above propogation.)
     */
    private boolean isFromRejectedChild;



    // ------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------

    /**
     * Basic Constructor.
     */
    public Instance(){

    }

    // ------------------------------------------------------------------
    // Data Accessors
    // ------------------------------------------------------------------
    public Object getObject(){
	return containedObject;
    }

    public void setObject(Object object){
	containedObject = object;
    }

    public Object getEvidenceObject(){
	return evidenceObject;
    }

    public void setEvidenceObject(Object object){
        evidenceObject = object;
    }

    public void setReviewStatusId(int reviewStatusId){
	this.reviewStatusId = reviewStatusId;
    }

    public int getReviewStatusId(){
	return reviewStatusId;
    }

    public int getLOEId(){
	return loeId;
    }

    public void setLOEId(int loeId){
	this.loeId = loeId;
    }

    public void setIsNot(boolean isNot){
	this.isNot = isNot;
    }

    public boolean getIsNot(){
	return isNot;
    }

    public boolean getIsPrimary(){
	return isPrimary;
    }
    
    public void setIsPrimary(boolean isPrimary){
	this.isPrimary = isPrimary;
    }

    public boolean getIsDeprecated(){
	return isDeprecated;
    }
    
    public void setIsDeprecated(boolean isDeprecated){
	this.isDeprecated = isDeprecated;
    }

    // ------------------------------------------------------------------
    // Public Methods
    // ------------------------------------------------------------------

    public Instance cloneNotPrimary(){
	Instance newInstance = this.cloneInstance();
	newInstance.setIsPrimary(false);
	return newInstance;
    }
    
    public String toString(String tab){
	
	String evidenceString = "Evidence: ";
	/*	if (evidenceObject != null){
		if (evidenceObject instanceof SimRulePair){
		SimRulePair srp = (SimRulePair)evidenceObject;
		GUSRow simObject = srp.getSimilarity();
		evidenceString = evidenceString.concat("similarity/rule " + simObject.getValue("SIMILARITY_ID"));
	    }
	    else if (evidenceObject instanceof GUSRow){
		evidenceObject = (GUSRow)evidenceObject;
		GUSRow gusRow = (GUSRow)evidenceObject;
		if (gusRow.getTableName().equals("Similarity")){
		    evidenceString = evidenceString.concat("similarity " + gusRow.getValue("SIMILARITY_ID"));
		}
		else if (gusRow.getTableName().equals("Comment")){
		    evidenceString = evidenceString.concat("Comment " + gusRow.getValue("COMMENT_ID"));
		}
		}
	}
	else{
	    evidenceString = evidenceString.concat(" no evidence");
	    }*/

	evidenceString = evidenceString.concat("\n");
	
	return new String (tab + "Instance: Primary = " + isPrimary + " RS = " + reviewStatusId + " LOE = " + loeId + " isNot = " + isNot + " isDeprecated = " + isDeprecated + "\n" + tab + "\t" + evidenceString);
    }
    
    public Instance cloneInstance(){
	
	Instance newInstance = new Instance();
	newInstance.setReviewStatusId(getReviewStatusId());
	newInstance.setLOEId(getLOEId());
	newInstance.setIsNot(getIsNot());
	newInstance.setIsPrimary(getIsPrimary());
	
	return newInstance;
    }

    public boolean isFromRejectedChild(){
	return this.isFromRejectedChild;
    }
    
    public void setIsFromRejectedChild(){
	this.isFromRejectedChild = true;
    }
}
