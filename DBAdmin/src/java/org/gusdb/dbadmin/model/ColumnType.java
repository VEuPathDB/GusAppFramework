package org.gusdb.dbadmin.model;

/**
 * @author msaffitz
 * @version $Revision$ $Date: 2005-06-16 16:35:04 -0400 (Thu, 16 Jun
 *          2005) $
 */
public final class ColumnType {

    public static final ColumnType CHARACTER = new ColumnType( "CHARACTER" );
    public static final ColumnType CLOB      = new ColumnType( "CLOB" );
    public static final ColumnType DATE      = new ColumnType( "DATE" );
    public static final ColumnType FLOAT     = new ColumnType( "FLOAT" );
    public static final ColumnType STRING    = new ColumnType( "STRING" );
    public static final ColumnType UNDEFINED = new ColumnType( "UNDEFINED" );
    private String                 id;
    public static ColumnType       NUMBER    = new ColumnType( "NUMBER" );

    private ColumnType( String id ) {
        this.id = id;
    }

    public String toString( ) {
        return id;
    }

    public static ColumnType getInstance( String id ) {
        if ( id.compareToIgnoreCase( "CHARACTER" ) == 0 ) {
            return CHARACTER;
        }
        else if ( id.compareToIgnoreCase( "CLOB" ) == 0 ) {
            return CLOB;
        }
        else if ( id.compareToIgnoreCase( "DATE" ) == 0 ) {
            return DATE;
        }
        else if ( id.compareToIgnoreCase( "FLOAT" ) == 0 ) {
            return FLOAT;
        }
        else if ( id.compareToIgnoreCase( "NUMBER" ) == 0 ) {
            return NUMBER;
        }
        else if ( id.compareToIgnoreCase( "STRING" ) == 0 ) {
            return STRING;
        }
        else if ( id.compareToIgnoreCase( "UNDEFINED" ) == 0 ) {
            return UNDEFINED;
        }
        return null;
    }

}
