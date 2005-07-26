package org.gusdb.dbadmin.model;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Vector;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

/**
 * @version $Revision$ $Date: 2005-06-16 16:35:04 -0400 (Thu, 16 Jun
 *          2005) $
 * @author msaffitz
 */
public class Database extends DatabaseObject {

    protected final Log log             = LogFactory.getLog( Database.class );
    private float       version;
    private Collection  schema          = new HashSet( );
    private ArrayList   superCategories = new ArrayList( );

    public Collection getSchemas( ) {
        return schema;
    }

    public Collection getSchemas( boolean restrictVersion ) {
        if ( !restrictVersion ) return getSchemas( );
        Collection gusSchemas = new Vector( );
        for ( Iterator i = getSchemas( ).iterator( ); i.hasNext( ); ) {
            Schema s = (Schema) i.next( );
            if ( s.getClass( ) == GusSchema.class ) {
                gusSchemas.add( s );
            }
        }
        return gusSchemas;
    }

    public void addSchema( Schema schema ) {
        log.debug( "Adding schema " + schema.getName( ) );

        if ( !this.schema.contains( schema ) ) {
            this.schema.add( schema );
            schema.setDatabase( this );
        }
    }

    public void removeSchema( Schema schema ) {
        boolean removed = this.schema.remove( schema );
        if ( removed ) schema.setDatabase( (Database) null );
    }

    public Schema getSchema( String name ) {
        if ( name == null ) return null;

        for ( Iterator i = getSchemas( ).iterator( ); i.hasNext( ); ) {
            Schema schema = (Schema) i.next( );
            if ( schema.getName( ).compareToIgnoreCase( name ) == 0 ) {
                return schema;
            }
        }
        return null;
    }

    public float getVersion( ) {
        return version;
    }

    public void setVersion( float version ) {
        this.version = version;
    }

    public ArrayList getSuperCategories( ) {
        return this.superCategories;
    }
    
    public Category getCategory(String name) {
        for ( Iterator i = getCategories().iterator(); i.hasNext(); ) {
            Category cat = (Category) i.next();
            if ( cat.getName() != null && 
                    cat.getName().equalsIgnoreCase(name) ) return cat;
        }
        return null;
    }
    
    public Collection getCategories() {
        Collection categories = new ArrayList();
        for ( Iterator i = getSuperCategories().iterator(); i.hasNext(); ) {
            SuperCategory superCat = (SuperCategory) i.next();
            categories.addAll(superCat.getCategories());
        }
        return categories;
    }
    
    public void setSuperCategories(ArrayList superCategories) {
        for ( Iterator i = getSuperCategories().iterator(); i.hasNext(); ) {
            removeSuperCategory((SuperCategory) i.next());
        }
        for ( Iterator i = superCategories.iterator(); i.hasNext(); ) {
            addSuperCategory((SuperCategory) i.next());
        }
    }
    
    public void addSuperCategory( SuperCategory superCategory ) {
        if ( !this.superCategories.contains( superCategory ) ) {
            this.superCategories.add( superCategory );
            superCategory.setDatabase( this );
        }
    }

    public void removeSuperCategory( SuperCategory superCategory ) {
        boolean removed = this.superCategories.remove( superCategory );
        if ( removed ) superCategory.setDatabase( (Database) null );
    }

    /**
     * @param restrictVersion true to not include version tables
     * @return All tables in the database
     */
    public Collection getTables( boolean restrictVersion ) {
        Collection tables = new Vector( );
        for ( Iterator i = getSchemas( restrictVersion ).iterator( ); i.hasNext( ); ) {
            Schema schema = (Schema) i.next( );
            tables.addAll( schema.getTables( ) );
        }
        return tables;
    }

    public void resolveReferences( ) {
        log.info( "Resolving Database References" );

        for ( Iterator i = getSchemas( ).iterator( ); i.hasNext( ); ) {
            Schema schema = (Schema) i.next( );
            if ( schema.getClass( ) == GusSchema.class ) {
                ((GusSchema) schema).resolveReferences( this );
            }
        }
    }

    public boolean equals( DatabaseObject o ) {
        Database other = (Database) o;

        if ( version != other.getVersion( ) ) return false;
        return super.equals( o );
    }
}
