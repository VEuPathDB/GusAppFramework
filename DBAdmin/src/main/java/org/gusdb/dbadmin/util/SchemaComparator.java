package org.gusdb.dbadmin.util;

import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.Iterator;
import java.util.TreeSet;
import java.util.ArrayList;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.gusdb.dbadmin.model.Column;
import org.gusdb.dbadmin.model.Constraint;
import org.gusdb.dbadmin.model.Database;
import org.gusdb.dbadmin.model.DatabaseObject;
import org.gusdb.dbadmin.model.GusTable;
import org.gusdb.dbadmin.model.Schema;
import org.gusdb.dbadmin.model.Table;

/**
 * @author msaffitz
 */
public class SchemaComparator {

    private static final Logger log = LogManager.getLogger( SchemaComparator.class );

    private Database           leftDatabase;
    private Database           rightDatabase;

    private List<Table>         leftIdenticalTables         = new ArrayList<>( );

    private HashMap<Table,List<Table>>          leftRenamedTables           = new HashMap<>( );

    private HashMap<GusTable,List<String>>            leftColChangedTables        = new HashMap<>( );
    private HashMap<GusTable,List<String>>            leftIndChangedTables        = new HashMap<>( );
    private HashMap<GusTable,List<String>>            leftConChangedTables        = new HashMap<>( );

    private List<Table>         leftDroppedTables           = new ArrayList<>( );

    private List<Table>         rightAddedTables            = new ArrayList<>( );
    private List<Table>         potentialRightRenameTargets = new ArrayList<>( );

    private HashMap<Table,List<Table>>            potentialRenameMatches      = new HashMap<>( );

    public SchemaComparator( Database leftDatabase, Database rightDatabase ) {
        this.leftDatabase = leftDatabase;
        this.rightDatabase = rightDatabase;
    }

    public List<Table> findLeftIdenticalTables( ) {
        if ( ! leftIdenticalTables.isEmpty( ) ) return leftIdenticalTables;
        log.info("finding identical tables");
        
        for ( GusTable table : leftDatabase.getGusTables() ) {
            Schema rightSchema = rightDatabase.getSchema( table.getSchema( ).getName( ) );
            if ( rightSchema == null ) continue;
            GusTable rightTable = (GusTable) rightSchema.getTable( table.getName( ) );
            if ( rightTable == null ) continue;

            if ( !table.equals( rightTable ) ) continue;
            if ( !table.columnsEqual( rightTable ) ) continue;
//          if ( !table.subclassesEqual( rightTable ) ) continue;
            if ( !table.constraintsEqual( rightTable ) ) continue;
            if ( !table.indexesEqual( rightTable ) ) continue;
            leftIdenticalTables.add( table );
        }
        return leftIdenticalTables;
    }

    public Map<Table,List<Table>> findLeftRenamedTables( ) {
        if ( !leftRenamedTables.isEmpty( ) ) return leftRenamedTables;
        log.info("finding renamed tables");
        for ( GusTable table : leftDatabase.getGusTables() ) {
            if ( findLeftIdenticalTables( ).contains( table ) ) continue;
            if ( rightDatabase.getSchema( table.getSchema( ).getName( ) ) != null
                    && rightDatabase.getSchema( table.getSchema( ).getName( ) ).getTable( table.getName( ) ) != null ) continue;
            List<Table> renamedTables = findRenameMatches( table, 0 );
            if ( !renamedTables.isEmpty( ) ) {
                potentialRightRenameTargets.addAll( renamedTables );
                leftRenamedTables.put( table, renamedTables );
            }
        }

        return leftRenamedTables;
    }

    public Map<GusTable,List<String>> findLeftColChangedTables( ) {
        if ( !leftColChangedTables.isEmpty( ) ) return leftColChangedTables;
        log.info("finding tables with changed column sets");
        for ( GusTable table : leftDatabase.getGusTables() ) {
            if ( findLeftIdenticalTables( ).contains( table ) ) continue;
            if ( findLeftRenamedTables( ).get( table ) != null ) continue;
            if ( rightDatabase.getSchema( table.getSchema( ).getName( ) ) == null
                    || rightDatabase.getSchema( table.getSchema( ).getName( ) ).getTable( table.getName( ) ) == null ) continue;
            Table rightTable = rightDatabase.getSchema( table.getSchema( ).getName( ) ).getTable( table.getName( ) );

            List<String> colCompareResults = compareColumnSets( table.getColumnsExcludeSuperclass( false ), rightTable
                    .getColumnsExcludeSuperclass( false ) );
            if ( !colCompareResults.isEmpty( ) ) {
                leftColChangedTables.put( table, colCompareResults );
            }
        }
        return leftColChangedTables;
    }

    public Map<GusTable, List<String>> findLeftIndChangedTables( ) {
        if ( !leftIndChangedTables.isEmpty( ) ) return leftIndChangedTables;
        log.info("finding tables with changed indexes");
        for ( GusTable table : leftDatabase.getGusTables() ) {
            if ( findLeftIdenticalTables( ).contains( table ) ) continue;
            if ( findLeftRenamedTables( ).get( table ) != null ) continue;
            if ( rightDatabase.getSchema( table.getSchema( ).getName( ) ) == null
                    || rightDatabase.getSchema( table.getSchema( ).getName( ) ).getTable( table.getName( ) ) == null ) continue;
            GusTable rightTable = (GusTable) rightDatabase.getSchema( table.getSchema( ).getName( ) ).getTable(
                    table.getName( ) );

            if ( !table.indexesEqual( rightTable ) ) {
                leftIndChangedTables.put( table, new ArrayList<>( ) );
            }
        }
        return leftIndChangedTables;
    }

    public Map<GusTable, List<String>> findLeftConChangedTables( ) {
        if ( !leftConChangedTables.isEmpty( ) ) return leftConChangedTables;
        log.info("finding tables with changed constraints ");
        for ( GusTable table : leftDatabase.getGusTables() ) {
            if ( findLeftIdenticalTables( ).contains( table ) ) continue;
            if ( findLeftRenamedTables( ).get( table ) != null ) continue;
            if ( rightDatabase.getSchema( table.getSchema( ).getName( ) ) == null
                    || rightDatabase.getSchema( table.getSchema( ).getName( ) ).getTable( table.getName( ) ) == null ) continue;
            GusTable rightTable = (GusTable) rightDatabase.getSchema( table.getSchema( ).getName( ) ).getTable(
                    table.getName( ) );

            if ( !table.constraintsEqual( rightTable ) ) {
                leftConChangedTables.put( table, getConstraintDifferences( table, rightTable ) );
            }
        }
        return leftConChangedTables;
    }

    public List<Table> findLeftDroppedTables( ) {
        if ( !leftDroppedTables.isEmpty( ) ) return leftDroppedTables;
        log.info("finding tables that have been dropped");
        for ( GusTable table : leftDatabase.getGusTables() ) {
            if ( findLeftIdenticalTables( ).contains( table ) ) continue;
            if ( findLeftRenamedTables( ).get( table ) != null ) continue;
            if ( findLeftColChangedTables( ).get( table ) != null ) continue;
            if ( findLeftIndChangedTables( ).get( table ) != null ) continue;
            if ( findLeftConChangedTables( ).get( table ) != null ) continue;
            leftDroppedTables.add( table );
        }
        return leftDroppedTables;
    }

    public List<Table> findRightAddedTables( ) {
        // Need a side affect of this for below
        if ( !rightAddedTables.isEmpty( ) ) return rightAddedTables;
        log.info("finding added tables");
        findLeftRenamedTables( );
        for ( GusTable table : rightDatabase.getGusTables() ) {
            if ( leftDatabase.getSchema( table.getSchema( ).getName( ) ) != null
                    && leftDatabase.getSchema( table.getSchema( ).getName( ) ).getTable( table.getName( ) ) != null ) continue;
            if ( potentialRightRenameTargets.contains( table ) ) continue;
            rightAddedTables.add( table );
        }
        return rightAddedTables;
    }

    public List<Table> findRenameMatches( Table table, int maxModifiedColumns ) {
        if ( potentialRenameMatches.get( table ) != null ) return potentialRenameMatches.get( table );

        List<Table> potentialMatches = new ArrayList<>( );

        for ( GusTable targetTable : rightDatabase.getGusTables() ) {
            if ( targetTable.getSchema( ).getName( ) == table.getSchema( ).getName( )
                    && targetTable.getName( ) == table.getName( ) ) continue;

            int foundModifiedColumns = targetTable.getColumnsIncludeSuperclass( false ).size( )
                    - table.getColumnsIncludeSuperclass( false ).size( );
            if ( foundModifiedColumns < 0 ) foundModifiedColumns = 0;

            for ( Iterator<Column> k = table.getColumnsIncludeSuperclass( false ).iterator( ); k.hasNext( ); ) {
                Column column = k.next( );
                if ( targetTable.getColumn( column.getName( ) ) == null ) foundModifiedColumns++;
                else if ( !column.equals( targetTable.getColumn( column.getName( ) ) ) ) foundModifiedColumns++;
            }
            if ( foundModifiedColumns > maxModifiedColumns ) continue;
            potentialMatches.add( targetTable );
        }
        potentialRenameMatches.put( table, potentialMatches );
        return potentialMatches;
    }

    public static <C extends Column> boolean compareColumnSetNames( List<C> leftColumns, List<C> rightColumns ) {
        Object[] leftColumnsA = leftColumns.toArray( );
        Object[] rightColumnsA = rightColumns.toArray( );

        int l = 0;
        int r = 0;
        while ( l < leftColumnsA.length && r < rightColumnsA.length ) {
            DatabaseObject leftColumn = (DatabaseObject) leftColumnsA[l];
            DatabaseObject rightColumn = (DatabaseObject) rightColumnsA[r];
            if ( !leftColumn.equals( rightColumn ) ) return false;
            l++;
            r++;
        }
        if ( l < leftColumnsA.length || r < rightColumnsA.length ) return false;
        return true;
    }

    public static List<String> compareColumnSets( List<Column> leftColumns, List<Column> rightColumns ) {
        List<String> results = new ArrayList<>( );

        Object[] leftColumnsA = leftColumns.toArray( );
        Object[] rightColumnsA = rightColumns.toArray( );

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
                if ( leftColumn.getName( ).compareToIgnoreCase( rightColumn.getName( ) ) == 0 ) {
                    String res = leftColumn.getName( ) + " changed: ";
                    if ( leftColumn.getLength( ) != rightColumn.getLength( ) ) {
                        res = res.concat( "length: " + leftColumn.getLength( ) + " to " + rightColumn.getLength( )
                                + " " );
                    }
                    if ( leftColumn.getPrecision( ) != leftColumn.getPrecision( ) ) {
                        res = res.concat( "precision: " + leftColumn.getPrecision( ) + " to "
                                + rightColumn.getPrecision( ) + " " );
                    }
                    if ( leftColumn.getType( ) != leftColumn.getType( ) ) {
                        res = res.concat( "type: " + leftColumn.getType( ) + " to " + rightColumn.getType( ) );
                    }
                    results.add( res );
                    l++;
                    r++;
                }
                // Testing for left column being dropped:
                else if ( rightColumn.getTable( ).getColumn( leftColumn.getName( ) ) == null ) {
                    results.add( leftColumn.getName( ) + " removed from table" );
                    l++;
                }
                // Testing for new right column:
                else if ( leftColumn.getTable( ).getColumn( rightColumn.getName( ) ) == null ) {
                    results.add( rightColumn.getName( ) + " added to table ( nullable: " + rightColumn.isNullable() + " )" );
                    r++;
                }
                else {
                    results.add( "Error:  Confused about changes for " + leftColumn.getName( ) + "(l) and "
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

/*    private List getIndexDifferences( Index leftIndex, Index rightIndex ) {
        List differences = new ArrayList<>( );

        if ( leftIndex.getType( ) != rightIndex.getType( ) ) {
            differences.add( "types differ" );
        }
        if ( !compareColumnSetNames( leftIndex.getColumns( ), rightIndex.getColumns( ) ) ) {
            differences.add( "column sets differ" );
        }
        return differences;
    }
*/
    
    private List<String> getConstraintDifferences( GusTable leftTable, GusTable rightTable ) {
        List<String> results = new ArrayList<>( );

        Object[] leftConstraints = new TreeSet<>( leftTable.getConstraints( ) ).toArray( );
        Object[] rightConstraints = new TreeSet<>( rightTable.getConstraints( ) ).toArray( );

        int l = 0;
        int r = 0;

        if ( leftConstraints.length != rightConstraints.length ) {
            results.add( " constraint counts differ" );
            return results;
        }

        while ( l < leftConstraints.length && r < rightConstraints.length ) {
            Constraint leftConstraint = (Constraint) leftConstraints[l];
            Constraint rightConstraint = (Constraint) rightConstraints[r];

            if ( leftConstraint.getReferencedTable( ) != null && rightConstraint.getReferencedTable( ) != null ) {
                if ( leftConstraint.getReferencedTable( ).equals( rightConstraint.getReferencedTable( ) ) ) {
                    results.add( leftConstraint.getName( ) + ": referenced tables differ" );
                }
                if ( compareColumnSetNames( leftConstraint.getReferencedColumns( ), rightConstraint
                        .getReferencedColumns( ) ) ) {
                    results.add( leftConstraint.getName( ) + ": referenced column sets differ" );
                }
            }
            else if ( leftConstraint.getReferencedTable( ) == null && rightConstraint.getReferencedTable( ) == null ) {}
            else {
                results.add( leftConstraint.getName( ) + ": one referenced table is null" );
            }

            if ( compareColumnSetNames( leftConstraint.getConstrainedColumns( ), rightConstraint
                    .getConstrainedColumns( ) ) ) {
                results.add( leftConstraint.getName( ) + ": constrained column sets differ" );
            }
            l++;
            r++;
        }

        return results;
    }

}
