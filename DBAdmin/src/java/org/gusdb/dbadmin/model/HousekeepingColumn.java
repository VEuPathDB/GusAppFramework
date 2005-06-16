
package org.gusdb.dbadmin.model;

import java.util.Collection;
import java.util.HashSet;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

/**
 * @author msaffitz
 * @version $Revision$ $Date$
 */
public class HousekeepingColumn extends Column {

    protected static final Log log = LogFactory.getLog(HousekeepingColumn.class);

    public HousekeepingColumn() {
    }

    public void setTable(Table table) {
	if ( getTable() != table ) {
	    if ( getTable() != null ) getTable().removeHousekeepingColumn(this);
	    log.debug("Setting table: '" + table.getName() + "' for HousekeepingColumn: '" + getName() + "'");
	    this.table = table;
	    if ( table != null ) table.addHousekeepingColumn(this);
	}
    }

    public Object clone() {
       HousekeepingColumn clone = new HousekeepingColumn();
       clone.setLength(getLength());
       clone.setName(getName());
       clone.setNullable(isNullable());
       clone.setPrecision(getPrecision());
       clone.setType(getType());
       return clone;
    }

    public boolean deepEquals(DatabaseObject o) {
	if ( o.getClass() != HousekeepingColumn.class ) return false;
	if ( equals( (HousekeepingColumn) o, new HashSet() ) == 1 ) return true;
	return false;
    }

    int equals( DatabaseObject other, HashSet seen ) {
	if ( super.equals(other, seen) == 0 ) return 0;
	return compareChildren(other, seen);
    }

}