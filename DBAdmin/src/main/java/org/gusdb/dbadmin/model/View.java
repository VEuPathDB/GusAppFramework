package org.gusdb.dbadmin.model;

import java.util.ArrayList;

import org.gusdb.dbadmin.util.ColumnPair;

/**
 * @author msaffitz
 * @version $Revision$ $Date: 2005-06-16 16:35:04 -0400 (Thu, 16 Jun
 *          2005) $
 */
public abstract class View extends DatabaseObject implements Comparable {

    private String                sql;
    private boolean               materialized;

    private Schema                schema;

    private View                  superclass;
    private ArrayList<View>       subclass  = new ArrayList<View>( );
    private ArrayList<ColumnPair> column    = new ArrayList<ColumnPair>( );

    private Table                 table;

    protected String              verSuffix = "Ver";

    public Table getTable( ) {
        return table;
    }

    public void setTable( Table table ) {
        this.table = table;
    }

    public View getSuperclass( ) {
        return superclass;
    }

    public void setSuperclass( View superclass ) {
        if ( this.superclass != superclass ) {
            if ( this.superclass != null ) this.superclass.removeSubclass( this );
            this.superclass = superclass;
            if ( superclass != null ) superclass.addSubclass( this );
        }
    }

    public ArrayList<ColumnPair> getColumns( ) {
        return column;
    }

    public void setColumns( ArrayList<ColumnPair> colpair) {
        column = colpair;
    }

    public void addColumn( ColumnPair columnPair ) {
        if ( !this.column.contains( columnPair ) ) {
            this.column.add( columnPair );
        }
    }

    public void removeColumn( ColumnPair columnPair ) {
        this.column.remove( columnPair );
    }

    public ArrayList<? extends View> getSubclasses( ) {
        return subclass;
    }

    public void addSubclass( View subclass ) {
        if ( !this.subclass.contains( subclass ) ) {
            this.subclass.add( subclass );
            subclass.setSuperclass( this );
        }
    }

    public void removeSubclass( View subclass ) {
        boolean removed = this.subclass.remove( subclass );
        if ( removed ) subclass.setSuperclass( (View) null );
    }

    public Schema getSchema( ) {
        return schema;
    }

    public void setSchema( Schema schema ) {
        if ( this.schema != schema ) {
            if ( this.schema != null ) this.schema.removeView( this );
            this.schema = schema;
            if ( schema != null ) schema.addView( this );
        }
    }

    public String getSql( ) {
        return sql;
    }

    public void setSql( String sql ) {
        this.sql = sql;
    }

    public boolean isMaterialized( ) {
        return materialized;
    }

    public void setMaterialized( boolean materialized ) {
        this.materialized = materialized;
    }

    @Override
    public int compareTo( Object o ) {
        View v = (View) o;
        if ( v == null ) return 1;
        if ( this.getName( ) == null ) {
            if ( v.getName( ) == null ) return 0;
            else return -1;
        }
        return this.getName( ).compareTo( v.getName( ) );
    }

    @Override
    public boolean equals( DatabaseObject o ) {
        View other = (View) o;
        if ( !sql.equals( other.getSql( ) ) ) return false;
        return super.equals( o );
    }
}
