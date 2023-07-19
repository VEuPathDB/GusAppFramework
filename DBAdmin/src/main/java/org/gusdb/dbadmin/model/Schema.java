package org.gusdb.dbadmin.model;

import java.util.TreeSet;

/**
 * @version $Revision$ $Date: 2005-06-16 16:35:04 -0400 (Thu, 16 Jun
 *          2005) $
 * @author msaffitz
 */
public abstract class Schema extends DatabaseObject implements Comparable {

    private Database       database;
    private TreeSet<Table> table     = new TreeSet<Table>( );
    private TreeSet<View>  view      = new TreeSet<View>( );
    protected final String verSuffix = "Ver";

    public Database getDatabase( ) {
        return database;
    }

    public void setDatabase( Database database ) {
        if ( this.database != database ) {
            if ( this.database != null ) this.database.removeSchema( this );
            this.database = database;
            if ( this.database != null ) this.database.addSchema( this );
        }
    }

    public TreeSet<? extends Table> getTables( ) {
        return table;
    }

    public void addTable( Table table ) {
        if ( !this.table.contains( table ) ) {
            this.table.add( table );
            table.setSchema( this );
        }
    }

    public void removeTable( Table table ) {
        boolean removed = this.table.remove( table );
        if ( removed ) table.setSchema( (Schema) null );
    }

    public TreeSet<View> getViews( ) {
        return view;
    }

    public void addView( View view ) {
        if ( !this.view.contains( view ) ) {
            this.view.add( view );
            view.setSchema( this );
        }
    }

    public void removeView( View view ) {
        boolean removed = this.view.remove( view );
        if ( removed ) view.setSchema( (Schema) null );
    }

    public Table getTable( String name ) {
        if ( name == null ) return null;
        for ( Table table : getTables( ) ) {
            if ( table.getName( ).compareToIgnoreCase( name ) == 0 ) {
                return table;
            }
        }
        return null;
    }

    @Override
    public int compareTo( Object o ) {
        Schema s = (Schema) o;
        if ( s == null ) return 1;
        if ( this.getName( ) == null ) {
            if ( s.getName( ) == null ) return 0;
            else return -1;
        }
        return this.getName( ).compareTo( s.getName( ) );
    }

}
