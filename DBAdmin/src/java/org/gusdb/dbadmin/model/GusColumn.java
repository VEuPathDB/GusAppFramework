package org.gusdb.dbadmin.model;

import java.util.TreeSet;

/**
 * @author msaffitz
 * @version $Revision$ $Date: 2005-06-16 16:35:04 -0400 (Thu, 16 Jun
 *          2005) $
 */
public class GusColumn extends Column {

    private String              documentation;
    private TreeSet<Constraint> referentialConstraint = new TreeSet<Constraint>( );
    private TreeSet<Index>      index                 = new TreeSet<Index>( );
    private VersionColumn       versionColumn;

    public VersionColumn getVersionColumn( ) {
        return this.versionColumn;
    }

    public void setVersionColumn( VersionColumn versionColumn ) {
        this.versionColumn = versionColumn;
    }

    public String getDocumentation( ) {
        return documentation;
    }

    public void setDocumentation( String documentation ) {
        this.documentation = documentation;
    }

    public TreeSet<Constraint> getReferentialConstraints( ) {
        return referentialConstraint;
    }

    public void addReferentialConstraint( Constraint constraint ) {
        if ( !this.referentialConstraint.contains( constraint ) ) {
            this.referentialConstraint.add( constraint );
            constraint.addReferencedColumn( this );
        }
    }

    public void removeReferentialConstraint( Constraint constraint ) {
        boolean removed = this.referentialConstraint.remove( constraint );
        if ( removed ) constraint.removeReferencedColumn( this );
    }

    public void setTable( GusTable table ) {
        super.setTable( table );
        if ( getVersionColumn( ) != null ) {
            if ( table != null ) getVersionColumn( ).setTable( table.getVersionTable( ) );
            else getVersionColumn( ).setTable( null );
        }
        else {
            if ( table != null ) {
                setVersionColumn( new VersionColumn( this ) );
            }
        }
    }

    public TreeSet<Index> getIndexs( ) {
        return index;
    }

    public void addIndex( Index index ) {
        if ( !this.index.contains( index ) ) {
            this.index.add( index );
            index.addColumn( this );
        }
    }

    public void removeIndex( Index index ) {
        boolean removed = this.index.remove( index );
        if ( removed ) index.removeColumn( this );
    }

    @Override
    public void setName( String name ) {
        super.setName( name );
        if ( getVersionColumn( ) != null ) getVersionColumn( ).setName( name );
    }

    @Override
    public void setPrecision( int precision ) {
        super.setPrecision( precision );
        if ( getVersionColumn( ) != null ) getVersionColumn( ).setPrecision( precision );
    }

    @Override
    public void setLength( int length ) {
        super.setLength( length );
        if ( getVersionColumn( ) != null ) getVersionColumn( ).setLength( length );
    }

    @Override
    public void setNullable( boolean nullable ) {
        super.setNullable( nullable );
        if ( getVersionColumn( ) != null ) getVersionColumn( ).setNullable( nullable );
    }

    @Override
    public void setType( String type ) {
        super.setType( type );
        if ( getVersionColumn( ) != null ) getVersionColumn( ).setType( type );
    }

    @Override
    public void setType( ColumnType columnType ) {
        super.setType( columnType );
        if ( getVersionColumn( ) != null ) getVersionColumn( ).setType( columnType );
    }

    @Override
    public Object clone( ) {
        GusColumn clone = new GusColumn( );
        clone.setLength( getLength( ) );
        clone.setName( getName( ) );
        clone.setNullable( isNullable( ) );
        clone.setPrecision( getPrecision( ) );
        clone.setType( getType( ) );
        return clone;
    }

}
