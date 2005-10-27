/**
 * 
 */
package org.gusdb.dbadmin.model;

import java.util.TreeSet;

/**
 * @author msaffitz
 */
public class Category {

    private SuperCategory     superCategory;
    private TreeSet<GusTable> tables = new TreeSet<GusTable>( );
    private String            name;

    public Category( ) {}

    public SuperCategory getSuperCategory( ) {
        return this.superCategory;
    }

    public void setSuperCategory( SuperCategory superCategory ) {
        if ( this.superCategory != superCategory ) {
            if ( this.superCategory != null ) this.superCategory.removeCategory( this );
            this.superCategory = superCategory;
            if ( this.superCategory != null ) this.superCategory.addCategory( this );
        }
    }

    public TreeSet<GusTable> getTables( ) {
        return tables;
    }

    public void addTable( GusTable table ) {
        if ( !this.tables.contains( table ) ) {
            this.tables.add( table );
            table.setCategory( this );
        }
    }

    public void removeTable( GusTable table ) {
        boolean removed = this.tables.remove( table );
        if ( removed ) table.setCategory( (Category) null );
    }

    public String getName( ) {
        return name;
    }

    public void setName( String name ) {
        this.name = name;
    }
}
