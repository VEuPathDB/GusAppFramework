package org.gusdb.dbadmin.model;

import java.util.Collection;
import java.util.HashSet;
import java.util.Iterator;

/**
 * @version $Revision$ $Date: 2005-06-16 16:35:04 -0400 (Thu, 16 Jun
 *          2005) $
 * @author msaffitz
 */
public abstract class Schema extends DatabaseObject implements Comparable {

    private Database       database;
    private Collection     table     = new HashSet( ); // of type Table
    private Collection     view      = new HashSet( ); // of type View
    protected final String verSuffix = "Ver";

    /**
     * DOCUMENT ME!
     * 
     * @return DOCUMENT ME!
     */
    public Database getDatabase( ) {

        return database;
    }

    /**
     * DOCUMENT ME!
     * 
     * @param database DOCUMENT ME!
     */
    public void setDatabase( Database database ) {

        if ( this.database != database ) {

            if ( this.database != null ) this.database.removeSchema( this );

            this.database = database;

            if ( this.database != null ) this.database.addSchema( this );
        }
    }

    /**
     * DOCUMENT ME!
     * 
     * @return DOCUMENT ME!
     */
    public Collection getTables( ) {

        return table;
    }

    /**
     * DOCUMENT ME!
     * 
     * @param table DOCUMENT ME!
     */
    public void addTable( Table table ) {

        if ( !this.table.contains( table ) ) {
            this.table.add( table );
            table.setSchema( this );
        }
    }

    /**
     * DOCUMENT ME!
     * 
     * @param table DOCUMENT ME!
     */
    public void removeTable( Table table ) {

        boolean removed = this.table.remove( table );

        if ( removed ) table.setSchema( (Schema) null );
    }

    /**
     * DOCUMENT ME!
     * 
     * @return DOCUMENT ME!
     */
    public Collection getViews( ) {

        return view;
    }

    /**
     * DOCUMENT ME!
     * 
     * @param view DOCUMENT ME!
     */
    public void addView( View view ) {

        if ( !this.view.contains( view ) ) {
            this.view.add( view );
            view.setSchema( this );
        }
    }

    /**
     * DOCUMENT ME!
     * 
     * @param view DOCUMENT ME!
     */
    public void removeView( View view ) {

        boolean removed = this.view.remove( view );

        if ( removed ) view.setSchema( (Schema) null );
    }

    /**
     * DOCUMENT ME!
     * 
     * @param name DOCUMENT ME!
     * @return DOCUMENT ME!
     */
    public Table getTable( String name ) {

        if ( name == null )

        return null;

        for ( Iterator i = getTables( ).iterator( ); i.hasNext( ); ) {

            Table table = (Table) i.next( );

            if ( table.getName( ).compareToIgnoreCase( name ) == 0 ) {

                return table;
            }
        }

        return null;
    }

    /**
     * DOCUMENT ME!
     * 
     * @param o DOCUMENT ME!
     * @return DOCUMENT ME!
     */
    public int compareTo( Object o ) {

        Schema s = (Schema) o;

        if ( s == null )

        return 1;

        if ( this.getName( ) == null ) {

            if ( s.getName( ) == null )

            return 0;
            else

            return -1;
        }

        return this.getName( ).compareTo( s.getName( ) );
    }

}
