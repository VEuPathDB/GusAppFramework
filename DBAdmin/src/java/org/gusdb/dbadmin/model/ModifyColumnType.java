
/* Java class "ModifyColumnType.java" generated from Poseidon for UML.
 *  Poseidon for UML is developed by <A HREF="http://www.gentleware.com">Gentleware</A>.
 *  Generated with <A HREF="http://jakarta.apache.org/velocity/">velocity</A> template engine.
 */
package org.gusdb.dbadmin.model;


/**
 * <p>
 * 
 * </p>
 */
public class ModifyColumnType {

  ///////////////////////////////////////
  // attributes


/**
 * <p>
 * Represents ...
 * </p>
 * 
 */
    private String path; 

/**
 * <p>
 * Represents ...
 * </p>
 */
    private int newLength; 

/**
 * <p>
 * Represents ...
 * </p>
 */
    private int newPrecision; 

   ///////////////////////////////////////
   // associations

/**
 * <p>
 * 
 * </p>
 */
    private ChangeSet changeSet; 
/**
 * <p>
 * 
 * </p>
 */
    private ColumnType newType; 


   ///////////////////////////////////////
   // access methods for associations

    /** @poseidon-generated */
    public ChangeSet getChangeSet() {
        return changeSet;
    }
    /** @poseidon-generated */
    public void setChangeSet(ChangeSet changeSet) {
        if (this.changeSet != changeSet) {
            if (this.changeSet != null) this.changeSet.removeModifyColumnType(this);
            this.changeSet = changeSet;
            if (changeSet != null) changeSet.addModifyColumnType(this);
        }
    }
    /** @poseidon-generated */
    public ColumnType getNewType() {
        return newType;
    }
    /** @poseidon-generated */
    public void setNewType(ColumnType columnType) {
        this.newType = columnType;
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
    public String getPath() {        
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
    public void setPath(String _path) {        
        path = _path;
    } // end setPath        

/**
 * <p>
 * Does ...
 * </p>
 * 
 * 
 * @return 
 */
    public int getNewPrecision() {        
        return newPrecision;
    } // end getNewPrecision        

/**
 * <p>
 * Does ...
 * </p>
 * 
 * 
 * @param _newPrecision 
 */
    public void setNewPrecision(int _newPrecision) {        
        newPrecision = _newPrecision;
    } // end setNewPrecision        

/**
 * <p>
 * Does ...
 * </p>
 * 
 * 
 * @return 
 */
    public int getNewLength() {        
        return newLength;
    } // end getNewLength        

/**
 * <p>
 * Does ...
 * </p>
 * 
 * 
 * @param _newLength 
 */
    public void setNewLength(int _newLength) {        
        newLength = _newLength;
    } // end setNewLength        

 } // end ModifyColumnType




