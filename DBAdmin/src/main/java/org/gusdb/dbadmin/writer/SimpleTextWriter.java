/*
 *  Created on Oct 28, 2004
 *
 */
package org.gusdb.dbadmin.writer;

import static org.gusdb.dbadmin.model.GusSchema.toGusTables;

import java.io.IOException;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Set;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.gusdb.dbadmin.model.Column;
import org.gusdb.dbadmin.model.Constraint;
import org.gusdb.dbadmin.model.Database;
import org.gusdb.dbadmin.model.GusColumn;
import org.gusdb.dbadmin.model.GusSchema;
import org.gusdb.dbadmin.model.GusTable;
import org.gusdb.dbadmin.model.Index;
import org.gusdb.dbadmin.model.Table;

/**
 *@author     msaffitz
 *@created    April 26, 2005
 *@version    $Revision$ $Date$
 */
public class SimpleTextWriter extends SchemaWriter {

    protected final Logger log = LogManager.getLogger(SimpleTextWriter.class);

    private Set<Table> written  = new HashSet<>();


	@Override
  protected void writeDatabase( Database db ) throws IOException {
		log.debug( "Writing database" );
		oStream.write( "-- Automatically generated by GusDBA.\n\n" );
		if ( db.getName() != null ) {
			oStream.write( "__" + db.getName() + "__ Version:" + db.getVersion() + "." + db.getPatchLevel() +"\n\n" );
		}

        for ( GusSchema schema : db.getGusSchemas() ) {
			oStream.write( "__" + schema.getName() + "__\n\n" );
			writeTables( schema );
			oStream.flush();
		}
		written = new HashSet<>();
	}


	private void writeTables( GusSchema schema ) throws IOException {
		for ( GusTable table : toGusTables(schema.getTables())) {
			writeTable( table );
			oStream.flush();
		}
	}


	private void writeIndexes( GusTable table ) throws IOException {
		for ( Iterator<Index> i = table.getIndexs().iterator(); i.hasNext();  ) {
			writeIndex( i.next() );
		}
	}


	private void writeTable( GusTable table ) throws IOException {
		if ( written.contains( table ) ) {
			return;
		}
		if ( table.getSuperclass() != null &&
			! written.contains( table.getSuperclass() ) ) {
			writeTable( table.getSuperclass() );
		}

		oStream.write( table.getSchema().getName() + "." + table.getName() + " " );
		if ( table.getSuperclass() != null ) {
			oStream.write( " extends " +
				table.getSuperclass().getSchema().getName() +
				"." + table.getSuperclass().getName() );
		}
		oStream.write( "\n----------------------------------------------------\n" );
		writeColumns( table );
		oStream.write( "\n" );
		writeIndexes( table );
		oStream.write( "\n\n" );
		oStream.flush();
		written.add( table );

		if ( ! table.getSubclasses().isEmpty() ) {
			for ( GusTable subclass : toGusTables(table.getSubclasses()) ) {
		        writeTable(subclass);
			}
		}
	}


	private void writeIndex( Index index ) throws IOException {
		oStream.write( "Index: (" );
		for ( Iterator<GusColumn> i = index.getColumns().iterator(); i.hasNext();  ) {
			Column col  = i.next();
			oStream.write( " " + col.getName() );
		}
		oStream.write( " )\n" );
	}


	private void writeColumns( Table table ) throws IOException {
        for ( Column column : table.getColumnsExcludeSuperclass(false)) {
			oStream.write( "\t" + column.getName() );
			writeSpace( column.getName() );
		    writeType( column );
			if ( !column.isNullable() ) {
			    oStream.write( "\tNOT NULL" );
			}
			oStream.write( "\n" );
		}
		oStream.flush();
	}

	private void writeType( Column column ) throws IOException {
		if ( !column.getConstraints().isEmpty() ) {
			for ( Iterator<Constraint> i = column.getConstraints().iterator(); i.hasNext();  ) {
			Constraint cons  = i.next();

				if ( cons.getType() == Constraint.ConstraintType.FOREIGN_KEY ) {
					writeRefType( cons );
				}
				if ( cons.getType() == Constraint.ConstraintType.PRIMARY_KEY ) {
					writeTrueType( column );
				}
			}
		}
		else {
			writeTrueType( column );
		}
	}


	private void writeTrueType( Column column ) throws IOException {
		String type  = column.getType().toString();

		if ( column.getType() == Column.ColumnType.STRING ||
			 column.getType() == Column.ColumnType.CHARACTER ) {
			type = type + "(" + column.getLength() + ") ";
		}
		if ( column.getType() == Column.ColumnType.NUMBER &&
			column.getLength() != 0 ) {
			type = type + "(" + column.getLength() + ","
				 + column.getPrecision() + ") ";
		}
		oStream.write( type );
		writeSpace( type );
	}


	private void writeRefType( Constraint cons ) throws IOException {
		oStream.write( cons.getReferencedTable().getSchema().getName()
			 + "." + cons.getReferencedTable().getName() );
		writeSpace( cons.getReferencedTable().getSchema().getName()
			 + "." + cons.getReferencedTable().getName() );

	}


	private void writeSpace( String word ) throws IOException {
		int l  = 40 - word.length();

		while ( l > 0 ) {
			oStream.write( " " );
			l--;
		}
	}


	/**
	 *@see    org.gusdb.dbadmin.writer.SchemaWriter#setUp()
	 */
	@Override
  protected void setUp() {
	}


	/**
	 *@see    org.gusdb.dbadmin.writer.SchemaWriter#tearDown()
	 */
	@Override
  protected void tearDown() { }
}

