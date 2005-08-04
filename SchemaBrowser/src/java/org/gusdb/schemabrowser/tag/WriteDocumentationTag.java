/**
 * 
 */
package org.gusdb.schemabrowser.tag;

import java.io.IOException;

import javax.servlet.jsp.JspWriter;
import javax.servlet.jsp.tagext.TagSupport;

import org.gusdb.dbadmin.model.GusSchema;
import org.gusdb.dbadmin.model.GusTable;

/**
 * @author msaffitz
 */
public class WriteDocumentationTag extends TagSupport {

    private GusTable table = null;
    
    public void setTable( GusTable table ) {
        this.table = table;
    }

    public GusTable getTable( ) {
        return this.table;
    }
   
    public int doStartTag( ) {
        try {
            JspWriter out = pageContext.getOut( );
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
    
    private void writeTableDocumentationRow(JspWriter out) throws IOException {
        String schemaName = table.getSchema().getName();
        
        out.println("<tr id=\"" + table.getSchema().getName() + "::" + table.getName() + "\" style=\"display: none\">");
        out.println("<td colspan=\"4\" class=\"tableDocumentation\">");
        //<!--<a href="edit/edit.htm?schema=${table.schema.name}">Edit Schema Documentation</a> | -->
        out.println("<a href=\"edit/edit.htm?schema=" + schemaName + "&table=" + table.getName() +
                "\">Edit Table Documentation</a> | ");
        out.println("<a href=\"#"+ schemaName + table.getName() + "\" onClick=\"Toggle.display('" + 
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
