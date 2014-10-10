package org.gusdb.dbadmin.model;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.TreeSet;

/**
 * @author msaffitz
 * @created May 2, 2005
 * @version $Revision$ $Date: 2005-06-16 16:35:04 -0400 (Thu, 16 Jun
 *          2005) $
 */
public class GusTable extends Table {

    private String              documentation;
    private Category            category;
    private String              categoryRef;
    private String              ref;
    private TreeSet<Constraint> constraint            = new TreeSet<Constraint>( );
    private ArrayList<Constraint> referentialConstraint = new ArrayList<Constraint>( );
    private TreeSet<Index>      index                 = new TreeSet<Index>( );
    private Sequence            sequence;
    private final String        sequenceSuffix        = "_SQ";
    private Constraint          primaryKey;

    private boolean             versioned;
    private VersionTable        versionTable;

    public GusTable( ) {
        setSequence( new Sequence( ) );
        Integer start = new Integer( System.getProperty( "SEQUENCE_START" ) );
        sequence.setStart( start.intValue( ) );
    }

    public VersionTable getVersionTable( ) {
        return this.versionTable;
    }

    public String getDocumentation( ) {
        return documentation;
    }

    public void setDocumentation( String documentation ) {
        this.documentation = documentation;
    }

    public Category getCategory( ) {
        return category;
    }

    public void setCategory( Category category ) {
        if ( this.category != category ) {
            if ( this.category != null ) this.category.removeTable( this );
            this.category = category;
            if ( this.category != null ) this.category.addTable( this );
        }
    }

    public String getCategoryRef( ) {
        if ( this.getCategory( ) != null ) return this.getCategory( ).getName( );
        return categoryRef;
    }

    public void setCategoryRef( String categoryRef ) {
        this.categoryRef = categoryRef;
    }

    public String getRef( ) {
        return ref;
    }

    public void setRef( String ref ) {
        this.ref = ref;
    }

    public String getPrimaryKeyName( ) {
        if ( getPrimaryKey( ) == null ) return null;
        if ( getPrimaryKey( ).getConstrainedColumns( ).isEmpty( ) ) return null;
        ArrayList<Column> columns = getPrimaryKey( ).getConstrainedColumns( );
        return columns.get( 0 ).getName( );
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
    
    public ArrayList<Constraint> getReferentialConstraints( ) {
        return referentialConstraint;
    }

    public void addReferentialConstraint( Constraint constraint ) {
        if ( !this.referentialConstraint.contains( constraint ) ) {
            this.referentialConstraint.add( constraint );
            constraint.setReferencedTable( this );
        }
    }

    public void removeReferentialConstraint( Constraint constraint ) {
        boolean removed = this.referentialConstraint.remove( constraint );
        if ( removed ) {
            constraint.setReferencedTable( null );
        }
    }

    public TreeSet<Index> getIndexs( ) {
        return getIndexes();
    }
    
    public TreeSet<Index> getIndexes( ) {
        return index;
    }

    public void addIndex( Index index ) {
        if ( !this.index.contains( index ) ) {
            this.index.add( index );
            index.setTable( this );
        }
    }

    public void removeIndex( Index index ) {
        boolean removed = this.index.remove( index );

        if ( removed ) {
            index.setTable( null );
        }
    }

    public void setSchema( GusSchema schema ) {
        super.setSchema( schema );
        if ( this.versionTable != null ) {
            if ( schema == null ) {
                versionTable.setSchema( null );
            }
            else {
                versionTable.setSchema( schema.getVersionSchema( ) );
            }
        }
    }

    public void addColumn( GusColumn column ) {
        super.addColumn( column );
        if ( this.versionTable != null ) {
            if ( column.getVersionColumn( ) == null ) {
                column.setVersionColumn( new VersionColumn( column ) );
            }
            versionTable.addColumn( column.getVersionColumn( ) );
        }
    }

    public void removeColumn( GusColumn column ) {
        super.removeColumn( column );
        if ( this.versionTable != null ) {
            versionTable.removeColumn( getColumn( column.getName( ) ) );
        }
    }

    public void addSubclass( GusTable table ) {
        super.addSubclass( table );
        if ( table.getVersionTable( ) != null && this.versionTable != null ) {
            versionTable.addSubclass( table.getVersionTable( ) );
        }
    }

    public void removeSubclass( GusTable table ) {
        super.removeSubclass( table );
        if ( table.getVersionTable( ) != null && this.versionTable != null ) {
            versionTable.removeSubclass( table.getVersionTable( ) );
        }
    }

    public void setSuperclass( GusTable table ) {
        super.setSuperclass( table );
        if ( table.getVersionTable( ) != null && this.versionTable != null ) {
            versionTable.setSuperclass( table.getVersionTable( ) );
        }
    }

    @Override
    public GusTable getSuperclass() {
        return (GusTable) super.getSuperclass();
    }
    
    @Override
    public TreeSet<GusTable> getSubclasses( ) {
        return (TreeSet<GusTable>) super.getSubclasses( );
    }

    public TreeSet<Constraint> getConstraints( ) {
        TreeSet<Constraint> constraints = constraint;

        if ( getPrimaryKey( ) != null ) {
            constraints.add( getPrimaryKey( ) );
        }
        return constraints;
    }

    public void addConstraint( Constraint constraint ) {
        if ( constraint.getType( ) == Constraint.ConstraintType.PRIMARY_KEY ) {
            setPrimaryKey( constraint );
            return;
        }
        if ( !this.constraint.contains( constraint ) ) {
            this.constraint.add( constraint );
            constraint.setConstrainedTable( this );
        }
    }

    public void removeConstraint( Constraint constraint ) {
        boolean removed = false;

        log.debug( "Removing constraint: '" + constraint.getName( ) + "' from Table: '" + getName( ) + "'" );
        if ( constraint.getType( ) == Constraint.ConstraintType.PRIMARY_KEY ) {
            if ( getPrimaryKey( ) != null ) {
                setPrimaryKey( null );
                removed = true;
            }
        }
        else {
            removed = this.constraint.remove( constraint );
        }
        if ( removed ) {
            constraint.setConstrainedTable( null );
        }
    }

    public Sequence getSequence( ) {
        return sequence;
    }

    public void setSequence( Sequence sequence ) {
        if ( this.sequence != sequence ) {
            this.sequence = sequence;
            this.sequence.setTable( this );
        }
    }

    @Override
    public void setTablespace( String tablespace ) {
        super.setTablespace( tablespace );
        if ( this.versionTable != null ) {
            versionTable.setTablespace( tablespace );
        }
    }

    @Override
    public void setName( String name ) {
        super.setName( name );
        if ( this.versionTable != null ) {
            versionTable.setName( name + verSuffix );
        }
        sequence.setName( name + sequenceSuffix );
    }

    public Constraint getConstraint( String name ) {
        for ( Iterator<Constraint> i = getConstraints( ).iterator( ); i.hasNext( ); ) {
            Constraint constraint = i.next( );

            if ( constraint.getName( ).compareToIgnoreCase( name ) == 0 ) {
                return constraint;
            }
        }
        return null;
    }

    @Override
    public void setHousekeeping( boolean housekeeping ) {
        super.setHousekeeping( housekeeping );
        if ( this.versionTable != null ) {
            versionTable.setHousekeeping( housekeeping );
        }
    }

    public boolean isVersioned( ) {
        return this.versioned;
    }

    public void setVersioned( boolean versioned ) {
        if ( this.versioned && !versioned ) {
            this.versioned = versioned;
            this.versionTable.setSchema( null );
            this.versionTable = null;
        }
        if ( !this.versioned && versioned ) {
            this.versioned = versioned;
            this.versionTable = new VersionTable( this );
            for ( Column col : getColumnsExcludeSuperclass(false) ) {
                if ( col instanceof GusColumn ) {
                    GusColumn col1 = (GusColumn) col;
                    if ( col1.getVersionColumn( ) != null ) {
                        col1.getVersionColumn( ).setTable( this.versionTable );
                    }
                }
            }
        }
    }

    @Override
    public void setUpdatable( boolean updatable ) {
        super.setUpdatable( updatable );
        if ( this.versionTable != null ) {
            versionTable.setUpdatable( updatable );
        }
    }

    public void resolveCategoryReference( ) {
        Database db = getSchema( ).getDatabase( );
        setCategory( db.getCategory( getCategoryRef( ) ) );
    }

    void resolveReferences( Database db ) {
        for ( Index i : getIndexs( ) ) {
            i.resolveReferences( db );
        }
        for ( Constraint con : getConstraints( ) ) {
            con.resolveReferences( db );
        }
    }

    @Override
    public boolean equals( DatabaseObject o ) {
        GusTable other = (GusTable) o;
        if ( versioned != other.isVersioned( ) ) return false;
        return super.equals( o );
    }
    

}
