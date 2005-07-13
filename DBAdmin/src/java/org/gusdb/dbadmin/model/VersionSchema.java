package org.gusdb.dbadmin.model;

import java.util.Iterator;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

/**
 * @author msaffitz
 * @version $Revision$ $Date: 2005-06-16 16:35:04 -0400 (Thu, 16 Jun
 *          2005) $
 */
public class VersionSchema extends Schema {

    protected final Log log = LogFactory.getLog( VersionSchema.class );
    private GusSchema   gusSchema;

    public VersionSchema( GusSchema gusSchema ) {
        setGusSchema( gusSchema );
        setName( gusSchema.getName( ) + verSuffix );
        setDatabase( gusSchema.getDatabase( ) );
        for ( Iterator i = gusSchema.getTables( ).iterator( ); i.hasNext( ); ) {
            GusTable table = (GusTable) i.next( );
            if ( table.getVersionTable( ) != null ) {
                addTable( table.getVersionTable( ) );
            }
        }
        for ( Iterator i = gusSchema.getViews( ).iterator( ); i.hasNext( ); ) {
            GusView view = (GusView) i.next( );
            if ( view.getVersionView( ) != null ) {
                addView( view.getVersionView( ) );
            }
        }
    }

    public GusSchema getGusSchema( ) {
        return gusSchema;
    }

    public void setGusSchema( GusSchema gusSchema ) {
        this.gusSchema = gusSchema;
    }
    /*
     * public boolean deepEquals(DatabaseObject o, Writer writer) throws
     * IOException { if (o.getClass() != VersionSchema.class) return false; if
     * (equals((VersionSchema) o, new HashSet(), writer)) return true; return
     * false; } boolean equals(DatabaseObject o, HashSet seen, Writer writer)
     * throws IOException { VersionSchema other = (VersionSchema) o; if
     * (!super.equals(other, seen, writer)) return false; boolean equal = true;
     * if (!gusSchema.equals(other.getGusSchema(), seen, writer)) equal = false;
     * if (!equal) { log.debug("VersionSchema attributes vary"); return false; }
     * return compareChildren(other, seen, writer); }
     */

}
