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
        if ( gusColumn.getTable( ) != null && ((GusTable) gusColumn.getTable( )).isVersioned( ) ) {
            setTable( ((GusTable) gusColumn.getTable( )).getVersionTable( ) );
        }
    }

    GusColumn getGusColumn( ) {
        return this.gusColumn;
    }

    void setGusColumn( GusColumn gusColumn ) {
        this.gusColumn = gusColumn;
    }

}
