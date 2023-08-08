package org.gusdb.dbadmin.model;

import java.util.TreeSet;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * @author msaffitz
 * @created May 2, 2005
 * @version $Revision$ $Date: 2005-06-16 16:35:04 -0400 (Thu, 16 Jun
 *          2005) $
 */
public abstract class Column extends DatabaseObject {

    private static final Logger log = LogManager.getLogger( Column.class );

    private int                length;
    private int                precision;
    private boolean            nullable;

    public enum ColumnType {
        CHARACTER, CLOB, BLOB, DATE, FLOAT, STRING, NUMBER, UNDEFINED
    }

    private ColumnType          type;
    private TreeSet<Constraint> constraint = new TreeSet<Constraint>( );
    protected Table             table;

    public TreeSet<Constraint> getConstraints( ) {
        return constraint;
    }

    public void addConstraint( Constraint constraint ) {
        if ( !this.constraint.contains( constraint ) ) {
            log.debug( "Adding constraint: '" + constraint.getName( ) + "' to Column: '" + getName( ) + "'" );
            this.constraint.add( constraint );
            constraint.addConstrainedColumn( this );
        }
    }

    public void removeConstraint( Constraint constraint ) {
        log.debug( "Removing constraint: '" + constraint.getName( ) + "' from Column: '" + getName( ) + "'" );

        boolean removed = this.constraint.remove( constraint );

        if ( removed ) {
            constraint.removeConstrainedColumn( this );
        }
    }

    public Table getTable( ) {
        return table;
    }

    public void setTable( Table table ) {
        if ( this.table != table ) {
            if ( this.table != null ) {
                this.table.removeColumn( this );
            }
            this.table = table;
            if ( table != null ) {
                table.addColumn( this );
            }
        }
    }

    public int getPrecision( ) {
        return precision;
    }

    public void setPrecision( int precision ) {
        this.precision = precision;
    }

    public int getLength( ) {
        return length;
    }

    public void setLength( int length ) {
        this.length = length;
    }

    public boolean isNullable( ) {
        return nullable;
    }

    public void setNullable( boolean nullable ) {
        this.nullable = nullable;
    }

    public ColumnType getType( ) {
        return type;
    }

    public void setType( String type ) {
        this.type = ColumnType.valueOf( type );
    }

    public void setType( ColumnType columnType ) {
        this.type = columnType;
    }

    @Override
    public boolean equals( Object other ) {
        if (!(other instanceof Column)) return false;
        Column o = (Column)other;
        if ( length != o.getLength( ) ) return false;
        if ( precision != o.getPrecision( ) ) return false;
        if ( type != o.getType( ) ) return false;
        return super.equals( o );
    }

}
