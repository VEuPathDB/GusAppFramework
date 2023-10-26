package org.gusdb.dbadmin.model;

import java.util.TreeSet;

/**
 * @version $Revision$ $Date: 2005-06-16 16:35:04 -0400 (Thu, 16 Jun
 *          2005) $
 * @author msaffitz
 */
public abstract class Schema extends DatabaseObject {

    private Database       database;
    private TreeSet<Table> table     = new TreeSet<>( );
    private TreeSet<View>  view      = new TreeSet<>( );
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

    public TreeSet<Table> getTables( ) {
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
        if ( removed ) table.setSchema( null );
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
        if ( removed ) view.setSchema( null );
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

}
