
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
public abstract class Schema extends DatabaseObject implements Comparable {

    private Database database; 
    private Collection table = new HashSet(); // of type Table
    private Collection view  = new HashSet(); // of type View
    protected final String verSuffix = "Ver";

    public Database getDatabase() {
        return database;
    }
    
    public void setDatabase(Database database) {
        if (this.database != database) {
            if (this.database != null) this.database.removeSchema(this);
            this.database = database;
            if (this.database != null) this.database.addSchema(this);
        }
    }

    public Collection getTables() {
        return table;
    }

    public void addTable(Table table) {
        if (! this.table.contains(table)) {
            this.table.add(table);
            table.setSchema(this);
        }
    }
    
    public void removeTable(Table table) {
        boolean removed = this.table.remove(table);
        if (removed) table.setSchema((Schema)null);
    }

    public Collection getViews() {
        return view;
    }

    public void addView(View view) {
        if (! this.view.contains(view)) {
            this.view.add(view);
            view.setSchema(this);
        }
    }

    public void removeView(View view) {
        boolean removed = this.view.remove(view);
        if (removed) view.setSchema((Schema)null);
    }

    public Table getTable(String name) {        
        if ( name == null ) return null;
        for (Iterator i = getTables().iterator(); i.hasNext(); ) {
            Table table = (Table) i.next();
            if ( table.getName().compareToIgnoreCase(name) == 0 ) {
                return table;
            }
        }
        return null;
    }
 
    public int compareTo(Object o) {
	Schema s = (Schema) o;
	if ( s == null ) return 1;
	if ( this.getName() == null ) {
	    if ( s.getName() == null ) return 0;
	    else return -1;
	}
	return this.getName().compareTo(s.getName());
    }

    TreeSet getSortedChildren() {
	TreeSet children = new TreeSet();
	children.addAll(getTables());
	children.addAll(getViews());
	return children;
    }

    int equals (DatabaseObject o, HashSet seen) {
	Schema other = (Schema) o;
	if ( seen.contains(this) ) return -1;
	seen.add(this);
	
	boolean equal = true;

	if ( ! name.equals(other.getName()) ) equal = false;
	if ( database.equals(other.getDatabase(), seen) == 0 ) equal = false;
	
	if ( ! equal ) {
	    log.debug("Schema attributes vary");
	    return 0;
	}
	
	return 1;
    }


}