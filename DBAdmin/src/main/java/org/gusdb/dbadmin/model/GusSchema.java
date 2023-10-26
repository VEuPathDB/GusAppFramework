package org.gusdb.dbadmin.model;

import java.util.Collection;
import java.util.List;
import java.util.stream.Collectors;

/**
 * @author msaffitz
 * @version $Revision$ $Date: 2005-06-16 16:35:04 -0400 (Thu, 16 Jun
 *          2005) $
 */
public class GusSchema extends Schema {

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

    public void addGusTable( GusTable table ) {
        super.addTable( table );
        if ( table.getVersionTable( ) != null ) {
            versionSchema.addTable( table.getVersionTable( ) );
        }
    }

    public void removeGusTable( GusTable table ) {
        super.removeTable( table );
        if ( table.getVersionTable( ) != null ) {
            versionSchema.removeTable( table.getVersionTable( ) );
        }
    }

    public static List<GusTable> toGusTables(Collection<Table> tables) {
        return tables.stream()
            .map(t -> (GusTable)t)
            .collect(Collectors.toList());
    }

    public void addGusView( GusView view ) {
        super.addView( view );
        if ( view.getVersionView( ) != null ) {
            versionSchema.addView( view.getVersionView( ) );
        }
    }

    public void removeGusView( GusView view ) {
        super.removeView( view );
        if ( view.getVersionView( ) != null ) {
            versionSchema.removeView( view.getVersionView( ) );
        }
    }

    public static List<GusView> toGusViews(Collection<View> views) {
      return views.stream()
          .map(t -> (GusView)t)
          .collect(Collectors.toList());
    }

    void resolveReferences( Database db ) {
        for ( GusTable table : toGusTables(getTables()) ) {
            table.resolveReferences( db );
        }
        // This is clunky to avoid concurrent modification exception
        Object[] tables = getTables().toArray();
        for ( int i = 0; i < tables.length; i++ ) {
            GusTable table = (GusTable) tables[i];
            for ( GusTable subclass : toGusTables(table.getSubclasses()) ) {
                subclass.setSchema(this);
            }
        }
    }

}
