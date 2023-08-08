package org.gusdb.dbadmin.model;

import java.util.ArrayList;

import org.gusdb.dbadmin.util.ColumnPair;

/**
 * @author msaffitz
 * @version $Revision$ $Date: 2005-06-16 16:35:04 -0400 (Thu, 16 Jun
 *          2005) $
 */
public abstract class View extends DatabaseObject {

    private String                sql;
    private boolean               materialized;

    private Schema                schema;

    private View                  superclass;
    private ArrayList<View>       subclass  = new ArrayList<>( );
    private ArrayList<ColumnPair> column    = new ArrayList<>( );

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

    public void setSuperclass( View view ) {
        if ( this.superclass != view ) {
            if ( this.superclass != null ) this.superclass.removeSubclass( this );
            this.superclass = view;
            if ( view != null ) view.addSubclass( this );
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

    public ArrayList<View> getSubclasses( ) {
        return subclass;
    }

    public void addSubclass( View view ) {
        if ( !this.subclass.contains( view ) ) {
            this.subclass.add( view );
            view.setSuperclass( this );
        }
    }

    public void removeSubclass( View view ) {
        boolean removed = this.subclass.remove( view );
        if ( removed ) view.setSuperclass( null );
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
    public boolean equals( Object other ) {
        if (!(other instanceof View)) return false;
        View v = (View)other;
        if (!sql.equals(v.getSql())) return false;
        return super.equals(v);
    }

}
