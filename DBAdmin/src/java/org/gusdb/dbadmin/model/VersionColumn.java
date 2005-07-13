package org.gusdb.dbadmin.model;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

/**
 * @author msaffitz
 * @version $Revision$ $Date: 2005-06-16 16:35:04 -0400 (Thu, 16 Jun
 *          2005) $
 */
public class VersionColumn extends Column {

    protected static final Log log = LogFactory.getLog( VersionColumn.class );

    private GusColumn          gusColumn;

    VersionColumn( GusColumn gusColumn ) {
        setGusColumn( gusColumn );
        setLength( gusColumn.getLength( ) );
        setName( gusColumn.getName( ) );
        setNullable( gusColumn.isNullable( ) );
        setPrecision( gusColumn.getPrecision( ) );
        setType( gusColumn.getType( ) );
        if ( gusColumn.getTable( ) != null
                && ((GusTable) gusColumn.getTable( )).isVersioned( ) ) {
            setTable( ((GusTable) gusColumn.getTable( )).getVersionTable( ) );
        }
    }

    GusColumn getGusColumn( ) {
        return this.gusColumn;
    }

    void setGusColumn( GusColumn gusColumn ) {
        this.gusColumn = gusColumn;
    }
    /*
     * public boolean deepEquals(DatabaseObject o, Writer writer) throws
     * IOException { if (o.getClass() != VersionColumn.class) return false; if
     * (equals((VersionColumn) o, new HashSet(), writer)) return true; return
     * false; } boolean equals(DatabaseObject o, HashSet seen, Writer writer)
     * throws IOException { VersionColumn other = (VersionColumn) o; if
     * (!super.equals(other, seen, writer)) return false; boolean equal = true;
     * if (!gusColumn.equals(other.getGusColumn(), seen, writer)) equal = false;
     * if (!equal) { log.debug("VersionColumn attributes vary"); return false; }
     * return compareChildren(other, seen, writer); }
     */

}
