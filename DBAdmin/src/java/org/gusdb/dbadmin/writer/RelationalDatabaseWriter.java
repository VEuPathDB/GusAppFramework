/*
 * Created on Oct 28, 2004
 */
package org.gusdb.dbadmin.writer;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Iterator;
import java.util.Random;

import org.gusdb.dbadmin.model.Column;
import org.gusdb.dbadmin.model.Constraint;
import org.gusdb.dbadmin.model.DatabaseObject;
import org.gusdb.dbadmin.model.GusTable;
import org.gusdb.dbadmin.model.Index;
import org.gusdb.dbadmin.model.Schema;
import org.gusdb.dbadmin.model.Sequence;
import org.gusdb.dbadmin.model.Table;
import org.gusdb.dbadmin.model.View;

/**
 * @version $Revision$ $Date: 2005-06-01 16:03:02 -0400 (Wed, 01 Jun
 *          2005) $
 * @author msaffitz
 */
public abstract class RelationalDatabaseWriter extends SchemaWriter {

    protected Random         random;
    protected ArrayList<DatabaseObject> written = new ArrayList<DatabaseObject>( );

    /**
     * DOCUMENT ME!
     * 
     * @param schema DOCUMENT ME!
     * @throws IOException DOCUMENT ME!
     */
    protected void writeTables( Schema schema ) throws IOException {

        for ( Iterator i = schema.getTables( ).iterator( ); i.hasNext( ); ) {

            Table table = (Table) i.next( );
            writeTable( table );
        }
    }

    /**
     * DOCUMENT ME!
     * 
     * @param table DOCUMENT ME!
     * @throws IOException DOCUMENT ME!
     */
    protected void writeTable( Table table ) throws IOException {

        if ( written.contains( table ) ) {

            return;
        }

        if ( table.getSuperclass( ) != null && !written.contains( table.getSuperclass( ) ) ) {
            writeTable( table.getSuperclass( ) );
        }

        oStream.write( "CREATE TABLE " + table.getSchema( ).getName( ) + "." + table.getName( ) + " (\n" );
        writeColumns( table );
        oStream.write( ");\n\n" );
        oStream.flush( );
        written.add( table );

        if ( table.getClass( ) == GusTable.class ) {
            writeIndexes( (GusTable) table );
            oStream.write( "\n" );
            writePKConstraint( (GusTable) table );
        }

        oStream.write( "\n" );
    }

    /**
     * DOCUMENT ME!
     * 
     * @param schema DOCUMENT ME!
     * @throws IOException DOCUMENT ME!
     */
    protected void writeViews( Schema schema ) throws IOException {
        for ( View view : schema.getViews( ) ) {
            writeView( view );
        }
    }

    /**
     * DOCUMENT ME!
     * 
     * @param view DOCUMENT ME!
     * @throws IOException DOCUMENT ME!
     */
    protected void writeView( View view ) throws IOException {
        if ( written.contains( view ) ) {
            return;
        }
        oStream.write( "CREATE VIEW " + view.getSchema( ).getName( ) + "." + view.getName( ) + " AS \n" );
        oStream.write( view.getSql( ) );
        oStream.write( "\n\n" );
        oStream.flush( );
        written.add( view );
    }

    /**
     * DOCUMENT ME!
     * 
     * @param table DOCUMENT ME!
     * @throws IOException DOCUMENT ME!
     */
    protected void writeColumns( Table table ) throws IOException {

        boolean first = true;

        for ( Column column : table.getColumnsExcludeSuperclass( true ) ) {

            if ( !first ) {
                oStream.write( ",\n" );
            }

            first = false;
            log.debug( "Writing column details for Table: '" + table.getName( ) + "' Column: '" + column.getName( )
                    + "' and Type: '" + column.getType( ) + "'" );
            oStream.write( "\t " + column.getName( ) + " " + getType( column.getType( ) ) );

            if ( ( column.getType( ) == Column.ColumnType.STRING || column.getType( ) == Column.ColumnType.CHARACTER || column.getType( ) == Column.ColumnType.FLOAT )
                 && column.getLength( ) != 0 ) {
                oStream.write( "(" + column.getLength( ) + ") " );
            }

            if ( column.getType( ) == Column.ColumnType.NUMBER && column.getLength( ) != 0 ) {
                oStream.write( "(" + column.getLength( ) + "," + column.getPrecision( ) + ") " );
            }

            if ( !column.isNullable( ) ) {
                oStream.write( " NOT NULL" );
            }

            oStream.flush( );
        }
    }

    /**
     * DOCUMENT ME!
     * 
     * @param columns DOCUMENT ME!
     * @throws IOException DOCUMENT ME!
     */
    protected void writeColumnList( Collection columns ) throws IOException {

        boolean first = true;

        for ( Iterator i = columns.iterator( ); i.hasNext( ); ) {

            if ( !first ) {
                oStream.write( ", " );
            }

            first = false;
            oStream.write( "" + ((Column) i.next( )).getName( ) + "" );
        }
    }

    /**
     * DOCUMENT ME!
     * 
     * @param table DOCUMENT ME!
     * @throws IOException DOCUMENT ME!
     */
    protected void writeIndexes( GusTable table ) throws IOException {

        for ( Iterator i = table.getIndexs( ).iterator( ); i.hasNext( ); ) {
            Index index = (Index) i.next( );
            // If this index is for a PK or Unique Constraint,
            // skip it-- it's implicitly created
            if ( table.getConstraint( index.getName( ) ) != null ) {
                continue;
            }

            writeIndex( index );
        }
    }

    /**
     * DOCUMENT ME!
     * 
     * @param index DOCUMENT ME!
     * @throws IOException DOCUMENT ME!
     */
    protected void writeIndex( Index index ) throws IOException {

        Table table = index.getTable( );
        oStream.write( "CREATE INDEX " );

        if ( index.getName( ) == null ) {
            index.setName( "IND_" + random.nextInt( 100000 ) );
        }

        oStream.write( index.getName( ) + " ON " + table.getSchema( ).getName( ) + "." + table.getName( ) + " (" );
        writeColumnList( index.getColumns( ) );
        oStream.write( ");\n" );
        oStream.flush( );
    }

    /**
     * DOCUMENT ME!
     * 
     * @param table DOCUMENT ME!
     * @throws IOException DOCUMENT ME!
     */
    protected void writePKConstraint( GusTable table ) throws IOException {

        Constraint constraint = table.getPrimaryKey( );

        if ( constraint == null ) {

            return;
        }

        oStream.write( "ALTER TABLE " + table.getSchema( ).getName( ) + "." );
        oStream.write( "" + table.getName( ) + " ADD CONSTRAINT " + constraint.getName( ) );
        oStream.write( " PRIMARY KEY (" );
        writeColumnList( constraint.getConstrainedColumns( ) );
        oStream.write( ");\n" );
        oStream.flush( );
    }

    /**
     * DOCUMENT ME!
     * 
     * @param table DOCUMENT ME!
     * @throws IOException DOCUMENT ME!
     */
    protected void writeUQConstraints( GusTable table ) throws IOException {

        for ( Iterator i = table.getConstraints( ).iterator( ); i.hasNext( ); ) {

            Constraint constraint = (Constraint) i.next( );

            if ( constraint.getType( ) == Constraint.ConstraintType.UNIQUE ) {
                writeUQConstraint( constraint );
            }
        }
    }

    /**
     * DOCUMENT ME!
     * 
     * @param constraint DOCUMENT ME!
     * @throws IOException DOCUMENT ME!
     */
    protected void writeUQConstraint( Constraint constraint ) throws IOException {
        oStream.write( "ALTER TABLE " + constraint.getConstrainedTable( ).getSchema( ).getName( ) + "." );
        oStream.write( "" + constraint.getConstrainedTable( ).getName( ) + " " );
        oStream.write( "ADD CONSTRAINT " + constraint.getName( ) );
        oStream.write( " UNIQUE (" );
        writeColumnList( constraint.getConstrainedColumns( ) );
        oStream.write( ");\n" );
        oStream.flush( );
    }

    /**
     * DOCUMENT ME!
     * 
     * @param table DOCUMENT ME!
     * @throws IOException DOCUMENT ME!
     */
    protected void writeFKConstraints( GusTable table ) throws IOException {

        for ( Iterator i = table.getConstraints( ).iterator( ); i.hasNext( ); ) {

            Constraint constraint = (Constraint) i.next( );

            if ( constraint.getType( ) == Constraint.ConstraintType.FOREIGN_KEY ) {
                writeFKConstraint( constraint );
            }
        }
    }

    /**
     * Converts a foreign key constraint to RDBMS ddl
     * 
     * @param constraint Constraint for conversion
     * @throws IOException
     */
    protected void writeFKConstraint( Constraint constraint ) throws IOException {
        oStream.write( "ALTER TABLE " + constraint.getConstrainedTable( ).getSchema( ).getName( ) + "." );
        oStream.write( "" + constraint.getConstrainedTable( ).getName( ) + " " );
        oStream.write( "ADD CONSTRAINT " + constraint.getName( ) );
        oStream.write( " FOREIGN KEY (" );
        writeColumnList( constraint.getConstrainedColumns( ) );
        oStream.write( ") REFERENCES " + constraint.getReferencedTable( ).getSchema( ).getName( ) );
        oStream.write( "." + constraint.getReferencedTable( ).getName( ) + " (" );
        writeColumnList( constraint.getReferencedColumns( ) );
        oStream.write( ");\n" );
        oStream.flush( );
    }

    /**
     * Converts a Sequence object to RDBMS ddl
     * 
     * @param sequence Sequence for conversion
     * @throws IOException
     */
    protected void writeSequence( Sequence sequence ) throws IOException {
        oStream.write( "CREATE SEQUENCE " + sequence.getTable( ).getSchema( ).getName( ) + "." );
        oStream.write( sequence.getName( ) + " START WITH " + sequence.getStart( ) + ";\n" );
        oStream.flush( );
    }

    /**
     * Returns the specific RDBMS type given a canonical ColumnType
     * 
     * @param type The ColumnType for conversion
     * @return Corresponding RDBMS type
     */
    protected abstract String getType( Column.ColumnType type );

    /**
     * @see org.gusdb.dbadmin.writer.SchemaWriter#setUp()
     */
    protected void setUp( ) {
        random = new Random( );
    }

    /**
     * @see org.gusdb.dbadmin.writer.SchemaWriter#tearDown()
     */
    protected void tearDown( ) {}
}
