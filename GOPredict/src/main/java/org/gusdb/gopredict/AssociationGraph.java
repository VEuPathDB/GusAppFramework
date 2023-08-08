//todo: determine package (of all classes)
//review rules in adjust is_not method
//review all is_not rules, here and in association.java
//especially some of the automatic, needs review stuff, with additional 
//evidence. It seems strange that an annotator could review one association
//that causes another to require 'needs re-review'.  but maybe possible.
//consolidate 
//figure out how to handle contained object
//evidence newly added here

/**
 * AssociationGraph.java
 * A class representing a set of Associations.  These 
 * Associations in turn keep track of the GO terms to which 
 * they are associated and also point to the associations to the    
 * respective parents and children of their GO Terms.  An
 * AssociationGraph knows which association in its set is 
 * with the root of the Molecular Function branch of the GO     
 * Ontology, thus forming a complete graph that can be traversed 
 * or searched recursively.

 *
 * Created: Tue Jul 15 16:55:30 2003
 *
 * @author David Barkan
 */
package org.gusdb.gopredict;

import java.util.Enumeration;
import java.util.Hashtable;
import java.util.Vector;


public class AssociationGraph  {



    // ------------------------------------------------------------------
    // Instance Variables
    // ------------------------------------------------------------------
    
    /**
     * The root Association for this AssociationGraph
     */
    private Association rootAssoc;

    /**
     * The Hashtable that tracks all Associations; keyed on the GO Ids (i.e. GO:XXXXXX) 
     * of the Go Term of each Association
     */
    private Hashtable<String, Association> associationHash;
    
    /**
     * Hashtable that tracks Associations that have been added in the graftAssociation
     * method to prevent a duplicate Association being added when there are multiple
     * paths to that Association from a descendant.
     */
    private Hashtable<Association, String> alreadyAdded;
     
    
    // ------------------------------------------------------------------
    // Constructors
    // ------------------------------------------------------------------
    
    /**
     * Constructor; given an Association, return an AssociationGraph representing
     * all associations on the paths to the root from that Association.
     */
    public AssociationGraph(Association assoc, GoGraph goGraph){
	init();
	growBasicGraph(assoc);
	setRoot(goGraph);

    }

    /**
     * Constructor; given a list of Associations, return a complete AssociationGraph 
     * containing all Associations and all Associations on all paths to the root
     */
    public AssociationGraph(Vector<Association> assocList, GoGraph goGraph){
	init();
	if (assocList.size() > 0){
	    Association firstAssoc = assocList.get(0);
	    
	    //create initial AssociationGraph with the first association
	    growBasicGraph(firstAssoc);
	    setRoot(goGraph);  
	    //one difference from perl version; perl uses other constructor which sets root implicitly
	    Vector<Association> remainingAssociations = new Vector<>();
	    for (int i = 1; i < assocList.size(); i++){
		remainingAssociations.add(assocList.get(i));
	    }
	    //add the rest with addAssociations method
	    addAssociations(remainingAssociations, goGraph);
	}
    }

    // ------------------------------------------------------------------
    // Public Methods
    // ------------------------------------------------------------------

    /**
     * Returns all Associations in this AssociationGraph as a Enumeration.
     */
    public Enumeration<Association> getAsList(){
	
	return associationHash.elements();
    }

    /**
     * For each Association in the AssociationGraph, deprecates all predicted instances.
     */
    public void deprecateAllPredictedInstances(){

	Enumeration<Association> assocEnum = getAsList();
	while (assocEnum.hasMoreElements()){
	    Association nextAssoc = assocEnum.nextElement();
	    nextAssoc.deprecatePredictedInstances();
	}
    }

    /**
     * For each Association in the AssociationGraph, deprecates the Association if it has no 
     * non-deprecated instances.
     */
    public void deprecateAssociations(){

	Enumeration<Association> assocEnum = getAsList();
	while (assocEnum.hasMoreElements()){
	    Association nextAssoc = assocEnum.nextElement();
	    nextAssoc.deprecateIfInstancesDeprecated();
	}
    }

    /**
     * Sets the value of the 'is not' flag in the Association to reflect its place 
     * in the rest of the Hierarchy.  This takes place according to the following rules:
     * 1. If a primary Association is set to 'is' (i.e., not 'is_not') but its only path(s) 
     *    to the root is through an 'is not' Association, then the 'is' Association 
     *    is set to 'is not'.  
     * 2. The association gets an Instance reflecting this change.  
     * 3. If this Association was manually reviewed, it gets another Instance
     *    indicating needs to be rereviewed.   
     */
    public void adjustIsNots(){
	rootAssoc.initializeOnIsPath();
	Enumeration<Association> assocEnum = getAsList();
	while (assocEnum.hasMoreElements()){
	    Association nextAssoc = assocEnum.nextElement();
	    nextAssoc.setIsNotFromIsPath();
	}
    }

    /**
     * Sets the the 'defining' flag in all Associations 
     * that have no children or do not have children that are 'is', 
     * primary, not obsolete, and not deprecated. Generally, a defining 
     * Association will be the lowest one in each branch of the Associations 
     * that comprise the graph.
     */
    public void setDefiningLeaves(){
	rootAssoc.determineAndSetDefining();
    }

    /* Copies all primary instances for each primary Association Ap
     * to each parent Association B according to the following rules:
     * 1. Ap is not obsolete.
     * 2. The primary Instance is not deprecated, predicted to be 'is not', 
     *    or reflects an Instance created by another 'scrubber' method
     * 3. If the instance to be propogated is 'is not', then it is only 
     *    propogated to B if B has no other descendants that are 'is.'  In 
     *    this case, B is set to 'is not' as well.  
     * 4. Once cached, the Instance is no longer primary.  It gets its 
     *    own GUS Instance object and has no Evidence.
     */
    public void cachePrimaryInstances(){
	
	Enumeration<Association> assocEnum = getAsList();
	while (assocEnum.hasMoreElements()){
	    Association nextAssoc = assocEnum.nextElement();
	    if (nextAssoc.getIsPrimary()){ //ignoring obsolete for now
		Vector<Instance> instanceList = new Vector<>();
		Vector<Instance> assocInstances = nextAssoc.getInstances();
		for (int i = 0; i < assocInstances.size(); i++){
		    Instance nextInstance = assocInstances.get(i);
		    //put instance on the list to cache if it is acceptable
		    if (nextInstance.getIsPrimary() &&
			nextInstance.getIsDeprecated() == false &&
			nextInstance.getIsNot() == false &&
			nextInstance.getLOEId() != Association.CBIL_PREDICT_LOE &&  //needs package name
			nextInstance.getLOEId() != Association.SCRUBBER_LOE &&
			nextInstance.getLOEId() != Association.OBSOLETE_LOE){
			
			instanceList.add(nextInstance);
		    }
		}
		//initialize hashtable of instances to cache
		Hashtable<String,Vector<Instance>> instanceInfoHash = new Hashtable<>();
		instanceInfoHash.put(nextAssoc.getGoTerm().getRealId(), instanceList);
		Vector<Association> parents = nextAssoc.getParents();
		for (int j = 0; j < parents.size(); j++){
		    Association parent = parents.get(j);
		    parent.propogateInstances(instanceInfoHash);
		}
	    }
	}
	Enumeration<Association> assocEnumCache = getAsList();
	while (assocEnumCache.hasMoreElements()){
	    Association nextAssoc = assocEnumCache.nextElement();
	    //actually do the caching given the priming above
	    nextAssoc.cacheDescendantInstances();
	}
    }
    
    /**
     * Return the Association whose GO Term is the root of the GO Molecular 
     * Function branch.
     */
    public Association getRoot(){
	return rootAssoc;
    }
    
    @Override
    public String toString(){
	
	return "AssociationGraph: " + rootAssoc.toString("\t");
    }

    public void addGoTerms(Vector<Integer> addedGoIds, GoGraph goGraph) throws IllegalHierarchyException{
	
	Vector<Association> newAssociations = new Vector<>();
	
	for (int i = 0; i < addedGoIds.size(); i++){
	    
	    Integer goTermId = addedGoIds.elementAt(i);

	    GoTerm goTerm = goGraph.getGoTermFromGusGoId(goTermId.intValue());
	    Association assoc = makeManuallyAddedAssoc(goTerm);

	    newAssociations.add(assoc);
	}
	if (rootAssoc == null){  //AssociationGraph currently has no entries in it; create a new one
	    growBasicGraph(newAssociations.get(0));
	    setRoot(goGraph);
	    if (newAssociations.size() > 1){
		Vector<Association> remainingAssociations = new Vector<>();
		for (int i = 1; i < newAssociations.size(); i++){
		    remainingAssociations.add(newAssociations.get(i));
		}
		//add the rest with addAssociations method
		addAssociations(remainingAssociations, goGraph);
	    }
	}
	else{  //simply add associations onto current graph
	    addAssociations(newAssociations, goGraph);
	}
	for (int i = 0; i < newAssociations.size(); i++){
	    Association nextNewAssociation = newAssociations.elementAt(i);
	    nextNewAssociation.propogateVerifiedUp(nextNewAssociation.getGoTerm().getRealId());
	}
    }

    /**
     * Given a list of gus GO Ids for associations that have been verified by an 
     * annotator and evidence for their verification, find the corresponding Associations 
     * in the graph, set them as reviewed and verified, set all of their ancestors as reviewed
     * and verified and propogate the evidence to be used as instances for this ancestral
     * modification.  
     *
     * If being used in conjunction with <code>rejectGoAssociations</code>, then this method should
     * be run first so that verified GO Associations are set and capable of receiving 
     * rule evidence from rejected descendant Associations that indicates the rule was good but 
     * too specific.
     */
    public void verifyGoAssociations(Vector<AssocEvidenceSet> verifiedAssocEvidenceSets, GoGraph goGraph) throws IllegalHierarchyException{

	for (int i = 0; i < verifiedAssocEvidenceSets.size(); i++){
	    
	    AssocEvidenceSet nextAssocEvidenceSet = verifiedAssocEvidenceSets.elementAt(i);
	    String realGoId = goGraph.getGoTermFromGusGoId(nextAssocEvidenceSet.getModifiedGoTermId()).getRealId();
	    Association verifiedAssoc = find(realGoId);
	    verifiedAssoc.setReviewStatusId(Association.REVIEWED_ID);
	    verifiedAssoc.setIsNot(false);
	    Vector<Instance> evidenceSetInstances = nextAssocEvidenceSet.getInstances();
	    for (int j = 0; j < evidenceSetInstances.size(); j++){
		Instance nextInstance = evidenceSetInstances.elementAt(j);
		verifiedAssoc.addInstance(nextInstance);
	    }
	}
	//propogates verified status along with instances/evidence
	propogateVerifiedEvidenceUp(verifiedAssocEvidenceSets, goGraph);	//	propogateIsNotDown(verifiedAssocList, true); //dtb not now
    }

    /**
     * Given a list of GUS GO Ids for Associations that have been rejected by an annotator
     * and evidence for their rejection, find the corresponding Associations in the graph,
     * set them as reviewed and rejected, set all of their descendants as reviewed and 
     * rejected, and propogate the evidence to be used as instances for the descendant's 
     * modification.  Also propogate rule/similarity evidence up to the first verified
     * ancestors.
     *
     * If being run in conjunction with <code>verifyGoAssociations</code>, this method should
     * be run after the verification (see notes in that method for details.)
     */
    public void rejectGoAssociations(Vector<AssocEvidenceSet> rejectedAssocEvidenceSets, GoGraph goGraph) throws IllegalHierarchyException{
	
	for (int i = 0; i < rejectedAssocEvidenceSets.size(); i++){
	    AssocEvidenceSet nextAssocEvidenceSet = rejectedAssocEvidenceSets.elementAt(i);
	    String realGoId = goGraph.getGoTermFromGusGoId(nextAssocEvidenceSet.getModifiedGoTermId()).getRealId();
	    Association rejectedAssoc = find(realGoId);
	    rejectedAssoc.setReviewStatusId(Association.REVIEWED_ID);
	    rejectedAssoc.setIsNot(true);
	    Vector<Instance> evidenceSetInstances = nextAssocEvidenceSet.getInstances();
	    for (int j = 0; j < evidenceSetInstances.size(); j++){
		Instance nextInstance = evidenceSetInstances.elementAt(j);
		rejectedAssoc.addInstance(nextInstance);
	    }
	}
	propogateRejectedEvidenceDown(rejectedAssocEvidenceSets, false, goGraph);
	propogateRejectedEvidenceUp(rejectedAssocEvidenceSets, goGraph);
    }


    // ------------------------------------------------------------------
    // Private Methods
    // ------------------------------------------------------------------


    private Association makeManuallyAddedAssoc(GoTerm goTerm){
	//throw exception if no go term
	Association assoc = new Association(goTerm);
	assoc.setIsNot(false);
	assoc.setReviewStatusId(Association.REVIEWED_ID);
	assoc.setIsDeprecated(false);
	//dtb for now not adding an instance.  This should be done after the association
	//is first submitted to the database, and then evidence is added.
	/*        Instance instance = new Instance();
	instance.setIsPrimary(true);
	instance.setReviewStatusId(Association.REVIEWED_ID);
	instance.setIsDeprecated(false);
	instance.setIsNot(false);
	instance.setLOEId(Association.ANNOTATOR_LOE);
	assoc.addInstance(instance);*/ 
 	return assoc;
    }
    /**
     * Recursive method called from constructors; it actually does the work of creating new
     * Associations that lead up to the root from the given Association.  Creates relationships
     * between parents and children as necessary.
     */

    private void growBasicGraph(Association assoc){
	//exception if assoc is null
	setAssocByRealGoId(assoc);
	
	GoTerm goTerm = assoc.getGoTerm();
	Vector<GoTerm> goParents = goTerm.getParents();
	for (int i = 0; i < goParents.size(); i++){
	    
	    GoTerm currentGoParent = goParents.get(i);
	    //make sure this parent has not already been added to the AssociationGraph
	    Association parent = find(currentGoParent.getRealId());
	    if (parent == null){
		parent = new Association(currentGoParent);
		//recursive call to continue creating the path up.  
		growBasicGraph(parent);
	    }
	    //create relationship
	    parent.addChild(assoc);
	}
    }     

    /**
     * Set the Association that is to the root of the Molecular Function branch of 
     * the GO Hierarchy as the root Association of this AssociationGraph.
     */
    private void setRoot(GoGraph goGraph){
	if (goGraph == null){
	    System.err.println("no graph");
	}
	if (goGraph.getRootTerm() == null){
	    System.err.println("no root");
	}
	if (goGraph.getRootTerm().getRealId() == null){
	    System.err.println("no root real id");
	}

	String rootGoId = goGraph.getRootTerm().getRealId();
	Association assocForRoot = find(rootGoId);
	//exception if not found
	rootAssoc = assocForRoot;
    }

    /**
     * Adds the given Association to this AssociationGraph.
     */
    private void setAssocByRealGoId(Association assoc){
	if (assoc.getGoTerm() == null){
	    System.out.println("go term is null!");
	}
	String realGoId = assoc.getGoTerm().getRealId();
	associationHash.put(realGoId, assoc);
    }

    /**
     * Given the GO ID of some Association in the AssociationGraph,
     * return that Association.
     */
    private Association find(String realGoId){
	
	Association assoc = associationHash.get(realGoId);
	return assoc;
    }

    /**
     * Simple method to initialize instance objects.
     */
    private void init(){
	alreadyAdded = new Hashtable<>();
	associationHash = new Hashtable<>();
    }
    
    /**
     * Given a list of Associations, add them to this AssociationGraph.
     */
    private void addAssociations(Vector<Association> assocList, GoGraph goGraph){
	
	Association nextAssoc;
	for(int i = 0; i < assocList.size(); i++){
	    nextAssoc = assocList.get(i);
	    //create separate AssociationGraph with the next Association and graft it 
	    //to this AssociationGraph.
	    @SuppressWarnings("unused")
	    AssociationGraph tempAssocGraph = new AssociationGraph(nextAssoc, goGraph);
	    graftAssociation(nextAssoc, null);
	    //not worrying about memory leaks with temporary Association Graphs, for now
	}
    }

    /**
     * Given a list of manually reviewed, verified Associations, set all of their ancestors
     * on the path to the root to also be manually reviewed and verified, and then propogate
     * the evidence used to verify the Association to its ancestors. Throws an 
     * Exception if a rejected Association is encountered on the path to the root.
     */
    private void propogateVerifiedEvidenceUp(Vector<AssocEvidenceSet> verifiedAssocEvidenceSets, GoGraph goGraph) 
	throws IllegalHierarchyException{

	for (int i = 0; i < verifiedAssocEvidenceSets.size(); i++){
	    AssocEvidenceSet nextAssocEvidenceSet = verifiedAssocEvidenceSets.elementAt(i);
	    String realGoId = goGraph.getGoTermFromGusGoId(nextAssocEvidenceSet.getModifiedGoTermId()).getRealId();
	    Association verifiedAssoc = find(realGoId);

	    verifiedAssoc.propogateVerifiedUp(realGoId);
	    verifiedAssoc.propogateVerifiedInstancesUp(nextAssocEvidenceSet);
	}
	cacheAllPropogatedInstances();
    }

    /**
     * Given a list of associations, set all of their unreviewed descendants to be 'is not.'
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
    //dtb--not sure if will ever be setting ignoreVerifiedDescendants, but keep it for now.
    private void propogateRejectedEvidenceDown(Vector<AssocEvidenceSet> rejectedAssocEvidenceSets, 
					       boolean ignoreVerifiedDescendants,
					       GoGraph goGraph) throws IllegalHierarchyException{
	for (int i = 0; i < rejectedAssocEvidenceSets.size(); i++){
	    AssocEvidenceSet nextAssocEvidenceSet = rejectedAssocEvidenceSets.elementAt(i);
	    String realGoId = goGraph.getGoTermFromGusGoId(nextAssocEvidenceSet.getModifiedGoTermId()).getRealId();
	    Association rejectedAssoc = find(realGoId);
	    rejectedAssoc.propogateIsNotDown(ignoreVerifiedDescendants, realGoId);
	    rejectedAssoc.propogateRejectedInstancesDown(nextAssocEvidenceSet);
	}
	cacheAllPropogatedInstances();
    }

    /**
     * Given a list of rejected associations and their evidence, propogate the evidence up to the
     * first verified ancestor Association (or multiple Associations when the path splits.)
     */
    private void propogateRejectedEvidenceUp(Vector<AssocEvidenceSet> rejectedAssocEvidenceSets, GoGraph goGraph){

	for (int i = 0; i < rejectedAssocEvidenceSets.size(); i++){
	    AssocEvidenceSet nextAssocEvidenceSet = rejectedAssocEvidenceSets.elementAt(i);
	    String realGoId = goGraph.getGoTermFromGusGoId(nextAssocEvidenceSet.getModifiedGoTermId()).getRealId();
	    Association rejectedAssoc = find(realGoId);
	    rejectedAssoc.propogateRejectedInstancesUp(nextAssocEvidenceSet);
	}
	cacheAllPropogatedInstances();
    }

    private void cacheAllPropogatedInstances(){

	Enumeration<Association> assocList = getAsList();
	while (assocList.hasMoreElements()){
	    Association nextAssoc = assocList.nextElement();
	    nextAssoc.addPropogatedInstances();
	}
    }

    private void graftAssociation(Association assoc, Association childAssoc){
	
	String realGoId = assoc.getGoTerm().getRealId();

	//determine if the Association to be grafted already exists in this AssociationGraph
	Association prevAssoc = find(realGoId);
	
	//if the same Association object already exists, return here.
	if (prevAssoc == assoc &&
	    prevAssoc.getGoTerm().getRealId().equals(assoc.getGoTerm().getRealId())){
	    return;
	}

	//if the Association already exists in this AssociationGraph, and the child's
	//link has not been made with it, then make the link (replacing the parent
	//in the temporary AssociationGraph with the parent in this AssociationGraph)
	if (childAssoc != null && prevAssoc != null){
	    childAssoc.replaceParent(prevAssoc);
	}

	//check to see if this Association is already in this AssociationGraph
	//(note:  this is the way it was in the perl version; I think there's a good
	//reason we're not using find() to do this but can't remember right now)
	// FIXME: This is broken; looking up String value in a map with Association keys
	if (alreadyAdded.get(assoc.getGoTerm().getRealId()) != null){
	    return;
	}
	alreadyAdded.put(assoc, new String("1"));
	Association needsLink = null;
	if (prevAssoc != null){  
	    //assoc is in there but with incorrect state; it exists only by virtue
	    //of a descendant association
	    
	    Vector<Instance> instances = assoc.getInstances();
	    for (int i = 0; i < instances.size(); i++){
		prevAssoc.addInstance(instances.get(i));
	    }
	    if (assoc.getObject() != null){
		prevAssoc.absorbStateFromAssociation(assoc);
	    }
	}
	else{
	    setAssocByRealGoId(assoc);
	    needsLink = assoc;
	}
	Vector<Association> parents = assoc.getParents();
	//do the same for all parents; pass current assoc if a relationship needs to be created
	for (int i = 0; i < parents.size(); i ++){
	    graftAssociation(parents.get(i), needsLink);
	}
    }

}
