package org.gusdb.dbadmin.model;

import java.util.ArrayList;
import java.util.TreeSet;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

/**
 * @version $Revision$ $Date: 2005-06-16 16:35:04 -0400 (Thu, 16 Jun
 *          2005) $
 * @author msaffitz
 */
public class Database extends DatabaseObject {

    protected final Log              log             = LogFactory.getLog( Database.class );
    private float                    version;
    private int                      patchLevel;
    private TreeSet<Schema>          schema          = new TreeSet<Schema>( );
    private ArrayList<SuperCategory> superCategories = new ArrayList<SuperCategory>( );

    public TreeSet<Schema> getAllSchemas( ) {
        return schema;
    }

    public TreeSet<GusSchema> getGusSchemas( ) {
        TreeSet<GusSchema> gusSchemas = new TreeSet<GusSchema>( );
        for ( Schema s : getAllSchemas( ) ) {
            if ( s.getClass( ) == GusSchema.class ) {
                gusSchemas.add( (GusSchema) s );
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

        for ( Schema s : getAllSchemas( ) ) {
            if ( s.getName( ).compareToIgnoreCase( name ) == 0 ) {
                return s;
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

    public int getPatchLevel( ) {
        return patchLevel;
    }

    public void setPatchLevel( int patchLevel ) {
        this.patchLevel = patchLevel;
    }    
    
    public ArrayList<SuperCategory> getSuperCategories( ) {
        return this.superCategories;
    }

    public Category getCategory( String name ) {
        for ( Category cat : getCategories( ) ) {
            if ( cat.getName( ) != null && cat.getName( ).equalsIgnoreCase( name ) ) return cat;
        }
        return null;
    }

    public ArrayList<Category> getCategories( ) {
        ArrayList<Category> categories = new ArrayList<Category>( );
        for ( SuperCategory superCat : getSuperCategories( ) ) {
            categories.addAll( superCat.getCategories( ) );
        }
        return categories;
    }

    public void setSuperCategories( ArrayList superCategories ) {
        for ( SuperCategory s : getSuperCategories( ) ) {
            removeSuperCategory( s );
        }
        for ( SuperCategory s : getSuperCategories( ) ) {
            addSuperCategory( s );
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

    public ArrayList<Table> getAllTables( ) {
        ArrayList<Table> tables = new ArrayList<Table>( );
        for ( Schema s : getAllSchemas( ) ) {
            tables.addAll( s.getTables( ) );
        }
        return tables;
    }

    public ArrayList<GusTable> getGusTables( ) {
        ArrayList<GusTable> tables = new ArrayList<GusTable>( );
        for ( GusSchema s : getGusSchemas( ) ) {
            tables.addAll( s.getTables( ) );
        }
        return tables;
    }

    public void resolveReferences( ) {
        log.info( "Resolving Database References" );

        for ( GusSchema schema : getGusSchemas( ) ) {
            schema.resolveReferences( this );
        }
    }
   
    @Override
    public boolean equals( DatabaseObject o ) {
        Database other = (Database) o;

        if ( version != other.getVersion( ) ) return false;
        return super.equals( o );
    }
}
