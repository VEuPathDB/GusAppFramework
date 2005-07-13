/**
 * 
 */
package org.gusdb.dbadmin.util;

import java.util.Collection;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Vector;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.gusdb.dbadmin.model.Column;
import org.gusdb.dbadmin.model.Database;
import org.gusdb.dbadmin.model.GusTable;
import org.gusdb.dbadmin.model.Schema;
import org.gusdb.dbadmin.model.Table;

/**
 * @author msaffitz
 */
public class SchemaComparator {

    protected static final Log log                    = LogFactory
                                                              .getLog( SchemaComparator.class );

    private Database           leftDatabase;
    private Database           rightDatabase;

    private Collection         leftIdenticalTables    = new Vector( );

    private HashMap            leftRenamedTables      = new HashMap( );
    private HashMap            leftChangedTables      = new HashMap( );
    private Collection         leftDroppedTables      = new Vector( );

    private Collection         rightAddedTables;

    private HashMap            potentialRenameMatches = new HashMap( );

    public SchemaComparator( Database leftDatabase, Database rightDatabase ) {
        this.leftDatabase = leftDatabase;
        this.rightDatabase = rightDatabase;
    }

    public boolean compare( ) {
        findLeftIdenticalTables( );
        findLeftRenamedTables( );
        findLeftChangedTables( );
        findLeftDroppedTables( );
        findRightAddedTables( );

        return false;
    }

    public Collection findLeftIdenticalTables( ) {
        if ( !leftIdenticalTables.isEmpty( ) ) return leftIdenticalTables;

        for ( Iterator i = leftDatabase.getTables( true ).iterator( ); i
                .hasNext( ); ) {
            GusTable table = (GusTable) i.next( );

            Schema rightSchema = rightDatabase.getSchema( table.getSchema( )
                    .getName( ) );
            if ( rightSchema == null ) continue;
            Table rightTable = rightSchema.getTable( table.getName( ) );
            if ( rightTable == null ) continue;

            if ( !table.equals( rightTable ) ) continue;
            if ( !table.columnsEqual( rightTable ) ) continue;
            if ( !table.subclassesEqual( rightTable ) ) continue;
            if ( !table.constraintsEqual( rightTable ) ) continue;
            if ( !table.indexesEqual( rightTable ) ) continue;
            leftIdenticalTables.add( table );
        }
        return leftIdenticalTables;
    }

    public HashMap findLeftRenamedTables( ) {
        if ( !leftRenamedTables.isEmpty( ) ) return leftRenamedTables;
        for ( Iterator i = leftDatabase.getTables( true ).iterator( ); i
                .hasNext( ); ) {
            GusTable table = (GusTable) i.next( );
            if ( findLeftIdenticalTables( ).contains( table ) ) continue;
            if ( rightDatabase.getSchema( table.getSchema( ).getName( ) ) != null
                    && rightDatabase.getSchema( table.getSchema( ).getName( ) )
                            .getTable( table.getName( ) ) != null ) continue;
            Collection renamedTables = findRenameMatches( table, 0 );
            if ( !renamedTables.isEmpty( ) ) {
                leftRenamedTables.put( table, renamedTables );
            }
        }

        return leftRenamedTables;
    }

    public HashMap findLeftChangedTables( ) {
        if ( !leftChangedTables.isEmpty( ) ) return leftChangedTables;
        for ( Iterator i = leftDatabase.getTables( true ).iterator( ); i
                .hasNext( ); ) {
            GusTable table = (GusTable) i.next( );
            if ( findLeftIdenticalTables( ).contains( table ) ) continue;
            if ( findLeftRenamedTables( ).get( table ) != null ) continue;
            if ( rightDatabase.getSchema( table.getSchema( ).getName( ) ) == null
                    || rightDatabase.getSchema( table.getSchema( ).getName( ) )
                            .getTable( table.getName( ) ) == null ) continue;
            Table rightTable = rightDatabase.getSchema(
                    table.getSchema( ).getName( ) ).getTable( table.getName( ) );
            Collection colCompareResults = compareColumnSets( table
                    .getColumnsExcludeSuperclass( false ), rightTable
                    .getColumnsExcludeSuperclass( false ) );
            if ( !colCompareResults.isEmpty( ) ) {
                leftChangedTables.put( table, colCompareResults );
            }
            // TODO Constraints
            // TODO Indexes
        }
        return leftChangedTables;
    }

    public Collection findLeftDroppedTables( ) {
        if ( !leftDroppedTables.isEmpty( ) ) return leftDroppedTables;
        for ( Iterator i = leftDatabase.getTables( true ).iterator( ); i
                .hasNext( ); ) {
            GusTable table = (GusTable) i.next( );
            if ( findLeftIdenticalTables( ).contains( table ) ) continue;
            if ( findLeftRenamedTables( ).get( table ) != null ) continue;
            if ( findLeftChangedTables( ).get( table ) != null ) continue;
            leftDroppedTables.add( table );
        }
        return leftDroppedTables;
    }

    public Collection findRightAddedTables( ) {
        return rightAddedTables;

    }

    public Collection findRenameMatches( Table table, int maxModifiedColumns ) {
        if ( potentialRenameMatches.get( table ) != null ) return (Collection) potentialRenameMatches
                .get( table );

        Collection potentialMatches = new Vector( );

        for ( Iterator i = rightDatabase.getTables( true ).iterator( ); i
                .hasNext( ); ) {
            Table targetTable = (Table) i.next( );
            if ( targetTable.getSchema( ).getName( ) == table.getSchema( )
                    .getName( )
                    && targetTable.getName( ) == table.getName( ) ) continue;

            int foundModifiedColumns = targetTable.getColumnsIncludeSuperclass(
                    false ).size( )
                    - table.getColumnsIncludeSuperclass( false ).size( );
            if ( foundModifiedColumns < 0 ) foundModifiedColumns = 0;

            for ( Iterator k = table.getColumnsIncludeSuperclass( false )
                    .iterator( ); k.hasNext( ); ) {
                Column column = (Column) k.next( );
                if ( targetTable.getColumn( column.getName( ) ) == null ) foundModifiedColumns++;
                else if ( !column.equals( targetTable.getColumn( column
                        .getName( ) ) ) ) foundModifiedColumns++;
            }
            if ( foundModifiedColumns > maxModifiedColumns ) continue;
            potentialMatches.add( targetTable );
        }
        potentialRenameMatches.put( table, potentialMatches );
        return potentialMatches;
    }

    public Collection compareColumnSets( Collection leftColumns,
            Collection rightColumns ) {
        Collection results = new Vector( );

        Object[] leftColumnsA = leftColumns.toArray();
        Object[] rightColumnsA = rightColumns.toArray();
        
        
        int l = 0;
        int r = 0;
        while ( l < leftColumnsA.length && r < rightColumnsA.length ) {
            Column leftColumn = (Column) leftColumnsA[l];
            Column rightColumn = (Column) rightColumnsA[r];

            if ( leftColumn.equals( rightColumn ) ) {
                l++;
                r++;
            }
            else {
                // Column attributes changed
                if ( leftColumn.getName( ).compareToIgnoreCase(
                        rightColumn.getName( ) ) == 0 ) {
                    results.add( leftColumn.getName( ) + " changed " );
                    // TODO changed details
                    l++;
                    r++;
                }
                // Testing for left column being dropped:
                else if ( rightColumn.getTable( ).getColumn(
                        leftColumn.getName( ) ) == null ) {
                    results.add( leftColumn.getName( ) + " removed from table" );
                    l++;
                }
                // Testing for new right column:
                else if ( leftColumn.getTable( ).getColumn(
                        rightColumn.getName( ) ) == null ) {
                    results.add( rightColumn.getName( ) + " added to table" );
                    r++;
                }
                else {
                    results.add( "Error:  Confused about changes for "
                            + leftColumn.getName( ) + "(l) and "
                            + rightColumn.getName( ) + "(r)" );
                    l++;
                    r++;
                }
            }

        }
        while ( r < rightColumnsA.length ) {
            Column rightColumn = (Column) rightColumnsA[r];
            results.add( rightColumn.getName( ) + " added to table" );
            r++;
        }
        while ( l < leftColumnsA.length ) {
            Column leftColumn = (Column) leftColumnsA[l];
            results.add( leftColumn.getName( ) + " removed from table" );
            l++;
        }
        return results;
    }

}
