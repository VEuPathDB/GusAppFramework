package org.gusdb.gus.supported;


/**
 * All owl parsers should subclass this class and override all its methods
 * 
 * @author John Brestelli
 *
 */
public interface GusRdfRow {
	
    /**
     * Include or exclude rows which are written
     * 
     * @return
     *     true if it should be written
     */
    public boolean isValid ();
	
	
    /**
     * What do you want to print out for this statemnt??
     * 
     * @return
     *     string which can easily be read into GUS
     */
    public abstract String getOutputString();
	
    /**
     * Properties are the strangest things with Jena/owl... (there are several
     * sets of objects and predicates for each statment.)
     * Use this method to set instance variables based on property values
     * 
     * @param os
     *     one of the property object strings
     * @param ps
     *     oen of the property predicate strings
     */
    public abstract void parse ();

}
