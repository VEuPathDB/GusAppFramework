package org.gusdb.dbadmin.model;


/**
 * @author msaffitz
 * @created May 2, 2005
 * @version $Revision$ $Date: 2005-06-16 16:35:04 -0400 (Thu, 16 Jun
 *          2005) $
 */
public class VersionTable extends Table {

    private GusTable           gusTable;

    public VersionTable( GusTable gusTable ) {
        setGusTable( gusTable );
        setName( gusTable.getName( ) + verSuffix );
        if ( gusTable.getSchema( ) != null ) {
            setSchema( ((GusSchema) gusTable.getSchema( )).getVersionSchema( ) );
        }

        setTablespace( gusTable.getTablespace( ) );
        setHousekeeping( gusTable.isHousekeeping( ) );
        setUpdatable( gusTable.isUpdatable( ) );

        if ( gusTable.getSuperclass( ) != null ) {
            setSuperclass( gusTable.getSuperclass( ).getVersionTable( ) );
        }

        for ( Column col : gusTable.getColumnsExcludeSuperclass( true ) ) {
            if ( col.getClass( ) == GusColumn.class ) {
                addColumn( (Column) ((GusColumn) col).clone( ) );
            }
        }

        for ( GusTable gusSubclass : gusTable.getSubclasses( ) ) {
            if ( !gusSubclass.isVersioned( ) ) {
                gusSubclass.setVersioned( true );
            }
            addSubclass( gusSubclass.getVersionTable( ) );
        }
    }

    public GusTable getGusTable( ) {
        return this.gusTable;
    }

    public void setGusTable( GusTable gusTable ) {
        this.gusTable = gusTable;
    }
}
