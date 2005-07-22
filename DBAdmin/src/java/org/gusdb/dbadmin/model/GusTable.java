package org.gusdb.dbadmin.model;

import java.util.Collection;
import java.util.HashSet;
import java.util.Iterator;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

/**
 * @author msaffitz
 * @created May 2, 2005
 * @version $Revision$ $Date: 2005-06-16 16:35:04 -0400 (Thu, 16 Jun
 *          2005) $
 */
public class GusTable extends Table {

    protected final static Log log                   = LogFactory
                                                             .getLog( GusTable.class );

    private String             documentation;
    private String             category;
    private String             ref;
    private Collection         constraint            = new HashSet( );
    // of type Constraint
    private Collection         referentialConstraint = new HashSet( );
    // of type Constraint
    private Collection         index                 = new HashSet( );
    // of type Index
    private Sequence           sequence;
    private final String       sequenceSuffix        = "_SQ";

    private boolean            versioned;
    private VersionTable       versionTable;

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

    public String getCategory() {
            return category;
    }
    
    public void setCategory(String category) {
        this.category = category;
    }
    
    public String getRef( ) {
        return ref;
    }

    public void setRef( String ref ) {
        this.ref = ref;
    }

    public Collection getReferentialConstraints( ) {
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

    public Collection getIndexs( ) {
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

    public void setPrimaryKey( Constraint primaryKey ) {
        super.setPrimaryKey( primaryKey );
        if ( this.versionTable != null && primaryKey == null ) {
            versionTable.setPrimaryKey( null );
            return;
        }
        else if ( this.versionTable != null ) {
            Constraint vPk = new Constraint( );

            if ( versionTable.getName( ).length( ) > 27 ) {
                vPk
                        .setName( versionTable.getName( ).substring( 0, 26 )
                                + "_PK" );
            }
            else {
                vPk.setName( versionTable.getName( ) + "_PK" );
            }
            vPk.setType( ConstraintType.PRIMARY_KEY );
            for ( Iterator i = primaryKey.getConstrainedColumns( ).iterator( ); i
                    .hasNext( ); ) {
                vPk.addConstrainedColumn( versionTable.getColumn( ((Column) i
                        .next( )).getName( ) ) );
            }
            if ( versionTable.getColumn( "MODIFICATION_DATE" ) != null ) {
                vPk.addConstrainedColumn( versionTable
                        .getColumn( "MODIFICATION_DATE" ) );
            }
            versionTable.setPrimaryKey( vPk );
        }
    }

    public Collection getConstraints( ) {
        Collection constraints = constraint;

        if ( getPrimaryKey( ) != null ) {
            constraints.add( getPrimaryKey( ) );
        }
        return constraints;
    }

    public void addConstraint( Constraint constraint ) {
        if ( constraint.getType( ) == ConstraintType.PRIMARY_KEY ) {
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

        log.debug( "Removing constraint: '" + constraint.getName( )
                + "' from Table: '" + getName( ) + "'" );
        if ( constraint.getType( ) == ConstraintType.PRIMARY_KEY ) {
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
            this.sequence.setTable( (GusTable) this );
        }
    }

    public void setTablespace( String tablespace ) {
        super.setTablespace( tablespace );
        if ( this.versionTable != null ) {
            versionTable.setTablespace( tablespace );
        }
    }

    public void setName( String name ) {
        super.setName( name );
        if ( this.versionTable != null ) {
            versionTable.setName( name + verSuffix );
        }
        sequence.setName( name + sequenceSuffix );
    }

    public Constraint getConstraint( String name ) {
        for ( Iterator i = getConstraints( ).iterator( ); i.hasNext( ); ) {
            Constraint constraint = (Constraint) i.next( );

            if ( constraint.getName( ).compareToIgnoreCase( name ) == 0 ) {
                return constraint;
            }
        }
        return null;
    }

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
            for ( Iterator i = getColumns( false ).iterator( ); i.hasNext( ); ) {
                GusColumn col = (GusColumn) i.next( );

                if ( col.getVersionColumn( ) != null ) {
                    col.getVersionColumn( ).setTable( this.versionTable );
                }
            }
        }
    }

    public void setUpdatable( boolean updatable ) {
        super.setUpdatable( updatable );
        if ( this.versionTable != null ) {
            versionTable.setUpdatable( updatable );
        }
    }

    void resolveReferences( Database db ) {
        for ( Iterator i = getIndexs( ).iterator( ); i.hasNext( ); ) {
            ((Index) i.next( )).resolveReferences( db );
        }
        for ( Iterator i = getConstraints( ).iterator( ); i.hasNext( ); ) {
            Constraint con = (Constraint) i.next( );

            con.resolveReferences( db );
            if ( con.getType( ) == ConstraintType.PRIMARY_KEY
                    && this.getVersionTable( ) != null ) {
                Constraint vPk = new Constraint( );

                if ( versionTable.getName( ).length( ) > 27 ) {
                    vPk.setName( versionTable.getName( ).substring( 0, 26 )
                            + "_PK" );
                }
                else {
                    vPk.setName( versionTable.getName( ) + "_PK" );
                }
                vPk.setType( ConstraintType.PRIMARY_KEY );
                for ( Iterator j = con.getConstrainedColumns( ).iterator( ); j
                        .hasNext( ); ) {
                    vPk.addConstrainedColumn( versionTable
                            .getColumn( ((Column) j.next( )).getName( ) ) );
                }
                if ( versionTable.getColumn( "MODIFICATION_DATE" ) != null ) {
                    vPk.addConstrainedColumn( versionTable
                            .getColumn( "MODIFICATION_DATE" ) );
                }
                versionTable.setPrimaryKey( vPk );
            }
        }
    }

    public boolean equals( DatabaseObject o ) {
        GusTable other = (GusTable) o;
        if ( versioned != other.isVersioned( ) ) return false;
        return super.equals( o );
    }
}
