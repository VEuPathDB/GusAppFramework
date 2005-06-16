
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
public class GusSchema extends Schema {

    protected final Log log        = LogFactory.getLog(GusSchema.class);

    private String documentation;
    private VersionSchema versionSchema;

    public GusSchema() {
	versionSchema = new VersionSchema(this);
    }

    public VersionSchema getVersionSchema() {
	return versionSchema;
    }
    
    public String getDocumentation() {
	return documentation;
    }
    
    public void setDocumentation(String documentation) {
	this.documentation = documentation;
    }
    
    public void setName(String name) {
	super.setName(name);
	versionSchema.setName(name + verSuffix);
    }
        
    public void setDatabase(Database database) {
	super.setDatabase(database);
	versionSchema.setDatabase(database);
    }
    
    public void addTable(GusTable table) {
	super.addTable(table);
	if ( table.getVersionTable() != null ) {
	    versionSchema.addTable(table.getVersionTable());
	}
    }
    
    public void removeTable(GusTable table) {
	super.removeTable(table);
	if ( table.getVersionTable() != null ) {
	    versionSchema.removeTable(table.getVersionTable());
	}
    }
    
    public void addView(GusView view) {
	super.addView(view);
	if ( view.getVersionView() != null ) {
	    versionSchema.addView(view.getVersionView());
	}
    }
    
    public void removeView(GusView view) {
	super.removeView(view);
	if ( view.getVersionView() != null ) {
	    versionSchema.removeView(view.getVersionView());
	}
    }
    
    void resolveReferences(Database db) {
	for ( Iterator i = getTables().iterator(); i.hasNext(); ) {
	    ((GusTable) i.next()).resolveReferences(db);
	}
	Object[] tables = getTables().toArray();
	for ( int i = 0; i<tables.length; i++ ) {
	    Table table = (Table) tables[i];
	    for ( Iterator j = table.getSubclasss().iterator(); j.hasNext(); ) {
		((GusTable) j.next()).setSchema(this);
	    }
	}
    }

    public boolean deepEquals(DatabaseObject o) {
	if ( o.getClass() != GusSchema.class ) return false;
	if ( equals( (GusSchema) o, new HashSet()) == 1 ) return true;
	return false;
    }

    int equals (DatabaseObject o, HashSet seen) {
	GusSchema other = (GusSchema) o;
	if ( super.equals(other, seen) == 0 ) return 0;

	boolean equal = true;
	
	if ( ! documentation.equals(other.getDocumentation()) ) equal = false;
	if ( versionSchema.equals(other.getVersionSchema(), seen) == 0 ) equal = false;

	if ( ! equal ) { 
	    log.debug("GusSchema attributes vary");
	    return 0;
	}

	return compareChildren(other, seen);
    }


}