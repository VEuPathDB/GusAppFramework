
package org.gusdb.dbadmin.model;

import java.util.Collection;
import java.util.HashSet;
import java.util.Iterator;
import java.util.TreeSet;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

/**
 * @author msaffitz
 * @version $Revision$ $Date$
 */
public class Database extends DatabaseObject {

    protected final Log log = LogFactory.getLog(Database.class);	
	
    private float version; 
    private ChangeSet changeSet; 
    private Collection schema = new HashSet(); // of type Schema

    public ChangeSet getChangeSet() {
        return changeSet;
    }

    public void setChangeSet(ChangeSet changeSet) {
        if (this.changeSet != changeSet) {
            this.changeSet = changeSet;
            if (changeSet != null) changeSet.setDatabase(this);
        }
    }

    public Collection getSchemas() {
        return schema;
    }

    public void addSchema(Schema schema) {
    	log.debug("Adding schema " + schema.getName());
        if (! this.schema.contains(schema)) {
            this.schema.add(schema);
            schema.setDatabase(this);
        }
    }

    public void removeSchema(Schema schema) {
        boolean removed = this.schema.remove(schema);
        if (removed) schema.setDatabase((Database)null);
    }

    public Schema getSchema(String name) {        
        if ( name == null ) return null;
        for ( Iterator i = getSchemas().iterator(); i.hasNext(); ) {
            Schema schema = (Schema) i.next();
            if ( schema.getName().compareToIgnoreCase(name) == 0 ) {
                return schema;
            }
        }
        return null;
    }

    public float getVersion() {        
        return version;
    } 

    public void setVersion(float version) {        
        this.version = version;
    }

    public void resolveReferences() {
	log.info("Resolving Database References");
	for ( Iterator i = getSchemas().iterator(); i.hasNext(); ) {
	    Schema schema = (Schema) i.next();
	    if ( schema.getClass() == GusSchema.class) {
		((GusSchema) schema).resolveReferences(this);
	    }
	}
    }

    public boolean deepEquals(DatabaseObject o) {
	if ( o.getClass() != Database.class) return false;
	if ( equals((Database) o, new HashSet()) == 1 ) return true;
	return false;
    }

    TreeSet getSortedChildren() {
	return new TreeSet(getSchemas());
    }

    int equals (DatabaseObject o, HashSet seen) {
	Database other = (Database) o;
	if ( seen.contains(this) ) return -1 ;
	seen.add(this);

	boolean equal  = true;
	if ( ! name.equals(other.getName()) ) equal = false;
	if ( version != other.getVersion() ) equal = false;
	if ( ! equal ) {
	    log.debug("Database attributes vary");
	    return 0;
	}
	
	return compareChildren(other, seen);
    }

}

