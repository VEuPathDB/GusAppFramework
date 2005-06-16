
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
public class VersionColumn extends Column {

    protected static final Log log = LogFactory.getLog(VersionColumn.class);

    private GusColumn gusColumn;

    VersionColumn (GusColumn gusColumn) {
	setGusColumn(gusColumn);
        setLength(gusColumn.getLength());
	setName(gusColumn.getName());
	setNullable(gusColumn.isNullable());
	setPrecision(gusColumn.getPrecision());
	setType(gusColumn.getType());
	if ( gusColumn.getTable() != null &&  
	     ((GusTable)gusColumn.getTable()).isVersioned() ) {
	    setTable( ((GusTable)gusColumn.getTable()).getVersionTable());
	}
    }
    
    GusColumn getGusColumn() {
	return this.gusColumn;
    }

    void setGusColumn(GusColumn gusColumn) {
	this.gusColumn = gusColumn;
    }
	
    public boolean deepEquals(DatabaseObject o) {
	if ( o.getClass() !=VersionColumn.class ) return false;
	if ( equals( (VersionColumn) o, new HashSet() ) == 1 ) return true;
	return false;
    }

    int equals( DatabaseObject o, HashSet seen ) {
	VersionColumn other = (VersionColumn) o;
	if ( super.equals(other, seen) == 0 ) return 0;
	
	boolean equal = true;

	if ( gusColumn.equals(other.getGusColumn(), seen) == 0 ) equal = false;

	if ( ! equal ) {
	    log.debug("VersionColumn attributes vary");
	    return 0;
	}

	return compareChildren(other, seen);
    }

    
}