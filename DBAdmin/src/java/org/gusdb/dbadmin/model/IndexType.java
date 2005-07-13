package org.gusdb.dbadmin.model;

/**
 * @author msaffitz
 * @version $Revision$ $Date: 2005-06-16 16:35:04 -0400 (Thu, 16 Jun
 *          2005) $
 */
public class IndexType {

    public static final IndexType NORMAL = new IndexType( "NORMAL" );
    public static final IndexType BITMAP = new IndexType( "BITMAP" );
    private String                id;

    private IndexType( String id ) {
        this.id = id;
    }

    public String toString( ) {
        return id;
    }

    public static IndexType getInstance( String id ) {
        if ( id.compareToIgnoreCase( "NORMAL" ) == 0 ) {
            return NORMAL;
        }
        else if ( id.compareToIgnoreCase( "BITMAP" ) == 0 ) {
            return BITMAP;
        }
        return null;
    }

}
