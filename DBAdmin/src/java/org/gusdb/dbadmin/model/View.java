
package org.gusdb.dbadmin.model;


import java.util.ArrayList;
import java.util.Collection;
import java.util.HashSet;
import java.util.TreeSet;

import org.gusdb.dbadmin.util.ColumnPair;

/**
 * @author msaffitz
 * @version $Revision$ $Date$
 */
public abstract class View extends DatabaseObject implements Comparable {

    private String sql; 
    private boolean materialized; 

    private Schema schema;

    private View superclass;
    private Collection subclass = new HashSet();
	private Collection column = new ArrayList(); // Of type ColumnPair
	
    private Table table;

    protected String verSuffix = "Ver";

    public Table getTable() {
        return table;
    }
    
    public void setTable(Table table) {
        this.table = table;
    }
    
    public View getSuperclass() {
        return superclass;
    }

    public void setSuperclass(View superclass) {
        if (this.superclass != superclass) {
            if (this.superclass != null) this.superclass.removeSubclass(this);
            this.superclass = superclass;
            if (superclass != null) superclass.addSubclass(this);
        }
    }
	
	public Collection getColumns() { 
		return column;
	}
	
	public void addColumn(ColumnPair columnPair) {
		if ( ! this.column.contains(columnPair) ) {
			this.column.add(columnPair);
		}
	}
	    
    public void removeColumn(ColumnPair columnPair) {
        this.column.remove(columnPair);
    }
	
    public Collection getSubclasss() {
        return subclass;
    }

    public void addSubclass(View subclass) {
        if (! this.subclass.contains(subclass)) {
            this.subclass.add(subclass);
            subclass.setSuperclass(this);
        }
    }

    public void removeSubclass(View subclass) {
        boolean removed = this.subclass.remove(subclass);
        if (removed) subclass.setSuperclass((View)null);
    }

    
    public Schema getSchema() {
        return schema;
    }

    public void setSchema(Schema schema) {
        if (this.schema != schema) {
            if (this.schema != null) this.schema.removeView(this);
            this.schema = schema;
            if (schema != null) schema.addView(this);
        }
    }

    public String getSql() {        
        return sql;
    }

    public void setSql(String sql) {        
        this.sql = sql;
    }

    public boolean isMaterialized() {        
        return materialized;
    }

    public void setMaterialized(boolean materialized) {        
        this.materialized = materialized;
    }

    public int compareTo(Object o) {
	View v = (View) o;
	if ( v == null ) return 1;
	if ( this.getName() == null ) {
	    if ( v.getName() == null ) return 0;
	    else return -1;
	}
	return this.getName().compareTo(v.getName());
    }

    TreeSet getSortedChildren() {
	return new TreeSet(getSubclasss());
    }
    
    int equals (DatabaseObject o, HashSet seen ) {
	View other = (View) o;
	if ( seen.contains(this) ) return -1;
	seen.add(this);

	boolean equal = true;
	
	if ( ! name.equals(other.getName())) equal = false;
	if ( ! sql.equals(other.getSql()) ) equal = false;
	if ( schema.equals(other.getSchema(), seen) == 0 ) equal = false;
	if ( superclass.equals(other.getSuperclass(), seen) == 0 ) equal = false;
	if ( table.equals(other.getTable(), seen) == 0 ) equal = false;

	if ( ! equal ) {
	    log.debug("View attributs vary");
	    return 0;
	}

	return 1;
    }
}