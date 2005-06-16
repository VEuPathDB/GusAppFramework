

package org.gusdb.dbadmin.model;

import java.util.ArrayList;
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
public abstract class Table extends DatabaseObject implements Comparable {

    protected static final Log log = LogFactory.getLog(Table.class);

    private String tablespace; 
    private boolean housekeeping  = true;
    private boolean updatable     = true;
    private Schema schema; 
    private Collection column = new ArrayList(); // of type Column
    private Collection housekeepingColumn = new ArrayList();
    private Collection subclass = new HashSet(); // of type Table
    private Table superclass; 
    private Constraint primaryKey;

    protected final String verSuffix = "Ver";

    public Schema getSchema() {
        return schema;
    }

    public void setSchema(Schema schema) {
        if (this.schema != schema) {
            if (this.schema != null) this.schema.removeTable(this);
            this.schema = schema;
            if (schema != null) schema.addTable(this);
        }
    }

    public Collection getColumns() {
        return getColumns(true);
    }
    
    public Collection getColumns(boolean housekeeping) {
        ArrayList columns = new ArrayList();
        columns.addAll(column);
        if ( housekeeping ) { 
            columns.addAll(housekeepingColumn); 
        }
        return columns;        
    }
    
    public void addColumn(Column column) {
	if ( ! this.column.contains(column) ) {
	    log.debug("Adding Column: '" + column.getName() + "' to Table: '" 
		             + getName() + "' of Type: '" + column.getType() + "'");
	    this.column.add(column);
	    column.setTable(this);
	}
    }

    public void removeColumn(Column column) {
        boolean removed = this.column.remove(column);
        if (removed) column.setTable(null);
    }

    public Collection getHousekeepingColumns() {
        return housekeepingColumn;
    }
   
    public void addHousekeepingColumn(HousekeepingColumn housekeepingColumn) {
       if (! this.housekeepingColumn.contains(housekeepingColumn)) {
	   log.debug("Adding HousekeepingColumn: '" + housekeepingColumn.getName() 
		        + "' to Table: '" + getName() + "'");
            this.housekeepingColumn.add(housekeepingColumn);
            housekeepingColumn.setTable(this);
        }
    }

    public void setHousekeepingColumns(Collection housekeepingColumns) {
	log.debug("Setting HousekeepingColumns for Table: '" + getName() + "'");
	this.housekeepingColumn.clear();
	for ( Iterator i = housekeepingColumns.iterator(); i.hasNext(); ) {
	    HousekeepingColumn col = (HousekeepingColumn) i.next();
	    addHousekeepingColumn((HousekeepingColumn) col.clone());
	}
    }
   
    public void removeHousekeepingColumn(HousekeepingColumn housekeepingColumn) {
        boolean removed = this.housekeepingColumn.remove(housekeepingColumn);
        if (removed) housekeepingColumn.setTable(null);
    }

    public Collection getSubclasss() {
        return subclass;
    }

    // Simple Aliase
    public Collection getSubclasses() {
	return getSubclasss();
    }

    public void addSubclass(Table table) {
        if (! this.subclass.contains(table)) {
            this.subclass.add(table);
            table.setSuperclass(this);
        }
    }

    public void removeSubclass(Table table) {
        boolean removed = this.subclass.remove(table);
        if (removed) table.setSuperclass(null);
    }

    public Table getSuperclass() {
        return superclass;
    }

    public void setSuperclass(Table table) {
        if (this.superclass != table) {
	    log.debug("Setting superclass: '" + table.getName() +
		           "' for Table: '" + getName() + "'");
            if (this.superclass != null) this.superclass.removeSubclass(this);
            this.superclass = table;
            if (table != null) table.addSubclass(this);
        }
    }

	public String getPrimaryKeyName() {
		if ( getPrimaryKey() == null ) return null;
		if ( getPrimaryKey().getConstrainedColumns().isEmpty() ) return null;
		ArrayList columns = (ArrayList) getPrimaryKey().getConstrainedColumns();
		return ((Column) columns.get(0)).getName();
	}

    public Constraint getPrimaryKey() {
		return primaryKey;
    }
    
    public boolean removePrimaryKey() {
		boolean removed = false;
		Constraint pk = this.primaryKey;
		if ( pk != null &&
		     pk.getConstrainedTable() != null ) {
				 this.primaryKey = null;
				 removed = true;
		}
		if ( removed) pk.setConstrainedTable(null);
		return removed;
   	 }

    public void setPrimaryKey(Constraint primaryKey) {
		boolean removed = false;
		if ( this.primaryKey != primaryKey ) {
			log.debug("Setting primary key for Table: '" + name + "'");
			removePrimaryKey();
			this.primaryKey = primaryKey;
			if ( primaryKey != null ) primaryKey.setConstrainedTable(this);
		}
    }

    public String getTablespace() {        
        return tablespace;
    }

    public void setTablespace(String tablespace) {        
        this.tablespace = tablespace;
    }      

    public Column getColumn(String name) {        
        if ( name == null ) return null;
        for (Iterator i = getColumns().iterator(); i.hasNext(); ) {
            Column column = (Column) i.next();
            if ( column.getName().compareToIgnoreCase(name) == 0 ) {
                return column;
            }
        }
        return null;
    }

    public boolean isHousekeeping() {        
        return housekeeping;
    }

    public void setHousekeeping(boolean housekeeping) {        
        this.housekeeping = housekeeping;
    }

    public boolean isUpdatable() {        
        return updatable;
    }

    public void setUpdatable(boolean updatable) {        
        this.updatable = updatable;
    } 


    public static Table getTableFromRef(Database db, String ref) {
	String[] path = ref.split("/");
	if ( path.length != 2 ) {
	    log.error("Invalid table ref: "+ref);
	    throw new RuntimeException("Invalid table ref");
	}
	Table table = db.getSchema(path[0]).getTable(path[1]);
	if ( table == null ) {
	    log.error("Unable to find table for ref: "+ref);
	    throw new RuntimeException("Invalid table ref");
	}
	log.debug("Resolved: "+table.getName());
	return table;
    }

    public int compareTo(Object o) {
	Table t = (Table) o;
	if ( t == null ) return 1;
	if ( this.getName() == null ) {
	    if ( t.getName() == null ) return 0;
	    else return -1;
	}
	return this.getName().compareTo(t.getName());
    }

    TreeSet getSortedChildren() {
	TreeSet children = new TreeSet();
	children.addAll(getColumns());
	children.addAll(getHousekeepingColumns());
	children.addAll(getSubclasss());
	return children;
    }

    int equals (DatabaseObject o, HashSet seen) {
	Table other = (Table) o;
	if ( seen.contains(this) ) return -1;
	seen.add(this);

	boolean equal = true;
	
	if ( ! name.equals(other.getName()) ) equal = false;
	if ( ! tablespace.equals(other.getTablespace()) ) equal = false;
	if ( housekeeping != other.isHousekeeping() ) equal = false;
	if ( updatable != other.isUpdatable() ) equal = false;
	if ( schema.equals(other.getSchema(), seen) == 0 ) equal = false;
	if ( superclass.equals(other.getSuperclass(), seen) == 0 ) 
	    equal = false;
	if ( primaryKey.equals(other.getPrimaryKey(), seen) == 0 ) 
	    equal = false;

	if ( ! equal ) { 
	    log.debug("Table attributes vary");
	    return 0;
	}

	return 1;
    }
}