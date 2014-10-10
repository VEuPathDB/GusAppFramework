// $Id$
package org.gusdb.dbadmin.model;


/**
 * @version $Revision$
 * @author msaffitz
 */
abstract public class DatabaseObject implements Comparable {

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

    public boolean equals( DatabaseObject o ) {
        return getName( ).equalsIgnoreCase( o.getName( ) );
    }

    @Override
    public int compareTo( Object o ) {
        DatabaseObject other = (DatabaseObject) o;
        return this.getName( ).compareToIgnoreCase( other.getName( ) );
    }

}
