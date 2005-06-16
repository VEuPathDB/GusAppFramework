
/* Java class "ChangeSet.java" generated from Poseidon for UML.
 *  Poseidon for UML is developed by <A HREF="http://www.gentleware.com">Gentleware</A>.
 *  Generated with <A HREF="http://jakarta.apache.org/velocity/">velocity</A> template engine.
 */
package org.gusdb.dbadmin.model;

import java.util.ArrayList;
import java.util.Collection;

/**
 * <p>
 * 
 * </p>
 */
public class ChangeSet {

   ///////////////////////////////////////
   // associations

/**
 * <p>
 * 
 * </p>
 */
    private Database database; 
/**
 * <p>
 * 
 * </p>
 */
    public Collection delete = new ArrayList(); // of type Delete
/**
 * <p>
 * 
 * </p>
 */
    public Collection add = new ArrayList(); // of type Add
/**
 * <p>
 * 
 * </p>
 */
    public Collection rename = new ArrayList(); // of type Rename
/**
 * <p>
 * 
 * </p>
 */
    public Collection modifyColumnType = new ArrayList(); // of type ModifyColumnType


   ///////////////////////////////////////
   // access methods for associations

    /** @poseidon-generated */
    public Database getDatabase() {
        return database;
    }
    /** @poseidon-generated */
    public void setDatabase(Database database) {
        if (this.database != database) {
            this.database = database;
            if (database != null) database.setChangeSet(this);
        }
    }
    /** @poseidon-generated */
    public Collection getDeletes() {
        return delete;
    }
    /** @poseidon-generated */
    public void addDelete(Delete delete) {
        if (! this.delete.contains(delete)) {
            this.delete.add(delete);
            delete.setChangeSet(this);
        }
    }
    /** @poseidon-generated */
    public void removeDelete(Delete delete) {
        boolean removed = this.delete.remove(delete);
        if (removed) delete.setChangeSet((ChangeSet)null);
    }
    /** @poseidon-generated */
    public Collection getAdds() {
        return add;
    }
    /** @poseidon-generated */
    public void addAdd(Add add) {
        if (! this.add.contains(add)) {
            this.add.add(add);
            add.setChangeSet(this);
        }
    }
    /** @poseidon-generated */
    public void removeAdd(Add add) {
        boolean removed = this.add.remove(add);
        if (removed) add.setChangeSet((ChangeSet)null);
    }
    /** @poseidon-generated */
    public Collection getRenames() {
        return rename;
    }
    /** @poseidon-generated */
    public void addRename(Rename rename) {
        if (! this.rename.contains(rename)) {
            this.rename.add(rename);
            rename.setChangeSet(this);
        }
    }
    /** @poseidon-generated */
    public void removeRename(Rename rename) {
        boolean removed = this.rename.remove(rename);
        if (removed) rename.setChangeSet((ChangeSet)null);
    }
    /** @poseidon-generated */
    public Collection getModifyColumnTypes() {
        return modifyColumnType;
    }
    /** @poseidon-generated */
    public void addModifyColumnType(ModifyColumnType modifyColumnType) {
        if (! this.modifyColumnType.contains(modifyColumnType)) {
            this.modifyColumnType.add(modifyColumnType);
            modifyColumnType.setChangeSet(this);
        }
    }
    /** @poseidon-generated */
    public void removeModifyColumnType(ModifyColumnType modifyColumnType) {
        boolean removed = this.modifyColumnType.remove(modifyColumnType);
        if (removed) modifyColumnType.setChangeSet((ChangeSet)null);
    }

 } // end ChangeSet




