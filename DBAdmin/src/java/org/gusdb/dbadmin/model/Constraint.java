package org.gusdb.dbadmin.model;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Iterator;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

/**
 * @author msaffitz
 * @version $Revision$ $Date: 2005-06-16 16:35:04 -0400 (Thu, 16 Jun
 *          2005) $
 */
public class Constraint extends DatabaseObject {

    protected final Log    log                  = LogFactory
                                                        .getLog( Constraint.class );

    private Collection     constrainedColumnRef = new ArrayList( );
    private String         constrainedTableRef;
    private String         referencedTableRef;
    private Collection     referencedColumnRef  = new ArrayList( );
    private Collection     referencedColumn     = new ArrayList( );
    private Collection     constrainedColumn    = new ArrayList( );
    private ConstraintType type;
    private GusTable       referencedTable;
    private Table          constrainedTable;

    public Collection getReferencedColumns( ) {
        return referencedColumn;
    }

    public void addReferencedColumn( GusColumn column ) {
        if ( !this.referencedColumn.contains( column ) ) {
            this.referencedColumn.add( column );
            column.addReferentialConstraint( this );
        }
    }

    public void removeReferencedColumn( GusColumn column ) {
        boolean removed = this.referencedColumn.remove( column );
        if ( removed ) column.removeReferentialConstraint( this );
    }

    public Collection getConstrainedColumns( ) {
        return constrainedColumn;
    }

    public void addConstrainedColumn( Column column ) {
        if ( !this.constrainedColumn.contains( column ) ) {
            this.constrainedColumn.add( column );
            column.addConstraint( this );
        }
    }

    public void removeConstrainedColumn( Column column ) {
        log.debug( "Removing Column: '" + column.getName( )
                + "' from Constraint: '" + getName( ) + "'" );
        boolean removed = this.constrainedColumn.remove( column );
        if ( removed ) column.removeConstraint( this );
    }

    public GusTable getReferencedTable( ) {
        return referencedTable;
    }

    public void setReferencedTable( GusTable table ) {
        if ( this.referencedTable != table ) {
            if ( this.referencedTable != null ) this.referencedTable
                    .removeReferentialConstraint( this );
            this.referencedTable = table;
            if ( table != null ) table.addReferentialConstraint( this );
        }
    }

    public Table getConstrainedTable( ) {
        return constrainedTable;
    }

    public void setConstrainedTable( Table table ) {
        if ( this.constrainedTable != table ) {
            String name = "null";
            if ( table != null ) name = table.getName( );
            log.debug( "Setting Table: '" + name + "' for Constraint: '"
                    + getName( ) + "' of Type: '" + getType( ) + "'" );

            if ( this.constrainedTable != null
                    && this.type != ConstraintType.PRIMARY_KEY ) ((GusTable) this.constrainedTable)
                    .removeConstraint( this );

            if ( this.constrainedTable != null
                    && this.type == ConstraintType.PRIMARY_KEY ) this.constrainedTable
                    .setPrimaryKey( null );

            this.constrainedTable = table;

            if ( table != null && this.type != ConstraintType.PRIMARY_KEY ) ((GusTable) table)
                    .addConstraint( this );

            if ( table != null && this.type == ConstraintType.PRIMARY_KEY ) table
                    .setPrimaryKey( this );
        }
    }

    public ConstraintType getType( ) {
        return type;
    }

    public void setType( ConstraintType constraintType ) {
        Table constrained = getConstrainedTable( );
        if ( constrained != null ) setConstrainedTable( (Table) null );
        this.type = constraintType;
        setConstrainedTable( constrained );
    }

    public void setType( String type ) {
        setType( ConstraintType.getInstance( type ) );
    }

    public Collection getReferencedColumnRefs( ) {
        return referencedColumnRef;
    }

    public void setReferencedColumnRefs( Collection referencedColumnRef ) {
        this.referencedColumnRef = referencedColumnRef;
    }

    public void addReferencedColumnRef( String _referencedColumnRef ) {
        if ( !referencedColumnRef.contains( _referencedColumnRef ) ) {
            referencedColumnRef.add( _referencedColumnRef );
        }
    }

    public String getReferencedTableRef( ) {
        return referencedTableRef;
    }

    public void setReferencedTableRef( String referencedTableRef ) {
        this.referencedTableRef = referencedTableRef;
    }

    public void removeReferencedColumnRef( String referencedColumnRef ) {
        this.referencedColumnRef.remove( referencedColumnRef );
    }

    public Collection getConstrainedColumnRefs( ) {
        return constrainedColumnRef;
    }

    public void setConstrainedColumnRefs( Collection constrainedColumnRef ) {
        this.constrainedColumnRef = constrainedColumnRef;
    }

    public void addConstrainedColumnRef( String _constrainedColumnRef ) {
        if ( !constrainedColumnRef.contains( _constrainedColumnRef ) ) {
            constrainedColumnRef.add( _constrainedColumnRef );
        }
    }

    public void removeConstrainedColumnRef( String _constrainedColumnRef ) {
        constrainedColumnRef.remove( _constrainedColumnRef );
    }

    public String getConstrainedTableRef( ) {
        return constrainedTableRef;
    }

    public void setConstrainedTableRef( String constrainedTableRef ) {
        this.constrainedTableRef = constrainedTableRef;
    }

    void resolveReferences( Database db ) {
        for ( Iterator i = getConstrainedColumnRefs( ).iterator( ); i.hasNext( ); ) {
            addConstrainedColumn( Column.getColumnFromRef( db, (String) i
                    .next( ) ) );
        }
        if ( getType( ) == ConstraintType.FOREIGN_KEY ) {
            for ( Iterator i = getReferencedColumnRefs( ).iterator( ); i
                    .hasNext( ); ) {
                addReferencedColumn( (GusColumn) Column.getColumnFromRef( db,
                        (String) i.next( ) ) );
            }
            if ( getReferencedTableRef( ) == null ) log.error( "Null ref for "
                    + getName( ) );
            setReferencedTable( (GusTable) Table.getTableFromRef( db,
                    getReferencedTableRef( ) ) );
        }
    }

    /**
     * TreeSet getSortedChildren() { TreeSet children = new TreeSet();
     * children.addAll(getReferencedColumns());
     * children.addAll(getConstrainedColumns()); return children; } public
     * boolean deepEquals(DatabaseObject o, Writer writer) throws IOException {
     * if (o.getClass() != Constraint.class) return false; if
     * (equals((Constraint) o, new HashSet(), writer)) return true; return
     * false; }
     */
    public boolean equals( DatabaseObject o ) {
        Constraint other = (Constraint) o;

        if ( type != other.getType( ) ) return false;
        return super.equals( o );
    }
}
