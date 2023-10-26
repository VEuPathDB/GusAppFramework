package org.gusdb.dbadmin.model;

import static org.gusdb.dbadmin.model.GusSchema.toGusTables;
import static org.gusdb.dbadmin.model.GusSchema.toGusViews;

import java.util.Iterator;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * @author msaffitz
 * @version $Revision$ $Date: 2005-06-16 16:35:04 -0400 (Thu, 16 Jun
 *          2005) $
 */
public class VersionSchema extends Schema {

    @SuppressWarnings("unused")
    private static final Logger log = LogManager.getLogger( VersionSchema.class );

    private GusSchema   gusSchema;

    public VersionSchema( GusSchema gusSchema ) {
        setGusSchema( gusSchema );
        setName( gusSchema.getName( ) + verSuffix );
        setDatabase( gusSchema.getDatabase( ) );
        for ( Iterator<GusTable> i = toGusTables(gusSchema.getTables()).iterator( ); i.hasNext( ); ) {
            GusTable table = i.next( );
            if ( table.getVersionTable( ) != null ) {
                addTable( table.getVersionTable( ) );
            }
        }
        for ( Iterator<GusView> i = toGusViews(gusSchema.getViews()).iterator( ); i.hasNext( ); ) {
            GusView view = i.next( );
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

}
