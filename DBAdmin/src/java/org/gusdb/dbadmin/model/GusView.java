package org.gusdb.dbadmin.model;

import java.util.ArrayList;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

/**
 * @author msaffitz
 * @version $Revision$ $Date: 2005-06-16 16:35:04 -0400 (Thu, 16 Jun
 *          2005) $
 */
public class GusView extends View {

    protected final Log log = LogFactory.getLog( GusView.class );

    private String      documentation;
    private boolean     versioned;
    private VersionView versionView;

    public GusView( ) {}

    public String getDocumentation( ) {
        return this.documentation;
    }

    public void setDocumentation( String documentation ) {
        this.documentation = documentation;
    }

    public boolean isVersioned( ) {
        return this.versioned;
    }

    public void setVersioned( boolean versioned ) {
        if ( this.versioned && !versioned ) {
            this.versioned = versioned;
            this.versionView.setSchema( null );
            this.versionView = null;
        }
        if ( !this.versioned && versioned ) {
            this.versioned = versioned;
            versionView = new VersionView( this );
        }
    }

    public VersionView getVersionView( ) {
        return this.versionView;
    }

    @Override
    public GusTable getTable() {
        return (GusTable) super.getTable();
    }
    
    public void setTable( GusTable table ) {
        super.setTable( table );
        if ( table.getVersionTable( ) != null && this.versionView != null ) {
            versionView.setTable( table.getVersionTable( ) );
        }
    }

    public void setSuperclass( GusView superclass ) {
        super.setSuperclass( superclass );
        if ( superclass.getVersionView( ) != null && this.versionView != null ) {
            versionView.setSuperclass( superclass.getVersionView( ) );
        }
    }

    public void addSubclass( GusView subclass ) {
        super.addSubclass( subclass );
        if ( subclass.getVersionView( ) != null && this.versionView != null ) {
            versionView.addSubclass( subclass.getVersionView( ) );
        }
    }

    public void removeSubclass( GusView subclass ) {
        super.removeSubclass( subclass );
        if ( subclass.getVersionView( ) != null && this.versionView != null ) {
            versionView.removeSubclass( subclass.getVersionView( ) );
        }
    }

    @Override
    public ArrayList<GusView> getSubclasses() {
        return (ArrayList<GusView>) super.getSubclasses();
    }
    
    public void setSchema( GusSchema schema ) {
        super.setSchema( schema );
        if ( versionView != null ) {
            versionView.setSchema( schema.getVersionSchema( ) );
        }
    }

    @Override
    public void setName( String name ) {
        super.setName( name );
        if ( versionView != null ) {
            versionView.setName( name + verSuffix );
        }
    }

    @Override
    public boolean equals( DatabaseObject o ) {
        GusView other = (GusView) o;
        if ( versioned != other.isVersioned( ) ) return false;
        return super.equals( o );
    }

}
