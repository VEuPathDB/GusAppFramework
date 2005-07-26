/**
 * 
 */
package org.gusdb.schemabrowser;

import java.io.IOException;

import javax.servlet.jsp.JspWriter;
import javax.servlet.jsp.tagext.TagSupport;

import org.gusdb.dbadmin.model.GusSchema;
import org.gusdb.dbadmin.model.GusTable;

/**
 * @author msaffitz
 */
public class RowWriter extends TagSupport {

    private GusTable table = null;
    private int number = 0;

    public void setTable( GusTable table ) {
        this.table = table;
    }

    public GusTable getTable( ) {
        return this.table;
    }

    public void setNumber( int number ) {
        this.number =number;
    }
    
    public int getNumber() { 
        return this.number;
    }
    
    public int doStartTag( ) {
        try {
            JspWriter out = pageContext.getOut( );
            writeTableRow(out);
            writeTableDocumentationRow(out);
        }
        catch ( IOException ex ) {
            throw new Error( "Error rendering page" );
        }
        return SKIP_BODY;
    }

    public int doEndTag( ) {
        return SKIP_BODY;
    }

    private void writeTableRow(JspWriter out) throws IOException {
        String row = number %2==0 ? "even" : "odd";
        String schemaName = getTable().getSchema().getName();
        out.println("<tr class=\"tableRow " + row + "\">");
        out.println("<td><a name=\"" + schemaName + "::" + table.getName() + "\"/><big>");
        
        out.print("<a href=\"tableList.htm?schema=" + schemaName + "\">" + schemaName + "</a>::" );
        out.print("<a href=\"table.htm?schema=" + schemaName + "&table=" + table.getName() + "\">" );
        out.println( table.getName() + "</a>");
        
        out.println("</td></big>");
        
        out.println("<td>");
        if ( table.getSuperclass() != null ) {
            String superClassSchemaName = table.getSuperclass().getSchema().getName();
            out.print("<a href=\"table.htm?schema=" + superClassSchemaName + "&table=");
            out.print(table.getSuperclass().getName() + "\">" + superClassSchemaName + "::");
            out.println(table.getSuperclass().getName() + "</a>");
        }
        out.println("</td><td>");
        
        if ( table.getCategory() != null ) {
            out.print("<a href=\"tableList.htm?category=" + table.getCategory().getName() + "\">" );
            out.println( table.getCategory().getName() + "</a>");
        }
        
        out.println("</td><td>");
        out.println("<a href=\"table.htm?schema=" + schemaName + "&table=" + table.getName() + "\">View Table</a> | ");
        out.println("<a href=\"#"+ schemaName + "::" + table.getName() + "\" onClick=\"Toggle.display('"+ 
                schemaName + "::" + table.getName() + "');\">View Documentation</a> | ");
        out.println("<a href=\"edit/edit.htm?schema=" + schemaName + "&table=" + table.getName() + "\">Edit</a>");
        
        out.println("</td></tr>");
    }
    
    private void writeTableDocumentationRow(JspWriter out) throws IOException {
        String schemaName = table.getSchema().getName();
        
        out.println("<tr id=\"" + table.getSchema().getName() + "::" + table.getName() + "\" style=\"display: none\">");
        out.println("<td colspan=\"4\" class=\"tableDocumentation\">");
        //<!--<a href="edit/edit.htm?schema=${table.schema.name}">Edit Schema Documentation</a> | -->
        out.println("<a href=\"edit/edit.htm?schema=" + schemaName + "&table=" + table.getName() +
                "\">Edit Table Documentation</a> | ");
        out.println("<a href=\"#"+ schemaName + "::" + table.getName() + "\" onClick=\"Toggle.display('" + 
                schemaName + "::"+ table.getName() + "');\">Close Documentation</a><p/>");

        out.println("<b>" + schemaName + "</b> Documentation:<p/>");
        
        if ( ((GusSchema) table.getSchema()).getDocumentation() != null ) {
            out.println( ((GusSchema)table.getSchema()).getDocumentation() );
        } else {
            out.println("No Documentation Provided.");
            //<!--Help out: <a href="edit/edit.htm?schema=${table.schema.name}">Add Documentation</a>-->
        }
        out.println("<p/><b>" + schemaName + "::" + table.getName() + "</b> Documentation:<p/>");
        
        if ( table.getDocumentation() != null ) {
            out.println(table.getDocumentation() );
        } else {
            out.println("No Documentation Provided.  Help out: <a href=\"edit/edit.htm?schema=" + schemaName + 
                    "&table=" + table.getName() + "\">Add Documentation</a>");
        }
         
        out.println("</td></tr>");
    }

}
