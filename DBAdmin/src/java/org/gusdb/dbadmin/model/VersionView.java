package org.gusdb.dbadmin.model;

import java.util.Iterator;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

/**
 * @author msaffitz
 * @version $Revision$ $Date: 2005-06-16 16:35:04 -0400 (Thu, 16 Jun
 *          2005) $
 */
public class VersionView extends View {

    protected final Log log = LogFactory.getLog( VersionView.class );
    private GusView     gusView;

    public VersionView( GusView gusView ) {
        setGusView( gusView );
        setName( gusView.getName( ) + verSuffix );
        if ( gusView.getSchema( ) != null ) {
            setSchema( ((GusSchema) gusView.getSchema( )).getVersionSchema( ) );
        }
        if ( gusView.getSuperclass( ) != null ) {
            setSuperclass( ((GusView) gusView.getSuperclass( ))
                    .getVersionView( ) );
        }
        for ( Iterator i = gusView.getSubclasss( ).iterator( ); i.hasNext( ); ) {
            GusView subclass = (GusView) i.next( );
            if ( subclass.getVersionView( ) != null ) {
                addSubclass( subclass.getVersionView( ) );
            }
        }
        setTable( gusView.getTable( ) );
    }

    public GusView getGusView( ) {
        return this.gusView;
    }

    public void setGusView( GusView gusView ) {
        this.gusView = gusView;
    }
    /*
     * public boolean deepEquals(DatabaseObject o, Writer writer) throws
     * IOException { if (o.getClass() != VersionView.class) return false; if
     * (equals((VersionView) o, new HashSet(), writer)) return true; return
     * false; } boolean equals(DatabaseObject o, HashSet seen, Writer writer)
     * throws IOException { VersionView other = (VersionView) o; if
     * (!super.equals(other, seen, writer)) return false; boolean equal = true;
     * if (!gusView.equals(other.getGusView(), seen, writer)) equal = false; if
     * (!equal) { log.debug("VersionView attributes vary"); return false; }
     * return compareChildren(other, seen, writer); }
     */
}
