package org.gusdb.dbadmin.model;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashSet;
import java.util.Iterator;
import java.util.TreeSet;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

/**
 * @author msaffitz
 * @version $Revision$ $Date: 2005-06-16 16:35:04 -0400 (Thu, 16 Jun
 *          2005) $
 */
public abstract class Table extends DatabaseObject {

    protected static final Log log                = LogFactory
                                                          .getLog( Table.class );

    private String             tablespace;
    private boolean            housekeeping       = true;
    private boolean            updatable          = true;
    private Schema             schema;
    private Collection         column             = new ArrayList( );            // of
    // type
    // Column
    private Collection         housekeepingColumn = new ArrayList( );
    private Collection         subclass           = new HashSet( );              // of
    // type
    // Table
    private Table              superclass;
    private Constraint         primaryKey;

    protected final String     verSuffix          = "Ver";

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
     * Returns all columns in the table, including housekeeping,
     * but not including columns from the superclass.  Kept for
     * compatability as a bean, but really you should use
     * getColumnsExcludeSuperclass
     * 
     * @deprecated
     * @see getColumnsExplainSuperclass
     */
    public Collection getColumns( ) {
        return getColumnsExcludeSuperclass( true );
    }

    /**
     * @deprecated
     * @param housekeeping true to include housekeeping columns
     * @return
     */
    public Collection getColumns( boolean housekeeping ) {
        ArrayList columns = new ArrayList( );
        columns.addAll( column );
        if ( housekeeping ) {
            columns.addAll( housekeepingColumn );
        }
        return columns;
    }
    
    /**
     * 
     * @param housekeeping true to include housekeeping columns
     * @return collection of columns specific to this table
     */
    public Collection getColumnsExcludeSuperclass( boolean housekeeping ) {
        ArrayList columns = new ArrayList( );
        columns.addAll( column );
        if ( housekeeping ) {
            columns.addAll( housekeepingColumn );
        }
        return columns;
    }
    
    /**
     * 
     * @param housekeeping true to include housekeeping columns
     * @return collection of columns including those from any superclasses
     */
    
    public Collection getColumnsIncludeSuperclass( boolean housekeeping ) {
        ArrayList columns = new ArrayList( );
        if ( getSuperclass() != null ) {
            columns.addAll( getSuperclass().getColumnsIncludeSuperclass(false));
        }
        columns.addAll( getColumnsExcludeSuperclass( housekeeping ) );
        return columns;
    }

    public void addColumn( Column column ) {
        if ( !this.column.contains( column ) ) {
            log.debug( "Adding Column: '" + column.getName( ) + "' to Table: '"
                    + getName( ) + "' of Type: '" + column.getType( ) + "'" );
            this.column.add( column );
            column.setTable( this );
        }
    }

    public void removeColumn( Column column ) {
        boolean removed = this.column.remove( column );
        if ( removed ) column.setTable( null );
    }

    public Collection getHousekeepingColumns( ) {
        return housekeepingColumn;
    }

    public void addHousekeepingColumn( HousekeepingColumn housekeepingColumn ) {
        if ( !this.housekeepingColumn.contains( housekeepingColumn ) ) {
            log.debug( "Adding HousekeepingColumn: '"
                    + housekeepingColumn.getName( ) + "' to Table: '"
                    + getName( ) + "'" );
            this.housekeepingColumn.add( housekeepingColumn );
            housekeepingColumn.setTable( this );
        }
    }

    public void setHousekeepingColumns( Collection housekeepingColumns ) {
        log.debug( "Setting HousekeepingColumns for Table: '" + getName( )
                + "'" );
        this.housekeepingColumn.clear( );
        for ( Iterator i = housekeepingColumns.iterator( ); i.hasNext( ); ) {
            HousekeepingColumn col = (HousekeepingColumn) i.next( );
            addHousekeepingColumn( (HousekeepingColumn) col.clone( ) );
        }
    }

    public void removeHousekeepingColumn( HousekeepingColumn housekeepingColumn ) {
        boolean removed = this.housekeepingColumn.remove( housekeepingColumn );
        if ( removed ) housekeepingColumn.setTable( null );
    }

    public Collection getSubclasss( ) {
        return subclass;
    }

    /**
     * Alias for getSubclasses()
     * @return
     */
    public Collection getSubclasses( ) {
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
            log.debug( "Setting superclass: '" + table.getName( )
                    + "' for Table: '" + getName( ) + "'" );
            if ( this.superclass != null ) this.superclass
                    .removeSubclass( this );
            this.superclass = table;
            if ( table != null ) table.addSubclass( this );
        }
    }

    public String getPrimaryKeyName( ) {
        if ( getPrimaryKey( ) == null ) return null;
        if ( getPrimaryKey( ).getConstrainedColumns( ).isEmpty( ) ) return null;
        ArrayList columns = (ArrayList) getPrimaryKey( )
                .getConstrainedColumns( );
        return ((Column) columns.get( 0 )).getName( );
    }

    public Constraint getPrimaryKey( ) {
        return primaryKey;
    }

    public boolean removePrimaryKey( ) {
        boolean removed = false;
        Constraint pk = this.primaryKey;
        if ( pk != null && pk.getConstrainedTable( ) != null ) {
            this.primaryKey = null;
            removed = true;
        }
        if ( removed ) pk.setConstrainedTable( null );
        return removed;
    }

    public void setPrimaryKey( Constraint primaryKey ) {
        if ( this.primaryKey != primaryKey ) {
            log.debug( "Setting primary key for Table: '" + name + "'" );
            removePrimaryKey( );
            this.primaryKey = primaryKey;
            if ( primaryKey != null ) primaryKey.setConstrainedTable( this );
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
        for ( Iterator i = getColumnsIncludeSuperclass( true ).iterator( ); i.hasNext( ); ) {
            Column column = (Column) i.next( );
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

    public static Table getTableFromRef( Database db, String ref ) {
        String[] path = ref.split( "/" );
        if ( path.length != 2 ) {
            log.error( "Invalid table ref: " + ref );
            throw new RuntimeException( "Invalid table ref" );
        }
        Table table = db.getSchema( path[0] ).getTable( path[1] );
        if ( table == null ) {
            log.error( "Unable to find table for ref: " + ref );
            throw new RuntimeException( "Invalid table ref" );
        }
        log.debug( "Resolved: " + table.getName( ) );
        return table;
    }

    /**
     * TreeSet getSortedChildren() { TreeSet children = new TreeSet();
     * children.addAll(getColumns()); children.addAll(getHousekeepingColumns());
     * children.addAll(getSubclasss()); return children; }
     */
    public boolean equals( DatabaseObject o ) {
        Table other = (Table) o;

        if ( !tablespace.equals( other.getTablespace( ) ) ) return false;
        if ( housekeeping != other.isHousekeeping( ) ) return false;
        if ( updatable != other.isUpdatable( ) ) return false;

        return super.equals( o );
    }
    
    public boolean columnsEqual( Table other ) {
        if ( this.getColumnsExcludeSuperclass(false).size() != other.getColumnsExcludeSuperclass(false).size() ) return false;
        for ( int i = 0; i < getColumnsExcludeSuperclass(false).size(); i++ ) {
            Column leftCol = (Column) getColumnsExcludeSuperclass(false).toArray()[i];
            Column rightCol = (Column) getColumnsExcludeSuperclass(false).toArray()[i];
            if ( ! leftCol.equals(rightCol)) return false;
        }
        return true;
    }
    
    public boolean subclassesEqual( Table other ) {
        if ( getSubclasses().isEmpty() && other.getSubclasses().isEmpty() ) return true;
        
        Object[] leftSubclasses = (Object[]) ( new TreeSet(getSubclasses())).toArray();
        Object[] rightSubclasses = (Object[]) ( new TreeSet(other.getSubclasses())).toArray();
        
        if ( this.getSubclasses().size() != other.getSubclasses().size() ) return false;
        for ( int i = 0; i < getSubclasses().size(); i++ ) {
            Table leftSubclass = (Table) leftSubclasses[i];
            Table rightSubclass = (Table) rightSubclasses[i];
            if ( ! leftSubclass.equals(rightSubclass) ) return false;
            if ( ! leftSubclass.columnsEqual(rightSubclass) ) return false;
            if ( ! leftSubclass.constraintsEqual(rightSubclass) ) return false;
            if ( ! leftSubclass.indexesEqual(rightSubclass) ) return false;
        }
        return true;
    }
    
    public boolean constraintsEqual( Table other ) {
        // TODO Implement
        return true;
    }
    
    public boolean indexesEqual( Table other ) {
       // Index[] leftIndexes = (Index[]) (TreeSet) getIndexes()).toArray();
       // Index[] rightIndexes = (Index[]) ((TreeSet) getIndexes()).toArray();
       // TODO Implement
        
        return true;
    }
 
    
}
