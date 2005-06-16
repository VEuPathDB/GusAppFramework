
package org.gusdb.dbadmin.model;

import java.util.HashSet;
import java.util.TreeSet;

/**
 * @author msaffitz
 * @version $Revision$ $Date$
 */
public class Sequence extends DatabaseObject implements Comparable {

    private int start; 
    private GusTable table; 

    public GusTable getTable() {
        return table;
    }
 
    public void setTable(GusTable table) {
	if ( this.table != table ) {
	    this.table = table;
	    this.table.setSequence(this);
	}
    }
    
    public int getStart() {        
        return start;
    }

    public void setStart(int start) {        
        this.start = start;
    } 

    public int compareTo(Object o) {
	Sequence s = (Sequence) o;
	if ( s == null ) return 1;
	if ( this.getName() == null ) {
	    if ( s.getName() == null ) return 0;
	    else return -1;
	}
	return this.getName().compareTo(s.getName());
    }

    public boolean deepEquals(DatabaseObject o) {
	if ( o.getClass() != Sequence.class ) return false;
	if ( equals( (Sequence) o, new HashSet() ) == 1 ) return true;
	return false;
    }

    TreeSet getSortedChildren() {
	return new TreeSet();
    }

    int equals ( DatabaseObject o, HashSet seen ) {
	Sequence other = (Sequence) o;
	if ( seen.contains(this) ) return -1;
	seen.add(this);

	boolean equal = true;

	if ( ! getName().equals(other.getName()) ) equal = false;
	if ( start != other.getStart() ) equal = false;
	if ( table.equals(other.getTable(), seen) == 0 ) equal = false;

	if ( ! equal ) { 
	    log.debug("Sequence attributes vary");
	    return 0;
	}
	return 1;
    }

 }