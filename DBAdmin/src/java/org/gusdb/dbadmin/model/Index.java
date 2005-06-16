
package org.gusdb.dbadmin.model;

import java.util.Iterator;
import java.util.HashSet;
import java.util.TreeSet;
import java.util.ArrayList;
import java.util.Collection;

/**
 * @author msaffitz
 * @version $Revision$ $Date$
 */
public class Index extends DatabaseObject implements Comparable {

    private String tablespace; 
    private Collection columnRef = new ArrayList(); // of type String
    private Collection column = new ArrayList(); // of type GusColumn
    private GusTable table; 
    private IndexType type; 

    public Collection getColumns() {
        return column;
    }

    public void addColumn(GusColumn column) {
        if (! this.column.contains(column)) {
            this.column.add(column);
            column.addIndex(this);
        }
    }

    public void removeColumn(GusColumn column) {
        boolean removed = this.column.remove(column);
        if (removed) column.removeIndex(this);
    }

    public GusTable getTable() {
        return table;
    }

    public void setTable(GusTable table) {
        if (this.table != table) {
            if (this.table != null) this.table.removeIndex(this);
            this.table = table;
            if (table != null) table.addIndex(this);
        }
    }

    public IndexType getType() {
        return type;
    }

    public void setType(IndexType indexType) {
        this.type = indexType;
    }


    public String getTablespace() {        
        return tablespace;
    }

    public void setTablespace(String _tablespace) {        
        tablespace = _tablespace;
    }
    
    public void setType(String _type) {        
        this.type = IndexType.getInstance(_type);
    }
    
    public Collection getColumnRefs() {        
        return columnRef;
    }
    
    public void setColumnRefs(Collection _columnRef) {        
        columnRef = _columnRef;
    }
    
    public void addColumnRef(String _columnRef) {        
        if (! columnRef.contains(_columnRef)) columnRef.add(_columnRef);
    }

    public void removeColumnRef(String _columnRef) {        
        columnRef.remove(_columnRef);
    }

    public void resolveReferences(Database db) { 
	for ( Iterator i = getColumnRefs().iterator(); i.hasNext(); ) {
	    addColumn((GusColumn)Column.getColumnFromRef(db, (String) i.next()));
	}
    }

    public int compareTo(Object o) {
	Index i = (Index) o;
	if ( i == null ) return 1;
	if ( this.getName() == null ) {
	    if ( i.getName() == null ) return 0;
	    else return -1;
	}
	return this.getName().compareTo(i.getName());
    }

    TreeSet getSortedChildren() {
	return new TreeSet(getColumns());
    }

    public boolean deepEquals(DatabaseObject o) {
	if ( o.getClass() != Index.class ) return false;
	if ( equals( (Index) o, new HashSet() ) == 1 ) return true;
	return false;
    }

    int equals(DatabaseObject o, HashSet seen) {
	Index other = (Index) o;
	if ( seen.contains(this) ) return -1;
	seen.add(this);

	boolean equal = true;

	if ( ! name.equals(other.getName()) ) equal = false;
	if ( ! tablespace.equals(other.getTablespace()) ) equal = false;
	if ( table.equals(other.getTable(), seen) == 0 ) equal = false;
	if ( type != other.getType() ) equal = false;

	if ( ! equal ) {
	    log.debug("Index attributes vary");
	}

	return compareChildren(other, seen);
    }

 }