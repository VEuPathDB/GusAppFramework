/*
 *  Created on Oct 28, 2004
 */
package org.gusdb.dbadmin.writer;

import java.io.IOException;
import java.util.Iterator;
import java.util.TreeSet;

import org.gusdb.dbadmin.model.Column;
import org.gusdb.dbadmin.model.Constraint;
import org.gusdb.dbadmin.model.Database;
import org.gusdb.dbadmin.model.GusSchema;
import org.gusdb.dbadmin.model.GusTable;
import org.gusdb.dbadmin.model.GusView;
import org.gusdb.dbadmin.model.Index;

/**
 *@author     msaffitz
 *@created    April 29, 2005
 *@version    $Revision$ $Date$
 */
public class XMLWriter extends SchemaWriter {

	int indent  = 0;

	/**
	 *@param  db               Database to be written
	 *@exception  IOException 
	 *@see                     org.gusdb.dbadmin.writer.SchemaWriter#writeDatabase(java.io.OutputStreamWriter,
	 *      org.gusdb.dbadmin.model.Database)
	 */
	protected void writeDatabase( Database db ) throws IOException {
		log.debug( "Writing XML for database " + db.getName() );
		indent();
		oStream.write( "<?xml version=\"1.0\"?>\n" );
		indent();
		oStream.write( "<database name=\"" + db.getName() + "\" version=\"" + db.getVersion() + 
                "\" patchLevel=\"" + db.getPatchLevel() + "\">\n" );
		indent++;
		writeSchemas( (Database) db );
		indent--;
		indent();
		oStream.write( "</database>\n" );
		oStream.flush();
	}


	private void writeSchemas( Database db ) throws IOException {
		if ( db.getGusSchemas().isEmpty() ) {
			return;
		}
		indent();
		oStream.write( "<schemas>\n" );

        for ( GusSchema schema : db.getGusSchemas() ) {
			writeSchema( (GusSchema) schema );
		}
		indent();
		oStream.write( "</schemas>\n" );
	}


	private void writeSchema( GusSchema schema ) throws IOException {
		indent++;
		indent();
		oStream.write( "<schema name=\"" + schema.getName() + "\">\n " );
		indent++;
		writeTables( schema );
		writeViews( schema );
		writeDocumentation( schema.getDocumentation() );
		indent--;
		indent();
		oStream.write( "</schema>\n" );
		indent--;
	}


	private void writeTables( GusSchema schema ) throws IOException {
		if ( schema.getTables().isEmpty() ) {
			return;
		}

		indent();
		oStream.write( "<tables>\n" );

		TreeSet tables  = new TreeSet( schema.getTables() );

		for ( Iterator i = tables.iterator(); i.hasNext();  ) {
			writeTable( (GusTable) i.next() );
			oStream.flush();
		}
		indent();
		oStream.write( "</tables>\n" );
	}


	private void writeTable( GusTable table ) throws IOException {

		if ( isSubclass( table ) ) {
			return;
		}
		indent++;
		indent();
		oStream.write( "<table " );
		oStream.write( "id=\"" + table.getSchema().getName() + "/" + table.getName() + "\" " );
		oStream.write( "name=\"" + table.getName() + "\" " );
		oStream.write( "housekeeping=\"" + table.isHousekeeping() + "\" " );
		oStream.write( "versioned=\"" + table.isVersioned() + "\" " );
		oStream.write( "tablespace=\"" + table.getTablespace() + "\" " );
        oStream.write( "categoryRef=\"" + table.getCategoryRef() + "\" " );
		oStream.write( "updatable=\"" + table.isUpdatable() + "\">\n" );
		indent++;
		writeDocumentation( table.getDocumentation() );
		writeColumns( table );
		writeSubclasses( table );
		writeIndexes( table );
		writeConstraints( table );
		indent--;
		indent();
		oStream.write( "</table>\n" );
		indent--;
	}


	private void writeViews( GusSchema schema ) throws IOException {
		if ( schema.getViews().isEmpty() ) {
			return;
		}

		indent();
		oStream.write( "<views>\n" );

		TreeSet views  = new TreeSet( schema.getViews() );

		for ( Iterator i = views.iterator(); i.hasNext();  ) {
			writeView( (GusView) i.next() );
			oStream.flush();
		}
		indent();
		oStream.write( "</views>\n" );
	}


	private void writeView( GusView view ) throws IOException {
		indent++;
		indent();
		oStream.write( "<view " );
		oStream.write( "id =\"" + view.getSchema().getName() + "/" + view.getName() + "\" " );
		oStream.write( "name=\"" + view.getName() + "\" " );
		oStream.write( "materialized=\"" + view.isMaterialized() + "\">\n" );
		indent++;
		indent();
		oStream.write( "<sql><![CDATA[" + view.getSql() + "]]</sql>\n" );
		indent--;
		indent();
		oStream.write( "</view>\n" );
		indent--;
	}


	private void writeSubclasses( GusTable table ) throws IOException {
		if ( table.getSubclasses().isEmpty() ) {
			return;
		}
		indent();
		oStream.write( "<subclasses>\n" );

        for ( GusTable subclass : table.getSubclasses() ) {
            writeSubclass(subclass);
			oStream.flush();
		}
		indent();
		oStream.write( "</subclasses>\n" );
	}


	private void writeSubclass( GusTable subclass ) throws IOException {
		indent++;
		indent();
		oStream.write( "<subclass " );
		oStream.write( "id=\"" + subclass.getSchema().getName() + "/" +
			subclass.getSuperclass().getName() + "/" + subclass.getName() + "\" " );
		oStream.write( "name=\"" + subclass.getName() + "\" " );
		oStream.write( "versioned=\"" + subclass.isVersioned() + "\" " );
		oStream.write( "tablespace=\"" + subclass.getTablespace() + "\" " );
		oStream.write( "categoryRef=\"" + subclass.getCategoryRef() + "\" " );
		oStream.write( "updatable=\"" + subclass.isUpdatable() + "\">\n" );
		indent++;
		writeDocumentation( subclass.getDocumentation() );
		writeColumns( subclass );
		indent--;
		indent();
		oStream.write( "</subclass>\n" );
		indent--;
	}


	private void writeColumns( GusTable table ) throws IOException {
		if ( table.getColumnsExcludeSuperclass( false ).isEmpty() ) {
			return;
		}
		indent();
		oStream.write( "<columns>\n" );
		for ( Iterator i = table.getColumnsExcludeSuperclass( false ).iterator(); i.hasNext();  ) {
			writeColumn( (Column) i.next() );
			oStream.flush();
		}
		indent();
		oStream.write( "</columns>\n" );
	}


	private void writeColumn( Column column ) throws IOException {
		indent++;
		indent();
		oStream.write( "<column " );
		oStream.write( "id=\"" + column.getTable().getSchema().getName() + "/" +
			column.getTable().getName() + "/" + column.getName() + "\" " );
		oStream.write( "name=\"" + column.getName() + "\" " );
		oStream.write( "nullable=\"" + column.isNullable() + "\" " );
		oStream.write( "length=\"" + column.getLength() + "\" " );
		oStream.write( "precision=\"" + column.getPrecision() + "\" " );
		oStream.write( "type=\"" + column.getType() + "\"" );

		//		if ( column.getClass() == GusColumn.class &&
		//	( (GusColumn) column ).getDocumentation() != null ) {
		//	oStream.write( ">\n" );
		//	indent++;
		//	writeDocumentation( ( (GusColumn) column ).getDocumentation() );
		//	indent--;
		//	indent();
		//	oStream.write( "</column>\n" );
		//}
		//else {
			oStream.write( "/>\n" );
			//}
		indent--;
	}


	private void writeColumnRefs( Iterator columns ) throws IOException {
		while ( columns.hasNext() ) {
		Column c    = (Column) columns.next();
		String ref  = c.getTable().getSchema().getName() + "/" + c.getTable().getName() + "/" + c.getName();

			indent();
			oStream.write( "<column idref=\"" + ref + "\"/>\n" );
		}
	}


	private void writeIndexes( GusTable table ) throws IOException {
		if ( table.getIndexs().isEmpty() ) {
			return;
		}

		indent();
		oStream.write( "<indexes>\n" );

	TreeSet indexes  = new TreeSet( table.getIndexs() );

		for ( Iterator i = indexes.iterator(); i.hasNext();  ) {
			writeIndex( (Index) i.next() );
			oStream.flush();
		}
		indent();
		oStream.write( "</indexes>\n" );
	}


	private void writeIndex( Index index ) throws IOException {
		indent++;
		indent();
		oStream.write( "<index name=\"" + index.getName() + "\" " );
		oStream.write( "tablespace=\"" + index.getTablespace() + "\" " );
		oStream.write( "type=\"" + index.getType() + "\">\n" );
		indent++;
		indent();
		oStream.write( "<columns>\n" );
		indent++;
		for ( Iterator i = index.getColumns().iterator(); i.hasNext();  ) {
		Column c    = (Column) i.next();
		String ref  = c.getTable().getSchema().getName() + "/" + c.getTable().getName() + "/" + c.getName();

			indent();
			oStream.write( "<column idref=\"" + ref + "\"/>\n" );
		}
		indent--;
		indent();
		oStream.write( "</columns>\n" );
		indent--;
		indent();
		oStream.write( "</index>\n" );
		indent--;
	}


	private void writeConstraints( GusTable table ) throws IOException {
		if ( table.getConstraints().isEmpty() ) {
			return;
		}

		indent();
		oStream.write( "<constraints>\n" );

		TreeSet constraints  = new TreeSet( table.getConstraints() );

		for ( Iterator i = constraints.iterator(); i.hasNext();  ) {
			writeConstraint( (Constraint) i.next() );
			oStream.flush();
		}
		indent();
		oStream.write( "</constraints>\n" );
	}


	private void writeConstraint( Constraint constraint ) throws IOException {
		indent++;
		indent();
		oStream.write( "<constraint name=\"" + constraint.getName() + "\" " );
		oStream.write( "type=\"" + constraint.getType() + "\">\n" );
		indent++;
		indent();
		oStream.write( "<constrainedColumns>\n" );
		indent++;
		writeColumnRefs( constraint.getConstrainedColumns().iterator() );
		indent--;
		indent();
		oStream.write( "</constrainedColumns>\n" );
		if ( constraint.getType() == Constraint.ConstraintType.FOREIGN_KEY ) {
			indent();
			oStream.write( "<referencedTable idref=\"" + constraint.getReferencedTable().getSchema().getName() + "/" +
				constraint.getReferencedTable().getName() + "\"/>\n" );
			indent();
			oStream.write( "<referencedColumns>\n" );
			indent++;
			writeColumnRefs( constraint.getReferencedColumns().iterator() );
			indent--;
			indent();
			oStream.write( "</referencedColumns>\n" );
		}
		indent--;
		indent();
		oStream.write( "</constraint>\n" );
		indent--;
	}


	private void writeDocumentation( String documentation ) throws IOException {
		if ( documentation == null ) {
			return;
		}
		// indent();
		//		oStream.write( "<documentation>![CDATA[" + documentation + "]]</documentation>\n" );
	}


	private void indent() throws IOException {
		for ( int i = 0; i < indent; i++ ) {
			oStream.write( "   " );
		}
	}


	private boolean isSubclass( GusTable table ) {
		if ( table.getSuperclass() != null ) {
			return true;
		}
		return false;
	}


	/**
	 *@see    org.gusdb.dbadmin.writer.SchemaWriter#setUp()
	 */
	protected void setUp() { }


	/**
	 *@see    org.gusdb.dbadmin.writer.SchemaWriter#tearDown()
	 */
	protected void tearDown() { }
}

