
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
public class VersionSchema extends Schema {


    protected final Log log = LogFactory.getLog(VersionSchema.class);
    private GusSchema gusSchema;

    public VersionSchema(GusSchema gusSchema) {
	setGusSchema(gusSchema);
	setName(gusSchema.getName() + verSuffix);
	setDatabase(gusSchema.getDatabase());
	for ( Iterator i = gusSchema.getTables().iterator(); i.hasNext(); ) {
	    GusTable table = (GusTable) i.next();
	    if ( table.getVersionTable() != null ) {
		addTable(table.getVersionTable());
	    }
	}
	for ( Iterator i = gusSchema.getViews().iterator(); i.hasNext(); ) {
	    GusView view = (GusView) i.next();
	    if ( view.getVersionView() != null ) {
		addView(view.getVersionView());
	    }
	}
    }
    
    public GusSchema getGusSchema() {
	return gusSchema;
    }

    public void setGusSchema(GusSchema gusSchema) {
	this.gusSchema = gusSchema;
    }

    public boolean deepEquals(DatabaseObject o) {
	if ( o.getClass() != VersionSchema.class ) return false;
	if ( equals( (VersionSchema) o, new HashSet()) == 1 ) return true;
	return false;
    }

    int equals (DatabaseObject o, HashSet seen) {
	VersionSchema other = (VersionSchema) o;
	if ( super.equals(other, seen) == 0 ) return 0;
	
	boolean equal = true;

	if ( gusSchema.equals(other.getGusSchema(), seen) == 0 ) equal = false;

	if ( ! equal ) {
	    log.debug("VersionSchema attributes vary");
	    return 0;
	}

	return compareChildren(other, seen);
    }

}