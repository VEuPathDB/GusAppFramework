package org.gusdb.dbadmin.model;

/**
 * @author msaffitz
 * @version $Revision$ $Date: 2005-06-16 16:35:04 -0400 (Thu, 16 Jun
 *          2005) $
 */
public class VersionView extends View {

    private GusView     gusView;

    public VersionView( GusView gusView ) {
        setGusView( gusView );
        setName( gusView.getName( ) + verSuffix );
        if ( gusView.getSchema( ) != null ) {
            setSchema( ((GusSchema) gusView.getSchema( )).getVersionSchema( ) );
        }
        if ( gusView.getSuperclass( ) != null ) {
            setSuperclass( ((GusView)gusView.getSuperclass()).getVersionView( ) );
        }
        for ( View subclass : gusView.getSubclasses() ) {
            GusView view = (GusView)subclass;
            if ( view.getVersionView( ) != null ) {
                addSubclass( view.getVersionView( ) );
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
