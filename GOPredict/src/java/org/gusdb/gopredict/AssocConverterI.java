package org.gusdb.gopredict;


/**
 * AssocConverterI.java
 *
 * An API for classes that convert specific objects representing
 * associations between a piece of data (for instance, a protein sequence
 * and a GO Term.  These associations are converted to a generic Data Structure
 * that tracks relationships between the GO Terms and serves primarily to 
 * ensure that the data in the associations are consistent CBIL GO Association
 * management policies.
 *
 * Created: Thu July 24 12:08:30 2003
 *
 * @author David Barkan
 */

public interface AssocConverterI {

    /**
     * Classes implementing this interface use this method to  to take a 
     * specific type of Object, which will vary depending on the application 
     * that is using AssociationGraph functionality, and return a generic Association
     * object that represents the data contained in the original Object.
     * Input objects should have as much data as possible that is tracked
     * by the Association object, and the method should provide defaults
     * when that information is not available.  The Association should 
     * point to the object as an instance variable.
     */

    public Association createAssociationFromObject(Object object);


    /**
     * The 'deconverter' for this interface; it takes the generic Association object
     * and uses its data to update the contained Object's instance data.  The contained
     * Object is then returned.  As the Object may have other objects that it relies on 
     * (for example, an Association and its Instances), a Vector is returned.  The API
     * of the implementing class should detail the order of the objects within the vector.
     */

    //dtb: maybe make an object that can track different objects (assocs, instances) instead
    //of a hack vector
    public Object updateAndGetObjectFromAssoc(Association assoc);

    public Instance makeInstanceForEvidenceSet(Object evidence, Object genericInstance);
    //    public AssocEvidenceSet makeAssocEvidenceSet(Object assoc, Object evidence, Object instance);


}
