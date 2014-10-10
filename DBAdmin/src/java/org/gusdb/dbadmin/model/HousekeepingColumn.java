package org.gusdb.dbadmin.model;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

/**
 * @author msaffitz
 * @version $Revision$ $Date: 2005-06-16 16:35:04 -0400 (Thu, 16 Jun
 *          2005) $
 */
public class HousekeepingColumn extends Column {

    protected static final Log log = LogFactory.getLog( HousekeepingColumn.class );

    public HousekeepingColumn( ) {}

    @Override
    public void setTable( Table table ) {
        if ( getTable( ) != table ) {
            if ( getTable( ) != null ) getTable( ).removeHousekeepingColumn( this );
            log.debug( "Setting table: '" + table.getName( ) + "' for HousekeepingColumn: '" + getName( ) + "'" );
            this.table = table;
            if ( table != null ) table.addHousekeepingColumn( this );
        }
    }

    @Override
    public Object clone( ) {
        HousekeepingColumn clone = new HousekeepingColumn( );
        clone.setLength( getLength( ) );
        clone.setName( getName( ) );
        clone.setNullable( isNullable( ) );
        clone.setPrecision( getPrecision( ) );
        clone.setType( getType( ) );
        return clone;
    }

}
