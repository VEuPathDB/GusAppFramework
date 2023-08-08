// $Id$
package org.gusdb.dbadmin.model;


/**
 * @version $Revision$
 * @author msaffitz
 */
abstract public class DatabaseObject implements Comparable<DatabaseObject> {

    protected String           name;

    /**
     * @return Object Name
     */
    public String getName( ) {
        return name;
    }

    /**
     * @param name New Object Name
     */
    public void setName( String name ) {
        this.name = name;
    }

    @Override
    public boolean equals( Object o ) {
        if (!(o instanceof DatabaseObject)) return false;
        DatabaseObject other = (DatabaseObject)o;
        return getName().equalsIgnoreCase(other.getName());
    }

    @Override
    public int compareTo( DatabaseObject o ) {
        String myName = name == null ? "" : name;
        String oName = o.getName() == null ? "" : o.getName();
        return myName.compareToIgnoreCase(oName);
    }

}
