
package org.gusdb.dbadmin.model;

import java.util.Collection;
import java.util.HashSet;
import java.util.TreeSet;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

/**
 * @author msaffitz
 * @version $Revision$ $Date$
 */
public class GusView extends View {

    protected final Log log        = LogFactory.getLog(GusView.class);

    private String documentation; 
    private boolean versioned;
    private VersionView versionView;

    public GusView() {
    }

    public String getDocumentation() {
	return this.documentation;
    }
    
    public void setDocumentation(String documentation) { 
	this.documentation = documentation;
    }

    public boolean isVersioned() {
	return this.versioned;
    }

    public void setVersioned(boolean versioned) {
	if ( this.versioned && ! versioned ) {
	    this.versioned = versioned;
	    this.versionView.setSchema(null);
	    this.versionView = null;
	}
	if ( ! this.versioned && versioned ) {
	    this.versioned = versioned;
	    versionView = new VersionView(this);
	}
    }

    public VersionView getVersionView() {
	return this.versionView;
    }

    public void setTable(GusTable table) {
	super.setTable(table);
	if ( table.getVersionTable() != null &&
	     this.versionView != null ) {
	    versionView.setTable(table.getVersionTable());
	}
    }

    public void setSuperclass(GusView superclass) {
	super.setSuperclass(superclass);
	if ( superclass.getVersionView() != null &&
	     this.versionView != null ) {
	    versionView.setSuperclass(superclass.getVersionView());
	}
    }

    public void addSubclass(GusView subclass) {
	super.addSubclass(subclass);
	if ( subclass.getVersionView() != null &&
	     this.versionView != null ) {
	    versionView.addSubclass(subclass.getVersionView());
	}
    }

    public void removeSubclass(GusView subclass) {
	super.removeSubclass(subclass);
	if ( subclass.getVersionView() != null &&
	     this.versionView != null ) {
	    versionView.removeSubclass(subclass.getVersionView());
	}
    }

    public void setSchema(GusSchema schema) {
	super.setSchema(schema);
	if ( versionView != null ) { versionView.setSchema(schema.getVersionSchema()); }
    }

    public void setName(String name) {
	super.setName(name);
	if ( versionView != null ) { versionView.setName(name + verSuffix); }
    }

    public boolean deepEquals(DatabaseObject o) {
	if ( o.getClass() != GusView.class ) return false;
	if ( equals( (GusView) o, new HashSet()) == 1 ) return true;
	return false;
    }

    int equals(DatabaseObject o, HashSet seen) {
	GusView other = (GusView) o;
	if ( super.equals(other, seen) == 0 ) return 0;
	
	boolean equal = true;

	if ( ! documentation.equals(other.getDocumentation()) ) equal = false;
	if ( versioned != other.isVersioned() ) equal = false;
	if ( versionView.equals(other.getVersionView(), seen) == 0 ) equal = false;

	if ( ! equal ) {
	    log.debug("GusView attributes vary");
	    return 0;
	}

	return compareChildren(other, seen);
    }

}