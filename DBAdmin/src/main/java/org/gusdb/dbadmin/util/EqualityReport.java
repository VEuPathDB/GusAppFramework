/**
 * $Id:$
 */
package org.gusdb.dbadmin.util;

import java.io.IOException;
import java.io.Writer;
import java.util.Iterator;
import java.util.List;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.gusdb.dbadmin.model.Database;
import org.gusdb.dbadmin.model.GusTable;
import org.gusdb.dbadmin.model.Table;

/**
 * @author msaffitz
 */
public class EqualityReport {

    private static final Logger log = LogManager.getLogger( EqualityReport.class );

    private Database         leftDatabase;
    private Database         rightDatabase;

    private SchemaComparator comparator;

    public EqualityReport( Database left, Database right ) {
        this.leftDatabase = left;
        this.rightDatabase = right;
        comparator = new SchemaComparator( left, right );
    }

    public void writeReport( Writer writer ) throws IOException {
        log.debug("Writing Equility Report");
        writer.write( "===============================================================\n" );
        writer.write( "== GUS Schema Comparison Report                              ==\n" );
        writer.write( "==                                                           ==\n" );
        writer.write( "== Left Database: " + leftDatabase.getName( ) + "            ==\n" );
        writer.write( "== Right Database: " + rightDatabase.getName( ) + "          ==\n" );
        writer.write( "===============================================================\n\n" );
        writeRenamedReport( writer );
        writeAddedReport( writer );
        writeDroppedReport( writer );
        writeChangedReport( writer );
       // writeUnchangedReport( writer );
        writer.flush( );
    }

    private void writeRenamedReport( Writer writer ) throws IOException {

        writer.write( " == Renamed Tables ==\n\n" );
        for ( Iterator<Table> i = comparator.findLeftRenamedTables( ).keySet( ).iterator( ); i.hasNext( ); ) {
            Table table = i.next( );
            writer.write( table.getSchema( ).getName( ) + "." + table.getName( ) + " renamed to " );
            List<Table> newTables = comparator.findRenameMatches( table, 0 );
            if ( newTables.isEmpty( ) ) {
                writer.write( "ERROR:  No Table\n" );
            }
            else if ( newTables.size( ) == 1 ) {
                Table newTable = (Table) newTables.toArray( )[0];
                writer.write( newTable.getSchema( ).getName( ) + "." + newTable.getName( ) + "\n" );
            }
            else {
                writer.write( "\n\t" );
                for ( Iterator<Table> j = newTables.iterator( ); j.hasNext( ); ) {
                    Table newTable = j.next( );
                    writer.write( " " + newTable.getSchema( ).getName( ) + "." + newTable.getName( ) );
                }
                writer.write( "\n" );
            }
        }
        writer.write( "\n" );
        writer.flush( );

    }

    @SuppressWarnings("unused")
    private void writeUnchangedReport( Writer writer ) throws IOException {
        writer.write( " == Unchanged Tables == \n\n" );

        for ( Iterator<Table> i = comparator.findLeftIdenticalTables( ).iterator( ); i.hasNext( ); ) {
            Table table = i.next( );
            writer.write( table.getSchema( ).getName( ) + "." + table.getName( ) + "\n" );
        }
        writer.write( "\n" );
        writer.flush( );
    }

    private void writeAddedReport( Writer writer ) throws IOException {
        writer.write( " == Added Tables == \n\n" );
        for ( Iterator<Table> i = comparator.findRightAddedTables( ).iterator( ); i.hasNext( ); ) {
            Table table = i.next( );
            writer.write( table.getSchema( ).getName( ) + "." + table.getName( ) + "\n" );
        }
        writer.write( "\n" );
        writer.flush( );
    }

    private void writeDroppedReport( Writer writer ) throws IOException {
        writer.write( " == Dropped Tables == \n\n" );
        for ( Iterator<Table> i = comparator.findLeftDroppedTables( ).iterator( ); i.hasNext( ); ) {
            Table table = i.next( );
            writer.write( table.getSchema( ).getName( ) + "." + table.getName( ) + "\n" );
        }
        writer.write( "\n" );
        writer.flush( );
    }

    private void writeChangedReport( Writer writer ) throws IOException {
        writer.write( " == Changed Tables (Columns, Indexes, Constraints)  == \n\n" );
        for ( Iterator<GusTable> i = comparator.findLeftColChangedTables( ).keySet( ).iterator( ); i.hasNext( ); ) {
            GusTable table = i.next( );
            writer.write( table.getSchema( ).getName( ) + "." + table.getName( ) + ":  \n" );
            for ( Iterator<String> j = comparator.findLeftColChangedTables( ).get( table ).iterator( ); j
                    .hasNext( ); ) {
                writer.write( "\t" + j.next( ) + "\n" );
            }
        }

        for ( Iterator<GusTable> i = comparator.findLeftIndChangedTables( ).keySet( ).iterator( ); i.hasNext( ); ) {
            GusTable table = i.next( );
            writer.write( table.getSchema( ).getName( ) + "." + table.getName( ) + " has changed indexes:\n" );
            for ( Iterator<String> j = comparator.findLeftIndChangedTables( ).get( table ).iterator( ); j
                    .hasNext( ); ) {
                writer.write( "\t" + j.next( ) + "\n" );
            }
        }

        for ( Iterator<GusTable> i = comparator.findLeftConChangedTables( ).keySet( ).iterator( ); i.hasNext( ); ) {
            GusTable table = i.next( );
            writer.write( table.getSchema( ).getName( ) + "." + table.getName( ) + " has changed constraints:\n" );
            for ( Iterator<String> j = comparator.findLeftConChangedTables( ).get( table ).iterator( ); j
                    .hasNext( ); ) {
                writer.write( "\t" + j.next( ) + "\n" );
            }
        }
        writer.write( "\n" );
        writer.flush( );
    }

}
