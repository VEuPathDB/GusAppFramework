
/* Java class "Add.java" generated from Poseidon for UML.
 *  Poseidon for UML is developed by <A HREF="http://www.gentleware.com">Gentleware</A>.
 *  Generated with <A HREF="http://jakarta.apache.org/velocity/">velocity</A> template engine.
 */
package org.gusdb.dbadmin.model;


/**
 * <p>
 * 
 * </p>
 */
public class Add {

  ///////////////////////////////////////
  // attributes


/**
 * <p>
 * Represents ...
 * </p>
 */
    private Object path; 

   ///////////////////////////////////////
   // associations

/**
 * <p>
 * 
 * </p>
 */
    private ChangeSet changeSet; 


   ///////////////////////////////////////
   // access methods for associations

    /** @poseidon-generated */
    public ChangeSet getChangeSet() {
        return changeSet;
    }
    /** @poseidon-generated */
    public void setChangeSet(ChangeSet changeSet) {
        if (this.changeSet != changeSet) {
            if (this.changeSet != null) this.changeSet.removeAdd(this);
            this.changeSet = changeSet;
            if (changeSet != null) changeSet.addAdd(this);
        }
    }


  ///////////////////////////////////////
  // operations


/**
 * <p>
 * Does ...
 * </p>
 * 
 * 
 * @return 
 */
    public Object getPath() {        
        return path;
    } // end getPath        

/**
 * <p>
 * Does ...
 * </p>
 * 
 * 
 * @param _path 
 */
    public void setPath(Object _path) {        
        path = _path;
    } // end setPath        

 } // end Add




