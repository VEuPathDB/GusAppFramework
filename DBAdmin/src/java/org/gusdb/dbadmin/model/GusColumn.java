
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
public class GusColumn extends Column {

    protected static final Log log = LogFactory.getLog(Column.class);

    private String documentation; 
    private Collection referentialConstraint = new HashSet();
    private Collection index = new HashSet();
    private VersionColumn versionColumn;

    public VersionColumn getVersionColumn() {
	return this.versionColumn;
    }

    public void setVersionColumn(VersionColumn versionColumn) {
	this.versionColumn = versionColumn;
    }

    public String getDocumentation() {
	return documentation;
    }
    
    public void setDocumentation(String documentation) {
	this.documentation = documentation;
    }


    public Collection getReferentialConstraints() {
	return referentialConstraint;
    }
    
    public void addReferentialConstraint(Constraint constraint) {
        if (! this.referentialConstraint.contains(constraint)) {
            this.referentialConstraint.add(constraint);
            constraint.addReferencedColumn(this);
        }
    }

    public void removeReferentialConstraint(Constraint constraint) {
        boolean removed = this.referentialConstraint.remove(constraint);
        if (removed) constraint.removeReferencedColumn(this);
    }

    public void setTable(GusTable table) {
	super.setTable(table);
	if ( getVersionColumn() != null ) {
	    if ( table != null) getVersionColumn().setTable(table.getVersionTable());
	    else getVersionColumn().setTable(null);
	}
	else {
	    if ( table != null ) {
		setVersionColumn(new VersionColumn(this));
	    }
	}
    }

    public Collection getIndexs() {
	return index;
    }

    public void addIndex(Index index) {
        if (! this.index.contains(index)) {
            this.index.add(index);
            index.addColumn(this);
        }
    }

    public void removeIndex(Index index) {
        boolean removed = this.index.remove(index);
        if (removed) index.removeColumn(this);
    }

    public void setName(String name) {
	super.setName(name);
	if ( getVersionColumn() != null ) getVersionColumn().setName(name);
    }
    
    public void setPrecision(int precision) {
	super.setPrecision(precision);
	if ( getVersionColumn() != null ) getVersionColumn().setPrecision(precision);
    }
    
    public void setLength(int length) {
	super.setLength(length);
	if ( getVersionColumn() != null ) getVersionColumn().setLength(length);
    }
    
    public void setNullable(boolean nullable) {
        super.setNullable(nullable);
	if ( getVersionColumn() != null ) getVersionColumn().setNullable(nullable);
    }

    public void setType(String type) {
	super.setType(type);
	if ( getVersionColumn() != null ) getVersionColumn().setType(type);
    }
    
    public void setType(ColumnType columnType) {
	super.setType(columnType);
	if ( getVersionColumn() != null ) getVersionColumn().setType(columnType);
    }

    public Object clone() {
        GusColumn clone = new GusColumn();
        clone.setLength(getLength());
	clone.setName(getName());
	clone.setNullable(isNullable());
	clone.setPrecision(getPrecision());
	clone.setType(getType());
        return clone;
    }
    
    TreeSet getSortedChildren() {
	TreeSet children = super.getSortedChildren();
	children.addAll(getReferentialConstraints());
	children.addAll(getIndexs());
	return children;
    }


    public boolean deepEquals(DatabaseObject o) {
	if ( o.getClass() != GusColumn.class ) return false;
	if ( equals( (GusColumn) o, new HashSet() ) == 1 ) return true;
	return false;
    }

    int equals( DatabaseObject o, HashSet seen ) {
	GusColumn other = (GusColumn) o;
	if ( super.equals(other, seen) == 0 ) return 0;
	
	boolean equal = true;

	if ( ! documentation.equals(other.getDocumentation()) ) equal = false;
	if ( versionColumn.equals(other.getVersionColumn(), seen) == 0 ) equal = false;

	if ( ! equal ) {
	    log.debug("GusColumn attributes vary");
	    return 0;
	}

	return compareChildren(other, seen);
    }



}