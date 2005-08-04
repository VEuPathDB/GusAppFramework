/**
 * $Id:$
 */
package org.gusdb.schemabrowser.controller;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Iterator;
import java.util.TreeSet;
import java.util.Vector;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.gusdb.dbadmin.model.GusSchema;
import org.gusdb.dbadmin.model.GusTable;
import org.springframework.web.servlet.ModelAndView;

public class TableDisplayController extends SchemaBrowserController {

    public ModelAndView handleRequest( HttpServletRequest request, HttpServletResponse response )
            throws ServletException, IOException {

        // Table Display
        if ( request.getParameter( "schema" ) != null && request.getParameter( "table" ) != null ) {
            return tableDisplay( request.getParameter( "schema" ), request.getParameter( "table" ) );
        }
        // List Display
        else {
            if ( request.getParameter("category") != null ) {
                return listCategoryDisplay(request.getParameter("category"), request.getParameter("sort"));
            }
            else if ( request.getParameter("schema") != null ) {
                return listSchemaDisplay(request.getParameter("schema"), request.getParameter("sort"));
            }
            return listAllDisplay(request.getParameter("sort"));
        }

    }

    private ArrayList sortTablesByName( Collection tables ) {
        return new ArrayList( new TreeSet( tables ) );
    }

    private ArrayList sortTablesBySchema( Collection tables ) {
        TreeSet schemas = new TreeSet( );
        ArrayList results = new ArrayList( );
        for ( Iterator i = tables.iterator( ); i.hasNext( ); ) {
            GusTable table = (GusTable) i.next( );
            schemas.add( table.getSchema( ).getName( ) );
        }
        for ( Iterator j = schemas.iterator( ); j.hasNext( ); ) {
            String schema = (String) j.next( );
            for ( Iterator k = new TreeSet( tables ).iterator( ); k.hasNext( ); ) {
                GusTable table = (GusTable) k.next( );
                if ( table.getSchema( ).getName( ).equalsIgnoreCase( schema ) ) {
                    results.add( table );
                }
            }
        }
        return results;
    }

    private ArrayList sortTablesByCategory( Collection tables ) {
        TreeSet categories = new TreeSet( );
        ArrayList results = new ArrayList( );
        for ( Iterator i = tables.iterator( ); i.hasNext( ); ) {
            GusTable table = (GusTable) i.next( );
            if ( table.getCategory() != null ) {
                categories.add( table.getCategory( ) );
            }
        }
        for ( Iterator i = categories.iterator( ); i.hasNext( ); ) {
            String category = (String) i.next( );
            for ( Iterator k = new TreeSet( tables ).iterator( ); k.hasNext( ); ) {
                GusTable table = (GusTable) k.next( );
                if ( table.getCategory( ) != null &&
                    table.getCategory().getName().equalsIgnoreCase( category ) ) {
                    results.add( table );
                }
            }
        }
        for ( Iterator i = new TreeSet(tables).iterator(); i.hasNext(); ) {
            GusTable table = (GusTable) i.next();
            if ( table.getCategory() == null ) {
                results.add(table);
            }
        }
        return results;
    }

    private ModelAndView tableDisplay( String schemaName, String tableName ) {
        GusSchema schema = (GusSchema) getDatabaseFactory( ).getDatabase( ).getSchema( schemaName );
        GusTable table = null;
        if ( schema != null ) {
            table = (GusTable) schema.getTable( tableName );
        }

        if ( table != null ) {
            return new ModelAndView( "table", "table", table );
        }
        else {
            return new ModelAndView( "error", "error", "Unknown Table" );
        }
    }

    
    private ModelAndView listAllDisplay(String sort) {
        return doSortAndDisplay(getDatabaseFactory( ).getDatabase( ).getTables( true ), sort);
    }
    
    private ModelAndView listCategoryDisplay( String category, String sort ) {
        if ( category == null ) return new ModelAndView("error", "error", "Invalid Category");
        Collection tables = new Vector();
        for ( Iterator i = getDatabaseFactory().getDatabase().getTables(true).iterator(); i.hasNext(); ) {
            GusTable table = (GusTable) i.next();
            if ( table.getCategory() != null && 
                    category.equalsIgnoreCase(table.getCategory().getName())) {
                tables.add(table);
            }
        }
        return doSortAndDisplay(tables, sort);
    }
    
    private ModelAndView listSchemaDisplay(String schemaName, String sort ) {
       GusSchema schema = (GusSchema) getDatabaseFactory( ).getDatabase( ).getSchema( schemaName );
       if ( schema == null ) return new ModelAndView( "error", "error", "Unknown Schema" );
       return doSortAndDisplay(schema.getTables(), sort);
    }
    
    private ModelAndView doSortAndDisplay( Collection tables, String sort ) {
        if ( sort != null && sort.equalsIgnoreCase( "schema" ) ) {
            tables = sortTablesBySchema( tables );
        }
        else if ( sort != null && sort.equalsIgnoreCase( "name" ) ) {
            tables = sortTablesByName( tables );
        }
        else if ( sort != null && sort.equalsIgnoreCase( "category" ) ) {
            tables = sortTablesByCategory( tables );
        }
        else {
            tables = new ArrayList( tables );
        }
        return new ModelAndView( "tableList", "tables", tables );
    }

}
