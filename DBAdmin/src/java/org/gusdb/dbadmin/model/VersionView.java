package org.gusdb.dbadmin.model;

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
            setSuperclass( ((GusView) gusView.getSuperclass( )).getVersionView( ) );
        }
        for ( GusView subclass : gusView.getSubclasses() ) {
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
}
