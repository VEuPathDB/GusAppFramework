package org.gusdb.dbadmin.model;

import java.util.Iterator;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

/**
 * @author msaffitz
 * @version $Revision$ $Date: 2005-06-16 16:35:04 -0400 (Thu, 16 Jun
 *          2005) $
 */
public class GusSchema extends Schema {

    protected final Log   log = LogFactory.getLog( GusSchema.class );

    private String        documentation;
    private VersionSchema versionSchema;

    public GusSchema( ) {
        versionSchema = new VersionSchema( this );
    }

    public VersionSchema getVersionSchema( ) {
        return versionSchema;
    }

    public String getDocumentation( ) {
        return documentation;
    }

    public void setDocumentation( String documentation ) {
        this.documentation = documentation;
    }

    public void setName( String name ) {
        super.setName( name );
        versionSchema.setName( name + verSuffix );
    }

    public void setDatabase( Database database ) {
        super.setDatabase( database );
        versionSchema.setDatabase( database );
    }

    public void addTable( GusTable table ) {
        super.addTable( table );
        if ( table.getVersionTable( ) != null ) {
            versionSchema.addTable( table.getVersionTable( ) );
        }
    }

    public void removeTable( GusTable table ) {
        super.removeTable( table );
        if ( table.getVersionTable( ) != null ) {
            versionSchema.removeTable( table.getVersionTable( ) );
        }
    }

    public void addView( GusView view ) {
        super.addView( view );
        if ( view.getVersionView( ) != null ) {
            versionSchema.addView( view.getVersionView( ) );
        }
    }

    public void removeView( GusView view ) {
        super.removeView( view );
        if ( view.getVersionView( ) != null ) {
            versionSchema.removeView( view.getVersionView( ) );
        }
    }

    void resolveReferences( Database db ) {
        for ( Iterator i = getTables( ).iterator( ); i.hasNext( ); ) {
            ((GusTable) i.next( )).resolveReferences( db );
        }
        Object[] tables = getTables( ).toArray( );
        for ( int i = 0; i < tables.length; i++ ) {
            Table table = (Table) tables[i];
            for ( Iterator j = table.getSubclasss( ).iterator( ); j.hasNext( ); ) {
                ((GusTable) j.next( )).setSchema( this );
            }
        }
    }
    /*
     * public boolean deepEquals(DatabaseObject o, Writer writer) throws
     * IOException { if (o.getClass() != GusSchema.class) return false; if
     * (equals((GusSchema) o, new HashSet(), writer)) return true; return false; }
     * boolean equals(DatabaseObject o, HashSet seen, Writer writer) throws
     * IOException { GusSchema other = (GusSchema) o; if (!super.equals(other,
     * seen, writer)) return false; boolean equal = true; if
     * (!documentation.equals(other.getDocumentation())) equal = false; if
     * (!versionSchema.equals(other.getVersionSchema(), seen, writer)) equal =
     * false; if (!equal) { log.debug("GusSchema attributes vary"); return
     * false; } return compareChildren(other, seen, writer); }
     */

}
