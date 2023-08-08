package org.gusdb.dbadmin.model;

import java.util.ArrayList;

/**
 * @author msaffitz
 * @version $Revision$ $Date: 2005-06-16 16:35:04 -0400 (Thu, 16 Jun
 *          2005) $
 */
public class Index extends DatabaseObject {

    private String               tablespace;
    private ArrayList<String>    columnRef = new ArrayList<String>( );
    private ArrayList<GusColumn> column    = new ArrayList<GusColumn>( );
    private GusTable             table;

    public enum IndexType {
        NORMAL, BITMAP
    }

    private IndexType type;

    public ArrayList<GusColumn> getColumns( ) {
        return column;
    }

    public void addColumn( GusColumn column ) {
        if ( !this.column.contains( column ) ) {
            this.column.add( column );
            column.addIndex( this );
        }
    }

    public void removeColumn( GusColumn column ) {
        boolean removed = this.column.remove( column );
        if ( removed ) column.removeIndex( this );
    }

    public GusTable getTable( ) {
        return table;
    }

    public void setTable( GusTable table ) {
        if ( this.table != table ) {
            if ( this.table != null ) this.table.removeIndex( this );
            this.table = table;
            if ( table != null ) table.addIndex( this );
        }
    }

    public IndexType getType( ) {
        return type;
    }

    public void setType( IndexType indexType ) {
        this.type = indexType;
    }

    public String getTablespace( ) {
        return tablespace;
    }

    public void setTablespace( String _tablespace ) {
        tablespace = _tablespace;
    }

    public void setType( String _type ) {
        this.type = IndexType.valueOf( _type );
    }

    public ArrayList<String> getColumnRefs( ) {
        return columnRef;
    }

    public void setColumnRefs( ArrayList<String> _columnRef ) {
        columnRef = _columnRef;
    }

    public void addColumnRef( String _columnRef ) {
        if ( !columnRef.contains( _columnRef ) ) columnRef.add( _columnRef );
    }

    public void removeColumnRef( String _columnRef ) {
        columnRef.remove( _columnRef );
    }

    public void resolveReferences( Database db ) {
        for ( String ref : getColumnRefs() ) {
            addColumn( (GusColumn) db.getColumnFromRef( ref ) );
        }
    }

    @Override
    public boolean equals( Object o ) {
        if (!(o instanceof Index)) return false;
        Index i = (Index)o;
        if (!tablespace.equals(i.getTablespace())) return false;
        if (type != i.getType()) return false;
        return super.equals(i);
    }

}
