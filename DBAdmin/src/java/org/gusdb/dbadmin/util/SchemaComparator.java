/**
 * 
 */
package org.gusdb.dbadmin.util;

import java.util.Collection;
import java.util.HashMap;
import java.util.Iterator;
import java.util.TreeSet;
import java.util.Vector;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
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

    protected static final Log log                         = LogFactory.getLog( SchemaComparator.class );

    private Database           leftDatabase;
    private Database           rightDatabase;

    private Collection         leftIdenticalTables         = new Vector( );

    private HashMap            leftRenamedTables           = new HashMap( );

    private HashMap            leftColChangedTables        = new HashMap( );
    private HashMap            leftIndChangedTables        = new HashMap( );
    private HashMap            leftConChangedTables        = new HashMap( );

    private Collection         leftDroppedTables           = new Vector( );

    private Collection         rightAddedTables            = new Vector( );
    private Collection         potentialRightRenameTargets = new Vector( );

    private HashMap            potentialRenameMatches      = new HashMap( );

    public SchemaComparator( Database leftDatabase, Database rightDatabase ) {
        this.leftDatabase = leftDatabase;
        this.rightDatabase = rightDatabase;
    }

    public Collection findLeftIdenticalTables( ) {
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

    public HashMap findLeftRenamedTables( ) {
        if ( !leftRenamedTables.isEmpty( ) ) return leftRenamedTables;
        log.info("finding renamed tables");
        for ( GusTable table : leftDatabase.getGusTables() ) {
            if ( findLeftIdenticalTables( ).contains( table ) ) continue;
            if ( rightDatabase.getSchema( table.getSchema( ).getName( ) ) != null
                    && rightDatabase.getSchema( table.getSchema( ).getName( ) ).getTable( table.getName( ) ) != null ) continue;
            Collection renamedTables = findRenameMatches( table, 0 );
            if ( !renamedTables.isEmpty( ) ) {
                potentialRightRenameTargets.addAll( renamedTables );
                leftRenamedTables.put( table, renamedTables );
            }
        }

        return leftRenamedTables;
    }

    public HashMap findLeftColChangedTables( ) {
        if ( !leftColChangedTables.isEmpty( ) ) return leftColChangedTables;
        log.info("finding tables with changed column sets");
        for ( GusTable table : leftDatabase.getGusTables() ) {
            if ( findLeftIdenticalTables( ).contains( table ) ) continue;
            if ( findLeftRenamedTables( ).get( table ) != null ) continue;
            if ( rightDatabase.getSchema( table.getSchema( ).getName( ) ) == null
                    || rightDatabase.getSchema( table.getSchema( ).getName( ) ).getTable( table.getName( ) ) == null ) continue;
            Table rightTable = rightDatabase.getSchema( table.getSchema( ).getName( ) ).getTable( table.getName( ) );

            Collection colCompareResults = compareColumnSets( table.getColumnsExcludeSuperclass( false ), rightTable
                    .getColumnsExcludeSuperclass( false ) );
            if ( !colCompareResults.isEmpty( ) ) {
                leftColChangedTables.put( table, colCompareResults );
            }
        }
        return leftColChangedTables;
    }

    public HashMap findLeftIndChangedTables( ) {
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
                leftIndChangedTables.put( table, new Vector( ) );
            }
        }
        return leftIndChangedTables;
    }

    public HashMap findLeftConChangedTables( ) {
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

    public Collection findLeftDroppedTables( ) {
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

    public Collection findRightAddedTables( ) {
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

    public Collection findRenameMatches( Table table, int maxModifiedColumns ) {
        if ( potentialRenameMatches.get( table ) != null ) return (Collection) potentialRenameMatches.get( table );

        Collection potentialMatches = new Vector( );

        for ( GusTable targetTable : rightDatabase.getGusTables() ) {
            if ( targetTable.getSchema( ).getName( ) == table.getSchema( ).getName( )
                    && targetTable.getName( ) == table.getName( ) ) continue;

            int foundModifiedColumns = targetTable.getColumnsIncludeSuperclass( false ).size( )
                    - table.getColumnsIncludeSuperclass( false ).size( );
            if ( foundModifiedColumns < 0 ) foundModifiedColumns = 0;

            for ( Iterator k = table.getColumnsIncludeSuperclass( false ).iterator( ); k.hasNext( ); ) {
                Column column = (Column) k.next( );
                if ( targetTable.getColumn( column.getName( ) ) == null ) foundModifiedColumns++;
                else if ( !column.equals( targetTable.getColumn( column.getName( ) ) ) ) foundModifiedColumns++;
            }
            if ( foundModifiedColumns > maxModifiedColumns ) continue;
            potentialMatches.add( targetTable );
        }
        potentialRenameMatches.put( table, potentialMatches );
        return potentialMatches;
    }

    public static boolean compareColumnSetNames( Collection leftColumns, Collection rightColumns ) {
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

    public static Collection compareColumnSets( Collection leftColumns, Collection rightColumns ) {
        Collection results = new Vector( );

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

/*    private Collection getIndexDifferences( Index leftIndex, Index rightIndex ) {
        Collection differences = new Vector( );

        if ( leftIndex.getType( ) != rightIndex.getType( ) ) {
            differences.add( "types differ" );
        }
        if ( !compareColumnSetNames( leftIndex.getColumns( ), rightIndex.getColumns( ) ) ) {
            differences.add( "column sets differ" );
        }
        return differences;
    }
*/
    
    private Collection getConstraintDifferences( GusTable leftTable, GusTable rightTable ) {
        Collection results = new Vector( );

        Object[] leftConstraints = new TreeSet( leftTable.getConstraints( ) ).toArray( );
        Object[] rightConstraints = new TreeSet( rightTable.getConstraints( ) ).toArray( );

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
