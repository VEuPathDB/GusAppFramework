package org.gusdb.dbadmin.model;

import java.io.IOException;
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

    protected final Log log    = LogFactory.getLog( Database.class );
    private float       version;
    private Collection  schema = new HashSet( );                     // of

    /**
     * DOCUMENT ME!
     * 
     * @return DOCUMENT ME!
     */
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

    /**
     * DOCUMENT ME!
     * 
     * @param schema DOCUMENT ME!
     */
    public void addSchema( Schema schema ) {
        log.debug( "Adding schema " + schema.getName( ) );

        if ( !this.schema.contains( schema ) ) {
            this.schema.add( schema );
            schema.setDatabase( this );
        }
    }

    /**
     * DOCUMENT ME!
     * 
     * @param schema DOCUMENT ME!
     */
    public void removeSchema( Schema schema ) {

        boolean removed = this.schema.remove( schema );

        if ( removed ) schema.setDatabase( (Database) null );
    }

    /**
     * DOCUMENT ME!
     * 
     * @param name DOCUMENT ME!
     * @return DOCUMENT ME!
     */
    public Schema getSchema( String name ) {

        if ( name == null )

        return null;

        for ( Iterator i = getSchemas( ).iterator( ); i.hasNext( ); ) {

            Schema schema = (Schema) i.next( );

            if ( schema.getName( ).compareToIgnoreCase( name ) == 0 ) {

                return schema;
            }
        }

        return null;
    }

    /**
     * DOCUMENT ME!
     * 
     * @return DOCUMENT ME!
     */
    public float getVersion( ) {

        return version;
    }

    /**
     * DOCUMENT ME!
     * 
     * @param version DOCUMENT ME!
     */
    public void setVersion( float version ) {
        this.version = version;
    }

    /**
     * @param restrictVersion true to not include version tables
     * @return All tables in the database
     */
    public Collection getTables( boolean restrictVersion) {
        Collection tables = new Vector();
        for ( Iterator i = getSchemas( restrictVersion ).iterator(); i.hasNext(); ) {
            Schema schema = (Schema) i.next();
            tables.addAll(schema.getTables());
        }
        return tables;
    }
    
    /**
     * DOCUMENT ME!
     */
    public void resolveReferences( ) {
        log.info( "Resolving Database References" );

        for ( Iterator i = getSchemas( ).iterator( ); i.hasNext( ); ) {

            Schema schema = (Schema) i.next( );

            if ( schema.getClass( ) == GusSchema.class ) {
                ((GusSchema) schema).resolveReferences( this );
            }
        }
    }


    /**
     * DOCUMENT ME!
     * 
     * @param o DOCUMENT ME!
     * @param seen DOCUMENT ME!
     * @return DOCUMENT ME!
     * @throws IOException
     */
    public boolean equals( DatabaseObject o ) {
        Database other = (Database) o;

        if ( version != other.getVersion( ) ) return false;
        return super.equals( o );
    }
}
