package org.gusdb.dbadmin.model;

import java.util.TreeSet;

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

    @Override
    public TreeSet<GusTable> getTables() {
        return (TreeSet<GusTable>) super.getTables();
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

    @Override
    public void setName( String name ) {
        super.setName( name );
        versionSchema.setName( name + verSuffix );
    }

    @Override
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
        for ( GusTable table : getTables() ) {
            table.resolveReferences( db );
        }
        // This is clunky to avoid concurrent modification exception
        Object[] tables = getTables().toArray();
        for ( int i = 0; i < tables.length; i++ ) {
            GusTable table = (GusTable) tables[i];
            for ( GusTable subclass : table.getSubclasses() ) {
                subclass.setSchema(this);
            }
        }
    }

}
