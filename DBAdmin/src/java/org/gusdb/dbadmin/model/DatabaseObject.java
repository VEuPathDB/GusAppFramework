
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
abstract public class DatabaseObject { 

    protected static final Log log = LogFactory.getLog(Table.class);

    protected String name; 

    public String getName() {        
        return name;
    }

    public void setName(String name) {        
        this.name = name;
    }

    int compareChildren(DatabaseObject other , HashSet seen) {
	if ( getSortedChildren().size() != other.getSortedChildren().size() ) {
	    log.debug("Child counts vary");
	    return 0;
	}

	Iterator otherI = other.getSortedChildren().iterator();
	for ( Iterator thisI = getSortedChildren().iterator(); thisI.hasNext(); ) {
	    if ( ((DatabaseObject) thisI.next()).equals((DatabaseObject) otherI.next(), seen) == 0 ) {
		log.debug("Database children vary");
		return 0;
	    }
	}
	log.debug("Children are equal");
	return 1;
    }

    abstract TreeSet getSortedChildren();

    //    public abstract boolean equals(Object o);

    public abstract boolean deepEquals (DatabaseObject other);

    abstract int equals (DatabaseObject other, HashSet seen);

}

