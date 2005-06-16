
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
public class VersionView extends View {

    protected final Log log        = LogFactory.getLog(VersionView.class);
    private GusView gusView;

    public VersionView(GusView gusView) {
	setGusView(gusView);
	setName(gusView.getName() + verSuffix);
	if ( gusView.getSchema() != null ) {
	    setSchema(((GusSchema)gusView.getSchema()).getVersionSchema());
	}
	if ( gusView.getSuperclass() != null ) {
	    setSuperclass(((GusView)gusView.getSuperclass()).getVersionView());
	}
	for ( Iterator i = gusView.getSubclasss().iterator(); i.hasNext(); ) {
	    GusView subclass = (GusView) i.next();
	    if ( subclass.getVersionView() != null ) {
		addSubclass(subclass.getVersionView());
	    }
	}
	setTable(gusView.getTable());
    }
    
    public GusView getGusView() {
	return this.gusView;
    }

    public void setGusView(GusView gusView) {
	this.gusView = gusView;
    }
    
      public boolean deepEquals(DatabaseObject o) {
	if ( o.getClass() != VersionView.class ) return false;
	if ( equals( (VersionView) o, new HashSet()) == 1 ) return true;
	return false;
    }

    int equals(DatabaseObject o, HashSet seen) {
	VersionView other = (VersionView) o;
	if ( super.equals(other, seen) == 0 ) return 0;
	
	boolean equal = true;

	if ( gusView.equals(other.getGusView(), seen) == 0 ) equal = false;

	if ( ! equal ) {
	    log.debug("VersionView attributes vary");
	    return 0;
	}

	return compareChildren(other, seen);
    }      
} 