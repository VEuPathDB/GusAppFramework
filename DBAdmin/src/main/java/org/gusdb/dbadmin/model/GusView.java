package org.gusdb.dbadmin.model;

/**
 * @author msaffitz
 * @version $Revision$ $Date: 2005-06-16 16:35:04 -0400 (Thu, 16 Jun
 *          2005) $
 */
public class GusView extends View {

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

    public void setGusSuperclass( GusView superclass ) {
        super.setSuperclass( superclass );
        if ( superclass.getVersionView( ) != null && this.versionView != null ) {
            versionView.setSuperclass( superclass.getVersionView( ) );
        }
    }

    public void addGusSubclass( GusView subclass ) {
        super.addSubclass( subclass );
        if ( subclass.getVersionView( ) != null && this.versionView != null ) {
            versionView.addSubclass( subclass.getVersionView( ) );
        }
    }

    public void removeGusSubclass( GusView subclass ) {
        super.removeSubclass( subclass );
        if ( subclass.getVersionView( ) != null && this.versionView != null ) {
            versionView.removeSubclass( subclass.getVersionView( ) );
        }
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
