package org.gusdb.dbadmin.model;

import java.util.Objects;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * @author msaffitz
 * @version $Revision$ $Date: 2005-06-16 16:35:04 -0400 (Thu, 16 Jun
 *          2005) $
 */
public class HousekeepingColumn extends Column {

    private static final Logger log = LogManager.getLogger( HousekeepingColumn.class );

    public HousekeepingColumn( ) {}

    @Override
    public void setTable( Table table ) {
        Objects.requireNonNull(table);
        if ( getTable() != table ) {
            getTable().removeHousekeepingColumn( this );
            log.debug( "Setting table: '" + table.getName( ) + "' for HousekeepingColumn: '" + getName( ) + "'" );
            this.table = table;
            table.addHousekeepingColumn( this );
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
