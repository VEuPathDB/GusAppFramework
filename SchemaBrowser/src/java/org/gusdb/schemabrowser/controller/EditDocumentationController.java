/**
 * 
 */
package org.gusdb.schemabrowser.controller;

import java.util.Iterator;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.gusdb.dbadmin.model.GusColumn;
import org.gusdb.dbadmin.model.GusTable;
import org.gusdb.dbadmin.model.Schema;
import org.gusdb.schemabrowser.DatabaseFactory;
import org.gusdb.schemabrowser.dao.DocumentationDAO;
import org.gusdb.schemabrowser.model.Documentation;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.mvc.SimpleFormController;
import org.springframework.web.servlet.view.RedirectView;

/**
 * @author msaffitz
 */
public class EditDocumentationController extends SimpleFormController {

    protected final Log      log = LogFactory.getLog( getClass( ) );
    private DocumentationDAO docDAO;
    private DatabaseFactory  dbFactory;

    public ModelAndView onSubmit( Object command ) throws ServletException {
        log.info( "Handling submit of documentation edit" );
        Documentation doc = (Documentation) command;
        if ( doc.getSchemaName( ) == null ) {
            log.warn( "Error: lost schema at some point." );
            return new ModelAndView( "error", "error", "Internal Argument Error" );
        }
        log.info( "doing db stuff" );
        getDocumentationDAO( ).saveDocumentationObject( doc );
        
        updateTableDocumentation( doc.getSchemaName(), doc.getTableName(), doc.getAttributeName() ) ;
        
        return new ModelAndView( new RedirectView( getSuccessView( ) ) );
    }

    protected Object formBackingObject( HttpServletRequest request ) throws ServletException {
        Documentation doc = getDocumentationDAO( ).getDocumentationObject( request.getParameter( "schema" ),
                request.getParameter( "table" ), request.getParameter( "attribute" ) );
        if ( doc == null ) {
            doc = new Documentation( );
            doc.setSchemaName( request.getParameter( "schema" ) );
            doc.setTableName( request.getParameter( "table" ) );
            doc.setAttributeName( request.getParameter( "attribute" ) );
        }
        log.debug( "Returning a doc with the name: '" + doc.getSchemaName( ) + "'" );
        return doc;
    }

    private void updateTableDocumentation( String schemaName, String tableName, String attributeName ) {
        log.info( "Updating Table Documentation: '" + schemaName + "' '" + tableName + "' '" + attributeName + "'" );
        Schema schema = getDatabaseFactory( ).getDatabase( ).getSchema( schemaName );
        if ( schema == null ) return;
        if ( tableName == null ) {
            // TODO update schema doc
        } else {
            GusTable table = (GusTable) schema.getTable( tableName );
            if ( table == null ) return;
            if ( attributeName != null ) { 
                GusColumn column = (GusColumn) table.getColumn( attributeName );
                column.setDocumentation( getDocumentationDAO().getDocumentation( table.getSchema().getName(), 
                        table.getName(), column.getName() ));
            } else {
                table.setDocumentation( getDocumentationDAO( ).getDocumentation( table.getSchema( ).getName( ), 
                        table.getName( ) ) );
            }
        }
    }
    
    public DocumentationDAO getDocumentationDAO( ) {
        return this.docDAO;
    }

    public void setDocumentationDAO( DocumentationDAO docDAO ) {
        this.docDAO = docDAO;
    }

    public DatabaseFactory getDatabaseFactory( ) {
        return this.dbFactory;
    }

    public void setDatabaseFactory( DatabaseFactory dbFactory ) {
        this.dbFactory = dbFactory;
    }

}
