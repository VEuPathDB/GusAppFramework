/**
 * 
 */
package org.gusdb.dbadmin.model;

import java.util.ArrayList;
import java.util.Iterator;

/**
 * @author msaffitz
 */
public class SuperCategory {

    private Database  database;
    private ArrayList categories = new ArrayList( );
    private String    name;

    public SuperCategory( ) {

    }

    public Database getDatabase( ) {
        return this.database;
    }

    public void setDatabase( Database database ) {
        if ( this.database != database ) {
            if ( this.database != null ) this.database.removeSuperCategory( this );
            this.database = database;
            if ( this.database != null ) this.database.addSuperCategory( this );
        }
        this.database = database;
    }

    public String getName( ) {
        return this.name;
    }

    public void setName( String name ) {
        this.name = name;
    }

    public ArrayList getCategories( ) {
        return this.categories;
    }

    public void addCategory( Category category ) {
        if ( !this.categories.contains( category ) ) {
            this.categories.add( category );
            category.setSuperCategory( this );
        }
    }

    public void removeCategory( Category category ) {
        boolean removed = this.categories.remove( category );
        if ( removed ) category.setSuperCategory( (SuperCategory) null );
    }

    public Category getCategory( String name ) {
        for ( Iterator i = categories.iterator( ); i.hasNext( ); ) {
            Category category = (Category) i.next( );
            if ( category.getName( ).equalsIgnoreCase( name ) ) return category;
        }
        return null;
    }

}
