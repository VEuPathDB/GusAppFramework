package org.gusdb.dbadmin.model;

import java.util.ArrayList;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * @author msaffitz
 * @version $Revision$ $Date: 2005-06-16 16:35:04 -0400 (Thu, 16 Jun
 *          2005) $
 */
public class Constraint extends DatabaseObject {

    private static final Logger log = LogManager.getLogger( Constraint.class );

    private ArrayList<String>    constrainedColumnRef = new ArrayList<>();
    private String               constrainedTableRef;
    private String               referencedTableRef;
    private ArrayList<String>    referencedColumnRef  = new ArrayList<>();
    private ArrayList<GusColumn> referencedColumn     = new ArrayList<>();
    private ArrayList<Column>    constrainedColumn    = new ArrayList<>();
    private ConstraintType       type;
    private GusTable             referencedTable;
    private GusTable             constrainedTable;

    public enum ConstraintType {
        UNIQUE, PRIMARY_KEY, FOREIGN_KEY
    }


    public ArrayList<GusColumn> getReferencedColumns( ) {
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

    public ArrayList<Column> getConstrainedColumns( ) {
        return constrainedColumn;
    }

    public void addConstrainedColumn( Column column ) {
        if ( !this.constrainedColumn.contains( column ) ) {
            this.constrainedColumn.add( column );
            column.addConstraint( this );
        }
    }

    public void removeConstrainedColumn( Column column ) {
        log.debug( "Removing Column: '" + column.getName( ) + "' from Constraint: '" + getName( ) + "'" );
        boolean removed = this.constrainedColumn.remove( column );
        if ( removed ) column.removeConstraint( this );
    }

    public GusTable getReferencedTable( ) {
        return referencedTable;
    }

    public void setReferencedTable( GusTable table ) {
        if ( this.referencedTable != table ) {
            if ( this.referencedTable != null ) this.referencedTable.removeReferentialConstraint( this );
            this.referencedTable = table;
            if ( table != null ) table.addReferentialConstraint( this );
        }
    }

    public GusTable getConstrainedTable( ) {
        return constrainedTable;
    }

    public void setConstrainedTable( GusTable table ) {
        if ( this.constrainedTable != table ) {
            String tableName = "null";
            if ( table != null ) tableName = table.getName( );
            log.debug( "Setting Table: '" + tableName + "' for Constraint: '" + getName( ) + "' of Type: '" + getType( )
                    + "'" );

            if ( this.constrainedTable != null && this.type != ConstraintType.PRIMARY_KEY ) {
                this.constrainedTable.removeConstraint( this );
            }
                    

            if ( this.constrainedTable != null && this.type == ConstraintType.PRIMARY_KEY ) {
                this.constrainedTable.setPrimaryKey( null );
            }
                    

            this.constrainedTable = table;

            if ( table != null && this.type != ConstraintType.PRIMARY_KEY ) table.addConstraint( this );
            if ( table != null && this.type == ConstraintType.PRIMARY_KEY ) table.setPrimaryKey( this );
        }
    }

    public ConstraintType getType( ) {
        return type;
    }

    public void setType( ConstraintType constraintType ) {
        GusTable constrained = getConstrainedTable( );
        if ( constrained != null ) setConstrainedTable( (GusTable) null );
        this.type = constraintType;
        setConstrainedTable( constrained );
    }

    public void setType( String type ) {
        setType( ConstraintType.valueOf( type ) );
    }

    public ArrayList<String> getReferencedColumnRefs( ) {
        return referencedColumnRef;
    }

    public void setReferencedColumnRefs( ArrayList<String> referencedColumnRef ) {
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

    public ArrayList<String> getConstrainedColumnRefs( ) {
        return constrainedColumnRef;
    }

    public void setConstrainedColumnRefs( ArrayList<String> constrainedColumnRef ) {
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
        for ( String ref : getConstrainedColumnRefs( ) ) {
            addConstrainedColumn( db.getColumnFromRef( ref ) );
        }
        if ( getType( ) == ConstraintType.FOREIGN_KEY ) {
            for ( String ref : getReferencedColumnRefs( ) ) {
                addReferencedColumn( (GusColumn) db.getColumnFromRef( ref ) );
            }
            if ( getReferencedTableRef( ) == null ) log.error( "Null ref for " + getName( ) );
            setReferencedTable( (GusTable) db.getTableFromRef( getReferencedTableRef( ) ) );
        }
    }

    @Override
    public boolean equals( DatabaseObject o ) {
        Constraint other = (Constraint) o;

        if ( type != other.getType( ) ) return false;
        return super.equals( o );
    }
}
