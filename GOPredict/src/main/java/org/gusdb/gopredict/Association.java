/**
 * Association.java
 * A class representing an association between a sequence and a 
 * GO ID.  Associations are usually grouped by their sequence in
 * a set known as an AssociationGraph, so the sequence is not 
 * tracked but instead implied.
 *
 * An Association keeps track of other Associations that contain 
 * the parents and children of its GO ID.  The GO ID, in turn, 
 * is represented by a GO Term object.  Associations also keep 
 * track of Instances, which can be thought of reasons for the 
 * existance of the Association (for example, it was predicted
 * by the CBIL GO Function Predictor or manually annotated by a 
 * curator).
 *
 * Created: Thu Jul 17 15:04:30 2003
 *
 * @author David Barkan
 */
package org.gusdb.gopredict;

import java.util.Enumeration;
import java.util.Hashtable;
import java.util.Vector;

public class Association  {

    
    // ------------------------------------------------------------------
    // Static variables
    // ------------------------------------------------------------------

    /**
     * Static ids in GUS of Lines of Evidence that are assigned to Instances
     */
    public static final int OBSOLETE_LOE = 5;
    public static final int SCRUBBER_LOE = 6;
    public static final int CBIL_PREDICT_LOE = 3;
    public static final int ANNOTATOR_LOE = 4;
    

    /**
     * Static ids in GUS of various Review Status Ids assigned to Instances and 
     * Associations.
     */
    public static final int UNREVIEWED_ID = 0;
    public static final int REVIEWED_ID = 1;
    public static final int NEEDS_REVIEW_ID = 5;
    
    
    // ------------------------------------------------------------------
    // Instance Variables
    // ------------------------------------------------------------------

    /**
     * The GO Term object containing, among other data, the ID of the Go Term
     * with which this Association is made.
     */
    private GoTerm goTerm;

    /**
     * Vectors containing respective relations to this Association, via the GO 
     * Hierarchy.
     */
    private Vector<Association> parents;
    private Vector<Association> children;
    
    /**
     * The Instances for this Association.
     */
    private Vector<Instance> instances;

    /**
     * Object for which this class is a container.
     */
    private Object containedObject;

    /**
     * Flag representing whether this Association has been set to 'is not'
     * by the curator.
     */
    private boolean isNot;
    
    /** 
     * This flag is true if the Association can reach the 
     * root of an AssociationGraph through a path of Associations 
     * that are all 'is' (i.e., no Associations on the path
     * are set to 'is not')
     */
    private boolean onIsPath;

    /**
     * Represents the ID in GUS of the current review status of this
     * Association.
     */
    private int reviewStatusId;

    /**
     * Represents whether this is an outdated Association from an earlier
     * run of a GO prediction algorithm such as the CBIL GO Predictor.
     */
    private boolean isDeprecated;

    /**
     * Flag indicating whether this Association is defining; generally
     * defining Associations are the lowest Associations on a branch
     * of the GO Hierarchy, with some exceptions (see AssociationGraph.java
     * for a complete definition.
     */
    private boolean isDefining;

    /**
     * ID in gus of association; may want to take this out because makes
     * this object a bit less than generic.
     */
    private int associationId;

    /**
     * Hashtable that tracks instances that will eventually be cached
     * using the methods that implement the Instance caching algorithm.
     * The keys of the hashtable are Strings representing GO Ids of 
     * descendant Associations and the values are vectors of Instances
     * from those descendants that will be cached.  
     */
    private Hashtable<String,Vector<Instance>> cachedInstances;

    /**
     * Hashtable that tracks EvidenceSets that will eventually be cached
     * using the methods that implement EvidenceSet propogation algorithms.
     * The keys of the hashtable are Integers representing GO Ids of 
     * descendant Associations and the values are vectors of EvidenceSets
     * from those descendants that will be cached.
     * Note: might eventually want to integrate this with cached instances
     * above but for now just use this.
     */
    private Hashtable<Integer,Vector<Instance>> cachedEvidenceSets;


    // ------------------------------------------------------------------
    // Constructors
    // ------------------------------------------------------------------

    /**
     * Basic new constructor; takes an initial GO Term.
     */
    public Association(GoTerm goTerm){
	//throw exception if no go term

	this.goTerm = goTerm;
	init();
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

    public GoTerm getGoTerm(){
	return goTerm;
    }
    
    public void setGoTerm(GoTerm goTerm){
	this.goTerm = goTerm;
    }

    public void setIsNot(boolean isNot){
	this.isNot = isNot;
    }

    public boolean getIsNot(){
	return isNot;
    }

    public void setOnIsPath(boolean onIsPath){
	this.onIsPath = onIsPath;
    }

    public boolean getOnIsPath(){
	return onIsPath;
    }

    public void setReviewStatusId(int reviewStatusId){
	this.reviewStatusId = reviewStatusId;
    }

    public int getReviewStatusId(){
	return reviewStatusId;
    }

    public void setAssociationId(int associationId){
	this.associationId = associationId;
    }

    public int getAssociationId(){
	return associationId;
    }

    public void setIsDeprecated(boolean isDeprecated){
	this.isDeprecated = isDeprecated;
    }

    public boolean getIsDeprecated(){
	return isDeprecated;
    }

    public void setIsDefining(boolean isDefining){
	this.isDefining = isDefining;
    }

    public Vector<Association> getParents(){
	return parents;
    }

    public Vector<Association> getChildren(){
	return children;
    }

    public Vector<Instance> getInstances(){
	return instances;
    }

    /**
     * This accessor represents whether this Association 
     * is the lowest in a branch of the AssociationGraph to 
     * which it belongs without being deprecated or 'is not'
     */
    public boolean getIsDefining(){
	return isDefining;
    }
    
    // ------------------------------------------------------------------
    // Public Methods
    // ------------------------------------------------------------------
    
    /**
     * Given an association (param $newParent), find the existing parent
     * association of self that has the same go term as the new parent
     * and replace it with the new parent.  The rest of the parents
     * remain unchanged.
     */
    public void replaceParent(Association newParent){
	
	Vector<Association> existingParents = new Vector<>(parents);
	//remove all parents, which have been saved in a local vector
	parents.clear();

	//go through and re-add all parents except for the one to be replaced
	for (int i = 0; i < existingParents.size(); i++){
	    Association nextExistingParent = existingParents.get(i);
	    
	    if (nextExistingParent.getGoTerm().getRealId().equals(newParent.getGoTerm().getRealId()) == false){
		addParent(existingParents.get(i));
	    }
	}
	
	newParent.addChild(this);
    }

    /**
     * Add this Association as a child to me (adds myself as a parent for the child too).
     */
    public void addChild(Association child){
	children.add(child);
	child.addParent(this);
    }
	
    /**
     * Add this Instance to my list of Instances.
     */
    public void addInstance(Instance instance){
	instances.add(instance);
    }

    public String toString(String tab){
	String myself = new String(tab + "ASSOCIATION GO ID " + goTerm.getRealId() + "\n");
	String childInfo = tab + "Children: ";
	for (int i = 0; i < children.size(); i++){
	    Association nextChild = children.get(i);
	    childInfo = childInfo.concat(nextChild.getGoTerm().getRealId() + ", ");
	}
	childInfo = childInfo.concat("\n" + tab + "Parents: ");
	for (int i = 0; i < parents.size(); i++){
	    Association nextParent = parents.get(i);
	    childInfo = childInfo.concat(nextParent.getGoTerm().getRealId() + ", ");
	}
	myself = myself.concat(childInfo + "\n");
	myself = myself.concat(tab + "primary:      " + getIsPrimary() + "\n");
	myself = myself.concat(tab + "isNot:        " + isNot + " assocId: " + associationId + "\n");
	myself = myself.concat(tab + "reviewStatus: " + reviewStatusId + " defining:  " + isDefining + "\n");
	for (int i = 0; i < instances.size(); i++){
	    Instance nextInstance = instances.get(i);
	    myself = myself.concat(nextInstance.toString(tab));
	}
	for (int i = 0; i < children.size(); i++){
	    Association nextChild = children.get(i);
	    myself = myself.concat(nextChild.toString(tab + "   "));
	}
	
	return myself;
						  
    }

    
    
    /**
     * Set all of my ancestors to be manually reviewed and verified.  Throws an exception if a
     * reviewed, rejected Association is encountered as one of my ancestors.
     */
    public void propogateVerifiedUp(String initialRealGoId) throws IllegalHierarchyException{
	
	if (reviewStatusId != REVIEWED_ID){
	    reviewStatusId = REVIEWED_ID;
	    isNot = false;
	}
	
	Vector<Association> parentAssocs = getParents();
	
	for (int i = 0; i < parentAssocs.size(); i++){
	    Association nextParent = parentAssocs.elementAt(i);
	    if (nextParent.getReviewStatusId() != UNREVIEWED_ID && nextParent.getIsNot() == true){
		System.err.println("Association: new hierarchy exception");
		String badGoId = nextParent.getGoTerm().getRealId();
		String error = "Error:  User attempted to assign an Association (GO ID: " + badGoId + ") to be 'is not' as the ancestor of an Association (GO ID: " + initialRealGoId + ") that is manually reviewed and verified";
		throw new IllegalHierarchyException(error);
	    }	
    
	    nextParent.propogateVerifiedUp(initialRealGoId);
	}
    }
    

    /**
     * Propogates Instances up to every ancestor, without restrictions.  Creates
     * a new instance at each ancestor and copies Evidence to the ancestor as well.
     * Once this method has been run, <code>addPropogatedInstances</code> must be
     * run to actually add the Instances (this method prepares the Instances for 
     * caching and also prevents duplication if propogating along two converging paths).
     * Note this is different than instance caching as it deals with evidence and
     * all instances are primary. (Might want to consider a new name for the method).
     */
    public void propogateVerifiedInstancesUp(AssocEvidenceSet assocEvidenceSet){
		
	for (int i = 0; i < parents.size(); i++){
	    Association nextParent = parents.elementAt(i);
	    Vector<Instance> verifiedInstances = assocEvidenceSet.getInstances();
	    Vector<Instance> processedInstances = new Vector<>();
	    for (int j = 0; j < verifiedInstances.size(); j++){
		Instance nextInstance = verifiedInstances.elementAt(j);
		Instance copiedInstance = nextInstance.cloneInstance();
		copiedInstance.setEvidenceObject(nextInstance.getEvidenceObject());
		processedInstances.add(copiedInstance);
	    }
	    nextParent.prepareInstancesToCache(assocEvidenceSet.getModifiedGoTermId(), processedInstances);
	    nextParent.propogateVerifiedInstancesUp(assocEvidenceSet);
	}
    }

    public void prepareInstancesToCache(int goTermId, Vector<Instance> instancesToCache){
	cachedEvidenceSets.put(Integer.valueOf(goTermId), instancesToCache);
    }
    

    /**
     * Propogates an instance down to every descendant, without restrictions.
     * Creates a new instance at each descendant and copies Evidence to the 
     * descendant as well.
     * Once this method has been run, <code>addPropogatedInstances</code> must be
     * run to actually add the Instances (this method prepares the Instances for 
     * caching and also prevents duplication if propogating along two converging paths).
     */
    public void propogateRejectedInstancesDown(AssocEvidenceSet assocEvidenceSet){
	
	for (int i = 0; i < children.size(); i++){
	    Association nextChild = children.elementAt(i);
	    Vector<Instance> rejectedInstances = assocEvidenceSet.getInstances();
	    Vector<Instance> processedInstances = new Vector<>();
	    for (int j = 0; j < rejectedInstances.size(); j++){
		Instance nextInstance = rejectedInstances.elementAt(j);
		Instance copiedInstance = nextInstance.cloneInstance();
		copiedInstance.setEvidenceObject(nextInstance.getEvidenceObject());
		processedInstances.add(copiedInstance);
	    }
	    nextChild.prepareInstancesToCache(assocEvidenceSet.getModifiedGoTermId(), processedInstances);
	    nextChild.propogateRejectedInstancesDown(assocEvidenceSet);
	}
    }
	

    /**
     * Sets all unreviewed descendants to be reviewed and 'is not'.
     * 
     * @param ignoreVerifiedDescendants Flag indicating whether to continue
     *                                  drilling down when it finds a verified
     *                                  descendant.  If this flag is set to false
     *                                  and the method finds a verified descendant,
     *                                  it will throw an Exception.  The flag 
     *                                  should primarily be true when calling
     *                                  this method on an initial set of Associations
     *                                  that are themselves 'is not', and false when
     *                                  calling the method on a set of Associations 
     *                                  that are verified.
     */

    public void propogateIsNotDown(boolean ignoreVerifiedDescendants, String initialRealGoId) throws IllegalHierarchyException{

	if (reviewStatusId == UNREVIEWED_ID){
	    System.err.println ("propogating is not = true to " + goTerm.getRealId());
	    reviewStatusId = REVIEWED_ID;
	    isNot = true;
	}

	Vector<Association> childAssocs = getChildren();
	for (int i = 0; i < childAssocs.size(); i++){
	    Association nextAssoc = childAssocs.elementAt(i);

	    if (ignoreVerifiedDescendants == false &&
		nextAssoc.getReviewStatusId() != UNREVIEWED_ID &&
		nextAssoc.getIsNot() != true){
		System.err.println("PropogateIsNotDown: throwing new illegal hierarchy exception");
		String badGoId = nextAssoc.getGoTerm().getRealId();
		String error = "Error:  User attempted to assign an Association (GO ID: " + initialRealGoId + ") to be 'is not' as the ancestor of an Association (GO ID: " + badGoId + ") that is manually reviewed and verified";
		throw new IllegalHierarchyException(error);
	    }
	    
	    nextAssoc.propogateIsNotDown(ignoreVerifiedDescendants, initialRealGoId);
	}
    }

    /**
     * Propogates Instances from a rejected Association to the first verified Ancestor
     * on the path from the rejected Association to the root, and returns.  If the path
     * splits then propogate to the first verified Ancestor on each path.
     * Once this method has been run, <code>addPropogatedInstances</code> must be
     * run to actually add the Instances (this method prepares the Instances for 
     * caching and also prevents duplication if propogating along two converging paths).
     */
    
    public void propogateRejectedInstancesUp(AssocEvidenceSet assocEvidenceSet){
	
	for (int i = 0; i < parents.size(); i++){
	    Association nextParent = parents.elementAt(i);
	    //primary?
	    if (nextParent.getReviewStatusId() != UNREVIEWED_ID && nextParent.getIsNot() != true){
		Vector<Instance> rejectedInstances = assocEvidenceSet.getInstances();
		Vector<Instance> processedInstances = new Vector<>();
		for (int j = 0; j < rejectedInstances.size(); j++){
		    Instance instance = rejectedInstances.elementAt(j);
		    Instance copiedInstance = instance.cloneInstance();
		    copiedInstance.setEvidenceObject(instance.getEvidenceObject());
		    copiedInstance.setIsFromRejectedChild();
		    copiedInstance.setIsNot(false);
		    processedInstances.add(copiedInstance);
		    nextParent.prepareInstancesToCache(assocEvidenceSet.getModifiedGoTermId(), processedInstances);
		}
	    }
	    else{
		nextParent.propogateRejectedInstancesUp(assocEvidenceSet);
	    }
	}
    }
    
    public void addPropogatedInstances(){
	Enumeration<Integer> goIds = cachedEvidenceSets.keys();
	while (goIds.hasMoreElements()){
	    Integer goId = goIds.nextElement();
	    Vector<Instance> nextInstanceList = cachedEvidenceSets.get(goId);
	    for (int i = 0; i < nextInstanceList.size(); i++){
		Instance instance = nextInstanceList.elementAt(i);
		instances.add(instance);
	    }
	}
	cachedEvidenceSets = new Hashtable<>();
    }


    /**
     * Returns true if this Association has one or more primary Instances.
     */
    public boolean getIsPrimary(){

	for (int i = 0; i < instances.size(); i++){
	    Instance nextInstance = instances.get(i);
	    if (nextInstance.getIsPrimary() == true){
		return true;
	    }
	}
	return false;
    }

    /**
     * Deprecate this Association if it has no Instances that are not 
     * deprecated.
     */
    public void deprecateIfInstancesDeprecated(){

	boolean deprecate = true;
	for (int i = 0; i < instances.size(); i++){
	    Instance nextInstance = instances.get(i);
	    if (nextInstance.getIsDeprecated() == false){
		deprecate = false;
	    }
	}
	setIsDeprecated(deprecate);
    }

    /**
     * Recursive function that determines and sets the 'onIsPath' 
     * instance variable for this Association and its children.
     */
    public void initializeOnIsPath(){

	if (getIsNot() == false){
	    setOnIsPath(true);
	    
	    for (int i = 0; i < children.size(); i++){
		Association nextAssoc = children.get(i);
		nextAssoc.initializeOnIsPath();
	    }
	}
    }

    /**
     * Sets the Association to be 'is not' if it is not on the 'is path'
     * determined from initializeOnIsPath(). If the Association was 
     * previously reviewed to be 'is' and has moved to a place where it 
     * is no longer on the is path, then it gets a new instance indicating 
     * it needs to be re-reviewed.
     */
    public void setIsNotFromIsPath(){

	if (getOnIsPath() == false){
	    if (getIsPrimary() == true && 
		getIsNot() == false && 
		getReviewStatusId() != UNREVIEWED_ID){
		
		Instance instance = new Instance();
		instance.setIsPrimary(true);
		instance.setIsNot(true);
		instance.setLOEId(SCRUBBER_LOE);
		
		//need to add instance evidence stuff
		
		instance.setReviewStatusId(NEEDS_REVIEW_ID);
		setReviewStatusId(NEEDS_REVIEW_ID);
		setIsNot(true);
		addInstance(instance);
	    }
	}
    }

    /**
     * Recursive method that copies all primary instances of an 
     * Association to all of its ancestors. Does not propogate 'is not' 
     * instances unless they are the only ones an Association will receive.
     *
     * @param instanceInfoHash  Hashtable where keys are the GO Ids of
     *                          primary descendants and the entry is a Vector
     *                          of that descendant's ancestors.  The parent
     *                          Association builds a set of them and then the
     *                          AssociationGraph uses cacheDescendantInstances()
     *                          to add them.
     */
    public void propogateInstances(Hashtable<String,Vector<Instance>> instanceInfoHash){

	if (getIsNot() == false){ //Do not propogate or add 'is not' instances
	    Enumeration<String> descendantGoIds = instanceInfoHash.keys();
	    while (descendantGoIds.hasMoreElements()){
		String nextGoId = descendantGoIds.nextElement();
		Vector<Instance> descendantInstances = instanceInfoHash.get(nextGoId);
		Vector<Instance> instancesToCache;
		if (hasNoIsDescendants() == true){ 
		    //cache 'is not' instances if have no other 'is' descendants.
		    instancesToCache = descendantInstances;
		    setIsNot(true);
		}
		else{
		    instancesToCache = stripIsNotInstances(descendantInstances);
		}
		cachedInstances.put(nextGoId, instancesToCache);
	    }
	    for (int j = 0; j < parents.size(); j++){
		Association nextParent = parents.get(j);
		nextParent.propogateInstances(instanceInfoHash);
	    }
	}
    }

    /**
     * Having built up a list of instances to cache, go ahead and do 
     * it.  The cached instances altered so as not to be primary.
     */
    public void cacheDescendantInstances(){

	Enumeration<String> descendantIds = cachedInstances.keys();
	while (descendantIds.hasMoreElements()){
	    String nextDescendantId = descendantIds.nextElement();
	    Vector<Instance> descendantInstances = cachedInstances.get(nextDescendantId);
	    for (int i = 0; i < descendantInstances.size(); i++){
		Instance nextInstance = descendantInstances.get(i);
		Instance newInstance = nextInstance.cloneNotPrimary();
	        //newInstance.setObject(undef);
		addInstance(newInstance);
	    }
	}
	cachedInstances.clear();
    }
    
    /**
     * A recursive method which sets the Association to be defining according to the rules
     * laid out in AssociationGraph.java (in the setDefiningLeaves method).
     */
    public boolean determineAndSetDefining(){

	boolean haveDefiningChildren = false;
	for (int i = 0; i < children.size(); i++){
	    Association child = children.get(i);
	    if (child.determineAndSetDefining() == true){
		haveDefiningChildren = true;
	    }
	}
	if (haveDefiningChildren == true){
	    return true;
	}
	if (getIsDeprecated() == true || 
	    getIsNot() == true ||
	    getIsPrimary() == false){
	    
	    return false;
	}
	setIsDefining(true);
	return true;
    }

    public void deprecatePredictedInstances(){

	for (int i = 0; i < instances.size(); i++){
	    Instance nextInstance = instances.get(i);
	    if (nextInstance.getLOEId() == CBIL_PREDICT_LOE){
		nextInstance.setIsDeprecated(true); 
	    }
	}
    }

    public void absorbStateFromAssociation(Association assoc){
	setReviewStatusId(assoc.getReviewStatusId());
	setIsNot(assoc.getIsNot());
	setObject(assoc.getObject());
	//association object?
    }

    // ------------------------------------------------------------------
    // Protected Methods
    // ------------------------------------------------------------------

    /**
     * Add an Association to the list of this Association's parents.
     * Only called from the method 'addChild', which is the public method
     * used to set a relationship between two Associations.
     */

    protected void addParent(Association parent){
	parents.add(parent);
    }

    // ------------------------------------------------------------------
    // Private Methods
    // ------------------------------------------------------------------
    
    private void init(){
	
	this.parents = new Vector<>();
	this.children = new Vector<>();
	this.instances = new Vector<>();
	this.cachedInstances = new Hashtable<>();
	this.cachedEvidenceSets = new Hashtable<>();
    }

    /**
     * Returns true if this Association has no descendants that are not
     * 'is not'.  Used when determining whether 'is not' Instances should
     * be propogated to this Association (which happens if this method 
     * returns true to ensure that all Associations have Instances).
     */
    private boolean hasNoIsDescendants(){

	if (getIsPrimary() == true && getIsNot() == false){
	    return false;
	}//base case

	for (int i = 0; i < children.size(); i++){
	    Association nextChild = children.get(i);
	    if (nextChild.hasNoIsDescendants() == false){
		return false;
	    }
	}
	return true;
    }

    /**
     * Given an instance list, remove all of those that are 'is not'.
     */
    private Vector<Instance> stripIsNotInstances(Vector<Instance> instancesToCheck){

	Vector<Instance> instancesToCache = new Vector<>();
	for (int i = 0; i < instancesToCheck.size(); i++){
	    Instance instance = instancesToCheck.get(i);
	    if (instance.getIsNot() == false){
		instancesToCache.add(instance);
	    }
	}
	return instancesToCache;
    }
}
