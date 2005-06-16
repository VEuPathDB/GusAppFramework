
package org.gusdb.dbadmin.model;

import java.util.Collection;
import java.util.HashSet;
import java.util.TreeSet;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

/**
 *@author     msaffitz
 *@created    May 2, 2005
 *@version    $Revision$ $Date$
 */
public abstract class Column extends DatabaseObject {

	protected final static Log log  = LogFactory.getLog( Column.class );

	private int length;
	private int precision;
	private boolean nullable;
	private ColumnType type;
	private Collection constraint   = new HashSet();
	protected Table table;


	public Collection getConstraints() {
		return constraint;
	}


	public void addConstraint( Constraint constraint ) {
		if ( !this.constraint.contains( constraint ) ) {
			log.debug( "Adding constraint: '" + constraint.getName()
				 + "' to Column: '" + getName() + "'" );
			this.constraint.add( constraint );
			constraint.addConstrainedColumn( this );
		}
	}


	public void removeConstraint( Constraint constraint ) {
		log.debug( "Removing constraint: '" + constraint.getName()
			 + "' from Column: '" + getName() + "'" );

		boolean removed  = this.constraint.remove( constraint );

		if ( removed ) {
			constraint.removeConstrainedColumn( this );
		}
	}


	public Table getTable() {
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


	public int getPrecision() {
		return precision;
	}


	public void setPrecision( int precision ) {
		this.precision = precision;
	}


	public int getLength() {
		return length;
	}


	public void setLength( int length ) {
		this.length = length;
	}


	public boolean isNullable() {
		return nullable;
	}


	public void setNullable( boolean nullable ) {
		this.nullable = nullable;
	}


	public ColumnType getType() {
		return type;
	}


	public void setType( String type ) {
		String name  = "null";

		if ( table != null ) {
			name = table.getName();
		}
		log.debug( "Setting Column Type: '" + type + "' for Table: '" + name + "'" );
		this.type = ColumnType.getInstance( type );
	}


	public void setType( ColumnType columnType ) {
		String name  = "null";

		if ( table != null ) {
			name = table.getName();
		}
		log.debug( "Setting Column Type: '" + columnType + "' for Table: '" + name + "'" );
		this.type = columnType;
	}


	static Column getColumnFromRef( Database db, String ref ) {
		String[] path  = ref.split( "/" );

		if ( path.length != 3 ) {
			log.error( "Invalid column ref: '" + ref + "'" );
			throw new RuntimeException( "Invalid column ref" );
		}
		try {
			Table table    = db.getSchema( path[0] ).getTable( path[1] );
			Column column  = table.getColumn( path[2] );

			if ( column == null ) {
				throw new NullPointerException( "No column found. Table: '"
					 + table.getName() + "', Column: '" + path[2] + "'" );
			}
			log.debug( "Resolved Column: '" + column.getName() + "'" );
			return column;
		}
		catch ( NullPointerException e ) {
			log.error( "Unable to parse ref: '" + ref + "'" );
			throw new RuntimeException( e );
		}
	}


	TreeSet getSortedChildren() {
		return new TreeSet( getConstraints() );
	}


	int equals( DatabaseObject other, HashSet seen ) {
		Column otherCol  = (Column) other;

		if ( seen.contains( this ) ) {
			return -1;
		}
		seen.add( this );

		boolean equal    = true;

		if ( !name.equals( otherCol.getName() ) ) {
			equal = false;
		}
		if ( length != otherCol.getLength() ) {
			equal = false;
		}
		if ( precision != otherCol.getPrecision() ) {
			equal = false;
		}
		if ( type != otherCol.getType() ) {
			equal = false;
		}
		if ( table.equals( otherCol.getTable(), seen ) == 0 ) {
			equal = false;
		}

		if ( !equal ) {
			log.debug( "Column attributes vary" );
			return 0;
		}

		return 1;
	}

}
