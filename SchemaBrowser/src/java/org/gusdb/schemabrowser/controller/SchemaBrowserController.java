/**
 * $Id:$
 */
package org.gusdb.schemabrowser.controller;

import java.util.Collection;
import java.util.Iterator;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.gusdb.dbadmin.model.GusTable;
import org.gusdb.schemabrowser.DatabaseFactory;
import org.gusdb.schemabrowser.dao.DocumentationDAO;
import org.springframework.web.servlet.mvc.Controller;

public abstract class SchemaBrowserController implements Controller {

    protected final Log               log          = LogFactory.getLog( getClass( ) );
    protected static DatabaseFactory  dbFactory;
    protected static DocumentationDAO docDAO;
    protected static boolean          docPopulated = false;

    protected void populateTableDocumentation( Collection tables ) {
        log.info( "Populating Table Documentation" );
        for ( Iterator i = tables.iterator( ); i.hasNext( ); ) {
            GusTable table = (GusTable) i.next( );
            table.setDocumentation( getDocumentationDAO( ).getDocumentation( table.getSchema( ).getName( ),
                    table.getName( ) ) );
        }
    }

    protected DatabaseFactory getDatabaseFactory( ) {
        if ( !docPopulated ) {
            populateTableDocumentation( this.dbFactory.getDatabase( ).getTables( true ) );
            docPopulated = true;
        }
        return dbFactory;
    }

    public void setDatabaseFactory( DatabaseFactory dbFactory ) {
        this.dbFactory = dbFactory;
    }

    protected DocumentationDAO getDocumentationDAO( ) {
        return this.docDAO;
    }

    public void setDocumentationDAO( DocumentationDAO docDAO ) {
        this.docDAO = docDAO;
    }

}
