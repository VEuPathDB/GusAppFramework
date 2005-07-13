package org.gusdb.dbadmin.model;

import java.util.Iterator;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

/**
 * @author msaffitz
 * @created May 2, 2005
 * @version $Revision$ $Date: 2005-06-16 16:35:04 -0400 (Thu, 16 Jun
 *          2005) $
 */
public class VersionTable extends Table {

    protected final static Log log = LogFactory.getLog( VersionTable.class );
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
            setSuperclass( ((GusTable) gusTable.getSuperclass( ))
                    .getVersionTable( ) );
        }

        for ( Iterator i = gusTable.getColumns( true ).iterator( ); i.hasNext( ); ) {
            Column col = (Column) i.next( );

            if ( col.getClass( ) == GusColumn.class ) {
                addColumn( (Column) ((GusColumn) col).clone( ) );
            }
        }

        if ( gusTable.getPrimaryKey( ) != null ) {
            Constraint vPk = new Constraint( );

            if ( getName( ).length( ) > 27 ) {
                vPk.setName( getName( ).substring( 0, 26 ) + "_PK" );
            }
            else {
                vPk.setName( getName( ) + "_PK" );
            }
            vPk.setType( ConstraintType.PRIMARY_KEY );
            for ( Iterator i = gusTable.getPrimaryKey( )
                    .getConstrainedColumns( ).iterator( ); i.hasNext( ); ) {
                Column column = (Column) i.next( );

                if ( getColumn( column.getName( ) ) == null ) {
                    log.error( "Should have found column '" + column.getName( )
                            + "' in the version table, but didn't" );
                }
                else {
                    vPk.addConstrainedColumn( getColumn( column.getName( ) ) );
                }
            }
            if ( getColumn( "MODIFICATION_DATE" ) != null ) {
                vPk.addConstrainedColumn( getColumn( "MODIFICATION_DATE" ) );
            }
            setPrimaryKey( vPk );
        }
        for ( Iterator i = gusTable.getSubclasss( ).iterator( ); i.hasNext( ); ) {
            GusTable gusSubclass = (GusTable) i.next( );

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
    /*
     * public boolean deepEquals(DatabaseObject o, Writer writer) throws
     * IOException { if (o.getClass() != VersionTable.class) { return false; }
     * if (equals((VersionTable) o, new HashSet(), writer)) { return true; }
     * return false; } boolean equals(DatabaseObject o, HashSet seen, Writer
     * writer) throws IOException { VersionTable other = (VersionTable) o; if
     * (!super.equals(other, seen, writer)) { return false; } boolean equal =
     * true; if (!gusTable.equals(other.getGusTable(), seen, writer)) { equal =
     * false; } if (!equal) { log.debug("VersionTable attributes vary"); return
     * false; } return compareChildren(other, seen, writer); }
     */
}
