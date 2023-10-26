package org.gusdb.dbadmin.model;

import java.util.ArrayList;
import java.util.TreeSet;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * @author msaffitz
 * @version $Revision$ $Date: 2005-06-16 16:35:04 -0400 (Thu, 16 Jun
 *          2005) $
 */
public abstract class Table extends DatabaseObject {

    private static final Logger log = LogManager.getLogger( Table.class );

    private String                        tablespace;
    private boolean                       housekeeping       = true;
    private boolean                       updatable          = true;
    private Schema                        schema;
    private ArrayList<Column>             column             = new ArrayList<>( );
    private ArrayList<HousekeepingColumn> housekeepingColumn = new ArrayList<>( );
    private TreeSet<Table>                subclass           = new TreeSet<>( );
    private Table                         superclass;

    protected final String                verSuffix          = "Ver";

    public Schema getSchema( ) {
        return schema;
    }

    public void setSchema( Schema schema ) {
        if ( this.schema != schema ) {
            if ( this.schema != null ) this.schema.removeTable( this );
            this.schema = schema;
            if ( schema != null ) schema.addTable( this );
        }
    }

    /**
     * @param housekeeping true to include housekeeping columns
     * @return collection of columns specific to this table
     */
    public ArrayList<Column> getColumnsExcludeSuperclass( boolean housekeeping ) {
        ArrayList<Column> columns = new ArrayList<>( );
        columns.addAll( column );
        if ( housekeeping ) {
            columns.addAll( housekeepingColumn );
        }
        return columns;
    }

    /**
     * @param housekeeping true to include housekeeping columns
     * @return collection of columns including those from any superclasses
     */
    public ArrayList<Column> getColumnsIncludeSuperclass( boolean housekeeping ) {
        ArrayList<Column> columns = new ArrayList<Column>( );
        if ( getSuperclass( ) != null ) {
            columns.addAll( getSuperclass( ).getColumnsIncludeSuperclass( false ) );
        }
        columns.addAll( getColumnsExcludeSuperclass( housekeeping ) );
        return columns;
    }

    public void addColumn( Column column ) {
        if ( !this.column.contains( column ) ) {
            log.debug( "Adding Column: '" + column.getName( ) + "' to Table: '" + getName( ) + "' of Type: '"
                    + column.getType( ) + "'" );
            this.column.add( column );
            column.setTable( this );
        }
    }

    public void removeColumn( Column column ) {
        boolean removed = this.column.remove( column );
        if ( removed ) column.setTable( null );
    }

    public ArrayList<HousekeepingColumn> getHousekeepingColumns( ) {
        return housekeepingColumn;
    }

    public void addHousekeepingColumn( HousekeepingColumn housekeepingColumn ) {
        if ( !this.housekeepingColumn.contains( housekeepingColumn ) ) {
            log.debug( "Adding HousekeepingColumn: '" + housekeepingColumn.getName( ) + "' to Table: '" + getName( )
                    + "'" );
            this.housekeepingColumn.add( housekeepingColumn );
            housekeepingColumn.setTable( this );
        }
    }

    public void setHousekeepingColumns( ArrayList<HousekeepingColumn> housekeepingColumns ) {
        log.debug( "Setting HousekeepingColumns for Table: '" + getName( ) + "'" );
        this.housekeepingColumn.clear( );
        for ( HousekeepingColumn col : housekeepingColumns ) {
            addHousekeepingColumn( (HousekeepingColumn) col.clone( ) );
        }
    }

    public void removeHousekeepingColumn( HousekeepingColumn housekeepingColumn ) {
        boolean removed = this.housekeepingColumn.remove( housekeepingColumn );
        if ( removed ) housekeepingColumn.setTable( null );
    }

    public TreeSet<Table> getSubclasss( ) {
        return subclass;
    }

    /**
     * Alias for getSubclasses()
     * 
     * @return
     */
    public TreeSet<Table> getSubclasses( ) {
        return getSubclasss( );
    }

    public void addSubclass( Table table ) {
        if ( !this.subclass.contains( table ) ) {
            this.subclass.add( table );
            table.setSuperclass( this );
        }
    }

    public void removeSubclass( Table table ) {
        boolean removed = this.subclass.remove( table );
        if ( removed ) table.setSuperclass( null );
    }

    public Table getSuperclass( ) {
        return superclass;
    }

    public void setSuperclass( Table table ) {
        if ( this.superclass != table ) {
            log.debug( "Setting superclass: '" + table.getName( ) + "' for Table: '" + getName( ) + "'" );
            if ( this.superclass != null ) this.superclass.removeSubclass( this );
            this.superclass = table;
            table.addSubclass( this );
        }
    }

    public String getTablespace( ) {
        return tablespace;
    }

    public void setTablespace( String tablespace ) {
        this.tablespace = tablespace;
    }

    public Column getColumn( String name ) {
        if ( name == null ) return null;

        for ( Column column : getColumnsIncludeSuperclass( true ) ) {
            if ( column.getName( ).compareToIgnoreCase( name ) == 0 ) {
                return column;
            }
        }
        return null;
    }

    public boolean isHousekeeping( ) {
        return housekeeping;
    }

    public void setHousekeeping( boolean housekeeping ) {
        this.housekeeping = housekeeping;
    }

    public boolean isUpdatable( ) {
        return updatable;
    }

    public void setUpdatable( boolean updatable ) {
        this.updatable = updatable;
    }

    @Override
    public boolean equals( DatabaseObject o ) {
        Table other = (Table) o;

        if ( housekeeping != other.isHousekeeping( ) ) return false;
        if ( updatable != other.isUpdatable( ) ) return false;

        return super.equals( o );
    }

    public boolean columnsEqual( Table other ) {
        if ( this.getColumnsExcludeSuperclass( false ).size( ) != other.getColumnsExcludeSuperclass( false ).size( ) ) return false;

        for ( int i = 0; i < getColumnsExcludeSuperclass( false ).size( ); i++ ) {
            Column leftCol = (Column) getColumnsExcludeSuperclass( false ).toArray( )[i];
            Column rightCol = (Column) other.getColumnsExcludeSuperclass( false ).toArray( )[i];
            if ( !leftCol.equals( rightCol ) ) return false;
        }
        return true;
    }

    public boolean subclassesEqual( Table other ) {
        if ( getSubclasses( ).isEmpty( ) && other.getSubclasses( ).isEmpty( ) ) return true;

        ArrayList<Table> leftSubclasses = new ArrayList<Table>( getSubclasses( ) );
        ArrayList<Table> rightSubclasses = new ArrayList<Table>( getSubclasses( ) );

        if ( this.getSubclasses( ).size( ) != other.getSubclasses( ).size( ) ) return false;

        for ( int i = 0; i < getSubclasses( ).size( ); i++ ) {
            Table leftSubclass = leftSubclasses.get( i );
            Table rightSubclass = rightSubclasses.get( i );
            if ( !leftSubclass.equals( rightSubclass ) ) return false;
            if ( !leftSubclass.columnsEqual( rightSubclass ) ) return false;
            if ( !leftSubclass.constraintsEqual( rightSubclass ) ) return false;
            if ( !leftSubclass.indexesEqual( rightSubclass ) ) return false;
        }
        return true;
    }

    public boolean constraintsEqual( Table other ) {
        // TODO Implement
        return true;
    }

    public boolean indexesEqual( Table other ) {
        // TODO Implement
        return true;
    }

}
